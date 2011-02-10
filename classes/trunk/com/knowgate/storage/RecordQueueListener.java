/*
  Copyright (C) 2003-2011  Know Gate S.L. All rights reserved.

  Redistribution and use in source and binary forms, with or without
  modification, are permitted provided that the following conditions
  are met:

  1. Redistributions of source code must retain the above copyright
     notice, this list of conditions and the following disclaimer.

  2. The end-user documentation included with the redistribution,
     if any, must include the following acknowledgment:
     "This product includes software parts from hipergate
     (http://www.hipergate.org/)."
     Alternately, this acknowledgment may appear in the software itself,
     if and wherever such third-party acknowledgments normally appear.

  3. The name hipergate must not be used to endorse or promote products
     derived from this software without prior written permission.
     Products derived from this software may not be called hipergate,
     nor may hipergate appear in their name, without prior written
     permission.

  This library is distributed in the hope that it will be useful,
  but WITHOUT ANY WARRANTY; without even the implied warranty of
  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.

  You should have received a copy of hipergate License with this code;
  if not, visit http://www.hipergate.org or mail to info@hipergate.org
*/

package com.knowgate.storage;

import java.sql.SQLException;

import java.util.HashMap;
import java.util.ArrayList;
import java.util.Enumeration;

import javax.jms.Message;
import javax.jms.Session;
import javax.jms.TextMessage;
import javax.jms.ObjectMessage;
import javax.jms.TemporaryQueue;
import javax.jms.MessageProducer;
import javax.jms.MessageListener;

import com.knowgate.debug.DebugFile;
import com.knowgate.jdc.JDCConnection;
import com.knowgate.misc.Gadgets;
import com.knowgate.misc.Environment;
import com.knowgate.dataobjs.DBBind;
import com.knowgate.dataobjs.DBPersist;

import com.knowgate.storage.Table;
import com.knowgate.storage.Engine;
import com.knowgate.storage.StorageException;

import com.knowgate.berkeleydb.DBErrorLog;

public class RecordQueueListener implements MessageListener {

  private String sProfile;
  private Session oSes;
  private DataSource oDts;
  private static HashMap<String,DBBind> oDbs = new HashMap<String,DBBind>();
  private static HashMap<String,Integer> oDbr = new HashMap<String,Integer>();

  public RecordQueueListener(Engine eEngine, String sProfileName, Session oSssn)
  	throws StorageException,InstantiationException {
  	sProfile = sProfileName;
  	oSes = oSssn;
  	if (Environment.getProfileVar(sProfileName,"dbenvironment","").length()==0) {
	  oDts = null;
  	} else {
  	  oDts = DataSourcePool.get(eEngine,sProfileName,false);  	  
  	}
  	if (Environment.getProfileVar(sProfileName,"dburl","").length()==0) {
	  if (!oDbs.containsKey(sProfileName)) {
	    oDbs.put(sProfileName, new DBBind(sProfileName));
	    oDbr.put(sProfileName, new Integer(1));	  
	  } else {
	    int iRefs = oDbr.get(sProfileName).intValue();
	    oDbr.remove(sProfileName);
	    oDbr.put(sProfileName, new Integer(++iRefs));
	  }
  	}
  }

  public void close() throws StorageException {
  	if (oDts!=null) DataSourcePool.free(oDts);
  	if (oDbr.containsKey(sProfile)) {
	  int iRefs = oDbr.get(sProfile).intValue();
	  if (--iRefs==0) {
	    oDbs.get(sProfile).close();
	    oDbs.remove(sProfile);
	    oDbr.remove(sProfile);
	  } else {
	    oDbr.remove(sProfile);
	    oDbr.put(sProfile, new Integer(iRefs));	  	
	  }  	  
  	}
  }
  
  public void onMessage (Message oMsg) {

  	Table oCon = null;
    TemporaryQueue oRpl;
	MessageProducer oRpr = null;
	String sErr = null; 

  	if (DebugFile.trace) {
  	  DebugFile.writeln("Begin RecordQueueListener.onMessage([Message])");
  	  DebugFile.incIdent();
  	}
	
    try {

  	  	int iCommand = -1;
  	  	for (Enumeration oPropNames = oMsg.getPropertyNames();
  	  	  oPropNames.hasMoreElements() && iCommand<0;) {
  	  	  if (oPropNames.nextElement().equals("command"))
  	  	  iCommand = oMsg.getIntProperty("command");
  	  	} // next

  	    if (oMsg instanceof ObjectMessage) {

  	  	  ObjectMessage oObj = (ObjectMessage) oMsg;

  	  	  switch (iCommand) {

  	  	  	case COMMAND_STORE_RECORD:
  	  	  	case COMMAND_DELETE_RECORDS:
  	  	  	  Record oRec = (Record) oObj.getObject();

  	  	      if (DebugFile.trace) DebugFile.writeln("processing "+oRec.getClass().getName());

  	  	  	  try {
  	  	  	    oCon = oDts.openTable(oRec);
  	  	  	    
  	  	  	    if (COMMAND_STORE_RECORD==iCommand) {

  	  	  	      oRec.store(oCon);

  	  	  	    } else if (COMMAND_DELETE_RECORDS==iCommand) {

  	  	  	      String[] aKeys = Gadgets.split(oMsg.getStringProperty("keys"),'`');
  	  	  	      if (null!=aKeys) {
  	  	  	      	for (int k=0; k<aKeys.length; k++) {
  	  	  	      	  oRec.setPrimaryKey(aKeys[k]);
  	  	  	      	  oRec.delete(oCon);
  	  	  	      	} // next
  	  	  	      } // fi

  	  	  	    } // fi

  	  	  	    oCon.close();
  	  	  	    oCon=null;

  	  	        if (DebugFile.trace) DebugFile.writeln("record successfully "+(iCommand==COMMAND_STORE_RECORD ? "stored" : "deleted"));
  	  	  	    
  	  	  	  } catch (Exception oXcpt) {
  	  			if (DebugFile.trace) DebugFile.writeln(oXcpt.getClass().getName()+" "+oXcpt.getMessage());
		    	try { if (DebugFile.trace) DebugFile.writeln(com.knowgate.debug.StackTraceUtil.getStackTrace(oXcpt)); } catch (Exception ignore) {}
  	  	  	  	sErr = oXcpt.getClass().getName()+" "+oXcpt.getMessage();
  	  	  	  	String sUserAcc = oMsg.getStringProperty("UserAccount");
  	  	  	  	if (sUserAcc!=null) {
				  try {
				    new DBErrorLog().log(oDts,ErrorCode.DATABASE_EXCEPTION, sUserAcc, oMsg, oXcpt, oXcpt.getCause());
				  } catch (Exception ignore) { }
  	  	  	  	} //
  	  	  	  } finally {
  	  	  	  	if (oCon!=null) {
  	  	          if (DebugFile.trace) DebugFile.writeln("gracefully closing connection");
  	  	  	  	  oCon.close();
  	  	  	  	}
  	  	  	  }
  	  	  	  break;

  	  	  	case COMMAND_STORE_REGISTER:

  	  	  	  DBPersist oDbp = (DBPersist) oObj.getObject();
  	  	      String sClsName = oDbp.getClass().getName();

  	  	      if (DebugFile.trace) DebugFile.writeln("processing "+sClsName);

  	  	  	  JDCConnection oJcn = null;
  	  	  	  try {
  	  	  	    oJcn = oDbs.get(sProfile).getConnection(sClsName);
  	  	  	    oJcn.setAutoCommit(false);
  	  	  	    oDbp.store(oJcn);
  	  	  	    oJcn.commit();
  	  	  	    oJcn.close(sClsName);
  	  	  	    oJcn=null;
  	  	  	  } catch (Exception oXcpt) {
  	  			if (DebugFile.trace)
  	  	          DebugFile.writeln(sClsName+" "+oXcpt.getMessage());
		    	try { if (DebugFile.trace) DebugFile.writeln(com.knowgate.debug.StackTraceUtil.getStackTrace(oXcpt)); } catch (Exception ignore) {}
  	  	  	  	sErr = oXcpt.getClass().getName()+" "+oXcpt.getMessage();
  	  	  	  	String sUserAcc = oMsg.getStringProperty("UserAccount");
  	  	  	  	if (sUserAcc!=null) {
				  // ErrorLog.log(sUserAcc, oXcpt, oMsg);
  	  	  	  	} //
  	  	  	  	break;
  	  	  	  } finally {
  	  	  	  	if (oJcn!=null) {
  	  	  	  	  try {
  	  	  	  		if (!oJcn.isClosed()) {
  	  	  	  		  oJcn.rollback();
  	  	  	  		  oJcn.close(sClsName);
  	  	  	  		}
  	  	  	  	  } catch (SQLException oSqle) {
  	  			    if (DebugFile.trace) {
  	  	              DebugFile.writeln(sClsName+" "+oSqle.getMessage());
		    	      try { DebugFile.writeln(com.knowgate.debug.StackTraceUtil.getStackTrace(oSqle)); } catch (Exception ignore) {}
  	  	  	  	    }
  	  	  	  	  }
  	  	  	  	} // fi
  	  	  	  }

  	  	  	default:
  	  	  	  if (-1==iCommand)
  	  	  	    throw new UnsupportedOperationException("Command property not found");
  	  	  	  else
  	  	  	    throw new UnsupportedOperationException("Command "+String.valueOf(iCommand)+" not found");
  	  	  }
  	  	  
  	    } else if (oMsg instanceof TextMessage) {

  	  	  TextMessage oTxt = (TextMessage) oMsg;
  	  	  if (DebugFile.trace) DebugFile.writeln("processing text message "+oTxt.getText());

  	  	  switch (iCommand) {

  	  	  	case COMMAND_STOP:
  	  	  	  break;

  	  	  	default:
  	  	  	  if (-1==iCommand)
  	  	  	    throw new UnsupportedOperationException("Command property not found");
  	  	  	  else
  	  	  	    throw new UnsupportedOperationException("Command "+String.valueOf(iCommand)+" not found");
  	  	  }
  	  	  
  	    } else {
  	  	  throw new ClassNotFoundException("Could not handle messages of type "+oMsg.getClass().getName());
  	    }

  	  	oRpl = (TemporaryQueue) oMsg.getJMSReplyTo();

		if (oRpl!=null && oSes!=null) {
		  if (DebugFile.trace) DebugFile.writeln("replying message "+oMsg.getJMSMessageID()+" to "+oRpl.getQueueName()+(sErr==null ? "" : " with error "+sErr));
		  oRpr = oSes.createProducer(oRpl);
	      TextMessage oTxt = oSes.createTextMessage();
	      oTxt.setBooleanProperty("Error", sErr!=null);
	      oTxt.setText(sErr==null ? "Acknowledge" : sErr);
		  oTxt.setJMSCorrelationID(oMsg.getJMSMessageID());
	      oRpr.send(oTxt);
	      oRpr.close();
		  oRpr=null;
		} else {
		  if (DebugFile.trace) DebugFile.writeln("no reply destination set for messsage "+oMsg.getJMSMessageID());
		}

  	} catch (Exception xcpt) {

  	  if (DebugFile.trace)
  	  	DebugFile.writeln(xcpt.getClass().getName()+" "+xcpt.getMessage());
  	  try { if (DebugFile.trace) DebugFile.writeln(com.knowgate.debug.StackTraceUtil.getStackTrace(xcpt)); } catch (Exception ignore) {}

	  try {
  	  	oRpl = (TemporaryQueue) oMsg.getJMSReplyTo();

		if (oRpl!=null && oSes!=null) {
		  if (DebugFile.trace) DebugFile.writeln("replying message "+oMsg.getJMSMessageID()+" to "+oRpl.getQueueName()+" with error "+xcpt.getClass().getName()+" "+xcpt.getMessage());
		  oRpr = oSes.createProducer(oRpl);
	      TextMessage oTxt = oSes.createTextMessage();
	      oTxt.setBooleanProperty("Error", true);
	      oTxt.setText(xcpt.getClass().getName()+" "+xcpt.getMessage());
		  oTxt.setJMSCorrelationID(oMsg.getJMSMessageID());
	      oRpr.send(oTxt);
	      oRpr.close();
		  oRpr=null;
		}

	  } catch (Exception ignore) { }

  	} finally {
  	  if (oRpr!=null) { try { oRpr.close(); } catch (Exception ignore) {} }
  	}

  	if (DebugFile.trace) {
  	  DebugFile.decIdent();
  	  DebugFile.writeln("End RecordQueueListener.onMessage()");
  	}
  } // onMessage

  public final static int COMMAND_STOP = 0;
  public final static int COMMAND_STORE_RECORD = 1;
  public final static int COMMAND_STORE_REGISTER = 2;
  public final static int COMMAND_DELETE_RECORDS = 4;

}
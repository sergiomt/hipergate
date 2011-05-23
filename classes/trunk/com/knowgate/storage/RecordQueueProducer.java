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

import javax.jms.Queue;
import javax.jms.Session;
import javax.jms.Message;
import javax.jms.Connection;
import javax.jms.DeliveryMode;
import javax.jms.JMSException;
import javax.jms.TextMessage;
import javax.jms.ObjectMessage;
import javax.jms.QueueSession;
import javax.jms.QueueReceiver;
import javax.jms.QueueRequestor;
import javax.jms.TemporaryQueue;
import javax.jms.QueueConnection;
import javax.jms.MessageProducer;
import com.sun.messaging.ConnectionFactory;

import javax.naming.Context;
import javax.naming.RefAddr;
import javax.naming.Reference;
import javax.naming.InitialContext;
import javax.naming.NamingException;

import java.io.Serializable;

import java.util.ArrayList;
import java.util.Iterator;
import java.util.Hashtable;
import java.util.Properties;
import java.util.Enumeration;

import com.knowgate.misc.Gadgets;

import com.knowgate.debug.DebugFile;
import com.knowgate.debug.StackTraceUtil;

import com.knowgate.berkeleydb.DBEnvironment;

import com.knowgate.misc.Gadgets;

import com.knowgate.clocial.MetaData;

import com.knowgate.dataobjs.DBPersist;

public class RecordQueueProducer {

  private String sLoginId;
  private String sAuthStr;
  private Hashtable oEnv;
  private Context oCtx;
  private ConnectionFactory oCnf;
  private Queue oQue;
  private RecordQueueListener oRql;
  private Properties oDefaultProps = new Properties();
  
  public RecordQueueProducer()
  	throws StorageException, InstantiationException {
    oEnv = new Hashtable();
    oCtx = null;
    oCnf = null;
    oQue = null;  
    oRql = new RecordQueueListener(Engine.DEFAULT, "extranet", null);
  }
  
  public RecordQueueProducer(String sConnectionFactoryName, String sQueueName,
  							 String sDirectory, String sUserId,
  							 String sPassword)
  	throws NamingException,JMSException,StorageException,InstantiationException {
  	sLoginId = sUserId;
  	sAuthStr = sPassword;
    oEnv = new Hashtable();
    if (sConnectionFactoryName!=null && sQueueName!=null && sDirectory!=null) {
      oEnv.put(Context.INITIAL_CONTEXT_FACTORY, "com.sun.jndi.fscontext.RefFSContextFactory");
      oEnv.put(Context.PROVIDER_URL, "file://"+sDirectory);
      oCtx = new InitialContext(oEnv);
      oCnf = (ConnectionFactory) oCtx.lookup(sConnectionFactoryName);	
      oQue = (Queue) oCtx.lookup(sQueueName);
      oRql = null;
    } else {
      oRql = new RecordQueueListener(Engine.DEFAULT, "extranet", null);
    }
  }

  public RecordQueueProducer(String sProfileName)
  	throws NamingException,JMSException,StorageException,InstantiationException {
    oRql = new RecordQueueListener(Engine.DEFAULT, sProfileName, null);
  }

  public RecordQueueProducer(Properties oProps)
  	throws NamingException,JMSException,StorageException,InstantiationException {
  	this(oProps.getProperty("jmsconnectionfactory"),
  		 oProps.getProperty("jmsqueue"),
  		 oProps.getProperty("jmsprovider"),
  		 oProps.getProperty("jmsuser"),
  		 oProps.getProperty("jmspassword"));
  }

  protected void finalize() {
    try { close(); } catch (Exception ignore) { }
  }  

  public void close() throws StorageException {
    if (null!=oRql) oRql.close();	
  }

  private void setProperties(ObjectMessage oMsg, Properties oProps)
  	throws JMSException {
  	
  	if (DebugFile.trace) {
  	  DebugFile.writeln("Begin RecordQueueProducer.setProperties()");
  	  DebugFile.incIdent();
  	}
  	
	oMsg.setBooleanProperty("synchronous", false);
	oMsg.setJMSMessageID(Gadgets.generateUUID());

  	if (oProps!=null) {
	  Iterator oItr = oProps.keySet().iterator();
	  while (oItr.hasNext()) {
	    String sKey = (String)oItr.next();
	  	if (sKey.equalsIgnoreCase("synchronous") || sKey.equalsIgnoreCase("sync")) {
	  	  String sVal = oProps.getProperty(sKey);
	  	  if ((sVal.equalsIgnoreCase("true") ||
	  	    sVal.equalsIgnoreCase("1") || 
	  	    sVal.equalsIgnoreCase("yes") ||
	  	    sVal.equalsIgnoreCase("synchronous"))) {
	  	    if (DebugFile.trace)
  	          DebugFile.writeln("ObjectMessage.setBooleanProperty(synchronous, true)");
	  	    oMsg.setBooleanProperty("synchronous", true);
	  	  } // fi
	  	} else {
	  	  if (DebugFile.trace)
  	        DebugFile.writeln("ObjectMessage.setStringProperty("+sKey+","+oProps.getProperty(sKey)+")");
	  	  oMsg.setStringProperty(sKey, oProps.getProperty(sKey));
	  	}
	  } // wend
	} // fi

  	if (DebugFile.trace) {
  	  DebugFile.decIdent();
  	  DebugFile.writeln("End RecordQueueProducer.setProperties()");
  	}
  } // setProperties
  
  private void sendMessage(Serializable oObj,int iCommand,Properties oProps) throws JMSException,StorageException {

	QueueConnection oQcn = null;
	Session oSes = null;
	MessageProducer oMpr = null;
    QueueReceiver oQrr = null;
    QueueRequestor oQrq = null;

  	if (DebugFile.trace) {
  	  DebugFile.writeln("Begin RecordQueueProducer.sendMessage([Serializable],"+String.valueOf(iCommand)+",[Properties])");
  	  DebugFile.incIdent();
  	}
	
	if (oQue==null) {

	  ObjectMessageImpl oMsg = new ObjectMessageImpl();
	  oMsg.setObject(oObj);
	  oMsg.setIntProperty("command", iCommand);
	  setProperties(oMsg,oProps);
	  oRql.onMessage(oMsg);
  	  	
	} else {

	  try {
	    oQcn = oCnf.createQueueConnection(sLoginId,sAuthStr);
	    oSes = oQcn.createQueueSession(false, Session.AUTO_ACKNOWLEDGE);
	    ObjectMessage oMsg = oSes.createObjectMessage(oObj);
	    oMsg.setJMSDeliveryMode(DeliveryMode.PERSISTENT);
	    oMsg.setIntProperty("command", iCommand);
	    setProperties(oMsg,oProps);

		if (oMsg.getBooleanProperty("synchronous")) {
	      oQcn.start();
		  TemporaryQueue oTqe = oSes.createTemporaryQueue();
	      oMsg.setJMSPriority(PRIORITY_EXPEDITED);
	  	  oMsg.setJMSReplyTo(oTqe);

	      oMpr = oSes.createProducer(oQue);
	      oMpr.send(oMsg);
		  if (DebugFile.trace)
  	  	    DebugFile.writeln("Requested message "+oMsg.getJMSMessageID()+" with reply to "+oTqe.getQueueName());

    	  oQrr = (QueueReceiver) oSes.createConsumer(oTqe); // "JMSCorrelationID='"+oMsg.getJMSMessageID()+"'"
		  TextMessage oRpl = (TextMessage) oQrr.receive(20000l);
		  oQrr.close();
		  oQrr=null;
	      oMpr.close();
	      oMpr = null;
		  oTqe.delete();      
  	  	  oTqe=null;
	      oQcn.stop();

		  if (oRpl==null) {

		    if (DebugFile.trace) {
  	  	      DebugFile.writeln("Reply timed out");
		      DebugFile.decIdent();
		    }
  	  	    throw new JMSException("Message reply timed out");

		  } else if (oRpl.getBooleanProperty("Error")) {

		    if (DebugFile.trace) {
  	  	      DebugFile.writeln(oRpl.getText());
		      DebugFile.decIdent();
		    }
			throw new StorageException(oRpl.getText());

		  }

		} else {

	      oMsg.setJMSPriority(PRIORITY_NORMAL);
	      oMpr = oSes.createProducer(oQue);
	      oMpr.send(oMsg);
		  if (DebugFile.trace)
  	  	    DebugFile.writeln("Sent message "+oMsg.getJMSMessageID());
	      oMpr.close();
	      oMpr = null;

		}

	    oSes.close();
	    oSes = null;
	    oQcn.close();
	    oQcn = null;
	  } finally {
	    if (null!=oQrq) { try {oQrq.close(); } catch (Exception ignore) {} }
	    if (null!=oQrr) { try {oQrr.close(); } catch (Exception ignore) {} }
	    if (null!=oMpr) { try {oMpr.close(); } catch (Exception ignore) {} }
	    if (null!=oSes) { try {oSes.close(); } catch (Exception ignore) {} }
	    if (null!=oQcn) { try {oQcn.close(); } catch (Exception ignore) {} }
	  }
	} // fi

  	if (DebugFile.trace) {
  	  DebugFile.decIdent();
  	  DebugFile.writeln("End RecordQueueProducer.sendMessage()");
  	}

  } // store

  public void store(Record oRec) throws JMSException,StorageException {
  	if (DebugFile.trace) {
  	  DebugFile.writeln("RecordQueueProducer.store("+oRec.getTableName()+"."+oRec.getPrimaryKey()+")");
  	}
    if (!oDefaultProps.containsKey("useraccount")) oDefaultProps.put("useraccount","anonymous");    
    sendMessage(oRec,COMMAND_STORE_RECORD,null);
  }

  public void store(Record oRec,Properties oProps) throws JMSException,StorageException {
  	if (DebugFile.trace) {
  	  DebugFile.writeln("RecordQueueProducer.store("+oRec.getTableName()+"."+oRec.getPrimaryKey()+","+oProps+")");
  	}
    if (oProps==null) oProps = oDefaultProps;
    if (!oProps.containsKey("useraccount")) oProps.put("useraccount","anonymous");
    sendMessage(oRec,COMMAND_STORE_RECORD,oProps);
  }

  public void store(DBPersist oDbp,Properties oProps) throws JMSException,StorageException {
    if (oProps==null) oProps = oDefaultProps;
    if (!oProps.containsKey("useraccount")) oProps.put("useraccount","anonymous");
    sendMessage(oDbp,COMMAND_STORE_REGISTER,oProps);
  }

  public void delete(Record oRec, String[] aKeys, Properties oProps) throws JMSException,StorageException {
    if (oProps==null) oProps = oDefaultProps;
    if (!oProps.containsKey("useraccount")) oProps.put("useraccount","anonymous");
    oProps.put("keys",Gadgets.join(aKeys,"`"));
    sendMessage(oRec,COMMAND_DELETE_RECORDS,oProps);
  }

  public void stop(boolean bInmediate, int iTimeout) throws JMSException,StorageException {
	Connection oQcn = null;
	Session oSes = null;
	MessageProducer oMpr = null;
    QueueReceiver oQrr = null;
    TemporaryQueue oRpl = null;

  	if (DebugFile.trace) {
  	  DebugFile.writeln("Begin RecordQueueProducer.stop("+String.valueOf(bInmediate)+","+String.valueOf(iTimeout)+")");
  	  DebugFile.incIdent();
  	}
	
	if (oQue!=null) {
	  try {
	    oQcn = oCnf.createConnection(sLoginId,sAuthStr);
	    oSes = (Session) oQcn.createSession(false, Session.AUTO_ACKNOWLEDGE);
	    TextMessage oMsg = oSes.createTextMessage("Stop");
	    oMsg.setJMSDeliveryMode(DeliveryMode.NON_PERSISTENT);
	    oMsg.setIntProperty("command", COMMAND_STOP);
	    oMsg.setJMSPriority(bInmediate ? 9 : 0);
	    if (iTimeout>0) {
		  oRpl = oSes.createTemporaryQueue();
	  	  oMsg.setJMSReplyTo(oRpl);
	    }
	    oMpr = oSes.createProducer(oQue);
	    oMpr.send(oMsg);
	    oMpr.close();
	    oMpr = null;

		if (DebugFile.trace)
  	  	    DebugFile.writeln("Sent stop message "+oMsg.getJMSMessageID());

		if (iTimeout>0) {
		  oQcn.start();
    	  oQrr = (QueueReceiver) oSes.createConsumer(oRpl, "JMSCorrelationID='"+oMsg.getJMSMessageID()+"'");
		  Message oMss = oQrr.receive(iTimeout);
		  if (null==oMss) throw new JMSException("Stop request timed out");
		  if (DebugFile.trace)
  	  	    DebugFile.writeln("Stop completed "+oMsg.getJMSMessageID()+" "+oMss.getJMSCorrelationID());
		  oQrr.close();
		  oQrr=null;
		  oRpl.delete();
		  oRpl=null;
		  oQcn.stop();
		}

	    oSes.close();
	    oSes = null;
	    oQcn.close();
	    oQcn = null;
	  } finally {
	    if (null!=oQrr) { try {oQrr.close(); } catch (Exception ignore) {} }
	    if (null!=oMpr) { try {oMpr.close(); } catch (Exception ignore) {} }
	    if (null!=oRpl) { try {oRpl.delete();} catch (Exception ignore) {} }
	    if (null!=oSes) { try {oSes.close(); } catch (Exception ignore) {} }
	    if (null!=oQcn) { try {oQcn.close(); } catch (Exception ignore) {} }
	  }
	} // fi

  	if (DebugFile.trace) {
  	  DebugFile.decIdent();
  	  DebugFile.writeln("End RecordQueueProducer.stop()");
  	}
  } // stop

  public final static int COMMAND_STOP = 0;
  public final static int COMMAND_STORE_RECORD = 1;
  public final static int COMMAND_STORE_REGISTER = 2;
  public final static int COMMAND_DELETE_RECORDS = 4;

  public final static int PRIORITY_LOW = 1;
  public final static int PRIORITY_NORMAL = 4;
  public final static int PRIORITY_EXPEDITED = 7;
  
}

/*
  Copyright (C) 2008  Know Gate S.L. All rights reserved.
                      C/Oña, 107 1º2 28050 Madrid (Spain)

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

package com.knowgate.scheduler;

import java.io.File;
import java.io.FileWriter;
import java.io.IOException;

import java.rmi.RemoteException;

import java.lang.reflect.Constructor;
import java.lang.reflect.InvocationTargetException;

import java.util.Date;
import java.util.Map;
import java.util.HashMap;
import java.util.Properties;

import java.sql.SQLException;
import java.sql.Statement;
import java.sql.ResultSet;

import com.knowgate.cache.DistributedCachePeer;
import com.knowgate.dataobjs.DB;
import com.knowgate.dataobjs.DBPersist;
import com.knowgate.misc.Gadgets;
import com.knowgate.debug.DebugFile;
import com.knowgate.debug.StackTraceUtil;
import com.knowgate.jdc.JDCConnection;
import com.knowgate.jdc.JDCConnectionPool;
import com.knowgate.dataobjs.DBBind;

/**
 * <p>Abstract superclass for event handlers</p>
 * Classes implementing an event handler must derive from this one and implement the trigger method
 * @author Sergio Montoro Ten
 * @version 7.0
 **/
 
public abstract class Event extends DBPersist implements Runnable {

  private static final long serialVersionUID = 700l;
  private static HashMap<String,Class> oCmmdClasses = null;
  private static HashMap<Integer,HashMap<String,String>> oEventsPerDomain = null;
  private static DistributedCachePeer oEventCache = null;
  private DBBind oDbb;
  private String sLogDir;
  
  protected Event(DBBind oDbBind) {
	super(DB.k_events, "Event");
	oDbb = oDbBind;
	
	try {
	  // Create directory storage/events
      sLogDir = oDbBind.getProperty("storage") + File.separator + "events";
      File oLogDir = new File(sLogDir);
      if (!oLogDir.exists()) oLogDir.mkdir();
      sLogDir += File.separator;
	} catch (Exception ignore) { sLogDir=null; }

  }
  
  protected Event() {
	super(DB.k_events, "Event");
	oDbb = null;
	sLogDir = null;
  }

  // ----------------------------------------------------------
  
  public void run() {
	JDCConnection oCon = null;
	
	if (DebugFile.trace) {
	  DebugFile.writeln("Begin Event.run("+getEventId()+")");
	  DebugFile.incIdent();
	}

	log ("Begin Event.run("+getEventId()+")");
	
	if (null==oDbb) {
	  if (DebugFile.trace) {
		DebugFile.writeln("DBBind not initialized for Event");
		DebugFile.decIdent();
	  }
	  log ("DBBind not initialized for Event");
	  throw new IllegalStateException("DBBind not initialized for Event");
	}

	try {
	  if (DebugFile.trace) DebugFile.writeln("Getting JDCConnection from DBBind");
	  oCon = oDbb.getConnection("Event");
	  if (DebugFile.trace) {
		if (oCon!=null) if (oCon.isClosed()) DebugFile.writeln("JDCConnection is closed!");
	  }
	  oCon.setAutoCommit(false);
	  trigger(oCon, null, oDbb.getProperties());
	  oCon.commit();
	  oCon.close("Event");
	  oCon=null;
	} catch (Exception xcpt) {
      log (xcpt.getClass().getName()+" "+xcpt.getMessage());
      if (DebugFile.trace) DebugFile.writeln("Event.run("+getEventId()+") "+xcpt.getClass().getName()+" "+xcpt.getMessage());
      try { if (DebugFile.trace) DebugFile.writeln(StackTraceUtil.getStackTrace(xcpt)); } catch (IOException ignore) {}

      if (oCon!=null) {
    	try {
    	  if (!oCon.isClosed()) {
    	    oCon.rollback();
    	    oCon.close("Event");
    	  }
    	} catch (SQLException sqle) {
    	  if (DebugFile.trace)  DebugFile.writeln("SQLException "+sqle.getMessage());
    	}
      } // if
    }
	
	log ("End Event.run("+getEventId()+")");

	if (DebugFile.trace) {
	  DebugFile.decIdent();
	  DebugFile.writeln("End Event.run()");
    }
  } // run

  // ----------------------------------------------------------
  
  public abstract void trigger (JDCConnection oConn, Map oParameters, Properties oEnvironment)
  	throws Exception;

  // ----------------------------------------------------------

  public String getEventId() {
    return getStringNull(DB.id_event,null);
  }

  // ----------------------------------------------------------

  /**
   * <p>Write Line to Event Log File</p>
   * @param sStr Line to be written
   */
  public void log (String sStr) {
	Date d = new Date();
	File oLogFile = null;
	FileWriter oWriter = null;

    if (sLogDir!=null) {
      try {
        oLogFile = new File(sLogDir+getEventId()+"-"+String.valueOf(d.getYear()+1900)+String.valueOf(d.getMonth()+1)+String.valueOf(d.getDate())+".log");
        oWriter = new FileWriter(oLogFile, true);
        oWriter.write(d.toString()+" "+sStr+"\n");
        oWriter.close();
        oWriter = null;
      }
      catch (IOException ioe) {
        if (null!=oWriter) { try {oWriter.close();} catch (IOException e) {} }
      }
    } // fi (oLogFile)
  } // log

  // ----------------------------------------------------------
  
  protected HashMap<String,String> parseDefaultParameters() throws IllegalArgumentException {
    HashMap<String,String> oParamMap = new HashMap<String,String>();
    String[] aParams = Gadgets.split(getStringNull(DB.tx_parameters,""),";");
	int nParams = aParams.length;
	for (int p=0; p<nParams; p++) {
	  if (aParams[p].indexOf('=')<1) throw new IllegalArgumentException("Event "+getStringNull("id_event","null")+": invalid name-value pair \""+aParams[p]+"\" at tx_parameters");
	  String[] aNameValuePair = Gadgets.split2(aParams[p],'=');
	  if (oParamMap.containsKey(aNameValuePair[0].trim().toLowerCase())) throw new IllegalArgumentException("Event "+getStringNull("id_event","null")+": duplicated parameter name "+aNameValuePair[0]);
	  oParamMap.put(aNameValuePair[0].trim().toLowerCase(),aNameValuePair[1]);	  
	} // next
	return oParamMap;
  } // parseDefaultParameters

  // ----------------------------------------------------------
  
  public static void reset() {
  	oEventsPerDomain = null;
  	oCmmdClasses = null;
  	oEventCache = null;
  }

  // ----------------------------------------------------------
  
/*
  public static Class[] listEventHandlers() {
    throws ClassNotFoundException, IOException {

    final String sPackage = "com.knowgate.scheduler.events";
    final String sPath = sPackage.replace('.', File.separator.charAt(0));
    ClassLoader oClssLdr = Thread.currentThread().getContextClassLoader();

    Enumeration<URL> oRsrcs = oClssLdr.getResources(sPath);
    List<File> oDirs = new ArrayList<File>();
    while (oRsrcs.hasMoreElements()) {
      URL oRsrcs = oRsrcs.nextElement();
      oDirs.add(new File(oRsrcs.getFile()));
    }
    ArrayList<Class> oClss = new ArrayList<Class>();
    for (File f : oDirs) {
            oClss.addAll(findClasses(directory, packageName));
    }
        return oClss.toArray(new Class[oClss.size()]);
  } // listEventHandlers
*/

  // ----------------------------------------------------------
  
  private static void cacheEventsActions(JDCConnection oConn) throws SQLException {
	ResultSet oRSet;
	Statement oStmt;
	@SuppressWarnings("unused")
	int nCmmds = 0;

    if (DebugFile.trace) {
      DebugFile.writeln("Begin cacheEventsActions([JDCConnection])");
      DebugFile.incIdent();
    }
	
    if (null==oCmmdClasses) {
      oStmt = oConn.createStatement(ResultSet.TYPE_FORWARD_ONLY, ResultSet.CONCUR_READ_ONLY);
	  if (DebugFile.trace)
	    DebugFile.writeln("Statement.executeQuery(SELECT "+DB.id_command+","+DB.nm_class+" FROM "+DB.k_lu_job_commands+")");
      oRSet = oStmt.executeQuery("SELECT "+DB.id_command+","+DB.nm_class+" FROM "+DB.k_lu_job_commands);
      oCmmdClasses = new HashMap<String,Class>(113);
      while (oRSet.next()) {
      	if (DebugFile.trace) DebugFile.writeln("Caching "+oRSet.getString(1)+" "+oRSet.getString(2));
        try {
          oCmmdClasses.put(oRSet.getString(1).toLowerCase(), Class.forName(oRSet.getString(2)));  
          nCmmds++;
        } catch (ClassNotFoundException cnfe) {
	      if (DebugFile.trace) DebugFile.writeln("Class "+oRSet.getString(2)+" not found for command "+oRSet.getString(1));
        }
        if (DebugFile.trace) DebugFile.writeln(oRSet.getString(2)+" cached");
      } // wend
      oRSet.close();
      oStmt.close();
      if (DebugFile.trace) DebugFile.writeln(String.valueOf(nCmmds)+" commands found at "+DB.k_lu_job_commands+" table");
    } // fi

    if (null==oEventsPerDomain) {
      if (DebugFile.trace) DebugFile.writeln("cache miss events per domain");
      oEventsPerDomain = new HashMap<Integer,HashMap<String,String>>(113);
      oStmt = oConn.createStatement(ResultSet.TYPE_FORWARD_ONLY, ResultSet.CONCUR_READ_ONLY);
	  if (DebugFile.trace)
	    DebugFile.writeln("Statement.executeQuery(SELECT "+DB.id_domain+","+DB.id_event+","+DB.id_command+" FROM "+DB.k_events+" WHERE "+DB.bo_active+"<>0)");
	  oRSet = oStmt.executeQuery("SELECT "+DB.id_domain+","+DB.id_event+","+DB.id_command+" FROM "+DB.k_events+" WHERE "+DB.bo_active+"<>0");
	  while (oRSet.next()) {
	  	Integer oIdDomain = new Integer(oRSet.getInt(1));
		if (!oEventsPerDomain.containsKey(oIdDomain))
		  oEventsPerDomain.put(oIdDomain, new HashMap<String,String>());
		oEventsPerDomain.get(oIdDomain).put(oRSet.getString(2).toLowerCase(), oRSet.getString(3).toLowerCase());
	  } // wend
      oRSet.close();
      oStmt.close();
    } else {
      if (DebugFile.trace) DebugFile.writeln("cache hit events per domain");
    }// fi (oEventsPerDomain)

    if (DebugFile.trace) {
      DebugFile.decIdent();
      DebugFile.writeln("End cacheEventsActions()");
    }
    
  } // cacheEventsActions

  // ----------------------------------------------------------
  
  public static Event getEvent(JDCConnection oConn, int iDomainId, String sEventId)
  	throws SQLException, InstantiationException, IllegalAccessException, RemoteException, NoSuchMethodException, SecurityException, IllegalArgumentException, InvocationTargetException {

	Integer oIdDomain = new Integer(iDomainId);
	String sIdCmmd = null;
	Event oEvnt = null;
	DBBind oDbb = null;

	if (null==sEventId) throw new NullPointerException("Event.getEvent() event id may not be null");
	
	final String sLCaseEvent = sEventId.toLowerCase();
	
	if (DebugFile.trace) {
	  DebugFile.writeln("Begin Event.getEvent([JDCConnection], "+String.valueOf(iDomainId)+", "+sLCaseEvent+")");
	  DebugFile.incIdent();
	}

	if (oEventsPerDomain==null || oCmmdClasses==null) cacheEventsActions(oConn);

	JDCConnectionPool oPool = oConn.getPool();
	if (null!=oPool) {
	  if (DebugFile.trace) DebugFile.writeln("got JDCConnectionPool"+oPool);
	  if (DebugFile.trace) DebugFile.writeln("DataSource is "+oPool.getDatabaseBinding());
	  oDbb = (DBBind) oPool.getDatabaseBinding();
	  if (DebugFile.trace) DebugFile.writeln("got DataSource");
	}
	
	if (oEventsPerDomain.containsKey(oIdDomain)) {
	  if (oEventsPerDomain.get(oIdDomain).containsKey(sLCaseEvent)) {
	    sIdCmmd = oEventsPerDomain.get(oIdDomain).get(sLCaseEvent);
		if (oCmmdClasses.containsKey(sIdCmmd.toLowerCase())) {
	      Class oEvntClss = (Class) oCmmdClasses.get(sIdCmmd.toLowerCase());

	      if (null!=oEvntClss) {
	        if (null==oEventCache) oEventCache = new DistributedCachePeer();
	        oEvnt = (Event) oEventCache.get(sLCaseEvent+"("+String.valueOf(iDomainId)+")");
	        if (null==oEvnt) {
	          if (DebugFile.trace) DebugFile.writeln("Creating instance of "+oEvntClss.getName());
	  	      if (null==oDbb) {
	  	    	oEvnt = (Event) oEvntClss.newInstance();
	          } else {
		        Constructor<Event> oCnstr = oEvntClss.getConstructor(DBBind.class);
	  	        oEvnt = oCnstr.newInstance(oDbb);
	  	      }
	  	      oEvnt.load(oConn, new Object[]{new Integer(iDomainId), sLCaseEvent});
		      oEventCache.put(sEventId.toLowerCase()+"("+String.valueOf(iDomainId)+")",oEvnt);
	        } else {
	          if (DebugFile.trace) DebugFile.writeln("Event cache hit "+sLCaseEvent+"("+String.valueOf(iDomainId)+")");
	        }
	      } else {
		    if (DebugFile.trace) DebugFile.writeln("Class is null for command "+sIdCmmd+" of event "+sLCaseEvent+" at domain "+String.valueOf(iDomainId));	    
	      }
		} else {
	      if (DebugFile.trace) DebugFile.writeln("Class not found for command "+sIdCmmd+" of event "+sLCaseEvent+" at domain "+String.valueOf(iDomainId));
		}
	  } else {
	    if (DebugFile.trace) DebugFile.writeln("No command assigned to event "+sLCaseEvent+" at domain "+String.valueOf(iDomainId));
	  }
	} else {
	  if (DebugFile.trace) DebugFile.writeln("No event commands found for domain "+String.valueOf(iDomainId));
	}

	if (DebugFile.trace) {
	  DebugFile.decIdent();
	  if (null==oEvnt)
	    DebugFile.writeln("End Event.getEvent() : null");
	  else
	    DebugFile.writeln("End Event.getEvent() : "+oEvnt.getStringNull(DB.id_event,"no event id found!"));
	}

    return oEvnt;
  } // getEvent

  // ----------------------------------------------------------
  
  public static void trigger(JDCConnection oConn, int iDomainId, String sEventId,
                             Map oParameters, Properties oEnvironment)
    throws Exception {
	String sGuWorkArea;
	
	if (DebugFile.trace) {
	  DebugFile.writeln("Begin Event.trigger([JDCConnection], "+String.valueOf(iDomainId)+", "+sEventId.toLowerCase()+")");
	  DebugFile.incIdent();
	}
	
	cacheEventsActions(oConn);
		    		
	Event oEvnt = getEvent(oConn, iDomainId, sEventId);

	if (null!=oEvnt) {
	  if (oParameters.containsKey(DB.gu_workarea))
	    sGuWorkArea = (String) oParameters.get(DB.gu_workarea);
	  else
	    sGuWorkArea = "";
	  if (oEvnt.isNull(DB.gu_workarea) || oEvnt.getStringNull(DB.gu_workarea,"").equals(sGuWorkArea)) {
	    try {
		  oEvnt.trigger(oConn, oParameters, oEnvironment);
	    } catch (Exception xcpt) {
	      if (DebugFile.trace) {
	    	DebugFile.writeln("Event.trigger("+String.valueOf(iDomainId)+", "+sEventId.toLowerCase()+") "+xcpt.getClass().getName()+" "+xcpt.getMessage());
	    	try { DebugFile.writeln(StackTraceUtil.getStackTrace(xcpt)); } catch (IOException ignore) {}
	    	DebugFile.decIdent();
	      }
	      
	    }
	  }
	}

	if (DebugFile.trace) {
	  DebugFile.decIdent();
	  DebugFile.writeln("End Event.trigger()");
	}
	
  } // trigger

}


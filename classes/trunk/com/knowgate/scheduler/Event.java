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

import java.net.URL;

import java.util.List;
import java.util.Map;
import java.util.HashMap;
import java.util.Properties;
import java.util.Enumeration;
import java.util.ArrayList;

import java.sql.SQLException;
import java.sql.PreparedStatement;
import java.sql.Statement;
import java.sql.ResultSet;

import com.knowgate.cache.DistributedCachePeer;
import com.knowgate.dataobjs.DB;
import com.knowgate.dataobjs.DBCommand;
import com.knowgate.dataobjs.DBPersist;
import com.knowgate.misc.Gadgets;
import com.knowgate.debug.DebugFile;
import com.knowgate.jdc.JDCConnection;

/**
 * <p>Abstract superclass for event handlers</p>
 * Classes implementing an event handler must derive from this one and implement the trigger method
 * @author Sergio Montoro Ten
 * @version 5.5
 **/
 
public abstract class Event extends DBPersist {

  private static HashMap<String,Class> oCmmdClasses = null;
  private static HashMap<Integer,HashMap<String,String>> oEventsPerDomain = null;
  private static DistributedCachePeer oEventCache = null;
  
  protected Event() {
	super(DB.k_events, "Event");
  }

  public abstract void trigger (JDCConnection oConn, Map oParameters, Properties oEnvironment)
  	throws Exception;

  public String getEventId() {
    return getStringNull(DB.id_event,null);
  }
  
  protected HashMap<String,String> parseDefaultParameters() throws IllegalArgumentException {
    HashMap<String,String> oParamMap = new HashMap();
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

  public static void reset() {
  	oEventsPerDomain = null;
  	oCmmdClasses = null;
  	oEventCache = null;
  }

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

  public static void trigger(JDCConnection oConn, int iDomainId, String sEventId,
                             Map oParameters, Properties oEnvironment)
    throws Exception {
	ResultSet oRSet;
	String sIdCmmd = null;
	String sGuWorkArea;
	Integer oIdDomain;
	Statement oStmt;
	int nCmmds = 0;
	
	if (DebugFile.trace) {
	  DebugFile.writeln("Begin Event.trigger([JDCConnection], "+String.valueOf(iDomainId)+", "+sEventId.toLowerCase()+")");
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
          oCmmdClasses.put(oRSet.getString(1), Class.forName(oRSet.getString(2)));  
          nCmmds++;
        } catch (ClassNotFoundException cnfe) {
	      if (DebugFile.trace) DebugFile.writeln("Class "+oRSet.getString(2)+" not found for command "+oRSet.getString(1));
        }
        if (DebugFile.trace) DebugFile.writeln(oRSet.getString(2)+" cached");
      } // wend
      oRSet.close();
      oStmt.close();
    } // fi

    if (DebugFile.trace) DebugFile.writeln(String.valueOf(nCmmds)+" commands found at "+DB.k_lu_job_commands+" table");
	    	
    if (null==oEventsPerDomain) {
      oEventsPerDomain = new HashMap<Integer,HashMap<String,String>>(113);
      oStmt = oConn.createStatement(ResultSet.TYPE_FORWARD_ONLY, ResultSet.CONCUR_READ_ONLY);
	  if (DebugFile.trace)
	    DebugFile.writeln("Statement.executeQuery(SELECT "+DB.id_domain+","+DB.id_event+","+DB.id_command+" FROM "+DB.k_events+" WHERE "+DB.bo_active+"<>0)");
	  oRSet = oStmt.executeQuery("SELECT "+DB.id_domain+","+DB.id_event+","+DB.id_command+" FROM "+DB.k_events+" WHERE "+DB.bo_active+"<>0");
	  while (oRSet.next()) {
	  	oIdDomain = new Integer(oRSet.getInt(1));
		if (!oEventsPerDomain.containsKey(oIdDomain))
		  oEventsPerDomain.put(oIdDomain, new HashMap<String,String>());
		oEventsPerDomain.get(oIdDomain).put(oRSet.getString(2), oRSet.getString(3));
	  } // wend
      oRSet.close();
      oStmt.close();
    } // fi (oEventsPerDomain)
	
	oIdDomain = new Integer(iDomainId);
	if (oEventsPerDomain.containsKey(oIdDomain)) {
	  if (oEventsPerDomain.get(oIdDomain).containsKey(sEventId.toLowerCase())) {
	    sIdCmmd = oEventsPerDomain.get(oIdDomain).get(sEventId.toLowerCase());
		if (oCmmdClasses.containsKey(sIdCmmd)) {
	      Class oEvntClss = (Class) oCmmdClasses.get(sIdCmmd);

	      if (null!=oEvntClss) {
	        if (null==oEventCache) oEventCache = new DistributedCachePeer();
	        Event oEvnt = (Event) oEventCache.get(sEventId.toLowerCase()+"("+String.valueOf(iDomainId)+")");
	        if ((null==oEvnt)) {
	          if (DebugFile.trace) DebugFile.writeln("Creating instance of "+oEvntClss.getName());
	  	      oEvnt = (Event) oEvntClss.newInstance();
	          oEvnt.load(oConn, new Object[]{new Integer(iDomainId), sEventId.toLowerCase()});
		      oEventCache.put(sEventId.toLowerCase()+"("+String.valueOf(iDomainId)+")",oEvnt);
	        } // fi
	        if (oParameters.containsKey(DB.gu_workarea))
	          sGuWorkArea = (String) oParameters.get(DB.gu_workarea);
	        else
	          sGuWorkArea = "";
	        if (oEvnt.isNull(DB.gu_workarea) || oEvnt.getStringNull(DB.gu_workarea,"").equals(sGuWorkArea)) {
	          oEvnt.trigger(oConn, oParameters, oEnvironment);
	        }
	      } // fi (null!=sEvntClss)
		} else {
	      if (DebugFile.trace) DebugFile.writeln("Class not found for command "+sIdCmmd+" of event "+sEventId.toLowerCase()+" for domain "+String.valueOf(iDomainId));
		}
	  } else {
	    if (DebugFile.trace) DebugFile.writeln("No command assigned to event "+sEventId.toLowerCase()+" for domain "+String.valueOf(iDomainId));
	  }
	} else {
	  if (DebugFile.trace) DebugFile.writeln("No event commands found for domain "+String.valueOf(iDomainId));
	}

	if (DebugFile.trace) {
	  DebugFile.decIdent();
	  DebugFile.writeln("End Event.trigger()");
	}
	
  } // trigger

}


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

import java.util.HashMap;
import java.util.Map;
import java.util.Properties;

import java.sql.SQLException;
import java.sql.PreparedStatement;
import java.sql.Statement;
import java.sql.ResultSet;

import com.knowgate.cache.DistributedCachePeer;
import com.knowgate.dataobjs.DB;
import com.knowgate.dataobjs.DBCommand;
import com.knowgate.dataobjs.DBPersist;
import com.knowgate.misc.Gadgets;

import com.knowgate.jdc.JDCConnection;

/**
 * <p>Abstract superclass for event handlers</p>
 * Classes implementing an event handler must derive from this one and implement the trigger method
 * @author Sergio Montoro Ten
 * @version 4.0
 **/
 
public abstract class Event extends DBPersist {

  private static HashMap oCmmdClasses = null;
  private static DistributedCachePeer oEventCache = null;
  
  protected Event() {
	super(DB.k_events, "Event");
  }

  public abstract void trigger (JDCConnection oConn, Map oParameters, Properties oEnvironment)
  	throws Exception;

  protected HashMap parseDefaultParameters() throws IllegalArgumentException {
    HashMap oParamMap = new HashMap();
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

  public static void trigger(JDCConnection oConn, int iDomainId, String sEventId,
                             Map oParameters, Properties oEnvironment)
    throws Exception {
	ResultSet oRSet;
	String sIdCmmd = null;
	
    if (null==oCmmdClasses) {
      Statement oStmt = oConn.createStatement(ResultSet.TYPE_FORWARD_ONLY, ResultSet.CONCUR_READ_ONLY);
      oRSet = oStmt.executeQuery("SELECT "+DB.id_command+","+DB.nm_class+" FROM "+DB.k_lu_job_commands);
      oCmmdClasses = new HashMap(27);
      while (oRSet.next()) {
        oCmmdClasses.put(oRSet.getString(1),oRSet.getString(2));  
      } // wend
      oRSet.close();
      oStmt.close();
    } // fi
    
	PreparedStatement oPtmt = oConn.prepareStatement("SELECT "+DB.id_command+" FROM "+DB.k_events+" WHERE id_domain=? AND id_event=?",
													 ResultSet.TYPE_FORWARD_ONLY, ResultSet.CONCUR_READ_ONLY);
	oPtmt.setInt(1, iDomainId);
	oPtmt.setString(2, sEventId);
	oRSet = oPtmt.executeQuery();
	if (oRSet.next()) sIdCmmd = oRSet.getString(1);
	oRSet.close();
	oPtmt.close();
	
	if (null==sIdCmmd) throw new SQLException("Event "+sEventId+"("+String.valueOf(iDomainId)+") not found at "+DB.k_events+" table", "01S06", 200);

	String sEvntClss = (String) oCmmdClasses.get(sIdCmmd);

	if (null!=sEvntClss) {
	    if (null==oEventCache) oEventCache = new DistributedCachePeer();
	    Event oEvnt = (Event) oEventCache.get(sEventId+"("+String.valueOf(iDomainId)+")");
	    if ((null==oEvnt)) {
	  	  oEvnt = (Event) Class.forName(sEvntClss).newInstance();
	      oEvnt.load(oConn, new Object[]{new Integer(iDomainId), sEventId});
		  oEventCache.put(sEventId+"("+String.valueOf(iDomainId)+")",oEvnt);
	    } // fi
	  oEvnt.trigger(oConn, oParameters, oEnvironment);
	} // fi
	
  } // trigger

}


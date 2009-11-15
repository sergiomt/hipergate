<%@ page import="java.util.Date,java.sql.PreparedStatement,java.sql.ResultSet,java.sql.Timestamp,java.sql.Types,java.sql.SQLException,com.knowgate.jdc.JDCConnection,com.knowgate.dataobjs.*,com.knowgate.misc.Gadgets" language="java" session="false" contentType="text/plain;charset=UTF-8" %><%@ include file="../methods/dbbind.jsp" %><%@ include file="../methods/clientip.jspf" %><jsp:useBean id="GlobalCacheClient" scope="application" class="com.knowgate.cache.DistributedCachePeer"/><% 
/*
  Copyright (C) 2009  Know Gate S.L. All rights reserved.
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

  String sBeaconId = request.getParameter("id_webbeacon");
  int iBeaconId = 0;
  if (null!=sBeaconId) iBeaconId = Integer.parseInt(sBeaconId);

  String sUserId = request.getParameter("gu_user");

  String sContactId = request.getParameter("gu_contact");

  String sObjectId = request.getParameter("gu_object");
  
  String sPageId = request.getParameter("id_page");

  int iPageId = -1;
  if (null!=sPageId) iPageId = Integer.parseInt(sPageId);
  
  String sPageUrl = request.getParameter("url_page");
  if (null!=sPageUrl) {
    if (sPageUrl.indexOf('?')>0) sPageUrl=Gadgets.substrUpTo(sPageUrl, 0, '?');
    if (sPageUrl.length()>254) sPageUrl=Gadgets.left(sPageUrl, 254);
  }

  String sReferrerId = request.getParameter("id_referrer");

  int iReferrerId = -1;
  if (null!=sReferrerId) iReferrerId = Integer.parseInt(sReferrerId);

  String sReferrerUrl = request.getParameter("url_referrer");
  if (null!=sReferrerUrl) {
    if (sReferrerUrl.indexOf('?')>0) sReferrerUrl=Gadgets.substrUpTo(sReferrerUrl, 0, '?');
    if (sReferrerUrl.length()>254) sReferrerUrl=Gadgets.left(sReferrerUrl, 254);
  }

  JDCConnection oConn = null;  
  PreparedStatement oStmt;
  ResultSet oRSet;
  boolean bExists;

  Timestamp tsNow = new Timestamp(new Date().getTime());

  try {
    oConn = GlobalDBBind.getConnection("webbeacon_hit");

    oConn.setAutoCommit(true);

		if (null==sBeaconId) {
		  if (sUserId!=null) {
		    Integer oBeaconId = DBCommand.queryInt(oConn, "SELECT id_webbeacon FROM k_webbeacons WHERE gu_user='"+sUserId+"'");
		    if (null!=oBeaconId) {
		      iBeaconId = oBeaconId.intValue();
		      sBeaconId = String.valueOf(iBeaconId);
		    }
		  }
		} else {
		  if (!DBCommand.queryExists(oConn, "k_webbeacons", "id_webbeacon='"+sBeaconId+"'")) {
		    sBeaconId = null;
		    iBeaconId = 0;
		  }	
		}

    if (null==sBeaconId) {
      iBeaconId = DBBind.nextVal(oConn, "seq_k_webbeacons");
      oStmt = oConn.prepareStatement("INSERT INTO k_webbeacons(id_webbeacon,dt_created,dt_last_visit,nu_pages,gu_user,gu_contact) VALUES (?,?,?,1,?,?)");
		  oStmt.setInt 	(1, iBeaconId);
		  oStmt.setTimestamp(2, tsNow);
		  oStmt.setTimestamp(3, tsNow);
			if (null==sUserId)
		    oStmt.setNull(4, Types.CHAR);
		  else
		    oStmt.setString(4, sUserId);
			if (null==sContactId)
		    oStmt.setNull(5, Types.CHAR);
		  else
		    oStmt.setString(5, sContactId);
			oStmt.executeUpdate();
			oStmt.close();
    } else {
    	if (request.getParameter("id_webbeacon")!=null) {
    	  if (request.getParameter("gu_user")!=null) {
          String sPrevUserId = null;
          oStmt = oConn.prepareStatement("SELECT gu_user FROM k_webbeacons WHERE id_webbeacon=?");
				  oStmt.setInt(1, iBeaconId);
				  oRSet = oStmt.executeQuery();
          if (oRSet.next())
            sPrevUserId = oRSet.getString(1);
          oRSet.close();
          oStmt.close();
          if (sPrevUserId!=null) {
            if (!sUserId.equals(sPrevUserId)) {
      	      iBeaconId = DBBind.nextVal(oConn, "seq_k_webbeacons");
      		    oStmt = oConn.prepareStatement("INSERT INTO k_webbeacons(id_webbeacon,dt_created,dt_last_visit,nu_pages,gu_user,gu_contact) VALUES (?,?,?,1,?,?)");
		  		    oStmt.setInt  (1, iBeaconId);
		  		    oStmt.setTimestamp(2, tsNow);
		  		    oStmt.setTimestamp(3, tsNow);
		          oStmt.setString   (4, sUserId);
			        if (null==sContactId)
		            oStmt.setNull(5, Types.CHAR);
		          else
		            oStmt.setString(5, sContactId);
			        oStmt.executeUpdate();
			        oStmt.close();
            } // fi
          } else {
            DBCommand.executeUpdate(oConn, "UPDATE k_webbeacons SET gu_user='"+request.getParameter("gu_user")+"' WHERE id_webbeacon="+request.getParameter("id_webbeacon"));
          }
        } // fi
      } // fi
    } // fi

    if (null==sPageId) {
      Integer oPageId = GlobalCacheClient.getInteger("WebBeacon["+sPageUrl+"]");
      if (null==oPageId) {
        oStmt = oConn.prepareStatement("SELECT id_page FROM k_webbeacon_pages WHERE url_page=?");
        oStmt.setString(1, sPageUrl);
        oRSet = oStmt.executeQuery();
        bExists = oRSet.next();
        if (bExists) {
          iPageId = oRSet.getInt(1);
          oPageId = new Integer(iPageId);
        }
        oRSet.close();
        oStmt.close();
        if (!bExists) {
				  oPageId = DBCommand.queryMaxInt(oConn, "id_page", "k_webbeacon_pages", null);
				  if (null==oPageId) oPageId = new Integer(0);
				  iPageId = oPageId.intValue()+1;
          oStmt = oConn.prepareStatement("INSERT INTO k_webbeacon_pages (id_page,nu_hits,gu_object,url_page) VALUES (?,0,?,?)");
          oStmt.setInt(1, iPageId);
          if (sObjectId==null)
            oStmt.setNull(2, Types.CHAR);
          else
            oStmt.setString(2, sObjectId);
          oStmt.setString(3, sPageUrl);
          oStmt.executeUpdate();
          oStmt.close();
        } // fi
        GlobalCacheClient.put("WebBeacon["+sPageUrl+"]", new Integer(iPageId));
      } else {
        iPageId = oPageId.intValue();
      }
    } // fi

    if (null==sReferrerId && sReferrerUrl!=null) {
      Integer oReferrerId = GlobalCacheClient.getInteger("WebBeacon["+sReferrerUrl+"]");
      if (null==oReferrerId) {
        oStmt = oConn.prepareStatement("SELECT id_page FROM k_webbeacon_pages WHERE url_page=?");
        oStmt.setString(1, sReferrerUrl);
        oRSet = oStmt.executeQuery();
        bExists = oRSet.next();
        if (bExists) {
          iReferrerId = oRSet.getInt(1);
          oReferrerId = new Integer(iReferrerId);
        }
        oRSet.close();
        oStmt.close();
        if (!bExists) {
				  oReferrerId = DBCommand.queryMaxInt(oConn, "id_page", "k_webbeacon_pages", null);
				  if (null==oReferrerId) oReferrerId = new Integer(0);
          iReferrerId = oReferrerId.intValue()+1;
          oStmt = oConn.prepareStatement("INSERT INTO k_webbeacon_pages (id_page,nu_hits,gu_object,url_page) VALUES (?,0,?,?)");
          oStmt.setInt(1, iReferrerId);
          if (sObjectId==null)
            oStmt.setNull(2, Types.CHAR);
          else
            oStmt.setString(2, sObjectId);
          oStmt.setString(3, sReferrerUrl);
          oStmt.executeUpdate();
          oStmt.close();
        } // fi
        GlobalCacheClient.put("WebBeacon["+sReferrerUrl+"]", new Integer(iReferrerId));
      } else {
        iReferrerId = oReferrerId.intValue();
      }
    } // fi

    oStmt = oConn.prepareStatement("INSERT INTO k_webbeacon_hit (id_webbeacon,id_page,id_referrer,dt_hit,ip_addr) VALUES (?,?,?,?,?)");
    oStmt.setInt(1,iBeaconId); 
    oStmt.setInt(2,iPageId);
    if (iReferrerId==-1)
      oStmt.setNull(3,Types.INTEGER); 
    else
      oStmt.setInt(3,iReferrerId); 
    oStmt.setTimestamp(4,tsNow);
    oStmt.setInt(5,getClientIP(request)); 
		oStmt.executeUpdate();
		oStmt.close();

		DBCommand.executeUpdate("UPDATE k_webbeacons SET nu_pages=nu_pages+1 WHERE id_webbeacon="+String.valueOf(iBeaconId));
		DBCommand.executeUpdate("UPDATE k_webbeacon_pages SET nu_hits=nu_hits+1 WHERE id_page="+String.valueOf(iPageId));

    oConn.close("webbeacon_hit");

		out.write("OK|"+String.valueOf(iBeaconId));
  }
  catch (Exception e) {
    if (oConn!=null)
      if (!oConn.isClosed()) {
        oConn.close("webbeacon_hit");
      }
    oConn = null;
		out.write("ERROR|"+e.getClass().getName()+" "+e.getMessage());
  }
%>
<%@ page import="java.io.IOException,java.net.URLDecoder,java.sql.PreparedStatement,java.sql.ResultSet,java.sql.SQLException,com.knowgate.jdc.JDCConnection,com.knowgate.dataobjs.*,com.knowgate.acl.*,com.knowgate.crm.ListMember,com.knowgate.misc.CSVParser,com.knowgate.misc.Gadgets" language="java" session="false" contentType="text/html;charset=UTF-8" %>
<%@ include file="../methods/dbbind.jsp" %><%@ include file="../methods/cookies.jspf" %><%@ include file="../methods/authusrs.jspf" %><%@ include file="../methods/nullif.jspf" %><% 
/*
  Copyright (C) 2003  Know Gate S.L. All rights reserved.
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

  /* Autenticate user cookie */
  
  if (autenticateSession(GlobalDBBind, request, response)<0) return;
      
  String gu_workarea = request.getParameter("gu_workarea");
  String gu_member = request.getParameter("gu_member");
  String full_name = "";
  
  String sOldSettings = request.getParameter("old_settings").replace(';','\n');
  String sNewSettings = request.getParameter("new_settings").replace(';','\n');
  String sDescriptor  = "guid,member,active,blocked";
  
  CSVParser oOldSets = new CSVParser();
  CSVParser oNewSets = new CSVParser();

  oOldSets.parseData (sOldSettings.toCharArray(), sDescriptor);
  oNewSets.parseData (sNewSettings.toCharArray(), sDescriptor);
  
  int iLines = oNewSets.getLineCount();
  
  String sOld, sNew;
  
  ListMember oOptOut, oOptIn;

  JDCConnection oConn = null;  
  PreparedStatement oStmt;
  ResultSet oRSet;
        
  try {
    oConn = GlobalDBBind.getConnection("subscriptions_store");

    oStmt = oConn.prepareStatement("SELECT " + DB.tx_email + "," + DB.tx_name + "," + DB.tx_surname + "," + DB.tx_salutation + " FROM " + DB.k_member_address + " WHERE " + DB.gu_contact + "=? OR " + DB.gu_company + "=?", ResultSet.TYPE_FORWARD_ONLY, ResultSet.CONCUR_READ_ONLY);
    oStmt.setString(1, gu_member);
    oStmt.setString(2, gu_member);
    oRSet = oStmt.executeQuery();
    if (oRSet.next()) {
    
      full_name = nullif(oRSet.getString(2)) + " " + nullif(oRSet.getString(3));
      
      oOptIn = new ListMember();
      oOptIn.put (DB.gu_member, gu_member);
      oOptIn.put (DB.gu_workarea, gu_workarea);
      oOptIn.put (DB.tx_email, oRSet.getObject(1));
      oOptIn.put (DB.tx_name, oRSet.getObject(2));
      oOptIn.put (DB.tx_surname, oRSet.getObject(3));
      oOptIn.put (DB.tx_salutation, oRSet.getObject(4));
    }
    else
      oOptIn = null;
      
    oRSet.close();
    oStmt.close();
    
    if (null==oOptIn) {

      for (int l=0; l<iLines; l++) {

        if (oOldSets.getField(1,l).equals("0") && oOldSets.getField(1,l).equals("1"))

          throw new IllegalStateException ("It is not possible to add member to this list because he does not have any associated address");
      }
    }

    oConn.setAutoCommit (false);
    
    for (int l=0; l<iLines; l++) {

      sOld = oOldSets.getField(1,l);
      sNew = oNewSets.getField(1,l);
      
      if (sOld.equals("1") && sNew.equals("0")) {

        oOptOut = new ListMember(oConn, gu_member, oOldSets.getField(0,l));
        oOptOut.delete(oConn, oOldSets.getField(0,l));
        oOptOut = null;

      }
      else if (sOld.equals("0") && sNew.equals("1")) {

	    oOptIn.store (oConn, oNewSets.getField(0,l));	
      }
      
      // If Member belongs to List...
      
      if (sNew.equals("1")) {
        
        // Activate/Deactivate Member from List

	if (!oOldSets.getField(2,l).equals(oNewSets.getField(2,l))) {

          oStmt = oConn.prepareStatement("UPDATE " + DB.k_x_list_members + " SET " + DB.bo_active + "=? WHERE " + DB.gu_list + "=? AND " + DB.tx_email + "=?");

	  if (oNewSets.getField(2,l).equals("0"))
	    oStmt.setShort(1, (short) 0);
	  else
	    oStmt.setShort(1, (short) 1);
	
	  oStmt.setString(2, oNewSets.getField(0,l));
	  oStmt.setString(3, oOptIn.getString(DB.tx_email));
	
	  oStmt.executeUpdate();
	  oStmt.close();
        }
        
	if (!oOldSets.getField(3,l).equals(oNewSets.getField(3,l))) {
        
          // Block/Unblock Member at Black List
	
	  if (oNewSets.getField(3,l).equals("1"))
	    oOptIn.block (oConn, oNewSets.getField(0,l));	
	  else
	    oOptIn.unblock (oConn, oNewSets.getField(0,l));	
	}
		
      } // fi (member==1)
            
    } // next()
    
    oConn.commit();
           
    oConn.close("subscriptions_store");
  }
  catch (IllegalStateException e) {  
    if (oConn!=null)
      if (!oConn.isClosed()) {
        oConn.close("subscriptions_store");
      }
    oConn = null;
    response.sendRedirect (response.encodeRedirectUrl ("../common/errmsg.jsp?title=Address not Found&desc=" + e.getMessage() + "&resume=_back"));
  }
  catch (NoSuchFieldException e) {  
    disposeConnection(oConn,"subscriptions_store");
    oConn = null;
    response.sendRedirect (response.encodeRedirectUrl ("../common/errmsg.jsp?title=NoSuchFieldException&desc=" + e.getMessage() + "&resume=_back"));
  }
  catch (SQLException e) {  
    disposeConnection(oConn,"subscriptions_store");
    oConn = null;
    response.sendRedirect (response.encodeRedirectUrl ("../common/errmsg.jsp?title=SQLException&desc=" + e.getMessage() + "&resume=_back"));
  }
  
  if (null==oConn) return;
    
  oConn = null;

  response.sendRedirect (response.encodeRedirectUrl ("subscriptions_listing.jsp?gu_workarea=" + gu_workarea + "&gu_contact=" + gu_member + "&full_name=" + Gadgets.URLEncode(full_name)));

%>

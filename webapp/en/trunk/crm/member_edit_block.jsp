<%@ page import="java.util.*,java.io.IOException,java.net.URLDecoder,java.sql.*,com.knowgate.jdc.*,com.knowgate.dataobjs.*,com.knowgate.acl.*,com.knowgate.hipergate.*,com.knowgate.misc.Gadgets,com.knowgate.crm.*" language="java" session="false" contentType="text/html;charset=UTF-8" %>
<%@ include file="../methods/dbbind.jsp" %>
<%@ include file="../methods/cookies.jspf" %>
<%@ include file="../methods/authusrs.jspf" %>
<%@ include file="../methods/clientip.jspf" %>
<%@ include file="../methods/nullif.jspf" %>
<%
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

  if (autenticateSession(GlobalDBBind, request, response)<0) return;
  
  String id_user = getCookie (request, "userid", null);
  String gu_workarea = request.getParameter("gu_workarea");
  String gu_list = request.getParameter("gu_list");
  String de_list = request.getParameter("de_list");
  String gu_black, gu_company, gu_contact;
  String a_items[] = Gadgets.split(request.getParameter("checkeditems"), ',');
  
  PreparedStatement oStm;
  ResultSet oRSet;
  DistributionList oLst;
  ListMember oMbr;
     
  JDCConnection oCon = GlobalDBBind.getConnection("listmember_delete");
  
  try {
    
    // ************************************************
    // Obtener la lista asociada de miembros bloqueados
    
    oLst = new DistributionList(oCon, gu_list);
    gu_black = oLst.blackList(oCon);

    if (gu_black==null) {

        // *****************************************************
        // [~//Si no existe la lista de usuarios bloqueados, crearla~]
    
        oLst = new DistributionList();
        
        oLst.put(DB.gu_workarea, gu_workarea);
        oLst.put(DB.tp_list, DistributionList.TYPE_BLACK);
        oLst.put(DB.gu_query, gu_list);
        oLst.put(DB.de_list, nullif(request.getParameter("de_list"),"black list"));

	oLst.store(oCon);
	
	gu_black = oLst.getString(DB.gu_list);
    }

    oCon.setAutoCommit (false);
    
    oStm = oCon.prepareStatement("SELECT " + DB.gu_company + "," + DB.gu_contact + " FROM " + DB.k_x_list_members + " WHERE " + DB.gu_list + "='" + gu_list + "' AND " + DB.tx_email + "=?", ResultSet.TYPE_FORWARD_ONLY, ResultSet.CONCUR_READ_ONLY);

    oMbr = new ListMember();
    oMbr.put(DB.gu_list, gu_black);
    oMbr.put(DB.bo_active, (short)1);
    oMbr.put(DB.tp_member, ListMember.ClassId);
    oMbr.put(DB.id_format, "NIL");

    for (int i=0;i<a_items.length;i++) {
        
      oStm.setString(1, a_items[i]);

      oRSet = oStm.executeQuery();
      if (oRSet.next()) {                
        oMbr.replace(DB.tx_email, a_items[i]);
        oMbr.replace(DB.gu_company, oRSet.getObject(1));
        oMbr.replace(DB.gu_contact, oRSet.getObject(2));
	oMbr.store(oCon, gu_black);
      }
      oRSet.close();

    } // next ()
    
    oStm.close();
    oCon.commit();
    oCon.close("listmember_delete");
  } 
  catch(SQLException e) {
      disposeConnection(oCon,"listmember_delete");
      oCon = null;
      response.sendRedirect (response.encodeRedirectUrl ("../common/errmsg.jsp?title=Error&desc=" + e.getLocalizedMessage() + "&resume=_close"));
    }
  
  if (null==oCon) return;
    
  oCon = null; 

  out.write("<HTML><HEAD><TITLE>Wait...</TITLE><" + "SCRIPT LANGUAGE='JavaScript' TYPE='text/javascript'>window.document.location='member_listing.jsp?selected=" + request.getParameter("selected") + "&subselected=" + request.getParameter("subselected") + "&gu_list=" + gu_list + "&de_list=" + de_list + "'<" + "/SCRIPT" +"></HEAD></HTML>"); 
%>
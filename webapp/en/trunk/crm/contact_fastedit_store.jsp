<%@ page import="java.io.IOException,java.net.URLDecoder,java.sql.SQLException,com.knowgate.jdc.JDCConnection,com.knowgate.dataobjs.*,com.knowgate.acl.*,com.knowgate.crm.ContactLoader,com.knowgate.crm.OportunityLoader,com.knowgate.marketing.ActivityAudienceLoader,com.knowgate.misc.Gadgets" language="java" session="false" contentType="text/html;charset=UTF-8" %>
<%@ include file="../methods/dbbind.jsp" %><%@ include file="../methods/cookies.jspf" %><%@ include file="../methods/authusrs.jspf" %><%@ include file="../methods/clientip.jspf" %><%@ include file="../methods/reqload.jspf" %><%@ include file="../methods/nullif.jspf" %><%
/*
  Copyright (C) 2003-2005  Know Gate S.L. All rights reserved.
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
      
  String id_user = getCookie (request, "userid", null);
  String gu_workarea = request.getParameter("gu_workarea");
  
  int iMode, iFlags ;
  if (request.getParameter("id_mode").equals("append"))
    iMode = ContactLoader.MODE_APPEND;
  else if (request.getParameter("id_mode").equals("appendupdate"))
    iMode = ContactLoader.MODE_APPENDUPDATE;
  else {
    response.sendRedirect (response.encodeRedirectUrl ("../common/errmsg.jsp?title=IllegalArgumentException&desc=Insert or update mode not valid&resume=_back"));  
    return;
  }

  final int iDefaultFlags = iMode|ContactLoader.WRITE_CONTACTS|(nullif(request.getParameter("chk_dup_names")).equals("1") ? ContactLoader.NO_DUPLICATED_NAMES : 0)|(nullif(request.getParameter("chk_dup_emails")).equals("1") ? ContactLoader.NO_DUPLICATED_MAILS : 0);

  int r=0;
  String s, v;
  int nStored = 0;
  int nRows = Integer.parseInt(request.getParameter("nu_rows"));
  String[] aDesc = Gadgets.split(request.getParameter("tx_descriptor"), new char[]{'\t','|',',',';'});
  int iDesc = aDesc.length;
  String[] aCampaignActivity = new String[]{"",""};
  String sReturnTo;
  ContactLoader oLoader = null;
  OportunityLoader oOprts = null;
  ActivityAudienceLoader oActAud = null;
  JDCConnection oConn = null;

  String sCampaignActivity = nullif(request.getParameter("sel_activity"));
	if (sCampaignActivity.length()>0) {
	  aCampaignActivity = Gadgets.split2(sCampaignActivity,',');	
	}

  try {
    oConn = GlobalDBBind.getConnection("contact_fastedit_store"); 
  
    oLoader = new ContactLoader(oConn);
  
  	oOprts = new OportunityLoader();
		oOprts.prepare(oConn,null);
		
		oActAud = new ActivityAudienceLoader();
		oActAud.prepare(oConn,null);

    oConn.setAutoCommit (false);
  
    while (r<nRows) {
      s = String.valueOf(r);
      if (request.getParameter("tx_name"+s).length()>0 || request.getParameter("tx_surname"+s).length()>0) {
        for (int c=0; c<iDesc; c++) {
          v = request.getParameter(aDesc[c]+s);
          if (null!=v)
            if (v.length()>0) {
              int iColIndex = oLoader.getColumnIndex(aDesc[c]);
              if (iColIndex>0) oLoader.put(iColIndex, v);              
            }
        } // next (c)
        
        iFlags = iDefaultFlags;        
        if (nullif(request.getParameter("nm_legal"+s)).length()>0)
	        iFlags |= ContactLoader.WRITE_COMPANIES;
        if (nullif(request.getParameter("nm_street"+s)).length()>0 || nullif(request.getParameter("zipcode"+s)).length()>0 || nullif(request.getParameter("id_country"+s)).length()>0 || nullif(request.getParameter("direct_phone"+s)).length()>0 || nullif(request.getParameter("tx_email"+s)).length()>0)
	        iFlags |= ContactLoader.WRITE_ADDRESSES;

        oLoader.store(oConn, gu_workarea, iFlags);

				if (oLoader.get(ContactLoader.gu_contact)==null)
				  throw new SQLException("gu_contact ("+String.valueOf(ContactLoader.gu_contact)+") is null after store");
				if (oLoader.get(ContactLoader.gu_address)==null)
				  throw new SQLException("gu_address ("+String.valueOf(ContactLoader.gu_address)+") is null after store");

				if (aCampaignActivity[1].length()>0) {
				  oActAud.put(ActivityAudienceLoader.gu_writer, id_user);
				  oActAud.put(ActivityAudienceLoader.gu_activity, aCampaignActivity[1]);
				  oActAud.put(ActivityAudienceLoader.bo_confirmed, new Short((short)1));
				  oActAud.put(ActivityAudienceLoader.bo_went, new Short((short)1));
				  oActAud.put(ActivityAudienceLoader.bo_allows_ads, new Short((short)1));
				  oActAud.put(ActivityAudienceLoader.bo_paid, new Short((short)0));
				  oActAud.put("gu_contact", oLoader.get(ContactLoader.gu_contact));
				  oActAud.put("gu_address", oLoader.get(ContactLoader.gu_address));
          if (nullif(request.getParameter("tp_origin")).length()>0) oActAud.put(ActivityAudienceLoader.tp_origin, request.getParameter("tp_origin"));
          oActAud.store(oConn, gu_workarea, ActivityAudienceLoader.MODE_APPEND|ActivityAudienceLoader.NO_DUPLICATED_MAILS);
        }
				  
        if (nullif(request.getParameter("id_objetive"+s)).length()>0) {
          oOprts.put(OportunityLoader.gu_contact, oLoader.get(ContactLoader.gu_contact));
          oOprts.put(OportunityLoader.gu_workarea, gu_workarea);
          oOprts.put(OportunityLoader.gu_writer, id_user);
          oOprts.put(OportunityLoader.bo_private, (short) 0);
          oOprts.put(OportunityLoader.id_objetive, request.getParameter("id_objetive"+s));
          oOprts.put(OportunityLoader.tx_contact, Gadgets.left(request.getParameter("tx_name"+s)+" "+request.getParameter("tx_surname"+s),200));
          oOprts.put(OportunityLoader.tl_oportunity, Gadgets.left(request.getParameter("id_objetive"+s)+" "+request.getParameter("tx_name"+s)+" "+request.getParameter("tx_surname"+s),128));
          if (aCampaignActivity[0].length()>0) oOprts.put(OportunityLoader.gu_campaign, aCampaignActivity[0]);
          if (nullif(request.getParameter("tp_origin")).length()>0) oOprts.put(OportunityLoader.tp_origin, request.getParameter("tp_origin"));
          oOprts.store(oConn, gu_workarea, OportunityLoader.MODE_APPEND);
        }
        
				nStored++;

				oActAud.setAllColumnsToNull();
        oOprts.setAllColumnsToNull();
        oLoader.setAllColumnsToNull();
      } // fi (tx_name!="" || tx_surname!="")
      r++;
    } // wend

		oActAud.close();
  	oOprts.close();
    oLoader.close();

    oConn.commit();
    oConn.close("contact_fastedit_store");
  }
  /*
  catch (SQLException e) {  
    disposeConnection(oConn,"contact_fastedit_store");
    oConn = null;
    response.sendRedirect (response.encodeRedirectUrl ("../common/errmsg.jsp?title=SQLException&desc=Row " + String.valueOf(r+1) + " " + e.getLocalizedMessage() + "&resume=_back"));
  }
  catch (IllegalArgumentException e) {  
    disposeConnection(oConn,"contact_fastedit_store");
    oConn = null;
    response.sendRedirect (response.encodeRedirectUrl ("../common/errmsg.jsp?title=IllegalArgumentException&desc=Row " + String.valueOf(r+1) + " " + e.getMessage() + "&resume=_back"));
  }
  catch (ArrayIndexOutOfBoundsException e) {  
    disposeConnection(oConn,"contact_fastedit_store");
    oConn = null;
    response.sendRedirect (response.encodeRedirectUrl ("../common/errmsg.jsp?title=ArrayIndexOutOfBoundsException&desc=Row " + String.valueOf(r+1) + " " + e.getMessage() + "&resume=_back"));
  }
  */
  catch (NullPointerException e) {  
    disposeConnection(oConn,"contact_fastedit_store");
    oConn = null;
    response.sendRedirect (response.encodeRedirectUrl ("../common/errmsg.jsp?title=NullPointerException&desc=Row " + String.valueOf(r+1) + e.getMessage() + "&resume=_back"));
  }
  catch (ClassCastException e) {  
    disposeConnection(oConn,"contact_fastedit_store");
    oConn = null;
    response.sendRedirect (response.encodeRedirectUrl ("../common/errmsg.jsp?title=ClassCastException&desc=Row " + String.valueOf(r+1) + e.getMessage() + "&resume=_back"));
  }
  if (null==oConn) return;  
  oConn = null;

%>
<HTML>
<HEAD>
  <META HTTP-EQUIV="Content-Type" CONTENT="text/html; charset=UTF-8">
  <SCRIPT TYPE="text/javascript" SRC="../javascript/cookies.js"></SCRIPT>  
  <SCRIPT TYPE="text/javascript" SRC="../javascript/setskin.js"></SCRIPT>
</HEAD>
<BODY TOPMARGIN="32" MARGINHEIGHT="32">
  <TABLE ALIGN="CENTER" WIDTH="90%" BGCOLOR="#000080">
    <TR><TD>
      <FONT FACE="Arial,Helvetica,sans-serif" COLOR="white" SIZE="2"><B><% out.write("Operation Completed"); %></B></FONT>
    </TD></TR>
    <TR><TD>
      <TABLE WIDTH="100%" BGCOLOR="#FFFFFF">
        <TR><TD>
          <TABLE BGCOLOR="#FFFFFF" BORDER="0" CELLSPACING="8" CELLPADDING="8">
            <TR VALIGN="middle">
              <TD><IMG SRC="../images/images/chequeredflag.gif" WIDTH="40" HEIGHT="38" BORDER="0" ALT="Chequered Flag"></TD>
              <TD><FONT CLASS="textplain"><% out.write(String.valueOf(nStored)+" Rows successfully saved"); %></FONT></TD>
	    </TR>
	  </TABLE>
        </TD></TR>
        <TR><TD ALIGN="center">
          <FORM>
          	<BR/>
            <INPUT TYPE="button" CLASS="pushbutton" VALUE="Back" onclick="window.location='<%=request.getHeader("referer")%>'">
          </FORM>
        </TD></TR>
      </TABLE>
    </TD></TR>    
  </TABLE>
</BODY>
</HTML>
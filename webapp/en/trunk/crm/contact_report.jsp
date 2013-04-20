 <%@ page import="java.io.IOException,java.net.URLDecoder,java.sql.SQLException,com.knowgate.jdc.JDCConnection,com.knowgate.dataobjs.*,com.knowgate.acl.*,com.knowgate.crm.*,com.knowgate.hipergate.DBLanguages" language="java" session="false" contentType="text/html;charset=UTF-8" %>
<%@ include file="../methods/page_prolog.jspf" %><%@ include file="../methods/dbbind.jsp" %><%@ include file="../methods/cookies.jspf" %><%@ include file="../methods/authusrs.jspf" %><%@ include file="../methods/nullif.jspf" %>
<% 
/*
  Copyright (C) 2004  Know Gate S.L. All rights reserved.
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

  response.addHeader ("Pragma", "no-cache");
  response.addHeader ("cache-control", "no-store");
  response.setIntHeader("Expires", 0);
  
  String sLanguage = getNavigatorLanguage(request);  

  String id_user = getCookie (request, "userid", null); 
  String gu_contact = request.getParameter("gu_contact");
  String full_name = "", de_title = "";
  
  Contact oCont = new Contact();
  Company oComp = new Company();
  
  DBSubset oAddr = null;
  DBSubset oColl = new DBSubset (DB.k_contacts, DB.tx_name+","+DB.tx_surname+","+DB.de_title, DB.gu_company+"=? AND " + DB.gu_contact + "<>? ORDER BY 1", 10);
  DBSubset oOprt = new DBSubset (DB.k_oportunities, DB.tl_oportunity+","+DB.dt_created+","+DB.dt_modified+","+DB.dt_next_action+","+DB.id_status+","+DB.tx_cause+","+DB.im_revenue+","+DB.tx_note, DB.gu_contact+"=? AND (" + DB.gu_writer + "=? OR " + DB.bo_private + "=0) ORDER BY 2 DESC",10);
  DBSubset oNots = new DBSubset (DB.k_contact_notes, DB.tl_note+","+DB.pg_note+","+DB.tx_fullname+","+DB.tx_main_email+","+DB.dt_created+","+DB.tx_note, DB.gu_contact+"=? ORDER BY 2 DESC", 10);
  DBSubset oAttc = new DBSubset (DB.k_products + " p," + DB.k_contact_attachs + " c", "p."+DB.nm_product+",c."+DB.dt_created, "c." + DB.gu_contact + "=? AND p." + DB.gu_product + "=c." + DB.gu_product + " ORDER BY 2 DESC", 10);
  DBSubset oMeet = new DBSubset (DB.k_meetings + " m," + DB.k_x_meeting_contact + " c," + DB.k_fellows + " f", "f."+DB.tx_name+",f."+DB.tx_surname+",m."+DB.dt_start+",m."+DB.tp_meeting+",m."+DB.tx_meeting+",m."+DB.de_meeting, "c." + DB.gu_contact + "=? AND m." + DB.gu_meeting + "=c." + DB.gu_meeting + " AND f." + DB.gu_fellow + "=m." + DB.gu_fellow + " AND (m." + DB.gu_fellow + "=? OR m." + DB.bo_private + "=0) ORDER BY 3 DESC", 10);
  DBSubset oCall = new DBSubset (DB.k_phone_calls, DB.tp_phonecall+","+DB.dt_start+","+DB.gu_user+","+DB.contact_person+","+DB.tx_comments, DB.gu_contact+"=? ORDER BY 2 DESC", 10);
  DBSubset oProj = new DBSubset (DB.k_projects, DB.nm_project+","+DB.dt_created+","+DB.id_status+","+DB.de_project, DB.gu_contact+"=? ORDER BY 2 DESC",10);
  DBSubset oDuty = new DBSubset (DB.k_duties, DB.nm_duty+","+DB.dt_created+","+DB.tx_status+","+DB.de_duty, DB.gu_contact+"=? ORDER BY 2 DESC",10);
  DBSubset oBugs = new DBSubset (DB.k_bugs, DB.tl_bug+","+DB.dt_created+","+DB.tx_status+","+DB.tx_bug_brief, DB.gu_writer+"=? ORDER BY 2 DESC",10);
  DBSubset oOrdr = new DBSubset (DB.k_orders, DB.im_total+","+DB.dt_created+","+DB.id_status, DB.gu_contact+"=? ORDER BY 2 DESC",10);
  
  int iColl=0, iOprt=0, iNots=0, iAttc=0, iMeet=0, iCall=0, iProj=0, iDuty=0, iBugs=0, iOrdr=0;
  
  if (autenticateSession(GlobalDBBind, request, response)<0) return;

  JDCConnection oConn = null;  
    
  try {
    oConn = GlobalDBBind.getConnection("contact_report");
    
    oCont.load(oConn, new Object[]{gu_contact});
    
    if (!oCont.isNull(DB.de_title))
      de_title = DBLanguages.getLookUpTranslation ((java.sql.Connection) oConn, DB.k_contacts_lookup, oCont.getString(DB.gu_workarea), DB.de_title, sLanguage, oCont.getString(DB.de_title));
      
    if (!oCont.isNull(DB.gu_company)) {
      oComp.load(oConn, new Object[]{oCont.getString(DB.gu_company)});
      iColl = oColl.load(oConn, new Object[]{oCont.getString(DB.gu_company),gu_contact});
      for (int cp=0; cp<iColl; cp++) {
        if (!oColl.isNull(2,cp))
          oColl.setElementAt(DBLanguages.getLookUpTranslation ((java.sql.Connection) oConn,DB.k_contacts_lookup,oCont.getString(DB.gu_workarea),DB.de_title,sLanguage,oColl.getString(2,cp)),2,cp);
      }
    }
    
    oAddr = oCont.getAddresses(oConn);

    iOprt = oOprt.load(oConn, new Object[]{gu_contact,id_user});
    iNots = oNots.load(oConn, new Object[]{gu_contact});
    iAttc = oAttc.load(oConn, new Object[]{gu_contact});
    iMeet = oMeet.load(oConn, new Object[]{gu_contact,id_user});    
    
    iCall = oCall.load(oConn, new Object[]{gu_contact});
    for (int a=0; a<iCall; a++) {
      if (oCall.getString(0,a).equals("R") && !oCall.isNull(2,a)) {
        ACLUser oTo = new ACLUser(oConn, oCall.getString(2,a));
        oCall.setElementAt(oTo.getStringNull(DB.nm_user,"")+" "+oTo.getStringNull(DB.tx_surname1,"")+" "+oTo.getStringNull(DB.tx_surname2,""),3,a);
      }
    }
    
    iProj = oProj.load(oConn, new Object[]{gu_contact});
    iDuty = oDuty.load(oConn, new Object[]{gu_contact});

    iBugs = oBugs.load(oConn, new Object[]{gu_contact});
    for (int i=0; i<iBugs; i++) {
      if (!oBugs.isNull(2,i))
        oBugs.setElementAt(DBLanguages.getLookUpTranslation ((java.sql.Connection) oConn, DB.k_bugs_lookup,oCont.getString(DB.gu_workarea),DB.tx_status,sLanguage,oBugs.getString(2,i)),2,i);
    }

    iOrdr = oOrdr.load(oConn, new Object[]{gu_contact});
    
    oConn.close("contact_report");
  }
  catch (SQLException e) {  
    disposeConnection(oConn,"contact_report");
    oConn = null;
    response.sendRedirect (response.encodeRedirectUrl ("../common/errmsg.jsp?title=SQLException&desc=" + e.getLocalizedMessage() + "&resume=_close"));
  }
  
  if (null==oConn) return;
    
  oConn = null;

%>

<HTML LANG="<% out.write(sLanguage); %>">
<HEAD>
  <TITLE><%=oCont.getStringNull(DB.tx_name,"")+" "+oCont.getStringNull(DB.tx_surname,"")%></TITLE>
  <SCRIPT SRC="../javascript/cookies.js"></SCRIPT>  
  <SCRIPT SRC="../javascript/setskin.js"></SCRIPT>
</HEAD>
<BODY  TOPMARGIN="8" MARGINHEIGHT="8">
  <TABLE><TR><TD CLASS="striptitle"><FONT CLASS="title1">Report of <%=oCont.getStringNull(DB.tx_name,"")+" "+oCont.getStringNull(DB.tx_surname,"")%></FONT></TD></TR></TABLE>  
  <TABLE>
    <TR>
      <TD><FONT CLASS="textplain">Company:</FONT></TD>
      <TD><FONT CLASS="textplain"><%=oComp.getStringNull(DB.nm_legal,"")%></FONT></TD>      
    </TR>
    <TR>
      <TD><FONT CLASS="textplain">Position:</FONT></TD>
      <TD><FONT CLASS="textplain"><%=de_title%></FONT></TD> 
    </TR>
<% if (iColl>0) { %>        
    <TR>
      <TD COLSPAN="2">
        <FONT CLASS="textplain">Other people from the same company
<% for (int f=0; f<iColl; f++) {
     out.write ("<BR>&nbsp;&nbsp;&nbsp;" + oColl.getStringNull(0,f,"")+" "+oColl.getStringNull(1,f,""));
     if (!oColl.isNull(2,f))
      out.write ("&nbsp;(" + oColl.getString(2,f) + ")");
     
   } %>
        </FONT>
      </TD>
    </TR>
<% } %>        
  </TABLE>
  <BR>
  <FONT CLASS="subtitle">Addresses:</FONT>
  <BR>
  <FONT CLASS="textplain">
<% for (int d=0; d<oAddr.getRowCount(); d++) {
     if (sLanguage.startsWith("es")) {
       out.write (oAddr.getStringNull(DB.tp_street, d, "")+" "+oAddr.getStringNull(DB.nm_street, d, "")+" "+oAddr.getStringNull(DB.nu_street, d, "")+"<BR>");
       out.write (oAddr.getStringNull(DB.zipcode, d, "")+" "+oAddr.getStringNull(DB.mn_city, d, "")+" ("+oAddr.getStringNull(DB.nm_state, d, "")+")<BR>");
     }
     else {
       out.write (oAddr.getStringNull(DB.nu_street, d, "")+" "+oAddr.getStringNull(DB.nm_street, d, "")+" "+oAddr.getStringNull(DB.tp_street, d, "")+"<BR>");   
       out.write (oAddr.getStringNull(DB.mn_city, d, "")+" "+oAddr.getStringNull(DB.id_state, d, "")+" "+oAddr.getStringNull(DB.zipcode, d, "")+"<BR>");
     }
     if (!oAddr.isNull(DB.work_phone,d)) out.write ("Main " + oAddr.getString(DB.work_phone,d) + "  ");
     if (!oAddr.isNull(DB.direct_phone,d)) out.write ("Direct Phone " + oAddr.getString(DB.direct_phone,d));
     if (!oAddr.isNull(DB.mov_phone,d)) out.write ("Mobile Phone " + oAddr.getString(DB.mov_phone,d));
     if (!oAddr.isNull(DB.fax_phone,d)) out.write ("Fax " + oAddr.getString(DB.fax_phone,d));
     if (!oAddr.isNull(DB.work_phone,d)||!oAddr.isNull(DB.direct_phone,d)||!oAddr.isNull(DB.mov_phone,d)||!oAddr.isNull(DB.fax_phone,d)) out.write("<BR>");

     out.write ("e-mail <A HREF=\"mailto:" + oAddr.getStringNull(DB.tx_email,d,"") + "\">" + oAddr.getStringNull(DB.tx_email,d,"") + "</A>&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;<A HREF=\"" + oAddr.getStringNull(DB.url_addr,d,"") + "\">"+oAddr.getStringNull(DB.url_addr,d,"")+"</A><BR>");
     out.write ("Contact Person " + oAddr.getStringNull(DB.contact_person,d,"") + "  <A HREF=\"" + oAddr.getStringNull(DB.tx_email_alt,d,"") + "\">"+oAddr.getStringNull(DB.tx_email_alt,d,"")+"</A><BR>");
     out.write ("<BR>"); 
}
%>
  </FONT>
  <FONT CLASS="subtitle">Opportunities</FONT>
  <BR>
  <FONT CLASS="textplain">
<% for (int o=0; o<iOprt; o++) {
     out.write(oOprt.getStringNull(0,o,"")+"<BR>");
     out.write("created "+oOprt.getDateShort(1,o)+" ");
     if (!oOprt.isNull(2,o)) out.write("modified "+oOprt.getDateShort(2,o)+" ");
     if (!oOprt.isNull(3,o)) out.write("next task "+oOprt.getDateShort(3,o)+" ");
     out.write("<BR>");
     out.write("status "+oOprt.getStringNull(4,o,"")+"  cause "+oOprt.getStringNull(5,o,"?")+"<BR>");
     if (!oOprt.isNull(6,o)) out.write("cost "+oOprt.get(6,o).toString()+"<BR>");
     if (!oOprt.isNull(7,o)) out.write(oOprt.getString(7,o)+"<BR>");
} %>
  </FONT>
  <BR>
  <FONT CLASS="subtitle">Notes:</FONT>
  <BR>
  <FONT CLASS="textplain">
<% for (int n=0; n<iNots; n++) {
     out.write(oNots.getDateShort(4,n)+"  "+oNots.getStringNull(0,n,"")+"<BR>");
     if (!oNots.isNull(2,n)) {
       out.write("From " + oNots.getString(2,n));
       if (!oNots.isNull(3,n))
       out.write("&lt;<A HREF=\"mailto:" + oNots.getString(3,n) + "\">" + oNots.getString(3,n) + "</A>&gt;");
       out.write("<BR>");
     }
     
     if (!oNots.isNull(5,n)) out.write(oNots.getStringNull(5,n,"")+"<BR>");     
} %>

  </FONT>
  <BR>
  <FONT CLASS="subtitle">Meetings:</FONT>
  <BR>
  <FONT CLASS="textplain">
<% for (int m=0; m<iMeet; m++) {

     out.write(oMeet.getDateShort(2,m)+"  "+oMeet.getStringNull(3,m,"")+" with "+ oMeet.getStringNull(0,m,"") + " "+oMeet.getStringNull(1,m,"")+"<BR>");
     if (!oMeet.isNull(4,m)) out.write(oMeet.getStringNull(4,m,"")+"<BR>");
     if (!oMeet.isNull(5,m)) out.write(oMeet.getStringNull(5,m,"")+"<BR>");
} %>
  </FONT>  
  <BR>
  <FONT CLASS="subtitle">Calls:</FONT>
  <BR>
  <FONT CLASS="textplain">
<% for (int c=0; c<iCall; c++) {
     out.write(oCall.getDateShort(1,c)+"  "+oCall.getStringNull(3,c,"")+"<BR>");
     if (!oCall.isNull(4,c)) out.write(oCall.getStringNull(4,c,"")+"<BR>");
} %>
  </FONT>  
  <BR>
  <FONT CLASS="subtitle">Orders:</FONT>
  <BR>
  <FONT CLASS="textplain">
<% for (int x=0; x<iOrdr; x++) {
     out.write(oOrdr.getDateShort(1,x)+"  "+oOrdr.getStringNull(2,x,"")+" "+oOrdr.get(0,x)+"<BR>");
} %>
  </FONT>  
  <BR>
  <FONT CLASS="subtitle">Incidents:</FONT>
  <BR>
  <FONT CLASS="textplain">
<% for (int b=0; b<iBugs; b++) {
     out.write(oBugs.getDateShort(1,b)+"  "+oBugs.getStringNull(0,b,"")+"<BR>");
     if (!oBugs.isNull(2,b)) out.write("Status: "+oBugs.getStringNull(2,b,"")+"<BR>");
     if (!oBugs.isNull(3,b)) out.write(oBugs.getStringNull(3,b,"")+"<BR>");
} %>
  </FONT>  
  <BR>
<CENTER>
<A HREF="#" CLASS="linkplain" onclick="window.print()">Print</A>
&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;
<A HREF="#" CLASS="linkplain" onclick="window.close()">Close</A>
</CENTER>
</BODY>
</HTML>

<%@ include file="../methods/page_epilog.jspf" %>

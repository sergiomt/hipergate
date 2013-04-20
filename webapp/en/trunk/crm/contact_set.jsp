<%@ page import="java.util.Date,java.io.IOException,java.net.URLDecoder,java.sql.SQLException,com.knowgate.jdc.JDCConnection,com.knowgate.dataobjs.*,com.knowgate.acl.*,com.knowgate.misc.Gadgets" language="java" session="false" contentType="text/html;charset=UTF-8" %>
<%@ include file="../methods/dbbind.jsp" %><%@ include file="../methods/cookies.jspf" %><%@ include file="../methods/authusrs.jspf" %><%@ include file="../methods/nullif.jspf" %>
<% 

  if (autenticateSession(GlobalDBBind, request, response)<0) return;
      
  String id_user = getCookie (request, "userid", null);
  String gu_workarea = request.getParameter("gu_workarea");
  String gu_contact = request.getParameter("gu_contact");

  DBSubset oSearch = new DBSubset(DB.k_member_address,"*",DB.gu_contact+"=? AND "+DB.gu_workarea + "=? AND ("+DB.bo_private+"=0 OR "+DB.gu_writer+"=?)",1);

  int iSearch = 0;
  
  JDCConnection oConn = null;  
    
  try {
    oConn = GlobalDBBind.getConnection("contact_set");
    
    iSearch = oSearch.load(oConn, new Object[]{gu_contact,gu_workarea,id_user});
    if (0==iSearch) {
      oSearch = new DBSubset(DB.v_contact_company_all,"*",DB.gu_contact+"=? AND "+DB.gu_workarea + "=? AND ("+DB.bo_private+"=0 OR "+DB.gu_writer+"=?)",1);
      iSearch = oSearch.load(oConn, new Object[]{gu_contact,gu_workarea,id_user});
    }
    
    oConn.close("contact_set");
  }
  catch (SQLException e) {  
    if (oConn!=null)
      if (!oConn.isClosed()) {
        oConn.close("contact_set");      
      }
    oConn = null;
    response.sendRedirect (response.encodeRedirectUrl ("../common/errmsg.jsp?title=SQLException&desc=" + e.getLocalizedMessage() + "&resume=_close"));
  }
  catch (NumberFormatException e) {
    if (oConn!=null)
      if (!oConn.isClosed()) {
        oConn.close("contact_set");      
      }
    oConn = null;
    response.sendRedirect (response.encodeRedirectUrl ("../common/errmsg.jsp?title=NumberFormatException&desc=" + e.getMessage() + "&resume=_close"));
  }
  
  if (null==oConn) return;
    
  oConn = null;
%>

<HTML>
<HEAD>
  <SCRIPT SRC="../javascript/combobox.js"></SCRIPT>
  <SCRIPT TYPE="text/javascript">
  <!--
    function setContact() {
      var opn = window.opener;
      var frm;
      
      if (opn) {
        if (!opn.closed) {
          frm = opn.document.forms[0];
<%	  int iCol;
	  if (iSearch>0) {
	    out.write("          if (frm.gu_contact) frm.gu_contact.value=\""+oSearch.getString(DB.gu_contact,0)+"\";\n");
	    out.write("          if (frm.nm_legal) frm.nm_legal.value=\""+oSearch.getStringNull(DB.nm_legal,0,"")+"\";\n");
	    out.write("          if (frm.tx_name) frm.tx_name.value=\""+oSearch.getStringNull(DB.tx_name,0,"")+"\";\n");
	    out.write("          if (frm.tx_surname) frm.tx_surname.value=\""+oSearch.getStringNull(DB.tx_surname,0,"")+"\";\n");
	    out.write("          if (frm.sn_passport) frm.sn_passport.value=\""+oSearch.getStringNull(DB.sn_passport,0,"")+"\";\n");
	    if (!oSearch.isNull(DB.dt_birth,0)) {
	      iCol = oSearch.getColumnPosition(DB.dt_birth);
	      Date oDt = oSearch.getDate(iCol,0);
	      out.write("          if (frm.day_bday) setCombo(frm.day_bday,\""+String.valueOf(oDt.getDate())+"\");\n");
	      out.write("          if (frm.month_bday) setCombo(frm.month_bday,\""+String.valueOf(oDt.getMonth())+"\");\n");
	      out.write("          if (frm.day_bday) setCombo(frm.year_bday,\""+String.valueOf(oDt.getYear())+"\");\n");
	      out.write("          if (frm.dt_birth) frm.dt_birth.value=\""+oSearch.getDateShort(iCol,0)+"\";\n");
	    }
	    iCol = oSearch.getColumnPosition(DB.id_country);
	    if (-1!=iCol) {
	      out.write("          if (frm.sel_country) setCombo(frm.sel_country,\""+oSearch.getStringNull(DB.id_country,0,"").trim()+"\");\n");
	    }
	    iCol = oSearch.getColumnPosition(DB.id_state);
	    if (-1!=iCol) {
	      out.write("          if (frm.id_state) frm.id_state.value=\""+oSearch.getStringNull(DB.id_state,0,"")+"\";\n");
	      out.write("          if (frm.sel_state) setCombo(frm.sel_state, \""+oSearch.getStringNull(DB.id_state,0,"")+"\");\n");
	    }
	    iCol = oSearch.getColumnPosition(DB.nm_state);
	    if (-1!=iCol) {
	      out.write("          if (frm.nm_state) frm.nm_state.value=\""+oSearch.getStringNull(DB.nm_state,0,"")+"\";\n");
	    }
	    iCol = oSearch.getColumnPosition(DB.mn_city);
	    if (-1!=iCol) {
	      out.write("          if (frm.mn_city) frm.mn_city.value=\""+oSearch.getStringNull(DB.mn_city,0,"")+"\";\n");
	    }
	    iCol = oSearch.getColumnPosition(DB.zipcode);
	    if (-1!=iCol) {
	      out.write("          if (frm.zipcode) frm.zipcode.value=\""+oSearch.getStringNull(DB.zipcode,0,"")+"\";\n");
	    }
	    iCol = oSearch.getColumnPosition(DB.home_phone);
	    if (-1!=iCol) {
	      out.write("          if (frm.home_phone) frm.home_phone.value=\""+oSearch.getStringNull(DB.home_phone,0,"")+"\";\n");
	    }
	    iCol = oSearch.getColumnPosition(DB.tx_email);
	    if (-1!=iCol) {
	      out.write("          if (frm.tx_email) frm.tx_email.value=\""+oSearch.getStringNull(DB.tx_email,0,"")+"\";\n");
	    }
	  } // fi (iSearch>0)
%>
        } // fi (opener.isClosed())
      } // fi (window.opener)
      window.close();
    }
  //-->
  </SCRIPT> 
</HEAD>
<BODY onload="setContact()">
</BODY>
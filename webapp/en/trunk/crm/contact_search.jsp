<%@ page import="java.io.IOException,java.net.URLDecoder,java.sql.SQLException,com.knowgate.jdc.JDCConnection,com.knowgate.dataobjs.*,com.knowgate.acl.*,com.knowgate.misc.Gadgets" language="java" session="false" contentType="text/html;charset=UTF-8" %>
<%@ include file="../methods/dbbind.jsp" %><%@ include file="../methods/cookies.jspf" %><%@ include file="../methods/authusrs.jspf" %><%@ include file="../methods/nullif.jspf" %>
<% 

  if (autenticateSession(GlobalDBBind, request, response)<0) return;
      
  String gu_workarea = request.getParameter("gu_workarea");
  String tx_searched = request.getParameter("tx_searched");  
  String nu_skip = nullif(request.getParameter("nu_skip"), "0");  

  String id_user = getCookie (request, "userid", null);

  DBSubset oSearch = new DBSubset(DB.v_contact_company_all,
  				  DB.gu_contact+","+DB.tx_name+","+DB.tx_surname+","+DB.nm_legal,
  				  DB.gu_workarea + "=? AND "+
  				  "(" + DB.tx_name + " " + DBBind.Functions.ILIKE + " ? OR " + DB.tx_surname + " " + DBBind.Functions.ILIKE + " ? OR "+
  				  DB.id_ref + "=? OR " + DB.sn_passport + "=? OR " + DB.nm_legal + " " + DBBind.Functions.ILIKE + " ?) AND " +
				  "(" + DB.bo_private + "<>1 OR " + DB.gu_writer + "=?) ORDER BY 2", 100);  				  
  int iSearch = 0;
  
  JDCConnection oConn = null;  
    
  try {
    oConn = GlobalDBBind.getConnection("contact_search");
    
    oSearch.setMaxRows(100);
    iSearch = oSearch.load(oConn, new Object[]{gu_workarea,tx_searched,tx_searched,tx_searched,tx_searched,tx_searched,id_user}, Integer.parseInt(nu_skip));

    oConn.close("contact_search");
  }
  catch (SQLException e) {  
    if (oConn!=null)
      if (!oConn.isClosed()) {
        oConn.close("contact_search");      
      }
    oConn = null;
    response.sendRedirect (response.encodeRedirectUrl ("../common/errmsg.jsp?title=SQLException&desc=" + e.getLocalizedMessage() + "&resume=_close"));
  }
  catch (NumberFormatException e) {
    if (oConn!=null)
      if (!oConn.isClosed()) {
        oConn.close("contact_search");      
      }
    oConn = null;
    response.sendRedirect (response.encodeRedirectUrl ("../common/errmsg.jsp?title=NumberFormatException&desc=" + e.getMessage() + "&resume=_close"));
  }
  
  if (null==oConn) return;
    
  oConn = null;
%>

<HTML>
<HEAD>
  <SCRIPT SRC="../javascript/cookies.js"></SCRIPT>  
  <SCRIPT SRC="../javascript/setskin.js"></SCRIPT>
  <TITLE>hipergate :: Search contact</TITLE>
</HEAD>
<BODY  TOPMARGIN="8" MARGINHEIGHT="8">
<%
if (iSearch==0) out.write("<BR><FONT CLASS=\"textplain\">No indivicual was found with the given criteria</FONT>");

for (int c=0; c<iSearch; c++) {
     out.write("<A CLASS=\"linkplain\" HREF=\"contact_set.jsp?gu_contact="+oSearch.getString(0,c)+"&gu_workarea="+gu_workarea+"\">"+oSearch.getStringNull(1,c,"")+" "+oSearch.getStringNull(2,c,""));
     if (!oSearch.isNull(3,c))
       out.write(" ("+oSearch.getString(3,c)+")");
     out.write("</A><BR>"); 
}
if (iSearch==0) out.write("<BR><A HREF=\"contact_search.jsp?nu_skip="+String.valueOf(Integer.parseInt(nu_skip)+100)+"&gu_workarea="+gu_workarea+"&tx_searched="+Gadgets.URLEncode(tx_searched)+"\" CLASS=\"linkplain\">Next >></A>");
%>
<BR><BR>
<FORM><CENTER><INPUT TYPE="BUTTON" CLASS="closebutton" VALUE="Close" onclick="window.close()"></CENTER></FORM>
</BODY>
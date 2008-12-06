<%@ page import="java.util.*,java.io.IOException,java.net.URLDecoder,java.sql.SQLException,java.sql.ResultSet,java.sql.PreparedStatement,com.knowgate.jdc.*,com.knowgate.dataobjs.*,com.knowgate.acl.*,com.knowgate.hipergate.*,com.knowgate.misc.Gadgets" language="java" session="false" %>
<%@ include file="../methods/dbbind.jsp" %>
<%@ include file="../methods/cookies.jspf" %>
<%@ include file="../methods/authusrs.jspf" %>
<%@ include file="../methods/nullif.jspf" %>
<%
  if (autenticateSession(GlobalDBBind, request, response)<0) return;
  
  String gu_workarea = getCookie (request, "workarea", null);
  String gu_company = request.getParameter("gu_company");
  String gu_contact = request.getParameter("gu_contact");
  
  ResultSet oRst;
  int iAddrs = 0;
  DBSubset oAddrs;
  JDCConnection oCon = GlobalDBBind.getConnection("addr_load");
    
  try {
    if (null!=gu_company) {
      oAddrs = new DBSubset(DB.k_addresses + " a," + DB.k_x_company_addr + " x",
      			    "a." + DB.gu_address + ",a." + DB.tp_location + ",a." + DB.tp_street + ",a." + DB.nm_street + ",a." + DB.nu_street + ",a." + DB.zipcode + ",a." + DB.nm_state,
      			    "a." + DB.gu_workarea + "=? AND a." + DB.bo_active + "<>0 AND x." + DB.gu_company + "=? AND a." + DB.gu_address + "=x." + DB.gu_address, 2);
      iAddrs = oAddrs.load(oCon, new Object[]{gu_workarea, gu_company});
    }
    else {
      oAddrs = new DBSubset(DB.k_addresses + " a," + DB.k_x_contact_addr + " x",
      			    "a." + DB.gu_address + ",a." + DB.tp_location + ",a." + DB.tp_street + ",a." + DB.nm_street + ",a." + DB.nu_street + ",a." + DB.zipcode + ",a." + DB.mn_city,
      			    "a." + DB.gu_workarea + "=? AND a." + DB.bo_active + "<>0 AND x." + DB.gu_contact + "=? AND a." + DB.gu_address + "=x." + DB.gu_address, 2);
      iAddrs = oAddrs.load(oCon, new Object[]{gu_workarea, gu_contact});
    }
    
    oCon.close("addr_load");
  } 
  catch(SQLException e) {
      if (oCon!=null)
        if (!oCon.isClosed()) {
          oCon.close("addr_load");
        }
      oAddrs = null;
      response.sendRedirect (response.encodeRedirectUrl ("../common/errmsg.jsp?title=Error&desc=" + e.getLocalizedMessage() + "&resume=_back"));
    }
    
  oCon = null; 

  out.write("<HTML><HEAD><TITLE>Wait...</TITLE>\n");
  out.write("<SCRIPT LANGUAGE='JavaScript' TYPE='text/javascript' SRC='../javascript/combobox.js'></SCRIPT>\n");
  out.write("<SCRIPT LANGUAGE='JavaScript' TYPE='text/javascript'>\n");
  out.write("var frm = window.parent.orderdata.document.forms[0];\n");

  out.write("clearCombo(frm.sel_ship_addr);\n");
  out.write("clearCombo(frm.sel_bill_addr);\n");
  
  for (int a=0; a<iAddrs; a++) {
      out.write("comboPush (frm.sel_ship_addr, \"" + (oAddrs.getStringNull(2,a,"") + " " + oAddrs.getStringNull(3,a,"") + " " + oAddrs.getStringNull(4,a,"") + " (" + oAddrs.getStringNull(5,a,"") + " " + oAddrs.getStringNull(6,a,"")) + ")\", \"" + oAddrs.getString(0,a) + "\", " + (oAddrs.getStringNull(0,a,"").equals("ENVIO") ? "true" : "false") + ", " + (oAddrs.getStringNull(1,a,"").equals("1") ? "true" : "false") + ");\n");
      out.write("comboPush (frm.sel_bill_addr, \"" + (oAddrs.getStringNull(2,a,"") + " " + oAddrs.getStringNull(3,a,"") + " " + oAddrs.getStringNull(4,a,"") + " (" + oAddrs.getStringNull(5,a,"") + " " + oAddrs.getStringNull(6,a,"")) + ")\", \"" + oAddrs.getString(0,a) + "\", " + (oAddrs.getStringNull(0,a,"").equals("FACTURACION") ? "true" : "false") + ", " + (oAddrs.getStringNull(1,a,"").equals("2") ? "true" : "false") + ");\n");
  }
    
  out.write("window.document.location='../blank.htm';\n"); 
  out.write("</SCRIPT></HEAD></HTML>"); 
 %>
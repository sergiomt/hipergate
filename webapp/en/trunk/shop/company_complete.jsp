<%@ page import="java.util.*,java.io.IOException,java.net.URLDecoder,java.sql.SQLException,java.sql.ResultSet,java.sql.PreparedStatement,com.knowgate.jdc.*,com.knowgate.dataobjs.*,com.knowgate.acl.*,com.knowgate.hipergate.*,com.knowgate.misc.Gadgets" language="java" session="false" contentType="text/html;charset=UTF-8" %>
<%@ include file="../methods/dbbind.jsp" %><%@ include file="../methods/cookies.jspf" %><%@ include file="../methods/authusrs.jspf" %><%@ include file="../methods/nullif.jspf" %>
<%
  if (autenticateSession(GlobalDBBind, request, response)<0) return;
  
  String gu_workarea = getCookie (request, "workarea", null);
  String gu_company = request.getParameter("gu_company");
  String sFoundId = null, sFoundNm = null, sFoundLg = null;
  int iType = 0;
  
  ResultSet oRst;
  PreparedStatement oStm;
  int iAddrs = 0;
  DBSubset oAddrs;
  JDCConnection oCon = GlobalDBBind.getConnection("company_complete");
    
  try {
    oStm = oCon.prepareStatement("SELECT " + DB.gu_company + "," + DB.nm_legal + "," + DB.id_legal + " FROM " + DB.k_companies + " WHERE " + DB.gu_company + "=?", ResultSet.TYPE_FORWARD_ONLY, ResultSet.CONCUR_READ_ONLY);
    oStm.setQueryTimeout(10);
    oStm.setString(1,gu_company);
    oRst = oStm.executeQuery();
    if (oRst.next()) {
      sFoundId = oRst.getString(1);
      sFoundNm = oRst.getString(2);
      sFoundLg = nullif(oRst.getString(3));
      iType = 1;
    }
    oRst.close();
    oStm.close();
        
    oAddrs = new DBSubset(DB.k_addresses + " a," + DB.k_x_company_addr + " x",
      			  "a." + DB.gu_address + ",a." + DB.tp_location + ",a." + DB.tp_street + ",a." + DB.nm_street + ",a." + DB.nu_street + ",a." + DB.zipcode + ",a." + DB.mn_city,
      			  "a." + DB.gu_workarea + "=? AND a." + DB.bo_active + "<>0 AND x." + DB.gu_company + "=? AND a." + DB.gu_address + "=x." + DB.gu_address, 2);
    iAddrs = oAddrs.load(oCon, new Object[]{gu_workarea, sFoundId});
      
    oCon.close("company_complete");
  } 
  catch(SQLException e) {
      if (oCon!=null)
        if (!oCon.isClosed()) {
          oCon.close("company_complete");
        }
      oAddrs = null;
      oCon = null;
      response.sendRedirect (response.encodeRedirectUrl ("../common/errmsg.jsp?title=Error&desc=" + e.getLocalizedMessage() + "&resume=_back"));
    }
    
  oCon = null; 

  out.write("<HTML><HEAD><TITLE>Wait...</TITLE>\n");
  out.write("<SCRIPT LANGUAGE='JavaScript' TYPE='text/javascript' SRC='../javascript/combobox.js'></SCRIPT>\n");
  out.write("<SCRIPT LANGUAGE='JavaScript' TYPE='text/javascript'>\n");
  out.write("var doc = window.parent.orderdata.document;\n");
  out.write("var frm = doc.forms[0];\n");
  out.write("var opt;\n");
  
  if (0!=iType) {
    out.write("frm.gu_company.value = '" + sFoundId + "';\n");
    out.write("frm.id_legal.value = '" + sFoundLg + "';\n");
    
    out.write("frm.nm_client.value = unescape('" + Gadgets.URLEncode(sFoundNm) + "');\n");
    out.write("window.parent.orderdata.document.images['clientwarning'].src = '../images/images/viewtxt.gif';\n");

    out.write("clearCombo(frm.sel_ship_addr);\n");
    out.write("clearCombo(frm.sel_bill_addr);\n");
    
    for (int a=0; a<iAddrs; a++) {
      out.write("  opt = doc.createElement(\"OPTION\");\n");
      out.write("  opt.text = \"" + oAddrs.getStringNull(3,a,"") + " " + oAddrs.getStringNull(4,a,"") + " (" + oAddrs.getStringNull(6,a,"") + ")\";\n");
      out.write("  opt.value = \"" + oAddrs.getStringNull(0,a,"") + "\";\n");
      if (oAddrs.getStringNull(1,a,"").equals("ENVIO")) out.write("  opt.selected = true;\n");
      out.write("  frm.sel_ship_addr.options.add(opt);\n");

      out.write("  opt = doc.createElement(\"OPTION\");\n");
      out.write("  opt.text = \"" + oAddrs.getStringNull(3,a,"") + " " + oAddrs.getStringNull(4,a,"") + " (" + oAddrs.getStringNull(6,a,"") + ")\";\n");
      out.write("  opt.value = \"" + oAddrs.getStringNull(0,a,"") + "\";\n");
      if (oAddrs.getStringNull(1,a,"").equals("FACTURACION")) out.write("  opt.selected = true;\n");
      out.write("  frm.sel_bill_addr.options.add(opt);\n");
    } // next
    
  } // fi (iType)
  
  out.write("window.document.location='../blank.htm';\n"); 
  out.write("</SCRIPT>\n</HEAD></HTML>"); 
 %>
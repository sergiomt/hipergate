<%@ page import="java.util.*,java.io.IOException,java.net.URLDecoder,java.sql.SQLException,java.sql.ResultSet,java.sql.PreparedStatement,com.knowgate.jdc.*,com.knowgate.dataobjs.*,com.knowgate.acl.*,com.knowgate.hipergate.*,com.knowgate.misc.Gadgets" language="java" session="false" %>
<%@ include file="../methods/dbbind.jsp" %>
<%@ include file="../methods/cookies.jspf" %>
<%@ include file="../methods/authusrs.jspf" %>
<%@ include file="../methods/nullif.jspf" %>
<%
  if (autenticateSession(GlobalDBBind, request, response)<0) return;
  
  String gu_workarea = getCookie (request, "workarea", null);
  String id_legal = request.getParameter("id_legal");
  String sFoundId = null, sFoundNm = null, sFoundLg = null;
  int iType = 0;
  
  ResultSet oRst;
  int iAddrs = 0;
  DBSubset oAddrs;
  PreparedStatement oStm;
  JDCConnection oCon = GlobalDBBind.getConnection("legal_complete");
    
  try {
    oStm = oCon.prepareStatement("SELECT " + DB.gu_company + "," + DB.nm_legal + "," + DB.id_legal + " FROM " + DB.k_companies + " WHERE " + DB.gu_workarea+ "=? AND " + DB.id_legal + " = ?", ResultSet.TYPE_FORWARD_ONLY, ResultSet.CONCUR_READ_ONLY);
    oStm.setQueryTimeout(10);
    oStm.setString(1,gu_workarea);
    oStm.setString(2,id_legal);
    oRst = oStm.executeQuery();
    if (oRst.next()) {
      sFoundId = oRst.getString(1);
      sFoundNm = oRst.getString(2);
      sFoundLg = nullif(oRst.getString(3));
      iType = 1;
    }
    oRst.close();
    oStm.close();

    if (1==iType) {
      oAddrs = new DBSubset(DB.k_addresses + " a," + DB.k_x_company_addr + " x",
      			    "a." + DB.gu_address + ",a." + DB.tp_location + ",a." + DB.tp_street + ",a." + DB.nm_street + ",a." + DB.nu_street + ",a." + DB.zipcode + ",a." + DB.mn_city,
      			    "a." + DB.gu_workarea + "=? AND a." + DB.bo_active + "<>0 AND x." + DB.gu_company + "=? AND a." + DB.gu_address + "=x." + DB.gu_address, 2);
      iAddrs = oAddrs.load(oCon, new Object[]{gu_workarea, sFoundId});
    }
    else
      oAddrs = null;
              
    oCon.close("legal_complete");
  } 
  catch(SQLException e) {
      if (oCon!=null)
        if (!oCon.isClosed()) {
          oCon.close("legal_complete");
        }
      oAddrs = null;
      response.sendRedirect (response.encodeRedirectUrl ("../common/errmsg.jsp?title=Error&desc=" + e.getLocalizedMessage() + "&resume=_back"));
    }
    
  oCon = null; 

  out.write("<HTML><HEAD><TITLE>Wait...</TITLE>\n");
  out.write("<SCRIPT LANGUAGE='JavaScript' TYPE='text/javascript' SRC='../javascript/combobox.js'></SCRIPT>\n");
  out.write("<SCRIPT LANGUAGE='JavaScript' TYPE='text/javascript'>\n");
  out.write("var frm = window.parent.orderdata.document.forms[0];\n");

  if (0!=iType) {
    if (1==iType) {
      out.write("frm.gu_company.value = '" + sFoundId + "';\n");
      out.write("frm.id_legal.value = '" + sFoundLg + "';\n");
    }
    
    out.write("frm.nm_client.value = '" + sFoundNm + "';\n");
    out.write("window.parent.orderdata.document.images['clientwarning'].src = '../images/images/viewtxt.gif';\n");

    out.write("clearCombo(frm.sel_ship_addr);\n");
    out.write("clearCombo(frm.sel_bill_addr);\n");
    
    for (int a=0; a<iAddrs; a++) {
      out.write("comboPush (frm.sel_ship_addr, \"" + (oAddrs.getStringNull(2,a,"") + " " + oAddrs.getStringNull(3,a,"") + " " + oAddrs.getStringNull(4,a,"") + " (" + oAddrs.getStringNull(5,a,"") + " " + oAddrs.getStringNull(6,a,"")) + ")\", \"" + oAddrs.getString(0,a) + "\", " + (oAddrs.getStringNull(0,a,"").equals("ENVIO") ? "true" : "false") + ", " + (oAddrs.getStringNull(1,a,"").equals("1") ? "true" : "false") + ");\n");
      out.write("comboPush (frm.sel_bill_addr, \"" + (oAddrs.getStringNull(2,a,"") + " " + oAddrs.getStringNull(3,a,"") + " " + oAddrs.getStringNull(4,a,"") + " (" + oAddrs.getStringNull(5,a,"") + " " + oAddrs.getStringNull(6,a,"")) + ")\", \"" + oAddrs.getString(0,a) + "\", " + (oAddrs.getStringNull(0,a,"").equals("FACTURACION") ? "true" : "false") + ", " + (oAddrs.getStringNull(1,a,"").equals("2") ? "true" : "false") + ");\n");
    } // next
    
  } // fi (iType)
  
  out.write("window.document.location='../blank.htm';\n"); 
  out.write("</SCRIPT></HEAD></HTML>"); 
 %>
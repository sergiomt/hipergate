<%@ page import="java.util.*,java.io.IOException,java.net.URLDecoder,java.sql.SQLException,java.sql.ResultSet,java.sql.PreparedStatement,com.knowgate.jdc.*,com.knowgate.dataobjs.*,com.knowgate.acl.*,com.knowgate.hipergate.*,com.knowgate.misc.Gadgets" language="java" session="false" contentType="text/html;charset=UTF-8" %>
<%@ include file="../methods/dbbind.jsp" %><%@ include file="../methods/cookies.jspf" %><%@ include file="../methods/authusrs.jspf" %><%@ include file="../methods/nullif.jspf" %><%

  if (autenticateSession(GlobalDBBind, request, response)<0) return;
  
  String gu_workarea = getCookie (request, "workarea", null);
  String nm_product = "%" + nullif(request.getParameter("nm_product")) + "%";
  String gu_shop = request.getParameter("gu_shop");
  String gu_category = request.getParameter("gu_category");
  String gu_root_cat;
  
  java.util.Date dtTodayStart = new Date();
  java.util.Date dtTodayEnd = new Date();

  dtTodayStart.setHours(0) ; dtTodayStart.setMinutes(1) ; dtTodayStart.setSeconds(1);
  dtTodayEnd.setHours(23) ; dtTodayEnd.setMinutes(59) ; dtTodayEnd.setSeconds(59);
  
  float fPrice, fTax;
  StringBuffer oBuffer = new StringBuffer();  
  ResultSet oRst;
  PreparedStatement oStm;
  int iProds = 0;
  DBSubset oProds = null;
  JDCConnection oCon = GlobalDBBind.getConnection("product_seek");
    
  try {
    oStm = oCon.prepareStatement("SELECT " + DB.gu_root_cat + " FROM " + DB.k_shops + " WHERE " + DB.gu_shop + "=?",
    													   ResultSet.TYPE_FORWARD_ONLY, ResultSet.CONCUR_READ_ONLY);
    oStm.setString(1, gu_shop);
    oRst = oStm.executeQuery();
    oRst.next();
    gu_root_cat = oRst.getString(1);
    oRst.close();
    oStm.close();
    
    if (null!=request.getParameter("nm_product")) {
    
      if (null!=request.getParameter("gu_category")) {
        oProds = new DBSubset(DB.k_products + " p," + DB.k_x_cat_objs + " x",
      			     "p." + DB.gu_product + ",p." + DB.nm_product + "," + DBBind.Functions.ISNULL + "(p." + DB.pr_list + ",0) ,p." + DB.pr_sale + ",p." + DB.dt_start + ",p." + DB.dt_end + ",p." + DB.id_currency + "," + DB.pct_tax_rate + "," + DB.is_tax_included,
      			     "x." + DB.gu_category + "=? AND p." + DB.gu_product + "=x." + DB.gu_object + " AND p." + DB.nm_product + " " + DBBind.Functions.ILIKE + " ? ORDER BY 2", 5);

        iProds = oProds.load(oCon, new Object[]{gu_category,nm_product});

      } else {
        oProds = new DBSubset(DB.k_products + " p," + DB.k_x_cat_objs + " x," + DB.k_cat_expand + " e",
      			     "p." + DB.gu_product + ",p." + DB.nm_product + "," + DBBind.Functions.ISNULL + "(p." + DB.pr_list + ",0) ,p." + DB.pr_sale + ",p." + DB.dt_start + ",p." + DB.dt_end + ",p." + DB.id_currency + "," + DB.pct_tax_rate + "," + DB.is_tax_included,
      			     "e." + DB.gu_rootcat + "=? AND x." + DB.gu_category + "=" + "e." + DB.gu_category + " AND p." + DB.gu_product + "=x." + DB.gu_object + " AND p." + DB.nm_product + " " + DBBind.Functions.ILIKE + " ? ORDER BY 2", 5);

        iProds = oProds.load(oCon, new Object[]{gu_root_cat,nm_product});
      }
    }
    
    else {
      if (null!=request.getParameter("gu_category")) {
        oProds = new DBSubset(DB.k_products + " p," + DB.k_x_cat_objs + " x",
      			     "p." + DB.gu_product + ",p." + DB.nm_product + "," + DBBind.Functions.ISNULL + "(p." + DB.pr_list + ",0) ," + DBBind.Functions.ISNULL + "(p." + DB.pr_sale + ",0),p." + DB.dt_start + ",p." + DB.dt_end + ",p." + DB.id_currency + "," + DB.pct_tax_rate + "," + DB.is_tax_included,
      			     "x." + DB.gu_category + "=? AND p." + DB.gu_product + "=x." + DB.gu_object + " ORDER BY 2", 100);
        iProds = oProds.load(oCon, new Object[]{gu_category});
      } else {
        oProds = new DBSubset(DB.k_products + " p," + DB.k_x_cat_objs + " x," + DB.k_cat_expand + " e",
      			     "p." + DB.gu_product + ",p." + DB.nm_product + "," + DBBind.Functions.ISNULL + "(p." + DB.pr_list + ",0) ," + DBBind.Functions.ISNULL + "(p." + DB.pr_sale + ",0),p." + DB.dt_start + ",p." + DB.dt_end + ",p." + DB.id_currency + "," + DB.pct_tax_rate + "," + DB.is_tax_included,
      			     "e." + DB.gu_rootcat + "=? AND x." + DB.gu_category + "=" + "e." + DB.gu_category + " AND p." + DB.gu_product + "=x." + DB.gu_object + " ORDER BY 2", 100);

        iProds = oProds.load(oCon, new Object[]{gu_root_cat});
      }
    }
        
    for (int p=0; p<iProds; p++) {
      
      if (oProds.isNull(4,p) && oProds.isNull(5,p)) {
        fPrice = oProds.getFloat(2,p,2);
      }
      else if (!oProds.isNull(4,p)) {
        if (oProds.isNull(5,p))
          if (dtTodayStart.compareTo(oProds.getDate(4,p))>0)
            fPrice = oProds.getFloat(3,p,2);
          else
            fPrice = oProds.getFloat(2,p,2);
	else
          if (dtTodayStart.compareTo(oProds.getDate(4,p))>0 && dtTodayEnd.compareTo(oProds.getDate(5,p))<0)
            fPrice = oProds.getFloat(3,p,2);
          else
            fPrice = oProds.getFloat(2,p,2);	
      }
      else {
        if (dtTodayEnd.compareTo(oProds.getDate(5,p))<0)
          fPrice = oProds.getFloat(3,p,2);
        else
          fPrice = oProds.getFloat(2,p,2);      
      }
      
      if (oProds.isNull(7,p))
        fTax = 0f;
      else
        fTax = oProds.getFloat(7,p,2);
      
      if (!oProds.isNull(8,p)) {
        if (oProds.getShort(8,p)==(short)1)
          fTax = 0;
      }
      
      oBuffer.append("    opt = doc.createElement(\"OPTION\");\n");
      oBuffer.append("    opt.text = \"" + oProds.getString(1,p) + "\";\n");
      oBuffer.append("    opt.value = \"" + oProds.getString(0,p) + ":" + String.valueOf(fPrice) + ":" + String.valueOf(fTax) + ":" + oProds.getStringNull(6,p,"999") + "\";\n");
      oBuffer.append("    frm.sel_product.options.add(opt);\n");
      
    } // next
        
    oCon.close("product_seek");
  } 
  catch(SQLException e) {
      if (oCon!=null)
        if (!oCon.isClosed()) {
          oCon.close("product_seek");
        }
      response.sendRedirect (response.encodeRedirectUrl ("../common/errmsg.jsp?title=Error&desc=" + e.getLocalizedMessage() + "&resume=_back"));
    }
    
  oCon = null; 

  out.write("<HTML><HEAD><TITLE>Wait...</TITLE>\n<SCRIPT LANGUAGE='JavaScript' TYPE='text/javascript'>\n");
  out.write("    var doc = window.parent.orderdata.document;\n");
  out.write("    var frm = doc.forms[0];\n");  
  out.write("    frm.sel_product.options[0] = null;\n");
  out.write(oBuffer.toString()); 
  out.write("window.document.location='../blank.htm';\n"); 
  out.write("</SCRIPT></HEAD>");  
  out.write("</HTML>"); 
 %>
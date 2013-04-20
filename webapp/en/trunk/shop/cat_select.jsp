<%@ page import="java.util.Iterator,java.util.Vector,java.io.IOException,java.net.URLDecoder,java.sql.SQLException,java.sql.PreparedStatement,java.sql.ResultSet,com.knowgate.jdc.*,com.knowgate.dataobjs.*,com.knowgate.acl.*,com.knowgate.misc.*,com.knowgate.hipergate.*" language="java" session="false" contentType="text/html;charset=UTF-8" %>
<%@ include file="../methods/dbbind.jsp" %><%@ include file="../methods/cookies.jspf" %><%@ include file="../methods/authusrs.jspf" %><%@ include file="../methods/nullif.jspf" %>
<%!
  
  public static void listChilds(StringBuffer oOptions, PreparedStatement oStmt, String sThisCategory, String sParent, int iLevel) throws SQLException {
    ResultSet oChls;
    Vector vIds = new Vector(10);
    Vector vNms = new Vector(10);
        
    oStmt.setString(1, sParent);
    oChls = oStmt.executeQuery();
    
    int iOps = 0;
    while (oChls.next()) {
      vIds.add(oChls.getObject(1));
      vNms.add(oChls.getObject(2));      
      iOps++;
    } // wend
    oChls.close();
    
    for (int o=0; o<iOps; o++) {
        
      oOptions.append("  opt = doc.createElement(\"OPTION\");\n");
      oOptions.append("  opt.value = \"" + vIds.get(o) + "\";\n");
      oOptions.append("  opt.text = \"");
      for (int l=0;l<iLevel;l++) oOptions.append(" ");
      oOptions.append(vNms.get(o) + "\";\n");
      oOptions.append("  cat.add(opt);\n");
      
      listChilds (oOptions,oStmt,sThisCategory,(String)vIds.get(o),iLevel+3);
    } // next
  } // listChilds
%>
<%

  if (autenticateSession(GlobalDBBind, request, response)<0) return;

  String top_parent = request.getParameter("top_parent");
  String id_form = nullif(request.getParameter("id_form"),"0");;
  
  String sLanguage = getNavigatorLanguage(request);
  StringBuffer oSelCategories = new StringBuffer();
  PreparedStatement oBrowseChilds;

  JDCConnection oConn = GlobalDBBind.getConnection("cat_select");  
    
  try {  
    // Get full cat tree as combo box
    oBrowseChilds = oConn.prepareStatement("SELECT c." + DB.gu_category + "," + DBBind.Functions.ISNULL + "(l." + DB.tr_category + ",c." + DB.nm_category + ") FROM " + DB.k_categories + " c," + DB.k_cat_tree + " t," + DB.k_cat_labels + " l WHERE c." + DB.gu_category + "=t." + DB.gu_child_cat + " AND l." + DB.gu_category + "=c." + DB.gu_category + " AND l." + DB.id_language + "='" + sLanguage + "' AND t." + DB.gu_parent_cat + "=?", ResultSet.TYPE_FORWARD_ONLY, ResultSet.CONCUR_READ_ONLY);
    listChilds (oSelCategories, oBrowseChilds, top_parent, top_parent, 3);
    oBrowseChilds.close();

    oConn.close("cat_select");
  }
  catch (SQLException e) {  
    if (oConn!=null)
      if (!oConn.isClosed()) oConn.close("cat_select");
    oConn = null;
    response.sendRedirect (response.encodeRedirectUrl ("../common/errmsg.jsp?title=Error&desc=" + e.getLocalizedMessage() + "&resume=_back"));
  }
  
  if (oConn==null) return;
  oConn = null;
%>
<HTML>
<HEAD>
<TITLE>Wait...</TITLE>
<SCRIPT TYPE="text/javascript" SRC="../javascript/combobox.js"></SCRIPT>
<SCRIPT TYPE="text/javascript" SRC="../javascript/xmlhttprequest.js"></SCRIPT>
<SCRIPT TYPE="text/javascript">
<!--
  function setCombo() {
 	  	
    var opt;
    var doc = parent.msgslist.document;
    var cat = doc.forms[<%=id_form%>].sel_target.options;
  
    <% out.write(oSelCategories.toString()); %>
  
    cat[0] = null;
    cat.selectedIndex = 0;
  
  	if (cat.length>0 && doc.forms[<%=id_form%>].sel_product) {
	    var rxml = httpRequestXML("../common/select_xml.jsp?gu_workarea="+cat[0].value+"&nu_limit=1000&nu_skip=0&nm_select=Products&id_form=<%=id_form%>&nm_table=v_prod_cat_on_sale&nm_value=gu_product&nm_text=nm_product");
      clearCombo (doc.forms[<%=id_form%>].sel_product);
    	var prods = rxml.getElementsByTagName("option");
    	for (var p = 0; p < prods.length; p++) {
        comboPush (doc.forms[<%=id_form%>].sel_product, getElementValue(prods[p]), prods[p].getAttribute("value"), false, false);
      } // next
	  } // fi

    document.location = "../blank.htm";
  } // setCombo()    
//-->
</SCRIPT>
</HEAD>
<BODY onload="setCombo()">
</BODY>
</HTML>
<%@ page import="java.util.Iterator,java.util.Vector,java.io.IOException,java.net.URLDecoder,java.sql.SQLException,java.sql.PreparedStatement,java.sql.ResultSet,com.knowgate.jdc.*,com.knowgate.dataobjs.*,com.knowgate.acl.*,com.knowgate.misc.*,com.knowgate.hipergate.*" language="java" session="false" contentType="text/html;charset=UTF-8" %>
<%@ include file="../methods/dbbind.jsp" %>
<%@ include file="../methods/cookies.jspf" %>
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
  String top_parent = request.getParameter("top_parent");
  
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
<SCRIPT LANGUAGE="JavaScript" TYPE="text/javascript">
<!--
  function setCombo() {
    var opt;
    var doc = parent.msgslist.document;
    var cat = doc.forms[0].sel_target.options;
  
    <% out.write(oSelCategories.toString()); %>
  
    cat[0] = null;
    cat.selectedIndex = 0;
  
    self.document.location = "../blank.htm";
  } // setCombo()    
//-->
</SCRIPT>
</HEAD>
<BODY onload="setCombo()">
</BODY>
</HTML>
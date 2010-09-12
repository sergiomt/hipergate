<%@ page import="java.io.IOException,java.net.URLDecoder,java.sql.SQLException,com.knowgate.jdc.*,com.knowgate.jdc.JDCConnection,com.knowgate.dataobjs.*,com.knowgate.acl.*,com.knowgate.hipergate.*" language="java" session="false" %>
<%@ include file="../methods/dbbind.jsp" %><%@ include file="../methods/cookies.jspf" %><%@ include file="../methods/authusrs.jspf" %><%@ include file="../methods/clientip.jspf" %><%@ include file="../methods/nullif.jspf" %><%  
  if (autenticateSession(GlobalDBBind, request, response)<0) return;

  int id_domain = Integer.parseInt(getCookie (request, "domainid", "0"), 10);  
  short id_doc_status = Short.parseShort(request.getParameter("id_doc_status"));
  String id_category = request.getParameter("id_category").length()==0 ? null : request.getParameter("id_category");
  String n_category = nullif(request.getParameter("n_category")).trim().toUpperCase();
  String tr_category = request.getParameter("tr_category");
  
  short is_active;
  if (nullif(request.getParameter("is_active")).length()>0)
    is_active = Short.parseShort(request.getParameter("is_active"));
  else
    is_active = (short) 0;
  String id_parent_cat = request.getParameter("id_parent_cat");
  String id_parent_old = request.getParameter("id_parent_old");
  String nm_icon1 = request.getParameter("nm_icon1");
  String nm_icon2 = request.getParameter("nm_icon2");
  String id_user = getCookie (request, "userid", null);
    
  String sCatg = "";
  Category oCatg;
  JDCConnection oCon1 = null;
           
  try {
    oCon1 = GlobalDBBind.getConnection("listcatedit_store");
    
    if (n_category.length()==0)
      n_category = Category.makeName(oCon1, tr_category);   
      
    oCon1.setAutoCommit (false);
    
    if (id_category==null) {
      sCatg = Category.create ( oCon1, new Object[] {id_parent_cat, id_user, n_category, new Short(is_active), new Short(id_doc_status), nm_icon1, nm_icon2} );
      
      oCatg = new Category(sCatg);
      
      // Assign permissions to current user. Administrator priviledges will be assigned
      // automaticaly by newCategory()
      ACLDomain oDom = new ACLDomain(oCon1, id_domain);
      if (!id_user.equals(oDom.getString(DB.gu_owner)))
        oCatg.setUserPermissions ( oCon1, id_user, ACL.PERMISSION_LIST|ACL.PERMISSION_READ|ACL.PERMISSION_ADD|ACL.PERMISSION_DELETE|ACL.PERMISSION_MODIFY|ACL.PERMISSION_GRANT, (short) 1, (short) 0);
    }
    else {        
      oCatg = new Category(oCon1, id_category);
      
      oCatg.replace(DB.nm_category, n_category);
      oCatg.replace(DB.bo_active, new Short(is_active));
      oCatg.replace(DB.id_doc_status, new Short(id_doc_status));
      oCatg.replace(DB.nm_icon , nm_icon1.length()==0 ? "folderclosed_16x16.gif" : nm_icon1);
      oCatg.replace(DB.nm_icon2, nm_icon2.length()==0 ? "folderopen_16x16.gif" : nm_icon2);
      
      oCatg.store(oCon1);
      
      // Change parent (if aplicable)
      if (id_parent_old.length()>0 && !id_parent_old.equals(id_parent_cat)) {
        oCatg.resetParent (oCon1, id_parent_old);  
        oCatg.setParent   (oCon1, id_parent_cat);
      }
    }
    
    StringBuffer names_subset = new StringBuffer(DBLanguages.SupportedLanguages[0]+"`"+tr_category);
    for (int l=1; l<DBLanguages.SupportedLanguages.length; l++)
      names_subset.append("¨"+DBLanguages.SupportedLanguages[l]+"`"+tr_category);

    oCatg.storeLabels(oCon1, names_subset.toString(), "¨", "`");
    
    for (Category oPrnt : oCatg.browse (oCon1, Category.BROWSE_UP, Category.BROWSE_BOTTOMUP)) {
      Categories.expand (oCon1, oPrnt.getString(DB.gu_category));
		  if (oPrnt.getString(DB.gu_category).equals(request.getParameter("top_parent"))) break;
		}
		
    oCon1.commit();
    oCon1.close("listcatedit_store");
    
    out.write ("<HTML><HEAD><TITLE>Wait...</TITLE><" + "SCRIPT LANGUAGE='JavaScript' TYPE='text/javascript'>window.opener.parent.document.location.reload(true); self.close();<" + "/SCRIPT" +"></HEAD></HTML>");
  }
  catch (SQLException d) {
    disposeConnection(oCon1,"listcatedit_store");
    response.sendRedirect (response.encodeRedirectUrl ("../common/errmsg.jsp?title=Error&desc=" + d.getMessage() + "&resume=_back"));    
  }      
%>

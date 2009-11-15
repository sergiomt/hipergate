<%@ page import="java.io.IOException,java.net.URLDecoder,java.sql.SQLException,com.knowgate.jdc.*,com.knowgate.dataobjs.*,com.knowgate.acl.*,com.knowgate.hipergate.*" language="java" session="false" contentType="text/html;charset=UTF-8" %>
<%@ include file="../methods/dbbind.jsp" %><%@ include file="../methods/cookies.jspf" %><%@ include file="../methods/authusrs.jspf" %><%@ include file="../methods/clientip.jspf" %><%@ include file="../methods/reqload.jspf" %>
<% 
  if (autenticateSession(GlobalDBBind, request, response)<0) return;
      
  String nm_domain = request.getParameter("n_domain");;
  String id_domain = request.getParameter("id_domain");
  String gu_workarea = request.getParameter("gu_workarea");
  String id_user = getCookie (request, "userid", null);
  
  String gu_shop = request.getParameter("gu_shop");

  String sOpCode = gu_shop.length()>0 ? "NSHP" : "MSHP";
      
  ACLDomain oDomain;
  Category oShopsCat;
  String sShopsCat,sAppsCat;

  JDCConnection oConn = GlobalDBBind.getConnection("shop_edit_store");  

  Shop oShp = new Shop();

  loadRequest(oConn, request, oShp);
  
  oShp.replace(DB.bo_active, Short.parseShort(request.getParameter("bo_active").length()==0 ? "0" : "1"));
    
  try {

    oConn.setAutoCommit (false);
    oShp.setAuditUser(id_user);
    
    if (gu_shop.length()==0) {
      // Search for root category by name
      sShopsCat = Category.getIdFromName(oConn, nm_domain + "_apps_shop");
                  
      // Si no existe la categoría raiz de la aplicación de tienda, crearla dinamicamente sobre la marcha
      if (null==sShopsCat) {
                    
        // Create a reference to domain
        oDomain = new ACLDomain(oConn, Integer.parseInt(id_domain));
        nm_domain = oDomain.getString(DB.nm_domain);
	 
        sAppsCat = Category.getIdFromName(oConn, nm_domain + "_apps");
      
        sShopsCat = Category.store(oConn, null, sAppsCat, nm_domain + "_apps_shop", (short)1, (short)1, oDomain.getString(DB.gu_owner), "shop16x20.gif", "shop16x20.gif");	   

        oShopsCat = new Category(sShopsCat);
        oShopsCat.setUserPermissions(oConn, oDomain.getString(DB.gu_owner), ACL.PERMISSION_FULL_CONTROL, (short)0, (short)0);
        oShopsCat.setGroupPermissions(oConn, oDomain.getString(DB.gu_admins), ACL.PERMISSION_FULL_CONTROL, (short)0, (short)0);
	 
        CategoryLabel.create (oConn, new Object[]{sShopsCat, "es", "tienda", null});
        CategoryLabel.create (oConn, new Object[]{sShopsCat, "en", "shop", null});
        CategoryLabel.create (oConn, new Object[]{sShopsCat, "de", "shop", null});
        CategoryLabel.create (oConn, new Object[]{sShopsCat, "fi", "shop", null});
        CategoryLabel.create (oConn, new Object[]{sShopsCat, "fr", "boutique", null});
        CategoryLabel.create (oConn, new Object[]{sShopsCat, "it", "negozio", null});
        CategoryLabel.create (oConn, new Object[]{sShopsCat, "ru", "mагазин", null});
        CategoryLabel.create (oConn, new Object[]{sShopsCat, "no", "butikk", null});        
      } // fi (sShopsCat)

      oShp.store(oConn, sShopsCat);

      CategoryLabel.create (oConn, new Object[]{oShp.getString(DB.gu_root_cat), "es", request.getParameter("nm_shop"), null});
      CategoryLabel.create (oConn, new Object[]{oShp.getString(DB.gu_root_cat), "en", request.getParameter("nm_shop"), null});

      DBAudit.log(oConn, Shop.ClassId, sOpCode, id_user, oShp.getString(DB.gu_shop), sShopsCat, 0, 0, oShp.getString(DB.nm_shop), null);
    } else {
      oShp.store(oConn);
    }
    oConn.commit();
    oConn.close("shop_edit_store");
  }
  catch (SQLException e) {
    disposeConnection(oConn,"shop_edit_store");
    response.sendRedirect (response.encodeRedirectUrl ("../common/errmsg.jsp?title=SQLException&desc=" + e.getMessage() + "&resume=_close"));
  }
  catch (IllegalArgumentException e) {
    disposeConnection(oConn,"shop_edit_store");
    response.sendRedirect (response.encodeRedirectUrl ("../common/errmsg.jsp?title=IllegalArgumentException&desc=" + e.getMessage() + "&resume=_close"));
  }
  oConn = null;
  
  // Refresh parent and close window
  out.write ("<HTML><HEAD><TITLE>Wait...</TITLE><" + "SCRIPT LANGUAGE='JavaScript' TYPE='text/javascript'>window.opener.location.reload(); self.close();<" + "/SCRIPT" +"></HEAD></HTML>");

%>
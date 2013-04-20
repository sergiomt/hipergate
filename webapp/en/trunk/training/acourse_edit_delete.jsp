<%@ page import="com.knowgate.training.AcademicCourse,java.util.*,java.io.IOException,java.net.URLDecoder,java.sql.PreparedStatement,java.sql.ResultSet,java.sql.SQLException,com.knowgate.jdc.*,com.knowgate.dataobjs.*,com.knowgate.acl.*,com.knowgate.hipergate.*,com.knowgate.misc.Gadgets,com.knowgate.workareas.WorkArea" language="java" session="false" %><jsp:useBean id="GlobalCacheClient" scope="application" class="com.knowgate.cache.DistributedCachePeer"/><%@ include file="../methods/dbbind.jsp" %><%@ include file="../methods/cookies.jspf" %><%@ include file="../methods/authusrs.jspf" %><%@ include file="../methods/clientip.jspf" %><%
  if (autenticateSession(GlobalDBBind, request, response)<0) return;
  
  String id_user = getCookie (request, "userid", null);
  String gu_workarea = getCookie(request,"workarea",null);
  String a_items[] = Gadgets.split(request.getParameter("checkeditems"), ',');
  String sLanguage = getNavigatorLanguage(request);
    
  JDCConnection oCon = null;
  PreparedStatement oStm = null;
  PreparedStatement oUpd = null;
  PreparedStatement oDlt = null;
    
  try {
    oCon = GlobalDBBind.getConnection("acourse_delete");

    oCon.setAutoCommit (false);
  
    if (WorkArea.saveAcademicCoursesAsOportunityObjetives(oCon,gu_workarea)) {
    	oStm = oCon.prepareStatement("SELECT NULL FROM "+DB.k_oportunities+" WHERE "+DB.gu_workarea+"=? AND "+DB.id_objetive+"=?");
    	oUpd = oCon.prepareStatement("UPDATE "+DB.k_oportunities_lookup+" SET "+DB.bo_active+"=0 WHERE "+DB.gu_owner+"=? AND "+DB.id_section+"='id_objetive' AND "+DB.vl_lookup+"=?");
    	oDlt = oCon.prepareStatement("DELETE FROM "+DB.k_oportunities_lookup+" WHERE "+DB.gu_owner+"=? AND "+DB.id_section+"='id_objetive' AND "+DB.vl_lookup+"=?");
    
    	for (int i=0;i<a_items.length;i++) {
    	  oStm.setString(1, gu_workarea);
    	  oStm.setString(2, a_items[i]);
    	  ResultSet oRst = oStm.executeQuery();
    	  boolean bExistValues = oRst.next();
    	  oRst.close();
    	  if (bExistValues) {
        	oUpd.setString(1, gu_workarea);
        	oUpd.setString(2, a_items[i]);
        	oUpd.executeUpdate();
    	  } else {
         	oDlt.setString(1, gu_workarea);
         	oDlt.setString(2, a_items[i]);
         	oDlt.executeUpdate();    		  
    	  }
    	} // next
    	oDlt.close();
    	oUpd.close();
    	oStm.close();
      GlobalCacheClient.expire(DB.k_oportunities_lookup + ".id_objetive[" + gu_workarea + "]");
      GlobalCacheClient.expire(DB.k_oportunities_lookup + ".id_objetive#" + sLanguage + "[" + gu_workarea + "]");
    } // fi

    for (int i=0;i<a_items.length;i++)
      AcademicCourse.delete(oCon, a_items[i]);      
  
    oCon.commit();
    oCon.close("acourse_delete");
  } 
  catch(SQLException e) {
      disposeConnection(oCon,"acourse_delete");
      oCon = null; 
      response.sendRedirect (response.encodeRedirectUrl ("../common/errmsg.jsp?title=SQLException&desc=" + e.getLocalizedMessage() + "&resume=_back"));
    }
  
  if (null==oCon) return;
  
  oCon = null; 

  out.write("<HTML><HEAD><TITLE>Espere...</TITLE><" + "SCRIPT LANGUAGE='JavaScript' TYPE='text/javascript'>window.document.location='acourses_listing.jsp?selected=" + request.getParameter("selected") + "&subselected=" + request.getParameter("subselected") + "'<" + "/SCRIPT" +"></HEAD></HTML>"); 
 %>
<%@ page import="java.util.Date,java.util.Properties,java.io.IOException,java.io.File,javax.portlet.GenericPortlet,javax.portlet.WindowState,java.net.URLDecoder,com.knowgate.misc.Environment,com.knowgate.misc.Gadgets,com.knowgate.http.portlets.*" language="java" session="false" contentType="text/plain;charset=UTF-8" %>
<%@ include file="../methods/dbbind.jsp" %><%@ include file="../methods/cookies.jspf" %><%@ include file="../methods/nullif.jspf" %><%@ include file="../methods/globalportletconfig.jspf" %><% 

  String sLanguage = getNavigatorLanguage(request);
  String sSkin = getCookie(request, "skin", "xp");
      
  String id_domain = request.getParameter("id_domain");
  String n_domain = request.getParameter("n_domain");
  String gu_workarea = request.getParameter("gu_workarea");
  String id_user = nullif(request.getParameter("gu_user"), getCookie (request, "userid", null));

  String sRealPath = request.getRealPath(request.getServletPath());
         sRealPath = sRealPath.substring(0, sRealPath.lastIndexOf(File.separator));
         sRealPath = sRealPath.substring(0, sRealPath.lastIndexOf(File.separator)+1);

  Properties EnvPros = new Properties();
    
  EnvPros.put("domain", id_domain);
  EnvPros.put("workarea", gu_workarea);
  EnvPros.put("user", gu_user);
  EnvPros.put("language", sLanguage);
  EnvPros.put("skin", sSkin);
  EnvPros.put("storage", Environment.getProfilePath(GlobalDBBind.getProfileName(), "storage"));
  EnvPros.put("template", sRealPath+"includes"+File.separator+"put_stylesheet_file_name_here.xsl");

  HipergateRenderRequest portletRequest = new com.knowgate.http.portlets.HipergateRenderRequest(request);
  portletRequest.setAttribute("modified", new Date());
  portletRequest.setWindowState(WindowState.NORMAL);
  portletRequest.setProperties (EnvPros);

  HipergateRenderResponse portletResponse = new HipergateRenderResponse(response);
    
  try {

    Class oPorletCls = Class.forName (oLeft.getString(0,l));
    GenericPortlet oPorlet = (GenericPortlet) oPorletCls.newInstance();	  
    oPorlet.init(GlobalPortletConfig);
    oPorlet.render(portletRequest, portletResponse);

  } catch (Exception e) {
    out.write(e.getClass().getName()+" "+e.getMessage()+"<BR>");
    out.write(Gadgets.replace(StackTraceUtil.getStackTrace(e),"\n","<BR>"));
  }
%>
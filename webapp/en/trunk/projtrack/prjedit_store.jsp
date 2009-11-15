<%@ page import="java.io.IOException,java.net.URLDecoder,java.sql.SQLException,java.sql.Timestamp,java.sql.Statement,java.sql.PreparedStatement,java.sql.ResultSet,java.text.SimpleDateFormat,com.knowgate.jdc.JDCConnection,com.knowgate.acl.*,com.knowgate.dataobjs.*,com.knowgate.projtrack.*,com.knowgate.misc.Gadgets" language="java" session="false" %>
<%@ include file="../methods/page_prolog.jspf" %><%@ include file="../methods/dbbind.jsp" %><%@ include file="../methods/cookies.jspf" %><%@ include file="../methods/authusrs.jspf" %><%@ include file="../methods/clientip.jspf" %><%@ include file="../methods/nullif.jspf" %><%
/*
  Copyright (C) 2003  Know Gate S.L. All rights reserved.
                      C/Oña, 107 1º2 28050 Madrid (Spain)

  Redistribution and use in source and binary forms, with or without
  modification, are permitted provided that the following conditions
  are met:

  1. Redistributions of source code must retain the above copyright
     notice, this list of conditions and the following disclaimer.

  2. The end-user documentation included with the redistribution,
     if any, must include the following acknowledgment:
     "This product includes software parts from hipergate
     (http://www.hipergate.org/)."
     Alternately, this acknowledgment may appear in the software itself,
     if and wherever such third-party acknowledgments normally appear.

  3. The name hipergate must not be used to endorse or promote products
     derived from this software without prior written permission.
     Products derived from this software may not be called hipergate,
     nor may hipergate appear in their name, without prior written
     permission.

  This library is distributed in the hope that it will be useful,
  but WITHOUT ANY WARRANTY; without even the implied warranty of
  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.

  You should have received a copy of hipergate License with this code;
  if not, visit http://www.hipergate.org or mail to info@hipergate.org
*/

  response.setHeader("Cache-Control","no-cache");
  response.setHeader("Pragma","no-cache");
  response.setIntHeader("Expires", 0);

  if (autenticateSession(GlobalDBBind, request, response)<0) return;

  String sOpCode = Integer.parseInt(request.getParameter("is_new"))==1 ? "NPRJ" : "MPRJ";
  String sWorkArea = getCookie(request,"workarea",null);

  String gu_owner = getCookie(request,"workarea","");
  String gu_project = request.getParameter("gu_project");
  String nm_project = request.getParameter("nm_project").trim();
  String id_ref = request.getParameter("id_ref");
  String id_dept = request.getParameter("id_dept");
  String id_status = request.getParameter("id_status");  
  String id_parent = request.getParameter("id_parent");
  String id_previous_parent = request.getParameter("id_previous_parent");
  String sz_start = request.getParameter("dt_start")==null ? "" : request.getParameter("dt_start");
  String sz_end = request.getParameter("dt_end")==null ? "" : request.getParameter("dt_end");
  String de_project = request.getParameter("de_project");
  String gu_company = nullif(request.getParameter("gu_company"));
  String gu_contact = nullif(request.getParameter("gu_contact"));
  String gu_user = nullif(request.getParameter("gu_user"));
  
  Timestamp dt_start;
  Timestamp dt_end;
  SimpleDateFormat oDateFormat = new SimpleDateFormat("yyyy-MM-dd hh:mm:ss");
  PreparedStatement oStmt;
  ResultSet oRSet;

  if (id_parent!=null) if (id_parent.length()==0) id_parent=null;
  
  if (de_project!=null) if (de_project.length()==0) de_project=null;

  if (id_dept!=null) if (id_dept.length()==0) id_dept=null;
  
  if (id_status!=null) if (id_status.length()==0) id_status=null;
    
  if (sz_start.length()>0)
    dt_start =  new Timestamp(oDateFormat.parse(sz_start + " 00:00:00").getTime());
  else
    dt_start = null;

  if (sz_end.length()>0)
    dt_end =  new Timestamp(oDateFormat.parse(sz_end + " 00:00:00").getTime());
  else
    dt_end = null;
    
  JDCConnection oCon1 = null;
  boolean bAlreadyExists=false;
  Project oPrj = new Project();
            
  try {
    oCon1 = GlobalDBBind.getConnection("prjedit_store");  
    
    if (null==gu_project) {
      oStmt = oCon1.prepareStatement("SELECT " + DB.gu_project + " FROM  " +  DB.k_projects + " WHERE " + DB.nm_project + "=? AND id_parent=?", ResultSet.TYPE_FORWARD_ONLY, ResultSet.CONCUR_READ_ONLY);
      oStmt.setString(1, nm_project);
      oStmt.setString(2, id_parent);
      oRSet = oStmt.executeQuery();
    
      if (oRSet.next()) {
        out.write ("<HTML><HEAD><TITLE>Wait...</TITLE><" + "SCRIPT LANGUAGE='JavaScript' TYPE='text/javascript'>");
        out.write ("alert('Another Project with the same name already exists');"); 
        out.write ("window.opener.location.reload();");
        out.write ("window.history.back();");  
        out.write ("<" + "/SCRIPT" +"></HEAD></HTML>");
        oRSet.close();
        oStmt.close();
        bAlreadyExists=true;
      } // fi (oRSet.next())
      oRSet.close();
      oStmt.close();
    }
    else {
      oPrj.put(DB.gu_project, gu_project);
    }
    
    oPrj.put(DB.nm_project, nm_project);
    if (null!=id_parent)  oPrj.put(DB.id_parent, id_parent);
    if (null!=dt_start)   oPrj.put(DB.dt_start, dt_start);
    if (null!=dt_end)     oPrj.put(DB.dt_end, dt_end);
    if (null!=sWorkArea)  oPrj.put(DB.gu_owner, sWorkArea);
    if (null!=id_dept)    oPrj.put(DB.id_dept, id_dept);
    if (null!=id_status)  oPrj.put(DB.id_status, id_status);
    if (null!=de_project) oPrj.put(DB.de_project, de_project);
    if (gu_company.length()>0) oPrj.put(DB.gu_company, gu_company);
    if (gu_contact.length()>0) oPrj.put(DB.gu_contact, gu_contact);
    if (gu_user.length()>0) oPrj.put(DB.gu_user, gu_user);
    if (id_ref.length()>0) oPrj.put(DB.id_ref, id_ref);
        
    oCon1.setAutoCommit (false);
    
    if (nullif(id_parent).length()!=0 && nullif(id_previous_parent).length()==0) {
      Statement oDlte = oCon1.createStatement();
      oDlte.executeUpdate("DELETE FROM " + DB.k_project_expand + " WHERE " + DB.gu_rootprj + "='" + gu_project + "'");
      oDlte.close();
    }
    
    if (!oPrj.isNull(DB.gu_project))
      oPrj.replace(DB.pr_cost, oPrj.cost(oCon1));

    oPrj.store(oCon1);

    String sTopParent;
    
    if (nullif(id_parent).length()!=0 && nullif(id_previous_parent).length()!=0) {
      if (!id_parent.equals(id_previous_parent)) {
        
        sTopParent = new Project(id_previous_parent).topParent(oCon1);         
        new Project(sTopParent).expand(oCon1);
      }
    }
    
    if (nullif(id_parent).length()==0 && nullif(id_previous_parent).length()!=0) {

      sTopParent = new Project(id_previous_parent).topParent(oCon1);    
      new Project(sTopParent).expand(oCon1);
    }
                  
    DBAudit.log(oCon1, Project.ClassId, sOpCode, "unknown", oPrj.getString(DB.gu_project), id_parent, 0, getClientIP(request), nm_project, null);
        
    oCon1.commit();
    
    oCon1.close("prjedit_store");
  }
  catch (SQLException e) {
    if (null!=oCon1)
      if (!oCon1.isClosed()) {
        oCon1.rollback();
        oCon1.close("prjedit_store");
        oCon1 = null;
      }

    if (com.knowgate.debug.DebugFile.trace) {
      com.knowgate.dataobjs.DBAudit.log ((short)0, "CJSP", sUserIdCookiePrologValue, request.getServletPath(), "", 0, request.getRemoteAddr(), "SQLException", e.getMessage());
    }
          
    response.sendRedirect (response.encodeRedirectUrl ("../common/errmsg.jsp?title=Error de Acceso a la Base de Datos&desc=" + e.getLocalizedMessage() + "&resume=_back"));    
  }
  
  if (null==oCon1) return;
  
  oCon1 = null;
  
  if (!bAlreadyExists) {    
    out.write ("<HTML><HEAD><TITLE>Wait...</TITLE><" + "SCRIPT LANGUAGE='JavaScript1.2' TYPE='text/javascript'>");

    if (nullif(request.getParameter("is_subproject")).equals("1"))
      out.write ("window.document.location.href = 'prj_edit.jsp?gu_project="+oPrj.getString(DB.gu_project)+"&n_project="+Gadgets.URLEncode(oPrj.getString(DB.nm_project))+"&standalone=1';");
    else if (nullif(request.getParameter("is_standalone")).equals("1"))
      out.write ("self.close();");
    else if (null==gu_project)
      out.write ("window.document.location.href = 'prj_new.jsp';");      
    else
      out.write ("window.parent.location.reload();");
  
    out.write ("<" + "/SCRIPT" +"></HEAD></HTML>");
    
  } // fi(!bAlreadyExists)
%>
<%@ include file="../methods/page_epilog.jspf" %>
<%@ page import="java.util.*,java.io.*,java.math.*,java.io.IOException,java.net.URLDecoder,java.sql.SQLException,com.knowgate.jdc.*,com.knowgate.dataobjs.*,com.knowgate.acl.*,com.knowgate.hipergate.*,com.knowgate.dataxslt.PageSet,com.knowgate.dataxslt.db.*,com.knowgate.dfs.FileSystem,com.knowgate.misc.*" language="java" session="false" %>
<%@ include file="../methods/page_prolog.jspf" %><%@ include file="../methods/dbbind.jsp" %><%@ include file="../methods/cookies.jspf" %><%@ include file="../methods/authusrs.jspf" %><%@ include file="../methods/clientip.jspf" %><%@ include file="../methods/reqload.jspf" %>
<%
/*
  Copyright (C) 2008  Know Gate S.L. All rights reserved.
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

  final String sSep = System.getProperty("file.separator");

  //Recuperar parametros generales
  String id_domain = getCookie(request,"domainid","");
  String gu_workarea = request.getParameter("gu_workarea");
  
  String sUrl = "pageset_listing.jsp?selected="+request.getParameter("selected")+"&subselected="+request.getParameter("subselected")+"&doctype="+request.getParameter("doctype");

  String sDefWrkArPut = request.getRealPath(request.getServletPath());
  sDefWrkArPut = sDefWrkArPut.substring(0,sDefWrkArPut.lastIndexOf(sSep));
  sDefWrkArPut = sDefWrkArPut.substring(0,sDefWrkArPut.lastIndexOf(sSep));
  sDefWrkArPut = sDefWrkArPut + java.io.File.separator + "workareas";

  String sEnvWorkPut	 = Environment.getProfileVar(GlobalDBBind.getProfileName(),"workareasput",sDefWrkArPut);
  String sStorageRoot	 = Environment.getProfilePath(GlobalDBBind.getProfileName(),"storage");

  Properties UserProperties = new Properties();
  UserProperties.put("domain",   id_domain);
  UserProperties.put("workarea", gu_workarea);
      
  if (autenticateSession(GlobalDBBind, request, response)<0) return;
  
  String id_user = getCookie (request, "userid", null);
  JDCConnection oCon = null;
  String[] aPKs = new String[1];
  PageSetDB oPageSetDB = new PageSetDB();
    
  // Recuperar datos de formulario
  String chkItems = request.getParameter("checkeditems");  
  String a_items[] = Gadgets.split(chkItems, ',');
  StringBuffer oErrors = new StringBuffer();

  try {
    oCon = GlobalDBBind.getConnection("pageset_edit_publish");
    
    for (int i=0;i<a_items.length;i++) {
      aPKs[0] = a_items[i];
   
      if (oPageSetDB.load(oCon,aPKs)) {        
        PageDB aPages[] = oPageSetDB.getPages(oCon);
        if (null==aPages) {
    	    oErrors.append(oPageSetDB.getString("nm_pageset")+" PageSet does not contain any page suitable for publishing<BR/>");        
        } else {

    			String sFilePageSet = sStorageRoot + oPageSetDB.getString(DB.path_data);
    		  String sFileTemplate = sStorageRoot + oPageSetDB.getString(DB.path_metadata);

    			String sCompanyGUID = oPageSetDB.getStringNull(DB.gu_company, null);
    			if (sCompanyGUID!=null) PageSet.mergeCompanyInfo (oCon, sFilePageSet, sCompanyGUID);
            
    			PageSet oPageSet = new PageSet (sFileTemplate, sFilePageSet);
    			MicrositeDB oMSite = new MicrositeDB(oCon, oPageSetDB.getString(DB.gu_microsite));

  				UserProperties.put("pageset", oPageSetDB.getString(DB.gu_pageset));

				  String sAppDir;
					switch (oMSite.getShort(DB.tp_microsite)) {
					  case MicrositeDB.TYPE_XSL:
    			    sAppDir = "Mailwire";
					    break;
					  case MicrositeDB.TYPE_HTML:
    			    sAppDir = "WebBuilder";
					    break;
					  case MicrositeDB.TYPE_SURVEY:
    			    sAppDir = "Surveys";
					    break;
					  default:
    			    sAppDir = "Other";					  					  
					}

    			oPageSet.buildSite(sStorageRoot,
    									       sEnvWorkPut + sSep + gu_workarea + sSep + "apps" + sSep + sAppDir + sSep + "html" + sSep + oPageSetDB.getString(DB.gu_pageset) + sSep,
    			                   Environment.getProfile(GlobalDBBind.getProfileName()),
    			                   UserProperties);
        	
          int nPages = aPages.length;
          for (int p=0; p<nPages; p++) {
            try {
            	aPages[p].publish();
            } catch (Exception xcpt) {
    	        oErrors.append(oPageSetDB.getString("nm_pageset")+" "+xcpt.getClass().getName()+" "+xcpt.getMessage()+"<BR/>");            
            }
          } // next
        }
      } else {
    	  oErrors.append(a_items[i]+" PageSet not found<BR/>");
    	}
    } // next
  
    oCon.close("pageset_edit_publish");
  }
  catch (Exception xcpt) {
    if (oCon!=null)
      if (!oCon.isClosed()) {
        oCon.close("pageset_edit_publish");
      }      
    oCon = null;

    if (com.knowgate.debug.DebugFile.trace) {
      com.knowgate.dataobjs.DBAudit.log ((short)0, "CJSP", sUserIdCookiePrologValue, request.getServletPath(), "", 0, request.getRemoteAddr(), xcpt.getClass().getName(), xcpt.getMessage());
    }
    
    response.sendRedirect (response.encodeRedirectUrl ("../common/errmsg.jsp?title=" + xcpt.getClass().getName() + "&desc=" + xcpt.getMessage() + "&resume=_back"));
  }

  if (null==oCon) return;
    
  // Vaciar instancias
  oCon = null;
  oPageSetDB = null;
  
  if (com.knowgate.debug.DebugFile.trace) {
      com.knowgate.dataobjs.DBAudit.log ((short)0, "CJSP", sUserIdCookiePrologValue, request.getServletPath(), "", 0, request.getRemoteAddr(), "", "");
  }

	if (oErrors.length()==0) {
    response.sendRedirect(sUrl);	  
	} else {
    response.sendRedirect (response.encodeRedirectUrl ("../common/errmsg.jsp?title=Publishing finished with warnings&desc="+oErrors.toString()+"&resume="+Gadgets.URLEncode("../webbuilder/"+sUrl)));
  }
  
%><%@ include file="../methods/page_epilog.jspf" %>
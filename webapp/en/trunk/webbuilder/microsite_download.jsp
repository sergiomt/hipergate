<%@ page import="java.io.File,java.net.URLDecoder,com.knowgate.acl.*,com.knowgate.misc.Environment,com.knowgate.misc.Gadgets,com.knowgate.dfs.FileSystem" language="java" session="false" contentType="text/xml;charset=UTF-8" %><%@ include file="../methods/dbbind.jsp" %><%@ include file="../methods/cookies.jspf" %><%@ include file="../methods/authusrs.jspf" %><%
/*
  
  Copyright (C) 2003-2005  Know Gate S.L. All rights reserved.
                           C/O🪠107 1º2 28050 Madrid (Spain)

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

  if (autenticateSession(GlobalDBBind, request, response)<0) return;

  final String sSep = java.io.File.separator;
  final String sProtocol = Environment.getProfileVar(GlobalDBBind.getProfileName(), "fileprotocol", "file://");
  final String sFileSrvr = Environment.getProfileVar(GlobalDBBind.getProfileName(), "fileserver", "localhost");
  final String sStorage = Environment.getProfilePath(GlobalDBBind.getProfileName(), "storage");
  final String sTemplates = sStorage + "xslt" + sSep + "templates" + sSep;
  final String sMSiteName = request.getParameter("site_name");
  final String sFileName = request.getParameter("file_name");
  
  response.addHeader ("Pragma", "no-cache");
  response.addHeader ("cache-control", "no-store");
  response.setIntHeader("Expires", 0);
  response.setHeader("Content-Disposition","inline; filename=\"" + sMSiteName + "\"");

  
  FileSystem oFS = new FileSystem(Environment.getProfile(GlobalDBBind.getProfileName()));
  
  if (sProtocol.equals("file://"))
    out.write(oFS.readfilestr(sTemplates+sMSiteName+sSep+sFileName, null));
  else
    out.write(oFS.readfilestr(sProtocol+sSep+sFileSrvr+sTemplates+sMSiteName+sSep+sFileName, null));
%>
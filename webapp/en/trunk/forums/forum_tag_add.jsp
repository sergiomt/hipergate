<%@ page import="java.io.IOException,java.net.URLDecoder,java.sql.SQLException,com.knowgate.jdc.JDCConnection,com.knowgate.dataobjs.*,com.knowgate.acl.*,com.knowgate.forums.NewsGroup,com.knowgate.forums.NewsGroupTag" language="java" session="false" contentType="text/plain;charset=UTF-8" %><%@ include file="../methods/dbbind.jsp" %><%@ include file="../methods/cookies.jspf" %><%@ include file="../methods/authusrs.jspf" %><%@ include file="../methods/clientip.jspf" %><%@ include file="../methods/reqload.jspf" %><jsp:useBean id="GlobalCacheClient" scope="application" class="com.knowgate.cache.DistributedCachePeer"/><%
/*
  Copyright (C) 2003-2009  Know Gate S.L. All rights reserved.
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

  response.addHeader ("Pragma", "no-cache");
  response.addHeader ("cache-control", "no-store");
  response.setIntHeader("Expires", 0);

  final String PAGE_NAME = "forum_tag_add";

  if (autenticateSession(GlobalDBBind, request, response)<0) return;

  String id_user = getCookie (request, "userid", null);
      
  String gu_newsgroup = request.getParameter("gu_newsgroup");
  String tl_tag = request.getParameter("tl_tag");
      
  NewsGroupTag oNgTg = new NewsGroupTag();

  JDCConnection oConn = null;

  try {
  
    oConn = GlobalDBBind.getConnection(PAGE_NAME); 

    oConn.setAutoCommit (false);    
    oNgTg.put(DB.tl_tag, tl_tag);
    oNgTg.put(DB.gu_newsgrp, gu_newsgroup);    
    oNgTg.store(oConn);

    DBAudit.log(oConn, NewsGroup.ClassId, "NTAG", id_user, gu_newsgroup, oNgTg.getString(DB.gu_tag), 0, 0, oNgTg.getStringNull(DB.tl_tag,""), null);

    oConn.commit();
    oConn.close(PAGE_NAME);

    GlobalCacheClient.expire("NewsGroupTags["+gu_newsgroup+"]");
  }
  catch (SQLException e) {  
    disposeConnection(oConn,PAGE_NAME);
    oConn = null;

    out.write ("ERROR "+e.getMessage());
  }
  
  if (null==oConn) return;
  
  oConn = null;
  
  out.write (oNgTg.getString(DB.gu_tag));

%>
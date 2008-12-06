<%@ page import="org.apache.lucene.document.*,org.apache.lucene.search.*,org.apache.lucene.queryParser.*,org.apache.lucene.analysis.SimpleAnalyzer,java.io.IOException,java.net.URLDecoder,java.sql.SQLException,java.sql.Statement,java.sql.PreparedStatement,java.sql.ResultSet,com.knowgate.jdc.JDCConnection,com.knowgate.dataobjs.*,com.knowgate.misc.Environment" language="java" session="false" contentType="text/html;charset=UTF-8" %>
<%@ include file="../methods/dbbind.jsp" %>
<%@ include file="../methods/cookies.jspf" %>
<%@ include file="../methods/nullif.jspf" %>
<% 
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
      
  String id_domain = request.getParameter("id_domain");
  String gu_workarea = request.getParameter("gu_workarea");
  String id_user = getCookie (request, "userid", null);

  JDCConnection oConn = null;  
    
  try {
    oConn = GlobalDBBind.getConnection("lucene_search");
    
    /* TO DO: Your database access stuff */
      
    oConn.close("lucene_search");


    /* Document field list
    "workarea" 
    "container"
    "guid"     
    "title"    
    "author"   
    "text"
    
    For rebuilding index call:
    
       com.knowgate.lucene.Indexer.rebuild(Environment.getProfile(GlobalDBBind.getProfileName()), ["k_bugs"|"k_newsmsgs"]);

    */
            
    Query oQry = QueryParser.parse("fechas", "text", new SimpleAnalyzer());

    IndexSearcher oSearch = new IndexSearcher(Environment.getProfilePath(GlobalDBBind.getProfileName(), "luceneindex") + "k_bugs");

    Hits oHitSet = oSearch.search(oQry);
    
    int iHitCount = oHitSet.length();
    
    Document oDoc;
    
    for ( int h=0; h<iHitCount; h++) {
      oDoc = oHitSet.doc(h);
      
      out.write ( nullif (oDoc.get("title") ) + "<br>" );
    }
    
  }
  catch (SQLException e) {  
    if (oConn!=null)
      if (!oConn.isClosed()) {
        oConn.close("lucene_search");      
      }
    oConn = null;
    response.sendRedirect (response.encodeRedirectUrl ("../common/errmsg.jsp?title=SQLException&desc=" + e.getLocalizedMessage() + "&resume=_back"));
  }
  catch (IOException e) {
    if (oConn!=null)
      if (!oConn.isClosed()) {
        oConn.close("lucene_search");      
      }
    oConn = null;
    response.sendRedirect (response.encodeRedirectUrl ("../common/errmsg.jsp?title=IOException&desc=" + e.getMessage() + "&resume=_back"));
  }
  catch (ParseException e) {
    if (oConn!=null)
      if (!oConn.isClosed()) {
        oConn.close("lucene_search");      
      }
    oConn = null;
    response.sendRedirect (response.encodeRedirectUrl ("../common/errmsg.jsp?title=ParseException&desc=" + e.getMessage() + "&resume=_back"));
  }
  
  
  if (null==oConn) return;
    
  oConn = null;

  /* TO DO: Write HTML or redirect to another page */
%>

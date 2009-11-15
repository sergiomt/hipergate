<%@ page import="java.util.LinkedList,java.util.ListIterator,java.io.IOException,java.net.URLDecoder,java.sql.SQLException,com.knowgate.jdc.JDCConnection,com.knowgate.dataobjs.*,com.knowgate.acl.*,com.knowgate.surveys.Survey,com.knowgate.surveys.SurveyPage,com.knowgate.surveys.DataSheet" language="java" session="false" contentType="text/html;charset=UTF-8" %>
<%@ include file="../methods/dbbind.jsp" %><%@ include file="../methods/cookies.jspf" %><%@ include file="../methods/authusrs.jspf" %><%@ include file="../methods/clientip.jspf" %><%@ include file="../methods/reqload.jspf" %>
<jsp:useBean id="GlobalCacheClient" scope="application" class="com.knowgate.cache.DistributedCachePeer"/><%
/*
  Copyright (C) 2003-2005  Know Gate S.L. All rights reserved.
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

  /* Autenticate user cookie */
  // if (autenticateSession(GlobalDBBind, request, response)<0) return;
  
  String sStorage = Environment.getProfilePath(GlobalDBBind.getProfileName(), "storage");
      
  String gu_pageset = request.getParameter("gu_pageset");
  String gu_workarea = request.getParameter("gu_workarea");
  String gu_datasheet = request.getParameter("gu_datasheet");
  String id_user = getCookie (request, "userid", null);
  
  DBPersist oInfo = = new DBPersist(DB.k_pageset_datasheets, "DataSheetInfo");
  Survey oSrvy = null;
  DataSheet oData = null;
  SurveyPage oPage;
  Question oQuest;
  Answer oAnwr;
  
  JDCConnection oConn = null;
  
  try {
    oConn = GlobalDBBind.getConnection("survey_finish"); 
  
    loadRequest(oConn, request, oInfo);

    oConn.setAutoCommit (false);
    
    oInfo.store(oConn);
    
    oConn.commit();
  }
  catch (SQLException e) {  
    if (oConn!=null) {
      if (!oConn.isClosed()) {
        if (!oConn.getAutoCommit()) oConn.rollback();
        oConn.close("survey_finish");
      }
    }
    oConn = null;
    response.sendRedirect (response.encodeRedirectUrl ("../common/errmsg.jsp?title=SQLException&desc=" + e.getLocalizedMessage() + "&resume=_back"));
  }
  if (null==oConn) return;  

  LinkedList oErrors = new LinkedList();
  int i1stError=-1, nPage=1, nQuest, iAnswerIdx;
  
  try {
    oSrvy = new Survey(oConn, gu_pageset);
    oData = new DataSheet(oSrvy);
    oData.load(oConn, gu_datasheet);
    
    LinkedList oPages = oSrvy.listpages(oConn);
    ListIterator oIter = oPages.listIterator();
    while (oIter.hasNext()) {
      String sGuPage = (String) oIter.next();
      oPage = oSrvy.getPage(oConn, sGuPage, sStorage, "UTF-8");       
      if (oPage.questions!=null) {
        nQuest = oPage.questions.size();
        for (int q=0; q<nQuest; q++) {
          oQuest = oPage.getQuestion(q);
          if (oQuest.mustAnswer()) {
	    iAnswerIdx = oData.getAnswerIndex(oQuest.getName());
	    if (-1==iAnswerIdx) {
	      oErrors.add(new String("A required question is missing Page&nbsp;"+String.valueOf(nPage)+"&nbsp;Question&nbsp;"+String.valueOf(q)));
	      if (-1==i1stError) i1stError=nPage;
	    }
	    else {
	      oAnwr = oData.getAnswer(iAnswerIdx);
	      if (null==oAnwr.getValue()) {
	        oErrors.add(new String("A required question is missing&nbsp;Page&nbsp;"+String.valueOf(nPage)+"&nbsp;Question&nbsp;"+String.valueOf(q)));
	        if (-1==i1stError) i1stError=nPage;
	      }
	      else if (oAnwr.getValue().length()==0) {
	        oErrors.add(new String("A required question is missing&nbsp;Page&nbsp;"+String.valueOf(nPage)+"&nbsp;Question&nbsp;"+String.valueOf(q)));
	        if (-1==i1stError) i1stError=nPage;
	      }
	    }
          } // fi (mustAnswer())       
        } // next
      }
      nPage++;
    }  // wend
    oPage = null;
    
    oConn.close("survey_finish");
  }
  catch (SQLException e) {  
    if (oConn!=null) { if (!oConn.isClosed()) { oConn.close("survey_finish"); } }
    oConn = null;
    response.sendRedirect (response.encodeRedirectUrl ("../common/errmsg.jsp?title=SQLException&desc=" + e.getLocalizedMessage() + "&resume=_back"));
  }
  if (null==oConn) return;  
  oConn = null;

%>

<HTML>
<HEAD>
<TITLE><%=(-1==i1stError : "Cuestionario Finalizado" : "Cuestionario Incompleto")%></TITLE>
</HEAD>
<BODY>
<% if (-1==i1stError) { %>
Gracias por rellenar el cuestionario
<% } else { %>
<H1>Cuestionario Incompleto</h1>
<BR>
<%
  ListIterator oErrs = oErrors.listIterator();
  while (oErrs.hasNext()) {
    String sErr = (String) oErrs.next();
     
  }  // wend
  } %>
</BODY>
</HTML>

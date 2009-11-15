<%@ page import="java.io.File,java.io.FileNotFoundException,java.io.IOException,java.net.URLDecoder,java.sql.SQLException,org.jibx.runtime.JiBXException,com.knowgate.jdc.JDCConnection,com.knowgate.dataobjs.*,com.knowgate.acl.*,com.knowgate.misc.Environment,com.knowgate.misc.Gadgets,com.knowgate.surveys.*" language="java" session="false" contentType="text/html;charset=UTF-8" %>
<%@ include file="../methods/dbbind.jsp" %><%@ include file="../methods/cookies.jspf" %><%@ include file="../methods/authusrs.jspf" %><%@ include file="../methods/nullif.jspf" %>
<jsp:useBean id="GlobalCacheClient" scope="application" class="com.knowgate.cache.DistributedCachePeer"/><%
/*  
  Copyright (C) 2005  Know Gate S.L. All rights reserved.
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
  //if (autenticateSession(GlobalDBBind, request, response)<0) return;

  String gu_writer = getCookie (request, "userid", null);      
  String gu_workarea = request.getParameter("gu_workarea");
  String gu_pageset = request.getParameter("gu_pageset");
  String pg_page = request.getParameter("pg_page");
  String pg_previous = request.getParameter("pg_previous");
  String gu_datasheet = request.getParameter("gu_datasheet");

  int iChoiceNum;
  int iPgPage = Integer.parseInt(pg_page);
  String sValue;
  Survey oSrvy = null;
  SurveyPage oPage = null;  
  Question oQuest = null;
  Answer oAnswr;
  String sQName;
  JDCConnection oConn = null;

%><%@ include file="survey_getpage.jspf" %><%  

  DataSheet oData = new DataSheet(oSrvy);
  oData.setGuid(gu_datasheet);
  oData.put(DB.gu_writer, gu_writer);
  oData.put(DB.id_doc_status, "EDITING");
  
  final int nQuests = oPage.questions.size();
  
  for (int q=0; q<nQuests; q++) {
    oQuest = oPage.getQuestion(q);
    sQName = oQuest.getName();
    oAnswr = new Answer(gu_datasheet, gu_pageset, oPage.getString(DB.gu_page), iPgPage, sQName, q, gu_writer);
    switch (oQuest.getClassId()) {
      case Question.SubTypes.TEXT:
        oAnswr.setType("TEXT");
        oAnswr.setValue(request.getParameter(sQName));
	break;
      case Question.SubTypes.MEMO:
        oAnswr.setType("MEMO");
        oAnswr.setValue(request.getParameter(sQName));
	break;
      case Question.SubTypes.LICKERT:
        oAnswr.setType("LICKERT");
        oAnswr.setValue(request.getParameter(sQName));
	break;
      case Question.SubTypes.CHOICE:
        oAnswr.setType("CHOICE");
        oAnswr.setValue(request.getParameter(sQName));
	break;
      case Question.SubTypes.LISTCHOICE:
        oAnswr.setType("LISTCHOICE");
        oAnswr.setValue(request.getParameter(sQName));
	break;
      case Question.SubTypes.MULTICHOICE:
        oAnswr.setType("MULTICHOICE");
        iChoiceNum = 1;
        sValue = "";
        while (null!=request.getParameter(sQName+"_"+String.valueOf(iChoiceNum))) {
          if (sValue.length()==0)
            sValue = nullif(request.getParameter(sQName+"_"+String.valueOf(iChoiceNum)));
          else
            sValue += ";" + nullif(request.getParameter(sQName+"_"+String.valueOf(iChoiceNum)));
          iChoiceNum++;
        } // wend
        oAnswr.setValue(sValue);
	break;
      case Question.SubTypes.MATRIX:
  	Matrix oMatrx = (Matrix) oQuest;
        oAnswr.setType("MATRIX");
        int iRows = oMatrx.rowCount(), iCols = oMatrx.columnCount();
        sValue = "";
        if (oMatrx.isMulti()) {
          for (int r=1; r<=iRows; r++) {
            if (r>1) sValue += "|";
            sValue += nullif(request.getParameter(sQName+"_"+String.valueOf(r)+"_"+String.valueOf(1)));          
            for (int c=2; c<=iCols; c++) {
              sValue += ";" + nullif(request.getParameter(sQName+"_"+String.valueOf(r)+"_"+String.valueOf(c)));
            } // next (c)
          } // next (r)
        }
        else {
          for (int r=1; r<=iRows; r++) {
            if (r>1) sValue += "|";
            sValue += nullif(request.getParameter(sQName+"_"+String.valueOf(r)));          
          }
        }        
        oAnswr.setValue(sValue);
	break;
    } // end switch
    oData.addAnswer(oAnswr);
  }
  
  try {
    oConn = GlobalDBBind.getConnection("survey_store"); 
    
    oConn.setAutoCommit (false);
    
    oData.store(oConn);
    
    oConn.commit();
    oConn.close("survey_store");
  }
  catch (SQLException e) {  
    disposeConnection(oConn,"survey_store");
    oConn = null;
    response.sendRedirect (response.encodeRedirectUrl ("../common/errmsg.jsp?title=SQLException&desc=" + e.getLocalizedMessage() + "&resume=_back"));
  }
  if (null==oConn) return;
  oConn=null;
  
  String sRedirUrl = "survey.jsp?gu_workarea="+gu_workarea+"&gu_pageset="+gu_pageset+"&gu_datasheet="+gu_datasheet+"&pg_previous="+pg_page+"&pg_page=";
  String sRedirTarget = request.getParameter("redirect");
  if (sRedirTarget.equalsIgnoreCase("previous")) {
    response.sendRedirect (response.encodeRedirectUrl (sRedirUrl+pg_previous));  
  }
  else if (sRedirTarget.equalsIgnoreCase("current")) {
    response.sendRedirect (response.encodeRedirectUrl (sRedirUrl+pg_page));  
  }
  else if (sRedirTarget.equalsIgnoreCase("next")) {
    response.sendRedirect (response.encodeRedirectUrl (sRedirUrl+String.valueOf(oPage.getRouteToPageNumber(oData))));
  }
  else if (sRedirTarget.equalsIgnoreCase("last")) {
    response.sendRedirect (response.encodeRedirectUrl ("survey_info_f.jsp?gu_workarea="+gu_workarea+"&gu_pageset="+gu_pageset+"&gu_datasheet="+gu_datasheet+"&pg_previous="+pg_page));
  }
  else if (sRedirTarget.equalsIgnoreCase("jump")) {
    response.sendRedirect (response.encodeRedirectUrl (sRedirUrl+request.getParameter("pg_jump")));
  }
%>
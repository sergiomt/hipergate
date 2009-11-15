<%@ page import="java.io.File,java.io.FileNotFoundException,java.io.IOException,java.net.URLDecoder,java.sql.SQLException,org.jibx.runtime.JiBXException,com.knowgate.jdc.JDCConnection,com.knowgate.dataobjs.*,com.knowgate.acl.*,com.knowgate.misc.Environment,com.knowgate.misc.Gadgets,com.knowgate.surveys.*" language="java" session="false" contentType="text/html;charset=UTF-8" %>
<%@ include file="../methods/dbbind.jsp" %><%@ include file="../methods/cookies.jspf" %><%@ include file="../methods/authusrs.jspf" %>
<jsp:useBean id="GlobalCacheClient" scope="application" class="com.knowgate.cache.DistributedCachePeer"/><%!
  public static String jsEsc(String sStr) {
    String sRet = null;
    try {
      sRet = Gadgets.replace(Gadgets.replace(sStr, "\n", "\\n"), "\"", "\\\"");
    } catch (org.apache.oro.text.regex.MalformedPatternException neverthrown) {}
    return sRet;
  }
%><%
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

  String gu_pageset = request.getParameter("gu_pageset");
  String pg_page = request.getParameter("pg_page");
  String gu_datasheet = request.getParameter("gu_datasheet");

  int iPgPage = Integer.parseInt(pg_page);
  int nAnswers = 0; 
  Survey oSrvy = null;
  SurveyPage oPage = null;  
  Answer oAnswr;
  String sAName, sAType;
  JDCConnection oConn = null;

%><%@ include file="survey_getpage.jspf" %><%  

  DataSheet oData = new DataSheet(oSrvy);
  try {
    oConn = GlobalDBBind.getConnection("surveydata");
    nAnswers = oData.load(oConn, gu_datasheet, iPgPage);
    oConn.close("surveydata");
  }
  catch (SQLException e) {  
    if (oConn!=null) { if (!oConn.isClosed()) { oConn.close("surveydata"); } }
    oConn = null;
    response.sendRedirect (response.encodeRedirectUrl ("../common/errmsg.jsp?title=SQLException&desc=" + e.getLocalizedMessage() + "&resume=_back"));
  }
  if (null==oConn) return;
  oConn=null;

  out.write("function setValues() {\n");
  out.write("var df0=document.forms[0];\n");
  out.write("var rad;\n");
  out.write("var chk;\n");
  out.write("var opt;\n");
  out.write("/* "+String.valueOf(nAnswers)+" answers found for DataSheet "+gu_datasheet+" page "+pg_page+" */ \n");
  
  for (int a=0; a<nAnswers; a++) {
    oAnswr = oData.getAnswer(a);
    sAName = oAnswr.getName();
    sAType = oAnswr.getType();
    if (sAType==null) {
      out.write("/* Answer "+String.valueOf(a)+" as no type */\n");
    }
    else if (sAType.equals("TEXT") || sAType.equals("MEMO")) {
      out.write("df0."+sAName+".value=\""+jsEsc(oAnswr.getValue()));
    }
    else if (sAType.equals("LICKERT") || sAType.equals("CHOICE")) {
      out.write("rad=df0."+sAName+";\n");
      out.write("for (var l=0; l<rad.length; l++) { if (rad[l].value==\""+oAnswr.getValue()+"\") { rad[l].checked=true; break; } }\n");
    }
    else if (sAType.equals("MULTICHOICE")) {
      String[] aElements = Gadgets.split(oAnswr.getValue(),";");
      if (aElements!=null) {
        for (int m=0; m<aElements.length; m++) {
          if (aElements[m].length()>0)
            out.write("df0."+sAName+"_"+String.valueOf(m+1)+".value=\""+aElements[m]+"\";\n");
        } // next
      } // fi (aElements!=null)
    }
    else if (sAType.equals("LISTCHOICE")) {
      out.write("opt=df0."+sAName+".options;\n");
      out.write("for (var i=0;i<opt.length;i++) { if (opt[i].value==\""+oAnswr.getValue()+"\") { opt.selectedIndex=i; break; } }\n");
    }
    else if (sAType.equals("MATRIX")) {
      String[] aCols;
      String[] aRows = Gadgets.split(oAnswr.getValue(),'|');
      if (null!=aRows) {      
        if (oAnswr.getValue().indexOf(';')<0) {

          // *******************************************
          // Process radio buttons (1 value per column)

	  Matrix oMtrx = (Matrix)oPage.getQuestion(sAName);	  
	  if (null!=oMtrx) {
            int iCols = ((Matrix)oPage.getQuestion(sAName)).columnCount();          
            for (int r=0; r<aRows.length; r++) {
              String sCell = aRows[r];
              for (int c=0; c<iCols; c++) {         
                out.write("if (df0."+sAName+"_"+String.valueOf(r+1)+"["+String.valueOf(c)+"].value==\""+sCell+"\") { df0."+sAName+"_"+String.valueOf(r+1)+"["+String.valueOf(c)+"].checked=true; }\n");
              } // next (c)
            } // next (r)
          } else {
            out.write("/* Question "+sAName+" not found at survey definition for page "+pg_page+"*/\n");
          }
        } else {

          // ***********************************************
          // Process checkboxes (multiple values per column)

          for (int r=0; r<aRows.length; r++) {
            aCols = Gadgets.split(aRows[r], ';');
            if (aCols!=null) {
              for (int c=0; c<aCols.length; c++) {
                out.write("if (df0."+sAName+"_"+String.valueOf(r+1)+"_"+String.valueOf(c+1)+".value==\""+aCols[c]+"\") { df0."+sAName+"_"+String.valueOf(r+1)+"_"+String.valueOf(c+1)+".checked=true; }\n");
              } // next(c)
            } // fi (aCols!=null)
          } // next (r)
        } // fi
      } // fi if (aRows!=null)
    }
    else {
      out.write("/* unrecognized type "+sAType+" for Answer "+String.valueOf(a)+"*/\n");
    }    
  } // next
  out.write("}\n");
%>
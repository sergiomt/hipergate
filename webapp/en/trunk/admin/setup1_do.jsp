<%@ page language="java" session="false" contentType="text/html;charset=UTF-8" %>
<% 
/*
  Copyright (C) 2004  Know Gate S.L. All rights reserved.
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

  Class c;

  int iErrorLevel = 0;
  String sErrors = "";
  
  try {
    c = Class.forName("javax.ejb.CreateException");
  }
  catch (ClassNotFoundException e) {
    iErrorLevel = 2;
    sErrors += "ClassNotFoundException javax.ejb.CreateException j2ee.jar<BR>"; 
  }
  catch (LinkageError l) {
    iErrorLevel = 2;
    sErrors += "LinkageError javax.ejb.CreateException j2ee.jar " + l.getMessage() + "<BR>"; 
  }

  try {
    c = Class.forName("org.apache.xerces.parsers.SAXParser");
  }
  catch (ClassNotFoundException e) {
    iErrorLevel = 2;
    sErrors += "ClassNotFoundException org.apache.xerces.parsers.SAXParser xercesImpl.jar<BR>"; 
  }
  catch (LinkageError l) {
    iErrorLevel = 2;
    sErrors += "LinkageError org.apache.xerces.parsers.SAXParser xercesImpl.jar " + l.getMessage() + "<BR>"; 
  }

  try {
    c = Class.forName("org.xml.sax.helpers.ParserFactory");
  }
  catch (ClassNotFoundException e) {
    iErrorLevel = 2;
    sErrors += "ClassNotFoundException org.xml.sax.helpers.ParserFactory xmlParserAPIs.jar<BR>"; 
  }
  catch (LinkageError l) {
    iErrorLevel = 2;
    sErrors += "LinkageError org.xml.sax.helpers.ParserFactory xmlParserAPIs.jar " + l.getMessage() + "<BR>"; 
  }

  try {
    c = Class.forName("bsh.Interpreter");
  }
  catch (ClassNotFoundException e) {
    iErrorLevel = 2;
    sErrors += "ClassNotFoundException bsh.Interpreter beanshell.bsh.jar<BR>"; 
  }
  catch (LinkageError l) {
    iErrorLevel = 2;
    sErrors += "LinkageError bsh.Interpreter beanshell.bsh.jar " + l.getMessage() + "<BR>"; 
  }

  try {
    c = Class.forName("org.jibx.runtime.JiBXException");
  }
  catch (ClassNotFoundException e) {
    iErrorLevel = 2;
    sErrors += "ClassNotFoundException org.jibx.runtime.JiBXException jibx-run.jar<BR>"; 
  }
  catch (LinkageError l) {
    iErrorLevel = 2;
    sErrors += "LinkageError org.jibx.runtime.JiBXException jibx-run.jar " + l.getMessage() + "<BR>"; 
  }

  try {
    c = Class.forName("org.apache.oro.text.regex.MalformedPatternException");
  }
  catch (ClassNotFoundException e) {
    iErrorLevel = 2;
    sErrors += "ClassNotFoundException org.apache.oro.text.regex.MalformedPatternException jakarta-oro.jar<BR>"; 
  }
  catch (LinkageError l) {
    iErrorLevel = 2;
    sErrors += "LinkageError org.apache.oro.text.regex.MalformedPatternException jakarta-oro.jar " + l.getMessage() + "<BR>"; 
  }

  try {
    c = Class.forName("org.apache.poi.hpsf.SummaryInformation");
  }
  catch (ClassNotFoundException e) {
    iErrorLevel = 2;
    sErrors += "ClassNotFoundException org.apache.poi.hpsf.SummaryInformation poi.jar<BR>"; 
  }
  catch (LinkageError l) {
    iErrorLevel = 2;
    sErrors += "LinkageError org.apache.poi.hpsf.SummaryInformation poi.jar " + l.getMessage() + "<BR>"; 
  }

  try {
    c = Class.forName("com.novell.ldap.LDAPException");
  }
  catch (ClassNotFoundException e) {
    iErrorLevel = 2;
    sErrors += "ClassNotFoundException com.novell.ldap.LDAPException novell.ldap.jar<BR>"; 
  }
  catch (LinkageError l) {
    iErrorLevel = 2;
    sErrors += "LinkageError com.novell.ldap.LDAPException novell.ldap.jar " + l.getMessage() + "<BR>"; 
  }
  
  try {
    c = Class.forName("java.awt.MediaTracker");
  }
  catch (ClassNotFoundException e) {
    iErrorLevel = 2;
    sErrors += "ClassNotFoundException java.awt.MediaTracker rt.jar<BR>"; 
  }
  catch (LinkageError l) {
    iErrorLevel = 2;
    sErrors += "LinkageError java.awt.MediaTracker rt.jar " + l.getMessage() + "<BR>"; 
  }
  
  try {
    c = Class.forName("javax.media.jai.util.ImagingException");
  }
  catch (ClassNotFoundException e) {
    iErrorLevel = 2;
    sErrors += "ClassNotFoundException javax.media.jai.util.ImagingException sun.jai-jai_core.jar<BR>"; 
  }
  catch (LinkageError l) {
    iErrorLevel = 2;
    sErrors += "LinkageError javax.media.jai.util.ImagingException sun.jai-jai_core.jar " + l.getMessage() + "<BR>"; 
  }

  try {
    c = Class.forName("com.sun.media.jai.codec.ImageCodec");
  }
  catch (ClassNotFoundException e) {
    iErrorLevel = 2;
    sErrors += "ClassNotFoundException com.sun.media.jai.codec.ImageCodec sun.jai-jai_codec.jar<BR>"; 
  }
  catch (LinkageError l) {
    iErrorLevel = 2;
    sErrors += "LinkageError com.sun.media.jai.codec.ImageCodec sun.jai-jai_codec.jar " + l.getMessage() + "<BR>"; 
  }

  try {
    c = Class.forName("javax.activation.UnsupportedDataTypeException");
  }
  catch (ClassNotFoundException e) {
    iErrorLevel = 2;
    sErrors += "ClassNotFoundException javax.activation.UnsupportedDataTypeException sun.activation.jar<BR>"; 
  }
  catch (LinkageError l) {
    iErrorLevel = 2;
    sErrors += "LinkageError javax.activation.UnsupportedDataTypeException sun.activation.jar " + l.getMessage() + "<BR>"; 
  }

  try {
    c = Class.forName("javax.activation.UnsupportedDataTypeException");
  }
  catch (ClassNotFoundException e) {
    iErrorLevel = 2;
    sErrors += "ClassNotFoundException javax.activation.UnsupportedDataTypeException sun.activation.jar<BR>"; 
  }
  catch (LinkageError l) {
    iErrorLevel = 2;
    sErrors += "LinkageError javax.activation.UnsupportedDataTypeException sun.activation.jar " + l.getMessage() + "<BR>"; 
  }

  try {
    c = Class.forName("javax.portlet.PortletException");
  }
  catch (ClassNotFoundException e) {
    iErrorLevel = 2;
    sErrors += "ClassNotFoundException javax.portlet.PortletException sun.portlet.jar<BR>"; 
  }
  catch (LinkageError l) {
    iErrorLevel = 2;
    sErrors += "LinkageError javax.portlet.PortletException sun.portlet.jar " + l.getMessage() + "<BR>"; 
  }

%>
<HTML>
<HEAD>
  <META HTTP-EQUIV="Content-Type" CONTENT="text/html; charset=UTF-8">
  <SCRIPT SRC="../javascript/cookies.js"></SCRIPT>  
  <SCRIPT SRC="../javascript/setskin.js"></SCRIPT>
</HEAD>
<BODY CLASS="textplain">
<% if (sErrors.length()>0) { %>
<FONT COLOR="red">Warning about libraries not found</FONT>
<BR/>
<%=sErrors%>
<% } %>
</BODY>
</HTML>
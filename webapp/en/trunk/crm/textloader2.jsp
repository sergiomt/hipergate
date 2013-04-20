<%@ page import="java.io.IOException,java.net.URLDecoder,java.io.File,java.io.FileInputStream,java.io.InputStreamReader,java.sql.SQLException,com.oreilly.servlet.MultipartRequest,org.apache.oro.text.regex.MalformedPatternException,com.knowgate.jdc.JDCConnection,com.knowgate.dataobjs.*,com.knowgate.acl.*,com.knowgate.misc.Environment,com.knowgate.misc.Gadgets,com.knowgate.hipergate.datamodel.ImportLoader,com.knowgate.crm.ContactLoader,com.knowgate.crm.OportunityLoader,com.knowgate.debug.DebugFile" language="java" session="false" contentType="text/html;charset=UTF-8" %>
<%@ include file="../methods/dbbind.jsp" %><%@ include file="../methods/cookies.jspf" %><%@ include file="../methods/authusrs.jspf" %><%@ include file="../methods/nullif.jspf" %><%!

  final static int TYPE_TEXT = 0;
  final static int TYPE_INT = 1;
  final static int TYPE_DEC = 2;
  final static int TYPE_DATE1 = 3;
  final static int TYPE_DATE2 = 4;
  final static int TYPE_DATE3 = 5;
  final static int TYPE_DATE4 = 6;
  final static int TYPE_DATE5 = 7;
  final static int TYPE_DATE6 = 8;
  
  public static int detectType(String sInput, String sDecimalDelimiter) {
    String sTrim = sInput.trim();
    try {
      if (Gadgets.matches(sTrim,"-?\\d+"))
        return TYPE_INT;
      else if (Gadgets.matches(sTrim,"-?\\d+"+sDecimalDelimiter+"?\\d+"))
        return TYPE_DEC;
      else if (Gadgets.matches(sTrim,"\\d{4}-\\d{2}-\\d{2}")) 
        return TYPE_DATE1;
      else if (Gadgets.matches(sTrim,"\\d{4}/\\d{2}/\\d{2}")) 
        return TYPE_DATE2;
      else if (Gadgets.matches(sTrim,"\\d{2}-\\d{2}-\\d{4}")) 
        return TYPE_DATE3;
      else if (Gadgets.matches(sTrim,"\\d{2}/\\d{2}/\\d{4}")) 
        return TYPE_DATE4;
    } catch (MalformedPatternException neverthrown) {}
    return TYPE_TEXT;
  }
%><% 

  if (autenticateSession(GlobalDBBind, request, response)<0) return;

  String id_domain = null, gu_workarea = null, nm_workarea = null;

  Cookie aCookies[] = request.getCookies();
    
  if (null != aCookies) {
      for (int c=0; c<aCookies.length; c++) {
      	if (aCookies[c].getName().equals("workarea")) {
          gu_workarea = java.net.URLDecoder.decode(aCookies[c].getValue());
        } else if (aCookies[c].getName().equals("workareanm")) {
          nm_workarea = java.net.URLDecoder.decode(aCookies[c].getValue());
        } else if (aCookies[c].getName().equals("domainid")) {
          id_domain = java.net.URLDecoder.decode(aCookies[c].getValue());
        }  
      } // for      
  } // fi
  

  String sTmpDir = Environment.getProfileVar(GlobalDBBind.getProfileName(), "temp", Environment.getTempDir());

  File oTmp = new File(sTmpDir);
  if (!oTmp.canWrite()) {
    response.sendRedirect (response.encodeRedirectUrl ("../common/errmsg.jsp?title=SecurityException&desc=Cannot write into directory "+sTmpDir+"&resume=_back"));  
    return;
  }

  sTmpDir = Gadgets.chomp(sTmpDir,File.separator) + gu_workarea;
  oTmp = new File(sTmpDir);
  if (!oTmp.exists()) oTmp.mkdir();

  int iMaxPostSize = Integer.parseInt(Environment.getProfileVar(GlobalDBBind.getProfileName(), "maxfileupload", "10485760"));

  ImportLoader oImpLoad = null;
  MultipartRequest oReq = new MultipartRequest(request, sTmpDir, iMaxPostSize, "UTF-8");

  String id_action = oReq.getParameter("sel_action");
  String id_type = oReq.getParameter("sel_type");
  char tx_delimiter = oReq.getParameter("sel_delim").charAt(0);
  if (tx_delimiter=='T') tx_delimiter = '\t';
  String tx_decimal = oReq.getParameter("sel_decimal");
  String id_encoding = oReq.getParameter("sel_encoding");
  String nu_maxerrors = oReq.getParameter("maxerrors");
  boolean bo_colnames = nullif(oReq.getParameter("colnames")).equals("1");
  String is_loadlookups = nullif(oReq.getParameter("loadlookups")).equals("INSERTLOOKUPS") ? "INSERTLOOKUPS" : "";
  String is_recoverable = nullif(oReq.getParameter("recoverable")).equals("RECOVERABLE") ? "RECOVERABLE" : "UNRECOVERABLE";
  String bo_allcaps = nullif(oReq.getParameter("allcaps")).equals("ALLCAPS") ? "ALLCAPS" : "";
  String gu_list = oReq.getParameter("sel_list");
  String de_list = oReq.getParameter("de_list");

  File oTxtFile = oReq.getFile(0);
  int iFLen = (int) oTxtFile.length();
  
  if (iFLen==0) {
    response.sendRedirect (response.encodeRedirectUrl ("../common/errmsg.jsp?title=IOException&desc=Input file is empty&resume=_back"));
    return;
  }
  
  if (iFLen>65000) iFLen = 65000;
  char aBuffer[] = new char[iFLen];

  FileInputStream oInStrm = new FileInputStream(oTxtFile);
  InputStreamReader oReader = new InputStreamReader(oInStrm, id_encoding);
  int iReaded = oReader.read(aBuffer, 0, iFLen);  
  oReader.close();
  oInStrm.close();
  
  int iFlags = 0;
  int iSkip = ( (int) aBuffer[0] == 65279 || (int) aBuffer[0] == 65534 ? 1 : 0);
  String sDelimitedTxt = Gadgets.removeChar(new String(aBuffer, iSkip, iReaded-iSkip), '\r');
  String[] aLines = Gadgets.split(sDelimitedTxt, "\n");
  int iLines = aLines.length;
  if (iLines>5) iLines=5;

  JDCConnection oConn = null;  
    
  try {
    oConn = GlobalDBBind.getConnection("textloader2");

    if (id_type.equals("CONTACTS")) {
      oImpLoad = new ContactLoader(oConn);
       iFlags |= ContactLoader.WRITE_CONTACTS|ContactLoader.WRITE_COMPANIES|ContactLoader.WRITE_ADDRESSES;
    } else if (id_type.equals("COMPANIES")) {
       oImpLoad = new ContactLoader(oConn);
       iFlags |= ContactLoader.WRITE_COMPANIES|ContactLoader.WRITE_ADDRESSES;;
    } else if (id_type.equals("OPORTUNITIES")) {
       oImpLoad = new OportunityLoader();
    }
      
    oConn.close("textloader2");
  }
  catch (SQLException e) {  
    if (oConn!=null)
      if (!oConn.isClosed()) {
        oConn.close("textloader2");      
      }
    oConn = null;
    response.sendRedirect (response.encodeRedirectUrl ("../common/errmsg.jsp?title="+e.getClass().getName()+"&desc=" + e.getMessage() + "&resume=_back"));
  }
  catch (NumberFormatException e) {
    disposeConnection(oConn,"textloader2");
    oConn = null;
    response.sendRedirect (response.encodeRedirectUrl ("../common/errmsg.jsp?title=NumberFormatException&desc=" + e.getMessage() + "&resume=_back"));
  }
  if (null==oConn) return;    
  oConn = null;
  int iType;
  int iCols;
  String[] aCols = Gadgets.split(aLines[0], tx_delimiter);
  int i1stLinColCount = aCols.length;
  String[] aColNames = oImpLoad.columnNames();
  int iColNames = aColNames.length;
%>
<HTML>
<HEAD>
  <TITLE>hipergate :: Contact Loader</TITLE>
  <SCRIPT TYPE="text/javascript" SRC="../javascript/cookies.js"></SCRIPT>  
  <SCRIPT TYPE="text/javascript" SRC="../javascript/setskin.js"></SCRIPT>
  <SCRIPT TYPE="text/javascript" DEFER="defer">
    <!--
      function validate() {
	return window.confirm("You are about to import the selected file. Are you sure that you want to proceed?");
      } // validate;
    //-->
  </SCRIPT>
</HEAD>
<BODY  TOPMARGIN="8" MARGINHEIGHT="8">
  <FORM method="post" ACTION="textloader3.jsp" onsubmit="return validate()">
  <INPUT TYPE="hidden" NAME="id_domain" VALUE="<%=id_domain%>">
  <INPUT TYPE="hidden" NAME="gu_workarea" VALUE="<%=gu_workarea%>">
  <INPUT TYPE="hidden" NAME="nm_workarea" VALUE="<%=nm_workarea%>">
  <INPUT TYPE="hidden" NAME="nm_file" VALUE="<%=oTxtFile.getName()%>">
  <INPUT TYPE="hidden" NAME="id_encoding" VALUE="<%=id_encoding%>">
  <INPUT TYPE="hidden" NAME="id_action" VALUE="<%=id_action%>">
  <INPUT TYPE="hidden" NAME="id_type" VALUE="<%=id_type%>">
  <INPUT TYPE="hidden" NAME="tx_delimiter" VALUE="<%=oReq.getParameter("sel_delim")%>">
  <INPUT TYPE="hidden" NAME="nu_cols" VALUE="<%=String.valueOf(i1stLinColCount)%>">
  <INPUT TYPE="hidden" NAME="bo_colnames" VALUE="<%=(bo_colnames ? "1" : "0")%>">
  <INPUT TYPE="hidden" NAME="nu_maxerrors" VALUE="<%=nu_maxerrors%>">
  <INPUT TYPE="hidden" NAME="is_recoverable" VALUE="<%=is_recoverable%>">
  <INPUT TYPE="hidden" NAME="is_loadlookups" VALUE="<%=is_loadlookups%>">
  <INPUT TYPE="hidden" NAME="bo_allcaps" VALUE="<%=bo_allcaps%>">
  <INPUT TYPE="hidden" NAME="gu_list" VALUE="<%=gu_list%>">
  <INPUT TYPE="hidden" NAME="de_list" VALUE="<%=de_list%>">
  
  <TABLE SUMMARY="Form Title" WIDTH="100%">
    <TR><TD><IMG SRC="../images/images/spacer.gif" HEIGHT="4" WIDTH="1" BORDER="0"></TD></TR>
    <TR><TD CLASS="striptitle"><FONT CLASS="title1">Contact Loader</FONT></TD></TR>
  </TABLE>  
  <TABLE SUMMARY="Preview">
<%
      out.write("<TR>\n");
      if (bo_colnames) {
        for (int c=0; c<i1stLinColCount; c++) {
          out.write("      <TD><SELECT CLASS=\"combomini\" NAME=\"colname"+String.valueOf(c+1)+"\"><OPTION VALUE=\"\">Ignore</OPTION>");
          boolean bColFound = false;
          for (int n=0; n<iColNames && !bColFound; n++) {
            if (aCols[c].length()>0) bColFound = aCols[c].equalsIgnoreCase(aColNames[n]);
            if (bColFound) out.write("<OPTION VALUE=\""+aColNames[n]+"\" SELECTED>"+aColNames[n]+"</OPTION>");
          } // next (n)
          if (!bColFound) {
            for (int n=0; n<iColNames; n++)
              out.write("<OPTION VALUE=\""+aColNames[n]+"\">"+aColNames[n]+"</OPTION>");
          }
          out.write("</TD>\n");
        } // next
      } else {
        for (int c=0; c<i1stLinColCount; c++) {
          out.write("      <TD><SELECT CLASS=\"combomini\" NAME=\"colname"+String.valueOf(c+1)+"\"><OPTION VALUE=\"\">Ignore</OPTION>");
          for (int n=0; n<iColNames; n++) out.write("<OPTION VALUE=\""+aColNames[n]+"\">"+aColNames[n]+"</OPTION>");
          out.write("</TD>\n");
        } // next
      }
      out.write("</TR>\n");
      out.write("<TR>\n");
      if (bo_colnames && iLines>1) aCols = Gadgets.split(aLines[1], tx_delimiter);
      iCols = aCols.length;
      if (iCols>i1stLinColCount) iCols=i1stLinColCount;
      for (int c=0; c<iCols; c++) {
	iType = detectType(aCols[c], tx_decimal);
        out.write("<TD><SELECT CLASS=\"combomini\" NAME=\"coltype"+String.valueOf(c+1)+"\">");
        out.write("<OPTION VALUE=\"VARCHAR\" "+(TYPE_TEXT==iType ? "SELECTED" : "")+">Text</OPTION>");
        out.write("<OPTION VALUE=\"INTEGER\" "+(TYPE_INT==iType ? "SELECTED" : "")+">Integer</OPTION>");
        out.write("<OPTION VALUE=\"DECIMAL\" "+(TYPE_DEC==iType ? "SELECTED" : "")+">Decimal</OPTION>");
        out.write("<OPTGROUP LABEL=\"Date\">");
        out.write("<OPTION VALUE=\"DATE 'yyyy-MM-dd'\" "+(TYPE_DATE1==iType ? "SELECTED" : "")+">YYYY-MM-DD</OPTION>");
        out.write("<OPTION VALUE=\"DATE 'yyyy/MM/dd'\" "+(TYPE_DATE2==iType ? "SELECTED" : "")+">YYYY/MM/DD</OPTION>");
        out.write("<OPTION VALUE=\"DATE 'dd-MM-yyyy'\" "+(TYPE_DATE3==iType ? "SELECTED" : "")+">DD-MM-YYYY</OPTION>");
        out.write("<OPTION VALUE=\"DATE 'dd/MM/yyyy'\" "+(TYPE_DATE4==iType ? "SELECTED" : "")+">DD/MM/YYYY</OPTION>");
        out.write("<OPTION VALUE=\"DATE 'MM-dd-yyyy'\">MM-DD-YYYY</OPTION>");
        out.write("<OPTION VALUE=\"DATE 'MM/dd/yyyy'\">MM/DD/YYYY</OPTION>");
        out.write("<OPTGROUP>");
        out.write("</TD>\n");
      } // next
      out.write("</TR>\n");
      for (int l=(bo_colnames ? 1 : 0); l<iLines; l++) {
        out.write("<TR>\n");
        aCols = Gadgets.split(aLines[l], tx_delimiter);
        iCols = aCols.length;
        if (iCols>i1stLinColCount) iCols=i1stLinColCount;
        for (int c=0; c<iCols; c++) {
          out.write("<TD CLASS=\"textsmall\">"+aCols[c]+"</TD>");
        } 
        out.write("</TR>\n");
      }
    %>
    </TR>
  </TABLE>
  <INPUT TYPE="button" class="pushbutton" VALUE="Previous" TITLE="ALT+b" ACCESSKEY="b" onclick="document.location='textloader2undo.jsp?action=_back&workarea=<%=gu_workarea%>&filename=<%=oTxtFile.getName()%>'">
  &nbsp;&nbsp;&nbsp;
  <INPUT TYPE="submit" class="pushbutton" VALUE="Import" TITLE="ALT+i" ACCESSKEY="i">
  &nbsp;&nbsp;&nbsp;
  <INPUT TYPE="button" class="closebutton" VALUE="Cancel" TITLE="ALT+c" ACCESSKEY="c" onclick="document.location='textloader2undo.jsp?action=_close&workarea=<%=gu_workarea%>&filename=<%=oTxtFile.getName()%>'">
  </FORM>
</BODY>
</HTML>
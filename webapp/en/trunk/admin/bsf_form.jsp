<%@ page import="java.util.Properties,java.io.File,java.io.FileInputStream,java.io.IOException,java.net.URLDecoder,com.knowgate.misc.Environment" language="java" session="false" contentType="text/html;charset=UTF-8" %>
<%@ include file="../methods/dbbind.jsp" %>
<%@ include file="../methods/cookies.jspf" %>
<%@ include file="../methods/authusrs.jspf" %>
<%@ include file="../methods/clientip.jspf" %>
<%   
  String sSkin = getCookie(request, "skin", "default");
  String sLanguage = getNavigatorLanguage(request);
  String sScript = request.getParameter("script");
  
  String sStorage = Environment.getProfileVar(GlobalDBBind.getProfileName(), "storage");
  File oScripts = new File(sStorage + "/scripts");
  String aFiles[] = oScripts.list();
  
  File oSource;
  FileInputStream oStream;
  byte byBuffer[];
  String sSource = "";
  String aParams[] = { null, null, null, null, null, null, null, null, null, null };
  int iParam, iNameStart, iNameEnd, iOffset, iParamCount=0;
  
  if (null!=sScript)
    if (sScript.length()>0) {
      oSource = new File(sStorage + "/scripts/" + sScript);
      byBuffer = new byte[new Long(oSource.length()).intValue()];
      oStream = new FileInputStream(oSource);
      oStream.read(byBuffer);
      oStream.close();
      oStream = null;
      sSource = new String(byBuffer);
      byBuffer = null;
      oSource = null;
      
      iOffset = 0;
      do {
        iParam = sSource.indexOf("@param", iOffset);
        if (iParam<0) break;
        iNameStart = sSource.indexOf(" ", iParam);
        while (sSource.charAt(iNameStart)<=32) iNameStart++;
        if (iNameStart>=sSource.length()) break;        
        iOffset = iNameEnd = sSource.indexOf(" ", iNameStart);
	aParams[iParamCount++] = sSource.substring(iNameStart, iNameEnd);
      } while (true);
    } // fi (sScript)       
%>

<HTML LANG="<% out.write(sLanguage); %>">
<HEAD>
  <SCRIPT LANGUAGE="JavaScript" SRC="../javascript/cookies.js"></SCRIPT>
  <SCRIPT LANGUAGE="JavaScript" SRC="../javascript/setskin.js"></SCRIPT>
  <SCRIPT LANGUAGE="JavaScript" SRC="../javascript/combobox.js"></SCRIPT>
  <SCRIPT LANGUAGE="JavaScript" TYPE="text/javascript">
  <!--
    function loadSource() {
      window.location = "bsf_form.jsp?script=" + escape(getCombo(document.forms[0].sel_script));
    }
    
  //-->
  </SCRIPT>
  <TITLE>hipergate :: Java Shell</TITLE>
</HEAD>
<BODY  TOPMARGIN="8" MARGINHEIGHT="8">
  <FORM NAME="" METHOD="post" ACTION="bsh_exec.jsp">
    <TABLE><TR><TD WIDTH="750" CLASS="striptitle"><FONT CLASS="title1">Java Shell</FONT></TD></TR></TABLE>    
    <TABLE CLASS="formback">
      <TR><TD>
        <TABLE WIDTH="100%" CLASS="formfront">
          <TR>
            <TD ALIGN="right" WIDTH="80"><FONT CLASS="formstrong">Script</FONT></TD>
            <TD ALIGN="left">
              <SELECT NAME="sel_script" STYLE="font-family:Courier New;font-size:10pt" onChange="loadSource()">
                <OPTION VALUE=""></OPTION>
<%		for (int f=0; f<aFiles.length; f++)
		  if (aFiles[f].endsWith(".java")) {
		    out.write("<OPTION VALUE=\"" + aFiles[f] + "\"");
		    if (aFiles[f].equals(sScript)) out.write(" SELECTED");
		    out.write(">" + aFiles[f].substring(0,aFiles[f].length()-5) + "</OPTION>");
		  }
%>
              </SELECT>
            </TD>
          </TR>
          <TR>
            <TD ALIGN="right" WIDTH="80"></TD>
            <TD ALIGN="left">
	      <TEXTAREA STYLE="font-family:Courier New;font-size:8pt" NAME="tx_script" ROWS="15" COLS="91"><%=sSource%></TEXTAREA>
            </TD>
          </TR>
          <TR>
            <TD ALIGN="right" WIDTH="80"><FONT CLASS="formstrong">Parameters</FONT></TD>
            <TD ALIGN="left">
              <TABLE BORDER="0">
<%	      for (int p=0; p<iParamCount; p++) {
	        out.write("                <TR><TD ALIGN=\"right\"><FONT CLASS=\"textplain\">" + aParams[p] + ": </FONT></TD><TD><INPUT TYPE=\"text\" STYLE=\"font-family:Courier New;font-size:9pt\" NAME=\"" + aParams[p] + "\" SIZE=50></TD></TR>");
	      } // next (p)
%>		
              </TABLE>
            </TD>
          </TR>
          <TR>
            <TD COLSPAN="2"><HR></TD>
          </TR>
          <TR>
    	    <TD COLSPAN="2" ALIGN="center">
              <INPUT TYPE="submit" ACCESSKEY="x" VALUE="Run" CLASS="pushbutton" STYLE="width:80" TITLE="ALT+x">&nbsp;
    	      &nbsp;&nbsp;<INPUT TYPE="button" ACCESSKEY="c" VALUE="Cancel" CLASS="closebutton" STYLE="width:80" TITLE="ALT+c" onclick="window.close()">
    	      <BR><BR>
    	    </TD>	            
        </TABLE>
      </TD></TR>
    </TABLE>                 
  </FORM>
</BODY>
</HTML>

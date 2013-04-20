<%@ page import="com.knowgate.misc.Environment" language="java" session="false" contentType="text/html;charset=UTF-8" %>
<% String sProfile = request.getParameter("profile");
   if (null==sProfile) sProfile="hipergate";

%>
<HTML>
<HEAD>
  <META HTTP-EQUIV="Content-Type" CONTENT="text/html; charset=UTF-8">
  <SCRIPT TYPE="text/javascript" SRC="../javascript/cookies.js"></SCRIPT>  
  <SCRIPT TYPE="text/javascript" SRC="../javascript/setskin.js"></SCRIPT>
  <SCRIPT TYPE="text/javascript" SRC="../javascript/combobox.js"></SCRIPT>
</HEAD>
<BODY onload="setCombo(document.forms[0].sel_profile,'<%=sProfile%>')">
  <table width="100%" cellspacing="0" cellpadding="0" border="0">
    <tr>
      <td align="left" class="striptitle">
        <font class="title1">SQL Query</font>
      </td>
      <td align="right">
        <table width="200" cellspacing="0" cellpadding="0" border="0">
        <!-- Linea de arriba menu superior derecho -->
        <tr>
          <!-- col 1 -->
          <td width="3"  height="3"><img src="../images/images/tabmenu/esq1.gif" width="3" height="3" border="0"></td>
          <td width="24" height="3" class="opcion" background="../images/images/tabmenu/opcion1.gif"></td>

          <td width="50" height="3" class="opcion" background="../images/images/tabmenu/opcion1.gif"></td>
          <td width="5"  height="3"><img src="../images/images/tabmenu/opcion_med.gif" width="5" height="3" border="0"></td>
          <!-- col 2 -->
          <td width="24" height="3" class="opcion" background="../images/images/tabmenu/opcion1.gif"></td>
          <td width="80" height="3" class="opcion" background="../images/images/tabmenu/opcion1.gif"></td>
          <td width="3"  height="3"><img src="../images/images/tabmenu/esq2.gif" width="3" height="3" border="0"></td>
        </tr>
        <!-- Linea del medio menu superior derecho -->
        <tr>
          <!-- linea izquierda -->
          <td width="3" background="../images/images/tabmenu/opcion_a.gif" class="menu1"><img src="../images/images/tabmenu/transp.gif" width="3" height="1"></td>
          <!-- col 1 -->
          <td width="24" align="top" class="menu1"><img src="../images/images/tabmenu/kgicon.gif" width="24" height="22" border="0"></td>
          <td width="50" align="center" class="menu1"><a href="../common/desktop.jsp" class="opcion" target="_top" title="Main Menu">Menu</a></td>
          <td width="5" background="../images/images/tabmenu/opcion_ab.gif" class="menu1"></td>
          <!-- col 2 -->
          <td width="24" align="top" class="menu1"><img src="../images/images/tabmenu/disconnect.gif" width="24" height="22" border="0"></td>

          <td width="80" align="center" class="menu1"><a href="../index.html" target="_top" class="opcion" title="Disconnect">Disconnect</a></td>
          <!-- linea derecha -->
          <td width="3" background="../images/images/tabmenu/opcion_b.gif" class="menu1"><img src="../images/images/tabmenu/transp.gif" width="3" height="1"></td>
        </tr>
        <!-- Linea de abajo del menu superior derecho -->
        <tr>
          <!-- col 1 -->
          <td width="3"  height="3"><img src="../images/images/tabmenu/esq3.gif" width="3" height="3" border="0"></td>

          <td width="24" height="3" class="opcion" background="../images/images/tabmenu/opcion2.gif"></td>
          <td width="50" height="3" class="opcion" background="../images/images/tabmenu/opcion2.gif"></td>
          <td width="5"  height="3"><img src="../images/images/tabmenu/opcion_medb.gif" width="5" height="3" border="0"></td>
          <!-- col 2 -->
          <td width="24" height="3" class="opcion" background="../images/images/tabmenu/opcion2.gif"></td>
          <td width="80" height="3" class="opcion" background="../images/images/tabmenu/opcion2.gif"></td>
          <td width="3"  height="3"><img src="../images/images/tabmenu/esq4.gif" width="3" height="3" border="0"></td>
        </tr>
        </table>
        <!-- fin tabla menu -->
      </td>  
    </tr>
  </table>

  <FORM TARGET="sqlresultset" METHOD="post" onsubmit="document.forms[0].action=document.forms[0].output[1].checked ? 'sql_text.jsp' : 'sql_exec.jsp'; document.forms[0].profile.value=document.forms[0].sel_profile.options[document.forms[0].sel_profile.selectedIndex].value;">
    <INPUT TYPE="hidden" NAME="profile" VALUE="">
    <TABLE>
      <TR>
        <TD ALIGN="right">
          <FONT CLASS="textplain">Environment</FONT>&nbsp;<SELECT NAME="sel_profile" onchange="document.location='sql_form.jsp?profile='+this.options[this.selectedIndex].value"><OPTION VALUE="hipergate">hipergate</OPTION><OPTION VALUE="test">test</OPTION><OPTION VALUE="devel">devel</OPTION><OPTION VALUE="real">real</OPTION><OPTION VALUE="demo">demo</OPTION><OPTION VALUE="crm">crm</OPTION><OPTION VALUE="portal">portal</OPTION><OPTION VALUE="intranet">intranet</OPTION><OPTION VALUE="extranet">extranet</OPTION><OPTION VALUE="shop">shop</OPTION><OPTION VALUE="site">site</OPTION><OPTION VALUE="web">web</OPTION><OPTION VALUE="work">work</OPTION></SELECT>
        </TD>
	<TD>
          <FONT CLASS="textplain">Connected to &nbsp;<B><%=Environment.getProfileVar(sProfile, "dburl")%></B></FONT>
        </TD>
      </TR>
      <TR>
        <TD ALIGN="right">
          <FONT CLASS="textplain">Delimiter</FONT>&nbsp;<SELECT NAME="delimiter"><OPTION VALUE=""></OPTION><OPTION VALUE=";">;</OPTION><OPTION VALUE="/">/</OPTION><OPTION VALUE="\">\</OPTION><OPTION VALUE="GO;">GO;</OPTION></SELECT>
	</TD>
	<TD>
          <FONT CLASS="textplain">Max. Rows</FONT>&nbsp;<INPUT TYPE="text" NAME="maxrows" MAXLENGTH="4" SIZE="4" VALUE="1000" onkeypress="return acceptOnlyNumbers();">
          &nbsp;
          <INPUT TYPE="radio" NAME="output" VALUE="html" checked>&nbsp;<FONT CLASS="textplain">HTML</FONT>&nbsp;&nbsp;&nbsp;<INPUT TYPE="radio" NAME="output" VALUE="text">&nbsp;<FONT CLASS="textplain">Text</FONT>
        </TD>
      </TR>
    </TABLE>
    <TABLE>
      <TR>
        <TD ALIGN="left"><A CLASS="linkplain" HREF="cpy_form.jsp">Data Copy between tables</A><BR/><A CLASS="linkplain" HREF="ldr_form.jsp">Load data into a table</A></TD>
        <TD ALIGN="right"><INPUT TYPE="submit" CLASS="pushbutton" VALUE="Execute"></TD>
      </TR>
      <TR><TD COLSPAN="2"><TEXTAREA NAME="sqlstatements" ROWS="15" COLS="60"></TEXTAREA></TD></TR>
    </TABLE>    
  </FORM>
</BODY>
</HTML>
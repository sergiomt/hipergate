<%@ page import="com.knowgate.misc.Environment" language="java" session="false" contentType="text/html;charset=UTF-8" %>
<HTML>
<HEAD>
  <META HTTP-EQUIV="Content-Type" CONTENT="text/html; charset=UTF-8">
  <SCRIPT SRC="../javascript/cookies.js"></SCRIPT>  
  <SCRIPT SRC="../javascript/setskin.js"></SCRIPT>
  <SCRIPT SRC="../javascript/simplevalidations.js"></SCRIPT>
</HEAD>
<BODY onLoad="parent.frames[1].document.location='../common/blank.htm'">
  <table width="100%" cellspacing="0" cellpadding="0" border="0">
    <tr>
      <td align="left" class="striptitle">
        <font class="title1">Copy registers between tables</font>
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
  <BR>
  <FORM TARGET="sqlresultset" METHOD="post" action="cpy_exec.jsp" onsubmit="">
    <TABLE SUMMARY="Origin and Target" BORDER="0">
      <TR>
	<TD><A CLASS="linkplain" HREF="sql_form.jsp">SQL Query</A></TD>
	<TD></TD>
	<TD></TD>
	<TD></TD>
	<TD></TD>
      </TR>
      <TR>
        <TD CLASS="textplain">Source Connection</TD>
        <TD><SELECT NAME="con_origin"><OPTION VALUE="hipergate" SELECTED="selected">hipergate</OPTION><OPTION VALUE="test">test</OPTION><OPTION VALUE="devel">devel</OPTION><OPTION VALUE="real">real</OPTION><OPTION VALUE="demo">demo</OPTION><OPTION VALUE="crm">crm</OPTION><OPTION VALUE="portal">portal</OPTION><OPTION VALUE="intranet">intranet</OPTION><OPTION VALUE="extranet">extranet</OPTION><OPTION VALUE="shop">shop</OPTION><OPTION VALUE="site">site</OPTION><OPTION VALUE="web">web</OPTION><OPTION VALUE="work">work</OPTION></SELECT></TD>
        <TD CLASS="textplain">Target Connection</TD>
        <TD><SELECT NAME="con_target"><OPTION VALUE="hipergate" SELECTED="selected">hipergate</OPTION><OPTION VALUE="test">test</OPTION><OPTION VALUE="devel">devel</OPTION><OPTION VALUE="real">real</OPTION><OPTION VALUE="demo">demo</OPTION><OPTION VALUE="crm">crm</OPTION><OPTION VALUE="portal">portal</OPTION><OPTION VALUE="intranet">intranet</OPTION><OPTION VALUE="extranet">extranet</OPTION><OPTION VALUE="shop">shop</OPTION><OPTION VALUE="site">site</OPTION><OPTION VALUE="web">web</OPTION><OPTION VALUE="work">work</OPTION></SELECT></TD>
      </TR>
      <TR>
	<TD CLASS="textplain">Source Table</TD>
	<TD><INPUT TYPE="text" NAME="tbl_origin" MAXLENGTH="32" SIZE="30"></TD>
	<TD CLASS="textplain">Target Table</TD>
	<TD><INPUT TYPE="text" NAME="tbl_target" MAXLENGTH="32" SIZE="30"></TD>
      </TR>
      <TR>
	<TD><INPUT TYPE="submit" CLASS="pushbutton" VALUE="Copy"></TD>
	<TD></TD>
	<TD></TD>
	<TD></TD>
	<TD></TD>
      </TR>
    </TABLE>
  </FORM>
</BODY>
</HTML>
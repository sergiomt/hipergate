<%@ page import="java.io.IOException,java.net.URLDecoder,java.sql.SQLException,com.knowgate.jdc.*,com.knowgate.dataobjs.*,com.knowgate.acl.*" language="java" session="false" contentType="text/html;charset=UTF-8" %>

<HTML>
<HEAD>
  <SCRIPT TYPE="text/javascript" SRC="../javascript/cookies.js"></SCRIPT>  
  <SCRIPT TYPE="text/javascript" SRC="../javascript/setskin.js"></SCRIPT>
  <SCRIPT TYPE="text/javascript" SRC="../javascript/getparam.js"></SCRIPT>
  <SCRIPT TYPE="text/javascript">
    <!--
      function setInputs() {
        window.resizeTo(420,420);
        
	var frm = document.forms[0];
	
	frm.id_domain.value = getURLParam("id_domain");
	frm.n_domain.value = getURLParam("n_domain");
	frm.gu_workarea.value = getURLParam("gu_workarea");
	frm.tp_list.value = getURLParam("tp_list");
	if (frm.tp_list.value=="1") frm.listtype[0].checked = true;
	if (frm.tp_list.value=="2") frm.listtype[1].checked = true;
	if (frm.tp_list.value=="3") frm.listtype[2].checked = true;
	if (frm.tp_list.value=="" || frm.tp_list.value=="null") {
		frm.listtype[0].checked = true;
		frm.tp_list.value="1";
	}
      }

      function validate() {
        var frm = document.forms[0];
        if (frm.tp_list.value=="" || frm.tp_list.value=="null") {
          alert ("Debe elegir un tipo de lista a generar");
          return false;
        }

        if (frm.tp_list.value=="3") {
          frm.action = "list_wizard_d2.jsp";
        }
        
        return true;
      }
    //-->
  </SCRIPT>
  <TITLE>hipergate :: Create Distribution List - Step 1 of 4</TITLE>
</HEAD>
<BODY  TOPMARGIN="8" MARGINHEIGHT="8" onLoad="setInputs()">
  <DIV ID="dek" STYLE="width:200;height:20;z-index:200;visibility:hidden;position:absolute"></DIV>  
  <FORM NAME="" METHOD="get" ACTION="list_wizard_02.jsp" onSubmit="return validate()">
    <INPUT TYPE="hidden" NAME="id_domain">
    <INPUT TYPE="hidden" NAME="n_domain">
    <INPUT TYPE="hidden" NAME="gu_workarea">
    <INPUT TYPE="hidden" NAME="tp_list">
    <CENTER>
    <TABLE><TR><TD WIDTH="310px" CLASS="striptitle"><FONT CLASS="title1">Create List - Step 1 of 4</FONT></TD></TR></TABLE>
    <TABLE WIDTH="310px" CLASS="formback">
      <TR><TD ALIGN="left" CLASS="formstrong">What type of list do you want to create?</TD></TR>
      <TR><TD>
        <TABLE WIDTH="100%" CLASS="formfront">
          <TR>
            <TD ALIGN="left">
              <INPUT TYPE="radio" checked NAME="listtype" VALUE="static" onClick="document.forms[0].tp_list.value='1';">&nbsp;<FONT CLASS="formstrong">Static</FONT>
              <BR>
              <FONT CLASS="textsmall">A Static List takes its members from a Query once and never changes over time even if query results do.</FONT>
              <BR>
              <INPUT TYPE="radio" NAME="listtype" VALUE="dynamic" onClick="document.forms[0].tp_list.value='2';">&nbsp;<FONT CLASS="formstrong">Dynamic</FONT>
              <BR>
              <FONT CLASS="textsmall">A Dynamic List reflect results from a Query, its members change over time as query produces new results.</FONT>
              <BR>
              <INPUT TYPE="radio" NAME="listtype" VALUE="direct" onClick="document.forms[0].tp_list.value='3';">&nbsp;<FONT CLASS="formstrong">Directly loaded from a file</FONT>
              <BR>
              <FONT CLASS="textsmall">A Direct List takes its members from a fixed test file an never changes over time.<BR><BR></FONT>
            </TD>
          </TR>
        </TABLE>
      </TD>
     </TR>
    </TABLE>
    <TABLE WIDTH="310px"><TR><TD ALIGN="right"><INPUT TYPE="button" CLASS="closebutton" VALUE="Cancel" STYLE="width:100px" onClick="self.close()">&nbsp;<INPUT TYPE="submit" CLASS="pushbutton" VALUE="Next >>" STYLE="width:100px"></TD></TR></TABLE>
    </CENTER>
  </FORM>
</BODY>
</HTML>
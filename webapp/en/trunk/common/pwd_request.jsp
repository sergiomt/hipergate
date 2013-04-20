<%@ page language="java" session="false" contentType="text/html;charset=UTF-8" %>
<% response.addHeader ("Pragma", "no-cache"); response.addHeader ("cache-control", "no-store"); response.setIntHeader("Expires", 0); %>
<HTML>
<HEAD>
  <TITLE>Retrieve password</TITLE>
  <SCRIPT TYPE="text/javascript" SRC="../javascript/cookies.js"></SCRIPT>  
  <SCRIPT TYPE="text/javascript" SRC="../javascript/setskin.js"></SCRIPT>
  <SCRIPT TYPE="text/javascript" SRC="../javascript/email.js"></SCRIPT>
  <SCRIPT TYPE="text/javascript" DEFER="defer">

      function validate() {
        var frm = window.document.forms[0];

			  if (frm.captcha_text.value.length!=6) {
          alert ("The verification text must have six characters");
					frm.captcha_text.focus();
					return false;
			  }

			  if (frm.nickname.value.length==0) {
          alert ("The e-mail or username is required");
					frm.nickname.focus();
					return false;
			  }

			  if (frm.nickname.value.indexOf("@")>=0) {
			  	if (!check_email(frm.nickname.value)) {
			  	  alert ("The e-mail is not valid");
					  frm.nickname.focus();
					  return false;
			  	}
			  } else {
			  	if (!check_nick(frm.nickname.value)) {
			  	  alert ("The user name is not valid");
					  frm.nickname.focus();
					  return false;
			  	}			  	
			  }
			          
        return true;
      } // validate;
    //-->
  </SCRIPT>
</HEAD>
<BODY TOPMARGIN="8" MARGINHEIGHT="8">
  <TABLE WIDTH="420px">
    <TR><TD><IMG SRC="../images/images/spacer.gif" HEIGHT="4" WIDTH="1" BORDER="0"></TD></TR>
    <TR><TD CLASS="striptitle"><FONT CLASS="title1">Retrieve password</FONT></TD></TR>
  </TABLE>  
  <FORM METHOD="get" ACTION="pwd_challenge.jsp" onSubmit="return validate()">
	  
    <TABLE WIDTH="420px">
      <TR>
        <TD CLASS="textplain" COLSPAN="2">
          Type your user or e-mail and the graphic key shown on screen
        </TD>
		  </TR>
      <TR>
        <TD CLASS="textplain" WIDTH="140px">
          User or e-mail
        </TD>
        <TD CLASS="textplain" WIDTH="140px">
          <INPUT TYPE="text" NAME="nickname" MAXLENGTH="100" SIZE="32">
        </TD>
		  </TR>
      <TR>
        <TD CLASS="textplain">
          <IMG SRC="captcha.jsp" HSPACE="4" ALT="If you cannot see this image check that Sun JAI is properly installed"/>
        </TD>
        <TD CLASS="textplain">
			    <INPUT TYPE="text" NAME="captcha_text" MAXLENGTH="6" SIZE="8">
        </TD>
		  </TR>
      <TR>
        <TD></TD>
        <TD CLASS="textplain">
			    <INPUT TYPE="submit" CLASS="pushbutton" ACCESSKEY="r" TITLE="ALT+r" VALUE="Retrieve">&nbsp;&nbsp;<INPUT TYPE="button" CLASS="closebutton" ACCESSKEY="c" TITLE="ALT+c" VALUE="Cancel" onclick="window.close()">
        </TD>
		  </TR>
		</TABLE>
		          
  </FORM>
</BODY>
</HTML>
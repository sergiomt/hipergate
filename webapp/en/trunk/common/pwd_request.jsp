<%@ page language="java" session="false" contentType="text/html;charset=UTF-8" %>
<% response.addHeader ("Pragma", "no-cache"); response.addHeader ("cache-control", "no-store"); response.setIntHeader("Expires", 0); %>
<HTML>
<HEAD>
  <TITLE>[~Recuperar contrase&ntilde;a~]</TITLE>
  <SCRIPT LANGUAGE="JavaScript" TYPE="text/javascript" SRC="../javascript/cookies.js"></SCRIPT>  
  <SCRIPT LANGUAGE="JavaScript" TYPE="text/javascript" SRC="../javascript/setskin.js"></SCRIPT>
  <SCRIPT LANGUAGE="JavaScript" TYPE="text/javascript" SRC="../javascript/email.js"></SCRIPT>
  <SCRIPT LANGUAGE="JavaScript" TYPE="text/javascript" DEFER="defer">

      function validate() {
        var frm = window.document.forms[0];

			  if (frm.captcha_text.value.length!=6) {
          alert ("[~El texto de verificación debe tener 6 caracteres~]");
					frm.captcha_text.focus();
					return false;
			  }

			  if (frm.nickname.value.length==0) {
          alert ("[~El e-mail o nombre de usuario es obligatorio~]");
					frm.nickname.focus();
					return false;
			  }

			  if (frm.nickname.value.indexOf("@")>=0) {
			  	if (!check_email(frm.nickname.value)) {
			  	  alert ("[~El e-mail no es válido~]");
					  frm.nickname.focus();
					  return false;
			  	}
			  } else {
			  	if (!check_nick(frm.nickname.value)) {
			  	  alert ("[~El nombre de usuario no es válido~]");
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
    <TR><TD CLASS="striptitle"><FONT CLASS="title1">[~Recuperar contrase&ntilde;a~]</FONT></TD></TR>
  </TABLE>  
  <FORM METHOD="get" ACTION="pwd_challenge.jsp" onSubmit="return validate()">
	  
    <TABLE WIDTH="420px">
      <TR>
        <TD CLASS="textplain" COLSPAN="2">
          [~Introduzca su nombre de usuario o e-mail junto con el c&oacute;digo de seguridad que encontrar&aacute; en la pantalla~]
        </TD>
		  </TR>
      <TR>
        <TD CLASS="textplain" WIDTH="140px">
          [~Usuario o e-mail~]
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
			    <INPUT TYPE="submit" CLASS="pushbutton" ACCESSKEY="r" TITLE="ALT+r" VALUE="[~Recuperar~]">&nbsp;&nbsp;<INPUT TYPE="button" CLASS="closebutton" ACCESSKEY="c" TITLE="ALT+c" VALUE="[~Cancelar~]" onclick="window.close()">
        </TD>
		  </TR>
		</TABLE>
		          
  </FORM>
</BODY>
</HTML>
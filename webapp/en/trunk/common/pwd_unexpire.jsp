<%@ page import="java.net.URLDecoder,java.sql.SQLException,com.knowgate.debug.DebugFile,com.knowgate.jdc.JDCConnection,com.knowgate.acl.*,com.knowgate.dataobjs.*,com.knowgate.misc.Environment" language="java" session="false" contentType="text/html;charset=UTF-8" %>
<%@ include file="../methods/cookies.jspf" %><%@ include file="../methods/nullif.jspf" %><%@ include file="../methods/dbbind.jsp" %><%


  JDCConnection oConn = null;
  ACLUser oUser = new ACLUser();
  
  try {

    oConn = GlobalDBBind.getConnection("pwd_unexpire");  
    
    oUser.load(oConn, new Object[]{request.getParameter("userid")});

    oConn.close("pwd_unexpire");
  }
  catch (SQLException e) {  
    if (oConn!=null)
      if (!oConn.isClosed()) oConn.close("pwd_unexpire");
    oConn = null;
    response.sendRedirect (response.encodeRedirectUrl ("errmsg.jsp?title=SQLException&desc=" + e.getLocalizedMessage() + "&resume=_close"));  
  }

  if (null==oConn) return;

  oConn = null;  

%><!DOCTYPE HTML PUBLIC "-//W3C//DTD HTML 4.01 Transitional//EN" "http://www.w3.org/TR/html4/loose.dtd">
<html>
<!-- hipergate © 2008 KnowGate -->
<head>
  <meta name="robots" content="noindex,nofollow">
  <meta http-equiv="Content-Type" content="text/html; charset=utf-8">
  <title>hipergate :: Password Change</title>
  <link rel=stylesheet type=text/css HREF=../skins/xp/styles.css>
  <script language="JavaScript" type="text/javascript" src="../javascript/cookies.js"></script>
  <script language="JavaScript" type="text/javascript" src="../javascript/trim.js"></script>
  <script language="JavaScript" type="text/javascript" src="../javascript/getparam.js"></script>

  <script language="JavaScript" type="text/javascript" defer="defer">  
    <!--
      
      var skin = getURLParam("skin");
      
      // ----------------------------------------------------------------------
      
      function onLoadComplete() {
        document.getElementById("triangles").src = "../skins/"+skin+"/log/triangulos.gif";
        document.getElementById("deco1").src = "../skins/"+skin+"/log/deco.gif";
        document.getElementById("deco2").src = "../skins/"+skin+"/log/deco.gif";
        document.getElementById("deco3").src = "../skins/"+skin+"/log/deco.gif";
        document.body.background = "../skins/"+skin+"/log/bg_registro.gif";
      }

      // ----------------------------------------------------------------------

    //-->
  </script>
  <script language="JavaScript" type="text/javascript" defer="defer">  
    <!--
      function validate() {
        var frm = window.document.forms[0];
        
        if (rtrim(frm.pwd_new_text1.value).length==0) {
          alert ("Password may not be empty");
          return false;
        }

        if (rtrim(frm.pwd_new_text1.value)!=rtrim(frm.pwd_new_text2.value)) {
          alert ("The password verification does not match the previous one");
          return false;
        }

        if (rtrim(frm.pwd_new_text.value).toUpperCase()==rtrim(frm.pwd_new_text1.value).toUpperCase()) {
          alert ("The new password cannot be the same as the previous one");
          return false;
        }

        return true;
      }      
    //-->
  </script>
</head>
<body text="black" leftmargin="0" topmargin="30" marginwidth="0" marginheight="30" onLoad="onLoadComplete()">
  <br>
  <form name="form1" method="post" action="login_chk.jsp" onSubmit="return validate()">
    <input type="hidden" name="context" value="<%=request.getParameter("context")%>">
    <input type="hidden" name="face" value="<%=request.getParameter("face")%>">
    <input type="hidden" name="skin" value="<%=request.getParameter("skin")%>">
    <input type="hidden" name="nickname" value="<%=oUser.getString(DB.tx_main_email)%>">
<% if (oUser.getString(DB.tx_pwd).equals("(not set yet, change on next logon)")) out.write("<input type=\"hidden\" name=\"pwd_text\" value=\"(not set yet, change on next logon)\">"); %>
    <center>
    <table width="469" cellspacing="0" cellpadding="0" border="0" name="principal" summary="Change Password Box">
      <!-- top line -->
      <tr style="height:10px">
        <td style="font-size:1px" width="9" valign="bottom"><img src="../images/images/login/top_left.gif" width="9" height="9" border="0" alt="|-"></td>
        <td style="font-size:1px" colspan="6" width="10" height="10" background="../images/images/login/bg_top.gif"><img src="../images/images/login/transp.gif" width="10" height="9" border="0" alt=""></td>
        <td style="font-size:1px" width="9" valign="bottom"><img src="../images/images/login/top_right.gif" width="9" height="9" border="0" alt="-|"></td>
      </tr>

      <!-- start session -->
      <tr>
	      <td width="9" background="../images/images/login/bg_left.gif"><img src="../images/images/login/transp.gif" width="9" height="1" alt=""></td>
	      <td width="26" bgcolor="white" align="right"><img id="triangles" src="../images/images/login/transp.gif" width="15" height="8" alt="Triangles"></td>
	      <td colspan="5" width="435" bgcolor="white" class="textstrong" align="center"><img src="../images/images/login/transp.gif" width="5" height="1" alt="">Changing the password is required</td>
	      <td width="9" background="../images/images/login/bg_right.gif"><img src="../images/images/login/transp.gif" width="9" height="1" alt=""></td>
      </tr>

      <!-- white interstitial -->
      <tr>
        <td width="9" height="3" background="../images/images/login/bg_left.gif"><img src="../images/images/login/transp.gif" width="9" height="1" alt=""></td>
        <td colspan="6" width="451" height="3" bgcolor="white" valign="bottom"><img src="../images/images/login/transp.gif" width="451" height="3" alt=""></td>
        <td width="9" height="3" background="../images/images/login/bg_right.gif"><img src="../images/images/login/transp.gif" width="9" height="1" alt=""></td>
      </tr>

      <!-- black line -->
      <tr>
        <td width="9" height="1" background="../images/images/login/bg_left.gif"><img src="../images/images/login/transp.gif" width="9" height="1" alt=""></td>
        <td colspan="6" width="451" height="1" bgcolor="white" valign="bottom"><img src="../images/images/login/black.gif" width="451" height="1" alt=""></td>
        <td width="9" height="1" background="../images/images/login/bg_right.gif"><img src="../images/images/login/transp.gif" width="9" height="1" alt=""></td>
      </tr>
<% if (!oUser.getString(DB.tx_pwd).equals("(not set yet, change on next logon)")) { %>
      <!-- white interstitial -->
      <tr>
        <td width="9" height="3" background="../images/images/login/bg_left.gif"><img src="../images/images/login/transp.gif" width="9" height="1" alt=""></td>
        <td colspan="6" width="451" height="3" bgcolor="white" valign="bottom"><img src="../images/images/login/transp.gif" width="451" height="3" alt=""></td>
        <td width="9" height="3" background="../images/images/login/bg_right.gif"><img src="../images/images/login/transp.gif" width="9" height="1" alt=""></td>
      </tr>

      <tr>
        <td width="9" background="../images/images/login/bg_left.gif"><img src="../images/images/login/transp.gif" width="9" height="1" alt=""></td>
        <td width="26" bgcolor="#eeeeee" align="right"><img id="deco1" src="../images/images/login/transp.gif" width="11" height="22" alt="Decoration"></td>
        <td width="200" bgcolor="#eeeeee" class="login"><img src="../images/images/login/transp.gif" width="5" height="1" alt="">Current Password</td>
        <td width="1" bgcolor="#808080"><img src="../images/images/login/transp.gif" width="1" height="1" alt=""></td>
        <td width="223" background="../images/images/login/login_bg.gif" align="left" valign="middle">
          <!-- this is the actual input textbox for the email -->
          <img src="../images/images/login/transp.gif" width="16" height="1" alt="">
          <input type="text" name="pwd_text" class="box" size="30" maxlength="30">
        </td>
        <td width="1" bgcolor="#808080"><img src="../images/images/login/transp.gif" width="1" height="1" alt=""></td>
        <td width="10" bgcolor="white"><img src="../images/images/login/transp.gif" width="10" height="1" alt=""></td>
        <td width="9" background="../images/images/login/bg_right.gif"><img src="../images/images/login/transp.gif" width="9" height="1" alt=""></td>
      </tr>
<% } %>
      <!-- white interstitial -->
      <tr>
        <td width="9" height="3" background="../images/images/login/bg_left.gif"><img src="../images/images/login/transp.gif" width="9" height="1" alt=""></td>
        <td colspan="6" width="451" height="3" bgcolor="white" valign="bottom"><img src="../images/images/login/transp.gif" width="451" height="3" alt=""></td>
        <td width="9" height="3" background="../images/images/login/bg_right.gif"><img src="../images/images/login/transp.gif" width="9" height="1" alt=""></td>
      </tr>

      <tr>
        <td width="9" background="../images/images/login/bg_left.gif"><img src="../images/images/login/transp.gif" width="9" height="1" alt=""></td>
        <td width="26" bgcolor="#eeeeee" align="right"><img id="deco2" src="../images/images/login/transp.gif" width="11" height="22" alt="Decoration"></td>
        <td width="200" bgcolor="#eeeeee" class="login"><img src="../images/images/login/transp.gif" width="5" height="1" alt="">New password</td>
        <td width="1" bgcolor="#808080"><img src="../images/images/login/transp.gif" width="1" height="1" alt=""></td>
        <td width="223" background="../images/images/login/login_bg.gif" align="left" valign="middle">
          <img src="../images/images/login/transp.gif" width="16" height="1" alt="">
          <input type="text" name="pwd_new_text1" class="box" size="30" maxlength="30">
        </td>
        <td width="1" bgcolor="#808080"><img src="../images/images/login/transp.gif" width="1" height="1" alt=""></td>
        <td width="10" bgcolor="white"><img src="../images/images/login/transp.gif" width="10" height="1" alt=""></td>
        <td width="9" background="../images/images/login/bg_right.gif"><img src="../images/images/login/transp.gif" width="9" height="1" alt=""></td>
      </tr>

      <!-- white interstitial -->
      <tr>
        <td width="9" height="3" background="../images/images/login/bg_left.gif"><img src="../images/images/login/transp.gif" width="9" height="1" alt=""></td>
        <td colspan="6" width="451" height="3" bgcolor="white" valign="bottom"><img src="../images/images/login/transp.gif" width="451" height="3" alt=""></td>
        <td width="9" height="3" background="../images/images/login/bg_right.gif"><img src="../images/images/login/transp.gif" width="9" height="1" alt=""></td>
      </tr>

      <tr>
        <td width="9" background="../images/images/login/bg_left.gif"><img src="../images/images/login/transp.gif" width="9" height="1" alt=""></td>
        <td width="26" bgcolor="#eeeeee" align="right"><img id="deco3" src="../images/images/login/transp.gif" width="11" height="22" alt="Decoration"></td>
        <td width="200" bgcolor="#eeeeee" class="login"><img src="../images/images/login/transp.gif" width="5" height="1" alt="">Repeat password</td>
        <td width="1" bgcolor="#808080"><img src="../images/images/login/transp.gif" width="1" height="1" alt=""></td>
        <td width="223" background="../images/images/login/login_bg.gif" align="left" valign="middle">
          <img src="../images/images/login/transp.gif" width="16" height="1" alt="">
          <input type="text" name="pwd_new_text2" class="box" maxlength="30" size="30">
        </td>
        <td width="1" bgcolor="#808080"><img src="../images/images/login/transp.gif" width="1" height="1" alt=""></td>
        <td width="10" bgcolor="white"><img src="../images/images/login/transp.gif" width="10" height="1" alt=""></td>
        <td width="9" background="../images/images/login/bg_right.gif"><img src="../images/images/login/transp.gif" width="9" height="1" alt=""></td>
      </tr>

      <!-- white interstitial -->
      <tr>
        <td width="9" height="3" background="../images/images/login/bg_left.gif"><img src="../images/images/login/transp.gif" width="9" height="1" alt=""></td>
        <td colspan="6" width="451" height="3" bgcolor="white" valign="bottom"><img src="../images/images/login/transp.gif" width="451" height="3" alt=""></td>
        <td width="9" height="3" background="../images/images/login/bg_right.gif"><img src="../images/images/login/transp.gif" width="9" height="1" alt=""></td>
      </tr>

      <!-- espacio entre negro y log in -->
      <tr>
        <td width="9" height="7" background="../images/images/login/bg_left.gif"><img src="../images/images/login/transp.gif" width="9" height="7" alt=""></td>
        <td colspan="6" width="451" height="7" bgcolor="white" valign="bottom"><img src="../images/images/login/transp.gif" width="451" height="7" alt=""></td>
        <td width="9" height="7" background="../images/images/login/bg_right.gif"><img src="../images/images/login/transp.gif" width="9" height="7" alt=""></td>
      </tr>

      <!-- enter -->
      <tr>
        <td width="9" background="../images/images/login/bg_left.gif"><img src="../images/images/login/transp.gif" width="9" height="1" alt=""></td>
        <td width="26" bgcolor="white" align="right">
          <img src="../images/images/login/transp.gif" width="26" height="1" alt="">
        </td>
        <td width="200" bgcolor="white">
          <img src="../images/images/login/transp.gif" width="200" height="1" alt="">
        </td>
        <td colspan="4" width="235" bgcolor="white" align="center"><input type="submit" class="pushbutton" value="Change" accesskey="e"></td>
        <td width="9" background="../images/images/login/bg_right.gif"><img src="../images/images/login/transp.gif" width="9" height="1" alt=""></td>
      </tr>

      <tr>
        <td width="9" height="7" background="../images/images/login/bg_left.gif"><img src="../images/images/login/transp.gif" width="9" height="7" alt=""></td>
        <td colspan="6" width="451" height="7" bgcolor="white" valign="bottom"><img src="../images/images/login/transp.gif" width="451" height="7" alt=""></td>
        <td width="9" height="7" background="../images/images/login/bg_right.gif"><img src="../images/images/login/transp.gif" width="9" height="7" alt=""></td>
      </tr>

      <tr>
        <td width="9" height="22"><img src="../images/images/login/bot_left.gif" width="9" height="22" alt="|_"></td>
        <td width="26" height="22" background="../images/images/login/bg_bot.gif"><img src="../images/images/login/transp.gif" width="26" height="22" alt=""></td>
        <td width="200" height="22" background="../images/images/login/bg_bot.gif"><img src="../images/images/login/transp.gif" width="200" height="22" alt=""></td>
        <td width="1" height="22" background="../images/images/login/bg_bot.gif"><img src="../images/images/login/transp.gif" width="1" height="22" alt=""></td>
        <td width="223" height="22" background="../images/images/login/bg_bot.gif"><img src="../images/images/login/transp.gif" width="223" height="22" alt=""></td>
        <td width="1" height="22" background="../images/images/login/bg_bot.gif"><img src="../images/images/login/transp.gif" width="1" height="22" alt=""></td>
        <td width="10" height="22" background="../images/images/login/bg_bot.gif"><img src="../images/images/login/transp.gif" width="10" height="22" alt=""></td>
        <td width="9" height="22"><img src="../images/images/login/bot_right.gif" width="9" height="22" alt="_|"></td>
      </tr>
    </table>
    </center>
  </form>
</body>
</html>
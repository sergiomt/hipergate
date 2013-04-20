<%@ page language="java" import="com.knowgate.misc.Gadgets" session="false" contentType="text/html;charset=UTF-8" %><% response.addHeader ("cache-control", "private"); %>
<%
  String nm_action = request.getParameter("nm_action");
  String gu_folder = request.getParameter("gu_folder");
  String nm_folder = request.getParameter("nm_folder");
  String sBackUrl = "../hipermail/fldr_opts.jsp?gu_folder="+gu_folder+"&nm_folder="+Gadgets.URLEncode(nm_folder);
  String sConfirm;
  if (nm_action.equals("mbox_compact.jsp"))
    sConfirm = "Are you sure that you want to compact folder?";
  else if (nm_action.equals("mbox_wipe.jsp"))
    sConfirm = "Are you sure that you want to empty folder?";
  else
    sConfirm = "Are you sure that you want to re-index folder?";
%>
<HTML>
<HEAD>
  <SCRIPT SRC="../javascript/cookies.js"></SCRIPT>  
  <SCRIPT SRC="../javascript/setskin.js"></SCRIPT>
  <SCRIPT TYPE="text/javascript">
    <!--
      function submitForm() {
      var frm = document.forms[0];
      
      frm.screen_width.value=String(screen.width);
      
      if (window.confirm("<%=sConfirm%>"))
        frm.submit();
      else
        document.location.href = "<%=sBackUrl%>";
      }
    //-->    
  </SCRIPT>
</HEAD>
<BODY LEFTMARGIN="16" MARGINWIDTH="16" TOPMARGIN="16" MARGINHEIGHT="16" onload="submitForm()">
  <FONT CLASS="textplain"><B><% if (nm_action.equals("mbox_compact.jsp")) out.write("Compacting folder, please wait..."); else if (nm_action.equals("mbox_wipe.jsp")) out.write("Emptying folder, please wait..."); else out.write("Re-indexing folder, please wait..."); %></B></FONT>
  <BR>
  <IMG SRC="../images/images/hipermail/loading.gif" BORDER="0" ALT="">
  <FORM METHOD="post" ACTION="<%=nm_action%>">
    <INPUT TYPE="hidden" NAME="screen_width">
    <INPUT TYPE="hidden" NAME="gu_folder" VALUE="<%=gu_folder%>">
    <INPUT TYPE="hidden" NAME="nm_folder" VALUE="<%=nm_folder%>">
  </FORM>
</BODY>
</HTML>
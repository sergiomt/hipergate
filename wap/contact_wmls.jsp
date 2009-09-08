<%@ page language="java" session="false" contentType="text/vnd.wap.wmlscript;charset=UTF-8" %><%

  response.setHeader("Content-Disposition","inline; filename=\"contact.wmls\"");

  final java.util.ResourceBundle Labels = java.util.ResourceBundle.getBundle("Labels", request.getLocale());
%>

extern function confirmDelete(gu) {
  if (Dialogs.confirm("<%=Labels.getString("msg_delete_contact")%>", "<%=Labels.getString("msg_yes")%>", "<%=Labels.getString("msg_no")%>"))
    WMLBrowser.go("contact_delete.jsp?gu_contact="+gu);
}
function newMail() {
  window.open('mail_edit.jsp','','width=640,height=480');
}
function showMsg(i) {
  window.open('mail_read.jsp?msgid='+i,'read_'+i,'width=640,height=480,scrollbars=yes');
}
<%@ page import="java.net.URLDecoder,java.io.Reader,java.sql.SQLException,java.sql.PreparedStatement,java.sql.ResultSet,com.knowgate.acl.*,com.knowgate.jdc.JDCConnection,com.knowgate.dataobjs.DB,com.knowgate.dataobjs.DBBind" language="java" session="false" contentType="text/html;charset=UTF-8" %>
<%@ include file="../methods/dbbind.jsp" %>

<HTML>
<HEAD>
<!-- +---------------------------+ -->
<!-- | Vista Previa de Mensajes  | -->
<!-- | (c) KnowGate 2001         | -->
<!-- +---------------------------+ -->
  <meta http-equiv="Content-Type" content="text/html; charset=utf-8">
  <SCRIPT SRC="../javascript/cookies.js"></SCRIPT>  
  <SCRIPT SRC="../javascript/setskin.js"></SCRIPT>
  <TITLE>hipergate :: Message preview</TITLE>
</HEAD>
<BODY  LEFTMARGIN="16" MARGINWIDTH="16">
<FONT CLASS="textcode">
<%


  final int BufferSize = 1024;
  PreparedStatement oStmt;
  ResultSet oRSet;
  Reader oRead;
  char Buffer[] = new char[BufferSize];
  int iReaded=0;
  
  JDCConnection oConn = GlobalDBBind.getConnection("messagepreview");
  String sSubject;
  
  try {
    oStmt = oConn.prepareStatement("SELECT " + DB.tx_subject + "," + DB.tx_msg + " FROM " + DB.k_newsmsgs + " WHERE " + DB.gu_msg + "=?", ResultSet.TYPE_FORWARD_ONLY, ResultSet.CONCUR_READ_ONLY);
    oStmt.setString(1, request.getParameter("gu_msg"));
    oRSet = oStmt.executeQuery();
    oRSet.next();
    sSubject = oRSet.getString(1);
    oRead = oRSet.getCharacterStream(2);
    if (oRead!=null) {
      iReaded = oRead.read(Buffer,0,BufferSize);
      oRead.close();
    }
    oRSet.close();
    oStmt.close();
    oConn.close("messagepreview");
  }
  catch (SQLException e) {  
    iReaded = 0;
    sSubject = "";
    if (oConn!=null)
      if (!oConn.isClosed())
        oConn.close("messagepreview");
    response.sendRedirect (response.encodeRedirectUrl ("../common/errmsg.jsp?title=Error&desc=" + e.getLocalizedMessage() + "&resume=../common/blank.htm"));
  }
  out.write("<B>" + sSubject + "</B><BR>");
  out.write(new String(Buffer,0,iReaded));
  out.write("</FONT>");
  if (BufferSize==iReaded)
    out.write("<BR><A CLASS=\"linkplain\" HREF=\"msg_read.jsp?gu_msg=" + request.getParameter("gu_msg")+ "\" TARGET=\"_blank\" TITLE=\"View complete message\">[more]</A>");      
%>
</FONT>
</BODY>
</HTML>

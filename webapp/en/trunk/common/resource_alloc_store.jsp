<%@ page import="java.util.Enumeration,java.io.IOException,java.net.URLDecoder,java.io.File,java.sql.SQLException,java.text.SimpleDateFormat,com.oreilly.servlet.MailMessage,com.oreilly.servlet.MultipartRequest,com.knowgate.jdc.JDCConnection,com.knowgate.misc.Environment,com.knowgate.misc.Gadgets,com.knowgate.dataobjs.*,com.knowgate.acl.*,com.knowgate.addrbook.Meeting,com.knowgate.projtrack.Bug,com.knowgate.hipergate.Order" language="java" session="false" contentType="text/html;charset=UTF-8" %>
<%@ include file="../methods/dbbind.jsp" %><%@ include file="../methods/cookies.jspf" %><%@ include file="../methods/authusrs.jspf" %><%@ include file="../methods/nullif.jspf" %>
<% 
  
  // if (autenticateSession(GlobalDBBind, request, response)<0) return;
  
  String sTmpDir = Environment.getProfileVar(GlobalDBBind.getProfileName(), "temp", Environment.getTempDir());
  sTmpDir = Gadgets.chomp(sTmpDir,File.separator);

  MultipartRequest oReq = new MultipartRequest(request, sTmpDir, "UTF-8");
  SimpleDateFormat oDtFmt = new SimpleDateFormat("yyyy-MM-dd HH:mm:ss");
  
  String id_domain = oReq.getParameter("id_domain");
  String gu_workarea = oReq.getParameter("gu_workarea");
  String gu_shop = oReq.getParameter("gu_shop");
  String gu_product = oReq.getParameter("sel_products");
  String nu_quantity = oReq.getParameter("sel_quantity");
  String tp_action = oReq.getParameter("chk_type");
  String tx_email = oReq.getParameter("my_email");
  String tp_meeting = oReq.getParameter("tp_meeting");
  String tx_meeting = oReq.getParameter("tx_meeting");
  String nm_room = oReq.getParameter("sel_rooms");
  String gu_project = oReq.getParameter("sel_projects");
  String tl_bug = oReq.getParameter("tl_bug");
  String tx_brief = oReq.getParameter("tx_brief");
  String ts_start = oReq.getParameter("ts_start");
  String ts_end = oReq.getParameter("ts_end");
  String tx_subject = "";
  String tx_message = "";

  String gu_user = null;
  
  JDCConnection oConn = null;  
    
  try {
    oConn = GlobalDBBind.getConnection("resource_alloc_store");

    oConn.setAutoCommit(false);

    gu_user = ACLUser.getIdFromEmail(oConn, tx_email);

    if (null==gu_user) throw new SQLException("La direccion de correo "+tx_email+" no corresponde a ningun usuario del sistema");

    ACLUser oUsr = new ACLUser(oConn, gu_user);

    if (tp_action.equals("Room")) {

      Meeting oMee = new Meeting();
      oMee.put(DB.id_domain,new Integer(id_domain));
      oMee.put(DB.gu_workarea,gu_workarea);
      oMee.put(DB.dt_start, ts_start, oDtFmt);
      oMee.put(DB.dt_end, ts_end, oDtFmt);
      oMee.put(DB.gu_fellow,gu_user);
      oMee.put(DB.df_before,new Integer(-1));
      oMee.put(DB.tp_meeting,tp_meeting);
      oMee.put(DB.tx_meeting,tx_meeting);
      oMee.put(DB.gu_writer,gu_user);
      oMee.store(oConn);
      oMee.setAttendant(oConn, gu_user);
      oMee.setRoom(oConn, nm_room);

      tx_subject = "hipergate - Reserva de Recurso: " +nm_room;
      tx_message = "De "+ts_start+" a "+ts_end;
      
    } else if (tp_action.equals("Incident")) {

      Bug oBug = new Bug();
      oBug.put(DB.tl_bug, tl_bug);
      oBug.put(DB.gu_project, gu_project);
      oBug.put(DB.gu_writer, gu_user);
      oBug.put(DB.od_severity, (short)0);
      oBug.put(DB.od_priority, (short)0);
      oBug.put(DB.nm_reporter, (oUsr.getStringNull(DB.nm_user,"")+" "+oUsr.getStringNull(DB.tx_surname1,"")+" "+oUsr.getStringNull(DB.tx_surname2,"")).trim());
      oBug.put(DB.tx_rep_mail, tx_email);
      oBug.put(DB.tx_bug_brief, tx_brief);        
      oBug.store(oConn);
      
      Enumeration oFileNames = oReq.getFileNames();
      while (oFileNames.hasMoreElements()) {
        String sFileName = oReq.getOriginalFileName(oFileNames.nextElement().toString());
        if (sFileName!=null) {
          String sFilePath = sTmpDir+sFileName;
          File oFile = new File(sFilePath);
          oBug.attachFile(oConn, sFilePath);
          oFile.delete();
        }
      } // wend

      tx_subject = "hipergate - Notificación de Incidencia: " +String.valueOf(Bug.getPgFromId(oConn, oBug.getString(DB.gu_bug))) + " " +tl_bug;
      tx_message = tx_brief;

    } else if (tp_action.equals("Product")) {

      Order oOrdr = new Order();
      oOrdr.put(DB.gu_workarea, gu_workarea);
      oOrdr.put(DB.gu_shop, gu_shop);
      oOrdr.put(DB.id_currency, "978");
      oOrdr.put(DB.bo_active, (short)0);
      oOrdr.put(DB.bo_approved, (short)1);
      oOrdr.put(DB.bo_credit_ok, (short)1);
      oOrdr.store(oConn);
      
      oOrdr.addProduct(oConn, gu_product, Float.parseFloat(nu_quantity));

      tx_subject = "hipergate - Petición de Material";
    }

    oConn.commit();
      
    oConn.close("resource_alloc_store");
  }
  catch (SQLException e) {  
    disposeConnection(oConn,"resource_alloc_store");
    oConn = null;
    response.sendRedirect (response.encodeRedirectUrl ("../common/errmsg.jsp?title=SQLException&desc=" + e.getLocalizedMessage() + "&resume=_back"));
  }
  catch (NumberFormatException e) {
    if (oConn!=null)
      if (!oConn.isClosed()) {
        if (!oConn.getAutoCommit()) oConn.rollback();
        oConn.close("...");      
      }
    oConn = null;
    response.sendRedirect (response.encodeRedirectUrl ("../common/errmsg.jsp?title=NumberFormatException&desc=" + e.getMessage() + "&resume=_back"));
  }
  
  if (null==oConn) return;    
  oConn = null;

  /*
  MailMessage msg = new MailMessage("mail.knowgate.es");
  msg.to("sergiom@knowgate.com");
  msg.from("Gestor de Peticiones");
  msg.setHeader("Return-Path", "noreply@hipergate.com");
  msg.setHeader("MIME-Version","1.0");
  msg.setHeader("Content-Type","text/plain;charset=\"utf-8\"");
  msg.setHeader("Content-Transfer-Encoding","8bit");
      
  msg.setSubject(tx_subject);
  msg.getPrintStream().println("That you for using the incidents reporting system. We have received your report and our team will contact you soon");
  msg.sendAndClose();
  */
%>
<HTML>
<HEAD>
  <META HTTP-EQUIV="Content-Type" CONTENT="text/html; charset=UTF-8">
  <TITLE>hipergate</TITLE>
  <SCRIPT SRC="../javascript/cookies.js"></SCRIPT>  
  <SCRIPT SRC="../javascript/setskin.js"></SCRIPT>
</HEAD>
<BODY TOPMARGIN="16px" MARGINHEIGHT="16px">
  <BR>
  <TABLE ALIGN="CENTER" WIDTH="90%" BGCOLOR="#000000">
    <TR><TD>
      <FONT FACE="Arial,Helvetica,sans-serif" COLOR="white" SIZE="2"><B>Petición Procesada</B></FONT>
    </TD></TR>
    <TR><TD>
      <TABLE WIDTH="100%" BGCOLOR="#FFFFFF">
        <TR><TD>
          <TABLE BGCOLOR="#FFFFFF" BORDER="0" CELLSPACING="8" CELLPADDING="8">
            <TR VALIGN="middle">
              <TD><IMG SRC="../images/images/navigate32x32.gif" BORDER="0"></TD>
              <TD><FONT CLASS="textplain">Su petición ha sido procesada. Gracias.</FONT></TD>
	    </TR>
	  </TABLE>
        </TD></TR>
        <TR><TD ALIGN="center">
          <FORM>
            <INPUT TYPE="button" CLASS="pushbutton" VALUE="Close Window" onclick="window.close()">
          </FORM>
        </TD></TR>
      </TABLE>
    </TD></TR>    
  </TABLE>
</BODY>
</HTML>
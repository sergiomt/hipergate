<%@ page import="java.net.URL,javax.mail.Session,javax.mail.Message,javax.mail.Folder,javax.mail.MessagingException,javax.mail.URLName,javax.mail.Address,javax.mail.internet.*,java.util.Properties,java.net.URLDecoder,java.io.IOException,java.sql.ResultSet,java.sql.SQLException,java.sql.PreparedStatement,com.knowgate.debug.DebugFile,com.knowgate.jdc.JDCConnection,com.knowgate.dataobjs.*,com.knowgate.acl.*,com.knowgate.misc.Environment,com.knowgate.misc.Gadgets,com.knowgate.hipergate.ProductLocation,com.knowgate.dfs.FileSystem,com.knowgate.hipermail.*" language="java" session="false" contentType="text/html;charset=UTF-8" %>
<jsp:useBean id="GlobalCacheClient" scope="application" class="com.knowgate.cache.DistributedCachePeer"/><%@ include file="../methods/dbbind.jsp" %><%@ include file="../methods/cookies.jspf" %><%@ include file="../methods/authusrs.jspf" %><%@ include file="../methods/nullif.jspf" %><%@ include file="msg_txt_util.jspf" %><%@ include file="mail_env.jspf" %><%@ include file="../methods/page_prolog.jspf" %><%

  if (autenticateSession(GlobalDBBind, request, response)<0) return;

  final boolean bIE = true; // (nullif(request.getHeader("user-agent")).indexOf("MSIE")>0); 

  final String forward = "forward";
  final String reply = "reply";
  final String replyall = "replyall";
  
  String action = request.getParameter("action");
  String folder = nullif(request.getParameter("folder"),"drafts");
  String id_message = request.getParameter("msgid");    
  String gu_mimemsg = nullif(request.getParameter("gu_mimemsg"));
  String gu_contact = nullif(request.getParameter("gu_contact"));
  String contenttype = nullif(request.getParameter("contenttype"), "html");

  if (!bIE) contenttype = "text";
  
  boolean bo_new = (gu_mimemsg.length()==0);
  
  String tx_subject = null, id_priority = null, tx_content = null;
  String sGuid = null, sId = null, sFrom = "", sTo = "", sCc = "", sBcc = "";

  String sWebRoot = Environment.getProfileVar(GlobalDBBind.getProfileName(),"webserver");
  if (null==sWebRoot) {
    sWebRoot = request.getRequestURI();
    sWebRoot = sWebRoot.substring(0,sWebRoot.lastIndexOf("/"));
    sWebRoot = sWebRoot.substring(0,sWebRoot.lastIndexOf("/"));
  }
  sWebRoot = com.knowgate.misc.Gadgets.chomp (sWebRoot, "/");

  String sTmpDir = Environment.getProfileVar(GlobalDBBind.getProfileName(), "temp", Environment.getTempDir());
  sTmpDir = com.knowgate.misc.Gadgets.chomp(sTmpDir,java.io.File.separator);
    
  DBStore oRDBMS = null;
  DBFolder oFolder = null;
  DBFolder oDrafts = null;
  DBMimeMessage oMsg;
  DBSubset oAccounts = new DBSubset(DB.k_user_mail,DB.gu_account+","+DB.tl_account+","+DB.tx_main_email,DB.gu_user+"=?",10);
  int iAccounts = 0;
  
  String sMailHost = oMacc.getString(DB.outgoing_server);
  SessionHandler oHndl = null;
  Address[] aTo = null;
  
  try {
    oHndl = new SessionHandler(oMacc,sMBoxDir);

    oRDBMS = DBStore.open(oHndl.getSession(), sProfile, sMBoxDir, id_user, tx_pwd);

    iAccounts = oAccounts.load(oRDBMS.getConnection(), new Object[]{id_user});
    
    oFolder = oRDBMS.openDBFolder(folder==null ? "drafts" : folder, DBFolder.READ_ONLY);
    
    oDrafts = oRDBMS.openDBFolder("drafts",DBFolder.READ_WRITE);
    
    DBMimeMessage oOriginalMsg = oFolder.getMessageByGuid(gu_mimemsg);
    
    if (forward.equals(action)) {
      oMsg = DraftsHelper.draftMessageForForward(oDrafts, sMailHost, gu_workarea, id_user, oFolder, gu_mimemsg, contenttype);
      tx_subject = "Fw: " + oMsg.getSubject();
    } else if (reply.equals(action)) {
      oMsg = DraftsHelper.draftMessageForReply(oDrafts, sMailHost, gu_workarea, id_user, oFolder, gu_mimemsg, false, contenttype);
      tx_subject = "Re: " + oMsg.getSubject();
      aTo = new Address[]{oOriginalMsg.getFromRecipient()};
      if (aTo!=null) {
	      if (aTo.length>0) {
          InternetAddress oAdr = (InternetAddress) aTo[0];
          sTo = oAdr.getAddress();
        } // fi
      } // fi
    }
    else if (replyall.equals(action)) {
      oMsg = DraftsHelper.draftMessageForReply(oDrafts, sMailHost, gu_workarea, id_user, oFolder, gu_mimemsg, true, contenttype);
      tx_subject = "Re: " + oMsg.getSubject();
      aTo = new Address[]{oOriginalMsg.getFromRecipient()};
      if (aTo!=null) {
	      if (aTo.length>0) {
          InternetAddress oAdr = (InternetAddress) aTo[0];
          sTo = oAdr.getAddress();
        } // fi
      } // fi
      sCc = RecipientsHelper.joinAddressList(oMsg.getRecipients(Message.RecipientType.CC));
    }
    else if (bo_new) {
      oMsg = DraftsHelper.draftMessage(oDrafts, sMailHost, gu_workarea, id_user, contenttype);
      sTo = nullif(request.getParameter("to"),sTo);
      
      String gu_location = request.getParameter("gu_location");
      if (gu_location!=null) {
        Object oMax = DBCommand.queryMax(oRDBMS.getConnection(), DB.id_part, DB.k_mime_parts, DB.gu_mimemsg+"='"+oMsg.getMessageGuid()+"'");
        int iLastPart;
        if (oMax!=null)
          iLastPart = Integer.parseInt(oMax.toString());
				else
					iLastPart = 0;

				ProductLocation oLoca = new ProductLocation(oRDBMS.getConnection(), gu_location);

				FileSystem oFs = new FileSystem();
				oFs.copy(oLoca.getURL(), "file://" + sTmpDir + gu_location);
				
        String sType = com.knowgate.hipermail.DBMimePart.getMimeType(oRDBMS.getConnection(),oLoca.getString(DB.xfile));

			  oRDBMS.getConnection().setAutoCommit(false);
    		PreparedStatement oStmt = oRDBMS.getConnection().prepareStatement("INSERT INTO " + DB.k_mime_parts + "("+DB.gu_mimemsg+","+DB.id_message+","+DB.id_part+","+DB.id_disposition+","+DB.id_content+","+DB.id_type+","+DB.len_part+","+DB.de_part+","+DB.file_name+") VALUES ('"+oMsg.getMessageGuid()+"',?,?,'reference',?,?,?,?,?)");
	      if (oMsg.getMessageID()==null)
	        oStmt.setString(1, oMsg.getMessageGuid());
	      else if (oMsg.getMessageID().length()==0)
	        oStmt.setString(1, oMsg.getMessageGuid());
				else
	        oStmt.setString(1, oMsg.getMessageID());
        oStmt.setInt(2, iLastPart+1);
	      oStmt.setString(3, sType);        
	      oStmt.setString(4, sType);        
        oStmt.setInt(5, oLoca.getInt(DB.len_file));
	      oStmt.setString(6, oLoca.getString(DB.xfile));
	      oStmt.setString(7, sTmpDir + gu_location);	
	      oStmt.executeUpdate();
			  oStmt.close();
			  oRDBMS.getConnection().commit();
      } // fi (gu_location)
      
    } else {
      oMsg = oFolder.getMessageByGuid(gu_mimemsg);

      tx_subject = oMsg.getSubject();
      
      sTo = RecipientsHelper.joinAddressList(oMsg.getRecipients(Message.RecipientType.TO));
      sCc = RecipientsHelper.joinAddressList(oMsg.getRecipients(Message.RecipientType.CC));
      sBcc= RecipientsHelper.joinAddressList(oMsg.getRecipients(Message.RecipientType.BCC));
      if (sTo.length()==0) sTo = nullif(request.getParameter("to"));
    }
 
    oDrafts.close(false);
    oDrafts=null;

    if (bIE)
      tx_content = quote(oMsg.getText());
    else
      tx_content = oMsg.getText();
    
    sGuid = oMsg.getMessageGuid();    
    sId = DBCommand.queryStr(oRDBMS.getConnection(),"SELECT "+DB.id_message+" FROM "+DB.k_mime_msgs+" WHERE "+DB.gu_mimemsg+"='"+sGuid+"'");
    
    oFolder.close(false);
    oFolder=null;
    oRDBMS.close();
    oRDBMS=null;
    oHndl.close();
    oHndl=null;
  }
  catch (Exception e) {  
    if (oDrafts!=null) { try {oDrafts.close(false);} catch (Exception ignore) {}}
    if (oFolder!=null) { try {oFolder.close(false);} catch (Exception ignore) {}}
    if (oRDBMS!=null) {
      try { oRDBMS.getConnection().rollback(); } catch (Exception ignore) {}
      try { oRDBMS.close(); } catch (Exception ignore) {}
    }
    if (oHndl!=null) { try { oHndl.close(); } catch (Exception ignore) {} }
    response.sendRedirect (response.encodeRedirectUrl ("../common/errmsg.jsp?title="+e.getClass().getName()+"&desc=" + e.getMessage() + "&resume=_topclose"));
    return;
  }
  
  sendUsageStats(request, "msg_new"); 
%>
<HTML>
<HEAD>
  <TITLE></TITLE>
  <META HTTP-EQUIV="Content-Type" CONTENT="text/html; charset=utf-8">
<% if (bo_new) { %>
  <META HTTP-EQUIV="refresh" CONTENT="0; url=msg_new.jsp?gu_mimemsg=<%=sGuid+(id_message==null ? "" : "&msgid="+sId)+(gu_contact==null ? "" : "&gu_contact="+gu_contact)+(action==null ? "" : "&action="+action)+(folder==null ? "" : "&folder="+folder)+"&to="+Gadgets.URLEncode(sTo)%>">
<% } else if (gu_mimemsg!=null) { %>
  <SCRIPT TYPE="text/javascript">
    parent.frames[1].location = "<%="msg_attachs.jsp?msgid="+id_message + (folder==null ? "" : "&folder=" + folder) + "&gu_mimemsg=" + gu_mimemsg%>";
  </SCRIPT>
<% } %>  
  <SCRIPT TYPE="text/javascript" SRC="../fckeditor/fckeditor.js"></SCRIPT>
  <SCRIPT TYPE="text/javascript" SRC="../javascript/cookies.js"></SCRIPT>
  <SCRIPT TYPE="text/javascript" SRC="../javascript/setskin.js"></SCRIPT>
  <SCRIPT TYPE="text/javascript" SRC="../javascript/email.js"></SCRIPT>
  <SCRIPT TYPE="text/javascript" SRC="../javascript/trim.js"></SCRIPT>
  <SCRIPT TYPE="text/javascript" SRC="../javascript/combobox.js"></SCRIPT>  
  <SCRIPT TYPE="text/javascript">
    <!--
      function validate() {
        var frm = document.forms[0];
        var del;
        var rec;
        var adr;
        var edt;
        
        if ((frm.TO.value.indexOf(',')>=0 && frm.TO.value.indexOf(';')>=0) ||
            (frm.CC.value.indexOf(',')>=0 && frm.CC.value.indexOf(';')>=0) ||
            (frm.BCC.value.indexOf(',')>=0 && frm.BCC.value.indexOf(';')>=0)) {
          alert ("Address delimiter must bu colon or semi-colon");
          return false;
        }
	
	      if (frm.TO.value.length>0) {
      	  rec = frm.TO.value.split(frm.TO.value.indexOf(',')>=0 ? "," : ";");
      	
      	  for (var t=0; t<rec.length; t++) {
      	    adr = ltrim(rtrim(rec[t]));
      	    if (adr.length>0) {
      	      if ((!check_email(adr) && adr.charAt(0)!='{') || adr.length>254) {
      	        alert ("Mail address " + adr + " is not valid");
      	        return false;
      	      } // fi (check_email) 
      	    } // fi (adr!="") 
      	  } // next
      	} // fi (TO!="")
      
      	if (frm.CC.value.length>0) {
      	  rec = frm.CC.value.split(frm.CC.value.indexOf(',')>=0 ? "," : ";");
      	
      	  for (var c=0; c<rec.length; c++) {
      	    adr = ltrim(rtrim(rec[c]));
      	    if (adr.length>0) {
      	      if ((!check_email(adr) && adr.charAt(0)!='{') || adr.length>254) {
      	        alert ("Mail address " + adr + " is not valid");
      	        return false;
      	      } // fi (check_email) 
      	    } // fi (adr!="") 
      	  } // next
      	} // fi (CC!="")
      
      	if (frm.BCC.value.length>0) {
      	  rec = frm.BCC.value.split(frm.BCC.value.indexOf(',')>=0 ? "," : ";");
      	
      	  for (var b=0; b<rec.length; b++) {
      	    adr = ltrim(rtrim(rec[b]));
      	    if (adr.length>0) {
      	      if ((!check_email(adr) && adr.charAt(0)!='{') || adr.length>254) {
      	        alert ("Mail address " + adr + " is not valid");
      	        return false;
      	      } // fi (check_email) 
      	    } // fi (adr!="") 
      	  } // next
      	} // fi (CC!="")
      	
      	frm.FROM.value = frm.SEL_FROM.options[frm.SEL_FROM.selectedIndex].value;
      	
<% if (contenttype.equals("html")) { %>
        edt = FCKeditorAPI.GetInstance("MSGBODY");
        
        if (edt.GetHTML().indexOf("{#")>=0) {
          if (frm.TO.value.indexOf("{")<0 && frm.CC.value.indexOf("{")<0 && frm.BCC.value.indexOf("{")<0) {
            alert ("The body of the message contains personalized fields, but it is not being sent to any distribution list");
            return false;
          }
        }
<% } %>
      	return true;
      } // validate

      // ----------------------------------------------------------------------
      
      function savemsg() {
        var frm = document.forms[0];
        
        if (validate()) {           
            frm.action = "msg_store.jsp";
	    frm.submit();
	}
      }

      // ----------------------------------------------------------------------
      
      function send() {
        var frm = document.forms[0];
        
        if (validate()) {

          if (frm.TO.value.length==0 && frm.CC.value.length==0 && frm.BCC.value.length==0) {
            alert ("You must specify at least one recipient");
            return false;
          }
	        else if (frm.SUBJECT.value.length==0 || frm.SUBJECT.value=="no subject") {
	          if (window.confirm("Message has no subject. Are you sure that you want to send it anyway?")) {
              frm.action = "msg_send.jsp";
	            frm.submit();
	          }
	        }
	        else {
            frm.action = "msg_send.jsp";
	          frm.submit();
	        }
	      } // fi (validate())
      } // send

      // ----------------------------------------------------------------------

      function attachfiles() {
        window.open ("attachfiles.htm?gu_mimemsg=<%=gu_mimemsg%>&id_message=<%=(id_message==null ? "" : id_message)%>", "attachfiles_<%=gu_mimemsg%>", "toolbar=no,directories=no,menubar=no,width=500,height=400");
      }

      // ----------------------------------------------------------------------

			function insertCustomField() {
        var frm = document.forms[0];
<% if (contenttype.equals("html")) { %>
        var oEditor = FCKeditorAPI.GetInstance("MSGBODY") ;
				if ( oEditor.EditMode == FCK_EDITMODE_WYSIWYG ) {
          oEditor.InsertHtml(getCombo(frm.sel_custom)) ;
        }
        else {
          alert( 'You must be on WYSIWYG mode!' ) ;
        }
<% } else { %>
        if (document.selection) {
			    frm.MSGBODY.focus();

					sel = document.selection.createRange();
					sel.text = getCombo(frm.sel_custom);
        }
				else if (frm.MSGBODY.selectionStart || frm.MSGBODY.selectionStart == '0') {
				  var startPos = frm.MSGBODY.selectionStart;
					var endPos = frm.MSGBODY.selectionEnd;
					frm.MSGBODY.value = frm.MSGBODY.value.substring(0, startPos)+getCombo(frm.sel_custom)+frm.MSGBODY.value.substring(endPos, frm.MSGBODY.value.length);
				} else {
				  frm.MSGBODY.value += getCombo(frm.sel_custom);
			  }
<% } %>
      } // insertCustomField
			
    //-->
  </SCRIPT>
</HEAD>
<% if (null!=request.getParameter("gu_mimemsg")) { %>
<BODY SCROLLING="no">
<FORM NAME="msg" METHOD="post">
  <INPUT TYPE="hidden" NAME="GUID" VALUE="<%=sGuid%>">
  <INPUT TYPE="hidden" NAME="ID" VALUE="<%=sId%>">
  <INPUT TYPE="hidden" NAME="WRKA" VALUE="<%=gu_workarea%>">
  <INPUT TYPE="hidden" NAME="FOLDER" VALUE="<%=folder%>">
  <INPUT TYPE="hidden" NAME="CONTACT" VALUE="<%=gu_contact%>">
  <INPUT TYPE="hidden" NAME="PRIORITY" VALUE="3">
  <INPUT TYPE="hidden" NAME="FROM">

  <TABLE SUMMARY="Recipients" WIDTH="100%">
    <TR HEIGHT="20">
      <TD BGCOLOR="linen" WIDTH="100px"><FONT CLASS="formstrong">From:</FONT></TD>
      <TD BGCOLOR="#EAE5E1">
        <SELECT NAME="SEL_FROM">
<%      for (int a=0; a<iAccounts; a++) {
          out.write("<OPTION VALUE=\""+oAccounts.getString(0,a)+"\" "+(oAccounts.getString(0,a).equals(oMacc.getString(DB.gu_account)) ? "SELECTED" : "")+">"+oAccounts.getString(1,a)+" &lt;"+oAccounts.getString(2,a)+"&gt;</OPTION>");
	}
%>
        </SELECT>
      </TD>
    </TR>
    <TR HEIGHT="20">
      <TD BGCOLOR="linen" WIDTH="100px"><FONT CLASS="formstrong">To:</FONT></TD>
      <TD BGCOLOR="#EAE5E1"><INPUT TYPE="text" NAME="TO" VALUE="<%=sTo%>" SIZE="70">
      <INPUT CLASS="minibutton" TYPE="button" VALUE="Address book" onclick="window.open ('addrbook_f.jsp', 'hipermailaddressbook','toolbar=no,directories=no,menubar=no,resizable=no,width=720,height=500')"></TD>
    </TR>
    <TR HEIGHT="20">
      <TD BGCOLOR="linen" WIDTH="100px"><FONT CLASS="formstrong">Cc:</FONT></TD>
      <TD BGCOLOR="#EAE5E1"><INPUT TYPE="text" NAME="CC" VALUE="<%=sCc%>" SIZE="70">
      <INPUT CLASS="minibutton" TYPE="button" VALUE="Address book" onclick="window.open ('addrbook_f.jsp', 'hipermailaddressbook','toolbar=no,directories=no,menubar=no,resizable=no,width=720,height=500')"></TD>
    </TR>
    <TR HEIGHT="20">
      <TD BGCOLOR="linen" WIDTH="100px"><FONT CLASS="formstrong">Bcc:</FONT></TD>
      <TD BGCOLOR="#EAE5E1"><INPUT TYPE="text" NAME="BCC" VALUE="<%=sBcc%>" SIZE="70">
      <INPUT CLASS="minibutton" TYPE="button" VALUE="Address book" onclick="window.open ('addrbook.jsp', 'hipermailaddressbook','toolbar=no,directories=no,menubar=no,resizable=no,width=720,height=500')"></TD>
    </TR>
    <TR HEIGHT="20">
      <TD BGCOLOR="linen" WIDTH="100px"><FONT CLASS="formstrong">Subject:</FONT></TD>
      <TD BGCOLOR="#EAE5E1"><INPUT TYPE="text" NAME="SUBJECT" SIZE="70" MAXLENGTH="254" VALUE="<%=nullif(tx_subject)%>"></TD>
    </TR>
    <TR >
      <TD BGCOLOR="linen" COLSPAN="2" HEIGHT="20">
        <TABLE SUMMARY="Buttons" BORDER="0">
          <TR>
            <TD VALIGN="middle"><IMG SRC="../images/images/hipermail/send2.gif" WIDTH="35" HEIGHT="35" BORDER="0" ALT="Send"></TD>
            <TD VALIGN="middle"><A CLASS="linkplain" HREF="#" onclick="send()" TITLE="Send"><B>Send</B></A></TD>
            <TD><IMG SRC="../images/images/spacer.gif" WIDTH="16" HEIGHT="1" BORDER="0" ALT=""></TD>
            <TD VALIGN="middle"><IMG SRC="../images/images/hipermail/attachfiles.gif" WIDTH="35" HEIGHT="35" BORDER="0" ALT="Attach"></TD>
            <TD VALIGN="middle"><A CLASS="linkplain" HREF="#" onclick="attachfiles()" TITLE="Attach"><B>Attach Files</B></A></TD>
            <TD><IMG SRC="../images/images/spacer.gif" WIDTH="16" HEIGHT="1" BORDER="0" ALT=""></TD>
            <TD VALIGN="middle"><IMG SRC="../images/images/hipermail/savemsg.gif" WIDTH="35" HEIGHT="35" BORDER="0" ALT="Save"></TD>
            <TD VALIGN="middle"><A CLASS="linkplain" HREF="#" onclick="savemsg()" TITLE="Save"><B>Save Message</B></A></TD>
            <TD VALIGN="middle"><IMG SRC="../images/images/spacer.gif" WIDTH="8" HEIGHT="1" BORDER="0" ALT=""></TD>
	    <TD VALIGN="middle">
	      <TABLE SUMMARY="Plain Text or HTML" BORDER="0" CELLSPACING="0" CELLPADDING="0">
<%   if (bIE) { %>
	        <TR>
	          <TD>
                    <INPUT TYPE="radio" NAME="CONTENTTYPE" VALUE="html" <%if (contenttype.equals("html")) out.write("CHECKED"); %> onclick="savemsg()">&nbsp;<FONT CLASS="formplain">HTML</FONT>&nbsp;&nbsp;
	          </TD>
	        </TR>
<%   } %>
	        <TR>
	          <TD>
                    <INPUT TYPE="radio" NAME="CONTENTTYPE" VALUE="text" <%if (contenttype.equals("text") || contenttype.equals("plain")) out.write("CHECKED"); %> onclick="savemsg()">&nbsp;<FONT CLASS="formplain">Texto</FONT>
	          </TD>
	        </TR>
	      </TABLE>
      </TD>

	    <TD VALIGN="middle">
	      <TABLE SUMMARY="Custom Tags" BORDER="0" CELLSPACING="0" CELLPADDING="0">
	        <TR>
	          <TD CLASS="formplain">Change</TD>
	        </TR>
	        <TR>
	          <TD>
						  <SELECT NAME="sel_custom" CLASS="combomini"><OPTION VALUE=""></OPTION><OPTION VALUE="{#Data.Name}">Name</OPTION><OPTION VALUE="{#Data.Surname}">Surname</OPTION><OPTION VALUE="{#Data.Legal_Name}">Legal Name</OPTION><OPTION VALUE="{#Address.EMail}">e-mail</OPTION><OPTION VALUE="{#Address.Street_Type}">Street Type</OPTION><OPTION VALUE="{#Address.Street_Name}">Street Name</OPTION><OPTION VALUE="{#Address.Street_Num}">Street Number</OPTION><OPTION VALUE="{#Address.Line1}">Address Line 1</OPTION><OPTION VALUE="{#Address.Line2}">Address Line 2</OPTION><OPTION VALUE="{#Address.Country}">Country</OPTION><OPTION VALUE="{#Address.State}">State/Province</OPTION><OPTION VALUE="{#Address.City}">City</OPTION><OPTION VALUE="{#Address.Zipcode}">Zipcode</OPTION><OPTION VALUE="{#Address.Proffesional_Phone}">Telephone</OPTION></SELECT>&nbsp;<INPUT TYPE="button" CLASS="minibutton" VALUE="Insert" onclick="insertCustomField()">
	          </TD>
	        </TR>
	      </TABLE>
      </TD>
<% if (contenttype.equals("html")) { %>
	    <TD VALIGN="middle" CLASS="formplain">
	    	<INPUT TYPE="checkbox" NAME="chk_notification" VALUE="1">&nbsp;Request read confirmation receipt
	    	<BR/>
	    	<INPUT TYPE="checkbox" NAME="chk_webbeacon" VALUE="1">&nbsp;Insert Web Beacon
      </TD>
<% } else { %>
	    <TD VALIGN="top" CLASS="formplain">
	    	<INPUT TYPE="checkbox" NAME="chk_notification" VALUE="1">&nbsp;Request read confirmation receipt
      </TD>
<% } %>
    </TR>
        </TABLE>
      </TD>        
    </TR>    
  </TABLE>
  <TABLE SUMMARY="Editor" BORDER="0" CELLSPACING="0" CELLPADDING="0" WIDTH="100%" HEIGHT="100%">
    <TR>
      <TD VALIGN="top">
<%  if (!bo_new) { 
      if (contenttype.equals("html")) { %>
        <SCRIPT TYPE="text/javascript">
        <!--
        var oFCKeditor = new FCKeditor( 'MSGBODY' ) ;
        oFCKeditor.BasePath = "<%=request.getContextPath()%>/fckeditor/";       
        oFCKeditor.Config['CustomConfigurationsPath'] = oFCKeditor.BasePath + "fckconfig.js";
        switch (screen.height) {
          case 600: oFCKeditor.Height = "136"; break;
          case 768: oFCKeditor.Height = "288"; break;
          case 800: oFCKeditor.Height = "320"; break;
          case 864: oFCKeditor.Height = "384"; break;
          case 864: oFCKeditor.Height = "384"; break;
          case 1000: oFCKeditor.Height = "500"; break;
          case 1024: oFCKeditor.Height = "512"; break;
          case 1152: oFCKeditor.Height = "600"; break;
          case 1200: oFCKeditor.Height = "720"; break;
          default : oFCKeditor.Height = String(Math.floor(parseFloat(136*screen.height/600)));
        }        
        oFCKeditor.Value = "<%=nullif(tx_content)%>";
        oFCKeditor.Create() ;
        //-->
        </SCRIPT>
<%    } else { %>
        <TEXTAREA NAME="MSGBODY" COLS="93" ROWS="18"><%=nullif(tx_content)%></TEXTAREA>
<%    }
    } %>
      </TD>
    </TR>
  </TABLE>
</FORM>
</BODY>
<% } %>
<%@ include file="../methods/page_epilog.jspf" %>
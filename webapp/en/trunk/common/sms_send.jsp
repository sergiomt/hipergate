<%@ page import="java.util.Properties,java.util.Date,java.io.IOException,java.net.URLDecoder,java.sql.PreparedStatement,java.sql.Timestamp,java.sql.Types,com.knowgate.jdc.JDCConnection,com.knowgate.dataobjs.*,com.knowgate.acl.*,com.knowgate.misc.Gadgets,com.knowgate.sms.SMSMessage,com.knowgate.sms.SMSResponse,com.knowgate.sms.SMSPush,com.knowgate.sms.SMSPushFactory" language="java" session="false" contentType="text/html;charset=UTF-8" %>
<%@ include file="../methods/page_prolog.jspf" %><%@ include file="../methods/dbbind.jsp" %><%@ include file="../methods/cookies.jspf" %><%@ include file="../methods/authusrs.jspf" %><%@ include file="../methods/clientip.jspf" %><%@ include file="../methods/nullif.jspf" %><%
/*
  Copyright (C) 2003-2009  Know Gate S.L. All rights reserved.
                           C/Oña, 107 1º2 28050 Madrid (Spain)

  Redistribution and use in source and binary forms, with or without
  modification, are permitted provided that the following conditions
  are met:

  1. Redistributions of source code must retain the above copyright
     notice, this list of conditions and the following disclaimer.

  2. The end-user documentation included with the redistribution,
     if any, must include the following acknowledgment:
     "This product includes software parts from hipergate
     (http://www.hipergate.org/)."
     Alternately, this acknowledgment may appear in the software itself,
     if and wherever such third-party acknowledgments normally appear.

  3. The name hipergate must not be used to endorse or promote products
     derived from this software without prior written permission.
     Products derived from this software may not be called hipergate,
     nor may hipergate appear in their name, without prior written
     permission.

  This library is distributed in the hope that it will be useful,
  but WITHOUT ANY WARRANTY; without even the implied warranty of
  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.

  You should have received a copy of hipergate License with this code;
  if not, visit http://www.hipergate.org or mail to info@hipergate.org
*/

  response.addHeader ("Pragma", "no-cache");
  response.addHeader ("cache-control", "no-store");
  response.setIntHeader("Expires", 0);

  final String PAGE_NAME = "sms_send";

  /* Autenticate user cookie */
  if (autenticateSession(GlobalDBBind, request, response)<0) return;

  String id_domain = getCookie(request,"domainid","");
  String gu_workarea = getCookie(request,"workarea",null);
  String gu_user = getCookie(request,"userid",null); 
  
  String tx_msg = request.getParameter("tx_msg");
  String nu_msisdn  = request.getParameter("nu_msisdn");
  String gu_address = nullif(request.getParameter("gu_address"));
  String gu_contact = nullif(request.getParameter("gu_contact"));
  String gu_company = nullif(request.getParameter("gu_company"));
      
  if (GlobalDBBind.getProperty("smsprovider","").length()==0) {
    response.sendRedirect (response.encodeRedirectUrl ("errmsg.jsp?title=Error SMS Provider not found&desc=No SMS provider class found at property smsprovider of hipergate.cnf&resume=_close"));
    return;
  } // fi
  if (GlobalDBBind.getProperty("smsaccount","").length()==0) {
    response.sendRedirect (response.encodeRedirectUrl ("errmsg.jsp?title=Error SMS Account not found&desc=No SMS account class found at property smsaccount of hipergate.cnf&resume=_close"));
    return;
  } // fi
  if (GlobalDBBind.getProperty("smspassword","").length()==0) {
    response.sendRedirect (response.encodeRedirectUrl ("errmsg.jsp?title=Error SMS Password not foundE&desc=No SMS password class found at property smsaccount of hipergate.cnf&resume=_close"));
    return;
  } // fi

  JDCConnection oCon = null;
  PreparedStatement oStm = null;
    
  try {
    SMSPush oPsh = SMSPushFactory.newInstanceOf(GlobalDBBind.getProperty("smsprovider"));

		SMSMessage oMsg = new SMSMessage(SMSMessage.MType.PLAIN_TEXT, Gadgets.generateUUID(), GlobalDBBind.getProperty("smsaccount"),
																	   nu_msisdn, "", tx_msg, null, new Date()); 

		Properties oPrp = new Properties();
		if (GlobalDBBind.getProperty("smsprovider").equals("com.knowgate.sms.SMSPushRealidadFutura")) {
		  oPrp.put("from", request.getParameter("nu_from"));
		}
		
		oPsh.connect(GlobalDBBind.getProperty("smsurl"), GlobalDBBind.getProperty("smsaccount"), GlobalDBBind.getProperty("smspassword"), oPrp);
		SMSResponse oRsp = oPsh.push (oMsg);
		oPsh.close();

    oCon = GlobalDBBind.getConnection(PAGE_NAME);   
    oCon.setAutoCommit (false);
		oStm = oCon.prepareStatement("INSERT INTO "+DB.k_sms_audit+" (id_sms,gu_workarea,pg_part,nu_msisdn,id_msg,gu_batch,bo_success,nu_error,id_status,dt_sent,gu_writer,gu_address,gu_contact,gu_company,tx_msg,tx_err) VALUES ('"+oRsp.messageId()+"','"+gu_workarea+"',1,'"+nu_msisdn+"',NULL,NULL,?,?,?,?,'"+gu_user+"',?,?,?,?,?)");
		oStm.setShort(1, (short) (oRsp.errorCode()==SMSResponse.ErrorCode.NONE ? 1 : 0));
		oStm.setInt(2, (int) oRsp.errorCode().intValue());
		oStm.setInt(3, (int) oRsp.notificationStatusCode().intValue());
		oStm.setTimestamp(4, new Timestamp(oRsp.dateStamp().getTime()));
		if (gu_address.length()>0)
		  oStm.setString(5, gu_address);
    else
    	oStm.setNull(5, Types.CHAR);
		if (gu_contact.length()>0)
		  oStm.setString(6, gu_contact);
    else
    	oStm.setNull(6, Types.CHAR);
		if (gu_company.length()>0)
		  oStm.setString(7, gu_company);
    else
    	oStm.setNull(7, Types.CHAR);
    oStm.setString(8, tx_msg);
    if (oRsp.errorCode()==SMSResponse.ErrorCode.NONE)
    	oStm.setNull(9, Types.VARCHAR);
    else
    	oStm.setString(9, Gadgets.left(oRsp.errorMessage(),254));
	  oStm.executeUpdate();
	  oStm.close();
    oCon.commit();
    oCon.close(PAGE_NAME);

		if (oRsp.errorCode()!=SMSResponse.ErrorCode.NONE) {
		  response.sendRedirect (response.encodeRedirectUrl ("errmsg.jsp?title=Error&desc=" + oRsp.errorCode() + " " + oRsp.errorMessage() + "&resume=_close"));
		}
  }
  catch (Exception e) {  
    disposeConnection(oCon,PAGE_NAME);
    oCon = null;

    if (com.knowgate.debug.DebugFile.trace) {
      com.knowgate.dataobjs.DBAudit.log ((short)0, "CJSP", sUserIdCookiePrologValue, request.getServletPath(), "", 0, request.getRemoteAddr(), e.getClass().getName(), e.getMessage());
    }

    response.sendRedirect (response.encodeRedirectUrl ("errmsg.jsp?title="+e.getClass().getName()+"&desc=" + e.getMessage() + "&resume=_close"));
  }
  
  if (null==oCon) return;
  
  oCon = null;
  
  out.write ("<HTML><HEAD><TITLE>Wait...</TITLE><" + "SCRIPT LANGUAGE='JavaScript' TYPE='text/javascript'>top.close();<" + "/SCRIPT" +"></HEAD></HTML>");

%><%@ include file="../methods/page_epilog.jspf" %>
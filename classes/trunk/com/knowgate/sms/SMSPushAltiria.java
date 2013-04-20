/*
  Copyright (C) 2009  Know Gate S.L. All rights reserved.

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

package com.knowgate.sms;

import com.knowgate.sms.SMSPush;

import java.io.IOException;
import java.io.InputStreamReader;
import java.io.BufferedReader;
import java.io.OutputStreamWriter;
import java.io.UnsupportedEncodingException;

import java.sql.SQLException;

import java.net.URL;
import java.net.HttpURLConnection;
import java.net.MalformedURLException;

import java.text.SimpleDateFormat;
import java.util.Date;
import java.util.Properties;

/**
 * <p>Implementation for sending SMS messages with Altiria platform</p>
 * @author Sergio Montoro Ten
 * @version 5.0
 */

public final class SMSPushAltiria extends SMSPush {
    
  private static SimpleDateFormat DTF = new SimpleDateFormat("yyyyMMddHHmmssSSS");

  private String sUsr, sPwd;
  private HttpURLConnection oCon;
  
  /**
   * <p>Open HTTP connection for sending messages</p>
   * @param sUrl Base URL. Typically it should be "http://www.altiria.net/sustituirPOSTsms/");
   * where sustituirPOSTsms is a customer specific string provided by Altiria
   * @param sUser Altiria Customer Account Identifier
   * @param sPassword Altiria Customer Account Password
   * @param oConnectionProps Not used, must be null
   * @throws IOException
   * @throws MalformedURLException
   */

  public void connect(String sUrl, String sUser, String sPassword, Properties oConnectionProps)
    throws IOException,SQLException,MalformedURLException {

	sUsr = sUser;
	sPwd = sPassword;

	URL oUrl = new URL(sUrl);
    oCon = (HttpURLConnection) oUrl.openConnection();
    oCon.setRequestProperty("Content-Type", "application/x-www-form-urlencoded; charset=UTF-8");
    oCon.setDoOutput(true);
    oCon.setDoInput (true);
    oCon.setUseCaches(false);
	oCon.setRequestMethod("POST");
  } // connect

  /**
   * Send SMS
   * @param SMSMessage
   * @return SMSResponse
   * @throws IOException
   * @throws SQLException
   * @throws IllegalArgumentException
   * @throws UnsupportedEncodingException
   */

  public SMSResponse push (SMSMessage oMsg)
    throws IOException,SQLException,IllegalArgumentException,UnsupportedEncodingException {    

    String sData = "cmd=sendsms\ndomainId="+oMsg.subject()+"\nlogin="+sUsr+"\npasswd="+sPwd+"\ndest="+oMsg.msisdnNumber()+"\nmsg="+oMsg.textBody();

	OutputStreamWriter oWrt = new OutputStreamWriter(oCon.getOutputStream());
    oWrt.write(sData);
    oWrt.flush();
	oWrt.close();
	
    int iStatusCode = oCon.getResponseCode();
    SMSResponse oRsp;
	BufferedReader oRdr;
    String sLin, uLin, sId, sErr;
    SMSResponse.ErrorCode iErrCode;
		
	switch (iStatusCode) {
	  case 200:
	  	sId = "";
	    oRdr = new BufferedReader(new InputStreamReader(oCon.getInputStream()));
	
	    sLin = oRdr.readLine();
        while( null != sLin ) {
		  if (sLin.startsWith("OK")) {
		  	sId = sLin.substring(sLin.indexOf("idAck:")+6);
		  } else if (sLin.startsWith("ERROR")) {
			switch (Integer.parseInt(sLin.substring(sLin.indexOf("errNum:")+7))) {
				case 1:
	    			oRsp = new SMSResponse(oMsg.messageId(), new Date(), SMSResponse.ErrorCode.UNKNOWN_ERROR, SMSResponse.StatusCode.NEGATIVE_FAILED_DELIVERY, "Error interno. Contactar con el soporte tecnico");
					break;					
				case 10:
	    			oRsp = new SMSResponse(oMsg.messageId(), new Date(), SMSResponse.ErrorCode.INVALID_MSISDN, SMSResponse.StatusCode.NEGATIVE_FAILED_DELIVERY, "Error en el formato del numero de telefono");
					break;					
				case 11:
	    			oRsp = new SMSResponse(oMsg.messageId(), new Date(), SMSResponse.ErrorCode.INVALID_CHARACTER, SMSResponse.StatusCode.NEGATIVE_FAILED_DELIVERY, "Error en el envio de los parametros del comando o codificacion incorrecta");
					break;					
				case 13:
	    			oRsp = new SMSResponse(oMsg.messageId(), new Date(), SMSResponse.ErrorCode.TEXT_TOO_LONG, SMSResponse.StatusCode.NEGATIVE_FAILED_DELIVERY, "El mensaje excede la longitud maxima permitida");
					break;					
				case 14:
	    			oRsp = new SMSResponse(oMsg.messageId(), new Date(), SMSResponse.ErrorCode.TEXT_TOO_LONG, SMSResponse.StatusCode.NEGATIVE_FAILED_DELIVERY, "La peticion HTTP usa una codificacion de caracteres invalida");
					break;					
				case 15:
	    			oRsp = new SMSResponse(oMsg.messageId(), new Date(), SMSResponse.ErrorCode.INVALID_MSISDN, SMSResponse.StatusCode.NEGATIVE_FAILED_DELIVERY, "No hay destinatarios validos para enviar el mensaje");
					break;					
				case 17:
	    			oRsp = new SMSResponse(oMsg.messageId(), new Date(), SMSResponse.ErrorCode.INVALID_CHARACTER, SMSResponse.StatusCode.NEGATIVE_FAILED_DELIVERY, "Mensaje vacio");
					break;					
				case 20:
	    			oRsp = new SMSResponse(oMsg.messageId(), new Date(), SMSResponse.ErrorCode.AUTHENTICATION_FAILURE, SMSResponse.StatusCode.NEGATIVE_FAILED_DELIVERY, "Error en la autentificacion");
					break;					
				case 22:
	    			oRsp = new SMSResponse(oMsg.messageId(), new Date(), SMSResponse.ErrorCode.INVALID_MSISDN, SMSResponse.StatusCode.NEGATIVE_FAILED_DELIVERY, "El remitente seleccionado para el envio no es valido");
					break;					
				case 30:
	    			oRsp = new SMSResponse(oMsg.messageId(), new Date(), SMSResponse.ErrorCode.TEXT_TOO_LONG, SMSResponse.StatusCode.NEGATIVE_FAILED_DELIVERY, "La url y el mensaje superan la longitud maxima permitida");
					break;					
				case 31:
	    			oRsp = new SMSResponse(oMsg.messageId(), new Date(), SMSResponse.ErrorCode.TEXT_TOO_LONG, SMSResponse.StatusCode.NEGATIVE_FAILED_DELIVERY, "La longitud de la url es incorrecta");
					break;					
				case 32:
	    			oRsp = new SMSResponse(oMsg.messageId(), new Date(), SMSResponse.ErrorCode.INVALID_CHARACTER, SMSResponse.StatusCode.NEGATIVE_FAILED_DELIVERY, "La url contiene caracteres no permitidos");
					break;					
				default:
	    			oRsp = new SMSResponse(oMsg.messageId(), new Date(), SMSResponse.ErrorCode.UNKNOWN_ERROR, SMSResponse.StatusCode.NEGATIVE_FAILED_DELIVERY, "Error "+sLin.substring(sLin.indexOf("errNum:")+7));
					break;					
			}
		  }
	      sLin = oRdr.readLine();
        }
        oRdr.close();
	    oRsp = new SMSResponse(sId, new Date(), SMSResponse.ErrorCode.NONE, SMSResponse.StatusCode.POSITIVE_ACK, "");
	    break;

	  case 400:
	    oRdr = new BufferedReader(new InputStreamReader(oCon.getErrorStream()));
	
		iErrCode = SMSResponse.ErrorCode.UNKNOWN_ERROR;
		sErr = "";
	    sLin = oRdr.readLine();
        while( null != sLin ) {
	      sLin = oRdr.readLine();
        }
        oRdr.close();
	    oRsp = new SMSResponse(oMsg.messageId(), new Date(), iErrCode, SMSResponse.StatusCode.NEGATIVE_FAILED_DELIVERY, sErr);
	    break;

	    default:
	      throw new IOException("Invalid HTTP response Code "+String.valueOf(iStatusCode));
	} // end switch

	return oRsp;
  } // push

  /**
   * Open a new connection and send and SMS
   * @param sBaseUrl Altiria HTTP base URL
   * @param sDomain Altiria Customer Domain
   * @param sAccount Altiria Customer Account Identifier
   * @param sAuthStr Altiria Customer Account Password
   * @param sMsisdn MSISDN Number with country preffix (no 00 nor +) like 34609090603
   * @param sText Message Text.
   * @return SMSResponse
   * @throws IOException
   * @throws IllegalArgumentException
   */

  public static SMSResponse push (String sBaseUrl, String sDomain, String sAccount, String sAuthStr,
  						          String sMsisdn, String sText)
    throws IOException,IllegalArgumentException {      
  	Date dtNow = new Date();
  	String sId = DTF.format(dtNow);
  	SMSResponse oRsp = null;
    SMSPushAltiria oSms = new SMSPushAltiria();
    try {
  	  oSms.connect(sBaseUrl, sAccount, sAuthStr, null);
      oRsp = oSms.push(new SMSMessage(SMSMessage.MType.PLAIN_TEXT,
      			       sId, sAccount,
      			       sMsisdn, sDomain, sText,
      			       "UTF-8", dtNow));
  	  oSms.close();
  	} catch (SQLException neverthrown) {}
  	  catch (UnsupportedEncodingException neverthrown) {}
  	return oRsp;
  } // push
  
  public void close() throws IOException,SQLException {
  	oCon.disconnect();
	oCon=null;
  }
  
} // SMSPushAltiria

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

import java.io.IOException;
import java.io.BufferedReader;
import java.io.InputStreamReader;
import java.io.UnsupportedEncodingException;

import java.text.SimpleDateFormat;

import java.util.Date;
import java.util.Properties;

import java.sql.SQLException;

import java.net.URL;
import java.net.URLEncoder;
import java.net.HttpURLConnection;
import java.net.MalformedURLException;


public final class SMSPushRealidadFutura extends SMSPush {

  	private static SimpleDateFormat DTF = new SimpleDateFormat("yyyyMMddHHmmssSSS");

	private static final String DEFAULT_URL = "http://railsfax.realidadfutura.net/sms/send_sms?";

	private String sUrl, sUsr, sPwd;
	
	private Properties oPrp;
	
	/**
     * <p>Prepare internal state for sending messages</p>
     * @param sBaseUrl Base URL. Typically it should be "http://railsfax.realidadfutura.net/sms/send_sms?",
     * if null then the default value http://railsfax.realidadfutura.net/sms/send_sms? is used
     * The target URL will be sUrl+"username="+sUser+"&password="+sPassword+"&from="+oConnectionProps.from+"&to="+34XXXXXXXXX+"&text=Message Text"
     * @param sUser Realidad Futura Customer Account Identifier
     * @param sPassword Realidad Futura Customer Account Password
     * @param oConnectionProps Set property from for changing sender's number
     * @throws IOException
     * @throws MalformedURLException
     */
	public void connect(String sBaseUrl, String sUser, String sPassword, Properties oConnectionProps)
		throws IOException, SQLException, MalformedURLException {

		// Sanitize base URL
		if (sUrl==null) sUrl = DEFAULT_URL;
		if (sUrl.length()==0) sUrl = DEFAULT_URL;
		if (!sUrl.endsWith("?")) sUrl += "?";

		sUrl = sBaseUrl;
		sUsr = sUser;
		sPwd = sPassword;
		oPrp = oConnectionProps;

	}

	/**
	 * This method does not do anything for Realidad Futura platform
	 */
	public void close() throws IOException, SQLException {
	}

  /**
   * Open HTTP connection and send SMS
   * @param SMSMessage
   * @return SMSResponse
   * @throws IOException
   * @throws SQLException
   * @throws IllegalArgumentException
   * @throws UnsupportedEncodingException
   */
	public SMSResponse push(SMSMessage oMsg)
		throws IOException, SQLException, IllegalArgumentException, UnsupportedEncodingException {

    	SMSResponse oRsp;
		BufferedReader oRdr;

		String sErr, sLin, sFrm = "";
		if (oPrp.getProperty("from")!=null) sFrm = "&from="+oPrp.getProperty("from");

		URL oUrl = new URL(sUrl+"username="+sUsr+"&password="+sPwd+sFrm+"&text="+URLEncoder.encode(oMsg.textBody(), "ISO8859_1"));
    	HttpURLConnection oCon = (HttpURLConnection) oUrl.openConnection();
	    int iStatusCode = oCon.getResponseCode();
	    switch (iStatusCode) {
	    	case 200:
	    		oRdr = new BufferedReader(new InputStreamReader(oCon.getInputStream()));
				oRdr.close();
				oRsp = new SMSResponse(oMsg.messageId(), new Date(), SMSResponse.ErrorCode.NONE, SMSResponse.StatusCode.POSITIVE_ACK, "");
				break;
	    	case 400:
	    		oRdr = new BufferedReader(new InputStreamReader(oCon.getErrorStream()));
				sErr = "";
				sLin = oRdr.readLine();
        		while( null != sLin ) {
        		  sErr += sLin + "\n";
        		  sLin = oRdr.readLine();
        		} // wend
				oRdr.close();
				oRsp = new SMSResponse(oMsg.messageId(), new Date(), SMSResponse.ErrorCode.UNKNOWN_ERROR, SMSResponse.StatusCode.NEGATIVE_FAILED_DELIVERY, sErr);
				break;
	    	default:
	      		throw new IOException("Invalid HTTP response Code "+String.valueOf(iStatusCode));
	    } // end switch	
		
		oCon.disconnect();
		
		return oRsp;
	} // push

	/**
	 * Open a new connection and send and SMS
	 * @param sUser Realidad Futura Customer Account Identifier
     * @param sAuthStr Realidad Futura Customer Account Password
     * @param sFrom Sender's Number
     * @param sTo Recipient's MSISDN Number with country preffix like +34609090603
     * @param sText Message Text.
     * @return SMSResponse
     * @throws IOException
     * @throws IllegalArgumentException
	*/

	public static SMSResponse push (String sAccount, String sAuthStr,
  						            String sFrom, String sTo, String sText)
    	throws IOException,IllegalArgumentException {
  		Date dtNow = new Date();
  		String sId = DTF.format(dtNow);
  		SMSResponse oRsp = null;
    	SMSPushRealidadFutura oSms = new SMSPushRealidadFutura();
    	try {
    		Properties oProps = new Properties();
    		oProps.put("from", sFrom);
  	  		oSms.connect(null, sAccount, sAuthStr, oProps);
      		oRsp = oSms.push(new SMSMessage(SMSMessage.MType.PLAIN_TEXT,
      			       		 sId, sAccount, sTo, "", sText, "ISO8859_1", dtNow));
  		} catch (SQLException neverthrown) {}
  	  	  catch (UnsupportedEncodingException neverthrown) {}
  		return oRsp;
  	} // push

}

package com.knowgate.sms;

import java.io.IOException;
import java.net.URL;
import java.net.MalformedURLException;

import java.util.Date;
import java.util.Properties;

import org.apache.commons.httpclient.HttpClient;
import org.apache.commons.httpclient.UsernamePasswordCredentials;
import org.apache.commons.httpclient.methods.PostMethod;

public class SMSPushSybase365 extends SMSPush {
	
	private HttpClient oHttpCli;
	
	public SMSPushSybase365() {
	  oHttpCli = null;
	}

	/**
	 * Method connect
	 * @param sUrl
	 * @param sUser
	 * @param sPassword
	 @throws IOException
	 @throws MalformedURLException
	 @throws ProtocolNotSuppException
	 @throws ParseException
	 @throws ModuleException
	 *
	 */
	public void connect(String sUrl, String sUser, String sPassword, Properties oProps) throws IOException, MalformedURLException {
      
      URL oUrl = new URL(sUrl);

	  HttpClient oHttpCli = new HttpClient();
	
	  oHttpCli.getState().setCredentials("Access Restricted", oUrl.getHost(),
                					     new UsernamePasswordCredentials(sUser, sPassword));

	  
	}

	/**
	 * Method close
	 */
	public void close() {
	  oHttpCli = null;
	}	

	public SMSResponse push (SMSMessage oSms) {
	  PostMethod oPost = new PostMethod();
	  oPost.addRequestHeader("Content-type", "application/x-www-form-urlencoded");
	  oPost.addParameter("Subject","782585_114709171");
	  oPost.addParameter("List",sRecipient);
	  oPost.addParameter("Text",sText);
	  oPost.setDoAuthentication(true);
	  oHttpCli.executeMethod(oPost);
	  String sResponse = oPost.getResponseBodyAsString();
	  oPost.releaseConnection();

      int iId1 = sResponse.indexOf("ORDERID=")+8;
      int iId2 = iId1;
      while (Character.isDigit(sResponse.charAt(iId2))) iId2++;
      
	  return new SMSResponse(sResponse.substring(iId1, iId2),SMSResponse.ErrorCode.NONE, SMSResponse.StatusCode.POSITIVE_ACK);

	  return null;
	} // push

}

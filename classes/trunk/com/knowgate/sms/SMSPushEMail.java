/*
  Copyright (C) 2008  Know Gate S.L. All rights reserved.

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
import java.io.UnsupportedEncodingException;

import java.net.MalformedURLException;

import java.sql.SQLException;

import java.util.Date;
import java.util.Properties;

import com.oreilly.servlet.MailMessage;

import com.knowgate.sms.SMSPush;

public class SMSPushEMail extends SMSPush {

  private Properties oMailProps;
  
  public void connect(String sHost, String sUser, String sPass, Properties oConnectionProps)
    throws IOException,SQLException,MalformedURLException {
  	oMailProps=oConnectionProps;
  	if (sHost!=null) oMailProps.setProperty("mail.smtp.host", sHost);
  	if (sUser!=null) oMailProps.setProperty("mail.user", sUser);
  	if (sPass!=null) oMailProps.setProperty("mail.password", sPass);
  }

  public SMSResponse push (SMSMessage oSms)
    throws IOException,SQLException,IllegalArgumentException,UnsupportedEncodingException {

	  MailMessage oMail = new MailMessage();
	  oMail.to(oSms.msisdnNumber());
	  oMail.from("noreply@hipergate.org");
	  oMail.setSubject("Hipergate SMS Test");
	  oMail.getPrintStream().print(oSms.textBody());
	  oMail.sendAndClose();
      return new SMSResponse(oSms.subject(), new Date(), SMSResponse.ErrorCode.NONE, SMSResponse.StatusCode.POSITIVE_ACK, null);
  }	
	
  public void close() throws IOException,SQLException { }

}

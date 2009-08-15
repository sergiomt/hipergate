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

import java.util.Date;

public class SMSMessage {

  // --------------------------------------------------------------------------
  
  public enum MType {
    PLAIN_TEXT, WAP_PUSH, OPERATOR_LOGO, RINGTONE
  }

  // --------------------------------------------------------------------------
  
  private String sId;       // Message Unique Id.
  private MType  eMsgType;  // Message Type
  private String sCustCode; // Unique identifier of customer account
  private String sMsisdn;   // A single MSISDN
  private String sSubject;  // Message Subject  
  private String sText;	    // Message Text
  private String sCharSet;  // Character encoding for text
  private Date   dtStamp;   // Date when sent or received
  
  // --------------------------------------------------------------------------
  
  /**
   * Constructor
   * @param eMessageType MType SMS Message Type. It must be SMSMessage.MType.PLAIN_TEXT for standard SMS
   * @param sUniqueId String Unique identifier of message (ony required for incoming message)
   * @param sCustomerAccount String Unique identifier of customer account (for billing)
   * @param sMsisdnRecipient String MSISDN Must be like +34609696969 plus sign and country code are mandatory, plus the digits of the phone number without any space nor other signs. 
   * @param sMessageSubject String Message Subject up to 40 characters
   * @param sMessageText String Up to 160 characters for ISO-8859-1 encoding or less for other encodings
   * @param sCharacterEncoding String Character encoding as defined at http://java.sun.com/j2se/1.5.0/docs/guide/intl/encoding.doc.html
   * @param dtMessageDate Optional Date when sent or received. If this parameter is null then the message will be sent as soon as posible.
   */
  public  SMSMessage(SMSMessage.MType eMessageType,
  					 String sUniqueId, String sCustomerAccount,
  					 String sMsisdnRecipient, String sMessageSubject,
  					 String sMessageText,
  					 String sCharacterEncoding, Date dtMessageDate)
  	throws StringIndexOutOfBoundsException {
  
  	/* Maximum message length check disabled, let each implementation throw an exception or
  	 * split the text over several messages
  	if (SMSMessage.MType.PLAIN_TEXT==eMessageType) {
  	  if (sMessageSubject.length()>40) 
	    throw new StringIndexOutOfBoundsException("Message subject may not exceed 40 characters");
  	  if (sMessageText.length()>160 && 
  	     (sCharacterEncoding.equalsIgnoreCase("ISO8859_1") || sCharacterEncoding.equalsIgnoreCase("ISO-8859-1") ||
  	      sCharacterEncoding.equalsIgnoreCase("ISO8859_5") || sCharacterEncoding.equalsIgnoreCase("ISO-8859-5") ||
  	      sCharacterEncoding.equalsIgnoreCase("ISO8859_7") || sCharacterEncoding.equalsIgnoreCase("ISO-8859-7")))
	    throw new StringIndexOutOfBoundsException("Message body may not exceed 160 characters");
  	  if (sMessageText.length()>70 && 
  	     (sCharacterEncoding.equalsIgnoreCase("Big5") || sCharacterEncoding.equalsIgnoreCase("GB2312")))
	    throw new StringIndexOutOfBoundsException("Message body may not exceed 70 characters");
 	}
    */
    sId = sUniqueId;
    eMsgType = eMessageType;
    sCustCode = sCustomerAccount;
    sMsisdn = sMsisdnRecipient;
    sSubject = sMessageSubject;
    sText = sMessageText;
    sCharSet = sCharacterEncoding;
    dtStamp = dtMessageDate;
  }

  // --------------------------------------------------------------------------

  public String messageId() {
	return sId;
  }

  // --------------------------------------------------------------------------
  
  public SMSMessage.MType mType() {
  	return eMsgType;  	
  }

  // --------------------------------------------------------------------------

  public String customerAccount() {
    return sCustCode;
  }

  // --------------------------------------------------------------------------

  public String msisdnNumber() {
    return sMsisdn;
  }

  // --------------------------------------------------------------------------

  public String subject() {
    return sSubject;
  }

  // --------------------------------------------------------------------------

  public String textBody() {
    return sText;
  }

  // --------------------------------------------------------------------------

  public String textEncoding() {
    return sCharSet;
  }

  // --------------------------------------------------------------------------

  public Date dateStamp() {
    return dtStamp;
  }

} // SMSMessage

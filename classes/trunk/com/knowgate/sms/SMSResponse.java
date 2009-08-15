/*
  Copyright (C) 2008  Know Gate S.L. All rights reserved.
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

package com.knowgate.sms;

import java.util.Date;

public class SMSResponse {

  // --------------------------------------------------------------------------
	
	private String sId;	
	private Date dtStamp;
	private ErrorCode eErrorCode;
	private StatusCode eNotificationStatusCode;
	private String sErrorMessage;

  // --------------------------------------------------------------------------
	
	/**
	 * Constructor for SMS response
	 * @param sMsgId Unique Message Identifier, as returned from SMS carrier
	 * @param dtResponse Date of acknowledgement
	 * @param eErrCode Error Code from enumeration { NONE(0), AUTHENTICATION_FAILURE(1), SERVER_UNAVAILABLE(2), INVALID_MSISDN(4), INVALID_CHARACTER(8), TEXT_TOO_LONG(16), UNKNOWN_ERROR(128) }
	 * @param eNotifyStatusCode from enumeration { POSITIVE_ACK(0),TEMPORARY_ACK(1),TEMPORARY_ACK_WAITING_FOR_HANDSET(2),NEGATIVE_RETRYING_DELIVERY(-1),NEGATIVE_MSISDN_IS_BLACKLISTED(-2),NEGATIVE_CALL_BARRED_BY_OPERATOR(-4),NEGATIVE_FAILED_DELIVERY(-8),NEGATIVE_OUT_OF_CREDIT(-16) }
	 * @param sErrorMsg Additional Error Information
	 */
	public SMSResponse(String sMsgId, Date dtResponse, ErrorCode eErrCode, StatusCode eNotifyStatusCode, String sErrorMsg) {
	  sId = sMsgId;
	  dtStamp = dtResponse;
	  eErrorCode = eErrCode;
	  eNotificationStatusCode = eNotifyStatusCode;
	  sErrorMessage = sErrorMsg;
	}

  // --------------------------------------------------------------------------
	
	public String errorMessage() {
	  return sErrorMessage;
	}

  // --------------------------------------------------------------------------
	
	public String messageId() {
	  return sId;
	}

  // --------------------------------------------------------------------------

	public ErrorCode errorCode() {
	  return eErrorCode;
	}

  // --------------------------------------------------------------------------

	public StatusCode notificationStatusCode() {
	  return eNotificationStatusCode;	  
	}

  // --------------------------------------------------------------------------

    public Date dateStamp() {
      return dtStamp;
    }

  // --------------------------------------------------------------------------

    public String toString() {
      return sId+";"+dtStamp+";"+eErrorCode+";"+eNotificationStatusCode+";"+sErrorMessage;
    }

  // --------------------------------------------------------------------------

    public enum ErrorCode {
	  NONE(0),
	  AUTHENTICATION_FAILURE(1),
	  SERVER_UNAVAILABLE(2),
	  INVALID_MSISDN(4),
	  INVALID_CHARACTER(8),
	  TEXT_TOO_LONG(16),
	  UNKNOWN_ERROR(128);

	  private final int iOrd;

	  ErrorCode(int iOrdinal) { iOrd= iOrdinal; }
	  
 	  public int intValue() {
        return iOrd;
      }

 	  public String toString(){
        return name();
      }

    } // ErrorCode

  // --------------------------------------------------------------------------

    public enum StatusCode {
	  POSITIVE_ACK(0),
	  TEMPORARY_ACK(1),
	  TEMPORARY_ACK_WAITING_FOR_HANDSET(2),
	  NEGATIVE_RETRYING_DELIVERY(-1),
	  NEGATIVE_MSISDN_IS_BLACKLISTED(-2),
	  NEGATIVE_CALL_BARRED_BY_OPERATOR(-4),
	  NEGATIVE_FAILED_DELIVERY(-8),
	  NEGATIVE_OUT_OF_CREDIT(-16);

	  private final int iOrd;

	  StatusCode(int iOrdinal) { iOrd= iOrdinal; }
	  
 	  public int intValue(){
        return iOrd;
      }

 	  public String toString(){
        return name();
      }

    } // StatusCode

} // SMSResponse

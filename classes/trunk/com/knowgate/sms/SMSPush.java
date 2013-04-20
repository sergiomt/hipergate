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

import java.util.Properties;

import java.io.IOException;
import java.io.UnsupportedEncodingException;

import java.sql.SQLException;

import java.net.MalformedURLException;

public abstract class SMSPush {

  /**
   * Conect to SMS HTTP Push Platform
   * @param sUrl String Connection URL
   * @param sUser String User
   * @param sPassword String Password
   * @throws IOException
   * @throws MalformedURLException
   */
  public abstract void connect(String sUrl, String sUser, String sPassword, Properties oConnectionProps)
    throws IOException,SQLException,MalformedURLException;

  /**
   * Close SMS HTTP Push Connection
   */
  public abstract void close() throws IOException,SQLException;
	
  /**
   * Send Plain Text SMS
   * @param SMSMessage oMsg
   * @throws IOException
   * @throws IllegalArgumentException If MSISDN or text are malformed or dtWhenMustBeSend is before now
   * @throws UnsupportedCharacterEncoding If given sCharacterEncoding is not supported
   * @return SMSResponse
   */
  public abstract SMSResponse push (SMSMessage oMsg)
    throws IOException,SQLException,IllegalArgumentException,UnsupportedEncodingException;	

} // SMSPush

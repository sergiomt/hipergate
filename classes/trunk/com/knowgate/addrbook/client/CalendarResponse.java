/*
  Copyright (C) 2010  Know Gate S.L. All rights reserved.

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

package com.knowgate.addrbook.client;

import java.io.IOException;
import java.io.ByteArrayOutputStream;
import java.io.StringBufferInputStream;

import java.net.URL;
import java.net.MalformedURLException;

import java.util.ArrayList;

import javax.activation.DataHandler;

import org.jibx.runtime.IBindingFactory;
import org.jibx.runtime.IUnmarshallingContext;
import org.jibx.runtime.BindingDirectory;
import org.jibx.runtime.JiBXException;

class CalendarResponse {

  public int code;
  public String error = null;
  public String command = null;
  public String value = null;
  public ArrayList<CalendarMeeting> oMeetings;
  public ArrayList<CalendarRoom> oRooms;

  // ----------------------------------------------------------

  /**
   * <p>Read a text file from HHTP into a String</p>
   * @param sFilePath Full URL of file to be readed.
   * @param sEncoding Text Encoding for file {UTF-8, ISO-8859-1, ...}<BR>
   * if <b>null</b> then if first two bytes of file are FF FE then UTF-8 will be assumed<BR> else ISO-8859-1 will be assumed.
   * @return String with full contents of file
   * @throws IOException
   * @throws OutOfMemoryError
   * @throws MalformedURLException
   */
  private static String readfilestr (String sFilePath, String sEncoding)
    throws MalformedURLException, IOException, OutOfMemoryError {

    String sRetVal;

    URL oUrl = new URL(sFilePath);
	  
    ByteArrayOutputStream oStrm = new ByteArrayOutputStream();
    DataHandler oHndlr = new DataHandler(oUrl);
    oHndlr.writeTo(oStrm);
    sRetVal = oStrm.toString(sEncoding);
    oStrm.close();

    return sRetVal;
  } // readfilestr

  // ----------------------------------------------------------

  public static CalendarResponse get(String sUrl)
    throws JiBXException, IOException {
	
	CalendarResponse oCalRsp = null;	

    String sResponse = readfilestr(sUrl,"UTF-8");

	StringBufferInputStream oResponse = new StringBufferInputStream(sResponse);

    IBindingFactory bfact = BindingDirectory.getFactory(CalendarResponse.class);
    IUnmarshallingContext uctx = bfact.createUnmarshallingContext();

    oCalRsp = (CalendarResponse) uctx.unmarshalDocument (oResponse, "UTF-8");

	return oCalRsp;
  } // get

}

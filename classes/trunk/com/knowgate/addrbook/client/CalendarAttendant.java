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

import java.util.SimpleTimeZone;

import org.apache.oro.text.regex.Perl5Matcher;
import org.apache.oro.text.regex.Perl5Compiler;
import org.apache.oro.text.regex.MalformedPatternException;

public class CalendarAttendant {

  private String id;
  private String gu;
  private String email;
  private String name;
  private String surname;
  private String timezone;
  private SimpleTimeZone oZone;

  public String getId() {
  	return id==null ? "" : id;
  }
  
  public void setId(String sId) {
  	if (sId!=null) if (sId.length()>50) 
  	  throw new IllegalArgumentException("Id. may not exceed 50 characters");
  	id = sId;
  }
  
  public String getGuid() {
  	return gu==null ? "" : gu;
  }
  
  public void setGuid(String sGuid)
  	throws IllegalArgumentException {
  	if (sGuid!=null) if (sGuid.length()>32) 
  	  throw new IllegalArgumentException("GUID may not exceed 32 characters");
  	gu = sGuid;
  }

  public String getEmail() {
  	return email;
  }

  public void setEmail(String sAttendantEmail)
  	throws IllegalArgumentException {

    try {
  	if (!new Perl5Matcher().matches(sAttendantEmail, new Perl5Compiler().compile("[\\w\\x2E_-]+@[\\w\\x2E_-]+\\x2E\\D{2,4}",Perl5Compiler.CASE_INSENSITIVE_MASK)))
  	  throw new IllegalArgumentException("Invalid e-mail syntax");
    } catch (MalformedPatternException neverthrown) { }

  	if (sAttendantEmail.length()>100) 
  	  throw new IllegalArgumentException("e-mail may not exceed 100 characters");
  	email = sAttendantEmail;
  }

  public String getName() {
  	return name==null ? "" : name;
  }

  public void setName(String sAttendantName) {
  	if (sAttendantName!=null) if (sAttendantName.length()>100) 
  	  throw new IllegalArgumentException("name may not exceed 100 characters");
  	name = sAttendantName;
  }

  public String getSurname() {
  	return surname==null ? "" : surname;
  }

  public void setSurname(String sAttendantSurname) {
  	if (sAttendantSurname!=null) if (sAttendantSurname.length()>100) 
  	  throw new IllegalArgumentException("surname may not exceed 100 characters");
  	surname = sAttendantSurname;
  }

  public SimpleTimeZone getTimeZone() {
  	if (oZone==null && timezone!=null) setTimeZone(timezone);
  	return oZone;
  }
  
  public void setTimeZone(String sTime) throws NumberFormatException {
  	timezone = sTime;
  	String[] aHourMins = sTime.split(":");
  	oZone = new SimpleTimeZone((sTime.charAt(0)=='+' ? 1 : -1)*(Integer.parseInt(aHourMins[0])*3600000+Integer.parseInt(aHourMins[1])*60000), sTime);
  }

} // CalendarAttendant
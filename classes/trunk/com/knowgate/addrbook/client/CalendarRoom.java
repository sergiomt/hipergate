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

public class CalendarRoom {

  private int active;
  private String name;
  private String rtype;
  private String comments;

  public boolean isActive() {
  	return active!=0;
  }

  public void isActive(boolean bIsActive) {
  	active = bIsActive ? 1 : 0;
  }

  public String getName() {
  	return name==null ? "" : name;
  }
  
  public void setName(String sRoomName) {
  	name = sRoomName;
  }

  public String getType() {
  	return rtype==null ? "" : rtype;
  }
  
  public void setType(String sRoomType) {
  	rtype = sRoomType;
  }

  public String getComments() {
  	return comments==null ? "" : comments;
  }
  
  public void setComments(String sRoomComments) {
  	comments = sRoomComments;
  }
} // CalendarRoom

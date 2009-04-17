/*
  Copyright (C) 2009  Know Gate S.L. All rights reserved.
                      C/Ona, 107 1 2 28050 Madrid (Spain)

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

package com.knowgate.acl;

public class PasswordRecordLine {

  public String ValueId;

  public char ValueType;

  public String ValueLabel;

  public String ValueText;

  public String getId() {
  	return ValueId;
  }
  
  public void setId(String sId) throws NullPointerException {
  	if (sId==null) throw new NullPointerException("PasswordRecordLine Id may not be null");
  	ValueId = sId;
  }

  public String getLabel() {
  	return ValueLabel;
  }

  public void setLabel(String sLabel) {
  	ValueLabel = sLabel;
  }

  public String getValue() {
  	return ValueText;
  }

  public void setValue(char cType, String sText) {
  	switch (cType) {
  	  case PasswordRecordTemplate.TYPE_TEXT:
	  case PasswordRecordTemplate.TYPE_PASS:
	  case PasswordRecordTemplate.TYPE_DATE:
  	    ValueType = cType;
		ValueText = sText;
		break;
	  case PasswordRecordTemplate.TYPE_INT:
  	    ValueType = cType;
		ValueText = sText;
		break;
	  case PasswordRecordTemplate.TYPE_MAIL:
  	    ValueType = cType;
		ValueText = sText;
		break;
	  case PasswordRecordTemplate.TYPE_URL:
  	    ValueType = cType;
		ValueText = sText;
		break;
	  case PasswordRecordTemplate.TYPE_ADDR:
  	    ValueType = cType;
		ValueText = sText;
		break;
	  default:
	  	throw new IllegalArgumentException("PasswordRecordLine.setValue() Invalid type for value");
  	} // end switch
  } // setValue
    
  public String toString() {
  	return ValueId+"|"+ValueType+"|"+ValueLabel+"|"+ValueText;
  }

}

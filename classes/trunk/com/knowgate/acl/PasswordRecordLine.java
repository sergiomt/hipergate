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

import java.io.File;
import java.io.InputStream;
import java.io.FileInputStream;
import java.io.Serializable;
import java.io.IOException;
import java.io.BufferedInputStream;
import java.io.ObjectInputStream;
import java.io.ObjectOutputStream;
import java.io.FileNotFoundException;
import java.io.ByteArrayInputStream;
import java.io.ByteArrayOutputStream;

import com.knowgate.misc.Base64Encoder;
import com.knowgate.misc.Base64Decoder;
import com.knowgate.misc.Gadgets;

public class PasswordRecordLine {

  public String ValueId;

  public char ValueType;

  public String ValueLabel;

  public String ValueFileName;

  public String ValueText;  

  public PasswordRecordLine(String sId, char cType, String sLabel) {
    ValueId = sId;
    ValueType = cType;
    ValueLabel = sLabel;
    ValueFileName = null;
    ValueText = null;
  }

  public PasswordRecordLine(String sId, char cType, String sLabel, String sValue) {
    ValueId = sId;
    ValueType = cType;
    ValueLabel = sLabel;
    ValueFileName = null;
    setValue(cType, sValue);
  }

  public char getType() {
  	return ValueType;
  }

  public void setType(char cType) {
  	ValueType = cType;
  }
  
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

  public String getFileName() {
  	return ValueFileName;
  }

  public void setFileName(String sFileName) {
  	ValueFileName = sFileName;
  }

  public String getValue() {
  	return ValueText;
  }

  public void setValue(char cType, String sText) {
  	switch (cType) {
  	  case TYPE_NAME:
  	  case TYPE_TEXT:
	  case TYPE_PASS:
	  case TYPE_DATE:
  	    ValueType = cType;
		ValueText = sText;
		break;
	  case TYPE_INT:
  	    ValueType = cType;
		ValueText = sText;
		break;
	  case TYPE_MAIL:
  	    ValueType = cType;
		ValueText = sText;
		break;
	  case TYPE_URL:
  	    ValueType = cType;
		ValueText = sText;
		break;
	  case TYPE_ADDR:
  	    ValueType = cType;
		ValueText = sText;
		break;
	  case TYPE_BIN:
  	    ValueType = cType;
		ValueText = sText;
		break;
	  default:
	  	throw new IllegalArgumentException("PasswordRecordLine.setValue() Invalid type for value");
  	} // end switch
  } // setValue

  public byte[] getBinaryValue() {
	int i2ndSlash = ValueText.indexOf('/',1);
  	return Base64Decoder.decodeToBytes(ValueText.substring(++i2ndSlash));
  }

  public Object getObjectValue() throws IOException, ClassNotFoundException {
	ByteArrayInputStream oBai = new ByteArrayInputStream(getBinaryValue());
	ObjectInputStream oOis = new ObjectInputStream(oBai);
	Object oObj = oOis.readObject();
	oOis.close();
	oBai.close();
	return oObj;
  }

  public void setBinaryValue(String sName, byte[] byValue) {
    ValueType = TYPE_BIN;
    ValueFileName = sName;
    ValueText = "/"+sName+"/"+Gadgets.removeChar(Base64Encoder.encode(byValue),'\n');
  }

  public void setBinaryValue(String sName, InputStream oInStrm)
  	throws IOException {
    ValueType = TYPE_BIN;
    ValueFileName = sName;
    ByteArrayOutputStream oBy = new ByteArrayOutputStream();    
    int by = oInStrm.read();
    while (by!=-1) {
      oBy.write(by);      
      by = oInStrm.read();
    } // wend
    ValueText = "/"+sName+"/"+Gadgets.removeChar(Base64Encoder.encode(oBy.toByteArray()),'\n');
  } // setBinaryValue

  public void setBinaryValue(File oFile)
  	throws FileNotFoundException, IOException {
    FileInputStream oFio = new FileInputStream(oFile);
    BufferedInputStream oBio = new BufferedInputStream(oFio);
    setBinaryValue(oFile.getName(), oBio);
    oBio.close();
    oFio.close();
  }

  public void setObjectValue(Serializable oObj)
	throws FileNotFoundException, IOException {
	ByteArrayOutputStream oBos = new ByteArrayOutputStream();
	ObjectOutputStream oOos = new ObjectOutputStream(oBos);
	oOos.writeObject(oObj);	
	setBinaryValue(oObj.getClass().getName(), oBos.toByteArray()); 
	oOos.close();
	oBos.close();
  }
  
  public String toString() {
  	return ValueId+"|"+ValueType+"|"+ValueLabel+"|"+(ValueText==null ? "" : ValueText);
  }

  public static final char TYPE_NAME = '!';
  public static final char TYPE_TEXT = '$';
  public static final char TYPE_DATE = '#';
  public static final char TYPE_PASS = '*';
  public static final char TYPE_INT  = '%';
  public static final char TYPE_MAIL = '@';
  public static final char TYPE_URL  = '&';
  public static final char TYPE_ADDR = '~';
  public static final char TYPE_BIN  = '/';

}

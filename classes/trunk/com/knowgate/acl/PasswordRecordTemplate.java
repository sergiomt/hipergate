/*
  Copyright (C) 2009  Know Gate S.L. All rights reserved.
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

package com.knowgate.acl;

import java.io.IOException;
import java.net.MalformedURLException;

import java.util.ArrayList;

import com.enterprisedt.net.ftp.FTPException;
import com.knowgate.dfs.FileSystem;
import com.knowgate.misc.NameValuePair;

public class PasswordRecordTemplate {

  private ArrayList<NameValuePair> oItems;
  
  public PasswordRecordTemplate() {
    oItems = new ArrayList<NameValuePair>();  
  }

  public int size() {
  	return oItems.size();
  }

  public String getItemId(int nLine) {
  	return oItems.get(nLine).getName();
  }

  public String getItemLabel(int nLine) {
  	return oItems.get(nLine).getValue().substring(1);
  }

  public char getItemType(int nLine) {
  	return oItems.get(nLine).getValue().charAt(0);
  }

  public void parse(String sText) {
  	String[] aLines = sText.split("\n");
	int nLines = aLines.length;
	oItems.clear();    
    for (int n=0; n<nLines; n++) {
	  String sLine = aLines[n].trim();
	  if (sLine.length()>0) {
		String[] aLine = sLine.split("=");
		if (aLine.length>1)
		  oItems.add(new NameValuePair(aLine[0],aLine[1]));
      } // fi
    } // next
  } // parse

  public void load(String sFilePath)
  	throws MalformedURLException, FTPException, IOException {

  	FileSystem oFs = new FileSystem();

  	if (!sFilePath.startsWith("file://") && !sFilePath.startsWith("ftp://") &&
  		!sFilePath.startsWith("ftps://") && !sFilePath.startsWith("https://") &&
  		!sFilePath.startsWith("http://") && !sFilePath.startsWith("file://"))
  	  sFilePath = "file://" + sFilePath;

  	String sTemplate = oFs.readfilestr(sFilePath, "UTF-8");

	oItems.clear();

	if (sTemplate!=null) {
	  if (sTemplate.length()>0) {
	    parse(sTemplate);
	  }
	} // fi
  } // load

  public void store(String sFilePath)
  	throws MalformedURLException, FTPException, IOException {

    StringBuffer oTemplate = new StringBuffer();
	for (NameValuePair oNvp : oItems) {
	  oTemplate.append(oNvp.getName()+"="+oNvp.getValue()+"\n");
	} // next

  	if (!sFilePath.startsWith("file://") && !sFilePath.startsWith("ftp://") &&
  		!sFilePath.startsWith("ftps://") && !sFilePath.startsWith("https://") &&
  		!sFilePath.startsWith("http://") && !sFilePath.startsWith("file://"))
  	  sFilePath = "file://" + sFilePath;

  	FileSystem oFs = new FileSystem();

	oFs.writefilestr(sFilePath, oTemplate.toString(), "UTF-8");
	
  } // store

  public static final char TYPE_TEXT = '$';
  public static final char TYPE_DATE = '#';
  public static final char TYPE_PASS = '*';
  public static final char TYPE_INT = '%';
  public static final char TYPE_MAIL = '@';
  public static final char TYPE_URL = '&';
  public static final char TYPE_ADDR = '~';
  	
}

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
import java.io.FileNotFoundException;
import java.net.MalformedURLException;

import java.util.ArrayList;

import com.enterprisedt.net.ftp.FTPException;
import com.knowgate.dfs.FileSystem;
import com.knowgate.debug.DebugFile;
import com.knowgate.misc.Gadgets;

/**
 * <p>Password Record Template</p>
 * A password record template is a plain text file which contains one line for each password record field.<br/>
 * Each field line has three columns delimited by a vertical pipe: id|type|label<br/>
 * The id column is the internal name for the field.<br/>
 * The type column is a single character that can have one of the following values:<br/>
 * <table summary="Password field types">
 * <tr><td>!</td><td>Type Name</td></tr>
 * <tr><td>$</td><td>Type Text</td></tr>
 * <tr><td>#</td><td>Type Date</td></tr>
 * <tr><td>*</td><td>Type Password</td></tr>
 * <tr><td>%</td><td>Type Integer</td></tr>
 * <tr><td>@</td><td>Type e-Mail</td></tr>
 * <tr><td>&</td><td>Type URL</td></tr>
 * <tr><td>~</td><td>Type Postal Address</td></tr>
 * <tr><td>/</td><td>Type Binary</td></tr>
 * </table>
 */
public class PasswordRecordTemplate {

  private PasswordRecord oMasterRecord;
  private String sName;
  
  public PasswordRecordTemplate() {
    oMasterRecord = new PasswordRecord();
    sName = "";
  }

  public String getName() {
    return sName;
  }

  public char getTypeOf(String sLineId) {
    for (PasswordRecordLine l : lines()) {
      if (l.getId().equals(sLineId)) {
      	return l.getType(); 
      } // fi
    } // next
    return 0;
  } // getTypeOf

  /**
   * Create a new password record for this template
   */
  public PasswordRecord createRecord() {
    PasswordRecord oNewRec = new PasswordRecord();
    for (PasswordRecordLine l : oMasterRecord.lines()) {
      oNewRec.lines().add(new PasswordRecordLine(l.getId(), l.getType(), l.getLabel()));
    } // next
    return oNewRec;
  }

  public ArrayList<PasswordRecordLine> lines() {
    return oMasterRecord.lines();
  }

  /**
   * Parse template from string
   */
  public void parse(String sText) throws NullPointerException {

	if (null==sText) throw new NullPointerException("PasswordRecordTemplate.parse() Input text to be parsed is null");
	
  	if (DebugFile.trace) {
  	  if (sText.indexOf('\n')>0)
  	    DebugFile.writeln("Begin PasswordRecordTemplate.parse("+Gadgets.substrUpTo(sText,0,'\n')+")");
	  else
  	    DebugFile.writeln("Begin PasswordRecordTemplate.parse("+sText+")");
  	  DebugFile.incIdent();
  	}
  	
  	String[] aLines = sText.split("\n");
	int nLines = aLines.length;
	oMasterRecord.lines().clear();      
    sName = Gadgets.removeChars(aLines[0].trim(),"\r");
    for (int n=1; n<nLines; n++) {
	  String sLine = Gadgets.removeChars(aLines[n].trim(),"\r");
	  if (sLine.length()>0) {
        if (DebugFile.trace) DebugFile.writeln("Parsing line "+String.valueOf(n)+" "+sLine);
		String[] aLine = Gadgets.split(sLine,'|');
		if (aLine.length>1) {
		  lines().add(new PasswordRecordLine(aLine[0],aLine[1].charAt(0),aLine[2]));
		} // fi		  
      } // fi
    } // next

  	if (DebugFile.trace) {
  	  DebugFile.decIdent();
  	  DebugFile.writeln("End PasswordRecordTemplate.parse() " + String.valueOf(oMasterRecord.lines().size()));
  	}

  } // parse

  /**
   * Load template from UTF-8 text file
   * @param File Path including protocol, for example: file:///tmp/template1.txt
   * @throws MalformedURLException
   * @throws FTPException
   * @throws IOException
   */
  public void load(String sFilePath)
  	throws MalformedURLException, FTPException, FileNotFoundException, IOException {

  	if (DebugFile.trace) {
  	  DebugFile.writeln("Begin PasswordRecordTemplate.load("+sFilePath+")");
  	  DebugFile.incIdent();
  	}

  	FileSystem oFs = new FileSystem();
  	if (!sFilePath.startsWith("file://") && !sFilePath.startsWith("ftp://") &&
  		!sFilePath.startsWith("ftps://") && !sFilePath.startsWith("https://") &&
  		!sFilePath.startsWith("http://") && !sFilePath.startsWith("file://"))
  	  sFilePath = "file://" + sFilePath;

	if (!oFs.exists(sFilePath)) {
  	  if (DebugFile.trace) {
  	    DebugFile.writeln("FileNotFoundException: PasswordRecordTemplate.load() "+sFilePath);
  	    DebugFile.decIdent();
  	  }
  	  throw new FileNotFoundException("PasswordRecordTemplate.load() "+sFilePath);
	}

  	String sTemplate = oFs.readfilestr(sFilePath, "UTF-8");

	oMasterRecord.lines().clear();

	if (sTemplate!=null) {
	  if (sTemplate.length()>0) {
	    parse(sTemplate);
	  }
	} // fi

  	if (DebugFile.trace) {
  	  DebugFile.decIdent();
  	  DebugFile.writeln("End PasswordRecordTemplate.load()");
  	}

  } // load

  /**
   * Store template into a text file encoded in UTF-8 character set
   * @param File Path including protocol, for example: file:///tmp/template1.txt
   * @throws MalformedURLException
   * @throws FTPException
   * @throws IOException
   */
  public void store(String sFilePath)
  	throws MalformedURLException, FTPException, IOException {

    StringBuffer oTemplate = new StringBuffer(4000);

	for (PasswordRecordLine oLin : oMasterRecord.lines()) {
	  if (oTemplate.length()>0) oTemplate.append("\n");
	  oTemplate.append(oLin.getId());
	  oTemplate.append('|');
	  oTemplate.append(oLin.getType());
	  oTemplate.append('|');
	  oTemplate.append(oLin.getLabel());
	} // next

  	if (!sFilePath.startsWith("file://") && !sFilePath.startsWith("ftp://") &&
  		!sFilePath.startsWith("ftps://") && !sFilePath.startsWith("https://") &&
  		!sFilePath.startsWith("http://") && !sFilePath.startsWith("file://"))
  	  sFilePath = "file://" + sFilePath;

  	FileSystem oFs = new FileSystem();

	oFs.writefilestr(sFilePath, oTemplate.toString(), "UTF-8");
	
  } // store

    	
}

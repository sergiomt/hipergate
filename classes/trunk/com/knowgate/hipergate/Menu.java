/*
  Copyright (C) 2003-2005  Know Gate S.L. All rights reserved.
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

package com.knowgate.hipergate;

import java.util.ArrayList;
import java.util.Iterator;

import java.io.IOException;
import java.io.FileNotFoundException;
import java.io.UnsupportedEncodingException;
import java.io.FileInputStream;
import java.io.BufferedInputStream;

import org.jibx.runtime.IBindingFactory;
import org.jibx.runtime.IUnmarshallingContext;
import org.jibx.runtime.BindingDirectory;
import org.jibx.runtime.JiBXException;

import com.knowgate.debug.DebugFile;

/**
 * <p>hipergate top menu definition JiBX handler</p>
 * This class needs to be processed with JiBX after being compiled.
 * If you get the error org.jibx.runtime.JiBXException:
 * Unable to access binding information for class com.knowgate.hipergate.Menu
 * whilst trying to execute hipergate then
 * execute from the command line:
 * C:\JRE\bin\java -cp C:\JAR\bcel.jar;C:\JAR\jibx-1beta3.jar;C:\JAR\jibx-extras.jar;C:\JAR\xpp3.jar org.jibx.binding.Compile C:\knowgate\storage\xslt\schemas\menu-def-jixb.xml
 * @author Sergio Montoro Ten
 * @version 1.0
 */
public class Menu {
  private ArrayList options;

  // ---------------------------------------------------------------------------

  /**
   * Default constructor
   */
  public Menu() {
    options = new ArrayList();
  }

  // ---------------------------------------------------------------------------

  /**
   * Number of top level options
   * @return int
   */
  public int countSubOptions() {
    return options.size();
  }

  // ---------------------------------------------------------------------------

  /**
   * Number of top level options that have access set to <b>true</b>
   * @return int
   */
  public int countAccesibleSubOptions() {
	int nActive = 0;
	Iterator iter = options.iterator();
	while (iter.hasNext()) {
	  MenuOption opt = (MenuOption) iter.next();
	  if (opt.getAccess()) nActive++;
	} // wend
	return nActive;
  }

  // ---------------------------------------------------------------------------

  /**
   * Get option by index
   * @param nIndex int Option Index
   * @return MenuOption
   * @throws ArrayIndexOutOfBoundsException if n<0 or n>=countSubOptions()
   */
  public MenuOption getOption(int nIndex)
    throws ArrayIndexOutOfBoundsException {
    return (MenuOption) options.get(nIndex);
  }

  // ---------------------------------------------------------------------------

  /**
   * <p>Get option by index</p>
   * Perform linear search on top level options
   * @param sName String Option name
   * @return MenuOption
   * @throws ArrayIndexOutOfBoundsException if no option with such name was found
   */
  public MenuOption getOption(String sName)
    throws ArrayIndexOutOfBoundsException {
    final int nOptCount = countSubOptions();
    for (int o=0;o<nOptCount;o++) {
      if (((MenuOption)options.get(o)).getName().equalsIgnoreCase(sName))
        return (MenuOption) options.get(o);
    } // next
    throw new ArrayIndexOutOfBoundsException(sName + " menu option not found");
  } // getOption

  // ---------------------------------------------------------------------------

  public boolean getAccess(int nOption) {
  	if (nOption<0 || nOption>=options.size())
  	  return false;
  	else
      return ((MenuOption) options.get(nOption)).getAccess();
  }

  // ---------------------------------------------------------------------------

  public boolean getSelected(int nOption) {
  	if (nOption<0 || nOption>=options.size())
  	  return false;
  	else
      return ((MenuOption) options.get(nOption)).getSelected();
  }

  // ---------------------------------------------------------------------------

  /**
   * <p>Determine access to evey menu option for an application mask</p>
   * Get whether or not a user with the given application mask and roles can
   * access each menu option. Application Masks are 32 bit integers with one
   * bit flags per application.
   * This method calls setAccess(hasAccess(iAppMask, bAdmin, bOwner)) for
   * each menu option thus setting the access flag for all of them
   * @param iAppMask int Application mask
   * @param bAdmin boolean <b>true</b> if user has administrator role
   * @param bOwner boolean <b>true</b> if user is owner of his WorkArea
   * @since 4.0
   */
  public void setAccessFor (int iAppMask, boolean bAdmin, boolean bOwner) {
	Iterator iter = options.iterator();
	while (iter.hasNext()) {
	  MenuOption opt = (MenuOption) iter.next();
	  opt.setAccess(opt.hasAccess(iAppMask, bAdmin, bOwner));
	} // wend
  } // setAccessFor

  // ---------------------------------------------------------------------------

  public String toXML() {
    StringBuffer oXML = new StringBuffer(16000);
    oXML.append("<?xml version=\"1.0\" encoding=\"UTF-8\"?>\n<menu>\n<options count=\""+String.valueOf(options.size())+"\">\n");
	Iterator iter = options.iterator();
	while (iter.hasNext()) {
	  MenuOption opt = (MenuOption) iter.next();
      oXML.append(opt.toXML());
      oXML.append("\n");
	} // wend
    oXML.append("</options>\n</menu>");
    return oXML.toString();
  } // toXML
  
  // ---------------------------------------------------------------------------

  /**
   * Create a Menu object by parsing its definition from an XML file
   * @param sXMLDocPath String Full path to menu XML definition file
   * @param sEnc String Character encoding, if <b>null</b> then UTF-8 is assumed.
   * @return Menu object
   * @throws JiBXException
   * @throws FileNotFoundException
   * @throws UnsupportedEncodingException
   * @throws IOException
   */
  public static Menu parse(String sXMLDocPath, String sEnc)
    throws JiBXException, FileNotFoundException, UnsupportedEncodingException,
           IOException {

    if (DebugFile.trace) {
      DebugFile.writeln("Begin Menu.parse("+sXMLDocPath+","+sEnc+")");
      DebugFile.incIdent();
    }

    if (sEnc==null) sEnc="UTF-8";

    IBindingFactory bfact = BindingDirectory.getFactory(Menu.class);
    IUnmarshallingContext uctx = bfact.createUnmarshallingContext();

    final int BUFFER_SIZE = 28000;
    FileInputStream oFileStream = new FileInputStream(sXMLDocPath);
    BufferedInputStream oXMLStream = new BufferedInputStream(oFileStream, BUFFER_SIZE);

    Object obj = uctx.unmarshalDocument (oXMLStream, sEnc);

    oXMLStream.close();
    oFileStream.close();

    if (DebugFile.trace) {
      DebugFile.decIdent();
      DebugFile.writeln("End Menu.parse()");
    }

    return (Menu) obj;
  } // parse

}

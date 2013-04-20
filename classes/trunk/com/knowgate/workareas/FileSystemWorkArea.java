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

package com.knowgate.workareas;

import java.lang.Exception;
import java.util.Properties;
import java.io.IOException;

import com.knowgate.debug.DebugFile;
import com.knowgate.dfs.FileSystem;

import com.enterprisedt.net.ftp.FTPException;

public class FileSystemWorkArea extends FileSystem {
  private Properties oPropsCNF;

  @SuppressWarnings("unused")
  private FileSystemWorkArea() { oPropsCNF= null; }

  @SuppressWarnings("unused")
  private FileSystemWorkArea(String sUser, String sPwd) { oPropsCNF= null; }

  public FileSystemWorkArea(Properties oEnvProps) {
    super(oEnvProps);
    oPropsCNF = oEnvProps;
  }

  // ---------------------------------------------------------------------------

  /**
   * Read text file under workarea root directory
   * @param sWorkArea WorkArea GUID
   * @param sPath Relative path to file under workarea root directory at /web branch including file name. For example "apps/Shop/change.log"
   * @param sEncoding Encoding to be used
   * see <a href="http://java.sun.com/j2se/1.4.2/docs/guide/intl/encoding.doc.html">Java Supported Encodings</a>
   * @throws IllegalArgumentException if sWorkArea or sPath is null
   * @throws IOException
   * @throws OutOfMemoryError
   * @since 4.0
   */
  
  public String readworkfilestr (String sWorkArea, String sPath, String sEncoding)
  	throws IllegalArgumentException, IOException, OutOfMemoryError {

    if (sWorkArea==null)
      throw new IllegalArgumentException("WorkArea GUID may not be null");

    if (sPath==null)
      throw new IllegalArgumentException("File path may not be null");

    String sWorkAreaPath = oPropsCNF.getProperty("workareasput");
    if (!sWorkAreaPath.endsWith(SLASH)) sWorkAreaPath += SLASH;
  	
  	String sRetVal;
  	try {
  	  sRetVal = readfilestr("file://" + sWorkAreaPath + sWorkArea + sPath, sEncoding);
  	} catch (FTPException neverthrown) {
  	  sRetVal = null;
  	}
  	return sRetVal;
  } // readworkfilestr

  // ---------------------------------------------------------------------------

  /**
   * Write a String to a text file under workarea root directory using given encoding
   * @param sWorkArea WorkArea GUID
   * @param sPath Relative path to file under workarea root directory at /web branch including file name. For example "apps/Shop/change.log"
   * @param sText String to be written
   * @param sEncoding Encoding to be used
   * see <a href="http://java.sun.com/j2se/1.4.2/docs/guide/intl/encoding.doc.html">Java Supported Encodings</a>
   * @throws IllegalArgumentException if sWorkArea or sPath is null
   * @throws IOException
   * @throws OutOfMemoryError
   * @since 4.0
   */
  
  public void writeworkfilestr (String sWorkArea, String sPath, String sText, String sEncoding)
  	throws IllegalArgumentException, IOException, OutOfMemoryError {

    if (sWorkArea==null)
      throw new IllegalArgumentException("WorkArea GUID may not be null");

    if (sPath==null)
      throw new IllegalArgumentException("File path may not be null");

    String sWorkAreaPath = oPropsCNF.getProperty("workareasput");
    if (!sWorkAreaPath.endsWith(SLASH)) sWorkAreaPath += SLASH;

    writefilestr("file://" + sWorkAreaPath + sWorkArea + sPath, sText, sEncoding);
  } // writeworkfilestr

  // ---------------------------------------------------------------------------

  /** 
   * Read text file under storage root directory using given encoding
   * @param sPath Relative path to file under storage root directory including file name. For example "cache/recent.html"
   * @param sEncoding Encoding to be used
   * see <a href="http://java.sun.com/j2se/1.4.2/docs/guide/intl/encoding.doc.html">Java Supported Encodings</a>
   * @throws IllegalArgumentException if sWorkArea or sPath is null
   * @throws IOException
   * @throws OutOfMemoryError
   * @since 6.0
   */
  
  public String readstorfilestr (String sPath, String sEncoding)
  	throws IllegalArgumentException, IOException, FTPException, OutOfMemoryError {

    if (sPath==null)
      throw new IllegalArgumentException("File path may not be null");

    String sProtocol = oPropsCNF.getProperty("protocol", "file://");
    String sWorkAreaPath = oPropsCNF.getProperty("storage");

    if (sProtocol.equalsIgnoreCase("ftp://")) {
      if (!sWorkAreaPath.endsWith("/")) sWorkAreaPath += "/";
    } else {
      if (!sWorkAreaPath.endsWith(SLASH)) sWorkAreaPath += SLASH;
    }
    
    return readfilestr(sProtocol + sWorkAreaPath + sPath, sEncoding);
  } // readstorfilestr

  // ---------------------------------------------------------------------------

  /** 
   * Read text file under storage root directory using given encoding
   * @param iDomain Domain Numeric Identifier
   * @param sWorkArea WorkArea GUID
   * @param sPath Relative path to file under storage root directory including file name. For example "cache/recent.html"
   * @param sEncoding Encoding to be used
   * see <a href="http://java.sun.com/j2se/1.4.2/docs/guide/intl/encoding.doc.html">Java Supported Encodings</a>
   * @throws IllegalArgumentException if sWorkArea or sPath is null
   * @throws IOException
   * @throws OutOfMemoryError
   * @since 4.0
   */
  
  public String readstorfilestr (int iDomain, String sWorkArea, String sPath, String sEncoding)
  	throws IllegalArgumentException, IOException, FTPException, OutOfMemoryError {

    if (sWorkArea==null)
      throw new IllegalArgumentException("WorkArea GUID may not be null");

    if (sPath==null)
      throw new IllegalArgumentException("File path may not be null");

    String sProtocol = oPropsCNF.getProperty("protocol", "file://");
    String sWorkAreaPath = oPropsCNF.getProperty("storage");

    if (sProtocol.equalsIgnoreCase("ftp://")) {
      if (!sWorkAreaPath.endsWith("/")) sWorkAreaPath += "/";
      sWorkAreaPath += "domains/" + String.valueOf(iDomain) + "/workareas/"+sWorkArea;
      if (sPath.startsWith("/")) sWorkAreaPath += sPath; else sWorkAreaPath += "/" + sPath;
    } else {
      if (!sWorkAreaPath.endsWith(SLASH)) sWorkAreaPath += SLASH;
      sWorkAreaPath += "domains" + SLASH + String.valueOf(iDomain) + SLASH + "workareas" + SLASH + sWorkArea;
      if (sPath.startsWith(SLASH)) sWorkAreaPath += sPath; else sWorkAreaPath += SLASH + sPath;
    }
    
    return readfilestr(sProtocol + sWorkAreaPath, sEncoding);
  } // readstorfilestr

  // ---------------------------------------------------------------------------

  /** 
   * Write a String to a text file under storage root directory using given encoding
   * @param iDomain Domain Numeric Identifier
   * @param sWorkArea WorkArea GUID
   * @param sPath Relative path to file under storage root directory including file name. For example "cache/recent.html"
   * @param sText String to be written
   * @param sEncoding Encoding to be used
   * see <a href="http://java.sun.com/j2se/1.4.2/docs/guide/intl/encoding.doc.html">Java Supported Encodings</a>
   * @throws IllegalArgumentException if sWorkArea or sPath is null
   * @throws IOException
   * @throws OutOfMemoryError
   * @since 4.0
   */
  
  public void writestorfilestr (int iDomain, String sWorkArea, String sPath, String sText, String sEncoding)
  	throws IllegalArgumentException, IOException, FTPException, OutOfMemoryError {

    if (sWorkArea==null)
      throw new IllegalArgumentException("WorkArea GUID may not be null");

    if (sPath==null)
      throw new IllegalArgumentException("File path may not be null");

    String sProtocol = oPropsCNF.getProperty("protocol", "file://");
    String sWorkAreaPath = oPropsCNF.getProperty("storage");

    if (sProtocol.equalsIgnoreCase("ftp://")) {
      if (!sWorkAreaPath.endsWith("/")) sWorkAreaPath += "/";
      sWorkAreaPath += "domains/" + String.valueOf(iDomain) + "/workareas/";
    } else {
      if (!sWorkAreaPath.endsWith(SLASH)) sWorkAreaPath += SLASH;
      sWorkAreaPath += "domains" + SLASH + String.valueOf(iDomain) + SLASH + "workareas" + SLASH;
    }
    
    writefilestr(sProtocol + sWorkAreaPath + sWorkArea + sPath, sText, sEncoding);
  } // writestorfilestr

  // ---------------------------------------------------------------------------

  /**
   * <p>Create a complete directory branch under workarea root directory at /web branch</p>
   * The given path is appended to "file://" + <i>workareasput</i> + <i>sWorkArea<</i>
   * and the full resulting path is created if it does not exist.
   * @param oProps Properties collection containing <i>workareasput</i> property
   * (typically readed from file hipergate.cnf)
   * @param sWorkArea WorkArea GUID
   * @param sPath Relative path to be created under workarea root directory
   * @throws IOException
   * @throws IllegalArgumentException If sWorkArea is <b>null</b>
   */

  private boolean mkworkpath (Properties oProps, String sWorkArea, String sPath)
    throws IOException,IllegalArgumentException {
    boolean bRetVal = false;

    if (DebugFile.trace) {
      DebugFile.writeln("Begin FileSystemWorkArea.mkworkpath(" + sPath + ")");
      DebugFile.incIdent();
    }

    if (sWorkArea==null)
      throw new IllegalArgumentException ("WorkArea GUID may not be null");

    String sWorkAreaPath = oProps.getProperty("workareasput");
    if (!sWorkAreaPath.endsWith(SLASH)) sWorkAreaPath += SLASH;

    try {
      if (null==sPath)
        bRetVal = mkdirs("file://" + sWorkAreaPath + sWorkArea);
      else
        bRetVal = mkdirs("file://" + sWorkAreaPath +  sWorkArea + SLASH + sPath);
    }
    catch (IOException ioe) { throw new IOException (ioe.getMessage()); }
    catch (Exception e) { /* never thrown */ }

    if (DebugFile.trace) {
      DebugFile.decIdent();
      DebugFile.writeln("End FileSystemWorkArea.mkworkpath() : " + String.valueOf(bRetVal));
    }

    return bRetVal;
  } // mkworkpath

  // ---------------------------------------------------------------------------

  /**
   * <p>Create workarea root directory at /web branch</p>
   * @param oProps Properties collection containing <i>workareasput</i> property
   * @param sWorkArea WorkArea GUID
   * @throws IllegalArgumentException If sWorkArea is <b>null</b>
   */
  private boolean mkworkpath (Properties oProps, String sWorkArea)
    throws IOException,IllegalArgumentException {

    return mkworkpath(oProps, sWorkArea, null);
  }

  // ---------------------------------------------------------------------------

  /**
   * <p>Create a complete directory branch under workarea root directory.</p>
   * The given path is appended to "file://" + workareasput + <i>sWorkArea</i>
   * and the full resulting path is created if it does not exist.
   * @param sWorkArea WorkArea GUID
   * @param sPath Relative path to be created under workareas root directory
   * @throws IOException
   * @throws IllegalArgumentException If sWorkArea is <b>null</b>
   */
  public boolean mkworkpath (String sWorkArea, String sPath) throws Exception,IOException {
    return mkworkpath(oPropsCNF, sWorkArea, sPath);
  }

  // ---------------------------------------------------------------------------

  /**
   * <p>Create workarea root directory at /web branch</p>
   * @param oProps Properties collection containing <i>workareasput</i> property
   * @param sWorkArea WorkArea GUID
   * @throws IllegalArgumentException If sWorkArea is <b>null</b>
   */
  public boolean mkworkpath (String sWorkArea)
    throws IOException,IllegalArgumentException {

    return mkworkpath(oPropsCNF, sWorkArea, null);
  }

  // ---------------------------------------------------------------------------

  /**
   * <p>Delete a directory and all its subdirectories and files
   * under workarea root directory at /web branch.</p>
   * The given path is appended to "file://" + <i>workareasput</i> + <i>sWorkArea</i>,
   * the resulting directory and all its childs are deleted.
   * @param oProps Properties collection containing workareasput property
   * @param sWorkArea WorkArea GUID
   * @param sPath Relative path to be created under workareas root directory
   * @throws IOException
   * @throws IllegalArgumentException If sWorkArea is <b>null</b>
   * @throws NullPointerException if "workareasput" property is not found at oProps Properties
   */

  private boolean rmworkpath (Properties oProps, String sWorkArea, String sPath)
      throws IOException,IllegalArgumentException,NullPointerException {
    boolean bRetVal = false;

    if (DebugFile.trace) {
      DebugFile.writeln("Begin FileSystemWorkArea.rmworkpath(" + sPath + ")");
      DebugFile.incIdent();
    }

    String sWorkAreaPath = oProps.getProperty("workareasput");

    if (sWorkAreaPath==null) {
      throw new NullPointerException("Cannot find property workareasput at configuration file");
    }
    else {
      if (sPath == null) {
        bRetVal = rmdir ("file://" + sWorkAreaPath);
      }
      else {
        if (!sWorkAreaPath.endsWith(SLASH) && !sPath.startsWith(SLASH)) sWorkAreaPath += SLASH;
        bRetVal = rmdir ("file://" + sWorkAreaPath + sPath);
      }
    }

    if (DebugFile.trace) {
      DebugFile.decIdent();
      DebugFile.writeln("End FileSystemWorkArea.rmworkpath() : " + String.valueOf(bRetVal));
    }

    return bRetVal;
  } // rmworkpath

  // ---------------------------------------------------------------------------

  /**
   * <p>Delete a directory and all its subdirectories and files
   * under workarea root directory at /web branch.</p>
   * The given path is appended to "file://" + <i>workareasput</i> + <i>sWorkArea</i>,
   * the resulting directory and all its childs are deleted.
   * @param sWorkArea WorkArea GUID
   * @param sPath Relative path to be created under workareas root directory
   * @throws IOException
   * @throws IllegalArgumentException If sWorkArea is <b>null</b>
   */

  public boolean rmworkpath (String sWorkArea, String sPath)
    throws IOException,IllegalArgumentException {
    return rmworkpath(oPropsCNF, sWorkArea, sPath);
  }

  // ---------------------------------------------------------------------------

  /**
   * <p>Delete workarea root directory at /web branch.</p>
   * The given path is appended to "file://" + <i>workareasput</i> + ,
   * the resulting directory and all its childs are deleted.
   * @param sWorkArea WorkArea GUID
   * @throws IOException
   * @throws IllegalArgumentException If sWorkArea is <b>null</b>
   */

  public boolean rmworkpath (String sWorkArea)
    throws IOException,IllegalArgumentException {
    return rmworkpath(oPropsCNF, sWorkArea, null);
  }

  // ---------------------------------------------------------------------------

  /**
   * <p>Get base path for storage at given domain and work area</p>
   * /$<i>storage</i>$/domains/<i>iDomain</i>/workareas/<i>sWorkArea</i>/
   * @param oProps Properties collection containing storage property
   * (typically readed from file hipergate.cnf)
   * @param iDomain Domain Numeric Identifier
   * @param sWorkArea WorkArea GUID
   * @throws IllegalArgumentException If sWorkArea is <b>null</b>
   * @since 6.0
   */
  public String getstorpath (Properties oProps, int iDomain, String sWorkArea)
  	throws IllegalArgumentException {

    if (sWorkArea==null)
      throw new IllegalArgumentException("WorkArea GUID may not be null");

    String sProtocol = oProps.getProperty("protocol", "file://");
    String sWorkAreaPath = oProps.getProperty("storage");

    if (sProtocol.equalsIgnoreCase("ftp://")) {
      if (!sWorkAreaPath.endsWith("/")) sWorkAreaPath += "/";
      sWorkAreaPath += "domains/" + String.valueOf(iDomain) + "/workareas/" + sWorkArea;
    } else {
      if (!sWorkAreaPath.endsWith(SLASH)) sWorkAreaPath += SLASH;

      sWorkAreaPath += "domains" + SLASH + String.valueOf(iDomain) + SLASH + "workareas" + SLASH + sWorkArea;
   } // fi (sProtocol)
   
   return sWorkAreaPath;
  } // getstorpath

  // ---------------------------------------------------------------------------

  /**
   * <p>Create a complete directory branch under storage root directory</p>
   * The given path is appended to storage/domains/<i>iDomain</i>/workareas/<i>sWorkArea</i>/
   * and the full resulting path is created if it does not exist.
   * @param oProps Properties collection containing storage property
   * (typically readed from file hipergate.cnf)
   * @param iDomain Domain Numeric Identifier
   * @param sWorkArea WorkArea GUID
   * @param sPath Relative path to be created under workarea directory. For example:
   * "ROOT/DOMAINS/TEST1/TEST1_USERS/TEST1_administrator/TEST1_administrator_temp"
   * If sPath is <b>null</b> hen the workarea root directory itself will be created.
   * @throws IOException
   * @throws IllegalArgumentException If sWorkArea is <b>null</b>
   */

  private boolean mkstorpath (Properties oProps, int iDomain, String sWorkArea, String sPath)
    throws Exception,IOException,IllegalArgumentException {
    boolean bRetVal = false;

    if (DebugFile.trace) {
      DebugFile.writeln("Begin FileSystemWorkArea.mkstorpath([Properties]," + String.valueOf(iDomain) + "," + sWorkArea + "," + sPath + ")");
      DebugFile.incIdent();
    }

    String sProtocol = oProps.getProperty("protocol", "file://");
    String sWorkAreaPath = getstorpath(oProps, iDomain, sWorkArea);

    if (sProtocol.equalsIgnoreCase("ftp://")) {
      if (null==sPath)
        bRetVal = mkdirs(sProtocol + oProps.getProperty("protocol", "localhost") + "/" + sWorkAreaPath);
      else
        bRetVal = mkdirs(sProtocol + oProps.getProperty("protocol", "localhost") + "/" + sWorkAreaPath + (sPath.startsWith("/") ? sPath : "/" + sPath));
    }
   else {
      if (null==sPath)
        bRetVal = mkdirs(sProtocol + sWorkAreaPath);
      else
        bRetVal = mkdirs(sProtocol + sWorkAreaPath + (sPath.startsWith(SLASH) ? sPath : SLASH+sPath));
   } // fi (sProtocol)

    if (DebugFile.trace) {
      DebugFile.decIdent();
      DebugFile.writeln("End FileSystemWorkArea.mkstorpath() : " + String.valueOf(bRetVal));
    }

    return bRetVal;
  } // mkworkpath

  // ---------------------------------------------------------------------------

  /**
   * <p>Create a complete directory branch under storage root directory</p>
   * The given path is appended to storage/domains/<i>iDomain</i>/workareas/<i>sWorkArea</i>/
   * and the full resulting path is created if it does not exist.
   * @param iDomain Domain Numeric Identifier
   * @param sWorkArea WorkArea GUID
   * @param sPath Relative path to be created under workarea directory. For example:
   * "ROOT/DOMAINS/TEST1/TEST1_USERS/TEST1_administrator/TEST1_administrator_temp"
   * If sPath is <b>null</b> hen the workarea root directory itself will be created.
   * @throws IOException
   * @throws IllegalArgumentException If sWorkArea is <b>null</b>
   */
  public boolean mkstorpath (int iDomain, String sWorkArea, String sPath) throws Exception,IOException {
    return mkstorpath(oPropsCNF, iDomain, sWorkArea, sPath);
  }

  /**
   * <p>Remove workarea files under /storage branch</p>
   * @param oProps Properties collection containing storage property
   * @param iDomain Domain Numeric Identifier
   * @param sWorkArea WorkArea GUID
   * @param sPath Relative path from workarea subdirectory to delete.
   * @throws Exception
   * @throws IOException
   */
  private boolean rmstorpath (Properties oProps, int iDomain, String sWorkArea, String sPath) throws Exception,IOException {
    boolean bRetVal = false;

    if (DebugFile.trace) {
      DebugFile.writeln("Begin FileSystemWorkArea.rmstorpath (" + String.valueOf(iDomain) + "," + sWorkArea + "," + (sPath==null ? "null" : sPath) + ")");
      DebugFile.incIdent();
    }

    String sProtocol = oProps.getProperty("protocol", "file://");
    String sWorkAreaPath = oProps.getProperty("storage");

    if (sProtocol.equalsIgnoreCase("ftp://")) {
      if (!sWorkAreaPath.endsWith("/")) sWorkAreaPath += "/";
      sWorkAreaPath += "domains/" + String.valueOf(iDomain) + "/workareas/" + sWorkArea;

      if (null==sPath)
        bRetVal = rmdir(sProtocol + oProps.getProperty("protocol", "localhost") + "/" + sWorkAreaPath);
      else
        bRetVal = rmdir(sProtocol + oProps.getProperty("protocol", "localhost") + "/" + sWorkAreaPath + (sPath.startsWith("/") ? sPath : "/" + sPath));
    }
   else {
      if (!sWorkAreaPath.endsWith(SLASH)) sWorkAreaPath += SLASH;

      sWorkAreaPath += "domains" + SLASH + String.valueOf(iDomain) + SLASH + "workareas" + SLASH + sWorkArea;

      if (null==sPath)
        bRetVal = rmdir(sProtocol + sWorkAreaPath);
      else
        bRetVal = rmdir(sProtocol + sWorkAreaPath + (sPath.startsWith(SLASH) ? sPath : SLASH+sPath));
   }

    if (DebugFile.trace) {
      DebugFile.decIdent();
      DebugFile.writeln("End FileSystemWorkArea.rmworkpath() : " + String.valueOf(bRetVal));
    }

    return bRetVal;
  } // rmstorpath

  // ---------------------------------------------------------------------------

  /**
   * <p>Remove workarea files under /storage branch</p>
   * @param iDomain Domain Numeric Identifier
   * @param sWorkArea WorkArea GUID
   * @param sPath Relative path from workarea subdirectory to delete.
   * @throws Exception
   * @throws IOException
   */

  public boolean rmstorpath (int iDomain, String sWorkArea, String sPath) throws Exception,IOException {
    return rmstorpath(oPropsCNF, iDomain, sWorkArea, sPath);
  }

  /**
   * <p>Remove workarea files under /storage branch</p>
   * @param iDomain Domain Numeric Identifier
   * @param sWorkArea WorkArea GUID
   * @throws Exception
   * @throws IOException
   */

  public boolean rmstorpath (int iDomain, String sWorkArea) throws Exception,IOException {
    return rmstorpath(oPropsCNF, iDomain, sWorkArea, null);
  }

}
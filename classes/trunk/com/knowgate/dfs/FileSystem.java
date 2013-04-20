/*
  Copyright (C) 2003  Know Gate S.L. All rights reserved.

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

package com.knowgate.dfs;

import java.io.*;

import java.net.URL;
import java.net.HttpURLConnection;
import java.net.MalformedURLException;
import java.net.ProtocolException;
import javax.net.ssl.HttpsURLConnection;

import java.util.TreeSet;
import java.util.zip.ZipEntry;
import java.util.zip.ZipOutputStream;

import javax.activation.DataHandler;

import org.apache.http.HttpResponse;
import org.apache.http.HttpEntity;
import org.apache.http.client.methods.HttpGet;
import org.apache.http.impl.client.DefaultHttpClient;
import org.apache.http.auth.AuthScope;
import org.apache.http.auth.UsernamePasswordCredentials;

import com.enterprisedt.net.ftp.FTPClient;
import com.enterprisedt.net.ftp.FTPException;
import com.enterprisedt.net.ftp.FTPTransferType;

import org.apache.oro.text.regex.Util;
import org.apache.oro.text.regex.Pattern;
import org.apache.oro.text.regex.Perl5Matcher;
import org.apache.oro.text.regex.Perl5Compiler;
import org.apache.oro.text.regex.StringSubstitution;
import org.apache.oro.text.regex.PatternMatcherInput;
import org.apache.oro.text.regex.MalformedPatternException;

import com.knowgate.debug.DebugFile;
import com.knowgate.misc.Gadgets;
import com.knowgate.misc.Environment;

import com.knowgate.dfs.chardet.CharacterSetDetector;

import java.util.Properties;

// ==========================================================

/**
 * <p>Abstract FileSystem object for encasulating NFS and FTP file transfer.</p>
 * FileSystem can work in 100% Pure Java mode or using native operating system
 * atomic calls.
 * <p>This is an alpha state testing module.</p>
 * @author Sergio Montoro Ten
 * @version 6.0
 */

public class FileSystem {

  /**
   * <p>Create new File System</p>
   * <p>Operation mode will be Pure Java by default</p>
   * <p>User and Password fro FTP access wil be readed from hipergate.cnf file</p>
   * @throws NumberFormatException If javamode property is not a positive integer number.
   * @throws IllegalArgumentException If javamode property is not 0, 1 or 2.
   */

  public FileSystem() throws NumberFormatException, IllegalArgumentException {

    try {
      OS = Integer.parseInt(Environment.getProfileVar("hipergate", "javamode", String.valueOf(OS_PUREJAVA)));
    }
    catch (NumberFormatException nfe) { OS=OS_PUREJAVA; }

    if (OS<0 || OS>2)
      throw new IllegalArgumentException("javamode property can only be set to 0, 1 or 2");

    SLASH = System.getProperty("file.separator");

    oRunner = null;
    
    oHttpCli = null;

    sUsr = Environment.getProfileVar("hipergate", "fileuser", "anonymous");
    sPwd = Environment.getProfileVar("hipergate", "filepassword", "");
    sSrv = Environment.getProfileVar("hipergate", "fileserver", "localhost");
  }

  // ==========================================================

  /**
   * <p>Create new File System</p>
   * <p>Operation mode may be set for faster file access throught direct usage
   * of operating system atomic calls.</p>
   * <p>User and Password fro FTP access wil be readed from hipergate.cnf file</p>
   * @param iMode Operation Mode { OS_PUREJAVA | OS_UNIX | OS_WINDOWS }
   */

  public FileSystem(int iMode) {
	OS = iMode;
    SLASH = System.getProperty("file.separator");
    oRunner = Runtime.getRuntime();
    oHttpCli = null;
    sUsr = Environment.getProfileVar("hipergate", "fileuser", "anonymous");
    sPwd = Environment.getProfileVar("hipergate", "filepassword", "");
    sSrv = Environment.getProfileVar("hipergate", "fileserver", "localhost");
  }

  // ----------------------------------------------------------

  /**
   * <p>Create new File System</p>
   * <p>Operation mode will be Pure Java by default</p>
   * @param sUser User for FTP access
   * @param sPassword Password for FTP access
   */

  public FileSystem(String sUser, String sPassword) {
    OS = OS_PUREJAVA;
    SLASH = System.getProperty("file.separator");
    oRunner = Runtime.getRuntime();
    oHttpCli = null;
    sUsr = sUser;
    sPwd = sPassword;
    sSrv = Environment.getProfileVar("hipergate", "fileserver", "localhost");
  }

  // ----------------------------------------------------------

  /**
   * <p>Create new File System</p>
   * <p>Operation mode will be Pure Java by default</p>
   * @param sUser User for FTP access
   * @param sPassword Password for FTP access
   * @param sRealm Realm for HTTP authentication
   * @since 4.0
   */

  public FileSystem(String sUser, String sPassword, String sRealm) {
    OS = OS_PUREJAVA;
    SLASH = System.getProperty("file.separator");
    oRunner = Runtime.getRuntime();
    oHttpCli = null;
    sUsr = sUser;
    sPwd = sPassword;
    sSrv = sRealm;
  }

  // ----------------------------------------------------------

  /**
   * <p>Create new File System</p>
   * @param iMode Operation Mode: OS_PUREJAVA or OS_UNIX or OS_WINDOWS
   * @param sUser User for FTP access
   * @param sPassword Password for FTP access
   */

  public FileSystem(int iMode, String sUser, String sPassword) {
    OS = iMode;

    SLASH = System.getProperty("file.separator");
    oRunner = Runtime.getRuntime();
    oHttpCli = null;
    sUsr = sUser;
    sPwd = sPassword;
    sSrv = Environment.getProfileVar("hipergate", "fileserver", "localhost");
  }

  // ----------------------------------------------------------

  /**
   * Crea un FileSystem tomando los parámetros de creación necesarios
   * de un conjunto de propiedades.
   * @param oProps Conjunto de propiedades. Actualmente se usan dos:
   * fileuser = Nombre de Usuario a Autentificar
   * filepassword = Clave de Acceso del Usuario
   */

  /**
   *
   * @param oProps Properties collection.<br>
   * <u>Property names</u>:<br>
   * <b>javamode</b> : "0" (default) for Pure Java, "1" for UNIX, "2" for Windows.<br>
   * <b>fileuser</b> : User for FTP access (default is "anonymous").
   * <b>filepassword</b> : Password for FTP access (default is "").
   * @throws NumberFormatException If javamode property is not a positive integer number.
   * @throws IllegalArgumentException If javamode property is not 0, 1 or 2.
   */
  public FileSystem(Properties oProps) throws NumberFormatException,IllegalArgumentException {

	String sJavaMode = oProps.getProperty("javamode", "0");
	if (sJavaMode.length()==0) sJavaMode = "0";
	
    OS = Integer.parseInt(sJavaMode.trim());

    if (OS<0 || OS>2)
      throw new IllegalArgumentException("javamode property can only be set to 0, 1 or 2");

    SLASH = System.getProperty("file.separator");

    oRunner = Runtime.getRuntime();

    oHttpCli = null;

    sUsr = oProps.getProperty("fileuser", "anonymous");
    sPwd = oProps.getProperty("filepassword", "");
    sSrv = oProps.getProperty("fileserver", "localhost");
  }

  // ----------------------------------------------------------

  /**
   * @param iOperatingSystem =  { FileSystem.OS_PUREJAVA, FileSystem.OS_UNIX, FileSystem.OS_WINDOWS }
   */

  public void os(int iOperatingSystem) {
    OS = iOperatingSystem;

    if (OS!=OS_PUREJAVA && null==oRunner)
      oRunner = Runtime.getRuntime();
  }

  // ----------------------------------------------------------

  /**
   * @param sUser user for FTP access
   */

  public void user(String sUser) {
    sUsr = sUser;
  }

  // ----------------------------------------------------------

  /**
   * @return user for FTP access.
   */
  public String user() {
    return sUsr;
  }

  // ----------------------------------------------------------

  /**
   * @param sPassword Password for FTP or HTTP access
   */
  public void password(String sPassword) {
    sPwd = sPassword;
  }

  // ----------------------------------------------------------

  /**
   * @return Password for FTP or HTTP access
   */

  public String password() {
    return sPwd;
  }

  // ----------------------------------------------------------

  /**
   * @return Realm for HTTP access
   */

  public String realm() {
    return sSrv;
  }

  // ----------------------------------------------------------

  protected String host() {
    return sHost;
  }

  // ----------------------------------------------------------

  protected String path() {
    return sPath;
  }

  // ----------------------------------------------------------

  protected String file() {
    return sFile;
  }

  // ----------------------------------------------------------

  protected void splitURI(String sURI) {
    String sURINoProtocol;
    int iHost, iPort, iPath;

    if (sURI.startsWith("file://")) {
      sURINoProtocol = sURI.substring(7);
      sProtocol = "file://";
    }
    else if (sURI.startsWith("ftp://")) {
      sURINoProtocol = sURI.substring(6);
      sProtocol = "ftp://";
    }
    else {
      sURINoProtocol = sURI;
      sProtocol = "";
    }

    if (sProtocol.equals("ftp://")) {
      iHost = sURINoProtocol.indexOf('/', 7);
      sHost = sURINoProtocol.substring(0, iHost);
      iPort = sHost.indexOf(':');
      if (iPort > 0) {
        sPort = sHost.substring(iPort + 1);
        sHost = sHost.substring(0, iPort);
      }
      else
        sPort = "";

      iPath = sURINoProtocol.lastIndexOf('/');
      sPath = sURINoProtocol.substring(iHost, iPath+1);
      sFile = sURINoProtocol.substring(iPath+1);
    }
    else if (sProtocol.equals("file://")) {
      sHost = "";
      sPort = "";
      iPath = sURINoProtocol.lastIndexOf('/', 8);
      sPath = sURINoProtocol.substring(7, iPath+1);
      sFile = sURINoProtocol.substring(iPath+1);
    }
  } // splitURI()

  // ---------------------------------------------------------------------------

  private static void copyFileNFS(String sSource, String sTarget) throws Exception {
    FileInputStream fis  = new FileInputStream(sSource);
    FileOutputStream fos = new FileOutputStream(sTarget);

    BufferedInputStream bis = new BufferedInputStream(fis);
    BufferedOutputStream bos = new BufferedOutputStream(fos);

    byte[] buf = new byte[2048];
    int i = 0;

    while((i=bis.read(buf))!=-1) bos.write(buf, 0, i);

    bis.close();
    bos.close();
    fis.close();
    fos.close();
  } // copyFileNFS()

  // ---------------------------------------------------------------------------

  private void copyFTPToFTP(String sSource, String sTarget)
    throws FTPException,IOException {

    String sSourceHost, sTargetHost, sSourcePath, sTargetPath, sSourceFile, sTargetFile, sTempName;
    FTPWorkerThread oReader,oWriter;
    FTPClient oFTPC;

    if (DebugFile.trace) {
      DebugFile.writeln("Begin FileSystem.copyFTPToFTP(" + sSource + "," + sTarget + ")");
      DebugFile.incIdent();
    }

    splitURI(sSource);
    sSourceHost = sHost;
    sSourcePath = sPath;
    if (!sSourcePath.endsWith("/")) sSourcePath+="/";
    sSourceFile = sFile;

    splitURI(sTarget);
    sTargetHost = sHost;
    sTargetPath = sPath;
    if (!sTargetPath.endsWith("/")) sTargetPath+="/";
    sTargetFile = sFile;

    if (sSourceHost.equals(sTargetHost) && (OS!=OS_PUREJAVA)) {
      sTempName = Gadgets.generateUUID();

      oFTPC = new FTPClient(sTargetHost);
      oFTPC.login(user(), password());

      if (DebugFile.trace)DebugFile.writeln("FTPClient.site(exec cp " + sSourcePath + sSourceFile + " " + sTargetPath + sTargetFile);
      oFTPC.rename(sSourcePath + sSourceFile, sSourcePath + sTempName );
      oFTPC.site("exec cp " + sSourcePath + sTempName + " " + sTargetPath + sTargetFile);
      oFTPC.rename(sSourcePath + sTempName, sSourcePath + sSourceFile);
      oFTPC.quit();
    }
    else {
      oReader = new FTPWorkerThread(sSourceHost, sUsr, sPwd);
      oWriter = new FTPWorkerThread(sTargetHost, sUsr, sPwd);

      oReader.get(sSourcePath+sSourceFile);
      oWriter.put(sTargetPath+sTargetFile);

      oReader.connect(oWriter.getInputPipe());

      if (DebugFile.trace) DebugFile.writeln("starting read pipe...");

      oReader.start();

      if (DebugFile.trace) DebugFile.writeln("starting write pipe...");

      oWriter.start();
    } // fi (sSourceHost==sTargetHost AND OS!=PUREJAVA)

    if (DebugFile.trace) {
      DebugFile.decIdent();
      DebugFile.writeln("End FileSystem.copyFTPToFTP()");
    }
  } // copyFTPToFTP()

  // ---------------------------------------------------------------------------

  private void copyFileToFTP(String sSource, String sTarget) throws Exception,IOException {
    boolean bFTPSession = false;

    FTPClient oFTPC = null;

    splitURI(sTarget);

    try {
      if (DebugFile.trace) DebugFile.writeln("new FTPClient(" + sHost + ")");
      oFTPC = new FTPClient(sHost);
      if (DebugFile.trace) DebugFile.writeln("FTPClient.login(" + sUsr + "," + sPwd + ")");
      oFTPC.login(sUsr, sPwd);
      bFTPSession = true;
      if (DebugFile.trace) DebugFile.writeln("FTPClient.chdir(" + sPath + ")");
      oFTPC.chdir(sPath);
      if (DebugFile.trace) DebugFile.writeln("FTPClient.put(" + sSource + "," + sFile + ",false)");
      oFTPC.setType(FTPTransferType.BINARY);
      oFTPC.put(sSource, sFile, false);

    } catch (FTPException ftpe) {
      throw new Exception(ftpe.getMessage(), ftpe.getCause());
    }
    finally {
      if (DebugFile.trace) DebugFile.writeln("FTPClient.quit()");
      if (bFTPSession) oFTPC.quit();
    }

  } // copyFileToFTP()

  // ---------------------------------------------------------------------------

  private void copyFTPToFile(String sSource, String sTarget)
    throws Exception,IOException {

    boolean bFTPSession = false;

    FTPClient oFTPC = null;

    splitURI(sSource);

    try {
      if (DebugFile.trace) DebugFile.writeln("new FTPClient(" + sHost + ")");
      oFTPC = new FTPClient(sHost);
      if (DebugFile.trace) DebugFile.writeln("FTPClient.login(" + sUsr + "," + sPwd + ")");
      oFTPC.login(sUsr, sPwd);
      bFTPSession = true;
      if (DebugFile.trace) DebugFile.writeln("FTPClient.chdir(" + sPath + ")");
      oFTPC.chdir(sPath);
      if (DebugFile.trace) DebugFile.writeln("FTPClient.get(" + sTarget + "," + sFile + ",false)");
      oFTPC.setType(FTPTransferType.BINARY);
      oFTPC.get(sTarget, sFile);

    } catch (FTPException ftpe) {
      throw new Exception(ftpe.getMessage(), ftpe.getCause());
    }
    finally {
      if (DebugFile.trace) DebugFile.writeln("FTPClient.quit()");
      if (bFTPSession) oFTPC.quit();
    }

  } // copyFileToFTP()

  // ---------------------------------------------------------------------------

  private static void copyHTTPToFile (String sSource, String sTarget)
    throws MalformedURLException,IOException {
    URL oUrl = new URL(sSource);
    FileOutputStream oTrgt = new FileOutputStream(sTarget.substring(7));
    DataHandler oHndlr = new DataHandler(oUrl);
    oHndlr.writeTo(oTrgt);
    oTrgt.close();
  } // copyHTTPToFile

  // ---------------------------------------------------------------------------

  /**
   * <p>Copy a file</p>
   * <p>This method is able to copy a file from local or network disk location
   * to and FTP location or viceversa.</p>
   * @param sSourceURI Source URI, it must have the following syntax:
   * protocol://[server:[port]]/path/filename
   * Even whe working with local files protocol must be specified, ej.
   * copy ("file:///tmp/upload/image.jpg", "file:///opt/storage/approved/image.jpg")
   * @param sTargetURI Target URI
   * @throws Exception
   * @throws IOException
   * @throws MalformedURLException
   */

  public boolean copy (String sSourceURI, String sTargetURI) throws MalformedURLException, IOException, Exception {
    // Copy a file by delegating the operation into an operating system atomic call

    if (DebugFile.trace) {
      DebugFile.writeln("Begin FileSystem.copy(" + sSourceURI + "," + sTargetURI + ")");
      DebugFile.incIdent();
    }

    byte verbose[] = new byte[256];
    boolean bRetVal;
    int iReaded;
    String sCmd;
    InputStream oStdOut;
    String sSourcePath;
    String sTargetPath;
    File oSourceFile;

    if (sSourceURI.startsWith("file://") && sTargetURI.startsWith("file://")) {
      sSourcePath = sSourceURI.substring(7);
      sTargetPath = sTargetURI.substring(7);
      oSourceFile = new File(sSourcePath);

      switch (OS) {
        case OS_UNIX:
          if (oSourceFile.isDirectory())
            sCmd = "/usr/bin/cp -r " + sSourcePath + " " + sTargetPath;
          else
            sCmd = "/usr/bin/cp \"" + sSourcePath + "\" \"" + sTargetPath + "\"";
          break;
        case OS_WINDOWS:
          if (oSourceFile.isDirectory())
            sCmd = "xcopy " + sSourcePath + " " + sTargetPath + " /E /C /Q /Y";
          else
            sCmd = "copy \"" + sSourcePath + "\" \"" + sTargetPath + "\"";
          break;
        default:
          sCmd = "";
      } // end switch(OS)

      if (sCmd.length()>0) {
        if (DebugFile.trace) {
          DebugFile.writeln("Runtime.exec(" + sCmd + ")");
          oStdOut = oRunner.exec(sCmd).getInputStream();
          iReaded = oStdOut.read(verbose, 0, 255);
          oStdOut.close();
          if (iReaded>0) DebugFile.writeln(new String(verbose, iReaded));
        }
        else {
          oRunner.exec(sCmd);
        }
      }
      else {
        if (DebugFile.trace) DebugFile.writeln("copyFileNFS(" + sSourcePath + "," + sTargetPath + ")");

        if (oSourceFile.isDirectory()) {
		  File[] oFiles = oSourceFile.listFiles();
		  if (oFiles!=null) {
		  	final int nFiles = oFiles.length;
            if (DebugFile.trace) DebugFile.writeln(String.valueOf(nFiles)+" files found");
		  	for (int f=0; f<nFiles; f++) {
		  	  if (oFiles[f].isDirectory()) {
		  	  	String sSourceDir = Gadgets.chomp(sSourceURI,File.separator)+oFiles[f].getName();		  	  	
		  	  	String sTargetDir = Gadgets.chomp(sTargetURI,File.separator)+oFiles[f].getName();
    		    if (DebugFile.trace) {
      			  DebugFile.writeln("  Copying directory "+sSourceDir+" to "+sTargetDir);
    		    }
		  	  	mkdirs(sTargetDir);
				copy(sSourceDir,sTargetDir);
		  	  } else {
    		    if (DebugFile.trace) {
      			  DebugFile.writeln("  Copying file "+Gadgets.chomp(sSourcePath,File.separator)+oFiles[f].getName()+" to "+Gadgets.chomp(sTargetPath,File.separator)+oFiles[f].getName());
    		    }
                copyFileNFS(Gadgets.chomp(sSourcePath,File.separator)+oFiles[f].getName(),
                			Gadgets.chomp(sTargetPath,File.separator)+oFiles[f].getName());
		  	  }
		  	} // next
		  }
        } else {
          copyFileNFS(sSourcePath, sTargetPath);
        }
      }
      bRetVal = exists(sTargetURI);

    } // fi(Source==file AND Target==file)
    
    else if (sSourceURI.startsWith("file://") && sTargetURI.startsWith("ftp://")) {
      sSourcePath = sSourceURI.substring(7);
      sTargetPath = sTargetURI.substring(6);
      if (DebugFile.trace) DebugFile.writeln("copyFileToFTP(" + sSourcePath + "," + sTargetURI + ")");

      copyFileToFTP(sSourcePath, sTargetURI);
      bRetVal = true;
    }
    else if (sSourceURI.startsWith("ftp://") && sTargetURI.startsWith("ftp://")) {
      if (DebugFile.trace) DebugFile.writeln("copyFTPToFTP(" + sSourceURI + "," + sTargetURI + ")");

      copyFTPToFTP(sSourceURI, sTargetURI);
      bRetVal = true;
    }
    else if (sSourceURI.startsWith("ftp://") && sTargetURI.startsWith("file://")) {
      if (DebugFile.trace) DebugFile.writeln("copyFTPToFTP(" + sSourceURI + "," + sTargetURI + ")");

      copyFTPToFile(sSourceURI, sTargetURI);
      bRetVal = exists(sTargetURI);
    }
    else if (sSourceURI.startsWith("http://") && sTargetURI.startsWith("file://")) {
      if (DebugFile.trace) DebugFile.writeln("copyHTTPToFile(" + sSourceURI + "," + sTargetURI + ")");

      copyHTTPToFile(sSourceURI, sTargetURI);
      bRetVal = exists(sTargetURI);
    }
    else {
      if (DebugFile.trace) DebugFile.writeln("ERROR: FileSystem.copy(), Source or Target protocol not recognized");
      bRetVal = false;
      throw new IOException("FileSystem.copy(), protocol not recognized");
    }

    if (DebugFile.trace) {
      DebugFile.decIdent();
      DebugFile.writeln("End FileSystem.copy() : " + String.valueOf(bRetVal));
    }

    return bRetVal;
  } // copy()

  // ---------------------------------------------------------------------------

  /**
   * Checks whether a file or directory exists
   * @param sSouceURI Source URI (including protocol preffix)
   * @throws IOException
   * @since 4.0
   **/
  public boolean exists(String sSourceURI)
  	throws IOException {
	boolean bExists = false;

    if (DebugFile.trace) {
      DebugFile.writeln("Begin FileSystem.exists(" + sSourceURI + ")");
      DebugFile.incIdent();
    }

	if (sSourceURI.startsWith("file://")) {
	  bExists = new File(sSourceURI.substring(7)).exists();	  
	} else if (sSourceURI.startsWith("ftp://")) {
      boolean bFTPSession = false;
      FTPClient oFTPC = null;
      splitURI(sSourceURI);
	  String[] aFiles = null;
	  try {
        if (DebugFile.trace) DebugFile.writeln("new FTPClient(" + sHost + ")");
        oFTPC = new FTPClient(sHost);
        if (DebugFile.trace) DebugFile.writeln("FTPClient.login(" + sUsr + "," + sPwd + ")");
        oFTPC.login(sUsr, sPwd);
        bFTPSession = true;
        if (DebugFile.trace) DebugFile.writeln("FTPClient.dir(" + sPath + ")");
        aFiles = oFTPC.dir(sPath);
	    oFTPC.quit();
	  } catch (FTPException ftpe) {
	  	throw new IOException(ftpe.getMessage());
	  }
	  if (aFiles!=null) {
	  	int nFiles = aFiles.length;
	  	for (int f=0; f<nFiles && !bExists; f++) {
	  	  bExists = aFiles[f].equals(sFile);
	  	} // next
	  } // fi (aFiles)
	} else if (sSourceURI.startsWith("http://")) {
		try {
    	  URL oUrl = new URL(sSourceURI);
		  HttpURLConnection oCon = (HttpURLConnection) oUrl.openConnection();
		  int iResponseCode = oCon.getResponseCode();
		  oCon.disconnect();
		  bExists = (iResponseCode>=200 && iResponseCode<=299);
	    } catch (MalformedURLException mue) {
	      throw new IOException(mue.getMessage());
	    }
	} else if (sSourceURI.startsWith("https://")) {
		try {
    	  URL oUrl = new URL(sSourceURI);
		  HttpsURLConnection oCon = (HttpsURLConnection) oUrl.openConnection();
		  int iResponseCode = oCon.getResponseCode();
		  oCon.disconnect();
		  bExists = (iResponseCode>=200 && iResponseCode<=299);
	    } catch (MalformedURLException mue) {
	      throw new IOException(mue.getMessage());
	    }
	}
    if (DebugFile.trace) {
      DebugFile.decIdent();
      DebugFile.writeln("End FileSystem.exists() : " + String.valueOf(bExists));
    }
	return bExists;
  } // exists

  // ---------------------------------------------------------------------------

  /**
   * <p>Get file length</p>
   * Currently only local and network files length can be queried</p>
   * @param sFullURI File URI (protocol+path)
   * @return File length in bytes
   * @throws IOException
   */
  public int filelen (String sFullURI) throws IOException {
    File oFile;
    Long oFLng;
    int  iFLen;

    if (DebugFile.trace) {
      DebugFile.writeln("Begin FileSystem.filelen(" + sFullURI + ")");
      DebugFile.incIdent();
    }

    oFile = new File(sFullURI);
    if (oFile.exists()) {
      oFLng = new Long(oFile.length());
      iFLen = oFLng.intValue();
    }
    else
      throw new IOException("File " + sFullURI + " does not exists");

    if (DebugFile.trace) {
      DebugFile.decIdent();
      DebugFile.writeln("End FileSystem.filelen() : " + String.valueOf(iFLen));
    }

    return iFLen;
  } // filelen()

  // ----------------------------------------------------------

  private static String[] listFTP (FTPClient oFTPC, String sBaseDir, char cType)
    throws FTPException, IOException {

    if (DebugFile.trace) {
      DebugFile.writeln("Begin FileSystem.listFTP(" + sBaseDir + "," + cType + ")");
      DebugFile.incIdent();
    }

    String[] aFileNames = oFTPC.dir(sBaseDir);
    String[] aFileAttrs = oFTPC.dir(sBaseDir, true);

    int iFileCount = aFileNames.length;
    int iAttrCount = aFileAttrs.length;

    boolean[] aIsDirectory = new boolean[iFileCount];

    for (int i=0; i<iFileCount; i++) aIsDirectory[i] = false;

    String sFile;
    int iDirCount = 0;

    for (int f=0; f<iFileCount; f++) {
      sFile = aFileNames[f];
      for (int a=0; a<iAttrCount; a++) {
        if ((aFileAttrs[a].charAt(0)==cType))
          if (aFileAttrs[a].endsWith(sFile)) {
            aIsDirectory[f] = true;
            iDirCount++;
            break;
          } // fi
      } // next
    } // next

    String[] aDirNames = new String[iDirCount];

    iDirCount = 0;

    for (int d=0; d<iFileCount; d++)
      if (aIsDirectory[d])
        aDirNames[iDirCount++] = aFileNames[d];

    if (DebugFile.trace) {
      DebugFile.decIdent();
      DebugFile.writeln("End FileSystem.listFTP()");
    }

    return aDirNames;
  } // listFTP

  // ----------------------------------------------------------

  private static String[] listDirsFTP (FTPClient oFTPC, String sBaseDir)
    throws FTPException, IOException {
    return listFTP(oFTPC, sBaseDir, 'd');
  }

  // ----------------------------------------------------------

  private static String[] listFilesFTP (FTPClient oFTPC, String sBaseDir)
    throws FTPException, IOException {
    return listFTP(oFTPC, sBaseDir, '-');
  }

  // ----------------------------------------------------------

  private static boolean isDirectoryFTP (FTPClient oFTPC, String sFilePath)
    throws FTPException, IOException {

    if (DebugFile.trace) {
      DebugFile.writeln("Begin FileSystem.isDirectoryFTP(" + sFilePath + ")");
      DebugFile.incIdent();
    }

    if (sFilePath.equals("/")) return true;

    String sPathName, sFileName;

    int iSlash = sFilePath.lastIndexOf('/');
    if (iSlash<1) {
      sPathName = "/";
      sFileName = sFilePath.substring(1);
    }
    else {
      sPathName = sFilePath.substring(0, iSlash);
      sFileName = sFilePath.substring(iSlash+1);
    }

    String[] aFileAttrs = oFTPC.dir(sPathName, true);
    boolean bIsDir = false;

    int iFileCount = aFileAttrs.length;

    for (int d=0; d<iFileCount; d++) {
      if (aFileAttrs[d].endsWith(sFileName)) {
        bIsDir = (aFileAttrs[d].charAt(0) == 'd');
        break;
      } // fi()
    } // next

    if (DebugFile.trace) {
      DebugFile.decIdent();
      DebugFile.writeln("End FileSystem.isDirectoryFTP() : " + String.valueOf(bIsDir));
    }

    return bIsDir;
  } // isDirectoryFTP

  // ----------------------------------------------------------

  /**
   * Remove a directory and all its subdirectories and files.
   * @param sFullURI Directory URI. For example: file:///tmp/upload
   * @return <b>true</b> if Directory was successfully deleted.
   * This return value should always be checked as Java functions may not return
   * any error but not delete a directory that is in use by another process.
   * @throws IOException
   */
  public boolean rmdir (String sFullURI) throws IOException {
    File oFile;
    int iReaded;
    String sFullPath;
    boolean bRetVal = false;
    boolean bFTPSession = false;
    FTPClient oFTPC = null;
    String sCmd = null;
    InputStream oStdOut;
    byte verbose[] = new byte[256];

    if (DebugFile.trace) {
      DebugFile.writeln("Begin FileSystem.rmdir(" + sFullURI + ")");
      DebugFile.incIdent();
    }

    if (sFullURI.startsWith("file://")) {
      sFullPath = sFullURI.substring(7);
      if (sFullPath.endsWith(SLASH)) sFullPath = sFullPath.substring(0, sFullPath.length()-SLASH.length());
      oFile = new File(sFullPath);

      if (DebugFile.trace) DebugFile.writeln(sFullPath + " is a directory");

      switch (OS) {
          case OS_PUREJAVA:
        	File[] aFiles = oFile.listFiles();
        	if (aFiles!=null)
        	  for (int f=0; f<aFiles.length; f++)
        	    if (aFiles[f].isDirectory())
        	      rmdir("file://"+aFiles[f].getAbsolutePath());
        	    else
        	      aFiles[f].delete();
            bRetVal = oFile.delete();
            break;
          case OS_UNIX:
            sCmd = "rm -rf \"" + sFullPath + "\"";
            break;
          case OS_WINDOWS:
            sCmd = "DEL /F /S /Q \"" + sFullPath + "\"";
            break;
      } // end switch()

      if (null!=sCmd) {
          if (DebugFile.trace) {
            DebugFile.writeln("Runtime.exec(" + sCmd + ")");
            oStdOut = oRunner.exec(sCmd).getInputStream();
            iReaded = oStdOut.read(verbose, 0, 255);
            oStdOut.close();
            if (iReaded > 0) {
              DebugFile.writeln(new String(verbose, iReaded));
              bRetVal = false;
            }
            else
              bRetVal = true;
          }
          else {
            oRunner.exec(sCmd);
            bRetVal = true;
          }
      } // fi (sCmd)

      if (oFile.exists()) bRetVal = false;

      oFile = null;
    }

    else if (sFullURI.startsWith("ftp://")) {

      splitURI(sFullURI);

      try {
        if (DebugFile.trace) DebugFile.writeln("new FTPClient(" + sHost + ")");

        oFTPC = new FTPClient(sHost);

        if (DebugFile.trace) DebugFile.writeln("oFTPC.login(" + sUsr + ", ...);");

        oFTPC.login(sUsr, sPwd);

        bFTPSession = true;

        sFullPath = Gadgets.chomp(sPath, '/') + sFile;

        String[] aSubDirs = listDirsFTP(oFTPC, sFullPath);

        for (int d = 0; d < aSubDirs.length; d++) {
          delete (Gadgets.chomp(sFullURI, '/') + aSubDirs[d]);
        }

        String[] aFiles = listFilesFTP(oFTPC, sFullPath);

        for (int f=0; f<aFiles.length; f++) {
          if (DebugFile.trace) DebugFile.writeln("FTPClient.delete(" + Gadgets.chomp(sPath,'/') + Gadgets.chomp(sFile,'/') + aFiles[f] + ")");

          oFTPC.delete (Gadgets.chomp(sPath,'/') + Gadgets.chomp(sFile,'/') + aFiles[f]);
        }

        if (DebugFile.trace) DebugFile.writeln("FTPClient.rmdir(" + sFullPath + ")");

        oFTPC.rmdir(sFullPath);

        bRetVal = true;
      } catch (FTPException ftpe) {
        bRetVal = false;
        throw new IOException(ftpe.getMessage());
      }
      catch (Exception xcpt) {
        bRetVal = false;
        throw new IOException(xcpt.getMessage());
      }
      finally {
        try { if (bFTPSession) oFTPC.quit(); } catch (Exception xcpt) { }
      }
    }
    // fi(sFullURI.startsWith(...))

    if (DebugFile.trace) {
      DebugFile.decIdent();
      DebugFile.writeln("End FileSystem.rmdir() : " + String.valueOf(bRetVal));
    }

    return bRetVal;
  } // rmdir

  /**
   * <p>Delete o file or directory</p>
   * <p>Can recursively delete local or FTP directories</p>
   * @param sFullURI File or directory URI.
   * For example ftp://localhost/opt/temp/upload/logo.gif
   * @return <b>true</b> if File or Directory was successfully deleted.
   * This return value should always be checked as Java functions may not return
   * any error but not delete a directory or file that is in use by another process.
   * @throws IOException
   */
  public boolean delete (String sFullURI) throws IOException {
    File oFile;
    String sFullPath;
    boolean bRetVal = false;
    boolean bFTPSession = false;
    FTPClient oFTPC = null;
    String sCmd = null;
    byte verbose[] = new byte[256];

    if (DebugFile.trace) {
      DebugFile.writeln("Begin FileSystem.delete(" + sFullURI + ")");
      DebugFile.incIdent();
      switch (OS) {
        case OS_PUREJAVA:
          DebugFile.writeln("OS mode is Pure Java");
          break;
        case OS_UNIX:
          DebugFile.writeln("OS mode is Unix");
          break;
        case OS_WINDOWS:
          DebugFile.writeln("OS mode is Windows");
          break;
      }
    }

    // Codigo a ejecutar por el protocolo de ficheros locales
    if (sFullURI.startsWith("file://")) {
      sFullPath = sFullURI.substring(7);
      if (sFullPath.endsWith(SLASH)) sFullPath = sFullPath.substring(0, sFullPath.length()-SLASH.length());
      oFile = new File(sFullPath);

      if (oFile.isFile()) {
        if (DebugFile.trace) DebugFile.writeln(sFullPath + " is a file");
        bRetVal = oFile.delete();
      }
      else {
        bRetVal = rmdir(sFullURI);
      } // fi (isFile())
      oFile = null;
    }
    // Codigo a ejecutar por el protocolo FTP
    else if (sFullURI.startsWith("ftp://")) {

      splitURI(sFullURI);

      try {
        if (DebugFile.trace) DebugFile.writeln("new FTPClient(" + sHost + ")");

        oFTPC = new FTPClient(sHost);

        if (DebugFile.trace) DebugFile.writeln("oFTPC.login(" + sUsr + ", ...);");

        oFTPC.login(sUsr, sPwd);

        bFTPSession = true;

        sFullPath = Gadgets.chomp(sPath,'/') + sFile;

        if (isDirectoryFTP(oFTPC, sFullPath)) {
          oFTPC.quit();
          bFTPSession = false;
          rmdir (sFullURI);
        }
        else {
          oFTPC.delete(sFullPath);
        }

        bRetVal = true;
      } catch (FTPException ftpe) {
        bRetVal = false;
        throw new IOException(ftpe.getMessage());
      }
      catch (Exception xcpt) {
        bRetVal = false;
        throw new IOException(xcpt.getMessage());
      }
      finally {
        try { if (bFTPSession) oFTPC.quit(); } catch (Exception xcpt) { }
      }
    }
    // fi(sFullURI.startsWith(...))

    if (DebugFile.trace) {
      DebugFile.decIdent();
      DebugFile.writeln("End FileSystem.delete() : " + String.valueOf(bRetVal));
    }

    return bRetVal;
  } // delete()

  // ----------------------------------------------------------

  /**
   * <p>Mark an URI for deffered deletion</p>
   * Because web servers often cache and lock files as they are accessed,
   * it is sometimes not possible to delete recently accessed files inmediately.
   * This method just appends the given URI at the end of a plain text file
   * containing a list of file names. This file name list can be later used upon
   * Web Server re-start for purging files that could no be deleted before because
   * they where locked.
   * @param sFullURI File URI to delete, ej. file:///opt/knowgate/files/deleteme.txt
   * @param sDeferedFiles Local path to file containing delete list
   * @throws IOException
   */

  public boolean delete (String sFullURI, String sDeferedFiles) throws IOException {
    boolean bRetVal = delete(sFullURI);
    FileWriter oWrt;

    if (sDeferedFiles.startsWith("file://")) sDeferedFiles = sDeferedFiles.substring(7);

    if (!bRetVal && sFullURI.startsWith("file://")) {
      oWrt = new FileWriter(sDeferedFiles, true);
      oWrt.write("\"" + sFullURI.substring(7) + "\"\n");
      oWrt.close();
    } // fi ()

    return bRetVal;
  } // delete

  // ----------------------------------------------------------

  /**
   * <p>Recursively delete a files matching a given wildcard from a local directory</p>
   * @param sBasePath String. base path for start deleting files (like file:///opt/knowgate/files/)
   * @param sWildCard String. Wildcard to match (like *.tmp)
   * @return Number of deleted files or directories
   * @throws IOException
   * @throws  MalformedPatternException
   * @since 7.0
   */

  public int xdelete (String sBasePath, final String sWildCard) throws IOException, MalformedPatternException  {

	if (DebugFile.trace) {
	  DebugFile.writeln("Begin FileSystem.xdelete(" + sBasePath + "," + sWildCard + ")");
	  DebugFile.incIdent();
	}

	int nDeleted = 0;
    final String sRegExp = Gadgets.replace(Gadgets.replace(Gadgets.replace(Gadgets.replace(Gadgets.replace(Gadgets.replace(Gadgets.replace(sWildCard,
    		               '?', "[^\\x2E]"), '*', "[^\\x2E]*"), '.', "\\x2E"), '(', "\\x28"), ')', "\\x29"), '[', "\\x5B"), ']', "\\x5D");
    final Pattern oPattern = new Perl5Compiler().compile(sRegExp, Perl5Compiler.CASE_INSENSITIVE_MASK);
	
    FilenameFilter oFilter = new FilenameFilter() {
        public boolean accept(File oDir, String sName) {
          Perl5Matcher oMatcher = new Perl5Matcher();
          return oMatcher.matches(sName, oPattern);
        }
      };

    if (sBasePath.startsWith("file://")) sBasePath = sBasePath.substring(7);
    File oDir = new File(sBasePath);    
    File aFiles[] = oDir.listFiles(oFilter);
    if (aFiles!=null) {
      int nFiles = aFiles.length;
      for (int f=0; f<nFiles; f++) {
      	System.out.println("Deleting "+aFiles[f].getAbsolutePath());
    	boolean dDeleted = delete("file://"+aFiles[f].getAbsolutePath());
    	if (!dDeleted) System.out.println(aFiles[f].getAbsolutePath()+" could not be deleted");
    	nDeleted++;
      } // next
    } // fi
    aFiles = oDir.listFiles();
    if (aFiles!=null) {
      int nFiles = aFiles.length;
      for (int f=0; f<nFiles; f++) {
    	  nDeleted += xdelete(aFiles[f].getAbsolutePath(), sWildCard);
      } // next
    } // fi

    if (DebugFile.trace) {
      DebugFile.decIdent();
      DebugFile.writeln("End FileSystem.xdelete() : " + String.valueOf(nDeleted));
    }
    
    return nDeleted;
  } // xdelete
  
  // ----------------------------------------------------------

  private boolean moveFTPToFTP (String sSourceURI, String sTargetURI) throws FTPException, IOException {
    boolean bRetVal = true;
    String sSourceHost, sTargetHost, sSourcePath, sTargetPath, sSourceFile, sTargetFile;
    FTPWorkerThread oReader,oWriter;
    FTPClient oFTPC;

    if (DebugFile.trace) {
      DebugFile.writeln("Begin FileSystem.moveFTPToFTP(" + sSourceURI + "," + sTargetURI + ")");
      DebugFile.incIdent();
    }

    splitURI(sSourceURI);
    sSourceHost = sHost;
    sSourcePath = sPath;
    if (!sSourcePath.endsWith("/")) sSourcePath+="/";
    sSourceFile = sFile;

    splitURI(sTargetURI);
    sTargetHost = sHost;
    sTargetPath = sPath;
    if (!sTargetPath.endsWith("/")) sTargetPath+="/";
    sTargetFile = sFile;

    if (sSourceHost.equals(sTargetHost)) {
      if (DebugFile.trace) DebugFile.writeln("new FTPClient(" + sTargetHost + ")");

      oFTPC = new FTPClient(sTargetHost);
      oFTPC.login(user(), password());

      if (DebugFile.trace) DebugFile.writeln("FTPClient.rename(" + sSourcePath + sSourceFile + "," + sTargetPath + sTargetFile + ")");

      oFTPC.rename(sSourcePath + sSourceFile, sTargetPath + sTargetFile);
      oFTPC.quit();
    }
    else {

      oReader = new FTPWorkerThread(sSourceHost, sUsr, sPwd);
      oWriter = new FTPWorkerThread(sTargetHost, sUsr, sPwd);

      oReader.move(sSourcePath+sSourceFile);
      oWriter.put (sTargetPath+sTargetFile);

      oReader.connect(oWriter.getInputPipe());

      if (DebugFile.trace) DebugFile.writeln("starting read pipe...");

      oReader.start();

      if (DebugFile.trace) DebugFile.writeln("starting write pipe...");

      oWriter.start();
    }

    if (DebugFile.trace) {
      DebugFile.decIdent();
      DebugFile.writeln("End FileSystem.moveFTPToFTP()");
    }
    return bRetVal;
  } // moveFTPToFTP

  // ----------------------------------------------------------

  /**
   * <p>Move a file from one location to another</p>
   * @param sSourceURI Source URI
   * @param sTargetURI Target URI
   * @return
   * @throws Exception
   * @throws IOException
   */

  public boolean move (String sSourceURI, String sTargetURI) throws Exception, IOException {
    boolean bRetVal;

    if (sSourceURI.startsWith("ftp://") && sTargetURI.startsWith("ftp://")) {
      bRetVal = moveFTPToFTP(sSourceURI, sTargetURI);
    }
    else {
      bRetVal = copy(sSourceURI, sTargetURI);
      if (bRetVal)
        bRetVal = delete(sSourceURI);
    }
    return bRetVal;
  } // move

  // ----------------------------------------------------------

  /**
   * Rename file
   * @param sSourceURI Source URI (ej. "file:///tmp/files/oldfile.txt")
   * @param sTargetURI Target URI (ej. "file:///tmp/files/newfile.txt")
   * @since 2.1
   * @throws Exception
   * @throws IOException
   * @throws ProtocolException If source and target file does not use the same protocol, either file:// or ftp://
   */
  public boolean rename (String sSourceURI, String sTargetURI)
    throws Exception, IOException, ProtocolException {
    boolean bRetVal;

    if (sSourceURI.startsWith("file://") && sTargetURI.startsWith("file://")) {
      File oOldFile = new File (sSourceURI.substring(7));
      File oNewFile = new File (sTargetURI.substring(7));
      bRetVal = oOldFile.renameTo(oNewFile);
    }
    else if (sSourceURI.startsWith("ftp://") && sTargetURI.startsWith("ftp://")) {
      bRetVal = moveFTPToFTP(sSourceURI, sTargetURI);
    }
    else {
      throw new ProtocolException("");
    }
    return bRetVal;
  } // move

  // ----------------------------------------------------------

  private static void mkdirsFTP (FTPClient oFTPC, String sPath) throws IOException,FTPException {
    String aPath[] = Gadgets.split( (sPath.endsWith("/") ? sPath.substring(0, sPath.length()-1) : sPath), "/");
    String sCurrent = "/";
    int l = aPath.length;
    boolean bAlreadyExists;

    for (int p=0; p<=l; p++) {
      try {
        if (DebugFile.trace) DebugFile.writeln("oFTPC.chdir(" + sCurrent + ")");
        oFTPC.chdir(sCurrent);
        bAlreadyExists = true;
      }
      catch (FTPException ftpe) {
        if (DebugFile.trace) DebugFile.writeln(sCurrent + " does not exist");
        bAlreadyExists = false;
      }
      if (!bAlreadyExists) {
        if (DebugFile.trace) DebugFile.writeln("oFTPC.mkdir(" + sCurrent + ")");
        oFTPC.mkdir(sCurrent);
      }
      if (p==l) break;
      sCurrent += aPath[p] + "/";
    } // next (p)
  } // mkdirsFTP

  // ----------------------------------------------------------

  /**
   * <p>Create a complete directory branch.</p>
   * @param sFullURI Full path of directory to create,
   * ej. file:///tmp/uploads/binaries/images
   * ej. ftp://ftpserver/tmp/uploads/binaries/images
   * @throws Exception
   * @throws IOException
   */

  public boolean mkdirs (String sFullURI) throws Exception,IOException {
    boolean bFTPSession = false;
    String sCmd;

    if (DebugFile.trace) {
      DebugFile.writeln("Begin FileSystem.mkdirs(" + sFullURI + ")");
      DebugFile.incIdent();
    }

    File oFile;
    FTPClient oFTPC = null;
    boolean bRetVal = false;
    String sFullPath = sFullURI.substring(7);

    // Assume file protocol by default
    if (!sFullURI.startsWith("file://") && !sFullURI.startsWith("ftp://"))
      sFullURI = "file://" + sFullURI;

    if (sFullURI.startsWith("file://")) {
      switch (OS) {
        case OS_PUREJAVA:
          oFile = new File(sFullPath);
          if (DebugFile.trace) DebugFile.writeln("File.mkdirs(" + sFullPath + ")");
          bRetVal = oFile.mkdirs();
          oFile = null;
          break;
        case OS_UNIX:
          if (DebugFile.trace) DebugFile.writeln("mkdir -p \"" + sFullPath + "\"");
          sCmd = "mkdir -p \"" + sFullPath + "\"";
          oRunner.exec(sCmd);
          break;
        case OS_WINDOWS:
          if (DebugFile.trace) DebugFile.writeln("md \"" + sFullPath + "\"");
          sCmd = "md \"" + sFullPath + "\"";
          oRunner.exec(sCmd);
          break;
      }
    }
    else if (sFullURI.startsWith("ftp://")) {
      if (!sFullURI.endsWith("/")) sFullURI += "/";
      splitURI(sFullURI);

      try {
        if (DebugFile.trace) DebugFile.writeln("new FTPClient(" + sHost + ")");
        oFTPC = new FTPClient(sHost);

        if (DebugFile.trace) DebugFile.writeln("FTPClient.login(" + sUsr + "," + sPwd + ")");
        oFTPC.login(sUsr, sPwd);
        bFTPSession = true;

        if (DebugFile.trace) DebugFile.writeln("FileSystem.mkdirsFTP(" + sPath + ")");

        mkdirsFTP(oFTPC, sPath);
        bRetVal = true;
      }
      catch (FTPException ftpe) {
        throw new IOException(ftpe.getMessage());
      }
      finally {
        if (bFTPSession) oFTPC.quit();
      }
    } // fi(sFullURI.startsWith(...))

    if (DebugFile.trace) {
      DebugFile.decIdent();
      DebugFile.writeln("End FileSystem.mkdirs() : " + String.valueOf(bRetVal));
    }

    return bRetVal;
  } // mkdirs()

  // ----------------------------------------------------------

  /**
   * <p>Convert a text file from one character set to another</p>
   * The input file is overwritten.
   * @param sFilePath File Path
   * @param sOldCharset Original file character set
   * @param sNewCharset New character set
   * @throws FileNotFoundException
   * @throws IOException
   * @throws UnsupportedEncodingException
   */
  public static void convert (String sFilePath, String sOldCharset, String sNewCharset)
    throws FileNotFoundException, IOException,UnsupportedEncodingException {

    if (DebugFile.trace) {
      DebugFile.writeln("Begin FileSystem.convert(" + sFilePath + "," + sOldCharset + "," + sNewCharset + ")");
      DebugFile.incIdent();
    }

    final int iBufferSize = 8192;
    int iReaded;
    char[] cBuffer = new char[iBufferSize];

    FileInputStream oFileStrm = new FileInputStream(sFilePath);

    BufferedInputStream oInStrm = new BufferedInputStream(oFileStrm);

    InputStreamReader oStrm = new InputStreamReader(oInStrm, sOldCharset);

    FileOutputStream oOutStrm = new FileOutputStream(sFilePath + ".tmp");

    while (true) {
      iReaded = oStrm.read(cBuffer,0,iBufferSize);

      if (-1==iReaded) break;

      oOutStrm.write(new String(cBuffer,0,iReaded).getBytes(sNewCharset));
    }

    oOutStrm.close();

    oStrm.close();
    oInStrm.close();
    oFileStrm.close();

    File oOld = new File(sFilePath);
    oOld.delete();

    File oNew = new File(sFilePath + ".tmp");
    oNew.renameTo(oOld);

    if (DebugFile.trace) {
      DebugFile.decIdent();
      DebugFile.writeln("End FileSystem.convert()");
    }

  } // convert

  // ----------------------------------------------------------

  /**
   * Detect file encoding
   * @param oFile File
   * @param sDefault String Character encoding to be returned if no clear character encoding was identified
   * @return String UTF-16LE, UTF-16BE or UTF-8
   * @throws FileNotFoundException
   * @throws IOException
   * @since 3.1
   */
  public static String detectEncoding(File oFile, String sDefault)
    throws FileNotFoundException, IOException {

	if (!oFile.exists())
	  throw new FileNotFoundException("FileSystem.detectEncoding("+oFile.getPath()+","+sDefault+")");

	return new CharacterSetDetector().detect(oFile, sDefault);

  } // detectEncoding

  // ----------------------------------------------------------

  /**
   * Detect file encoding
   * @param sFilePath File Path including protocol. Like "file:///tmp/myfile.txt" or "ftp://myhost:21/dir/myfile.txt"
   * @param sDefault String Character encoding to be returned if no clear character encoding was identified
   * @return String UTF-16LE, UTF-16BE or UTF-8
   * @throws FileNotFoundException
   * @throws IOException
   * @since 3.1
   */
  public String detectEncoding(String sFilePath, String sDefault)
    throws FileNotFoundException, IOException, FTPException {
    byte[] byBuffer = readfilebin(sFilePath);
    if (null==byBuffer) return sDefault;
    if (byBuffer.length==0) return sDefault;
	ByteArrayInputStream oInStrm = new ByteArrayInputStream(readfilebin(sFilePath));
    String sEncoding = new CharacterSetDetector().detect(oInStrm, sDefault);
	oInStrm.close();
	return sEncoding;
  } // detectEncoding

  // ----------------------------------------------------------

  /**
   * <p>Read a text file and returns a character array with it</p>
   * Enconding is UTF-8 by default
   * @param sFilePath Full path of file to be readed. Like "file:///tmp/myfile.txt" or "ftp://myhost:21/dir/myfile.txt"
   * @return character array with full contents of file
   * @throws FileNotFoundException
   * @throws IOException
   * @throws OutOfMemoryError
   * @throws FTPException
   */
  public static char[] readfile (String sFilePath)
    throws FileNotFoundException, IOException, OutOfMemoryError, FTPException {

    if (DebugFile.trace) {
      DebugFile.writeln("Begin FileSystem.readfile(" + sFilePath + ")");
      DebugFile.incIdent();
    }

    char[] aBuffer;
    String sLower = sFilePath.toLowerCase();

    if (sLower.startsWith("file://")) sFilePath = sFilePath.substring(7);

    if (sLower.startsWith("http://") || sLower.startsWith("https://") || sLower.startsWith("ftp://")) {
      aBuffer = new FileSystem().readfilestr(sFilePath, "UTF-8").toCharArray();
    }
    else {
      File oFile = new File(sFilePath);

      aBuffer = new char[(int) oFile.length()];

      FileReader oReader = new FileReader(oFile);

      oReader.read(aBuffer);

      oReader.close();

      oReader = null;
      oFile = null;
    }

    if (DebugFile.trace) {
      DebugFile.decIdent();
      DebugFile.writeln("End FileSystem.readfile() : " + String.valueOf(aBuffer.length));
    }

    return aBuffer;
  } // readfile

  // ----------------------------------------------------------

  /**
   * <p>Read a text file and returns a character array with it</p>
   * @param sFilePath Full path of file to be readed. Like "file:///tmp/myfile.txt" or "ftp://myhost:21/dir/myfile.txt"
   * @param sCharSet Encoding character set name
   * @return character array with full contents of file
   * @throws FileNotFoundException
   * @throws IOException
   * @throws OutOfMemoryError
   * @throws FTPException
   */
  public static char[] readfile (String sFilePath, String sCharSet)
    throws FileNotFoundException, IOException, OutOfMemoryError, FTPException {

    if (DebugFile.trace) {
      DebugFile.writeln("Begin FileSystem.readfile(" + sFilePath + ", charset=" + sCharSet + ")");
      DebugFile.incIdent();
    }

    char[] aBuffer;
    String sLower = sFilePath.toLowerCase();

    if (sLower.startsWith("file://")) sFilePath = sFilePath.substring(7);

    aBuffer = new FileSystem().readfilestr(sFilePath, sCharSet).toCharArray();

    if (DebugFile.trace) {
      DebugFile.decIdent();
      DebugFile.writeln("End FileSystem.readfile() : " + String.valueOf(aBuffer.length));
    }

    return aBuffer;
  } // readfile

  // ----------------------------------------------------------

  /**
   * <p>Read a binary file into a byte array</p>
   * @param sFilePath Full path of file to be readed. Like "file:///tmp/myfile.txt" or "ftp://myhost:21/dir/myfile.txt"
   * @return byte array with full contents of file
   * @throws FileNotFoundException
   * @throws IOException
   * @throws OutOfMemoryError
   * @throws MalformedURLException
   * @throws FTPException
   */
  public byte[] readfilebin (String sFilePath)
    throws MalformedURLException, FTPException, FileNotFoundException, IOException, OutOfMemoryError {

    if (DebugFile.trace) {
      DebugFile.writeln("Begin FileSystem.readfilebin(" + sFilePath + ")");
      DebugFile.incIdent();
    }

    byte[] aRetVal;
    String sLower = sFilePath.toLowerCase();

    if (sLower.startsWith("file://")) sFilePath = sFilePath.substring(7);

    if (sLower.startsWith("http://") || sLower.startsWith("https://")) {

      URL oUrl = new URL(sFilePath);

	  if (user().equals("anonymous") || user().length()==0) {
        ByteArrayOutputStream oStrm = new ByteArrayOutputStream();
		if (DebugFile.trace) DebugFile.writeln("new DataHandler(" + oUrl.toString() + ")");
        DataHandler oHndlr = new DataHandler(oUrl);
        oHndlr.writeTo(oStrm);
        aRetVal = oStrm.toByteArray();
        oStrm.close();
      } else {
	    if (null==oHttpCli) {
	      oHttpCli = new DefaultHttpClient();
	    } // fi (oHttpCli)

		oHttpCli.getCredentialsProvider().setCredentials(new AuthScope(oUrl.getHost(), AuthScope.ANY_PORT, realm()), 
														 new UsernamePasswordCredentials(user(), password()));	      
	    HttpGet oGet = null;
	    try {
	      oGet = new HttpGet(sFilePath);		  
	      HttpResponse oResp = oHttpCli.execute(oGet);
	      HttpEntity oEnty = oResp.getEntity();
	      int nLen = (int) oEnty.getContentLength();
	      if (nLen>0) {
	        aRetVal = new byte[nLen];
	        InputStream oBody = oEnty.getContent();
			oBody.read(aRetVal,0,nLen);
			oBody.close();	        
	      } else {
	      	aRetVal = null;
	      }// fi	      
		} finally {
          oHttpCli.getConnectionManager().shutdown();
          oHttpCli = null;
        }
      } // fi (user is anonymous)
    }
    else if (sLower.startsWith("ftp://")) {

      FTPClient oFTPC = null;
      boolean bFTPSession = false;

      splitURI (sFilePath);

      try {

        if (DebugFile.trace) DebugFile.writeln("new FTPClient(" + sHost + ")");
        oFTPC = new FTPClient(sHost);

        if (DebugFile.trace) DebugFile.writeln("FTPClient.login(" + sUsr + "," + sPwd + ")");
        oFTPC.login(sUsr, sPwd);

        bFTPSession = true;

        if (DebugFile.trace) DebugFile.writeln("FTPClient.chdir(" + sPath + ")");
        oFTPC.chdir(sPath);

        ByteArrayOutputStream oStrm = new ByteArrayOutputStream();

        oFTPC.setType(FTPTransferType.BINARY);

        if (DebugFile.trace) DebugFile.writeln("FTPClient.get(" + sPath + sFile + "," + sFile + ",false)");
        oFTPC.get(oStrm, sFile);

        aRetVal = oStrm.toByteArray();

        oStrm.close();
      } catch (FTPException ftpe) {
        throw new FTPException(ftpe.getMessage());
      }
      finally {
        if (DebugFile.trace) DebugFile.writeln("FTPClient.quit()");
        if (bFTPSession) oFTPC.quit();
      }

    }
    else {

      File oFile = new File(sFilePath);
      int iFLen = (int) oFile.length();

      BufferedInputStream oBfStrm;
      FileInputStream oInStrm;

      if (iFLen>0) {
        aRetVal = new byte[iFLen];
        oInStrm = new FileInputStream(oFile);
        oBfStrm = new BufferedInputStream(oInStrm, iFLen);

        int iReaded = oBfStrm.read(aRetVal, 0, iFLen);

        oBfStrm.close();
        oInStrm.close();

        oInStrm = null;
        oFile = null;

      }
      else
        aRetVal = null;
    }

    if (DebugFile.trace) {
      DebugFile.decIdent();
      DebugFile.writeln("End FileSystem.readfilebin()");
    }

    return aRetVal;
  } // readfilebin

  // ----------------------------------------------------------

  /**
   * <p>Read a text file into a String</p>
   * @param sFilePath Full path of file to be readed. Like "file:///tmp/myfile.txt" or "ftp://myhost:21/dir/myfile.txt"
   * @param sEncoding Text Encoding for file {UTF-8, ISO-8859-1, ...}<BR>
   * if <b>null</b> then if first two bytes of file are FF FE then UTF-8 will be assumed<BR>
   * else ISO-8859-1 will be assumed.
   * @return String with full contents of file
   * @throws FileNotFoundException
   * @throws IOException
   * @throws OutOfMemoryError
   * @throws MalformedURLException
   * @throws FTPException
   */
  public String readfilestr (String sFilePath, String sEncoding)
    throws MalformedURLException, FTPException, FileNotFoundException, IOException, OutOfMemoryError {

    if (DebugFile.trace) {
      DebugFile.writeln("Begin FileSystem.readfilestr(" + sFilePath + "," + sEncoding + ")");
      DebugFile.incIdent();
    }

    String sRetVal;
    String sLower = sFilePath.toLowerCase();

    if (sLower.startsWith("file://")) sFilePath = sFilePath.substring(7);

    if (sLower.startsWith("http://") || sLower.startsWith("https://")) {

      URL oUrl = new URL(sFilePath);
	  if (user().equals("anonymous") || user().length()==0) {
        ByteArrayOutputStream oStrm = new ByteArrayOutputStream();
        DataHandler oHndlr = new DataHandler(oUrl);
        oHndlr.writeTo(oStrm);
        sRetVal = oStrm.toString(sEncoding);
        oStrm.close();
	  } else {
	    if (null==oHttpCli) {	    	
	      oHttpCli = new DefaultHttpClient();
	    } // fi (oHttpCli)
		oHttpCli.getCredentialsProvider().setCredentials(new AuthScope(oUrl.getHost(), AuthScope.ANY_PORT, realm()), 
														 new UsernamePasswordCredentials(user(), password()));	      
	    HttpGet oGet = null;
	    try {

	      oGet = new HttpGet(sFilePath);		  
	      HttpResponse oResp = oHttpCli.execute(oGet);
	      HttpEntity oEnty = oResp.getEntity();
	      int nLen = (int) oEnty.getContentLength();
	      if (nLen>0) {
	        byte[] aRetVal = new byte[nLen];
	        InputStream oBody = oEnty.getContent();
			oBody.read(aRetVal,0,nLen);
			oBody.close();
			sRetVal = new String(aRetVal, sEncoding);
	      } else {
	      	sRetVal = "";
	      }// fi	      
		} finally {
          oHttpCli.getConnectionManager().shutdown();
          oHttpCli = null;
        }
	  } // fi
    }
    else if (sLower.startsWith("ftp://")) {

      FTPClient oFTPC = null;
      boolean bFTPSession = false;

      splitURI (sFilePath);

      try {

        if (DebugFile.trace) DebugFile.writeln("new FTPClient(" + sHost + ")");
        oFTPC = new FTPClient(sHost);

        if (DebugFile.trace) DebugFile.writeln("FTPClient.login(" + sUsr + "," + sPwd + ")");
        oFTPC.login(sUsr, sPwd);

        bFTPSession = true;

        if (DebugFile.trace) DebugFile.writeln("FTPClient.chdir(" + sPath + ")");
        oFTPC.chdir(sPath);

        ByteArrayOutputStream oStrm = new ByteArrayOutputStream();

        oFTPC.setType(FTPTransferType.BINARY);

        if (DebugFile.trace) DebugFile.writeln("FTPClient.get(" + sPath + sFile + "," + sFile + ",false)");
        oFTPC.get(oStrm, sFile);

        sRetVal = oStrm.toString(sEncoding);

        oStrm.close();
      } catch (FTPException ftpe) {
        throw new FTPException(ftpe.getMessage());
      }
      finally {
        if (DebugFile.trace) DebugFile.writeln("FTPClient.quit()");
        try { if (bFTPSession) oFTPC.quit(); } catch (Exception ignore) { }
      }
    }
    else {

      File oFile = new File(sFilePath);
      int iFLen = (int) oFile.length();
      if (iFLen>0) {
        byte byBuffer[] = new byte[3];
        char aBuffer[] = new char[iFLen];
        BufferedInputStream oBfStrm;
        FileInputStream oInStrm;
        InputStreamReader oReader;

        if (sEncoding==null) {
          oInStrm = new FileInputStream(oFile);
          oBfStrm = new BufferedInputStream(oInStrm, iFLen);

          sEncoding = new CharacterSetDetector().detect(oBfStrm,"ISO-8859-1");

          if (DebugFile.trace) DebugFile.writeln("encoding is " + sEncoding);

          oBfStrm.close();
          oInStrm.close();
        } // fi

        oInStrm = new FileInputStream(oFile);
        oBfStrm = new BufferedInputStream(oInStrm, iFLen);

        oReader = new InputStreamReader(oBfStrm, sEncoding);

        int iReaded = oReader.read(aBuffer, 0, iFLen);

        // Skip FF FE character mark for Unidode files
        int iSkip = ( (int) aBuffer[0] == 65279 || (int) aBuffer[0] == 65533 || (int) aBuffer[0] == 65534 ? 1 : 0);

        oReader.close();
        oBfStrm.close();
        oInStrm.close();

        oReader = null;
        oInStrm = null;
        oFile = null;

        sRetVal = new String(aBuffer, iSkip, iReaded - iSkip);
      }
      else
        sRetVal = "";
    } // fi (iFLen>0)

    if (DebugFile.trace) {
      DebugFile.decIdent();
      DebugFile.writeln("End FileSystem.readfilestr() : " + String.valueOf(sRetVal.length()));
    }

    return sRetVal;
  } // readfilestr

  // ----------------------------------------------------------

  /**
   * Write a String to a text file using given encoding
   * @param sFilePath Full file path. For example "file:///tmp/myfile.txt" or "ftp://localhost:21/tmp/myfile.txt"
   * @param sText String to be written
   * @param sEncoding Encoding to be used
   * see <a href="http://java.sun.com/j2se/1.4.2/docs/guide/intl/encoding.doc.html">Java Supported Encodings</a>
   * @throws IOException
   * @throws OutOfMemoryError
   */
  public void writefilestr (String sFilePath, String sText, String sEncoding)
    throws IOException, OutOfMemoryError {

    if (DebugFile.trace) {
      DebugFile.writeln("Begin FileSystem.writefilestr(" + sFilePath + ", ..., " + sEncoding + ")");
      DebugFile.incIdent();
    }

    String sLower = sFilePath.toLowerCase();

    if (sLower.startsWith("file://")) sFilePath = sFilePath.substring(7);

    if (sLower.startsWith("ftp://")) {

      FTPClient oFTPC = null;
      boolean bFTPSession = false;

      splitURI(sFilePath);

      try {

        if (DebugFile.trace) DebugFile.writeln("new FTPClient(" + sHost + ")");
        oFTPC = new FTPClient(sHost);

        if (DebugFile.trace) DebugFile.writeln("FTPClient.login(" + sUsr + "," +
                                               sPwd + ")");
        oFTPC.login(sUsr, sPwd);

        bFTPSession = true;

        if (DebugFile.trace) DebugFile.writeln("FTPClient.chdir(" + sPath + ")");
        oFTPC.chdir(sPath);

        oFTPC.setType(FTPTransferType.BINARY);
        if (DebugFile.trace) DebugFile.writeln("FTPClient.put(byte[], " + sFile + ")");
        oFTPC.put(sText.getBytes(sEncoding), sFile);
      }
      catch (FTPException ftpe) {
        throw new IOException(ftpe.getMessage());
      }
      finally {
        if (DebugFile.trace) DebugFile.writeln("FTPClient.quit()");
        try { if (bFTPSession) oFTPC.quit(); } catch (Exception ignore) { }
      }
    }
    else {
      FileOutputStream oOutStrm = new FileOutputStream(sFilePath);

      if (sText.length() > 0) {
          BufferedOutputStream oBFStrm = new BufferedOutputStream(oOutStrm,
              sText.length());
          OutputStreamWriter oWriter = new OutputStreamWriter(oBFStrm, sEncoding);
          oWriter.write(sText);
          oWriter.close();
          oBFStrm.close();
      } // fi (sText!="")

      oOutStrm.close();
    }
    if (DebugFile.trace) {
      DebugFile.decIdent();
      DebugFile.writeln("End FileSystem.writefilestr()");
    }
  } // writefilestr

  // ----------------------------------------------------------

  /**
   * Write a byte array to a text file
   * @param sFilePath Full file path. For example "file:///tmp/myfile.bin" or "ftp://localhost:21/tmp/myfile.bin"
   * @param aBytes Bytes to be written
   * @throws IOException
   * @since 3.0
   */
  public void writefilebin (String sFilePath, byte[] aBytes)
    throws IOException {

    if (DebugFile.trace) {
      DebugFile.writeln("Begin FileSystem.writefilebin(" + sFilePath + ", ...)");
      DebugFile.incIdent();
    }

    String sLower = sFilePath.toLowerCase();

    if (sLower.startsWith("file://")) sFilePath = sFilePath.substring(7);

    if (sLower.startsWith("ftp://")) {

      FTPClient oFTPC = null;
      boolean bFTPSession = false;

      splitURI(sFilePath);

      try {

        if (DebugFile.trace) DebugFile.writeln("new FTPClient(" + sHost + ")");
        oFTPC = new FTPClient(sHost);

        if (DebugFile.trace) DebugFile.writeln("FTPClient.login(" + sUsr + "," +
                                               sPwd + ")");
        oFTPC.login(sUsr, sPwd);

        bFTPSession = true;

        if (DebugFile.trace) DebugFile.writeln("FTPClient.chdir(" + sPath + ")");
        oFTPC.chdir(sPath);

        oFTPC.setType(FTPTransferType.BINARY);
        if (DebugFile.trace) DebugFile.writeln("FTPClient.put(byte[], " + sFile + ")");
        oFTPC.put(aBytes, sFile);
      }
      catch (FTPException ftpe) {
        throw new IOException(ftpe.getMessage());
      }
      finally {
        if (DebugFile.trace) DebugFile.writeln("FTPClient.quit()");
        try { if (bFTPSession) oFTPC.quit(); } catch (Exception ignore) { }
      }
    }
    else {
      FileOutputStream oOutStrm = new FileOutputStream(sFilePath);
      oOutStrm.write(aBytes);
      oOutStrm.close();
    }
    if (DebugFile.trace) {
      DebugFile.decIdent();
      DebugFile.writeln("End FileSystem.writefilebin()");
    }
  } // writefilebin

  // ----------------------------------------------------------

  /**
   * Read a serializable object from a text file
   * @param sFilePath Full file path. For example "file:///tmp/myfile.bin" or "ftp://localhost:21/tmp/myfile.bin"
   * @throws MalformedURLException if sFilePath does not begin with file://or ftp://
   * @throws ClassNotFoundException
   * @throws FileNotFoundException
   * @throws IOException
   * @since 4.0
   */

  public Object readfileobj (String sFilePath)
    throws MalformedURLException, FileNotFoundException, IOException, FTPException, ClassNotFoundException {
	Object oRetVal;
	ObjectInputStream oObjStrm;
	
    String sLower = sFilePath.toLowerCase();

    if (sLower.startsWith("file://")) {
      sFilePath = sFilePath.substring(7);

 	  FileInputStream oInStrm= new FileInputStream(sFilePath);
	  oObjStrm = new ObjectInputStream(oInStrm);
	  oRetVal = oObjStrm.readObject();
	  oObjStrm.close();
	  oInStrm.close();
    }  else if (sLower.startsWith("ftp://")) {
       byte[] aFileBytes = readfilebin(sFilePath);
       ByteArrayInputStream oBteStrm = new ByteArrayInputStream(aFileBytes);
       oObjStrm = new ObjectInputStream(oBteStrm);
	   oRetVal = oObjStrm.readObject();
	   oObjStrm.close();
	   oBteStrm.close();
    } else {
      throw new MalformedURLException("FileSystem.readfileobj("+sFilePath+") File protocol must begin with file:// or ftp://");
    }
    return oRetVal;
  } // readfileobj

  // ----------------------------------------------------------

  /**
   * Write a serializable object to a text file
   * @param sFilePath Full file path. For example "file:///tmp/myfile.bin" or "ftp://localhost:21/tmp/myfile.bin"
   * @param oObj Serializable object to be written
   * @throws IOException
   * @since 4.0
   */

  public void writefileobj (String sFilePath, Serializable oObj)
    throws IOException {
	ObjectOutputStream oObjStrm;
	
    String sLower = sFilePath.toLowerCase();

    if (sLower.startsWith("file://")) {
      sFilePath = sFilePath.substring(7);

	  FileOutputStream oOutStrm = new FileOutputStream(sFilePath);
      oObjStrm = new ObjectOutputStream(oOutStrm);
	  oObjStrm.writeObject(oObj);
	  oObjStrm.close();
	  oOutStrm.close();

    } else if (sLower.startsWith("ftp://")) {
      ByteArrayOutputStream oBteStrm = new ByteArrayOutputStream();
      oObjStrm = new ObjectOutputStream(oBteStrm);
	  oObjStrm.writeObject(oObj);
	  oObjStrm.close();
	  writefilebin(sFilePath,oBteStrm.toByteArray());
	  oBteStrm.close();
    }
  } // writefileobj

  // ----------------------------------------------------------

  /**
   * Download an HTML page and all its referenced files into a ZIP
   * @param sBasePath String Base path for page and its referenced files
   * @param sFilePath String File path from sBasePath
   * @param oOutStrm OutputStream where ZIP is written
   * @param sDefaultEncoding Character encoding of file to be downloaded
   * @throws IOException
   * @since 7.0
   */
  public void downloadhtmlpage (String sBasePath, String sFilePath, OutputStream oOutStrm, String sDefaultEncoding)
    throws IOException {

	if (DebugFile.trace) {
	  DebugFile.writeln("Begin FileSystem.downloadhtmlpage("+sBasePath+","+sFilePath+",[OutputStream],"+sDefaultEncoding+")");
	  DebugFile.incIdent();
	}
	
    String sEncoding = sDefaultEncoding;
	String sBaseHref = "";
	boolean bAutoDetectEncoding = (sDefaultEncoding==null);
	TreeSet<String> oFiles = new TreeSet<String>();
	TreeSet<String> oEntries = new TreeSet<String>();
    Perl5Matcher oMatcher = new Perl5Matcher();
    Perl5Matcher oReplacer = new Perl5Matcher();
    Perl5Compiler oCompiler = new Perl5Compiler();

	if (sDefaultEncoding==null) sDefaultEncoding = "ASCII";
	
    try {
      String sHtml = readfilestr(sBasePath+sFilePath,sDefaultEncoding);

	  if (null==sHtml) {
	    if (DebugFile.trace) {
	      DebugFile.writeln("Could not read file "+sBasePath+sFilePath);
	      DebugFile.decIdent();
	      throw new IOException("Could not read file "+sBasePath+sFilePath);
	    }
	  }

	  if (DebugFile.trace) {
	    DebugFile.writeln(String.valueOf(sHtml.length())+" characters readed from file "+sBasePath+sFilePath);
	  }
	  
	  if (bAutoDetectEncoding) {
      if (oMatcher.contains(sHtml, oCompiler.compile("<meta\\x20+http-equiv=(\"|')?Content-Type(\"|')?\\x20+content=(\"|')?text/html;\\x20+charset=(\\w|-){3,32}(\"|')?>",Perl5Compiler.CASE_INSENSITIVE_MASK))) {
        if (DebugFile.trace) DebugFile.writeln("<meta http-equiv> tag found");
        String sHttpEquiv = oMatcher.getMatch().toString();
        int iCharset = Gadgets.indexOfIgnoreCase(sHttpEquiv,"charset=");
        if (iCharset>0) {
          int iQuoute = sHttpEquiv.indexOf('"', iCharset);
          if (iQuoute<0) iQuoute = sHttpEquiv.indexOf((char)39, iCharset);
          if (iQuoute<0) {
            bAutoDetectEncoding = true;
          } else {
            sEncoding = sHttpEquiv.substring(iCharset+8, iQuoute);
        	if (DebugFile.trace) DebugFile.writeln("setting charset encoding to "+sEncoding);
            bAutoDetectEncoding = false;
            try {
          	  byte[] aTest = new String("Test").getBytes(sEncoding);
            } catch (UnsupportedEncodingException uex) {
              bAutoDetectEncoding = true;
            }
          }
        } else {
          bAutoDetectEncoding = true;
        }
      } else {
        bAutoDetectEncoding = true;    	
      } }
    
      if (bAutoDetectEncoding) {
        if (DebugFile.trace) DebugFile.writeln("Autodetecting encoding");
      	ByteArrayInputStream oHtmlStrm = new ByteArrayInputStream(sHtml.getBytes(sDefaultEncoding));
        sEncoding = new CharacterSetDetector().detect(oHtmlStrm,sDefaultEncoding);
        oHtmlStrm.close();
        if (DebugFile.trace) DebugFile.writeln("Encoding set to "+sEncoding);
      }
    	
      Pattern oPattern = oCompiler.compile("<base(\\x20)+href=(\"|')?([^'\"\\r\\n]+)(\"|')?(\\x20)*/?>", Perl5Compiler.CASE_INSENSITIVE_MASK);
	  if (oMatcher.contains(sHtml, oPattern)) {
	    sBaseHref = Gadgets.chomp(oMatcher.getMatch().group(3),"/");
	    if (DebugFile.trace) DebugFile.writeln("<base href="+sBaseHref+">");
	  }
	
      PatternMatcherInput oMatchInput = new PatternMatcherInput(sHtml);
	  oPattern = oCompiler.compile("\\x20(src=|background=|background-image:url\\x28)(\"|')?([^'\"\\r\\n]+)(\"|')?(\\x20|\\x29|/|>)", Perl5Compiler.CASE_INSENSITIVE_MASK);
	  StringSubstitution oSrcSubs = new StringSubstitution();
	  int nMatches = 0;
	  while (oMatcher.contains(oMatchInput, oPattern)) {
	    nMatches++;
	    String sMatch = oMatcher.getMatch().toString();
	    String sAttr = oMatcher.getMatch().group(1);
	    String sQuo = oMatcher.getMatch().group(2);
	    if (sQuo==null) sQuo = "";
	    String sSrc = oMatcher.getMatch().group(3);
	    if (DebugFile.trace) DebugFile.writeln("Source file found at "+sSrc);
	    String sEnd = oMatcher.getMatch().group(5);
	    if (!oFiles.contains(sSrc)) oFiles.add(sSrc);
	    String sFilename = sSrc.substring(sSrc.replace('\\','/').lastIndexOf('/')+1);
	    if (DebugFile.trace)
	      DebugFile.writeln("StringSubstitution.setSubstitution("+sMatch+" replace with "+sMatch.substring(0,sAttr.length()+1)+sQuo+sFilename+sQuo+sEnd+")");
	    oSrcSubs.setSubstitution(sMatch.substring(0,sAttr.length()+1)+sQuo+sFilename+sQuo+sEnd);
        sHtml = Util.substitute(oReplacer, oCompiler.compile(sMatch), oSrcSubs, sHtml, Util.SUBSTITUTE_ALL);
	  } //wend
	  
	  oMatchInput = new PatternMatcherInput(sHtml);
	  oPattern = oCompiler.compile("<link\\x20+(rel=(\"|')?stylesheet(\"|')?\\x20+)?(type=(\"|')?text/css(\"|')?\\x20+)?href=(\"|')?([^'\"\\r\\n]+)(\"|')?");
	  while (oMatcher.contains(oMatchInput, oPattern)) {
	    nMatches++;
	    String sMatch = oMatcher.getMatch().toString();
	    String sSrc = oMatcher.getMatch().group(8);
	    String sFilename = sSrc.substring(sSrc.replace('\\','/').lastIndexOf('/')+1);
	    if (!oFiles.contains(sSrc)) oFiles.add(sSrc);
	    if (DebugFile.trace)
	      DebugFile.writeln("StringSubstitution.setSubstitution("+sMatch+" replace with "+Gadgets.replace(sMatch, sSrc, sFilename)+")");
	    oSrcSubs.setSubstitution(Gadgets.replace(sMatch, sSrc, sFilename));
        sHtml = Util.substitute(oReplacer, oCompiler.compile(sMatch), oSrcSubs, sHtml);	   
	  } // wend	  
	  
	  if (DebugFile.trace) {
	  	DebugFile.writeln(String.valueOf(nMatches)+" matches found");
	    DebugFile.write("\n"+sHtml+"\n");
	  }

      ZipOutputStream oZOut = new ZipOutputStream(oOutStrm);
      String sLocalName = sFilePath.substring(sFilePath.replace('\\','/').lastIndexOf('/')+1);
	  int iDot = sLocalName.lastIndexOf('.');
	  if (iDot>0)
	  	sLocalName = Gadgets.ASCIIEncode(sLocalName.substring(0, iDot)).toLowerCase()+".html";
      else
      	sLocalName = Gadgets.ASCIIEncode(sLocalName).toLowerCase();
	  oEntries.add(sLocalName);
      if (DebugFile.trace) DebugFile.writeln("Putting entry "+sLocalName+" into ZIP");
	  oZOut.putNextEntry(new ZipEntry(sLocalName));
      StringBufferInputStream oHtml = new StringBufferInputStream(sHtml);
      new StreamPipe().between(oHtml, oZOut);
      oHtml.close();
      oZOut.closeEntry();

      for (String sName : oFiles) {
      	String sZipEntryName = sName.substring(sName.replace('\\','/').lastIndexOf('/')+1);
      	if (!oEntries.contains(sZipEntryName)) {
      	  oEntries.add(sZipEntryName);
          if (DebugFile.trace) DebugFile.writeln("Putting entry "+sZipEntryName+" into ZIP");
	      oZOut.putNextEntry(new ZipEntry(sZipEntryName));
          if (sName.startsWith("http://") || sName.startsWith("https://") || sName.startsWith("file://") || sBaseHref.length()>0) {
            try {
              new StreamPipe().between(new ByteArrayInputStream(readfilebin(sBaseHref+sName)), oZOut);
            } catch (IOException ioe) {
              if (DebugFile.trace) {
                DebugFile.decIdent();
                DebugFile.writeln("Could not download file "+sName);
              }
            }        
          } else {
            try {
              byte[] aFile = readfilebin(sBasePath+(sName.startsWith("/") ? sName.substring(1) : sName));
              if (null!=aFile) {
              	if (aFile.length>0)
                  new StreamPipe().between(new ByteArrayInputStream(aFile), oZOut);
              } else {
                DebugFile.writeln("Could not find file "+sBasePath+(sName.startsWith("/") ? sName.substring(1) : sName));
              }
            } catch (IOException ioe) {
              if (DebugFile.trace) {
			    DebugFile.decIdent();
                DebugFile.writeln("Could not download file "+sBasePath+(sName.startsWith("/") ? sName.substring(1) : sName));
              }
            }      	
          }
          oZOut.closeEntry();
      	} // fi (sName!=sLocalName)
      } // next
      oZOut.close();

    } catch (MalformedPatternException mpe) {
      
    } catch (FTPException ftpe) {
    	
    }

	if (DebugFile.trace) {
	  DebugFile.decIdent();
	  DebugFile.writeln("End FileSystem.downloadhtmlpage()");
	}
  } // downloadhtmlpage

  // ----------------------------------------------------------

  /**
   * Download an HTML page and all its referenced files into a ZIP
   * @param sBasePath String Base path for page and its referenced files
   * @param sFilePath String File path from sBasePath
   * @param oOutStrm OutputStream where ZIP is written
   * @throws IOException
   * @since 5.5
   */
  public void downloadhtmlpage (String sBasePath, String sFilePath, OutputStream oOutStrm) throws IOException {
    downloadhtmlpage (sBasePath, sFilePath, oOutStrm, null);
  }
  
  // ----------------------------------------------------------

  // ******************
  // Private variables

  private int OS;
  protected String SLASH;
  private Runtime oRunner;
  private String sUsr;
  private String sPwd;
  private String sSrv;
  private String sProtocol;
  private String sHost;
  private String sPort;
  private String sPath;
  private String sFile;
  private DefaultHttpClient oHttpCli;

  // ******************
  // Static values

  public static final int OS_PUREJAVA = 0;
  public static final int OS_UNIX = 1;
  public static final int OS_WINDOWS = 2;
}

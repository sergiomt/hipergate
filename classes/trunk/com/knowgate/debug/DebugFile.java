/*
  Copyright (C) 2003  Know Gate S.L. All rights reserved.
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

package com.knowgate.debug;

import java.util.Date;
import java.util.Properties;
import java.util.concurrent.ConcurrentHashMap;

import java.io.File;
import java.io.FileWriter;
import java.io.IOException;
import java.io.InputStream;

/**
 * <p>Write execution traces to a flat text file</p>
 * Traces are written to javatrc.txt file on the especified directory.<br>
 * By default /tmp/ on Unix and C:\WINNT\TEMP or C:\WINDOWS\TEMP on Windows.
 * @author Sergio Montoro Ten
 * @version 7.0
 */
public final class DebugFile {

  private static final String DEFAULT_TMP_LINUX = "/tmp/";
  private static final String DEFAULT_TMP_WIN32 = "C:\\TEMP\\Debug\\";

  private static String chomp(String sSource, String cEndsWith) {
  	return sSource.endsWith(cEndsWith) ? sSource : sSource + cEndsWith;
  } // chomp

  private static String getDebugPath() {
  	String sWin32DebugDir = DEFAULT_TMP_WIN32;
  	String sLinuxDebugDir = DEFAULT_TMP_LINUX;
    try {
      Class oThisClass = Class.forName("com.knowgate.debug.DebugFile");
	  InputStream oInStrm = oThisClass.getResourceAsStream("debugdir.cnf");
      if (oInStrm!=null) {
        Properties oProps = new Properties();
        oProps.load(oInStrm);
        sWin32DebugDir = oProps.getProperty("debugdir_win32",DEFAULT_TMP_WIN32);
        sLinuxDebugDir = oProps.getProperty("debugdir_linux",DEFAULT_TMP_LINUX);
        oInStrm.close();
      }
    } catch (ClassNotFoundException neverthrown) {}
      catch (IOException ignore) {}
    if (System.getProperty("os.name").startsWith("Windows"))
	  return sWin32DebugDir;
	else
	  return sLinuxDebugDir;
  } // getDebugPath
  
  /**
   * Set debug file path
   * @param sDebugFilePath Full path to file where debug traces will be written including directory and file name
   */
  public static void setFile(String sDebugFilePath) {
    sFilePath = sDebugFilePath;
  }

  /**
   * Get debug file path
   * @return If setFile() has not been called this method returns C:\\javatrc.txt
   * on Windows environments or /tmp/javatrc.txt on UNIX environments
   * @since v2.2 the behaviour of this method has changed and now reads Java
   * environment variable hipergate.debugdir for getting the directory where
   * javatrc.txt file is generated
   */
  public static String getFile() {
    if (null==sFilePath)
      sFilePath = chomp(System.getProperty("hipergate.debugdir", getDebugPath()),File.separator) + "javatrc.";
    return sFilePath+String.valueOf(Thread.currentThread().getId())+".txt";
  } // getFile()

  /**
   * Increment identation level
   * Maximum identation level is 80,
   * after reaching that limit
   * identation is automatically set to zero
   */
  public static void incIdent() {
    Long oThId = new Long (Thread.currentThread().getId());
	String sIdent = "";
	if (mIdent.containsKey(oThId)) {
	  sIdent = mIdent.get(oThId);
	  mIdent.remove(oThId);
      if (sIdent.length()>80) sIdent = "";
	  
	}
	mIdent.put(oThId, sIdent+"  ");
  } // incIdent()

  /**
   * Decrement identation level
   */

  public static void decIdent() {
    Long oThId = new Long (Thread.currentThread().getId());
	String sIdent = "";
	if (mIdent.containsKey(oThId)) {
	  sIdent = mIdent.get(oThId);
      if (sIdent.length()>2)
        sIdent = sIdent.substring(0,sIdent.length()-2);
      else
        sIdent = "";
	  mIdent.remove(oThId);
	} // fi
	mIdent.put(oThId, sIdent);
  }

  private static String getIdent() {
    Long oThId = new Long (Thread.currentThread().getId());
	String sIdent = "";
	if (mIdent.containsKey(oThId)) {
	  sIdent = mIdent.get(oThId);
	}
	return sIdent;
  } // getIdent()

  /**
   * <p>Write trace</p>
   * Traces are written to /tmp/javatrc.txt on UNIX systems or C:\WINNT\javatrc.txt on Windows
   */
  public static void write(char[] str) {
    FileWriter oDebugWriter;

    try {

      // Volcar las trazas de salida a una ubicación por defecto
      // según el sistema operativo sea Windows o UNIX

      switch (dumpTo) {
        case DUMP_TO_FILE:
          oDebugWriter = new FileWriter(getFile(), true);
          oDebugWriter.write(str);
          oDebugWriter.close();
          break;
        case DUMP_TO_STDOUT:
          System.out.print(str);
          break;
      }
    }
    catch (IOException e) {
      System.out.print(str);
    }
  }

  /**
   * <p>Write trace</p>
   * Traces are written to /tmp/javatrc.txt on UNIX systems or C:\WINNT\javatrc.txt on Windows
   */
  public static void write(String str) {
    FileWriter oDebugWriter;

    try {

      // Volcar las trazas de salida a una ubicación por defecto
      // según el sistema operativo sea Windows o UNIX

      switch (dumpTo) {
        case DUMP_TO_FILE:
          oDebugWriter = new FileWriter(getFile(), true);
          oDebugWriter.write(str);
          oDebugWriter.close();
          break;
        case DUMP_TO_STDOUT:
          System.out.print(str);
          break;
      }
    }
    catch (IOException e) {
      System.out.print(str);
    }
  }

  /**
   * Write trace and append line feed
   * @param str
   */
  public static void writeln(String str) {
    FileWriter oDebugWriter;
    Date dt = new Date(System.currentTimeMillis());

    try {

      // Volcar las trazas de salida a una ubicación por defecto
      // según el sistema operativo sea Windows o UNIX

      switch (dumpTo) {
        case DUMP_TO_FILE:
          oDebugWriter = new FileWriter(getFile(), true);
          oDebugWriter.write(String.valueOf(Thread.currentThread().getId())+" "+dt.toString()+" "+getIdent()+str+"\n");
          oDebugWriter.close();
          break;
        case DUMP_TO_STDOUT:
          System.out.print(String.valueOf(Thread.currentThread().getId())+" "+dt.toString()+getIdent()+str+"\n");
          break;
      }
    }
    catch (IOException e) {
      System.out.print(dt.toString()+getIdent()+str+"\n");
    }
  }

  /**
   * Write trace and append line feed
   * @param str
   */
  public static void writeln(char[] str) {
    FileWriter oDebugWriter;
    Date dt = new Date(System.currentTimeMillis());

    try {

      // Volcar las trazas de salida a una ubicación por defecto
      // según el sistema operativo sea Windows o UNIX

      switch (dumpTo) {
        case DUMP_TO_FILE:
          oDebugWriter = new FileWriter(getFile(), true);
          oDebugWriter.write(String.valueOf(Thread.currentThread().getId())+" "+dt.toString()+" "+getIdent()+new String(str)+"\n");
          oDebugWriter.close();
          break;
        case DUMP_TO_STDOUT:
          System.out.print(String.valueOf(Thread.currentThread().getId())+" "+dt.toString()+getIdent()+new String(str)+"\n");
          break;
      }
    }
    catch (IOException e) {
      System.out.print(dt.toString()+getIdent()+new String(str)+"\n");
    }
  } // write

  /**
   * Write stack trace for an exception to debug file
   * @param t Throwable
   */
  public static void writeStackTrace(Throwable t) {
    try {
      DebugFile.write(StackTraceUtil.getStackTrace(t));
    } catch (Exception ignore) {}
  }

  /**
   * This method is just an alias for DebugFile.writeln
   * @param str
   */
  public void debug(String str) {
    DebugFile.writeln(str);
  }

  public void debug(String str, Exception xcpt) {
    DebugFile.writeln(str);
    new ErrorHandler(xcpt);
  }


  public static void envinfo() throws java.security.AccessControlException {
    DebugFile.writeln(System.getProperty("java.vendor") + " Runtime Environment " + System.getProperty("java.version"));
    DebugFile.writeln(System.getProperty("java.vm.vendor") + " " + System.getProperty("java.vm.name") +  " " + System.getProperty("java.vm.version"));
    DebugFile.writeln(System.getProperty("os.name") + " " + System.getProperty("os.version") + " " + System.getProperty("os.arch"));
    DebugFile.writeln("JVM encoding " + (new java.io.OutputStreamWriter(new java.io.ByteArrayOutputStream()).getEncoding()));
    DebugFile.writeln("Debug tracing is " + (DebugFile.trace ? "on" : "off"));

    /*
    WINDOWS MILLENIUM
    -----------------
    java.vendor=Sun Microsystems Inc.
    java.version=1.3.1
    java.vm.vendor=Sun Microsystems Inc.
    java.vm.name=Java HotSpot(TM) Client VM
    java.vm.version=1.3.1-b24
    os.name=Windows Me
    os.version=4.90
    os.arch=x86

    ALPHA
    -----
    java.vendor=Compaq Computer Corp.
    java.version=1.2.2-8
    java.vm.vendor=Compaq Computer Corp.
    java.vm.name=Classic VM
    java.vm.version=1.2.2-8
    os.name=OSF1
    os.version=V4.0
    os.arch=alpha

    JSERVER
    -------
    java.vendor=Oracle Corporation
    java.version=1.2.1
    java.vm.vendor=Oracle Corporation
    java.vm.name=JServer VM
    java.vm.version=1.2.1
    os.name=Solaris
    os.version=V4.0
    os.arch=alpha
    */
  }

  public static void main(String[] argv) {
    System.out.println("Debug mode " + (trace ? "enabled" : "disabled"));
    System.out.println("Debug file " + getFile());
    System.out.println(System.getProperty("java.vendor") + " Runtime Environment " + System.getProperty("java.version"));
    System.out.println(System.getProperty("java.vm.vendor") + " " + System.getProperty("java.vm.name") +  " " + System.getProperty("java.vm.version"));
    System.out.println(System.getProperty("os.name") + " " + System.getProperty("os.version") + " " + System.getProperty("os.arch"));
    System.out.println("JVM encoding " + System.getProperty( "file.encoding"));
  }

  // Espacios de identación en cada línea de traza
  private static ConcurrentHashMap<Long,String> mIdent = new ConcurrentHashMap<Long,String>();
  private static String sFilePath;
  
  // **********************************************************
  // Esta variable controla si se volcarán trazas o no

  public static final short DUMP_TO_FILE = (short) 1;
  public static final short DUMP_TO_STDOUT = (short) 2;

  public static short dumpTo = DUMP_TO_FILE;

  /**
   * Activate/Deactivate trace output
   */
  public static final boolean trace = false;
  }

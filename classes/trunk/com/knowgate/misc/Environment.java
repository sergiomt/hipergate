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

package com.knowgate.misc;

import java.io.IOException;
import java.io.InputStream;
import java.io.StringBufferInputStream;
import java.io.FileNotFoundException;
import java.io.File;
import java.io.FileInputStream;

import java.lang.System;
import java.util.Properties;
import java.util.HashMap;
import java.util.Date;
import java.util.Set;
import java.text.SimpleDateFormat;

import com.knowgate.debug.*;

/**
 * <p>Reads and keeps in memory properties from .cnf initialization files.</p>
 * @author Sergio Montoro Ten
 * @version 5.0
 */

public class Environment {
  public static String DEFAULT_PROFILES_DIR = (System.getProperty("os.name").equals("Windows XP") ?		
		  "C:\\Windows\\" : (System.getProperty("os.name").startsWith("Windows") ? "C:\\WINNT\\" :
		  "/etc/"));

  private Environment() { }

  //-----------------------------------------------------------

  private static String getEnvironmentDirectory() {
    if (DEFAULT_PROFILES_DIR.equalsIgnoreCase("C:\\WINNT\\")) {
      File oWinDir = new File("C:\\WINNT");
      if (!oWinDir.exists()) {
        oWinDir = new File ("C:\\WINDOWS");
        if (oWinDir.exists()) {
          DEFAULT_PROFILES_DIR = "C:\\WINDOWS\\";
        }
        else {
          DEFAULT_PROFILES_DIR = getEnvVar("windir", getEnvVar("SystemRoot"));
        }
      }
    } // fi (DEFAULT_PROFILES_DIR=="C:\WINNT"
    return DEFAULT_PROFILES_DIR;
  }

  //-----------------------------------------------------------

  private static void readEnvVars() throws IllegalArgumentException {
    envVars = new Properties();
    Runtime oRT;
    Process oPT;
    InputStream oST;

    final int ENV_BUFFER_SIZE = 131072;

    try {
      if (System.getProperty("os.name").startsWith("Windows")) {

        if (DebugFile.trace) DebugFile.writeln ("Runtime.getRuntime()");

        oRT = Runtime.getRuntime();

        if (DebugFile.trace) DebugFile.writeln ("Runtime.exec(\"cmd.exe /cset\")");

        oPT = oRT.exec("cmd.exe /cset");

        oST = oPT.getInputStream();

        byte[] byBuffer = new byte[ENV_BUFFER_SIZE];

        int iReaded = oST.read (byBuffer, 0, ENV_BUFFER_SIZE);

        oST.close();

        oPT.destroy();

        oRT = null;

        // Double back slashes
        byte[] byEnvVars = new byte[ENV_BUFFER_SIZE+4096];
        int iEnvLength = 0;

        for (int i=0; i<iReaded; i++) {
          byEnvVars[iEnvLength++] = byBuffer[i];
          if (92==byBuffer[i])
            byEnvVars[iEnvLength++] = byBuffer[i];
        } // next

        byBuffer = null;

        if (DebugFile.trace) DebugFile.writeln (new String(byEnvVars, 0, iEnvLength));

        envVars.load (new StringBufferInputStream(new String(byEnvVars, 0, iEnvLength)));

      }
      else {

        if (DebugFile.trace) DebugFile.writeln ("Runtime.getRuntime()");

        oRT = Runtime.getRuntime();

        if (DebugFile.trace) DebugFile.writeln ("Runtime.exec(\"/usr/bin/env\")");

        oPT = oRT.exec("/usr/bin/env");

        oST = oPT.getInputStream();

        if (DebugFile.trace) DebugFile.writeln ("Properties.load(Process.getInputStream())");

        envVars.load(oST);

        oST.close();

        oPT.destroy();

        oRT = null;
      }
    }
    catch (IOException ioe) {
      if (DebugFile.trace) DebugFile.writeln ("Runtime.getRuntime().exec(...) IOException " + ioe.getMessage());
    }
    catch (NullPointerException npe) {
      if (DebugFile.trace) DebugFile.writeln ("Runtime.getRuntime().exec(...) NullPointerException " + npe.getMessage());
    }
    finally {
      if (null==envVars.getProperty("KNOWGATE_PROFILES")) {
        if (DebugFile.trace) DebugFile.writeln ("KNOWGATE_PROFILES environment variable not found setting default to "+getEnvironmentDirectory());

        envVars.setProperty("KNOWGATE_PROFILES", getEnvironmentDirectory());
      }
    }
  } // readEnvVars

  //-----------------------------------------------------------

  /**
   * <p>Get value for an environment variable.</p>
   * This is not a Pure Java method since it uses the Runtime obeject for calling
   * OS specific shell commands.
   * @param sVarName Name of the variable to be readed.
   * @return Value of variable or <b>null</b> if no environment variable with such name was found.
   * @throws IllegalArgumentException If there is a Malformed \\uxxxx encoding or any other type of intrinsic error at the environment variables values
   */

  public static String getEnvVar(String sVarName)
    throws IllegalArgumentException {

    if (envVars==null) readEnvVars();

    return envVars.getProperty(sVarName);
  } // getEnvVar()

  //-----------------------------------------------------------

  /**
   * <p>Get value for an environment variable.</p>
   * This is not a Pure Java method since it uses the Runtime object for calling
   * OS specific shell commands.
   * @param sVarName Name of the variable to be readed.
   * @return Value of variable or sDefault if no environment variable with such name was found.
   */

  public static String getEnvVar(String sVarName, String sDefault)
    throws IllegalArgumentException {
    if (envVars==null) readEnvVars();

    String sRetVal = envVars.getProperty(sVarName);

    if (sRetVal==null)
      return sDefault;
    else
      return sRetVal;
  } // getEnvVar()

  //-----------------------------------------------------------

  /**
   * <P>Get temporary directory</P>
   * @return For UNIX Sytems this function always return "/tmp/".<BR>
   * For Windows Systems getTempDir() returns the value set at the environment
   * variable "TEMP" or C:\\%WINDIR%\\TEMP\\ if TEMP variable is not set.
   * @throws IllegalArgumentException
   */
  public static String getTempDir() throws IllegalArgumentException {
    if (System.getProperty("os.name").startsWith("Windows")) {
      String sTempDir = getEnvVar("TEMP");
      if (null==sTempDir) {
        File oWinDir;
        oWinDir = new File("C:\\WINNT\\TEMP\\");
        if (oWinDir.exists()) {
          return "C:\\WINNT\\TEMP\\";
        } else {
          oWinDir = new File("C:\\WINDOWS\\TEMP\\");
          if (oWinDir.exists()) {
            return "C:\\WINDOWS\\TEMP\\";
          } else {
            return "C:\\TEMP\\";
          }
        }
      } else {
        return sTempDir;
      }
    } else { // Unix
      return "/tmp/";
    }
  } // getTempDir()

  //-----------------------------------------------------------

  /**
   * <p>Get a Properties collection from a .CNF file</p>
   * Property files must be in the directory pointed by a operating system environment variable names
   * <b>KNOWGATE_PROFILES</b>. If KNOWGATE_PROFILES environment variable is not found, the files will
   * be seeked by default on C:\WINNT\ or C:\WINDOWS\ on Window Systems and /etc/ on UNIX systems.
   * @param sProfile Properties file to read (for example "hipergate.cnf")
   * @since v2.2 The behaviour of this function has changed: it first tries to get KNOWGATE_PROFILES
   * from Java environment variables as set on startup "java -DKNOWGATE_PROFILES=..." if there is no
   * Java property named KNOWGATE_PROFILES then operating system environment variabled are scanned and
   * last if neither is found the default C:\WINNT\ C:\WINDOWS\ or /etc/ is returned
   */
  public static Properties getProfile(String sProfile) {
    String sProfilesHome = null;
    Properties oProfile = null;

    if (DebugFile.trace) DebugFile.writeln("Begin Environment.getProfile()");

    oProfile = (Properties ) profiles.get(sProfile);

	if (oProfile==null) oProfile = loadProfile(sProfile);
	
    if (oProfile==null) {
	  
      try {
        sProfilesHome = System.getProperty("KNOWGATE_PROFILES", getEnvVar("KNOWGATE_PROFILES"));
      }
      catch (java.lang.IllegalArgumentException iae) {
        sProfilesHome = getEnvironmentDirectory();

        if (DebugFile.trace) DebugFile.writeln("Environment.getEnvVar(KNOWGATE_PROFILES) IllegalArgumentException " + iae.getMessage());
      }

      if (DebugFile.trace) DebugFile.writeln("  KNOWGATE_PROFILES=" + sProfilesHome);

      if (!sProfilesHome.endsWith(System.getProperty("file.separator")))
        sProfilesHome += System.getProperty("file.separator");

      oProfile = loadProfile(sProfile, sProfilesHome + (sProfile.endsWith(".cnf") ? sProfile : sProfile + ".cnf"));

    } // fi (oProfile)

    if (DebugFile.trace) DebugFile.writeln("End Environment.getProfile()");

    return oProfile;
  } // getProfile()

  //-----------------------------------------------------------

  /**
   * <p>Load a Profile from a Properties file</p>
   * <p>The loaded Profile is cached in memory and will be returned in
   * future calls to getProfile()</p>
   * <p>If profile had been already loaded, then it is overwritten.</p>
   * @param sProfile Profile name, for example "hipergate"
   * @param sPath Full path to properties file, fo example "/etc/knowgate/hipergate.cnf"
   */
  public static Properties loadProfile(String sProfile, String sPath) {
    FileInputStream oFileStream;
    Properties oProfile;

    if (DebugFile.trace) DebugFile.writeln("Begin Environment.loadProfile(" + sProfile + "," + sPath + ")");

    if (profiles.containsKey(sProfile))
      profiles.remove(sProfile);

    oProfile = new Properties();
    try  {
      oFileStream = new FileInputStream(sPath);

      oProfile.load(oFileStream);
      oFileStream.close();

      profiles.put(sProfile, oProfile);
    }
    catch (FileNotFoundException nfe) {
      if (DebugFile.trace) DebugFile.writeln("FileNotFoundException " + sPath + " " + nfe.getMessage());
    }
    catch (IOException ioe) {
      if (DebugFile.trace) DebugFile.writeln("IOException " + sPath + " " + ioe.getMessage());
    }

    if (DebugFile.trace) DebugFile.writeln("End Environment.loadProfile()");

    return oProfile;
  } // loadProfile

  //-----------------------------------------------------------

  /**
   * <p>Load a Profile from a resource bundle</p>
   * <p>The loaded Profile is cached in memory and will be returned in
   * future calls to getProfile()</p>
   * <p>If profile had been already loaded, then it is overwritten.</p>
   * @param sProfile Profile name, for example "hipergate"
   * @since 5.0
   */
  public static Properties loadProfile(String sProfile) {
    Properties oProfile = null;

    if (DebugFile.trace) DebugFile.writeln("Begin Environment.loadProfile(" + sProfile + ")");

    if (profiles.containsKey(sProfile))
      profiles.remove(sProfile);

    try  {
      Class oThisClass = Class.forName("com.knowgate.misc.Environment");
	  InputStream oInStrm = oThisClass.getResourceAsStream((sProfile.endsWith(".cnf") ? sProfile : sProfile + ".cnf"));
      if (oInStrm!=null) {    
        oProfile = new Properties();
        oProfile.load(oInStrm);
        oInStrm.close();
        profiles.put(sProfile, oProfile);
      } else {
      	oProfile = null;
      }
    }
    catch (ClassNotFoundException neverthrown) { }
    catch (IOException ioe) {
      if (DebugFile.trace) DebugFile.writeln("IOException " + ioe.getMessage());
    }

    if (DebugFile.trace) DebugFile.writeln("End Environment.loadProfile()");

    return oProfile;
  } // loadProfile

  //-----------------------------------------------------------

  /**
   * Get a Set with all loaded profiles names
   * @return Set of profile names
   */
  public static Set getProfilesSet() {
    return profiles.keySet();
  }

  //-----------------------------------------------------------

  /**
   * <p>Get a single property from a .CNF file.</p>
   * <p>Properties are readed once from disk and then cached in memory.
   * If .CNF file is changed, refresh() method must be called for refreshing
   * in-memory cached values.</p>
   * @param sProfile .CNF file name
   * @param sVarName Property Name
   * @return Value of property or <b>null</b> if no property with such name was found.
   */
  public static String getProfileVar(String sProfile, String sVarName) {
    String sRetVal;
    Properties oProfile;

    //if (DebugFile.trace) DebugFile.writeln("Begin Environment.getProfileVar(" + sProfile + "," + sVarName + ")");

    oProfile = getProfile(sProfile);

    if (oProfile==null)
      sRetVal = null;
    else
      sRetVal = oProfile.getProperty(sVarName);
    // fi (oProfile)

    //if (DebugFile.trace) DebugFile.writeln("End Environment.getProfileVar() : " + (sRetVal!=null ? sRetVal : "null"));

    return sRetVal;
  } // getProfileVar()

  //-----------------------------------------------------------

  /**
   * Get names of all properties in a profile
   * @param sProfile Profile Name
   * @return Set of property names
   */
  public static Set getProfileVarSet(String sProfile) {

    Set oRetVal;
    Properties oProfile;

    //if (DebugFile.trace) DebugFile.writeln("Begin Environment.getProfileVarSet(" + sProfile + ")");

    oProfile = getProfile(sProfile);

    if (oProfile==null)
      oRetVal = null;
    else
      oRetVal = oProfile.keySet();
    // fi (oProfile)

    /*
    if (DebugFile.trace)
      if (null==oRetVal)
        DebugFile.writeln("End Environment.getProfileVarSet() : null");
      else
        DebugFile.writeln("End Environment.getProfileVarSet() : " + String.valueOf(oRetVal.size()));
    */

    return oRetVal;

  } // getProfileVarSet

  //-----------------------------------------------------------

  /**
   * <p>Get a property from a .CNF file representing a file path.</p>
   * <p>This method is equivalent to getProfileVar except that a
   * file separator is always appended to the end of the readed value.</p>
   * @param sProfile .CNF file name
   * @param sVarName Property Name
   * @return Value terminated with a file separator or <b>null</b> if no property with such name was found.
   */

  public static String getProfilePath(String sProfile, String sVarName) {
    String sPath = getProfileVar(sProfile, sVarName);
    return Gadgets.chomp(sPath, System.getProperty("file.separator"));
  }

  //-----------------------------------------------------------

  /**
   * <p>Get the value of a property that represents a boolean type.</p>
   * @param sProfile .CNF file name
   * @param sVarName Property Name
   * @param bDefault Default Value
   * @return If no property named sVarName is found at sProfile then bDefault value is returned.
   * If sVarName is one of {true , yes, on, 1} then return value is <b>true</b>.
   * If sVarName is one of {false, no, off, 0} then return value is <b>false</b>.
   * If sVarName is any other value then then return value is bDefault
   * @since 4.0
   */

  public static boolean getProfileBool(String sProfile, String sVarName, boolean bDefault) {
    boolean bRetVal = bDefault;
    String sBool = getProfileVar(sProfile, sVarName);
    if (null!=sBool) {
      sBool = sBool.trim();
      if (sBool.equalsIgnoreCase("true") || sBool.equalsIgnoreCase("yes") || sBool.equalsIgnoreCase("on") || sBool.equals("1"))
        bRetVal = true;
      else if (sBool.equalsIgnoreCase("false") || sBool.equalsIgnoreCase("no") || sBool.equalsIgnoreCase("off") || sBool.equals("0"))
        bRetVal = false;
      else
        bRetVal = bDefault;      	
    } // fi
    return bRetVal;
  } // getProfileBool

  //-----------------------------------------------------------

  /**
   * <p>Get a single property from a .CNF file.</p>
   * @param sProfile .CNF file name
   * @param sVarName Property Name
   * @param sDefault Default Value
   * @return Value of property or sDefault if no property with such name was found.
   */

  public static String getProfileVar(String sProfile, String sVarName, String sDefault) {
    String sRetVal;
    Properties oProfile;

    //if (DebugFile.trace) DebugFile.writeln("Begin Environment.getProfileVar(" + sProfile + "," + sVarName + "," + sDefault +  ")");

    oProfile = getProfile(sProfile);

    if (oProfile==null)
      sRetVal = null;
    else
      sRetVal = oProfile.getProperty(sVarName);
    // fi (oProfile)

    //if (DebugFile.trace) DebugFile.writeln("End Environment.getProfileVar() : " + (sRetVal!=null ? sRetVal : sDefault));

    return (null!=sRetVal ? sRetVal : sDefault);
  } // getProfileVar()

  //-----------------------------------------------------------

  /**
   * <p>Set value for a profile property</p>
   * Value is change in memory cache but not saved to disk.
   * @param sProfile Profile Name
   * @param sVarName Property Name
   * @param sVarValue Prioperty Value
   */
  public static void setProfileVar(String sProfile, String sVarName, String sVarValue) {
    Properties oProfile = Environment.getProfile(sProfile);

    oProfile.setProperty(sVarName,  sVarValue);
  } // setProfileVar()

  //-----------------------------------------------------------

  private static boolean execCommand(String sCmd) {
    boolean bRetVal=true;

    try {
      Runtime.getRuntime().exec(sCmd);
    }
    catch (IOException ioe) {
      bRetVal=false;
    }

    return bRetVal;
  } // execCommand

  //-----------------------------------------------------------

  /**
   * <p>Refresh in-memory cached properties by re-reading then from disk files.</p>
   */

  public static void refresh() {
    envVars = null;
    profiles = new HashMap();
  }

  //-----------------------------------------------------------

  /**
   * <p>Replace values of environment variables at given string</p>
   * Change all substrings of the form %[A-Z]% to the corresponding environment variables values<br>
   * For example, in Windows %ProgramFiles% typically maps to "C:\Program Files"<br>
   * Variable matching is case sensitive
   * @param sInput String
   * @return String
   * @throws IllegalArgumentException If there is a Malformed \\uxxxx encoding or any other type of intrinsic error at the environment variables values
   * @since 3.1
   */
  public static String resolveEnvironmentVariables(String sInput)
    throws IllegalArgumentException {
    // If input is null then ouput is null
    if (null==sInput) return null;
    final int iLen = sInput.length();
    // If input is empty string then ouput is empty string
    if (0==iLen) return "";
    StringBuffer oOutput = new StringBuffer(sInput.length()*2);
    int iPct1 = sInput.indexOf('%');
    // If input does not contain any percentage symbol then return input as is
    if (iPct1<0) return sInput;
    int iPct2 = sInput.indexOf('%', iPct1+1);
    // If input does not contain at least two percentage symbols then return input as is
    if (iPct2<0) return sInput;
    int iFrom = 0;
    // If the first percentage found is not the first character the append prior
    // characters to temporary output buffer
    if (iPct1>0) oOutput.append(sInput.substring(0, iPct1));
    while (true) {
      if (iPct1+1==iPct2) {
        // If second percentage is just next to first one then append a double "%%"
        oOutput.append("%%");
      } else {
        // The environment variable name is the substring between the two percentage symbols
        String sVariableName = sInput.substring(iPct1+1, iPct2);
        // Try to get environment variable with the candidate name
        String sVariableValue = getEnvVar(sVariableName);
        if (null==sVariableValue) {
          // If no environment variable is found with such name then everything
          // is left untouched, so %NotFoundVariable% is appended to temporary
          // ouput buffer
          oOutput.append(sInput.substring(iPct1, iPct2+1));
        } else {
          // If an environment variable is found, then the %VariableName%
          // substring is replaced with the environmnet variable value
          oOutput.append(sVariableValue);
        }
        // Continue searching for percetage symbols after the second one
        iFrom = iPct2+1;
        // Exit loop if end of string has been reached
        if (iFrom>=iLen) break;
        iPct1 = sInput.indexOf('%', iFrom);
        // If no more percentage symbols are found,
        // or the symbols is at end of string, then append the rest of the input
        if (iPct1<0 || iPct1==iLen-1) {
          oOutput.append(sInput.substring(iFrom));
          break;
        }
        iPct2 = sInput.indexOf('%', iPct1+1);
        // If a second percentage symbol is not found,
        // then append the rest of the input
        if (iPct2<0) {
          oOutput.append(sInput.substring(iFrom));
          break;
        }
        // Append the characters between the last percentage pair and the current one
        if (iPct1>iFrom) oOutput.append(sInput.substring(iFrom, iPct1));
      } // fi (iPct1+1==iPct2)
    } // wend
    return oOutput.toString();
  } // resolveEnvironmentVariables

  /**
   * <p>Update system time</p>
   * <p>This is an alpha testing method, do not use in production environments.</p>
   * @param lTime New System Date
   */

  public static void updateSystemTime(long lTime) {
    try
    {
        String system = System.getProperty("os.name");
        String cmdDate = "";
        String cmdTime = "";
        Date curDate = new Date();
        curDate.setTime(lTime);
        SimpleDateFormat fmt = new SimpleDateFormat(getProfileVar("hipergate", "dateformat", "dd-MM-yyyy"));
        //SimpleTimeZone atz = null;
        //fmt.setCalendar(new GregorianCalendar(atz));
        String actDate = fmt.format(curDate);
        fmt.applyPattern("HH:mm:ss");
        String actTime = fmt.format(curDate);
        if (system.startsWith("Windows NT") || system.startsWith("Windows 2000")) {
            execCommand("cmd /c date " + actDate);
            cmdTime = "cmd /c time " + actTime;
            execCommand(cmdTime);
        } else
        // Win 95/98. Dirty skunk. Doesn't tell us about who it is in real
        if (system.indexOf("Windows") == 0) {
            fmt.applyPattern("MM.dd.yyyy");
            actDate = fmt.format(curDate);
            execCommand("c:\\command.com /c date " + actDate);
            fmt.applyPattern("dd-MM-yyyy");
            actDate = fmt.format(curDate);
            execCommand("c:\\command /c date " + actDate);
            fmt.applyPattern("yyyy-MM-dd");
            actDate = fmt.format(curDate);
            execCommand("c:\\command /c date " + actDate);
            cmdTime = "c:\\command.com /c time " + actTime;
            execCommand(cmdTime);
        } else
        //if ((system.toUpperCase().indexOf("UNIX") == 0) || (system.toUpperCase().indexOf("LINUX") == 0))
        {
            fmt.applyPattern("MM/dd/yyyy HH:mm:ss");
            actDate = fmt.format(curDate);
            cmdDate = "date -u -s'" + actDate + "' +'%D %T'";
            execCommand(cmdDate);
        }
    }
    catch (Exception e) {
    }
  } // updateSystemTime

  //-----------------------------------------------------------

  private static Properties envVars = null;
  private static HashMap profiles = new HashMap();

} // Environment

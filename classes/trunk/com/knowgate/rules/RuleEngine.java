/*
  Copyright (C) 2006  Know Gate S.L. All rights reserved.
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

package com.knowgate.rules;

import java.util.Properties;
import java.util.HashMap;
import java.util.Date;
import java.util.Iterator;
import java.util.Enumeration;
import java.text.ParseException;
import java.text.SimpleDateFormat;

import java.math.BigDecimal;

import java.io.File;
import java.io.FileInputStream;
import java.io.FileOutputStream;
import java.io.FileNotFoundException;
import java.io.IOException;

import java.sql.SQLException;
import java.sql.Connection;

import javax.sql.DataSource;

import com.knowgate.debug.DebugFile;

/**
 * <p>Rule Engine</p>
 * @author Sergio Montoro Ten
 * @version 2.0
 */
public class RuleEngine {
  private static HashMap<String,RuleEngine> oEngines = new HashMap<String,RuleEngine>(11);

  private HashMap<String,Properties> oProps = new HashMap<String,Properties>(11);
  private HashMap<String,File> oPaths = new HashMap<String,File>(11);
  private HashMap<String,DataSource> oDbbs = new HashMap<String,DataSource>(11);
  private HashMap oAsrt = new HashMap(29);

  private String sDefaultProfileName = "default";
  private String sDefaultBindingName = "default";

  private RuleEngine() {
    sDefaultProfileName = null;
    sDefaultBindingName = null;
  }

  protected RuleEngine(Properties oProperties, DataSource oDataSrc)
    throws FileNotFoundException, IOException {

    if (DebugFile.trace) {
      DebugFile.writeln("new RuleEngine([oProperties],[DataSource])");
      DebugFile.incIdent();
      Enumeration oKeys = oProperties.keys();
      while (oKeys.hasMoreElements()) {
        String sKey = (String) oKeys.nextElement();
        DebugFile.writeln(sKey+"="+oProperties.getProperty(sKey));
      } // wend
    }

    setDefaultProperties(oProperties);
    setDefaultDataBaseBind(oDataSrc);

    if (DebugFile.trace) DebugFile.decIdent();
  }

  public static HashMap engines() {
    return oEngines;
  }

  public static boolean existsEngine(String sEngineName) {
    return oEngines.containsKey(sEngineName);
  }

  public static RuleEngine getEngine(String sEngineName, Properties oProps, DataSource oDataSrc)
    throws FileNotFoundException, IOException {

  if (DebugFile.trace) {
    DebugFile.writeln("Begin RuleEngine.getEngine("+sEngineName+",[DataSource])");
    DebugFile.incIdent();
  }

    RuleEngine oEngine;
    if (existsEngine(sEngineName)) {
      if (DebugFile.trace) DebugFile.writeln("getting existing engine");
      oEngine = (RuleEngine) oEngines.get(sEngineName);
    } else {
      if (DebugFile.trace) DebugFile.writeln("instantiating new engine");
      oEngine = new RuleEngine(oProps, oDataSrc);
      oEngines.put(sEngineName, oEngine);
    }

    if (DebugFile.trace) {
      DebugFile.decIdent();
      DebugFile.writeln("End RuleEngine.getEngine()");
    }

    return oEngine;
  } // getEngine

  public void close() {
    if (DebugFile.trace) {
      DebugFile.writeln("Begin RuleEngine.close()");
      DebugFile.incIdent();
    }

    if (DebugFile.trace) {
      DebugFile.decIdent();
      DebugFile.writeln("End RuleEngine.close()");
    }
  } // closeEngine

  public static void closeAll() {
      Iterator oKeys = oEngines.keySet().iterator();
      while (oKeys.hasNext()) {
        oEngines.get(oKeys.next()).close();
      } // wend
  } // closeAll

  public Properties getProperties(String sSetName) {
    return (Properties) oProps.get(sSetName);
  }

  public Properties getDefaultProperties() {
    return (Properties) oProps.get(sDefaultProfileName);
  }

  public String getPropertyStr(String sSetName, String sKey) {
    return getProperties(sSetName).getProperty(sKey);
  }

  public String getPropertyStr(String sSetName, String sKey, String sDefault) {
    return getProperties(sSetName).getProperty(sKey, sDefault);
  }

  public String getDefaultPropertyStr(String sKey, String sDefault) {
    String sProp = getDefaultProperties().getProperty(sKey);
    return sProp==null ? sDefault : sProp;
  }

  public String getDefaultPropertyStr(String sKey) {
    return getDefaultPropertyStr(sKey,null);
  }

  public BigDecimal getPropertyDec(String sSetName, String sKey, BigDecimal dDefault)
    throws NumberFormatException {
    String sProp = getProperties(sSetName).getProperty(sKey);
    if (null==sProp)
      return dDefault;
    else
      return new BigDecimal(sProp);
  }

  public BigDecimal getPropertyDec(String sSetName, String sKey)
      throws NumberFormatException {
    return getPropertyDec(sSetName, sKey, null);
  }

  public BigDecimal getDefaultPropertyDec(String sKey)
      throws NumberFormatException {
    return getPropertyDec(sDefaultProfileName, sKey, null);
  }

  public BigDecimal getDefaultPropertyDec(String sKey, BigDecimal dDefault)
      throws NumberFormatException {
    return getPropertyDec(sDefaultProfileName, sKey, dDefault);
  }

  public Integer getPropertyInt(String sSetName, String sKey, Integer iDefault)
    throws NumberFormatException {
    String sProp = getProperties(sSetName).getProperty(sKey);
    if (null==iDefault)
      return null;
    else
      return new Integer(sProp);
  }

  public Integer getPropertyInt(String sSetName, String sKey)
    throws NumberFormatException {
    return getPropertyInt(sSetName, sKey);
  }

  public Integer getDefaultPropertyInt(String sKey)
    throws NumberFormatException {
    return getPropertyInt(sDefaultProfileName, sKey);
  }

  public Integer getDefaultPropertyInt(String sKey, Integer iDefault)
    throws NumberFormatException {
    return getPropertyInt(sDefaultProfileName, sKey, iDefault);
  }

  public Date getPropertyDate(String sSetName, String sKey, String sFormat, Date dtDefault)
    throws ParseException {
    String sProp = getProperties(sSetName).getProperty(sKey);
    if (null==sProp)
      return dtDefault;
    else {
      SimpleDateFormat oFmt = new SimpleDateFormat(sFormat);
      return oFmt.parse(sProp);
    }
  }

  public Date getPropertyDate(String sSetName, String sKey, String sFormat)
    throws ParseException {
    return getPropertyDate(sSetName, sKey, null);
  }

  public Date getDefaultPropertyDate(String sKey, String sFormat)
    throws ParseException {
    return getPropertyDate(sDefaultProfileName, sKey, null);
  }

  public Date getDefaultPropertyDate(String sKey, String sFormat, Date dtDefault)
    throws ParseException {
    return getPropertyDate(sDefaultProfileName, sKey, sFormat, dtDefault);
  }

  public void setProperties(String sSetName, Properties oPSet) {
    if (oProps.containsKey(sSetName))
      oProps.remove(sSetName);
    oProps.put(sSetName, oPSet);
  }

  public void setDefaultProperties(Properties oProps) {
    setProperties(sDefaultProfileName, oProps);
  }

  public void setDefaultProperties(Properties oProps, String sProfileName) {
    sDefaultProfileName = sProfileName;
    if (oProps.containsKey(sProfileName)) oProps.remove(sProfileName);
    setProperties(sDefaultProfileName, oProps);
  }

  public void loadProperties(String sSetName, String sPathFile)
    throws FileNotFoundException, IOException {

    if (DebugFile.trace) {
      DebugFile.writeln("Begin RuleEngine.loadProperties("+sSetName+","+sPathFile+")");
      DebugFile.incIdent();
    }

    if (oProps.containsKey(sSetName))
      oProps.remove(sSetName);
    Properties oPSet = new Properties();
    File oFile = new File(sPathFile);
    FileInputStream oIoStrm = new FileInputStream(oFile);
    oPSet.load(oIoStrm);
    oIoStrm.close();

    if (DebugFile.trace) {
      Enumeration oKeys = oPSet.keys();
      while (oKeys.hasMoreElements()) {
        String sKey = (String) oKeys.nextElement();
        DebugFile.writeln(sKey+"="+oPSet.getProperty(sKey));
      } // wend
    } // fi

    oProps.put(sSetName, oPSet);
    oPaths.put(sSetName, oFile);

    if (DebugFile.trace) {
      DebugFile.decIdent();
      DebugFile.writeln("End RuleEngine.loadProperties()");
    }
  } // loadProperties

  public void loadDefaultProperties(String sSetName, String sPathFile)
    throws FileNotFoundException, IOException {
    sDefaultProfileName = sSetName;
    loadProperties(sSetName, sPathFile);
  }

  public void saveProperties(String sSetName)
    throws IOException {
    FileOutputStream oIoStrm = new FileOutputStream((File)oPaths.get(sSetName));
    getProperties(sSetName).store(oIoStrm, "# hipergate Rule Engine "+new Date().toString());
    oIoStrm.close();
  }

  public void saveDefaultProperties()
    throws IOException {
    saveProperties(sDefaultProfileName);
  }

  public DataSource getDefaultDataBaseBind() {
    return oDbbs.get(sDefaultBindingName);
  }

  public void setDefaultDataBaseBind(DataSource oDatSrc) {
    oDbbs.put(sDefaultBindingName, oDatSrc);
  }
  
  public Connection getConnection(String sCaller)
    throws SQLException {
    Connection oRetObj;
    oRetObj = getDefaultDataBaseBind().getConnection();
    return oRetObj;
  }

  public void setAssert(String sAssertKey, boolean bTrueOrFalse) {
    if (oAsrt.containsKey(sAssertKey))
      oAsrt.remove(sAssertKey);
    oAsrt.put(sAssertKey, new Boolean(bTrueOrFalse));
  }

  public boolean getAssert(String sAssertKey) {
    Boolean bAssrt = (Boolean) oAsrt.get(sAssertKey);
    if (bAssrt==null)
      return false;
    else
      return bAssrt.booleanValue();
  }
}

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

import java.util.Map;
import java.util.Iterator;
import java.util.HashMap;
import java.util.Date;
import java.math.BigDecimal;

/**
 * <p>RuleExecution</p>
 * RuleExecution represents an abstract operation performed on a set of data.
 * Rule Executions are composed of three items:<br>
 * 1. The Parameters Collection<br>
 * 2. The Assertions Collection<br>
 * 3. The Rule Execution Code<br>
 * Also RuleExecution can used additional global properties and asserts from its parent RuleEngine.
 * @author Sergio Montoro Ten
 * @version 1.0
 */
public abstract class RuleExecution {

  private RuleEngine oRuleEngine;

  private HashMap<String,Object> oParams;
  private HashMap<String,Boolean> oAssrts;

  /**
   * Create RuleExecution on given RuleEngine
   * @param oEngine RuleEngine
   */
  public RuleExecution(RuleEngine oEngine) {
    oRuleEngine = oEngine;
    oParams = new HashMap<String,Object>(29);
    oAssrts = new HashMap<String,Boolean>(29);
  }

  /**
   * Create copy from another RuleExecution
   * @param oRexec RuleExecution
   */
  public RuleExecution(RuleExecution oRexec) {
    oRuleEngine = oRexec.getRuleEngine();
    oParams = (HashMap) oRexec.getParamMap().clone();
    oAssrts = (HashMap) oRexec.getAssertMap().clone();
  }

  /**
   * Clear all parameters and asserts
   */
  public void clear() {
    oParams.clear();
    oAssrts.clear();
  }

  /**
   * Get RuleEngine to which this RuleExecution belongs
   * @return RuleEngine
   */
  public RuleEngine getRuleEngine() {
    return oRuleEngine;
  }

  /**
   * Set true or false status for a fact
   * @param sAssertKey String A unique key in this RuleExecution for the fact
   * @param bTrueOrFalse boolean
   */
  public void setAssert(String sAssertKey, boolean bTrueOrFalse) {
    if (oAssrts.containsKey(sAssertKey)) oAssrts.remove(sAssertKey);
    oAssrts.put(sAssertKey, new Boolean(bTrueOrFalse));
  }

  /**
   * Get status of a given fact
   * @param sAssertKey String A unique key in this RuleExecution for the fact
   * @return boolean If no assertion with given key is found then <b>false</b> is returned.
   */
  public boolean getAssert(String sAssertKey) {
    Boolean bAssrt = oAssrts.get(sAssertKey);
    if (bAssrt==null)
      return false;
    else
      return bAssrt.booleanValue();
  }

  /**
   * Get map of parameters used by this RuleExecution
   * @return HashMap
   */
  public HashMap<String,Object> getParamMap() {
    return oParams;
  }

  /**
   * Get map of assertions used by this RuleExecution
   * @return HashMap
   */
  public HashMap<String,Boolean> getAssertMap() {
    return oAssrts;
  }

  /**
   * Find out whether or not a given parameter is <b>null</b>
   * @param sKey String Parameter name
   * @return boolean If parameter is <b>null</b> or if it has not defined value
   * then the return value is <b>true</b>, else if the parameter is defined and
   * has a value other than <b>null</b> the return value is <b>false</b>
   */
  public boolean isNull(String sKey) {
    if (oParams.containsKey(sKey))
      return (null==oParams.get(sKey));
    else
      return true;
  }

  /**
   * Find out whether or not a given parameter has a defined value
   * @param sKey String Parameter Name
   * @return boolean
   */
  public boolean isDefined(String sKey) {
    return oParams.containsKey(sKey);
  }

  /**
   * <p>Set value for parameter</p>
   * If parameter already exists then its value is replaced with the new one
   * @param sKey String Parameter name
   * @param oValue Object
   */
  public void setParam(String sKey, Object oValue) {
    if (oParams.containsKey(sKey)) oParams.remove(sKey);
    oParams.put(sKey, oValue);
  }

  /**
   * Remove parameter value
   * @param sKey String Parameter name
   */
  public void resetParam(String sKey) {
    if (oParams.containsKey(sKey)) oParams.remove(sKey);
  }

  /**
   * Set values for a set of parameters
   * If parameters already exist then theirs values are replaced with the new ones
   * @param oMap Map of values to be set
   */
  public void setParams(Map oMap) {
    Iterator oKeys = oMap.keySet().iterator();
    while (oKeys.hasNext()) {
      String oKey = (String) oKeys.next();
      if (oParams.containsKey(oKey)) oParams.remove(oKey);
      oParams.put(oKey, oMap.get(oKey));
    } // wend
  }

  /**
   * <p>Get parameter value</p>
   * @param sKey String Parameter Name
   * @return Object If parameter is undefined then return value is <b>null</b>
   */
  public Object getParam(String sKey) {
    if (oParams.containsKey(sKey))
      return oParams.get(sKey);
    else
      return null;
  }

  /**
   * <p>Get parameter value</p>
   * @param sKey String Parameter Name
   * @param oDefault Default value
   * @return Object If parameter is undefined then return value is oDefault
   */
  public Object getParam(String sKey, Object oDefault) {
    if (oParams.containsKey(sKey))
      return oParams.get(sKey);
    else
      return oDefault;
  }

  /**
   * Get parameter as String
   * @param sKey String Parameter Name
   * @param sDefault String Default value
   * @return String
   */
  public String getParamStr(String sKey, String sDefault) {
    Object oParam = oParams.get(sKey);
    if (oParam==null)
      return sDefault;
    else
      return oParam.toString();
  }

  /**
   * Get parameter as String
   * @param sKey String Parameter Name
   * @return String
   */
  public String getParamStr(String sKey) {
      return getParamStr(sKey, null);
  }

  /**
   * Get parameter as java.util.Date
   * @param sKey String Parameter Name
   * @param dtDefault Date Default value
   * @return Date If parameter is undefined then return value is dtDefault
   * @throws ClassCastException
   */
  public Date getParamDate(String sKey, Date dtDefault)
    throws ClassCastException {
    Object oParam = oParams.get(sKey);
    if (oParam==null)
      return dtDefault;
    else
      return (Date) oParam;
  }

  /**
   * Get parameter as java.util.Date
   * @param sKey String Parameter Name
   * @return Date If parameter is undefined then return value is <b>null</b>
   * @throws ClassCastException
   */
  public Date getParamDate(String sKey)
    throws ClassCastException {
    return getParamDate(sKey, null);
  }

  /**
   * Get parameter as BigDecimal
   * @param sKey String Parameter Name
   * @param oDefault BigDecimal
   * @return BigDecimal If parameter is undefined then return value is dtDefault
   * @throws ClassCastException
   */
  public BigDecimal getParamDec(String sKey, BigDecimal oDefault)
    throws ClassCastException {
    Object oParam = oParams.get(sKey);
    if (oParam==null)
      return oDefault;
    else
      return (BigDecimal) oParam;
  }

  /**
   * Get parameter as BigDecimal
   * @param sKey String Parameter Name
   * @return BigDecimal
   * @throws ClassCastException
   */
  public BigDecimal getParamDec(String sKey)
    throws ClassCastException {
    return getParamDec(sKey, null);
  }

  /**
   * Get parameter as Integer
   * @param sKey String Parameter Name
   * @param iDefault Integer Default value
   * @return Integer If parameter is undefined then return value is iDefault
   * @throws ClassCastException
   */
  public Integer getParamInt(String sKey, Integer iDefault)
    throws ClassCastException {
    Object oParam = oParams.get(sKey);
    if (oParam==null)
      return iDefault;
    else
      return (Integer) oParam;
  }

  /**
   * Get parameter as Integer
   * @param sKey String Parameter Name
   * @return Integer If parameter is undefined then return value is <b>null</b>
   * @throws ClassCastException
   */
  public Integer getParamInt(String sKey)
    throws ClassCastException {
    return getParamInt(sKey, null);
  }

  /**
   * <p>Get result of applying this rule</p>
   * This method must be implemented on eeach derived class for providing
   * the actual behaviour of the RuleExecution instance
   * @return Object
   * @throws RuleExecutionException
   */
  public abstract Object getResult() throws RuleExecutionException;
  
  /**
   * <p>Get explanation about how the last result of applying this rule was computed</p>
   * This method must be implemented on eeach derived class for providing
   * the actual behaviour of the RuleExecution instance
   * @return Object
   * @throws RuleExecutionException
   */  
  public abstract Object getExplanation() throws RuleExecutionException;
  
}

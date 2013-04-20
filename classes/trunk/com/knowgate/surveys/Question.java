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

package com.knowgate.surveys;

import com.knowgate.debug.DebugFile;

/**
 * Generic superclass for Survey questions
 * @author Sergio Montoro Ten
 * @version 1.0
 */
public abstract class Question {

  protected String  name;
  protected boolean mustanswer;
  protected String  caption;
  protected String  captstyle;
  protected String  style;
  protected String  illegalval;

  public Question() { }

  /**
   * <p>Get Question name</p>
   * Each question name must be unique inside the Survey
   * @return String
   */
  public String getName() { return name; }

  /**
   * <p>Set Question name</p>
   * Only letters and numbers allowed. No spaces nor delimiter characters.
   * @param sName String
   * @throws IllegalArgumentException
   */
  public void setName(String sName)
    throws IllegalArgumentException {

    if (DebugFile.trace) {
      if (sName.indexOf(' ')>=0 || sName.indexOf(',')>=0 || sName.indexOf(';')>=0 ||
          sName.indexOf('|')>=0 || sName.indexOf('&')>=0 || sName.indexOf('?')>=0 ||
          sName.indexOf('*')>=0 || sName.indexOf('/')>=0 || sName.indexOf('\\')>=0 ||
          sName.indexOf('-')>=0 || sName.indexOf('(')>=0 || sName.indexOf(')')>=0 ||
          sName.indexOf('+')>=0 || sName.indexOf('[')>=0 || sName.indexOf(']')>=0 ||
          sName.indexOf('%')>=0 || sName.indexOf('{')>=0 || sName.indexOf('}')>=0 ||
          sName.indexOf('ñ')>=0 || sName.indexOf('Ñ')>=0 || sName.indexOf('^')>=0 ||
          sName.indexOf('ç')>=0 || sName.indexOf('Ç')>=0 || sName.indexOf('"')>=0 ||
          sName.indexOf('á')>=0 || sName.indexOf('é')>=0 || sName.indexOf('í')>=0 ||
          sName.indexOf('ó')>=0 || sName.indexOf('ú')>=0 || sName.indexOf('à')>=0 ||
          sName.indexOf('è')>=0 || sName.indexOf('è')>=0 || sName.indexOf('ò')>=0 ||
          sName.indexOf('ù')>=0 || sName.indexOf('`')>=0 || sName.indexOf('´')>=0 ||
          sName.indexOf('.')>=0 || sName.indexOf(':')>=0 || sName.indexOf(',')>=0 ||
          sName.indexOf(39 )>=0 || sName.indexOf('¡')>=0 || sName.indexOf('¿')>=0) {
      }
      throw new IllegalArgumentException("Question name contains invalid characters");
    } else {
      name = sName;
    }
  }

  public String getCaption() { return caption; }
  public void setCaption(String sCaption) { caption = sCaption;  }
  public boolean mustAnswer() { return mustanswer; }
  public void mustAnswer(boolean bMustAnswer) { mustanswer = bMustAnswer; }
  public String getStyle() { return style; }
  public void setStyle(String sStyle) { style = sStyle; }
  public String getCaptStyle() { return captstyle; }
  public void setCaptStyle(String sCaptStyle) { captstyle = sCaptStyle; }
  public String getIllegalVal() { return illegalval; }
  public void setIllegalVal(String sVal) { illegalval = sVal; }

  public abstract Object getValue();

  public abstract short getClassId();

  public static final class SubTypes {
      public static final short CHOICE = 201;
      public static final short MULTICHOICE = 202;
      public static final short LISTCHOICE = 203;
      public static final short TEXT = 204;
      public static final short MEMO = 205;
      public static final short BOOLALTERNATIVE = 206;
      public static final short LICKERT = 207;
      public static final short MATRIX = 208;
      public static final short MULTITEXT = 213;
      public static final short HOTORNOT = 214;
  }
} // Question

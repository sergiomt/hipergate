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

/**
 * @author Sergio Montoro Ten
 * @version 1.0
 */
public class Lickert extends Question {

  public Lickert() { }

  protected float steps;
  protected float value;
  protected float lefttag;
  protected float righttag;
  protected boolean reversed;
  protected int selectedindex;
  protected String leftcapt;
  protected String rightcapt;

  //----------------------------------------------------------------------------

  public float getSteps() {
    return steps;
  }

  //----------------------------------------------------------------------------

  public void setSteps(float iSteps) {
    steps = iSteps;
  }

  //----------------------------------------------------------------------------

  public float leftTag() {
    return lefttag;
  }

  //----------------------------------------------------------------------------

  public void leftTag(float iLeftTag) {
    lefttag = iLeftTag;
  }

  //----------------------------------------------------------------------------

  public float rightTag() {
    return righttag;
  }

  //----------------------------------------------------------------------------

  public void rightTag(float iRightTag) {
    righttag = iRightTag;
  }

  //----------------------------------------------------------------------------

  public boolean isReversed() {
    return reversed;
  }

  //----------------------------------------------------------------------------

  public void isReversed(boolean bReversed) {
    reversed = bReversed;
  }

  //----------------------------------------------------------------------------

  public int selectedIndex() {
    return selectedindex;
  }

  //----------------------------------------------------------------------------

  public void selectedIndex(int iIndex) {
    selectedindex = iIndex;
  }

  //----------------------------------------------------------------------------

  public float floatValue() {
    return value;
  }

  // ===========================================================================
  // Question abstract class implementation

   // ---------------------------------------------------------------------------

   public Object getValue() {
     return new Float(value);
   }

  // ---------------------------------------------------------------------------

  public short getClassId() {
    return Lickert.ClassId;
  }

  // ---------------------------------------------------------------------------

   public static final short ClassId = Question.SubTypes.LICKERT;

  //----------------------------------------------------------------------------
} // Lickert

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

import java.util.ArrayList;

/**
 * @author Sergio Montoro Ten
 * @version 1.0
 */
public class MultiChoice extends Choice {

  //----------------------------------------------------------------------------

  protected String colcaptstyle;
  protected ArrayList colheaders;

  //----------------------------------------------------------------------------

  public MultiChoice() {  }

  //----------------------------------------------------------------------------

  public int[] selectedIndexes() {
    final int iCount = getChoiceElementCount();

    if (iCount==0) return null;

    int[] aAll = new int[iCount];
    int s = 0;
    for (int c=0; c<iCount; c++) {
      if (getChoiceElement(c).checked)
        aAll[s++] = c;
    } // next
    if (s==0) return null;
    int[] aRet = new int[s];
    System.arraycopy(aAll, 0, aRet, 0, s);

    return aRet;
  } // selectedIndexes

  //----------------------------------------------------------------------------

  public ArrayList selectedElements() {
    final int iCount = getChoiceElementCount();

    ArrayList oRet = new ArrayList();
    for (int c=0; c<iCount; c++) {
      if (getChoiceElement(c).checked)
        oRet.add(getChoiceElement(c));
    } // next

    return oRet;
  } // selectedElements

  //----------------------------------------------------------------------------

  public String stringValue() {
    final int iCount = getChoiceElementCount();

    StringBuffer oRet = new StringBuffer();
    ChoiceElement oElement;
    int s=0;
    for (int c=0; c<iCount; c++) {
      oElement = getChoiceElement(c);
      if (oElement.checked) {
        if (0==s) oRet.append(';');
        oRet.append(oElement.value);
        s++;
      } // fi
    } // next

    return oRet.toString();
  }

  // ===========================================================================
  // Question abstract class implementation

  public Object getValue() {
    return selectedElements();
  }

  // ---------------------------------------------------------------------------

  public short getClassId() {
    return MultiChoice.ClassId;
  }

  // ---------------------------------------------------------------------------

   public static final short ClassId = Question.SubTypes.MULTICHOICE;

}

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
public class Matrix extends Question {
  public Matrix() {
    rows = new ArrayList();
  }

  //----------------------------------------------------------------------------

  public String coltitles;
  public String border;
  public int colwidth;
  public String captalign;
  public String colcaptstyle;
  public String rowcaptstyle;
  public boolean uniquecolumns;
  public boolean uniquerows;

  protected ArrayList rows;

  //----------------------------------------------------------------------------

  /**
   * Get Matrix cell
   * @param iCol int [0..columnCount()-1]
   * @param iRow int [0..rowCount()-1]
   * @return ChoiceElement
   * @throws ArrayIndexOutOfBoundsException
   */
  public MatrixCell getCell(int iCol, int iRow)
    throws ArrayIndexOutOfBoundsException {

    MatrixRow oRow = (MatrixRow) rows.get(iRow);

    return  oRow.getCell(iCol);
  }

  //----------------------------------------------------------------------------

  public MatrixRow getRow(int iRow) throws ArrayIndexOutOfBoundsException {
    return (MatrixRow) rows.get(iRow);
  }

  //----------------------------------------------------------------------------

  public int rowCount() {
    return rows.size();
  }

  //----------------------------------------------------------------------------

  public int columnCount() {
    MatrixRow oRow = (MatrixRow) rows.get(0);
    return oRow.columnCount();
  }

  // ===========================================================================
  // Question abstract class implementation

  public Object getValue() {
    final int iRows = rowCount();
    final int iCols = columnCount();
    String[][] aValues = new String[iCols][iRows];

    for (int r=0; r<iRows; r++) {
      for (int c=0; c<iCols; c++) {
        aValues[c][r] = getCell(c, r).value;
      } // next c
    } // next r
    return aValues;
  } // getValue

  // ---------------------------------------------------------------------------

  public short getClassId() {
    return Matrix.ClassId;
  }

  // ---------------------------------------------------------------------------

   public static final short ClassId = Question.SubTypes.MATRIX;

  //----------------------------------------------------------------------------
} // Matrix

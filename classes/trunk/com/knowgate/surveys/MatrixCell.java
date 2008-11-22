package com.knowgate.surveys;

import java.util.ArrayList;

/**
 * @author Sergio Montoro Ten
 * @version 1.0
 */
public class MatrixCell extends ChoiceElement {

  protected String celltype;
  protected float steps;
  protected float lefttag;
  protected float righttag;
  protected boolean reversed;
  protected int selectedindex;
  protected int maxlen;
  protected boolean numerical;
  protected float minval;
  protected float maxval;
  protected String texttransform;
  protected ArrayList listelements;

  public MatrixCell() {
    celltype = "com.knowgate.surveys.ChoiceElement";
    listelements = new ArrayList();
  }

  //----------------------------------------------------------------------------

  public String getTypeName() {
    return celltype;
  }

  //----------------------------------------------------------------------------

  public void setTypeName(String sTypeName) {
    celltype = sTypeName;
  }

  //----------------------------------------------------------------------------

  public int getMaxLen() {
    return maxlen;
  }

  //----------------------------------------------------------------------------

  public void setMaxLen(int iMaxLen) {
    maxlen = iMaxLen;
  }

  //----------------------------------------------------------------------------

  public boolean isNumerical() {
    return numerical;
  }

  //----------------------------------------------------------------------------

  public void isNumerical(boolean bNumerical) {
    numerical = bNumerical;
  }

  //----------------------------------------------------------------------------

  public short getType() {
    short iType;
    if (celltype.endsWith("Lickert"))
      iType = Lickert.ClassId;
    else if (celltype.endsWith("Text"))
      iType = Text.ClassId;
    else if (celltype.endsWith("ListChoice"))
      iType = ListChoice.ClassId;
    else if (celltype.endsWith("Enumeration"))
      iType = Enumeration.ClassId;
    else
      iType = ChoiceElement.ClassId;
    return iType;
  } // getType
}

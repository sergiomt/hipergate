package com.knowgate.surveys;

/**
 * @author Sergio Montoro Ten
 * @version 1.0
 */
public class Memo extends Question {
  public Memo() {
  }

  protected String value;
  protected int rows;
  protected int cols;

  //----------------------------------------------------------------------------

  public String stringValue() {
    if (null==value)
      return getIllegalVal();
    else
      return value;
  }

  // ===========================================================================
  // Question abstract class implementation

  public Object getValue() {
    return stringValue();
  }

  // ---------------------------------------------------------------------------

  public short getClassId() {
    return Memo.ClassId;
  }

  // ---------------------------------------------------------------------------

   public static final short ClassId = Question.SubTypes.MEMO;

  //----------------------------------------------------------------------------
} // Memo

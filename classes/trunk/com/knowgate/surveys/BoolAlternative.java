package com.knowgate.surveys;

/**
 * @author Sergio Montoro Ten
 * @version 1.0
 */
public class BoolAlternative extends Question {

  //----------------------------------------------------------------------------

  public BoolAlternative() { }

  //----------------------------------------------------------------------------

  protected boolean checked;

  //----------------------------------------------------------------------------

  public boolean booleanValue() {
    return checked;
  }

  // ===========================================================================
  // Question abstract class implementation

  public Object getValue() {
    return new Boolean(checked);
  }

  // ---------------------------------------------------------------------------

  public short getClassId() {
    return BoolAlternative.ClassId;
  }

  // ---------------------------------------------------------------------------

   public static final short ClassId = Question.SubTypes.BOOLALTERNATIVE;

} // BoolAlternative

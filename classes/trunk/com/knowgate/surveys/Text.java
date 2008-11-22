package com.knowgate.surveys;

/**
 * @author Sergio Montoro Ten
 * @version 1.0
 */

public class Text extends Question {

  protected String value;
  protected int maxlen;
  protected boolean numerical;
  protected float minval;
  protected float maxval;
  protected String texttransform;

  //----------------------------------------------------------------------------

  public Text() {
    value = null;
    maxlen = 80;
    numerical = false;
    texttransform = "none";
  }

  //----------------------------------------------------------------------------

  /**
   * Get text transformation
   * @return String {uppercase, lowercase, none}
   */
  public String getTextTransform() {
    return texttransform;
  }

  /**
   * Set text transformation
   * @param sTransform {uppercase, lowercase, none}
   * @throws IllegalArgumentException If sTransform is not "uppercase", "lowercase" or "none"
   */
  public void setTextTransform(String sTransform)
    throws IllegalArgumentException {
    if (sTransform==null)
      texttransform="none";
    else
      texttransform=sTransform.toLowerCase();
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
    return Text.ClassId;
  }

  // ---------------------------------------------------------------------------

   public static final short ClassId = Question.SubTypes.TEXT;

  //----------------------------------------------------------------------------
} // Text

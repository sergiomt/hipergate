package com.knowgate.surveys;

/**
 * @author Sergio Montoro Ten
 * @version 1.0
 */
public class ListChoice extends MultiChoice {
  public ListChoice() { }

  public int visiblelen;
  public boolean numerical;

  //----------------------------------------------------------------------------

  public int getVisibleLength() {
    return visiblelen;
  }

  //----------------------------------------------------------------------------

  public void setVisibleLength(int iLength) {
    visiblelen = iLength;
  }

  //----------------------------------------------------------------------------

  public boolean isNumerical() {
    return numerical;
  }

  //----------------------------------------------------------------------------

  public void isNumerical(boolean bNumerical) {
    numerical = bNumerical;
  }

  // ---------------------------------------------------------------------------

  public short getClassId() {
    return ListChoice.ClassId;
  }

  // ---------------------------------------------------------------------------

   public static final short ClassId = Question.SubTypes.LISTCHOICE;

} // List

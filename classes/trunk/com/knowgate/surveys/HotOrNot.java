package com.knowgate.surveys;

import java.util.ArrayList;

/**
 * @author Sergio Montoro Ten
 * @version 1.0
 */
public class HotOrNot extends Question {

  public Picture pict;
  public ArrayList lickerts;

  // ---------------------------------------------------------------------------

  public HotOrNot() {
    pict = new Picture();
    lickerts = new ArrayList();
  }

  // ---------------------------------------------------------------------------

  public int getLickertCount() {
    if (null==lickerts)
      return 0;
    else
      return lickerts.size();
  }

  // ---------------------------------------------------------------------------

  public Lickert getLickert(int l) throws ArrayIndexOutOfBoundsException{
    return (Lickert) lickerts.get(l);
  }

  // ---------------------------------------------------------------------------

  public Object getValue() {
    final int n = getLickertCount();
    String sValue = "";
    for (int l=0; l<n; l++) {
      sValue += (l==0 ? "" : "|") + getLickert(l).getValue();
    }
    return sValue;
  } // getValue()

  // ---------------------------------------------------------------------------

  public short getClassId() {
    return ClassId;
  }

  // ---------------------------------------------------------------------------

  public static final short ClassId = Question.SubTypes.HOTORNOT;

} // HotOrNot

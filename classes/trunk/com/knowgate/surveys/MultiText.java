package com.knowgate.surveys;

import java.util.ArrayList;
/**
 * @author Sergio Montoro Ten
 * @version 1.0
 */
public class MultiText extends Question {

  public ArrayList textelements;
  protected boolean ascii7caps;

  // ---------------------------------------------------------------------------

  public MultiText() {
    textelements = new ArrayList();
  }

  // ---------------------------------------------------------------------------

  public int getTextElementCount() {
    if (null==textelements)
      return 0;
    else
      return textelements.size();
  }

  // ---------------------------------------------------------------------------

  public boolean forceASCII7Caps() {
    return ascii7caps;
  }

  // ---------------------------------------------------------------------------

  public void forceASCII7Caps(boolean bForce) {
    final int iTexts = getTextElementCount();
    for (int t=0; t<iTexts; t++) ((TextElement)textelements.get(t)).forceASCII7Caps(bForce);
    ascii7caps = bForce;
  }

  // ---------------------------------------------------------------------------

  /**
   * Get Multitext Values
   * @return A String[] array with the value of each TextElement
   */
  public Object getValue() {
    if (textelements.size()==0) return null;
    final int count = textelements.size();
    String[] texts = new String[count];
    for (int t=0; t<count; t++) {
      texts[t] = ((TextElement)(textelements.get(t))).value;
    }
    return texts;
  }

  // ---------------------------------------------------------------------------

  public short getClassId() {
    return Question.SubTypes.MULTITEXT;
  }

  // ---------------------------------------------------------------------------

  public static final short ClassId = Question.SubTypes.MULTITEXT;

  // ---------------------------------------------------------------------------
}

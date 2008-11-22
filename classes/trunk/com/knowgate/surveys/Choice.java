package com.knowgate.surveys;

import java.util.ArrayList;

/**
 * @author Sergio Montoro Ten
 * @version 1.0
 */
public class Choice extends Question {

  //----------------------------------------------------------------------------

  protected String otherfield;
  protected ArrayList choiceelements;
  protected int selectedindex;

  //----------------------------------------------------------------------------

  public Choice() {
    choiceelements = new ArrayList();
    selectedindex = -1;
  }

  //----------------------------------------------------------------------------

  public String getOtherField() {
    return otherfield;
  }

  //----------------------------------------------------------------------------

  public void setOtherField(String sOtherField) {
    otherfield = sOtherField;
  }

  //----------------------------------------------------------------------------

  public ArrayList getChoiceElements() {
    return choiceelements;
  }

  //----------------------------------------------------------------------------

  public void addChoiceElement(ChoiceElement oElement) {
    choiceelements.add(oElement);
  }

  //----------------------------------------------------------------------------

  public ChoiceElement getChoiceElement(int iIndex) {
    return (ChoiceElement) choiceelements.get(iIndex);
  }

  //----------------------------------------------------------------------------

  public int getChoiceElementCount() {
    if (choiceelements==null)
      return 0;
    else
      return choiceelements.size();
  }

  //----------------------------------------------------------------------------

  public void removeChoiceElement(int iIndex) {
    choiceelements.remove(iIndex);
  }

  //----------------------------------------------------------------------------

  public int selectedIndex() {
    if (-1==selectedindex) {
      final int iCount = choiceelements.size();
      for (int c = 0; c < iCount; c++) {
        if (getChoiceElement(c).checked)
          return c;
      } // next
      return -1;
    }
    else {
      return selectedindex;
    }
  } // selectedIndex

  //----------------------------------------------------------------------------

  public void selectedIndex(int iIndex) {
    getChoiceElement(iIndex).checked = true;
    selectedindex = iIndex;
  }

  //----------------------------------------------------------------------------

  public String stringValue() {
    final int iSelected = selectedIndex();
    if (iSelected>=0)
      return getChoiceElement(iSelected).value;
    else
      return getIllegalVal();
  }

  // ===========================================================================
  // Question abstract class implementation

  public Object getValue() {
    return stringValue();
  }

  // ---------------------------------------------------------------------------

  public short getClassId() {
    return Choice.ClassId;
  }

  // ---------------------------------------------------------------------------

   public static final short ClassId = Question.SubTypes.CHOICE;

} // Choice

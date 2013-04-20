package com.knowgate.surveys;

import com.knowgate.debug.DebugFile;
import com.knowgate.misc.Gadgets;

/**
 * @author Sergio Montoro Ten
 * @version 1.0
 */
public class ChoiceElement {

  public String name;
  public String value;
  public String caption;
  public boolean checked;
  public int column;

  public ChoiceElement() {
    caption = name = value = null;
    column = 1;
    checked = false;
  }

  /**
   * <p>Get Element name</p>
   * @return String
   */
  public String getName() { return name; }

  /**
   * <p>Set Element name</p>
   * Only letters and numbers allowed. No spaces nor delimiter characters.
   * @param sName String
   * @throws IllegalArgumentException
   */
  public void setName(String sName)
    throws IllegalArgumentException {

    if (DebugFile.trace) {
      if (sName.indexOf(' ')>=0 || sName.indexOf(',')>=0 || sName.indexOf(';')>=0 ||
          sName.indexOf('|')>=0 || sName.indexOf('&')>=0 || sName.indexOf('?')>=0 ||
          sName.indexOf('*')>=0 || sName.indexOf('/')>=0 || sName.indexOf('\\')>=0 ||
          sName.indexOf('-')>=0 || sName.indexOf('(')>=0 || sName.indexOf(')')>=0 ||
          sName.indexOf('+')>=0 || sName.indexOf('[')>=0 || sName.indexOf(']')>=0 ||
          sName.indexOf('%')>=0 || sName.indexOf('{')>=0 || sName.indexOf('}')>=0 ||
          sName.indexOf('ñ')>=0 || sName.indexOf('Ñ')>=0 || sName.indexOf('^')>=0 ||
          sName.indexOf('ç')>=0 || sName.indexOf('Ç')>=0 || sName.indexOf('"')>=0 ||
          sName.indexOf('á')>=0 || sName.indexOf('é')>=0 || sName.indexOf('í')>=0 ||
          sName.indexOf('ó')>=0 || sName.indexOf('ú')>=0 || sName.indexOf('à')>=0 ||
          sName.indexOf('è')>=0 || sName.indexOf('è')>=0 || sName.indexOf('ò')>=0 ||
          sName.indexOf('ù')>=0 || sName.indexOf('`')>=0 || sName.indexOf('´')>=0 ||
          sName.indexOf('.')>=0 || sName.indexOf(':')>=0 || sName.indexOf(',')>=0 ||
          sName.indexOf(39 )>=0 || sName.indexOf('¡')>=0 || sName.indexOf('¿')>=0) {
      }
      throw new IllegalArgumentException("Element name contains invalid characters");
    } else {
      name = sName;    	
    }
  }

  /**
   * Get element caption
   * @return String
   */
  public String getCaption() {
    return caption==null ? "" : caption;
  }

  /**
   * Get element caption text or alt if it is an image
   * @return String
   */
  public String getCaptionAlt() {
    String sCaptionText;
    if (null==caption) {
      sCaptionText = "";
    }
    else {
      int iAlt = caption.indexOf("alt=");
      if (iAlt<0) iAlt = caption.indexOf("ALT=");
      if (iAlt>0) {
        int iQ1=iAlt+3;
        do {
          iQ1++;
        } while (iQ1<caption.length() && caption.charAt(iQ1)!=39 && caption.charAt(iQ1)!='"');
        int iQ2=iQ1;
        do {
          iQ2++;
        } while (iQ2<caption.length() && caption.charAt(iQ2)!=caption.charAt(iQ1));
        if (iQ1+1==iQ2)
          sCaptionText = "";
        else
          sCaptionText = Gadgets.HTMLDencode(caption.substring(iQ1+1, iQ2));
      }
      else {
        sCaptionText = caption;
      }
    }
    return sCaptionText;
  } // getCaptionAlt

  /**
   * Set element caption
   * @return String
   */
  public void setCaption(String sCaption) { caption = sCaption;  }

  /**
   * Get checked state
   * @return boolean
   */
  public boolean isChecked() { return checked; }

  /**
   * Set checked state
   */
  public void isChecked(boolean bChecked) { checked=bChecked; }

  /**
   * Get element value
   * @return String
   */
  public String getValue() { return value; }

  /**
   * Set element value
   */
  public void setValue(String sValue) { value=sValue; }

  /**
   * Get element column
   * @return int [1..n] Column at which element must be displayed. It is 1 by default.
   */
  public int getColumn() { return column; }

  /**
   * Set element column
   * @param iColumn int [1..n] Column at which element must be displayed when painting the form
   */
  public void setColumn(int iColumn) { column=iColumn; }

  // ---------------------------------------------------------------------------

  public short getClassId() {
    return ChoiceElement.ClassId;
  }

  // ---------------------------------------------------------------------------

   public static final short ClassId = 214;

}

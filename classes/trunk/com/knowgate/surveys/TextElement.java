package com.knowgate.surveys;

import com.knowgate.misc.Gadgets;
import com.knowgate.debug.DebugFile;

/**
 * @author Sergio Montoro Ten
 * @version 1.0
 */
public class TextElement {

  protected String name;
  protected String value;
  protected String caption;
  protected int maxlen;
  protected boolean ascii7caps;
  protected boolean numerical;

  // ---------------------------------------------------------------------------

  public TextElement() {
    caption = name = value = null;
    maxlen = 80;
    ascii7caps = false;
  }

  // ---------------------------------------------------------------------------

  public boolean forceASCII7Caps() {
    return ascii7caps;
  }

  // ---------------------------------------------------------------------------

  public void forceASCII7Caps(boolean bForce) {
    ascii7caps = bForce;
  }

  // ---------------------------------------------------------------------------

  /**
   * <p>Set element value</p>
   * If forceASCII7Caps() is <b>true</b> the function Gadgets.ASCIIEncode() is
   * applied to input argument before setting value.
   * @param sValue String
   * @throws IllegalArgumentException If sValue.length()>getMaxLength()
   */
  public void setValue(String sNewVal) throws IllegalArgumentException {
    if (DebugFile.trace) {
      if (sNewVal!=null) {
        if (sNewVal.length()>maxlen)
          throw new IllegalArgumentException("Value exceeds maximum length of "+String.valueOf(maxlen) + " characters");
      }
    }
    if (null==sNewVal)
      value = "";
    else if (ascii7caps)
      value = Gadgets.ASCIIEncode(sNewVal).toUpperCase();
    else
      value = sNewVal;
  } // setValue

  // ---------------------------------------------------------------------------

  /**
   * <p>Get element value</p>
   * If forceASCII7Caps() is <b>true</b> the function Gadgets.ASCIIEncode() is
   * applied to return value.
   * @return String
   */
  public String getValue() {
    if (null==value)
      return "";
    else if (ascii7caps)
      return Gadgets.ASCIIEncode(value).toUpperCase();
    else
      return value;
  }

  // ---------------------------------------------------------------------------

  /**
   * <p>Get Element name</p>
   * @return String
   */
  public String getName() { return name; }

  // ---------------------------------------------------------------------------

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

  // ---------------------------------------------------------------------------

  /**
   * Get element caption
   * @return String
   */
  public String getCaption() { return caption; }

  /**
   * Set element caption
   * @return String
   */
  public void setCaption(String sCaption) { caption = sCaption;  }

  // ---------------------------------------------------------------------------

  /**
   * Get element value maximum character length
   * @return int
   */
  public int getMaxLength() { return maxlen; }

  // ---------------------------------------------------------------------------

  /**
   * Set element value maximum character length
   * @param iMaxLength Maximum lenght for value in characters
   */
  public void setMaxLength(int iMaxLen) { maxlen=iMaxLen; }

  // ---------------------------------------------------------------------------

}

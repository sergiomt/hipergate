package com.knowgate.surveys;

import java.util.ArrayList;
import com.knowgate.misc.Gadgets;

/**
 * @author Sergio Montoro Ten
 * @version 1.0
 */
public class MatrixRow {

  public MatrixRow() {
    cols = new ArrayList();
  }

  //----------------------------------------------------------------------------

  public String  caption;
  protected ArrayList cols;

  //----------------------------------------------------------------------------

  public String getCaption() {
    return caption;
  }

  //----------------------------------------------------------------------------

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

  //----------------------------------------------------------------------------

  public MatrixCell getCell(int iCol)
    throws ArrayIndexOutOfBoundsException {
    return (MatrixCell) cols.get(iCol);
  }

  //----------------------------------------------------------------------------

  public void setCell(int iCol, MatrixCell oElement) {
    cols.add(iCol, oElement);
  }

  //----------------------------------------------------------------------------

  public void addCell(MatrixCell oElement) {
    cols.add(oElement);
  }

  //----------------------------------------------------------------------------

  public int columnCount() {
    return cols.size();
  }

  //----------------------------------------------------------------------------

} // MatrixRow

package com.knowgate.surveys;

import java.util.ArrayList;

/**
 * @author Sergio Montoro Ten
 * @version 1.0
 */
public class Enumeration {

  protected ArrayList enumelements;
  protected String name;
  protected int selectedindex;

  public Enumeration() {
    enumelements = new ArrayList();
  }

  public ArrayList getElements() {
    return enumelements;
  }

  // ---------------------------------------------------------------------------

  public short getClassId() {
    return Enumeration.ClassId;
  }

  // ---------------------------------------------------------------------------

   public static final short ClassId = 215;

}

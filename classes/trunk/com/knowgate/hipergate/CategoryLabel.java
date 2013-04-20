/*
  Copyright (C) 2003  Know Gate S.L. All rights reserved.
                      C/Oña, 107 1º2 28050 Madrid (Spain)

  Redistribution and use in source and binary forms, with or without
  modification, are permitted provided that the following conditions
  are met:

  1. Redistributions of source code must retain the above copyright
     notice, this list of conditions and the following disclaimer.

  2. The end-user documentation included with the redistribution,
     if any, must include the following acknowledgment:
     "This product includes software parts from hipergate
     (http://www.hipergate.org/)."
     Alternately, this acknowledgment may appear in the software itself,
     if and wherever such third-party acknowledgments normally appear.

  3. The name hipergate must not be used to endorse or promote products
     derived from this software without prior written permission.
     Products derived from this software may not be called hipergate,
     nor may hipergate appear in their name, without prior written
     permission.

  This library is distributed in the hope that it will be useful,
  but WITHOUT ANY WARRANTY; without even the implied warranty of
  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.

  You should have received a copy of hipergate License with this code;
  if not, visit http://www.hipergate.org or mail to info@hipergate.org
*/

package com.knowgate.hipergate;

import com.knowgate.jdc.JDCConnection;
import com.knowgate.dataobjs.DB;
import com.knowgate.dataobjs.DBPersist;

import com.knowgate.debug.DebugFile;

import java.sql.SQLException;

/**
 * Category Translated Labels
 * @author Sergio Montoro
 * @version 1.0
 */
public class CategoryLabel  extends DBPersist {

  /**
   * Create empty label
   */
  public CategoryLabel() {
    super(DB.k_cat_labels, "CategoryLabel");
  }

  /**
   * Load label from database
   * @param sCatId Category GUID
   * @param sLanguage 2 characters language code (see k_lu_languages table)
   */
  public CategoryLabel(String sCatId, String sLanguage) {
    super(DB.k_cat_labels, "CategoryLabel");
    put(DB.gu_category, sCatId);
    put(DB.id_language, sLanguage);
  }

  // **********************************************************
  // Static Methods

  /**
   * Single Step label Create and Store
   * @param oConn Database Conenction
   * @param Values An Array with values { (String) gu_category, (String) id_language,
   * (String) tr_category, (String) url_category }
   * @throws SQLException
   */
  public static void create(JDCConnection oConn, Object[] Values) throws SQLException {
    if (DebugFile.trace) {
      String sValues = "";
      if (Values!=null) {
      	for (int v=0; v<Values.length; v++) {
      	  sValues += (sValues.length()==0 ? "" : ",") + (Values[v]==null ? "null" : Values[v]);
      	}
      }
      DebugFile.writeln("Begin CategoryLabel.create([JDCConnection], {"+sValues+"})");
      DebugFile.incIdent();
    }
    
    if (Values[1].equals("vn")) {
      Values[1] = "vi";
    }
    
    CategoryLabel oLbl = new CategoryLabel();

    oLbl.put(DB.gu_category, Values[0]);
    oLbl.put(DB.id_language, Values[1]);
    oLbl.put(DB.tr_category, Values[2]);
    oLbl.put(DB.url_category, Values[3]);

    if (Values.length>4) oLbl.put(DB.de_category, Values[4]);

    oLbl.store(oConn);

    if (DebugFile.trace) {
      DebugFile.writeln("End CategoryLabel.create()");
      DebugFile.decIdent();
    }
  } // create

  // **********************************************************
  // Public Constants

  public static final short ClassId = 11;
}
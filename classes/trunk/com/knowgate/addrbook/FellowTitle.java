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

package com.knowgate.addrbook;

import java.sql.SQLException;
import java.sql.PreparedStatement;

import com.knowgate.debug.DebugFile;
import com.knowgate.jdc.JDCConnection;
import com.knowgate.dataobjs.DB;
import com.knowgate.dataobjs.DBPersist;

/**
 * @author Sergio Montoro Ten
 * @version 4.0
 */

public class FellowTitle extends DBPersist {

  public FellowTitle() {
     super(DB.k_lu_fellow_titles, "FellowTitle");
  }

  public FellowTitle(String sIdWorkArea, String sDeTitle) {
     super(DB.k_lu_fellow_titles, "FellowTitle");

     put (DB.gu_workarea, sIdWorkArea);
     put (DB.de_title, sDeTitle);
  }

  public FellowTitle(String sIdWorkArea, String sDeTitle, String sIdTitle, String sTpTitle, String sIdBoss, Float fSalaryMax, Float fSalaryMin) {
     super(DB.k_lu_fellow_titles, "FellowTitle");

     put (DB.gu_workarea, sIdWorkArea);
     put (DB.de_title, sDeTitle);
	 if (null!=sIdTitle) put (DB.id_title, sIdTitle);
	 if (null!=sTpTitle) put (DB.tp_title, sTpTitle);
	 if (null!=sIdBoss) put (DB.id_boss, sIdBoss);
	 if (null!=fSalaryMax) put (DB.im_salary_max, fSalaryMax.floatValue());
	 if (null!=fSalaryMin) put (DB.im_salary_min, fSalaryMin.floatValue());
  }

  public boolean delete(JDCConnection oConn) throws SQLException {
    PreparedStatement oStmt;
    String sSQL = "UPDATE " + DB.k_lu_fellow_titles + " SET " + DB.id_boss + "=NULL WHERE " + DB.id_boss + "=?";

    if (DebugFile.trace) DebugFile.writeln("Connection.prepareStatement(" + sSQL + ")");

    oStmt = oConn.prepareStatement(sSQL);
    oStmt.setString(1, getString(DB.de_title));
    oStmt.executeUpdate();
    oStmt.close();

    return super.delete(oConn);
  } // delete

}
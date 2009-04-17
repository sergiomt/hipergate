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

import java.lang.System;

import java.io.File;

import java.sql.SQLException;
import java.sql.Connection;
import java.sql.PreparedStatement;

import com.knowgate.dataobjs.DB;

/**
 * Class used for creating references to files at k_prod_locats database table
 * @author Sergio Montoro Ten
 * @version 1.0
 */
public class FileHandler {

  public FileHandler() {
    sFileSeparator = System.getProperty("file.separator");
  }

  // ----------------------------------------------------------

  private String getExtension(String sFile) {
    int iLast = sFile.lastIndexOf(".");

    if (iLast>0)
      return sFile.substring(++iLast);
    else
      return "";
  } // getExtension()

  // ----------------------------------------------------------

  public void upload(String sPath, String sFile, Connection oConn, String sLocationId) throws SQLException {
    int iFileLen;
    File oOldFile;
    String sExt;
    String sUniqueName;
    PreparedStatement oStmt;

    if (!sPath.endsWith(sFileSeparator)) sPath = sPath + sFileSeparator;

    sExt = getExtension(sFile);

    sUniqueName = (sExt.length()==0 ? sLocationId : sLocationId + "." + sExt);

    oOldFile = new File(sPath + sFile);
    iFileLen = new Long(oOldFile.length()).intValue();
    oOldFile.renameTo(new File(sPath + sUniqueName));
    oOldFile = null;

    if (null!=oConn && null!=sLocationId) {
      oStmt = oConn.prepareStatement("UPDATE " + DB.k_prod_locats + " SET " + DB.xfile + "=?," + DB.len_file + "=? WHERE " + DB.gu_location + "=?");
      oStmt.setString(1, sUniqueName);
      oStmt.setInt(2, iFileLen);
      oStmt.setString(3, sLocationId);
      oStmt.executeUpdate();
      oStmt.close();
      oStmt = null;
    } // fi (oConn && sLocationId)
  } // upload()

  // ----------------------------------------------------------

  public void delete(String sPath, String sFile, Connection oConn, String sLocationId) throws SQLException {
    File oFile;
    String sPathFile;
    PreparedStatement oStmt;

    if (null!=sPath && null!=sFile) {
      if (sPath.endsWith(sFileSeparator))
        sPathFile = sPath + sFile;
      else
        sPathFile = sPath + sFileSeparator + sFile;

      oFile = new File(sPathFile);
      oFile.delete();
      oFile = null;
    } // fi (sPath && sFile)

    if (null!=oConn && null!=sLocationId) {
      oStmt = oConn.prepareStatement("DELETE " + DB.k_prod_locats + " WHERE " + DB.gu_location + "=?");
      oStmt.setString(1, sLocationId);
      oStmt.executeUpdate();
      oStmt.close();
      oStmt = null;
    } // fi (oConn && sLocationId)
  } // delete()

  // ----------------------------------------------------------

  private String sFileSeparator;
}
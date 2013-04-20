package com.knowgate.training;

/*
  Copyright (C) 2003-2009  Know Gate S.L. All rights reserved.

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

import java.sql.PreparedStatement;
import java.sql.ResultSet;
import java.sql.SQLException;

import com.knowgate.jdc.JDCConnection;
import com.knowgate.dataobjs.DB;
import com.knowgate.dataobjs.DBPersist;
import com.knowgate.misc.Gadgets;

public class EducationDegree extends DBPersist {

  public EducationDegree() {
  	super (DB.k_education_degree, "EducationDegree");
  }
  
  public boolean store(JDCConnection oConn) throws SQLException {

    if (isNull(DB.gu_degree)) {
      put(DB.gu_degree, Gadgets.generateUUID());
    }

    return super.store(oConn);
  }
  
  /*
   * <p>Get GUID of a degree given its type and name</p>
   * Search is case sensitive
   * @param oConn JDCConnection
   * @param sGuWorkArea String GUID of WorkArea
   * @param sTpDegree Column tp_degree of table k_education_degree (optional, may be <b>null</b>)
   * @param sNmDegree Column nm_degree of table k_education_degree
   * @return GUID of degree or <b>null</b> if no degree with such name was found
   * @throws SQLException
   * @since 6.0
   */
  public static String getIdFromName(JDCConnection oConn, String sGuWorkArea, String sTpDegree, String sNmDegree)
  	throws SQLException {
  	
  	PreparedStatement oStmt;
  	ResultSet oRset;
  	String sGuDegree;
  	
  	if (sTpDegree==null) {
  	  oStmt = oConn.prepareStatement("SELECT "+DB.gu_degree+" FROM "+DB.k_education_degree+" WHERE "+DB.gu_workarea+"=? AND "+DB.nm_degree+"=?");
  	  oStmt.setString(1, sGuWorkArea);
  	  oStmt.setString(2, sNmDegree);
  	} else if (sTpDegree.length()==0) {
  	  oStmt = oConn.prepareStatement("SELECT "+DB.gu_degree+" FROM "+DB.k_education_degree+" WHERE "+DB.gu_workarea+"=? AND "+DB.nm_degree+"=?");
  	  oStmt.setString(1, sGuWorkArea);
  	  oStmt.setString(2, sNmDegree);	  
  	} else {
  	  oStmt = oConn.prepareStatement("SELECT "+DB.gu_degree+" FROM "+DB.k_education_degree+" WHERE "+DB.gu_workarea+"=? AND "+DB.tp_degree+"=? AND "+DB.nm_degree+"=?");
  	  oStmt.setString(1, sGuWorkArea);
  	  oStmt.setString(2, sTpDegree);	  
  	  oStmt.setString(3, sNmDegree);	  
  	}
  	oRset = oStmt.executeQuery();
  	if (oRset.next())
  	  sGuDegree = oRset.getString(1);
  	else
  	  sGuDegree = null;
  	oRset.close();
  	oStmt.close();
  	return sGuDegree;

  } // getIdFromName

  /*
   * <p>Get GUID of a degree given its type and identifier</p>
   * Search is case sensitive
   * @param oConn JDCConnection
   * @param sGuWorkArea String GUID of WorkArea
   * @param sTpDegree Column tp_degree of table k_education_degree (optional, may be <b>null</b>)
   * @param sIdDegree Column id_degree of table k_education_degree
   * @return GUID of degree or <b>null</b> if no degree with such name was found
   * @throws SQLException
   * @since 6.0
   */
  public static String getIdFromRef(JDCConnection oConn, String sGuWorkArea, String sTpDegree, String sIdDegree)
  	throws SQLException {
  	
  	PreparedStatement oStmt;
  	ResultSet oRset;
  	String sGuDegree;
  	
  	if (sTpDegree==null) {
  	  oStmt = oConn.prepareStatement("SELECT "+DB.gu_degree+" FROM "+DB.k_education_degree+" WHERE "+DB.gu_workarea+"=? AND "+DB.id_degree+"=?");
  	  oStmt.setString(1, sGuWorkArea);
  	  oStmt.setString(2, sIdDegree);
  	} else if (sTpDegree.length()==0) {
  	  oStmt = oConn.prepareStatement("SELECT "+DB.gu_degree+" FROM "+DB.k_education_degree+" WHERE "+DB.gu_workarea+"=? AND "+DB.id_degree+"=?");
  	  oStmt.setString(1, sGuWorkArea);
  	  oStmt.setString(2, sIdDegree);	  
  	} else {
  	  oStmt = oConn.prepareStatement("SELECT "+DB.gu_degree+" FROM "+DB.k_education_degree+" WHERE "+DB.gu_workarea+"=? AND "+DB.tp_degree+"=? AND "+DB.id_degree+"=?");
  	  oStmt.setString(1, sGuWorkArea);
  	  oStmt.setString(2, sTpDegree);	  
  	  oStmt.setString(3, sIdDegree);	  
  	}
  	oRset = oStmt.executeQuery();
  	if (oRset.next())
  	  sGuDegree = oRset.getString(1);
  	else
  	  sGuDegree = null;
  	oRset.close();
  	oStmt.close();
  	return sGuDegree;

  } // getIdFromRef
  
  public static final short ClassId = 67;
  private static final long serialVersionUID = 67l;
  
}

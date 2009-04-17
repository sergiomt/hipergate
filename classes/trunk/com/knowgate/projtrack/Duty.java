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

package com.knowgate.projtrack;

import com.knowgate.debug.DebugFile;
import com.knowgate.jdc.JDCConnection;
import com.knowgate.dataobjs.DB;
import com.knowgate.dataobjs.DBBind;
import com.knowgate.dataobjs.DBCommand;
import com.knowgate.dataobjs.DBPersist;
import com.knowgate.dataobjs.DBSubset;

import com.knowgate.misc.Calendar;
import com.knowgate.misc.Gadgets;

import java.sql.SQLException;
import java.sql.CallableStatement;
import java.sql.Statement;
import java.sql.ResultSet;

import java.math.BigDecimal;
import java.util.Date;
import java.util.HashMap;

public class Duty extends DBPersist {

  /**
   * Create empty Duty
   */
  public Duty() {
    super(DB.k_duties, "Duty");
  }

  // ----------------------------------------------------------

  /**
   * Load Duty from database
   */
  public Duty(JDCConnection oConn, String sIdDuty) throws SQLException {
    super(DB.k_duties,"Duty");

    Object aDuty[] = { sIdDuty };

    load (oConn,aDuty);
  }

  // ----------------------------------------------------------

  /**
   * <p>Delete Duty</p>
   * Calls k_sp_del_duty stored procedure.
   * @param oConn Database Connection
   * @throws SQLException
   */
  public boolean delete(JDCConnection oConn) throws SQLException {
    return Duty.delete(oConn, getString(DB.gu_duty));
  }

  // ----------------------------------------------------------

  /**
   * <p>Store Duty</p>
   * If gu_duty is null a new GUID is automatically assigned.<br>
   * dt_modified field is set to current date.
   * @param oConn Database Connection
   * @throws SQLException
   */
  public boolean store(JDCConnection oConn) throws SQLException {
    java.sql.Timestamp dtNow = new java.sql.Timestamp(DBBind.getTime());

    if (!AllVals.containsKey(DB.gu_duty))
      put(DB.gu_duty, Gadgets.generateUUID());

    // Forzar la fecha de modificación del registro
    replace(DB.dt_modified, dtNow);
    
    if (!isNull(DB.dt_start) || !isNull(DB.dt_scheduled)) {
      Date dtBegin = isNull(DB.dt_start) ? getDate(DB.dt_scheduled) : getDate(DB.dt_start);
      Date dtEnd = isNull(DB.dt_end) ? new Date(dtBegin.getTime()+86400000l) : getDate(DB.dt_end);
      replace(DB.ti_duration, new BigDecimal(Calendar.DaysBetween(dtBegin, dtEnd)));
      
      Date oPrjEnd = DBCommand.queryDateTime(oConn, "SELECT "+DB.dt_end+" FROM "+DB.k_projects+" WHERE "+DB.gu_project+"='"+getString(DB.gu_project)+"'");
      boolean bUpdateProject = false;
      if (oPrjEnd==null)
      	bUpdateProject = true;
      else if (oPrjEnd.compareTo(dtEnd)<0)
      	bUpdateProject = true;
	  if (bUpdateProject)
	  	Project.setEndDate(oConn, getString(DB.gu_project), dtEnd);
    } // fi

    return super.store(oConn);
  } // store

  /**
   * <p>Get resources assigned to this duty</p>
   * @param oConn Database Connection
   * @throws IllegalStateException
   * @throws SQLException
   * @since 5.0
   */
  public Resource[] resources(JDCConnection oConn)
  	throws IllegalStateException,SQLException {
    
    if (isNull(DB.gu_duty))
      throw new IllegalStateException("Duty.resources() Duty must be loaded before calling resources() method");

    Resource[] aResces = null;
    DBSubset oResces = new DBSubset(DB.k_x_duty_resource,
                                    DB.nm_resource+","+DB.pct_time,
                                    DB.gu_duty+"=?",10);
    int nResources = oResces.load(oConn, new Object[]{getString(DB.gu_duty)});
    if (nResources>0) {
      String sWorkArea = DBCommand.queryStr(oConn, "SELECT "+DB.gu_owner+" FROM "+DB.k_projects+" p,"+DB.k_duties+" d WHERE d."+DB.gu_project+"=p."+DB.gu_project+" AND d."+DB.gu_duty+"='"+getString(DB.gu_duty)+"'");
      aResces = new Resource[nResources];
      for (int r=0; r<nResources; r++) {
      	aResces[r] = new Resource();
      	aResces[r].load(oConn, sWorkArea, oResces.getString(0,r));
      	if (!oResces.isNull(1,r))
      	  aResces[r].setWorkLoadPercentage(oResces.getShort(1,r));
      } // next
    } // fi

    return aResces;
  } // resources

  public String toXML(String sIdent, String sDelim, HashMap oAttrs) {
    return super.toXML(sIdent, sDelim, oAttrs);
  }

  // **********************************************************
  // Static Methods

  /**
   * <p>Delete Duty</p>
   * Calls k_sp_del_duty stored procedure.
   * @param oConn Database Connection
   * @param sDutyGUID GUID of Duty to be deleted
   * @throws SQLException
   */
  public static boolean delete(JDCConnection oConn, String sDutyGUID) throws SQLException {
    boolean bRetVal;

    if (oConn.getDataBaseProduct()==JDCConnection.DBMS_POSTGRESQL) {
      if (DebugFile.trace) DebugFile.writeln("Connection.executeQuery(SELECT k_sp_del_duty ('" + sDutyGUID + "'))");
      Statement oStmt = oConn.createStatement();
      ResultSet oRSet = oStmt.executeQuery("SELECT k_sp_del_duty ('" + sDutyGUID + "')");
      oRSet.close();
      oStmt.close();
      bRetVal = true;
    }
    else {
      if (DebugFile.trace) DebugFile.writeln("Connection.prepareCall({ call k_sp_del_duty ('" + sDutyGUID + "')})");
      CallableStatement oCall = oConn.prepareCall("{call k_sp_del_duty ('" + sDutyGUID + "')}");
      bRetVal = oCall.execute();
      oCall.close();
    }

    return bRetVal;
  } // delete()

  // **********************************************************
  // Constantes Publicas

  public static final short ClassId = 81;
}
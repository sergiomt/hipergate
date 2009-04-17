/*
  Copyright (C) 2003-2006  Know Gate S.L. All rights reserved.
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

package com.knowgate.http.portlets;

import java.util.Enumeration;
import java.util.ResourceBundle;
import java.util.Locale;
import java.util.Date;

import javax.portlet.PortletConfig;
import javax.portlet.PortletContext;

import java.sql.Connection;
import java.sql.PreparedStatement;
import java.sql.SQLException;
import java.sql.Timestamp;

import com.knowgate.debug.DebugFile;
import com.knowgate.dataobjs.DB;

/**
 * @author Sergio Montoro Ten
 * @version 1.0
 */

public class HipergatePortletConfig implements PortletConfig {

  private HipergatePortletContext oCtx;

  public HipergatePortletConfig() {
    oCtx = new HipergatePortletContext();
  }

  public String getPortletName () {
    return null;
  }

  public PortletContext getPortletContext() {
    return oCtx;
  }

  public ResourceBundle getResourceBundle(Locale locale) {
    return null;
  }

  public String getInitParameter(String name) {
    return oCtx.getInitParameter(name);
  }

  public Enumeration getInitParameterNames() {
    return oCtx.getInitParameterNames();
  }

  // ---------------------------------------------------------------------------

  /**
   * <p>Touch portlet last modified date</p>
   * Portlet last modified date is used for caching portlet output
   * @param oCon JDBC database connection
   * @param sUserId GUID of ACLUser owner of the portlet
   * @param sPortletNm GenericPortlet subclass name
   * @param sWrkAId GUID of WorkArea where portlet is shown
   * @throws SQLException
   */
  public static void touch (Connection oCon, String sUserId, String sPortletNm, String sWrkAId)
    throws SQLException {

    if (DebugFile.trace) {
      DebugFile.writeln("Begin HipergatePortletConfig.touch([Connection],"+sUserId+","+sPortletNm+","+sWrkAId+")");
      DebugFile.incIdent();
    }

    PreparedStatement oStm = null;
    int iAffected = 0;

    try {
      oStm = oCon.prepareStatement("UPDATE " + DB.k_x_portlet_user + " SET " + DB.dt_modified + "=? WHERE " + DB.gu_user + "=? AND " + DB.nm_portlet + "=? AND " + DB.gu_workarea + "=?");
      oStm.setTimestamp(1, new Timestamp(new Date().getTime()));
      oStm.setString(2, sUserId);
      oStm.setString(3, sPortletNm);
      oStm.setString(4, sWrkAId);
      iAffected = oStm.executeUpdate();
      oStm.close();
      oStm = null;
    }
    catch (SQLException sqle) {
      DebugFile.decIdent();
      try { if (null!=oStm) oStm.close(); } catch (SQLException ignore) {}
      throw new SQLException (sqle.getMessage(),sqle.getSQLState(), sqle.getErrorCode());
    }
    if (DebugFile.trace) {
      DebugFile.decIdent();
      DebugFile.writeln("End HipergatePortletConfig.touch() : " + String.valueOf(iAffected));
    }
  } // touch
}

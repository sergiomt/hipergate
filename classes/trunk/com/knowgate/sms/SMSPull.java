/*
  Copyright (C) 2008  Know Gate S.L. All rights reserved.

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

package com.knowgate.sms;

import java.util.Properties;

import java.sql.Connection;
import java.sql.DriverManager;
import java.sql.PreparedStatement;
import java.sql.SQLException;
import java.sql.Timestamp;
import java.sql.Types;

import com.knowgate.debug.DebugFile;
import com.knowgate.misc.Environment;

public class SMSPull {

  // --------------------------------------------------------------------------

  private Connection oCon;
  private PreparedStatement oRcv;
  private PreparedStatement oAck;

  // --------------------------------------------------------------------------

  public SMSPull() {
  	oCon = null;
  	oAck = oRcv = null;
  }

  // --------------------------------------------------------------------------

  /**
   * Connect to JDBC DataSource for storing incoming messages and notifications
   * @param sDataSource String Name of properties file for connecting to database (typically "hipergate")
   * @param sUser String GUID of user from k_users table
   * @param sPassword String User's passwords from k_users table
   * @throws SQLException
   */
  public void connect(String sDataSource, String sUser, String sPassword)
    throws SQLException {
    
    if (oCon!=null) {
      if (!oCon.isClosed()) throw new SQLException("SMSPull.connect() Already connected to data source");
    }
    
    if (DebugFile.trace) {
      DebugFile.writeln("Begin SMSPull.connect("+sDataSource+","+sUser+", ...)");
      DebugFile.incIdent();
    }

    Properties oDbBind = Environment.getProfile(sDataSource);
    try {
      @SuppressWarnings("unused")
	  Class cDriver = Class.forName(oDbBind.getProperty("driver"));
    } catch (ClassNotFoundException cnfe) {
      if (DebugFile.trace)DebugFile.decIdent();
      throw new SQLException("SMSPull.connect() Could not find class for driver "+oDbBind.getProperty("driver"));
    }
    
	oCon = DriverManager.getConnection(oDbBind.getProperty("dburl"),
								oDbBind.getProperty("dbuser"),
								oDbBind.getProperty("dbpassword"));
	oCon.setAutoCommit(true);

	oRcv = oCon.prepareStatement("INSERT INTO k_sms_received (id_msg,id_customer,id_chain,dt_received,bo_readed,dt_readed,nu_msisdn,tx_body) VALUES (?,?,?,?,0,NULL,?,?)");
	oAck = oCon.prepareStatement("INSERT INTO k_sms_notifications (id_msg,dt_received,bo_readed,dt_readed,id_error,id_status) VALUES (?,?,0,NULL,?,?)");

    if (DebugFile.trace) {
      DebugFile.decIdent();
      DebugFile.writeln("End SMSPull.connect()");
    }

  } // connect

  // --------------------------------------------------------------------------

  /**
   * Close JDBC connection to database
   */
  public void close()
    throws SQLException {
	if (null==oCon) throw new SQLException("SMSPull.close() Connection does not exist");
	if (oCon.isClosed()) throw new SQLException("SMSPull.close() Not connected to data source");

	if (null!=oAck) oAck.close();
	if (null!=oRcv) oRcv.close();
	
	oCon.close();
	oCon=null;
  } // close

  // --------------------------------------------------------------------------

  /**
   * Store an incoming message at the database
   * @param oMsg SMSMessage
   * @throws SQLException
   */

  public void receive(SMSMessage oMsg)
  	throws SQLException {

    if (DebugFile.trace) {
      DebugFile.writeln("Begin SMSPull.receive("+oMsg.customerAccount()+","+oMsg.messageId()+","+oMsg.msisdnNumber()+")");
      DebugFile.incIdent();
    }

	oRcv.setString(1, oMsg.customerAccount());
	oRcv.setString(2, oMsg.messageId());
	oRcv.setNull(3, Types.VARCHAR);
	oRcv.setTimestamp(4, new Timestamp(oMsg.dateStamp().getTime()));
	oRcv.setString(5, oMsg.msisdnNumber());
	oRcv.setString(6, oMsg.textBody());
	oRcv.executeUpdate();

    if (DebugFile.trace) {
      DebugFile.decIdent();
      DebugFile.writeln("End SMSPull.receive()");
    }

  } // receive

  // --------------------------------------------------------------------------
  
  public void acknowledge(SMSResponse oRsp)
  	throws SQLException {

    if (DebugFile.trace) {
      DebugFile.writeln("Begin SMSPull.acknowledge("+oRsp.messageId()+","+oRsp.errorCode().toString()+","+oRsp.notificationStatusCode().toString()+")");
      DebugFile.incIdent();
    }
  		
	oAck.setString(1, oRsp.messageId());
	oRcv.setTimestamp(2, new Timestamp(oRsp.dateStamp().getTime()));
	oAck.setInt(3, oRsp.errorCode().intValue());
	oAck.setInt(4, oRsp.notificationStatusCode().intValue());
	oAck.executeUpdate();

    if (DebugFile.trace) {
      DebugFile.decIdent();
      DebugFile.writeln("End SMSPull.acknowledge()");
    }

  } // acknowledge

  // --------------------------------------------------------------------------

} // SMSPull

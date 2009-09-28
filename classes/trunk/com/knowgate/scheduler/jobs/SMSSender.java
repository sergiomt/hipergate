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

package com.knowgate.scheduler.jobs;

import java.io.FileNotFoundException;
import java.io.IOException;

import java.util.Date;
import java.util.Properties;

import java.sql.PreparedStatement;
import java.sql.SQLException;
import java.sql.Timestamp;
import java.sql.Types;

import com.knowgate.debug.DebugFile;
import com.knowgate.dataobjs.DB;
import com.knowgate.jdc.JDCConnection;
import com.knowgate.scheduler.Job;
import com.knowgate.scheduler.Atom;
import com.knowgate.sms.SMSPush;
import com.knowgate.sms.SMSPushFactory;
import com.knowgate.sms.SMSMessage;
import com.knowgate.sms.SMSResponse;
import com.knowgate.misc.Gadgets;

public class SMSSender extends Job {

  // --------------------------------------------------------------------------
	
	/**
	 * Send SMS message for an Atom
	 * @param oAtm
	 * @throws SQLException
	 * @throws FileNotFoundException
	 * @throws IOException
	 * @throws MessagingException
	 * @throws NullPointerException
	 * @return SMSResponse Object
	 */
  public Object process(Atom oAtm)
  	throws SQLException, FileNotFoundException,
  	       IOException, NullPointerException,
  	       ClassNotFoundException,InstantiationException, IllegalAccessException {

    if (DebugFile.trace) {
      DebugFile.writeln("Begin SMSSender.process("+oAtm.getString(DB.gu_job)+":"+String.valueOf(oAtm.getInt(DB.pg_atom))+")");
      DebugFile.incIdent();
    }

	if (null==oAtm) {
	  if (DebugFile.trace) {
	  	DebugFile.writeln("NullPointerException SMSSender.process() Atom may not be null");
	  	DebugFile.decIdent();
	  }
	  throw new NullPointerException("SMSSender.process() Atom may not be null");
	}

	if (null==getDataBaseBind().getProperty("smsprovider")) {
	  if (DebugFile.trace) {
	  	DebugFile.writeln("NullPointerException SMSSender.process() smsprovider property not found at "+getDataBaseBind().getProfileName()+".cnf file");
	  	DebugFile.decIdent();
	  }
	  throw new NullPointerException("NullPointerException SMSSender.process() smsprovider property not found at "+getDataBaseBind().getProfileName()+".cnf file");
	}

    SMSPush oPsh = SMSPushFactory.newInstanceOf(getDataBaseBind().getProperty("smsprovider"));

	SMSMessage oMsg = new SMSMessage(SMSMessage.MType.PLAIN_TEXT, Gadgets.generateUUID(),
									 getDataBaseBind().getProperty("smsaccount"),
									 oAtm.getString(DB.mov_phone),
									 getStringNull(DB.tl_job,""),
									 getParameter("txt"), null, new Date()); 

	Properties oPrp = new Properties();
	oPrp.put("from", getParameter("from"));
		
	oPsh.connect(getDataBaseBind().getProperty("smsurl"),
			     getDataBaseBind().getProperty("smsaccount"),
			     getDataBaseBind().getProperty("smspassword"),
			     oPrp);
	SMSResponse oRsp = oPsh.push (oMsg);
	oPsh.close();

    JDCConnection oCon = getDataBaseBind().getConnection("SMSSender");
    oCon.setAutoCommit (true);
	PreparedStatement oStm = oCon.prepareStatement("INSERT INTO "+DB.k_sms_audit+" (id_sms,gu_workarea,pg_part,nu_msisdn,id_msg,gu_batch,bo_success,nu_error,id_status,dt_sent,gu_writer,gu_address,gu_contact,gu_company,tx_msg,tx_err) "+
		                                           "VALUES ('"+oRsp.messageId()+"','"+getString(DB.gu_workarea)+"',1,'"+oAtm.getString(DB.mov_phone)+"',NULL,'"+getString(DB.gu_job)+"',?,?,?,?,'"+getString(DB.gu_writer)+"',?,?,?,?,?)");

	oStm.setShort(1, (short) (oRsp.errorCode()==SMSResponse.ErrorCode.NONE ? 1 : 0));
	oStm.setInt(2, (int) oRsp.errorCode().intValue());
	oStm.setInt(3, (int) oRsp.notificationStatusCode().intValue());
	oStm.setTimestamp(4, new Timestamp(oRsp.dateStamp().getTime()));
    oStm.setNull(5, Types.CHAR);
	if (oAtm.isNull(DB.gu_contact))
      oStm.setNull(6, Types.CHAR);
    else
      oStm.setString(6, oAtm.getString(DB.gu_contact));
	if (oAtm.isNull(DB.gu_company))
      oStm.setNull(7, Types.CHAR);
    else
	  oStm.setString(7, oAtm.getString(DB.gu_company));
    oStm.setString(8, getParameter("txt"));
    if (oRsp.errorCode()==SMSResponse.ErrorCode.NONE)
      oStm.setNull(9, Types.VARCHAR);
    else
      oStm.setString(9, Gadgets.left(oRsp.errorMessage(),254));
	  oStm.executeUpdate();
	  oStm.close();
    oCon.close("SMSSender");

    if (DebugFile.trace) {
      DebugFile.decIdent();
      DebugFile.writeln("End SMSSender.process()");
    }
	return oRsp;
  } // process

  // --------------------------------------------------------------------------
  
  public void free() {
  
  }	

  // --------------------------------------------------------------------------

}

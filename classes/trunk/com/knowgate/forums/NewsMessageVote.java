/*
  Copyright (C) 2007  Know Gate S.L. All rights reserved.
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
package com.knowgate.forums;

import java.util.Date;
import java.sql.SQLException;
import java.sql.ResultSet;
import java.sql.PreparedStatement;
import java.sql.Timestamp;
import java.sql.Types;

import com.knowgate.debug.DebugFile;
import com.knowgate.jdc.JDCConnection;
import com.knowgate.dataobjs.DB;
import com.knowgate.dataobjs.DBBind;
import com.knowgate.dataobjs.DBPersist;
import com.knowgate.misc.Gadgets;

public class NewsMessageVote extends DBPersist {

  // --------------------------------------------------------------------------

  public NewsMessageVote () {
    super(DB.k_newsmsg_vote,"NewsMessageVote");
  }
 
  // --------------------------------------------------------------------------

  public static int insert (JDCConnection oCon, String sGuMsg, Integer oScore,
		  	                String sIpAddr, String sNmAuthor, String sGuWriter,
		  	                String sTxEmail, String sTxVote) throws SQLException {

	if (DebugFile.trace) {
	  DebugFile.writeln("Begin NewsMessageVote.insert([Connection], " + sGuMsg + ", ...)");
	  DebugFile.incIdent();
	}

    if (null!=sTxEmail) {
	  if (!Gadgets.checkEMail(sTxEmail)) {
	    if (DebugFile.trace) {
		  DebugFile.decIdent();
		}
	    throw new SQLException ("NewsMessageVote.insert() "+sTxEmail+" is not a valid e-mail address");
	  } // fi
	} // fi
 
    if (sNmAuthor==null && null!=sGuWriter) {
      PreparedStatement oQry = oCon.prepareStatement("SELECT "+DB.nm_user+","+DB.tx_surname1+","+DB.tx_surname2+","+DB.tx_nickname+" FROM "+DB.k_users+" WHERE "+DB.gu_user+"=?",ResultSet.TYPE_FORWARD_ONLY, ResultSet.CONCUR_READ_ONLY);
      oQry.setString(1, sGuWriter);
      ResultSet oRst = oQry.executeQuery();
      if (oRst.next()) {
    	String sName = oRst.getString(1);
    	String sSur1 = oRst.getString(2);
    	String sSur2 = oRst.getString(3);
    	String sNick = oRst.getString(4);
    	if (sName==null) {
    	  sNmAuthor = sNick;
    	} else {
    	  sNmAuthor = sName;
    	  if (null!=sSur1) sNmAuthor += " " + sSur1;
    	  if (null!=sSur2) sNmAuthor += " " + sSur2;
    	}
      }
      oRst.close();
      oQry.close();
    } // fi (sNmAuthor==null && null!=sGuWriter)
 
    int iPgVote = DBBind.nextVal(oCon, "seq_k_msg_votes");
 
	PreparedStatement oIns = oCon.prepareStatement("INSERT INTO "+DB.k_newsmsg_vote+" ("+
    		                                       DB.gu_msg+","+DB.pg_vote+","+DB.dt_published+","+DB.od_score+","+DB.ip_addr+","+DB.nm_author+","+DB.gu_writer+","+DB.tx_email+","+DB.tx_vote+") VALUES (?,?,?,?,?,?,?,?,?)");
    oIns.setString(1,sGuMsg);
    oIns.setInt(2, iPgVote);
    oIns.setTimestamp(3, new Timestamp(new Date().getTime()));
    if (null==oScore)
      oIns.setNull(4, Types.INTEGER);
    else
      oIns.setInt(4, oScore.intValue());
    if (null==sIpAddr)
      oIns.setNull(5, Types.VARCHAR);
    else
      oIns.setString(5, sIpAddr);
    if (null==sNmAuthor)
      oIns.setNull(6, Types.VARCHAR);
    else
      oIns.setString(6, sNmAuthor);
    if (null==sGuWriter)
      oIns.setNull(7, Types.VARCHAR);
    else
      oIns.setString(7, sGuWriter);
    if (null==sTxEmail)
      oIns.setNull(8, Types.VARCHAR);
    else
      oIns.setString(8, sTxEmail);
    if (null==sTxVote)
      oIns.setNull(9, Types.VARCHAR);
    else
      oIns.setString(9, sTxVote);
    oIns.executeUpdate();
    oIns.close();

    PreparedStatement oUpd = oCon.prepareStatement("UPDATE "+DB.k_newsmsgs+" SET "+DB.nu_votes+"="+DB.nu_votes+"+1 WHERE "+DB.gu_msg+"=?");
    oUpd.setString(1, sGuMsg);
    oUpd.executeUpdate();
    oUpd.close();

    if (DebugFile.trace) {
      DebugFile.decIdent();
      DebugFile.writeln("End NewsMessageVote.insert() : " + String.valueOf(iPgVote));
    }
    return iPgVote;
  } // insert

} // NewsMessageVote

/*
  Copyright (C) 2009  Know Gate S.L. All rights reserved.
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

import java.sql.PreparedStatement;
import java.sql.ResultSet;
import java.sql.SQLException;

import com.knowgate.jdc.JDCConnection;
import com.knowgate.dataobjs.DB;
import com.knowgate.dataobjs.DBBind;
import com.knowgate.acl.ACLUser;
import com.knowgate.addrbook.Fellow;
import com.knowgate.crm.Contact;
import com.knowgate.crm.Company;
import com.knowgate.crm.Supplier;

public class Resource  {

  private int iPg;
  private String sVl;
  private short iPct;
  private String sFullName;
  private String sEmail;
  private String sPhone;

  public Resource() {
    iPg = 0;
    sVl = "";
    iPct = 100;
  }
  
  public int getProgressive() {
    return iPg;
  }

  public void setProgressive(int iProgressive) {
    iPg = iProgressive;
  }

  public String getValue() {
    return sVl;
  }
  
  public String getFullName() {
    return sFullName;
  }

  public String getEmail() {
    return sEmail;
  }

  public String getPhone() {
    return sPhone;
  }

  public void setWorkLoadPercentage(short iPercentage) {
    iPct = iPercentage;
  }

  public short getWorkLoadPercentage() {
    return iPct;
  }

  public boolean load (JDCConnection oConn, String sWorkArea, String sId) throws SQLException {
    ACLUser  oUser = new ACLUser();
    Fellow   oFellw = new Fellow();
    Contact  oCont = new Contact();
    Company  oComp = new Company();
    Supplier oSupl = new Supplier();
    boolean bFound;
    
	PreparedStatement oStmt = oConn.prepareStatement("SELECT "+DB.pg_lookup+" FROM "+DB.k_duties_lookup+" WHERE "+DB.gu_owner+"=? AND "+DB.id_section+"='nm_resource' AND "+DB.vl_lookup+"=?",
	                                                 ResultSet.TYPE_FORWARD_ONLY, ResultSet.CONCUR_READ_ONLY);
	oStmt.setString(1, sWorkArea);
	oStmt.setString(2, sId);
	ResultSet oRSet = oStmt.executeQuery();
	bFound = oRSet.next();
	if (bFound) iPg = oRSet.getInt(1);
	oRSet.close();
	oStmt.close();

	if (bFound) {
      sVl = sId;

      if (oFellw.load(oConn, sId)) {
	    sFullName = (oFellw.getStringNull(DB.tx_name,"")+" "+oFellw.getStringNull(DB.tx_surname,"")).trim();
	    sEmail = oUser.getStringNull(DB.tx_email,"");
	    sPhone = oUser.getStringNull(DB.work_phone,"");
      } else if (oUser.load(oConn, sId)) {
	    sFullName = (oUser.getStringNull(DB.nm_user,"")+" "+oUser.getStringNull(DB.tx_surname1,"")+" "+oUser.getStringNull(DB.tx_surname2,"")).trim();
	    sEmail = oUser.getStringNull(DB.tx_main_email,"");
	    sPhone = "";
      } else if (oCont.load(oConn, sId)) {
	    sFullName = (oCont.getStringNull(DB.tx_name,"")+" "+oCont.getStringNull(DB.tx_surname,"")).trim();
	    sEmail = "";
	    sPhone = "";
      } else if (oComp.load(oConn, sId)) {
	    sFullName = oComp.getStringNull(DB.nm_commercial,oComp.getString(DB.nm_legal));
	    sEmail = "";
	    sPhone = "";
      } else if (oSupl.load(oConn, sId)) {
	    sFullName = oSupl.getStringNull(DB.nm_commercial,oComp.getString(DB.nm_legal));
	    sEmail = oSupl.getAddress().getStringNull(DB.tx_email,"");
	    sPhone = oSupl.getAddress().getStringNull(DB.work_phone,"");
      } else {
      	
	    oStmt = oConn.prepareStatement("SELECT "+DBBind.Functions.ISNULL+"("+DB.tr_+"es,"+DB.tr_+"en) FROM "+DB.k_duties_lookup+" WHERE "+DB.gu_owner+"=? AND "+DB.id_section+"='nm_resource' AND "+DB.vl_lookup+"=?",
	                                   ResultSet.TYPE_FORWARD_ONLY, ResultSet.CONCUR_READ_ONLY);
	    oStmt.setString(1, sWorkArea);
	    oStmt.setString(2, sId);
	    oRSet = oStmt.executeQuery();
	    oRSet.next();
	    sFullName = oRSet.getString(1);
	    oRSet.close();
	    oStmt.close();        
	    sEmail = "";
	    sPhone = "";
      }
	} // fi (bFound)
	return bFound;	
  } // load
}

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

import java.sql.SQLException;

import com.knowgate.jdc.JDCConnection;
import com.knowgate.dataobjs.DB;
import com.knowgate.dataobjs.DBCommand;
import com.knowgate.dataobjs.DBPersist;
import com.knowgate.misc.Gadgets;

public class EducationInstitution extends DBPersist {

  public EducationInstitution() {
  	super (DB.k_education_institutions, "EducationInstitution");
  }
  
  public boolean store(JDCConnection oConn) throws SQLException {
    if (isNull(DB.gu_institution)) put(DB.gu_institution, Gadgets.generateUUID());
    return super.store(oConn);	
  }

  public boolean delete(JDCConnection oConn) throws SQLException {
	DBCommand.executeUpdate(oConn, "UPDATE "+DB.k_contact_education+" SET "+DB.gu_institution+"=NULL WHERE "+DB.gu_institution+"='"+getStringNull(DB.gu_institution,"")+"'");
    return super.delete(oConn);
  }

  public static final short ClassId = 66;
}

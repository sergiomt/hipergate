/*
  Copyright (C) 2003-2009 Know Gate S.L. All rights reserved.

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

import java.sql.SQLException;

import com.knowgate.dataobjs.DB;
import com.knowgate.jdc.JDCConnection;
import com.knowgate.dataobjs.DBBind;
import com.knowgate.dataobjs.DBPersist;

public class BugTrack extends DBPersist {

  public BugTrack() {
    super(DB.k_bugs_track, "BugTrack");
  }
  
  public boolean store(JDCConnection oConn) throws SQLException {
  	if (!AllVals.containsKey(DB.pg_bug_track)) {
  	  put(DB.pg_bug_track, DBBind.nextVal(oConn, "seq_k_bugs_track"));
  	}
  	return super.store(oConn);
  } // store
}

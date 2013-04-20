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

import com.knowgate.dataobjs.DB;
import com.knowgate.dataobjs.DBCommand;
import com.knowgate.dataobjs.DBPersist;
import com.knowgate.jdc.JDCConnection;
import com.knowgate.misc.Gadgets;

/**
 * @author Ingenieria Informatica Empresarial, S.L.
 * @version 1.0
 */
public class ContactShortCourses extends DBPersist {
	
	public static final short ClassId = 100;

	public ContactShortCourses() {
		super(DB.k_contact_short_courses, "ContactShortCourses");
	}

	@Override
	public boolean store(JDCConnection oConn) throws SQLException {
		if (isNull(DB.ix_scourse)) {
			Integer oMaxDg = DBCommand.queryMaxInt(oConn, DB.ix_scourse,DB.k_contact_short_courses, DB.gu_contact + "='"+ getString(DB.gu_contact) + "'");
			if (null == oMaxDg) oMaxDg = new Integer(1);
			put(DB.ix_scourse, oMaxDg.intValue());
		}
		if (!AllVals.containsKey(DB.gu_scourse)) {
			put(DB.gu_scourse, Gadgets.generateUUID());
		}
		return super.store(oConn);
	} // store

	
}

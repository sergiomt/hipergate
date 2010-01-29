package com.knowgate.training;

import java.sql.SQLException;

import com.knowgate.dataobjs.DB;
import com.knowgate.dataobjs.DBPersist;
import com.knowgate.jdc.JDCConnection;
import com.knowgate.misc.Gadgets;

public class ContactExperience extends DBPersist {

	public static final short ClassId = 102;
	
	public ContactExperience() {
		super(DB.k_contact_experience, "ContactExperience");
	}

	@Override
	public boolean store(JDCConnection oConn) throws SQLException {


		if (!AllVals.containsKey(DB.gu_experience)) {
			put(DB.gu_experience, Gadgets.generateUUID());
		}
		return super.store(oConn);
	} // store
}

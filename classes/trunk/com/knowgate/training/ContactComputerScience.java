package com.knowgate.training;

import java.sql.SQLException;

import com.knowgate.dataobjs.DB;
import com.knowgate.dataobjs.DBPersist;
import com.knowgate.jdc.JDCConnection;
import com.knowgate.misc.Gadgets;

public class ContactComputerScience extends DBPersist {

	public static final short ClassId = 104;
	
	public ContactComputerScience() {
		super(DB.k_contact_computer_science, "ContactComputerScience");
	}

	@Override
	public boolean store(JDCConnection oConn) throws SQLException {

		if (!AllVals.containsKey(DB.gu_ccsskill)) {
			put(DB.gu_ccsskill, Gadgets.generateUUID());
		}
		return super.store(oConn);
	} // store
}

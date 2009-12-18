package com.knowgate.training;

import java.sql.SQLException;

import com.knowgate.dataobjs.DB;
import com.knowgate.dataobjs.DBPersist;
import com.knowgate.jdc.JDCConnection;
import com.knowgate.misc.Gadgets;

public class ContactLanguages extends DBPersist {

	public ContactLanguages() {
		super(DB.k_contact_languages, "ContactLanguages");
	}

	@Override
	public boolean store(JDCConnection oConn) throws SQLException {

		
		return super.store(oConn);
	} // store
}

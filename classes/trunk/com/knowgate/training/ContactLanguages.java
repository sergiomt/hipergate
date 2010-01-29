package com.knowgate.training;

import java.sql.SQLException;

import com.knowgate.dataobjs.DB;
import com.knowgate.dataobjs.DBPersist;
import com.knowgate.jdc.JDCConnection;

public class ContactLanguages extends DBPersist {

	public static final short ClassId = 101;
	
	public ContactLanguages() {
		super(DB.k_contact_languages, "ContactLanguages");
	}

	@Override
	public boolean store(JDCConnection oConn) throws SQLException {

		
		return super.store(oConn);
	} // store
}

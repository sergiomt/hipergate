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

package com.knowgate.crm;

import java.sql.Connection;
import java.sql.SQLException;

import java.util.HashMap;
import java.util.Iterator;

import com.knowgate.misc.Gadgets;
import com.knowgate.dataobjs.DB;
import com.knowgate.hipergate.datamodel.ImportLoader;
import com.knowgate.hipergate.datamodel.ColumnList;

/**
 * <p>Load Company and Address data from a VCard Record</p>
 * Company loader creates or updates simultaneously registers at k_contacts, k_companies and k_addresses tables and the links between them k_x_contact_addr.
 * @author Sergio Montoro Ten
 * @version 5.0
 */

public class VCardLoader implements ImportLoader {
	
	private ContactLoader oDelegateTo;

	/**
	 * Default Constructor
	 */
	public VCardLoader() {
		oDelegateTo = new ContactLoader();
	}

    // ---------------------------------------------------------------------------

    /**
     * Create ContactLoader and call prepare() on Connection
     * @param oConn Connection
     * @throws SQLException
    */
    public VCardLoader(Connection oConn) throws SQLException {
	  oDelegateTo = new ContactLoader();
	  oDelegateTo.prepare(oConn, null);
    }

    // ---------------------------------------------------------------------------

	public int columnCount() {
	  return oDelegateTo.columnCount();
	}

    // ---------------------------------------------------------------------------

	public String[] columnNames() throws IllegalStateException {
	  return oDelegateTo.columnNames();
	}

    // ---------------------------------------------------------------------------

	/**
	 * Method get
	 * @param iColumnIndex
	 * @throws ArrayIndexOutOfBoundsException
	 * @return
	 */
	public Object get(int iColumnIndex) throws ArrayIndexOutOfBoundsException {
      return oDelegateTo.get(iColumnIndex);
	}

    // ---------------------------------------------------------------------------

	/**
	 * Method get
	 * @param sColumnName
	 * @throws ArrayIndexOutOfBoundsException
	 * @return
	 */
	public Object get(String sColumnName) throws ArrayIndexOutOfBoundsException {
      return oDelegateTo.get(sColumnName);
	}

    // ---------------------------------------------------------------------------

	/**
	 * Method getColumnIndex
	 * @param sColumnName
	 * @return
	 */
	public int getColumnIndex(String sColumnName) {
      return oDelegateTo.getColumnIndex(sColumnName);
	}

    // ---------------------------------------------------------------------------

	/**
	 * Method put
	 * @param iColumnIndex
	 * @param oValue
	 * @throws ArrayIndexOutOfBoundsException
	 */
	public void put(int iColumnIndex, Object oValue) throws ArrayIndexOutOfBoundsException {
	  oDelegateTo.put(iColumnIndex, oValue);
	}

	/**
	 * Method put
	 * @param sColumnName
	 * @param oValue
	 * @throws ArrayIndexOutOfBoundsException
	 */
	public void put(String sColumnName, Object oValue) throws ArrayIndexOutOfBoundsException {
	  oDelegateTo.put(sColumnName, oValue);
	}

	public void put (HashMap<String,String> oVCard) {
	  setAllColumnsToNull();
	  String[] aLine;
	  Iterator oKeys = oVCard.keySet().iterator();
	  while (oKeys.hasNext()) {
	  	String sKey = (String) oKeys.next();
	  	String sVal = (String) oVCard.get(sKey);
	  	if (sKey.equalsIgnoreCase("N")) {
	  	  if (sVal.indexOf(';')>0 && sVal.indexOf(';')<sVal.length()-1) {
	        aLine = Gadgets.split(sVal,';');
	        put(DB.tx_surname, Gadgets.left(aLine[0],100));     
	        put(DB.tx_name, Gadgets.left(aLine[1],100));
	  	  } else {
	        put(DB.tx_name, Gadgets.left(Gadgets.removeChar(sVal,';'),100));
	  	  }	      
	  	} else if (sKey.equalsIgnoreCase("FN")) {
	        put(DB.contact_person, Gadgets.left(sVal,100));
	  	} else if (sKey.equalsIgnoreCase("TITLE")) {
	        put(DB.de_title, Gadgets.left(sVal,50));
	  	} else if (sKey.equalsIgnoreCase("ORG")) {
	        put(DB.nm_legal, Gadgets.left(sVal,70));
	  	} else if (sKey.equalsIgnoreCase("EMAIL;INTERNET")) {
	        put(DB.tx_email, Gadgets.left(sVal,100));
	  	}
	  } // wend
	} // put

	/**
	 * Method setAllColumnsToNull
	 */
	public void setAllColumnsToNull() {
      oDelegateTo.setAllColumnsToNull();
	}

	/**
	 * Method prepare
	 * @param oConn
	 * @param oCols
	 * @throws SQLException
	 */
	public void prepare(Connection oConn, ColumnList oCols) throws SQLException {
      oDelegateTo.prepare(oConn, oCols);
	}

	/**
	 * Method close
	 * @throws SQLException
	 */
	public void close() throws SQLException {
      oDelegateTo.close();
	}

	/**
	 * Method store
	 * @param oConn
	 * @param sWorkArea
	 * @param iFlags
	 * @throws SQLException
	 * @throws IllegalArgumentException
	 * @throws NullPointerException
	 *
	 */
	public void store(Connection oConn, String sWorkArea, int iFlags)
	  throws SQLException, IllegalArgumentException, NullPointerException {
	  oDelegateTo.store(oConn, sWorkArea, iFlags); 
	}	

	public void store(Connection oConn, String sWorkArea)
	  throws SQLException, IllegalArgumentException, NullPointerException {
	  oDelegateTo.store(oConn, sWorkArea,
	  					MODE_APPENDUPDATE|WRITE_LOOKUPS|WRITE_ADDRESSES|WRITE_COMPANIES|
	  					WRITE_CONTACTS|NO_DUPLICATED_NAMES|NO_DUPLICATED_MAILS); 
	} // store	

    // ---------------------------------------------------------------------------

    public static final int MODE_APPEND = ImportLoader.MODE_APPEND;
    public static final int MODE_UPDATE = ImportLoader.MODE_UPDATE;
    public static final int MODE_APPENDUPDATE = ImportLoader.MODE_APPENDUPDATE;
    public static final int WRITE_LOOKUPS = ImportLoader.WRITE_LOOKUPS;

    public static final int WRITE_CONTACTS  = ContactLoader.WRITE_CONTACTS;
    public static final int WRITE_ADDRESSES = ContactLoader.WRITE_ADDRESSES;
    public static final int WRITE_COMPANIES = ContactLoader.WRITE_COMPANIES;

    public static final int NO_DUPLICATED_NAMES = ContactLoader.NO_DUPLICATED_NAMES;
    public static final int NO_DUPLICATED_MAILS = ContactLoader.NO_DUPLICATED_MAILS;
	
}

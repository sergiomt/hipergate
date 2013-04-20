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
package com.knowgate.hipergate;

import java.sql.Driver;
import java.sql.DriverManager;
import java.sql.Connection;
import java.sql.Statement;
import java.sql.PreparedStatement;
import java.sql.SQLException;
import java.sql.ResultSet;
import java.sql.Timestamp;

import java.io.FileReader;

import java.util.Date;
import java.util.ArrayList;
import java.util.Iterator;
import java.util.Properties;

import java.math.BigDecimal;

import com.knowgate.debug.DebugFile;
import com.knowgate.math.CurrencyCode;
import com.knowgate.dataobjs.DB;

/**
 * Maintenance and query routines for k_lu_currencies and k_lu_currencies_history tables
 * @author Sergio Montoro ten
 */

public class DBCurrencies {
	
	private static ArrayList<CurrencyCode> aCurrencies = null;
	
	public DBCurrencies() {	  
	}

	public static ArrayList<CurrencyCode> currencyCodes(Connection oConn) throws SQLException {
	  if (null==aCurrencies) {

	  	aCurrencies = new ArrayList<CurrencyCode>(270);
	    Statement oStmt = oConn.createStatement(ResultSet.TYPE_FORWARD_ONLY, ResultSet.CONCUR_READ_ONLY);
	    ResultSet oRSet = oStmt.executeQuery("SELECT "+DB.numeric_code+","+DB.alpha_code+","+DB.char_code+","+DB.id_entity+","+DB.nm_entity+","+DB.tr_currency_+"en FROM "+DB.k_lu_currencies+" ORDER BY 2");
		while (oRSet.next()) {
		  try {
		  	String sNum = oRSet.getString(1);
		  	if (!oRSet.wasNull())
		      aCurrencies.add(new CurrencyCode(Integer.parseInt(sNum.trim()), oRSet.getString(2), oRSet.getString(3), oRSet.getString(4), oRSet.getString(5), oRSet.getString(6)));
		  } catch (java.lang.IllegalArgumentException iae) {
		  	// Not all values present at k_lu_currencies are supported by Currency.getInstance()		  	
		  }
		} // wend
		oRSet.close();
		oStmt.close();
	  }	// fi
	  return aCurrencies;
	} // currencyCodes

    public static CurrencyCode currencyCodeFor (int iNumCode) throws NullPointerException {
      if (null==aCurrencies) throw new NullPointerException("DBCurrencies.currencyCodeFor() CurrencyCode array has not been initialized");
	  int count = aCurrencies.size();
	  CurrencyCode oCurCod = null;
	  for (int c=0; c<count; c++) {
	  	if (aCurrencies.get(c).numericCode()==iNumCode) {
	  	  oCurCod = aCurrencies.get(c);
	  	  break;
	  	} // fi
	  } // next
	  return oCurCod;
    } // currencyCodeFor

    public static CurrencyCode currencyCodeFor (String sAlphaCode) throws NullPointerException {
      if (null==aCurrencies) throw new NullPointerException("DBCurrencies.currencyCodeFor() CurrencyCode array has not been initialized");
	  int count = aCurrencies.size();
	  CurrencyCode oCurCod = null;
	  for (int c=0; c<count; c++) {
	  	if (aCurrencies.get(c).alphaCode().equalsIgnoreCase(sAlphaCode)) {
	  	  oCurCod = aCurrencies.get(c);
	  	  break;
	  	} // fi
	  } // next
	  return oCurCod;
    } // currencyCodeFor
    
    /**
     * <p>Update nu_conversion column of k_lu_currencies for a given base currency</p>
     * Conversion rates are computed by calling a free web service.
     * Each time a conversion is get a new row is inserted at k_lu_currencies_history
     * with the conversion rate found at current timestamp
     * @param oConn JDBC database connection
     * @param sBaseCurrency Base Currency alphanumeric 3 letter uppercase ISO code
     * @throws SQLException
     * @throws NullPointerException
     * @throws NumberFormatException
     */
	public static void updateConversionRates(Connection oConn, String sBaseCurrency)
	  throws SQLException,NullPointerException,NumberFormatException {
	  long lTsStart = 0l;
	  if (DebugFile.trace) {
		DebugFile.writeln("Begin updateConversionRates([Connection], "+sBaseCurrency+")");
		DebugFile.incIdent();
		lTsStart = new Date().getTime();
	  }
	  Timestamp oTsNow = new Timestamp(new Date().getTime());
	  CurrencyCode oCurrBase = CurrencyCode.currencyCodeFor(sBaseCurrency.toUpperCase());
	  ArrayList aList = new ArrayList(300);
	  Statement oList = oConn.createStatement(ResultSet.TYPE_FORWARD_ONLY, ResultSet.CONCUR_READ_ONLY);
	  ResultSet rList = oList.executeQuery("SELECT DISTINCT("+DB.alpha_code+") FROM "+DB.k_lu_currencies);
	  while (rList.next()) {
	  	aList.add(rList.getString(1));
	  } // wend
	  rList.close();
	  oList.close();
	  PreparedStatement oInsr = oConn.prepareStatement("INSERT INTO "+DB.k_lu_currencies_history+" ("+DB.alpha_code_from+","+DB.alpha_code_to+","+DB.nu_conversion+","+DB.dt_stamp+") VALUES ('"+sBaseCurrency.toUpperCase()+"',?,?,?)");
	  PreparedStatement oUpdt = oConn.prepareStatement("UPDATE "+DB.k_lu_currencies+" SET "+DB.nu_conversion+"=? WHERE "+DB.alpha_code+"=?");
	  Iterator oIter = aList.iterator();
	  while (oIter.hasNext()) {
	    String sAlphaCode = (String) oIter.next();
	    try {
	      double dRate = oCurrBase.conversionRateTo(sAlphaCode);
	      oUpdt.setBigDecimal(1, new BigDecimal(dRate));
	      oUpdt.setString(2, sAlphaCode);
	      if (0d!=dRate) {
	  	    oInsr.setString(1, sAlphaCode);
	        oInsr.setBigDecimal(2, new BigDecimal(dRate));
	        oInsr.setTimestamp(3, oTsNow);
	        oInsr.executeUpdate();
	      } // fi (0d!=dRate)
	      if (DebugFile.trace) {
		    DebugFile.writeln("Updating "+sAlphaCode+" conversion rate to "+String.valueOf(dRate));
	      }
	    } catch (Exception xcpt) {
	      oUpdt.setNull(1, java.sql.Types.DECIMAL);
	      oUpdt.setString(2, sAlphaCode);
	      if (DebugFile.trace) {
		    DebugFile.writeln("Could not get conversion rate to "+sAlphaCode+" "+xcpt.getClass().getName()+" "+xcpt.getMessage());
	      }
	    }
	    oUpdt.executeUpdate();
	  } // wend
	  oUpdt.close();
	  oInsr.close();
	  if (DebugFile.trace) {		
		DebugFile.writeln("updating all rates took "+String.valueOf((new Date().getTime() - lTsStart)/1000)+" seconds");
		DebugFile.decIdent();
		DebugFile.writeln("End updateConversionRates()");
	  }
	} // updateConversionRates

	// ------------------------------------------------------------------------

	public static void main(String[] args) throws Exception {
      if (null==args) {
        System.out.println("Usage: DBCurrencies cnf_file_path base_currency_3_letter_code");
      } else if (args.length<2) {
        System.out.println("Usage: DBCurrencies cnf_file_path base_currency_3_letter_code");
      } else {
		FileReader oReader = new FileReader(args[0]);
		Properties oDatabaseConnectionProps = new Properties();
		oDatabaseConnectionProps.load(oReader);
		oReader.close();

		DriverManager.registerDriver((Driver) Class.forName(oDatabaseConnectionProps.getProperty("driver")).newInstance());
		Connection oConn = DriverManager.getConnection(oDatabaseConnectionProps.getProperty("dburl"),oDatabaseConnectionProps.getProperty("dbuser"),oDatabaseConnectionProps.getProperty("dbpassword"));
	    oConn.setAutoCommit(true);
	    try {
	      updateConversionRates(oConn, "EUR");
	      //updateConversionRates(oConn, args[1].toUpperCase());
	    } finally {
	      if (oConn!=null) oConn.close();
	    }
	  } // fi
	} // main	
}

package com.knowgate.clocial;

import java.sql.SQLException;


import com.knowgate.misc.Gadgets;
import com.knowgate.debug.DebugFile;

import com.knowgate.storage.*;

public class Company extends RecordDelegator {

  private static final String tableName = "k_companies";

  private static final long serialVersionUID = Serials.Company;

  public Company(DataSource oDts) throws InstantiationException {
  	super(oDts, tableName);
  }	

  public String store(Table oConn) throws StorageException {

	replace("nm_ascii", Gadgets.ASCIIEncode(getString("nm_legal")));

	if (!containsKey("nm_commercial")) put("nm_commercial", get("nm_legal"));

	if (containsKey("id_country") && !getString("nm_legal","").endsWith(" ("+getString("id_country","")+")")) {
	  String sNmLegalLocale = getString("id_country","").toUpperCase()+"-"+Gadgets.ASCIIEncode(getString("nm_legal",""));
	  replace("nm_ascii_locale", sNmLegalLocale);
	} else {
	  replace("nm_ascii_locale", getString("nm_ascii"));
	}

	return super.store(oConn);
  }

  public static Record byName(DataSource oDts, String sNmLegal) 
    throws StorageException,SQLException {
    Record oRetVal = null;
    Table oCon = oDts.openTable(tableName,new String[]{"nm_legal"});
    try {
      RecordSet oRecSet = oCon.fetch("nm_legal", sNmLegal, 1);
      if (oRecSet.size()>0) {
      	oRetVal = oRecSet.get(0);
      }
    } catch (Exception xcpt) {
      throw new StorageException(xcpt.getMessage(), xcpt);
    } finally {
      if (oCon!=null) oCon.close();
    }
    return oRetVal;  	
  }
  
  public static RecordSet fetchLike(DataSource oDts, String sPartialNameStart, String sIdCountry, int nMaxRows)
    throws StorageException,SQLException {

    RecordSet oRetSet = null;
    Table oCon = null;
    
	if (DebugFile.trace) DebugFile.writeln("Company.fetchLike([DataSource],"+sPartialNameStart+","+sIdCountry+","+String.valueOf(nMaxRows)+")");
	
    try {
      if (sIdCountry==null) {
        oCon = oDts.openTable(tableName,new String[]{"nm_ascii"});
        oRetSet = oCon.fetch("nm_ascii", Gadgets.ASCIIEncode(sPartialNameStart)+"%", nMaxRows);
      } else {
        oCon = oDts.openTable(tableName,new String[]{"nm_ascii_locale"});    	
        oRetSet = oCon.fetch("nm_ascii_locale", Gadgets.ASCIIEncode(sIdCountry.trim()+"-"+sPartialNameStart)+"%", nMaxRows);
      }
    } catch (Exception xcpt) {
      throw new StorageException(xcpt.getMessage(), xcpt);
    } finally {
      if (oCon!=null) oCon.close();
    }
    return oRetSet;
  } // fetchLike

}

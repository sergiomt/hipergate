package com.knowgate.clocial;

import java.util.Date;

import com.knowgate.misc.Gadgets;

import com.knowgate.storage.*;

public class Company extends RecordDelegator {

  private static final String tableName = "k_companies";

  private static final long serialVersionUID = Serials.Company;

  public Company() {
  	super(Engine.DEFAULT, tableName,MetaData.getDefaultSchema().getColumns(tableName));
  }	

  public Company(Engine eEngine) {
  	super(eEngine, tableName,MetaData.getDefaultSchema().getColumns(tableName));
  }	

  public String store(Table oConn) throws StorageException {

	replace("nm_ascii", Gadgets.ASCIIEncode(getString("nm_legal")));

	if (!containsKey("nm_commercial")) put("nm_commercial", get("nm_legal"));

	if (containsKey("id_country") && !getString("nm_legal","").endsWith(" ("+getString("id_country","")+")")) {
	  String sNmLegalLocale = getString("nm_legal","")+" ("+getString("id_country","")+")";
	  replace("nm_ascii_locale", Gadgets.ASCIIEncode(sNmLegalLocale));
	} else {
	  replace("nm_ascii_locale", getString("nm_ascii"));
	}

	return super.store(oConn);
  }

  public static Record byName(DataSource oDts, String sNmLegal) 
    throws StorageException {
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
    throws StorageException {
    RecordSet oRetSet = null;
    Table oCon = null;
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

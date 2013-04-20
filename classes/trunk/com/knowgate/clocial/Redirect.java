package com.knowgate.clocial;

import java.net.URL;
import java.net.MalformedURLException;

import java.sql.SQLException;

import com.knowgate.misc.Gadgets;
import com.knowgate.storage.Table;
import com.knowgate.storage.Record;
import com.knowgate.storage.DataSource;
import com.knowgate.storage.StorageException;
import com.knowgate.storage.RecordDelegator;
import com.knowgate.storage.IntegrityViolationException;

public class Redirect extends RecordDelegator {

  private static final String tableName = "k_redirects";

  private static final long serialVersionUID = Serials.Redirect;

  public Redirect(DataSource oDts) throws InstantiationException {
  	super(oDts,tableName);
  }

  public String shortURL() {
  	return getString("url_addr");
  }

  public String targetURL() {
  	return getString("url_target");
  }
  
  public static Redirect shorten(DataSource oDts, String sTargetURL, String sDomain, String sPathInfo)
  	throws InstantiationException, MalformedURLException, StorageException, IntegrityViolationException {
  	Table oTbl = null;
    boolean bAlreadyExists = true;
  	Redirect oRedir = new Redirect(oDts);
	
	if (null==sTargetURL) throw new NullPointerException("The URL to be shortened may not be null");
	if (null==sDomain) throw new NullPointerException("The target base domain for shortening may not be null");

	URL oUrl = new URL(sTargetURL);
	
	String sShortURL = null;
	
    try {
      oTbl = oDts.openTable(oRedir);
  	  if (sPathInfo==null) {
  	  	int nRetries = 0;
  	  	while (bAlreadyExists) {
  	  	  sPathInfo = Gadgets.generateRandomId(7,null,Character.LOWERCASE_LETTER);
          sShortURL = Gadgets.chomp(sDomain,'/')+sPathInfo;
          bAlreadyExists = oTbl.exists(sShortURL);
          if (++nRetries>10000) {
            oTbl.close();
            oTbl=null;
            throw new StorageException("Random identifiers pool is exausted");
          }
  	  	} // wend
  	  } else {
  	  	sShortURL = Gadgets.chomp(sDomain,'/')+sPathInfo;
        bAlreadyExists = oTbl.exists(sShortURL);  	  	
        if (bAlreadyExists) {
          oTbl.close();
          oTbl=null;
          throw new IntegrityViolationException("Identifier is already taken");
        }
  	  }
  	  oRedir.put("url_addr", sShortURL);
  	  oRedir.put("url_target", sTargetURL);
  	  oRedir.store(oTbl);
	  oTbl.close();
  	} catch (SQLException sqle) {
  	  throw new StorageException(sqle.getMessage(), sqle);
    } finally {
	  try { if (null!=oTbl) oTbl.close(); }
	  catch (SQLException sqle) { throw new StorageException(sqle.getMessage(), sqle); }
    }
    return oRedir;
  } // shorten
  
  public static String resolve(DataSource oDts, String sURL, String sIP)
  	throws StorageException, InstantiationException {
    String sTarget = null, sJob = null, sContact = null, sEmail = null;
    Table oTbl = oDts.openTable(tableName);
  	Record oRec = oTbl.load(sURL);
  	if (null!=oRec) {
	  sTarget = oRec.getString("url_target");
	  if (!oRec.isNull("gu_job")) sJob = oRec.getString("gu_job");
	  if (!oRec.isNull("gu_contact")) sContact = oRec.getString("gu_contact");
	  if (!oRec.isNull("tx_email")) sEmail = oRec.getString("tx_email");
  	}
	try { if (null!=oTbl) oTbl.close(); }
	catch (SQLException sqle) { throw new StorageException(sqle.getMessage(), sqle); }
  	if (null!=sTarget) RedirectRequest.store(oDts, sURL, sIP, sJob, sContact, sEmail);
  	return sTarget;
  }
}


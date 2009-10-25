package com.knowgate.hipermail;

import java.sql.SQLException;

import java.util.Date;
import java.util.Arrays;
import java.util.ArrayList;

import org.apache.oro.text.regex.MalformedPatternException;

import com.knowgate.jdc.JDCConnection;
import com.knowgate.dataobjs.DB;
import com.knowgate.dataobjs.DBBind;
import com.knowgate.dataobjs.DBPersist;
import com.knowgate.dataobjs.DBCommand;
import com.knowgate.misc.Gadgets;

public class AdHocMailing extends DBPersist {

  private String[] aRecipients;
  private String[] aBlackList;


  public AdHocMailing() {
  	super(DB.k_adhoc_mailings, "AdHocMailing");
  	aBlackList = null;
  	aRecipients = null;
  }
  
  public boolean load(JDCConnection oConn, int iPgMailing, String sGuWorkArea)
  	throws SQLException {
  	String sGuMaiiling = DBCommand.queryStr(oConn, "SELECT "+DB.gu_mailing+" FROM "+DB.k_adhoc_mailings+" WHERE "+DB.pg_mailing+"="+String.valueOf(iPgMailing)+" AND "+DB.gu_workarea+"='"+sGuWorkArea+"'");
    if (null==sGuMaiiling)
      return false;
    else
      return super.load(oConn, sGuMaiiling);
  }
  
  private String[] concatArrays(String[] a1, String a2[]) {
	final int l1 = a1.length;
	final int l2 = a2.length;
	final int ll = l1+l2;
	String[] aRetVal = Arrays.copyOf(a1, ll);
    for (int e=0; e<l2; e++) aRetVal[e+l1] = a2[e];
    return aRetVal;
  } // concatArrays

  public String[] getBlackList() {
    return aBlackList;
  }

  public void addBlackList(String[] aEMails)
  	throws MalformedPatternException {
    if (aEMails!=null) {
      if (aEMails.length>0) {
      	if (aBlackList==null) {
      	  aBlackList = aEMails;
      	} else {
      	  aBlackList = concatArrays(aBlackList, aEMails);
      	} // fi (aRecipients!=null)
      	final int nBlackList = aBlackList.length;
      	Arrays.sort(aBlackList, String.CASE_INSENSITIVE_ORDER);
      }
    }
  } // addBlackList

  public String[] getRecipients() {
    return aRecipients;
  }
  	  
  public void addRecipients(String[] aEMails)
  	throws MalformedPatternException {
	String sAllowPattern, sDenyPattern;
    ArrayList<String> oRecipientsWithoutDuplicates;
    boolean bAllowed;
    
    if (aEMails!=null) {
      if (aEMails.length>0) {
      	if (aRecipients==null) {
      	  aRecipients = aEMails;
      	} else {
      	  aRecipients = concatArrays(aRecipients, aEMails);
      	} // fi (aRecipients!=null)
      	final int nRecipients = aRecipients.length;
      	Arrays.sort(aRecipients, String.CASE_INSENSITIVE_ORDER);
		
		oRecipientsWithoutDuplicates = new ArrayList<String>(nRecipients);

	  	if (isNull(DB.tx_allow_regexp)) sAllowPattern = ""; else sAllowPattern = getString(DB.tx_allow_regexp);
	  	if (isNull(DB.tx_deny_regexp))  sDenyPattern  = ""; else sDenyPattern  = getString(DB.tx_deny_regexp);
	  	  	  
	    for (int r=0; r<nRecipients-1; r++) {
		  bAllowed = true;
		  if (sAllowPattern.length()>0) bAllowed &= Gadgets.matches(aRecipients[r], sAllowPattern);
		  if (sDenyPattern.length()>0) bAllowed &= !Gadgets.matches(aRecipients[r], sDenyPattern);
		  if (bAllowed) {
	  	    if (!aRecipients[r].equalsIgnoreCase(aRecipients[r+1])) {
	  	      if (aBlackList==null) {
	  	        if (aRecipients[r].trim().length()>0) oRecipientsWithoutDuplicates.add(aRecipients[r].trim());
	  	      } else if (Arrays.binarySearch(aBlackList, aRecipients[r].toLowerCase(), String.CASE_INSENSITIVE_ORDER)<0) {
	  	        if (aRecipients[r].trim().length()>0) oRecipientsWithoutDuplicates.add(aRecipients[r].trim());
	  	      } // fi
	  	    } // fi
	  	  } // fi bAllowed
	    } // next      

	    bAllowed=true;
	    if (sAllowPattern.length()>0) bAllowed &= Gadgets.matches(aRecipients[nRecipients-1], sAllowPattern);
	    if (sDenyPattern.length()>0) bAllowed &= !Gadgets.matches(aRecipients[nRecipients-1], sDenyPattern);
	    if (bAllowed) {
	      if (aBlackList==null) {
	        if (aRecipients[nRecipients-1].trim().length()>0) oRecipientsWithoutDuplicates.add(aRecipients[nRecipients-1].trim());
	      } else if (Arrays.binarySearch(aBlackList, aRecipients[nRecipients-1].toLowerCase(), String.CASE_INSENSITIVE_ORDER)<0) {
	  	    if (aRecipients[nRecipients-1].trim().length()>0) oRecipientsWithoutDuplicates.add(aRecipients[nRecipients-1].trim());
	      }
	    } // fi (bAllowed)

	    aRecipients = oRecipientsWithoutDuplicates.toArray(new String[oRecipientsWithoutDuplicates.size()]);
	    	  
      } // fi (aEMails != {})
    } // fi (aEMails != null)

  } // addRecipients

  public boolean store (JDCConnection oConn)
  	throws SQLException {
    
    Date dtNow = new Date();
    
    if (!AllVals.containsKey(DB.dt_modified) && AllVals.containsKey(DB.gu_mailing))
      put (DB.dt_modified, dtNow);
    if (!AllVals.containsKey(DB.gu_mailing))
      put (DB.gu_mailing, Gadgets.generateUUID());
    if (!AllVals.containsKey(DB.pg_mailing))
      put (DB.pg_mailing, DBBind.nextVal(oConn, "seq_k_adhoc_mailings"));
    if (!AllVals.containsKey(DB.dt_created))
      put (DB.dt_created, dtNow);
    if (AllVals.containsKey(DB.tx_email_from))
      if (!Gadgets.checkEMail(getString(DB.tx_email_from)))
      	throw new SQLException ("AdHocMailing.store() invalid syntax for tx_email_from address "+getString(DB.tx_email_from));
    if (AllVals.containsKey(DB.tx_email_reply))
      if (!Gadgets.checkEMail(getString(DB.tx_email_reply)))
      	throw new SQLException ("AdHocMailing.store() invalid syntax for tx_email_from address "+getString(DB.tx_email_from));

    return super.store(oConn);
  }
  
  public static final short ClassId = 811;

}

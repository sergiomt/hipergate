package com.knowgate.syndication.crawler;

import java.io.IOException;

import java.util.Arrays;
import java.util.Date;

import java.sql.SQLException;

import com.knowgate.dataobjs.DB;
import com.knowgate.clocial.UserAccount;

import com.knowgate.storage.Table;
import com.knowgate.storage.Record;
import com.knowgate.storage.Manager;
import com.knowgate.storage.DataSource;
import com.knowgate.storage.RecordSet;
import com.knowgate.storage.RecordList;
import com.knowgate.storage.StorageException;

import com.knowgate.misc.Gadgets;
import com.knowgate.misc.NameValuePair;

import com.knowgate.syndication.SyndSearch;
import com.knowgate.syndication.SyndSearchRequest;
import com.knowgate.syndication.crawler.SearchRunner;

import com.sun.syndication.io.FeedException;
import com.sun.syndication.fetcher.FetcherException;

public class EntrySearcher {

  public static RecordSet search(Manager oStorMngr, String[] aQrys,
  								 NameValuePair[] aParams, String sGuAcc,
  								 int iMaxResults)
  	throws NullPointerException,StorageException,InstantiationException,
  		   FeedException,FetcherException,IOException {
  	final Date dtNow = new Date();
  	final int nQrys = aQrys.length;
  	final long lStartTime = dtNow.getTime();
  	RecordSet oRetSet, oMinSet;
  	RecordSet[] aRetSet = new RecordSet[nQrys];
  	DataSource oDts = null;
  	Table oTbl = null;
  	SyndSearch oSs;

	if (null==aQrys)
	  throw new NullPointerException("EntrySearcher.search() query string may not be null");
	else if (aQrys[0].length()==0)
	  throw new NullPointerException("EntrySearcher.search() query string may not an empty string");

  	try {
  	  boolean bNewSearch = false;

	  oDts = oStorMngr.getDataSource();

	  oSs = new SyndSearch(oDts);
	  	
  	  for (int q=0; q<nQrys; q++) {
  	    if (oStorMngr.exists(DB.k_syndsearches, aQrys[q])) {
	      // ******************************************
	      // Update last request and number of requests
  	      oSs = new SyndSearch(oDts);
  	      oTbl = oDts.openTable(oSs);  	      	    
  	      oSs.load(oTbl, aQrys[q]);
	      oSs.put("dt_last_request", dtNow);
	      oSs.put("nu_requests", oSs.getInt("nu_requests")+1);			    
	      oSs.store(oTbl);
	      oTbl.close();
	      oTbl=null;
  	    } else {
  	      bNewSearch = true;
	      // *************************
	      // Create new search request
  	      oSs = new SyndSearch(oDts,Gadgets.left(aQrys[q], 254), dtNow, 0, null, 0, 0);
  	      oStorMngr.store(oSs, true);
  	      SearchRunner oRun = new SearchRunner(aQrys[q], oStorMngr.getProperties());
  	      oRun.run(oDts);
  	    }
  	  } // next

	  oTbl = oDts.openTable(DB.k_syndentries, new String[]{"tx_sought"});
	  if (aParams==null) {
	    for (int q=0; q<nQrys; q++)
	      aRetSet[q] = oTbl.fetch("tx_sought", aQrys[q], iMaxResults);
	  } else {
	    NameValuePair[] aWhere = Arrays.copyOf(aParams, aParams.length+1);
	    for (int q=0; q<nQrys; q++) {
	      aWhere[aParams.length] = new NameValuePair("tx_sought", aQrys[q]);
	      aRetSet[q] = oTbl.fetch(aWhere, iMaxResults);	      
	    } // next
	  } // fi
	  oTbl.close();
	  oTbl=null;

	  if (sGuAcc!=null) {
	    oTbl = oDts.openTable(DB.k_user_accounts);
	    UserAccount oAcc = new UserAccount(oDts);
	    oAcc.load(oTbl, sGuAcc);
	    for (int q=0; q<nQrys; q++)
	      oAcc.pushSearch(aQrys[q]);
	    oTbl.close();
	    oTbl=null;
	    oStorMngr.store(oAcc, false);
	  }

	  for (int q=0; q<nQrys; q++)
	    oStorMngr.store(new SyndSearchRequest(oDts, aQrys[q], dtNow,
	  									     (int) (new Date().getTime()-lStartTime), sGuAcc), false);
	  	  
	  oStorMngr.free(oDts);
	  
	  if (1==nQrys) {
	  	oRetSet = aRetSet[0];
	  } else {
	    int iSmallestResultSetQry = 0;
	    int iSmallestResultSetLen = 2147483647;
	    for (int q=0; q<nQrys; q++) {
	      if (aRetSet[q].size()<iSmallestResultSetLen) {
	        iSmallestResultSetQry = q;
	        iSmallestResultSetLen = aRetSet[q].size();
	      }
	    } // next
	    oMinSet = aRetSet[iSmallestResultSetQry];
	    oRetSet = new RecordList(iSmallestResultSetLen);
	    for (int r=0; r<iSmallestResultSetLen; r++) {
	      boolean bIsIntersected = true;
	      for (int q=0; q<nQrys && bIsIntersected; q++) {
	        if (q!=iSmallestResultSetQry)
	          bIsIntersected &= (aRetSet[q].find("uri_entry", oMinSet.get(r).getString("uri_entry"))>=0);
	      } // next
	      if (bIsIntersected) oRetSet.add(oMinSet.get(r));
	    } // next
	  } // fi
	  
	  oRetSet.sortDesc("dt_published");
	  
  	} catch (InstantiationException ie) {
  	  throw new StorageException(ie.getMessage(), ie);
  	} catch (SQLException se) {
  	  throw new StorageException(se.getMessage(), se);
  	} finally {
  	  if (oTbl!=null) { try { oTbl.close(); } catch (Exception xcpt) {} }
  	  if (oStorMngr!=null && oDts!=null) oStorMngr.free(oDts);
  	}
  	
    return oRetSet;
  } // search

  public static RecordSet search(Manager oStorMngr, String sQry, String sGuAcc, int iMaxResults)
  	throws NullPointerException,StorageException,InstantiationException,
  		   FeedException,FetcherException,IOException {
    return search(oStorMngr, new String[]{sQry}, null, sGuAcc, iMaxResults);
  }
  		   
  public static RecordSet referers(Manager oStorMngr, String sDomain)
  	throws NullPointerException,StorageException,InstantiationException,
  		   FeedException,FetcherException,IOException {
  	RecordSet oRetSet;

	if (null==sDomain)
	  throw new NullPointerException("EntrySearcher.referers() domain may not be null");
	else if (sDomain.length()==0)
	  throw new NullPointerException("EntrySearcher.referers() domain may not an empty string");

  	try {
  	  oRetSet = oStorMngr.fetch(DB.k_syndreferers, DB.url_domain, sDomain);
  	  oRetSet.sort("nu_entries");
  	} catch (InstantiationException ie) {
  	  throw new StorageException(ie.getMessage(), ie);
  	}
    return oRetSet;
  } // referers
  
  public static String searchXML(Manager oStorMngr, String sQry,
  								 String sGuAcc, String sDateFormat,
  								 int iMaxResults, int iOffset, boolean bReloadXMLCache)
  	throws StorageException,InstantiationException,FeedException,FetcherException,IOException {
    String sRetVal = null;
    if (iMaxResults<=100 && iOffset==0 && !bReloadXMLCache) {
      Record oSs = oStorMngr.load(DB.k_syndsearches, sQry);
      if (oSs!=null) {
      	if (!oSs.isNull("xml_recent")) {
      	  if (oSs.isNull("dt_last_request") || oSs.isNull("dt_last_run"))
      	  	bReloadXMLCache = true;
      	  else if (oSs.getDate("dt_last_run").compareTo(oSs.getDate("dt_last_request"))>0)
      	  	bReloadXMLCache = true;
      	  else
      	    sRetVal = oSs.getString("xml_recent");
	      // ******************************************
	      // Update last request and number of requests
	      oSs.put("dt_last_request", new Date());
	      oSs.put("nu_requests", oSs.getInt("nu_requests")+1);
		  oStorMngr.store(oSs, false);
      	}
      }
    } // fi
	if (null==sRetVal || bReloadXMLCache) {
      RecordSet oRst = search(oStorMngr, sQry, sGuAcc, iMaxResults);
      sRetVal = SearchRunner.recordSetToXML(oRst, sDateFormat, iMaxResults, iOffset);
	}
	return sRetVal;
  } // searchXML


  public static String searchXML(Manager oStorMngr, String[] aQrys,
  								 NameValuePair[] aParams, String sGuAcc,
  								 String sDateFormat, int iMaxResults,
  								 int iOffset, boolean bReloadXMLCache)
  	throws StorageException,InstantiationException,FeedException,FetcherException,IOException {
    String sRetVal = null;
	if (null==sRetVal || bReloadXMLCache) {
      RecordSet oRst = search(oStorMngr, aQrys, aParams, sGuAcc, iMaxResults);
      sRetVal = SearchRunner.recordSetToXML(oRst, sDateFormat, iMaxResults, iOffset);
	}
	return sRetVal;
  } // searchXML

}

/*
  Copyright (C) 2011  Know Gate S.L. All rights reserved.

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

package com.knowgate.syndication;

import java.util.Date;
import com.knowgate.dataobjs.DB;

import java.sql.SQLException;

import com.knowgate.clocial.Serials;

import com.knowgate.debug.DebugFile;

import com.knowgate.storage.Table;
import com.knowgate.storage.Record;
import com.knowgate.storage.RecordSet;
import com.knowgate.storage.DataSource;
import com.knowgate.storage.RecordDelegator;
import com.knowgate.storage.StorageException;

public class SyndSearch extends RecordDelegator {

  private static final String tableName = DB.k_syndsearches;
  
  private static final long serialVersionUID = Serials.SyndSearch;
	
	public SyndSearch(DataSource oDts) throws InstantiationException {
	  super(oDts, DB.k_syndsearches);
	}	

	public SyndSearch(DataSource oDts, String sTxSought, Date dtLastRun, int nRuns,
					  Date dtLastRequest, int nRequests, int nResults) throws InstantiationException {
	  super(oDts, DB.k_syndsearches);
	  put("tx_sought", sTxSought);
	  put("dt_last_run", dtLastRun);
	  put("nu_runs", nRuns);
	  if (null!=dtLastRequest) put("dt_last_request", dtLastRequest);
	  put("nu_requests", nRequests);
	  put("nu_results", nResults);
	}
	
    public void delete(Table oTbl) throws StorageException {
	  Table oFkt = null;
	  DataSource oDts = oTbl.getDataSource();
	  try {
	    Record[] aFKs = new Record[]{ new SyndSearchRequest(oDts),
	  								  new SyndSearchReferer(oDts),
	  								  new SyndSearchRun(oDts),
	  								  new FeedEntry(oDts) };
	    for (int r=0; r<aFKs.length; r++) {
	      oFkt = oDts.openTable(aFKs[r]);
	      oFkt.delete("tx_sought", getString("tx_sought"));
	      oFkt.close();
	      oFkt=null;	    
	    } // next
	    super.delete(oTbl);
	  } catch (SQLException sqle) {
	    throw new StorageException(sqle.getMessage(), sqle);
	  } catch (InstantiationException inse) {
	    throw new StorageException(inse.getMessage(), inse);
	  } finally {
	  	try { if (oFkt!=null) oFkt.close(); } catch (SQLException ignore) { }
	  }
    } // delete

    public static RecordSet fetchLike(DataSource oDts, String sPartialQueryStart, int nMaxRows)
      throws StorageException,SQLException {

      RecordSet oRetSet = null;
      Table oCon = null;
    
	  if (DebugFile.trace) DebugFile.writeln("SyndSearch.fetchLike([DataSource],"+sPartialQueryStart+","+String.valueOf(nMaxRows)+")");
	
      try {
        oCon = oDts.openTable(tableName,new String[]{"tx_sought"});
        oRetSet = oCon.fetch("tx_sought", sPartialQueryStart+"%", nMaxRows);
      } catch (Exception xcpt) {
        throw new StorageException(xcpt.getMessage(), xcpt);
      } finally {
        if (oCon!=null) oCon.close();
      }
      return oRetSet;
    } // fetchLike
}

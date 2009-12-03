package com.knowgate.crm;

import java.sql.SQLException;
import java.io.IOException;

import com.knowgate.yahoo.Boss;
import com.knowgate.yahoo.YSearchResponse;
import com.knowgate.jdc.JDCConnection;
import com.knowgate.dataobjs.DB;
import com.knowgate.dataobjs.DBBind;
import com.knowgate.dataobjs.DBCommand;
import com.knowgate.dataobjs.DBSubset;
import com.knowgate.debug.DebugFile;
import com.knowgate.misc.Gadgets;

public class SocialNetworks {

  public static int crawl(DBBind oDbb, final String sWorkArea, final String sWhere,
                          final String sSite, final int iLimit)
  	throws SQLException, IOException,IllegalArgumentException {
    
    if (!sSite.equals("linkedin") && !sSite.equals("facebook")) {
      throw new IllegalArgumentException("Crawled sites may be only linkedin or facebook");
    }
    
    if (DebugFile.trace) {
      DebugFile.writeln("Begin SocialNetworks.crawl("+sWorkArea+","+sWhere+","+sSite+")");
      DebugFile.incIdent();
    }
    
    Boss oBss = new Boss();
    JDCConnection oCon = oDbb.getConnection("SocialNetworksCrawler");
    oCon.setAutoCommit(true);
    DBSubset oDbs = new DBSubset(DB.k_contacts, DB.gu_contact+","+DB.tx_name+","+DB.tx_surname,
    							 DB.gu_workarea+"=? AND "+DB.tx_name+" IS NOT NULL AND "+
    							 DB.tx_surname+" IS NOT NULL "+
    							(sWhere==null ? "" : " AND "+sWhere), iLimit);
    oDbs.setMaxRows(iLimit);
    final int nContacts = oDbs.load(oCon, new Object[]{sWorkArea});
    if (DebugFile.trace) DebugFile.writeln("Crawling "+String.valueOf(nContacts)+" contacts");
    int nFound = 0;
    for (int c=0; c<nContacts; c++) {
      String sFullName = oDbs.getStringNull(1,c,"")+" "+oDbs.getStringNull(2,c,"");
      String sASCIIName = Gadgets.ASCIIEncode(sFullName);
      
      if (DebugFile.trace) DebugFile.writeln("Searching "+sFullName+"...");
      YSearchResponse oYsr = oBss.search("CCPHrtTV34Fxw3S4MtMcQ82YGu5H2f_VtcDINUxuGgKeByKmf2lAHbFiIbj4Dg--",
                                         Gadgets.ASCIIEncode(oDbs.getStringNull(1,c,""))+" "+
                                         Gadgets.ASCIIEncode(oDbs.getStringNull(2,c,"")),
                                         sSite+".com");
      if (oYsr.count()>0) {
      	if (DebugFile.trace) DebugFile.writeln("Found "+oYsr.results(0).title);
      	if (Gadgets.ASCIIEncode(oYsr.results(0).title).startsWith(sASCIIName)) {
      	  nFound++;
      	  DBCommand.executeUpdate(oCon, "UPDATE "+DB.k_contacts+" SET url_"+sSite+"='"+oYsr.results(0).url+"' WHERE "+DB.gu_contact+"='"+oDbs.getString(0,c)+"'");
      	} // fi
      } else {
      	if (DebugFile.trace) DebugFile.writeln("No results found for "+sFullName);
      }
    } // next
    oCon.close("SocialNetworksCrawler");

    if (DebugFile.trace) {
      DebugFile.decIdent();
      DebugFile.writeln("End SocialNetworks.crawl() : "+String.valueOf(nFound));
    }

    return nFound;
  } // crawl

}

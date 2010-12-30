package com.knowgate.berkeleydb;

import java.util.ArrayList;
import java.util.Comparator;
import java.util.Collections;

import com.knowgate.storage.Record;
import com.knowgate.storage.RecordSet;
import com.knowgate.storage.RecordColumnValueComparatorAsc;

public class DBEntitySet extends ArrayList<Record> implements RecordSet {

  private static String rpl(String s) {
  	return s.replace('"','`').replace('\n',' ').replace('\t',' ');
  }

  public void sort(String sColumnName) throws ArrayIndexOutOfBoundsException {
    if (size()>0) {
	  Collections.sort(this, new RecordColumnValueComparatorAsc(sColumnName));
    }
  }

  public String json(String sName, String sIdentifier, String sLabel) throws ArrayIndexOutOfBoundsException {  
    boolean c = false;
    StringBuffer oBuff = new StringBuffer(200*size());
    oBuff.append("{\"identifier\":\""+sIdentifier+"\",\"label\":\""+sLabel+"\",\"items\":[\n");

	if (sLabel.equalsIgnoreCase("NmLegal (IdCountry)")) {
      for (Record r : this) {
        if (c) oBuff.append(',');
        oBuff.append("{\"name\":\""+rpl(r.getString(sName,""))+"\",");
        oBuff.append("\""+sIdentifier+"\":\""+rpl(r.getString(sIdentifier,""))+"\",");
        if (r.isEmpty("IdCountry"))
          oBuff.append("\""+sLabel+"\":\""+rpl(r.getString("NmLegal",""))+"\"}\n");
        else
          oBuff.append("\""+sLabel+"\":\""+rpl(r.getString("NmLegal",""))+" ("+r.getString("IdCountry","").toUpperCase()+")\"}\n");
        c = true;
      } // next
	} else {
      for (Record r : this) {
        if (c) oBuff.append(',');
        oBuff.append("{\"name\":\""+rpl(r.getString(sName,""))+"\",");
        oBuff.append("\""+sIdentifier+"\":\""+rpl(r.getString(sIdentifier,""))+"\",");
        oBuff.append("\""+sLabel+"\":\""+rpl(r.getString(sLabel,""))+"\"}\n");
        c = true;
      } // next
	} // fi

    oBuff.append("]}");  	
    return oBuff.toString();
  } 

}

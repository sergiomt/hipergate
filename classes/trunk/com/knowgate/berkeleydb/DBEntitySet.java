package com.knowgate.berkeleydb;

import java.util.HashMap;
import java.util.ArrayList;
import java.util.Collections;

import com.knowgate.storage.Record;
import com.knowgate.storage.RecordSet;
import com.knowgate.storage.RecordColumnValueComparatorAsc;
import com.knowgate.storage.RecordColumnValueComparatorDesc;

public class DBEntitySet extends ArrayList<Record> implements RecordSet {

  private HashMap<String,HashMap<Object,Integer>> mIndexes;

  private static String rpl(String s) {
  	return s.replace('"','`').replace('\n',' ').replace('\t',' ');
  }

  public DBEntitySet() {
    mIndexes = null;
  }
  
  public void sort(String sColumnName) throws ArrayIndexOutOfBoundsException {
    if (size()>0) {
	  Collections.sort(this, new RecordColumnValueComparatorAsc(sColumnName));
    }
  }

  public void sortDesc(String sColumnName) throws ArrayIndexOutOfBoundsException {
    if (size()>0) {
	  Collections.sort(this, new RecordColumnValueComparatorDesc(sColumnName));
	}
  }
  
  public int find (String sColumnName, Object oValue) {
  	if (oValue==null) return -1;
  	if (mIndexes==null) mIndexes = new HashMap<String,HashMap<Object,Integer>>(size()*2);
    
    HashMap<Object,Integer> oIndex = mIndexes.get(sColumnName);
    if (null==oIndex) {
      oIndex = new HashMap<Object,Integer>();
      final int nSize = size();
      for (int n=0; n<nSize; n++)
      	oIndex.put(oValue, new Integer(n));
      mIndexes.put(sColumnName, oIndex);
    }
    Integer iPosition = oIndex.get(oValue);
    if (null==iPosition)
      return -1;
    else
      return iPosition.intValue();
  } // find

  public String json(String sName, String sIdentifier, String sLabel) throws ArrayIndexOutOfBoundsException {  
    boolean c = false;
    StringBuffer oBuff = new StringBuffer(200*size());
    oBuff.append("{\"identifier\":\""+sIdentifier+"\",\"label\":\""+sLabel+"\",\"items\":[\n");

	if (sLabel.equalsIgnoreCase("nm_legal (id_country)")) {
      for (Record r : this) {
        if (c) oBuff.append(',');
        oBuff.append("{\"name\":\""+rpl(r.getString(sName,""))+"\",");
        oBuff.append("\""+sIdentifier+"\":\""+rpl(r.getString(sIdentifier,""))+"\",");
        if (r.isEmpty("id_country"))
          oBuff.append("\""+sLabel+"\":\""+rpl(r.getString("nm_legal",""))+"\"}\n");
        else
          oBuff.append("\""+sLabel+"\":\""+rpl(r.getString("nm_legal",""))+" ("+r.getString("id_country","").toUpperCase()+")\"}\n");
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
  } // json

}

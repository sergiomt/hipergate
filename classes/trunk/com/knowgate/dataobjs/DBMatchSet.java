/*
  Copyright (C) 2008  Know Gate S.L. All rights reserved.
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
package com.knowgate.dataobjs;

import java.util.Collections;
import java.util.LinkedList;
import java.util.ListIterator;

/**
 * Hold a subset of rows from a Levenshtein distance or pattern matching execution
 */
 
public class DBMatchSet {
  private int nMaxItems;
  private LinkedList<DBMatch> oSortedList;

  /**
   * Default constructor
   */  	  
  public DBMatchSet() {
  	nMaxItems = 2147483647;
  	oSortedList = new LinkedList<DBMatch>();
  }

  /**
   * <p>Create match set with maximum number of matches</p>
   * When a maximum is specified, those items with less matching grade
   * will be discarded by the put method after the limit is reached.
   * @param nItems Maximum number of matches to keep in this set
   */  	  
  public DBMatchSet(int nItems) {
  	nMaxItems = nItems;
  	oSortedList = new LinkedList<DBMatch>();
  }

  /**
   * <p>Insert new match</p>
   * @param sRecordGuid Unique identifier of record originating the match
   * @param oRecordValue Value of matching element
   * @param iRecordIndex Index of matching element at DBSubset or RecordSet
   * @param fMatchPct Match degree percentage [0..100]
   */
  public void put (String sRecordGuid, Object oRecordValue, int iRecordIndex, float fMatchPct) {
  	int iPos;
  	DBMatch oNewMatch = new DBMatch(sRecordGuid, oRecordValue, iRecordIndex, fMatchPct);
  	
  	switch (count()) {
  	  case 0:
	    oSortedList.add(oNewMatch);
	    break;
	  default:
	    if (count()==nMaxItems) {
  	      if (((DBMatch) oSortedList.getLast()).grade()<fMatchPct) {
  	  	    oSortedList.removeLast();
  	  	    if (oSortedList.size()==0) {
	          oSortedList.add(oNewMatch);
  	  	    } else {
  	          iPos = Collections.binarySearch(oSortedList,oNewMatch,DBMatch.COMPARATOR);
	          if (iPos<0) iPos = -iPos;
	          iPos--;
	          if (iPos<0)
	          	oSortedList.addFirst(oNewMatch);
	          else
	            oSortedList.add(iPos,oNewMatch);
  	  	    }
  	      }
  	    } else {
  	      iPos = Collections.binarySearch(oSortedList,oNewMatch,DBMatch.COMPARATOR);
	      if (iPos<0) iPos = -iPos;
	      iPos--;
	      if (iPos<0)
	        oSortedList.addFirst(oNewMatch);
	      else
	        oSortedList.add(iPos,oNewMatch);
	    }
  	} // end switch
  } // put
  
  public ListIterator iterator() {
	return oSortedList.listIterator();
  }

  public DBMatch get(int m) {
    return (DBMatch) oSortedList.get(m);
  }
  
  /**
   * Get array of matches sorted by their degree
   * @return DBMatch[]
   */
  public DBMatch[] toArray() {
	DBMatch[] aMatches = null;
	Collections.sort(oSortedList, DBMatch.COMPARATOR);
	if (count()>0) {
	  aMatches = new DBMatch[count()];
	  ListIterator oIter = iterator();
	  int m = 0;
	  while (oIter.hasNext()) aMatches[m++] = (DBMatch) oIter.next();
	} // fi
	return aMatches;
  } // toArray

  /**
   * Count of matches in this set
   */  
  public int count() {
  	return oSortedList.size();
  }
    
  public String toXML() {
	Collections.sort(oSortedList, DBMatch.COMPARATOR);
    StringBuffer oBuff = new StringBuffer(200*count()+1);
    ListIterator oIter = iterator();
    oBuff.append("<DBMatchSet>\n");
	while (oIter.hasNext()) {
	  DBMatch oMatch = (DBMatch) oIter.next();
      oBuff.append("  <DBMatch>\n");
	  oBuff.append("    <guid>"+oMatch.guid()+"</guid>\n");
	  oBuff.append("    <index>"+String.valueOf(oMatch.index())+"</index>\n");
	  oBuff.append("    <grade>"+String.valueOf(oMatch.grade())+"</grade>\n");
	  oBuff.append("    <value><![CDATA["+oMatch.matchingValue()+"]]></value>\n");
      oBuff.append("  </DBMatch>\n");
	} // wend 
    oBuff.append("</DBMatchSet>");
    return oBuff.toString();
  } // toXML
}

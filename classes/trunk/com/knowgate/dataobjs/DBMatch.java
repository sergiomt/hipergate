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

import java.util.Comparator;

public final class DBMatch implements Comparable {

	private String sGuid;
	private Object oMatchingValue;
	private int iRowIndex;
	private float fMatchGrade;
	public static CompareMatches COMPARATOR = new CompareMatches();

    private static class CompareMatches implements Comparator {
	  public int compare(Object m1, Object m2) {
	    return ((DBMatch) m1).compareTo((DBMatch)m2);
	  }
    } // CompareMatches
    
	public DBMatch (String sRecordGuid, Object oRecordValue, int iRecordIndex, float fMatchPct)	{
	  sGuid = sRecordGuid;
	  oMatchingValue = oRecordValue;
	  iRowIndex = iRecordIndex;
	  fMatchGrade = fMatchPct;
	}

	public String guid() {
	  return sGuid;
	}

	public Object matchingValue() {
	  return oMatchingValue;
	}
	
	public int index() {
	  return iRowIndex;
	}

	public float grade() {
	  return fMatchGrade;
	}

	public int compareTo(DBMatch oDbMatch) {
	  float fOtherGrade = oDbMatch.grade();
	  return fMatchGrade==fOtherGrade ? 0 : (fMatchGrade>fOtherGrade ? -1 : 1);
	}
	
	public int compareTo(Object oDbMatch) {
	  float fOtherGrade = ((DBMatch) oDbMatch).grade();
	  return fMatchGrade==fOtherGrade ? 0 : (fMatchGrade>fOtherGrade ? -1 : 1);
	}

} // DBMatch

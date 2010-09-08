/*
  Copyright (C) 2003-2010  Know Gate S.L. All rights reserved.

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

import java.util.LinkedList;

public class DBIndex {
  
  private boolean bUnique;
  private String sName;
  private LinkedList<String> oColumns;
  
  public DBIndex (String sIndexName, LinkedList<String> oIndexColumns, boolean bIsUnique) {
  	sName = sIndexName;
  	bUnique = bIsUnique;
  	oColumns = new LinkedList<String>(oIndexColumns);
  }

  public DBIndex (String sIndexName, String[] aIndexColumns, boolean bIsUnique) {
  	sName = sIndexName;
  	bUnique = bIsUnique;
  	oColumns = new LinkedList<String>();
  	if (null!=aIndexColumns) {
  	  for (int c=0; c<aIndexColumns.length; c++) {
  	  	oColumns.add(aIndexColumns[c]);
  	  } // next
  	} // fi
  }
  
  public String getName() {
  	return sName;
  }

  public LinkedList<String> getColumns() {
  	return oColumns;
  }

  public boolean isUnique() {
  	return bUnique;
  }

}

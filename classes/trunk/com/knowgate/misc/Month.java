/*
  Copyright (C) 2009  Know Gate S.L. All rights reserved.
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

package com.knowgate.misc;

import java.util.Date;

public class Month {
  	
  	public Month (int y, int m) { year = y; month = m; }

	public int getYear() { return year; }

	public int getMonth() { return month; }

	public Date firstDay () { return new Date(year, month, 1, 0, 0, 0); }

	public Date lastDay () { return new Date(year, month, Calendar.LastDay(month, year<1900 ? year+1900 : year), 23, 59, 59); }

	public String toString() { return String.valueOf(year<1900 ? year+1900 : year)+"_"+Gadgets.leftPad(String.valueOf(month+1),'0',2); }

  	private int year;

  	private int month;
}

/*
  Copyright (C) 2003-2008  Know Gate S.L. All rights reserved.
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

package com.knowgate.http;

/**
 * <p>Cookies</p>
 * <p>Company: KnowGate</p>
 * @version 5.0
 */

import java.net.URLDecoder;
import javax.servlet.http.Cookie;
import javax.servlet.http.HttpServletRequest;

public class Cookies {

  public static String getCookie (HttpServletRequest req, String sName, String sDefault) {
    Cookie aCookies[] = req.getCookies();
    String sValue = null;

    for (int c=0; c<aCookies.length; c++) {
      if (aCookies[c].getName().equals(sName)) {
        sValue = URLDecoder.decode(aCookies[c].getValue());
        break;
      } // fi(aCookies[c]==sName)
    } // next(c)
    return sValue!=null ? sValue : sDefault;
  } // getCookie()

  public static String getCookie (HttpServletRequest req, String sName, String sDefault, String sEncoding)
  	throws java.io.UnsupportedEncodingException {
    Cookie aCookies[] = req.getCookies();
    String sValue = null;

    if (null != aCookies) {
      for (int c=0; c<aCookies.length; c++) {
        if (aCookies[c].getName().equals(sName)) {
          sValue = aCookies[c].getValue();
          if (null!=sValue)
            sValue = URLDecoder.decode(aCookies[c].getValue(),sEncoding);
          break;
        } // fi(aCookies[c]==sName)
      } // next(c)
    } // fi
    return sValue!=null ? sValue : sDefault;
  } // getCookie()

} // Cookies
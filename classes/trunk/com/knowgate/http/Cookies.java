package com.knowgate.http;

/**
 * <p>Cookies</p>
 * <p>Company: KnowGate</p>
 * @version 1.0
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
} // Cookies
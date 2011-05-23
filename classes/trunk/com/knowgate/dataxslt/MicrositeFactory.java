/*
  Copyright (C) 2003  Know Gate S.L. All rights reserved.
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

package com.knowgate.dataxslt;

import java.util.HashMap;

import com.knowgate.debug.DebugFile;

/**
 * A SoftReferences cache to Microsite objects.
 * When working with XSL tranformations, typically only a small number of Microsite
 * definitions are used. the definitions are stored in XML files that have to be parsed
 * for adding data to PageSets.<br>
 * MicrositeFactory loads once and the reuses Microsite objects reducing disk access
 * and CPU intensive XML parsing routines.
 * @author Sergio Montoro Ten
 * @version 1.0
 */
import java.lang.ref.SoftReference;

public class MicrositeFactory {
  public static boolean bCache = true;
  public static HashMap oMicrosites = new HashMap();

  public MicrositeFactory() {
  }

  /**
   * @return Caching status on/off
   */
  public static boolean cache () {
    return bCache;
  }

  /**
   * Turns Microsite caching on/off
   * @param bCacheOnOf <b>true</b> if Microsite caching is to be activated,
   * <b>false</b> if Microsite caching is to be deactivated.
   */
  public static void cache (boolean bCacheOnOf) {
    bCache = bCacheOnOf;
    if (false==bCacheOnOf)
      oMicrosites.clear();
  }

  /**
   * Get a Microsite from an XML file
   * If Microsite is cached then cached instance is returned.
   * @param sURI XML file URI starting with file://
   * (for example file:///opt/knowgate/storage/xslt/templates/Comtemporary.xml)
   * @param bValidateXML <b>true</b> if XML validation with W3C schemas is to be done,
   * <b>false</b> is no validation is to be done.
   * @return Microsite instance
   * @throws ClassNotFoundException
   * @throws IllegalAccessException
   */
  public static synchronized Microsite getInstance(String sURI, boolean bValidateXML) throws ClassNotFoundException, Exception, IllegalAccessException {
    Microsite oRetObj;
    Object oRefObj;

	if (DebugFile.trace) {
	  DebugFile.writeln("Begin MicrositeFactory.getInstance("+sURI+", "+String.valueOf(bValidateXML)+")");
	  DebugFile.incIdent();
	  DebugFile.writeln("cache is "+(bCache ? "enabled" : "disabled"));
	}
	
    if (bCache) {
      oRefObj = oMicrosites.get(sURI);

      if (null == oRefObj) {
      	if (DebugFile.trace) DebugFile.writeln("cache miss");
        oRetObj = new Microsite(sURI, bValidateXML);
        oMicrosites.put(sURI, new SoftReference(oRetObj));
      }
      else {
        oRetObj = (Microsite) ( (SoftReference) oRefObj).get();
        if (null == oRetObj)
          oRetObj = new Microsite(sURI, bValidateXML);
        else if (DebugFile.trace) DebugFile.writeln("cache hit");
      }
      return oRetObj;
    }
    else {
      oRetObj = new Microsite(sURI, bValidateXML);
    }

	if (DebugFile.trace) {
	  DebugFile.decIdent();
	  DebugFile.writeln("End MicrositeFactory.getInstance()");
	}

    return oRetObj;
  } // getInstance

  // ---------------------------------------------------------------------------

  /**
   * Get a Microsite from an XML file
   * If Microsite is cached then cached instance is returned.
   * XML validation is disabled.
   * @param sURI XML file path
   * @return Microsite instance
   * @throws ClassNotFoundException
   * @throws IllegalAccessException
   */

  public static Microsite getInstance(String sURI) throws ClassNotFoundException, Exception, IllegalAccessException {
    return getInstance(sURI, false);
  } // getInstance
}
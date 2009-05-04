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

package com.knowgate.hipergate.locale;

import java.io.InputStream;
import java.io.IOException;

import java.util.Properties;

/**
 * <p>Get an instance of a class implementing ITaxCalculator interface for the given locale</p>
 * @author Sergio Montoro Ten
 * @version 4.0
 */
public class TaxCalculatorFactory {

  private static Properties oFactoryProperties = null;
  	
  /**
   * Get tax calculator given a two letter ISO country code
   * @param sCountryId Country code
   * @return ITaxCalculator
   * @throws InstantiationException
   */	
  public static ITaxCalculator getCalculator(String sCountryId)
  	throws InstantiationException {
    String sLCaseCountryId = sCountryId.toLowerCase();

    if (null==oFactoryProperties) {
      
      InputStream oIoStrm = new TaxCalculatorFactory().getClass().getResourceAsStream("TaxCalculators.cnf");
      if (null!=oIoStrm) {
      	try {
          oFactoryProperties = new Properties();
          oFactoryProperties.load(oIoStrm);
          oIoStrm.close();
        } catch (IOException ioe) {
      	  throw new InstantiationException("Could not load file com/knowgate/hipergate/locale/TaxCalculators.cnf");        	
        }
      } else {
      	throw new InstantiationException("File not found com/knowgate/hipergate/locale/TaxCalculators.cnf");
      }
    } // fi
	
	String sImplementationClass = oFactoryProperties.getProperty(sLCaseCountryId);
	
	if (null==sImplementationClass) {
      throw new InstantiationException("Tax class not found for country "+sLCaseCountryId+" at file com/knowgate/hipergate/locale/TaxCalculators.cnf");
	}

	Class oImplementationClass = null;
	try {
	  oImplementationClass = Class.forName(sImplementationClass);
	} catch (ClassNotFoundException cnfe) {
      throw new InstantiationException("Class not found "+sImplementationClass);
	}
	
	ITaxCalculator oTaxCalc;
	
	try {
	  oTaxCalc = (ITaxCalculator) oImplementationClass.newInstance();
	} catch (IllegalAccessException iae) {
      throw new InstantiationException("Illegal access whilst instantiating "+sImplementationClass);	
	}

	return oTaxCalc;
  }

}

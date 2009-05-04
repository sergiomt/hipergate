/*
  Copyright (C) 2006  Know Gate S.L. All rights reserved.
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

package com.knowgate.hipergate.locale.es;

import java.math.BigDecimal;

import com.knowgate.hipergate.locale.ITaxCalculator;

/**
 * IVA, IGI and IPSI taxes calculator for Spain
 * @author Sergio Montoro Ten
 * @version 1.0
 */
public class TaxCalculatorEs implements ITaxCalculator {

    /**
     * IPSI Ceuta 3%
     */
  public static final BigDecimal IPSICeuta = new BigDecimal("0.03");
  /**
   * IPSI Melilla 4%
   */
  public static final BigDecimal IPSIMelilla = new BigDecimal("0.04");
  /**
   * IGI Canarias 5%
   */
  public static final BigDecimal IGICCanarias = new BigDecimal("0.05");
  /**
   * IVA Península y Baleares 16%
   */
  public static final BigDecimal IVAPeninsula = new BigDecimal("0.16");

  // ---------------------------------------------------------------------------

  /**
   * Get tax that applies to a given zip code.
   * @param sCodPost String Código Postal o Nombre de Provincia
   * @param sTipo String Tax type (currently not used)
   * @return BigDecimal IGICCanarias if sCodPost IN
   * {'38','35',TENERIFE','PALMAS, LAS','LAS PALMAS','GRAN CANARIA'}
   * IPSICeuta if sCodPost IN {'51','CEUTA'}
   * IPSIMelilla if sCodPost IN {'52','MELILLA'}
   * else IVAPeninsula.<br>
   * If sCodPost is <b>null</b> then IVAPeninsula is returned.
   */
  public static BigDecimal pctTasa (String sCodPost, String sTipo) {
    if (null==sCodPost)
      return IVAPeninsula;
    else if (sCodPost.startsWith("38") || sCodPost.startsWith("35") ||
             sCodPost.toUpperCase().indexOf("TENERIFE")>=0 ||
             sCodPost.equalsIgnoreCase("PALMAS, LAS") ||
             sCodPost.startsWith("LAS PALMAS ") ||
             sCodPost.toUpperCase().indexOf("GRAN CANARIA")>=0)
      return IGICCanarias;
    else if (sCodPost.startsWith("51") || sCodPost.equalsIgnoreCase("CEUTA"))
      return IPSICeuta;
    else if (sCodPost.startsWith("52") || sCodPost.equalsIgnoreCase("MELILLA"))
      return IPSIMelilla;
    else
      return IVAPeninsula;
  } // pctTasa

  // ---------------------------------------------------------------------------

  /**
   * @see pctTasa
   */
  public BigDecimal getTaxPct(String sTaxZone, String sItemType)
      throws NullPointerException,IllegalArgumentException {
    return pctTasa(sTaxZone, sItemType);
  }

  // ---------------------------------------------------------------------------

  /**
   * Get tax amount for a base price
   * @param oBasePrice BigDecimal Base Price
   * @param sCodPost String Código Postal o Nommbre de Provincia
   * @param sItemType String Not used
   * @return BigDecimal oBasePrice * getTaxPct(sCodPost, sItemType)
   * @throws NullPointerException
   * @throws IllegalArgumentException
   */
  public BigDecimal getTax(BigDecimal oBasePrice, String sCodPost, String sItemType)
    throws NullPointerException,IllegalArgumentException {
    return oBasePrice.multiply(pctTasa(sCodPost,sItemType));
  }
}

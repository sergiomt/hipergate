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

package com.knowgate.math;

import java.util.Locale;

import java.math.BigInteger;
import java.math.BigDecimal;

import java.text.DecimalFormat;
import java.text.FieldPosition;
import java.text.NumberFormat;

import com.knowgate.misc.Gadgets;

/**
 * <p>Combination of BigDecimal with Currency Sign</p>
 * This class handles money amounts that include a currency sign
 * @author Sergio Montoro Ten
 * @version 1.0
 */
public class Money extends BigDecimal {

  private static final long serialVersionUID = 1l;

  private static final DecimalFormat FMT2 = new DecimalFormat();
  
  // private static final FieldPosition FRAC = new FieldPosition(NumberFormat.FRACTION_FIELD);

  private CurrencyCode oCurrCode;

  // ---------------------------------------------------------------------------

  private Money(String sVal) throws UnsupportedOperationException {
    super(sVal);
    throw new UnsupportedOperationException("Money(String) is not an allowed constructor");
  }

  // ---------------------------------------------------------------------------

  /**
   * Constructor that makes a copy from another Money value
   */
  public Money(Money oVal) {
    super(((BigDecimal) oVal).toString());
    oCurrCode = oVal.oCurrCode;
  }

  // ---------------------------------------------------------------------------

  /**
   * Constructor
   * @param sVal String Numeric value in US decimal format (using dot as decimal delimiter)
   * @param oCur CurrencyCode
   * @throws NumberFormatException
   */
  public Money(String sVal, CurrencyCode oCur) throws NumberFormatException {
    super(sVal);
    oCurrCode = oCur;
  }

  // ---------------------------------------------------------------------------

  /**
   * Constructor
   * @param sVal String Numeric value in US decimal format (using dot as decimal delimiter)
   * @param sCur String Currency alphanumeric code {"USD", "EUR", etc.}
   * @throws NumberFormatException
   * @throws IllegalArgumentException
   */
  public Money(String sVal, String sCur)
    throws NumberFormatException, IllegalArgumentException {
    super(sVal);
    oCurrCode = CurrencyCode.currencyCodeFor(sCur);
    if (null==oCurrCode) throw new IllegalArgumentException("Money() "+sCur+" is not a legal currency alphanumeric code");
  }

  // ---------------------------------------------------------------------------

  /**
   * Constructor
   * @param dVal double
   * @param oCur CurrencyCode
   */
  public Money(double dVal, CurrencyCode oCur) {
    super(dVal);
    oCurrCode = oCur;
  }

  // ---------------------------------------------------------------------------

  /**
   * Constructor
   * @param dVal double
   * @param sCur String Currency alphanumeric code {"USD", "EUR", etc.}
   * @throws IllegalArgumentException
   */
  public Money(double dVal, String sCur) throws IllegalArgumentException {
    super(dVal);
    oCurrCode = CurrencyCode.currencyCodeFor(sCur);
  }

  // ---------------------------------------------------------------------------

  public Money(BigDecimal oVal, CurrencyCode oCur) {
    super(oVal.toString());
    oCurrCode = oCur;
  }

  // ---------------------------------------------------------------------------

  public Money(BigDecimal oVal, String sCur) {
    super(oVal.toString());
    oCurrCode = CurrencyCode.currencyCodeFor(sCur);
  }

  // ---------------------------------------------------------------------------

  public Money(BigInteger oVal, CurrencyCode oCur) {
    super(oVal);
    oCurrCode = oCur;
  }

  // ---------------------------------------------------------------------------

  public Money(BigInteger oVal, String sCur) {
    super(oVal);
    oCurrCode = CurrencyCode.currencyCodeFor(sCur);
  }

  // ---------------------------------------------------------------------------

  public CurrencyCode currencyCode() {
    return oCurrCode;
  }

  // ---------------------------------------------------------------------------

   public int compareTo(Money oMny) {
    if (currencyCode().equals(oMny.currencyCode()))
      return super.compareTo(oMny);
    else
      return super.compareTo(oMny.convertTo(currencyCode()));         	
   } // compareTo

  // ---------------------------------------------------------------------------

   public Money max(Money oMny) {
	  return compareTo(oMny)<0 ? oMny : this;
   } // max

  // ---------------------------------------------------------------------------

   public Money min(Money oMny) {
	  return compareTo(oMny)<0 ? this : oMny;
   } // max
   	
  // ---------------------------------------------------------------------------

  /**
   * <p>Add two money amounts</p>
   * The return value is in the currency of this object.
   * If the added amount does not have the same currency
   * then it is converted by calling a web service before performing addition.
   * The scale of the returned value is max(this.scale(), oMny.scale()).
   * @return this.value + (to this currency) oMny.value
   * @throws NullPointerException
   */
  public Money add(Money oMny) throws NullPointerException {
    if (oMny.signum()==0)
      return new Money(this);
    else if (currencyCode().equals(oMny.currencyCode()))
      return new Money (super.add(oMny),currencyCode());
    else
      return new Money (super.add(oMny.convertTo(currencyCode())),currencyCode());
  } // add

  // ---------------------------------------------------------------------------

  /**
   * <p>Subtract two money amounts</p>
   * The return value is in the currency of this object.
   * If the added amount does not have the same currency
   * then it is converted by calling a web service before performing addition.
   * The scale of the returned value is max(this.scale(), oMny.scale()).
   * @return this.value - (to this currency) oMny.value
   * @throws NullPointerException
   */
  public Money subtract(Money oMny) throws NullPointerException {
    if (oMny.signum()==0)
      return new Money(this);
    else if (currencyCode().equals(oMny.currencyCode()))
      return new Money (super.subtract(oMny),currencyCode());
    else
      return new Money (super.subtract(oMny.convertTo(currencyCode())),currencyCode());
  } // subtract
  	
  // ---------------------------------------------------------------------------

  /**
   * <p>Checks whether the given string can be parsed as a valid Money value</p>
   * Both comma and dot are allowed as either thousands or decimal delimiters.
   * If there is only a comma or a dot then it is assumed to be de decimal delimiter.
   * If both comma and dot are present, then the leftmost of them is assumed to
   * be the thousands delimiter and the rightmost is the decimal delimiter.
   * Any letters and currency symbols {€$£¤¢¥#ƒ&} are ignored
   */
  public static boolean isMoney (String sVal) {
    if (sVal==null) return false;
    if (sVal.length()==0) return false;
    String sAmount = sVal.toUpperCase();
    int iDot = sAmount.indexOf('.');
    int iCom = sAmount.indexOf(',');
    if (iDot!=0 && iCom!=0) {
      if (iDot>iCom) {
        Gadgets.removeChar(sAmount,',');
      } else {
        Gadgets.removeChar(sAmount,'.');
      }
    } // fi
    sAmount = sAmount.replace(',','.');
    sAmount = Gadgets.removeChars(sAmount, "€$£¤¢¥#ƒ& ABCDEFGHIJKLMNOPQRSZUVWXYZ");
    boolean bMatch = false;
    try {
      bMatch = Gadgets.matches(sAmount, "(\\+|-)?([0-9]+)|([0-9]+.[0-9]+)");
    } catch (org.apache.oro.text.regex.MalformedPatternException neverthrown) {}
    return bMatch;
  } // isMoney

  // ---------------------------------------------------------------------------

  public static Money parse(String sVal)
    throws NullPointerException,IllegalArgumentException,NumberFormatException {
    int iDot, iCom;
    CurrencyCode oCur = null;
    String sAmount;

    if (null==sVal) throw new NullPointerException("Money.parse() argument cannot be null");
    if (sVal.length()==0) throw new IllegalArgumentException("Money.parse() argument cannot be an empty string");

    sAmount = sVal.toUpperCase();
    if (sAmount.indexOf("EUR")>=0 || sAmount.indexOf("€")>=0 || sAmount.indexOf("&euro;")>=0)
      oCur = CurrencyCode.EUR;
    else if (sAmount.indexOf("USD")>=0 || sAmount.indexOf("$")>=0)
      oCur = CurrencyCode.USD;
    else if (sAmount.indexOf("GBP")>=0 || sAmount.indexOf("£")>=0)
      oCur = CurrencyCode.GBP;
    else if (sAmount.indexOf("JPY")>=0 || sAmount.indexOf("YEN")>=0 || sAmount.indexOf("¥")>=0)
      oCur = CurrencyCode.JPY;
    else if (sAmount.indexOf("CNY")>=0 || sAmount.indexOf("YUAN")>=0)
      oCur = CurrencyCode.CNY;

    iDot = sAmount.indexOf('.');
    iCom = sAmount.indexOf(',');

    if (iDot!=0 && iCom!=0) {
      if (iDot>iCom) {
    	sAmount = Gadgets.removeChar(sAmount,',');
      } else {
    	sAmount = Gadgets.removeChar(sAmount,'.');
      }
    } // fi

    sAmount = sAmount.replace(',','.');
    sAmount = Gadgets.removeChars(sAmount, "€$£¤¢¥#ƒ& ABCDEFGHIJKLMNOPQRSZUVWXYZ");

    return  new Money(sAmount, oCur);
  } // parse

  // ---------------------------------------------------------------------------

  /**
   * Rounds a BigDecimal value to two decimals
   * @return BigDecimal
   */
  public Money round2 () {
    FMT2.setMaximumFractionDigits(2);    
    return new Money (FMT2.format(doubleValue()).replace(',', '.'), oCurrCode);
  }

  // ---------------------------------------------------------------------------

  /**
   * <p>Convert <b>this</b> money to another currency</p>
   * @param oTarget Target CurrencyCode
   * @param oRatio BigDecimal Conversion ratio
   * @return Money if <b>this</b> CurrencyCode is the same as oTarget
   * then <b>this</b> is returned without any modification,
   * if if <b>this</b> CurrencyCode is different from oTarget
   * then the returned value is <b>this</b> multiplied by oRatio.
   * @throws NullPointerException if oTarget is <b>null</b>
   */
  public Money convertTo (CurrencyCode oTarget, BigDecimal oRatio)
    throws NullPointerException {

    Money oNewVal;

    if (oTarget==null) throw new NullPointerException("Money.convertTo() target currency cannot be null");
    if (oRatio==null) throw new NullPointerException("Money.convertTo() conversion ratio cannot be null");

    if (oCurrCode!=null) {
      if (oCurrCode.equals(oTarget))
        oNewVal = this;
      else
        oNewVal = new Money(multiply(oRatio), oTarget);
    } else {
      oNewVal = new Money(multiply(oRatio), oTarget);
    }
    return oNewVal;
  } // convertTo

  // ---------------------------------------------------------------------------

  /**
   * <p>Convert <b>this</b> money to another currency</p>
   * @param oTarget Target CurrencyCode
   * @param oRatio BigDecimal Conversion ratio
   * @return Money if <b>this</b> CurrencyCode is the same as oTarget
   * then <b>this</b> is returned without any modification,
   * if if <b>this</b> CurrencyCode is different from oTarget
   * then the returned value is <b>this</b> multiplied by oRatio.
   * @throws NullPointerException if oTarget is <b>null</b>
   */
  public Money convertTo (String sTarget, BigDecimal oRatio)
    throws NullPointerException,IllegalArgumentException {

    if (sTarget==null) throw new NullPointerException("Money.convertTo() target currency cannot be null");

    oCurrCode = CurrencyCode.currencyCodeFor(sTarget);
    if (null==oCurrCode) throw new IllegalArgumentException("Money.convertTo() "+sTarget+" is not a legal currency alphanumeric code");

	return convertTo(oCurrCode, oRatio);
  } // convertTo

  // ---------------------------------------------------------------------------

  /**
   * <p>Convert <b>this</b> money to another currency using a web service for finding the conversion ratio</p>
   * @param oTarget Target CurrencyCode
   * @throws NullPointerException if oTarget is <b>null</b>
   * @throws NumberFormatException
   */

  public Money convertTo (CurrencyCode oTarget)
    throws NullPointerException,NumberFormatException {
    
	return convertTo(oTarget, new BigDecimal(oCurrCode.conversionRateTo(oTarget)));
  } // convertTo

  // ---------------------------------------------------------------------------

  /**
   * <p>Convert <b>this</b> money to another currency using a web service for finding the conversion ratio</p>
   * @param sTarget 3 letter Code of Target Currency
   * @throws NullPointerException if oTarget is <b>null</b>
   * @throws IllegalArgumentException if sTarget is not a valid currency code
   * @throws NumberFormatException
   */

  public Money convertTo (String sTarget)
    throws NullPointerException,NumberFormatException,IllegalArgumentException {
	return convertTo(CurrencyCode.currencyCodeFor(sTarget));
  } // convertTo

  // ---------------------------------------------------------------------------

 /**
  * Format a BigDecimal as a String following the rules for an specific language and country
  * @param sLanguage String ISO-639 two letter language code
  * @param sCountry String ISO-3166 two leter country code
  * @return String
  */

 public String format (String sLanguage, String sCountry) {

    Locale oLoc;
    
    if (null==sCountry) sCountry = oCurrCode.countryCode();

    if (null!=sLanguage && null!=sCountry)
      oLoc = new Locale(sLanguage,sCountry);
    else if (null!=sLanguage)
      oLoc = new Locale(sLanguage);
    else
      oLoc = Locale.getDefault();
    NumberFormat oFmtC = NumberFormat.getCurrencyInstance(oLoc);
    oFmtC.setCurrency(currencyCode().currency());
    return oFmtC.format(doubleValue());
  } // format

  // ---------------------------------------------------------------------------

  public String toLocaleString () {
    if (oCurrCode==null)
      return super.toString();
    else
     return super.toString()+" "+oCurrCode.alphaCode();
  }

  // ---------------------------------------------------------------------------

}

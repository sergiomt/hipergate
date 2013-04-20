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

package com.knowgate.misc;

import java.util.Date;
import java.util.GregorianCalendar;
import java.util.regex.Pattern;

import com.knowgate.debug.DebugFile;

/**
 * <p>Calendar localization functions</p>
 * @author Sergio Montoro Ten
 * @version 7.0
 */

public class Calendar {

  public static final int SUNDAY = 0;
  public static final int MONDAY = 1;
  public static final int TUESDAY = 2;
  public static final int WEDNESDAY = 3;
  public static final int THURSDAY = 4;
  public static final int FRIDAY = 5;
  public static final int SATURDAY = 6;

  private static String WeekDayNamesES[] = { null, "domingo", "lunes", "martes", "miércoles", "jueves", "viernes", "sábado" };
  private static String WeekDayNamesEN[] = { null, "Sunday", "Monday", "Tuesday", "Wednesday", "Thursday", "Friday", "Saturday" };
  private static String WeekDayNamesIT[] = { null, "Domenica", "Lunedì", "Martedì", "Mercoledì", "Giovedì", "Venerdì", "Sabato" };
  private static String WeekDayNamesFR[] = { null, "Dimanche", "Lundi", "Mardi", "Mercredi", "Jeudi", "Vendredi", "Samedi" };
  private static String WeekDayNamesDE[] = { null, "Sonntag", "Montag", "Dienstag", "Mittwoch", "Donnerstag", "Freitag", "Samstag" };
  private static String WeekDayNamesPT[] = { null, "Domingo", "Segunda-feira", "Terça-feira", "Quarta-feira", "Quinta-feira", "Sexta-feira", "Sábado" };
  private static String WeekDayNamesRU[] = { null, "Воскресенье", "понедельник", "вторник", "среда", "четверг", "пятница", "суббота" };
  private static String WeekDayNamesCN[] = { null, "周日", "周一", "周二", "周三", "周四", "周五", "周六" };
  private static String WeekDayNamesNO[] = { null, "søndag", "mandag", "tirsdag", "onsdag", "torsdag", "fredag", "lørdag" };
  private static String WeekDayNamesPL[] = { null, "niedziela", "poniedzialek", "wtorek", "sroda", "czwartek", "piatek", "sobota" };

  private static String MonthNamesES[] = { "Enero","Febrero","Marzo","Abril","Mayo","Junio","Julio","Agosto","Septiembre","Octubre","Noviembre","Diciembre" };
  private static String MonthNamesEN[] = { "January","February","March","April","May","June","July","August","September","October","November","December" };
  private static String MonthNamesIT[] = { "Gennaio","Febbraio","Marzo","Aprile","Maggio","Giugno","Luglio","Agosto","Settembre","Ottobre","Novembre","Dicembre" };
  private static String MonthNamesFR[] = { "Janvier","Février","Mars","Avril","Mai","Juin","Juillet","Août","Septembre","Octobre","Novembre","Décembre" };
  private static String MonthNamesDE[] = { "Januar","Februar","März","April","Mai","Juni","Juli","August","September","Oktober","November","Dezember" };
  private static String MonthNamesPT[] = { "Janeiro","Fevereiro","Março","Abril","Maio","Junho","Julho","Agosto","Setembro","Outubro","Novembro","Dezembro" };
  private static String MonthNamesRU[] = { "Январь", "	Февраль", "март", "Апрель", "Пусть", "июня", "Июль", "Август", "сентябрь", "Октябрь", "Ноябрь", "Декабрь" };
  private static String MonthNamesCN[] = { "一月","二月","3月","4月","五月","六月","7月","8月","9月","10月","十一月","12月" };
  private static String MonthNamesNO[] = { "januar","februar","mars","april","mai","juni","juli","august","september","oktober","november","desember" };
  private static String MonthNamesPL[] = { "Styczen","Luty","Marzec","Kwiecien","Maj","Czerwiec","Lipiec","Sierpien","Wrzesien","Pazdziernik","Listopad","Grudzien" };

  private static String MonthNamesRFC[] = { "Jan","Feb","Mar","Apr","May","Jun","Jul","Aug","Sep","Oct","Nov","Dec" };

  //-----------------------------------------------------------

  /**
   * Get translated week day name
   * @param MyWeekDay [1=Sunday .. 7=Saturday]
   * @param sLangId 2 characters language identifier (currently only { "en","es","it","fr","de" and "pt" } are supported)
   * @return Week day name
   */
  public static String WeekDayName(int MyWeekDay, String sLangId) {

    if (DebugFile.trace) {
      DebugFile.writeln("Begin WeekDayName(" + String.valueOf(MyWeekDay) + "," + sLangId + ")");
      DebugFile.incIdent();
    }

    String sRetVal;

    if (MyWeekDay<1 || MyWeekDay>7)
      throw new java.lang.IllegalArgumentException("Calendar.WeekDayName 1st parameter (MyWeekDay) is " + String.valueOf(MyWeekDay) + " but must be in the range [1..7]");
    else {
      if (null==sLangId)
        throw new java.lang.IllegalArgumentException("Calendar.WeekDayName 2nd parameter (Language Id.) is null but must be one of {es,en,it,fr,de,pt,ru,cn,no} but is null");
      else if (sLangId.equalsIgnoreCase("es"))
        sRetVal = WeekDayNamesES[MyWeekDay];
      else if (sLangId.equalsIgnoreCase("en"))
        sRetVal = WeekDayNamesEN[MyWeekDay];
      else if (sLangId.equalsIgnoreCase("fr"))
        sRetVal = WeekDayNamesFR[MyWeekDay];
      else if (sLangId.equalsIgnoreCase("de"))
        sRetVal = WeekDayNamesDE[MyWeekDay];
      else if (sLangId.equalsIgnoreCase("it"))
        sRetVal = WeekDayNamesIT[MyWeekDay];
      else if (sLangId.equalsIgnoreCase("pt"))
        sRetVal = WeekDayNamesPT[MyWeekDay];
      else if (sLangId.equalsIgnoreCase("ru"))
        sRetVal = WeekDayNamesRU[MyWeekDay];
      else if (sLangId.equalsIgnoreCase("no"))
        sRetVal = WeekDayNamesNO[MyWeekDay];
      else if (sLangId.equalsIgnoreCase("pl"))
        sRetVal = WeekDayNamesPL[MyWeekDay];
      else if (sLangId.equalsIgnoreCase("cn"))
        sRetVal = WeekDayNamesCN[MyWeekDay];
      else
        throw new java.lang.IllegalArgumentException("Calendar.WeekDayName 2nd parameter (Language Id.) must be one of {es,en,it,fr,de,pt,ru,cn,no} but is "+sLangId);
    }

    if (DebugFile.trace) {
      DebugFile.decIdent();
      DebugFile.writeln("End WeekDayName() : " + sRetVal);
    }

    return sRetVal;
  } // WeekDay

  //-----------------------------------------------------------

  /**
   * Get translated month name
   * @param MyMonth [0=January .. 11=December]
   * @param sLangId sLangId 2 characters language identifier (currently only  { "en","es","it","fr","de" and "pt" } are supported)
   * @return Month Name
   * @throws IllegalArgumentException if sLangId is not one of {es, en, fr, it, de, pt}
   */
  public static String MonthName(int MyMonth, String sLangId)
  	throws IllegalArgumentException {

    if (DebugFile.trace) {
      DebugFile.writeln("Begin MonthName(" + String.valueOf(MyMonth) + "," + sLangId + ")");
      DebugFile.incIdent();
    }

    String sRetVal;

    if (MyMonth<0 || MyMonth>11)
      throw new java.lang.IllegalArgumentException("Calendar.MonthName 1st parameter (MyMonth) is " + String.valueOf(MyMonth) + " but must be in the range [0..11]");
    else {
      if (null==sLangId)
        throw new java.lang.IllegalArgumentException("Calendar.MonthName 2nd parameter (Language Id.) is null but must be one of {es,en,it,fr,de,pt,ru,cn,no} but is null");
      else if (sLangId.equalsIgnoreCase("es"))
        sRetVal = MonthNamesES[MyMonth];
      else if (sLangId.equalsIgnoreCase("en"))
        sRetVal = MonthNamesEN[MyMonth];
      else if (sLangId.equalsIgnoreCase("fr"))
        sRetVal = MonthNamesFR[MyMonth];
      else if (sLangId.equalsIgnoreCase("it"))
        sRetVal = MonthNamesIT[MyMonth];
      else if (sLangId.equalsIgnoreCase("de"))
        sRetVal = MonthNamesDE[MyMonth];
      else if (sLangId.equalsIgnoreCase("pt"))
        sRetVal = MonthNamesPT[MyMonth];
      else if (sLangId.equalsIgnoreCase("no"))
        sRetVal = MonthNamesNO[MyMonth];
      else if (sLangId.equalsIgnoreCase("ru"))
        sRetVal = MonthNamesRU[MyMonth];
      else if (sLangId.equalsIgnoreCase("pl"))
        sRetVal = MonthNamesPL[MyMonth];
      else if (sLangId.equalsIgnoreCase("cn"))
        sRetVal = MonthNamesCN[MyMonth];
      else
        throw new java.lang.IllegalArgumentException("Calendar.WeekDayName 2nd parameter (Language Id.) must be one of {es,en,it,fr,de,pt,ru,cn,no} but is "+sLangId);
    }

    if (DebugFile.trace) {
      DebugFile.decIdent();
      DebugFile.writeln("End MonthName() : " + sRetVal);
    }

    return sRetVal;
  } // MonthName

  //-----------------------------------------------------------

  /**
   * Get Month Last Day
   * @param MyMonth [0=January .. 11=December]
   * @param MyYear 4 digits year
   * @return the last day of the month. Takes into account leap years
   */
  public static int LastDay(int MyMonth, int MyYear) {

    if (MyMonth<0 || MyMonth>11)
      throw new java.lang.IllegalArgumentException("Calendar.LastDay 1st parameter (MyMonth) is " + String.valueOf(MyMonth) + " but must be in the range [0..11]");

    if (MyYear<1000 || MyYear>9999)
      throw new java.lang.IllegalArgumentException("Calendar.LastDay 2nd parameter (MyYear) is " + String.valueOf(MyYear) + " but must be in the range [1000..9999]");

    switch(MyMonth) {
      case 0:
      case 2:
      case 4:
      case 6:
      case 7:
      case 9:
      case 11:
        return 31;
      case 3:
      case 5:
      case 8:
      case 10:
        return 30;
      case 1:
        return ( (MyYear%400==0) || ((MyYear%4==0) && (MyYear%100!=0)) ) ? 29 : 28;
    } // end switch()
    return 0;
  } // LastDay()

  //-----------------------------------------------------------

  public static Date addMonths(int nMonths, Date dt) {
  	Date dtRetVal = dt;
  	if (nMonths>0) {
  	  for (int m=0; m<nMonths; m++) {
  	    dtRetVal = new Date(dtRetVal.getTime()+(86400000l*(LastDay(dtRetVal.getMonth(),dtRetVal.getYear()+1900))));
  	  }
  	} else if (nMonths<0) {
  	  for (int m=0; m>nMonths; m--) {
  	    dtRetVal = new Date(dtRetVal.getTime()-(86400000l*(LastDay(dtRetVal.getMonth(),dtRetVal.getYear()+1900))));
  	  }  		
  	}
  	return dtRetVal;
  } // addMonths

  //-----------------------------------------------------------

  public static int DaysBetween(Date dt1st, Date dt2nd) {
	return (int) Math.round(((double) (dt2nd.getTime() - dt1st.getTime())) / 86400000d); 
  } // DaysBetween

  //-----------------------------------------------------------

  public static int DaysBetween(GregorianCalendar dt1st, GregorianCalendar dt2nd) {
	return (int) Math.round(((double) (dt2nd.getTime().getTime() - dt1st.getTime().getTime())) / 86400000d); 
  } // DaysBetween

  //-----------------------------------------------------------
 
  public static Date[] ThisWeek(int iFirstDayOfWeek)
  	throws IllegalArgumentException {
  	
  	if (iFirstDayOfWeek<0 || iFirstDayOfWeek>6)
  	  throw new IllegalArgumentException("Week day must be between 0 and 6");
  	  	
    Date dtFirst = new Date();
    Date dtLast  = new Date();
    
    while (dtFirst.getDay()!=iFirstDayOfWeek) {
      dtFirst = new Date (dtFirst.getTime()-86400000l);
    }

    while (dtLast.getDay()!=(iFirstDayOfWeek==SUNDAY ? SATURDAY : SUNDAY)) {
      dtLast = new Date (dtLast.getTime()+86400000l);
    }

    return new Date[]{dtFirst,dtLast};
  } // ThisWeek

  //-----------------------------------------------------------
 
  public static Date[] LastWeek(int iFirstDayOfWeek)
  	throws IllegalArgumentException {
  	if (iFirstDayOfWeek<0 || iFirstDayOfWeek>6)
  	  throw new IllegalArgumentException("Week day must be between 0 and 6");
    Date[] aWeek = ThisWeek(iFirstDayOfWeek);
    aWeek[0] = new Date (aWeek[0].getTime()-(7l*86400000l));
    aWeek[1] = new Date (aWeek[1].getTime()-(7l*86400000l));
    return aWeek;
  } // LastWeek

  //-----------------------------------------------------------
 
  public static Date[] ThisMonth() {
    Date dtToday = new Date();
    Date dtFirst = new Date();
    Date dtLast  = new Date();    

    while (dtFirst.getDate()!=1) {
      dtFirst = new Date (dtFirst.getTime()-86400000l);
    }

    while (dtLast.getDate()!=LastDay(dtToday.getMonth(),dtToday.getYear()+1900)) {
      dtLast = new Date (dtLast.getTime()+86400000l);
    }
    
    return new Date[]{dtFirst,dtLast};
  } // ThisMonth

  //-----------------------------------------------------------
 
  public static Date[] LastMonth() {
    Date dtToday = new Date();
    Date dtFirst = new Date(dtToday.getMonth()==0 ? dtToday.getYear()-1 : dtToday.getYear(),
    						dtToday.getMonth()==0 ? 11 : dtToday.getMonth()-1, 1);
    Date dtLast = new Date(dtToday.getMonth()==0 ? dtToday.getYear()-1 : dtToday.getYear(),
    					   dtToday.getMonth()==0 ? 11 : dtToday.getMonth()-1,
    					   LastDay(dtToday.getMonth()==0 ? 11 : dtToday.getMonth()-1,
    					          (dtToday.getMonth()==0 ? dtToday.getYear()-1 : dtToday.getYear())+1900));

    
    return new Date[]{dtFirst,dtLast};    
  } // LastMonth
  
  
  /**
   * Verify that a string represents a valid date
   * @param dtexpr String
   * @param dtformat String Date format.
   * "d"  for dates with format "yyyy-MM-dd"
   * "s"  for dates with format "dd/MM/yyyy"
   * "ts" for dates with format "yyyy-MM-dd HH:mm:ss"
   * @since 7.0
  */  
  public static boolean isDate (String dtexpr, String dtformat) {
	    String[] ser;
	    boolean ret;
	    int yy, mm, dd;
	  
	    if (dtformat.equals("d")) {
	      if (Pattern.matches("[0-9]{4}-[0-9]{2}-[0-9]{2}", dtexpr)) {
	        ser = dtexpr.split("-");
	        yy = Integer.parseInt(ser[0],10);
	        mm = Integer.parseInt(ser[1],10)-1;
	        dd = Integer.parseInt(ser[2],10);
	      
	        if (mm<1 || mm>12) {
	          ret = false;
	        }
	        else if (dd>LastDay(mm-1,yy)) {
	          ret = false;
	        }
	        else
	          ret = true;                
	      }
	      else {
	        ret = false;
	      }
	    } else if (dtformat.equals("s")) {
	      if (Pattern.matches("[0-9]{2}/[0-9]{2}/[0-9]{4}", dtexpr)) {
	        ser = dtexpr.split("/");
	        yy = Integer.parseInt(ser[2],10);
	        mm = Integer.parseInt(ser[1],10)-1;
	        dd = Integer.parseInt(ser[0],10);
	      
	        if (mm<1 || mm>12) {
	          ret = false;
	        }
	        else if (dd>LastDay(mm-1,yy)) {
	          ret = false;
	        }
	        else
	          ret = true;                
	      }
	      else {
	        ret = false;
	      }
	    } else if (dtformat=="ts") {
	      if (Pattern.matches("[0-9]{4}-[0-9]{2}-[0-9]{2}.[0-9]{2}:[0-9]{2}:[0-9]{2}", dtexpr)) {
	        ret = isDate(dtexpr.substring(0,10), "d");
	      } else {
	        ret = false;
	      }      
	    } else {
	      ret = false;
	    }	    
	    return ret;
	  } // isDate()
}
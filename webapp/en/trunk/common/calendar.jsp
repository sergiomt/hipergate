<%@ page import="java.util.Date,java.net.URLDecoder" language="java" session="false" contentType="text/html;charset=UTF-8" %><%@ include file="../methods/cookies.jspf" %><%!
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

  static String MonthName(int MyMonth, String sLangId) {
     String MonthNamesES[] = { "Enero","Febrero","Marzo","Abril","Mayo","Junio","Julio","Agosto","Septiembre","Octubre","Noviembre","Diciembre" };
     String MonthNamesEN[] = { "January","February","March","April","May","June","July","August","September","October","November","December" };
     String MonthNamesIT[] = { "Gennaio","Febbraio","Marzo","Aprile","Maggio","Giugno","Luglio","Agosto","Settembre","Ottobre","Novembre","Dicembre" };
     String MonthNamesFR[] = { "Janvier","Février","Mars","Avril","Mai","Juin","Juillet","Août","Septembre","Octobre","Novembre","Décembre" };
     String MonthNamesDE[] = { "Januar","Februar","März","April","Mai","Juni","Juli","August","September","Oktober","November","Dezember" };
     String MonthNamesPT[] = { "Janeiro","Fevereiro","Março","Abril","Maio","Junho","Julho","Agosto","Setembro","Outubro","Novembro","Dezembro" };
     String MonthNamesNO[] = { "januar","februar","mars","april","mai","juni","juli","august","september","oktober","november","desember" };
     String MonthNamesRU[] = { "Январь", "	Февраль", "март", "Апрель", "Пусть", "июня", "Июль", "Август", "сентябрь", "Октябрь", "Ноябрь", "Декабрь" };
     String MonthNamesCN[] = { "一月","二月","3月","4月","五月","六月","7月","8月","9月","10月","十一月","12月" };
     String MonthNamesPL[] = { "Styczen","Luty","Marzec","Kwiecien","Maj","Czerwiec","Lipiec","Sierpien","Wrzesien","Pazdziernik","Listopad","Grudzien" };
    
    if (sLangId.equalsIgnoreCase("es"))
      return MonthNamesES[MyMonth];
    else if (sLangId.equalsIgnoreCase("it"))
      return MonthNamesIT[MyMonth];
    else if (sLangId.equalsIgnoreCase("fr"))
      return MonthNamesFR[MyMonth];
    else if (sLangId.equalsIgnoreCase("de"))
      return MonthNamesDE[MyMonth];
    else if (sLangId.equalsIgnoreCase("pt"))
      return MonthNamesPT[MyMonth];
    else if (sLangId.equalsIgnoreCase("ru"))
      return MonthNamesRU[MyMonth];
    else if (sLangId.equalsIgnoreCase("cn"))
      return MonthNamesCN[MyMonth];
    else if (sLangId.equalsIgnoreCase("no"))
      return MonthNamesNO[MyMonth];
    else if (sLangId.equalsIgnoreCase("pl"))
      return MonthNamesPL[MyMonth];
    else
      return MonthNamesEN[MyMonth];    
  } // MonthName

  // ----------------------------------------------------------
  
  static int LastDay(int MyMonth, int MyYear) {
    // Returns the last day of the month. Takes into account leap years
    // Usage: LastDay(Month, Year)
    // Example: LastDay(11,2000) or LastDay(11) or Lastday

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

  // ----------------------------------------------------------
  
  String PrevMonthURL(int iYear, int iMonth, String sCtrl) {
    String sURL = "calendar.jsp?";
    
    if (iMonth>0) {
      sURL += "a=" + String.valueOf(iYear) + "&m=" + String.valueOf(iMonth-1);
    }
    else
      sURL += "a=" + String.valueOf(iYear-1) + "&m=11";
    
    sURL += "&c=" + sCtrl;
    
    return sURL;
  } // PrevMonthURL()
  
  // ----------------------------------------------------------
  
  String NextMonthURL(int iYear, int iMonth, String sCtrl) {
    String sURL = "calendar.jsp?";
    
    if (iMonth<11) {
      sURL += "a=" + String.valueOf(iYear) + "&m=" + String.valueOf(iMonth+1);
    }
    else
      sURL += "a=" + String.valueOf(iYear+1) + "&m=0";
    
    sURL += "&c=" + sCtrl;
    
    return sURL;
  } // NextMonthURL()
  
%>

<%
  int  Month;      // Month of calendar
  int  MyYear;     // Year of calendar  
  int  FirstDay;   // First day of the month. (1 = Monday)
  int  CurrentDay; // Used to print dates in calendar
  int  Col;        // Calendar column
  int  Row;        // Calendar row
  int  MyMonth;
  String MyCtrl;   // Target control on opener form for date results
  Date dtNow = new Date();
  String sLanguage = getNavigatorLanguage(request);

  // ----------------------------------------------------------
  
  if (null!=request.getParameter("m"))
    MyMonth = Integer.parseInt(request.getParameter("m"));
  else
    MyMonth = dtNow.getMonth();

  if (null!=request.getParameter("a"))     
    MyYear = Integer.parseInt(request.getParameter("a"));
  else
    MyYear = dtNow.getYear()+1900;

  MyCtrl = request.getParameter("c");
  
  String MesAnyo = MonthName(MyMonth, sLanguage) + " " + String.valueOf(MyYear);
%>

<HTML LANG="<% out.write(sLanguage); %>">
  <HEAD>
    <TITLE>hipergate :: Calendar</TITLE>
    <SCRIPT SRC="../javascript/cookies.js"></SCRIPT>  
    <SCRIPT TYPE="text/javascript">
      <!--
      var skin = getCookie("skin");
      if (""==skin) skin="xp";
      
      document.write ('<LINK REL="stylesheet" TYPE="text/css" HREF="../skins/' + skin + '/styles.css">');
        
        
      function choose(currday) {
	      window.opener.document.forms[0].<%=MyCtrl%>.value = "<%=MyYear%>-<%=(MyMonth < 9 ? ("0" + String.valueOf(MyMonth+1)) : String.valueOf(MyMonth+1))%>-" + (currday<10 ? "0"+currday : currday);
	      if (window.opener.document.forms[0].<%=MyCtrl%>.onchange) window.opener.document.forms[0].<%=MyCtrl%>.onchange();
	      self.close();
      }          
      //-->
    </SCRIPT>
  </HEAD>
  <BODY TOPMARGIN="0" LEFTMARGIN="0" MARGINWIDTH="0" MARGINHEIGHT="0" SCROLL="no">
    <table border="0" cellpadding="0" cellspacing="0" width="171" bgcolor="#448af8">
      <tr>
        <td colspan="3">
        <!-- inicio del content -->
          <font face="Verdana,Arial" size="1" color="white">
          <center>
          <a style="color:#ffffff;text-decoration:none" title="Previous Month" href="<%=PrevMonthURL(MyYear,MyMonth,MyCtrl)%>">- &lt;&lt;</a>
          &nbsp;<b>Date</b>&nbsp;
          <a style="color:#ffffff;text-decoration:none" title="Next Month" href="<%=NextMonthURL(MyYear,MyMonth,MyCtrl)%>">&gt;&gt; +</a>
          </center>
          </font>
          <table border="0" cellpadding="2" cellspacing="0" width="100%">
            <tr>
              <td colspan="7" bgcolor="#0054A8" align="center">
                <font face="Verdana,Arial" size="1" color="white"><b><%=MesAnyo%></b></font>
              </td>
            </tr>
      	    <%
              out.write("            <tr>\n");	      
      	      if (sLanguage.equalsIgnoreCase("es")) {
		            String WeekDays[] = { "L","M","X","J","V","S","D"} ;
	              for (int w=0;w<7; w++)
	                out.write("              <td bgcolor=\"#0066CC\" align=\"center\"><font face=\"Verdana,Arial\" size=\"1\" color=\"white\">" + WeekDays[w] + "</font></td>\n");
                FirstDay = (new Date(MyYear, MyMonth, 0).getDay()+6)%7;
	              }
	            else {
		            String WeekDays[] = { "S","M","T","W","T","F","S"} ;
	              for (int w=0;w<7; w++)
	                out.write("              <td bgcolor=\"#0066CC\" align=\"center\"><font face=\"Verdana,Arial\" size=\"1\" color=\"white\">" + WeekDays[w] + "</font></td>\n");
                FirstDay = new Date(MyYear, MyMonth, 0).getDay();
	            }
              out.write("            </tr>\n");

              CurrentDay = 1;

              // Let's build the calendar
              for (int row=0; row<=5; row++) {
                out.write ("	    <tr>\n");
          	for (int col=0; col<=6; col++) {
            	  if (0==row && col<FirstDay)
                    out.write ("              <td bgcolor=\"white\" align=\"center\"><font class=\"calendarday\">-</font></td>\n");
            	  else if (CurrentDay > LastDay(MyMonth, MyYear))
                    out.write ("              <td bgcolor=\"white\" align=\"center\"><font class=\"calendarday\">-</font></td>\n");
                  else {
                    out.write ("              <td bgcolor=\"white\" align=\"center\"><a href=\"javascript:choose(" + CurrentDay + ")\" class=\"calendarday\">" + CurrentDay + "</a></td>\n");
                    CurrentDay++;
                  }
                } // next (col)            
              out.write ("	    </tr>\n");
              } // next (row)
            %>
          </table>
        </td>
      </tr>
    </table>
    <form><center><input type="button" class="closebutton" value="Close" onClick="self.close()"></center></form>
  </BODY>
</HTML>

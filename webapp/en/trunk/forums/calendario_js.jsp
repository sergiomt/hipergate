<%@ page import="java.text.SimpleDateFormat,java.util.ArrayList,java.util.Date,java.io.IOException,java.net.URLDecoder,java.sql.SQLException,com.knowgate.jdc.*,com.knowgate.dataobjs.*,com.knowgate.acl.*,com.knowgate.misc.Calendar,com.knowgate.misc.Gadgets,com.knowgate.misc.CGIParser,com.knowgate.forums.Forums" language="java" session="false" contentType="text/plain;charset=UTF-8" %>
<%@ include file="../methods/dbbind.jsp" %><%@ include file="../methods/cookies.jspf" %><%@ include file="../methods/authusrs.jspf" %><%@ include file="../methods/nullif.jspf" %><%

  // ********************************************************************************
  // El GUID del foro que se usa para mostrar eventos está en el fichero extranet.cnf
  //
  // ********************************************************************************
  //  
  // El año y el mes se pueden pasar como parámetros en la URL en la llamada o establecerse en cookies antes de cargar el JavaScript
  // Es decir, lo mismo se puede escribir
  // <script language="JavaScript" type="text/javascript"  src="http://extranet.fundacioncomillasweb.com/forums/calendario_js.jsp?cal_year=108&cal_month=0"></script>
  // que
  // <script>document.cookie="cal_year=108;path/";document.cookie="cal_month=1;path/";</script>
  // y luego
  // <script language="JavaScript" type="text/javascript"  src="http://extranet.fundacioncomillasweb.com/forums/calendario_js.jsp"></script>
  // sin parámetros
  // NOTA: recordar que el año es menos 1900 (2008=108) y elo mes es basado en cero (enero=0)
  //
  // ********************************************************************************
  //
  // Esta función JavaScript traspasa un parámetro de la URL a una cookie
  // está pensada para coger el año y el mes el la query string de la página de inicio
  // y dejarlas en una cookie antes de llamar al JavaScript que genera los document.write
  // del calendario.
  // 
  // function setCookieFromUrlQueryStr(name) {   
  //   var params = "&" + window.location.search.substr(1);    
  //   var indexa = params.indexOf("&" + name);
  //   var indexb;
  //   var retval;
        
  //   if (-1==indexa)
  //     retval = null;
  //   else {
  //     indexa += name.length+2;
  //     indexb = params.indexOf("&", indexa);
  //     indexb = (indexb==-1 ? params.length-1 : indexb-1);
  //     retval = params.substring(indexa, indexb+1);
  //   }
  //   document.cookie = name + "=" + escape(retval) +  "; path=/"
  // }  
  
  String sGuNewsGrp = GlobalDBBind.getProperty("events_es");
  String sLanguage = getNavigatorLanguage(request);
  String sRefYear = null;
  String sRefMonth = null;
  String sReferrer = request.getHeader("referer");
  if (null!=sReferrer) {
    int iQuest = sReferrer.indexOf('?');
    if (iQuest>0 && iQuest<sReferrer.length()-1) {
      CGIParser oQryStr = new CGIParser (sReferrer.substring(iQuest+1),"ISO8859_1");    
      sRefYear = oQryStr.getParameterValue("cal_year");
      sRefMonth = oQryStr.getParameterValue("cal_month");
    }
  }

  Date dtNow = new Date();
  int year = Integer.parseInt(nullif(request.getParameter("cal_year"),getCookie(request, "cal_year", nullif(sRefYear,String.valueOf(dtNow.getYear())))));
  int month = Integer.parseInt(nullif(request.getParameter("cal_month"),getCookie(request, "cal_month", nullif(sRefMonth,String.valueOf(dtNow.getMonth())))));

  final long lOneDayMilis = 24l*60l*60l*1000l;
  Date dtToday = new Date(year, month, 1);
  Date dtNextM = new Date(dtToday.getTime()+(((long)Calendar.LastDay(month,year+1900))*lOneDayMilis));
  Date dtLastD = new Date(dtNextM.getTime()-lOneDayMilis);
  String sMonth = Calendar.MonthName(month, sLanguage);
  int  FirstDay = (dtToday.getDay()+5)%7;
  int  CurrentDay = 1; // Used to print dates in calendar
  int  LastDay = Calendar.LastDay(month, year+1900);

  JDCConnection oConn = GlobalDBBind.getConnection("monthevents");  
  
  ArrayList oDays = Forums.getDaysWithPosts(oConn, sGuNewsGrp, dtToday, dtLastD);

  oConn.close("monthevents");

%>
document.write('        <div class="calendario">');
document.write('          <ol class="selectormes">');
document.write('            <li>');
document.write('            <a href="http://www.fundacioncomillasweb.com/es/publico/inicio.html?cal_year=<%=String.valueOf(year-(month==0 ? 1 :0))%>&cal_month=<%=String.valueOf(month==0 ? 11 : month-1)%>" title="Mes Anterior">&laquo;</a>&nbsp;<%=sMonth%>&nbsp;<%=String.valueOf(year+1900)%>&nbsp;<a href="http://www.fundacioncomillasweb.com/es/publico/inicio.html?cal_year=<%=String.valueOf(year+(month==11 ? 1 :0))%>&cal_month=<%=String.valueOf(month==11 ? 0 : month+1)%>" title="Mes Siguiente">&raquo;</a>');
document.write('            </li>');
document.write('          </ol>');
document.write('          <table class="tabla_mes" summary="Agenda de actividades">');
document.write('            <thead>');
document.write('              <tr>');
document.write('                <th scope="col">');
document.write('                  <abbr title="Lunes">L</abbr>');
document.write('                </th>');
document.write('                <th scope="col">');
document.write('                  <abbr title="Martes">M</abbr>');
document.write('                </th>');
document.write('                <th scope="col">');
document.write('                  <abbr title="Mi&eacute;rcoles">X</abbr>');
document.write('                </th>');
document.write('                <th scope="col">');
document.write('                  <abbr title="Jueves">J</abbr>');
document.write('                </th>');
document.write('                <th scope="col">');
document.write('                  <abbr title="Viernes">V</abbr>');
document.write('                </th>');
document.write('                <th scope="col">');
document.write('                  <abbr title="S&aacute;bado">S</abbr>');
document.write('                </th>');
document.write('                <th scope="col">');
document.write('                  <abbr title="Domingo">D</abbr>');
document.write('                </th>');
document.write('              </tr>');
document.write('            </thead>');
document.write('            <tbody>');
<%	for (int row=0; row<6; row++) {
	    out.write("document.write('              <tr>');\n");
	    for (int col=0; col<7; col++) {
        if ((CurrentDay<=LastDay) && (0!=row || col>FirstDay)) {
		      if (((Boolean) oDays.get(CurrentDay-1)).booleanValue())
	          out.write("document.write('                <td class=\"diaconevento\"><a href=\"http://extranet.fundacioncomillasweb.com/forums/eventos_dia.jsp?gu_newsgrp="+sGuNewsGrp+"&dt_date="+String.valueOf(year)+"-"+String.valueOf(month)+"-"+String.valueOf(CurrentDay)+"\">"+String.valueOf(CurrentDay)+"</a></td>');\n");
		      else
	          out.write("document.write('                <td>"+String.valueOf(CurrentDay)+"</td>');\n");
		      CurrentDay++;
		    } else {
	        out.write("document.write('                <td>&nbsp;</td>');\n");
		    }
		  } // next
	    out.write("document.write('              </tr>');\n");
    }

%>document.write('            </tbody>');
document.write('          </table>');
document.write('        </div>');

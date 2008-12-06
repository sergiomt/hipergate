<%@ page import="java.text.SimpleDateFormat,java.util.ArrayList,java.util.Date,java.io.IOException,java.net.URLDecoder,java.sql.SQLException,com.knowgate.jdc.*,com.knowgate.dataobjs.*,com.knowgate.acl.*,com.knowgate.misc.Calendar,com.knowgate.misc.Gadgets,com.knowgate.forums.Forums" language="java" session="false" contentType="text/plain;charset=UTF-8" %>
<%@ include file="../methods/dbbind.jsp" %><%@ include file="../methods/cookies.jspf" %><%@ include file="../methods/authusrs.jspf" %><%@ include file="../methods/nullif.jspf" %><%

  String sGuNewsGrp = GlobalDBBind.getProperty("events_es");
  String sLanguage = getNavigatorLanguage(request);

	int year, month;
  Date dtNow = new Date();
  if (null==request.getParameter("year"))
    year = dtNow.getYear();
  else
  	year = Integer.parseInt(request.getParameter("year"));
  	
  if (null==request.getParameter("month"))
    month = dtNow.getMonth();
  else
  	month = Integer.parseInt(request.getParameter("month"));

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

  <ol class="selectormes">
    <li>
    <a href="#" onclick="document.getElementById('rejilla_del_calendario').innerHTML=httpRequestText('http://extranet.fundacioncomillasweb.com/forums/calendario_div.jsp?year=<%=String.valueOf(year-(month==0 ? 1 :0))%>&month=<%=String.valueOf(month==0 ? 11 : month-1)%>')" title="Mes Anterior">&laquo;</a>&nbsp;<%=sMonth%>&nbsp;<%=String.valueOf(year+1900)%>&nbsp;<a href="#" onclick="document.getElementById('rejilla_del_calendario').innerHTML=httpRequestText('http://extranet.fundacioncomillasweb.com/forums/calendario_div.jsp?year=<%=String.valueOf(year+(month==11 ? 1 :0))%>&month=<%=String.valueOf(month==11 ? 0 : month+1)%>')" title="Mes Siguiente">&raquo;</a>
    </li>
  </ol>
  <table class="tabla_mes" summary="Agenda de actividades">
    <thead>
      <tr>
        <th scope="col">
          <abbr title="Lunes">L</abbr>
        </th>
        <th scope="col">
          <abbr title="Martes">M</abbr>
        </th>
        <th scope="col">
          <abbr title="Mi&eacute;rcoles">X</abbr>
        </th>
        <th scope="col">
          <abbr title="Jueves">J</abbr>
        </th>
        <th scope="col">
          <abbr title="Viernes">V</abbr>
        </th>
        <th scope="col">
          <abbr title="S&aacute;bado">S</abbr>
        </th>
        <th scope="col">
          <abbr title="Domingo">D</abbr>
        </th>
      </tr>
    </thead>
    <tbody>
<%	for (int row=0; row<6; row++) {
	    out.write("      <tr>\n");
	    for (int col=0; col<7; col++) {
        if ((CurrentDay<=LastDay) && (0!=row || col>FirstDay)) {
		      if (((Boolean) oDays.get(CurrentDay-1)).booleanValue())
	          out.write("        <td class=\"diaconevento\"><a href=\"http://extranet.fundacioncomillasweb.com/forums/eventos_dia.jsp?gu_newsgrp="+sGuNewsGrp+"&dt_date="+String.valueOf(year)+"-"+String.valueOf(month)+"-"+String.valueOf(CurrentDay)+"\">"+String.valueOf(CurrentDay)+"</a></td>\n");
		      else
	          out.write("        <td>"+String.valueOf(CurrentDay)+"</td>\n");
		      CurrentDay++;
		    } else {
	        out.write("        <td>&nbsp;</td>\n");
		    }
		  } // next
	    out.write("      </tr>\n");
    }

%>    </tbody>
  </table>


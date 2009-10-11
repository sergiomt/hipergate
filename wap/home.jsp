<%@ page language="java" import="java.util.Date,com.knowgate.dataobjs.DB,java.text.SimpleDateFormat,java.util.Date,java.sql.PreparedStatement,java.sql.ResultSet,java.sql.Timestamp,com.knowgate.addrbook.MonthPlan,com.knowgate.misc.Calendar,com.knowgate.misc.Gadgets,com.knowgate.workareas.ApplicationModule" session="true" contentType="text/vnd.wap.wml;charset=UTF-8" %><%@ include file="inc/dbbind.jsp" %><%
/*
  Copyright (C) 2009  Know Gate S.L. All rights reserved.

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

  response.addHeader ("Pragma", "no-cache");
  response.addHeader ("cache-control", "no-store");
  response.setIntHeader("Expires", 0);

  final SimpleDateFormat oFmtHour = new SimpleDateFormat("HH:mm");
  final SimpleDateFormat oFmtDate = new SimpleDateFormat(sLanguage.startsWith("es") ? "dd MMM" : "MMM dd");

  final String PAGE_NAME = "home";

  final String ye = request.getParameter("y");
  final String mo = request.getParameter("m");

  Date dtToday;
  if (ye==null || mo==null)
    dtToday = new Date();
  else
    dtToday = new Date(Integer.parseInt(ye), Integer.parseInt(mo), 1);
  dtToday.setHours(0); dtToday.setMinutes(0); dtToday.setSeconds(0);

  Date dtPrevMonth = Calendar.addMonths(-1, dtToday);
  Date dtNextMonth = Calendar.addMonths( 1, dtToday);

  final String sYeMo = "y="+String.valueOf(dtToday.getYear())+"&amp;m="+String.valueOf(dtToday.getMonth());

  Timestamp ts00 = new Timestamp(dtToday.getTime());
  Timestamp ts24 = new Timestamp(dtToday.getTime()+86400000l);

  StringBuffer oRecent = new StringBuffer();
  StringBuffer oMeetings = new StringBuffer();
  StringBuffer oToDo = new StringBuffer();

  PreparedStatement oStmt = null;
  ResultSet oRSet = null;
  MonthPlan oPlan = new MonthPlan();
  int nPlan = 0;
  
  try {

    oConn = GlobalDBBind.getConnection(PAGE_NAME);

    oStmt = oConn.prepareStatement("SELECT dt_last_visit,gu_contact,nm_company,full_name,work_phone,tx_email FROM "+DB.k_contacts_recent+" WHERE "+DB.gu_user+"=? ORDER BY "+DB.dt_last_visit+" DESC",
                                  ResultSet.TYPE_FORWARD_ONLY, ResultSet.CONCUR_READ_ONLY);
    oStmt.setString (1, oUser.getString(DB.gu_user));
    oRSet = oStmt.executeQuery();
	  for (int r=0; r<=4 && oRSet.next(); r++) {
		  oRecent.append("<br/><a href=\"contact_view.jsp?gu_contact="+oRSet.getString(2)+"\">"+oRSet.getString(3)+"</a>");		  
		}
		oRSet.close();
		oStmt.close();

    oStmt = oConn.prepareStatement("SELECT m." + DB.gu_meeting + ",m." + DB.gu_fellow + ",m." + DB.tp_meeting + ",m." + DB.tx_meeting + ", m." + DB.dt_start + ",m." + DB.dt_end + " FROM " +
                                  DB.k_meetings + " m," + DB.k_x_meeting_fellow + " f WHERE " +
                                  "m." + DB.gu_meeting + "=f." + DB.gu_meeting + " AND f." + DB.gu_fellow + "=? AND m." + DB.dt_start + " BETWEEN ? AND ? ORDER BY m." + DB.dt_start,
                                  ResultSet.TYPE_FORWARD_ONLY, ResultSet.CONCUR_READ_ONLY);
    oStmt.setString (1, oUser.getString(DB.gu_user));
    oStmt.setTimestamp (2, ts00);
    oStmt.setTimestamp (3, ts24);
    oRSet = oStmt.executeQuery();
    while (oRSet.next()) {
      oMeetings.append("<br/>&nbsp;<a href=\"meeting_edit.jsp?gu_meeting="+oRSet.getString(1)+"\">"+oFmtHour.format(oRSet.getTimestamp(5))+"&nbsp;-&nbsp;"+oFmtHour.format(oRSet.getTimestamp(6))+"</a>&nbsp;"+oRSet.getString(4));
    } // wend
		oRSet.close();
		oStmt.close();

    oStmt = oConn.prepareStatement("SELECT " + DB.gu_to_do + "," + DB.tl_to_do + "," + DB.od_priority + "," + DB.dt_end +
    	                             " FROM " + DB.k_to_do + " WHERE " + DB.tx_status + "='PENDING' AND " + DB.gu_workarea + "=? AND " + DB.gu_user + "=? ORDER BY 3");
    oStmt.setString (1, oUser.getString(DB.gu_workarea));
    oStmt.setString (2, oUser.getString(DB.gu_user));
    oRSet = oStmt.executeQuery();
    while (oRSet.next()) {
      oToDo.append("<br/>&nbsp;<a href=\"todo_edit.jsp?gu_to_do="+oRSet.getString(1)+"\">"+oRSet.getString(2)+"</a>");
      Date oDtEnd = oRSet.getDate(4);
      if (!oRSet.wasNull()) oToDo.append("&nbsp;"+oFmtDate.format(oDtEnd));
    } // wend
		oRSet.close();
		oStmt.close();
	
    oPlan.loadMeetingsForFellow(oConn, oUser.getInt(DB.id_domain), oUser.getString(DB.gu_workarea),
                                oUser.getString(DB.gu_user), dtToday.getYear(), dtToday.getMonth());

		oConn.close(PAGE_NAME);
		
  } catch (Exception xcpt) {
    if (null!=oRSet) oRSet.close();
    if (null!=oStmt) oStmt.close();
    if (oConn!=null)
      if (!oConn.isClosed()) oConn.close(PAGE_NAME);
    response.sendRedirect (response.encodeRedirectUrl ("errmsg.jsp?title="+xcpt.getClass().getName()+"&desc=" + xcpt.getMessage() + "&resume=home.jsp"));    
    return;
  }
%><?xml version="1.0"?>
<!DOCTYPE wml PUBLIC "-//WAPFORUM//DTD WML 1.1//EN"
"http://www.wapforum.org/DTD/wml_1.1.xml">
<wml>
  <head><meta http-equiv="cache-control" content="no-cache"/></head>
  <card id="home" title="<%=Labels.getString("title_main")%>">
    <br/>
    <fieldset title="<%=Labels.getString("lbl_contacts")%>">
      <input type="text" name="tx_find" />
      <br/>
      <anchor><%=Labels.getString("a_contact_search")%>
        <go href="contacts_list.jsp" accept-charset="UTF-8" method="get">
          <postfield name="find" value="$(tx_find)"/>
        </go>
      </anchor>
      <br/>
      <a href="contact_edit.jsp"><%=Labels.getString("a_contact_new")%></a>
      <br/><%
        if (oRecent.length()>0)
          out.write(Labels.getString("lbl_contacts_recent")+oRecent.toString());
    %></fieldset>
    <fieldset title="<%=Labels.getString("lbl_meetings")%>">
      <a href="meeting_edit.jsp"><%=Labels.getString("a_meeting_new")%></a>
      <% if (oMeetings.length()>0)
        out.write("<br/>"+Labels.getString("lbl_meetings_today")+oMeetings.toString());              
      %>
      <br/><a href="home.jsp?y=<%=String.valueOf(dtPrevMonth.getYear())%>&amp;m=<%=String.valueOf(dtPrevMonth.getMonth())%>"><%=Gadgets.left(Calendar.MonthName(dtPrevMonth.getMonth(), sLanguage),3)%></a>&nbsp;&nbsp;<%=Gadgets.left(Calendar.MonthName(dtToday.getMonth(), sLanguage),3)%>&nbsp;&nbsp;<a href="home.jsp?y=<%=String.valueOf(dtNextMonth.getYear())%>&amp;m=<%=String.valueOf(dtNextMonth.getMonth())%>"><%=Gadgets.left(Calendar.MonthName(dtNextMonth.getMonth(), sLanguage),3)%></a><br/>
      <table columns="7">
        <tr><%      	
          int FirstDay;
      	  if (sLanguage.equals("es")) {
      	    FirstDay = (new Date(dtToday.getYear(), dtToday.getMonth(), 0).getDay()+6)%7;
      	    for (int w=1;w<=7; w++) out.write("<td align=\"right\">"+((w%7)==3 ? 'x' : Calendar.WeekDayName((w%7)+1, "es").charAt(0))+"</td>");
          } else {
        	  FirstDay = new Date(dtToday.getYear(), dtToday.getMonth(), 0).getDay();
      	    for (int w=1;w<=7; w++) out.write("<td align=\"right\">"+Calendar.WeekDayName(w, sLanguage).charAt(0)+"</td>");        
          } %>
        </tr><%

        int CurrentDay = 1;

        for (int row=0; row<=5; row++) {
          out.write ("      <tr>\n");
          for (int col=0; col<=6; col++) {
            if (0==row && col<=FirstDay)
              out.write ("        <td align=\"right\">-</td>");
            else if (CurrentDay > Calendar.LastDay(dtToday.getMonth(), dtToday.getYear()+1900))
              out.write ("        <td align=\"right\">-</td>");
            else if (oPlan.hasAnyMeeting(CurrentDay))
              out.write ("      <td align=\"right\"><a href=\"meetings_day.jsp?"+sYeMo+"&amp;d="+String.valueOf(CurrentDay)+"\">" + String.valueOf(CurrentDay++) + "</a></td>\n");
            else
              out.write ("      <td align=\"right\">" + String.valueOf(CurrentDay++) + "</td>\n");
            	
          } // next (col)            
          out.write ("	    </tr>\n");
        } // next (row) %>      
      </table>
    </fieldset>
    <fieldset title="<%=Labels.getString("lbl_todos")%>">
      <a href="todo_edit.jsp"><%=Labels.getString("a_todo_new")%></a>
<%
        if (oToDo.length()>0)
          out.write(oToDo.toString());
%></fieldset>
<% if (ApplicationModule.PASSWORD_MANAGER.available(oUser.getInt("appmask"))) { %>
    <fieldset title="<%=Labels.getString("lbl_passw")%>">
      <a href="passwords.jsp"><%=Labels.getString("a_passwords")%></a>
    </fieldset>
<% } %>
    <p><a href="logout.jsp"><%=Labels.getString("a_close_session")%></a></p>
  </card>
</wml>

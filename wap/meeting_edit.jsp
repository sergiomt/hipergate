<%@ page import="java.util.Date,java.sql.Connection,com.knowgate.dataobjs.DB,com.knowgate.dataobjs.DBSubset,com.knowgate.addrbook.Meeting,com.knowgate.misc.Gadgets,com.knowgate.hipergate.DBLanguages" language="java" session="true" contentType="text/vnd.wap.wml;charset=UTF-8" %><jsp:useBean id="GlobalCacheClient" scope="application" class="com.knowgate.cache.DistributedCachePeer"/><jsp:useBean id="GlobalDBLang" scope="application" class="com.knowgate.hipergate.DBLanguages"/><%@ include file="inc/dbbind.jsp" %><%
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

  final String PAGE_NAME = "meeting_edit";

  final String gu_meeting = request.getParameter("gu_meeting");
  final String ye = request.getParameter("y");
  final String mo = request.getParameter("m");

  Date dtStart;
  if (ye==null || mo==null)
    dtStart = new Date();
  else
    dtStart = new Date(Integer.parseInt(ye), Integer.parseInt(mo), 1);
  Date dtEnd = new Date(dtStart.getTime()+3600000l);

  Meeting oMeet = new Meeting();
  boolean bAlreadyExists = false;

  DBSubset oRooms = GlobalCacheClient.getDBSubset("k_rooms.nm_room[" + oUser.getString(DB.gu_workarea) + "]");
  int iRooms = 0;

  try {

    oConn = GlobalDBBind.getConnection(PAGE_NAME);

		if (null!=gu_meeting) {
		  bAlreadyExists = oMeet.load(oConn, gu_meeting);
	    if (bAlreadyExists) {
	      dtStart = oMeet.getDate(DB.dt_start);
	      dtEnd = oMeet.getDate(DB.dt_end);
	    }
	  }
    if (null==oRooms) {
      oRooms = new DBSubset (DB.k_rooms,
       			                 DB.nm_room + "," + DB.tx_company + "," + DB.tx_location + "," + DB.tp_room + "," + DB.tx_comments,
      			                 DB.bo_available + "=1 AND " + DB.gu_workarea + "=? ORDER BY 4,1", 50);
      
      iRooms = oRooms.load (oConn, new Object[]{oUser.getString(DB.gu_workarea)});
            
      GlobalCacheClient.putDBSubset("k_rooms", "k_rooms.nm_room[" + oUser.getString(DB.gu_workarea) + "]", oRooms);           
    } // fi(oRooms)
    else {
      iRooms = oRooms.getRowCount();
    }

		oConn.close(PAGE_NAME);
    
  } catch (Exception xcpt) {
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
  <card id="meeting_edit">
    <%=Labels.getString("lbl_meeting_edit")%>
    <table columns="2">
    <tr><td><%=Labels.getString("lbl_start")%></td><td></td></tr><tr><td>
    <select name="sel_ystart" title="<%=Labels.getString("lbl_year")%>" value="<%=String.valueOf(dtStart.getYear())%>">
<%  for (int y=dtStart.getYear(); y<dtStart.getYear()+4; y++)
      out.write("<option value=\""+String.valueOf(y+1900)+"\">"+String.valueOf(y+1900)+"</option>"); %>
    </select>
    </td><td>
    <select name="sel_mstart" title="<%=Labels.getString("lbl_month")%>" value="<%=String.valueOf(dtStart.getMonth()+1)%>">
<%  for (int m=1; m<=12; m++)
      out.write("<option value=\""+String.valueOf(m)+"\">"+Gadgets.leftPad(String.valueOf(m),'0',2)+"</option>"); %>
    </select>
    <select name="sel_dstart" title="<%=Labels.getString("lbl_day")%>" ivalue="<%=String.valueOf(dtStart.getDate())%>">
<%  for (int d=1; d<=31; d++)
      out.write("<option value=\""+String.valueOf(d)+"\">"+Gadgets.leftPad(String.valueOf(d),'0',2)+"</option>"); %>
    </select>
    </td></tr><tr><td align="right"><%=Labels.getString("lbl_hour")%></td><td>
    <select name="sel_hstart" title="<%=Labels.getString("lbl_hour")%>" value="<%=String.valueOf(dtStart.getHours())%>">
<%  for (int h=0; h<24; h++)
      out.write("<option value=\""+String.valueOf(h)+"\">"+Gadgets.leftPad(String.valueOf(h),'0',2)+"</option>"); %>
    </select>
    <select name="sel_istart" title="<%=Labels.getString("lbl_minute")%>" value="<%=String.valueOf(dtStart.getMinutes())%>">
<%  for (int i=0; i<60; i+=5)
      out.write("<option value=\""+String.valueOf(i)+"\">"+Gadgets.leftPad(String.valueOf(i),'0',2)+"</option>"); %>
    </select>
    </td></tr>
    <tr><td><%=Labels.getString("lbl_end")%></td><td></td></tr><tr><td>
    <select name="sel_yend" title="<%=Labels.getString("lbl_year")%>" value="<%=String.valueOf(dtEnd.getYear())%>">
<%  for (int y=dtEnd.getYear(); y<dtEnd.getYear()+4; y++)
      out.write("<option value=\""+String.valueOf(y+1900)+"\">"+String.valueOf(y+1900)+"</option>"); %>
    </select>
    </td><td>
    <select name="sel_mend" title="<%=Labels.getString("lbl_month")%>" value="<%=String.valueOf(dtEnd.getMonth()+1)%>">
<%  for (int m=1; m<=12; m++)
      out.write("<option value=\""+String.valueOf(m)+"\">"+Gadgets.leftPad(String.valueOf(m),'0',2)+"</option>"); %>
    </select>
    <select name="sel_dend" title="<%=Labels.getString("lbl_day")%>" ivalue="<%=String.valueOf(dtEnd.getDate())%>">
<%  for (int d=1; d<=31; d++)
      out.write("<option value=\""+String.valueOf(d)+"\">"+Gadgets.leftPad(String.valueOf(d),'0',2)+"</option>"); %>
    </select>
    </td></tr><tr><td align="right"><%=Labels.getString("lbl_hour")%></td><td>
    <select name="sel_hend" title="<%=Labels.getString("lbl_hour")%>" value="<%=String.valueOf(dtEnd.getHours())%>">
<%  for (int h=0; h<24; h++)
      out.write("<option value=\""+String.valueOf(h)+"\">"+Gadgets.leftPad(String.valueOf(h),'0',2)+"</option>"); %>
    </select>
    <select name="sel_iend" title="<%=Labels.getString("lbl_minute")%>" value="<%=String.valueOf(dtEnd.getMinutes())%>">
<%  for (int i=0; i<60; i+=5)
      out.write("<option value=\""+String.valueOf(i)+"\">"+Gadgets.leftPad(String.valueOf(i),'0',2)+"</option>"); %>
    </select>
    </td></tr></table>

    <%=Labels.getString("lbl_subject")%>&nbsp;<select name="sel_tp_meeting" value="<%=oMeet.getStringNull(DB.tp_meeting,"")%>"><option value=""></option><option value="meeting"><%=Labels.getString("opt_meeting")%></option><option value="call"><%=Labels.getString("opt_call")%></option><option value="followup"><%=Labels.getString("opt_followup")%></option><option value="breakfast"><%=Labels.getString("opt_breakfast")%></option><option value="lunch"><%=Labels.getString("opt_lunch")%></option><option value="course"><%=Labels.getString("opt_course")%></option><option value="demo"><%=Labels.getString("opt_demo")%></option><option value="workshop"><%=Labels.getString("opt_workshop")%></option><option value="congress"><%=Labels.getString("opt_congress")%></option><option value="tradeshow"><%=Labels.getString("opt_tradeshow")%></option><option value="bill"><%=Labels.getString("opt_bill")%></option><option value="pay"><%=Labels.getString("opt_pay")%></option><option value="holidays"><%=Labels.getString("opt_holidays")%></option></select><br/>
    <input type="text" name="tmeeting" size="26" value="<%=oMeet.getStringNull(DB.tx_meeting,"")%>" /><br/>
    <%=Labels.getString("lbl_resource")%><br/>
    <select name="sel_room" value="<%=oMeet.getStringNull(DB.nm_room,"")%>"><option value=""></option>
<%	for (int r=0; r<iRooms; r++) {
		  out.write("<option value=\"" + oRooms.getString(0,r) + "\">");
		  if (!oRooms.isNull(DB.tp_room,r))
		    out.write(DBLanguages.getLookUpTranslation((Connection) oConn, DB.k_rooms_lookup, oUser.getString(DB.gu_workarea), "tp_room", sLanguage, oRooms.getString(DB.tp_room,r)) + " ");
		    out.write(oRooms.getString(0,r) + "</option>");
	  } // next
%>
    </select>

	  <table columns="2" align="LR" width="100%">
	    <tr>
	    	<td>
          <anchor><%=Labels.getString("a_save")%>
            <go href="meeting_store.jsp" accept-charset="UTF-8" method="post">
              <postfield name="gu_meeting" value="<%=oMeet.getStringNull(DB.gu_meeting,"")%>"/>
              <postfield name="ystart" value="$(sel_ystart)"/>
              <postfield name="mstart" value="$(sel_mstart)"/>
              <postfield name="dstart" value="$(sel_dstart)"/>
              <postfield name="hstart" value="$(sel_hstart)"/>
              <postfield name="istart" value="$(sel_istart)"/>
              <postfield name="yend" value="$(sel_yend)"/>
              <postfield name="mend" value="$(sel_mend)"/>
              <postfield name="dend" value="$(sel_dend)"/>
              <postfield name="hend" value="$(sel_hend)"/>
              <postfield name="iend" value="$(sel_iend)"/>
              <postfield name="tp_meeting" value="$(sel_tp_meeting)"/>
              <postfield name="tx_meeting" value="$(tmeeting)"/>
              <postfield name="nm_room" value="$(sel_room)"/>
            </go>
          </anchor>
        </td>
        <td>
        	<% if (gu_meeting!=null) { %><a href="meeting_delete.jsp?gu_meeting=<%=gu_meeting%>"><%=Labels.getString("a_delete")%></a><% } %>
        </td>
      </tr>
    </table>

    <p><a href="home.jsp"><%=Labels.getString("a_home")%></a> <do type="accept" label="<%=Labels.getString("a_back")%>"><prev/></do> <a href="logout.jsp"><%=Labels.getString("a_close_session")%></a></p>
  </card>
</wml>

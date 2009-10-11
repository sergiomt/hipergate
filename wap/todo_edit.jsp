<%@ page import="java.util.Date,java.sql.Connection,com.knowgate.dataobjs.DB,com.knowgate.dataobjs.DBSubset,com.knowgate.addrbook.ToDo,com.knowgate.misc.Gadgets,com.knowgate.hipergate.DBLanguages" language="java" session="true" contentType="text/vnd.wap.wml;charset=UTF-8" %><jsp:useBean id="GlobalCacheClient" scope="application" class="com.knowgate.cache.DistributedCachePeer"/><jsp:useBean id="GlobalDBLang" scope="application" class="com.knowgate.hipergate.DBLanguages"/><%@ include file="inc/dbbind.jsp" %><%
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

  final String PAGE_NAME = "todo_edit";

  final String gu_to_do = request.getParameter("gu_to_do");

  ToDo oTodo = new ToDo();
  boolean bAlreadyExists = false;

  try {

    oConn = GlobalDBBind.getConnection(PAGE_NAME);

		if (null!=gu_to_do) {
		  bAlreadyExists = oTodo.load(oConn, gu_to_do);
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
  <card id="todo_edit">
    <%=Labels.getString("lbl_todo_edit")%>
    
    <select name="sel_to_do" value="<%=oTodo.getStringNull(DB.tp_to_do,"")%>"><option value=""></option><option value="LUNCH"><%=Labels.getString("opt_lunch")%></option><option value="ANSWER"><%=Labels.getString("opt_answer")%></option><option value="BREAKFAST"><%=Labels.getString("opt_breakfast")%></option><option value="SENDDOC"><%=Labels.getString("opt_senddoc")%></option><option value="INVOICE"><%=Labels.getString("opt_bill")%></option><option value="REPORT"><%=Labels.getString("opt_report")%></option><option value="COURSE"><%=Labels.getString("opt_course")%></option><option value="DEMO"><%=Labels.getString("opt_demo")%></option><option value="MEETING"><%=Labels.getString("opt_meeting")%></option><option value="REVISE"><%=Labels.getString("opt_review")%></option></select>&nbsp;
    <br/>
    <input type="text" size="26" name="ttodo" value="<%=oTodo.getStringNull(DB.tl_to_do,"")%>"/>
    <br/>
    <%=Labels.getString("lbl_priority")%>&nbsp;<select name="sel_priority" value="<% if (oTodo.isNull(DB.od_priority)) out.write("3"); else out.write(String.valueOf(oTodo.getShort(DB.od_priority))); %>"><option value="1"><%=Labels.getString("opt_maximum")%></option><option value="2"><%=Labels.getString("opt_veryhigh")%></option><option value="3"><%=Labels.getString("opt_high")%></option><option value="4"><%=Labels.getString("opt_medium")%></option><option value="5"><%=Labels.getString("opt_low")%></option><option value="6"><%=Labels.getString("opt_verylow")%></option></select>
    <br/>
    <%=Labels.getString("lbl_status")%>&nbsp;<select name="sel_status" value="<%=oTodo.getStringNull(DB.tx_status,"PENDING")%>"><option value="PENDING"><%=Labels.getString("opt_pending")%></option><option value="DONE"><%=Labels.getString("opt_done")%></option></select>
    <br/>
  <select name="sel_yend" title="<%=Labels.getString("lbl_year")%>" <% if (!oTodo.isNull(DB.dt_end)) out.write("value=\""+String.valueOf(oTodo.getDate(DB.dt_end).getYear()+1900)+"\""); %>>
<%  for (int y=2009; y<2020; y++)
      out.write("<option value=\"\"></option><option value=\""+String.valueOf(y)+"\">"+String.valueOf(y)+"</option>"); %>
    </select>
    <select name="sel_mend" title="<%=Labels.getString("lbl_month")%>" <% if (!oTodo.isNull(DB.dt_end)) out.write("value=\""+String.valueOf(oTodo.getDate(DB.dt_end).getMonth()+1)+"\""); %>>
<%  for (int m=1; m<=12; m++)
      out.write("<option value=\"\"></option><option value=\""+String.valueOf(m)+"\">"+Gadgets.leftPad(String.valueOf(m),'0',2)+"</option>"); %>
    </select>
    <select name="sel_dend" title="<%=Labels.getString("lbl_day")%>" <% if (!oTodo.isNull(DB.dt_end)) out.write("ivalue=\""+String.valueOf(oTodo.getDate(DB.dt_end).getDate())+"\""); %>>
<%  for (int d=1; d<31; d++)
      out.write("<option value=\"\"></option><option value=\""+String.valueOf(d)+"\">"+Gadgets.leftPad(String.valueOf(d),'0',2)+"</option>"); %>
    </select>

	  <table columns="2" align="LR" width="100%">
	    <tr>
	    	<td>
          <anchor><%=Labels.getString("a_save")%>
            <go href="todo_store.jsp" accept-charset="UTF-8" method="post">
              <postfield name="gu_to_do" value="<%=oTodo.getStringNull(DB.gu_to_do,"")%>"/>
              <postfield name="yend" value="$(sel_yend)"/>
              <postfield name="mend" value="$(sel_mend)"/>
              <postfield name="dend" value="$(sel_dend)"/>
              <postfield name="hend" value="$(sel_hend)"/>
              <postfield name="iend" value="$(sel_iend)"/>
              <postfield name="tl_to_do" value="$(ttodo)"/>
              <postfield name="tp_to_do" value="$(sel_to_do)"/>
              <postfield name="od_priority" value="$(sel_priority)"/>
              <postfield name="tx_status" value="$(sel_status)"/>
            </go>
          </anchor>
        </td>
        <td>
        	<% if (gu_to_do!=null) { %><a href="todo_delete.jsp?gu_to_do=<%=gu_to_do%>"><%=Labels.getString("a_delete")%></a><% } %>
        </td>
      </tr>
    </table>

    <p><a href="home.jsp"><%=Labels.getString("a_home")%></a> <do type="accept" label="<%=Labels.getString("a_back")%>"><prev/></do> <a href="logout.jsp"><%=Labels.getString("a_close_session")%></a></p>
  </card>
</wml>

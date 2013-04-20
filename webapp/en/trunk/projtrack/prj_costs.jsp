<%@ page import="java.util.Date,java.util.HashMap,java.io.IOException,java.net.URLDecoder,java.text.DecimalFormat,java.text.SimpleDateFormat,java.sql.PreparedStatement,java.sql.ResultSet,java.sql.SQLException,com.knowgate.jdc.JDCConnection,com.knowgate.dataobjs.*,com.knowgate.acl.*,com.knowgate.misc.Gadgets,com.knowgate.hipergate.DBLanguages,com.knowgate.projtrack.Project" language="java" session="false" contentType="text/html;charset=UTF-8" %>
<%@ include file="../methods/dbbind.jsp" %><%@ include file="../methods/cookies.jspf" %><%@ include file="../methods/authusrs.jspf" %><%@ include file="../methods/nullif.jspf" %>
<jsp:useBean id="GlobalDBLang" scope="application" class="com.knowgate.hipergate.DBLanguages"/><%!
  public Date bestDate(Date dt1, Date dt2, Date dt3) {
    if (null==dt1)
      if (null==dt2)
        return dt3;
      else
        return dt2;
    else
      return dt1;
  }
%><%   
  if (autenticateSession(GlobalDBBind, request, response)<0) return;
  
  JDCConnection oConn = null;
  PreparedStatement oDuties = null;
  PreparedStatement oCosts = null;
  ResultSet oRSet = null;
  Project oProj = new Project();
  DBSubset oProjChlds = null;
  HashMap oTypes;
  String sPrj;
  String sTpCost;
  String sStrip;
  int iStrip = 1;
  int iPrjChlds = 0;
  int iLevel = 1;
  int iDivNest = 0;
  float fCost, fSubTotal, fGrandTotal = 0f;
  Date oDate;
  DecimalFormat Fmt = new DecimalFormat("#0.00");
  SimpleDateFormat Sdt =  new SimpleDateFormat("yyyy-MM-dd");
  SimpleDateFormat Ndt =  new SimpleDateFormat("yyyyMMdd");
  
  String sLanguage = getNavigatorLanguage(request);
  String gu_project = request.getParameter("gu_project");
  String dt_from = request.getParameter("dt_from");
  String dt_to = request.getParameter("dt_to");
  int iDate, iFrom, iTo;
  
  if (null!=dt_from) {
    iFrom = Integer.parseInt(Gadgets.removeChar(dt_from.trim(),'-'));
  } else {
    iFrom = 0;
  }
  if (null!=dt_to) {
    iTo = Integer.parseInt(Gadgets.removeChar(dt_to.trim(),'-'));
  } else {
    iTo = 99991231;
  }
%>
<HTML>
<HEAD>
  <TITLE>hipergate :: Edit project costs</TITLE>
  <SCRIPT SRC="../javascript/cookies.js"></SCRIPT>  
  <SCRIPT SRC="../javascript/setskin.js"></SCRIPT>
  <SCRIPT SRC="../javascript/setskin.js"></SCRIPT>
  <SCRIPT SRC="../javascript/datefuncs.js"></SCRIPT>
  <SCRIPT TYPE="text/javascript">
    <!--

      function showCalendar(ctrl) {       
        var dtnw = new Date();
        window.open("../common/calendar.jsp?a=" + (dtnw.getFullYear()) + "&m=" + dtnw.getMonth() + "&c=" + ctrl, "", "toolbar=no,directories=no,menubar=no,resizable=no,width=171,height=195");
      } // showCalendar()

      // ------------------------------------------------------

      function toggle(id) {
        var div = document.getElementById("d"+id);
        var img = document.getElementById("i"+id);
        if ("block"==div.style.display) {
          img.src = "../images/images/projtrack/expandprj.gif";
          div.style.display = "none"; 
        } else {
          img.src = "../images/images/projtrack/collapseprj.gif";
          div.style.display = "block";
        }
      }

      // ------------------------------------------------------

      function editCost(prj,gu) {
        window.open('cost_edit.jsp?gu_project='+prj+"&gu_cost="+gu, 'costedit', 'menubar=no,toolbar=no,width=520,height=360');
      }

      // ------------------------------------------------------

      function createCost(prj) {
        window.open('cost_edit.jsp?gu_project='+prj, 'costedit', 'menubar=no,toolbar=no,width=520,height=360');
      }

      // ------------------------------------------------------

      function createDuty(prj) {
        window.open('duty_new.jsp?gu_project='+prj, 'newduty', 'menubar=no,toolbar=no,width=780,height=' + (screen.height<=600 ? '520' : '640'));
      }

      // ------------------------------------------------------

      function editDuty(guDuty) {
        window.open("duty_edit.jsp?gu_duty=" + guDuty, "editduty", "width=780,height=" + (screen.height<=600 ? "520" : "640"));
      }

      // ------------------------------------------------------

      function filterByDate() {
        var frm = document.forms[0];
        if (!isDate(frm.dt_from.value,"d") && frm.dt_from.value.length>0) {
          alert ("Invalid Start Date");
	  return;
        }
        if (!isDate(frm.dt_to.value,"d") && frm.dt_to.value.length>0) {
          alert ("Invalid End Date");
	  return;
        }
        document.location.href = "prj_costs.jsp?gu_project=<%=gu_project%>" + (frm.dt_from.value.length>0 ? "&dt_from="+frm.dt_from.value : "") + (frm.dt_to.value.length>0 ? "&dt_to="+frm.dt_to.value : "");
      } // filterByDate  

      // ------------------------------------------------------

      function deleteSelected() {
        var frm0 = document.forms[0];
        var frm1 = document.forms[1];
        var len = frm0.elements.length;
        var sub;
        
        if (window.confirm("Are you sure that you want to delete selected duties and costs?")) {
          frm1.duties.value = "";
          frm1.costs.value = "";        
          for (var e=0; e<len; e++) {
            sub = frm0.elements[e].name.substr(0,4);
            if (sub=="chk_") {
              if (frm0.elements[e].name.substr(4,5)=="duty_") {
                if (frm0.elements[e].checked)
                  frm1.duties.value += (frm1.duties.value.length==0 ? "" : ",") + frm0.elements[e].name.substring(9);
              } else if (frm0.elements[e].name.substr(4,5)=="cost_") {
                if (frm0.elements[e].checked)
                  frm1.costs.value += (frm1.costs.value.length==0 ? "" : ",") + frm0.elements[e].name.substring(9);
              }
            } // fi
          } // next
          if (frm1.duties.value.length>0 || frm1.costs.value.length>0) {
            if (!isDate(frm0.dt_from.value,"d") && frm0.dt_from.value.length>0)
              frm1.dt_from.value = frm0.dt_from.value;
            else
              frm1.dt_from.value = "";
            if (!isDate(frm0.dt_to.value,"d") && frm0.dt_to.value.length>0)
              frm1.dt_to.value = frm0.dt_to.value;
            else
              frm1.dt_to.value = "";
            frm1.submit();
          }
        }        
      } // deleteSelected
      
      // ------------------------------------------------------

      function validate() {
        var frm = document.forms[0];
        var len = frm.elements.length;
        var sub;
        if (!isDate(frm.dt_from.value,"d") && frm.dt_from.value.length>0) {
          alert ("Invalid Start Date");
	  return false;
        }
        if (!isDate(frm.dt_to.value,"d") && frm.dt_to.value.length>0) {
          alert ("Invalid End Date");
	  return false;
        }
        for (var e=0; e<len; e++) {
          sub = frm.elements[e].name.substr(0,5);
          if (sub=="duty_" || sub=="cost_") {
            if (frm.elements[e].value.length==0) frm.elements[e].value = "0";
            if (isNaN(Number(frm.elements[e].value))) {
              alert ("Cost is not valid");
              frm.elements[e].focus();
              return false;
            } // fi
          } // fi
        } // next 
      } // validate

      // ------------------------------------------------------
      
    //-->
  </SCRIPT>
</HEAD>
<BODY >
<FORM ACTION="prj_costs_store.jsp" onclick="return validate()">
  <INPUT TYPE="hidden" NAME="gu_project" VALUE="<%=gu_project%>">
<%  
  try {
    oConn = GlobalDBBind.getConnection("prj_costs");
    oProj.load(oConn, new Object[]{gu_project}); %>
  <TABLE WIDTH="100%">
    <TR><TD><IMG SRC="../images/images/spacer.gif" HEIGHT="4" WIDTH="1" BORDER="0"></TD></TR>
    <TR><TD CLASS="striptitle"><FONT CLASS="title1">Edit Project Costs&nbsp;<%=oProj.getString(DB.nm_project)%></FONT></TD></TR>
  </TABLE>
  <TABLE CELLSPACING="0" CELLPADDING="2">      
    <TR><TD COLSPAN="7" BACKGROUND="../images/images/loginfoot_med.gif" HEIGHT="3"></TD></TR>
    <TR>
      <TD COLSPAN="2" CLASS="textplain">Filter between</TD>
      <TD><INPUT TYPE="text" NAME="dt_from" MAXLENGTH="10" SIZE="12" CLASS="combomini" VALUE="<%=nullif(dt_from)%>"></TD>
      <TD><A HREF="javascript:showCalendar('dt_from')"><IMG SRC="../images/images/datetime16.gif" WIDTH="16" HEIGHT="16" BORDER="0" ALT="Start date"></A></TD>
      <TD CLASS="textplain">and</TD>
      <TD><INPUT TYPE="text" NAME="dt_to" MAXLENGTH="10" SIZE="12" CLASS="combomini" VALUE="<%=nullif(dt_to)%>"></TD>
      <TD><A HREF="javascript:showCalendar('dt_to')"><IMG SRC="../images/images/datetime16.gif" WIDTH="16" HEIGHT="16" BORDER="0" ALT="End date"></A></TD>
    </TR>
    <TR>
      <TD><IMG SRC="../images/images/search16x16.gif" BORDER="0"></TD>
      <TD><A HREF="javascript:filterByDate()" CLASS="linkplain">Filter</A></TD>
      <TD COLSPAN="5"><IMG SRC="../images/images/undosearch16x16.gif" BORDER="0">&nbsp;<A HREF="prj_costs.jsp?gu_project=<%=gu_project%>" CLASS="linkplain">Discard Filter</A></TD>
    </TR>
    <TR>
      <TD><IMG SRC="../images/images/delete.gif" WIDTH="13" HEIGHT="13" BORDER="0"></TD>
      <TD COLSPAN="4"><A HREF="javascript:deleteSelected()" CLASS="linkplain">Delete selected costs</A></TD>
      <TD COLSPAN="2" ALIGN="right"><INPUT TYPE="submit" CLASS="minibutton" VALUE="Save" ACCESSKEY="s" TITLE="Alt+s"></TD>
    </TR>
    <TR><TD COLSPAN="7" BACKGROUND="../images/images/loginfoot_med.gif" HEIGHT="3"></TD></TR>
  </TABLE>
<%
    oTypes = GlobalDBLang.getLookUpMap((java.sql.Connection) oConn, DB.k_projects_lookup, oProj.getString(DB.gu_owner), DB.tp_cost, sLanguage);
    
    oProjChlds = oProj.getAllChilds(oConn);    			
    iPrjChlds = oProjChlds.getRowCount();       

    oDuties = oConn.prepareStatement("SELECT "+DB.gu_duty+","+DB.nm_duty+","+DB.pr_cost+","+DB.dt_end+","+DB.dt_start+","+DB.dt_created+" FROM "+DB.k_duties+" WHERE gu_project=?", ResultSet.TYPE_FORWARD_ONLY, ResultSet.CONCUR_READ_ONLY);
    oCosts = oConn.prepareStatement("SELECT "+DB.gu_cost+","+DB.tp_cost+","+DB.tl_cost+","+DB.pr_cost+","+DB.dt_cost+","+DB.dt_modified+","+DB.dt_created+" FROM "+DB.k_project_costs+" WHERE gu_project=? ORDER BY 2 DESC", ResultSet.TYPE_FORWARD_ONLY, ResultSet.CONCUR_READ_ONLY);

    for (int p=0;p<iPrjChlds; p++) {
      fSubTotal = 0f;
      sTpCost = "no previous cost";
      sPrj = oProjChlds.getString(0,p);
      iLevel = oProjChlds.getInt(2,p); 
      while (iLevel<=iDivNest) {
        out.write("  </DIV>\n");
        iDivNest--;
      }
      out.write("  <TABLE BORDER=0><TR><TD><IMG SRC=../images/images/spacer.gif BORDER=0 HEIGHT=1 WIDTH="+String.valueOf(10*(iLevel-1))+"><IMG ID=i"+sPrj+" SRC=../images/images/projtrack/collapseprj.gif WIDTH=11 HEIGHT=11 BORDER=0 onclick=\"toggle('"+sPrj+"')\"></TD><TD CLASS=textbigstrong>"+oProjChlds.getString(1,p)+"</TD></TR></TABLE>\n");
      out.write("  <DIV ID=\"d"+sPrj+"\" STYLE=\"display:block\">\n");
      oDuties.setString(1, sPrj);
      oRSet = oDuties.executeQuery();
      out.write("    <TABLE BORDER=\"0\">\n");
      out.write("      <TR><TD><IMG SRC=../images/images/spacer.gif BORDER=0 HEIGHT=1 WIDTH="+String.valueOf(10*(iLevel-1)+16)+"></TD><TD><FONT CLASS=\"textplain\"><B>Duties</B></FONT></TD><TD><FONT CLASS=\"textplain\"><B>Date</B></FONT></TD><TD><FONT CLASS=\"textplain\"><B>Cost</B></FONT></TD><TD></TD><TD></TD></TR>\n");
      
      while (oRSet.next()) {
        sStrip = String.valueOf((iStrip%2)+1);
        oDate = bestDate(oRSet.getDate(4),oRSet.getDate(5),oRSet.getDate(6));
        iDate = Integer.parseInt(Ndt.format(oDate));
        if (iDate>=iFrom && iDate<=iTo) {
          fCost = oRSet.getFloat(3);
          if (oRSet.wasNull()) {
            out.write("      <TR><TD><IMG SRC=../images/images/spacer.gif BORDER=0 HEIGHT=1 WIDTH="+String.valueOf(10*(iLevel-1)+16)+"></TD><TD CLASS=\"strip"+sStrip+"\"><FONT CLASS=\"textplain\">"+oRSet.getString(2)+"</FONT></TD><TD CLASS=\"strip"+sStrip+"\">"+Sdt.format(oDate)+"</TD><TD CLASS=\"strip"+sStrip+"\"><INPUT CLASS=\"combomini\" TYPE=\"text\" SIZE=\"8\" NAME=\"duty_cost_"+oRSet.getString(1)+"\" VALUE=\"0\"></TD><TD CLASS=\"strip"+sStrip+"\"><A CLASS=\"linksmall\" HREF=\"#\" onclick=\"editDuty('"+oRSet.getString(1)+"')\">Edit</A></TD><TD><INPUT TYPE=\"checkbox\" NAME=\"chk_duty_"+oRSet.getString(1)+"\"></TD></TR>\n");
          } else {
            out.write("      <TR><TD><IMG SRC=../images/images/spacer.gif BORDER=0 HEIGHT=1 WIDTH="+String.valueOf(10*(iLevel-1)+16)+"></TD><TD CLASS=\"strip"+sStrip+"\"><FONT CLASS=\"textplain\">"+oRSet.getString(2)+"</FONT></TD><TD CLASS=\"strip"+sStrip+"\">"+Sdt.format(oDate)+"</TD><TD CLASS=\"strip"+sStrip+"\"><INPUT CLASS=\"combomini\" TYPE=\"text\" SIZE=\"8\" NAME=\"duty_cost_"+oRSet.getString(1)+"\" VALUE=\""+Fmt.format(fCost)+"\"></TD><TD CLASS=\"strip"+sStrip+"\"><A CLASS=\"linksmall\" HREF=\"#\" onclick=\"editDuty('"+oRSet.getString(1)+"')\">Edit</A></TD><TD><INPUT TYPE=\"checkbox\" NAME=\"chk_duty_"+oRSet.getString(1)+"\"><TD></TD></TR>\n");
            fSubTotal += fCost;
          }
          iStrip++;
        } // fi (iDate between iFrom and iTo)
      } // wend
      oRSet.close();
      out.write("      <TR><TD><IMG SRC=../images/images/spacer.gif BORDER=0 HEIGHT=1 WIDTH="+String.valueOf(10*(iLevel-1)+16)+"></TD><TD><A HREF=\"#\" CLASS=\"linkplain\" onclick=\"createDuty('"+sPrj+"')\">New Task</A></TD><TD></TD></TD><TD></TD></TR>\n");

      oCosts.setString(1, sPrj);
      oRSet = oCosts.executeQuery();
      while (oRSet.next()) {
        if (!sTpCost.equals(oRSet.getString(2))) {
          if (oRSet.wasNull())
            out.write("      <TR><TD><IMG SRC=../images/images/spacer.gif BORDER=0 HEIGHT=1 WIDTH="+String.valueOf(10*(iLevel-1)+16)+"></TD><TD><FONT CLASS=\"textplain\"><B>Other Costs</B></FONT></TD><TD><FONT CLASS=\"textplain\"><B></B></FONT></TD><TD></TD><TD></TD></TR>\n");
	  else
            out.write("      <TR><TD><IMG SRC=../images/images/spacer.gif BORDER=0 HEIGHT=1 WIDTH="+String.valueOf(10*(iLevel-1)+16)+"></TD><TD><FONT CLASS=\"textplain\"><B>"+oTypes.get(oRSet.getString(2))+"</B></FONT></TD><TD><FONT CLASS=\"textplain\"><B>Date</B></FONT></TD><TD><FONT CLASS=\"textplain\"><B>Cost</B></FONT></TD><TD></TD><TD></TD></TR>\n");	            
        }
        sStrip = String.valueOf((iStrip%2)+1);
        oDate = bestDate(oRSet.getDate(5),oRSet.getDate(6),oRSet.getDate(7));
        iDate = Integer.parseInt(Ndt.format(oDate));
        if (iDate>=iFrom && iDate<=iTo) {
          fCost = oRSet.getFloat(4);
          if (oRSet.wasNull()) {
            out.write("      <TR><TD><IMG SRC=../images/images/spacer.gif BORDER=0 HEIGHT=1 WIDTH="+String.valueOf(10*(iLevel-1)+16)+"></TD><TD CLASS=\"strip"+sStrip+"\"><FONT CLASS=\"textplain\">"+oRSet.getString(3)+"</FONT></TD><TD CLASS=\"strip"+sStrip+"\">"+Sdt.format(oDate)+"</TD><TD CLASS=\"strip"+sStrip+"\"><INPUT CLASS=\"combomini\" TYPE=\"text\" SIZE=\"8\" NAME=\"cost_cost_"+oRSet.getString(1)+"\" VALUE=\"0\"></TD><TD CLASS=\"strip"+sStrip+"\"><A CLASS=\"linksmall\" HREF=\"#\" onclick=\"editCost('"+sPrj+"','"+oRSet.getString(1)+"')\">Edit</A></TD><TD><INPUT TYPE=\"checkbox\" NAME=\"chk_cost_"+oRSet.getString(1)+"\"></TD></TR>\n");
          } else {
            out.write("      <TR><TD><IMG SRC=../images/images/spacer.gif BORDER=0 HEIGHT=1 WIDTH="+String.valueOf(10*(iLevel-1)+16)+"></TD><TD CLASS=\"strip"+sStrip+"\"><FONT CLASS=\"textplain\">"+oRSet.getString(3)+"</FONT></TD><TD CLASS=\"strip"+sStrip+"\">"+Sdt.format(oDate)+"</TD><TD CLASS=\"strip"+sStrip+"\"><INPUT CLASS=\"combomini\" TYPE=\"text\" SIZE=\"8\" NAME=\"cost_cost_"+oRSet.getString(1)+"\" VALUE=\""+Fmt.format(oRSet.getFloat(4))+"\"></TD><TD CLASS=\"strip"+sStrip+"\"><A CLASS=\"linksmall\" HREF=\"#\" onclick=\"editCost('"+sPrj+"','"+oRSet.getString(1)+"')\">Edit</A></TD><TD><INPUT TYPE=\"checkbox\" NAME=\"chk_cost_"+oRSet.getString(1)+"\"><TD></TD></TR>\n");
            fSubTotal += fCost;
          }
          iStrip++;
        } // fi (iDate between iFrom and iTo)          
      } // wend
      oRSet.close();
      out.write("      <TR><TD><IMG SRC=../images/images/spacer.gif BORDER=0 HEIGHT=1 WIDTH="+String.valueOf(10*(iLevel-1)+16)+"></TD><TD><A HREF=\"#\" CLASS=\"linkplain\" onclick=\"createCost('"+sPrj+"')\">New Cost</A></TD><TD></TD></TD><TD></TD></TR>\n");
      out.write("      <TR><TD><IMG SRC=../images/images/spacer.gif BORDER=0 HEIGHT=1 WIDTH="+String.valueOf(10*(iLevel-1)+16)+"></TD><TD ALIGN=\"right\"><FONT CLASS=\"textplain\"><B>Subtotal</B></FONT></TD><TD><FONT CLASS=\"textplain\"><B>"+Fmt.format(fSubTotal)+"</B></FONT></TD></TD><TD></TD></TR>\n");
      out.write("    </TABLE>\n");
      iDivNest++;
      fGrandTotal += fSubTotal;
    } // next
    while (iLevel<=iDivNest) {
      out.write("  </DIV>\n");
      iDivNest--;
    }    
    oCosts.close();
    oDuties.close();
    
    oConn.close("prj_costs");
  }
  catch (SQLException e) {  
    if (oConn!=null)
      if (!oConn.isClosed()) {
        oConn.close("prj_costs");      
      }
    oConn = null;
    out.write("SQLException " + e.getMessage());
  }
  if (null==oConn) return;    
  oConn = null;
  out.write("<FONT CLASS=\"textbigstrong\">Total "+Fmt.format(fGrandTotal)+"</FONT>");
%>
</FORM>
<FORM ACTION="prj_costs_delete.jsp">
  <INPUT TYPE="hidden" NAME="gu_project" VALUE="<%=gu_project%>">
  <INPUT TYPE="hidden" NAME="duties">
  <INPUT TYPE="hidden" NAME="costs">
  <INPUT TYPE="hidden" NAME="dt_from">
  <INPUT TYPE="hidden" NAME="dt_to">
</FORM>
</BODY>
<HTML>
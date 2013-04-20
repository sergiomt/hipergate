<%@ page import="java.util.Date,java.text.SimpleDateFormat,java.util.HashMap,java.util.LinkedList,java.util.ListIterator,java.io.IOException,java.net.URLDecoder,java.sql.SQLException,java.sql.PreparedStatement,java.sql.ResultSet,com.knowgate.jdc.*,com.knowgate.dataobjs.*,com.knowgate.acl.*,com.knowgate.crm.*,com.knowgate.hipergate.DBLanguages,com.knowgate.hipergate.Term,com.knowgate.misc.Gadgets,com.knowgate.training.Admission" language="java" session="false" contentType="text/html;charset=UTF-8" %>
<%@ include file="../methods/nullif.jspf" %><%@ include file="../methods/dbbind.jsp" %><%@ include file="../methods/cookies.jspf" %><%@ include file="../methods/authusrs.jspf" %>
<jsp:useBean id="GlobalCacheClient" scope="application" class="com.knowgate.cache.DistributedCachePeer"/><jsp:useBean id="GlobalDBLang" scope="application" class="com.knowgate.hipergate.DBLanguages"/>
<%     // 01. Verify user credentials

if (autenticateSession(GlobalDBBind, request, response)<0) return;

// 02. Avoid page caching

response.addHeader ("Pragma", "no-cache");
response.addHeader ("cache-control", "no-store");
response.setIntHeader("Expires", 0);

// 03. Get parameters

final String PAGE_NAME = "admission_edit";

final String sLanguage = getNavigatorLanguage(request);
final String sSkin = getCookie(request, "skin", "xp");
final int iAppMask = Integer.parseInt(getCookie(request, "appmask", "0"));

final String id_user = getCookie(request, "userid", "");
final String id_domain = request.getParameter("id_domain");
final String gu_workarea = request.getParameter("gu_workarea");
final String gu_contact = request.getParameter("gu_contact");
final String gu_oportunity = request.getParameter("gu_oportunity");


boolean bIsGuest = true;
boolean bLoaded = false;

Admission oObj = new Admission();

String sIdObjectiveLookUp = null;
String sIdInterviewerLookUp = null;
String sIdPlaceLookUp = null;
String sGuAcourseLookUp = null;
String dtCreated = null;
String dtTarget = null;
String dtInterview = null;
String dtAdmisionTest = null;

HashMap oIdObjectiveLookUp = null;
HashMap oIdInterviewerLookUp = null;
HashMap oIdPlaceLookUp = null;

DBSubset oAcourses = null;

/* DBSubset oAdmission = new DBSubset(DB.k_admission, DB.gu_admission +","+ DB.gu_contact +","+ DB.gu_oportunity +","+ DB.gu_workarea +","+ DB.gu_acourse +","+ 
		DB.id_objetive_1 +","+ DB.id_objetive_2 +","+ DB.id_objetive_3 +","+ DB.dt_created +","+ DB.dt_target +","+ DB.is_call smallint +","+ DB.id_place +","+ 
		DB.id_interviewer +","+ DB.dt_interview +","+ DB.dt_admision_test +","+ DB.is_grant +","+ DB.nu_grant +","+ DB.nu_interview +","+ DB.nu_vips integer +","+ 
		DB.nu_nips +","+ DB.nu_elp integer +","+ DB.nu_total +","+ DB.id_test_result character varying(50) +" where gu_contact = ? and gu_oportunity = ? and gu_wokarea = ?" , 0);*/

int iAdmissions = 0;
int iAcoursesCount = 0;
JDCConnection oConn = null;
PreparedStatement oStmt = null;
ResultSet oRSet = null;
SimpleDateFormat oSimpleDate = new SimpleDateFormat("yyyy-MM-dd");
Date dtDate =null;
try {
	bIsGuest = isDomainGuest (GlobalCacheClient, GlobalDBBind, request, response);
	oConn = GlobalDBBind.getConnection(PAGE_NAME);
	// idAdmissions = oAdmission.load(oConn, new Object[]{gu_contact,gu_oportunity,gu_workarea});
	
	oIdObjectiveLookUp = DBLanguages.getLookUpMap(oConn, DB.k_oportunities_lookup, gu_workarea, DB.id_objetive, sLanguage);
	oIdInterviewerLookUp = DBLanguages.getLookUpMap(oConn, DB.k_admission_lookup, gu_workarea, DB.id_interviewer, sLanguage);
	oIdPlaceLookUp = DBLanguages.getLookUpMap(oConn, DB.k_admission_lookup, gu_workarea, DB.id_place, sLanguage);
	oAcourses = new DBSubset (DB.k_academic_courses, DB.gu_acourse + "," + DB.nm_course , " bo_active<>0 ORDER BY 2", 100);
	
	sIdObjectiveLookUp = DBLanguages.getHTMLSelectLookUp (oConn, DB.k_oportunities_lookup, gu_workarea, DB.id_objetive, sLanguage);
	sIdInterviewerLookUp = DBLanguages.getHTMLSelectLookUp (oConn, DB.k_admission_lookup, gu_workarea, DB.id_interviewer, sLanguage);
	sIdPlaceLookUp = DBLanguages.getHTMLSelectLookUp (oConn, DB.k_admission_lookup, gu_workarea, DB.id_place, sLanguage);
	
	iAcoursesCount = oAcourses.load(oConn, new Object[0]);
	
	if (null!=gu_contact && null!=gu_oportunity) {
		bLoaded = oObj.load(oConn, new Object[]{gu_contact,gu_oportunity});
		if (bLoaded) {
			dtDate = (Date) oObj.get(DB.dt_target);
			if (dtDate!=null) {
				dtTarget = oSimpleDate.format(dtDate);
			}
			dtDate = (Date) oObj.get(DB.dt_interview);
			if (dtDate!=null) {
				dtInterview = oSimpleDate.format(dtDate);
			}
			dtDate = (Date) oObj.get(DB.dt_admision_test);
			if (dtDate!=null) {
				dtAdmisionTest = oSimpleDate.format(dtDate);
			}
			oStmt = oConn.prepareStatement("SELECT " +  DB.dt_created +" FROM " + DB.k_admission + " WHERE " + DB.gu_oportunity + "=? AND "+DB.gu_contact+"=?");
		    oStmt.setString(1, gu_oportunity);
		    oStmt.setString(2, gu_contact);
		    oRSet = oStmt.executeQuery();
		    oRSet.next();
		    dtCreated = oSimpleDate.format(oRSet.getDate(1));
		    oRSet.close();
		    oRSet = null;
		    oStmt.close();
		    oStmt = null;
		}
		
	}
}catch (SQLException e) {  
    if (oConn!=null){
        if (!oConn.isClosed()){
        	oConn.close(PAGE_NAME);
        }
      oConn = null;
      response.sendRedirect (response.encodeRedirectUrl ("../common/errmsg.jsp?title=Error&desc=" + e.getLocalizedMessage() + "&resume=_close"));
	}
}
if (null==oConn){
	return;
}
oConn = null;
%>
<!DOCTYPE HTML PUBLIC "-//W3C//DTD HTML 4.0 Transitional//EN">
<HTML LANG="<%=sLanguage.toUpperCase()%>">
<HEAD>
  <SCRIPT SRC="../javascript/cookies.js"></SCRIPT>  
  <SCRIPT SRC="../javascript/setskin.js"></SCRIPT>
  <SCRIPT SRC="../javascript/getparam.js"></SCRIPT>
  <SCRIPT SRC="../javascript/usrlang.js"></SCRIPT>
  <SCRIPT SRC="../javascript/combobox.js"></SCRIPT>  
  <SCRIPT SRC="../javascript/trim.js"></SCRIPT>
  <SCRIPT SRC="../javascript/datefuncs.js"></SCRIPT>
  <SCRIPT TYPE="text/javascript">
    function setCombos() {
        var frm = document.forms[0];

        <% if (!oObj.isNull(DB.is_call)) { %>
    		setCheckedValue(frm.is_call, <%=String.valueOf(oObj.getShort(DB.is_call))%>);
		<% } %>
		<% if (!oObj.isNull(DB.is_grant)) { %>
		setCheckedValue(frm.is_grant, <%=String.valueOf(oObj.getShort(DB.is_grant))%>);
		<% } %>
        setCombo(frm.sel_id_objetive_1,"<% out.write(oObj.getStringNull(DB.id_objetive_1,"")); %>");
        setCombo(frm.sel_id_objetive_2,"<% out.write(oObj.getStringNull(DB.id_objetive_2,"")); %>");
        setCombo(frm.sel_id_objetive_3,"<% out.write(oObj.getStringNull(DB.id_objetive_3,"")); %>");
        setCombo(frm.sel_nm_acourse,"<% out.write(oObj.getStringNull(DB.gu_acourse,"")); %>");
        setCombo(frm.sel_id_place,"<% out.write(oObj.getStringNull(DB.id_place,"")); %>");
        setCombo(frm.sel_id_interviewer,"<% out.write(oObj.getStringNull(DB.id_interviewer,"")); %>");
        setCombo(frm.sel_id_test_result,"<%if (!oObj.isNull(DB.id_test_result)) out.write(String.valueOf(oObj.getInt(DB.id_test_result)));%>");

       
        return true;
    }

    function validate(){
    	var frm = window.document.forms[0];
    	
        frm.id_objetive_1.value = nullif(getCombo(frm.sel_id_objetive_1));
        frm.id_objetive_2.value = nullif(getCombo(frm.sel_id_objetive_2));
        frm.id_objetive_3.value = nullif(getCombo(frm.sel_id_objetive_3));
        frm.gu_acourse.value = nullif(getCombo(frm.sel_nm_acourse));
        frm.id_place.value = nullif(getCombo(frm.sel_id_place));
        frm.id_interviewer.value = nullif(getCombo(frm.sel_id_interviewer));
        frm.id_test_result.value = nullif(getCombo(frm.sel_id_test_result));
        
        
        return true;
    }
    function lookup(odctrl) {
	      var frm = document.forms[0];
	      switch(parseInt(odctrl)) {
          case 1:
            window.open("../common/lookup_f.jsp?nm_table=k_oportunities_lookup&id_language=" + getUserLanguage() + "&id_section=id_objetive&tp_control=2&nm_control=sel_id_objetive_1&nm_coding=id_objetive_1&id_form=0", "", "toolbar=no,directories=no,menubar=no,resizable=no,width=480,height=520");
            break;
          case 2:
            window.open("../common/lookup_f.jsp?nm_table=k_oportunities_lookup&id_language=" + getUserLanguage() + "&id_section=id_objetive&tp_control=2&nm_control=sel_id_objetive_2&nm_coding=id_objetive_2&id_form=0", "", "toolbar=no,directories=no,menubar=no,resizable=no,width=480,height=520");
            break;
          case 3:
            window.open("../common/lookup_f.jsp?nm_table=k_oportunities_lookup&id_language=" + getUserLanguage() + "&id_section=id_objetive&tp_control=2&nm_control=sel_id_objetive_3&nm_coding=id_objetive_3&id_form=0", "", "toolbar=no,directories=no,menubar=no,resizable=no,width=480,height=520");
            break;
          case 4:
            window.open("../common/lookup_f.jsp?nm_table=k_admission_lookup&id_language=" + getUserLanguage() + "&id_section=id_place&tp_control=2&nm_control=sel_id_place&nm_coding=id_place&id_form=0", "", "toolbar=no,directories=no,menubar=no,resizable=no,width=480,height=520");
            break;
          case 5:
            window.open("../common/lookup_f.jsp?nm_table=k_admission_lookup&id_language=" + getUserLanguage() + "&id_section=id_interviewer&tp_control=2&nm_control=sel_id_interviewer&nm_coding=id_interviewer&id_form=0", "", "toolbar=no,directories=no,menubar=no,resizable=no,width=480,height=520");
            break; 
	      }
    }

    function showCalendar(ctrl) {
        var dtnw = new Date();

        window.open("../common/calendar.jsp?a=" + (dtnw.getFullYear()) + "&m=" + dtnw.getMonth() + "&c=" + ctrl, "", "toolbar=no,directories=no,menubar=no,resizable=no,width=171,height=195");
      } //showcalendar
  </SCRIPT>       
  <TITLE>hipergate :: Edit Admission</TITLE>
</HEAD>
<BODY TOPMARGIN="8" MARGINHEIGHT="8" onLoad="setCombos();">
<DIV class="cxMnu1" style="width:350px"><DIV class="cxMnu2" style="width:350px">
    <SPAN class="hmMnuOff" onMouseOver="this.className='hmMnuOn'" onMouseOut="this.className='hmMnuOff'" onClick="history.back()"><IMG src="../images/images/toolmenu/historyback.gif" width="16" style="vertical-align:middle" height="16" border="0" alt="Back"> Back</SPAN>
    <SPAN class="hmMnuOff" onMouseOver="this.className='hmMnuOn'" onMouseOut="this.className='hmMnuOff'" onClick="location.reload(true)"><IMG src="../images/images/toolmenu/locationreload.gif" width="16" style="vertical-align:middle" height="16" border="0" alt="Refresh"> Refresh</SPAN>
    <SPAN class="hmMnuOff" onMouseOver="this.className='hmMnuOn'" onMouseOut="this.className='hmMnuOff'" onClick="window.print()"><IMG src="../images/images/toolmenu/windowprint.gif" width="16" height="16" style="vertical-align:middle" border="0" alt="Print"> Print</SPAN>
  </DIV></DIV>
</BODY>
<br>
  <TABLE SUMMARY="Admission" WIDTH="100%">
    <TR><TD><IMG SRC="../images/images/spacer.gif" HEIGHT="4" WIDTH="1" BORDER="0"></TD></TR>
    <TR><TD CLASS="striptitle"><FONT CLASS="title1">Admission Data</FONT></TD></TR>
  </TABLE>
  <FORM NAME="" METHOD="post" ACTION="admission_store.jsp" onSubmit="return validate()">
    <INPUT TYPE="hidden" NAME="id_domain" VALUE="<%=id_domain%>">
    <INPUT TYPE="hidden" NAME="gu_workarea" VALUE="<%=gu_workarea%>">
    <INPUT TYPE="hidden" NAME="gu_contact" VALUE="<%=gu_contact%>">
    <INPUT TYPE="hidden" NAME="gu_oportunity" VALUE="<%=gu_oportunity%>">
    <INPUT TYPE="hidden" NAME="dtCreated" VALUE="<%=dtCreated%>">

    <TABLE>
    	<TR>
    		<TD>
    		<fieldset>
				<legend>Admission Info</legend>
        		<TABLE WIDTH="100%">
        			<TR>
            			<TD ALIGN="right" WIDTH="110"><FONT CLASS="formplain">Created</FONT></TD>
            			<TD ALIGN="left" WIDTH="420" CLASS="formplain"><%if (dtCreated!=null){ out.write(dtCreated); }  else { %>New Admission <% }%>
            			</TD>
          			</TR>
        			<TR>
            			<TD ALIGN="right" WIDTH="110"><FONT CLASS="formplain">First option of interest programme</FONT></TD>
            			<TD ALIGN="left" WIDTH="420">
            				<INPUT TYPE="hidden" NAME="id_objetive_1">
              				<SELECT NAME="sel_id_objetive_1"><OPTION VALUE=""></OPTION><%=sIdObjectiveLookUp%></SELECT>&nbsp;
              				<A HREF="javascript:lookup(1)"><IMG SRC="../images/images/find16.gif" HEIGHT="16" BORDER="0" ALT="Objetive 1 list"></A>
            			</TD>
          			</TR>
          			<TR>
            			<TD ALIGN="right" WIDTH="110"><FONT CLASS="formplain">Second option of interest programme</FONT></TD>
            			<TD ALIGN="left" WIDTH="420">
            				<INPUT TYPE="hidden" NAME="id_objetive_2">
              				<SELECT NAME="sel_id_objetive_2"><OPTION VALUE=""></OPTION><%=sIdObjectiveLookUp%></SELECT>&nbsp;
              				<A HREF="javascript:lookup(2)"><IMG SRC="../images/images/find16.gif" HEIGHT="16" BORDER="0" ALT="Objetive 2 list"></A>
            			</TD>
          			</TR>
          			<TR>
            			<TD ALIGN="right" WIDTH="110"><FONT CLASS="formplain">Third option of interest programme</FONT></TD>
            			<TD ALIGN="left" WIDTH="420">
            				<INPUT TYPE="hidden" NAME="id_objetive_3">
              				<SELECT NAME="sel_id_objetive_3"><OPTION VALUE=""></OPTION><%=sIdObjectiveLookUp%></SELECT>&nbsp;
              				<A HREF="javascript:lookup(3)"><IMG SRC="../images/images/find16.gif" HEIGHT="16" BORDER="0" ALT="Objetive 3 list"></A>
            			</TD>
          			</TR>
        		</table>
        	</fieldset>
        	</TD>
        </TR>
        <TR>
    		<TD>
    		<fieldset>
				<legend>Admission test data</legend>
        		<TABLE WIDTH="100%">
        			<TR>
            			<TD ALIGN="right" WIDTH="55" ><FONT CLASS="formplain">Academic course</FONT></TD>            
            			<TD ALIGN="left" WIDTH="475" colspan="3">
              				<INPUT TYPE="hidden" NAME="gu_acourse">
              				<SELECT NAME="sel_nm_acourse"><OPTION VALUE=""></OPTION><%for(int i=0; i < iAcoursesCount ; i++){%>
              					<option value = "<%=oAcourses.getStringNull(0,i,"") %>"><%=oAcourses.getStringNull(1,i,"") %></option>
              				<%}%></SELECT>
    			        </TD>
          			</TR>
          			<TR>
          			 	<TD ALIGN="right" WIDTH="55" ><FONT CLASS="formplain">Call Type:</FONT></TD>
            			<TD ALIGN="left" WIDTH="475" colspan="3"  CLASS="formplain">
            				<INPUT TYPE="radio" NAME="is_call" VALUE="1">&nbsp;Ordinary&nbsp;&nbsp;&nbsp;
            				<INPUT TYPE="radio" NAME="is_call" VALUE="0">&nbsp;Extraordinary&nbsp;&nbsp;&nbsp;
            	       </TD>
          			</TR>
          			<TR>
            			<TD ALIGN="right" WIDTH="55"><FONT CLASS="formplain">Scheduled date of admission interview</FONT></TD>            
            			<TD ALIGN="left" WIDTH="210">
              				<INPUT TYPE="text" MAXLENGTH="10" SIZE="11" NAME="dt_target" VALUE="<% if (dtTarget!=null) out.write(dtTarget); %>">&nbsp;&nbsp;
              				<A HREF="javascript:showCalendar('dt_target')"><IMG SRC="../images/images/datetime16.gif" WIDTH="16" HEIGHT="16" BORDER="0" ALT="Show calendar"></A>
    			        </TD>
    			    	<TD ALIGN="right" WIDTH="55"><FONT CLASS="formplain">Actual date of admission interview</FONT></TD>
            			<TD ALIGN="left" WIDTH="210">
            				<INPUT TYPE="text" MAXLENGTH="10" SIZE="11" NAME="dt_admision_test" VALUE="<% if (dtAdmisionTest!=null) out.write(dtAdmisionTest); %>">&nbsp;&nbsp;
              				<A HREF="javascript:showCalendar('dt_admision_test')"><IMG SRC="../images/images/datetime16.gif" WIDTH="16" HEIGHT="16" BORDER="0" ALT="Show calendar"></A>
            			</TD>
          			</TR>
          			<TR>
            			<TD ALIGN="right" WIDTH="55"><FONT CLASS="formplain">Test Location</FONT></TD>
            			<TD ALIGN="left" WIDTH="475" colspan="3"  >
            				<INPUT TYPE="hidden" NAME="id_place">
              				<SELECT NAME="sel_id_place"><OPTION VALUE=""></OPTION><%=sIdPlaceLookUp%></SELECT>&nbsp;
              				<A HREF="javascript:lookup(4)"><IMG SRC="../images/images/find16.gif" HEIGHT="16" BORDER="0" ALT="Places list"></A>
            			</TD>
          			</TR>
          			<TR>
            			<TD ALIGN="right" WIDTH="55"><FONT CLASS="formplain">Interviewer's Name</FONT></TD>
            			<TD ALIGN="left" WIDTH="475" colspan="3"  >
            				<INPUT TYPE="hidden" NAME="id_interviewer">
              				<SELECT NAME="sel_id_interviewer"><OPTION VALUE=""></OPTION><%=sIdInterviewerLookUp%></SELECT>&nbsp;
              				<A HREF="javascript:lookup(5)"><IMG SRC="../images/images/find16.gif" HEIGHT="16" BORDER="0" ALT="Interviewers list"></A>
            			</TD>
          			</TR>
          			<TR>
            			<TD ALIGN="right" WIDTH="55"><FONT CLASS="formplain">Interview Date</FONT></TD>
            			<TD ALIGN="left" WIDTH="475" colspan="3"  >
            				<INPUT TYPE="text" MAXLENGTH="10" SIZE="11" NAME="dt_interview" VALUE="<% if (dtInterview!=null) out.write(dtInterview); %>">&nbsp;&nbsp;
              				<A HREF="javascript:showCalendar('dt_interview')"><IMG SRC="../images/images/datetime16.gif" WIDTH="16" HEIGHT="16" BORDER="0" ALT="Show calendar"></A>
            			</TD>
          			</TR>
        		</table>
        	</fieldset>
        	</TD>
        </TR>
        <TR>
    		<TD>
    		<fieldset>
				<legend>Grant Data</legend>
        		<TABLE WIDTH="100%">
        			<TR>
          			 	<TD ALIGN="right" WIDTH="55"><FONT CLASS="formplain">Request Grant</FONT></TD>
            			<TD ALIGN="left" WIDTH="210" CLASS="formplain">
            				<INPUT TYPE="radio" NAME="is_grant" VALUE="1">&nbsp;Yes&nbsp;&nbsp;&nbsp;<br/>
            				<INPUT TYPE="radio" NAME="is_grant" VALUE="0">&nbsp;No&nbsp;&nbsp;&nbsp;
            	       </TD>
          				<TD ALIGN="right" WIDTH="55"><FONT CLASS="formplain">Grant Amount/Percentage</FONT></TD>
            			<TD ALIGN="left" WIDTH="210"><INPUT TYPE="text" NAME="nu_grant" MAXLENGTH="6" SIZE="6" VALUE="<% out.write(oObj.getStringNull(DB.nu_grant,"")); %>"></TD>
            		</TR>
        		</table>
        	</fieldset>
        	</TD>
        </TR>
         <TR>
    		<TD>
    		<fieldset>
				<legend>Test Results</legend>
        		<TABLE WIDTH="100%">
        			<TR>
          			 	<TD ALIGN="right" WIDTH="55"><FONT CLASS="formplain">Interview</FONT></TD>
            			<TD ALIGN="left" WIDTH="210" CLASS="formplain">
            				<INPUT TYPE="text" NAME="nu_interview" MAXLENGTH="9" SIZE="9" VALUE="<% if (!oObj.isNull(DB.nu_interview)) out.write(String.valueOf(oObj.getInt(DB.nu_interview))); %>" onkeypress="return acceptOnlyNumbers();">&nbsp;Points
            	       </TD>
          				<TD ALIGN="right" WIDTH="55"><FONT CLASS="formplain">VIPS</FONT></TD>
            			<TD ALIGN="left" WIDTH="210" CLASS="formplain">
            				<INPUT TYPE="text" NAME="nu_vips"  MAXLENGTH="9" SIZE="9" VALUE="<% if (!oObj.isNull(DB.nu_vips)) out.write(String.valueOf(oObj.getInt(DB.nu_vips))); %>" onkeypress="return acceptOnlyNumbers();">&nbsp;Points
            			</TD>
            		</TR>
            		<TR>
          			 	<TD ALIGN="right" WIDTH="55"><FONT CLASS="formplain">NIPS</FONT></TD>
            			<TD ALIGN="left" WIDTH="210" CLASS="formplain">
            				<INPUT TYPE="text" NAME="nu_nips" MAXLENGTH="9" SIZE="9" VALUE="<% if (!oObj.isNull(DB.nu_nips)) out.write(String.valueOf(oObj.getInt(DB.nu_nips))); %>" onkeypress="return acceptOnlyNumbers();">&nbsp;Points
            	       </TD>
          				<TD ALIGN="right" WIDTH="55"><FONT CLASS="formplain">ELP</FONT></TD>
            			<TD ALIGN="left" WIDTH="210" CLASS="formplain">
            				<INPUT TYPE="text" NAME="nu_elp"  MAXLENGTH="9" SIZE="9" VALUE="<% if (!oObj.isNull(DB.nu_elp)) out.write(String.valueOf(oObj.getInt(DB.nu_elp))); %>" onkeypress="return acceptOnlyNumbers();">&nbsp;Points
            			</TD>
            		</TR>
            		<TR>
          			 	<TD ALIGN="right" WIDTH="55"><FONT CLASS="formplain">Global</FONT></TD>
            			<TD ALIGN="left" WIDTH="210" CLASS="formplain">
            				<INPUT TYPE="text" NAME="nu_total" MAXLENGTH="9" SIZE="9" VALUE="<% if (!oObj.isNull(DB.nu_total)) out.write(String.valueOf(oObj.getInt(DB.nu_total))); %>" onkeypress="return acceptOnlyNumbers();">&nbsp;Points
            	       </TD>
          				<TD ALIGN="right" WIDTH="55"></TD>
            			<TD ALIGN="left" WIDTH="210" CLASS="formplain"></TD>
            		</TR>
            		<TR>
          			 	<TD ALIGN="right" WIDTH="55"><FONT CLASS="formplain">Test Results</FONT></TD>
            			<TD ALIGN="left" WIDTH="475" colspan="3"   CLASS="formplain">
              				<SELECT NAME="sel_id_test_result"><OPTION VALUE=""></OPTION><OPTION VALUE="1">Admitted</OPTION><OPTION VALUE="2">Conditionally Admitted</OPTION><OPTION VALUE="3">Not Admitted</OPTION></SELECT>&nbsp;
              				<INPUT TYPE="hidden" NAME="id_test_result" VALUE="<%if (!oObj.isNull(DB.id_test_result)) out.write(String.valueOf(oObj.getInt(DB.id_test_result))); %>">
            	       </TD>
          				
            		</TR>
        		</table>
        	</fieldset>
        	</TD>
        </TR>					
        <TR>
    	    <TD COLSPAN="2" ALIGN="center">
              <INPUT TYPE="submit" ACCESSKEY="s" VALUE="Save" CLASS="pushbutton" STYLE="width:80" TITLE="ALT+s">&nbsp;
    	      &nbsp;&nbsp;<INPUT TYPE="reset" ACCESSKEY="c" VALUE="Clear" CLASS="closebutton" STYLE="width:80" TITLE="ALT+c">
    	      <BR><BR>
    	    </TD>
    	 </TR>    
    </TABLE>
  </FORM>
</HTML>
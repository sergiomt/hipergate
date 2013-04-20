<%@ page import="java.util.LinkedList,java.util.ListIterator,java.io.IOException,java.net.URLDecoder,java.sql.SQLException,java.sql.PreparedStatement,java.sql.ResultSet,com.knowgate.jdc.*,com.knowgate.dataobjs.*,com.knowgate.acl.*,com.knowgate.crm.*,com.knowgate.hipergate.DBLanguages,com.knowgate.hipergate.Term,com.knowgate.misc.Gadgets" language="java" session="false" contentType="text/html;charset=UTF-8" %>
<%@ include file="../methods/dbbind.jsp" %><%@ include file="../methods/cookies.jspf" %><%@ include file="../methods/authusrs.jspf" %><%@ include file="../methods/customattrs.jspf" %><%@ include file="../methods/nullif.jspf" %>
<jsp:useBean id="GlobalCacheClient" scope="application" class="com.knowgate.cache.DistributedCachePeer"/><jsp:useBean id="GlobalDBLang" scope="application" class="com.knowgate.hipergate.DBLanguages"/>
<%@ include file="contact_edit.jspf" %>
<BODY TOPMARGIN="8" MARGINHEIGHT="8" onClick="hideRightMenu()">
<FORM NAME="fixedAttrs" METHOD="post" ACTION="contact_edit_store.jsp" onSubmit="return validate()">
  <DIV class="cxMnu1" style="width:<%=(gu_contact.length()>0 && bIsAdmin ? "6" : bIsGuest ? "4" : "5")%>80px"><DIV class="cxMnu2">
    <SPAN class="hmMnuOff" onMouseOver="this.className='hmMnuOn'" onMouseOut="this.className='hmMnuOff'" onClick="history.back()"><IMG src="../images/images/toolmenu/historyback.gif" width="16" style="vertical-align:middle" height="16" border="0" alt="Back"> Back</SPAN>
    <% if (!bIsGuest) { %><SPAN class="hmMnuOff" onMouseOver="this.className='hmMnuOn'; showRightMenu(event);" onMouseOut="this.className='hmMnuOff'"><IMG src="../images/images/new16x16.gif" width="16" style="vertical-align:middle" height="16" border="0" alt="New"> New</SPAN><% } %>
    <SPAN class="hmMnuOff" onMouseOver="this.className='hmMnuOn'" onMouseOut="this.className='hmMnuOff'" onClick="location.reload(true)"><IMG src="../images/images/toolmenu/locationreload.gif" width="16" style="vertical-align:middle" height="16" border="0" alt="Refresh"> Refresh</SPAN>
    <SPAN class="hmMnuOff" onMouseOver="this.className='hmMnuOn'" onMouseOut="this.className='hmMnuOff'" onClick="window.print()"><IMG src="../images/images/toolmenu/windowprint.gif" width="16" height="16" style="vertical-align:middle" border="0" alt="Print"> Print</SPAN>
<% if (gu_contact.length()>0) { %>
    <SPAN class="hmMnuOff" onMouseOver="this.className='hmMnuOn'" onMouseOut="this.className='hmMnuOff'" onClick="window.open('contact_report.jsp?gu_contact=<%=gu_contact%>')"><IMG src="../images/images/crm/agent16.gif" width="16" height="16" style="vertical-align:middle" border="0" alt="Complete report"> Complete report</SPAN>
<%  if (bIsAdmin) { %>
    <SPAN class="hmMnuOff" onMouseOver="this.className='hmMnuOn'" onMouseOut="this.className='hmMnuOff'" onClick="document.location='contact_security.jsp?id_domain=<%=id_domain%>&gu_contact=<%=gu_contact%>'"><IMG src="../images/images/crm/padlock16.gif" width="16" height="16" style="vertical-align:middle" border="0" alt="Security"> Security</SPAN>
<% } } %>
  </DIV></DIV>
<% if (gu_contact.length()>0) { %>
  <TABLE CELLSPACING="2" CELLPADDING="2">
    <TR><TD COLSPAN="12"><IMG SRC="../images/images/spacer.gif" HEIGHT="4"></TD></TR>
    <TR><TD COLSPAN="12" BACKGROUND="../images/images/loginfoot_med.gif" HEIGHT="3"></TD></TR>
    <TR>
      <TD VALIGN="middle"><IMG SRC="../images/images/theworld16.gif" WIDTH="16" HEIGHT="16" BORDER="0" onMouseOver="quickViewAddrs(event)" onMouseOut="hideDiv()"></TD>
      <TD VALIGN="middle"><A HREF="#" onclick="viewAddrs()" CLASS="linkplain">Addresses</A></TD>
      <TD VALIGN="middle"><IMG SRC="../images/images/note16x16.gif" WIDTH="15" HEIGHT="18" BORDER="0"></TD>
      <TD VALIGN="middle"><A HREF="#" onclick="viewNotes()" CLASS="linkplain">Notes</A></TD>
      <TD VALIGN="middle"><IMG SRC="../images/images/attachedfile16x16.gif" WIDTH="21" HEIGHT="17" BORDER="0"></TD>
      <TD VALIGN="middle"><A HREF="#" onclick="viewAttachments()" CLASS="linkplain">Attached Files</A></TD>
<% if ((iAppMask & (1<<Sales))!=0) { %>
      <TD VALIGN="middle"><IMG SRC="../images/images/loan16x16.gif" WIDTH="26" HEIGHT="16" BORDER="0"></TD>
      <TD VALIGN="middle"><A HREF="#" onclick="viewOportunities()" CLASS="linkplain">Leads</A></TD>
      <TD VALIGN="middle"><IMG SRC="../images/images/crm/welcomepack.gif" WIDTH="20" HEIGHT="18" BORDER="0"></TD>
      <TD VALIGN="middle"><A HREF="#" onclick="viewWelcomePack()" CLASS="linkplain">Welcome Pack</A></TD>
<% } else { %>
      <TD COLSPAN="4"></TD>
<% } %>
    </TR>
    <TR>
   <% /* Inicio i2e 2009-11-30 */ %>
    <TD VALIGN="middle"><IMG SRC="../images/images/crm/cv.png" WIDTH="16" HEIGHT="16" BORDER="0"></TD>
    <TD VALIGN="middle"><A HREF="cv_contact_edit.jsp?gu_contact=<%=oCont.getString(DB.gu_contact)%>&fullname=<%=Gadgets.URLEncode(oCont.getStringNull(DB.tx_name,"") + " " + oCont.getStringNull(DB.tx_surname,""))%>" onclick="top.resizeTo(860,760);" CLASS="linkplain">Curriculum</A></TD>
    <%/* fin i2e */%>
<% if (((iAppMask & (1<<CollaborativeTools))!=0) && (gu_contact.length()>0)) { %>
      <TD VALIGN="middle"><IMG SRC="../images/images/addrbook/telephone16.gif" WIDTH="16" HEIGHT="16" BORDER="0"></TD>
      <TD VALIGN="middle"><A HREF="#" onclick="window.opener.parent.location.href='../addrbook/phonecall_listing.jsp?selected=1&subselected=5&field=<%=DB.gu_contact%>&find=<%=gu_contact%>&contact_person=<%=Gadgets.URLEncode(oCont.getStringNull(DB.tx_name,"") + " " + oCont.getStringNull(DB.tx_surname,""))%>'; window.opener.top.focus()" CLASS="linkplain">Calls</A></TD>
<% } else { %>
      <TD COLSPAN="2"></TD>
<% } %>
<% if (((iAppMask & (1<<Hipermail))!=0) && (gu_contact.length()>0)) { %>
      <TD VALIGN="middle"><IMG SRC="../images/images/crm/mailmsg.gif" WIDTH="16" HEIGHT="16" BORDER="0"></TD>
      <TD VALIGN="middle"><A HREF="contact_msgs.jsp?gu_contact=<%=gu_contact%>" CLASS="linkplain">e-Mails</A></TD>
<% } else { %>
      <TD COLSPAN="2"></TD>
<% } %>
<% if (((iAppMask & (1<<CollaborativeTools))!=0) && (gu_contact.length()>0)) { %>
      <TD VALIGN="middle"><IMG SRC="../images/images/crm/subscriptions16.gif" WIDTH="18" HEIGHT="18" BORDER="0"></TD>
      <TD VALIGN="middle"><A HREF="subscriptions_listing.jsp?gu_workarea=<%=gu_workarea%>&gu_contact=<%=gu_contact%>&full_name=<%=Gadgets.URLEncode(oCont.getStringNull(DB.tx_name,"") + " " + oCont.getStringNull(DB.tx_surname,""))%>" TARGET="_top" CLASS="linkplain">Subscriptions</A></TD>
<% } else { %>
      <TD COLSPAN="2"></TD>
<% } %>
<% if (((iAppMask & (1<<Shop))!=0) && (gu_contact.length()>0)) { %>
      <TD VALIGN="middle"><IMG SRC="../images/images/crm/history16.gif" WIDTH="16" HEIGHT="16" BORDER="0"></TD>
      <TD VALIGN="middle"><A HREF="#" onclick="viewSalesHistory()" CLASS="linkplain">Orders</A></TD>
<% } else { %>
      <TD COLSPAN="2"></TD>
<% } %>
<% if (((iAppMask & (1<<ProjectManager))!=0) && (gu_contact.length()>0)) { %>
      <TD VALIGN="middle"><IMG SRC="../images/images/crm/projects20.gif" WIDTH="20" HEIGHT="20" BORDER="0"></TD>
      <TD VALIGN="middle"><A HREF="#" onclick="viewProjects()" CLASS="linkplain">Projects</A></TD>
<% } else { %>
      <TD COLSPAN="2"></TD>
<% } %>
    </TR>
    <TR><TD COLSPAN="12" BACKGROUND="../images/images/loginfoot_med.gif" HEIGHT="3"></TD></TR>
  </TABLE>
<% } else { out.write("<BR><BR>"); } // fi (gu_contact) %>
  
  <DIV style="background-color:transparent; position: relative;width:700px;height:446px">
  <DIV id="p1panel0" class="panel" style="background-color:#eee;z-index:2">
    <INPUT TYPE="hidden" NAME="id_domain" VALUE="<%=id_domain%>">
    <INPUT TYPE="hidden" NAME="n_domain" VALUE="<%=n_domain%>">
    <INPUT TYPE="hidden" NAME="gu_writer" VALUE="<%=id_user%>">    
    <INPUT TYPE="hidden" NAME="gu_workarea" VALUE="<%=gu_workarea%>">
    <INPUT TYPE="hidden" NAME="gu_contact" VALUE="<%=gu_contact%>">
    <INPUT TYPE="hidden" NAME="nu_notes" VALUE="<%=oCont.get(DB.nu_notes)!=null ? String.valueOf(oCont.getInt(DB.nu_notes)) : "0" %>">
    <INPUT TYPE="hidden" NAME="nu_attachs" VALUE="<%=oCont.get(DB.nu_attachs)!=null ? String.valueOf(oCont.getInt(DB.nu_attachs)) : "0" %>">    
    <INPUT TYPE="hidden" NAME="bo_restricted" VALUE="<%=oCont.get(DB.bo_restricted)!=null ? String.valueOf(oCont.getShort(DB.bo_restricted)) : "0" %>">    
    <INPUT TYPE="hidden" NAME="noreload" VALUE="<%=nullif(request.getParameter("noreload"),"0")%>">
    <INPUT TYPE="hidden" NAME="id_batch" VALUE="<%=oCont.getStringNull("id_batch","")%>">
    <INPUT TYPE="hidden" NAME="tx_nickname" VALUE="<%=oCont.getStringNull(DB.tx_nickname,"")%>">
    <INPUT TYPE="hidden" NAME="tx_pwd" VALUE="<%=oCont.getStringNull(DB.tx_pwd,"")%>">

    <TABLE WIDTH="100%">
      <TR><TD>
        <TABLE ALIGN="center" SUMMARY="Contact Fields">
          <TR>
            <TD ALIGN="right" WIDTH="110"><FONT CLASS="textsmall">Creation Date</FONT></TD>
            <TD ALIGN="left" WIDTH="370" CLASS="textsmall"><%=sCreationdate%></TD>
          </TR>
          <TR>
            <TD ALIGN="right" WIDTH="110"><FONT CLASS="formstrong">Private:</FONT></TD>
            <TD ALIGN="left" WIDTH="370">
              <INPUT TYPE="hidden" NAME="bo_private" VALUE="<%=(sPrivate.length()>0 ? "1" : "0")%>">
              <INPUT TYPE="checkbox" NAME="chk_private" VALUE="1" <%=sPrivate%>>
              &nbsp;&nbsp;&nbsp;<FONT CLASS="formplain">Reference:</FONT>&nbsp;<INPUT TYPE="text" NAME="id_ref" MAXLENGTH="50" SIZE="20" VALUE="<%=oCont.getStringNull(DB.id_ref,"")%>" <% if (bContactAutoRefs) out.write("TABINDEX=\"-1\" onfocus=\"document.forms['fixedAttrs'].tx_name.focus()\""); %>>
<%            if (!oCont.isNull(DB.url_facebook)) out.write("&nbsp;<A HREF=\""+oCont.getString(DB.url_facebook)+"\" TARGET=\"_blank\"><IMG SRC=\"../images/images/facebook.gif\" WIDTH=\"16\" HEIGHT=\"16\" BORDER=\"0\"></A>");
              if (!oCont.isNull(DB.url_linkedin)) out.write("&nbsp;<A HREF=\""+oCont.getString(DB.url_linkedin)+"\" TARGET=\"_blank\"><IMG SRC=\"../images/images/linkedin.gif\" WIDTH=\"16\" HEIGHT=\"16\" BORDER=\"0\"></A>");
%>
            </TD>
          </TR>
          <TR>
            <TD ALIGN="right" WIDTH="110"><FONT CLASS="formstrong">Name:</FONT></TD>
            <TD ALIGN="left" WIDTH="420"><INPUT TYPE="text" NAME="tx_name" MAXLENGTH="50" SIZE="32" VALUE="<%=oCont.getStringHtml(DB.tx_name,"")%>"></TD>
          </TR>
          <TR>
            <TD ALIGN="right" WIDTH="110"><FONT CLASS="formstrong">Surname</FONT></TD>
            <TD ALIGN="left" WIDTH="420"><INPUT TYPE="text" NAME="tx_surname" MAXLENGTH="50" SIZE="32" VALUE="<%=oCont.getStringHtml(DB.tx_surname,"")%>"></TD>
          </TR>
          <TR>
            <TD ALIGN="right" WIDTH="110"><FONT CLASS="formplain">Position:</FONT></TD>
            <TD ALIGN="left" WIDTH="420">
              <SELECT CLASS="combomini" NAME="sel_title"><OPTION VALUE=""></OPTION><%=sTitleLookUp%></SELECT>&nbsp;<A HREF="javascript:lookup(1)" TITLE="View Employees Listing"><IMG SRC="../images/images/find16.gif" HEIGHT="16" BORDER="0" ALT="View"></A>
              <INPUT TYPE="hidden" NAME="de_title" VALUE="<%=oCont.getStringNull(DB.de_title,"")%>">
            </TD>
          </TR>
          <TR>
            <TD ALIGN="right" WIDTH="110"><FONT CLASS="formplain">Company:</FONT></TD>            
            <TD ALIGN="left" WIDTH="420">
              <INPUT TYPE="hidden" NAME="gu_company" VALUE="<%=oCont.getStringNull(DB.gu_company,"")%>">
              <INPUT TYPE="text" SIZE="40" NAME="nm_company" MAXLENGTH="70" VALUE="<% if (iCompanyCount>0) out.write(oContanies.getString(DB.nm_legal,0)); %>" onchange="document.forms['fixedAttrs'].gu_company.value='newguid';">
              &nbsp;&nbsp;<A HREF="javascript:reference(1)" TITLE="View Compnay Listing"><IMG SRC="../images/images/find16.gif" HEIGHT="16" BORDER="0" ALT="View"></A>
              &nbsp;&nbsp;<A HREF="#" onclick="document.forms[0].gu_company.value=document.forms[0].nm_company.value=''" TITLE="Remove from Company"><IMG SRC="../images/images/delete.gif" WIDTH="13" HEIGHT="13" BORDER="0" ALT="Delete"></A>
            </TD>
          </TR>
          <TR>
            <TD ALIGN="right" WIDTH="110"><FONT CLASS="formplain">Division:</FONT></TD>
            <TD ALIGN="left" WIDTH="420">
              <INPUT TYPE="text" NAME="tx_division" SIZE="20" MAXLENGTH="32" VALUE="<%=oCont.getStringHtml(DB.tx_division,"")%>">
              &nbsp;&nbsp;<FONT CLASS="formplain">Department:</FONT>
              <INPUT TYPE="text" NAME="tx_dept" SIZE="20" MAXLENGTH="32" VALUE="<%=oCont.getStringHtml(DB.tx_dept,"")%>">
            </TD>
          </TR>                              
          <TR>
            <TD ALIGN="right" WIDTH="110"><FONT CLASS="formplain">Gender:</FONT></TD>
            <TD ALIGN="left" WIDTH="420">
              <SELECT CLASS="combomini" NAME="sel_gender"><OPTION VALUE=""></OPTION><OPTION VALUE="M">M</OPTION><OPTION VALUE="F">F</OPTION></SELECT>
              <INPUT TYPE="hidden" NAME="id_gender" VALUE="<%=oCont.getStringNull(DB.id_gender,"")%>">
              &nbsp;&nbsp;<FONT CLASS="formplain">Status:</FONT>&nbsp;
              <SELECT CLASS="combomini" NAME="sel_status"><OPTION VALUE=""></OPTION><%=sStatusLookUp%></SELECT>&nbsp;<A HREF="javascript:lookup(2)" TITLE="View Status List"><IMG SRC="../images/images/find16.gif" HEIGHT="16" BORDER="0" ALT="View"></A>
              <INPUT TYPE="hidden" NAME="id_status" VALUE="<%=oCont.getStringNull(DB.id_status,"")%>">              
            </TD>
          </TR>                              
          <TR>
            <TD ALIGN="right" WIDTH="110"><FONT CLASS="formplain">Birth Date:</FONT></TD>
            <TD ALIGN="left" WIDTH="420">
              <INPUT TYPE="text" NAME="dt_birth" MAXLENGTH="10" SIZE="10" VALUE="<%=oCont.get(DB.dt_birth)!=null ? oCont.getDateFormated(DB.dt_birth,"yyyy-MM-dd") : ""%>">
              <A HREF="javascript:showCalendar('dt_birth')" TITLE="View Calendar"><IMG SRC="../images/images/datetime16.gif" WIDTH="16" HEIGHT="16" BORDER="0" ALT="View"></A>
	      &nbsp;&nbsp;&nbsp;
	      <FONT CLASS="formplain">Age:</FONT>
	      &nbsp;
              <INPUT TYPE="text" NAME="ny_age" MAXLENGTH="3" SIZE="3" VALUE="<% if (oCont.get(DB.ny_age)!=null) out.write(String.valueOf(oCont.getInt(DB.ny_age)));%>">
            </TD>
          </TR>                              
          <TR>
            <TD ALIGN="right" WIDTH="110"><FONT CLASS="formplain">Legal Id.</FONT></TD>
            <TD ALIGN="left" WIDTH="420">
              <INPUT TYPE="text" NAME="sn_passport" SIZE="10" MAXLENGTH="16" VALUE="<%=oCont.getStringNull(DB.sn_passport,"")%>" STYLE="text-transform:uppercase">&nbsp;
              <SELECT CLASS="combomini" NAME="sel_passport"><OPTION VALUE=""></OPTION><%=sPassportLookUp%></SELECT>&nbsp;<A HREF="javascript:lookup(3)"><IMG SRC="../images/images/find16.gif" HEIGHT="16" BORDER="0" ALT="View Indentity Doc. Types"></A>
              <INPUT TYPE="hidden" NAME="tp_passport" VALUE="<%=oCont.getStringNull(DB.tp_passport,"")%>">
            </TD>
          </TR>
          <TR>
            <TD ALIGN="right" WIDTH="110"><FONT CLASS="formplain">Nationality:</FONT></TD>
            <TD ALIGN="left" WIDTH="420">
              <SELECT CLASS="combomini" NAME="id_nationality"><OPTION VALUE=""></OPTION><%=sCountriesLookUp%></SELECT>
            </TD>
          </TR>
          <TR>
            <TD ALIGN="right" WIDTH="110"><FONT CLASS="formplain">Zone</FONT></TD>
            <TD ALIGN="left" WIDTH="370">
            <INPUT TYPE="hidden" NAME="gu_geozone" VALUE="<%=oCont.getStringNull(DB.gu_geozone,"")%>">
            <INPUT TYPE="hidden" NAME="nm_geozone" SIZE="40" VALUE="<%=oTerm.getStringNull(DB.tx_term,"")%>">
            <SELECT NAME="sel_geozone" onchange="setCombo(document.forms[0].sel_salesman,zone_salesman[this.options[this.selectedIndex].value])"><% out.write (sTerms); %></SELECT>&nbsp;<A HREF="#" onclick="lookupZone()"><IMG SRC="../images/images/find16.gif" BORDER="0"></A>            
            </TD>
          </TR>
          <TR>
            <TD ALIGN="right" WIDTH="110"><FONT CLASS="formplain">Salesman:</FONT></TD>
            <TD ALIGN="left" WIDTH="370">
            <INPUT TYPE="hidden" NAME="gu_sales_man" VALUE="<%=oCont.getStringNull(DB.gu_sales_man,"")%>">
            <SELECT NAME="sel_salesman"><OPTION VALUE=""></OPTION><% for (int s=0; s<iSalesMen; s++) out.write ("<OPTION VALUE=\""+oSalesMen.getString(0,s)+"\">"+oSalesMen.getStringNull(1,s,"")+" "+oSalesMen.getStringNull(2,s,"")+" "+oSalesMen.getStringNull(3,s,"")+"</OPTION>"); %></SELECT>
            </TD>
          </TR>
          <TR>
            <TD ALIGN="right" WIDTH="110"><FONT CLASS="formplain">Comments:</FONT></TD>
            <TD ALIGN="left" WIDTH="420">
            	<TEXTAREA NAME="tx_comments" ROWS="1" COLS="44"><%=oCont.getStringHtml(DB.tx_comments,"")%></TEXTAREA>
              <DIV STYLE="display:none"><TEXTAREA NAME="areas_interes" ROWS="1" COLS="44"><%=loadInterest(oConn,DB.k_contacts_attrs, gu_contact )%></TEXTAREA></DIV>
            </TD>
          </TR>
          <TR>
    	    <TD COLSPAN="2"><HR></TD>
  	  </TR>          
          <TR>
    	    <TD COLSPAN="2" ALIGN="center">
              <INPUT TYPE="submit" ACCESSKEY="s" VALUE="Save" CLASS="pushbutton" STYLE="width:80" TITLE="ALT+s">&nbsp;
    	      &nbsp;&nbsp;<INPUT TYPE="button" ACCESSKEY="c" VALUE="Close" CLASS="closebutton" STYLE="width:80" TITLE="ALT+c" onclick="window.close()">
    	      <BR><BR>
    	    </TD>	            
        </TABLE>
      </TD></TR>
    </TABLE>                 
  </DIV>
  <DIV onclick="selectTab(0)" id="p1tab0" class="tab" style="background-color:#eee; height:26px; left:0px; top:0px; z-index:2"><SPAN onmouseover="this.style.cursor='hand';" onmouseout="this.style.cursor='auto';">Fixed Fields</SPAN></DIV>
  <DIV id="p1panel1" class="panel" style="background-color:#ddd;z-index:1">
    <TABLE WIDTH="100%">
      <TR><TD>
        <TABLE ALIGN="center">  
  	   <%= paintAttributes (oConn, GlobalCacheClient, id_domain, id_user, iAppMask, DB.k_contacts_attrs, "Individuals", gu_workarea, sLanguage, gu_contact) %>
        </TABLE>
      </TD></TR>
      <TR>
        <TD COLSPAN="2"><HR></TD>
      </TR>          
      <TR>
    	<TD COLSPAN="2" ALIGN="center">
<% if (bIsGuest) { %>
          <INPUT TYPE="button" ACCESSKEY="s" VALUE="Save" CLASS="pushbutton" STYLE="width:80" TITLE="ALT+s" onclick="alert('Your current priviledges level as Guest does not allow you to perform this action')">&nbsp;&nbsp;&nbsp;
<% } else { %>
          <INPUT TYPE="submit" ACCESSKEY="s" VALUE="Save" CLASS="pushbutton" STYLE="width:80" TITLE="ALT+s">&nbsp;&nbsp;&nbsp;
<% } %>
    	  <INPUT TYPE="button" ACCESSKEY="c" VALUE="Close" CLASS="closebutton" STYLE="width:80" TITLE="ALT+c" onclick="window.close()">
    	</TD>
       </TR>
    </TABLE>    
  </DIV>
  <DIV onclick="selectTab(1)" id="p1tab1" class="tab" style="width:240px; background-color:#ddd; height:26px; left:180px; top:0px; z-index:1"><SPAN onmouseover="this.style.cursor='hand';" onmouseout="this.style.cursor='auto';">Defined by User</SPAN></DIV>
  </DIV>  
</FORM>
    <IFRAME name="addrIFrame" src="../common/blank.htm" width="0" height="0" border="0" frameborder="0"></IFRAME>
    <SCRIPT language="JavaScript" type="text/javascript">
      <!--
      addMenuOption("Address","createAddress()",0);
      addMenuOption("Opportunity","createOportunity()",0);
      addMenuOption("Note","createNote()",0);
      addMenuOption("File","createAttachment()",0);
<% if ((iAppMask & (1<<CollaborativeTools))!=0) { %>
      addMenuOption("Call","createPhoneCall()",0);
      addMenuOption("Meeting","createActivity()",0);
<% } %>
<% if ((iAppMask & (1<<ProjectManager))!=0) { %>
      addMenuOption("Project","createProject()",0);
<% } %>
      //-->
    </SCRIPT>
</BODY>
</HTML>
<%
if (null!=oConn) oConn.close("contact_edit");
oConn=null;
%>
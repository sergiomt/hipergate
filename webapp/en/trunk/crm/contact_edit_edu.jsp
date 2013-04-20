<%@ page import="java.util.LinkedList,java.util.ListIterator,java.io.IOException,java.net.URLDecoder,java.sql.SQLException,java.sql.PreparedStatement,java.sql.ResultSet,com.knowgate.jdc.*,com.knowgate.dataobjs.*,com.knowgate.acl.*,com.knowgate.crm.*,com.knowgate.hipergate.DBLanguages,com.knowgate.hipergate.Term,com.knowgate.misc.Gadgets" language="java" session="false" contentType="text/html;charset=UTF-8" %>
<%@ include file="../methods/dbbind.jsp" %><%@ include file="../methods/cookies.jspf" %><%@ include file="../methods/authusrs.jspf" %><%@ include file="../methods/customattrs.jspf" %><%@ include file="../methods/nullif.jspf" %>
<jsp:useBean id="GlobalCacheClient" scope="application" class="com.knowgate.cache.DistributedCachePeer"/><jsp:useBean id="GlobalDBLang" scope="application" class="com.knowgate.hipergate.DBLanguages"/>
<%@ include file="contact_edit.jspf" %>

<BODY  TOPMARGIN="8" MARGINHEIGHT="8">
<FORM NAME="fixedAttrs" METHOD="post" ACTION="contact_edit_store.jsp" onSubmit="return validate()">
  <DIV class="cxMnu1" style="width:320px"><DIV class="cxMnu2">
    <SPAN class="hmMnuOff" onMouseOver="this.className='hmMnuOn'" onMouseOut="this.className='hmMnuOff'" onClick="history.back()"><IMG src="../images/images/toolmenu/historyback.gif" width="16" style="vertical-align:middle" height="16" border="0" alt="Back"> Back</SPAN>
    <SPAN class="hmMnuOff" onMouseOver="this.className='hmMnuOn'" onMouseOut="this.className='hmMnuOff'" onClick="location.reload(true)"><IMG src="../images/images/toolmenu/locationreload.gif" width="16" style="vertical-align:middle" height="16" border="0" alt="Refresh"> Refresh</SPAN>
    <SPAN class="hmMnuOff" onMouseOver="this.className='hmMnuOn'" onMouseOut="this.className='hmMnuOff'" onClick="window.print()"><IMG src="../images/images/toolmenu/windowprint.gif" width="16" height="16" style="vertical-align:middle" border="0" alt="Print"> Print</SPAN>
  </DIV></DIV>
<% if (gu_contact.length()>0) { %>
  <TABLE CELLSPACING="2" CELLPADDING="2">
    <TR><TD COLSPAN="10"><IMG SRC="../images/images/spacer.gif" HEIGHT="4"></TD></TR>
    <TR><TD COLSPAN="10" BACKGROUND="../images/images/loginfoot_med.gif" HEIGHT="3"></TD></TR>
    <TR>
      <TD VALIGN="middle"><IMG SRC="../images/images/theworld16.gif" WIDTH="16" HEIGHT="16" BORDER="0"></TD>
      <TD VALIGN="middle"><A HREF="javascript:viewAddrs()" CLASS="linkplain">Addresses</A></TD>
      <TD VALIGN="middle"><IMG SRC="../images/images/note16x16.gif" WIDTH="15" HEIGHT="18" BORDER="0"></TD>
      <TD VALIGN="middle"><A HREF="javascript:viewNotes()" CLASS="linkplain">Notes</A></TD>
      <TD VALIGN="middle"><IMG SRC="../images/images/attachedfile16x16.gif" WIDTH="21" HEIGHT="17" BORDER="0"></TD>
      <TD VALIGN="middle"><A HREF="javascript:viewAttachments()" CLASS="linkplain">Attached Files</A></TD>
      <TD VALIGN="middle"><IMG SRC="../images/images/training/student16.gif" WIDTH="15" HEIGHT="18" BORDER="0"></TD>
      <TD VALIGN="middle"><A HREF="#" onclick="viewCourses()" CLASS="linkplain">Courses</A></TD>
<% if (((iAppMask & (1<<CollaborativeTools))!=0) && (gu_contact.length()>0)) { %>
      <TD VALIGN="middle"><IMG SRC="../images/images/addrbook/telephone16.gif" WIDTH="16" HEIGHT="16" BORDER="0"></TD>
      <TD VALIGN="middle"><A HREF="#" onclick="window.opener.top.location.href='../addrbook/phonecall_listing.jsp?selected=1&subselected=5&field=<%=DB.gu_contact%>&find=<%=gu_contact%>&contact_person=<%=Gadgets.URLEncode(oCont.getStringNull(DB.tx_name,"") + " " + oCont.getStringNull(DB.tx_surname,""))%>'; window.opener.top.focus()" CLASS="linkplain">Calls</A></TD>
<% } else { %>
      <TD COLSPAN="2"></TD>
<% } %>
    </TR>
    <TR>
      <TD VALIGN="middle"><IMG SRC="../images/images/training/diploma16.gif" WIDTH="16" HEIGHT="16" BORDER="0"></TD>
      <TD VALIGN="middle"><A HREF="contact_education_listing.jsp?gu_contact=<%=oCont.getString(DB.gu_contact)%>&fullname=<%=Gadgets.URLEncode(oCont.getStringNull(DB.tx_name,"") + " " + oCont.getStringNull(DB.tx_surname,""))%>" CLASS="linkplain">Qualifications</A></TD>
      <TD COLSPAN="8"></TD>
    </TR>
    <TR><TD COLSPAN="10" BACKGROUND="../images/images/loginfoot_med.gif" HEIGHT="3"></TD></TR>
  </TABLE>
<% } else { out.write("<BR><BR>"); } // fi (gu_contact) %>
  
  <DIV style="background-color:transparent; position: relative;width:600px;height:446px">
  <DIV id="p1panel0" class="panel" style="background-color:#eee;z-index:2">
    <INPUT TYPE="hidden" NAME="id_domain" VALUE="<%=id_domain%>">
    <INPUT TYPE="hidden" NAME="n_domain" VALUE="<%=n_domain%>">
    <INPUT TYPE="hidden" NAME="gu_writer" VALUE="<%=id_user%>">    
    <INPUT TYPE="hidden" NAME="gu_workarea" VALUE="<%=gu_workarea%>">
    <INPUT TYPE="hidden" NAME="gu_contact" VALUE="<%=gu_contact%>">
    <INPUT TYPE="hidden" NAME="nm_company" VALUE="<%=nm_company%>">    
    <INPUT TYPE="hidden" NAME="nu_notes" VALUE="<%=oCont.get(DB.nu_notes)!=null ? String.valueOf(oCont.getInt(DB.nu_notes)) : "0" %>">
    <INPUT TYPE="hidden" NAME="nu_attachs" VALUE="<%=oCont.get(DB.nu_attachs)!=null ? String.valueOf(oCont.getInt(DB.nu_attachs)) : "0" %>">    
    <INPUT TYPE="hidden" NAME="noreload" VALUE="<%=nullif(request.getParameter("noreload"),"0")%>">
    <INPUT TYPE="hidden" NAME="tx_division" MAXLENGTH="32" VALUE="<%=oCont.getStringNull(DB.tx_division,"")%>">
    <INPUT TYPE="hidden" NAME="tx_dept" SIZE="20" MAXLENGTH="32" VALUE="<%=oCont.getStringNull(DB.tx_dept,"")%>">
    <INPUT TYPE="hidden" NAME="gu_geozone" VALUE="<%=oCont.getStringNull(DB.gu_geozone,"")%>">
    <INPUT TYPE="hidden" NAME="nm_geozone" SIZE="40" VALUE="<%=oTerm.getStringNull(DB.tx_term,"")%>">
    <SELECT NAME="sel_geozone" STYLE="visibility:hidden"><% out.write (sTerms); %></SELECT>
    <INPUT TYPE="hidden" NAME="gu_geozone" VALUE="<%=oCont.getStringNull(DB.gu_geozone,"")%>">
    <INPUT TYPE="hidden" NAME="nm_geozone" SIZE="40" VALUE="<%=oTerm.getStringNull(DB.tx_term,"")%>">
    <INPUT TYPE="hidden" NAME="id_batch" VALUE="<%=oCont.getStringNull("id_batch","")%>">
    <INPUT TYPE="hidden" NAME="tx_nickname" VALUE="<%=oCont.getStringNull(DB.tx_nickname,"")%>">
    <INPUT TYPE="hidden" NAME="tx_pwd" VALUE="<%=oCont.getStringNull(DB.tx_pwd,"")%>">

    <TABLE WIDTH="100%">
      <TR><TD>
        <TABLE ALIGN="center">
          <TR>
            <TD ALIGN="right" WIDTH="110"><FONT CLASS="formstrong">Private:</FONT></TD>
            <TD ALIGN="left" WIDTH="370">
              <INPUT TYPE="hidden" NAME="bo_private" VALUE="<%=(sPrivate.length()>0 ? "1" : "0")%>">
              <INPUT TYPE="checkbox" NAME="chk_private" VALUE="1" <%=sPrivate%>>
            </TD>
          </TR>
          <TR>
            <TD ALIGN="right" WIDTH="110"><FONT CLASS="formstrong">Registration:</FONT></TD>
            <TD ALIGN="left" WIDTH="370">
              <INPUT TYPE="text" NAME="id_ref" MAXLENGTH="50" SIZE="20" VALUE="<%=oCont.getStringNull(DB.id_ref,"")%>">
            </TD>
          </TR>
          <TR>
            <TD ALIGN="right" WIDTH="110"><FONT CLASS="formstrong">Name:</FONT></TD>
            <TD ALIGN="left" WIDTH="420"><INPUT TYPE="text" NAME="tx_name" MAXLENGTH="50" SIZE="32" VALUE="<%=oCont.getStringNull(DB.tx_name,"")%>"></TD>
          </TR>
          <TR>
            <TD ALIGN="right" WIDTH="110"><FONT CLASS="formstrong">Surname:</FONT></TD>
            <TD ALIGN="left" WIDTH="420"><INPUT TYPE="text" NAME="tx_surname" MAXLENGTH="50" SIZE="32" VALUE="<%=oCont.getStringNull(DB.tx_surname,"")%>"></TD>
          </TR>
          <TR>
            <TD ALIGN="right" WIDTH="110"><FONT CLASS="formplain">Type:</FONT></TD>
            <TD ALIGN="left" WIDTH="420">
              <SELECT CLASS="combomini" NAME="sel_title"><OPTION VALUE=""></OPTION><%=sTitleLookUp%></SELECT>&nbsp;<A HREF="javascript:lookup(1)"><IMG SRC="../images/images/find16.gif" HEIGHT="16" BORDER="0" ALT="View employments list"></A>
              <INPUT TYPE="hidden" NAME="de_title" VALUE="<%=oCont.getStringNull(DB.de_title,"")%>">
            </TD>
          </TR>
          <TR>
            <TD ALIGN="right" WIDTH="110"><FONT CLASS="formplain">Location:</FONT></TD>            
            <TD ALIGN="left" WIDTH="420">
            <SELECT CLASS="combomini" NAME="sel_company">
            <OPTION VALUE=""></OPTION>
<%             
	      for (int i=0; i<iCompanyCount; i++)
	  	{            		
            		sCompId = oContanies.getString(0,i);
            		sCompDe = oContanies.getStringNull(1,i,"");
            		out.write ("<OPTION VALUE=\"" + sCompId + "\">" + sCompDe  + "</OPTION>" );            	       
               }             
%>
            </SELECT>
            <INPUT TYPE="hidden" NAME="gu_company" VALUE="<%=oCont.getStringNull(DB.gu_company,"")%>">            
            </TD>
          </TR>
          <TR>
            <TD ALIGN="right" WIDTH="110"><FONT CLASS="formplain">Gender:</FONT></TD>
            <TD ALIGN="left" WIDTH="420">
              <SELECT CLASS="combomini" NAME="sel_gender"><OPTION VALUE=""></OPTION><OPTION VALUE="M">M</OPTION><OPTION VALUE="F">F</OPTION></SELECT>
              <INPUT TYPE="hidden" NAME="id_gender" VALUE="<%=oCont.getStringNull(DB.id_gender,"")%>">
              &nbsp;&nbsp;<FONT CLASS="formplain">Status:</FONT>&nbsp;
              <SELECT CLASS="combomini" NAME="sel_status"><OPTION VALUE=""></OPTION><%=sStatusLookUp%></SELECT>&nbsp;<A HREF="javascript:lookup(2)"><IMG SRC="../images/images/find16.gif" HEIGHT="16" BORDER="0" ALT="View list  of status"></A>
              <INPUT TYPE="hidden" NAME="id_status" VALUE="<%=oCont.getStringNull(DB.id_status,"")%>">              
            </TD>
          </TR>                              
          <TR>
            <TD ALIGN="right" WIDTH="110"><FONT CLASS="formplain">Birth Date:</FONT></TD>
            <TD ALIGN="left" WIDTH="420">
              <INPUT TYPE="text" NAME="dt_birth" MAXLENGTH="10" SIZE="10" VALUE="<%=oCont.get(DB.dt_birth)!=null ? oCont.getDateFormated(DB.dt_birth,"yyyy-MM-dd") : ""%>">
              <A HREF="javascript:showCalendar('dt_birth')"><IMG SRC="../images/images/datetime16.gif" WIDTH="16" HEIGHT="16" BORDER="0" ALT="View Calendar"></A>
	      &nbsp;&nbsp;&nbsp;
	      <FONT CLASS="formplain">Age:</FONT>
	      &nbsp;
              <INPUT TYPE="text" NAME="ny_age" MAXLENGTH="3" SIZE="3" VALUE="<% if (oCont.get(DB.ny_age)!=null) out.write(String.valueOf(oCont.getInt(DB.ny_age)));%>">
            </TD>
          </TR>                              
          <TR>
            <TD ALIGN="right" WIDTH="110"><FONT CLASS="formplain">Identity Doc.</FONT></TD>
            <TD ALIGN="left" WIDTH="420">
              <INPUT TYPE="text" NAME="sn_passport" SIZE="10" MAXLENGTH="16" VALUE="<%=oCont.getStringNull(DB.sn_passport,"")%>">&nbsp;
              <SELECT CLASS="combomini" NAME="sel_passport"><OPTION VALUE=""></OPTION><%=sPassportLookUp%></SELECT>&nbsp;<A HREF="javascript:lookup(3)"><IMG SRC="../images/images/find16.gif" HEIGHT="16" BORDER="0" ALT="View list of identity document types"></A>
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
            <TD ALIGN="right" WIDTH="110"><FONT CLASS="formplain">Salesman:</FONT></TD>
            <TD ALIGN="left" WIDTH="370">
            <INPUT TYPE="hidden" NAME="gu_sales_man" VALUE="<%=oCont.getStringNull(DB.gu_sales_man,"")%>">
            <SELECT NAME="sel_salesman"><OPTION VALUE=""></OPTION><% for (int s=0; s<iSalesMen; s++) out.write ("<OPTION VALUE=\""+oSalesMen.getString(0,s)+"\">"+oSalesMen.getStringNull(1,s,"")+" "+oSalesMen.getStringNull(2,s,"")+" "+oSalesMen.getStringNull(3,s,"")+"</OPTION>"); %></SELECT>
            </TD>
          </TR>
          <TR>
            <TD ALIGN="right" WIDTH="110"><FONT CLASS="formplain">Comments:</FONT></TD>
            <TD ALIGN="left" WIDTH="420"><TEXTAREA NAME="tx_comments" ROWS="3" COLS="44"><%=oCont.getStringNull(DB.tx_comments,"")%></TEXTAREA></TD>
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
</BODY>
</HTML>
<%
if (null!=oConn) oConn.close("contact_edit");
oConn=null;
%>
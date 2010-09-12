<FORM NAME="" METHOD="post" ACTION="cv_contact_education_store.jsp" onSubmit="return validate()">
    <INPUT TYPE="hidden" NAME="gu_workarea" VALUE="<%=gu_workarea%>">
    <INPUT TYPE="hidden" NAME="gu_contact" VALUE="<%=gu_contact%>">
    <INPUT TYPE="hidden" NAME="gu_writer" VALUE="<%=id_user%>">
    <INPUT TYPE="hidden" NAME="tx_fullname" VALUE="<%=sFullName%>">

    <TABLE>
      <TR><TD>
        <TABLE WIDTH="100%">
          <TR>
            <TD ALIGN="right" WIDTH="90"><FONT CLASS="formplain">Degree</FONT></TD>
            <TD ALIGN="left" WIDTH="480">
              <SELECT NAME="gu_degree"><OPTION VALUE=""></OPTION><%=sTypeLookUp%></SELECT>&nbsp;
              <A HREF="../training/degree_lookup.jsp"><IMG SRC="../images/images/find16.gif" HEIGHT="16" BORDER="0" ALT="Edit Degrees"></A>
            </TD>
          </TR>
          <TR>
            <TD ALIGN="right" WIDTH="90" CLASS="formplain">Completed</TD>
            <TD ALIGN="left" WIDTH="480" CLASS="formplain">
            	<INPUT TYPE="radio" NAME="bo_completed" VALUE="1" CHECKED="checked">&nbsp;Yes&nbsp;&nbsp;&nbsp;<INPUT TYPE="radio" NAME="bo_completed" VALUE="0">&nbsp;No
            </TD>
          </TR>
          <TR>
            <TD ALIGN="right" WIDTH="90"><FONT CLASS="formplain">Institution</FONT></TD>
            <TD ALIGN="left" WIDTH="480">
              <SELECT NAME="gu_institution"><OPTION VALUE=""></OPTION><% for (int n=0; n<iInstitutions; n++) out.write("<OPTION VALUE=\""+oInstitutions.getString(0,n)+"\">"+oInstitutions.getString(1,n)+"</OPTION>"); %></SELECT>&nbsp;
              <A HREF="../training/institutions_lookup.jsp"><IMG SRC="../images/images/find16.gif" HEIGHT="16" BORDER="0" ALT="Edit Institutions"></A>
            </TD>
          </TR>
          <TR>
            <TD ALIGN="right" WIDTH="90" CLASS="formplain">Center</FONT></TD>
            <TD ALIGN="left" WIDTH="480"><INPUT TYPE="text" NAME="nm_center" MAXLENGTH="50" SIZE="40" VALUE="<% out.write(oObj.getStringNull("nm_center","")); %>"></TD>
          </TR>
          <TR>
            <TD ALIGN="right" WIDTH="90" CLASS="formplain">From</TD>
            <TD ALIGN="left" WIDTH="480" CLASS="formplain"><INPUT TYPE="text" NAME="tx_dt_from" MAXLENGTH="30" SIZE="10" VALUE="<% out.write(oObj.getStringNull("tx_dt_from","")); %>">&nbsp;&nbsp;&nbsp;To&nbsp;<INPUT TYPE="text" NAME="tx_dt_to" MAXLENGTH="30" SIZE="10" VALUE="<% out.write(oObj.getStringNull("tx_dt_to","")); %>"></TD>
          </TR>
          <TR>
            <TD ALIGN="right" WIDTH="90"><FONT CLASS="formplain">Average Grade</FONT></TD>
            <TD ALIGN="left" WIDTH="480"><INPUT TYPE="text" NAME="lv_degree" MAXLENGTH="6" SIZE="6" VALUE="<% out.write(oObj.getStringNull("lv_degree","")); %>"></TD>
          </TR>
          <TR>
            <TD COLSPAN="2"><HR></TD>
          </TR>
          <TR>
    	    <TD COLSPAN="2" ALIGN="center">
              <INPUT TYPE="submit" ACCESSKEY="s" VALUE="Save" CLASS="pushbutton" STYLE="width:80" TITLE="ALT+s">&nbsp;
    	      &nbsp;&nbsp;<INPUT TYPE="button" ACCESSKEY="c" VALUE="Cancel" CLASS="closebutton" STYLE="width:80" TITLE="ALT+c" onClick="cancelar(1)">
    	      <BR><BR>
    	    </TD>
    	  </TR>            
        </TABLE>
          <TABLE SUMMARY="Degrees" CELLSPACING="1" CELLPADDING="0" width="100%">
        <TR>

          <TD CLASS="tableheader" BACKGROUND="../skins/<%=sSkin%>/tablehead.gif"></TD>
          <TD CLASS="tableheader" BACKGROUND="../skins/<%=sSkin%>/tablehead.gif"><B>Degree</B></TD>
          <TD CLASS="tableheader" BACKGROUND="../skins/<%=sSkin%>/tablehead.gif"><B>Institution</B></TD>
          <TD CLASS="tableheader" BACKGROUND="../skins/<%=sSkin%>/tablehead.gif"><B>Center</B></TD>
          <TD CLASS="tableheader" BACKGROUND="../skins/<%=sSkin%>/tablehead.gif"><B>Dates</B></TD>
<% if (!bIsGuest) { %>
          <TD CLASS="tableheader" BACKGROUND="../skins/<%=sSkin%>/tablehead.gif"><IMG SRC="../images/images/papelera.gif" BORDER="0" ALT="DELETE"></TD>
<% } %>
        </TR>
<%

    for (int d=0; d<iDegrees; d++) {
            
      String sStrip = String.valueOf((d%2)+1);
%>
            <TR HEIGHT="14">
              <TD CLASS="strip<% out.write (sStrip); %>"><A HREF="#" onclick="viewAttachments()" TITLE="Attach Files"><IMG SRC="../images/images/attachedfile16x16.gif" WIDTH="21" HEIGHT="17" BORDER="0" ALT="Attach Files" /></A></TD>
              <TD CLASS="strip<% out.write (sStrip); %>">&nbsp;<A HREF="cv_contact_edit.jsp?gu_workarea=<%=gu_workarea%>&gu_contact=<%=gu_contact%>&gu_degree=<%=oDegrees.getString(1,d)%>&fullname=<%=Gadgets.URLEncode(sFullName)%>&selectTab=1" CLASS="linkplain"><%=oDegrees.getStringNull(4,d,"")%>&nbsp;<%=oDegrees.getStringNull(5,d,"")%></A></TD>
              <TD CLASS="strip<% out.write (sStrip); %>">&nbsp;<%=oDegrees.getStringNull(10,d,"")%></TD>
              <TD CLASS="strip<% out.write (sStrip); %>">&nbsp;<%=oDegrees.getStringNull(11,d,"")%></TD>
              <TD CLASS="strip<% out.write (sStrip); %>">&nbsp;<%=oDegrees.getStringNull(12,d,"")+" "+oDegrees.getStringNull(13,d,"")%></TD>
<% if (!bIsGuest) { %>
              <TD CLASS="strip<% out.write (sStrip); %>" ALIGN="center">&nbsp;<A HREF="#" onclick="deleteEducation('<%=gu_workarea%>','<%=gu_contact%>','<%=oDegrees.getString(1,d)%>','<%=Gadgets.URLEncode(sFullName)%>');" CLASS="linkplain"><IMG SRC="../images/images/delete.gif" WIDTH="13" HEIGHT="13" BORDER="0" ALT="Delete academic degree" /></A></TD>
<% } %>
            </TR>
<%        } // next %>
      </TABLE>
      </TD></TR>
    </TABLE>                 
  </FORM>
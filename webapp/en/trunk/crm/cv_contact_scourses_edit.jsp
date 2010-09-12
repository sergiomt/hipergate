<FORM NAME="" METHOD="post" ACTION="cv_contact_scourses_store.jsp" onSubmit="return validate()">
    		<INPUT TYPE="hidden" NAME="gu_workarea" VALUE="<%=gu_workarea%>">
    		<INPUT TYPE="hidden" NAME="gu_contact" VALUE="<%=gu_contact%>">
    		<INPUT TYPE="hidden" NAME="gu_writer" VALUE="<%=id_user%>">
    		<INPUT TYPE="hidden" NAME="gu_scourse" VALUE="<%=nullif(gu_scourse)%>">
    		<INPUT TYPE="hidden" NAME="tx_fullname" VALUE="<%=sFullName%>">
    		<TABLE >
    			<TR><TD>
        			<TABLE WIDTH="100%">
        				<TR>
            				<TD ALIGN="right" WIDTH="90" CLASS="formplain">Course Name</TD>
            				<TD ALIGN="left" WIDTH="480"><INPUT TYPE="text" NAME="nm_scourse" MAXLENGTH="50" SIZE="40" VALUE="<% out.write(oObj2.getStringNull("nm_scourse","")); %>"></TD>
          				</TR>
          				<TR>
            				<TD ALIGN="right" WIDTH="90" CLASS="formplain">Center</TD>
            				<TD ALIGN="left" WIDTH="480"><INPUT TYPE="text" NAME="nm_center" MAXLENGTH="50" SIZE="40" VALUE="<% out.write(oObj2.getStringNull("nm_center","")); %>"></TD>
          				</TR>
						<TR>
            				<TD ALIGN="right" WIDTH="90" CLASS="formplain">From</TD>
            				<TD ALIGN="left" WIDTH="480" CLASS="formplain"><INPUT TYPE="text" NAME="tx_dt_from" MAXLENGTH="30" SIZE="10" VALUE="<% out.write(oObj2.getStringNull("tx_dt_from","")); %>">&nbsp;&nbsp;&nbsp;To&nbsp;<INPUT TYPE="text" NAME="tx_dt_to" MAXLENGTH="30" SIZE="10" VALUE="<% out.write(oObj2.getStringNull("tx_dt_to","")); %>"></TD>
          				</TR>
          				<TR>
            				<TD ALIGN="right" WIDTH="90"><FONT CLASS="formplain">Average Grade</FONT></TD>
            				<TD ALIGN="left" WIDTH="480"><INPUT TYPE="text" NAME="lv_scourse" MAXLENGTH="6" SIZE="6" VALUE="<%out.write(oObj2.getStringNull("lv_scourse",""));%>"></TD>
          				</TR>
          				<TR>
            				<TD ALIGN="right" WIDTH="90"><FONT CLASS="formplain">Credits</FONT></TD>
            				<TD ALIGN="left" WIDTH="370"><INPUT TYPE="text" NAME="nu_credits" MAXLENGTH="9" SIZE="9" VALUE="<% if (!oObj2.isNull("nu_credits")) out.write(String.valueOf(oObj2.getInt("nu_credits"))); %>" onkeypress="return acceptOnlyNumbers();"></TD>
          				</TR>
          				<TR>
            				<TD COLSPAN="2"><HR></TD>
          				</TR>
          				<TR>
    		    			<TD COLSPAN="2" ALIGN="center">
            	  				<INPUT TYPE="submit" ACCESSKEY="s" VALUE="Save" CLASS="pushbutton" STYLE="width:80" TITLE="ALT+s">&nbsp;
    	      					&nbsp;&nbsp;<INPUT TYPE="button" ACCESSKEY="c" VALUE="Cancel" CLASS="closebutton" STYLE="width:80" TITLE="ALT+c" onclick="cancelar(2)">
    	      					<BR><BR>
    	    				</TD>
    	 				</TR>            
        			</TABLE>
          			<TABLE SUMMARY="Short Courses" CELLSPACING="1" CELLPADDING="0" width="100%">
        			<TR>
						<TD CLASS="tableheader" BACKGROUND="../skins/<%=sSkin%>/tablehead.gif"></TD>
			          	<TD CLASS="tableheader" BACKGROUND="../skins/<%=sSkin%>/tablehead.gif"><B>Course Name</B></TD>
			          	<TD CLASS="tableheader" BACKGROUND="../skins/<%=sSkin%>/tablehead.gif"><B>Center</B></TD>
			          	<TD CLASS="tableheader" BACKGROUND="../skins/<%=sSkin%>/tablehead.gif"><B>Dates</B></TD>
			          	<TD CLASS="tableheader" BACKGROUND="../skins/<%=sSkin%>/tablehead.gif"><B>Credits</B></TD>
						<% if (!bIsGuest) { %>
						          <TD CLASS="tableheader" BACKGROUND="../skins/<%=sSkin%>/tablehead.gif"><IMG SRC="../images/images/papelera.gif" BORDER="0" ALT="DELETE"></TD>
						<% } %>
    			    </TR>
						<%for (int d=0; d<iShortCourses; d++) {
            				String sStrip = String.valueOf((d%2)+1);
						%>
            		<TR HEIGHT="14">
		              <TD CLASS="strip<% out.write (sStrip); %>"><A HREF="#" onclick="viewAttachments()" TITLE="Attach file"><IMG SRC="../images/images/attachedfile16x16.gif" WIDTH="21" HEIGHT="17" BORDER="0" ALT="Attach file" /></A></TD>
		              <TD CLASS="strip<% out.write (sStrip); %>">&nbsp;<A HREF="cv_contact_edit.jsp?gu_workarea=<%=gu_workarea%>&gu_contact=<%=gu_contact%>&gu_scourse=<%=oShortCourses.getString(1,d)%>&fullname=<%=Gadgets.URLEncode(sFullName)%>&selectTab=2" CLASS="linkplain"><%=oShortCourses.getStringNull(2,d,"")%></A></TD>
		              <TD CLASS="strip<% out.write (sStrip); %>">&nbsp;<%=oShortCourses.getStringNull(4,d,"")%></TD>
		              <TD CLASS="strip<% out.write (sStrip); %>">&nbsp;<%=oShortCourses.getStringNull(7,d,"")+" "+oShortCourses.getStringNull(8,d,"")%></TD>
		              <TD CLASS="strip<% out.write (sStrip); %>">&nbsp;<%=oShortCourses.getStringNull(9,d,"")%></TD>
				<% if (!bIsGuest) { %>
              		 <TD CLASS="strip<% out.write (sStrip); %>" ALIGN="center">&nbsp;<A HREF="#" onclick="deleteShortCourse('<%=gu_workarea%>','<%=gu_contact%>','<%=oShortCourses.getString(1,d)%>','<%=Gadgets.URLEncode(sFullName)%>');" CLASS="linkplain"><IMG SRC="../images/images/delete.gif" WIDTH="13" HEIGHT="13" BORDER="0" ALT="Delete unofficial degree" /></A></TD>
				<% } %>
            		</TR>
						<%        } // next %>
      </TABLE>
      </TD></TR>
    	</TABLE>
   	</FORM>
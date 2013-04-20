<FORM NAME="" METHOD="post" ACTION="cv_contact_experience_store.jsp" onSubmit="return validateExperience()">
    		<INPUT TYPE="hidden" NAME="gu_workarea" VALUE="<%=gu_workarea%>">
    		<INPUT TYPE="hidden" NAME="gu_contact" VALUE="<%=gu_contact%>">
    		<INPUT TYPE="hidden" NAME="gu_writer" VALUE="<%=id_user%>">
    		<INPUT TYPE="hidden" NAME="tx_fullname" VALUE="<%=sFullName%>">
    		<INPUT TYPE="hidden" NAME="gu_experience" VALUE="<%=nullif(gu_experience)%>">
    		
    		<TABLE >
    			<TR><TD>
        			<TABLE WIDTH="100%" >
        				<TR>
            	            <TD ALIGN="right" WIDTH="90" CLASS="formplain">Company</TD>
				            <TD ALIGN="left" WIDTH="480"><INPUT TYPE="text" NAME="nm_company" MAXLENGTH="50" SIZE="40" VALUE="<%= oContactEx.getStringNull("nm_company","")%>"></TD>
          				</TR>
          				<TR>
          					<TD ALIGN="right" WIDTH="90" CLASS="formplain">Current</TD>
            				<TD ALIGN="left" WIDTH="480" CLASS="formplain">
            					<INPUT TYPE="radio" NAME="bo_current_job" VALUE="1" CHECKED="checked">&nbsp;Yes&nbsp;&nbsp;&nbsp;<INPUT TYPE="radio" NAME="bo_current_job" VALUE="0">&nbsp;No
            				</TD>
          				</TR>
          				<TR>
            				<TD ALIGN="right" WIDTH="140"><FONT CLASS="formplain">Company Activity</FONT></TD>
            				<TD ALIGN="left" WIDTH="460">
              					<INPUT TYPE="hidden" NAME="id_sector" VALUE="<%=oContactEx.getStringNull(DB.id_sector,"")%>">&nbsp;
              					<SELECT NAME="sel_id_sector"><OPTION VALUE=""></OPTION><% out.write(sIdSectorLookUp); %></SELECT>&nbsp;
              					<A HREF="javascript:lookup(4)"><IMG SRC="../images/images/find16.gif" HEIGHT="16" BORDER="0" ALT="Show company activities"></A>
            				</TD>
          				</TR>
          				<TR>
            				<TD ALIGN="right" WIDTH="140"><FONT CLASS="formplain">Position</FONT></TD>
            				<TD ALIGN="left" WIDTH="460">
              					<INPUT TYPE="hidden" NAME="de_title" VALUE="<%=oContactEx.getStringNull(DB.de_title,"")%>">&nbsp;
              					<SELECT NAME="sel_de_title"><OPTION VALUE=""></OPTION><% out.write(sDeTitleLookUp); %></SELECT>&nbsp;
              					<A HREF="javascript:lookup(5)"><IMG SRC="../images/images/find16.gif" HEIGHT="16" BORDER="0" ALT="Show Positions"></A>
            				</TD>
          				</TR>
          				<TR>
            				<TD ALIGN="right" WIDTH="90" CLASS="formplain">From</TD>
            				<TD ALIGN="left" WIDTH="480" CLASS="formplain"><INPUT TYPE="text" NAME="tx_dt_from" MAXLENGTH="30" SIZE="10" VALUE="<%=oContactEx.getStringNull("tx_dt_from","") %>">&nbsp;&nbsp;&nbsp;To&nbsp;<INPUT TYPE="text" NAME="tx_dt_to" MAXLENGTH="30" SIZE="10" VALUE="<%=oContactEx.getStringNull("tx_dt_to","")%>"></TD>
          				</TR>
          				<TR>
            	            <TD ALIGN="right" WIDTH="90" CLASS="formplain">Contact Person</TD>
				            <TD ALIGN="left" WIDTH="480"><INPUT TYPE="text" NAME="contact_person" MAXLENGTH="50" SIZE="40" VALUE="<%= oContactEx.getStringNull("contact_person","")%>"></TD>
          				</TR>
          				<TR>
            				<TD ALIGN="right" WIDTH="90">Comments</TD>
            				<TD ALIGN="left" WIDTH="370"><TEXTAREA NAME="tx_comments" cols="50"><%=oContactEx.getStringNull("tx_comments","")%></TEXTAREA></TD>
          				</TR>
          				<TR>
            				<TD COLSPAN="2"><HR></TD>
          				</TR>
          				<TR>
    		    			<TD COLSPAN="2" ALIGN="center">
            	  				<INPUT TYPE="submit" ACCESSKEY="s" VALUE="Save" CLASS="pushbutton" STYLE="width:80" TITLE="ALT+s">&nbsp;
    	      					&nbsp;&nbsp;<INPUT TYPE="button" ACCESSKEY="c" VALUE="Cancel" CLASS="closebutton" STYLE="width:80" TITLE="ALT+c" onclick="cancelar(5)">
    	      					<BR><BR>
    	    				</TD>
    	 				</TR>            
        			</TABLE>
          			<TABLE SUMMARY="Languages" CELLSPACING="1" CELLPADDING="0" width="100%">
        			<TR>
						<TD CLASS="tableheader" BACKGROUND="../skins/<%=sSkin%>/tablehead.gif"></TD>
			          	<TD CLASS="tableheader" BACKGROUND="../skins/<%=sSkin%>/tablehead.gif"><B>Company</B></TD>
			          	<TD CLASS="tableheader" BACKGROUND="../skins/<%=sSkin%>/tablehead.gif"><B>Position</B></TD>
			          	<TD CLASS="tableheader" BACKGROUND="../skins/<%=sSkin%>/tablehead.gif"><B>Dates</B></TD>
						<% if (!bIsGuest) { %>
						          <TD CLASS="tableheader" BACKGROUND="../skins/<%=sSkin%>/tablehead.gif"><IMG SRC="../images/images/papelera.gif" BORDER="0" ALT="DELETE"></TD>
						<% } %>
    			    </TR>
						<%for (int d=0; d < iContactExperience; d++) {
            				String sStrip = String.valueOf((d%2)+1);
						%>
            		<TR HEIGHT="14">
		              <TD CLASS="strip<% out.write (sStrip); %>"><A HREF="#" onclick="viewAttachments()" TITLE="Attach Files"><IMG SRC="../images/images/attachedfile16x16.gif" WIDTH="21" HEIGHT="17" BORDER="0" ALT="Attach Files" /></A></TD><!-- // -->
		              <TD CLASS="strip<% out.write (sStrip); %>">&nbsp;<A HREF="cv_contact_edit.jsp?gu_workarea=<%=gu_workarea%>&gu_contact=<%=gu_contact%>&gu_experience=<%=oContactExperience.getString(0,d)%>&fullname=<%=Gadgets.URLEncode(sFullName)%>&selectTab=5" CLASS="linkplain"><%=oContactExperience.getString(2,d)%></A></TD>
		              <TD CLASS="strip<% out.write (sStrip); %>">&nbsp;<%=oDeTitleLookUp.get(oContactExperience.getString(5,d))%></TD>
		              <TD CLASS="strip<% out.write (sStrip); %>">&nbsp;<%=oContactExperience.getStringNull(6,d,"")+" "+oContactExperience.getStringNull(7,d,"")%></TD>
				<% if (!bIsGuest) { %>
              		 <TD CLASS="strip<% out.write (sStrip); %>" ALIGN="center">&nbsp;<A HREF="#" onclick="deleteExperience('<%=gu_workarea%>','<%=gu_contact%>','<%=oContactExperience.getString(0,d)%>','<%=Gadgets.URLEncode(sFullName)%>');" CLASS="linkplain"><IMG SRC="../images/images/delete.gif" WIDTH="13" HEIGHT="13" BORDER="0" ALT="Delete experience" /></A></TD>
				<% } %>
            		</TR>
						<%        } // next %>
      </TABLE>
      </TD></TR>
    	</TABLE>
   	</FORM>
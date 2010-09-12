<FORM NAME="" METHOD="post" ACTION="cv_contact_computer_science_store.jsp" onSubmit="return validateComputerScience()">
    		<INPUT TYPE="hidden" NAME="gu_workarea" VALUE="<%=gu_workarea%>">
    		<INPUT TYPE="hidden" NAME="gu_contact" VALUE="<%=gu_contact%>">
    		<INPUT TYPE="hidden" NAME="gu_writer" VALUE="<%=id_user%>">
    		<INPUT TYPE="hidden" NAME="gu_ccsskill" VALUE="<%=nullif(gu_ccsskill)%>">
    		<INPUT TYPE="hidden" NAME="tx_fullname" VALUE="<%=sFullName%>">
    		<TABLE>
    			<TR><TD>
        			<TABLE WIDTH="100%" >
        				<TR>
            				<TD ALIGN="right" WIDTH="140"><FONT CLASS="formplain">Computer Science Skills</FONT></TD>
            				<TD ALIGN="left" WIDTH="460">
              					<INPUT TYPE="hidden" NAME="nm_skill" VALUE="<%=oContactCS.getStringNull(DB.nm_skill,"")%>">&nbsp;
              					<SELECT NAME="sel_nm_skill"><OPTION VALUE=""></OPTION><% out.write(sNmSkillLookUp); %></SELECT>&nbsp;
              					<A HREF="javascript:lookup(1)"><IMG SRC="../images/images/find16.gif" HEIGHT="16" BORDER="0" ALT="Show Computer Science Skills"></A>
            				</TD>
          				</TR>
          				<TR>
            				<TD ALIGN="right" WIDTH="140"><FONT CLASS="formplain">Level</FONT></TD>
            				<TD ALIGN="left" WIDTH="460">
              					<INPUT TYPE="hidden" NAME="lv_skill" VALUE="<%=oContactCS.getStringNull(DB.lv_skill,"")%>">&nbsp;
              					<SELECT NAME="sel_lv_skill"><OPTION VALUE=""></OPTION><% out.write(sLvSkillLookUp); %></SELECT>&nbsp;
              					<A HREF="javascript:lookup(2)"><IMG SRC="../images/images/find16.gif" HEIGHT="16" BORDER="0" ALT="Show Levels"></A>
            				</TD>
          				</TR>
          				<TR>
            				<TD COLSPAN="2"><HR></TD>
          				</TR>
          				<TR>
    		    			<TD COLSPAN="2" ALIGN="center">
            	  				<INPUT TYPE="submit" ACCESSKEY="s" VALUE="Save" CLASS="pushbutton" STYLE="width:80" TITLE="ALT+s">&nbsp;
    	      					&nbsp;&nbsp;<INPUT TYPE="button" ACCESSKEY="c" VALUE="Cancel" CLASS="closebutton" STYLE="width:80" TITLE="ALT+c" onclick="cancelar(3)">
    	      					<BR><BR>
    	    				</TD>
    	 				</TR>            
        			</TABLE>
          			<TABLE SUMMARY="Computer Science Skill" CELLSPACING="1" CELLPADDING="0" width="100%">
        			<TR>
						<TD CLASS="tableheader" BACKGROUND="../skins/<%=sSkin%>/tablehead.gif"></TD>
			          	<TD CLASS="tableheader" BACKGROUND="../skins/<%=sSkin%>/tablehead.gif"><B>Computer Science Skills</B></TD>
			          	<TD CLASS="tableheader" BACKGROUND="../skins/<%=sSkin%>/tablehead.gif"><B>Level</B></TD>
						<% if (!bIsGuest) { %>
						          <TD CLASS="tableheader" BACKGROUND="../skins/<%=sSkin%>/tablehead.gif"><IMG SRC="../images/images/papelera.gif" BORDER="0" ALT="DELETE"></TD>
						<% } %>
    			    </TR>
						<%for (int d=0; d < iComputerScienceSkill; d++) {
            				String sStrip = String.valueOf((d%2)+1);
						%>
            		<TR HEIGHT="14">
		              <TD CLASS="strip<% out.write (sStrip); %>"><A HREF="#" onclick="viewAttachments()" TITLE="Attach Files"><IMG SRC="../images/images/attachedfile16x16.gif" WIDTH="21" HEIGHT="17" BORDER="0" ALT="Attach Files" /></A></TD>
		              <TD CLASS="strip<% out.write (sStrip); %>">&nbsp;<A HREF="cv_contact_edit.jsp?gu_workarea=<%=gu_workarea%>&gu_contact=<%=gu_contact%>&gu_ccsskill=<%=oComputerScienceSkill.getString(0,d)%>&fullname=<%=Gadgets.URLEncode(sFullName)%>&selectTab=3" CLASS="linkplain"><%=oNmSkillLookUp.get(oComputerScienceSkill.getString(2,d))%></A></TD>
		              <TD CLASS="strip<% out.write (sStrip); %>">&nbsp;<%=oLvSkillLookUp.get(oComputerScienceSkill.getString(3,d))%></TD>
				<% if (!bIsGuest) { %>
              		 <TD CLASS="strip<% out.write (sStrip); %>" ALIGN="center">&nbsp;<A HREF="#" onclick="deleteComputerScience('<%=gu_workarea%>','<%=gu_contact%>','<%=oComputerScienceSkill.getString(0,d)%>','<%=Gadgets.URLEncode(sFullName)%>');" CLASS="linkplain"><IMG SRC="../images/images/delete.gif" WIDTH="13" HEIGHT="13" BORDER="0" ALT="Delete Computer Science Skill" /></A></TD>
				<% } %>
            		</TR>
						<%        } // next %>
      </TABLE>
      </TD></TR>
    	</TABLE>
   	</FORM>
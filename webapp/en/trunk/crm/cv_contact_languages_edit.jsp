<FORM NAME="" METHOD="post" ACTION="cv_contact_languages_store.jsp" onSubmit="return validateLanguages()">
    		<INPUT TYPE="hidden" NAME="gu_workarea" VALUE="<%=gu_workarea%>">
    		<INPUT TYPE="hidden" NAME="gu_contact" VALUE="<%=gu_contact%>">
    		<INPUT TYPE="hidden" NAME="gu_writer" VALUE="<%=id_user%>">
    		<INPUT TYPE="hidden" NAME="tx_fullname" VALUE="<%=sFullName%>">
    		<TABLE>
    			<TR><TD>
        			<TABLE WIDTH="100%" >
        				<TR>
            				<TD ALIGN="right" WIDTH="140"><FONT CLASS="formplain">Language</FONT></TD>
            				<TD ALIGN="left" WIDTH="460">
              					<INPUT TYPE="hidden" NAME="id_language" VALUE="<%=oContacL.getStringNull(DB.id_language,"").trim()%>">&nbsp;
              					<SELECT NAME="sel_language"><OPTION VALUE=""></OPTION><% out.write(sSelLang); %></SELECT>&nbsp;
            				</TD>
          				</TR>
          				<TR>
            				<TD ALIGN="right" WIDTH="140"><FONT CLASS="formplain">Official Degree</FONT></TD>
            				<TD ALIGN="left" WIDTH="460">
              					<INPUT TYPE="hidden" NAME="lv_language_degree" VALUE="<%=oContacL.getStringNull(DB.lv_language_degree,"")%>">&nbsp;
              					<SELECT NAME="sel_lv_language_degree"><OPTION VALUE=""></OPTION><% out.write(sLvLanguageDegreeLookUp); %></SELECT>&nbsp;
              					<A HREF="javascript:lookup(3)"><IMG SRC="../images/images/find16.gif" HEIGHT="16" BORDER="0" ALT="Show OFficial Degree"></A>
            				</TD>
          				</TR>
          			    <TR>
            				<TD ALIGN="right" WIDTH="140"><FONT CLASS="formplain">Conversation</FONT></TD>
            				<TD ALIGN="left" WIDTH="460">
              					&nbsp;<SELECT NAME="sel_language_spoken"><OPTION VALUE=""></OPTION><OPTION VALUE="1">Basic</OPTION><OPTION VALUE="2">Medium</OPTION><OPTION VALUE="3">Fluid</OPTION><OPTION VALUE="4">Native</OPTION></SELECT>
              					<INPUT TYPE="hidden" NAME="lv_language_spoken" VALUE="<%=oContacL.getStringNull(DB.lv_language_spoken,"")%>">
              			    </TD>
          				</TR>
          				 <TR>
            				<TD ALIGN="right" WIDTH="140"><FONT CLASS="formplain">Written</FONT></TD>
            				<TD ALIGN="left" WIDTH="460">
              					&nbsp;<SELECT NAME="sel_language_written"><OPTION VALUE=""></OPTION><OPTION VALUE="1">Basic</OPTION><OPTION VALUE="2">Medium</OPTION><OPTION VALUE="3">Fluid</OPTION><OPTION VALUE="4">Native</OPTION></SELECT>
              					<INPUT TYPE="hidden" NAME="lv_language_written" VALUE="<%=oContacL.getStringNull(DB.lv_language_written,"")%>">
              			    </TD>
          				</TR>
          				<TR>
            				<TD COLSPAN="2"><HR></TD>
          				</TR>
          				<TR>
    		    			<TD COLSPAN="2" ALIGN="center">
            	  				<INPUT TYPE="submit" ACCESSKEY="s" VALUE="Save" CLASS="pushbutton" STYLE="width:80" TITLE="ALT+s">&nbsp;
    	      					&nbsp;&nbsp;<INPUT TYPE="button" ACCESSKEY="c" VALUE="Cancel" CLASS="closebutton" STYLE="width:80" TITLE="ALT+c" onclick="cancelar(4)">
    	      					<BR><BR>
    	    				</TD>
    	 				</TR>            
        			</TABLE>
          			<TABLE SUMMARY="Languages" CELLSPACING="1" CELLPADDING="0" width="100%">
        			<TR>
						<TD CLASS="tableheader" BACKGROUND="../skins/<%=sSkin%>/tablehead.gif"></TD>
			          	<TD CLASS="tableheader" BACKGROUND="../skins/<%=sSkin%>/tablehead.gif"><B>Language</B></TD>
			          	<TD CLASS="tableheader" BACKGROUND="../skins/<%=sSkin%>/tablehead.gif"><B>Official Degree</B></TD>
						<% if (!bIsGuest) { %>
						          <TD CLASS="tableheader" BACKGROUND="../skins/<%=sSkin%>/tablehead.gif"><IMG SRC="../images/images/papelera.gif" BORDER="0" ALT="DELETE"></TD>
						<% } %>
    			    </TR>
						<%for (int d=0; d < iContactLanguage; d++) {
            				String sStrip = String.valueOf((d%2)+1);
						%>
            		<TR HEIGHT="14">
		              <TD CLASS="strip<% out.write (sStrip); %>"><A HREF="#" onclick="viewAttachments()" TITLE="Attach Files"><IMG SRC="../images/images/attachedfile16x16.gif" WIDTH="21" HEIGHT="17" BORDER="0" ALT="Attach Files" /></A></TD><!-- // -->
		              <TD CLASS="strip<% out.write (sStrip); %>">&nbsp;<A HREF="cv_contact_edit.jsp?gu_workarea=<%=gu_workarea%>&gu_contact=<%=gu_contact%>&id_language=<%=oContactLanguage.getString(1,d)%>&fullname=<%=Gadgets.URLEncode(sFullName)%>&selectTab=4" CLASS="linkplain"><%=oLanguagesLookUp.get(oContactLanguage.getString(1,d))%></A></TD>
		              <TD CLASS="strip<% out.write (sStrip); %>">&nbsp;<%=nullif((String)oLvLanguageDegreeLookUp.get(oContactLanguage.getString(2,d)),"")%></TD>
				<% if (!bIsGuest) { %>
              		 <TD CLASS="strip<% out.write (sStrip); %>" ALIGN="center">&nbsp;<A HREF="#" onclick="deleteLanguage('<%=gu_workarea%>','<%=gu_contact%>','<%=oContactLanguage.getString(1,d)%>','<%=Gadgets.URLEncode(sFullName)%>');" CLASS="linkplain"><IMG SRC="../images/images/delete.gif" WIDTH="13" HEIGHT="13" BORDER="0" ALT="Delete language" /></A></TD>
				<% } %>
            		</TR>
						<%        } // next %>
      </TABLE>
      </TD></TR>
    	</TABLE>
   	</FORM>
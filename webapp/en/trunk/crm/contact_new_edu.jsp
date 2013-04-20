<%@ page import="java.io.IOException,java.net.URLDecoder,java.sql.SQLException,com.knowgate.jdc.*,com.knowgate.dataobjs.*,com.knowgate.acl.*,com.knowgate.hipergate.*,com.knowgate.crm.*,com.knowgate.misc.Gadgets" language="java" session="false" contentType="text/html;charset=UTF-8" %>
<%@ include file="../methods/dbbind.jsp" %><%@ include file="../methods/cookies.jspf" %><%@ include file="../methods/authusrs.jspf" %><%@ include file="../methods/clientip.jspf" %><%@ include file="../methods/nullif.jspf" %>
<jsp:useBean id="GlobalCacheClient" scope="application" class="com.knowgate.cache.DistributedCachePeer"/>
<jsp:useBean id="GlobalDBLang" scope="application" class="com.knowgate.hipergate.DBLanguages"/>
<%@ include file="contact_new.jspf" %>
<!-- EDU Face -->
<BODY  TOPMARGIN="8" MARGINHEIGHT="8" onLoad="setCombos()">
  <DIV class="cxMnu1" style="width:290px"><DIV class="cxMnu2">
    <SPAN class="hmMnuOff" onMouseOver="this.className='hmMnuOn'" onMouseOut="this.className='hmMnuOff'" onClick="history.back()"><IMG src="../images/images/toolmenu/historyback.gif" width="16" style="vertical-align:middle" height="16" border="0" alt="Back"> Back</SPAN>
    <SPAN class="hmMnuOff" onMouseOver="this.className='hmMnuOn'" onMouseOut="this.className='hmMnuOff'" onClick="location.reload(true)"><IMG src="../images/images/toolmenu/locationreload.gif" width="16" style="vertical-align:middle" height="16" border="0" alt="Refresh"> Refresh</SPAN>
    <SPAN class="hmMnuOff" onMouseOver="this.className='hmMnuOn'" onMouseOut="this.className='hmMnuOff'" onClick="window.print()"><IMG src="../images/images/toolmenu/windowprint.gif" width="16" height="16" style="vertical-align:middle" border="0" alt="Print"> Print</SPAN>
  </DIV></DIV>
  <TABLE WIDTH="100%">
    <TR><TD><IMG SRC="../images/images/spacer.gif" HEIGHT="4" WIDTH="1" BORDER="0"></TD></TR>
    <TR><TD CLASS="striptitle"><FONT CLASS="title1">Create Student</FONT></TD></TR>
  </TABLE>
    
  <ILAYER id="panelLocator" width="600" height="510"></ILAYER>
  <NOLAYER>
  <CENTER>
    <DIV id="p1" style="background-color: transparent; position: relative; width: 600px; height: 470px">
    <DIV id="p1panel0" class="panel" style="background-color: #eeeeee;  z-index:4; height: 470px">
      <FORM METHOD="post" ACTION="contact_new_store.jsp" onSubmit="return validate()">

        <INPUT TYPE="hidden" NAME="id_domain" VALUE="<%=id_domain%>">
        <INPUT TYPE="hidden" NAME="gu_writer" VALUE="<%=id_user%>"> 
        <INPUT TYPE="hidden" NAME="gu_user" VALUE="<%=id_user%>">           
        <INPUT TYPE="hidden" NAME="gu_workarea" VALUE="<%=gu_workarea%>">
        <INPUT TYPE="hidden" NAME="bo_active" VALUE="1">        
        <INPUT TYPE="hidden" NAME="gu_contact" VALUE="">
        <INPUT TYPE="hidden" NAME="nm_company" VALUE="">
        <INPUT TYPE="hidden" NAME="nu_notes" VALUE="0">
        <INPUT TYPE="hidden" NAME="nu_attachs" VALUE="0">
        <INPUT TYPE="hidden" NAME="tx_division" VALUE="">
        <INPUT TYPE="hidden" NAME="tx_dept" VALUE="">

        <INPUT TYPE="hidden" NAME="gu_company" VALUE="">
        <INPUT TYPE="hidden" NAME="nm_legal">
        <INPUT TYPE="hidden" NAME="nm_commercial">
        <INPUT TYPE="hidden" NAME="id_sector">
        <INPUT TYPE="hidden" NAME="id_legal">
        <INPUT TYPE="hidden" NAME="tp_company">
        <INPUT TYPE="hidden" NAME="im_revenue">
        <INPUT TYPE="hidden" NAME="nu_employees">
        <INPUT TYPE="hidden" NAME="dt_founded">
        <INPUT TYPE="hidden" NAME="de_company">
                
        <INPUT TYPE="hidden" NAME="ix_address" VALUE="1">
        <INPUT TYPE="hidden" NAME="tp_location">
        <INPUT TYPE="hidden" NAME="nm_company">
        <INPUT TYPE="hidden" NAME="tp_street">
        <INPUT TYPE="hidden" NAME="nm_street">
        <INPUT TYPE="hidden" NAME="nu_street">
        <INPUT TYPE="hidden" NAME="id_country">
        <INPUT TYPE="hidden" NAME="nm_country">
        <INPUT TYPE="hidden" NAME="id_state">
        <INPUT TYPE="hidden" NAME="nm_state">
        <INPUT TYPE="hidden" NAME="mn_city">
        <INPUT TYPE="hidden" NAME="zipcode">
        <INPUT TYPE="hidden" NAME="work_phone">
        <INPUT TYPE="hidden" NAME="direct_phone">
        <INPUT TYPE="hidden" NAME="home_phone">
        <INPUT TYPE="hidden" NAME="mov_phone">
        <INPUT TYPE="hidden" NAME="fax_phone">
        <INPUT TYPE="hidden" NAME="other_phone">
        <INPUT TYPE="hidden" NAME="tx_email">
        <INPUT TYPE="hidden" NAME="url_addr">
        <INPUT TYPE="hidden" NAME="tx_salutation">
        <INPUT TYPE="hidden" NAME="contact_person">
        <INPUT TYPE="hidden" NAME="tx_remarks">

        <INPUT TYPE="hidden" NAME="courses">
                        
        <TABLE WIDTH="100%">
          <TR><TD>
            <TABLE ALIGN="center">
              <TR>
                <TD ALIGN="right" WIDTH="110"><FONT CLASS="formstrong">Private:</FONT></TD>
                <TD ALIGN="left" WIDTH="370">
                  <INPUT TYPE="hidden" NAME="bo_private">
                  <INPUT TYPE="checkbox" NAME="chk_private" VALUE="1">
                </TD>
              </TR>
              <TR>
                <TD ALIGN="right" WIDTH="110"><FONT CLASS="formplain">Registration:</FONT></TD>
                <TD ALIGN="left" WIDTH="370">
                  <INPUT TYPE="text" NAME="id_ref" MAXLENGTH="50" SIZE="32">
                </TD>
              </TR>
              <TR>
                <TD ALIGN="right" WIDTH="110"><FONT CLASS="formstrong">Name:</FONT></TD>
                <TD ALIGN="left" WIDTH="420"><INPUT TYPE="text" NAME="tx_name" MAXLENGTH="50" SIZE="32"></TD>
              </TR>
              <TR>
                <TD ALIGN="right" WIDTH="110"><FONT CLASS="formstrong">Surname:</FONT></TD>
                <TD ALIGN="left" WIDTH="420"><INPUT TYPE="text" NAME="tx_surname" MAXLENGTH="50" SIZE="32"></TD>
              </TR>
              <TR>
                <TD ALIGN="right" WIDTH="110"><FONT CLASS="formplain">Shift:</FONT></TD>
                <TD ALIGN="left" WIDTH="420">
                  <SELECT CLASS="combomini" NAME="sel_title"><OPTION VALUE=""></OPTION><%=sTitleLookUp%></SELECT>&nbsp;<A HREF="javascript:lookup(1)"><IMG SRC="../images/images/find16.gif" HEIGHT="16" BORDER="0" ALT="View employments list"></A>
                  <INPUT TYPE="hidden" NAME="de_title">
                </TD>
              </TR>
              <TR>
                <TD ALIGN="right" WIDTH="110"><FONT CLASS="formplain">Gender:</FONT></TD>
                <TD ALIGN="left" WIDTH="420">
                  <SELECT CLASS="combomini" NAME="sel_gender"><OPTION VALUE=""></OPTION><OPTION VALUE="M">M</OPTION><OPTION VALUE="F">F</OPTION></SELECT>
                  <INPUT TYPE="hidden" NAME="id_gender">
                </TD>
              </TR>                              
              <TR>
                <TD ALIGN="right" WIDTH="110"><FONT CLASS="formplain">Birth Date</FONT></TD>
                <TD ALIGN="left" WIDTH="420">
                  <INPUT TYPE="text" NAME="dt_birth" MAXLENGTH="10" SIZE="10">
                  <A HREF="javascript:showCalendar('dt_birth')"><IMG SRC="../images/images/datetime16.gif" WIDTH="16" HEIGHT="16" BORDER="0" ALT="View Calendar"></A>
    	      &nbsp;&nbsp;&nbsp;
    	      <FONT CLASS="formplain">Age:</FONT>
    	      &nbsp;
                  <INPUT TYPE="text" NAME="ny_age" MAXLENGTH="3" SIZE="3">
                </TD>
              </TR>                              
              <TR>
                <TD ALIGN="right" WIDTH="110"><FONT CLASS="formplain">Identity Doc.</FONT></TD>
                <TD ALIGN="left" WIDTH="420">
                  <INPUT TYPE="text" NAME="sn_passport" SIZE="10" MAXLENGTH="16">&nbsp;
                  <SELECT CLASS="combomini" NAME="sel_passport"><OPTION VALUE=""></OPTION><%=sPassportLookUp%></SELECT>&nbsp;<A HREF="javascript:lookup(2)"><IMG SRC="../images/images/find16.gif" HEIGHT="16" BORDER="0" ALT="View Identity Document Types"></A>
                  <INPUT TYPE="hidden" NAME="tp_passport">
                </TD>
              </TR>
              <TR>
                <TD ALIGN="right" WIDTH="110"><FONT CLASS="formplain">Nationality:</FONT></TD>
                <TD ALIGN="left" WIDTH="420">
                  <SELECT CLASS="combomini" NAME="id_nationality"><OPTION VALUE=""></OPTION><%=sCountriesLookUp%></SELECT>
                </TD>
              </TR>
              <TR>
                <TD ALIGN="right" WIDTH="110"><FONT CLASS="formplain">Zone:</FONT></TD>
                <TD ALIGN="left" WIDTH="370">
                  <INPUT TYPE="hidden" NAME="gu_geozone" VALUE="">
                  <INPUT TYPE="hidden" NAME="nm_geozone" SIZE="40" VALUE="">
                  <SELECT NAME="sel_geozone" CLASS="combomini" onchange="setCombo(document.forms[0].sel_salesman,zone_salesman[this.options[this.selectedIndex].value])"><% out.write (sTerms); %></SELECT>&nbsp;<A HREF="#" onclick="lookupZone()"><IMG SRC="../images/images/find16.gif" BORDER="0"></A>
                </TD>
              </TR>
              <TR>
                <TD ALIGN="right" WIDTH="110"><FONT CLASS="formplain">Salesman:</FONT></TD>
                <TD ALIGN="left" WIDTH="370">
                <INPUT TYPE="hidden" NAME="gu_sales_man" VALUE="">
                <SELECT NAME="sel_salesman"><OPTION VALUE=""></OPTION><% for (int s=0; s<iSalesMen; s++) out.write ("<OPTION VALUE=\""+oSalesMen.getString(0,s)+"\">"+oSalesMen.getStringNull(1,s,"")+" "+oSalesMen.getStringNull(2,s,"")+" "+oSalesMen.getStringNull(3,s,"")+"</OPTION>"); %></SELECT>
                </TD>
              </TR>
              <TR>
                <TD ALIGN="right" WIDTH="110"><FONT CLASS="formplain">Comments:</FONT></TD>
                <TD ALIGN="left" WIDTH="420"><TEXTAREA NAME="tx_comments" ROWS="3" COLS="44"></TEXTAREA></TD>
              </TR>
              <TR>
        	    <TD COLSPAN="2"><HR></TD>
      	  </TR>          
              <TR>
        	    <TD COLSPAN="2" ALIGN="center">
                  <INPUT TYPE="submit" ACCESSKEY="s" VALUE="Save" CLASS="pushbutton" STYLE="width:80" TITLE="ALT+s">&nbsp;
        	      &nbsp;&nbsp;<INPUT TYPE="button" ACCESSKEY="c" VALUE="Close" CLASS="closebutton" STYLE="width:80" TITLE="ALT+c" onclick="top.close()">
        	      <BR><BR>
        	    </TD>	            
            </TABLE>
          </TD></TR>
        </TABLE>

      </FORM>    
    </DIV>
    
    <DIV onclick="selectTab(0)" id="p1tab0" class="tab" style="background-color:#eeeeee; left:0px; top:0px; z-index:4; clip:rect(0 auto 30 0); cursor:hand">Student</DIV>

    <DIV id="p1panel1" class="panel" style="background-color: #dddddd;  z-index:3; height: 470px"> 

      <FORM NAME="frm_company">
        <INPUT TYPE="hidden" NAME="gu_company" VALUE="">
	<INPUT TYPE="hidden" NAME="nm_legal" VALUE="">
	<INPUT TYPE="hidden" NAME="nm_commercial" MAXLENGTH="50">
        <INPUT TYPE="hidden" NAME="im_revenue" MAXLENGTH="11" VALUE="">
	<INPUT TYPE="hidden" NAME="nu_employees" MAXLENGTH="9" VALUE="">
	<INPUT TYPE="hidden" NAME="dt_founded" MAXLENGTH="10" VALUE="">
	<INPUT TYPE="hidden" NAME="de_company" VALUE="">
	<INPUT TYPE="hidden" NAME="id_sector" VALUE="">
	<INPUT TYPE="hidden" NAME="id_legal" MAXLENGTH="16" VALUE="">
        <SELECT CLASS="combomini" STYLE="visibility:hidden" NAME="sel_typecompany"><OPTION VALUE=""></OPTION><%=sTypeLookUp%></SELECT>

        <TABLE WIDTH="100%">
        <TR><TD>
        <TABLE ALIGN="center">
          <TR>
            <TD ALIGN="right" WIDTH="110"><FONT CLASS="formstrong">Location:</FONT></TD>            
            <TD ALIGN="left" WIDTH="420">
                <SELECT CLASS="combomini" STYLE="visibility:hidden" NAME="sel_company" onChange="window.parent.contactexec.location.href='company_load.jsp?gu_company=' + getCombo(document.forms[1].sel_company) + '&gu_workarea=' + document.forms[0].gu_workarea.value;">
<%             
    	      for (int i=0; i<iCompanyCount; i++)
    	  	{            		
                sCompId = oContanies.getString(0,i);
                sCompDe = oContanies.getStringNull(1,i,"");
                out.write ("<OPTION VALUE=\"" + sCompId + "\">" + sCompDe + "</OPTION>" );            	       
                }             
%>
                </SELECT>
                <SCRIPT TYPE="text/javascript">
                <!--
                  window.parent.contactexec.location.href='company_load.jsp?gu_company=' + getCombo(document.forms[1].sel_company) + '&gu_workarea=' + document.forms[0].gu_workarea.value;
                //-->
                </SCRIPT>
            </TD>
          </TR>
          <TR>
            <TD ALIGN="right" WIDTH="110"><FONT CLASS="formstrong">Subjects</FONT></TD>            
    	    <TD ALIGN="left">
    	       <SELECT CLASS="combomini" STYLE="visibility:hidden" NAME="sel_acourse" SIZE="10" multiple>
<%	       for (int c=0; c<iCourseCount; c++) {
                out.write ("<OPTION VALUE=\"" + oCourses.getString(0,c) + "\">" + oCourses.getString(4,c) + "</OPTION>" );	          
	       }
%>
    	       </SELECT>
    	    </TD>
  	  </TR>
          
          <TR>
    	    <TD COLSPAN="2"><HR></TD>
  	  </TR>
          <TR>
    	    <TD COLSPAN="2" ALIGN="center">
              <INPUT TYPE="button" ACCESSKEY="s" VALUE="Save" CLASS="pushbutton" STYLE="width:80" TITLE="ALT+s" onclick="if (validate()) window.document.forms[0].submit();">&nbsp;
    	      &nbsp;&nbsp;<INPUT TYPE="button" ACCESSKEY="c" VALUE="Close" CLASS="closebutton" STYLE="width:80" TITLE="ALT+c" onclick="top.close()">
    	      <BR>
    	    </TD>	            
	  </TR>
        </TABLE>
      </TD></TR>
    </TABLE>
      
      </FORM> 

    </DIV>

    <DIV onclick="selectTab(1)" id="p1tab1" class="tab" style="background-color:#dddddd; left:150px; top:0px; z-index:3; clip:rect(0 auto 30 0)"><SPAN onmouseover="this.style.cursor='hand';" onmouseout="this.style.cursor='auto';">Location</SPAN></DIV>

    <DIV id="p1panel2" class="panel" style="background-color: #cccccc; z-index:2; height: 470px">

      <FORM>

        <TABLE>
          <TR><TD>
            <TABLE WIDTH="100%">
              <TR>
                <TD ALIGN="right" WIDTH="140"><FONT CLASS="formplain">Address Type</FONT></TD>
                <TD ALIGN="left" WIDTH="460">
                  <TABLE WIDTH="100%" CELLSPACING="0" CELLPADDING="0" BORDER="0"><TR>
                    <TD ALIGN="left">
                      <A HREF="javascript:lookup(5)"><IMG SRC="../images/images/find16.gif" HEIGHT="16" BORDER="0" ALT="View address types"></A>&nbsp;<SELECT CLASS="combomini" STYLE="visibility:hidden" NAME="sel_location"><OPTION VALUE=""></OPTION><%=sLocationLookUp%></SELECT>          
                      <INPUT TYPE="hidden" NAME="tp_location">
                    </TD>
                    <TD ALIGN="right">
                      <INPUT TYPE="hidden" NAME="nm_company" MAXLENGTH="50" SIZE="20" VALUE="">
                    </TD>
                  </TR></TABLE>
                </TD>
              </TR>
    <% if (sLanguage.equalsIgnoreCase("es")) { %>
              <TR>
                <TD ALIGN="right" WIDTH="140">
                  <A HREF="javascript:lookup(6)"><IMG SRC="../images/images/find16.gif" HEIGHT="16" BORDER="0" ALT="View street types"></A>&nbsp;
                  <INPUT TYPE="hidden" NAME="tp_street">
                  <SELECT CLASS="combomini" STYLE="visibility:hidden" NAME="sel_street"><OPTION VALUE=""></OPTION><%=sStreetLookUp%></SELECT>
                </TD>
                <TD ALIGN="left" WIDTH="460">
                  <INPUT TYPE="text" NAME="nm_street" MAXLENGTH="100" SIZE="36">
                  &nbsp;&nbsp;
                  <FONT CLASS="formplain">Number:</FONT>&nbsp;<INPUT TYPE="text" NAME="nu_street" MAXLENGTH="16" SIZE="4">
                </TD>
              </TR>
    <% } else { %>
              <TR>
                <TD ALIGN="right" WIDTH="140">
    	      <FONT CLASS="formplain">Number:</FONT>&nbsp;
                </TD>
                <TD ALIGN="left" WIDTH="460">
                  <INPUT TYPE="text" NAME="nu_street" MAXLENGTH="16" SIZE="4">
                  <INPUT TYPE="text" NAME="nm_street" MAXLENGTH="100" SIZE="36">
                  <INPUT TYPE="hidden" NAME="tp_street">
                  <SELECT CLASS="combomini" STYLE="visibility:hidden" NAME="sel_street"><OPTION VALUE=""></OPTION><%=sStreetLookUp%></SELECT>
                  <A HREF="javascript:lookup(6)"><IMG SRC="../images/images/find16.gif" HEIGHT="16" BORDER="0" ALT="View street types"></A>              
                </TD>
              </TR>
    <% } %>
              <TR>
                <TD ALIGN="right" WIDTH="140"><FONT CLASS="formplain">Flat:</FONT></TD>
                <TD ALIGN="left" WIDTH="460">
                  <INPUT TYPE="text" NAME="tx_addr1" MAXLENGTH="100" SIZE="10">
                  &nbsp;&nbsp;
                  <FONT CLASS="formplain">Rest:</FONT>&nbsp;
                  <INPUT TYPE="text" NAME="tx_addr2" MAXLENGTH="100" SIZE="32">
                </TD>
              </TR>
              <TR>
                <TD ALIGN="right" WIDTH="140"><FONT CLASS="formplain">Country:</FONT></TD>
                <TD ALIGN="left" WIDTH="460">
    	      <SELECT CLASS="combomini" STYLE="visibility:hidden" NAME="sel_country" onchange="loadstates()"><OPTION VALUE=""></OPTION><%=sCountriesLookUp%></SELECT>
                </TD>
              </TR>
              <TR>
                <TD ALIGN="right" WIDTH="140"><FONT CLASS="formplain">State:</FONT></TD>
                <TD ALIGN="left" WIDTH="460">
                  <A HREF="javascript:lookup(7)"><IMG SRC="../images/images/find16.gif" HEIGHT="16" BORDER="0" ALT="View states"></A>&nbsp;<SELECT CLASS="combomini" STYLE="visibility:hidden" NAME="sel_state"></SELECT>
                  <INPUT TYPE="hidden" NAME="id_state" MAXLENGTH="16">
                  <INPUT TYPE="hidden" NAME="nm_state" MAXLENGTH="30">
                </TD>
              </TR>
              <TR>
                <TD ALIGN="right" WIDTH="140"><FONT CLASS="formplain">City:</FONT></TD>
                <TD ALIGN="left" WIDTH="460">
                  <INPUT TYPE="text" NAME="mn_city" STYLE="text-transform:uppercase" MAXLENGTH="50" SIZE="30">
                  &nbsp;&nbsp;
                  <FONT CLASS="formplain">Zipcode:</FONT>
                  &nbsp;
                  <INPUT TYPE="text" NAME="zipcode" MAXLENGTH="30" SIZE="5">
                </TD>
              </TR>
              <TR>
                <TD ALIGN="right" WIDTH="140">
                  <FONT CLASS="formplain">Telephones:</FONT>
                </TD>
                <TD ALIGN="left" WIDTH="460">
                  <TABLE BGCOLOR="#E5E5E5">
                    <TR>
                      <TD><FONT CLASS="textsmall">Call Center</FONT></TD>
                      <TD><INPUT TYPE="text" NAME="work_phone" MAXLENGTH="16" SIZE="10"></TD>
                      <TD>&nbsp;&nbsp;&nbsp;&nbsp;</TD>
                      <TD><FONT CLASS="textsmall">Direct</FONT></TD>
                      <TD><INPUT TYPE="text" NAME="direct_phone" MAXLENGTH="16" SIZE="10"></TD>
                    </TR>
                    <TR>
                      <TD><FONT CLASS="textsmall">Personal</FONT></TD>
                      <TD><INPUT TYPE="text" NAME="home_phone" MAXLENGTH="16" SIZE="10"></TD>              
                      <TD>&nbsp;&nbsp;&nbsp;&nbsp;</TD>
                      <TD><FONT CLASS="textsmall">Mobile</FONT></TD>
                      <TD><INPUT TYPE="text" NAME="mov_phone" MAXLENGTH="16" SIZE="10"></TD>
                      <TD>&nbsp;&nbsp;&nbsp;&nbsp;</TD>
                    </TR>
                    <TR>                
                      <TD><FONT CLASS="textsmall">Fax</FONT></TD>
                      <TD><INPUT TYPE="text" NAME="fax_phone" MAXLENGTH="16" SIZE="10"></TD>
                      <TD>&nbsp;&nbsp;&nbsp;&nbsp;</TD>
                      <TD><FONT CLASS="textsmall">Other</FONT></TD>
                      <TD><INPUT TYPE="text" NAME="other_phone" MAXLENGTH="16" SIZE="10"></TD>
                    </TR>
                  </TABLE>
                </TD>
              </TR>
              <TR>
                <TD ALIGN="right" WIDTH="140"><FONT CLASS="formplain">e-Mail:</FONT></TD>
                <TD ALIGN="left" WIDTH="460"><INPUT TYPE="text" NAME="tx_email" STYLE="text-tansform:lowercase" MAXLENGTH="50" SIZE="42">
                </TD>
              </TR>
              <TR>
                <TD ALIGN="right" WIDTH="140"><FONT CLASS="formplain">URL:</FONT></TD>
                <TD ALIGN="left" WIDTH="460"><INPUT TYPE="text" NAME="url_addr" MAXLENGTH="254" SIZE="42">
                </TD>
              </TR>
              <TR>
                <TD ALIGN="right" WIDTH="140"><FONT CLASS="formplain">Tutor</FONT></TD>
                <TD ALIGN="left" WIDTH="460">
                  <A HREF="javascript:lookup(8)"><IMG SRC="../images/images/find16.gif" HEIGHT="16" BORDER="0" ALT="Salutation"></A>&nbsp;
                  <SELECT CLASS="combomini" STYLE="visibility:hidden"  NAME="sel_salutation"><OPTION VALUE=""></OPTION><%=sSalutationLookUp%></SELECT>&nbsp;
                  <INPUT TYPE="hidden" NAME="tx_salutation">
                  <INPUT TYPE="text" NAME="contact_person" MAXLENGTH="254" SIZE="32">
                </TD>
              </TR>
              <TR>
                <TD ALIGN="right" WIDTH="140"><FONT CLASS="formplain">Comments:</FONT></TD>
                <TD ALIGN="left" WIDTH="460"><TEXTAREA NAME="tx_remarks" ROWS="2" COLS="40"></TEXTAREA></TD>
              </TR>
              <TR>
              <TR>
                <TD COLSPAN="2"><HR></TD>
              </TR>
              <TR>
        	    <TD COLSPAN="2" ALIGN="center">
    <% if (bIsGuest) { %>
                  <INPUT TYPE="button" ACCESSKEY="s" VALUE="Save" CLASS="pushbutton" STYLE="width:80" TITLE="ALT+s" onclick="alert('Your priviledge level as Guest does not allow you to perform this action')">&nbsp;&nbsp;&nbsp;
    <% } else { %>
                  <INPUT TYPE="button" ACCESSKEY="s" VALUE="Save" CLASS="pushbutton" STYLE="width:80" TITLE="ALT+s" onclick="if (validate()) window.document.forms[0].submit();">&nbsp;&nbsp;&nbsp;
    <% } %>
                  <INPUT TYPE="button" ACCESSKEY="c" VALUE="Close" CLASS="closebutton" STYLE="width:80" TITLE="ALT+c" onclick="top.close()">
        	    </TD>	            
            </TABLE>
          </TD></TR>
        </TABLE>
      </FORM>
    </DIV>
    <DIV onclick="selectTab(2)" id="p1tab2" class="tab" style="background-color:#cccccc; left:300px; top:0px; z-index:2; clip:rect(0 auto 30 0)">
      <SPAN onmouseover="this.style.cursor='hand';" onmouseout="this.style.cursor='auto';">Address</SPAN>
    </DIV>
    </DIV>
  </CENTER>
  </NOLAYER>
  <LAYER id="p1" width="700" height="510" src="nav4.html"></LAYER>

</BODY>
</HTML>

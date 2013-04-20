<%@ page import="java.text.NumberFormat,java.util.Arrays,java.util.Comparator,java.util.ArrayList,java.util.HashMap,java.util.Collections,java.util.ArrayList,java.util.HashMap,java.util.TreeMap,java.util.Iterator,java.io.IOException,java.net.URLDecoder,java.sql.SQLException,com.knowgate.jdc.*,com.knowgate.dataobjs.*,com.knowgate.acl.*,com.knowgate.hipergate.*,com.knowgate.scheduler.Atom,com.knowgate.misc.Calendar" language="java" session="false" contentType="text/html;charset=UTF-8" %>
<%@ include file="../methods/dbbind.jsp" %><%@ include file="../methods/cookies.jspf" %><%@ include file="../methods/authusrs.jspf" %><%@ include file="../methods/clientip.jspf" %><%@ include file="../methods/nullif.jspf" %>
<jsp:useBean id="GlobalCacheClient" scope="application" class="com.knowgate.cache.DistributedCachePeer"/><jsp:useBean id="GlobalDBLang" scope="application" class="com.knowgate.hipergate.DBLanguages"/>
<%@ include file="job_followup_stats.jspf" %>
<HTML LANG="<% out.write(sLanguage); %>">
<HEAD>
  <TITLE>hipergate :: Newsletter follow-up statistics</TITLE>
  <SCRIPT TYPE="text/javascript" SRC="../javascript/cookies.js"></SCRIPT>
  <SCRIPT TYPE="text/javascript" SRC="../javascript/setskin.js"></SCRIPT>
  <SCRIPT TYPE="text/javascript">
    <!--

			function modifyContact(id) {
	  		open ("../crm/contact_edit.jsp?id_domain=" + getCookie("domainid") + "&n_domain=" + escape(getCookie("domainnm")) + "&gu_contact=" + id, "editcontact", "directories=no,toolbar=no,scrollbars=yes,menubar=no,width=660,height=660");
			}	

	    function modifyCompany(id,nm) {
	      open ("../crm/company_edit.jsp?id_domain=" + getCookie("domainid") + "&n_domain=" + escape(getCookie("domainnm")) + "&gu_company=" + id + "&n_company=" + escape(nm) + "&gu_workarea=<%=gu_workarea%>", "editcompany", "directories=no,scrollbars=yes,toolbar=no,menubar=no,width=660,height=660");
	    }	

      function showWebBeacons() {
			  document.getElementById('webbeacons').style.display='block';
			  document.getElementById('webbeacons_ctrl').innerHTML = "<A HREF=# onclick=\"hideWebBeacons()\" CLASS=\"linkplain\">Hide readed confirmations list</A>";
      }

      function hideWebBeacons() {
			  document.getElementById('webbeacons').style.display='none';
			  document.getElementById('webbeacons_ctrl').innerHTML = "<A HREF=# onclick=\"showWebBeacons()\" CLASS=\"linkplain\">Show readed confirmations list</A>";
      }
    //-->
  </SCRIPT>

</HEAD>
<BODY TOPMARGIN="8" MARGINHEIGHT="8">
  <DIV class="cxMnu1" style="width:290px"><DIV class="cxMnu2">
    <SPAN class="hmMnuOff" onMouseOver="this.className='hmMnuOn'" onMouseOut="this.className='hmMnuOff'" onClick="history.back()"><IMG src="../images/images/toolmenu/historyback.gif" width="16" style="vertical-align:middle" height="16" border="0" alt="Back"> Back</SPAN>
    <SPAN class="hmMnuOff" onMouseOver="this.className='hmMnuOn'" onMouseOut="this.className='hmMnuOff'" onClick="location.reload(true)"><IMG src="../images/images/toolmenu/locationreload.gif" width="16" style="vertical-align:middle" height="16" border="0" alt="Update"> Update</SPAN>
    <SPAN class="hmMnuOff" onMouseOver="this.className='hmMnuOn'" onMouseOut="this.className='hmMnuOff'" onClick="window.print()"><IMG src="../images/images/toolmenu/windowprint.gif" width="16" height="16" style="vertical-align:middle" border="0" alt="Print"> Print</SPAN>
  </DIV></DIV>
  <TABLE WIDTH="100%">
    <TR><TD><IMG SRC="../images/images/spacer.gif" HEIGHT="4" WIDTH="1" BORDER="0"></TD></TR>
    <TR><TD CLASS="striptitle"><FONT CLASS="title1">Newsletter follow-up statistics</FONT></TD></TR>
  </TABLE>  
    <IMG SRC="../images/images/excel16.gif" WIDTH="16" HEIGHT="16" BORDER="0" ALT="Excel">&nbsp;<A CLASS="linkplain" HREF="job_followup_stats_xls.jsp?gu_job=<%=gu_job%>">Show as Excel</A>
    
    <TABLE CLASS="formback">
      <TR><TD>
        <TABLE WIDTH="100%" CLASS="formfront">
          <TR>
            <TD></TD>
            <TD ALIGN="left" CLASS="formstrong"><%=sTxSubject%></TD>
          </TR>
          <TR>
            <TD ALIGN="right" CLASS="formplain" NOWRAP="nowrap">Total Recipients</TD>
            <TD ALIGN="left" CLASS="formplain"><%=String.valueOf(iAtoms)%></TD>
          </TR>
          <TR>
            <TD ALIGN="right" CLASS="formplain">Opened</TD>
            <TD ALIGN="left" CLASS="formplain"><% if (iWebBeaconsUnique>0) { %> <DIV ID="webbeacons_ctrl"><%=String.valueOf(iWebBeaconsUnique)%>&nbsp;&nbsp;<A HREF="#" onclick="showWebBeacons()" CLASS="linkplain">Show readed confirmations list</A></DIV><% } else { out.write("?"); } %></TD>
          </TR>
          <TR>
            <TD ALIGN="right" COLSPAN="2">
            	<DIV ID="webbeacons" STYLE="display:none">
            	<TABLE SUMMARY="Web Beacons List" BORDER="1">
<%            if (nPgAtoms>0) {
							  int nTotalOpened = 0;
								for (int p=0; p<nPgAtoms; p++) {
								  if (aPgAtoms[p]>0) {
								    int iPgAtm = iMinAtom+p;
							      int iIxAtm = oWebBeacons.find(3, new Integer(iPgAtm));
							      int nTimes = 0;
							      String sTxEmail = oWebBeacons.getString(0,iIxAtm);
										iIxMbr = oEmailAddrs.binaryFind(0,sTxEmail);
										if (iIxMbr==-1) {
									    sDisplayName = sTxEmail;
									  } else {
									    if (oEmailAddrs.isNull(1,iIxMbr))
									      sDisplayName = "<A HREF=\"#\" CLASS=\"linksmall\" onclick=\"modifyCompany('"+oEmailAddrs.getStringNull(2,iIxMbr,"")+"','"+oEmailAddrs.getStringNull(5,iIxMbr,"").replace('\n',' ').replace((char)39,' ')+"')\">"+oEmailAddrs.getStringNull(5,iIxMbr,"")+"</A>&nbsp;&lt;<A HREF=\"msg_new_f.jsp?to="+sTxEmail+"&gu_company="+oEmailAddrs.getStringNull(2,iIxMbr,"")+"\" TARGET=\"_blank\" CLASS=\"linksmall\">"+sTxEmail+"</A>&gt";
									    else
									      sDisplayName = "<A HREF=\"#\" CLASS=\"linksmall\" onclick=\"modifyContact('"+oEmailAddrs.getStringNull(1,iIxMbr,"")+"')\">"+oEmailAddrs.getStringNull(3,iIxMbr,"")+" "+oEmailAddrs.getStringNull(4,iIxMbr,"")+"</A>&nbsp;&lt;<A HREF=\"msg_new_f.jsp?to="+sTxEmail+"&gu_contact="+oEmailAddrs.getStringNull(1,iIxMbr,"")+"\" TARGET=\"_blank\" CLASS=\"linksmall\">"+sTxEmail+"</A>&gt";
							      }
							      StringBuffer oDates = new StringBuffer(256);
							      while (oWebBeacons.getInt(3,iIxAtm)==iPgAtm) {
							        nTimes++;
							        if (nTimes>1) oDates.append("<BR>");
							        oDates.append(oWebBeacons.getDateTime24(1,iIxAtm));							      
							        if (++iIxAtm==iWebBeacons) break;
							      } //wend
							      out.write("<TR><TD CLASS=\"textsmall\">"+sDisplayName+"</TD><TD CLASS=\"formplain\">"+String.valueOf(nTimes)+"</TD><TD CLASS=\"textsmall\">"+oDates.toString()+"</TD></TR>");
							      nTotalOpened++;
							    } // fi
							  } // next
							      out.write("<TR><TD CLASS=\"textplain\" COLSPAN=\"2\" ALIGN=\"right\"><B>Total</B></TD><TD CLASS=\"textplain\"><B>"+String.valueOf(nTotalOpened)+"</B></TD></TR>");
              }
%>            </TABLE>  
              </DIV></TD>
          </TR>
          <TR>
            <TD ALIGN="right" CLASS="formplain" NOWRAP="nowrap">E-Mail User Agents</TD>
            <TD ALIGN="left">
              <TABLE SUMMARY="User Agents">
<%              Iterator<String> oIter = oAgents.keySet().iterator();
								NumberFormat oPctFmt = NumberFormat.getPercentInstance();

                while (oIter.hasNext()) {
                  sUserAgent = oIter.next();
                  float fAgentCount = oAgents.get(sUserAgent).floatValue();
                  out.write("<TR><TD CLASS=\"formplain\">"+oPctFmt.format(fAgentCount/nAgents)+"</TD><TD CLASS=\"textsmall\">"+sUserAgent+"</TD></TR>");
                } // wend			
%>
              </TABLE>
            </TD>
          </TR>
          <TR>
            <TD COLSPAN="2"><HR></TD>
          </TR>
          <TR>
    	    <TD COLSPAN="2" ALIGN="center">
    	      <INPUT TYPE="button" ACCESSKEY="o" VALUE="OK" CLASS="closebutton" STYLE="width:80" TITLE="ALT+o" onclick="close()">
    	      <BR><BR>
    	    </TD>
    	  </TR>            
        </TABLE>
      </TD></TR>
    </TABLE>                 
</BODY>
</HTML>
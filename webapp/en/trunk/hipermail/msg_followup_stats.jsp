<%@ page import="java.text.NumberFormat,java.util.Arrays,java.util.HashMap,java.util.Iterator,java.io.IOException,java.net.URLDecoder,java.sql.SQLException,com.knowgate.jdc.*,com.knowgate.dataobjs.*,com.knowgate.acl.*,com.knowgate.hipergate.*,com.knowgate.scheduler.Atom" language="java" session="false" contentType="text/html;charset=UTF-8" %>
<%@ include file="../methods/dbbind.jsp" %><%@ include file="../methods/cookies.jspf" %><%@ include file="../methods/authusrs.jspf" %><%@ include file="../methods/clientip.jspf" %><%@ include file="../methods/nullif.jspf" %>
<jsp:useBean id="GlobalCacheClient" scope="application" class="com.knowgate.cache.DistributedCachePeer"/><jsp:useBean id="GlobalDBLang" scope="application" class="com.knowgate.hipergate.DBLanguages"/><% 
/*
  Copyright (C) 2003-2009  Know Gate S.L. All rights reserved.
                           C/Oña, 107 1º2 28050 Madrid (Spain)

  Redistribution and use in source and binary forms, with or without
  modification, are permitted provided that the following conditions
  are met:

  1. Redistributions of source code must retain the above copyright
     notice, this list of conditions and the following disclaimer.

  2. The end-user documentation included with the redistribution,
     if any, must include the following acknowledgment:
     "This product includes software parts from hipergate
     (http://www.hipergate.org/)."
     Alternately, this acknowledgment may appear in the software itself,
     if and wherever such third-party acknowledgments normally appear.

  3. The name hipergate must not be used to endorse or promote products
     derived from this software without prior written permission.
     Products derived from this software may not be called hipergate,
     nor may hipergate appear in their name, without prior written
     permission.

  This library is distributed in the hope that it will be useful,
  but WITHOUT ANY WARRANTY; without even the implied warranty of
  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.

  You should have received a copy of hipergate License with this code;
  if not, visit http://www.hipergate.org or mail to info@hipergate.org
*/

  if (autenticateSession(GlobalDBBind, request, response)<0) return;
  
  response.addHeader ("Pragma", "no-cache");
  response.addHeader ("cache-control", "no-store");
  response.setIntHeader("Expires", 0);

  final String PAGE_NAME = "msg_followup_stats";
  
  String sSkin = getCookie(request, "skin", "xp");
  String sLanguage = getNavigatorLanguage(request);
  HashMap<String,Float> oAgents = new HashMap<String,Float>(151);

  String gu_mimemsg = request.getParameter("gu_mimemsg");
  String gu_workarea = getCookie(request,"workarea","");
    
  JDCConnection oConn = null;
	DBSubset oReceipts = new DBSubset(DB.k_inet_addrs, DB.tx_email+","+DB.dt_displayed+","+DB.user_agent, DB.gu_mimemsg+"=? AND "+DB.dt_displayed+" IS NOT NULL AND "+DB.tp_recipient+"<>'from'", 100);
	DBSubset oAtoms = new DBSubset(DB.k_job_atoms, DB.tx_email+","+DB.dt_execution+","+DB.id_status+","+DB.tx_log, DB.gu_job+"=?", 100);
	DBSubset oArchived = new DBSubset(DB.k_job_atoms_archived, DB.tx_email+","+DB.dt_execution+","+DB.id_status+","+DB.tx_log, DB.gu_job+"=?",100);
	DBSubset oWebBeacons = new DBSubset(DB.k_job_atoms_tracking, DB.tx_email+","+DB.dt_action+","+DB.user_agent+","+DB.pg_atom, DB.gu_job+"=? ORDER BY "+DB.pg_atom+","+DB.dt_action, 100);
  DBSubset oEmailAddrs = null;
  int iReceipts=0, iAtoms=0, iWebBeacons=0, iWebBeaconsUnique=0, nRecipients = 0;
  float nAgents = 0f;
  int nAborted=0, nFinished=0, nPending=0, nSuspended=0, nRunning=0, nInterrupted=0;
	int iMinAtom = -1, iMaxAtom = -1;
	int[] aPgAtoms = null;
	int nPgAtoms = 0;
  int iIxMbr;
  String sTxSubject = null;  
  String sGuJob = null;
  String sUserAgent;
  String sDisplayName;
  Integer oPgAtom;
    
  try {

    oConn = GlobalDBBind.getConnection(PAGE_NAME);  

		iReceipts = oReceipts.load(oConn, new Object[]{gu_mimemsg});
		
		sTxSubject = DBCommand.queryStr(oConn, "SELECT "+DB.tx_subject+" FROM "+DB.k_mime_msgs+" WHERE "+DB.gu_mimemsg+"='"+gu_mimemsg+"'");
		sGuJob = DBCommand.queryStr(oConn, "SELECT "+DB.gu_job+" FROM "+DB.k_mime_msgs+" WHERE "+DB.gu_mimemsg+"='"+gu_mimemsg+"'");

		if (sGuJob!=null) {
		  oPgAtom = DBCommand.queryMinInt(oConn, DB.pg_atom, DB.k_job_atoms_tracking, DB.gu_job+"='"+sGuJob+"'");
		  if (null!=oPgAtom) iMinAtom = oPgAtom.intValue();
		  oPgAtom = DBCommand.queryMaxInt(oConn, DB.pg_atom, DB.k_job_atoms_tracking, DB.gu_job+"='"+sGuJob+"'");
		  if (null!=oPgAtom) iMaxAtom = oPgAtom.intValue();
		  if (iMinAtom!=-1 && iMaxAtom!=-1) {
		    nPgAtoms = iMaxAtom-iMinAtom+1;
		    aPgAtoms = new int[nPgAtoms];
		    Arrays.fill(aPgAtoms, 0);
		  }
		  oAtoms.load(oConn, new Object[]{sGuJob});
		  oArchived.load(oConn, new Object[]{sGuJob});
		  oAtoms.union(oArchived);
		  iAtoms = oAtoms.getRowCount();
		  nRecipients = iAtoms;
		  iWebBeacons = oWebBeacons.load(oConn, new Object[]{sGuJob});
  		oEmailAddrs = new DBSubset(DB.k_member_address, DB.tx_email+","+DB.gu_contact+","+DB.gu_company+","+DB.tx_name+","+DB.tx_surname+","+DB.nm_legal, DB.gu_workarea+"=? AND "+
  															 DB.tx_email+" IN (SELECT "+DB.tx_email+" FROM "+DB.k_job_atoms_tracking+" WHERE "+DB.gu_job+"=?) OR "+
  															 DB.tx_email+" IN (SELECT "+DB.tx_email+" FROM "+DB.k_inet_addrs+" WHERE "+DB.gu_mimemsg+"=? AND "+DB.dt_displayed+" IS NOT NULL AND "+DB.tp_recipient+"<>'from') ORDER BY 1", 100);
		  oEmailAddrs.load(oConn, new Object[]{gu_workarea, sGuJob, gu_mimemsg});
		} else {
		  nRecipients = DBCommand.queryCount(oConn, "*", DB.k_inet_addrs, DB.gu_mimemsg+"='"+gu_mimemsg+"' AND "+DB.tp_recipient+"<>'from'");
  		oEmailAddrs = new DBSubset(DB.k_member_address, DB.tx_email+","+DB.gu_contact+","+DB.gu_company+","+DB.tx_name+","+DB.tx_surname+","+DB.nm_legal, DB.gu_workarea+"=? AND "+
  															 DB.tx_email+" IN (SELECT "+DB.tx_email+" FROM "+DB.k_inet_addrs+" WHERE "+DB.gu_mimemsg+"=? AND "+DB.dt_displayed+" IS NOT NULL AND "+DB.tp_recipient+"<>'from') ORDER BY 1", 100);
		  oEmailAddrs.load(oConn, new Object[]{gu_workarea, gu_mimemsg});
		}

    oConn.close(PAGE_NAME);
  }
  catch (SQLException e) {  
    if (oConn!=null)
      if (!oConn.isClosed()) oConn.close(PAGE_NAME);
    oConn = null;
    response.sendRedirect (response.encodeRedirectUrl ("../common/errmsg.jsp?title=SQLException&desc=" + e.getLocalizedMessage() + "&resume=_close"));  
  }
  
  if (null==oConn) return;  
  oConn = null;  

	for (int a=0; a<iAtoms; a++) {
	  switch (oAtoms.getShort(2,a)) {
		  case Atom.STATUS_ABORTED:
		    nAborted++;
		    break;
		  case Atom.STATUS_FINISHED:
		    nFinished++;
		    break;
		  case Atom.STATUS_SUSPENDED:
		    nSuspended++;
		    break;
		  case Atom.STATUS_RUNNING:
		    nRunning++;
		    break;
		  case Atom.STATUS_INTERRUPTED:
		    nInterrupted++;
		    break;	  
	  }
	} // next
	
	for (int b=0; b<iWebBeacons; b++) {
	  int iIxAtom = oWebBeacons.getInt(3,b)-iMinAtom;
	  int nReads = aPgAtoms[iIxAtom];
	  if (nReads==0) iWebBeaconsUnique++;
	  aPgAtoms[iIxAtom] = ++nReads;
	  if (!oWebBeacons.isNull(2,b)) {
      nAgents++;
      sUserAgent = oWebBeacons.getString(2,b);
      if (oAgents.containsKey(sUserAgent)) {
        Float oCount = oAgents.get(sUserAgent);
        oAgents.remove(sUserAgent);
        oAgents.put(sUserAgent, new Float(oCount.floatValue()+1f));
      } else {
        oAgents.put(sUserAgent, new Float(1f));
      } // fi
    } // fi
  } // next

	for (int r=0; r<iReceipts; r++) {
	  if (!oReceipts.isNull(2,r)) {
      nAgents++;
      sUserAgent = oReceipts.getString(2,r);
      if (oAgents.containsKey(sUserAgent)) {
        Float oCount = oAgents.get(sUserAgent);
        oAgents.remove(sUserAgent);
        oAgents.put(sUserAgent, new Float(oCount.floatValue()+1f));
      } else {
        oAgents.put(sUserAgent, new Float(1f));
      } // fi
    } // fi
  } // next

%><HTML LANG="<% out.write(sLanguage); %>">
<HEAD>
  <TITLE>hipergate :: E-Mail follow-up statistics</TITLE>
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

      function showReceipts() {
			  document.getElementById('receipts').style.display='block';
			  document.getElementById('receipts_ctrl').innerHTML = "<A HREF=# onclick=\"hideReceipts()\" CLASS=\"linkplain\">Hide read receipts list</A>";
      }

      function hideReceipts() {
			  document.getElementById('receipts').style.display='none';
			  document.getElementById('receipts_ctrl').innerHTML = "<A HREF=# onclick=\"showReceipts()\" CLASS=\"linkplain\">Show read receipts list</A>";
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
    <TR><TD CLASS="striptitle"><FONT CLASS="title1">Follow-up statistics&nbsp;<%=sTxSubject%></FONT></TD></TR>
  </TABLE>  

    <TABLE CLASS="formback">
      <TR><TD>
        <TABLE WIDTH="100%" CLASS="formfront">
          <TR>
            <TD ALIGN="right" CLASS="formplain">Total recipients</TD>
            <TD ALIGN="left" CLASS="formplain"><%=String.valueOf(nRecipients)%></TD>
          </TR>
          <TR>
            <TD ALIGN="right" CLASS="formplain">Read receipts</TD>
            <TD ALIGN="left" CLASS="formplain"><% if (iReceipts>0) { %> <DIV ID="receipts_ctrl"><%=String.valueOf(iReceipts)%>&nbsp;&nbsp;<A HREF="#" onclick="showReceipts()" CLASS="linkplain">Show read receipts list</A></DIV><% } else { out.write("0"); } %></TD>
          </TR>
          <TR>
            <TD ALIGN="right"></TD>
            <TD ALIGN="left">
            	<DIV ID="receipts" STYLE="display:none">
							  <TABLE SUMMARY="Receipts" BORDER="1">
<%	            for (int r=0; r<iReceipts; r++) {
									iIxMbr = oEmailAddrs.binaryFind(0,oReceipts.getString(0,r));
									if (iIxMbr==-1) {
									  sDisplayName = oReceipts.getString(0,r);
									} else {
									  if (oEmailAddrs.isNull(1,iIxMbr))
									    sDisplayName = "<A HREF=\"#\" CLASS=\"linkplain\" onclick=\"modifyCompany('"+oEmailAddrs.getStringNull(2,iIxMbr,"")+"','"+oEmailAddrs.getStringNull(5,iIxMbr,"").replace('\n',' ').replace((char)39,' ')+"')\">"+oEmailAddrs.getStringNull(5,iIxMbr,"")+"</A>&nbsp;&lt;<A HREF=\"msg_new_f.jsp?to="+oReceipts.getString(0,r)+"&gu_company="+oEmailAddrs.getStringNull(2,iIxMbr,"")+"\" TARGET=\"_blank\" CLASS=\"linkplain\">"+oReceipts.getString(0,r)+"</A>&gt";
									  else
									    sDisplayName = "<A HREF=\"#\" CLASS=\"linkplain\" onclick=\"modifyContact('"+oEmailAddrs.getStringNull(1,iIxMbr,"")+"')\">"+oEmailAddrs.getStringNull(3,iIxMbr,"")+" "+oEmailAddrs.getStringNull(4,iIxMbr,"")+"</A>&nbsp;&lt;<A HREF=\"msg_new_f.jsp?to="+oReceipts.getString(0,r)+"&gu_contact="+oEmailAddrs.getStringNull(1,iIxMbr,"")+"\" TARGET=\"_blank\" CLASS=\"linkplain\">"+oReceipts.getString(0,r)+"</A>&gt";
									}
							    out.write("							    <TR><TD CLASS=\"formplain\">"+sDisplayName+"</TD><TD CLASS=\"formplain\">"+oReceipts.getDateTime24(1,r)+"</TD></TR>\n");
                }
%>
              </TABLE>
              </DIV>
            </TD>
          </TR>
          <TR>
            <TD ALIGN="right" CLASS="formplain">Opened</TD>
            <TD ALIGN="left" CLASS="formplain"><% if (iWebBeaconsUnique>0) { %> <DIV ID="webbeacons_ctrl"><%=String.valueOf(iWebBeaconsUnique)%>&nbsp;&nbsp;<A HREF="#" onclick="showWebBeacons()" CLASS="linkplain">Show readed confirmations list</A></DIV><% } else { out.write("?"); } %></TD>
          </TR>
          <TR>
            <TD ALIGN="right"></TD>
            <TD ALIGN="left">
            	<DIV ID="webbeacons" STYLE="display:none">
            	<TABLE SUMMARY="Web Beacons List" BORDER="1">
<%            if (nPgAtoms>0) {
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
									      sDisplayName = "<A HREF=\"#\" CLASS=\"linkplain\" onclick=\"modifyCompany('"+oEmailAddrs.getStringNull(2,iIxMbr,"")+"','"+oEmailAddrs.getStringNull(5,iIxMbr,"").replace('\n',' ').replace((char)39,' ')+"')\">"+oEmailAddrs.getStringNull(5,iIxMbr,"")+"</A>&nbsp;&lt;<A HREF=\"msg_new_f.jsp?to="+sTxEmail+"&gu_company="+oEmailAddrs.getStringNull(2,iIxMbr,"")+"\" TARGET=\"_blank\" CLASS=\"linkplain\">"+sTxEmail+"</A>&gt";
									    else
									      sDisplayName = "<A HREF=\"#\" CLASS=\"linkplain\" onclick=\"modifyContact('"+oEmailAddrs.getStringNull(1,iIxMbr,"")+"')\">"+oEmailAddrs.getStringNull(3,iIxMbr,"")+" "+oEmailAddrs.getStringNull(4,iIxMbr,"")+"</A>&nbsp;&lt;<A HREF=\"msg_new_f.jsp?to="+sTxEmail+"&gu_contact="+oEmailAddrs.getStringNull(1,iIxMbr,"")+"\" TARGET=\"_blank\" CLASS=\"linkplain\">"+sTxEmail+"</A>&gt";
							      }
							      StringBuffer oDates = new StringBuffer(256);
							      while (oWebBeacons.getInt(3,iIxAtm)==iPgAtm) {
							        nTimes++;
							        if (nTimes>1) oDates.append("<BR>");
							        oDates.append(oWebBeacons.getDateTime24(1,iIxAtm));							      
							        if (++iIxAtm==iWebBeacons) break;
							      } //wend
							      out.write("<TR><TD CLASS=\"formplain\">"+sDisplayName+"</TD><TD CLASS=\"formplain\">"+String.valueOf(nTimes)+"</TD><TD CLASS=\"formplain\">"+oDates.toString()+"</TD></TR>");
							    } // fi
							  } // next
              }
%>            </TABLE>  
              </DIV></TD>
          </TR>
          <TR>
            <TD ALIGN="right" CLASS="formplain">E-Mail User Agents</TD>
            <TD ALIGN="left">
              <TABLE SUMMARY="User Agents">
<%              Iterator<String> oIter = oAgents.keySet().iterator();
								NumberFormat oPctFmt = NumberFormat.getPercentInstance();
                while (oIter.hasNext()) {
                  sUserAgent = oIter.next();
                  float fAgentCount = oAgents.get(sUserAgent).floatValue();
                  out.write("<TR><TD CLASS=\"formplain\">"+oPctFmt.format(fAgentCount/nAgents)+"</TD><TD CLASS=\"formplain\">"+sUserAgent+"</TD></TR>");
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
    	      <INPUT TYPE="button" ACCESSKEY="o" VALUE="OK" CLASS="closebutton" STYLE="width:80" TITLE="ALT+o" onclick="window.history.back()">
    	      <BR><BR>
    	    </TD>
    	  </TR>            
        </TABLE>
      </TD></TR>
    </TABLE>                 
</BODY>
</HTML>

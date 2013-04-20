<%@ page import="java.net.URLDecoder,java.io.File,java.sql.SQLException,com.knowgate.acl.*,com.knowgate.jdc.JDCConnection,com.knowgate.dataobjs.DB,com.knowgate.dataobjs.DBBind,com.knowgate.dataobjs.DBSubset,com.knowgate.misc.Environment,com.knowgate.misc.Gadgets,com.knowgate.workareas.WorkArea,com.knowgate.scheduler.Atom" language="java" session="false" contentType="text/html;charset=UTF-8" %>
<%@ include file="../methods/dbbind.jsp" %><%@ include file="../methods/cookies.jspf" %><%@ include file="../methods/authusrs.jspf" %><%@ include file="../methods/nullif.jspf" %><%

  response.addHeader ("Pragma", "no-cache");
  response.addHeader ("cache-control", "no-store");
  response.setIntHeader("Expires", 0);

  String sLanguage = getNavigatorLanguage(request);  
  String sSkin = getCookie(request, "skin", "xp");

  String gu_workarea = getCookie(request,"workarea","");
  String id_user = getCookie (request, "userid", null);

  String sGuJob = request.getParameter("gu_job");
  String sStatusFilter = nullif(request.getParameter("id_status"));
  int iStatusFilterLen = sStatusFilter.length();

  // **********************************************

  int iAtomCount = 0;
  DBSubset oAtoms;
  DBSubset oAtomsArchived;
  String sOrderBy;
  int iOrderBy;  
  int iMaxRows;
  int iSkip;

  // 06. Maximum number of rows to display and row to start with

  try {  
    if (request.getParameter("maxrows")!=null)
      iMaxRows = Integer.parseInt(request.getParameter("maxrows"));
    else 
      iMaxRows = Integer.parseInt(getCookie(request, "maxrows", "100"));
  }
  catch (NumberFormatException nfe) { iMaxRows = 100; }
  
  if (request.getParameter("skip")!=null)
    iSkip = Integer.parseInt(request.getParameter("skip"));      
  else
    iSkip = 0;
    
  if (iSkip<0) iSkip = 0;

  // **********************************************

  // 07. Order by column
  
  if (request.getParameter("orderby")!=null)
    sOrderBy = request.getParameter("orderby");
  else
    sOrderBy = "";
  
  if (sOrderBy.length()>0)
    iOrderBy = Integer.parseInt(sOrderBy);
  else
    iOrderBy = 0;

  // **********************************************

  JDCConnection oConn = null;
  DBSubset oStatus = new DBSubset (DB.k_lu_job_status, "id_status,tr_en,tr_es,tr_de,tr_it,tr_fr,tr_pt,tr_ca,tr_eu,tr_ja,tr_cn,tr_tw,tr_ru", "1=1 ORDER BY 1", 10);
  int iStatus = 0, iMinStatus = 100, iMaxStatus = -100;
  boolean bIsAdmin = true;
  Object[] aFind;
  short[] aStatusId = null;
  String[] aStatusTx = null;
  short[] aTargetStatus;
  
  if (iStatusFilterLen==0 || sStatusFilter.equals(String.valueOf(Atom.STATUS_FINISHED)))
    aTargetStatus = null;
  else if (sStatusFilter.equals(String.valueOf(Atom.STATUS_ABORTED)))
    aTargetStatus = new short[]{Atom.STATUS_PENDING};
  else if (sStatusFilter.equals(String.valueOf(Atom.STATUS_PENDING)))
    aTargetStatus = new short[]{Atom.STATUS_ABORTED};
  else if (sStatusFilter.equals(String.valueOf(Atom.STATUS_RUNNING)))
    aTargetStatus = new short[]{Atom.STATUS_ABORTED};
  else if (sStatusFilter.equals(String.valueOf(Atom.STATUS_INTERRUPTED)))
    aTargetStatus = new short[]{Atom.STATUS_PENDING};

  try {

    oConn = GlobalDBBind.getConnection("atomlisting");  
        
    bIsAdmin = WorkArea.isAdmin (oConn, gu_workarea, id_user);
    
    if (!bIsAdmin) throw new SQLException("WorkArea Administrator rol is required for editing atoms");

    iStatus = oStatus.load(oConn);
    aStatusId = new short [iStatus];
    aStatusTx = new String[iStatus];
    for (int s=0; s<iStatus; s++) {
      aStatusId[s] = oStatus.getShort(0,s);
      if (sLanguage.equalsIgnoreCase("es"))
        aStatusTx[s] = oStatus.getString(2,s);
      else
        aStatusTx[s] = oStatus.getString(1,s);
    }

    if (iStatusFilterLen==0) {

      oAtomsArchived = new DBSubset ("k_job_atoms_archived",
      			     "pg_atom,dt_execution,id_status,tx_email,tx_log",
      			     DB.gu_job + "=?", iMaxRows);      				 

      oAtoms = new DBSubset ("k_job_atoms",
      			     "pg_atom,dt_execution,id_status,tx_email,tx_log",
      			     DB.gu_job + "=?", iMaxRows);      				 
      			     
      aFind = new Object[] { sGuJob };
    }
    else {

      oAtomsArchived = new DBSubset ("k_job_atoms_archived",
      			     "pg_atom,dt_execution,id_status,tx_email,tx_log",
      			     DB.gu_job + "=? " + " AND " + DB.id_status + "=?", iMaxRows);      				 

      oAtoms = new DBSubset ("k_job_atoms b", 
      				 "pg_atom,dt_execution,id_status,tx_email,tx_log",
      				 DB.gu_job + "=? " + " AND " + DB.id_status + "=?", iMaxRows);      				 

      oAtoms.setMaxRows(iMaxRows);

      aFind = new Object[] { sGuJob, Short.parseShort(sStatusFilter) };
    }
    oAtoms.setMaxRows(iMaxRows);
    oAtomsArchived.setMaxRows(iMaxRows);
		oAtomsArchived.load (oConn, aFind, iSkip);
		oAtoms.load (oConn, aFind, iSkip);
    oAtoms.union(oAtomsArchived);
    if (iOrderBy>0) oAtoms.sortBy(iOrderBy-1);
    iAtomCount = oAtoms.getRowCount();
    
    oConn.close("atomlisting"); 
  }
  catch (SQLException e) {  
    oAtoms = null;
    if (oConn!=null)
      if (!oConn.isClosed())
        oConn.close("atomlisting");
    oConn = null;
    response.sendRedirect (response.encodeRedirectUrl ("../common/errmsg.jsp?title=Error&desc=" + e.getLocalizedMessage() + "&resume=_close"));
  }
  
  if (null==oConn) return;
  
  oConn = null;  
%>
<HTML LANG="<% out.write(sLanguage); %>">
<HEAD>
  <SCRIPT TYPE="text/javascript" SRC="../javascript/cookies.js"></SCRIPT>  
  <SCRIPT TYPE="text/javascript" SRC="../javascript/setskin.js"></SCRIPT>
  <SCRIPT TYPE="text/javascript" SRC="../javascript/combobox.js"></SCRIPT>
  <SCRIPT TYPE="text/javascript" SRC="../javascript/getparam.js"></SCRIPT>
  <SCRIPT TYPE="text/javascript" DEFER="defer">
    <!--                    
<%
          // Write instance primary keys in a JavaScript Array
          // This Array is used when posting multiple elements
          
          out.write("var jsAtoms = new Array(");
          boolean bFirst = true;
            
            for (int i=0; i<iAtomCount; i++) {
              short iAtomStatus = oAtoms.getShort(2,i);
              if (iAtomStatus!=Atom.STATUS_FINISHED && iAtomStatus!=Atom.STATUS_PENDING && iAtomStatus!=Atom.STATUS_RUNNING) {
                if (bFirst)
                  bFirst=false;
                else
                  out.write(",");
                out.write("\"" + oAtoms.getString(0,i) + "\"");
              }
            }
            
          out.write(");\n        ");
%>

        // ----------------------------------------------------

		    function retrySelectedAtoms() {
          var frm = document.forms[0];
				  var chi = "";

          for (var c=0; c<jsAtoms.length; c++) {
            if (frm.elements["A"+jsAtoms[c]].checked) {
            	chi += (chi.length==0 ? "" : ",") + jsAtoms[c];
            } // fi
					} // next  
					if (chi.length==0) {
					  alert ("At least one atom to be re-executed must be selected first");
					  return false;
					} else {
					  frm.checkeditems.value = chi;
					  frm.submit();
					}
		    } // retrySelectedAtoms

        // ----------------------------------------------------

		    function retrySelectedAtoms() {
          var frm = document.forms[0];
				  var chi = "";

          for (var c=0; c<jsAtoms.length; c++) {
            if (frm.elements["A"+jsAtoms[c]].checked) {
            	chi += (chi.length==0 ? "" : ",") + jsAtoms[c];
            } // fi
					} // next  
					if (chi.length==0) {
					  alert ("At least one atom to be re-executed must be selected first");
					  return false;
					} else {
					  frm.checkeditems.value = chi;
					  frm.submit();
					}
		    } // retrySelectedAtoms
        // ----------------------------------------------------

		    function retrySelectedAtoms() {
          var frm = document.forms[0];
				  var chi = "";

          for (var c=0; c<jsAtoms.length; c++) {
            if (frm.elements["A"+jsAtoms[c]].checked) {
            	chi += (chi.length==0 ? "" : ",") + jsAtoms[c];
            } // fi
					} // next  
					if (chi.length==0) {
					  alert ("An atom to be suspended must be selected first");
					  return false;
					} else {
					  frm.checkeditems.value = chi;
					  frm.submit();
					}
		    } // retrySelectedAtoms

        // ----------------------------------------------------
        
        function filterByStatus(id) {
          var frm = document.forms[0];
	  	    window.location = "job_viewatoms.jsp?gu_job=<%=sGuJob%>&skip=0&orderby=<%=sOrderBy%>&field=" + getCombo(frm.sel_status) + "&id_status=" + getCombo(frm.sel_status);	        
        } // filterByStatus

        // ----------------------------------------------------

	      function sortBy(fld) { 
	        var frm = document.forms[0];
	  
	        window.location = "job_viewatoms.jsp?gu_job=<%=sGuJob%>&skip=0&orderby=" + fld + "&field=" + getCombo(frm.sel_status) + "&id_status=" + getCombo(frm.sel_status);
	      } // sortBy		

        // ----------------------------------------------------

        function selectAll() {
          var frm = document.forms[0];

          for (var c=0; c<jsAtoms.length; c++)                        
            eval ("frm.elements['A" + jsAtoms[c] + "'].click()");
        } // selectAll()
       
        // ----------------------------------------------------

    //-->    
  </SCRIPT>
  <SCRIPT TYPE="text/javascript">
    <!--
	    function setCombos() {
	      setCookie ("maxrows", "<%=iMaxRows%>");
	      setCombo(document.forms[0].maxresults, "<%=iMaxRows%>");
	      setCombo(document.forms[0].sel_status, "<%=sStatusFilter%>");
	    } // setCombos()
    //-->    
  </SCRIPT>
  <TITLE>hipergate :: List of atoms of a job</TITLE>
</HEAD>
<BODY TOPMARGIN="8" MARGINHEIGHT="8" onLoad="setCombos()">
    <DIV class="cxMnu1" style="width:220px"><DIV class="cxMnu2">
      <SPAN class="hmMnuOff" onMouseOver="this.className='hmMnuOn'" onMouseOut="this.className='hmMnuOff'" onClick="document.location='job_modify_f.jsp?gu_job=<%=sGuJob%>'"><IMG src="../images/images/toolmenu/historyback.gif" width="16" style="vertical-align:middle" height="16" border="0" alt="Back"> Back</SPAN>
      <SPAN class="hmMnuOff" onMouseOver="this.className='hmMnuOn'" onMouseOut="this.className='hmMnuOff'" onClick="location.reload(true)"><IMG src="../images/images/toolmenu/locationreload.gif" width="16" style="vertical-align:middle" height="16" border="0" alt="Refresh"> Refresh</SPAN>
    </DIV></DIV>
    <FORM METHOD="post" ACTION="<%=sStatusFilter.equals(String.valueOf(Atom.STATUS_PENDING)) ? "job_suspendatoms.jsp" : "job_retryatoms.jsp"%>">
      <INPUT TYPE="hidden" NAME="gu_job" VALUE="<%=sGuJob%>">
      <INPUT TYPE="hidden" NAME="maxrows" VALUE="<%=String.valueOf(iMaxRows)%>">
      <INPUT TYPE="hidden" NAME="skip" VALUE="<%=String.valueOf(iSkip)%>">      
      <INPUT TYPE="hidden" NAME="checkeditems">
      <TABLE CELLSPACING="2" CELLPADDING="2">
      <TR><TD COLSPAN="3" BACKGROUND="../images/images/loginfoot_med.gif" HEIGHT="3"></TD></TR>
      <TR>
        <TD VALIGN="bottom">&nbsp;&nbsp;<IMG SRC="../images/images/find16.gif" HEIGHT="16" BORDER="0" ALT="Find"></TD>
        <TD VALIGN="middle" CLASS="textplain">
          Status&nbsp;
          <SELECT NAME="sel_status" CLASS="combomini" onChange="filterByStatus(this.options[this.selectedIndex].value)"><OPTION VALUE="">All</OPTION>
            <% for (int s=0; s<iStatus; s++)
                 out.write("<OPTION VALUE=\""+String.valueOf(aStatusId[s])+"\">"+aStatusTx[s]+"</OPTION>");
            %>
          </SELECT>
        </TD>
        <TD VALIGN="bottom">
          <FONT CLASS="textplain">&nbsp;&nbsp;&nbsp;Show&nbsp;</FONT><SELECT CLASS="combomini" NAME="maxresults" onchange="setCookie('maxrows',getCombo(document.forms[0].maxresults));"><OPTION VALUE="10">10<OPTION VALUE="20">20<OPTION VALUE="50">50<OPTION VALUE="100">100<OPTION VALUE="200">200<OPTION VALUE="500">500</SELECT><FONT CLASS="textplain">&nbsp;&nbsp;&nbsp;results&nbsp;</FONT>
        </TD>
      </TR>
<% if (sStatusFilter.equals(String.valueOf(Atom.STATUS_SUSPENDED)) || sStatusFilter.equals(String.valueOf(Atom.STATUS_INTERRUPTED))) { %>
      <TR>
        <TD></TD>
        <TD VALIGN="middle" COLSPAN="2">
          <A HREF="#" CLASS="linkplain" onclick="retrySelectedAtoms()">Re-try execution of selected atoms</A>
        </TD>
      </TR>
<% } %>
<% if (sStatusFilter.equals(String.valueOf(Atom.STATUS_PENDING))) { %>
      <TR>
        <TD></TD>
        <TD VALIGN="middle" COLSPAN="2">
          <A HREF="#" CLASS="linkplain" onclick="suspendSelectedAtoms()">Suspend execution of selected atoms</A>
        </TD>
      </TR>
<% } %>
      <TR><TD COLSPAN="3" BACKGROUND="../images/images/loginfoot_med.gif" HEIGHT="3"></TD></TR>
      </TABLE>
      <TABLE CELLSPACING="1" CELLPADDING="0">
        <TR>
          <TD COLSPAN="3" ALIGN="left">
<%
    	  if (iAtomCount>0) {
            if (iSkip>0) // If iSkip>0 then we have prev items
              out.write("            <A HREF=\"job_viewatoms.jsp?skip=" + String.valueOf(iSkip-iMaxRows) + "&orderby=" + sOrderBy + "&id_status=" + sStatusFilter + "\" CLASS=\"linkplain\">&lt;&lt;&nbsp;Previous" + "</A>&nbsp;&nbsp;&nbsp;");
    
            if (!oAtoms.eof())
              out.write("            <A HREF=\"job_viewatoms.jsp?skip=" + String.valueOf(iSkip+iMaxRows) + "&orderby=" + sOrderBy + "&id_status=" + sStatusFilter + "\" CLASS=\"linkplain\">Next&nbsp;&gt;&gt;</A>");
	  } // fi (iAtomCount)
%>
          </TD>
        </TR>
        <TR>
          <TD CLASS="tableheader" BACKGROUND="../skins/<%=sSkin%>/tablehead.gif">&nbsp;<A HREF="javascript:sortBy(1);" oncontextmenu="return false;"><IMG SRC="../skins/<%=sSkin + (iOrderBy==1 ? "/sortedfld.gif" : "/sortablefld.gif")%>" WIDTH="14" HEIGHT="10" BORDER="0" ALT="Ordenar por este campo"></A></TD>
          <TD CLASS="tableheader" BACKGROUND="../skins/<%=sSkin%>/tablehead.gif">&nbsp;<A HREF="javascript:sortBy(3);" oncontextmenu="return false;"><IMG SRC="../skins/<%=sSkin + (iOrderBy==3 ? "/sortedfld.gif" : "/sortablefld.gif")%>" WIDTH="14" HEIGHT="10" BORDER="0" ALT="Ordenar por este campo"></A>&nbsp;<B>Status</B></TD>
          <TD CLASS="tableheader" BACKGROUND="../skins/<%=sSkin%>/tablehead.gif">&nbsp;<A HREF="javascript:sortBy(2);" oncontextmenu="return false;"><IMG SRC="../skins/<%=sSkin + (iOrderBy==2 ? "/sortedfld.gif" : "/sortablefld.gif")%>" WIDTH="14" HEIGHT="10" BORDER="0" ALT="Ordenar por este campo"></A>&nbsp;<B>Date</B></TD>
          <TD CLASS="tableheader" BACKGROUND="../skins/<%=sSkin%>/tablehead.gif">&nbsp;<A HREF="javascript:sortBy(4);" oncontextmenu="return false;"><IMG SRC="../skins/<%=sSkin + (iOrderBy==4 ? "/sortedfld.gif" : "/sortablefld.gif")%>" WIDTH="14" HEIGHT="10" BORDER="0" ALT="Ordenar por este campo"></A>&nbsp;<B>e-mail</B></TD>
          <TD CLASS="tableheader" BACKGROUND="../skins/<%=sSkin%>/tablehead.gif">&nbsp;<B>Comments</B></TD>
<% if (iStatusFilterLen>0) { %>
	  <TD CLASS="tableheader" BACKGROUND="../skins/<%=sSkin%>/tablehead.gif"><A HREF="#" onclick="selectAll()" TITLE="Select all"><IMG SRC="../images/images/selall16.gif" BORDER="0" ALT="Select all"></A></TD></TR>
<% }

	  int iStatIdx;
	  String sAtomPg, sExecDt, sStatusTx, sEMail, sLog, sStrip;
	  for (int i=0; i<iAtomCount; i++) {

            sAtomPg = String.valueOf(oAtoms.getInt(0,i));
            if (oAtoms.isNull(1,i))
              sExecDt = "";
            else
              sExecDt = oAtoms.getDateTime24(1,i);            
            
            sStatusTx = "?";
            for (int s=0; s<iStatus; s++) {
              if (oAtoms.getShort(2,i)==aStatusId[s]) {
                sStatusTx = aStatusTx[s];
                break;
              }
            }
            
            sEMail = oAtoms.getStringNull(3,i,"");
            sLog = oAtoms.getStringNull(4,i,"");

            sStrip = String.valueOf((i%2)+1);
%>            
            <TR HEIGHT="14">
              <TD CLASS="strip<% out.write (sStrip); %>">&nbsp;<%=sAtomPg%></TD>
              <TD CLASS="strip<% out.write (sStrip); %>">&nbsp;<%=sStatusTx%></TD>
              <TD CLASS="strip<% out.write (sStrip); %>">&nbsp;<%=sExecDt%></TD>
              <TD CLASS="strip<% out.write (sStrip); %>">&nbsp;<%=sEMail%></TD>
              <TD CLASS="strip<% out.write (sStrip); %>">&nbsp;<%=sLog%></TD>
<% if (iStatusFilterLen>0) { %>
              <TD CLASS="strip<% out.write (sStrip); %>" ALIGN="center"><INPUT VALUE="1" TYPE="checkbox" NAME="A<%=sAtomPg%>"></TD>
<% } %>
            </TR>
<%        } // next(i) %>          	  
      </TABLE>
    </FORM>
</BODY>
</HTML>
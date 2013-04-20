<%@ page import="java.net.URLDecoder,java.io.File,java.sql.SQLException,com.knowgate.acl.*,com.knowgate.jdc.JDCConnection,com.knowgate.dataobjs.DB,com.knowgate.dataobjs.DBBind,com.knowgate.dataobjs.DBSubset,com.knowgate.misc.Environment,com.knowgate.misc.Gadgets,com.knowgate.hipergate.QueryByForm" language="java" session="false" contentType="text/html;charset=UTF-8" %>
<%@ include file="../methods/dbbind.jsp" %><%@ include file="../methods/cookies.jspf" %><%@ include file="../methods/authusrs.jspf" %><%@ include file="../methods/nullif.jspf" %>
<jsp:useBean id="GlobalCacheClient" scope="application" class="com.knowgate.cache.DistributedCachePeer"/><%
 
  response.addHeader ("Pragma", "no-cache");
  response.addHeader ("cache-control", "no-store");
  response.setIntHeader("Expires", 0);

  String sLanguage = getNavigatorLanguage(request);  
  String sSkin = getCookie(request, "skin", "xp");

  String id_domain = getCookie(request,"domainid","");
  String n_domain = getCookie(request,"domainnm",""); 
  String gu_workarea = getCookie(request,"workarea","");

  String screen_width = request.getParameter("screen_width");

  int iScreenWidth;
  float fScreenRatio;

  if (screen_width==null)
    iScreenWidth = 800;
  else if (screen_width.length()==0)
    iScreenWidth = 800;
  else
    iScreenWidth = Integer.parseInt(screen_width);
  
  fScreenRatio = ((float) iScreenWidth) / 800f;
  if (fScreenRatio<1) fScreenRatio=1;

  String sField = nullif(request.getParameter("field"));
  String sFind = nullif(request.getParameter("find"));
  String sWhere = nullif(request.getParameter("where"));
  String sQuery = nullif(request.getParameter("query"));

  String sStorage = Environment.getProfilePath(GlobalDBBind.getProfileName(), "storage");

  // **********************************************

  int iCampaignCount = 0;
  int iSubrecordsCount = 0;
  DBSubset oCampaigns;        
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
  catch (NumberFormatException nfe) { iMaxRows = 10; }
  
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
  QueryByForm oQBF;
  boolean bIsGuest = true;
  
  try {

    bIsGuest = isDomainGuest (GlobalCacheClient, GlobalDBBind, request, response);
    
    // 08. Get a connection from pool

    oConn = GlobalDBBind.getConnection("campaignlisting");  
    
    // Results are stored in a DBSubset object and connection is closed.
    // Later the DBSubset is iterated and each row is send to HTML output.
    
    if (sWhere.length()>0) {

      // 09. QBF Filtered Listing
      
      oQBF = new QueryByForm("file://" + sStorage + "qbf" + File.separator + request.getParameter("queryspec") + ".xml");
    
      oCampaigns = new DBSubset (oQBF.getBaseObject(), 
      				 "b." + DB.gu_campaign + "," + "b." + DB.nm_campaign + ",b." + DB.dt_created + ",b." + DB.bo_active,
      				 "(" + oQBF.getBaseFilter(request) + ") " + sWhere + (iOrderBy>0 ? " ORDER BY " + sOrderBy : ""), iMaxRows);      				 
      
      oCampaigns.setMaxRows(iMaxRows);
      iCampaignCount = oCampaigns.load (oConn, iSkip);
    }
    
    else if (sFind.length()==0 || sField.length()==0) {
      
      // 10. If filter does not exist then return all rows up to maxrows limit

      oCampaigns = new DBSubset ("k_campaigns", 
      				 "gu_campaign,nm_campaign,dt_created,bo_active",
      				 DB.gu_workarea+ "='" + gu_workarea + "'" + (iOrderBy>0 ? " ORDER BY " + sOrderBy : ""), iMaxRows);      				 

      oCampaigns.setMaxRows(iMaxRows);
      iCampaignCount = oCampaigns.load (oConn, iSkip);
    }
    else {

      oCampaigns = new DBSubset ("k_campaigns b", 
      				 "gu_campaign,nm_campaign,dt_created,bo_active",
      				 "(" + DB.gu_workarea+ "='" + gu_workarea + "') AND (" + sField + " " + DBBind.Functions.ILIKE + " ?)" + (iOrderBy>0 ? " ORDER BY " + sOrderBy : ""), iMaxRows);      				 

      oCampaigns.setMaxRows(iMaxRows);

      Object[] aFind = { "%" + sFind + "%" };      
      iCampaignCount = oCampaigns.load (oConn, aFind, iSkip);
    }
    
    iSubrecordsCount = oCampaigns.loadSubrecords(oConn, DB.k_campaign_targets, DB.gu_campaign, 0);

    oConn.close("campaignlisting"); 
  }
  catch (SQLException e) {  
    oCampaigns = null;
    if (oConn!=null)
      if (!oConn.isClosed())
        oConn.close("campaignlisting");
    oConn = null;
    response.sendRedirect (response.encodeRedirectUrl ("../common/errmsg.jsp?title=Error&desc=" + e.getLocalizedMessage() + "&resume=_back"));
  }
  
  if (null==oConn) return;  
  oConn = null;  
  
  sendUsageStats(request, "campaign_list"); 

%><HTML LANG="<% out.write(sLanguage); %>">
<HEAD>
  <SCRIPT TYPE="text/javascript" SRC="../javascript/cookies.js"></SCRIPT>  
  <SCRIPT TYPE="text/javascript" SRC="../javascript/setskin.js"></SCRIPT>
  <SCRIPT TYPE="text/javascript" SRC="../javascript/combobox.js"></SCRIPT>
  <SCRIPT TYPE="text/javascript" SRC="../javascript/getparam.js"></SCRIPT>
  <SCRIPT TYPE="text/javascript" SRC="../javascript/simplevalidations.js"></SCRIPT>
  <SCRIPT TYPE="text/javascript" SRC="../javascript/dynapi3/dynapi.js"></SCRIPT>
  <SCRIPT TYPE="text/javascript">
    <!--
    dynapi.library.setPath('../javascript/dynapi3/');
    dynapi.library.include('dynapi.api.DynLayer');

    var menuLayer,addrLayer;
    dynapi.onLoad(init);
    function init() {
 
      setCombos();
      menuLayer = new DynLayer();
      menuLayer.setWidth(160);
      menuLayer.setHTML(rightMenuHTML);      
    }
    //-->
  </SCRIPT>
  <SCRIPT TYPE="text/javascript" SRC="../javascript/dynapi3/rightmenu.js"></SCRIPT>
  <SCRIPT TYPE="text/javascript" SRC="../javascript/dynapi3/floatdiv.js"></SCRIPT>
  <SCRIPT TYPE="text/javascript" DEFER="defer">
    <!--
        // Global variables for moving the clicked row to the context menu
        
        var jsCampaignId;
        var jsCampaignNm;
            
        <%
          // Write campaign primary keys in a JavaScript Array
          // This Array is used when posting multiple elements
          // for deletion.
          
          out.write("var jsCampaigns = new Array(");
            
            for (int i=0; i<iCampaignCount; i++) {
              if (i>0) out.write(","); 
              out.write("\"" + oCampaigns.getString(0,i) + "\"");
            }
            
          out.write(");\n        ");
        %>

        // ----------------------------------------------------

<% if (!bIsGuest) { %>
        
        // 12. Create new campaign

	function createCampaign() {	  
	  
	  self.open ("campaign_edit.jsp?id_domain=<%=id_domain%>&n_domain=" + escape("<%=n_domain%>") + "&gu_workarea=<%=gu_workarea%>", "editcampaign", "directories=no,toolbar=no,menubar=no,width=500,height=460");	  
	} // createCampaign()

        // ----------------------------------------------------

        // 13. Delete checked campaigns
	
	function deleteCampaigns() {
	  
	  var offset = 0;
	  var frm = document.forms[0];
	  var chi = frm.checkeditems;
	  	  
	  if (window.confirm("Are you sure that you want to delete the selected campaigns?")) {
	  	  
	    chi.value = "";	  	  
	    frm.action = "campaign_edit_delete.jsp?selected=" + getURLParam("selected") + "&subselected=" + getURLParam("subselected");
	  	  
	    for (var i=0;i<jsCampaigns.length; i++) {
              while (frm.elements[offset].type!="checkbox") offset++;
    	      if (frm.elements[offset].checked)
                chi.value += jsCampaigns[i] + ",";
              offset++;
	    } // next()
	    
	    if (chi.value.length>0) {
	      chi.value = chi.value.substr(0,chi.value.length-1);
              frm.submit();
            } // fi(chi!="")
          } // fi (confirm)
	} // deleteCampaigns()
<% } %>	
        // ----------------------------------------------------

        // 14. Modify Campaign

	      function modifyCampaign(id,nm) {
	  
	        self.open ("campaign_edit.jsp?id_domain=<%=id_domain%>&n_domain=" + escape("<%=n_domain%>") + "&gu_workarea=<%=gu_workarea%>" + "&gu_campaign=" + id + "&n_campaign=" + escape(nm), "editcampaign", "directories=no,toolbar=no,menubar=no,width=500,height=460");
	      } // modifyCampaign

	      function modifyCampaignTarget(id,tr) {
	  
	        self.open ("campaigntarget_edit.jsp?id_domain=<%=id_domain%>&n_domain=" + escape("<%=n_domain%>") + "&gu_workarea=<%=gu_workarea%>" + "&gu_campaign=" + id + "&gu_campaign_target=" + tr, "editcampaigntarget", "directories=no,toolbar=no,menubar=no,width=500,height=460");
	      } // modifyCampaign

        // ----------------------------------------------------

        // 15. Reload Page sorting by a field

	function sortBy(fld) {
	  
	  var frm = document.forms[0];
	  
	  window.location = "campaign_list.jsp?id_domain=<%=id_domain%>&n_domain=" + escape("<%=n_domain%>") + "&skip=0&orderby=" + fld + "&where=" + escape("<%=sWhere%>") + "&field=" + getCombo(frm.sel_searched) + "&find=" + escape(frm.find.value) + "&selected=" + getURLParam("selected") + "&subselected=" + getURLParam("subselected") + "&screen_width=" + String(screen.width);
	} // sortBy		

        // ----------------------------------------------------

        // 16. Select All Campaigns

        function selectAll() {
          
          var frm = document.forms[0];
          
          for (var c=0; c<jsCampaigns.length; c++)                        
            eval ("frm.elements['" + jsCampaigns[c] + "'].click()");
        } // selectAll()
       
        // ----------------------------------------------------

        // 17. Reload Page finding campaigns by a single field
	
	function findCampaign() {
	  	  
	  var frm = document.forms[0];

	  if (hasForbiddenChars(frm.find.value)) {
		  alert ("String sought contains invalid characters");
			frm.find.focus();
			return false;
		}
	  
	  if (frm.find.value.length>0)
	    window.location = "campaign_list.jsp?id_domain=<%=id_domain%>&n_domain=" + escape("<%=n_domain%>") + "&skip=0&orderby=<%=sOrderBy%>&field=" + getCombo(frm.sel_searched) + "&find=" + escape(frm.find.value) + "&selected=" + getURLParam("selected") + "&subselected=" + getURLParam("subselected") + "&screen_width=" + String(screen.width);
	  else
	    window.location = "campaign_list.jsp?id_domain=<%=id_domain%>&n_domain=" + escape("<%=n_domain%>") + "&skip=0&orderby=<%=sOrderBy%>&selected=" + getURLParam("selected") + "&subselected=" + getURLParam("subselected") + "&screen_width=" + String(screen.width);
	  
	} // findCampaign()

      // ----------------------------------------------------

      var intervalId;
      var winclone;

      // This function is called every 100 miliseconds for testing
      // whether or not clone call has finished.
      
      function findCloned() {
        
        if (winclone.closed) {
          clearInterval(intervalId);
          setCombo(document.forms[0].sel_searched, "<%=DB.nm_campaign%>");
          document.forms[0].find.value = jsCampaignNm;
          findCampaign();
        }
      } // findCloned()

      // 18. Clone an campaign using an XML data structure definition
      
      function clone() {        
        // Open a clone window and wait for it to be closed
        
        winclone = window.open ("../common/clone.jsp?id_domain=<%=id_domain%>&n_domain=" + escape("<%=n_domain%>") + "&datastruct=campaign_clon&gu_instance=" + jsCampaignId +"&opcode=CCAM&classid=300", null, "directories=no,toolbar=no,menubar=no,width=320,height=200");                
        intervalId = setInterval ("findCloned()", 100);
      }	// clone()
      
      // ------------------------------------------------------	
    //-->    
  </SCRIPT>
  <SCRIPT TYPE="text/javascript">
    <!--
	function setCombos() {
	  setCookie ("maxrows", "<%=iMaxRows%>");
	  setCombo(document.forms[0].maxresults, "<%=iMaxRows%>");
	  setCombo(document.forms[0].sel_searched, "<%=sField%>");
	} // setCombos()
    //-->    
  </SCRIPT>
  <TITLE>hipergate :: List of Campaigns</TITLE>
</HEAD>
<BODY  TOPMARGIN="8" MARGINHEIGHT="8" onClick="hideRightMenu()">
    <%@ include file="../common/tabmenu.jspf" %>
    <FORM METHOD="post">
      <TABLE><TR><TD WIDTH="<%=iTabWidth*iActive%>" CLASS="striptitle"><FONT CLASS="title1">List of Campaigns</FONT></TD></TR></TABLE>  
      <INPUT TYPE="hidden" NAME="id_domain" VALUE="<%=id_domain%>">
      <INPUT TYPE="hidden" NAME="n_domain" VALUE="<%=n_domain%>">
      <INPUT TYPE="hidden" NAME="gu_workarea" VALUE="<%=gu_workarea%>">
      <INPUT TYPE="hidden" NAME="maxrows" VALUE="<%=String.valueOf(iMaxRows)%>">
      <INPUT TYPE="hidden" NAME="skip" VALUE="<%=String.valueOf(iSkip)%>">      
      <INPUT TYPE="hidden" NAME="where" VALUE="<%=sWhere%>">
      <INPUT TYPE="hidden" NAME="checkeditems">
      <!-- 19. Top controls and filters -->
      <TABLE SUMMARY="Top controls and filters" CELLSPACING="2" CELLPADDING="2">
      <TR><TD COLSPAN="8" BACKGROUND="../images/images/loginfoot_med.gif" HEIGHT="3"></TD></TR>
      <TR>
<% if (bIsGuest) { %>      
        <TD COLSPAN="4"></TD>
<% } else { %>
        <TD>&nbsp;&nbsp;<IMG SRC="../images/images/new16x16.gif" WIDTH="16" HEIGHT="16" BORDER="0" ALT="New"></TD>
        <TD VALIGN="middle"><A HREF="#" onclick="createCampaign()" CLASS="linkplain">New</A></TD>
        <TD>&nbsp;&nbsp;<IMG SRC="../images/images/papelera.gif" WIDTH="16" HEIGHT="16" BORDER="0" ALT="Delete"></TD>
        <TD><A HREF="#" onclick="deleteCampaigns()" CLASS="linkplain">Delete</A></TD>
<% } %>
        <TD VALIGN="bottom">&nbsp;&nbsp;<IMG SRC="../images/images/find16.gif" HEIGHT="16" BORDER="0" ALT="Search"></TD>
        <TD VALIGN="middle">
          <SELECT NAME="sel_searched" CLASS="combomini"><OPTION VALUE=""></OPTION><OPTION VALUE="<%=DB.nm_campaign%>">Name</OPTION></SELECT>
          <INPUT CLASS="textmini" TYPE="text" NAME="find" MAXLENGTH="50" VALUE="<%=sFind%>">
	  &nbsp;<A HREF="javascript:findCampaign();" CLASS="linkplain" TITLE="Search">Search</A>	  
        </TD>
        <TD VALIGN="bottom">&nbsp;&nbsp;&nbsp;<IMG SRC="../images/images/findundo16.gif" HEIGHT="16" BORDER="0" ALT="Discard Search"></TD>
        <TD VALIGN="bottom">
          <A HREF="javascript:document.forms[0].find.value='';findCampaign();" CLASS="linkplain" TITLE="Discard Search">Discard</A>
          <FONT CLASS="textplain">&nbsp;&nbsp;&nbsp;Show&nbsp;</FONT><SELECT CLASS="combomini" NAME="maxresults" onchange="setCookie('maxrows',getCombo(document.forms[0].maxresults));"><OPTION VALUE="10">10<OPTION VALUE="20">20<OPTION VALUE="50">50<OPTION VALUE="100">100<OPTION VALUE="200">200<OPTION VALUE="500">500</SELECT><FONT CLASS="textplain">&nbsp;&nbsp;&nbsp;results&nbsp;</FONT>
        </TD>
      </TR>
      <TR><TD COLSPAN="8" BACKGROUND="../images/images/loginfoot_med.gif" HEIGHT="3"></TD></TR>
      </TABLE>
      <!-- End Top controls and filters -->
      <TABLE SUMMARY="Data" CELLSPACING="1" CELLPADDING="0">
        <TR>
          <TD COLSPAN="3" ALIGN="left">
<%
    	  // 20. Paint Next and Previous Links
    
    	  if (iCampaignCount>0) {
            if (iSkip>0) // If iSkip>0 then we have prev items
              out.write("            <A HREF=\"campaign_list.jsp?id_domain=" + id_domain + "&n_domain=" + n_domain + "&skip=" + String.valueOf(iSkip-iMaxRows) + "&orderby=" + sOrderBy + "&field=" + sField + "&find=" + sFind + "&selected=" + request.getParameter("selected") + "&subselected=" + request.getParameter("subselected") + "\" CLASS=\"linkplain\">&lt;&lt;&nbsp;Previous" + "</A>&nbsp;&nbsp;&nbsp;");
    
            if (!oCampaigns.eof())
              out.write("            <A HREF=\"campaign_list.jsp?id_domain=" + id_domain + "&n_domain=" + n_domain + "&skip=" + String.valueOf(iSkip+iMaxRows) + "&orderby=" + sOrderBy + "&field=" + sField + "&find=" + sFind + "&selected=" + request.getParameter("selected") + "&subselected=" + request.getParameter("subselected") + "\" CLASS=\"linkplain\">Next&nbsp;&gt;&gt;</A>");
	  } // fi (iCampaignCount)
%>
          </TD>
        </TR>
        <TR>
          <TD CLASS="tableheader" WIDTH="400" BACKGROUND="../skins/<%=sSkin%>/tablehead.gif">&nbsp;<A HREF="javascript:sortBy(2);" oncontextmenu="return false;"><IMG SRC="../skins/<%=sSkin + (iOrderBy==2 ? "/sortedfld.gif" : "/sortablefld.gif")%>" WIDTH="14" HEIGHT="10" BORDER="0" ALT="Ordenar por este campo"></A>&nbsp;<B>Name</B></TD>
          <TD CLASS="tableheader" WIDTH="150" BACKGROUND="../skins/<%=sSkin%>/tablehead.gif">&nbsp;<A HREF="javascript:sortBy(3);" oncontextmenu="return false;"><IMG SRC="../skins/<%=sSkin + (iOrderBy==3 ? "/sortedfld.gif" : "/sortablefld.gif")%>" WIDTH="14" HEIGHT="10" BORDER="0" ALT="Ordenar por este campo"></A>&nbsp;<B>Creation Date</B></TD>
          <TD CLASS="tableheader" BACKGROUND="../skins/<%=sSkin%>/tablehead.gif"><A HREF="#" onclick="selectAll()" TITLE="select all"><IMG SRC="../images/images/selall16.gif" BORDER="0" ALT="select all"></A></TD></TR>
<%
    	  // 21. List rows

	      String sInstId, sInstNm;
	      for (int i=0; i<iCampaignCount; i++) {
            sInstId = oCampaigns.getString(0,i);
            sInstNm = oCampaigns.getStringHtml(1,i,"");
            
%>          <TR HEIGHT="14">
              <TD CLASS="strip2" WIDTH="400">&nbsp;<A HREF="#" oncontextmenu="jsCampaignId='<%=sInstId%>'; jsCampaignNm='<%=sInstNm%>'; return showRightMenu(event);" onclick="modifyCampaign('<%=sInstId%>','<%=sInstNm%>')" TITLE="Click right mouse button to see the context menu"><%=sInstNm%></A></TD>
              <TD CLASS="strip2" WIDTH="150">&nbsp;<%=oCampaigns.getDateShort(2,i)%></TD>
              <TD CLASS="strip2" ALIGN="center"><INPUT VALUE="1" TYPE="checkbox" NAME="<% out.write (sInstId); %>"></TD>
            </TR>
<% if (iSubrecordsCount>0) {
     DBSubset oSubRecs = oCampaigns.getSubrecords(i);
     int iStartColPos = oSubRecs.getColumnPosition(DB.dt_start);
     int iEndColPos = oSubRecs.getColumnPosition(DB.dt_end);      
     if (oSubRecs.getRowCount()>0) {
       oSubRecs.sortBy(iStartColPos);
       for (int s=0; s<oSubRecs.getRowCount(); s++) {
          %>
            <TR HEIGHT="14">
              <TD CLASS="strip1" COLSPAN="3">&nbsp;&nbsp;&nbsp;&nbsp;<A HREF="#" CLASS="linksmall" onclick="modifyCampaignTarget('<%=oSubRecs.getString(DB.gu_campaign,s)%>','<%=oSubRecs.getString(DB.gu_campaign_target,s)%>')"><%=oSubRecs.getDateShort(iStartColPos,s)+"&nbsp;&rarr;&nbsp;"+oSubRecs.getDateShort(iEndColPos,s)%></A></TD>
            </TR>
<% } } } // fi (iSubrecordsCount>0)
        } // next(i) %>          	  
      </TABLE>
    </FORM>
    <!-- 22. DynFloat Right-click context menu -->
    <SCRIPT TYPE="text/javascript">
      <!--
      addMenuOption("Open","modifyCampaign(jsCampaignId)",1);
      addMenuOption("Clone","clone()",0);
      addMenuSeparator();
      //-->
    </SCRIPT>
    <!-- /RightMenuBody -->    
</BODY>
</HTML>
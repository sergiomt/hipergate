<%@ page import="java.io.File,java.io.FileNotFoundException,java.util.HashMap,java.util.Properties,java.net.URLDecoder,java.sql.PreparedStatement,java.sql.SQLException,java.util.Date,java.text.SimpleDateFormat,javax.portlet.GenericPortlet,com.knowgate.jdc.*,com.knowgate.acl.*,com.knowgate.dataobjs.*,com.knowgate.hipergate.DBLanguages,com.knowgate.misc.Gadgets,com.knowgate.http.portlets.*" language="java" session="false" contentType="text/html;charset=UTF-8" %>
<%@ include file="../methods/dbbind.jsp" %><%@ include file="../methods/cookies.jspf" %><%@ include file="../methods/nullif.jspf" %><%@ include file="../methods/authusrs.jspf" %>
<jsp:useBean id="GlobalCacheClient" scope="application" class="com.knowgate.cache.DistributedCachePeer"/><%@ include file="oportunity_listing.jspf" %><%@ include file="../methods/globalportletconfig.jspf" %><%
oConn = GlobalDBBind.getConnection("oportunitylisting",true);
%><%@ include file="oportunity_listbox.jspf" %><%
oConn.close("oportunitylisting");
%><HTML LANG="<% out.write(sLanguage); %>">
<HEAD>
  <TITLE>hipergate :: Opportunity Listing</TITLE>
  <SCRIPT TYPE="text/javascript" SRC="../javascript/cookies.js"></SCRIPT>  
  <SCRIPT TYPE="text/javascript" SRC="../javascript/setskin.js"></SCRIPT>
  <SCRIPT TYPE="text/javascript" SRC="../javascript/combobox.js"></SCRIPT>
  <SCRIPT TYPE="text/javascript" SRC="../javascript/getparam.js"></SCRIPT>
  <SCRIPT TYPE="text/javascript" SRC="../javascript/getparam.js"></SCRIPT>
  <SCRIPT TYPE="text/javascript" SRC="../javascript/datefuncs.js"></SCRIPT>
  <SCRIPT TYPE="text/javascript" SRC="../javascript/dynapi3/dynapi.js"></SCRIPT>
  <SCRIPT TYPE="text/javascript">
    dynapi.library.setPath('../javascript/dynapi3/');
    dynapi.library.include('dynapi.api.DynLayer');

    var menuLayer,addrLayer;
    dynapi.onLoad(init);
    function init() {
 
      setCombos();
      menuLayer = new DynLayer();
      menuLayer.setWidth(160);
      menuLayer.setVisible(true);
      menuLayer.setHTML(rightMenuHTML);
    }
  </SCRIPT>
  <SCRIPT TYPE="text/javascript" SRC="../javascript/dynapi3/rightmenu.js"></SCRIPT>
  <SCRIPT TYPE="text/javascript" DEFER="defer">
    <!--
      var jsOportunityId;
      var jsOportunityTl;
      var jsContactId;
      var jsCompanyId;

        <%          
          out.write("var jsOportunities = new Array(");
            for (int i=0; i<iOportunityCount; i++) {
              if (i>0) out.write(","); 
              out.write("\"" + oOportunities.getString(0,i) + "\"");
            }
          out.write(");\n        ");
        %>

        // ----------------------------------------------------

	function newOportunity() {	  
<% if (bIsGuest) { %>
        alert("Your credential level as Guest does not allow you to perform this action");
<% } else { %>
	  self.open ("oportunity_new.jsp?id_domain=<%=id_domain%>&n_domain=" + escape("<%=n_domain%>") + "&gu_workarea=<%=gu_workarea%>", "newoportunity", "directories=no,toolbar=no,scrollbars=yes,menubar=no,width=660,height=" + (screen.height<=600 ? "520" : "660"));	  
<% } %>
	} // newOportunity()

        // ----------------------------------------------------
        	
	function createOportunity (contact_id,company_id) {

	  self.open ("oportunity_edit.jsp?id_domain=<%=id_domain%>&n_domain=" + escape("<%=n_domain%>") + "&gu_workarea=<%=gu_workarea%>&gu_contact=" + contact_id + "&gu_company=" + company_id, "createoportunity", "directories=no,toolbar=no,menubar=no,width=660,height=660");	  
	} // createOportunity()

        // ----------------------------------------------------
	
	function deleteOportunities() {
	  var offset = 0;
	  var frm = document.forms[0];
	  var chi = frm.checkeditems;
	  	  
	  chi.value = "";
	  	  
	  frm.action = "oportunity_edit_delete.jsp";
                 
          while (frm.elements[offset].type!="checkbox") offset++;
                 
	  for (var i=0; i<jsOportunities.length; i++)	    	    
	    if (frm.elements[i+offset].checked)
              chi.value += jsOportunities[i] + ",";	              
	  
	  if (chi.value.length>0)
	    chi.value = chi.value.substr(0,chi.value.length-1);
	    
          frm.submit();
	} // deleteOportunities()
	
	
	//------------------------------------------
	      
  function findOportunity() {	 
	  var frm = document.forms[0];
	  
	  if (getCombo(frm.sel_searched)=="<%=DB.dt_next_action%>" && !isDate(frm.find.value, "d")) {
	  	alert ("Date for next action is not valid");
	  	frm.find.focus();
	  	return false;
	  }
	  window.parent.location = "oportunity_listing_f.jsp?id_domain=<%=id_domain%>&n_domain=" + escape("<%=n_domain%>") + "&skip=0&orderby=<%=String.valueOf(iOrderBy)%>&field=" + getCombo(frm.sel_searched) + "&find=" + escape(frm.find.value) + "&id_status=" + getCombo(frm.sel_status) + "&id_objetive=" + getCombo(frm.sel_objetive) + <% if (bCampaignsEnabled) out.write("\"&gu_campaign=\" + getCombo(frm.sel_campaign) + "); if (bIsAdmin && sSalesMenLookUp.length()>0) out.write("\"&gu_sales_man=\" + getCombo(frm.sel_salesman) + "); %> "&private=<%=String.valueOf(iPrivate)%>&selected=" + getURLParam("selected") + "&subselected=" + getURLParam("subselected");	
	} // findOportunity()
	
	// ----------------------------------------------------
		
	function sortBy(fld) {
	  var frm = document.forms[0];
	  if ("<%=sField%>"=="<%=DB.dt_next_action%>" && !isDate("<%=sFind%>", "d")) {
	  	alert ("Date for next action is not valid");
	  	frm.find.focus();
	  	return false;
	  }
	  window.parent.location = "oportunity_listing_f.jsp?id_domain=<%=id_domain%>&n_domain=" + escape("<%=n_domain%>") + "&skip=0&orderby=" + fld + "&field=<%=sField%>&find=<%=sFind%>" + "&id_status=" + getCombo(frm.sel_status) + "&id_objetive=" + getCombo(frm.sel_objetive) + <% if (bCampaignsEnabled) out.write("\"&gu_campaign=\" + getCombo(frm.sel_campaign) + "); if (bIsAdmin && sSalesMenLookUp.length()>0) out.write("\"&gu_sales_man=\" + getCombo(frm.sel_salesman) + "); %> "&selected=" + getURLParam("selected") + "&private=<%=String.valueOf(iPrivate)%>&subselected=" + getURLParam("subselected");
	} // sortBy

	// ----------------------------------------------------

	function modifyOportunity(id,contact,company) {
	  self.open ("oportunity_edit.jsp?id_domain=<%=id_domain%>&n_domain=" + escape("<%=n_domain%>") + "&gu_oportunity=" + id +"&gu_company=" + company + "&gu_contact=" + contact, "editoportunity", "directories=no,toolbar=no,menubar=no,width=660,height=660");
	}	

      // ------------------------------------------------------

      function addPhoneCall(op,cn,cp) {
<% if (bIsGuest) { %>
        alert("Your credential level as Guest does not allow you to perform this action");
<% } else { %>
        window.open("phonecall_record.jsp?id_domain=<%=id_domain%>&n_domain=" + escape("<%=n_domain%>") + "&gu_workarea=<%=gu_workarea%>&gu_user=" + getCookie("userid") + "&gu_oportunity=" + op + "&gu_contact=" + cn + "&gu_campaign=" + (cp==null ? "" : cp), "recordphonecall", "directories=no,toolbar=no,menubar=no,width=660,height=660");
<% } %>        
      } // addPhoneCall

        // ----------------------------------------------------

  function modifyContact(id) {
	  self.open ("contact_edit.jsp?id_domain=<%=id_domain%>&n_domain=" + escape("<%=n_domain%>") + "&gu_contact=" + id, "editcontact", "directories=no,toolbar=no,scrollbars=yes,menubar=no,width=660,height=660");
	}	

        // ----------------------------------------------------

	function modifyCompany(id,nm) {
	  self.open ("company_edit.jsp?id_domain=<%=id_domain%>&n_domain=" + escape("<%=n_domain%>") + "&gu_company=" + id + "&n_company=" + nm + "&gu_workarea=<%=gu_workarea%>", "editcompany", "directories=no,scrollbars=yes,toolbar=no,menubar=no,width=660,height=660");
	}	

        // ----------------------------------------------------
	
	function selectAll() {	
	  var frm = document.forms[0];
          
          for (var c=0; c<frm.length; c++)                        
            if (frm.elements[c].type=="checkbox")
              frm.elements[c].click();                                    
	}	

        // ----------------------------------------------------

	function reloadPrivate(prv) {	
	  var ref;
	  var url = window.location.href;
	  var idx = url.indexOf("&private=");
	   
	  if (idx==-1)
	    window.location.href = url + "&private=" + String(prv);
	  else {
	    ref = url.substring(0,idx+9) + String(prv)
	    if (idx+10<url.length) ref += url.substring(idx+10);
	    window.location.href = ref;
	  }
	}

      // ----------------------------------------------------

      var intervalId;
      var winclone;
      
      function findCloned() {
        
        if (winclone.closed) {
          clearInterval(intervalId);
          setCombo(document.forms[0].sel_searched, "<%=DB.tl_oportunity%>");
          document.forms[0].find.value = jsOportunityTl;
          findOportunity();
        }
      } // findCloned()
      
      function clone() {        
        winclone = window.open ("../common/clone.jsp?id_domain=<%=id_domain%>&n_domain=" + escape("<%=n_domain%>") + "&datastruct=oportunity_clon&gu_instance=" + jsOportunityId +"&opcode=COPO&classid=92", "cloneoportunity", "directories=no,toolbar=no,menubar=no,width=320,height=200");                
        intervalId = setInterval ("findCloned()", 100);
      }	// clone()
	
    //-->      
  </SCRIPT>  
   <SCRIPT TYPE="text/javascript">
    <!--
	function setCombos() {
		var frm = document.forms[0];
	  setCookie ("maxrows", "<%=iMaxRows%>");
	  setCombo(frm.maxresults, "<%=iMaxRows%>");
	  setCombo(frm.sel_searched, "<%=sField.equals(DB.gu_contact) ? "tx_contact" : sField%>");
    setCombo(frm.sel_status, getURLParam("id_status"));
<% if (bCampaignsEnabled) { %>
    setCombo(frm.sel_campaign, getURLParam("gu_campaign"));
<% }
   if (bIsAdmin && sSalesMenLookUp.length()>0) { %>
    setCombo(frm.sel_salesman, getURLParam("gu_sales_man"));
<% } %>	    
    setCombo(frm.sel_objetive, getURLParam("id_objetive"));
   	} // setCombos()
    //-->    
  </SCRIPT>
    
  <STYLE TYPE="text/css">
    <!--
      .tab { font-family: sans-serif; font-size: 12px; line-height:150%; font-weight: bold; position:absolute; text-align:center; border:2px; border-color:#999999; border-style:outset; border-bottom-style:none; width:90px; margin:0px; height: 30px; cursor: hand }
  
      .panel { font-family: sans-serif; font-size: 12px; position:absolute; border: 2px; border-color:#999999; border-style:outset; width: 520px; height: 296px; left:0px; top:28px; margin:0px; padding:6px; }
    -->
  </STYLE>
 </HEAD>

<BODY  TOPMARGIN="8" MARGINHEIGHT="8" onClick="hideRightMenu()">
    <%@ include file="../common/tabmenu.jspf" %>
    <FORM name=f1 METHOD="post" onSubmit="findOportunity();return false;">     
      <TABLE><TR><TD WIDTH="<%=iTabWidth*iActive%>" CLASS="striptitle"><FONT CLASS="title1">Opportunity Listing</FONT></TD></TR></TABLE>       
      <INPUT TYPE="hidden" NAME="id_domain" VALUE="<%=id_domain%>">
      <INPUT TYPE="hidden" NAME="n_domain" VALUE="<%=n_domain%>">
      <INPUT TYPE="hidden" NAME="gu_workarea" VALUE="<%=gu_workarea%>">
      <INPUT TYPE="hidden" NAME="maxrows" VALUE="<%=String.valueOf(iMaxRows)%>">
      <INPUT TYPE="hidden" NAME="skip" VALUE="<%=String.valueOf(iSkip)%>">      
      <INPUT TYPE="hidden" NAME="checkeditems">
      <INPUT TYPE="hidden" NAME="where" VALUE="<%=sWhere%>">
      <INPUT TYPE="hidden" NAME="selected" VALUE="<%=nullif(request.getParameter("selected"),"2")%>">
      <INPUT TYPE="hidden" NAME="subselected" VALUE="<%=nullif(request.getParameter("subselected"),"2")%>">

      <TABLE SUMMARY="Search Options" CELLSPACING="2" CELLPADDING="2" BORDER="0">
        <TR>
        	<TD COLSPAN="6" BACKGROUND="../images/images/loginfoot_med.gif" HEIGHT="3"></TD>
          <TD VALIGN="top" ROWSPAN="<%=String.valueOf(10+(bCampaignsEnabled ? 1 : 0)+(bIsAdmin && sSalesMenLookUp.length()>0 ? 1 : 0))%>"><%
          	/*
          	if (oPortlets.getRowCount()>0) {
              Class oPorletCls = Class.forName (oPortlets.getString(0,0));
              if (null==oPorletCls) throw new ClassNotFoundException("Portlet class not found "+oPortlets.getString(0,0));
	            GenericPortlet oPorlet = (GenericPortlet) oPorletCls.newInstance();
              if (null==oPorlet) throw new InstantiationException("Could not instantiate "+oPortlets.getString(0,0));
 	            oPorlet.init(GlobalPortletConfig);
	  				  portletRequest.setWindowState("NORMAL");
              EnvPros.put("modified", oPortlets.getDate(3,0));
              EnvPros.put("template", sRealPath+"includes"+File.separator+oPortlets.getString(4,0));
              EnvPros.put("zone", oPortlets.getString(5,0));
 	            try {
 	              oPorlet.render(portletRequest, portletResponse);
              } catch (FileNotFoundException fnfe) {
              }catch (Exception xcpt) {
                out.write(xcpt.getClass().getName()+" could not show portlet "+oPortlets.getString(0,0)+" "+xcpt.getMessage());
              }
            }
            */
            %>
          </TD>
        </TR>
        <TR>
<% if (sContactId.length()>0 || sCompanyId.length()>0) {%>
          <TD>&nbsp;&nbsp;<IMG SRC="../images/images/new16x16.gif" WIDTH="16" HEIGHT="16" BORDER="0" ALT="New Opportunity"></TD>
          <TD><A HREF="#" onclick="createOportunity('<%=sContactId%>','<%=sCompanyId%>');return false;" CLASS="linkplain">New</A></TD>        
<% } else { %>
          <TD>&nbsp;&nbsp;<IMG SRC="../images/images/new16x16.gif" WIDTH="16" HEIGHT="16" BORDER="0" ALT="New Opportunity"></TD>
          <TD ALIGN="left"><A HREF="#" onclick="newOportunity()" CLASS="linkplain">New</A></TD>
<% } %>
          <TD WIDTH="18"><IMG SRC="../images/images/papelera.gif" WIDTH="16" HEIGHT="16" BORDER="0" ALT="Delete Opportunity"></TD>
          <TD ALIGN="left">
<% if (bIsGuest) { %>
            <A HREF="#" onclick="alert('Your credential level as Guest does not allow you to perform this action')" CLASS="linkplain">Delete</A>
<% } else { %>
            <A HREF="#" onclick="deleteOportunities();return false;" CLASS="linkplain">Delete</A>
<% } %>
          </TD>
          <TD>&nbsp;&nbsp;<IMG SRC="../images/images/excel16.gif" HEIGHT="16" BORDER="0" ALT="Excel">&nbsp;<A HREF="oportunity_listing_xls.jsp?<%=request.getQueryString()%>&maxrows=65000" TARGET="_blank" CLASS="linkplain" TITLE="Excel Listing">Excel Listing</A></TD>
        </TR>
			  <TR>
          <TD></TD>
	        <TD><SELECT NAME="sel_searched" CLASS="combomini" onchange="if (this.options[this.selectedIndex].value=='<%=DB.dt_next_action%>' && document.forms[0].find.value.length==0) document.forms[0].find.value=dateToString(new Date(),'d')"><OPTION VALUE="<%=DB.tl_oportunity%>">Title<OPTION VALUE="<%=DB.tx_contact%>">Contact<OPTION VALUE="<%=DB.tx_company%>">Company<OPTION VALUE="<%=DB.dt_next_action%>">Next Action</SELECT></TD>
	        <TD COLSPAN="2"><INPUT TYPE="text" NAME="find" MAXLENGTH="50" VALUE="<%=sField.equals(DB.gu_contact) ? sFullName : sFind%>"></TD>
          <TD ALIGN="right"><FONT CLASS="textplain">Status&nbsp;</FONT></TD>
          <TD><SELECT NAME="sel_status" CLASS="combomini"><OPTION VALUE=""></OPTION><%=sStatusLookUp%></SELECT></TD>
        </TR>
<% if (bCampaignsEnabled) { %>
        <TR>
          <TD></TD>
          <TD><FONT CLASS="textplain">Campaign</FONT></TD>
          <TD COLSPAN="4"><SELECT NAME="sel_campaign" CLASS="combomini"><OPTION VALUE=""></OPTION><%=sCampaignsLookUp%></SELECT>
        </TR>
<% } %>
        <TR>
          <TD></TD>
          <TD><FONT CLASS="textplain">Objective</FONT></TD>
          <TD COLSPAN="4"><SELECT NAME="sel_objetive" CLASS="combomini"><OPTION VALUE=""></OPTION><%=sObjectiveLookUp%></SELECT>
        </TR>
<% if (bIsAdmin && sSalesMenLookUp.length()>0) { %>
        <TR>
          <TD></TD>
          <TD><FONT CLASS="textplain">Salesman</FONT></TD>
          <TD COLSPAN="4"><SELECT NAME="sel_salesman" CLASS="combomini"><OPTION VALUE=""></OPTION><%=sSalesMenLookUp%></SELECT>
        </TR>
<% } %>
        <TR>
          <TD>&nbsp;&nbsp;<IMG SRC="../images/images/find16.gif" HEIGHT="16" BORDER="0" ALT="Search"></TD>
	        <TD><A HREF="#" onclick="findOportunity();return false;" CLASS="linkplain" TITLE="Find Opportunity">Search</A></TD>
          <TD VALIGN="bottom"><IMG SRC="../images/images/findundo16.gif" HEIGHT="16" BORDER="0" ALT="Discard Find Filter"></TD>
          <TD><A HREF="#" onclick="document.forms[0].sel_status.selectedIndex=0;document.forms[0].sel_searched.selectedIndex=0;document.forms[0].sel_objetive.selectedIndex=0;document.forms[0].find.value='';<% if (bIsAdmin && sSalesMenLookUp.length()>0) { %>document.forms[0].sel_salesman.selectedIndex=0;<% } %>findOportunity();return false;" CLASS="linkplain" TITLE="Discard Find Filter">Discard</A></TD>
          <TD ALIGN="right" CLASS="textplain">Show&nbsp;</TD>
          <TD><SELECT CLASS="combomini" NAME="maxresults" onchange="setCookie('maxrows',getCombo(document.forms[0].maxresults));"><OPTION VALUE="10">10<OPTION VALUE="20">20<OPTION VALUE="50">50<OPTION VALUE="100">100<OPTION VALUE="200">200<OPTION VALUE="500">500</SELECT><FONT CLASS="textplain">&nbsp;&nbsp;&nbsp;results&nbsp;</FONT></TD>        
        </TR>
        <TR><TD COLSPAN="6" BACKGROUND="../images/images/loginfoot_med.gif" HEIGHT="3"></TD></TR>
        <TR>
          <TD ALIGN="right"><INPUT TYPE="radio" NAME="private" <% if (iPrivate!=0) out.write("CHECKED"); else out.write("onClick=\"reloadPrivate(1);\""); %>></TD>
          <TD COLSPAN="3" CLASS="textplain">View private opportunities only</TD>          
          <TD ALIGN="left" COLSPAN="2" CLASS="textplain"><INPUT TYPE="radio" NAME="private" <% if (iPrivate==0) out.write("CHECKED"); else out.write("onClick=\"reloadPrivate(0);\""); %>>&nbsp;<% if (bIsAdmin) out.write("Show All"); else out.write("View Public & Private Opportunities"); %></TD>
        </TR>
        <TR><TD COLSPAN="6" BACKGROUND="../images/images/loginfoot_med.gif" HEIGHT="3"></TD></TR>
        <TR>
          <TD>&nbsp;&nbsp;<IMG SRC="../images/images/addrbook/telephone16.gif" WIDTH="16" HEIGHT="16" BORDER="0" ALT="Call"></TD>
          <TD COLSPAN="5"><A HREF="#" oncontextmenu="return false;" onclick="if (document.forms[0].sel_campaign.selectedIndex<=0) { alert('A campaign for the call must be chosen first'); document.forms[0].sel_campaign.focus(); } else { addPhoneCall('','',getCombo(document.forms[0].sel_campaign)); } return false;" CLASS="linkplain">Make call for an automatically selected contact</A></TD>
			  </TR>
        <TR><TD COLSPAN="6" BACKGROUND="../images/images/loginfoot_med.gif" HEIGHT="3"></TD></TR>
      </TABLE>
<%   
     if (iSkip>0)
       out.write("            <A HREF=\"oportunity_listing.jsp?id_domain=" + id_domain + "&n_domain=" + n_domain + "&skip=" + String.valueOf(iSkip-iMaxRows) + "&orderby=" + String.valueOf(iOrderBy) + "&field=" + sField + "&find=" + sFind + "&gu_contact="+nullif(request.getParameter("gu_contact"))+"&gu_campaign="+nullif(request.getParameter("gu_campaign")) + "&tp_origin="+nullif(request.getParameter("tp_origin")) + "&id_status=" + nullif(request.getParameter("id_status")) + "&id_objetive=" + nullif(request.getParameter("id_objetive")) + "&gu_sales_man=" + nullif(request.getParameter("gu_sales_man")) + "&where=" + Gadgets.URLEncode(nullif(request.getParameter("where"))) + "&selected=" + request.getParameter("selected") + "&subselected=" + request.getParameter("subselected") + "\" CLASS=\"linkplain\">&lt;&lt;&nbsp;Previous" + "</A>&nbsp;&nbsp;&nbsp;");
         
     if (iOportunityCount>0) {
       if (!oOportunities.eof())
         out.write("            <A HREF=\"oportunity_listing.jsp?id_domain=" + id_domain + "&n_domain=" + n_domain + "&skip=" + String.valueOf(iSkip+iMaxRows) + "&orderby=" + String.valueOf(iOrderBy) + "&field=" + sField + "&find=" + sFind + "&gu_contact="+nullif(request.getParameter("gu_contact"))+"&gu_campaign="+nullif(request.getParameter("gu_campaign")) + "&tp_origin="+nullif(request.getParameter("tp_origin")) + "&id_status=" + nullif(request.getParameter("id_status")) + "&id_objetive=" + nullif(request.getParameter("id_objetive")) + "&gu_sales_man=" + nullif(request.getParameter("gu_sales_man")) + "&where=" + Gadgets.URLEncode(nullif(request.getParameter("where"))) + "&selected=" + request.getParameter("selected") + "&subselected=" + request.getParameter("subselected") + "\" CLASS=\"linkplain\">Next&nbsp;&gt;&gt;</A>");
     }
%>
      <TABLE SUMMARY="Leads List" CELLSPACING="1" CELLPADDING="0">
        <TR>
        	<TD CLASS="tableheader" BACKGROUND="../skins/<%=sSkin%>/tablehead.gif"></TD>        	
          <TD CLASS="tableheader" BACKGROUND="../skins/<%=sSkin%>/tablehead.gif">&nbsp;<A HREF="javascript:sortBy(2);" oncontextmenu="return false;"><IMG SRC="../skins/<%=sSkin + (iOrderBy==2 ? "/sortedfld.gif" : "/sortablefld.gif")%>" WIDTH="14" HEIGHT="10" BORDER="0" ALT="Order by this field"></A>&nbsp;<B>Status</B>&nbsp;</TD>
          <TD CLASS="tableheader" WIDTH="320" BACKGROUND="../skins/<%=sSkin%>/tablehead.gif">&nbsp;<A HREF="javascript:sortBy(3);" oncontextmenu="return false;"><IMG SRC="../skins/<%=sSkin + (iOrderBy==3 ? "/sortedfld.gif" : "/sortablefld.gif")%>" WIDTH="14" HEIGHT="10" BORDER="0" ALT="Order by this field"></A>&nbsp;<B>Title</B></TD>
          <TD CLASS="tableheader" BACKGROUND="../skins/<%=sSkin%>/tablehead.gif">&nbsp;<B>Campaign</B></TD>
          <TD CLASS="tableheader" BACKGROUND="../skins/<%=sSkin%>/tablehead.gif">&nbsp;<A HREF="javascript:sortBy(4);" oncontextmenu="return false;"><IMG SRC="../skins/<%=sSkin + (iOrderBy==5 ? "/sortedfld.gif" : "/sortablefld.gif")%>" WIDTH="14" HEIGHT="10" BORDER="0" ALT="Order by this field"></A>&nbsp;&nbsp;<B>Client</B></TD>
          <TD CLASS="tableheader" BACKGROUND="../skins/<%=sSkin%>/tablehead.gif">&nbsp;<A HREF="javascript:sortBy(8);" oncontextmenu="return false;"><IMG SRC="../skins/<%=sSkin + (iOrderBy==8 ? "/sortedfld.gif" : "/sortablefld.gif")%>" WIDTH="14" HEIGHT="10" BORDER="0" ALT="Order by this field"></A>&nbsp;&nbsp;<B>Amount</B>&nbsp;</TD>
          <TD CLASS="tableheader" BACKGROUND="../skins/<%=sSkin%>/tablehead.gif" NOWRAP="nowrap">&nbsp;<A HREF="javascript:sortBy(9);" oncontextmenu="return false;"><IMG SRC="../skins/<%=sSkin + (iOrderBy==9 ? "/sortedfld.gif" : "/sortablefld.gif")%>" WIDTH="14" HEIGHT="10" BORDER="0" ALT="Order by this field"></A>&nbsp;<B>Next Action</B>&nbsp;</TD>
          <TD CLASS="tableheader" BACKGROUND="../skins/<%=sSkin%>/tablehead.gif" NOWRAP="nowrap">&nbsp;<A HREF="javascript:sortBy(12);" oncontextmenu="return false;"><IMG SRC="../skins/<%=sSkin + (iOrderBy==12 ? "/sortedfld.gif" : "/sortablefld.gif")%>" WIDTH="14" HEIGHT="10" BORDER="0" ALT="Order by this field"></A>&nbsp;<B>Last Call</B>&nbsp;</TD>
          <!--<TD CLASS="tableheader" BACKGROUND="../skins/<%=sSkin%>/tablehead.gif">&nbsp;<A HREF="javascript:sortBy(11);" oncontextmenu="return false;"><IMG SRC="../skins/<%=sSkin + (iOrderBy==11 ? "/sortedfld.gif" : "/sortablefld.gif")%>" WIDTH="14" HEIGHT="10" BORDER="0" ALT="Order by this field"></A>&nbsp;<B>Objective</B>&nbsp;</TD>-->
          <TD CLASS="tableheader" WIDTH="20" BACKGROUND="../skins/<%=sSkin%>/tablehead.gif" ALIGN="center"><A HREF="#" onclick="selectAll()" TITLE="Seleccionar todos"><IMG SRC="../images/images/selall16.gif" BORDER="0" ALT="Select all"></A></TD>
        </TR>
<%
	  String sOpId, sOpSt, sOpTl, sOpCl, sOpDt, sOpCn, sOpCm, sOpRv, sOpCp, sOpLv, sOpOb, sDtLc;
	  Object oOpDt, oOpRv;
	  
	  for (int i=0; i<iOportunityCount; i++) {
            sOpId = oOportunities.getString(0,i);
            sOpSt = (String) oStatusLookUp.get(oOportunities.getStringNull(1,i,""));
            if (null==sOpSt) sOpSt = oOportunities.getStringNull(1,i,"");
            sOpTl = oOportunities.getStringNull(2,i,"* N/A *");
            if (sOpTl.length()==0) sOpTl = "* N/A *";
            sOpCl = oOportunities.getString(3,i);            
            oOpDt = oOportunities.get(4,i);
            if (null==oOpDt)
              sOpDt = "";
            else 
              sOpDt = oSimpleDate.format((Date)oOpDt);
            sOpCn = oOportunities.getStringNull(5,i,"");
            sOpCm = oOportunities.getStringNull(6,i,"");  
            oOpRv = oOportunities.get(7,i);  
            if (null!=oOpRv)
              sOpRv = oOpRv.toString();
            else 
              sOpRv = "";
            if (oOportunities.isNull(8,i))
              sOpCp = "";
            else {
            	int iCampaignIdx = oCampaigns.find(0, oOportunities.get(8,i));
            	if (iCampaignIdx>=0)
            	  sOpCp = oCampaigns.getString(1, iCampaignIdx);
              else
              	sOpCp = "* missing campaign *";
            }
            if (oOportunities.isNull(9,i))
              sOpLv = "0";
            else
            	sOpLv = String.valueOf(oOportunities.getShort(9,i));
            sOpOb = oOportunities.getStringNull(10,i,"");
            if (oOportunities.isNull(11,i))
              sDtLc = "";
            else
            	sDtLc = oOportunities.getDateFormated(11,i,oSimpleDateTime);
%>
	<TR HEIGHT="14">
		<TD CLASS="striplv<%=sOpLv%>">&nbsp;<%
			if (oOportunities.getStringNull(1,i,"").equals("ENCURSO")) { %>
			  <IMG SRC="../images/images/addrbook/callongoing.gif" WIDTH="22" HEIGHT="14" BORDER="0" ALT="Ongoing Call">
<%	  } else if (sOpCn.length()>0) { %>
			  <A HREF="#" onclick="addPhoneCall('<%=sOpId%>', '<%=sOpCn%>','')" TITLE="Call"><IMG SRC="../images/images/addrbook/telephone16.gif" WIDTH="16" HEIGHT="16" BORDER="0" ALT="Call"></A>
<%    } %>
    </TD>
	  <TD CLASS="striplv<%=sOpLv%>">&nbsp;<%=sOpSt%>&nbsp;</TD>
	  <TD CLASS="striplv<%=sOpLv%>">&nbsp;<A NAME="#<%=sOpId%>o" ID="#<%=sOpId%>o" HREF="#<%=sOpId%>o" oncontextmenu="jsOportunityId='<%=sOpId%>'; jsOportunityTl='<%=sOpTl%>'; jsContactId='<%=sOpCn%>'; jsCompanyId='<%=sOpCm%>'; return showRightMenu(event);" onmouseover="window.status='Editar Oportunidad'; return true;" onmouseout="window.status='';" onclick="modifyOportunity('<%=sOpId%>','<%=sOpCn%>','<%=sOpCm%>')" TITLE="Click Right Mouse Button for Context Menu"><%=sOpTl%></A></TD>
	  <TD CLASS="striplv<%=sOpLv%>">&nbsp;<%=sOpCp%></TD>
	  <TD CLASS="striplv<%=sOpLv%>">&nbsp;<A NAME="#<%=sOpId%>c" ID="#<%=sOpId%>c" HREF="#<%=sOpId%>c"  CLASS="linkplain" oncontextmenu="return false;" onclick="<%=(sOpCn.length()>0 ? "modifyContact('"+sOpCn+"')" : "modifyCompany('"+sOpCm+"','"+Gadgets.URLEncode(sOpCl)+"'))")%>"><%=sOpCl%></A></TD>
	  <TD CLASS="striplv<%=sOpLv%>" ALIGN="right">&nbsp;<%=sOpRv%></TD>
	  <TD CLASS="striplv<%=sOpLv%>" ALIGN="right">&nbsp;<%=sOpDt%>&nbsp;</TD>
	  <TD CLASS="striplv<%=sOpLv%>" ALIGN="center">&nbsp;<%=sDtLc%>&nbsp;</TD>
	  <!--<TD CLASS="striplv<%=sOpLv%>" ALIGN="center">&nbsp;<%=sOpOb%>&nbsp;</TD>-->
	  <TD CLASS="striplv<%=sOpLv%>" WIDTH="20" ><INPUT TYPE="checkbox" VALUE="<%=sOpId%>"></TD>
	</TR>
<% } %>
        <TR><TD COLSPAN="10" BACKGROUND="../images/images/loginfoot_med.gif" HEIGHT="3"></TD></TR>
        <TR>
        	<TD></TD>
          <TD ALIGN="right" VALIGN="top" CLASS="textstrong">Summary</TD>
          <TD ALIGN="left" CLASS="textplain">
<% 
  oStatusSummary.sortByDesc(0);
  for (int s=0; s<oStatusSummary.getRowCount(); s++ ) {
     if (oStatusSummary.isNull(1,s))
       out.write("Without status:&nbsp;"+String.valueOf(oStatusSummary.getLong(0,s)+"<BR/>\n"));
		 else {
		 	 String sLookupTr = (String) oStatusLookUp.get(oStatusSummary.getString(1,s));
       out.write((sLookupTr==null || "null".equals(sLookupTr) ? oStatusSummary.getString(1,s) : sLookupTr)+":&nbsp;"+String.valueOf(oStatusSummary.getLong(0,s)+"<BR/>\n"));
     }
   } %>
            Total:&nbsp;<% try { if (oStatusSummary.getRowCount()>0) out.write(String.valueOf(oStatusSummary.sum(0))); else out.write("0"); } catch (Exception e) { out.write(e.getClass().getName()+" "+e.getMessage()); } %>
          </TD>
          <TD ALIGN="right" VALIGN="top" CLASS="textstrong">Close Reason</TD>
          <TD ALIGN="left" VALIGN="top" CLASS="textplain">
<% oCausesSummary.sortByDesc(0);
   for (int s=0; s<oCausesSummary.getRowCount(); s++ ) {
     if (oCausesSummary.isNull(1,s))
       out.write("Without reason:&nbsp;"+String.valueOf(oCausesSummary.getLong(0,s)+"<BR/>\n"));
		 else {
		 	 String sCauseTr = (String) oCausesLookUp.get(oCausesSummary.getString(1,s));		 	 
       out.write((sCauseTr==null || "null".equals(sCauseTr) ? oCausesSummary.getString(1,s) : sCauseTr)+":&nbsp;"+String.valueOf(oCausesSummary.getLong(0,s)+"<BR/>\n"));
     }
   } %>
          </TD>
          <TD ALIGN="right" VALIGN="top" CLASS="textstrong"><% if (!oRevenueSummary.isNull(0,0)) out.write(String.valueOf(oRevenueSummary.getFloat(0,0))); %></TD>
        </TR>
        <TR><TD COLSPAN="10" BACKGROUND="../images/images/loginfoot_med.gif" HEIGHT="3"></TD></TR>
      </TABLE>
    </FORM>
    <SCRIPT type="text/javascript">
      addMenuOption("Open","modifyOportunity(jsOportunityId, jsContactId, jsCompanyId)",1);
      addMenuSeparator();
      addMenuOption("Duplicate","clone()",0);
      addMenuSeparator();
      addMenuOption("Call","addPhoneCall(jsOportunityId, jsContactId, getCombo(frm.sel_campaign))",0);
    </SCRIPT>
  </BODY>
</HTML>

<%@ page import="java.net.URLDecoder,java.io.File,java.sql.SQLException,com.knowgate.acl.*,com.knowgate.jdc.JDCConnection,com.knowgate.dataobjs.DB,com.knowgate.dataobjs.DBBind,com.knowgate.dataobjs.DBSubset,com.knowgate.misc.Environment,com.knowgate.misc.Gadgets,com.knowgate.hipergate.QueryByForm,com.knowgate.hipergate.Address" language="java" session="false" contentType="text/html;charset=UTF-8" %>
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

  int iSupplierCount = 0;
  DBSubset oSuppliers;        
  String sOrderBy;
  int iOrderBy;  
  int iMaxRows;
  int iSkip;

  // 06. Maximum number of rows to display and row to start with

  try {  
    if (request.getParameter("maxrows")!=null)
      iMaxRows = Integer.parseInt(request.getParameter("maxrows"));
    else 
      iMaxRows = Integer.parseInt(getCookie(request, "maxrows", "10"));
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

    oConn = GlobalDBBind.getConnection("supplierlisting");  
    
    // Results are stored in a DBSubset object and connection is closed.
    // Later the DBSubset is iterated and each row is send to HTML output.
    
    if (sWhere.length()>0) {

      // 09. QBF Filtered Listing
      
      oQBF = new QueryByForm("file://" + sStorage + "qbf" + File.separator + request.getParameter("queryspec") + ".xml");
    
      oSuppliers = new DBSubset (oQBF.getBaseObject(), 
      				 "gu_supplier,nm_legal,nm_commercial,tp_street,nm_street,nu_street,mn_city,nm_state,work_phone,direct_phone,work_phone,tx_email,contact_person,url_addr",
      				 "(" + oQBF.getBaseFilter(request) + ") " + sWhere + (iOrderBy>0 ? " ORDER BY " + sOrderBy : ""), iMaxRows);      				 
      
      oSuppliers.setMaxRows(iMaxRows);
      iSupplierCount = oSuppliers.load (oConn, iSkip);
    }
    
    else if (sFind.length()==0 || sField.length()==0) {
      
      // 10. If filter does not exist then return all rows up to maxrows limit

      oSuppliers = new DBSubset ("v_supplier_address",
      				 "gu_supplier,nm_legal,nm_commercial,tp_street,nm_street,nu_street,mn_city,nm_state,work_phone,direct_phone,work_phone,tx_email,contact_person,url_addr",
      				 DB.gu_workarea+ "='" + gu_workarea + "'" + (iOrderBy>0 ? " ORDER BY " + sOrderBy : ""), iMaxRows);      				 

      oSuppliers.setMaxRows(iMaxRows);
      iSupplierCount = oSuppliers.load (oConn, iSkip);
    }
    else {

      oSuppliers = new DBSubset ("v_supplier_address b", 
      				 "gu_supplier,nm_legal,nm_commercial,tp_street,nm_street,nu_street,mn_city,nm_state,work_phone,direct_phone,work_phone,tx_email,contact_person,url_addr",
      				 "b." + DB.gu_workarea+ "='" + gu_workarea + "' AND (" + sField + " " + DBBind.Functions.ILIKE + " ?)" + (iOrderBy>0 ? " ORDER BY " + sOrderBy : ""), iMaxRows);      				 

      oSuppliers.setMaxRows(iMaxRows);

      Object[] aFind = { "%" + sFind + "%" };      
      iSupplierCount = oSuppliers.load (oConn, aFind, iSkip);
    }
    
    oConn.close("supplierlisting"); 
  }
  catch (SQLException e) {  
    oSuppliers = null;
    if (oConn!=null)
      if (!oConn.isClosed())
        oConn.close("supplierlisting");
    oConn = null;
    response.sendRedirect (response.encodeRedirectUrl ("../common/errmsg.jsp?title=Error&desc=" + e.getLocalizedMessage() + "&resume=_back"));
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
        
        var jsSupplierId;
        var jsSupplierNm;
            
        <%
          // Write supplier primary keys in a JavaScript Array
          // This Array is used when posting multiple elements
          // for deletion.
          
          out.write("var jsSuppliers = new Array(");
            
            for (int i=0; i<iSupplierCount; i++) {
              if (i>0) out.write(","); 
              out.write("\"" + oSuppliers.getString(0,i) + "\"");
            }
            
          out.write(");\n        ");
        %>

        // ----------------------------------------------------

<% if (!bIsGuest) { %>
        
        // 12. Create new supplier

	function createSupplier() {	  
	  
	  self.open ("supplier_edit_f.jsp?gu_workarea=<%=gu_workarea%>", "editsupplier", "directories=no,toolbar=no,menubar=no,width=680,height=580");	  
	} // createSupplier()

        // ----------------------------------------------------

        // 13. Delete checked suppliers
	
	function deleteSuppliers() {
	  
	  var offset = 0;
	  var frm = document.forms[0];
	  var chi = frm.checkeditems;
	  	  
	  if (window.confirm("Are you sure that you want to delete the selected products?")) {
	  	  
	    chi.value = "";	  	  
	    frm.action = "supplier_edit_delete.jsp?selected=" + getURLParam("selected") + "&subselected=" + getURLParam("subselected");
	  	  
	    for (var i=0;i<jsSuppliers.length; i++) {
              while (frm.elements[offset].type!="checkbox") offset++;
    	      if (frm.elements[offset].checked)
                chi.value += jsSuppliers[i] + ",";
              offset++;
	    } // next()
	    
	    if (chi.value.length>0) {
	      chi.value = chi.value.substr(0,chi.value.length-1);
              frm.submit();
            } // fi(chi!="")
          } // fi (confirm)
	} // deleteSuppliers()
<% } %>	
        // ----------------------------------------------------

        // 14. Modify Supplier

	function modifySupplier(id) {
	  
	  self.open ("supplier_edit_f.jsp?gu_workarea=<%=gu_workarea%>" + "&gu_supplier=" + id, "editsupplier", "directories=no,toolbar=no,menubar=no,width=680,height=580");
	} // modifySupplier

        // ----------------------------------------------------

        // 15. Reload Page sorting by a field

	function sortBy(fld) {
	  
	  var frm = document.forms[0];
	  
	  window.location = "suppliers_listing.jsp?id_domain=<%=id_domain%>&n_domain=" + escape("<%=n_domain%>") + "&skip=0&orderby=" + fld + "&where=" + escape("<%=sWhere%>") + "&field=" + getCombo(frm.sel_searched) + "&find=" + escape(frm.find.value) + "&selected=" + getURLParam("selected") + "&subselected=" + getURLParam("subselected") + "&screen_width=" + String(screen.width);
	} // sortBy		

        // ----------------------------------------------------

        // 16. Select All Suppliers

        function selectAll() {
          
          var frm = document.forms[0];
          
          for (var c=0; c<jsSuppliers.length; c++)                        
            eval ("frm.elements['" + jsSuppliers[c] + "'].click()");
        } // selectAll()
       
        // ----------------------------------------------------

        // 17. Reload Page finding suppliers by a single field
	
	function findSupplier() {
	  	  
	  var frm = document.forms[0];
	  
	  if (frm.find.value.length>0)
	    window.location = "suppliers_listing.jsp?id_domain=<%=id_domain%>&n_domain=" + escape("<%=n_domain%>") + "&skip=0&orderby=<%=sOrderBy%>&field=" + getCombo(frm.sel_searched) + "&find=" + escape(frm.find.value) + "&selected=" + getURLParam("selected") + "&subselected=" + getURLParam("subselected") + "&screen_width=" + String(screen.width);
	  else
	    window.location = "suppliers_listing.jsp?id_domain=<%=id_domain%>&n_domain=" + escape("<%=n_domain%>") + "&skip=0&orderby=<%=sOrderBy%>&selected=" + getURLParam("selected") + "&subselected=" + getURLParam("subselected") + "&screen_width=" + String(screen.width);
	  
	} // findSupplier()

      // ----------------------------------------------------

      var intervalId;
      var winclone;

      // This function is called every 100 miliseconds for testing
      // whether or not clone call has finished.
      
      function findCloned() {
        
        if (winclone.closed) {
          clearInterval(intervalId);
          setCombo(document.forms[0].sel_searched, "<%=DB.nm_legal%>");
          document.forms[0].find.value = jsSupplierNm;
          findSupplier();
        }
      } // findCloned()

      // 18. Clone an supplier using an XML data structure definition
      
      function clone() {        
        // Open a clone window and wait for it to be closed
        
        winclone = window.open ("../common/clone.jsp?id_domain=<%=id_domain%>&n_domain=" + escape("<%=n_domain%>") + "&datastruct=supplier_clon&gu_instance=" + jsSupplierId +"&opcode=CSUP&classid=89", null, "directories=no,toolbar=no,menubar=no,width=320,height=200");                
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
  <TITLE>hipergate :: List of suppliers</TITLE>
</HEAD>
<BODY  TOPMARGIN="8" MARGINHEIGHT="8" onClick="hideRightMenu()">
    <%@ include file="../common/tabmenu.jspf" %>
    <FORM METHOD="post">
      <TABLE><TR><TD WIDTH="<%=iTabWidth*iActive%>" CLASS="striptitle"><FONT CLASS="title1">List of suppliers</FONT></TD></TR></TABLE>  
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
        <TD VALIGN="middle"><A HREF="#" onclick="createSupplier()" CLASS="linkplain">New</A></TD>
        <TD>&nbsp;&nbsp;<IMG SRC="../images/images/papelera.gif" WIDTH="16" HEIGHT="16" BORDER="0" ALT="Delete"></TD>
        <TD><A HREF="#" onclick="deleteSuppliers()" CLASS="linkplain">Delete</A></TD>
<% } %>
        <TD VALIGN="bottom">&nbsp;&nbsp;<IMG SRC="../images/images/find16.gif" HEIGHT="16" BORDER="0" ALT="Search"></TD>
        <TD VALIGN="middle">
          <SELECT NAME="sel_searched" CLASS="combomini"></SELECT>
          <INPUT CLASS="textmini" TYPE="text" NAME="find" MAXLENGTH="50" VALUE="<%=sFind%>">
	  &nbsp;<A HREF="javascript:findSupplier();" CLASS="linkplain" TITLE="Find">Search</A>	  
        </TD>
        <TD VALIGN="bottom">&nbsp;&nbsp;&nbsp;<IMG SRC="../images/images/findundo16.gif" HEIGHT="16" BORDER="0" ALT="Discard"></TD>
        <TD VALIGN="bottom">
          <A HREF="javascript:document.forms[0].find.value='';findSupplier();" CLASS="linkplain" TITLE="Discard Search">Discard</A>
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
    
    	  if (iSupplierCount>0) {
            if (iSkip>0)
              out.write("            <A HREF=\"suppliers_listing.jsp?id_domain=" + id_domain + "&n_domain=" + n_domain + "&skip=" + String.valueOf(iSkip-iMaxRows) + "&orderby=" + sOrderBy + "&field=" + sField + "&find=" + sFind + "&selected=" + request.getParameter("selected") + "&subselected=" + request.getParameter("subselected") + "\" CLASS=\"linkplain\">&lt;&lt;&nbsp;Previous" + "</A>&nbsp;&nbsp;&nbsp;");
    
            if (!oSuppliers.eof())
              out.write("            <A HREF=\"suppliers_listing.jsp?id_domain=" + id_domain + "&n_domain=" + n_domain + "&skip=" + String.valueOf(iSkip+iMaxRows) + "&orderby=" + sOrderBy + "&field=" + sField + "&find=" + sFind + "&selected=" + request.getParameter("selected") + "&subselected=" + request.getParameter("subselected") + "\" CLASS=\"linkplain\">Next&nbsp;&gt;&gt;</A>");
	  } // fi (iSupplierCount)
%>
          </TD>
        </TR>
        <TR>
          <TD CLASS="tableheader" WIDTH="<%=String.valueOf(floor(300f*fScreenRatio))%>" BACKGROUND="../skins/<%=sSkin%>/tablehead.gif">&nbsp;<A HREF="javascript:sortBy(2);" oncontextmenu="return false;"><IMG SRC="../skins/<%=sSkin + (iOrderBy==2 ? "/sortedfld.gif" : "/sortablefld.gif")%>" WIDTH="14" HEIGHT="10" BORDER="0" ALT="Ordenar por este campo"></A>&nbsp;<B>Corporate Name</B></TD>
          <TD CLASS="tableheader" WIDTH="<%=String.valueOf(floor(320f*fScreenRatio))%>" BACKGROUND="../skins/<%=sSkin%>/tablehead.gif">&nbsp;<A HREF="javascript:sortBy(3);" oncontextmenu="return false;"><IMG SRC="../skins/<%=sSkin + (iOrderBy==3 ? "/sortedfld.gif" : "/sortablefld.gif")%>" WIDTH="14" HEIGHT="10" BORDER="0" ALT="Ordenar por este campo"></A>&nbsp;<B>Address</B></TD>
          <TD CLASS="tableheader" BACKGROUND="../skins/<%=sSkin%>/tablehead.gif"><A HREF="#" onclick="selectAll()" TITLE="Seleccionar todos"><IMG SRC="../images/images/selall16.gif" BORDER="0" ALT="Select All"></A></TD></TR>
<%

		Address oAddr = new Address();
	  String sInstId, sInstNm, sAddr, sStrip;
	  for (int i=0; i<iSupplierCount; i++) {
            oAddr.replace(DB.tp_street, oSuppliers.get(3,i));
            oAddr.replace(DB.nm_street, oSuppliers.get(4,i));
            oAddr.replace(DB.nu_street, oSuppliers.get(5,i));
            
            sInstId = oSuppliers.getString(0,i);
            sInstNm = oSuppliers.getString(1,i);
            sAddr = oAddr.toLocaleString(sLanguage)+" ("+oSuppliers.getStringNull(6,i,oSuppliers.getStringNull(7,i,""))+") "+oSuppliers.getStringNull(8,i,oSuppliers.getStringNull(9,i,""));
            
            sStrip = String.valueOf((i%2)+1);
%>            
            <TR HEIGHT="14">
              <TD CLASS="strip<% out.write (sStrip); %>" WIDTH="<%=String.valueOf(floor(300f*fScreenRatio))%>">&nbsp;<A HREF="#" oncontextmenu="jsSupplierId='<%=sInstId%>'; jsSupplierNm='<%=sInstNm%>'; return showRightMenu(event);" onclick="modifySupplier('<%=sInstId%>')" TITLE="Right click to see context menu"><%=oSuppliers.getString(1,i)%></A></TD>
              <TD CLASS="strip<% out.write (sStrip); %>" WIDTH="<%=String.valueOf(floor(320f*fScreenRatio))%>">&nbsp;<%=sAddr%></TD>
              <TD CLASS="strip<% out.write (sStrip); %>" ALIGN="center"><INPUT VALUE="1" TYPE="checkbox" NAME="<% out.write (sInstId); %>"></TD>
            </TR>
<%        } // next(i) %>          	  
      </TABLE>
    </FORM>
    <!-- 22. DynFloat Right-click context menu -->
    <SCRIPT TYPE="text/javascript">
      <!--
      addMenuOption("Open","modifySupplier(jsSupplierId)",1);
      addMenuOption("Clone","clone()",0);
      //-->
    </SCRIPT>
    <!-- /RightMenuBody -->    
</BODY>
</HTML>
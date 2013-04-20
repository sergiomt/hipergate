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
  String sView = DB.v_sale_points;
  String sCols = DB.gu_sale_point+","+DB.nm_sale_point+"," +
  						   DB.bo_active+","+DB.nm_street+","+DB.nu_street+","+DB.mn_city+","+DB.nm_state;

  String sStorage = Environment.getProfilePath(GlobalDBBind.getProfileName(), "storage");

  // **********************************************

  int iSalePointCount = 0;
  DBSubset oSalePoints = null;
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

    oConn = GlobalDBBind.getConnection("salepointlisting");  
    
    // Results are stored in a DBSubset object and connection is closed.
    // Later the DBSubset is iterated and each row is send to HTML output.
    
    if (sWhere.length()>0) {

      // 09. QBF Filtered Listing
      
      oQBF = new QueryByForm("file://" + sStorage + "qbf" + File.separator + request.getParameter("queryspec") + ".xml");
    
      oSalePoints = new DBSubset (oQBF.getBaseObject(), sCols,
      				 "(" + oQBF.getBaseFilter(request) + ") " + sWhere + (iOrderBy>0 ? " ORDER BY " + sOrderBy : ""), iMaxRows);      				 
      
      oSalePoints.setMaxRows(iMaxRows);
      iSalePointCount = oSalePoints.load (oConn, iSkip);
    }
    
    else if (sFind.length()==0 || sField.length()==0) {

      oSalePoints = new DBSubset (sView, sCols,
      				 DB.gu_workarea+ "='" + gu_workarea + "'" + (iOrderBy>0 ? " ORDER BY " + sOrderBy : ""), iMaxRows);      				 

      oSalePoints.setMaxRows(iMaxRows);
      iSalePointCount = oSalePoints.load (oConn, iSkip);
    }
    else {

      oSalePoints = new DBSubset (sView, sCols,
      				 DB.gu_workarea+ "='" + gu_workarea + "' AND (" + sField + " " + DBBind.Functions.ILIKE + " ?)" + (iOrderBy>0 ? " ORDER BY " + sOrderBy : ""), iMaxRows);      				 

      oSalePoints.setMaxRows(iMaxRows);

      Object[] aFind = { "%" + sFind + "%" };      
      iSalePointCount = oSalePoints.load (oConn, aFind, iSkip);
    }
    
    oConn.close("salepointlisting"); 
  }
  catch (SQLException e) {  
    oSalePoints = null;
    if (oConn!=null)
      if (!oConn.isClosed())
        oConn.close("salepointlisting");
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
        
        var jsInstanceId;
        var jsInstanceNm;
            
        <%
          // Write instance primary keys in a JavaScript Array
          // This Array is used when posting multiple elements
          // for deletion.
          
          out.write("var jsSalePoints = new Array(");
            
            for (int i=0; i<iSalePointCount; i++) {
              if (i>0) out.write(","); 
              out.write("\"" + oSalePoints.getString(0,i) + "\"");
            }
            
          out.write(");\n        ");
        %>

        // ----------------------------------------------------

<% if (!bIsGuest) { %>

	      function createSalePoint() {
	        self.open ("salepoint_edit_f.jsp?id_class=48", "editsalepoint", "directories=no,toolbar=no,menubar=no,width=640,height=540");
	      } // createSalePoint()

        // ----------------------------------------------------

        // 13. Delete checked instances
	
	function deleteSalePoints() {
	  
	  var offset = 0;
	  var frm = document.forms[0];
	  var chi = frm.checkeditems;
	  	  
	  if (window.confirm("Are you sure that you want to delete the selected sale points?")) {
	  	  
	    chi.value = "";	  	  
	    frm.action = "salepoint_edit_delete.jsp?selected=" + getURLParam("selected") + "&subselected=" + getURLParam("subselected");
	  	  
	    for (var i=0;i<jsSalePoints.length; i++) {
              while (frm.elements[offset].type!="checkbox") offset++;
    	      if (frm.elements[offset].checked)
                chi.value += jsSalePoints[i] + ",";
              offset++;
	    } // next()
	    
	    if (chi.value.length>0) {
	      chi.value = chi.value.substr(0,chi.value.length-1);
              frm.submit();
            } // fi(chi!="")
          } // fi (confirm)
	} // deleteSalePoints()
<% } %>	
        // ----------------------------------------------------

	      function modifySalePoint(id,nm) {
	        self.open ("salepoint_edit_f.jsp?id_class=48&gu_sale_point=" + id, "editsalepoint", "directories=no,toolbar=no,menubar=no,width=640,height=540");
	      } // modifySalePoint

        // ----------------------------------------------------

	      function sortBy(fld) {	  
	        var frm = document.forms[0];
	        window.location = "salepoint_listing.jsp?id_domain=<%=id_domain%>&n_domain=" + escape("<%=n_domain%>") + "&skip=0&orderby=" + fld + "&where=" + escape("<%=sWhere%>") + "&field=" + getCombo(frm.sel_searched) + "&find=" + escape(frm.find.value) + "&selected=" + getURLParam("selected") + "&subselected=" + getURLParam("subselected") + "&screen_width=" + String(screen.width);
	      } // sortBy		

        // ----------------------------------------------------

        function selectAll() {
          
          var frm = document.forms[0];
          
          for (var c=0; c<jsSalePoints.length; c++)                        
            eval ("frm.elements['" + jsSalePoints[c] + "'].click()");
        } // selectAll()
       
        // ----------------------------------------------------
	
	      function findInstance() {
	  	  
	        var frm = document.forms[0];
	  
	        if (frm.find.value.length>0)
	          window.location = "salepoint_listing.jsp?id_domain=<%=id_domain%>&n_domain=" + escape("<%=n_domain%>") + "&skip=0&orderby=<%=sOrderBy%>&field=" + getCombo(frm.sel_searched) + "&find=" + escape(frm.find.value) + "&selected=" + getURLParam("selected") + "&subselected=" + getURLParam("subselected") + "&screen_width=" + String(screen.width);
	        else
	          window.location = "salepoint_listing.jsp?id_domain=<%=id_domain%>&n_domain=" + escape("<%=n_domain%>") + "&skip=0&orderby=<%=sOrderBy%>&selected=" + getURLParam("selected") + "&subselected=" + getURLParam("subselected") + "&screen_width=" + String(screen.width);
	  
	      } // findInstance()

      // ----------------------------------------------------

      var intervalId;
      var winclone;

      // This function is called every 100 miliseconds for testing
      // whether or not clone call has finished.
      
      function findCloned() {
        
        if (winclone.closed) {
          clearInterval(intervalId);
          setCombo(document.forms[0].sel_searched, "<%=DB.nm_legal%>");
          document.forms[0].find.value = jsInstanceNm;
          findInstance();
        }
      } // findCloned()

      // 18. Clone an instance using an XML data structure definition
      
      function clone() {        
        // Open a clone window and wait for it to be closed
        
        winclone = window.open ("../common/clone.jsp?id_domain=<%=id_domain%>&n_domain=" + escape("<%=n_domain%>") + "&datastruct=salepoint_clon&gu_instance=" + jsInstanceId +"&opcode=CSLP&classid=48", null, "directories=no,toolbar=no,menubar=no,width=320,height=200");                
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
  <TITLE>hipergate :: Sale point List</TITLE>
</HEAD>
<BODY  TOPMARGIN="8" MARGINHEIGHT="8" onClick="hideRightMenu()">
    <%@ include file="../common/tabmenu.jspf" %>
    <FORM METHOD="post">
      <TABLE SUMMARY="Listing Title"><TR><TD WIDTH="<%=iTabWidth*iActive%>" CLASS="striptitle"><FONT CLASS="title1">Sale point List</FONT></TD></TR></TABLE>  
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
        <TD VALIGN="middle"><A HREF="#" onclick="createSalePoint()" CLASS="linkplain">New</A></TD>
        <TD>&nbsp;&nbsp;<IMG SRC="../images/images/papelera.gif" WIDTH="16" HEIGHT="16" BORDER="0" ALT="Delete"></TD>
        <TD><A HREF="#" onclick="deleteSalePoints()" CLASS="linkplain">Delete</A></TD>
<% } %>
        <TD VALIGN="bottom">&nbsp;&nbsp;<IMG SRC="../images/images/find16.gif" HEIGHT="16" BORDER="0" ALT="Search"></TD>
        <TD VALIGN="middle">
          <SELECT NAME="sel_searched" CLASS="combomini"><OPTION VALUE=""></OPTION><OPTION VALUE="nm_sale_point">Nombre</OPTION><OPTION VALUE="nm_street">Direccion</OPTION><OPTION VALUE="mn_city">Ciudad</OPTION><OPTION VALUE="nm_state">Estado</OPTION></SELECT>
          <INPUT CLASS="textmini" TYPE="text" NAME="find" MAXLENGTH="50" VALUE="<%=sFind%>">
	        &nbsp;<A HREF="javascript:findInstance();" CLASS="linkplain" TITLE="Search">Search</A>	  
        </TD>
        <TD VALIGN="bottom">&nbsp;&nbsp;&nbsp;<IMG SRC="../images/images/findundo16.gif" HEIGHT="16" BORDER="0" ALT="Discard Search"></TD>
        <TD VALIGN="bottom">
          <A HREF="javascript:document.forms[0].find.value='';findInstance();" CLASS="linkplain" TITLE="Discard Search">Discard Search</A>
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
    
    	  if (iSalePointCount>0) {
            if (iSkip>0) // If iSkip>0 then we have prev items
              out.write("            <A HREF=\"salepoint_listing.jsp?id_domain=" + id_domain + "&n_domain=" + n_domain + "&skip=" + String.valueOf(iSkip-iMaxRows) + "&orderby=" + sOrderBy + "&field=" + sField + "&find=" + sFind + "&selected=" + request.getParameter("selected") + "&subselected=" + request.getParameter("subselected") + "\" CLASS=\"linkplain\">&lt;&lt;&nbsp;Previous" + "</A>&nbsp;&nbsp;&nbsp;");
    
            if (!oSalePoints.eof())
              out.write("            <A HREF=\"salepoint_listing.jsp?id_domain=" + id_domain + "&n_domain=" + n_domain + "&skip=" + String.valueOf(iSkip+iMaxRows) + "&orderby=" + sOrderBy + "&field=" + sField + "&find=" + sFind + "&selected=" + request.getParameter("selected") + "&subselected=" + request.getParameter("subselected") + "\" CLASS=\"linkplain\">Next&nbsp;&gt;&gt;</A>");
	  } // fi (iSalePointCount)
%>
          </TD>
        </TR>
        <TR>
          <TD CLASS="tableheader" WIDTH="300" BACKGROUND="../skins/<%=sSkin%>/tablehead.gif">&nbsp;<A HREF="javascript:sortBy(2);" oncontextmenu="return false;"><IMG SRC="../skins/<%=sSkin + (iOrderBy==2 ? "/sortedfld.gif" : "/sortablefld.gif")%>" WIDTH="14" HEIGHT="10" BORDER="0" ALT="order by name"></A>&nbsp;<B>Name</B></TD>
          <TD CLASS="tableheader" WIDTH="300" BACKGROUND="../skins/<%=sSkin%>/tablehead.gif">&nbsp;<A HREF="javascript:sortBy(4);" oncontextmenu="return false;"><IMG SRC="../skins/<%=sSkin + (iOrderBy==4 ? "/sortedfld.gif" : "/sortablefld.gif")%>" WIDTH="14" HEIGHT="10" BORDER="0" ALT="order by address"></A>&nbsp;<B>Address</B></TD>
          <TD CLASS="tableheader" BACKGROUND="../skins/<%=sSkin%>/tablehead.gif"><A HREF="#" onclick="selectAll()" TITLE="Select All"><IMG SRC="../images/images/selall16.gif" BORDER="0" ALT="Select All"></A></TD></TR>
<%
	        String sInstId, sInstNm, sStrip;
	        for (int i=0; i<iSalePointCount; i++) {
            sInstId = oSalePoints.getString(0,i);
            sInstNm = oSalePoints.getString(1,i);
            
            sStrip = String.valueOf((i%2)+1);
%>            
            <TR HEIGHT="14">
              <TD CLASS="strip<% out.write (sStrip); %>">&nbsp;<A HREF="#" oncontextmenu="jsInstanceId='<%=sInstId%>'; jsInstanceNm='<%=sInstNm%>'; return showRightMenu(event);" onclick="modifySalePoint('<%=sInstId%>','<%=oSalePoints.getString(1,i)%>')" TITLE="Right click to see context menu"><%=oSalePoints.getString(1,i)%></A></TD>
              <TD CLASS="strip<% out.write (sStrip); %>">&nbsp;
<% if (sLanguage.startsWith("es")) {
              	out.write(oSalePoints.getStringNull(3,i,"")+" "+oSalePoints.getStringNull(4,i,"")+"("+oSalePoints.getStringNull(5,i,oSalePoints.getStringNull(6,i,""))+")");
   } else { 
              	out.write(oSalePoints.getStringNull(4,i,"")+" "+oSalePoints.getStringNull(3,i,"")+"("+oSalePoints.getStringNull(5,i,oSalePoints.getStringNull(6,i,""))+")");
   }              	
%>            </TD>
              <TD CLASS="strip<% out.write (sStrip); %>" ALIGN="center"><INPUT VALUE="1" TYPE="checkbox" NAME="<% out.write (sInstId); %>"></TD>
            </TR>
<%        } // next(i) %>          	  
      </TABLE>
    </FORM>
    <!-- 22. DynFloat Right-click context menu -->
    <SCRIPT TYPE="text/javascript">
      <!--
      addMenuOption("Open","modifySalePoint(jsInstanceId)",1);
      addMenuOption("Clone","clone()",0);
      addMenuSeparator();
      //-->
    </SCRIPT>
    <!-- /RightMenuBody -->    
</BODY>
</HTML>
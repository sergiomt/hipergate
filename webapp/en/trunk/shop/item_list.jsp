<%@ page import="java.net.URLDecoder,java.sql.SQLException,com.knowgate.acl.*,com.knowgate.jdc.JDCConnection,com.knowgate.dataobjs.DB,com.knowgate.dataobjs.DBBind,com.knowgate.dataobjs.DBSubset,com.knowgate.misc.Environment,com.knowgate.hipergate.QueryByForm,com.knowgate.misc.Gadgets" language="java" session="false" contentType="text/html;charset=UTF-8" %>
<%@ include file="../methods/dbbind.jsp" %><%@ include file="../methods/cookies.jspf" %><%@ include file="../methods/authusrs.jspf" %><%@ include file="../methods/nullif.jspf" %>
<jsp:useBean id="GlobalCacheClient" scope="application" class="com.knowgate.cache.DistributedCachePeer"/>
<% 
  response.addHeader ("Pragma", "no-cache");
  response.addHeader ("cache-control", "no-store");
  response.setIntHeader("Expires", 0);

  String sLanguage = getNavigatorLanguage(request);

  String sSkin = getCookie(request, "skin", "xp");

  String sStorage = Environment.getProfileVar(GlobalDBBind.getProfileName(), "storage");
  
  int iScreenWidth;
  float fScreenRatio;

  String id_domain = getCookie(request,"domainid","");
  String n_domain = getCookie(request,"domainnm",""); 
  String gu_workarea = getCookie(request,"workarea",""); 
  String gu_category = request.getParameter("gu_category");
  String gu_bundles_cat = request.getParameter("gu_bundles_cat");
  String screen_width = request.getParameter("screen_width");

  if (screen_width==null)
    iScreenWidth = 800;
  else if (screen_width.length()==0)
    iScreenWidth = 800;
  else
    iScreenWidth = Integer.parseInt(screen_width);
  
  fScreenRatio = ((float) iScreenWidth) / 800f;
  if (fScreenRatio<1) fScreenRatio=1;
        
  String sField = request.getParameter("field")==null ? "" : request.getParameter("field");
  String sFind = request.getParameter("find")==null ? "" : request.getParameter("find");
  String sWhere = request.getParameter("where")==null ? "" : request.getParameter("where");
        

  int iProductCount = 0;
  DBSubset oProducts;        
  String sOrderBy;
  int iOrderBy;  
  int iMaxRows;
  int iSkip;

  try {
    if (request.getParameter("maxrows")!=null)
      iMaxRows = Integer.parseInt(request.getParameter("maxrows"));
    else 
      iMaxRows = Integer.parseInt(getCookie(request, "maxrows", "50"));
  }
  catch (NumberFormatException nfe) { iMaxRows = 50; }
  
  if (request.getParameter("skip")!=null)
    iSkip = Integer.parseInt(request.getParameter("skip"));      
  else
    iSkip = 0;

  if (request.getParameter("orderby")!=null)
    sOrderBy = request.getParameter("orderby");
  else
    sOrderBy = "";
  
  if (sOrderBy.length()>0)
    iOrderBy = Integer.parseInt(sOrderBy);
  else
    iOrderBy = 0;

  JDCConnection oConn = GlobalDBBind.getConnection("Productlisting");  
  QueryByForm oQBF;
  
  try {
    if (sWhere.length()>0) {
      oQBF = new QueryByForm("file://" + sStorage + "/qbf/" + request.getParameter("queryspec") + ".xml");
    
      oProducts = new DBSubset (oQBF.getBaseObject(), 
      				 "b." + DB.gu_company + "," + "b." + DB.nm_legal + "," + DBBind.Functions.ISNULL + "(" + "b." + DB.de_company + ",'')," + "b." + DB.id_sector + "," + "b." + DB.id_legal + "," + "b." + DB.id_status + "b." + DB.pg_prod_locat + ",x." + DB.od_position,
      				 "(" + oQBF.getBaseFilter(request) + ") " + sWhere + (iOrderBy>0 ? " ORDER BY " + sOrderBy : ""), iMaxRows);      				 
      oProducts.setMaxRows(iMaxRows);
      iProductCount = oProducts.load (oConn, iSkip);
    }
    
    else if (sFind.length()==0 || sField.length()==0) {

      oProducts = new DBSubset (DB.k_products + " p," + DB.k_x_cat_objs + " x", 
      				"p." + DB.gu_product + ",p." + DB.nm_product + ",p." + DB.id_status + ",p." + DB.dt_modified + ",p." + DB.pr_list + ",p." + DB.pr_sale + ",p." + DB.id_currency + ",(SELECT SUM(nu_current_stock) FROM k_prod_locats l WHERE l.gu_product=p.gu_product) AS nu_current_stock,0 AS pg_location,x." + DB.od_position,
      				" x." + DB.gu_category + "=? AND x." + DB.gu_object + "=p." + DB.gu_product + (iOrderBy>0 ? " GROUP BY p.gu_product ORDER BY " + sOrderBy : ""), iMaxRows);

      oProducts.setMaxRows(iMaxRows);
      iProductCount = oProducts.load (oConn, new Object[]{gu_category}, iSkip);
    }
    else {
      oProducts = new DBSubset (DB.k_products + " p," + DB.k_x_cat_objs + " x", 
      				"p." + DB.gu_product + ",p." + DB.nm_product + ",p." + DB.id_status + ",p." + DB.dt_modified + ",p." + DB.pr_list + ",p." + DB.pr_sale + ",p." + DB.id_currency + ",(SELECT SUM(nu_current_stock) FROM k_prod_locats l WHERE l.gu_product=p.gu_product) AS nu_current_stock,0 AS pg_location,x." + DB.od_position,
      				" x." + DB.gu_category + "=? AND x." + DB.gu_object + "=p." + DB.gu_product + " AND p." + sField + " " + DBBind.Functions.ILIKE + " ? " + (iOrderBy>0 ? " GROUP BY p.gu_product ORDER BY " + sOrderBy : ""), iMaxRows);      				 
      oProducts.setMaxRows(iMaxRows);
      iProductCount = oProducts.load (oConn, new Object[]{gu_category, "%" + sFind + "%"}, iSkip);

    }
    
    oConn.close("Productlisting"); 
  }
  catch (SQLException e) {  
    oProducts = null;
    oConn.close("Productlisting");
    response.sendRedirect (response.encodeRedirectUrl ("../common/errmsg.jsp?title=Error&desc=" + e.getLocalizedMessage() + "&resume=_back"));
  }
  oConn = null;  
%>

<HTML LANG="<% out.write(sLanguage); %>">
<HEAD>
  <SCRIPT SRC="../javascript/cookies.js"></SCRIPT>  
  <SCRIPT SRC="../javascript/setskin.js"></SCRIPT>
  <SCRIPT SRC="../javascript/combobox.js"></SCRIPT>
  <SCRIPT SRC="../javascript/getparam.js"></SCRIPT>
  <SCRIPT SRC="../javascript/simplevalidations.js"></SCRIPT>  
  <SCRIPT TYPE="text/javascript" DEFER="defer">
    <!--
        var jsProductId;
        var jsProductNm;
            
        <%          
          out.write("var jsProducts = new Array(");
            for (int i=0; i<iProductCount; i++) {
              if (i>0) out.write(","); 
              out.write("\"" + oProducts.getString(0,i) + "\"");
            }
          out.write(");\n        ");
        %>

        // ----------------------------------------------------
        	
	function createProduct() {	  
	  
	  self.open ("item_edit.jsp?id_domain=<%=id_domain%>&n_domain=" + escape("<%=n_domain%>") + "&gu_workarea=<%=gu_workarea%>&gu_shop=" + getURLParam("gu_shop") + "&gu_category=" + getURLParam("gu_category") + "&top_parent_cat=" + getURLParam("top_parent_cat"), "editProduct", "directories=no,toolbar=no,menubar=no,width=760,height=520");
	} // createProduct()

        // ----------------------------------------------------
	
	function composeSelectedList() {
	    var offset = 0;
	    var frm = document.forms[0];
	    var chi = frm.checkeditems;
	    
	    chi.value = "";	  	  
	  	  
	    for (var i=0;i<jsProducts.length; i++) {
              while (frm.elements[offset].type!="checkbox") offset++;
    	      if (frm.elements[offset].checked)
                chi.value += jsProducts[i] + ",";
              offset++;
	    } // next()
	    
	    if (chi.value.length>0) {
	      chi.value = chi.value.substr(0,chi.value.length-1);
	    }
	}  // composeSelectedList

        // ----------------------------------------------------
	
	function composeReorderList() {
	    var offset = 0;
	    var frm = document.forms[0];
	    var chi = frm.checkeditems;
	    var txt;
	    
	    chi.value = "";	  	  
	  	  
	    for (var i=0;i<jsProducts.length; i++) {
              while (frm.elements[offset].type!="text" || frm.elements[offset].name!="pos_"+jsProducts[i]) offset++;
    	      
    	      if (!isIntValue(frm.elements[offset].value)) {
    	        alert("Position for Product&nbsp;" + String(i+1) + " is not a valid integer");
    	        return false;
    	      }
    	          	    
              chi.value += jsProducts[i] + ":" + frm.elements[offset].value + ",";
              offset++;
	    } // next()
	    
	    if (chi.value.length>0) {
	      chi.value = chi.value.substr(0,chi.value.length-1);
	    }
	}  // composeReorderList
	
        // ----------------------------------------------------
	
	function deleteProducts() {
	  // Borrar los productos marcados con checkboxes
	  
	  var frm = document.forms[0];
	  	  
	  if (window.confirm("Are you sure you want to delete selected products?")) {
	  	  	    
	    composeSelectedList();
	    
	    if (frm.checkeditems.value.length>0) {
	      frm.action = "item_edit_delete.jsp";
	      frm.submit();
            }
	    else
	      alert ("Must first check the Products to be deleted");
	    
          } // fi (confirm)
	} // deleteProducts()

        // ----------------------------------------------------
	
	function moveProducts() {
	  
	  var frm = document.forms[0];
	  
	  if (getCombo(frm.sel_target).length==0) {
	    alert ("Must select a target Category");
	    return false;
	  }
	  	  
	  if (window.confirm("Are you sure you want to delete selected products?")) {
	    
	    frm.gu_category.value = getCombo(frm.sel_target);
	    	    
	    composeSelectedList();
	    
	    if (frm.checkeditems.value.length>0) {
	      frm.action = "item_edit_move.jsp";
	      frm.submit();
            }
            else
	      alert ("Must first check the Products to be moved");
            
          } // fi (confirm)
	} // moveProducts()

        // ----------------------------------------------------
	
	function reorderProducts() {
	  composeReorderList();
	  
	  if (document.forms[0].checkeditems.value.length==0)

	    alert("Must first check the Products to be ordered");

	  else {	  
	    document.forms[0].action = "item_edit_reorder.jsp";
	    document.forms[0].submit();
	  }
	} // reorderProducts
	
        // ----------------------------------------------------

	function modifyProduct(id) {
	  
	  self.open ("item_edit.jsp?id_domain=<%=id_domain%>&n_domain=" + escape("<%=n_domain%>") + "&gu_workarea=<%=gu_workarea%>&gu_shop=" + getURLParam("gu_shop") + "&gu_category=" + getURLParam("gu_category") + "&top_parent_cat=" + getURLParam("top_parent_cat") + "&gu_product=" + id, "editProduct", "directories=no,toolbar=no,menubar=no,width=760,height=520");	  
	}	

        // ----------------------------------------------------

	function sortBy(fld) {
	  var frm = document.forms[0];

	  window.location = "item_list.jsp?gu_shop=" + getURLParam("gu_shop") + "&gu_category=" + getURLParam("gu_category") + "&tr_category=" + getURLParam("tr_category") + "&top_parent_cat=" + getURLParam("top_parent_cat") + "&gu_bundles_cat=" + getURLParam("gu_bundles_cat") + "&skip=0&orderby=" + fld + "&where=" + escape("<%=sWhere%>") + "&field=" + getCombo(frm.sel_searched) + "&find=" + escape(frm.find.value) + "&screen_width=" + String(screen.width);
	}			

        // ----------------------------------------------------

        function selectAll() {
          // [~//Seleccionar/Deseleccionar todas las instancias~]
          
          var frm = document.forms[0];
          
          for (var c=0; c<jsProducts.length; c++)                        
            eval ("frm.elements['" + jsProducts[c] + "'].click()");
        } // selectAll()
       
       // ----------------------------------------------------
	
	function findProduct() {
	  // [~//Recargar la página para buscar una instancia~]
	  	  
	  var frm = document.forms[0];

	  if (getCombo(frm.sel_searched).length==0) {
	    alert ("Must specify field to be searched");
	    return false;
	  }
	  	  
	  if (frm.find.value.length==0) {
	    alert ("Must specify value to be searched");
	    return false;
	  }
	  
	  window.location = "item_list.jsp?gu_shop=" + getURLParam("gu_shop") + "&gu_category=" + getURLParam("gu_category") + "&tr_category=" + getURLParam("tr_category") + "&top_parent_cat=" + getURLParam("top_parent_cat") + "&gu_bundles_cat=" + getURLParam("gu_bundles_cat") + "&field=" + getCombo(frm.sel_searched) + "&find=" + escape(frm.find.value) + "&screen_width=" + String(screen.width);
	} // findProduct()

      // ----------------------------------------------------

	function discardSearch() {
	  	  	  
	  window.location = "item_list.jsp?gu_shop=" + getURLParam("gu_shop") + "&gu_category=" + getURLParam("gu_category") + "&tr_category=" + getURLParam("tr_category") + "&top_parent_cat=" + getURLParam("top_parent_cat") + "&gu_bundles_cat=" + getURLParam("gu_bundles_cat") + "&screen_width=" + String(screen.width);
	} // discardSearch()

      // ----------------------------------------------------

      var intervalId;
      var winclone;
      
      function findCloned() {
        // [~//Funcion temporizada que se llama cada 100 milisegundos para ver si ha terminado el clonado~]
        
        if (winclone.closed) {
          clearInterval(intervalId);
          setCombo(document.forms[0].sel_searched, "<%=DB.nm_product%>");
          document.forms[0].find.value = jsProductNm;
          findProduct();
        }
      } // findCloned()
      
      function clone() {        
        // [~//Abrir una ventana de clonado y poner un temporizador para recargar la página cuando se termine el clonado~]
                
        winclone = window.open ("../common/clone.jsp?id_domain=<%=id_domain%>&n_domain=" + escape("<%=n_domain%>") + "&datastruct=product_clon&gu_instance=" + jsProductId +"&opcode=CITM&classid=15", "cloneproduct", "directories=no,toolbar=no,menubar=no,width=320,height=200");                
        intervalId = setInterval ("findCloned()", 100);
      }	// clone()
      
      // ------------------------------------------------------	
    //-->    
  </SCRIPT>
  <SCRIPT TYPE="text/javascript">
    <!--
	var jsCategoriesLoaded = false;

	function setCombos() {
	  setCookie ("maxrows", "<%=iMaxRows%>");
	  setCombo(document.forms[0].maxresults, "<%=iMaxRows%>");
	  setCombo(document.forms[0].sel_searched, "<%=sField%>");
	} // setCombos()
    //-->    
  </SCRIPT>
  <TITLE>hipergate :: Products</TITLE>
</HEAD>
<BODY  TOPMARGIN="8" MARGINHEIGHT="8" onLoad="setCombos()">
    <FORM METHOD="post" TARGET="msgsexec">
      <TABLE WIDTH="100%"><TR><TD CLASS="striptitle"><FONT CLASS="title1"><% out.write(nullif(request.getParameter("tr_category"))); %></FONT></TD></TR></TABLE>  
      <INPUT TYPE="hidden" NAME="id_domain" VALUE="<%=id_domain%>">
      <INPUT TYPE="hidden" NAME="n_domain" VALUE="<%=n_domain%>">
      <INPUT TYPE="hidden" NAME="gu_workarea" VALUE="<%=gu_workarea%>">
      <INPUT TYPE="hidden" NAME="gu_category" VALUE="<%=gu_category%>">
      <INPUT TYPE="hidden" NAME="gu_bundles_cat" VALUE="<%=gu_bundles_cat%>">
      <INPUT TYPE="hidden" NAME="gu_shop" VALUE="<%=request.getParameter("gu_shop")%>">      
      <INPUT TYPE="hidden" NAME="tr_category" VALUE="<%=nullif(request.getParameter("tr_category"))%>">
      <INPUT TYPE="hidden" NAME="maxrows" VALUE="<%=String.valueOf(iMaxRows)%>">
      <INPUT TYPE="hidden" NAME="skip" VALUE="<%=String.valueOf(iSkip)%>">      
      <INPUT TYPE="hidden" NAME="where" VALUE="<%=sWhere%>">
      <INPUT TYPE="hidden" NAME="checkeditems">

<% if (gu_category.equals(gu_bundles_cat)) { %>

      <TABLE SUMMARY="Control menu for package categories" CELLSPACING="2" CELLPADDING="2">
      <TR><TD COLSPAN="8" BACKGROUND="../images/images/loginfoot_med.gif" HEIGHT="3"></TD></TR>
      <TR>
        <TD ALIGN="center"><IMG SRC="../images/images/new16x16.gif" WIDTH="16" HEIGHT="16" BORDER="0" ALT="New Package"></TD>
        <TD VALIGN="middle">
          <A HREF="#" onclick="createProduct()" CLASS="linkplain">New</A>
        </TD>
        <TD ALIGN="center"><IMG SRC="../images/images/papelera.gif" WIDTH="16" HEIGHT="16" BORDER="0" ALT="Delete Package"></TD>
        <TD>
          <A HREF="#" onclick="deleteProducts()" CLASS="linkplain">Delete</A>
        </TD>
        <TD VALIGN="bottom">&nbsp;&nbsp;<IMG SRC="../images/images/find16.gif" HEIGHT="16" BORDER="0" ALT="Search Package"></TD>
        <TD VALIGN="middle" NOWRAP>
          <SELECT NAME="sel_searched" CLASS="combomini">
            <OPTION VALUE=""></OPTION>
            <OPTION VALUE="nm_product">Name</OPTION>
            <OPTION VALUE="de_product">Description</OPTION>
            <OPTION VALUE="id_ref">Reference</OPTION>
          </SELECT>
          <INPUT CLASS="textmini" TYPE="text" NAME="find" MAXLENGTH="50" VALUE="<%=sFind%>">
	        &nbsp;<A HREF="javascript:findProduct();" CLASS="linkplain" TITLE="Search">Search</A>	  
        </TD>
        <TD VALIGN="bottom">&nbsp;&nbsp;&nbsp;<IMG SRC="../images/images/findundo16.gif" HEIGHT="16" BORDER="0" ALT="Discard Find Filter"></TD>
        <TD VALIGN="bottom" NOWRAP>
          <A HREF="javascript:discardSearch();" CLASS="linkplain" TITLE="Discard Find Filter">Discard</A>
          <FONT CLASS="textplain">&nbsp;&nbsp;&nbsp;Show&nbsp;</FONT><SELECT CLASS="combomini" NAME="maxresults" onchange="setCookie('maxrows',getCombo(document.forms[0].maxresults));"><OPTION VALUE="10">10<OPTION VALUE="20">20<OPTION VALUE="50">50<OPTION VALUE="100">100<OPTION VALUE="200">200<OPTION VALUE="500">500</SELECT>
        </TD>
      </TR>
      <TR><TD COLSPAN="8" BACKGROUND="../images/images/loginfoot_med.gif" HEIGHT="3"></TD></TR>
      </TABLE>

<% } else { %>

      <TABLE SUMMARY="Control menu for standard categories" CELLSPACING="2" CELLPADDING="2">
      <TR><TD COLSPAN="8" BACKGROUND="../images/images/loginfoot_med.gif" HEIGHT="3"></TD></TR>
      <TR>
        <TD ALIGN="center"><IMG SRC="../images/images/new16x16.gif" WIDTH="16" HEIGHT="16" BORDER="0" ALT="New Product"></TD>
        <TD VALIGN="middle">
          <A HREF="#" onclick="createProduct()" CLASS="linkplain">New</A>
        </TD>
        <TD ALIGN="center"><IMG SRC="../images/images/papelera.gif" WIDTH="16" HEIGHT="16" BORDER="0" ALT="Remove Products"></TD>
        <TD>
          <A HREF="#" onclick="deleteProducts()" CLASS="linkplain">Delete</A>
        </TD>
        <TD VALIGN="bottom">&nbsp;&nbsp;<IMG SRC="../images/images/find16.gif" HEIGHT="16" BORDER="0" ALT="Find Product"></TD>
        <TD VALIGN="middle" NOWRAP>
          <SELECT NAME="sel_searched" CLASS="combomini">
            <OPTION VALUE=""></OPTION>
            <OPTGROUP LABEL="Basic Data">
            <OPTION VALUE="nm_product">Name</OPTION>
            <OPTION VALUE="de_product">Description</OPTION>
            <OPTION VALUE="id_ref">Reference</OPTION>
            </OPTGROUP>
            <OPTGROUP LABEL="Attributes">
            <OPTION VALUE="scope">Scope</OPTION>
            <OPTION VALUE="subject">Subject</OPTION>
            <OPTION VALUE="author">Author</OPTION>
            <OPTION VALUE="size_z">Height</OPTION>
            <OPTION VALUE="size_x">Width</OPTION>
            <OPTION VALUE="size_y">Length</OPTION>
            <OPTION VALUE="department">Department</OPTION>
            <OPTION VALUE="days_to_deliver">Days to deliver</OPTION>
            <OPTION VALUE="availability">Availability</OPTION>
            <OPTION VALUE="product_group">Product Group</OPTION>
            <OPTION VALUE="isbn">ISBN</OPTION>
            <OPTION VALUE="brand">Brand</OPTION>
            <OPTION VALUE="doc_no">Doc. Number</OPTION>
            <OPTION VALUE="organization">Organization</OPTION>
            <OPTION VALUE="country">Country</OPTION>
            <OPTION VALUE="power">Power</OPTION>
            <OPTION VALUE="typeof">Type</OPTION>
            <OPTION VALUE="speed">Speed</OPTION>
            </OPTGROUP>
          </SELECT>
          <INPUT CLASS="textmini" TYPE="text" NAME="find" MAXLENGTH="50" VALUE="<%=sFind%>">
	  &nbsp;<A HREF="javascript:findProduct();" CLASS="linkplain" TITLE="Search">Search</A>	  
        </TD>
        <TD VALIGN="bottom">&nbsp;&nbsp;&nbsp;<IMG SRC="../images/images/findundo16.gif" HEIGHT="16" BORDER="0" ALT="Discard Find Filter"></TD>
        <TD VALIGN="bottom" NOWRAP>
          <A HREF="javascript:discardSearch();" CLASS="linkplain" TITLE="Discard Find Filter">Discard</A>
          <FONT CLASS="textplain">&nbsp;&nbsp;&nbsp;Show&nbsp;</FONT><SELECT CLASS="combomini" NAME="maxresults" onchange="setCookie('maxrows',getCombo(document.forms[0].maxresults));"><OPTION VALUE="10">10<OPTION VALUE="20">20<OPTION VALUE="50">50<OPTION VALUE="100">100<OPTION VALUE="200">200<OPTION VALUE="500">500</SELECT>
        </TD>
      </TR>
      <TR>
        <TD ALIGN="center"><IMG SRC="../images/images/movefiles.gif" WIDTH="24" HEIGHT="16" BORDER="0" ALT="M Products to another Category"></TD>
        <TD VALIGN="middle">
          <A HREF="#" onclick="moveProducts()" CLASS="linkplain" TITLE="M Products to another Category">Move</A>
        </TD>
        <!-- no copies by now
        <TD ALIGN="center"><IMG SRC="../images/images/copyfiles.gif" WIDTH="24" HEIGHT="16" BORDER="0" ALT="Copy Products"></TD>
        <TD><A HREF="#" onclick="copyProducts()" CLASS="linkplain">Copy</A></TD>
	      -->
        <TD COLSPAN="4"><FONT CLASS="textplain">&nbsp;to category&nbsp;</FONT><SELECT CLASS="combomini" onclick="if (!jsCategoriesLoaded) { jsCategoriesLoaded=true; this.options[0] = new Option('Loading...', ''); parent.msgsexec.document.location='cat_select.jsp?top_parent=' + getURLParam('top_parent_cat'); }" STYLE="width:260px"NAME="sel_target"></SELECT></TD> 
        <TD ALIGN="right"><IMG SRC="../images/images/resort.gif" WIDTH="22" HEIGHT="16" BORDER="0" ALT="Reorder Manually"></TD>
        <TD><A HREF="#" onclick="reorderProducts();" CLASS="linkplain" TITLE="Reorder Manually">Reorder</A></TD>
      </TR>
      <TR><TD COLSPAN="8" BACKGROUND="../images/images/loginfoot_med.gif" HEIGHT="3"></TD></TR>
      </TABLE>

<% } %>

      <TABLE SUMMARY="Products Listing" CELLSPACING="1" CELLPADDING="0">
        <TR>
          <TD COLSPAN="3" ALIGN="left">
<%    
    	  if (iProductCount>0) {
            if (iSkip>0) // [~//Si iSkip>0 entonces hay registros anteriores~]
              out.write("            <A HREF=\"item_list.jsp?id_domain=" + id_domain + "&n_domain=" + n_domain + "&gu_shop=" + request.getParameter("gu_shop") + "&gu_category=" + request.getParameter("gu_category") + "&tr_category=" + Gadgets.URLEncode(request.getParameter("tr_category")) + "&top_parent_cat=" + request.getParameter("gu_bundles_cat") + "&top_parent_cat=" + request.getParameter("gu_bundles_cat") + "&screen_width=" + request.getParameter("screen_width") + "&skip=" + String.valueOf(iSkip-iMaxRows) + "&orderby=" + sOrderBy + "&field=" + sField + "&find=" + sFind + "&selected=" + request.getParameter("selected") + "&subselected=" + request.getParameter("subselected") + "\" CLASS=\"linkplain\">&lt;&lt;&nbsp;Previous" + "</A>&nbsp;&nbsp;&nbsp;");
    
            if (!oProducts.eof())
              out.write("            <A HREF=\"item_list.jsp?id_domain=" + id_domain + "&n_domain=" + n_domain + "&gu_shop=" + request.getParameter("gu_shop") + "&gu_category=" + request.getParameter("gu_category") + "&tr_category=" + Gadgets.URLEncode(request.getParameter("tr_category")) + "&top_parent_cat=" + request.getParameter("gu_bundles_cat") + "&top_parent_cat=" + request.getParameter("gu_bundles_cat") + "&screen_width=" + request.getParameter("screen_width") + "&skip=" + String.valueOf(iSkip+iMaxRows) + "&orderby=" + sOrderBy + "&field=" + sField + "&find=" + sFind + "&selected=" + request.getParameter("selected") + "&subselected=" + request.getParameter("subselected") + "\" CLASS=\"linkplain\">Next&nbsp;&gt;&gt;</A>");
	  } // fi (iProductCount)
%>
          </TD>
        </TR>
        <TR>
          <TD CLASS="tableheader" BACKGROUND="../skins/<%=sSkin%>/tablehead.gif">&nbsp;<A HREF="javascript:sortBy(10);" oncontextmenu="return false;"><IMG SRC="../skins/<%=sSkin + (iOrderBy==10 ? "/sortedfld.gif" : "/sortablefld.gif")%>" WIDTH="14" HEIGHT="10" BORDER="0" ALT="Order by position"></A></TD>
          <TD CLASS="tableheader" WIDTH="<%=String.valueOf(floor(150f*fScreenRatio))%>" BACKGROUND="../skins/<%=sSkin%>/tablehead.gif">&nbsp;<A HREF="javascript:sortBy(2);" oncontextmenu="return false;"><IMG SRC="../skins/<%=sSkin + (iOrderBy==2 ? "/sortedfld.gif" : "/sortablefld.gif")%>" WIDTH="14" HEIGHT="10" BORDER="0" ALT="Order by name"></A>&nbsp;<B>Name</B></TD>
          <TD CLASS="tableheader" BACKGROUND="../skins/<%=sSkin%>/tablehead.gif">&nbsp;<A HREF="javascript:sortBy(5);" oncontextmenu="return false;"><IMG SRC="../skins/<%=sSkin + (iOrderBy==5 ? "/sortedfld.gif" : "/sortablefld.gif")%>" WIDTH="14" HEIGHT="10" BORDER="0" ALT="Order by priceSortuj według"></A>&nbsp;<B>Price&nbsp;</B></TD>
          <TD CLASS="tableheader" BACKGROUND="../skins/<%=sSkin%>/tablehead.gif">&nbsp;<A HREF="javascript:sortBy(8);" oncontextmenu="return false;"><IMG SRC="../skins/<%=sSkin + (iOrderBy==8 ? "/sortedfld.gif" : "/sortablefld.gif")%>" WIDTH="14" HEIGHT="10" BORDER="0" ALT="Order by quantity in stock"></A>&nbsp;<B>Stock&nbsp;</B></TD>
          <TD CLASS="tableheader" BACKGROUND="../skins/<%=sSkin%>/tablehead.gif">&nbsp;<A HREF="javascript:sortBy(3);" oncontextmenu="return false;"><IMG SRC="../skins/<%=sSkin + (iOrderBy==3 ? "/sortedfld.gif" : "/sortablefld.gif")%>" WIDTH="14" HEIGHT="10" BORDER="0" ALT="Order by status"></A>&nbsp;<B>Status&nbsp;</B></TD>
          <TD CLASS="tableheader" BACKGROUND="../skins/<%=sSkin%>/tablehead.gif">&nbsp;<A HREF="javascript:sortBy(4);" oncontextmenu="return false;"><IMG SRC="../skins/<%=sSkin + (iOrderBy==4 ? "/sortedfld.gif" : "/sortablefld.gif")%>" WIDTH="14" HEIGHT="10" BORDER="0" ALT="Order by last updated"></A>&nbsp;<B>Date Upd.&nbsp;</B></TD>
          <TD CLASS="tableheader" BACKGROUND="../skins/<%=sSkin%>/tablehead.gif"><A HREF="#" onclick="selectAll()" TITLE="Seleccionar todos"><IMG SRC="../images/images/selall16.gif" BORDER="0" ALT="Select all"></A></TD></TR>
<%
	  String sProdId,sProdNm,sProdDt,sPrice,sCurren,sStock,sStrip,sPos;
	  int iProdSt;
	  String aStatus[] ={ "<FONT color=red>Not available</FONT>", "<FONT color=green>In Stock</FONT>" , "<FONT color=gold>On demand</FONT>" };
	  
	  boolean bBargain;
	  	  
	  for (int i=0; i<iProductCount; i++) {
            sProdId = oProducts.getString(0,i);
            sProdNm = oProducts.getString(1,i);

	    if (oProducts.isNull(2,i))
	      iProdSt = 1;
	    else
	      iProdSt = (int) oProducts.getShort(2,i);
	    
            if (oProducts.isNull(3,i))
              sProdDt = "";
            else
              sProdDt = oProducts.getDateShort(3,i);

            if (!oProducts.isNull(5,i)) {
              
              sPrice = oProducts.getDecimal(5,i).toString();
              
              bBargain = true;
            }
            else if (!oProducts.isNull(4,i)) {
              sPrice = oProducts.getDecimal(4,i).toString();
              bBargain = false;
            }
            else {
              sPrice = "";
              bBargain = false;
            }
            
            if (oProducts.isNull(6,i))
              sCurren = "";
            else {
              sCurren = oProducts.getString(6,i);
              try {
                switch (Integer.parseInt(sCurren)) {
                  case 392:
                    sCurren="&yen;";
		    break;
                  case 826:
                    sCurren="&pound;";
                    break;
                  case 840:
                    sCurren="$";
                    break;
                  case 978:
                    sCurren="&euro;";
                    break;
		  default:
                    sCurren="&curren;";
                } // end switch
              } catch (NumberFormatException ignore) { }
	    }

            if (oProducts.isNull(7,i)) sStock  = ""; else sStock = String.valueOf((int) oProducts.getFloat(7,i));
	    
	    if (oProducts.isNull(9,i)) 
	      sPos = "";
	    else
	      sPos = String.valueOf(oProducts.getInt(9,i));

	    sStrip = String.valueOf((i%2)+1);   
%>            
            <TR HEIGHT="14">
              <TD CLASS="strip<%out.write(sStrip);%>"><INPUT TYPE="text" CLASS="combomini" SIZE="3" NAME="pos_<%=sProdId%>" VALUE="<% out.write(sPos); %>"></TD>
              <TD CLASS="strip<%out.write(sStrip);%>">&nbsp;<A HREF="#" onclick="modifyProduct('<% out.write (sProdId); %>')" oncontextmenu="jsProductId='<% out.write (sProdId); %>'; jsProductNm='<% out.write (sProdNm); %>'; return showRightMenu();" onmouseover="window.status='Editar Producto'; return true;" onmouseout="window.status='';" TITLE="Click Right Mouse Button for Context Menu"><% out.write (sProdNm); %></A></TD>
              <TD CLASS="strip<%out.write(sStrip);%>" ALIGN="right">&nbsp;<% if (sPrice.length()>0) out.write (sPrice+"&nbsp;"+sCurren); %></TD>
              <TD CLASS="strip<%out.write(sStrip);%>" ALIGN="right">&nbsp;<% out.write (sStock); %></TD>
              <TD CLASS="strip<%out.write(sStrip);%>" ALIGN="center">&nbsp;<% out.write (aStatus[iProdSt]); %></TD>
              <TD CLASS="strip<%out.write(sStrip);%>">&nbsp;<% if (null!=sProdDt) out.write (sProdDt); %></TD>
              <TD CLASS="strip<%out.write(sStrip);%>" ALIGN="center"><INPUT VALUE="1" TYPE="checkbox" NAME="<% out.write (sProdId); %>"></TD>
	    </TR>
<%        } // next(i) %>          	  
      </TABLE>
    </FORM>
    <!-- DynFloat -->
    <DIV id="divHolder" style="width:100px;height:20px;z-index:200;visibility:hidden;position:absolute;top:31px;left:0px"></DIV>
    <FORM name="divForm"><input type="hidden" name="divField" value=""></FORM>
    <SCRIPT src="../javascript/dynfloat.js"></SCRIPT>    
    <!-- DynFloat -->

    <!-- RightMenuBody -->
    <DIV class="menuDiv" id="rightMenuDiv">
      <TABLE border="0" cellpadding="0" cellspacing="0" width="100">
        <TR height="1">
          <TD width="1" bgcolor="#D6D3CE"><IMG src="../images/images/spacer.gif" height="1" width="1"></TD>
          <TD width="1" bgcolor="#D6D3CE"><IMG src="../images/images/spacer.gif" height="1" width="1"></TD>
          <TD bgcolor="#D6D3CE"><IMG src="../images/images/spacer.gif" height="1" width="1"></TD>
          <TD width="1" bgcolor="#D6D3CE"><IMG src="../images/images/spacer.gif" height="1" width="1"></TD>
          <TD width="1" bgcolor="#424142"><IMG src="../images/images/spacer.gif" height="1" width="1"></TD>
        </TR>
        <TR height="1">
          <TD width="1" bgcolor="#D6D3CE"><IMG src="../images/images/spacer.gif" height="1" width="1"></TD>
          <TD width="1" bgcolor="#FFFFFF"><IMG src="../images/images/spacer.gif" height="1" width="1"></TD>
          <TD bgcolor="#FFFFFF"><IMG src="../images/images/spacer.gif" height="1" width="1"></TD>
          <TD width="1" bgcolor="#848284"><IMG src="../images/images/spacer.gif" height="1" width="1"></TD>
          <TD width="1" bgcolor="#424142"><IMG src="../images/images/spacer.gif" height="1" width="1"></TD>
        </TR>
        <TR>
          <TD width="1" bgcolor="#D6D3CE"><IMG src="../images/images/spacer.gif" height="1" width="1"></TD>
          <TD width="1" bgcolor="#FFFFFF"><IMG src="../images/images/spacer.gif" height="1" width="1"></TD>
          <TD bgcolor="#D6D3CE">
            <!-- Opciones -->
            <DIV class="menuCP" onMouseOver="menuHighLight(this)" onMouseOut="menuHighLight(this)" onClick="modifyProduct(jsProductId)">Open</DIV>
            <DIV id="menuOpt01" class="menuE" onMouseOver="menuHighLight(this)" onMouseOut="menuHighLight(this)" onClick="clone()">Duplicate</DIV>
            <!-- /Opciones -->
          </TD>
          <TD width="1" bgcolor="#848284"><IMG src="../images/images/spacer.gif" height="1" width="1"></TD>
          <TD width="1" bgcolor="#424142"><IMG src="../images/images/spacer.gif" height="1" width="1"></TD>
        </TR>
        <TR height="1">
          <TD width="1" bgcolor="#D6D3CE"><IMG src="../images/images/spacer.gif" height="1" width="1"></TD>
          <TD width="1" bgcolor="#848284"><IMG src="../images/images/spacer.gif" height="1" width="1"></TD>
          <TD bgcolor="#848284"><IMG src="../images/images/spacer.gif" height="1" width="1"></TD>
          <TD width="1" bgcolor="#848284"><IMG src="../images/images/spacer.gif" height="1" width="1"></TD>
          <TD width="1" bgcolor="#424142"><IMG src="../images/images/spacer.gif" height="1" width="1"></TD>
        </TR>
        <TR height="1">
          <TD width="1" bgcolor="#424142"><IMG src="../images/images/spacer.gif" height="1" width="1"></TD>
          <TD width="1" bgcolor="#424142"><IMG src="../images/images/spacer.gif" height="1" width="1"></TD>
          <TD bgcolor="#424142"><IMG src="../images/images/spacer.gif" height="1" width="1"></TD>
          <TD width="1" bgcolor="#424142"><IMG src="../images/images/spacer.gif" height="1" width="1"></TD>
          <TD width="1" bgcolor="#424142"><IMG src="../images/images/spacer.gif" height="1" width="1"></TD>
        </TR>
      </TABLE>
    </DIV>
    <!-- /RightMenuBody -->
</BODY>
</HTML>
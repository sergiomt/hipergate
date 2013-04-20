<%@ page import="java.io.IOException,java.net.URLDecoder,java.sql.SQLException,com.knowgate.jdc.*,com.knowgate.dataobjs.*,com.knowgate.acl.*,com.knowgate.hipergate.Shop,com.knowgate.hipergate.DBLanguages,com.knowgate.workareas.WorkArea" language="java" session="false" contentType="text/html;charset=UTF-8" %>
<jsp:useBean id="GlobalDBLang" scope="application" class="com.knowgate.hipergate.DBLanguages"/>
<%@ include file="../methods/dbbind.jsp" %><%@ include file="../methods/cookies.jspf" %><%@ include file="../methods/authusrs.jspf" %><%@ include file="../methods/clientip.jspf" %><%@ include file="../methods/nullif.jspf" %><% 

  if (autenticateSession(GlobalDBBind, request, response)<0) return;
  
  response.addHeader ("Pragma", "no-cache");
  response.addHeader ("cache-control", "no-store");
  response.setIntHeader("Expires", 0);

  String sSkin = getCookie(request, "skin", "default");  
  String sLanguage = getNavigatorLanguage(request);
  int iAppMask = Integer.parseInt(getCookie(request, "appmask", "0"));
  String sCountriesLookUp = null;
  String sStreetLookUp = null;
  
  String gu_user = getCookie(request, "userid", "");
  String id_domain = request.getParameter("id_domain");
  String n_domain = request.getParameter("n_domain");
  String gu_workarea = request.getParameter("gu_workarea");
  String gu_shop = nullif(request.getParameter("gu_shop"));
  String nm_shop = "";
  String nm_company = "";
  String id_legal = "";
  short bo_active = (short)1;
  String gu_root_cat = "";
  String gu_bundles_cat = "";
  
  Shop oShp = new Shop();
  DBSubset oShops = null;
  int iShops = 0;
  boolean bIsAdmin = false;    
  JDCConnection oConn = null;  
    
  try {    
    oConn = GlobalDBBind.getConnection("shop_edit");
    
    bIsAdmin = WorkArea.isAdmin(oConn, gu_workarea, gu_user);
    
    oShops = new DBSubset(DB.k_shops, DB.nm_shop, DB.gu_workarea + "=?", 10);
    iShops = oShops.load (oConn, new Object[]{gu_workarea});
    
    if (gu_shop.length()>0) {
      oShp.load(oConn, new Object[]{gu_shop});
      nm_shop = oShp.getString(DB.nm_shop).toUpperCase();
      gu_root_cat = oShp.getString(DB.gu_root_cat);
      gu_bundles_cat = oShp.getString(DB.gu_bundles_cat);
      bo_active = oShp.getShort(DB.bo_active);
      gu_workarea = oShp.getString(DB.gu_workarea);
      id_domain = String.valueOf(oShp.getInt(DB.id_domain));
      id_legal = oShp.getStringNull(DB.id_legal,"");
      nm_company = oShp.getStringNull(DB.nm_company,"");
    }

    sStreetLookUp = DBLanguages.getHTMLSelectLookUp (oConn, "k_addresses_lookup", gu_workarea, "tp_street", sLanguage);    
    sCountriesLookUp = GlobalDBLang.getHTMLCountrySelect(oConn, sLanguage);
    
    oConn.close("shop_edit");
  }
  catch (IllegalStateException e) {  
    if (oConn!=null)
      if (!oConn.isClosed()) oConn.close("shop_edit");
    oConn=null;
    response.sendRedirect (response.encodeRedirectUrl ("../common/errmsg.jsp?title=IllegalStateException&desc=" + e.getMessage() + "&resume=_close"));  
  }
  catch (SQLException e) {  
    if (oConn!=null)
      if (!oConn.isClosed()) oConn.close("shop_edit");
    oConn=null;
    response.sendRedirect (response.encodeRedirectUrl ("../common/errmsg.jsp?title=SQLException&desc=" + e.getLocalizedMessage() + "&resume=_close"));  
  }
  
  if (null==oConn) return;
    
  oConn = null;
  
  if (!bIsAdmin) {
    response.sendRedirect (response.encodeRedirectUrl ("../common/errmsg.jsp?title=SecurityException&desc=Administrator role is needed to access this page&resume=_close"));    
    return;
  }
%>

<HTML LANG="<% out.write(sLanguage); %>">
<HEAD>
  <TITLE>hipergate :: Edit Catalog</TITLE>
  <SCRIPT SRC="../javascript/cookies.js"></SCRIPT>  
  <SCRIPT SRC="../javascript/setskin.js"></SCRIPT>
  <SCRIPT SRC="../javascript/trim.js"></SCRIPT>
  <SCRIPT SRC="../javascript/combobox.js"></SCRIPT> 
  <SCRIPT SRC="../javascript/usrlang.js"></SCRIPT> 
  <SCRIPT LANGUAGE="JavaScript1.2" TYPE="text/javascript" DEFER="defer">
    <!--
      var jsShops = new Array(<% boolean nil = true; for (int s=0; s<iShops; s++) if (!nm_shop.equalsIgnoreCase(oShops.getString(0,s))) { out.write((nil ? "" : ",") + "'"+oShops.getString(0,s).toUpperCase()+"'"); nil=false; } %>);
      
      // ------------------------------------------------------

      function lookup(odctrl) {
        var frm = window.document.forms[0];        
        switch(parseInt(odctrl)) {
          case 2:
            window.open("../common/lookup_f.jsp?nm_table=k_addresses_lookup&id_language=" + getUserLanguage() + "&id_section=tp_street&tp_control=2&nm_control=sel_street&nm_coding=tp_street", "lookupaddrstreet", "toolbar=no,directories=no,menubar=no,resizable=no,width=480,height=520");
            break;
        }
      } // lookup()

      // ------------------------------------------------------
      
      function validate() {
        var frm = window.document.forms[0];
	var txt = rtrim(frm.nm_shop.value);
	var txu = txt.toUpperCase();
	
	if (txt.length==0) {
	  alert ("Catalog name is mandatory");
	  return false;
	}

	if (txt.indexOf("'")>=0 || txt.indexOf("%")>=0 || txt.indexOf("*")>=0 || txt.indexOf(",")>=0 || txt.indexOf(";")>=0 || txt.indexOf("/")>=0 || txt.indexOf("?")>=0 || txt.indexOf("&")>=0) {
	  alert ("Catalog name contains invalid characters");
	  return false;
	}
        
        for (var s=0; s<jsShops.length; s++)
          if (txu==jsShops[s]) {
	    alert ("Another Catalog with same name already exists");
	    return false;
          }
          
        frm.nm_shop.value = txu;

        if (frm.sel_country.options.selectedIndex>0) {
	  frm.id_country.value = getCombo(frm.sel_country);
	  frm.nm_country.value = getComboText(frm.sel_country);
        } else {
          frm.id_country.value = frm.nm_country.value = "";
        }
        
        frm.tp_street.value = getCombo(frm.sel_street);

        return true;
      } // validate;

      // ------------------------------------------------------
      
      function setCombos() {
        var frm = document.forms[0];

	if (""=="<%=oShp.getStringNull(DB.id_country,"").trim()%>")
          setCombo (frm.sel_country, getUserLanguage());
	else
          setCombo  (frm.sel_country, "<%=oShp.getStringNull(DB.id_country,"").trim()%>");
      
        setCombo (frm.sel_street, frm.tp_street.value);
        
        if (frm.sel_country.options.selectedIndex>0) {
	  frm.id_country.value = getCombo(frm.sel_country);
	  frm.nm_country.value = getComboText(frm.sel_country);
        }                
      } // setCombos()      
    //-->
  </SCRIPT>
</HEAD>
<BODY  TOPMARGIN="8" MARGINHEIGHT="8" onLoad="setCombos()">
  <DIV class="cxMnu1" style="width:290px"><DIV class="cxMnu2">
    <SPAN class="hmMnuOff" onMouseOver="this.className='hmMnuOn'" onMouseOut="this.className='hmMnuOff'" onClick="history.back()"><IMG src="../images/images/toolmenu/historyback.gif" width="16" style="vertical-align:middle" height="16" border="0" alt="Back"> Back</SPAN>
    <SPAN class="hmMnuOff" onMouseOver="this.className='hmMnuOn'" onMouseOut="this.className='hmMnuOff'" onClick="location.reload(true)"><IMG src="../images/images/toolmenu/locationreload.gif" width="16" style="vertical-align:middle" height="16" border="0" alt="Update"> Update</SPAN>
    <SPAN class="hmMnuOff" onMouseOver="this.className='hmMnuOn'" onMouseOut="this.className='hmMnuOff'" onClick="window.print()"><IMG src="../images/images/toolmenu/windowprint.gif" width="16" height="16" style="vertical-align:middle" border="0" alt="Print"> Print</SPAN>
  </DIV></DIV>
  <TABLE WIDTH="100%">
    <TR><TD><IMG SRC="../images/images/spacer.gif" HEIGHT="4" WIDTH="1" BORDER="0"></TD></TR>
    <TR><TD CLASS="striptitle"><FONT CLASS="title1">Edit Catalog</FONT></TD></TR>
  </TABLE>  
  <FORM NAME="" METHOD="post" ACTION="shop_edit_store.jsp" onSubmit="return validate()">
    <INPUT TYPE="hidden" NAME="id_domain" VALUE="<%=id_domain%>">
    <INPUT TYPE="hidden" NAME="n_domain" VALUE="<%=n_domain%>">
    <INPUT TYPE="hidden" NAME="gu_workarea" VALUE="<%=gu_workarea%>">
    <INPUT TYPE="hidden" NAME="gu_shop" VALUE="<%=gu_shop%>">
    <INPUT TYPE="hidden" NAME="gu_root_cat" VALUE="<%=gu_root_cat%>">
    <INPUT TYPE="hidden" NAME="gu_bundles_cat" VALUE="<%=gu_bundles_cat%>">
    
    <TABLE CLASS="formback">
      <TR><TD>
        <TABLE WIDTH="100%" CLASS="formfront">
          <TR>
            <TD ALIGN="right"><FONT CLASS="formstrong">Active:</FONT></TD>
            <TD ALIGN="left"><INPUT TYPE="checkbox" NAME="bo_active" VALUE="1" <% out.write(bo_active==(short)1 ? " CHECKED" : ""); %>>
            &nbsp;&nbsp;&nbsp;
            <FONT CLASS="formstrong">Name:</FONT>
            &nbsp;
	    <INPUT TYPE="text" NAME="nm_shop" MAXLENGTH="100" SIZE="30" VALUE="<% out.write(nm_shop); %>">
            </TD>
          </TR>          
          <TR>
            <TD ALIGN="right"><FONT CLASS="formstrong">Legal Id:</FONT></TD>
            <TD ALIGN="left"><INPUT TYPE="text" NAME="id_legal" MAXLENGTH="16" SIZE="12" VALUE="<% out.write(id_legal); %>"></TD>
          </TR>
          <TR>
            <TD ALIGN="right"><FONT CLASS="formstrong">Legal Name:</FONT></TD>
            <TD ALIGN="left"><INPUT TYPE="text" NAME="nm_company" MAXLENGTH="70" SIZE="40" VALUE="<% out.write(nm_company); %>"></TD>
          </TR>
<% if (sLanguage.equalsIgnoreCase("es")) { %>
          <TR>
            <TD ALIGN="right" WIDTH="140">
              <A HREF="javascript:lookup(2)"><IMG SRC="../images/images/find16.gif" HEIGHT="16" BORDER="0" ALT="Street Types"></A>&nbsp;
              <SELECT CLASS="combomini" NAME="sel_street"><OPTION VALUE=""></OPTION><%=sStreetLookUp%></SELECT>
            </TD>
            <TD ALIGN="left" WIDTH="460">
              <INPUT TYPE="hidden" NAME="tp_street" VALUE="<%=oShp.getStringNull(DB.tp_street,"")%>">
              <INPUT TYPE="text" NAME="nm_street" MAXLENGTH="100" SIZE="32" VALUE="<%=oShp.getStringNull(DB.nm_street,"")%>">             
              &nbsp;&nbsp;
              <FONT CLASS="formplain">Address:</FONT>&nbsp;<INPUT TYPE="text" NAME="nu_street" MAXLENGTH="16" SIZE="4" VALUE="<%=oShp.getStringNull(DB.nu_street,"")%>">
            </TD>
          </TR>
<% } else { %>
          <TR>
            <TD ALIGN="right">
	      <FONT CLASS="formplain">Address:</FONT>&nbsp;
            </TD>
            <TD ALIGN="left">
              <INPUT TYPE="text" NAME="nu_street" MAXLENGTH="16" SIZE="4" VALUE="<%=oShp.getStringNull(DB.nu_street,"")%>">
              <INPUT TYPE="text" NAME="nm_street" MAXLENGTH="100" SIZE="30" VALUE="<%=oShp.getStringNull(DB.nm_street,"")%>">
              <INPUT TYPE="hidden" NAME="tp_street" VALUE="<%=oShp.getStringNull(DB.tp_street,"")%>">
              <SELECT NAME="sel_street"><OPTION VALUE=""></OPTION><%=sStreetLookUp%></SELECT>
              <A HREF="javascript:lookup(2)"><IMG SRC="../images/images/find16.gif" HEIGHT="16" BORDER="0" ALT="Street Types"></A>              
            </TD>
          </TR>
<% } %>
          <TR>
            <TD ALIGN="right" WIDTH="140"><FONT CLASS="formplain">Flat:</FONT></TD>
            <TD ALIGN="left" WIDTH="460">
              <INPUT TYPE="text" NAME="tx_addr1" MAXLENGTH="100" SIZE="10" VALUE="<%=oShp.getStringNull(DB.tx_addr1,"")%>">
              &nbsp;&nbsp;
              <FONT CLASS="formplain">Building:</FONT>&nbsp;
              <INPUT TYPE="text" NAME="tx_addr2" MAXLENGTH="100" SIZE="20" VALUE="<%=oShp.getStringNull(DB.tx_addr2,"")%>">              
            </TD>
          </TR>
          <TR>
            <TD ALIGN="right" WIDTH="140"><FONT CLASS="formplain">Country:</FONT></TD>
            <TD ALIGN="left" WIDTH="460">
	      <SELECT NAME="sel_country"><OPTION VALUE=""></OPTION><%=sCountriesLookUp%></SELECT>
              <INPUT TYPE="hidden" NAME="id_country" VALUE="<%=oShp.getStringNull(DB.id_country,"").trim()%>">
              <INPUT TYPE="hidden" NAME="nm_country" VALUE="<%=oShp.getStringNull(DB.nm_country,"")%>">
            </TD>
          </TR>
          <TR>
            <TD ALIGN="right" WIDTH="140"><FONT CLASS="formplain">State/Province:</FONT></TD>
            <TD ALIGN="left" WIDTH="460">
              <INPUT TYPE="text" NAME="nm_state" MAXLENGTH="30" VALUE="<%=oShp.getStringNull(DB.nm_state,"")%>">
            </TD>
          </TR>
          <TR>
            <TD ALIGN="right" WIDTH="140"><FONT CLASS="formplain">City:</FONT></TD>
            <TD ALIGN="left" WIDTH="460">
              <INPUT TYPE="text" NAME="mn_city" MAXLENGTH="50" SIZE="30" VALUE="<%=oShp.getStringNull(DB.mn_city,"")%>">
              &nbsp;&nbsp;
              <FONT CLASS="formplain">Zipcode:</FONT>
              &nbsp;
              <INPUT TYPE="text" NAME="zipcode" MAXLENGTH="30" SIZE="5" VALUE="<%=oShp.getStringNull(DB.zipcode,"")%>">
            </TD>
          </TR>
          <TR>
            <TD ALIGN="right" WIDTH="140"><FONT CLASS="formplain">Telephone:</FONT></TD>
            <TD ALIGN="left" WIDTH="460">
              <INPUT TYPE="text" NAME="work_phone" MAXLENGTH="16" SIZE="12" VALUE="<%=oShp.getStringNull(DB.work_phone,"")%>">
	      &nbsp;&nbsp;&nbsp;
	      <FONT CLASS="formplain">Fax:</FONT>&nbsp;
	      <INPUT TYPE="text" NAME="work_phone" MAXLENGTH="16" SIZE="12" VALUE="<%=oShp.getStringNull(DB.fax_phone,"")%>">
            </TD>
          </TR>
          <TR>
            <TD ALIGN="right" WIDTH="140"><FONT CLASS="formplain">Bank:</FONT></TD>
            <TD ALIGN="left" WIDTH="460">
              <INPUT TYPE="text" NAME="nm_bank" MAXLENGTH="50" SIZE="18" VALUE="<%=oShp.getStringNull(DB.nm_bank,"")%>">
              &nbsp;&nbsp;&nbsp;
              <FONT CLASS="formplain">Account:</FONT>
              &nbsp;
              <INPUT TYPE="text" NAME="nu_bank_acc" MAXLENGTH="20" SIZE="24" VALUE="<%=oShp.getStringNull(DB.nu_bank_acc,"")%>">
            </TD>
          </TR>
          <TR>
            <TD COLSPAN="2"><HR></TD>
          </TR>
          <TR>
    	    <TD COLSPAN="2" ALIGN="center">
              <INPUT TYPE="submit" ACCESSKEY="s" VALUE="Save" CLASS="pushbutton" STYLE="width:80" TITLE="ALT+s">&nbsp;
    	      &nbsp;&nbsp;<INPUT TYPE="button" ACCESSKEY="c" VALUE="Cancel" CLASS="closebutton" STYLE="width:80" TITLE="ALT+c" onclick="window.close()">
    	      <BR>
    	    </TD>	            
        </TABLE>
      </TD></TR>
    </TABLE>                 
  </FORM>
</BODY>
</HTML>

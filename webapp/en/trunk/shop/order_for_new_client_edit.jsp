<%@ page import="java.io.IOException,java.net.URLDecoder,java.sql.SQLException,com.knowgate.jdc.*,com.knowgate.dataobjs.*,com.knowgate.acl.*,com.knowgate.hipergate.*" language="java" session="false" contentType="text/html;charset=UTF-8" %>
<%@ include file="../methods/dbbind.jsp" %><%@ include file="../methods/cookies.jspf" %><%@ include file="../methods/authusrs.jspf" %><%@ include file="../methods/clientip.jspf" %><%@ include file="../methods/nullif.jspf" %>
<jsp:useBean id="GlobalCacheClient" scope="application" class="com.knowgate.cache.DistributedCachePeer"/><jsp:useBean id="GlobalDBLang" scope="application" class="com.knowgate.hipergate.DBLanguages"/><% 
/*  
  Copyright (C) 2008  Know Gate S.L. All rights reserved.
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

  String sSkin = getCookie(request, "skin", "xp");
  String sLanguage = getNavigatorLanguage(request);
  
  String id_domain = request.getParameter("id_domain");
  String gu_workarea = request.getParameter("gu_workarea");
    
  String sStatusLookUp = "", sStreetLookUp = "", sSalutationLookUp = "", sCountriesLookUp = "", sShops = "";
    
  JDCConnection oConn = null;

	DBSubset oShops = new DBSubset(DB.k_shops, DB.gu_shop+","+DB.nm_shop+","+DB.gu_bundles_cat,
	  														DB.bo_active+"<>0 AND "+DB.id_domain+"=? AND "+DB.gu_workarea+"=? ORDER BY 2", 10);

  int iShops = 0;
  int iProds = 0;

  try {

    oConn = GlobalDBBind.getConnection("order_for_new_client_edit");  

    sStatusLookUp  = DBLanguages.getHTMLSelectLookUp (GlobalCacheClient, oConn, DB.k_orders_lookup, gu_workarea, DB.id_status, sLanguage);
    sStreetLookUp = DBLanguages.getHTMLSelectLookUp (GlobalCacheClient, oConn, DB.k_addresses_lookup, gu_workarea, DB.tp_street, sLanguage);
    sSalutationLookUp = DBLanguages.getHTMLSelectLookUp (GlobalCacheClient, oConn, DB.k_addresses_lookup, gu_workarea, DB.tx_salutation, sLanguage);
    sCountriesLookUp = GlobalDBLang.getHTMLCountrySelect(oConn, sLanguage);

	  iShops = oShops.load(oConn, new Object[]{new Integer(id_domain), gu_workarea});
		iProds = oShops.loadSubrecords(oConn, DB.v_prod_cat, DB.gu_category, 2);

	  for (int s=0; s<iShops; s++) {
	    sShops += "<OPTGROUP LABEL=\""+oShops.getString(1,s)+"\"></OPTGROUP>";
	    
	    if (iProds>0) {
	      DBSubset oProds = oShops.getSubrecords(s);
	      for (int p=0; p<oProds.getRowCount(); p++) {
	        sShops += "<OPTION VALUE=\""+oShops.getString(0,s)+":"+oProds.getString(DB.gu_product,p)+"\">"+oProds.getString(DB.nm_product,p)+"</OPTION>";	      
	      } // next
	    }  // fi (iProds)
    } // next (s)

    oConn.close("order_for_new_client_edit");
  }
  catch (SQLException e) {  
    if (oConn!=null)
      if (!oConn.isClosed()) oConn.close("order_for_new_client_edit");
    oConn = null;
    response.sendRedirect (response.encodeRedirectUrl ("../common/errmsg.jsp?title=Exception&desc=" + e.getMessage() + "&resume=_close"));  
  }
  
  if (null==oConn) return;
  
  oConn = null;  
%>
<HTML LANG="<% out.write(sLanguage); %>">
<HEAD>
  <TITLE>hipergate :: Order for new customer</TITLE>
  <SCRIPT TYPE="text/javascript" SRC="../javascript/cookies.js"></SCRIPT>
  <SCRIPT TYPE="text/javascript" SRC="../javascript/setskin.js"></SCRIPT>
  <SCRIPT TYPE="text/javascript" SRC="../javascript/getparam.js"></SCRIPT>
  <SCRIPT TYPE="text/javascript" SRC="../javascript/usrlang.js"></SCRIPT>  
  <SCRIPT TYPE="text/javascript" SRC="../javascript/combobox.js"></SCRIPT>
  <SCRIPT TYPE="text/javascript" SRC="../javascript/trim.js"></SCRIPT>
  <SCRIPT TYPE="text/javascript" SRC="../javascript/email.js"></SCRIPT>  
  <SCRIPT TYPE="text/javascript" SRC="../javascript/datefuncs.js"></SCRIPT>
  <SCRIPT TYPE="text/javascript" SRC="../javascript/xmlhttprequest.js"></SCRIPT>
  <SCRIPT LANGUAGE="JavaScript1.2" TYPE="text/javascript" DEFER="defer">
    <!--
      
      // ------------------------------------------------------
              
      function lookup(odctrl) {
	      var frm = window.document.forms[0];
        
        switch(parseInt(odctrl)) {
          case 1:
            window.open("../common/lookup_f.jsp?nm_table=k_addresses_lookup&id_language=" + getUserLanguage() + "&id_section=a1_tp_street&tp_control=2&nm_control=a1_sel_street&nm_coding=tp_street", "lookupaddrstreet", "toolbar=no,directories=no,menubar=no,resizable=no,width=480,height=520");
            break;
          case 2:
            window.open("../common/lookup_f.jsp?nm_table=k_addresses_lookup&id_language=" + getUserLanguage() + "&id_section=a2_tp_street&tp_control=2&nm_control=a2_sel_street&nm_coding=tp_street", "lookupaddrstreet", "toolbar=no,directories=no,menubar=no,resizable=no,width=480,height=520");
            break;
          case 3:
            if (frm.a1_sel_country.options.selectedIndex>0)
              window.open("../common/lookup_f.jsp?nm_table=k_addresses_lookup&id_language=" + getUserLanguage() + "&id_section=" + getCombo(frm.a1_sel_country) + "&tp_control=2&nm_control=a1_sel_state&nm_coding=id_state", "lookupaddrstate", "toolbar=no,directories=no,menubar=no,resizable=no,width=480,height=520");
            else
              alert ("A country must be choosen before te State");
            break;
          case 4:
            if (frm.a2_sel_country.options.selectedIndex>0)
              window.open("../common/lookup_f.jsp?nm_table=k_addresses_lookup&id_language=" + getUserLanguage() + "&id_section=" + getCombo(frm.a2_sel_country) + "&tp_control=2&nm_control=a2_sel_state&nm_coding=id_state", "lookupaddrstate", "toolbar=no,directories=no,menubar=no,resizable=no,width=480,height=520");
            else
              alert ("A country must be choosen before te State");
            break;

        } // end switch()
      } // lookup()

      // ------------------------------------------------------

      function reference(odctrl) {
        var frm = document.forms[0];
        var c1,c2,c12;
        
        switch(parseInt(odctrl)) {
          case 1:
            if (frm.nm_company.value.indexOf("'")>=0)
              alert("Company name contains invalid characters");
            else
              window.open("../common/reference.jsp?nm_table=k_companies&tp_control=1&nm_control=nm_legal AS nm_company&nm_coding=gu_company" + 
                          (frm.nm_company.value.length==0 || document.gu_company.value.length==32 ? "" : "&where=" + escape(" <%=DB.nm_legal%> LIKE '"+frm.nm_company.value+"%' ")),
                          "", "scrollbars=yes,toolbar=no,directories=no,menubar=no,resizable=no,width=480,height=520");
            break;
            
        }
      } // reference()

      // ------------------------------------------------------
      
      function loadStates1() {
	      var frm = window.document.forms[0];

        clearCombo(frm.a1_sel_state);
        
        if (frm.a1_sel_country.options.selectedIndex>0) {
          parent.frames[1].location.href = "../common/addr_load.jsp?id_language=<%=sLanguage%>&gu_workarea=<%=gu_workarea%>&id_section=" + getCombo(frm.a1_sel_country) + "&control=a1_sel_state";        
        
          sortCombo(frm.a1_sel_state);
        }  
      } // loadStates1

      // ------------------------------------------------------
      
      function loadStates2() {
	      var frm = window.document.forms[0];

        clearCombo(frm.a2_sel_state);
        
        if (frm.a2_sel_country.options.selectedIndex>0) {
          parent.frames[1].location.href = "../common/addr_load.jsp?id_language=<%=sLanguage%>&gu_workarea=<%=gu_workarea%>&id_section=" + getCombo(frm.a2_sel_country) + "&control=a2_sel_state";        
        
          sortCombo(frm.a2_sel_state);
        }  
      } // loadStates2

      // ------------------------------------------------------

      function sameAddress(yn) {
        var frm = document.forms[0];
        
        if (yn) {
          document.getElementById('invoicing_data').style.display = "none";
				  frm.a2_sel_street.options.selectedIndex = frm.a2_sel_street.options.selectedIndex;
					frm.a2_tp_street.value = frm.a1_tp_street.value;
					frm.a2_nm_street.value = frm.a1_nm_street.value;
					frm.a2_nu_street.value = frm.a1_nu_street.value;
					frm.a2_tx_addr1.value  = frm.a1_tx_addr1.value;
					frm.a2_tx_addr2.value  = frm.a1_tx_addr2.value;
					frm.a2_id_country.value= frm.a1_id_country.value;
					frm.a2_nm_country.value= frm.a1_nm_country.value;
					frm.a2_id_state.value  = frm.a1_id_state.value;
					frm.a2_nm_state.value  = frm.a1_nm_state.value;
					frm.a2_mn_city.value   = frm.a1_mn_city.value;
					frm.a2_zipcode.value   = frm.a1_zipcode.value;
					frm.a2_tx_email.value  = frm.a1_tx_email.value;
					frm.a2_fax_phone.value = frm.a1_fax_phone.value;
					frm.a2_fixed_phone.value = frm.a1_fixed_phone.value;
					frm.a2_mobile_phone.value = frm.a1_mobile_phone.value;
          frm.a2_sel_country.options.selectedIndex = frm.a1_sel_country.options.selectedIndex;
					if (frm.a1_sel_state.options.selectedIndex>0) {
					  setCombo(frm.a2_sel_state, getCombo(frm.a1_sel_state));
					  if (frm.a1_sel_state.options.selectedIndex!=frm.a2_sel_state.options.selectedIndex) {
					    alert ("frm.a1_sel_state="+frm.a1_sel_state);
					    comboPush (frm.a2_sel_state, getComboText(frm.a1_sel_state), getCombo(frm.a1_sel_state), false, true);
				    }
				  }
        } else {
          document.getElementById('invoicing_data').style.display = "block";
        }
      } // sameAddress

      // ------------------------------------------------------
      
      function lookupPassport() {
        if (document.forms[0].sn_passport.value.length>0) {
        	var fnd = httpRequestText("../common/passport_lookup.jsp?gu_workarea=<%=gu_workarea%>&sn_passport="+document.forms[0].sn_passport.value);
          if ("found"==fnd.substr(0,5)) {
            if (window.confirm("Another customer with the same identifier already exists "+document.forms[0].sn_passport.value+" Would you like to reuse the current customer information for a new order?"))
              document.location = "order_edit.jsp?id_domain=<%=id_domain%>&gu_workarea=<%=gu_workarea%>&gu_contact="+fnd.split(" ")[1];
          }				  
				}
      }

      // ------------------------------------------------------
      
      function lookupLegalId() {
        if (document.forms[0].id_legal.value.length>0) {
        	var fnd = httpRequestText("../common/legalid_lookup.jsp?gu_workarea=<%=gu_workarea%>&id_legal="+document.forms[0].id_legal.value);
          if ("found"==fnd.substr(0,5)) {
            if (window.confirm("Another customer with the same identifier already exists "+document.forms[0].id_legal.value+" Would you like to reuse the current customer information for a new order?"))
              document.location = "order_edit.jsp?id_domain=<%=id_domain%>&gu_workarea=<%=gu_workarea%>&gu_company="+fnd.split(" ")[1];
          }				  
				}
      }

      // ------------------------------------------------------

      function validate() {
        var txt;
        var tpc;
        var frm = window.document.forms[0];

        if (null==getCheckedValue(frm.tp_client)) {

          alert ("A customer type (Company or Individual) must be selected");
          return false;

        } else {
          
          if (frm.sel_package.options.selectedIndex<0) {
            alert ("It is required to specify which is the requested product");
            frm.sel_package.focus();
            return false;
          }

          if (frm.de_order.length==0) {
            alert ("Order description is required");
            frm.de_order.focus();
            return false;
          }

          tpc = Number(getCheckedValue(frm.tp_client));
          
          if (90==tpc) {
            if (frm.tx_name.value.length==0) {
              alert ("The name is requiered");
              frm.tx_name.focus();
              return false;
            }
            if (frm.tx_surname.value.length==0) {
              alert ("Surname is required");
              frm.tx_surname.focus();
              return false;
            }
            
            frm.contact_person.value = frm.tx_name.value+" "+frm.tx_surname.value;
            
            if (frm.sn_passport.value.length==0) {
              alert ("The Legal Id. is required");
              frm.sn_passport.focus();
              return false;
            }
            
            frm.de_order.value = getComboText(frm.sel_packages)+" "+frm.tx_name.value+" "+frm.tx_surname.value+" ("+frm.sn_passport.value+")";

          } else {
            if (frm.nm_legal.value.length==0) {
              alert ("Corporate Name is required");
              frm.nm_legal.focus();
              return false;
            }
            if (frm.id_legal.value.length==0) {
              alert ("The company legal identifier is required");
              frm.id_legal.focus();
              return false;
            }
            
            frm.de_order.value = getComboText(frm.sel_packages)+" "+frm.nm_legal.value+" ("+frm.id_legal.value+")";
          }

				  if (frm.de_order.value.length>100) frm.de_order.value = frm.de_order.value.substr(0,100);

					for (var a=1; a<=2; a++) {
						var s = "a"+String(a)+"_";
						
            if (frm.elements[s+"sel_street"].options.selectedIndex>0)
	  				  frm.elements[s+"tp_street"].value = getCombo(frm.elements[s+"sel_street"]);
						else
	  			    frm.elements[s+"tp_street"].value = "";
	  
            if (frm.elements[s+"sel_country"].options.selectedIndex>0) {
	            frm.elements[s+"id_country"].value = getCombo(frm.elements[s+"sel_country"]);
	            frm.elements[s+"nm_country"].value = getComboText(frm.elements[s+"sel_country"]);
	          } else {
	            frm.elements[s+"id_country"].value = "";
	            frm.elements[s+"nm_country"].value = "";
	          }

            if (frm.elements[s+"sel_state"].options.selectedIndex>0) {
	            frm.elements[s+"id_state"].value = getCombo(frm.elements[s+"sel_state"]);
	            frm.elements[s+"nm_state"].value = getComboText(frm.elements[s+"sel_state"]);
	          } else {
	            frm.elements[s+"id_state"].value = "";
	            frm.elements[s+"nm_state"].value = "";
	          }

	          frm.elements[s+"mn_city"].value = frm.elements[s+"mn_city"].value.toUpperCase();
	
	          if (frm.elements[s+"id_country"].value=="es" && frm.elements[s+"zipcode"].value.length!=0 && frm.elements[s+"zipcode"].value.length!=5) {
	            alert("The zipcode must contain five digits");
	            frm.elements[s+"zipcode"].focus();
	            return false;
	          }
	          
						txt = ltrim(rtrim(frm.elements[s+"tx_email"].value));
						if (txt.length>0)
	            if (!check_email(txt)) {
	    			    alert ("The e-mail address is not valid");
	    			    frm.elements[s+"tx_email"].focus();
	    					return false;
              }
						frm.elements[s+"tx_email"].value = txt.toLowerCase();
					} // next (a)

          sameAddress (frm.chk_same_addr[0].checked);

          if (frm.a1_nm_state.value.length==0) {
            alert ("The delivery state is required");
            frm.a1_sel_state.focus();
            return false;
          }

          if (frm.a2_nm_state.value.length==0) {
            alert ("Invoincing state is required");
            frm.a2_sel_state.focus();
            return false;
          }

					if (frm.sel_packages.options.selectedIndex<=0) {
	    	    alert ("It is required to specify which is the requested product");
	    			frm.frm.sel_packages.focus();
	    		  return false;
					}
					
					frm.gu_shop.value = getCombo(frm.sel_packages).split(":")[0];
					frm.gu_product.value = getCombo(frm.sel_packages).split(":")[1];

        } // fi

        return true;
      } // validate;
    //-->
  </SCRIPT>
  <SCRIPT LANGUAGE="JavaScript1.2" TYPE="text/javascript">
    <!--
      function setCombos() {
        var frm = document.forms[0];
        
        if (getCheckedValue(frm.tp_client)=="91") {          
          document.getElementById("company_data").style.display = "block";
          document.getElementById("contact_data").style.display = "none";
        } else if (getCheckedValue(frm.tp_client)=="90") {
          document.getElementById("company_data").style.display = "none";
          document.getElementById("contact_data").style.display = "block";
        }

        setCombo (frm.a1_sel_country, getUserLanguage());
        setCombo (frm.a2_sel_country, getUserLanguage());

        if (frm.a1_sel_country.options.selectedIndex>0) {
	        frm.a1_id_country.value = getCombo(frm.a1_sel_country);
	        frm.a1_nm_country.value = getComboText(frm.a1_sel_country);
        }

        if (frm.a2_sel_country.options.selectedIndex>0) {
	        frm.a2_id_country.value = getCombo(frm.a2_sel_country);
	        frm.a2_nm_country.value = getComboText(frm.a2_sel_country);
        }
              
        loadStates1();

      } // setCombos
    //-->
  </SCRIPT> 
</HEAD>
<BODY  TOPMARGIN="8" MARGINHEIGHT="8" onLoad="setCombos()">
  <TABLE WIDTH="100%">
    <TR><TD><IMG SRC="../images/images/spacer.gif" HEIGHT="4" WIDTH="1" BORDER="0"></TD></TR>
    <TR><TD CLASS="striptitle"><FONT CLASS="title1">Order for new customer</FONT></TD></TR>
  </TABLE>  
  <FORM METHOD="post" ACTION="order_for_new_client_store.jsp" onSubmit="return validate()">
    <INPUT TYPE="hidden" NAME="id_domain" VALUE="<%=id_domain%>">
    <INPUT TYPE="hidden" NAME="gu_workarea" VALUE="<%=gu_workarea%>">
    <INPUT TYPE="hidden" NAME="gu_shop">
    <INPUT TYPE="hidden" NAME="gu_product">
    <INPUT TYPE="hidden" NAME="de_order">

    <TABLE SUMMARY="Form Background Border" CLASS="formback">
      <TR><TD>
        <TABLE SUMMARY="Form Front Color" WIDTH="100%" CLASS="formfront">
          <TR>
					  <TD WIDTH="640" ALIGN="left">
					    <TABLE SUMMARY="Company or Contact" WIDTH="100%">
                  <TR>
                    <TD ALIGN="right" WIDTH="180" CLASS="formback"><FONT CLASS="formplain">identification</FONT>
                    </TD>
                    <TD CLASS="formback"></TD>
                  </TR>
                </TR>
                  <TD ALIGN="right" WIDTH="180"><INPUT TYPE="radio" NAME="tp_client" VALUE="91" onclick="document.getElementById('company_data').style.display='block'; document.getElementById('contact_data').style.display='none';"></TD>
                  <TD ALIGN="left" CLASS="formstrong">The customer is a company</TD>
                </TR>
                <TR>
                  <TD ALIGN="right" WIDTH="180"><INPUT TYPE="radio" NAME="tp_client" VALUE="90" onclick="document.getElementById('company_data').style.display='none'; document.getElementById('contact_data').style.display='block';"></TD>
                  <TD ALIGN="left" CLASS="formstrong">The customer is an individual</TD>
                </TR>
              </TABLE>
				 	  </TD>
          <TR>
          	<TD WIDTH="640" ALIGN="left">
          	  <DIV id="company_data" STYLE="display:none">
							  <TABLE SUMMARY="Company Data" ALIGN="left">
							    <TR>
							      <TD ALIGN="right" WIDTH="180" CLASS="formstrong">Corporate Name</TD>
							      <TD ALIGN="left"><INPUT TYPE="text" NAME="nm_legal" MAXLENGTH="70" SIZE="50"></TD>
							    </TR>
							    <TR>
							      <TD ALIGN="right" WIDTH="180" CLASS="formstrong">Legal Id.</TD>
							      <TD ALIGN="left"><INPUT TYPE="text" NAME="id_legal" MAXLENGTH="16" SIZE="16" onChange="lookupLegalId()"></TD>
							    </TR>
							    <TR>
							      <TD ALIGN="right" WIDTH="180" CLASS="formplain">Contact Person</TD>
							      <TD ALIGN="left"><INPUT TYPE="text" NAME="contact_person" MAXLENGTH="100" SIZE="50"></TD>
							    </TR>
							  </TABLE>
          	  </DIV>
          	  <DIV id="contact_data" STYLE="display:none">
							  <TABLE SUMMARY="Contact Data">
							    <TR>
							      <TD ALIGN="right" WIDTH="180" CLASS="formstrong">Name</TD>
							      <TD ALIGN="left"><INPUT TYPE="text" NAME="tx_name" MAXLENGTH="49" SIZE="50"></TD>
							    </TR>
							    <TR>
							      <TD ALIGN="right" WIDTH="180" CLASS="formstrong">Surname</TD>
							      <TD ALIGN="left"><INPUT TYPE="text" NAME="tx_surname" MAXLENGTH="50" SIZE="50"></TD>
							    </TR>
							    <TR>
							      <TD ALIGN="right" WIDTH="180" CLASS="formstrong">Legal Id.</TD>
							      <TD ALIGN="left"><INPUT TYPE="text" NAME="sn_passport" MAXLENGTH="16" SIZE="16" onChange="lookupPassport()"></TD>
							    </TR>
							    <TR>
							      <TD ALIGN="right" WIDTH="180" CLASS="formplain">Company</TD>
							      <TD ALIGN="left">
                      <INPUT TYPE="hidden" NAME="gu_company">
                      <INPUT TYPE="text" SIZE="50" NAME="nm_company" MAXLENGTH="70">
                      &nbsp;&nbsp;<A HREF="javascript:reference(1)" TITLE="View list of companies"><IMG SRC="../images/images/find16.gif" HEIGHT="16" BORDER="0" ALT="Show"></A>
                      &nbsp;&nbsp;<A HREF="#" onclick="document.forms[0].gu_company.value=document.forms[0].nm_company.value=''" TITLE="Remove from Company"><IMG SRC="../images/images/delete.gif" WIDTH="13" HEIGHT="13" BORDER="0" ALT="Delete"></A>
							      </TD>
							    </TR>
							  </TABLE>
          	  </DIV>            
            </TD>
          </TR>
          <TR>
          	<TD WIDTH="640">
          	  <DIV id="delivery_data" STYLE="display:block">
							  <TABLE SUMMARY="Delivery Data" WIDTH="100%">
                  <TR>
                    <TD ALIGN="right" WIDTH="180" CLASS="formback"><FONT CLASS="formplain">Contact Data</FONT>
                    </TD>
                    <TD CLASS="formback"><FONT CLASS="formplain">Delivery Address</FONT></TD>
                  </TR>
<% if (sLanguage.equalsIgnoreCase("es")) { %>
                  <TR>
                    <TD ALIGN="right" WIDTH="180">
                      <A HREF="javascript:lookup(1)"><IMG SRC="../images/images/find16.gif" HEIGHT="16" BORDER="0" ALT="View street types"></A>&nbsp;
                      <SELECT CLASS="combomini" NAME="a1_sel_street"><OPTION VALUE=""></OPTION><%=sStreetLookUp%></SELECT>
                    </TD>
                    <TD ALIGN="left">
                      <INPUT TYPE="hidden" NAME="a1_tp_street">
                      <INPUT TYPE="text" NAME="a1_nm_street" MAXLENGTH="100" SIZE="40">
                      &nbsp;&nbsp;
                      <FONT CLASS="formplain">Number</FONT>&nbsp;<INPUT TYPE="text" NAME="a1_nu_street" MAXLENGTH="16" SIZE="4">
                    </TD>
                  </TR>
<% } else { %>
                  <TR>
                    <TD ALIGN="right" WIDTH="180">
        	            <FONT CLASS="formplain">Number</FONT>&nbsp;
                    </TD>
                    <TD ALIGN="left">
                      <INPUT TYPE="text" NAME="a1_nu_street" MAXLENGTH="16" SIZE="4">
                      <INPUT TYPE="text" NAME="a1_nm_street" MAXLENGTH="100" SIZE="40">
                      <INPUT TYPE="hidden" NAME="a1_tp_street">
                      <SELECT CLASS="combomini" NAME="a1_sel_street"><OPTION VALUE=""></OPTION><%=sStreetLookUp%></SELECT>
                      <A HREF="javascript:lookup(1)"><IMG SRC="../images/images/find16.gif" HEIGHT="16" BORDER="0" ALT="View street types"></A>
                    </TD>
                  </TR>
<% } %>
                  <TR>
                    <TD ALIGN="right" WIDTH="180"><FONT CLASS="formplain">Flat:</FONT></TD>
                    <TD ALIGN="left">
                      <INPUT TYPE="text" NAME="a1_tx_addr1" MAXLENGTH="100" SIZE="10">
                      &nbsp;&nbsp;
                      <FONT CLASS="formplain">Rest:</FONT>&nbsp;
                      <INPUT TYPE="text" NAME="a1_tx_addr2" MAXLENGTH="100" SIZE="32">
                    </TD>
                  </TR>
                  <TR>
                    <TD ALIGN="right" WIDTH="180"><FONT CLASS="formplain">Country:</FONT></TD>
                    <TD ALIGN="left">
        	            <SELECT CLASS="combomini" NAME="a1_sel_country" onchange="loadStates1()"><OPTION VALUE=""></OPTION><%=sCountriesLookUp%></SELECT>
                      <INPUT TYPE="hidden" NAME="a1_id_country">
                      <INPUT TYPE="hidden" NAME="a1_nm_country">
                    </TD>
                  </TR>
                  <TR>
                    <TD ALIGN="right" WIDTH="180"><FONT CLASS="formplain">State</FONT></TD>
                    <TD ALIGN="left">
                      <A HREF="javascript:lookup(3)"><IMG SRC="../images/images/find16.gif" HEIGHT="16" BORDER="0" ALT="View states"></A>&nbsp;<SELECT CLASS="combomini" NAME="a1_sel_state"></SELECT>
                      <INPUT TYPE="hidden" NAME="a1_id_state" MAXLENGTH="16">
                      <INPUT TYPE="hidden" NAME="a1_nm_state" MAXLENGTH="30">
                    </TD>
                  </TR>
                  <TR>
                    <TD ALIGN="right" WIDTH="180"><FONT CLASS="formplain">City</FONT></TD>
                    <TD ALIGN="left">
                      <INPUT TYPE="text" NAME="a1_mn_city" STYLE="text-transform:uppercase" MAXLENGTH="50" SIZE="30">
                      &nbsp;&nbsp;
                      <FONT CLASS="formplain">Zipcode:</FONT>
                      &nbsp;
                      <INPUT TYPE="text" NAME="a1_zipcode" MAXLENGTH="30" SIZE="5">
                    </TD>
                  </TR>
                  <TR>
                    <TD ALIGN="right" WIDTH="180" CLASS="formplain">Fixed Phone</TD>
                    <TD ALIGN="left" CLASS="formplain"><INPUT TYPE="text" NAME="a1_fixed_phone" MAXLENGTH="16" SIZE="10">
                      &nbsp;&nbsp;&nbsp;Mobile&nbsp;<INPUT TYPE="text" NAME="a1_mobile_phone" MAXLENGTH="16" SIZE="10">
                      &nbsp;&nbsp;&nbsp;Fax&nbsp;<INPUT TYPE="text" NAME="a1_fax_phone" MAXLENGTH="16" SIZE="10">
                    </TD>
                  </TR>
                  <TR>
                    <TD ALIGN="right" WIDTH="180"><FONT CLASS="formplain">e-mail:</FONT></TD>
                    <TD ALIGN="left" ><INPUT TYPE="text" NAME="a1_tx_email" STYLE="text-transform:lowercase" MAXLENGTH="100" SIZE="42" ></TD>
                  </TR>
                  <TR>
                    <TD ALIGN="right" WIDTH="180"><INPUT TYPE="radio" NAME="chk_same_addr" VALUE="true" onclick="sameAddress(true)" CHECKED></TD>
                    <TD ALIGN="left" CLASS="formplain">Invoicing address is the same as delivery address</TD>
                  </TR>
                  <TR>
                    <TD ALIGN="right" WIDTH="180"><INPUT TYPE="radio" NAME="chk_same_addr" VALUE="false" onclick="sameAddress(false)"></TD>
                    <TD ALIGN="left" CLASS="formplain">Invoing address is different from delivery address</TD>
                  </TR>
								</TABLE>
              </DIV>
            </TD>
          </TR>
          <TR>
          	<TD WIDTH="640">
          	  <DIV id="invoicing_data" STYLE="display:none">
							  <TABLE SUMMARY="Invoicing Data" WIDTH="100%">
                  <TR>
                    <TD ALIGN="right" WIDTH="180" CLASS="formplain"></TD>
                    <TD CLASS="formback"><FONT CLASS="formplain">Invoicing Address</FONT></TD>
                  </TR>
<% if (sLanguage.equalsIgnoreCase("es")) { %>
                  <TR>
                    <TD ALIGN="right" WIDTH="180">
                      <A HREF="javascript:lookup(2)"><IMG SRC="../images/images/find16.gif" HEIGHT="16" BORDER="0" ALT="View street types"></A>&nbsp;
                      <SELECT CLASS="combomini" NAME="a2_sel_street"><OPTION VALUE=""></OPTION><%=sStreetLookUp%></SELECT>
                    </TD>
                    <TD ALIGN="left">
                      <INPUT TYPE="hidden" NAME="a2_tp_street">
                      <INPUT TYPE="text" NAME="a2_nm_street" MAXLENGTH="100" SIZE="40">
                      &nbsp;&nbsp;
                      <FONT CLASS="formplain">Number</FONT>&nbsp;<INPUT TYPE="text" NAME="a2_nu_street" MAXLENGTH="16" SIZE="4">
                    </TD>
                  </TR>
<% } else { %>
                  <TR>
                    <TD ALIGN="right" WIDTH="180">
        	            <FONT CLASS="formplain">Number</FONT>&nbsp;
                    </TD>
                    <TD ALIGN="left">
                      <INPUT TYPE="text" NAME="a2_nu_street" MAXLENGTH="16" SIZE="4">
                      <INPUT TYPE="text" NAME="a2_nm_street" MAXLENGTH="100" SIZE="40">
                      <INPUT TYPE="hidden" NAME="a2_tp_street">
                      <SELECT CLASS="combomini" NAME="a2_sel_street"><OPTION VALUE=""></OPTION><%=sStreetLookUp%></SELECT>
                      <A HREF="javascript:lookup(2)"><IMG SRC="../images/images/find16.gif" HEIGHT="16" BORDER="0" ALT="View street types"></A>
                    </TD>
                  </TR>
<% } %>
                  <TR>
                    <TD ALIGN="right" WIDTH="180"><FONT CLASS="formplain">Flat:</FONT></TD>
                    <TD ALIGN="left">
                      <INPUT TYPE="text" NAME="a2_tx_addr1" MAXLENGTH="100" SIZE="10">
                      &nbsp;&nbsp;
                      <FONT CLASS="formplain">Rest:</FONT>&nbsp;
                      <INPUT TYPE="text" NAME="a2_tx_addr2" MAXLENGTH="100" SIZE="32">
                    </TD>
                  </TR>
                  <TR>
                    <TD ALIGN="right" WIDTH="180"><FONT CLASS="formplain">Country:</FONT></TD>
                    <TD ALIGN="left">
        	            <SELECT CLASS="combomini" NAME="a2_sel_country" onchange="loadStates2()"><OPTION VALUE=""></OPTION><%=sCountriesLookUp%></SELECT>
                      <INPUT TYPE="hidden" NAME="a2_id_country">
                      <INPUT TYPE="hidden" NAME="a2_nm_country">
                    </TD>
                  </TR>
                  <TR>
                    <TD ALIGN="right" WIDTH="180"><FONT CLASS="formplain">State</FONT></TD>
                    <TD ALIGN="left">
                      <A HREF="javascript:lookup(4)"><IMG SRC="../images/images/find16.gif" HEIGHT="16" BORDER="0" ALT="View states"></A>&nbsp;<SELECT CLASS="combomini" NAME="a2_sel_state"></SELECT>
                      <INPUT TYPE="hidden" NAME="a2_id_state" MAXLENGTH="16">
                      <INPUT TYPE="hidden" NAME="a2_nm_state" MAXLENGTH="30">
                    </TD>
                  </TR>
                  <TR>
                    <TD ALIGN="right" WIDTH="180"><FONT CLASS="formplain">City</FONT></TD>
                    <TD ALIGN="left">
                      <INPUT TYPE="text" NAME="a2_mn_city" STYLE="text-transform:uppercase" MAXLENGTH="50" SIZE="30">
                      &nbsp;&nbsp;
                      <FONT CLASS="formplain">Zipcode:</FONT>
                      &nbsp;
                      <INPUT TYPE="text" NAME="a2_zipcode" MAXLENGTH="30" SIZE="5">
                    </TD>
                  </TR>
                  <TR>
                    <TD ALIGN="right" WIDTH="180" CLASS="formplain">Fixed Phone</TD>
                    <TD ALIGN="left" CLASS="formplain"><INPUT TYPE="text" NAME="a2_fixed_phone" MAXLENGTH="16" SIZE="10">
                      &nbsp;&nbsp;&nbsp;Mobile&nbsp;<INPUT TYPE="text" NAME="a2_mobile_phone" MAXLENGTH="16" SIZE="10">
                      &nbsp;&nbsp;&nbsp;Fax&nbsp;<INPUT TYPE="text" NAME="a2_fax_phone" MAXLENGTH="16" SIZE="10">
                    </TD>
                  </TR>
                  <TR>
                    <TD ALIGN="right" WIDTH="180"><FONT CLASS="formplain">e-mail:</FONT></TD>
                    <TD ALIGN="left" ><INPUT TYPE="text" NAME="a2_tx_email" STYLE="text-transform:lowercase" MAXLENGTH="100" SIZE="42" ></TD>
                  </TR>
								</TABLE>
              </DIV>
            </TD>
          </TR>
          <TR>
					  <TD WIDTH="640" ALIGN="left">
					    <TABLE SUMMARY="Order Details" WIDTH="100%">
                <TR>
                  <TD ALIGN="right" WIDTH="180" CLASS="formback"><FONT CLASS="formplain">Order</FONT></TD>
                  <TD CLASS="formback"></TD>
                </TR>
                <TR>
                  <TD ALIGN="right" WIDTH="180" CLASS="formplain">Product:</TD>
                  <TD><SELECT NAME="sel_package"><OPTION VALUE="" SELECTED></OPTION><%=sShops%></TD>
                </TR>
              </TABLE>
            </TD>
          </TR>
          <TR>          	
    	    <TD COLSPAN="2" ALIGN="center">
              <INPUT TYPE="submit" ACCESSKEY="s" VALUE="Next" CLASS="pushbutton" STYLE="width:80" TITLE="ALT+s">&nbsp;
    	      &nbsp;&nbsp;<INPUT TYPE="button" ACCESSKEY="c" VALUE="Cancel" CLASS="closebutton" STYLE="width:80" TITLE="ALT+c" onclick="window.close()">
    	      <BR><BR>
    	    </TD>
    	  </TR>            
        </TABLE>
      </TD></TR>
    </TABLE>                 
  </FORM>
</BODY>
</HTML>

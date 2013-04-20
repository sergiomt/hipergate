<%@ page import="java.util.HashMap,java.io.File,java.io.IOException,java.net.URLDecoder,java.sql.SQLException,java.util.Date,java.util.Vector,java.text.SimpleDateFormat,org.w3c.dom.*,com.knowgate.jdc.JDCConnection,com.knowgate.acl.*,com.knowgate.dataobjs.*,com.knowgate.misc.Environment,com.knowgate.hipergate.QueryByForm,dom.*" language="java" session="false" contentType="text/html;charset=UTF-8" %>
<%@ include file="../methods/dbbind.jsp" %><%@ include file="../methods/cookies.jspf" %><%@ include file="../methods/authusrs.jspf" %><%@ include file="../methods/clientip.jspf" %><%@ include file="../methods/nullif.jspf" %><%
/*
  Copyright (C) 2003  Know Gate S.L. All rights reserved.
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

  if (request.getParameter("queryid")!=null) {
    response.addHeader ("Pragma", "no-cache");
    response.addHeader ("cache-control", "no-store");
  }

  String sLanguage = getNavigatorLanguage(request);

  if (!sLanguage.startsWith("en") && !sLanguage.startsWith("es"))
    sLanguage = "en";

  String sSkin = getCookie(request, "skin", "xp");
  String sStorage = Environment.getProfileVar(GlobalDBBind.getProfileName(), "storage");
  String gu_query = request.getParameter("queryid");
  String sCaller = nullif(request.getParameter("caller"),"");
  
  String gu_list = "";
  if (request.getParameter("queryspec").equals("listmember"))
	gu_list = request.getParameter("gu_list");
  String sQueries = "<OPTION VALUE=\"\"></OPTION>";
  DBSubset oQueries = new DBSubset("k_queries",
  				   "gu_query,tl_query,nm_field1,nm_operator1,tx_value1,vl_code1,tx_condition1,nm_field2,nm_operator2,tx_value2,vl_code2,tx_condition2,nm_field3,nm_operator3,tx_value3,vl_code3",
  				   "gu_workarea=? AND nm_queryspec=?", 50);
  Object aQueries[] = { getCookie(request, "workarea", null), request.getParameter("queryspec") };
  int iQueries = 0;
  int iCurrentQuery=-1;
  String sTlQuery = "";
  String sDateCast = "\"{ d '\" + val + \"'}\"";
  
  JDCConnection oConn = null;  
  
  boolean bIsGuest = true;
      
  try {
    bIsGuest = isDomainGuest (GlobalDBBind, request, response);
    
    oConn = GlobalDBBind.getConnection("qbf");  
    switch (oConn.getDataBaseProduct()) {
      case JDCConnection.DBMS_ORACLE:
        sDateCast = "\"TO_DATE ('\" + val + \"','YYYY-MM-DD')\"";
        break;
      case JDCConnection.DBMS_POSTGRESQL:
        sDateCast = "\"DATE '\" + val + \"'\"";
        break;
      case JDCConnection.DBMS_MYSQL:
        sDateCast = "\"CAST('\" + val + \"' AS DATE)\"";
        break;
    }
    
    iQueries = oQueries.load(oConn, aQueries);
    
    oConn.close("qbf");
  }
  catch (SQLException e) {  
    if (oConn!=null)
      if (!oConn.isClosed()) oConn.close("qbf");
    response.sendRedirect (response.encodeRedirectUrl ("errmsg.jsp?title=SQLException&desc=" + e.getLocalizedMessage() + "&resume=_close"));
    return;
  }
  oConn = null;
  
  for (int q=0;q<iQueries; q++)
    sQueries += "<OPTION VALUE=\"" + oQueries.getString(0,q) + "\">" + oQueries.getString(1,q) + "</OPTION>";

  QueryByForm oQBF = null;
  
  try {
    oQBF = new QueryByForm ("file://" + sStorage + File.separator + "qbf" + File.separator + request.getParameter("queryspec") + ".xml");
  }
  catch (Exception e) {
    response.sendRedirect (response.encodeRedirectUrl ("errmsg.jsp?title="+e.getClass().getName()+"&desc=" + e.getMessage() + " " + "file://" + sStorage + File.separator + "qbf" + File.separator + request.getParameter("queryspec") + ".xml" + "&resume=_close"));
    return;
  }
  
  String sMethod = oQBF.getMethod();
  String sAction = oQBF.getAction();
  String sTitle;
  
  if (null==request.getParameter("de_title"))
    sTitle = oQBF.getTitle(sLanguage);
  else
    sTitle = request.getParameter("de_title");
  
  Vector vFields = oQBF.getFields();  
  String sFields = "<OPTION VALUE=\"\"></OPTION>";
  DOMSubDocument oField;
  
  for (int f=0; f<vFields.size(); f++) {
    oField = (DOMSubDocument) vFields.get(f);
    sFields += "<OPTION VALUE=\"" + oField.getElement("name").trim() + "\">" + oField.getElement("label_" + sLanguage) + "</OPTION>";
  } // next (f)
%>
<HTML LANG="<%=sLanguage%>">
  <HEAD>
    <TITLE>hipergate :: <%=sTitle%></TITLE>
    <SCRIPT LANGUAGE="JavaScript1.2" TYPE="text/javascript" SRC="../javascript/defined.js"></SCRIPT>    
    <SCRIPT LANGUAGE="JavaScript1.2" TYPE="text/javascript" DEFER="defer">
      <!--

      function deleteQuery() {
        var frm = document.forms[0];
        
        if (frm.sel_queries.selectedIndex<=0) {
          alert ("Select the query to be deleted");
          return false;
        } else if (window.confirm("Are you sure that you want to delete this query? "+getComboText(frm.sel_queries) + " If the query is deleted, the list that are using it will be also deleted")) {
          frm.gu_query.value = getCombo(frm.sel_queries);
          frm.method = "POST";
          frm.action = "qbf_delete.jsp";
          frm.submit();
        }
      }

      function saveQuery() {
        var sTlQry = "<%=sTlQuery%>";
        
        if (sTlQry.length==0) {
          sTlQry = window.prompt("Enter the query short name", "<%=(sTlQuery.length()>0 ? sTlQuery : "Query"+String.valueOf(iQueries+1))%>");
        }
        
        if (defined(sTlQry))
          if (sTlQry!="") {
            document.forms[0].tl_query.value = sTlQry;
            document.forms[0].method = "POST";
            document.forms[0].action = "qbf_store.jsp";
            document.forms[0].submit();
            return true;
          }
          else
            return false;
        else
          return false;
      } // saveQuery()
      // -->
    </SCRIPT>    
    <SCRIPT TYPE="text/javascript" SRC="../javascript/cookies.js"></SCRIPT>
    <SCRIPT TYPE="text/javascript" SRC="../javascript/setskin.js"></SCRIPT>
    <SCRIPT TYPE="text/javascript" SRC="../javascript/trim.js"></SCRIPT>    
    <SCRIPT TYPE="text/javascript" SRC="../javascript/combobox.js"></SCRIPT>
    <SCRIPT TYPE="text/javascript" SRC="../javascript/layer.js"></SCRIPT>
    <SCRIPT TYPE="text/javascript" SRC="../javascript/datefuncs.js"></SCRIPT>    
    <SCRIPT TYPE="text/javascript" SRC="../javascript/usrlang.js"></SCRIPT>    
    <SCRIPT TYPE="text/javascript" SRC="../javascript/getparam.js"></SCRIPT>
    <SCRIPT TYPE="text/javascript" SRC="../javascript/simplevalidations.js"></SCRIPT>    
    <SCRIPT TYPE="text/javascript" DEFER="defer">
      <!--

      function loadQuery() {
<%      if (sCaller.startsWith("list_")) { %>
            window.location = "qbf.jsp?queryspec=" + escape(getURLParam("queryspec")) + "&queryid=<%=gu_query%><%=gu_list==null ? "" : "&gu_list="+gu_list%>";
<%      } else { %>
          if (getCombo(document.forms[0].sel_queries)!="")        
            window.location = "qbf.jsp?queryspec=" + escape(getURLParam("queryspec")) + "&queryid=" + getCombo(document.forms[0].sel_queries) + "<%=gu_list==null ? "" : "&gu_list="+gu_list%>";
<%      } %>
      } // loadQuery()

      // ------------------------------------------------------
     
      function columnVisibility () {
        if (getCombo(document.forms[0].sel_show_as)=="HTML") {
          hideLayer("columns1");
          hideLayer("columns2");
          hideLayer("columns3");
          hideLayer("columns4");
          hideLayer("columns5");
        }
        else {
          showLayer("columns1");
          showLayer("columns2");
          showLayer("columns3");
          showLayer("columns4");
          showLayer("columns5");
        } 
      } // columVisibility()

      // ------------------------------------------------------
     
      function addColumns() {
        var frm = document.forms[0];
        var opt = frm.sel_all_columns.options;
        
        for (var i=0; i<opt.length; i++) {
          if (opt[i].selected)
            if (comboIndexOf(frm.sel_show_columns, opt[i].value)<0)
	      comboPush (frm.sel_show_columns, opt[i].text, opt[i].value, false, false);
        } // next (i)
      } // addColumns()

      // ------------------------------------------------------
     
      function removeColumns() {
        var frm = document.forms[0];
        var opt = frm.sel_show_columns.options;
        
        for (var i=0; i<opt.length; i++) {
          if (opt[i].selected) {
            opt.remove(i);
            i=0;
          }
        } // next (i)
      } // removeColumns()

      // ------------------------------------------------------
      
      function validate() {
        var frm = document.forms[0];
        var opt = frm.sel_show_columns.options;
        var qry = "";
        var cmb;
        var opr;
        var val;
        var cod;
        var nan;
        var typ;
        	
	if (getCombo(frm.sel_show_as)!="HTML" && frm.sel_show_columns.options.length==0) {
            alert ("You must select at least one column to be shown");
            return false;	
	}
	
        cmb = getCombo(frm.field1);
	opr = getCombo(frm.operator1);                       
        val = frm.value1.value;
        cod = frm.code1.value;

        if (cmb.length==0 ) {
            alert ("You must specify at least one search field for the first condition");
            return false;
        }

        if (val.length==0 && opr!="M" && opr!="N") {
            alert ("You must specify at least one search field for the first condition");
            return false;
        }

	typ = getType(cmb);
                
        if ((typ=="integer" && !isIntValue(cod)) || (typ=="float" && !isFloatValue(cod))) {
          alert ("Value for field 1 is not a valid number");
          return false;
        }
                                    
        // Asignación de literales de fecha
        if (typ=="date" && !isDate(val,"d")) {
          alert ("Date of field 1 is not valid. Use format yyyy-mm-dd.");
          return false;
        }
        else if (typ=="date")
         cod = <%=sDateCast%>;
        // ***
                          
        if (val.length>0 || opr=="N" || opr=="M") {
            qry = getClause(cmb, opr, cod.length>0 ? cod : val);

	  if (frm.field2.selectedIndex<=0) {
	    frm.condition1[0].checked = false;
	    frm.condition1[1].checked = false;
	  }
	    
	  if (frm.condition1[0].checked || frm.condition1[1].checked) {
	    qry += frm.condition1[0].checked ? " AND " : " OR ";
	    
            cmb = getCombo(frm.field2);
	    opr = getCombo(frm.operator2);
            val = frm.value2.value;
            cod = frm.code2.value;
	    typ = getType(cmb);

            if ((typ=="integer" && !isIntValue(cod)) || (typ=="float" && !isFloatValue(cod))) {
              alert ("Value for field 2 is not a valid number");
              return false;
            }
              else
                frm.value2.value = cod;                        

            // Asignación de literales de fecha
            if (typ=="date" && !isDate(val,"d")) {
                alert ("Date of field 2 is not valid. Use format yyyy-mm-dd.");
                return false;
            }
            else if (typ=="date")
              cod = <%=sDateCast%>;
            // ***
            
            qry += getClause(cmb, opr, cod.length>0 ? cod : val);
	
	    if (frm.condition2[0].checked || frm.condition2[1].checked) {
	      qry += frm.condition2[0].checked ? " AND " : " OR ";

              cmb = getCombo(frm.field3);
	      opr = getCombo(frm.operator3);	
              val = frm.value3.value;
              cod = frm.code3.value;
	      typ = getType(cmb);

              if ((typ=="integer" && !isIntValue(cod)) || (typ=="float" && !isFloatValue(cod))) {
                alert ("Value for field 3 is not a valid number");
                return false;
              }
              else
                frm.value3.value = cod;
                  
              // Asignación de literales de fecha
              if (typ=="date" && !isDate(val,"d")) {
                alert ("Date of field 3is not valid. Use format yyyy-mm-dd.");
                return false;
              }
              else if (typ=="date")
                cod = <%=sDateCast%>;
              // ***

              qry += getClause(cmb, opr, cod.length>0 ? cod : val);
	    }
	  }
	}
	
	frm.where.value = " AND (" + qry + ")";
	
	frm.columnlist.value = "";	        
        for (var c=0; c<opt.length; c++) {
	  frm.columnlist.value += opt[c].value;
	  if (c<opt.length-1) frm.columnlist.value += ",";
	}

	frm.orderby.value = getCombo(frm.sel_orderby);
	frm.showas.value = getCombo(frm.sel_show_as);
	
	if (getCombo(frm.sel_show_as)=="HTML") {
	  frm.action = "<%=sAction%>";
	  frm.method = "<%=sMethod%>";
	}
	else {
	  frm.action = "../servlet/HttpQueryServlet";
	  frm.method = "GET";
	}
	
	if ("GET"==frm.method) {
	  frm.value1.value = escape(frm.value1.value);
	  frm.value2.value = escape(frm.value2.value);
	  frm.value3.value = escape(frm.value3.value);
	}
	
        return true;
      } // validate()
      
      //-->
    </SCRIPT>

    <SCRIPT LANGUAGE="JavaScript1.2" TYPE="text/javascript">
      <!--
      var members = 0;
<%   
      if (request.getParameter("queryspec").equals("listmember")) {
	gu_list = request.getParameter("gu_list");
	if (nullif(request.getParameter("tp_memberselection"),"").equals("table"))
	  out.write ("members = 1;\n");
      } // fi (getParameter("queryspec")=="listmember")
%>

      // ------------------------------------------------------
	
      function getType(fld) {
	var type;
	
	if (fld.length>0)
	  eval ("type = document.forms[0]." + fld + ".value"); 
	else
	  type = "";
	        
        return type;
      } // getType()
      
      // ------------------------------------------------------

      function filterOperators(odctrl) {
        var operators = new Array("=","<>",">","<","S","C","N","M");
        var names_es = new Array("Igual a","Distinto de","Mayor que","Menor que","Empieza por","Contiene","Es Nulo","Es No Nulo");
        var names_en = new Array("Equal to","Not Equal to","Greater than","Less than","Starts with","Contains","Is Null","Is Not Null");

	var frm = document.forms[0];
	var fld;
	var opr;
	var type;
	var nOpers;
	
	switch (odctrl) {
	  case 1:
	    fld = getCombo(frm.field1);
	    opr = frm.operator1;
	    break;
	  case 2:
	    fld = getCombo(frm.field2);
	    opr = frm.operator2;
	    break;
	  case 3:
	    fld = getCombo(frm.field3);	  
	    opr = frm.operator3;
	    break;
	}
	
	type = getType(fld);
			
	if (type=="varchar" || type=="lookup")
	  nOpers = 8;
	else if (type=="integer" || type=="float" || type=="date")
	  nOpers = 4;

	clearCombo(opr);
	
	if ("es"==getUserLanguage()) {
	  for (var i=0; i<nOpers; i++)
	    comboPush (opr, names_es[i], operators[i], false, false);
        } else {
	  for (var i=0; i<nOpers; i++)
	    comboPush (opr, names_en[i], operators[i], false, false);        
	} // fi (getUserLanguage())
      } // filterOperators()
      
            
      // ------------------------------------------------------

      function showLookUp(odctrl) {
        var frm = document.forms[0];
        var fld;
        var type;
        
        filterOperators(odctrl);
        
	switch (odctrl) {
	  case 1:
	    fld = getCombo(frm.field1);
	    break;
	  case 2:
	    if (frm.field2.options.selectedIndex<0) 
	      frm.condition1[0].checked = frm.condition1[1].checked = false;	      
	    fld = getCombo(frm.field2);
	    break;
	  case 3:
	    if (frm.field3.options.selectedIndex<0) 
	      frm.condition2[0].checked = frm.condition2[1].checked = false;
	    fld = getCombo(frm.field3);
	    break;
        }

	type = getType(fld);
	        
        if (type=="lookup" || type=="date")
          showLayer("lookup" + odctrl);
        else
          hideLayer("lookup" + odctrl);
                  
        return true;
      } // showLookUp()

      // ------------------------------------------------------

      function getClause(fld,opr,vle) {
        var ret;
        var type;
        
	type = getType(fld);
        
        if (type=="varchar" || type=="lookup") {
          if (opr=="S")
            ret = "b." + fld + " <%=DBBind.Functions.ILIKE%> '" + vle + "%' ";
          else if (opr=="C")
            ret = "b." + fld + " <%=DBBind.Functions.ILIKE%> '%" + vle + "%' ";
          else if (opr=="N")
            ret = "b." + fld + " IS NULL ";
          else if (opr=="M")
            ret = "b." + fld + " IS NOT NULL ";
          else
            ret = "b." + fld + " " + opr + " '" + vle + "' ";
        }
        else if (type=="integer" || type=="float" || type=="date" ) {
          ret = "b." + fld + opr + vle + " ";
        }
        return ret;
      } // getClause()

      // ------------------------------------------------------
      
      function lookup(odctrl) {
        var frm = document.forms[0];
        var sect;
        var ctrl;
        var code;
        var type;
        var dtnw = new Date();
        
        switch (parseInt(odctrl)) {
          case 1:
            sect = getCombo(frm.field1);
            ctrl = "value1";
            code = "code1";
            break;
          case 2:
            sect = getCombo(frm.field2);
            ctrl = "value2";
            code = "code2";
            break;
          case 3:
            sect = getCombo(frm.field3);
            ctrl = "value3";
            code = "code3";
            break;            
        }

	type = getType(sect);
	  
        if (type=="date")
          window.open("calendar.jsp?a=" + (dtnw.getFullYear()) + "&m=" + dtnw.getMonth() + "&c=" + ctrl, "", "toolbar=no,directories=no,menubar=no,resizable=no,width=171,height=195");
<%
        for (int l=0; l<vFields.size(); l++) {
          oField = (DOMSubDocument) vFields.get(l);
	  if (oField.getElement("type").trim().equalsIgnoreCase("lookup")) {
	    if (null==oField.getElement("form"))
	      throw new NullPointerException("Cannot find <form> tag for lookup element"); 
	    else {
	      out.write ("	else if (sect==\"" + oField.getElement("name").trim() + "\")\n");
	      out.write ("          window.open('" + oField.getElement("form").trim() + "&id_language=' + getUserLanguage() + '&id_section=' + rtrim(sect) + ' &tp_control=1&nm_control=' + ctrl + '&nm_coding=' + code, '', 'toolbar=no,directories=no,menubar=no,resizable=no,width=460,height=440');\n");
	    }
          }
        } // next (l)
%>
      } // lookup()

      // ------------------------------------------------------
                  
	function setCombos() {
	  var frm = document.forms[0];
<%
	  if (gu_query!=null) {
      if (sCaller.startsWith("list_"))
	      out.write("          loadQuery();\n");
	    else
	      out.write("          setCombo(frm.sel_queries, \"" + gu_query + "\");\n");

	    iCurrentQuery = oQueries.find(0,gu_query);
	    sTlQuery = oQueries.getString(1, iCurrentQuery);
%>
	    // **********************************************
	    // Asignación de valor y operador para el campo 1

	    setCombo(frm.field1, "<%=oQueries.getStringNull("nm_field1",iCurrentQuery,"")%>");
	    frm.value1.value="<%=oQueries.getStringNull("tx_value1",iCurrentQuery,"")%>";
	    frm.code1.value="<%=oQueries.getStringNull("vl_code1",iCurrentQuery,"")%>";
	    filterOperators(1);
	    setCombo(frm.operator1, "<%=oQueries.getStringNull("nm_operator1",iCurrentQuery,"")%>");

<%	    if (oQueries.getStringNull("tx_condition1",iCurrentQuery,"").equals("AND"))
	      out.write("          frm.condition1[0].checked=true;\n");
	    else if (oQueries.getStringNull("tx_condition1",iCurrentQuery,"").equals("OR"))
	      out.write("          frm.condition1[1].checked=true;\n");
%>	    
	    // **********************************************
	    // Asignación de valor y operador para el campo 2

	    setCombo(frm.field2, "<%=oQueries.getStringNull("nm_field2",iCurrentQuery,"")%>");
	    frm.value2.value="<%=oQueries.getStringNull("tx_value2",iCurrentQuery,"")%>";
	    frm.code2.value="<%=oQueries.getStringNull("vl_code2",iCurrentQuery,"")%>";
	    filterOperators(2);
	    setCombo(frm.operator2, "<%=oQueries.getStringNull("nm_operator2",iCurrentQuery,"")%>");

<%	    if (oQueries.getStringNull("tx_condition2",iCurrentQuery,"").equals("AND"))
	      out.write("          frm.condition2[0].checked=true;\n");
	    else if (oQueries.getStringNull("tx_condition2",iCurrentQuery,"").equals("OR"))
	      out.write("          frm.condition2[2].checked=true;\n");
%>
	    // **********************************************
	    // Asignación de valor y operador para el campo 3

	    setCombo(frm.field3, "<%=oQueries.getStringNull("nm_field3",iCurrentQuery,"")%>");
	    frm.value3.value="<%=oQueries.getStringNull("tx_value3",iCurrentQuery,"")%>";
	    frm.code3.value="<%=oQueries.getStringNull("vl_code3",iCurrentQuery,"")%>";
	    filterOperators(3);
	    setCombo(frm.operator3, "<%=oQueries.getStringNull("nm_operator3",iCurrentQuery,"")%>");
<%
	  } // fi(gu_query)
%>
/*
	  if (getURLParam("queryspec")!="listmember")
	    showLayer("showresultsas");
*/

	  if (members == 1) document.forms[0].submit();
	} // setCombos()
      //-->
    </SCRIPT>
  </HEAD>
  <BODY  TOPMARGIN="0" MARGINHEIGHT="0" onload="setCombos();">
  <% 
    if (!sCaller.startsWith("list_"))
    {
%>    
<%@ include file="../common/header.jspf" %>
<%  } else { %>
    <IMG SRC="../skins/<% out.write(sSkin); %>/hglogopeq.jpg" BORDER="0">
<%
    }
%>
    <TABLE WIDTH="100%" ><TR><TD CLASS="striptitle"><FONT CLASS="title1"><%=sTitle%></FONT></TD></TR></TABLE>
    <CENTER>
    <FORM onSubmit="return validate();">
      <INPUT TYPE="hidden" NAME="gu_query" VALUE="<%=nullif(gu_query)%>">
      <INPUT TYPE="hidden" NAME="tl_query" VALUE="<%=sTlQuery%>">
      <INPUT TYPE="hidden" NAME="queryspec" VALUE="<%=request.getParameter("queryspec")%>">
      <INPUT TYPE="hidden" NAME="gu_list" VALUE="<%=gu_list%>">
<% 
    if (!sCaller.startsWith("list_"))
    {
%>    
      <FONT CLASS="textplain">&nbsp;Load predefined Query&nbsp;</FONT>
      <SELECT NAME="sel_queries" CLASS="combomini" onchange="loadQuery()"><%=sQueries%></SELECT>
      &nbsp;
      <A HREF="#" onclick="deleteQuery()" TITLE="Delete Query"><IMG SRC="../images/images/delete.gif" WIDTH="13" HEIGHT="13" BORDER="0" ALT="Delete"></A>
      <A HREF="#" onclick="deleteQuery()" TITLE="Delete Query" CLASS="linkplain">Delete</A>
      <BR><BR>
<% } %>
      <FONT CLASS="textplain">&nbsp;cuyo</FONT><BR>
      <INPUT TYPE="hidden" NAME="columnlist" VALUE="">
      <INPUT TYPE="hidden" NAME="where" VALUE="">
      <INPUT TYPE="hidden" NAME="orderby" VALUE="">
      <INPUT TYPE="hidden" NAME="showas" VALUE="">      
      <INPUT TYPE="hidden" NAME="caller" VALUE="<%=sCaller%>">
<%
      HashMap oFieldNames = new HashMap(vFields.size()*2);
      String sFieldName;    
      for (int i=0; i<vFields.size(); i++) {
        oField = (DOMSubDocument) vFields.get(i);
        sFieldName = oField.getElement("name").trim();
        if (!oFieldNames.containsKey(sFieldName)) {
          out.write ("      <INPUT TYPE=\"hidden\" NAME=\"" + sFieldName + "\" VALUE=\"" + oField.getElement("type") + "\">\n");
          oFieldNames.put (sFieldName,sFieldName);
        }
      } // next (f)
%>
      <TABLE BORDER="0" CLASS="formfront">
        <TR>
          <TD CLASS="strip1">
            <SELECT NAME="field1" CLASS="combomini" onClick="showLookUp(1)"><%=sFields%></SELECT>
          </TD>
          <TD CLASS="strip1" ALIGN="center">
      	    <FONT CLASS="textplain">&nbsp;is&nbsp;</FONT>
            <SELECT NAME="operator1" CLASS="combomini" STYLE="width:100"></SELECT>
          </TD>
          <TD CLASS="strip1">
            <INPUT TYPE="hidden" NAME="code1">
            <DIV ID="val1txt" STYLE="position:relative;visibility:visible"><INPUT TYPE="text" NAME="value1" CLASS="textmini" MAXLENGTH="250" SIZE="30" onChange="document.forms[0].code1.value=''"></DIV>
          </TD>
          <TD CLASS="formfront">
            <DIV ID="lookup1" STYLE="position:relative;visibility:hidden"><A HREF="javascript:lookup(1)"><IMG SRC="../images/images/find16.gif" HEIGHT="16" BORDER="0" ALT="View list of values"></A></DIV>           
          </TD>
        </TR>
        <TR>
          <TD COLSPAN="3" CLASS="strip2">
            <INPUT TYPE="radio" NAME="condition1" VALUE="AND">&nbsp;<FONT CLASS="formstrong">And</FONT>&nbsp;&nbsp;&nbsp;&nbsp;<INPUT TYPE="radio" NAME="condition1" VALUE="OR">&nbsp;<FONT CLASS="formstrong">Or</FONT>
          </TD>
          <TD CLASS="formfront"></TD>
        </TR>
        <TR>
          <TD CLASS="strip1">
            <SELECT NAME="field2" CLASS="combomini" onClick="showLookUp(2)"><%=sFields%></SELECT>
          </TD>
          <TD CLASS="strip1">    
      	    <FONT CLASS="textplain">&nbsp;is&nbsp;</FONT>
            <SELECT NAME="operator2" CLASS="combomini" STYLE="width:100"></SELECT>
          </TD>
          <TD CLASS="strip1">
            <INPUT TYPE="hidden" NAME="code2">
            <DIV ID="val2txt" STYLE="position:relative;visibility:visible"><INPUT TYPE="text" NAME="value2" CLASS="textmini" MAXLENGTH="250" SIZE="30" onChange="document.forms[0].code2.value=''"></DIV>
          </TD>
          <TD VALIGN="middle" CLASS="formfront">
            <DIV ID="lookup2" STYLE="position:relative;visibility:hidden"><A HREF="javascript:lookup(2)"><IMG SRC="../images/images/find16.gif" HEIGHT="16" BORDER="0" ALT="View list of values"></A></DIV>
          </TD>
        </TR>
        <TR>
          <TD COLSPAN="3" CLASS="formfront" HEIGHT="16">          
            <INPUT TYPE="radio" NAME="condition2" VALUE="AND">&nbsp;<FONT CLASS="formstrong">And</FONT>&nbsp;&nbsp;&nbsp;&nbsp;<INPUT TYPE="radio" NAME="condition2" VALUE="OR">&nbsp;<FONT CLASS="formstrong">Or</FONT>
          </TD>
          <TD CLASS="formfront"></TD>
        </TR>
        <TR>
          <TD CLASS="strip1">
            <SELECT NAME="field3" CLASS="combomini" onClick="showLookUp(3)"><%=sFields%></SELECT>
          </TD>
          <TD CLASS="strip1">          
      	    <FONT CLASS="textplain">&nbsp;is&nbsp;</FONT>
            <SELECT NAME="operator3" CLASS="combomini" STYLE="width:100"></SELECT>
          </TD>
          <TD CLASS="strip1">
            <INPUT TYPE="hidden" NAME="code3">
            <DIV ID="val2txt" STYLE="position:relative;visibility:visible"><INPUT TYPE="text" NAME="value3" CLASS="textmini" MAXLENGTH="250" SIZE="30" onChange="document.forms[0].code3.value=''"></DIV>
          </TD>
          <TD CLASS="formfront">
            <DIV ID="lookup3" STYLE="position:relative;visibility:hidden"><A HREF="javascript:lookup(3)"><IMG SRC="../images/images/find16.gif" HEIGHT="16" BORDER="0" ALT="View list of values"></A></DIV>          
          </TD>
        </TR>        
	<TR>
	<TD COLSPAN="4">
<% if (nullif(request.getParameter("queryspec"),"").equals("listmember")) { %>
	  <DIV ID="showresultsas" STYLE="position:relative;visibility:hidden">
<% } else { %>
	  <DIV ID="showresultsas">
<% } %>
	  <FONT CLASS="formplain">show results as&nbsp;</FONT><SELECT onChange="columnVisibility()" CLASS="combomini" NAME="sel_show_as"><OPTION VALUE="HTML" SELECTED>HTML</OPTION><OPTION VALUE="XLS">Excel</OPTION><OPTION VALUE="CSV">Comma delimited text</OPTION><OPTION VALUE="TSV">Tab delimited text</OPTION></SELECT>
	  </DIV>
	</TD>
	</TR>
        <TR>
          <TD>
            <DIV ID="columns1" STYLE="position:relative;visibility:hidden">
      	    <FONT CLASS="textplain">All columns</FONT><BR>
<%
 	    String sColumns = "";  	    
 	    int iColumns = 0;

  	    Vector vColumns = oQBF.getColumns();  
  	    iColumns = vColumns.size();
  	   
	    DOMSubDocument oColumn;
	    Node oColNode;

  	    for (int c=0; c<iColumns; c++) {
    	      oColumn = (DOMSubDocument) vColumns.get(c);
    	      oColNode = oColumn.getNode();
    	      
    	      sColumns += "<OPTION VALUE=\"" + oColumn.getElement("name").trim() + "\"";
    	        
    	      sColumns += ">" + oColumn.getElement("label_" + sLanguage) + "</OPTION>";
  	    } // next (f)

%>
            <SELECT NAME="sel_all_columns" SIZE="5" MULTIPLE><%=sColumns%></SELECT>
            </DIV>
          </TD>
          <TD ALIGN="center" VALIGN="middle">
	    <DIV ID="columns2" STYLE="position:relative;visibility:hidden">
	    <INPUT TYPE="button" VALUE="Add >>" STYLE="font-family:Arial,Helvetica,sans-serif;font-size:9pt;width:100px" onClick="addColumns()">
	    <BR><BR>
	    <INPUT TYPE="button" VALUE="<< Remove" STYLE="font-family:Arial,Helvetica,sans-serif;font-size:9pt;width:100px" onClick="removeColumns()">
            </DIV>
          </TD>
          <TD>
      	    <DIV ID="columns3" STYLE="position:relative;visibility:hidden">
      	    <FONT CLASS="textplain">Columns to show</FONT><BR>
<%

	    DOMDocument oQBFDoc = oQBF.getDocument();

	    sColumns = "";
  	    for (int c=0; c<iColumns; c++) {
    	      oColumn = (DOMSubDocument) vColumns.get(c);
    	      oColNode = oColumn.getNode();    	      

    	      if (oQBFDoc.getAttribute(oColNode, "default")!=null) {    	        
    	        sColumns += "<OPTION VALUE=\"" + oColumn.getElement("name").trim() + "\"";
    	        sColumns += ">" + oColumn.getElement("label_" + sLanguage) + "</OPTION>";
  	      } // fi(default)
  	    } // next (f)
%>
            <SELECT NAME="sel_show_columns" SIZE="5" MULTIPLE><%=sColumns%></SELECT>
            </DIV>
          </TD>
          <TD></TD>
        </TR>        
        <TR>
          <TD></TD>
          <TD ALIGN="right">
            <DIV ID="columns4" STYLE="position:relative;visibility:hidden">
            <FONT CLASS="textplain">&nbsp;order by</FONT>
            </DIV>
          </TD>
          <TD COLSPAN="2">
            <DIV ID="columns5" STYLE="position:relative;visibility:hidden">
            <SELECT NAME="sel_orderby" CLASS="combomini">
<%
  	    Vector vSortable = oQBF.getSortable();  
  	    String sSortable = "<OPTION VALUE=\"\"></OPTION>";
	    DOMSubDocument oOrder;
  
  	    for (int s=0; s<vSortable.size(); s++) {
    	      oOrder = (DOMSubDocument) vSortable.get(s);
    	      sSortable += "<OPTION VALUE=\"" + oOrder.getElement("name").trim() + "\">" + oOrder.getElement("label_" + sLanguage) + "</OPTION>";
  	    } // next (f)
  	    out.write(sSortable);	    
%>            
            </SELECT>
            </DIV>
          </TD>
        </TR>
        <TR>
          <TD COLSPAN="4"><HR></TD>
        </TR>
        <TR>
          <TD COLSPAN="4" ALIGN="center">
<% if (bIsGuest) { %>
            <INPUT TYPE="button" ACCESSKEY="s" TITLE="ALT+s" VALUE="Save" CLASS="pushbutton" STYLE="width:80" onclick="alert ('Your credential level as Guest does not allow you to perform this action')">
<% } else { %>
            <INPUT TYPE="button" ACCESSKEY="s" TITLE="ALT+s" VALUE="Save" CLASS="pushbutton" STYLE="width:80" onclick="saveQuery()">
<% } %>
<% 
    	  if (!sCaller.startsWith("list_"))
            out.write("            &nbsp;&nbsp;&nbsp;<INPUT TYPE=\"submit\" ACCESSKEY=\"q\" TITLE=\"ALT+q\" VALUE=\"Query\" CLASS=\"pushbutton\" STYLE=\"width:80\">");
	  else
            out.write("            &nbsp;&nbsp;&nbsp;<INPUT TYPE=\"button\" ACCESSKEY=\"c\" TITLE=\"ALT+c\" VALUE=\"Cancel\" CLASS=\"closebutton\" STYLE=\"width:80\" onclick=\"window.close()\">");
%>            
          </TD>
        </TR>
      </TABLE>
    </FORM>
    </CENTER>
  </BODY>
</HTML>
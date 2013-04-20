<%@ page import="java.net.URLDecoder,java.util.Vector,java.sql.SQLException,java.sql.PreparedStatement,java.sql.ResultSet,com.knowgate.jdc.*,com.knowgate.dataobjs.*,com.knowgate.acl.*,com.knowgate.hipergate.*" language="java" session="false" contentType="text/html;charset=UTF-8" %>
<%@ include file="../methods/dbbind.jsp" %><%@ include file="../methods/cookies.jspf" %><%@ include file="../methods/nullif.jspf" %><%@ include file="../methods/authusrs.jspf" %><%@ include file="../methods/listchilds.jspf" %>
<jsp:useBean id="GlobalDBLang" scope="application" class="com.knowgate.hipergate.DBLanguages"/><%

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
  if (autenticateSession(GlobalDBBind, request, response)<0) return;

  response.setHeader("Cache-Control","no-cache");
  response.setHeader("Pragma","no-cache");
  response.setIntHeader("Expires", 0);

  final int Config=30;
    
  String sSkin = getCookie(request, "skin", "default");
  String sLanguage = getNavigatorLanguage(request);
  int iAppMask = Integer.parseInt(getCookie(request, "appmask", "0"));
  
  String sHeadStrip;
  
  if (null==request.getParameter("id_domain")) {
    response.sendRedirect (response.encodeRedirectUrl ("../common/errmsg.jsp?title=Dominio no encontrado&desc=Imposible encontrar el dominio de seguridad para la categoria&resume=_close"));
    return;
  }
  
  int id_domain = Integer.parseInt(request.getParameter("id_domain"));
  String gu_user = getCookie(request, "userid", "");
  String id_category = nullif(request.getParameter("id_category"));
  String id_parent = nullif(request.getParameter("id_parent_cat"));
  String top_parent = nullif(request.getParameter("top_parent_cat"));
  String n_category;
  Short  is_active;
  Short  id_doc_status;
  String nm_icon1;
  String nm_icon2;
  int iRowCount; // Nº de filas en la matriz de nombres traducidos
  int iColCount; // Nº de columnas en la matriz de nombres traducidos
  boolean bAdmin;
    
  Category   oCatg; // Categoria  
  ACLUser    oUser; // Usuario logado
  DBSubset   oName; // Nombres traducidos de la categoria (etiquetas)
  DBSubset   oPrnt; // Lista de nodos padre de esta categoria
  Object     oFld;  // Variable intermedia

  JDCConnection oConn; // Conexion con la BB.DD.
  PreparedStatement oBrowseChilds;
  StringBuffer oSelParents;
    
  // Conectar con la BB.DD.  
  oConn = GlobalDBBind.getConnection("shopcatedit");
  
  if ((iAppMask & (1<<Config))==0)
    bAdmin = false;
  else {
    oUser = new ACLUser();
    oUser.put(DB.gu_user, gu_user);
    oUser.put(DB.id_domain, id_domain);
    bAdmin = oUser.isDomainAdmin(oConn);
    oUser = null;
  }
  
  // Get language list in a <SELECT> tag
  String sSelLang = GlobalDBLang.toHTMLSelect(oConn, sLanguage);
  
  // Get categories list in a <SELECT> tag
  oSelParents = new StringBuffer();
  oBrowseChilds = oConn.prepareStatement("SELECT c." + DB.gu_category + "," + DBBind.Functions.ISNULL + "(l." + DB.tr_category + ",c." + DB.nm_category + ") FROM " + DB.k_categories + " c," + DB.k_cat_tree + " t," + DB.k_cat_labels + " l WHERE c." + DB.gu_category + "=t." + DB.gu_child_cat + " AND l." + DB.gu_category + "=c." + DB.gu_category + " AND l." + DB.id_language + "='" + sLanguage + "' AND t." + DB.gu_parent_cat + "=?", ResultSet.TYPE_FORWARD_ONLY, ResultSet.CONCUR_READ_ONLY);
  listChilds (oSelParents, oBrowseChilds, id_category, top_parent, 3);
  oBrowseChilds.close();
  
  if (0!=id_category.length()) {
    sHeadStrip = "Edit Category";
    
    oCatg = new Category(oConn, id_category);
    n_category = oCatg.getString(DB.nm_category);
    
    is_active = new Short(String.valueOf(oCatg.get(DB.bo_active)));
    
    if (oCatg.isNull(DB.id_doc_status))
      id_doc_status = new Short((short)0);
    else
      id_doc_status = new Short((short)0);
    
    nm_icon1 = oCatg.getStringNull(DB.nm_icon, "folderclosed_16x16.gif");
    nm_icon2 = oCatg.getStringNull(DB.nm_icon2, "folderopen_16x16.gif");

    // Get Labels
    oName = oCatg.getNames(oConn);
    iRowCount = oName.getRowCount();
    iColCount = oName.getColumnCount();
    
    // Get parent
    oPrnt = oCatg.getParents(oConn);
    id_parent = oPrnt.getString(0,0);
    
    oCatg = null;
  }
  else {
    sHeadStrip = "New Category";

    n_category = new String("");
    is_active = new Short((short)1);
    id_doc_status = new Short((short)0);
    nm_icon1 = "folderclosed_16x16.gif";
    nm_icon2 = "folderopen_16x16.gif";
    
    // Dummy variable initialization 
    oName = new DBSubset(DB.k_cat_labels,"","",0);    
  
    iRowCount = iColCount = 0;
  }
  
  
  oConn.close("shopcatedit");
  oConn = null;
%>

  <!-- +-----------------------+ -->
  <!-- | Edición de categorias | -->
  <!-- | © KnowGate 2001       | -->
  <!-- +-----------------------+ -->
<HTML LANG="<% out.write(sLanguage); %>">
<HEAD>
  <TITLE>hipergate :: <%=sHeadStrip%></TITLE>  
  <SCRIPT SRC="../javascript/cookies.js"></SCRIPT>  
  <SCRIPT SRC="../javascript/setskin.js"></SCRIPT>
  <SCRIPT SRC="../javascript/combobox.js"></SCRIPT>
  <SCRIPT SRC="../javascript/usrlang.js"></SCRIPT>
  <SCRIPT SRC="../javascript/trim.js"></SCRIPT>
  <SCRIPT SRC="../javascript/layer.js"></SCRIPT>  
  <SCRIPT SRC="../javascript/getparam.js"></SCRIPT>  
  <SCRIPT TYPE="text/javascript">
  <!--
    // Translation labels list current position
    var iLabelIndex = -1;
    // Translation labels list max index
    var iMaxLabel = <%=iRowCount-1%>;
    // Relative path to active skin
    var sSkinPath = "../skins/<%=sSkin%>/";
    // Toolbar image names array
    var aButtonName = new Array("newreg","delreg","left2","left","right","right2");
    // Toolbar tooltips array
    var aButtonTips = new Array("New translated label","Remove translated label","Go to first label","Previous label","Next label","Go to last label");
    // Non-clicked buttons images
    var aButtonDown = new Array(aButtonName.length);
    // Clicked buttons images
    var aButtonUp   = new Array(aButtonName.length);
    // Translated names array: each element is another array
    var aName = new Array(<% out.write(String.valueOf(iRowCount)); %>);
    // Translated labels array
    var oTrCt = new Array(<% out.write(String.valueOf(iColCount)); %>);

    <%
      // Loop the translated names array and assign to array aName
      for (int iRow=0; iRow<iRowCount; iRow++) {
        out.write("    aName[" + String.valueOf(iRow) + "] = new Array(");
        
        for (int iCol=0; iCol<iColCount; iCol++) {
          oFld = oName.get(iCol,iRow);
          if (null==oFld)
            out.write ("\"\"");
          else
            out.write ("\"" + String.valueOf(oFld) + "\"");
          if (iCol<iColCount-1)
            out.write (",");
          else
            out.write (");\n");
        }   
      }  
    %>
      
    // --------------------------------------------------------
    
    function writePos() {
      // Output current position in labels list in an HTML layer
      var sInnerHTML = '<FONT CLASS="textplain"><B>' + String(iLabelIndex+1) + "/" + String (iMaxLabel+1) + '</B></FONT>'
      
      if (iLabelIndex>=0) {
        
        if (navigator.appName=="Microsoft Internet Explorer") {
          document.all.trpos.innerHTML = sInnerHTML;
        } else {
          document.getElementById("trpos").innerHTML = sInnerHTML;
        }
        showLayer("trpos");
      }
      else {
        hideLayer("trpos");        
      }
    }

    // --------------------------------------------------------

    function preCache() {

      if (aName.length>0) {
        showLayer("trcat");
        frm.id_language.value = aName[0][0];
        setCombo (frm.sel_language, frm.id_language.value);
        frm.tr_category.value = aName[0][1];
        iLabelIndex = 0;
      }

      
      // Button images preload (toolbar)
      for (var i=0; i<aButtonName.length; i++) {
        aButtonUp[i] = new Image();
        aButtonUp[i].src = sSkinPath + aButtonName[i] + ".gif";

        aButtonDown[i] = new Image();
        aButtonDown[i].src = sSkinPath + aButtonName[i] + "_.gif";        
      }      
      writePos();
      
      if (getURLParam("id_category")==null) createLabel();
      
      if (""!=getURLParam("id_parent_cat"))
        setCombo(document.forms[0].sel_parent_cat, "<% out.write(id_parent); %>");
    }
  //-->
  </SCRIPT>
  
  <SCRIPT LANGUAGE="JavaScript1.2" TYPE="text/javascript" DEFER="defer">
  <!--
    function validate() {
      // Validate form data and post to catedit_store
      var frm = document.forms[0];
      var alias = frm.n_category.value;
   
      if (alias.length==0 && aName.length==0) {
        alert ("Must specify at least one Alias or Translated Label");
        return false;        
      }

      var bLocalLabel = false;
      for (var n=0; n<aName.length; n++) {
        bLocalLabel = (aName[n][0]==getUserLanguage());
        if (bLocalLabel) break;
      }
      if (!bLocalLabel) {
        alert ("Must specify a Translated Label in your browser current language'" + getUserLanguage() + "'");
			  return false;
      }
            
      if (alias.indexOf(" ")>=0 || alias.indexOf(";")>=0 || alias.indexOf(",")>=0 || alias.indexOf(".")>=0 || alias.indexOf("?")>=0 || alias.indexOf("$")>=0 || alias.indexOf("%")>=0 || alias.indexOf("/")>=0 || alias.indexOf("¨")>=0 || alias.indexOf("`")>=0) {
        alert ("Category alias contains forbidden characters");
        return false;        
      }
      else
        frm.n_category.value = alias;

      if (aName.length==0) {
        alert ("Must specify at least one Translated Label");
	return false;
      }

      frm.tr1st.value = aName[0][1];
      
      for (var n=0; n<aName.length; n++) {
        if (ltrim(aName[n][1]).length==0) {
          alert ("Label for language&nbsp;" + getComboText(frm.sel_language) + " cannot be empty");
          return false;
        }    
      } // next

      frm.id_parent_cat.value = getCombo(frm.sel_parent_cat);

      if (frm.id_parent_cat.value=="<%=id_category%>") {
          alert ("Category may not be parent of itself");
          return false;        
      }

      for (var l=0; l<aName.length; l++)
        aName[l] = aName[l][0] + "`" + aName[l][1];
      
      frm.names_subset.value = aName.join("¨");
      
      return true;
    } // validate

    // --------------------------------------------------------

    function showLabel(iLabel) {
      // Show contents of a label in HTML form
      var frm = document.forms[0];

      frm.id_language.value = aName[iLabel][0];
      setCombo (frm.sel_language, frm.id_language.value);
      frm.tr_category.value = aName[iLabel][1];
    }

    // --------------------------------------------------------

    function createLabel() {      
      var cat;
      var frm = document.forms[0];
      
      iLabelIndex=++iMaxLabel;
      if (0==iLabelIndex)
        setCombo(frm.sel_language, getUserLanguage());
      else
        frm.sel_language.selectedIndex = 0;
        frm.tr_category.value = frm.id_language.value = "";
        cat = new Array("","","");
        aName[iLabelIndex] = cat;
        showLayer("trcat");
    } // createLabel
    
    // --------------------------------------------------------
            
    function pressButton(button,index) {      
      var l,m;
      var nct;
      var cat;
      var frm;
            
      if (button.src.indexOf("_")!=-1) {
        switch(index) {
          case 0: // New label
            createLabel();
            break;
          case 1: // Remove label
            if (iLabelIndex!=-1) {	      
	      if (iMaxLabel>0) {
                nct = new Array(iMaxLabel);
                for (l=m=0; l<=iMaxLabel; l++)
                  if (l!=iLabelIndex) nct[m++] = aName[l];                            
                iMaxLabel--;
            	showLabel(iLabelIndex=0);
              }
              else {
                hideLayer("trcat");
                iMaxLabel=-1;
            	iLabelIndex=-1;              
              }              
            }
            break;
	  case 2: // Go to first label
	    if (iLabelIndex!=-1) showLabel(iLabelIndex=0);
	    break;
          case 3: // Back one label
            if (iLabelIndex>0) showLabel(--iLabelIndex);
            break;
          case 4: // Forward one label
      	    if (iLabelIndex!=-1 && iLabelIndex<iMaxLabel) showLabel(++iLabelIndex);
            break;
          case 5: // Go to last label
      	    if (iLabelIndex!=-1) showLabel(iLabelIndex=iMaxLabel);
            break;
        } // end switch(index)
        writePos();
      }
      button.src = aButtonUp[index].src;
    }

    // --------------------------------------------------------
    
    function leaveButton(button,index) {
      button.src = aButtonUp[index].src;
    }

    // --------------------------------------------------------

    function changeName() {
      var frm;
      var sel;
      var cat;

      if (iLabelIndex>=0) {
        frm = document.forms[0];
        sel = frm.sel_language.options;
        cat = aName[iLabelIndex];
        cat[0] = sel[sel.selectedIndex].value;
        cat[1] = frm.tr_category.value;
        cat[2] = "";        
      }
    }
            
  //-->
  </SCRIPT>
</HEAD>

<BODY  SCROLL="no" TOPMARGIN="4" MARGINHEIGHT="4" onLoad="preCache()">
  <TABLE WIDTH="100%"><TR><TD CLASS="striptitle"><FONT CLASS="title1"><%=sHeadStrip%></FONT></TD></TR></TABLE>

  <DIV ID="dek" STYLE="width:200;height:20;z-index:200;visibility:hidden;position:absolute"></DIV>
  <SCRIPT LANGUAGE="JavaScript1.2" SRC="../javascript/popover.js"></SCRIPT>
  <BR><BR>
  <FORM NAME="linkedit" METHOD="post" ACTION="catedit_store.jsp" onsubmit="return validate()">
    <INPUT TYPE="hidden" NAME="id_category" VALUE="<% out.write(id_category); %>">
    <INPUT TYPE="hidden" NAME="names_subset" VALUE="">
    <INPUT TYPE="hidden" NAME="tr1st" VALUE="">
    <INPUT TYPE="hidden" NAME="nm_icon1" VALUE="<% out.write(nm_icon1); %>">
    <INPUT TYPE="hidden" NAME="nm_icon2" VALUE="<% out.write(nm_icon2); %>">

    <INPUT TYPE="hidden" NAME="id_parent_cat" VALUE="<% out.write(id_parent); %>">
    <INPUT TYPE="hidden" NAME="id_parent_old" VALUE="<% out.write(id_parent); %>">
    <INPUT TYPE="hidden" NAME="top_parent" VALUE="<% out.write(top_parent); %>"> 
    
    <TABLE CLASS="formback">
      <TR><TD>
        <TABLE WIDTH="100%" CLASS="formfront">

<% if (1024==id_domain || 1025==id_domain) { %>
          <TR>
            <TD ALIGN="right" WIDTH="150"><SPAN onmouseover="popover('Alias is a language independent symbolic name for category.<BR><STRONG>Max 30 characters without spaces</STRONG>')" onmouseout="popout()"><FONT CLASS="formplain">Alias:</FONT></SPAN></TD>
            <TD ALIGN="left" WIDTH="290">
              <INPUT TYPE="text" NAME="n_category" MAXLENGTH="30" SIZE="34" VALUE="<% out.write(n_category); %>">
            </TD>
          </TR>
<% } else out.write("<INPUT TYPE=\"hidden\" NAME=\"n_category\" VALUE=\"" + n_category + "\">"); %>
	      
          <TR>
            <TD ALIGN="right" WIDTH="150"><SPAN onmouseover="popover('Category list is hierarchical.<BR>Parent Category')" onmouseout="popout()"><FONT CLASS="formstrong">Parent:</FONT></SPAN></TD>
            <TD ALIGN="left" WIDTH="290"><SELECT NAME="sel_parent_cat"><OPTION VALUE="<% out.write (top_parent);%>">ROOT</OPTION><% out.write(oSelParents.toString()); %></SELECT></TD>
          </TR>

          <TR>
            <TD ALIGN="right" WIDTH="150">
              <SPAN onmouseover="popover('Visibility')" onmouseout="popout()"><FONT CLASS="formstrong">Visible:</FONT></SPAN>
            </TD>
            <TD ALIGN="left" WIDTH="290">
              <INPUT TYPE="checkbox" NAME="is_active" VALUE="1" <% if (is_active.intValue()!=0) out.write(" CHECKED=\"true\" "); %>>&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;
              <INPUT TYPE="hidden" NAME="id_doc_status" VALUE="1">
            </TD>
          </TR>
          <TR>
            <TD COLSPAN="2">
              <TABLE ALIGN="center" WIDTH="92%" BACKGROUND="../skins/<%=sSkin%>/fondoc.gif">
                <TR><TD>
		  <SPAN CLASS="lightshadow" STYLE="position:relative;top:-8;left:0;width:48;height=23;" TITLE="Labels are Category titles shown for each language."><FONT CLASS="formstrong"><BIG>LABELS</BIG></FONT></SPAN>
		  <IMG SRC="../images/images/spacer.gif" WIDTH="24" HEIGHT="23" BORDER="0" oncontextmenu="return false;">
		  <SCRIPT TYPE="text/javascript">
		    <!--
		    for (var b=0; b<aButtonName.length; b++) {
		      document.write ('<IMG SRC="' + sSkinPath + aButtonName[b] + '.gif"' + ' WIDTH="26" HEIGHT="23" BORDER="0" VSPACE="3" ALT="' + aButtonTips[b] + '" oncontextmenu="return false;" onmousedown="this.src=aButtonDown[' + String(b) + '].src" onmouseout="leaveButton(this,' + String(b) + ')" onmouseup="pressButton(this,' + String(b) + ')">');
		      if (b==1) document.write ("&nbsp;");		      
		    }
		    if ((navigator.appName=="Microsoft Internet Explorer") || (navigator.appCodeName=="Mozilla"))
		      document.write('<DIV ID="trpos" CLASS="formfront" STYLE="position:relative;top:-28;left:330;width:40;height:10;"></DIV>');
		    else
		      document.write('<LAYER NAME="trpos" CLASS="formfront" STYLE="position:relative;top:-28;left:330;width:40;height:10;"></LAYER>');
		    //-->
		  </SCRIPT>
		</TD></TR>
                <TR><TD>
            	  <DIV ID="trcat" STYLE="visibility:hidden">
            	    <INPUT TYPE="hidden" NAME="id_language">
            	    <TABLE BORDER="0" CELLSPACING="0" CELLPADDING="0">
            	      <TR>            	      
            	        <TD><FONT CLASS="formstrong">Language:</FONT></TD>
            	        <TD>&nbsp;&nbsp;&nbsp;<FONT CLASS="formstrong">Text for Label:</FONT></TD>            	      
            	      </TR>  
            	      <TR>
            	        <TD><SELECT NAME="sel_language" onchange="changeName()"><OPTION VALUE="" SELECTED><% out.write (sSelLang); %></SELECT></TD>
		        <TD>&nbsp;&nbsp;&nbsp;<INPUT TYPE="text" NAME="tr_category" MAXLENGTH="30" SIZE="34" VALUE="" onblur="changeName()" onchange="changeName()" onkeypress="changeName()"></TD>
		      </TR>
		    </TABLE>
		    <IMG SRC="../images/images/spacer.gif" WIDTH="4" HEIGHT="4" BORDER="0" oncontextmenu="return false;">
		  </DIV>
		</TD></TR>
              </TABLE>
          </TR>    
          <TR>
    	    <TD COLSPAN="2"><HR></TD>
  	  </TR>
          <TR>
    	    <TD WIDTH="150">&nbsp;</TD>
    	    <TD WIDTH="290">
              <INPUT TYPE="submit" ACCESSKEY="s" VALUE="Save" CLASS="pushbutton" STYLE="width:80" TITLE="ALT+s">&nbsp;
    	      &nbsp;&nbsp;<INPUT TYPE="button" ACCESSKEY="c" VALUE="Cancel" CLASS="closebutton" STYLE="width:80" TITLE="ALT+c" onclick="window.close()">
    	      <BR><BR>
    	    </TD>	    
          </TR>           
        </TABLE>
      </TD></TR>
    </TABLE>
  </FORM>
</BODY>
<SCRIPT TYPE="text/javascript">
  <!--
    var frm = document.forms[0];
    <%    
/*
      if (iRowCount>0) {
        out.write ("    frm.id_language.value='" + oName.getString(0,0) + "';\n");
        out.write ("    setCombo(frm.sel_language,frm.id_language.value);\n");
        out.write ("    frm.tr_category.value='" + oName.getString(1,0) + "';\n");
        out.write ("    iLabelIndex = 0;\n");
        out.write ("    showLayer(\"trcat\");\n");
      }
*/
    %>
  //-->
</SCRIPT>
</HTML>

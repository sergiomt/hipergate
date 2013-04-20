<%@ page import="java.net.URLDecoder,com.knowgate.jdc.*,com.knowgate.dataobjs.*,com.knowgate.acl.*,com.knowgate.hipergate.*,com.knowgate.misc.Gadgets" language="java" session="false" contentType="text/html;charset=UTF-8" %>
<%@ include file="../methods/dbbind.jsp" %><%@ include file="../methods/cookies.jspf" %><%@ include file="../methods/authusrs.jspf" %><%@ include file="../methods/nullif.jspf" %><%
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

  String sVoid = "";
  if (null==request.getParameter("id_domain") || sVoid.equals(request.getParameter("id_domain"))) {
    response.sendRedirect (response.encodeRedirectUrl ("../common/errmsg.jsp?title=Domain not found&desc=Security domain not found&resume=_close"));
    return;
  }
    
  int id_domain = Integer.parseInt(request.getParameter("id_domain"));
  String gu_user = getCookie(request, "userid", "");

  String sSkin = getCookie(request, "skin", "xp");
  String sLanguage = getNavigatorLanguage(request);
  int iAppMask = Integer.parseInt(getCookie(request, "appmask", "0"));      
  int iRowCount; // Nº de filas en la matriz de nombres traducidos
  int iColCount; // Nº de columnas en la matriz de nombres traducidos
  boolean bAdmin;
  
  String gu_workarea = request.getParameter("gu_workarea");
  String nm_table = nullif(request.getParameter("nm_table"));
  String id_section = nullif(request.getParameter("id_section"));
  String tx_table = nullif(request.getParameter("tx_table"));
  
  String sHeadStrip = "Edit user defined field for&nbsp;" + tx_table;
  String sButtonList = "\"newreg\",\"delreg\",\"left2\",\"left\",\"right\",\"right2\"";
  String sButtonTips = "\"New translated label\",\"Delete translated label\",\"Go to first label\",\"Previous label\",\"Next label\",\"Go to last label\"";
  DBSubset   oName = null; // Nombres traducidos (etiquetas)
  Object     oFld;  // Variable intermedia
  JDCConnection oConn; // Conexion con la BB.DD.
    
  // Conectar con la BB.DD.  
  oConn = GlobalDBBind.getConnection("fldedit");
    
  if (0!=id_section.length()) {
    iRowCount = iColCount = 0;
  }
  else {
    iRowCount = iColCount = 0;
  }
    
  oConn.close("fldedit");
  oConn = null;
%>
  <!-- +--------------------------------------------+ -->
  <!-- | Edición de campos definidos por el usuario | -->
  <!-- | ¨ KnowGate 2003                            | -->
  <!-- +--------------------------------------------+ -->
<HTML LANG="<% out.write(sLanguage); %>">
<HEAD>
  <TITLE>hipergate :: <%=sHeadStrip%></TITLE>  
  <SCRIPT SRC="../javascript/cookies.js"></SCRIPT>  
  <SCRIPT SRC="../javascript/setskin.js"></SCRIPT>
  <SCRIPT SRC="../javascript/combobox.js"></SCRIPT>
  <SCRIPT SRC="../javascript/usrlang.js"></SCRIPT>
  <SCRIPT SRC="../javascript/trim.js"></SCRIPT>
  <SCRIPT SRC="../javascript/layer.js"></SCRIPT>
  
  <SCRIPT TYPE="text/javascript">
  <!--
    // Posicion actual dentro de la lista de etiquetas de traduccion
    var iLabelIndex = -1;
    // Maximo indice de la matriz de etiquetas de traduccion
    var iMaxLabel = <%=iRowCount-1%>;
    // Ruta relativa a los ficheros del skin activo
    var sSkinPath = "../skins/<%=sSkin%>/";
    // Matriz con los nombres de la imagenes de la toolbar
    var aButtonName = new Array(<%=sButtonList%>);
    // Matriz con los tips de la imagenes de la toolbar
    var aButtonTips = new Array(<%=sButtonTips%>);
    // Imagenes de los botones sin pinchar
    var aButtonDown = new Array(aButtonName.length);
    // Imagenes de los botones pinchados
    var aButtonUp   = new Array(aButtonName.length);
    // Matriz de Nombres traducidos: cada elemento es otro array
    var aName = new Array(<% out.write(String.valueOf(iRowCount)); %>);
    // Array que representa un nombre traducido de categoria (etiqueta)
    var oTrCt = new Array(<% out.write(String.valueOf(iColCount)); %>);
    
    <%
      // Recorrer la lista de nombres traducidos y asignarlos al array aName
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
      // Escribir en una capa HTML la posicion actual dentro de la lista de etiquetas
      var sInnerHTML = '<FONT CLASS="textplain"><B>' + String(iLabelIndex+1) + "/" + String (iMaxLabel+1) + '</B></FONT>';
      
      if (iLabelIndex>=0) {
        if (navigator.appName=="Microsoft Internet Explorer") {
          document.all.trpos.innerHTML = sInnerHTML;
          document.all.trpos.visibility = "visible";
        }
        else {
          document.getElementById("trpos").innerHTML = (sInnerHTML);
          document.getElementById("trpos").visibility="visible";
        }
      }
      else {
        if (navigator.appName=="Microsoft Internet Explorer")
          document.all.trpos.visibility = "hidden";
        else      
          document.getElementById("trpos").visibility="hidden";
      }
    }

    // --------------------------------------------------------

    function preCache() {
      // Precargar la imagenes de los botones de la toolbar
      for (var i=0; i<aButtonName.length; i++) {
        aButtonUp[i] = new Image();
        aButtonUp[i].src = sSkinPath + aButtonName[i] + ".gif";

        aButtonDown[i] = new Image();
        aButtonDown[i].src = sSkinPath + aButtonName[i] + "_.gif";        
      }
      writePos();
      
      setCombo(document.forms[0].sel_language, getUserLanguage());

      createLabel();
    }
  //-->
  </SCRIPT>
  
  <SCRIPT TYPE="text/javascript" DEFER="defer">
  <!--
    function validate() {
      
      var frm = document.forms[0];
      var txt;
      var alias = frm.id_section.value;
      
      if (alias.length==0) {
        alert ("Field name is mandatory");
        return false;        
      }
      
      if (alias.indexOf(" ")>=0 || alias.indexOf(";")>=0 || alias.indexOf(",")>=0 || alias.indexOf(".")>=0 || alias.indexOf("?")>=0 || alias.indexOf("$")>=0 || alias.indexOf("%")>=0 || alias.indexOf("/")>=0 || alias.indexOf("¿")>=0 || alias.indexOf("`")>=0) {
        alert ("Field name contains invalid characters");
        return false;        
      }
      else
        frm.id_section.value = alias.toLowerCase();

      txt = frm.max_len.value;
      for (var c=0; c<txt.length; c++)
        if (txt.charCodeAt(c)<48 || txt.charCodeAt(c)>57) {
	  alert ("Field length must be an integer quantity");
	  return false;
	} // fi
      if (parseInt(txt)>250) {
        alert ("Field max length must not be longer than 250 characters");
	return false;
      }

      if (aName.length==0) {
        alert ("Must specify at least one Translated Label");
	return false;
      }
      	        
      for (var n=0; n<aName.length; n++) {        
        if (aName[n][0].length>0)
          eval ("frm.tr_" + aName[n][0] + ".value='" + aName[n][1] + "'");
        else {
          alert ("Labels cannot ve empty strings");
	  return false;          
        }        
      }
                  
      return true;
    } // validate 


    // --------------------------------------------------------

    function showLabel(iLabel) {
      // Mostrar los datos de una etiqueta en el formulario HTML
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
      
      if (button.src.indexOf("_")==-1) {
        switch(index) {
          case 0: // Nueva Etiqueta
	    createLabel();
            break;
          case 1: // Borrar Etiqueta
            if (iLabelIndex!=-1) {	      
	      if (iMaxLabel>0) {
                nct = new Array(iMaxLabel);
                for (l=m=0; l<=iMaxLabel; l++)
                  if (l!=iLabelIndex) nct[m++] = aName[l];                            
                iMaxLabel--;
            	showLabel(iLabelIndex=0);
              }
              else {
                document.getElementById("trcat").style.visibility = "hidden";
                iMaxLabel=-1;
            	iLabelIndex=-1;              
              }              
            }
            break;
	  case 2: // Ir a la primera
	    if (iLabelIndex!=-1) showLabel(iLabelIndex=0);
	    break;
          case 3: // Ir una hacia atras
            if (iLabelIndex>0) showLabel(--iLabelIndex);
            break;
          case 4: // Ir una hacia adelante
      	    if (iLabelIndex!=-1 && iLabelIndex<iMaxLabel) showLabel(++iLabelIndex);
            break;
          case 5: // Ir a la ultima
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
   <TABLE><TR><TD CLASS="striptitle"><FONT CLASS="title1"><%=sHeadStrip%></FONT></TD></TR></TABLE> 
  <BR>
  <FORM NAME="linkedit" METHOD="post" ACTION="fldedit_store.jsp" onsubmit="return validate()">
    <INPUT TYPE="hidden" NAME="gu_owner" VALUE="<%=gu_workarea%>">
    <INPUT TYPE="hidden" NAME="nm_table" VALUE="<%=nm_table%>">
    <INPUT TYPE="hidden" NAME="tp_attr" VALUE="1"> <!-- De momento solo hay soporte para campo tipo INPUT -->
<% for (int l=0; l<DBLanguages.SupportedLanguages.length; l++) { %>
    <INPUT TYPE="hidden" NAME="tr_<%=DBLanguages.SupportedLanguages[l]%>">
<% } %>

    <TABLE WIDTH="600" CLASS="formback">
      <TR><TD>
        <TABLE WIDTH="100%" CLASS="formfront">
          <TR>
            <TD ALIGN="right" WIDTH="150" CLASS="formstrong" NOWRAP>Field name:</TD>
            <TD ALIGN="left" WIDTH="290"><INPUT TYPE="text" NAME="id_section" MAXLENGTH="30" SIZE="34" VALUE="<% out.write(id_section); %>" STYLE="text-transform:lowercase"></TD>
          </TR>
          <TR>
            <TD ALIGN="right" WIDTH="150" CLASS="formstrong" NOWRAP>Max. Length:</TD>
            <TD ALIGN="left" WIDTH="290"><INPUT TYPE="text" NAME="max_len" MAXLENGTH="3" SIZE="4" VALUE="100"></TD>
          </TR>

          <TR>
            <TD COLSPAN="2">
              <TABLE ALIGN="center" WIDTH="92%" BACKGROUND="../skins/<%=sSkin%>/fondoc.gif">
                <TR><TD>
		  <SPAN CLASS="lightshadow" STYLE="position:relative;top:-8;left:0;width:48;height=23;" TITLE="Labels are Category titles shown for each language."><FONT CLASS="formstrong"><BIG>LABELS</BIG></FONT></SPAN>
		  <IMG SRC="../images/images/spacer.gif" WIDTH="24" HEIGHT="23" BORDER="0" oncontextmenu="return false;">
		  <%
		    String[] aButtonList = Gadgets.split(sButtonList,',');
		    String[] aButtonTips = Gadgets.split(sButtonTips,',');
		    for (int i=0; i<aButtonList.length; i++) {
		      String sButton = Gadgets.removeChars(aButtonList[i],"\"");
		      String sAltTxt = Gadgets.removeChars(aButtonTips[i],"\"");
		      out.write("<A HREF=\"#\" TITLE=\""+sAltTxt+"\" onclick=\"pressButton(document.images['"+sButton+"'],"+String.valueOf(i)+")\"><IMG ID=\""+sButton+"\" SRC=\"../skins/"+sSkin+"/"+sButton+".gif\" WIDTH=\"26\" HEIGHT=\"23\" BORDER=\"0\" VSPACE=\"3\" ALT=\""+sAltTxt+"\" oncontextmenu=\"return false;\"></A>");
		    }
		  %>
		  <SCRIPT TYPE="text/javascript">
		    <!--
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
            	        <TD><FONT CLASS="formstrong">Idioma:</FONT></TD>
            	        <TD>&nbsp;&nbsp;&nbsp;<FONT CLASS="formstrong">Text for Label:</FONT></TD>            	      
            	      </TR>  
            	      <TR>
            	        <TD><SELECT NAME="sel_language" onchange="changeName()"><OPTION VALUE="" SELECTED><OPTION VALUE="es">Spanish</OPTION><OPTION VALUE="en">English</OPTION><OPTION VALUE="fr">French</OPTION><OPTION VALUE="it">Italian</OPTION><OPTION VALUE="de">German</OPTION><OPTION VALUE="pt">Portuguese</OPTION><OPTION VALUE="ru">Russian</OPTION><OPTION VALUE="cn">Traditional Chinese</OPTION><OPTION VALUE="tw">Simplified Chinese</OPTION><OPTION VALUE="ja">Japanese</OPTION><OPTION VALUE="fi">Finnish</OPTION><OPTION VALUE="ca">Catalan</OPTION><OPTION VALUE="eu">Euskera</OPTION></SELECT></TD>
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
      if (iRowCount>0) {
        out.write ("    frm.id_language.value='" + oName.getString(0,0) + "';\n");
        out.write ("    setCombo(frm.sel_language,frm.id_language.value);\n");
        out.write ("    frm.tr_category.value='" + oName.getString(1,0) + "';\n");
        out.write ("    iLabelIndex = 0;\n");
        out.write ("    document.getElementById(\"trcat\").style.visibility = 'visible';\n");
      }
    %>
  //-->
</SCRIPT>
</HTML>

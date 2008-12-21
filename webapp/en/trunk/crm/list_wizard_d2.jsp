<%@ page import="java.io.File,java.io.IOException,java.net.URLDecoder,java.sql.SQLException,com.knowgate.jdc.*,com.knowgate.dataobjs.*,com.knowgate.acl.*,com.knowgate.misc.Environment" language="java" session="false" contentType="text/html;charset=UTF-8" %>
<%@ include file="../methods/dbbind.jsp" %><%@ include file="../methods/cookies.jspf" %><%@ include file="../methods/authusrs.jspf" %>
<%
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

  String sLanguage = getNavigatorLanguage(request);
  boolean bLatinLanguage = (sLanguage.startsWith("es") || sLanguage.startsWith("en") || sLanguage.startsWith("fr") || sLanguage.startsWith("de") || sLanguage.startsWith("pt") || sLanguage.startsWith("nl") || sLanguage.startsWith("pl"));
  boolean bChineseTraditional = sLanguage.startsWith("tw");
  boolean bChineseSimplified = sLanguage.startsWith("cn");
  boolean bRussianLanguage = sLanguage.startsWith("ru");

  // Obtener el directorio temp
  String sTempDir = Environment.getProfileVar(GlobalDBBind.getProfileName(), "temp", Environment.getTempDir());
  sTempDir = com.knowgate.misc.Gadgets.chomp(sTempDir,java.io.File.separator);

  String gu_query = request.getParameter("gu_query");
  File oTmpFile;
  
  // Borrar el fichero subido temporalmente si ya existía
  
  if (null!=gu_query) {
    if (gu_query.length()>0) {
      oTmpFile = new File(sTempDir + gu_query + ".tmp");
      if (oTmpFile.exists())
        oTmpFile.delete();
      oTmpFile = null;
    }
  }
%>

<HTML>
<HEAD>
  <SCRIPT LANGUAGE="JavaScript" SRC="../javascript/cookies.js"></SCRIPT>  
  <SCRIPT LANGUAGE="JavaScript" SRC="../javascript/setskin.js"></SCRIPT>
  <SCRIPT LANGUAGE="JavaScript" SRC="../javascript/getparam.js"></SCRIPT>
  <SCRIPT LANGUAGE="JavaScript" SRC="../javascript/combobox.js"></SCRIPT>
  <SCRIPT LANGUAGE="JavaScript" TYPE="text/javascript">
    <!--
      function q(str) {
        if (document.forms[0].quotedfields[0].checked)
          return '"' + str + '"';
        else
          return str;        
      }
      
      function setInputs() {
	window.resizeTo(420,420);
	
	var frm = document.forms[0];
	
	frm.id_domain.value = getURLParam("id_domain");
	frm.n_domain.value = getURLParam("n_domain");
	frm.gu_workarea.value = getURLParam("gu_workarea");
	frm.tp_list.value = getURLParam("tp_list");
	frm.id_user.value = getCookie("userid");
	
      }
      
      // ----------------------------------------------------------------------
      
      function validate() {
        var frm = document.forms[0];
	
	if (frm.emails.value.length==0) {
	  alert ("[~Debe especificar el fichero de texto delimitado a cargar~]");
	  return false;
	}
	
	if (getCombo(frm.sel_column1)=="") {
	  alert ("La columna 1 es obligatoria");
	  return false;
	}
	 
	if (getCombo(frm.sel_column1)!="tx_email" && getCombo(frm.sel_column2)!="tx_email" && getCombo(frm.sel_column3)!="tx_email" && getCombo(frm.sel_column4)!="tx_email") {
	  alert ("[~Al menos una de las columnas del fichero debe ser el e-mail a cargar~]");
	  return false;
	}

        var delim = getCombo(frm.sel_delimiter);
        
        if (delim=="tab") delim = "\t";
        
	frm.desc_file.value = q(getCombo(frm.sel_column1));
	if (getCombo(frm.sel_column2)!="")
	  frm.desc_file.value += delim + q(getCombo(frm.sel_column2));
	if (getCombo(frm.sel_column3)!="")
	  frm.desc_file.value += delim + q(getCombo(frm.sel_column3));
	if (getCombo(frm.sel_column4)!="")
	  frm.desc_file.value += delim + q(getCombo(frm.sel_column4));

        return true;
      }
    //-->
  </SCRIPT>
  <TITLE>hipergate :: [~Crear Lista de Distribuci&oacute;n - Paso 2/4~]</TITLE>
</HEAD>
<BODY  TOPMARGIN="8" MARGINHEIGHT="8" onLoad="setInputs()">
  <FORM ENCTYPE="multipart/form-data" METHOD="post" ACTION="list_wizard_d3.jsp" onSubmit="return validate()">
    <INPUT TYPE="hidden" NAME="id_domain">
    <INPUT TYPE="hidden" NAME="id_user">    
    <INPUT TYPE="hidden" NAME="n_domain">
    <INPUT TYPE="hidden" NAME="gu_workarea">
    <INPUT TYPE="hidden" NAME="tp_list">
    <INPUT TYPE="hidden" NAME="desc_file">

    <TABLE><TR><TD WIDTH="310px" CLASS="striptitle"><FONT CLASS="title1">[~Crear Lista - Paso 2 de 4~]</FONT></TD></TR></TABLE>
    <TABLE WIDTH="310px" CLASS="formback">
      <TR><TD ALIGN="left" CLASS="formstrong">[~Subir Fichero de Direcciones de e-mail~]</TD></TR>
      <TR><TD>
        <TABLE WIDTH="100%" CLASS="formfront">
          <TR>
            <TD ALIGN="left">
              <FONT CLASS="textsmall">[~Ahora debe subir un fichero de texto delimitado con las direcciones de e-mail a incluir en la lista.~]</FONT>
              <BR>
              <INPUT TYPE="file" CLASS="combomini" SIZE="40" NAME="emails">
              <BR>
              <TABLE>
                <TR>
                  <TD><FONT CLASS="textsmall">[~Delimitador~]</FONT></TD>
                  <TD ALIGN="right"><SELECT CLASS="combomini" NAME="sel_delimiter"><OPTION VALUE="," SELECTED>[~Coma (,)~]</OPTION><OPTION VALUE=";">[~Punto y Coma (;)~]</OPTION><OPTION VALUE="tab">[~Tabulador~]</OPTION><OPTION VALUE="|">[~Barra Vertical (|)~]</OPTION></SELECT></TD>
                </TR>
                <TR>
                  <TD COLSPAN="2">
                    <SELECT NAME="sel_encoding" CLASS="combomini">
                      <OPTION VALUE="UTF8">UTF-8</OPTION>
                      <OPTION VALUE="UTF-16">UTF-16</OPTION>
                      <OPTION VALUE="UnicodeBig">Sixteen-bit Unicode big endian with byte-order mark</OPTION>
                      <OPTION VALUE="UnicodeBigUnmarked">Sixteen-bit Unicode big endian</OPTION>
                      <OPTION VALUE="UnicodeLittle">Sixteen-bit Unicode little endian with byte-order mark</OPTION>
                      <OPTION VALUE="UnicodeLittleUnmarked">Sixteen-bit Unicode little endian</OPTION>
                      <OPTION VALUE="Cp1252">Windows Latin 1</OPTION>
                      <OPTION VALUE="ISO8859_1" <%=bLatinLanguage ? "SELECTED" : ""%>>ISO 8859-1 Latin 1</OPTION>
                      <OPTION VALUE="ISO8859_2">ISO 8859-1 Latin 2</OPTION>
                      <OPTION VALUE="ISO8859_3">ISO 8859-1 Latin 3</OPTION>
                      <OPTION VALUE="ISO8859_4">ISO 8859-1 Latin 4</OPTION>
                      <OPTION VALUE="ISO8859_5" <%=bRussianLanguage ? "SELECTED" : ""%>>ISO 8859-5, Latin/Cyrillic</OPTION>
                      <OPTION VALUE="ISO8859_6">ISO 8859-6, Latin/Arabic</OPTION>
                      <OPTION VALUE="ISO8859_7">ISO 8859-7, Latin/Greek</OPTION>
                      <OPTION VALUE="ISO8859_8">ISO 8859-8, Latin/Hebrew</OPTION>
                      <OPTION VALUE="JIS0201">JIS X 0201, Japanese</OPTION>
                      <OPTION VALUE="KOI8_R">KOI8-R, Russian</OPTION>
                      <OPTION VALUE="ASCII">ASCII</OPTION>
                      <OPTION VALUE="Cp437">MS-DOS</OPTION>
                      <OPTION VALUE="Cp500">EBCDIC 500V1</OPTION>
                      <OPTION VALUE="Big5" <%=bChineseTraditional ? "SELECTED" : ""%>>Big5 Traditional Chinese</OPTION>
                      <OPTION VALUE="MS936" <%=bChineseSimplified ? "SELECTED" : ""%>>MS936 Windows Simplified Chinese</OPTION>
                      <OPTION VALUE="MS950">MS950 Windows Traditional Chinese</OPTION>
                      <OPTION VALUE="MS932">MS932 Windows Japanese</OPTION>
                      <OPTION VALUE="MS874">MS874 Windows Thai</OPTION>
                    </SELECT>
                  </TD>
                </TR>
                <TR>
                  <TD><FONT CLASS="textsmall">[~Campos entre comillas~]</FONT></TD>
                  <TD><INPUT TYPE="radio" NAME="quotedfields">&nbsp;<FONT CLASS="textsmall">[~Si~]</FONT>&nbsp;&nbsp;&nbsp;<INPUT TYPE="radio" NAME="quotedfields" CHECKED>&nbsp;<FONT CLASS="textsmall">[~No~]</FONT></TD>
                </TR>
                <TR>
                  <TD><FONT CLASS="textsmall">[~Columna 1~]</FONT></TD>
                  <TD>
                    <SELECT CLASS="combomini" NAME="sel_column1">
                      <OPTION VALUE=""></OPTION>
                      <OPTION VALUE="tx_email" SELECTED>[~e-mail~]</OPTION>
                      <OPTION VALUE="tx_name">[~Nombre~]</OPTION>
                      <OPTION VALUE="tx_surname">[~Apellidos~]</OPTION>
                      <OPTION VALUE="tx_salutation">[~Saludo~]</OPTION>
                      <OPTION VALUE="unnamed">[~Otro~]</OPTION>
                    </SELECT>
                  </TD>
                <TR>
                  <TD><FONT CLASS="textsmall">[~Columna 2~]</FONT></TD>
                  <TD>
                    <SELECT CLASS="combomini" NAME="sel_column2">
                      <OPTION VALUE=""></OPTION>
                      <OPTION VALUE="tx_email">[~e-mail~]</OPTION>
                      <OPTION VALUE="tx_name" SELECTED>[~Nombre~]</OPTION>
                      <OPTION VALUE="tx_surname">[~Apellidos~]</OPTION>
                      <OPTION VALUE="tx_salutation">[~Saludo~]</OPTION>
                      <OPTION VALUE="unnamed">[~Otro~]</OPTION>
                    </SELECT>
                  </TD>
                </TR>
                <TR>
                  <TD><FONT CLASS="textsmall">[~Columna 3~]</FONT></TD>
                  <TD>
                    <SELECT CLASS="combomini" NAME="sel_column3">
                      <OPTION VALUE=""></OPTION>
                      <OPTION VALUE="tx_email">[~e-mail~]</OPTION>
                      <OPTION VALUE="tx_name">[~Nombre~]</OPTION>
                      <OPTION VALUE="tx_surname" SELECTED>[~Apellidos~]</OPTION>
                      <OPTION VALUE="tx_salutation">[~Saludo~]</OPTION>
                      <OPTION VALUE="unnamed">Otro</OPTION>
                    </SELECT>
                  </TD>
                </TR>
                <TR>
                  <TD><FONT CLASS="textsmall">[~Columna 4~]</FONT></TD>
                  <TD>
                    <SELECT CLASS="combomini" NAME="sel_column4">
                      <OPTION VALUE="" SELECTED></OPTION>
                      <OPTION VALUE="tx_email">[~e-mail~]</OPTION>
                      <OPTION VALUE="tx_name">[~Nombre~]</OPTION>
                      <OPTION VALUE="tx_surname">[~Apellidos~]</OPTION>
                      <OPTION VALUE="tx_salutation">[~Saludo~]</OPTION>
                      <OPTION VALUE="unnamed">[~Otro~]</OPTION>
                    </SELECT>
                  </TD>
                </TR>
              </TABLE>
            </TR>
          </TD>
        </TABLE>
      </TD>
     </TR>
    </TABLE>
    <TABLE SUMMARY="Buttons"><TR><TD ALIGN="center"><INPUT TYPE="button" CLASS="closebutton" VALUE="[~Cancelar~]" STYLE="width:100px" onClick="self.close()">&nbsp;<INPUT TYPE="button" CLASS="pushbutton" VALUE="[~<< Anterior~]" STYLE="width:100px" onClick="document.forms[0].action='list_wizard_01.jsp';document.forms[0].submit()">&nbsp;<INPUT TYPE="submit" CLASS="pushbutton" VALUE="[~Siguiente >>~]" STYLE="width:100px"></TD></TR></TABLE>
  </FORM>
</BODY>
</HTML>
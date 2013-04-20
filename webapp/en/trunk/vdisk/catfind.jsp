<%@ page import="java.util.LinkedList,java.util.ListIterator,java.net.URLDecoder,java.lang.StringBuffer,java.sql.SQLException,java.sql.ResultSet,com.knowgate.jdc.*,com.knowgate.acl.*,com.knowgate.dataobjs.*,com.knowgate.hipergate.*,com.knowgate.misc.Gadgets" language="java" session="false" contentType="text/html;charset=UTF-8" %>
<%@ include file="../methods/dbbind.jsp" %><%@ include file="../methods/cookies.jspf" %><%@ include file="../methods/nullif.jspf" %><%

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
  
  // Obtener el skin actual
  String sSkin = getCookie(request, "skin", "default");
  String sLanguage = getNavigatorLanguage(request);
  
  String tx_sought = request.getParameter("tx_sought");
  
  String id_user = getCookie (request, "userid", null);
  String id_domain = getCookie(request,"domainid","");
  String n_domain = getCookie(request,"domainnm",""); 

    
  int iProdCount = 0;
  int iCatCount = 0;
  String sOrderBy;
  int iOrderBy;  
  int iMaxRows;
  int iSkip;

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

  if (request.getParameter("orderby")!=null)
    sOrderBy = request.getParameter("orderby");
  else
    sOrderBy = "";
  
  if (sOrderBy.length()>0)
    iOrderBy = Integer.parseInt(sOrderBy);
  else
    iOrderBy = 0;
  
  String sLbl;
  
  DBSubset oCatg = new DBSubset (DB.k_categories + " c," + DB.k_cat_labels + " l",
  				 "c." + DB.gu_category +",c." + DB.nm_category + ",l." + DB.tr_category + ",c." + DB.dt_modified, 
				 "c." + DB.gu_owner + "=? AND l." + DB.tr_category + " " + DBBind.Functions.ILIKE + " ?", 100);
				   				 
  DBSubset oProd = null;
    
  JDCConnection oConn = GlobalDBBind.getConnection("catfind");  

  try {    
    Object aParams[] = { id_user, "%" + tx_sought + "%" };

    if (oConn.getDataBaseProduct()==JDCConnection.DBMS_MYSQL)
      oProd = new DBSubset (DB.k_products + " p, " + DB.k_prod_locats + " l, " + DB.k_x_cat_objs + " x",
  		            "p." + DB.gu_product +",p." + DB.nm_product + ",p." + DB.de_product + ",p." + DB.dt_modified + ",CONCAT(l." + DB.xprotocol + ",l." + DB.xhost + ",COALESCE(l." + DB.xpath + ",''),COALESCE(l." + DB.xanchor + ",'')), l." + DB.id_cont_type + ",l." + DB.len_file + ",x." + DB.gu_category,
  			    "p." + DB.gu_product + "=x." + DB.gu_object + " AND l." + DB.gu_product + "=x." + DB.gu_object + " AND p." + DB.gu_owner + "=? AND p." + DB.nm_product + " " + DBBind.Functions.ILIKE + " ? AND x." + DB.id_class + "=15", 100);  
    else
      oProd = new DBSubset (DB.k_products + " p, " + DB.k_prod_locats + " l, " + DB.k_x_cat_objs + " x",
  		            "p." + DB.gu_product +",p." + DB.nm_product + ",p." + DB.de_product + ",p." + DB.dt_modified + ",l." + DB.xprotocol + DBBind.Functions.CONCAT + "l." + DB.xhost + DBBind.Functions.CONCAT + DBBind.Functions.ISNULL + "(l." + DB.xpath + ",'')" + DBBind.Functions.CONCAT + DBBind.Functions.ISNULL + "(l." + DB.xanchor + ",''), l." + DB.id_cont_type + ",l." + DB.len_file + ",x." + DB.gu_category,
  			    "p." + DB.gu_product + "=x." + DB.gu_object + " AND l." + DB.gu_product + "=x." + DB.gu_object + " AND p." + DB.gu_owner + "=? AND p." + DB.nm_product + " " + DBBind.Functions.ILIKE + " ? AND x." + DB.id_class + "=15", 100);  
    
    iProdCount = oProd.load (oConn, aParams);

    // Category find disabled
    // iCatCount  = oCatg.load (oConn, aParams);
            
    oConn.close("catfind"); 
  }
  catch (SQLException e) {
    oConn.close("catfind"); 
    response.sendRedirect (response.encodeRedirectUrl ("../common/errmsg.jsp?title=Error de Acceso a la Base de Datos&desc=" + e.getLocalizedMessage() + "&resume=_back"));
  }
  oConn = null;

  response.addHeader ("Pragma", "no-cache");
  response.addHeader ("cache-control", "no-store");
  response.setIntHeader("Expires", 0);

%>
  
  <!-- +-----------------------+ -->
  <!-- | Búsqueda de productos | -->
  <!-- | © KnowGate 2003       | -->
  <!-- +-----------------------+ -->
<HTML LANG="<% out.write(sLanguage); %>">
  <HEAD>
    <TITLE>hipergate :: Search Results</TITLE>
    <SCRIPT SRC="../javascript/cookies.js"></SCRIPT>  
    <SCRIPT SRC="../javascript/setskin.js"></SCRIPT>
  </HEAD>
  
  <BODY  TOPMARGIN="4" MARGINHEIGHT="4">
    <TABLE WIDTH="98%" CELLSPACING="4">
      <TR>
        <TD CLASS="striptitle">
          <FONT CLASS="title1">Search Results</FONT>
        </TD>      
      </TR>  
    </TABLE>
    
    <FORM METHOD="post" TARGET="catexec">              
      <TABLE CELLPADDING="2" CELLPADDING="0">
        <TR>
          <TD CLASS="tableheader" WIDTH="20" BACKGROUND="../skins/<%=sSkin%>/tablehead.gif">&nbsp;</TD>
          <TD CLASS="tableheader" BACKGROUND="../skins/<%=sSkin%>/tablehead.gif">Name</TD>
          <TD CLASS="tableheader" BACKGROUND="../skins/<%=sSkin%>/tablehead.gif">Modified</TD>
          <TD CLASS="tableheader" BACKGROUND="../skins/<%=sSkin%>/tablehead.gif">&nbsp;</TD>
        </TR>
<%
          
          String sFileLen,sProdDesc; 
          int iRows = oProd.getRowCount();
          StringBuffer sBuffer = new StringBuffer(640*iRows);
          
            for (int iRow=0; iRow<iRows; iRow++) {            
              if (oProd.get(6,iRow)!=null) 
                sFileLen = " " + String.valueOf(oProd.getInt(6,iRow) + " bytes");
              else
                sFileLen = "";
              
              sBuffer.append("        <TR><TD ALIGN='middle' CLASS='tabletd'><A HREF='");
              switch (oProd.getInt(5,iRow)) {
	        case 1:
	        case 4:	        
                  sBuffer.append("../servlet/HttpBinaryServlet?id_product=" + oProd.getString(0,iRow) + "&id_user=" + id_user);
            	  sBuffer.append("' TARGET='_blank'><IMG SRC='../images/images/download.gif' BORDER='0' ALT='Download/Open" + sFileLen + "'></A></TD><TD CLASS='tabletd'>");
                  break;
                case 2: 
                case 3: 
                  sBuffer.append(oProd.getString(4,iRow));
            	  sBuffer.append("' TARGET='_blank'><IMG SRC='../images/images/wlink.gif' WIDTH='16' HEIGHT='16' BORDER='0' ALT='Open in new window'></A></TD><TD CLASS='tabletd'>");
                  break;
              }
              sBuffer.append(oProd.getString(1,iRow));
              sBuffer.append("</TD><TD CLASS='tabletd'>");
              sBuffer.append(nullif(oProd.getDateTime(3,iRow)));
              sBuffer.append("</TD><TD>");
              sBuffer.append("<A HREF=\"catprods.jsp?id_category=" + oProd.getString(7,iRow) + "\"><IMG SRC=\"../skins/"+sSkin+"/nav/folderclosed_16x16.gif\" BORDER=\"0\"></A>");
              sBuffer.append("</TD></TR>\n");

	      if (null!=oProd.get(2,iRow)) {
                sProdDesc = oProd.getString(2,iRow);
                if (sProdDesc.length()>100) sProdDesc = sProdDesc.substring(0,100) + "...";
                sBuffer.append("        <TR><TD></TD><TD CLASS='tabletd' COLSPAN='2'><FONT CLASS='textsmall'>" + sProdDesc + "</FONT></TD><TD></TD></TR>\n");
	      }
	      
            } // next (iRow)
          
	    out.write(sBuffer.toString());
        %>
      </TABLE>
    </FORM>
  </BODY>
</HTML>

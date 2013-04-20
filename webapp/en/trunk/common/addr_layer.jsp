<%@ page import="java.net.URLDecoder,java.util.HashMap,java.sql.SQLException,com.knowgate.jdc.*,com.knowgate.acl.*,com.knowgate.dataobjs.*,com.knowgate.misc.Gadgets,com.knowgate.hipergate.Address,com.knowgate.hipergate.RecentlyUsed" language="java" session="false" contentType="text/html;charset=UTF-8" %>
<%@ include file="../methods/dbbind.jsp" %><%@ include file="../methods/nullif.jspf" %><%@ include file="../methods/cookies.jspf" %><jsp:useBean id="GlobalDBLang" scope="application" class="com.knowgate.hipergate.DBLanguages"/><%
/*
  Copyright (C) 2003-2008  Know Gate S.L. All rights reserved.
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

  final int Hipermail=21;

  final int iAppMask = Integer.parseInt(getCookie(request, "appmask", "0"));
 
  response.addHeader ("Pragma", "no-cache");
  response.addHeader ("cache-control", "no-store");
  response.setIntHeader("Expires", 0);

  String sAddrId;
  String sAddrTp;
  String sAddrTv;
  String sAddrSt;
  String sAddrNu;
  String sAddrZp;    
  String sAddrCt;
  String sAddrEm;
  Object oAddrPh;
  String sResult = "";

  String sErrMsg = "";
  String sLanguage = getNavigatorLanguage(request);

  String id_domain = getCookie(request,"domainid","");
  String n_domain = getCookie(request,"domainnm",""); 
  String gu_workarea = getCookie(request,"workarea",null); 
  String gu_user = getCookie(request,"userid",null); 
  
  String sLinkTable = request.getParameter("linktable")==null ? "" : request.getParameter("linktable");
  String sLinkField = request.getParameter("linkfield")==null ? "" : request.getParameter("linkfield");
  String sLinkValue = request.getParameter("linkvalue")==null ? "" : request.getParameter("linkvalue");
  
  HashMap oLocationTypes = null;
          
  int iAddressCount = 0;
  DBSubset oAddresses = null;        
  int iMaxRows = 4;
    
  JDCConnection oConn = GlobalDBBind.getConnection("addresspopup");  
    
  try {
    oAddresses = new DBSubset (DB.k_addresses + " a," + sLinkTable + " x",
      			       "a." + DB.gu_address + ",a." + DB.tp_location + ",a." + DB.tp_street + ",a." + DB.nm_street + ",a." + DB.nu_street + ",a." + DB.zipcode + ",a." + DB.mn_city + ",a." + DB.tx_email + ",a." + DB.work_phone + ",a." + DB.direct_phone + ",a." + DB.home_phone + ",a." + DB.mov_phone + ",a." + DB.fax_phone + ",a." + DB.nm_company,
      			       "x." + sLinkField + "='" + sLinkValue + "' AND a." + DB.gu_address + "=x." + DB.gu_address, iMaxRows);
    oAddresses.setMaxRows(iMaxRows);
    iAddressCount = oAddresses.load (oConn);
    
    // Cargar un mapa de códigos y etiquetas traducidas de tipos de ubicacion
    oLocationTypes = GlobalDBLang.getLookUpMap((java.sql.Connection) oConn, DB.k_addresses_lookup, gu_workarea, "tp_location", sLanguage);

    RecentlyUsed oRecent;
    DBPersist oItem;
    
    if (iAddressCount>0) {
      if (sLinkTable.equals(DB.k_x_company_addr)) {

        oRecent = new RecentlyUsed (DB.k_companies_recent, 10, DB.gu_company, DB.gu_user);

	oItem = new DBPersist (DB.k_companies_recent, "RecentCompany");

	oItem.put (DB.gu_company, sLinkValue);
	oItem.put (DB.gu_user, gu_user);
	oItem.put (DB.gu_workarea, gu_workarea);
	
	oItem.put (DB.nm_company, oAddresses.getStringNull(DB.nm_company, 0, ""));

	if (!oAddresses.isNull(DB.work_phone, 0))
	  oItem.put (DB.work_phone, oAddresses.get(DB.work_phone,0));

	if (!oAddresses.isNull(DB.tx_email, 0))
	  oItem.put (DB.tx_email, oAddresses.getString(DB.tx_email,0));
	  
	oRecent.add (oConn, oItem);
      }
      else if (sLinkTable.equals(DB.k_x_contact_addr)) {
        
        oRecent = new RecentlyUsed (DB.k_contacts_recent, 10, DB.gu_contact, DB.gu_user);

	oItem = new DBPersist (DB.k_contacts_recent, "RecentContact");
	
	DBPersist oCont = new DBPersist (DB.k_contacts, "Contact");
	oCont.load (oConn, new Object[]{sLinkValue});
	
	oItem.put (DB.gu_contact, oCont.getString(DB.gu_contact));
	oItem.put (DB.full_name, oCont.getStringNull(DB.tx_name,"") + " " + oCont.getStringNull(DB.tx_surname,""));
	oItem.put (DB.gu_user, gu_user);
	oItem.put (DB.gu_workarea, gu_workarea);	
	oItem.put (DB.nm_company, nullif(request.getParameter("nm_company")));

	if (!oAddresses.isNull(DB.work_phone, 0))
	  oItem.put (DB.work_phone, oAddresses.get(DB.work_phone,0));

	if (!oAddresses.isNull(DB.tx_email, 0))
	  oItem.put (DB.tx_email, oAddresses.get(DB.tx_email,0));
	  
	oRecent.add (oConn, oItem);
      }
    } // fi (iAddressCount>0)
 
    oConn.close("addresspopup"); 
  }
  catch (SQLException e) {  
    oAddresses = null;
    if (oConn!=null)
      if (!oConn.isClosed())
        oConn.close("addresspopup");
    sErrMsg = "../common/errmsg.jsp?title=SQLException&desc=" + e.getMessage() + "&resume=_close";
  }
  catch (ArrayIndexOutOfBoundsException e) {  
    oAddresses = null;
    if (oConn!=null)
      if (!oConn.isClosed())
        oConn.close("addresspopup");
    sErrMsg = "../common/errmsg.jsp?title=ArrayIndexOutOfBoundsException&desc=" + e.getMessage() + "&resume=_close";
  }
  oConn = null;  

  if (sErrMsg.length()==0) {    
    for (int i=0; i<iAddressCount; i++) {
      
      sAddrId = oAddresses.getString(0,i);
      sAddrTp = (String) oAddresses.get(1,i);
      sAddrTv = (String) oAddresses.get(2,i);    

      if (null!=sAddrTp) sAddrTp = (String) oLocationTypes.get(sAddrTp);              
      sAddrSt = oAddresses.getStringNull(3,i,"* N/A *");
      sAddrNu = oAddresses.getStringNull(4,i,"");
      sAddrZp = oAddresses.getStringNull(5,i,"");
      sAddrCt = oAddresses.getStringNull(6,i,"");      
      sAddrEm = oAddresses.getStringNull(7,i,"");

			if (sAddrEm.length()>0)  {
			  if (((iAppMask & (1<<Hipermail))!=0)) {
          if (sLinkTable.equals(DB.k_x_contact_addr))
            sAddrEm = "<A HREF=\"../hipermail/msg_new_f.jsp?folder=drafts&to="+sAddrEm+"&gu_contact="+sLinkValue+"\" TARGET=\"_blank\" TITLE=\"Send Message\">" + sAddrEm + "</A>";
					else
            sAddrEm = "<A HREF=\"../hipermail/msg_new_f.jsp?folder=drafts&to="+sAddrEm+"\" TARGET=\"_blank\" TITLE=\"Send Message\">" + sAddrEm + "</A>";						
		    } else {
          sAddrEm = "<A HREF=\"mailto:" + sAddrEm + "\" TITLE=\"Send Message\">" + sAddrEm + "</A>";
        }
      }

      if (null!=sAddrTp) sResult += "Address Type" + sAddrTp + "<BR>";

			Address oAddr = new Address();
			oAddr.putAll(oAddresses.getRowAsMap(i));
			sResult += Gadgets.HTMLEncode(oAddr.toLocaleString()) + "<BR>";

      if (!oAddresses.isNull(3,i) && GlobalDBBind.getProperty("googlemapskey","").length()>0) {
			  sResult += "<A HREF=\"#\" onclick=\"addrIFrame.showGoogleMap("+String.valueOf(i)+")\">Map</A>&nbsp;";
      }

      sResult += sAddrEm+"<BR>";
      
      oAddrPh = oAddresses.get(8,i);
      sResult += (oAddrPh==null ? "" : "PBX " + oAddrPh + "<BR>");
      oAddrPh = oAddresses.get(9,i);
      sResult += (oAddrPh==null ? "" : "Direct Phone" + oAddrPh + "<BR>");
      oAddrPh = oAddresses.get(10,i);
      sResult += (oAddrPh==null ? "" : "Personal Phone" + oAddrPh + "<BR>");
      oAddrPh = oAddresses.get(11,i);
      if (oAddrPh!=null) {
        if (GlobalDBBind.getProperty("smsprovider","").length()==0)
          sResult += "Mobile Phone" + oAddrPh + "<BR>";
				else
          sResult += "Mobile Phone <A HREF=\"#\" onclick=\"addrIFrame.sendSms("+String.valueOf(i)+")\">" + oAddrPh + "</A><BR>";
      }
      oAddrPh = oAddresses.get(12,i);
      sResult += (oAddrPh==null ? "" : "Fax" + oAddrPh + "<BR>");
    } // next(i)
  } // fi(sErrMsg)
%>
<HTML>
<HEAD>
  <TITLE>hipergate :: Address</TITLE>
  <LINK REL="stylesheet" TYPE="text/css" HREF="../skins/xp/styles.css" />
  <SCRIPT TYPE="text/javascript">
    <!--
      var nums = new Array(<% for (int i=0; i<iAddressCount; i++) out.write((i>0 ? "," : "")+"\""+Gadgets.URLEncode(oAddresses.getStringNull(11,i,""))+"\""); %>);
      var guids= new Array(<% for (int i=0; i<iAddressCount; i++) out.write((i>0 ? "," : "")+"\""+oAddresses.getString(0,i)+"\""); %>);

      function sendSms(a) {
      	var qry = "?nu_msisdn="+nums[a]+"&gu_address="+guids[a];
<%      if (sLinkTable.equals(DB.k_x_contact_addr)) { %>
				  qry += "&gu_contact=<%=sLinkValue%>";
<%      } else if (sLinkTable.equals(DB.k_x_company_addr)) { %>
				  qry += "&gu_company=<%=sLinkValue%>";
<%      }  %>
	
				window.open("../common/sms_edit.jsp"+qry,null,"directories=no,toolbar=no,scrollbars=yes,menubar=no,width=400,height=320");
      }
    //-->
  </SCRIPT>
</HEAD>
<BODY marginheight="0" marginwidth="0" topmargin="0" leftmargin="0" class="textsmall">
  <SCRIPT type="text/javascript">

    var aGuids = new Array(<% for (int i=0; i<iAddressCount; i++) { out.write((0==i ? "" : ",")+"\""+oAddresses.getString(0,i)+"\""); } %>);
    parent.addrLayer.setHTML('<table bgcolor="floralwhite" cellpadding="4" cellspacing="0" width="200" border="1"><tr height="100"><td valign="top" class="textsmall"><%=sResult%><br><a href="javascript:hideDiv()">Close</a></td></tr></table>');
    parent.addrLayer.setVisible(true);
    parent.document.body.style.cursor = "default";
    
    function showGoogleMap(n) {
    	window.open("../common/google_map.jsp?gu_address="+aGuids[n],"google_map_"+aGuids[n],"directories=no,toolbar=no,scrollbars=yes,menubar=no,width=540,height=400");
    }

  </SCRIPT>
</BODY>
</HTML>
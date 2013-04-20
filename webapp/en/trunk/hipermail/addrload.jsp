<%@ page import="java.net.URLDecoder,java.sql.SQLException,com.knowgate.acl.*,com.knowgate.jdc.JDCConnection,com.knowgate.dataobjs.DB,com.knowgate.dataobjs.DBBind,com.knowgate.dataobjs.DBSubset,com.knowgate.misc.Environment,com.knowgate.misc.Gadgets,com.knowgate.debug.DebugFile,com.knowgate.hipergate.QueryByForm,com.knowgate.crm.DistributionList" language="java" session="false" contentType="text/html;charset=UTF-8" %>
<%@ include file="../methods/dbbind.jsp" %><%@ include file="../methods/cookies.jspf" %><%@ include file="../methods/authusrs.jspf" %><%@ include file="../methods/nullif.jspf" %>
<%
/*
  Copyright (C) 2004  Know Gate S.L. All rights reserved.
                      C/Oña 107 1º2 28050 Madrid (Spain)

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

  final int MAXROWS = 1000;

  String id_domain = getCookie(request,"domainid","");
  String id_user = getCookie (request, "userid", null); 
  String gu_workarea = getCookie (request, "workarea", null);
  String gu_list = request.getParameter("gu_list");
  String gu_query = request.getParameter("gu_query");
  String tx_search = request.getParameter("tx_search");
  int tp_list = Integer.parseInt(request.getParameter("tp_list"));
  int iSkip = Integer.parseInt(nullif(request.getParameter("nu_skip"),"0"));

  JDCConnection oConn = null;
  DBSubset oContacts = null;
  DBSubset oUsers = null;
  DBSubset oLists = null;
  QueryByForm oQBF = null;
  Object[] aParams = null;
  
  if (tx_search.length()>0) {
    oContacts = new DBSubset (DB.k_member_address, DBBind.Functions.ISNULL+"("+DB.tx_name+","+DB.nm_commercial+"),"+DB.tx_surname+","+DB.tx_email,
  			      DB.tx_email + " IS NOT NULL AND " + DB.gu_workarea+"=? AND ("+DB.bo_private+"=0 OR "+DB.gu_writer+"=?) AND ("+
  			      DB.tx_name+" " + DBBind.Functions.ILIKE + " ? OR "+DB.tx_surname+" " + DBBind.Functions.ILIKE + " ?) ORDER BY 1,2", 500);
    aParams = new Object[]{gu_workarea,id_user,"%"+tx_search+"%","%"+tx_search+"%"};
    oUsers = new DBSubset (DB.k_users, DB.nm_user+","+DB.tx_surname1+","+DB.tx_surname2+","+DB.tx_main_email,
  		           DB.tx_main_email + " IS NOT NULL AND " + DB.id_domain+"=? AND "+DB.bo_active+"<>0 AND ("+
  			   DB.nm_user+" " + DBBind.Functions.ILIKE + " ? OR "+DB.tx_surname1+" " + DBBind.Functions.ILIKE + " ?) ORDER BY 1,2", 500);  		           
  }
  else if (gu_list.length()==0) {
    oContacts = new DBSubset (DB.k_member_address, DBBind.Functions.ISNULL+"("+DB.tx_name+","+DB.nm_commercial+"),"+DB.tx_surname+","+DB.tx_email,
  			      DB.tx_email + " IS NOT NULL AND " + DB.gu_workarea+"=? AND ("+DB.bo_private+"=0 OR "+DB.gu_writer+"=?) ORDER BY 1,2", 500);
    aParams = new Object[]{gu_workarea,id_user};
    oUsers = new DBSubset (DB.k_users, DB.nm_user+","+DB.tx_surname1+","+DB.tx_surname2+","+DB.tx_main_email,
  		           DB.tx_main_email + " IS NOT NULL AND " + DB.id_domain+"=? AND "+DB.bo_active+"<>0 ORDER BY 1,2,3", 500);
    oLists = new DBSubset (DB.k_lists, DB.gu_list+","+DB.de_list,DB.gu_workarea+"=? AND "+DB.tp_list+"<>4 AND "+DB.de_list+" IS NOT NULL ORDER BY 2", 20);
  }
  else if (gu_list.equals("domainusers")) {
    oContacts = new DBSubset (DB.k_users, DB.nm_user+","+DB.tx_surname1+","+DB.tx_main_email,
  			      DB.tx_main_email + " IS NOT NULL AND " + DB.id_domain+"=? AND "+DB.bo_active+"<>0 ORDER BY 1,2,3", 500);
    aParams = new Object[]{new Integer(id_domain)}; 
  }
  else {
    switch (tp_list) {
      case DistributionList.TYPE_DYNAMIC:
        oQBF = new QueryByForm(oConn, DB.k_member_address, "ma", gu_query);

        oContacts = new DBSubset (DB.k_member_address + " ma",
        			  DBBind.Functions.ISNULL+"(ma."+DB.tx_name+",ma."+DB.nm_commercial+"),ma."+DB.tx_surname+",ma."+DB.tx_email,
  			          "ma."+DB.tx_email + " IS NOT NULL AND ma." + DB.gu_workarea+"=? AND (ma."+DB.bo_private+"=0 OR ma."+DB.gu_writer+"=?) AND ("+
  			          oQBF.composeSQL() + ") AND NOT EXISTS (SELECT x."+DB.tx_email+" FROM "+DB.k_lists+" b,"+DB.k_x_list_members+" x WHERE "+
  			          "b."+DB.gu_list+"=x."+DB.gu_list+" AND b."+DB.gu_query+"=? AND b."+DB.tp_list+"="+String.valueOf(DistributionList.TYPE_BLACK)+
  			          " AND x."+DB.tx_email+"=ma."+DB.tx_email+") ORDER BY 1,2", 500);
    	aParams = new Object[]{gu_workarea,id_user,gu_list};
  	break;
      case DistributionList.TYPE_STATIC:
      case DistributionList.TYPE_DIRECT:
        oContacts = new DBSubset (DB.k_x_list_members + " lm",
			          DBBind.Functions.ISNULL+"(lm."+DB.tx_name+",''),lm."+DB.tx_surname+",lm."+DB.tx_email,
  			          "lm."+DB.gu_list+"=? AND "+
  			          " NOT EXISTS (SELECT x."+DB.tx_email+" FROM "+DB.k_lists+" b,"+DB.k_x_list_members+" x WHERE "+
  			          "b."+DB.gu_list+"=x."+DB.gu_list+" AND b."+DB.gu_query+"=? AND b."+DB.tp_list+"="+String.valueOf(DistributionList.TYPE_BLACK)+
  			          " AND x."+DB.tx_email+"=lm."+DB.tx_email+") ORDER BY 1,2", 500);
    	aParams = new Object[]{gu_list,gu_list};
    }    
  }

  int iContacts=0, iUsers=0, iLists=0;

  try {
    oConn = GlobalDBBind.getConnection("addrload");  

    oContacts.setMaxRows(1000);    
    iContacts = oContacts.load(oConn, aParams, iSkip);
    
    if (tx_search.length()>0) {
      oUsers.setMaxRows(MAXROWS);
      iUsers = oUsers.load(oConn, new Object[]{new Integer(id_domain),"%"+tx_search+"%","%"+tx_search+"%"}, iSkip);
    }
    else if (gu_list.length()==0) {
      oUsers.setMaxRows(MAXROWS);    
      iUsers = oUsers.load(oConn, new Object[]{new Integer(id_domain)}, iSkip);
      iLists = oLists.load(oConn, new Object[]{gu_workarea});
    }

    oConn.close("addrload");  
  }
  catch (SQLException e) {
   if (oConn!=null)
      if (!oConn.isClosed()) oConn.close("addrload");
    oConn = null;
    response.sendRedirect (response.encodeRedirectUrl ("../common/errmsg.jsp?title=SQLException&desc=" + e.getMessage() + "&resume=_close"));  
  }
  catch (NumberFormatException e) {
   if (oConn!=null)
      if (!oConn.isClosed()) oConn.close("addrload");
    oConn = null;
    response.sendRedirect (response.encodeRedirectUrl ("../common/errmsg.jsp?title=NumberFormatException&desc=" + e.getMessage() + "&resume=_close"));  
  }
  
  if (null==oConn) return;
  oConn = null;
%>
<HTML>
  <HEAD>
  <SCRIPT TYPE="text/javascript" SRC="../javascript/cookies.js"></SCRIPT> 
  <SCRIPT TYPE="text/javascript"> 
    var lst = window.parent.frames[0].document.forms[0].sel_addrbook;
    var opt = lst.options;
    
    for (var i=opt.length-1; i>=0; i--)  
      opt[i] = null;
<% 
   int iContactIndex=0, iUserIndex=0;
   String sContactName, sUserName;
   
   if (iLists>0) {
     for (int l=0; l<iLists; l++) {
       out.write("opt[opt.length] = new Option(\"{ "+oLists.getString(1,l)+" }\", \"list@"+oLists.getString(0,l)+".list\", false, false);\n");     
     } // next
   }
   
   if (iUsers>0) {
     do {
       if (iContactIndex<iContacts)
         sContactName = oContacts.getStringNull(0,iContactIndex,"")+" "+oContacts.getStringNull(1,iContactIndex,"");
       else
         sContactName = null;
  
       if (iUserIndex<iUsers)
         sUserName = oUsers.getStringNull(0,iUserIndex,"")+" "+oUsers.getStringNull(1,iUserIndex,"")+" "+oUsers.getStringNull(2,iUserIndex,"");
       else
         sUserName = null;
       
       if ((sContactName==null) && (sUserName!=null)) {
         out.write("opt[opt.length] = new Option(\""+sUserName+" <"+oUsers.getString(3,iUserIndex)+">\", \""+oUsers.getString(3,iUserIndex)+"\", false, false);\n");
         iUserIndex++;
       }
       else if ((sContactName!=null) && (sUserName==null)) {
         out.write("opt[opt.length] = new Option(\""+sContactName+" <"+oContacts.getString(2,iContactIndex)+">\", \""+oContacts.getString(2,iContactIndex)+"\", false, false);\n");
         iContactIndex++;
       }
       else if ((sContactName!=null) && (sUserName!=null)) {
         if (sContactName.compareTo(sUserName)<0) {
           out.write("opt[opt.length] = new Option(\""+sContactName+" <"+oContacts.getString(2,iContactIndex)+">\", \""+oContacts.getString(2,iContactIndex)+"\", false, false);\n");
           iContactIndex++;
         }
         else {
           out.write("opt[opt.length] = new Option(\""+sUserName+" <"+oUsers.getString(3,iUserIndex)+">\", \""+oUsers.getString(3,iUserIndex)+"\", false, false);\n");
           iUserIndex++;
         }
       }
     } while ((sContactName!=null) || (sUserName!=null));
   }
   else {
     for (int c=0; c<iContacts; c++) {
       sContactName = oContacts.getStringNull(0,c,"")+" "+oContacts.getStringNull(1,c,"");
       out.write("opt[opt.length] = new Option(\""+sContactName+" <"+oContacts.getString(2,c)+">\", \""+oContacts.getString(2,c)+"\", false, false);\n");     
     } // next
   } // fi (gu_list=="")
%>
  </SCRIPT>
  </HEAD>
</HTML>
<%@ page import="java.sql.SQLException,com.knowgate.jdc.JDCConnection,com.knowgate.dataobjs.DB,com.knowgate.dataobjs.DBSubset,com.knowgate.crm.DistributionList" language="java" session="false" contentType="text/plain;charset=UTF-8" %><%@ include file="../methods/dbbind.jsp" %><%@ include file="../methods/cookies.jspf" %><%@ include file="../methods/authusrs.jspf" %><% 
/*
  Copyright (C) 2003-2010  Know Gate S.L. All rights reserved.
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

  final String PAGE_NAME = "lists_x_category";
  final String gu_workarea = getCookie(request,"workarea","");

  JDCConnection oConn = null;  
  String sCategs = "'"+request.getParameter("gu_category")+"'";
  DBSubset oLists = null;  
  int nLists = 0;
  try {
    oConn = GlobalDBBind.getConnection(PAGE_NAME);
    
    DBSubset oChlds = new DBSubset (DB.k_cat_expand, DB.gu_category, DB.gu_rootcat+"=?", 20);
    int iChlds = oChlds.load(oConn, new Object[]{request.getParameter("gu_category")});
    for (int c=0; c<iChlds; c++) {
      sCategs += ",'"+oChlds.getString(0,c)+"'";
    }

    oLists = new DBSubset (DB.k_lists+" l,"+DB.k_x_cat_objs+" c", 
      			               "l.gu_list,l.tx_subject,l.de_list",
      			               "l."+DB.gu_list+"=c."+DB.gu_object+" AND c."+DB.id_class+"="+String.valueOf(DistributionList.ClassId)+" AND "+
      			               "c."+DB.gu_category+" IN ("+sCategs+") AND "+
      		                 "l."+DB.tp_list + "<>" + String.valueOf(DistributionList.TYPE_BLACK) + " AND l." + DB.gu_workarea + "='" + gu_workarea + "' ORDER BY 3", 500);
	  nLists = oLists.load(oConn);

    oConn.close(PAGE_NAME);
  }
  catch (Exception e) {  
    disposeConnection(oConn,PAGE_NAME);
    oConn = null;
    response.sendRedirect (response.encodeRedirectUrl ("../common/errmsg.jsp?title=Error&"+e.getClass().getName()+"=" + e.getMessage() + "&resume=_close"));  
  }
  
  if (null==oConn) return;    
  oConn = null;

  for (int l=0; l<nLists; l++) {
    out.write(oLists.getString(0,l)+"¨"+oLists.getStringNull(1,l,"").replace('"',' ').replace('\n',' ')+"¨"+oLists.getStringNull(2,l,"").replace('"',' ').replace('\n',' '));
    if (l<nLists-1) out.write("`");
  }
%>
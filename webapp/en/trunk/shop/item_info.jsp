<%@ page import="com.knowgate.dataobjs.DB,com.knowgate.dataobjs.DBBind,com.knowgate.dataobjs.DBCommand,com.knowgate.dataobjs.DBSubset,com.knowgate.jdc.JDCConnection,com.knowgate.misc.Gadgets" language="java" session="false" contentType="text/plain;charset=UTF-8" %><%@ include file="../methods/dbbind.jsp" %><%@ include file="../methods/cookies.jspf" %><%@ include file="../methods/authusrs.jspf" %><%
/*

  Copyright (C) 2010  Know Gate S.L. All rights reserved.
                      C/O🪠107 1º2 28050 Madrid (Spain)

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

  String gu_product = request.getParameter("gu_product");

  JDCConnection oCon = null;
  DBSubset oPrd = new DBSubset(DB.k_products+" p,"+DB.k_x_cat_objs+" x,"+DB.k_cat_expand+" e,"+DB.k_shops+" s",
    										       "p."+DB.gu_product+",p."+DB.nm_product+","+DBBind.Functions.ISNULL+"(p."+DB.de_product+",''),"+DBBind.Functions.ISNULL+"(p."+DB.id_ref+",''),"+
    										       "p."+DB.dt_start+",p."+DB.dt_end+",p."+DB.pr_list+",p."+DB.pr_sale+",p."+DB.pr_discount+","+
    										       "x."+DB.gu_category,
  											       "s."+DB.gu_root_cat+"=e."+DB.gu_rootcat+" AND "+
  											       "e."+DB.gu_category+"=x."+DB.gu_category+" AND x."+DB.gu_object+"=p."+DB.gu_product+" AND "+
  											       "p."+DB.gu_product+"=?", 1);

  try {
    oCon = GlobalDBBind.getConnection("item_info");

	  oPrd.load(oCon, new Object[]{gu_product});

    oCon.close("item_info");
  }
  catch (Exception e) {
    if (oCon!=null)
      if (!oCon.isClosed()) {
        oCon.close("item_info");      
      }
    oCon = null;
    out.write ("error "+e.getClass().getName()+" "+e.getMessage());
  }
  
  if (null==oCon) return;
  oCon = null;

  if (oPrd.getRowCount()>0) out.write (Gadgets.join(oPrd.getRowAsList(0),"\t"));
%>
<%@ page import="java.util.HashSet,java.util.HashMap,java.util.Iterator,java.util.Date,java.io.IOException,java.net.URLDecoder,java.sql.SQLException,com.knowgate.jdc.JDCConnection,com.knowgate.dataobjs.*,com.knowgate.acl.*,com.knowgate.misc.Gadgets,org.apache.poi.hssf.usermodel.HSSFWorkbook,org.apache.poi.hssf.usermodel.HSSFSheet,org.apache.poi.hssf.usermodel.HSSFRow,org.apache.poi.hssf.usermodel.HSSFCell,org.apache.poi.hssf.usermodel.HSSFCellStyle,org.apache.poi.hssf.usermodel.HSSFFont,org.apache.poi.hssf.usermodel.HSSFDataFormat,org.apache.poi.hssf.usermodel.HSSFPrintSetup,com.knowgate.hipergate.DBLanguages" language="java" session="false" contentType="application/vnd.ms-excel" %><%@ include file="../methods/dbbind.jsp" %><%@ include file="../methods/cookies.jspf" %><%@ include file="../methods/authusrs.jspf" %><%@ include file="../methods/nullif.jspf" %><% 
/*
  Copyright (C) 2003-2011  Know Gate S.L. All rights reserved.

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

  final String sQry = nullif(request.getParameter("qry"));
  final String sDtStart = request.getParameter("dt_start");
  final String sDtEnd = request.getParameter("dt_end");

  response.addHeader ("Pragma", "no-cache");
  response.addHeader ("cache-control", "no-store");
  response.setIntHeader("Expires", 0);
  response.setHeader("Content-Disposition", "inline; filename=\"oportunidades_"+(sQry.equals("won") ? "ganadas" : "perdidas")+".xls\"");
      
  String gu_workarea = getCookie (request, "workarea", null);
  String id_user = getCookie (request, "userid", null);
  String id_language = getNavigatorLanguage(request);

  String sStatus;
    
  JDCConnection oConn = null;
  HSSFWorkbook oWrkb = new HSSFWorkbook();
  DBSubset oSales = null;
  int iSales = 0;
  HashMap oObjctsNames = null;
  HashSet<String> oStatuses = new HashSet<String>();
  HashMap<String,HashMap<String,Integer>> oStatusByObjective = new HashMap<String,HashMap<String,Integer>>();
  Iterator<String> iObjctvs, iStatss;
  
  if (sQry.length()==0)
    sStatus = "";
  else if (sQry.equals("won"))
    sStatus = "('VENTA')";
  else
    sStatus = "('CONTACTADO','RETIRADO','NOADMITIDO','BAJA')";
  
  try {      
    oConn = GlobalDBBind.getConnection("rp_saleswinlost");

    if (null==sDtStart) {
      if (oConn.getDataBaseProduct()==JDCConnection.DBMS_MYSQL)
        oSales = new DBSubset(DB.k_oportunities + " o," + DB.k_users + " u",
    		                      "o." + DB.tl_oportunity + ",o." + DB.id_objetive + ",o." + DB.id_status + ",o." + DB.tx_cause + ",o." + DB.im_revenue + ",o." + DB.dt_modified + ",o." + DB.dt_next_action + "," +
    		                      "CONCAT(COALESCE(u." + DB.nm_user + ",''),' ',COALESCE(u." + DB.tx_surname1 + ",''),' ',COALESCE(u." + DB.tx_surname2 + ",'')) AS full_name,"+
    		                      "o."+DB.gu_writer+",o."+DB.bo_private,
    			                    "o." + DB.gu_writer + "=u." + DB.gu_user + " AND " +
    			                    "o." + DB.gu_workarea + "=? " + (sStatus.length()==0 ? "" : " AND o." + DB.id_status + " IN " + sStatus), 100);
      else
        oSales = new DBSubset(DB.k_oportunities + " o," + DB.k_users + " u",
    		                      "o." + DB.tl_oportunity + ",o." + DB.id_objetive + ",o." + DB.id_status + ",o." + DB.tx_cause + ",o." + DB.im_revenue + ",o." + DB.dt_modified + ",o." + DB.dt_next_action + "," + DBBind.Functions.ISNULL + "(u." + DB.nm_user + ",'') " + DBBind.Functions.CONCAT + " ' ' " + DBBind.Functions.CONCAT + " " + DBBind.Functions.ISNULL + "(u." + DB.tx_surname1 + ",'') " + DBBind.Functions.CONCAT + " ' ' " + DBBind.Functions.CONCAT + " " + DBBind.Functions.ISNULL + "(u." + DB.tx_surname2 + ",'') AS full_name,o."+DB.gu_writer+",o."+DB.bo_private,
    			                    "o." + DB.gu_writer + "=u." + DB.gu_user + " AND " +
    			                    "o." + DB.gu_workarea + "=? " + (sStatus.length()==0 ? "" : " AND o." + DB.id_status + " IN " + sStatus), 100);
      iSales = oSales.load (oConn, new Object[]{gu_workarea});
    } else {
      String[] aDtStart = Gadgets.split(sDtStart,'-');
      Date dDtStart = new Date(Integer.parseInt(aDtStart[0])-1900,Integer.parseInt(aDtStart[1])-1,Integer.parseInt(aDtStart[2]),0,0,0);
      
      if (oConn.getDataBaseProduct()==JDCConnection.DBMS_MYSQL)
      	oSales = new DBSubset(DB.k_oportunities + " o," + DB.k_users + " u",
    		                    "o." + DB.tl_oportunity + ",o." + DB.id_objetive + ",o." + DB.id_status + ",o." + DB.tx_cause + ",o." + DB.im_revenue + ",o." + DB.dt_modified + ",o." + DB.dt_next_action + ",CONCAT(COALESCE(u." + DB.nm_user + ",''),' ',COALESCE(u." + DB.tx_surname1 + ",''),' ',COALESCE(u." + DB.tx_surname2 + ",'')) AS full_name,o."+DB.gu_writer+",o."+DB.bo_private,
    			                  "o." + DB.gu_writer + "=u." + DB.gu_user + " AND " +
    			                  "o." + DB.gu_workarea + "=? " + (sStatus.length()==0 ? "" : " AND o." + DB.id_status + " IN " + sStatus) + " AND " + DBBind.Functions.ISNULL + "(o." + DB.dt_modified + ",o." + DB.dt_created + ")>=?", 100);
      else
      	oSales = new DBSubset(DB.k_oportunities + " o," + DB.k_users + " u",
    		                    "o." + DB.tl_oportunity + ",o." + DB.id_objetive + ",o." + DB.id_status + ",o." + DB.tx_cause + ",o." + DB.im_revenue + ",o." + DB.dt_modified + ",o." + DB.dt_next_action + "," + DBBind.Functions.ISNULL + "(u." + DB.nm_user + ",'') " + DBBind.Functions.CONCAT + " ' ' " + DBBind.Functions.CONCAT + " " + DBBind.Functions.ISNULL + "(u." + DB.tx_surname1 + ",'') " + DBBind.Functions.CONCAT + " ' ' " + DBBind.Functions.CONCAT + " " + DBBind.Functions.ISNULL + "(u." + DB.tx_surname2 + ",'') AS full_name,o."+DB.gu_writer+",o."+DB.bo_private,
    			                  "o." + DB.gu_writer + "=u." + DB.gu_user + " AND " +
    			                  "o." + DB.gu_workarea + "=? " + (sStatus.length()==0 ? "" : " AND o." + DB.id_status + " IN " + sStatus) + " AND " + DBBind.Functions.ISNULL + "(o." + DB.dt_modified + ",o." + DB.dt_created + ")>=?", 100);
      iSales = oSales.load (oConn, new Object[]{gu_workarea, dDtStart});
    }

		oObjctsNames = DBLanguages.getLookUpMap(oConn, DB.k_oportunities_lookup, gu_workarea, DB.id_objetive, id_language);

    oConn.close("rp_saleswinlost");    

		int nTotal = 0;
		for (int s=0; s<iSales; s++) {
		  boolean bPrivate;
		  if (oSales.isNull(DB.bo_private,s))
		    bPrivate = false;
		  else
		  	bPrivate = (oSales.getShort(DB.bo_private,s)!=(short)0);		  	
			if (!oSales.isNull(1,s) && !oSales.isNull(2,s) && (!bPrivate || id_user.equals(oSales.getStringNull(DB.gu_writer,s,"")))) {
			  nTotal++;
			  String sObjetive = oSales.getString(1,s);
			  String sStatusId = oSales.getString(2,s);
		    if (!oStatuses.contains(sStatusId))
		      oStatuses.add(sStatusId);
		    HashMap<String,Integer> oStatusesForObjective;
		    if (!oStatusByObjective.containsKey(sObjetive)) {
		      oStatusesForObjective = new HashMap<String,Integer>();
				  oStatusByObjective.put(sObjetive,oStatusesForObjective);
		    } else {
				  oStatusesForObjective = oStatusByObjective.get(sObjetive);		    
		    }
				if (oStatusesForObjective.containsKey(sStatusId)) {
					Integer nSameStatusCount = new Integer(oStatusesForObjective.get(sStatusId).intValue()+1);
					oStatusesForObjective.remove(sStatusId);
				  oStatusesForObjective.put(sStatusId,nSameStatusCount);					
				} else {
				  oStatusesForObjective.put(sStatusId,new Integer(1));
			  }
			} // fi
		} // next

    HSSFRow oRow;
    HSSFCell oCel;
    int r = 0;
    int c = 0;
    
    HSSFFont oBold = oWrkb.createFont();
    oBold.setBoldweight(HSSFFont.BOLDWEIGHT_BOLD);
    HSSFCellStyle oHeader = oWrkb.createCellStyle();
    oHeader.setFont(oBold);
    oHeader.setBorderBottom(oHeader.BORDER_THICK);
    HSSFCellStyle oIntFmt = oWrkb.createCellStyle();
    oIntFmt.setAlignment(HSSFCellStyle.ALIGN_CENTER);
    oIntFmt.setDataFormat((short)1);
    HSSFCellStyle oPctFmt = oWrkb.createCellStyle();
    oPctFmt.setAlignment(HSSFCellStyle.ALIGN_CENTER);
    oPctFmt.setDataFormat((short)9);
    HSSFCellStyle oDateFmt = oWrkb.createCellStyle();
    oDateFmt.setDataFormat((short)15);
    
    HSSFSheet oByObjc = oWrkb.createSheet();
    HSSFSheet oDetail = oWrkb.createSheet();
    oWrkb.setSheetName(0, "PorPrograma");
    oWrkb.setSheetName(1, "Detalle");

		oRow = oByObjc.createRow(r++);
	  oCel = oRow.createCell(c++);
    oCel.setCellValue("Programa");
	  oCel.setCellStyle(oHeader);
	  iStatss = oStatuses.iterator();
	  while (iStatss.hasNext()) {
	    oCel = oRow.createCell(c++);
      oCel.setCellValue((String) iStatss.next());
	    oCel.setCellStyle(oHeader);
	  } // wend
	  
	  iObjctvs = oStatusByObjective.keySet().iterator();
	  while (iObjctvs.hasNext()) {
		  c=0;
			oRow = oByObjc.createRow(r++);
		  String sObjetive = iObjctvs.next();
	    oCel = oRow.createCell(c++);
      oCel.setCellValue(nullif((String)oObjctsNames.get(sObjetive),sObjetive));
	    iStatss = oStatuses.iterator();
	    while (iStatss.hasNext()) {
	      String sStatusId = iStatss.next();
	      oCel = oRow.createCell(c++);
	      if (oStatusByObjective.get(sObjetive).containsKey(sStatusId))
          oCel.setCellValue(oStatusByObjective.get(sObjetive).get(sStatusId).intValue());	        
	      else
	      	oCel.setCellValue(0);
	      oCel.setCellStyle(oIntFmt);
	    } // wend
	  } // wend
		oRow = oByObjc.createRow(r++);
	  oCel = oRow.createCell(0);
    oCel.setCellValue("Total "+String.valueOf(nTotal));
	  oCel.setCellStyle(oHeader);
	  
  }
  catch (NullPointerException e) {  
    disposeConnection(oConn,"rp_saleswinlost");
    response.sendRedirect (response.encodeRedirectUrl ("../common/errmsg.jsp?title="+e.getClass().getName()+"&desc=" + e.getMessage() + "&resume=_back"));
    oConn = null;
    throw new Exception(e.getMessage());
  }

  oWrkb.write(response.getOutputStream());

  if (true) return; // Do not remove this line or you will get an error "getOutputStream() has already been called for this response"

%>
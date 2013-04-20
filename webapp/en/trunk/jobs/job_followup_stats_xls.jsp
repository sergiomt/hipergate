<%@ page import="org.apache.poi.hssf.usermodel.HSSFWorkbook,org.apache.poi.hssf.usermodel.HSSFSheet,org.apache.poi.hssf.usermodel.HSSFRow,org.apache.poi.hssf.usermodel.HSSFCell,org.apache.poi.hssf.usermodel.HSSFCellStyle,org.apache.poi.hssf.usermodel.HSSFFont,org.apache.poi.hssf.usermodel.HSSFDataFormat,org.apache.poi.hssf.usermodel.HSSFPrintSetup,java.text.NumberFormat,java.util.ArrayList,java.util.Collections,java.util.Comparator,java.util.HashMap,java.util.Arrays,java.util.TreeMap,java.util.Iterator,java.io.IOException,java.net.URLDecoder,java.sql.SQLException,com.knowgate.jdc.*,com.knowgate.dataobjs.*,com.knowgate.acl.*,com.knowgate.hipergate.*,com.knowgate.scheduler.Atom,com.knowgate.misc.Calendar,com.knowgate.misc.Gadgets" language="java" session="false" contentType="application/x-excel" %><%@ include file="../methods/dbbind.jsp" %><%@ include file="../methods/cookies.jspf" %><%@ include file="../methods/authusrs.jspf" %><%@ include file="../methods/clientip.jspf" %><%@ include file="../methods/nullif.jspf" %><jsp:useBean id="GlobalCacheClient" scope="application" class="com.knowgate.cache.DistributedCachePeer"/><jsp:useBean id="GlobalDBLang" scope="application" class="com.knowgate.hipergate.DBLanguages"/><%@ include file="job_followup_stats.jspf" %><%

  response.addHeader ("Pragma", "no-cache");
  response.addHeader ("cache-control", "no-store");
  response.setIntHeader("Expires", 0);
  response.setHeader("Content-Disposition","attachment; filename=\""+sTxSubject+".xls\"");
  
  HSSFWorkbook oWrkb = new HSSFWorkbook();
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

  HSSFSheet oDetail = oWrkb.createSheet();
  HSSFSheet oClicth = oWrkb.createSheet();
  HSSFSheet oTotals = oWrkb.createSheet();
  oWrkb.setSheetName(0, "Detail");
  oWrkb.setSheetName(1, "Clicks");
  oWrkb.setSheetName(2, "Summary");

  oRow = oTotals.createRow(r++);
  oCel = oRow.createCell(0);
  oCel.setCellValue("Summery");
	oCel.setCellStyle(oHeader);

  if (oAdHoc.getRowCount()>0) {
    oRow = oTotals.createRow(r++);
    oCel = oRow.createCell(0);
    oCel.setCellValue("Reference");
    oCel = oRow.createCell(1);
    if (oAdHoc.isNull(0,0))
      oCel.setCellValue(oAdHoc.getString(1,0));
    else
      oCel.setCellValue(oAdHoc.getString(1,0)+ " ("+String.valueOf(oAdHoc.getInt(0,0))+")");    	
  }

  oRow = oTotals.createRow(r++);
  oCel = oRow.createCell(0);
  oCel.setCellValue("Title");
  oCel = oRow.createCell(1);
  if (oActiv.getRowCount()>0)
    oCel.setCellValue(oActiv.getStringNull(0,0,""));
  else
    oCel.setCellValue(oAdHoc.getStringNull(2,0,""));

  oRow = oTotals.createRow(r++);
  oCel = oRow.createCell(0);
  oCel.setCellValue("Sent date");
  oCel = oRow.createCell(1);
  oCel.setCellValue(oDateRange.getDateShort(0,0));

  oRow = oTotals.createRow(r++);
  oCel = oRow.createCell(0);
  oCel.setCellValue("Recipients");
  oCel = oRow.createCell(1);
  if (oLists.getRowCount()>0)
    oCel.setCellValue(Gadgets.join(oLists.getColumnAsList(0),","));
  
  oRow = oTotals.createRow(r++);
  oCel = oRow.createCell(0);
  oCel.setCellValue("Total Recipients");
  oCel = oRow.createCell(1);
  oCel.setCellValue(oAtoms.getRowCount());

  oRow = oTotals.createRow(r++);
  oCel = oRow.createCell(0);
  oCel.setCellValue("Sent emails");
  oCel = oRow.createCell(1);
  oCel.setCellValue(nFinished+nRunning);

  if (nBlackListed>0) {
    oRow = oTotals.createRow(r++);
    oCel = oRow.createCell(0);
    oCel.setCellValue("Black List");
    oCel = oRow.createCell(1);
    oCel.setCellValue(nBlackListed);
  }
  
  if (nGreyListed>0) {
    oRow = oTotals.createRow(r++);
    oCel = oRow.createCell(0);
    oCel.setCellValue("Grey List");
    oCel = oRow.createCell(1);
    oCel.setCellValue(nGreyListed);
  }
  
  oRow = oTotals.createRow(r++);
  oCel = oRow.createCell(0);
  oCel.setCellValue("Webmails (GMail, Yahoo!, etc.)");
  oCel = oRow.createCell(1);
  oCel.setCellValue(nWebmails);

  oRow = oTotals.createRow(r++);
  oCel = oRow.createCell(0);
  oCel.setCellValue("Thick clients (Outlook, Thunderbird, etc.)");
  oCel = oRow.createCell(1);
  oCel.setCellValue(nThickClients);

  oRow = oTotals.createRow(r++);
  oCel = oRow.createCell(0);
  oCel.setCellValue("Opened before 24h");
  oCel = oRow.createCell(1);
  oCel.setCellValue(nOpen24);

  oRow = oTotals.createRow(r++);
  oCel = oRow.createCell(0);
  oCel.setCellValue("Openings before 72h");
  oCel = oRow.createCell(1);
  oCel.setCellValue(nOpen72);

  oRow = oTotals.createRow(r++);
  oCel = oRow.createCell(0);
  oCel.setCellValue("Unique Openings");
  oCel = oRow.createCell(1);
  oCel.setCellValue(iWebBeaconsUnique);

  oRow = oTotals.createRow(r++);
  oCel = oRow.createCell(0);
  oCel.setCellValue("Total Openings");
  oCel = oRow.createCell(1);
  oCel.setCellValue(oWebBeacons.getRowCount());

  oRow = oTotals.createRow(r++);
  oCel = oRow.createCell(0);
  oCel.setCellValue("User-Agents");
  Iterator<String> oIter = oAgents.keySet().iterator();
  while (oIter.hasNext()) {
    sUserAgent = oIter.next();
    float fAgentCount = oAgents.get(sUserAgent).floatValue();
    oRow = oTotals.createRow(r++);
    oCel = oRow.createCell(1);
	  oCel.setCellStyle(oPctFmt);
    oCel.setCellValue(fAgentCount/nAgents);
    oCel = oRow.createCell(2);
    oCel.setCellValue(sUserAgent);
  } // wend
  
  r = 0;
  oRow = oClicth.createRow(r++);

  oCel = oRow.createCell(0);
  oCel.setCellValue("URL");
	oCel.setCellStyle(oHeader);

  oCel = oRow.createCell(1);
  oCel.setCellValue("Title");
	oCel.setCellStyle(oHeader);

  oCel = oRow.createCell(2);
  oCel.setCellValue("Clicks");
	oCel.setCellStyle(oHeader);
	
  for (java.util.Map.Entry<String, Integer> k : aKeys) {
    oRow = oClicth.createRow(r++);
    Object oKey = k.getKey();
    int iUrlRow = oClicks.find(3,oKey);
    int z = 0;

    oCel = oRow.createCell(z++);
    oCel.setCellValue(oClicks.getString(4,iUrlRow));

    oCel = oRow.createCell(z++);
    String sPageTitle = oClicks.getStringNull(5,iUrlRow,"");
    try {
      sPageTitle = Gadgets.HTMLDencode(sPageTitle);
    } catch (Exception ignore) {}
    oCel.setCellValue(sPageTitle);

    oCel = oRow.createCell(z++);
    oCel.setCellStyle(oIntFmt);
    oCel.setCellValue(k.getValue().intValue());
    
    for (int x=0; x<nClicks; x++) {
      if (oClicks.getString(3,x).equals(oKey)) {
    	  oRow.createCell(++z).setCellValue(oClicks.getString(0,x));        
      } // fi
    }
  }

  oClicth.createRow(r++);
  oClicth.createRow(r++);
  oRow = oClicth.createRow(r++);

  oCel = oRow.createCell(0);
  oCel.setCellValue("URL");
	oCel.setCellStyle(oHeader);
  oCel = oRow.createCell(1);
  oCel.setCellValue("Title");
	oCel.setCellStyle(oHeader);
  oCel = oRow.createCell(2);
  oCel.setCellValue("Date");
	oCel.setCellStyle(oHeader);
  oCel = oRow.createCell(3);
  oCel.setCellValue("Hour");
	oCel.setCellStyle(oHeader);
  oCel = oRow.createCell(4);
  oCel.setCellValue("e-mail");
	oCel.setCellStyle(oHeader);

  oClicks.sortByDesc(1);
  for (int x=0; x<nClicks; x++) {
    oRow = oClicth.createRow(r++);
    oCel = oRow.createCell(0);
    oCel.setCellValue(oClicks.getStringNull(4,x,""));
    oCel = oRow.createCell(1);
    oCel.setCellValue(oClicks.getStringNull(5,x,""));
    oCel = oRow.createCell(2);
    oCel.setCellValue(oClicks.getDateShort(1,x));
    oCel = oRow.createCell(3);
    oCel.setCellValue(oClicks.getDateFormated(1,x,"HH:mm:ss"));
    oCel = oRow.createCell(4);
    oCel.setCellValue(oClicks.getStringNull(0,x,""));    
  }
  
  r = 0;
  oRow = oDetail.createRow(r++);
  oCel = oRow.createCell(0);
  oCel.setCellValue("Full Name");
	oCel.setCellStyle(oHeader);
  oCel = oRow.createCell(1);
  oCel.setCellValue("e-mail");
	oCel.setCellStyle(oHeader);
  oCel = oRow.createCell(2);
  oCel.setCellValue("Openings");
	oCel.setCellStyle(oHeader);
  oCel = oRow.createCell(3);
  oCel.setCellValue("Clicks");
	oCel.setCellStyle(oHeader);
  oCel = oRow.createCell(4);
  oCel.setCellValue("Dates");
	oCel.setCellStyle(oHeader);
	
  for (int p=0; p<nPgAtoms; p++) {
    if (aPgAtoms[p]>0) {      
      oRow = oDetail.createRow(r++);
		  int iPgAtm = iMinAtom+p;
			int iIxAtm = oWebBeacons.find(3, new Integer(iPgAtm));
			int nTimes = 0;
			String sTxEmail = oWebBeacons.getString(0,iIxAtm);
			iIxMbr = oEmailAddrs.binaryFind(0,sTxEmail);
			if (iIxMbr!=-1) {
    	  oCel = oRow.createCell(0);
			  if (oEmailAddrs.isNull(1,iIxMbr))
          oCel.setCellValue(oEmailAddrs.getStringNull(5,iIxMbr,""));
        else
				  oCel.setCellValue(oEmailAddrs.getStringNull(3,iIxMbr,"")+" "+oEmailAddrs.getStringNull(4,iIxMbr,""));
		  }
    	oCel = oRow.createCell(1);
		  oCel.setCellValue(sTxEmail);
			c = 4;
			while (oWebBeacons.getInt(3,iIxAtm)==iPgAtm) {
			  if (c>=255) break;
			  nTimes++;
    	  oCel = oRow.createCell(c++);
    	  oCel.setCellStyle(oDateFmt);
		    oCel.setCellValue(oWebBeacons.getDate(1,iIxAtm));
				if (++iIxAtm==iWebBeacons) break;
			} //wend
    	oCel = oRow.createCell(2);
      oCel.setCellStyle(oIntFmt);
		  oCel.setCellValue(nTimes);
		  if (oClickCounter.size()>0) {
    	  oCel = oRow.createCell(3);
        oCel.setCellStyle(oIntFmt);
		    if (oClickCounter.containsKey(sTxEmail))
		      oCel.setCellValue(oClickCounter.get(sTxEmail));
		  }
		} // fi
	} // next

  oWrkb.write(response.getOutputStream());

  if (true) return; // Do not remove this line or you will get an error "getOutputStream() has already been called for this response"
%>
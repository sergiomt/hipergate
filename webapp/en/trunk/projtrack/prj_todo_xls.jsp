<%@ page import="java.util.Date,java.util.HashMap,java.text.SimpleDateFormat,java.io.IOException,java.net.URLDecoder,java.sql.SQLException,com.knowgate.jdc.JDCConnection,com.knowgate.dataobjs.*,com.knowgate.hipergate.DBLanguages,org.apache.poi.hssf.usermodel.HSSFWorkbook,org.apache.poi.hssf.usermodel.HSSFSheet,org.apache.poi.hssf.usermodel.HSSFRow,org.apache.poi.hssf.usermodel.HSSFCell,org.apache.poi.hssf.usermodel.HSSFCellStyle,org.apache.poi.hssf.usermodel.HSSFFont,org.apache.poi.hssf.usermodel.HSSFDataFormat,org.apache.poi.hssf.usermodel.HSSFPrintSetup" language="java" session="false" contentType="application/x-excel;charset=UTF-8" %><%@ include file="../methods/dbbind.jsp" %><%@ include file="../methods/cookies.jspf" %><%@ include file="../methods/authusrs.jspf" %><%@ include file="../methods/nullif.jspf" %><% 

	SimpleDateFormat oDtFtm = new SimpleDateFormat("yyyyMMdd");

  response.addHeader ("Pragma", "no-cache");
  response.addHeader ("cache-control", "no-store");
  response.setIntHeader("Expires", 0);
  response.setHeader("Content-Disposition","attachment; filename=\"Hipergate-Duties-"+oDtFtm.format(new Date())+".xls\"");

  if (autenticateSession(GlobalDBBind, request, response)<0) return;

  String sLanguage = getNavigatorLanguage(request);

  String gu_workarea = getCookie(request,"workarea",""); 
  String gu_user = getCookie(request,"userid",""); 

  JDCConnection oConn = null;
  String sWhere = "p."+DB.gu_owner+"=? AND (d."+DB.tx_status+" IS NULL OR d."+DB.tx_status+" IN ('APROBADA','ENCURSO','ENESPERA','PENDIENTE','ENDEFINICION'))";
  
  DBSubset oDuties = new DBSubset(DB.k_duties+" d,"+DB.k_projects+" p,"+DB.k_project_expand+" e",
																	"d."+DB.gu_duty+",d."+DB.nm_duty+",d."+DB.gu_project+",d."+DB.gu_writer+",d."+DB.dt_created+",d."+DB.dt_modified+",d."+DB.dt_start+",d."+DB.dt_scheduled+",d."+DB.dt_end+","+
																	"d."+DB.ti_duration+",d."+DB.od_priority+",d."+DB.gu_contact+",d."+DB.tx_status+",d."+DB.pct_complete+",d."+DB.pr_cost+",d."+DB.tp_duty+",d."+DB.de_duty+",d."+DB.tx_comments+","+
																	"p."+DB.nm_project+",e."+DB.od_walk+",e."+DB.od_level,
																	"p."+DB.gu_project+"=e."+DB.gu_project+" AND "+
																	"d."+DB.gu_project+"=p."+DB.gu_project+" AND "+
																  sWhere+" ORDER BY "+DB.od_walk+","+DB.od_priority+" DESC", 1000);
	DBSubset oResces = new DBSubset (DB.k_duties+" d,"+DB.k_projects+" p,"+DB.k_x_duty_resource+" x",
																	 "d."+DB.gu_duty+",x."+DB.nm_resource,
																	 "x."+DB.gu_duty+"=d."+DB.gu_duty+" AND "+
																	 "d."+DB.gu_project+"=p."+DB.gu_project+" AND "+
																	 sWhere, 1000);

  try {
    oConn = GlobalDBBind.getConnection("duty_todo_xls");

		HashMap oResNames = DBLanguages.getLookUpMap(oConn, DB.k_duties_lookup, gu_workarea, DB.nm_resource, sLanguage);    

    oDuties.setMaxRows(32000);
    short nDuties = (short) oDuties.load(oConn, new Object[]{gu_workarea});

    int nResces = oResces.load(oConn, new Object[]{gu_workarea});
	
		HashMap<String,String> oResMap = new HashMap<String,String>(nDuties*2);

		for (int r=0; r<nResces; r++) {
		  String sGuDuty = oResces.getString(0,r);
		  String sResId = oResces.getString(1,r);
		  String sResName;
		  if (oResNames.containsKey(sResId))
		    sResName = (String) oResNames.get(sResId);
		  else
		  	sResName = DBLanguages.getLookUpTranslation(oConn, DB.k_duties_lookup, gu_workarea, DB.nm_resource, "en", sResId);

			if (sResName!=null) {
		    if (oResMap.containsKey(sGuDuty)) {
		      String sNewResList = oResMap.get(sGuDuty)+","+sResName;
		      oResMap.remove(sGuDuty);
		      oResMap.put(sGuDuty, sNewResList);
		    } else {
		      oResMap.put(sGuDuty, sResName);
		    } // fi
		  } // fi
	  } // next
		oResces = null;
    oConn.close("duty_todo_xls");

    HSSFWorkbook oWrkb = new HSSFWorkbook();
    HSSFSheet oSheet = oWrkb.createSheet();
    oWrkb.setSheetName(0, "Duties");
    oSheet.getPrintSetup().setLandscape(true);
    HSSFRow oRow;
    HSSFCell oCell;
    HSSFFont oBold = oWrkb.createFont();
    oBold.setBoldweight(HSSFFont.BOLDWEIGHT_BOLD);
    HSSFCellStyle oHeader = oWrkb.createCellStyle();
    oHeader.setFont(oBold);
    oHeader.setBorderBottom(oHeader.BORDER_THICK);
    HSSFCellStyle oNextProj = oWrkb.createCellStyle();
    oNextProj.setBorderTop(oNextProj.BORDER_THIN);
    HSSFCellStyle oIntFmt = oWrkb.createCellStyle();
    oIntFmt.setAlignment(HSSFCellStyle.ALIGN_CENTER);
    oIntFmt.setDataFormat((short)1);
    HSSFCellStyle oPctFmt = oWrkb.createCellStyle();
    oPctFmt.setAlignment(HSSFCellStyle.ALIGN_CENTER);
    oPctFmt.setDataFormat((short)9);
    HSSFCellStyle oDateFmt = oWrkb.createCellStyle();
    oDateFmt.setDataFormat((short)15);

		String[] aHeader = new String[]{"Project","Duty Type","Name","Status","Priority","Estimated","Actual start-up","End","Pct","Resources","Description","Comments"};
	  final short nCols = (short) aHeader.length;
	  
	  oRow = oSheet.createRow(0);
	  for (short h=0; h<nCols; h++) {
      oCell = oRow.createCell(h);
	    oCell.setCellValue(aHeader[h]);
	    oCell.setCellStyle(oHeader);
	  } // next
	  oSheet.setColumnWidth(0, 256*48); // Project
	  oSheet.setColumnWidth(1, 256*16); // Type
	  oSheet.setColumnWidth(2, 256*48); // Name
	  oSheet.setColumnWidth(3, 256*16); // Status
	  oSheet.setColumnWidth(4, 256*12); // Priority
	  oSheet.setColumnWidth(5, 256*12); // Sched Date
	  oSheet.setColumnWidth(6, 256*12); // Start Date
	  oSheet.setColumnWidth(7, 256*12); // End Date
	  oSheet.setColumnWidth(8, 256*8); // Pct
	  oSheet.setColumnWidth(9, 256*48); // Resources
	  oSheet.setColumnWidth(10, 256*64); // Description
	  oSheet.setColumnWidth(11, 256*64); // Comments

		String sLastProj = "";
		for (short d=(short)0; d<nDuties; d++) {
	    oRow = oSheet.createRow(d+1);
	  
	  	HSSFCell[] aCells = new HSSFCell[nCols];
	    for (short c=0; c<nCols; c++) {
        aCells[c] = oRow.createCell(c);	      
	    } //next
	  	
      if (!sLastProj.equals(oDuties.getString(DB.nm_project,d))) {
	      aCells[0].setCellValue(oDuties.getString(DB.nm_project,d));
	      if (sLastProj.length()>0) {
	        aCells[0].setCellStyle(oNextProj);
	      } // fi
	      sLastProj = oDuties.getString(DB.nm_project, d);      
	    } // fi
	  
	    aCells[1].setCellValue(oDuties.getStringNull(DB.tp_duty,d,""));
	    aCells[2].setCellValue(oDuties.getStringNull(DB.nm_duty,d,""));
	    aCells[3].setCellValue(oDuties.getStringNull(DB.tx_status,d,""));
      if (!oDuties.isNull(DB.od_priority,d)) {
        aCells[4].setCellType(aCells[4].CELL_TYPE_NUMERIC);
	      aCells[4].setCellStyle(oIntFmt);
	      aCells[4].setCellValue((double)oDuties.getShort(DB.od_priority,d));
      } // fi
      if (!oDuties.isNull(DB.dt_scheduled,d)) {
	      aCells[5].setCellStyle(oDateFmt);
	      aCells[5].setCellValue(oDuties.getDate(DB.dt_scheduled,d));
      } // fi
      if (!oDuties.isNull(DB.dt_start,d)) {
	      aCells[6].setCellStyle(oDateFmt);
	      aCells[6].setCellValue(oDuties.getDate(DB.dt_start,d));
      } // fi
      if (!oDuties.isNull(DB.dt_end,d)) {
	      aCells[7].setCellStyle(oDateFmt);
	      aCells[7].setCellValue(oDuties.getDate(DB.dt_end,d));
      } // fi
      if (!oDuties.isNull(DB.pct_complete,d)) {
        aCells[8].setCellType(aCells[8].CELL_TYPE_NUMERIC);
	      aCells[8].setCellStyle(oPctFmt);
	      aCells[8].setCellValue(((double)oDuties.getShort(DB.pct_complete,d))/100d);
      } // fi
		  if (oResMap.containsKey(oDuties.getString(DB.gu_duty,d))) {
	      aCells[9].setCellValue(oResMap.get(oDuties.getString(DB.gu_duty,d)));
      }
	    aCells[10].setCellValue(oDuties.getStringNull(DB.de_duty,d,""));
	    aCells[11].setCellValue(oDuties.getStringNull(DB.tx_comments,d,""));

	  } // next

    oWrkb.write(response.getOutputStream());
  }
  catch (Exception e) {
    if (oConn!=null)
      if (!oConn.isClosed()) {
        oConn.close("duty_todo_xls");
      }
    oConn = null;
    response.sendRedirect (response.encodeRedirectUrl ("../common/errmsg.jsp?title=" + e.getClass().getName() + "&desc=" + e.getMessage() + "&resume=_back"));
  }
  
  if (null==oConn) return;    
  oConn = null;

  if (true) return; // Do not remove this line or you will get an error "getOutputStream() has already been called for this response"
%>
<%@ page import="java.io.File,java.util.HashMap,java.util.Properties,java.text.SimpleDateFormat,java.util.Date,java.util.HashMap,java.net.URLDecoder,java.sql.Types,java.sql.PreparedStatement,java.sql.ResultSet,java.sql.SQLException,java.util.Date,java.text.SimpleDateFormat,com.knowgate.jdc.*,com.knowgate.acl.*,com.knowgate.dataobjs.*,com.knowgate.hipergate.DBLanguages,com.knowgate.misc.Gadgets,org.apache.poi.hssf.usermodel.HSSFWorkbook,org.apache.poi.hssf.usermodel.HSSFSheet,org.apache.poi.hssf.usermodel.HSSFRow,org.apache.poi.hssf.usermodel.HSSFCell,org.apache.poi.hssf.usermodel.HSSFCellStyle,org.apache.poi.hssf.usermodel.HSSFFont,org.apache.poi.hssf.usermodel.HSSFDataFormat,org.apache.poi.hssf.usermodel.HSSFPrintSetup,com.knowgate.http.portlets.*" language="java" session="false" contentType="application/vnd.ms-excel;charset=UTF-8" %><%@ include file="../methods/dbbind.jsp" %><%@ include file="../methods/cookies.jspf" %><%@ include file="../methods/nullif.jspf" %><%@ include file="../methods/authusrs.jspf" %><jsp:useBean id="GlobalCacheClient" scope="application" class="com.knowgate.cache.DistributedCachePeer"/><%@ include file="oportunity_listing.jspf" %><%

	  SimpleDateFormat oDtFtm = new SimpleDateFormat("yyyyMMdd");

    response.setHeader("Content-Disposition","attachment; filename=\"Hipergate-Oportunities-"+oDtFtm.format(new Date())+".xls\"");

		String[] aLastCallNumber = null;
		String[] aLastCallPerson = null;
		String[] aState = null;
		String[] aCity = null;
		String[] aZipcode = null;

	  if (iOportunityCount>0) {
	    aLastCallNumber = new String[iOportunityCount];
	    aLastCallPerson = new String[iOportunityCount];
		  aState = new String[iOportunityCount];
		  aCity = new String[iOportunityCount];
		  aZipcode = new String[iOportunityCount];

	    oConn = GlobalDBBind.getConnection("oportunitylistingxls");

	    PreparedStatement oLstC = oConn.prepareStatement("SELECT tx_phone, contact_person FROM k_phone_calls WHERE gu_oportunity=? ORDER BY dt_start DESC");
	    PreparedStatement oAddr = oConn.prepareStatement("SELECT nm_state,mn_city,zipcode,tx_email,direct_phone,work_phone,mov_phone  FROM k_member_address WHERE gu_contact=? OR gu_company=?");

	    for (int c=0; c<iOportunityCount; c++) {

	      oLstC.setString(1, oOportunities.getString(0,c));
	      ResultSet oRstC = oLstC.executeQuery();
	      if (oRstC.next()) {
	        aLastCallNumber[c] = oRstC.getString(1);
	        if (oRstC.wasNull())
	          aLastCallNumber[c] = null;
	        else if (aLastCallNumber[c].length()==0)
	          aLastCallNumber[c] = null;
	        aLastCallPerson[c] = oRstC.getString(2);
	        if (oRstC.wasNull()) aLastCallPerson[c] = "";
	      } else {
	      	aLastCallPerson[c] = aLastCallNumber[c] = "";
	      }
	      oRstC.close();

				if (oOportunities.isNull(5,c))
				  oAddr.setNull(1, Types.CHAR);
				else
				  oAddr.setString(1, oOportunities.getString(5,c));
				if (oOportunities.isNull(6,c))
				  oAddr.setNull(2, Types.CHAR);
				else
				  oAddr.setString(2, oOportunities.getString(6,c));
				ResultSet oAdds = oAddr.executeQuery();
	      if (oAdds.next()) {
	        aState[c] = oAdds.getString(1);
	        aCity[c] = oAdds.getString(2);
	        aZipcode[c] = oAdds.getString(3);
	      } else {
	      	aState[c] = aCity[c] = aZipcode[c] = "";
	      }
	      oAdds.close();
	    } // next

	    oAddr.close();
	    oLstC.close();

	    oConn.close("oportunitylistingxls");
	  }
    
    HSSFWorkbook oWrkb = new HSSFWorkbook();
    HSSFSheet oSheet = oWrkb.createSheet();
    oWrkb.setSheetName(0, "Tareas");
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

		String[] aHeader = new String[]{"Titulo","Campaña","Estado","Grado Interés","Causa cierre","Cliente","Provincia","Ciudad","Cód. Post.","Importe","Sig. Acción","Últ. llamada","Nº Telf.","Pers. Cto.","Comentarios"};

	  final short nCols = (short) aHeader.length;
	  
	  oRow = oSheet.createRow(0);
	  for (short h=0; h<nCols; h++) {
      oCell = oRow.createCell(h);
	    oCell.setCellValue(aHeader[h]);
	    oCell.setCellStyle(oHeader);
	  } // next
	  oSheet.setColumnWidth(0, 256*40);  // Title
	  oSheet.setColumnWidth(1, 256*40);  // Campaign
	  oSheet.setColumnWidth(2, 256*16);  // Status
	  oSheet.setColumnWidth(3, 256*16);  // Degree of interest
	  oSheet.setColumnWidth(4, 256*30);  // Closing cause
	  oSheet.setColumnWidth(5, 256*40);  // Client
	  oSheet.setColumnWidth(6, 256*20);  // State
	  oSheet.setColumnWidth(7, 256*20);  // City
	  oSheet.setColumnWidth(8, 256*8);   // Zipcode
	  oSheet.setColumnWidth(9, 256*12);  // Amount
	  oSheet.setColumnWidth(10, 256*12); // Next action
	  oSheet.setColumnWidth(11, 256*12); // Last Call
	  oSheet.setColumnWidth(12, 256*10); // Call Number
	  oSheet.setColumnWidth(13, 256*10); // Contact Person
	  oSheet.setColumnWidth(14, 256*80); // Comments

	  for (int i=0; i<iOportunityCount; i++) {
      oRow = oSheet.createRow(i+1);

	  	HSSFCell[] aCells = new HSSFCell[nCols];
	    for (short c=0; c<nCols; c++) {
        aCells[c] = oRow.createCell(c);	      
	    } //next
      
			// Title
      aCells[0].setCellValue(oOportunities.getStringNull(2,i,"* N/A *"));

			// Campaign
      if (!oOportunities.isNull(8,i)) {
        int iCampg = oCampaigns.find(0, oOportunities.get(8,i));
        if (iCampg>=0)
          aCells[1].setCellValue(oCampaigns.getString(1, iCampg));
        else
          aCells[1].setCellValue("");
      }

			// Status
      aCells[2].setCellValue((String) oStatusLookUp.get(oOportunities.getStringNull(1,i,"")));

			// Degree of Interest
      if (!oOportunities.isNull(9,i)) {
        aCells[3].setCellType(aCells[3].CELL_TYPE_NUMERIC);
	      aCells[3].setCellStyle(oIntFmt);
	      aCells[3].setCellValue((double)oOportunities.getShort(9,i));
      } // fi

			// Closing Cause
      if (!oOportunities.isNull(13,i)) {
        aCells[4].setCellValue((String) oCausesLookUp.get(oOportunities.getString(13,i)));
      }
      
			// Client
      aCells[5].setCellValue(oOportunities.getString(3,i));

			// State
      aCells[6].setCellValue(aState[i]);

			// City
      aCells[7].setCellValue(aCity[i]);

			// Zipcode
      aCells[8].setCellValue(aZipcode[i]);

			// Amount
      if (!oOportunities.isNull(7,i)) {
        aCells[9].setCellType(aCells[9].CELL_TYPE_NUMERIC);
	      aCells[9].setCellValue((double)oOportunities.getFloat(7,i));
      } // fi
      
      if (!oOportunities.isNull(4,i)) {
	      aCells[10].setCellStyle(oDateFmt);
	      aCells[10].setCellValue(oOportunities.getDate(4,i));
      } // fi
      
      if (!oOportunities.isNull(11,i)) {
	      aCells[11].setCellStyle(oDateFmt);
	      aCells[11].setCellValue(oOportunities.getDate(11,i));
      } // fi

      aCells[12].setCellValue(aLastCallNumber[i]);

      aCells[13].setCellValue(aLastCallPerson[i]);
      
      aCells[14].setCellValue(oOportunities.getStringNull(12,i,""));
    } // next
    
    oWrkb.write(response.getOutputStream());
    
    if (true) return; // Do not remove this line or you will get an error "getOutputStream() has already been called for this response"
%>
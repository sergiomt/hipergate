<%@ page import="java.util.Arrays,java.util.Date,java.util.HashMap,java.text.SimpleDateFormat,java.io.IOException,java.net.URLDecoder,java.sql.SQLException,com.knowgate.jdc.JDCConnection,com.knowgate.dataobjs.*,com.knowgate.hipergate.DBLanguages,com.knowgate.misc.Gadgets,org.apache.poi.hssf.usermodel.HSSFWorkbook,org.apache.poi.hssf.usermodel.HSSFSheet,org.apache.poi.hssf.usermodel.HSSFRow,org.apache.poi.hssf.usermodel.HSSFCell,org.apache.poi.hssf.usermodel.HSSFCellStyle,org.apache.poi.hssf.usermodel.HSSFFont,org.apache.poi.hssf.usermodel.HSSFDataFormat,org.apache.poi.hssf.usermodel.HSSFPrintSetup" language="java" session="false" contentType="application/x-excel" %><%@ include file="../methods/dbbind.jsp" %><%@ include file="../methods/cookies.jspf" %><%@ include file="../methods/authusrs.jspf" %><%@ include file="../methods/nullif.jspf" %><jsp:useBean id="GlobalCacheClient" scope="application" class="com.knowgate.cache.DistributedCachePeer"/><% 

    if (autenticateSession(GlobalDBBind, request, response)<0) return;
  
    final String PAGE_NAME = "activity_audience_xls";
  
    final String[] aContactColumns = new String[]{DB.id_ref+" AS id_contact",DB.tx_name,DB.tx_surname,DB.de_title,DB.dt_created,DB.id_status,DB.id_fare,DB.id_gender,DB.dt_birth,DB.ny_age,DB.id_nationality,DB.sn_passport,DB.tp_passport,DB.sn_drivelic,DB.dt_drivelic,DB.tx_dept,DB.tx_division,DB.tx_comments};
    final String[] aAddressColumns = new String[]{DB.tp_location,DB.nm_company,DB.tp_street,DB.nm_street,DB.nu_street,DB.tx_addr1,DB.tx_addr2,DB.id_country,DB.nm_country,DB.id_state,DB.nm_state,DB.mn_city,DB.zipcode,DB.work_phone,DB.direct_phone,DB.home_phone,DB.mov_phone,DB.fax_phone,DB.other_phone,DB.po_box,DB.tx_email,DB.tx_email_alt,DB.url_addr,DB.coord_x,DB.coord_y,DB.contact_person,DB.tx_salutation,DB.tx_remarks};
    final String[] aAudienceColumns= new String[]{DB.id_ref+" AS id_audience",DB.tp_origin,DB.bo_confirmed,DB.dt_confirmed,DB.bo_paid,DB.dt_paid,DB.im_paid,DB.id_transact,DB.tp_billing,DB.bo_went,DB.bo_allows_ads};

    final String sColumnsDataX = ",x.id_data1,x.de_data1,x.tx_data1,x.id_data2,x.de_data2,x.tx_data2,x.id_data3,x.de_data3,x.tx_data3,x.id_data4,x.de_data4,x.tx_data4,x.id_data5,x.de_data5,x.tx_data5,x.id_data6,x.de_data6,x.tx_data6,x.id_data7,x.de_data7,x.tx_data7,x.id_data8,x.de_data8,x.tx_data8,x.id_data9,x.de_data9,x.tx_data9";
    final String sColumnsList1 = "c."+Gadgets.join(aContactColumns,",c.")+",a."+Gadgets.join(aAddressColumns,",a.")+",x."+Gadgets.join(aAudienceColumns,",x.")+sColumnsDataX;
    final String sColumnsList2 = "c."+Gadgets.join(aContactColumns,",c.")+",NULL AS "+Gadgets.join(aAddressColumns,",NULL AS ")+",x."+Gadgets.join(aAudienceColumns,",x.")+sColumnsDataX;
    
		final short nAllColumns = (short) (aContactColumns.length+aAddressColumns.length+aAudienceColumns.length);
    
		boolean[] aDisplayColumn = new boolean[nAllColumns];
    String[] aAllColumns = new String[nAllColumns];
    System.arraycopy(aContactColumns , 0, aAllColumns, 0, aContactColumns.length);
    System.arraycopy(aAddressColumns , 0, aAllColumns, aContactColumns.length, aAddressColumns.length);
    System.arraycopy(aAudienceColumns, 0, aAllColumns, aContactColumns.length+aAddressColumns.length, aAudienceColumns.length);    
    
    String sSkin = getCookie(request, "skin", "xp");
    String gu_activity = request.getParameter("gu_activity");
  
    JDCConnection oConn = null;
  
    String sOrderBy = nullif(request.getParameter("orderby"),"2,3");
    String sFind = nullif(request.getParameter("find"));
    String sConfirmed = nullif(request.getParameter("confirmed"));
    String sTlActivity = null;
    
    int iMaxRows = 100;
    
  	DBSubset oAcA1 = null, oAcA2 = null;
    short iAcA1 = 0, iAcA2 = 0;
    
    boolean bIsGuest = true;
    
    try {
      oConn = GlobalDBBind.getConnection(PAGE_NAME);
  
      bIsGuest = isDomainGuest (GlobalCacheClient, GlobalDBBind, request, response);
  
  		sTlActivity = DBCommand.queryStr(oConn,"SELECT "+DB.tl_activity+" FROM "+DB.k_activities+" WHERE "+DB.gu_activity+"='"+gu_activity+"'");
  
  		String LIKEI = oConn.getDataBaseProduct()==JDCConnection.DBMS_POSTGRESQL ? "~*" : DBBind.Functions.ILIKE;
  
  	  oAcA1 = new DBSubset (DB.k_x_activity_audience+" x, "+DB.k_contacts+" c, "+DB.k_addresses+" a", sColumnsList1,
  																 "x."+DB.gu_contact+"=c."+DB.gu_contact+" AND x."+DB.gu_address+"=a."+DB.gu_address+" AND "+
  																(sFind.length()>0 ? " (c."+DB.tx_name+" "+LIKEI+" ? OR c."+DB.tx_surname+" "+LIKEI+" ?) AND " : "")+
  																(sConfirmed.length()>0 ? "x."+DB.bo_confirmed+"="+sConfirmed+" AND " : "")+
  																 "x."+DB.gu_activity+"=? ORDER BY "+sOrderBy, 16000);
  	  oAcA2 = new DBSubset (DB.k_x_activity_audience+" x, "+DB.k_contacts+" c", sColumnsList2,
  																 "x."+DB.gu_contact+"=c."+DB.gu_contact+" AND x."+DB.gu_address+" IS NULL AND "+
  																(sFind.length()>0 ? " (c."+DB.tx_name+" "+LIKEI+" ? OR c."+DB.tx_surname+" "+LIKEI+" ?) AND " : "")+
  																(sConfirmed.length()>0 ? "x."+DB.bo_confirmed+"="+sConfirmed+" AND " : "")+
  																 "x."+DB.gu_activity+"=? ORDER BY "+sOrderBy, 16000);
  
  		oAcA1.setMaxRows(16000);
  		oAcA2.setMaxRows(16000);
  		
  		if (sFind.length()==0) {
        iAcA1 = (short) oAcA1.load(oConn, new Object[]{gu_activity});
        iAcA2 = (short) oAcA2.load(oConn, new Object[]{gu_activity});
      } else {
      	String sSought = oConn.getDataBaseProduct()==JDCConnection.DBMS_POSTGRESQL ? Gadgets.accentsToPosixRegEx(sFind) + ".*" : sFind + "%";
        iAcA1 = (short) oAcA1.load(oConn, new Object[]{sSought, sSought, gu_activity});
        iAcA2 = (short) oAcA2.load(oConn, new Object[]{sSought, sSought, gu_activity});
      }
      if (iAcA1>0 && iAcA2>0) {
        oAcA1.union(oAcA2);
        oAcA1.sortBy(1);
        iAcA1 = (short) oAcA1.getRowCount();
      } else if (iAcA1==0 && iAcA2>0) {
  			iAcA1 = iAcA2;
  			oAcA1 = oAcA2;
      }
     
      oConn.close(PAGE_NAME);
    }
    catch (Exception e) {
      if (oConn!=null)
        if (!oConn.isClosed()) {
          oConn.close(PAGE_NAME);
        }
      oConn = null;
      response.sendRedirect (response.encodeRedirectUrl ("../common/errmsg.jsp?title=" + e.getClass().getName() + "&desc=" + e.getMessage() + "&resume=_back"));
    }
    
    if (null==oConn) return;    
    oConn = null;
  
		short nDisplayCols = 0;
		for (short d=0; d<nAllColumns; d++) {
	    aDisplayColumn[d] = false;
	    for (short r=0; r<iAcA1 && !aDisplayColumn[d]; r++) {
				if (!oAcA1.isNull(d,r)) {
				  nDisplayCols++;
				  aDisplayColumn[d] = true;
	      }
	    } // next (r)
	  } // next (d)

    response.addHeader ("Pragma", "no-cache");
    response.addHeader ("cache-control", "no-store");
    response.setIntHeader("Expires", 0);
    response.setHeader("Content-Disposition","attachment; filename=\""+sTlActivity+".xls\"");

    HSSFWorkbook oWrkb = new HSSFWorkbook();
    HSSFSheet oSheet = oWrkb.createSheet();
    oWrkb.setSheetName(0, "Attendants");
    oSheet.getPrintSetup().setLandscape(true);
    HSSFRow oRow;
    HSSFCell oCell;
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

	  oRow = oSheet.createRow(0);
	  short v = 0;
	  for (short h=(short)0; h<nAllColumns; h++) {
      if (aDisplayColumn[h]) {
        oCell = oRow.createCell(v++);
        if (aAllColumns[h].indexOf(" AS ")>0)
	        oCell.setCellValue(aAllColumns[h].substring(aAllColumns[h].indexOf(" AS ")+4));
        else
	        oCell.setCellValue(aAllColumns[h]);
	      oCell.setCellStyle(oHeader);
      }
	  } // next

		for (short d=(short)0; d<iAcA1; d++) {
	    oRow = oSheet.createRow(d+1);
	  
	  	HSSFCell[] aCells = new HSSFCell[nDisplayCols];
	    short w = 0;
	    for (short c=(short)0; c<nAllColumns; c++) {
        if (aDisplayColumn[c]) {
          oCell = oRow.createCell(w++);
	    	  if (!oAcA1.isNull(c,d)) {
            if (aAllColumns[c].startsWith("dt_")) {
	            oCell.setCellStyle(oDateFmt);          
	    	      oCell.setCellValue(oAcA1.getDate(c,d));
            } else {
	    	      oCell.setCellValue(oAcA1.get(c,d).toString());
            }
	        } // fi (!null)
	      } // fi
	    } //next
	  } // next

    oWrkb.write(response.getOutputStream());

  if (true) return; // Do not remove this line or you will get an error "getOutputStream() has already been called for this response"
%>
<%@ page import="java.io.IOException,java.net.URLDecoder,java.sql.SQLException,com.knowgate.debug.DebugFile,com.knowgate.jdc.JDCConnection,com.knowgate.dataobjs.*,com.knowgate.misc.Gadgets,com.knowgate.crm.Contact,com.knowgate.crm.Company" language="java" session="false" contentType="text/xml;charset=UTF-8" %><%@ include file="../methods/dbbind.jsp" %><%@ include file="../methods/cookies.jspf" %><%@ include file="../methods/authusrs.jspf" %><%@ include file="../methods/nullif.jspf" %><%

  response.addHeader ("Pragma", "no-cache");
  response.addHeader ("cache-control", "no-store");
  response.setIntHeader("Expires", 0);

  /* Autenticate user cookie */
  if (autenticateSession(GlobalDBBind, request, response)<0) return;
      
  String id_user = getCookie (request, "userid", null);

  String gu_workarea = request.getParameter("gu_workarea");
  String nm_table = request.getParameter("nm_table");
  String nm_wrkacolumn = nullif(request.getParameter("nm_wrkacolumn"),"gu_workarea");
  String nm_textcolumn = request.getParameter("nm_textcolumn");
  String nm_valuecolumn = request.getParameter("nm_valuecolumn");
  String nm_infocolumn = nullif(request.getParameter("nm_infocolumn"));
  String tx_where = request.getParameter("tx_where");
  String tx_like = request.getParameter("tx_like");
  String gu_shop = nullif(request.getParameter("gu_shop"));
  String[] aShop = null;
  Object[] aParams = null;
  
  JDCConnection oConn = null;  
  DBSubset oResults=null,oResults2=null;

  if (gu_shop.length()>0) {
        aShop = Gadgets.split(gu_shop,',');
        oResults = new DBSubset(DB.k_products+" p,"+DB.k_cat_expand+" e,"+DB.k_x_cat_objs+" x",
    												    "p."+DB.gu_product+",p."+DB.nm_product+",p."+DB.de_product+",p."+DB.id_ref,
  													    "e."+DB.gu_rootcat+"<>e."+DB.gu_category+" AND "+
  													    "e."+DB.gu_rootcat+" IN (SELECT "+DB.gu_root_cat+" FROM "+DB.k_shops+" WHERE "+DB.gu_shop+" IN ("+Gadgets.dechomp(Gadgets.repeat("?,",aShop.length),",")+")) AND "+
  													    "e."+DB.gu_category+" NOT IN (SELECT "+DB.gu_bundles_cat+" FROM "+DB.k_shops+" WHERE "+DB.gu_shop+" IN ("+Gadgets.dechomp(Gadgets.repeat("?,",aShop.length),",")+")) AND "+
  													    "e."+DB.gu_category+"=x."+DB.gu_category+" AND x."+DB.gu_object+"=p."+DB.gu_product+" AND "+
  													    "(p."+DB.nm_product+" "+DBBind.Functions.ILIKE+" ? OR p."+DB.id_ref+" "+DBBind.Functions.ILIKE+" ?) ORDER BY 2", 10);
  } else {
    if (nullif(nm_table).equalsIgnoreCase("k_contact_company")) {
      oResults = new DBSubset(DB.k_contacts,
      												DB.gu_contact+","+DB.gu_company+","+DBBind.Functions.strCat(new String[]{DB.tx_name,DB.tx_surname},' ')+","+DB.sn_passport+",'"+String.valueOf(Contact.ClassId)+"'",
  								            DB.gu_workarea+"=? AND ("+DB.sn_passport+"=? OR "+DB.tx_name+" "+DBBind.Functions.ILIKE+" ? OR "+DB.tx_surname+" "+DBBind.Functions.ILIKE+" ?) ORDER BY 2", 10);
      oResults2= new DBSubset(DB.k_companies,
      												"NULL AS "+DB.gu_contact+","+DB.gu_company+","+DBBind.Functions.ISNULL+"("+DB.nm_commercial+","+DB.nm_legal+")"+DB.id_legal+",'"+String.valueOf(Company.ClassId)+"'",
  								            DB.gu_workarea+"=? AND ("+DB.id_legal+"=? OR "+DB.nm_commercial+" "+DBBind.Functions.ILIKE+" ? OR "+DB.nm_legal+" "+DBBind.Functions.ILIKE+" ?) ORDER BY 2", 10);
	  }	else if (nullif(nm_table).equalsIgnoreCase("k_contact_doc_id")) {
      oResults = new DBSubset(DB.k_contacts,
      												DB.gu_contact+","+DBBind.Functions.strCat(new String[]{DB.tx_name,DB.tx_surname},' ')+",''",
  								            DB.gu_workarea+"=? AND "+DB.sn_passport+"=? ORDER BY 2", 10);
	  } else if (nullif(nm_table).equalsIgnoreCase("v_invoices")) {
		  if (nm_valuecolumn.equals("pg_invoice")) {
          oResults = new DBSubset(nm_table,"pg_invoice,nm_legal",
  								                "gu_workarea=? AND pg_invoice=?", 10);
		  } else if (nm_valuecolumn.equals("id_ref")) {
          oResults = new DBSubset(nm_table,"pg_invoice,id_ref",
  								                "gu_workarea=? AND id_ref " + DBBind.Functions.ILIKE + " ?", 10);
		  } else if (nm_valuecolumn.equals("id_ref")) {
          oResults = new DBSubset(nm_table,"pg_invoice,nm_legal",
  								                "gu_workarea=? AND nm_legal " + DBBind.Functions.ILIKE + " ?", 10);
		  } else if (nm_valuecolumn.equals("id_ref")) {
          oResults = new DBSubset(nm_table,"pg_invoice,id_legal",
  								                "gu_workarea=? AND id_legal " + DBBind.Functions.ILIKE + " ?", 10);
		  } else if (nm_valuecolumn.equals("id_ref")) {
          oResults = new DBSubset(nm_table,"pg_invoice,tx_comments",
  								                "gu_workarea=? AND tx_comments " + DBBind.Functions.ILIKE + " ?", 10);
		  }
	  } else if (nullif(nm_table).equalsIgnoreCase("k_contact_telephone")) {
          oResults = new DBSubset(DB.k_member_address,"work_phone,direct_phone,home_phone,mov_phone,other_phone",
  								                "gu_workarea=? AND gu_contact=? AND (work_phone LIKE ? OR direct_phone LIKE ? OR home_phone LIKE ? OR mov_phone LIKE ? OR other_phone LIKE ?)", 10);		
    } else {
      	  oResults = new DBSubset(nm_table,nm_valuecolumn+","+nm_textcolumn+","+(nm_infocolumn.length()>0 ? nm_infocolumn : "NULL AS tx_nilinfo"),
  								                nm_wrkacolumn+"=? AND "+tx_where+" "+DBBind.Functions.ILIKE+" ? ORDER BY 2", 10);
	  }
	}

  int nResults = 0;
  
  try {
    oConn = GlobalDBBind.getConnection("autocomplete");
    
    oResults.setMaxRows(10);

    if (gu_shop.length()>0) {
      final int nShop2 = 2*aShop.length;
      aParams = new Object[nShop2+2];
      System.arraycopy(aShop, 0, aParams, 0, aShop.length);
      System.arraycopy(aShop, 0, aParams, aShop.length, aShop.length);
      aParams[nShop2] = tx_like+"%";
      aParams[nShop2+1] = tx_like+"%";
      nResults = oResults.load(oConn, aParams);
      for (int r=0; r<nResults; r++)
        if (!oResults.isNull(3,r))
          if (oResults.getString(3,r).startsWith(tx_like))
            oResults.setElementAt(oResults.getString(3,r),1,r);
    } else {
      if (nullif(nm_table).equalsIgnoreCase("k_contact_company")) {
        nResults = oResults.load(oConn, new Object[]{gu_workarea,tx_like,tx_like+"%",tx_like+"%"});
      } else if (nullif(nm_table).equalsIgnoreCase("v_invoices")) {
		    if (nm_valuecolumn.equals("pg_invoice")) {
          nResults = oResults.load(oConn, new Object[]{gu_workarea,new Integer(tx_like)});		  
		    } else {
          nResults = oResults.load(oConn, new Object[]{gu_workarea,tx_like+"%"});		  
		    }
      } else if (nullif(nm_table).equalsIgnoreCase("k_contact_doc_id")) {
          nResults = oResults.load(oConn, new Object[]{gu_workarea,tx_like});
      } else if (nullif(nm_table).equalsIgnoreCase("k_contact_telephone")) {
          nResults = oResults.load(oConn, new Object[]{gu_workarea,tx_where,tx_like+"%",tx_like+"%",tx_like+"%",tx_like+"%",tx_like+"%"});
      } else {
        nResults = oResults.load(oConn, new Object[]{gu_workarea,tx_like+"%"});
      }
    } // fi

	  if (0==nResults) {
	    if (gu_shop.length()>0) {
        aParams[2*aShop.length] = "%"+tx_like+"%";
	      nResults = oResults.load(oConn, aParams);
	    } else {
        if (nullif(nm_table).equalsIgnoreCase("k_contact_company"))
	        nResults = oResults2.load(oConn, new Object[]{gu_workarea,tx_like,tx_like+"%",tx_like+"%"});
      }
    }

    oConn.close("autocomplete");
  }
  catch (SQLException e) {
    if (oConn!=null)
      if (!oConn.isClosed()) {
        oConn.close("autocomplete");
      }
    oConn = null;
    // out.write(e.getClass().getName() + " " + e.getMessage() + " " + tx_like);
    response.sendRedirect (response.encodeRedirectUrl ("../common/errmsg.jsp?title=" + e.getClass().getName() + "&desc=" + e.getMessage() + " tx_like="+tx_like+"&resume=_back"));
  }
  
  if (null==oConn) return;    
  oConn = null;

  out.write("<?xml version=\"1.0\" encoding=\"utf-8\" ?><results count=\""+String.valueOf(nResults)+"\">");

  if (nullif(nm_table).equalsIgnoreCase("k_contact_company")) {
    for (int r=0; r<nResults; r++) {
      out.write("<rs id=\""+oResults.getStringNull(0,r,oResults.getStringNull(1,r,""))+"\" info=\""+Gadgets.removeChars(oResults.getStringNull(3,r,"").equalsIgnoreCase(tx_like) ? oResults.getStringNull(2,r,"") : oResults.getStringNull(3,r,""), "\"'\n\r")+"\"><![CDATA["+oResults.getStringNull(2,r,"")+"]]></rs>");
    }
  } else if (nullif(nm_table).equalsIgnoreCase("k_contact_telephone")) {
    for (int r=0; r<nResults; r++) {
      if (!oResults.isNull(0,r)) if (oResults.getString(0,r).startsWith(tx_like)) out.write("<rs id=\"work_phone"  +String.valueOf(r)+"\" info=\""+oResults.getString(0,r)+"\"><![CDATA["+oResults.getString(0,r)+"]]></rs>");
      if (!oResults.isNull(1,r)) if (oResults.getString(1,r).startsWith(tx_like)) out.write("<rs id=\"direct_phone"+String.valueOf(r)+"\" info=\""+oResults.getString(1,r)+"\"><![CDATA["+oResults.getString(1,r)+"]]></rs>");
      if (!oResults.isNull(2,r)) if (oResults.getString(2,r).startsWith(tx_like)) out.write("<rs id=\"home_phone"  +String.valueOf(r)+"\" info=\""+oResults.getString(2,r)+"\"><![CDATA["+oResults.getString(2,r)+"]]></rs>");
      if (!oResults.isNull(3,r)) if (oResults.getString(3,r).startsWith(tx_like)) out.write("<rs id=\"mov_phone"   +String.valueOf(r)+"\" info=\""+oResults.getString(3,r)+"\"><![CDATA["+oResults.getString(3,r)+"]]></rs>");
      if (!oResults.isNull(4,r)) if (oResults.getString(4,r).startsWith(tx_like)) out.write("<rs id=\"other_phone" +String.valueOf(r)+"\" info=\""+oResults.getString(4,r)+"\"><![CDATA["+oResults.getString(4,r)+"]]></rs>");
    }

  } else {
    for (int r=0; r<nResults; r++) {
      out.write("<rs id=\""+oResults.getString(0,r)+"\" info=\""+oResults.getStringNull(2,r,"")+"\"><![CDATA["+oResults.getString(1,r)+"]]></rs>");
    }
	}
  out.write("</results>");

  /*
  DebugFile.write("<?xml version=\"1.0\" encoding=\"utf-8\" ?><results count=\""+String.valueOf(nResults)+"\">");
  for (int r=0; r<nResults; r++) {
    DebugFile.write("<rs id=\""+oResults.getString(0,r)+"\" info=\""+oResults.getStringNull(2,r,"")+"\"><![CDATA["+oResults.getString(1,r)+"]]></rs>");
  }
  DebugFile.write("</results>");
  */

%>
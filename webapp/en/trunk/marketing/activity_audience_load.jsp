<%@ page import="java.net.URLDecoder,java.util.ListIterator,java.io.IOException,java.net.URLDecoder,com.knowgate.acl.ACL,com.knowgate.workareas.WorkArea,com.knowgate.debug.DebugFile,com.knowgate.debug.StackTraceUtil,com.knowgate.dataobjs.DB,com.knowgate.dataobjs.DBAudit,com.knowgate.dataobjs.DBColumn,com.knowgate.dataobjs.DBCommand,com.knowgate.jdc.JDCConnection,com.knowgate.misc.Gadgets,com.knowgate.hipergate.Address,com.knowgate.crm.Contact,com.knowgate.marketing.ActivityAudience,com.knowgate.marketing.ActivityAudienceLoader,com.knowgate.crm.DistributionList,com.knowgate.hipermail.SendMail" language="java" session="false" contentType="text/plain;charset=UTF-8" %><%@ include file="../methods/dbbind.jsp" %><%@ include file="../methods/clientip.jspf" %><% 

  JDCConnection oConn = null;  
  ActivityAudienceLoader oLodr = new ActivityAudienceLoader();
	ListIterator<DBColumn> oIter;
	Contact oCont;
	Address oAddr;
  String sColName;
  int iColIndex;
  DBColumn oColn;

  final String PAGE_NAME = "activity_audience_load";

  final String gu_workarea = request.getParameter("gu_workarea");
  final String gu_writer = request.getParameter("gu_writer");
  final String tx_pwd = request.getParameter("tx_pwd");
  final String gu_list = request.getParameter("gu_list");
  final String mm_machine = request.getParameter("mm_machine");
  final String tx_colnames = request.getParameter("tx_colnames");
  final String tx_colvalues = URLDecoder.decode(request.getParameter("tx_colvalues"),"UTF-8");
  final char tx_coldelimiter = request.getParameter("tx_coldelimiter").charAt(0);


  final String[] aColNames = Gadgets.split(tx_colnames,tx_coldelimiter);
  final String[] aColValues = Gadgets.split(tx_colvalues,tx_coldelimiter);
  final int nCols = aColNames.length;
  
  if (nCols!=aColValues.length) throw new ArrayIndexOutOfBoundsException("There are "+String.valueOf(nCols)+" column names but "+String.valueOf(aColValues.length)+" values");

  final String tx_email = aColValues[Gadgets.search(aColNames, "tx_email")];
  final String sn_passport = aColValues[Gadgets.search(aColNames, "sn_passport")];

  int iFlags = ActivityAudienceLoader.MODE_APPENDUPDATE;

	String gu_address = null;
  String gu_contact = null;

  try {
    oConn = GlobalDBBind.getConnection(PAGE_NAME);

		short iAuth = ACL.(oConn, gu_writer, tx_pwd, ACL.PWD_CLEAR_TEXT);
		
		if (iAuth<0) throw new SecurityException(ACL.getErrorMessage(iAuth));
		
		if (!WorkArea.isAnyRole(oConn, gu_workarea, gu_writer)) throw new SecurityException(ACL.getErrorMessage(ACL.WORKAREA_ACCESS_DENIED));

    oConn.setAutoCommit(false);

		// *****************************************************************************************************************************
		// This code prevents any data at k_contacts o k_addresses table to be lost by an empty UPDATE comming from the activity loader.
		// The columns that are not empty at activity input are overwritten, but no old columns are erased.
	  // The ActivityAudienceLoader flags are set for updating k_contacts and/or k_addresses
	  // according to the new data e-mail and passport number (if any of them exist).
	  		
	  if (tx_email.length()>0) {

      // *********************************************************
      // Do not add the same attendant twice to any given activity
      String[] aFormerData = DBCommand.queryStrs(oConn, "SELECT c.gu_contact,d.gu_address FROM k_x_activity_audience a, k_contacts c, k_x_contact_addr x, k_addresses d WHERE a.gu_contact=c.gu_contact AND c.gu_contact=x.gu_contact AND x.gu_address=d.gu_address AND "+DBBind.Functions.LOWER+"(d.tx_email)='"+tx_email.toLowerCase()+"'");
      if (aFormerData!=null) {
			  oCont = new Contact(oConn, aFormerData[0]);
	      oAddr = new Address(oConn, aFormerData[1]);
	      for (int n=0; n<nCols; n++) {
	        String sColName = aColNames[n];
	        if (aColValues[n].length()>0) {
	          if (sColName.equals("tx_name") || sColName.equals("tx_surname") || sColName.equals("tp_passport") || sColName.equals("sn_passport") || sColName.equals("de_title"))
	            oCont.replace(sColName, aColValues[n]);
	          else if (sColName.equals("ny_age"))
	            oCont.replace(sColName, Short.parseShort(aColValues[n]));
	          else if (sColName.equals("tp_street") || sColName.equals("nm_street") || sColName.equals("nu_street") ||
	          	       sColName.equals("id_country") || sColName.equals("nm_country") || sColName.equals("tx_addr1") ||
	          	       sColName.equals("id_state") || sColName.equals("nm_state") || sColName.equals("tx_addr2") ||
	          	       sColName.equals("mn_city") || sColName.equals("zipcode") || sColName.equals("tx_email_alt") ||
	          	       sColName.equals("work_phone") || sColName.equals("direct_phone") || sColName.equals("mov_phone"))
	            oAddr.replace(sColName, aColValues[n]);
	        }
	      } // next
	      oCont.store(oConn);
	      oAddr.store(oConn);
        oConn.commit();
    		out.write("1.0:OK");
    		oConn.close(PAGE_NAME);
    		return;
      } // fi


	    // Get address GUID for an e-mail
		  gu_address = Address.getIdFromEmail(oConn, tx_email, gu_workarea);

			// If the Address does not exist then let ActivityAudienceLoader create it
		  if (gu_address==null) {

		    iFlags |= ActivityAudienceLoader.WRITE_CONTACTS|ActivityAudienceLoader.WRITE_ADDRESSES;

		  } else {
				aColValues[Gadgets.search(aColNames, "gu_address")] = gu_address;

			  // If the Address already exists overwrite new columns only
				oAddr = new Address(oConn, gu_address);
				oIter = oAddr.getTable(oConn).getColumns().listIterator();
		    while (oIter.hasNext()) {
		      oColn = oIter.next();
		      sColName = oColn.getName();
		      iColIndex = Gadgets.search(aColNames, sColName);
		      if (iColIndex!=-1) {
		        if (aColValues[iColIndex].length()>0) {
		          oAddr.replace(sColName, aColValues[iColIndex], oColn.getSqlType());
		        }
		      } // fi (iColIndex!=-1)
		    } // wend
		    oAddr.store(oConn);

				// Try to find the Contact corresponding to the already existing Address		    
		    gu_contact = DBCommand.queryStr(oConn, "SELECT "+DB.gu_contact+" FROM "+DB.k_x_contact_addr+" WHERE "+DB.gu_address+"='"+gu_address+"'"+(sn_passport.length()>0 ? " OR "+DB.gu_contact+" IN (SELECT "+DB.gu_contact+" FROM "+DB.k_contacts+" WHERE "+DB.gu_workarea+"='"+gu_workarea+"' AND "+DB.sn_passport+"='"+sn_passport+"')" : ""));

		    if (gu_contact==null) {

		      // If the contact does not exist, let ActivityAudienceLoader create it
		      iFlags |= ActivityAudienceLoader.WRITE_CONTACTS;

		    } else {
				  aColValues[Gadgets.search(aColNames, "gu_contact")] = gu_contact;

			    // If the Contact already exists overwrite new columns only
				  oCont = new Contact(oConn, gu_contact);
				  oIter = oCont.getTable(oConn).getColumns().listIterator();
		      while (oIter.hasNext()) {
		        oColn = oIter.next();
		        sColName = oColn.getName();
		        iColIndex = Gadgets.search(aColNames, sColName);
		        if (iColIndex!=-1) {
		          if (aColValues[iColIndex].length()>0) {
		            oCont.replace(sColName, aColValues[iColIndex], oColn.getSqlType());
		          }
		        } // fi (iColIndex!=-1)
		      } // wend
		      oCont.store(oConn);
		    }
		  } // fi (gu_address)
		} else {
		  
		  // If there is no-email, try to search the Contact by the passport number
		  if (sn_passport.length()>0) {

 		    gu_contact = DBCommand.queryStr(oConn, "SELECT "+DB.gu_contact+" FROM "+DB.k_contacts+" WHERE "+DB.gu_workarea+"='"+gu_workarea+"' AND "+DB.sn_passport+"='"+sn_passport+"'");

		    if (gu_contact==null) {

		      iFlags |= ActivityAudienceLoader.WRITE_CONTACTS;

		    } else {
				  aColValues[Gadgets.search(aColNames, "gu_contact")] = gu_contact;

				  oCont = new Contact(oConn, gu_contact);
				  oIter = oCont.getTable(oConn).getColumns().listIterator();
		      while (oIter.hasNext()) {
		        oColn = oIter.next();
		        sColName = oColn.getName();
		        iColIndex = Gadgets.search(aColNames, sColName);
		        if (iColIndex!=-1) {
		          if (aColValues[iColIndex].length()>0) {
		            oCont.replace(sColName, aColValues[iColIndex], oColn.getSqlType());
		          }
		        } // fi (iColIndex!=-1)
		      } // wend
		      oCont.store(oConn);					
		  	}

		  } else {

		    iFlags |= ActivityAudienceLoader.WRITE_CONTACTS;

		  }
		} // fi (tx_email)

	  // End of code for preventing accidental lost of data
		// *****************************************************************************************************************************

    oLodr.prepare(oConn, null);
    oLodr.storeLine(oConn, gu_workarea, iFlags, tx_colnames, tx_coldelimiter, tx_colvalues);

		String sFullName = "";
		if (oLodr.get("tx_name")!=null) sFullName += (String) oLodr.get("tx_name");
		if (oLodr.get("tx_surname")!=null) sFullName += " " + (String) oLodr.get("tx_surname");
		if (oLodr.get("tx_email")!=null) sFullName += " <" + (String) oLodr.get("tx_email") + ">";
		sFullName = Gadgets.left(sFullName, 254);

		if (gu_list.length()>0 && oLodr.get("gu_contact")!=null) {
		  DistributionList oList = new DistributionList();
		  oList.put (DB.gu_list, oList);
		  oList.put (DB.tp_list, DistributionList.TYPE_STATIC);
		  oList.put (DB.gu_workarea, gu_workarea);
		  oList.addContact(oConn, (String) oLodr.get("gu_contact"));
		}

    DBAudit.log(oConn, ActivityAudience.ClassId, "NACA", gu_writer,
    					 (String) oLodr.get(ActivityAudienceLoader.gu_activity),
    					 (String) oLodr.get(ActivityAudienceLoader.gu_contact), 0,
    						getClientIP(request), mm_machine, sFullName);

    oConn.commit();

    out.write("1.0:OK");
      
    oConn.close(PAGE_NAME);
  }
  catch (Exception e) {
    disposeConnection(oConn,PAGE_NAME);
    oConn=null;
    out.write("ERROR "+e.getClass().getName()+" "+e.getMessage()+" "+StackTraceUtil.getStackTrace(e));
    if (DebugFile.trace) {
      DebugFile.writeln("<JSP:"+PAGE_NAME+".jsp "+e.getClass().getName()+" "+e.getMessage()+"\n"+StackTraceUtil.getStackTrace(e));
    }
  }
%>

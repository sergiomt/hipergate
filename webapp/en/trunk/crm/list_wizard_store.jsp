<%@ page import="com.knowgate.debug.*,java.net.URLDecoder,java.io.File,java.io.FileNotFoundException,java.io.IOException,java.sql.Connection,java.sql.SQLException,java.sql.PreparedStatement,com.knowgate.jdc.*,com.knowgate.dataobjs.*,com.knowgate.acl.*,com.knowgate.crm.*,com.knowgate.misc.Environment,com.knowgate.hipergate.Category,com.knowgate.hipergate.QueryByForm" language="java" session="false" contentType="text/html;charset=UTF-8" %>
<%@ include file="../methods/dbbind.jsp" %><%@ include file="../methods/cookies.jspf" %><%@ include file="../methods/authusrs.jspf" %><%@ include file="../methods/reqload.jspf" %><%@ include file="../methods/nullif.jspf" %><%
/*
  Copyright (C) 2003  Know Gate S.L. All rights reserved.
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
  if (DebugFile.trace) DebugFile.writeln("Begin list_wizard_store.jsp");

  if (autenticateSession(GlobalDBBind, request, response)<0) return;

  // String sWebServer = Environment.getProfileVar(GlobalDBBind.getProfileName(),"webserver","");
      
  String id_domain = request.getParameter("id_domain");
  String n_domain = request.getParameter("n_domain");
  String gu_workarea = request.getParameter("gu_workarea");
  String n_list = request.getParameter("tx_subject");
  String id_user = getCookie (request, "userid", null);
  
  String gu_list = request.getParameter("gu_list");
  String gu_query = request.getParameter("gu_query");
  String tp_list = request.getParameter("tp_list");

  if (null==gu_list) {
    response.sendRedirect (response.encodeRedirectUrl ("../common/errmsg.jsp?title=NullPointerException&desc=missing parameter gu_list&resume=_back"));    
    return;
  }
    
  String caller = nullif(request.getParameter("caller"),"");
  String sOpCode = gu_list.length()>0 ? "NLST" : "MLST";
  String sWhere = "";
  
  DBSubset oMembers = null;
  int iMembersCount = 0;
  String sQuery = "";
      
  DistributionList oList = new DistributionList();
  DirectList oDirect = new DirectList();
  int[] Checks = null;

  String sTempDir = Environment.getProfileVar(GlobalDBBind.getProfileName(), "temp", Environment.getTempDir());
  sTempDir = com.knowgate.misc.Gadgets.chomp(sTempDir,java.io.File.separator);
  
  // **************************************************
  // Parsear el fichero de texto si la lista es directa
  
  try {
    if ((tp_list.equals("3")) && (caller.equals("wizard")))
      Checks = oDirect.parseFile(sTempDir + request.getParameter("gu_query") + ".tmp", request.getParameter("desc_file"));
  }
  catch (FileNotFoundException fnfe) {
    response.sendRedirect (response.encodeRedirectUrl ("../common/errmsg.jsp?title=FileNotFoundException&desc=" + sTempDir + request.getParameter("gu_query") + ".tmp " + fnfe.getMessage() + "&resume=_back"));    
    oDirect = null;
  }  
  catch (IOException ioe) {
    response.sendRedirect (response.encodeRedirectUrl ("../common/errmsg.jsp?title=IOException&desc=" + ioe.getMessage() + "&resume=_back"));    
    oDirect = null;
  }
  catch (ArrayIndexOutOfBoundsException aiob) {
    try { sWhere = oDirect.getLine(oDirect.errorLine()); } catch (Exception e) { }

    response.sendRedirect (response.encodeRedirectUrl ("../common/errmsg.jsp?title=ArrayIndexOutOfBoundsException&desc=" + aiob.getMessage() + " at line " + String.valueOf(oDirect.errorLine()) + " " + nullif(sWhere) + "&resume=_back"));
    oDirect = null;
  }
  catch (NullPointerException npe) {
    response.sendRedirect (response.encodeRedirectUrl ("../common/errmsg.jsp?title=NullPointerException&desc=" + npe.getMessage() + "&resume=_back"));    
    oDirect = null;
  }
  catch (RuntimeException rte) {
    response.sendRedirect (response.encodeRedirectUrl ("../common/errmsg.jsp?title=RuntimeException&desc=" + rte.getMessage() + "&resume=_back"));    
    oDirect = null;
  }

  if (null==oDirect) return;
  
  JDCConnection oConn = null;
  Connection    oCon2 = null;
  
  try {
    
    oConn = GlobalDBBind.getConnection("list_wizard_store");
    
    // *************************************************************
    // Primero guardar el registro principal de la lista en si misma
      
    loadRequest(oConn, request, oList);
    if (nullif(request.getParameter("gu_category")).length()>0)
      oList.replace(DB.gu_category, request.getParameter("gu_category"));
    else
      oList.remove(DB.gu_category);

    // Las listas directas no tienen query asociada
    if (null!=tp_list) if (tp_list.equals("3")) oList.remove(DB.gu_query);

    oConn.setAutoCommit (true);
    
    oList.store(oConn);
    
    gu_list = oList.getString("gu_list");

  }
  catch (SQLException e) {  
    if (oConn!=null)
      if (!oConn.isClosed()) {
        oConn.close("list_wizard_store");
      }
    oConn = null;
    response.sendRedirect (response.encodeRedirectUrl ("../common/errmsg.jsp?title=SQLException&desc=" + e.getMessage() + "&resume=_back"));
  }
  catch (NumberFormatException e) {
    if (oConn!=null)
      if (!oConn.isClosed()) {
        oConn.close();      
      }
    oConn = null;
    response.sendRedirect (response.encodeRedirectUrl ("../common/errmsg.jsp?title=NumberFormatException&desc=" + e.getMessage() + "&resume=_back"));
  }
      
  if (oConn==null) return;
  
  // ***************************************************************************************
  // Almacenar miembros si es lista estática y si la llamada proviene del wizard de creación

  if ((tp_list.equals("1")) && (caller.equals("wizard"))) {
    
    try {
      QueryByForm oQuery = new QueryByForm(oConn, DB.k_member_address, "b", gu_query);
      sWhere = oQuery.composeSQL();
      oQuery = null;
    
      // Recuperar miembros
      oMembers = new DBSubset (DB.k_member_address + " b", 
                               DB.gu_company + "," + DB.gu_contact + "," + DB.nm_legal + "," + DB.tx_name + "," + DB.tx_surname + ", " + DB.tx_email + ", " + DB.gu_address,
        		       						 DB.gu_workarea + "='" + gu_workarea + "' AND " + sWhere, 0);
      iMembersCount = oMembers.load(oConn);

      oConn.close("list_wizard_store");

      oCon2 = GlobalDBBind.getConnection(GlobalDBBind.getProperty("dbuser"), GlobalDBBind.getProperty("dbpassword"));
      oCon2.setAutoCommit (true);

      sQuery = "INSERT INTO " + DB.k_x_list_members + " (gu_list,tx_email,mov_phone,tx_name,tx_surname,dt_created,gu_company,gu_contact) SELECT '" + gu_list + "',tx_email,mov_phone,";

      if (DebugFile.trace)
        DebugFile.writeln("Connection.prepareStatement(" + sQuery + "nm_commercial,tx_surname,dt_created,gu_company,gu_contact FROM k_member_address WHERE gu_workarea='" + gu_workarea + "' AND gu_company=? AND gu_contact IS NULL AND gu_address=?)");
        
      PreparedStatement oInsertCompany = oCon2.prepareStatement(sQuery + "nm_commercial,tx_surname,dt_created,gu_company,gu_contact FROM k_member_address WHERE gu_workarea='" + gu_workarea + "' AND gu_company=? AND gu_contact IS NULL AND gu_address=?");

      if (DebugFile.trace)
        DebugFile.writeln("Connection.prepareStatement(" + sQuery + "tx_name,tx_surname,dt_created,gu_company,gu_contact FROM k_member_address WHERE gu_workarea='" + gu_workarea + "' AND gu_contact=? AND gu_company IS NULL AND gu_address=?)");
        
      PreparedStatement oInsertContact = oCon2.prepareStatement(sQuery + "tx_name,tx_surname,dt_created,gu_company,gu_contact FROM k_member_address WHERE gu_workarea='" + gu_workarea + "' AND gu_contact=? AND gu_company IS NULL AND gu_address=?");

      if (DebugFile.trace)
        DebugFile.writeln("Connection.prepareStatement(" + sQuery + "tx_name,tx_surname,dt_created,gu_company,gu_contact FROM k_member_address WHERE gu_workarea='" + gu_workarea + "' AND gu_company=? AND gu_contact=? AND gu_address=?)");
        
      PreparedStatement oInsertBoth    = oCon2.prepareStatement(sQuery + "tx_name,tx_surname,dt_created,gu_company,gu_contact FROM k_member_address WHERE gu_workarea='" + gu_workarea + "' AND gu_company=? AND gu_contact=? AND gu_address=?");
      
      for (int i=0; i<iMembersCount; i++) {              
        if (oMembers.isNull(0,i)) { 
          try {
            oInsertContact.setString(1, oMembers.getString(1,i));
            oInsertContact.setString(2, oMembers.getString(6,i)); 
            oInsertContact.executeUpdate();
          } catch (SQLException e) {            
            if (DebugFile.trace) DebugFile.writeln(e.getMessage() + " Duplicated member "+oMembers.getString(1,i)+" removed");
            oInsertContact.close();
            oInsertContact = oConn.prepareStatement(sQuery + "tx_name,tx_surname,dt_created,gu_company,gu_contact FROM k_member_address WHERE gu_workarea='" + gu_workarea + "' AND gu_contact=? AND gu_company IS NULL AND gu_address=?");
          }
        }
        else {
          if (oMembers.isNull(1,i)) { 
            try {
              oInsertCompany.setString(1, oMembers.getString(0,i)); 
              oInsertCompany.setString(2, oMembers.getString(6,i)); 
              oInsertCompany.executeUpdate();
            } catch (SQLException e) {
              if (DebugFile.trace) DebugFile.writeln(e.getMessage() + " Duplicated member "+oMembers.getString(0,i)+" removed");
              oInsertCompany.close();
              oInsertCompany = oConn.prepareStatement(sQuery + "nm_commercial,tx_surname,dt_created,gu_company,gu_contact FROM k_member_address WHERE gu_workarea='" + gu_workarea + "' AND gu_company=? AND gu_contact IS NULL AND gu_address=?");
            }
          }
          else { 
            try {
              oInsertBoth.setString(1, oMembers.getString(0,i)); 
              oInsertBoth.setString(2, oMembers.getString(1,i)); 
              oInsertBoth.setString(3, oMembers.getString(6,i)); 
              oInsertBoth.executeUpdate();
            } catch (SQLException e) {
              if (DebugFile.trace) DebugFile.writeln(e.getMessage() + " Duplicated member "+oMembers.getString(0,i)+" removed");
              oInsertBoth.close();
      				oInsertBoth = oConn.prepareStatement(sQuery + "tx_name,tx_surname,dt_created,gu_company,gu_contact FROM k_member_address WHERE gu_workarea='" + gu_workarea + "' AND gu_company=? AND gu_contact=? AND gu_address=?");
            }
          } // end if
        }                              
    } // next()
    
    oInsertBoth.close();
    oInsertCompany.close();
    oInsertContact.close();
    
    if (DebugFile.trace) DebugFile.writeln(String.valueOf(iMembersCount) + " candidate members processed");

	  oCon2.close();
	  oCon2=null;

    } catch (SQLException e) {  
      if (oConn!=null)
        if (!oConn.isClosed()) {
          oConn.close("list_wizard_store");
        }
        oConn = null;
      if (oCon2!=null)
        if (!oCon2.isClosed()) {
          oCon2.close();
        }
        oCon2 = null;
      response.sendRedirect (response.encodeRedirectUrl ("../common/errmsg.jsp?title=SQLException&desc=" + e.getMessage() + "&resume=_back"));
    }
    catch (NullPointerException e) {  
      if (oConn!=null)
        if (!oConn.isClosed()) {
          oConn.close("list_wizard_store");          
        }
        oConn = null;
      response.sendRedirect (response.encodeRedirectUrl ("../common/errmsg.jsp?title=SQLException&desc=" + e.getMessage() + "&resume=_back"));
    }

    if (null==oConn) return;

    if (!oConn.isClosed()) oConn.close("list_wizard_store");
    oConn = GlobalDBBind.getConnection("list_wizard_store");
    oConn.setAutoCommit (true);
        
    oMembers = null;

  } // fi (tp_list=="1" && caller=="wizard")

  // *****************************************************************************************
  // Almacenar miembros si es lista directa en y si la llamada proviene del wizard de creación

  else if ((tp_list.equals("3")) && (caller.equals("wizard"))) {
        
    try {
      oCon2 = GlobalDBBind.getConnection(GlobalDBBind.getProperty("dbuser"), GlobalDBBind.getProperty("dbpassword"));
      oCon2.setAutoCommit (true);
      oDirect.updateList((Connection) oCon2, gu_list, (short) 1);
			oCon2.close();
    }

    catch (SQLException sqle) {            
      if (oCon2!=null) if (!oCon2.isClosed()) { oConn.close(); }
      if (oConn!=null) if (!oConn.isClosed()) { oConn.close("list_wizard_store"); }
      oConn = null;
      response.sendRedirect (response.encodeRedirectUrl ("../common/errmsg.jsp?title=SQLException&desc=" + sqle.getMessage() + "&resume=_back"));
    }
    catch (StringIndexOutOfBoundsException siob) {
      if (oConn!=null) if (!oConn.isClosed()) { oConn.close("list_wizard_store"); }
      oConn = null;
      try { sWhere = oDirect.getLine(oDirect.errorLine()); } catch (Exception e) { }
      response.sendRedirect (response.encodeRedirectUrl ("../common/errmsg.jsp?title=StringIndexOutOfBoundsException&desc=" + siob.getMessage() + " at line " + String.valueOf(oDirect.errorLine()) + " " + sWhere + "&resume=_back"));
    }
    catch (ArrayIndexOutOfBoundsException aiob) {
      if (oConn!=null) if (!oConn.isClosed()) { oConn.close("list_wizard_store"); }
      oConn = null;
      try { sWhere = oDirect.getLine(oDirect.errorLine()); } catch (Exception e) { }
      response.sendRedirect (response.encodeRedirectUrl ("../common/errmsg.jsp?title=ArrayIndexOutOfBoundsException&desc=" + aiob.getMessage() + " at line " + String.valueOf(oDirect.errorLine()) + " " + sWhere + "&resume=_back"));
    }    
    catch (NullPointerException e) {
      if (oConn!=null) if (!oConn.isClosed()) { oConn.close("list_wizard_store"); }
      oConn = null;
      response.sendRedirect (response.encodeRedirectUrl ("../common/errmsg.jsp?title=NullPointerException&desc=" + e.getMessage() + "&resume=_back"));
    }    
    catch (Exception e) {
      if (oConn!=null) if (!oConn.isClosed()) { oConn.close("list_wizard_store"); }
      oConn = null;
      response.sendRedirect (response.encodeRedirectUrl ("../common/errmsg.jsp?title=Error&desc=" + e.getMessage() + "&resume=_back"));
    }    
    finally {

      File oTmpDlte = new File(sTempDir + request.getParameter("gu_query") + ".tmp");

      if (oTmpDlte.exists()) {
        if (DebugFile.trace) DebugFile.writeln("File.delete(" + sTempDir + request.getParameter("gu_query") + ".tmp" + ")");

        oTmpDlte.delete();
      }
      oTmpDlte = null;
    }
        
  } // fi (tp_list=="3" && caller=="wizard")
    
  if (oConn!=null) {
  
    // [~//Finalización~]
    oConn.close("list_wizard_store"); 
    oConn = null;
    
    if (DebugFile.trace) DebugFile.writeln("End list_wizard_store.jsp");
    
    out.write("<HTML><HEAD><TITLE>Wait...</TITLE><SCRIPT LANGUAGE='JavaScript' TYPE='text/javascript'>");
    out.write("window.opener.location.reload(true);");
    out.write("window.resizeTo(600,480);");
    out.write("window.location = 'list_edit.jsp?id_domain=" + id_domain + "&n_domain='+escape('" + n_domain + "') + '&gu_list=" + gu_list + "&n_list=' + escape('" + n_list+ "');");
    //if (caller.equals("edit")) out.write("self.close();");
    out.write("</SCRIPT></HEAD></HTML>");

  } // fi (oConn!=null)
%>
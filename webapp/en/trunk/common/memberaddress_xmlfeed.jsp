<%@ page import="java.io.IOException,java.sql.PreparedStatement,java.sql.ResultSet,com.knowgate.jdc.JDCConnection,com.knowgate.dataobjs.DB,com.knowgate.acl.ACLUser,com.knowgate.hipergate.Address,com.knowgate.crm.MemberAddress" language="java" session="false" contentType="text/xml;charset=UTF-8" %><%@ include file="../methods/dbbind.jsp" %><%@ include file="../methods/cookies.jspf" %><%@ include file="../methods/authusrs.jspf" %><%   

  if (autenticateSession(GlobalDBBind, request, response)<0) return;
  
  String sTxEmail = request.getParameter("email");
  String sSnPassp = request.getParameter("passp");
  String sNuPhone = request.getParameter("phone");
  String sGuWorkA = request.getParameter("workarea");
  String sGuWrtr = request.getParameter("writer");

  if (null==sTxEmail) {
    out.write ("error NullPointerException parameter email is required");
    return;
  }

  if (null==sGuWorkA) {
    out.write ("error NullPointerException parameter workarea is required");
    return;
  }

  JDCConnection oConn = null;  
  String sAddrGuid = null;
  MemberAddress oMmbr = null;
  boolean bPrivate;

  try {
    oConn = GlobalDBBind.getConnection("memberaddress_xmlfeed");
    
    if (sTxEmail!=null) {
    	if (sTxEmail.length()>0) {
        PreparedStatement oAddr = oConn.prepareStatement("SELECT " + DB.gu_address + " FROM " + DB.k_member_address + " WHERE " + DB.tx_email + "=? AND " + DB.gu_workarea + "=?",
                                                         ResultSet.TYPE_FORWARD_ONLY,  ResultSet.CONCUR_READ_ONLY);
				oAddr.setString(1, sTxEmail);
				oAddr.setString(2, sGuWorkA);
				ResultSet rAddr = oAddr.executeQuery();
				if (rAddr.next())
          sAddrGuid = rAddr.getString(1);
        else
          sAddrGuid = null;
        rAddr.close();
        oAddr.close();
    	}
    }
    
    if (sAddrGuid==null & sSnPassp!=null) {
    	if (sSnPassp.length()>0) {
    		PreparedStatement oStmt = oConn.prepareStatement("SELECT "+DB.gu_address+" FROM "+DB.k_member_address+" WHERE "+DB.gu_workarea+"=? AND "+DB.sn_passport+"=?");
    		oStmt.setString(1, sGuWorkA);
    		oStmt.setString(2, sSnPassp);
    		ResultSet oRSet = oStmt.executeQuery();
    		if (oRSet.next())
    			sAddrGuid = oRSet.getString(1);
    		oRSet.close();
    		oStmt.close();
    	}
    }

    if (sAddrGuid==null & sNuPhone!=null) {
    	if (sNuPhone.length()>0) {
    		PreparedStatement oStmt = oConn.prepareStatement("SELECT "+DB.gu_address+" FROM "+DB.k_member_address+" WHERE "+DB.gu_workarea+"=? AND ("+DB.direct_phone+"=? OR "+DB.work_phone+"= OR "+DB.mov_phone+"=?)");
    		oStmt.setString(1, sGuWorkA);
    		oStmt.setString(2, sNuPhone);
    		oStmt.setString(3, sNuPhone);
    		oStmt.setString(4, sNuPhone);
    		ResultSet oRSet = oStmt.executeQuery();
    		if (oRSet.next())
    			sAddrGuid = oRSet.getString(1);
    		oRSet.close();
    		oStmt.close();
    	}
    }
    
    if (null!=sAddrGuid) {
      oMmbr = new MemberAddress(oConn, sAddrGuid);
      // Hide private contacts of other people when performing lookup
      if (oMmbr.isNull(DB.bo_private))
        bPrivate = false;
      else
        bPrivate = (oMmbr.getShort(DB.bo_private)!=(short)0);
      if (!oMmbr.getStringNull(DB.gu_writer,"").equals(sGuWrtr) && bPrivate) oMmbr = null;
    }
    
    oConn.close("memberaddress_xmlfeed");
  }
  catch (Exception e) {  
    if (oConn!=null)
      if (!oConn.isClosed()) {
        oConn.close("memberaddress_xmlfeed");      
      }
    oConn = null;
    out.write ("<MemberAddress><error>"+e.getClass().getName()+" "+e.getMessage()+"</error></MemberAddress>");
  }
  
  if (null==oConn) return;    
  oConn = null;

  if (null==oMmbr)
    out.write ("<MemberAddress/>");
  else
    out.write (oMmbr.toXML());
%>
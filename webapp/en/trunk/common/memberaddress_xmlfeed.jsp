<%@ page import="java.io.IOException,com.knowgate.jdc.JDCConnection,com.knowgate.dataobjs.DB,com.knowgate.acl.ACLUser,com.knowgate.hipergate.Address,com.knowgate.crm.MemberAddress" language="java" session="false" contentType="text/xml;charset=UTF-8" %><%@ include file="../methods/dbbind.jsp" %><%   

  String sTxEmail = request.getParameter("email");
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
        
    sAddrGuid = Address.getIdFromEmail(oConn, sTxEmail, sGuWorkA);
    
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
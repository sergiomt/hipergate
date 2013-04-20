<%@ page import="java.util.Date,java.text.SimpleDateFormat,java.math.BigDecimal,java.io.IOException,java.net.URLDecoder,java.sql.Timestamp,java.sql.Types,java.sql.PreparedStatement,java.sql.SQLException,com.knowgate.jdc.JDCConnection,com.knowgate.dataobjs.*,com.knowgate.training.*" language="java" session="false" contentType="text/plain;charset=UTF-8" %>
<%@ include file="../methods/dbbind.jsp" %><%@ include file="../methods/cookies.jspf" %><%@ include file="../methods/authusrs.jspf" %><%@ include file="../methods/nullif.jspf" %><% 

  /* Autenticate user cookie */  
  if (autenticateSession(GlobalDBBind, request, response)<0) return;
      
  String id_domain = request.getParameter("id_domain");
  String gu_workarea = request.getParameter("gu_workarea");
  String gu_acourse = request.getParameter("gu_acourse");
  String bo_payinfo = nullif(request.getParameter("bo_payinfo"),"1");

  JDCConnection oConn = null;  
  PreparedStatement oStmt = null;
  PreparedStatement oStm1 = null;
  PreparedStatement oStm2 = null;
  PreparedStatement oStm3 = null;
  
  AcademicCourseBooking[] aBooks = null;
  AcademicCourse oAcrs = new AcademicCourse();
  SimpleDateFormat oFmt = new SimpleDateFormat("yyyy-MM-dd HH:mm:ss");
  int iBooks = 0;

  try {
    oConn = GlobalDBBind.getConnection("bookings_edit_store");

    oAcrs.load(oConn, new Object[]{gu_acourse});
    
    aBooks = oAcrs.getAllBookings(oConn);    
    iBooks = aBooks.length;
    
    oConn.setAutoCommit(false);

    oStmt = oConn.prepareStatement("UPDATE "+DB.k_x_course_bookings+" SET "+DB.bo_confirmed+"=?,"+DB.bo_waiting+"=?,"+DB.bo_canceled+"=?,"+DB.bo_paid+"=?,"+DB.im_paid+"=? WHERE "+DB.gu_acourse+"=? AND "+DB.gu_contact+"=?");
    oStm1 = oConn.prepareStatement("UPDATE "+DB.k_x_course_bookings+" SET "+DB.bo_confirmed+"=?,"+DB.bo_waiting+"=?,"+DB.bo_canceled+"=? WHERE "+DB.gu_acourse+"=? AND "+DB.gu_contact+"=?");
    oStm2 = oConn.prepareStatement("UPDATE "+DB.k_x_course_bookings+" SET "+DB.bo_confirmed+"=?,"+DB.bo_waiting+"=?,"+DB.bo_canceled+"=?,"+DB.bo_paid+"=?,"+DB.im_paid+"=?,"+DB.dt_paid+"=? WHERE "+DB.gu_acourse+"=? AND "+DB.gu_contact+"=?");
    oStm3 = oConn.prepareStatement("DELETE FROM "+DB.k_x_course_alumni+" WHERE "+DB.gu_acourse+"=? AND "+DB.gu_alumni+"=?");

    for (int c=0; c<iBooks; c++) {
      String sContactId = aBooks[c].getContact(oConn).getString(DB.gu_contact);
			Short iPaid = Short.parseShort(nullif(request.getParameter(sContactId+"_paid"),"-1"));
			short iCncl = Short.parseShort(nullif(request.getParameter(sContactId+"_canceled"),"0"));
			if (iPaid==-1) {
        oStm1.setShort(1, iCncl!=0 ? (short) 0 : Short.parseShort(nullif(request.getParameter(sContactId+"_confirmed"),"0")));
        oStm1.setShort(2, iCncl!=0 ? (short) 0 : Short.parseShort(nullif(request.getParameter(sContactId+"_waiting"),"0")));
        oStm1.setShort(3, iCncl);
        oStm1.setString(4, request.getParameter("gu_acourse"));
        oStm1.setString(5, sContactId);
        oStm1.executeUpdate();
			} else if (iPaid==0 || nullif(request.getParameter(sContactId+"_date")).length()==0) {
        oStmt.setShort(1, iCncl!=0 ? (short) 0 : Short.parseShort(nullif(request.getParameter(sContactId+"_confirmed"),"0")));
        oStmt.setShort(2, iCncl!=0 ? (short) 0 : Short.parseShort(nullif(request.getParameter(sContactId+"_waiting"),"0")));
        oStmt.setShort(3, iCncl);
        oStmt.setShort(4, iPaid);
        if (request.getParameter(sContactId+"_amount").length()==0)
          oStmt.setNull(5, Types.NUMERIC);
        else
          oStmt.setBigDecimal(5, new BigDecimal(request.getParameter(sContactId+"_amount")));
        oStmt.setString(6, request.getParameter("gu_acourse"));
        oStmt.setString(7, sContactId);
        oStmt.executeUpdate();
      } else {
        oStm2.setShort(1, iCncl!=0 ? (short) 0 : Short.parseShort(nullif(request.getParameter(sContactId+"_confirmed"),"0")));
        oStm2.setShort(2, iCncl!=0 ? (short) 0 : Short.parseShort(nullif(request.getParameter(sContactId+"_waiting"),"0")));
        oStm2.setShort(3, iCncl);
        oStm2.setShort(4, iPaid);
        if (request.getParameter(sContactId+"_amount").length()==0)
          oStm2.setNull(5, Types.NUMERIC);
        else
          oStm2.setBigDecimal(5, new BigDecimal(request.getParameter(sContactId+"_amount")));
        oStm2.setTimestamp(6, new Timestamp(oFmt.parse(request.getParameter(sContactId+"_date")+" 00:00:00").getTime()));
        oStm2.setString(7, request.getParameter("gu_acourse"));
        oStm2.setString(8, sContactId);
        oStm2.executeUpdate();      
      }
      if (iCncl!=0) {
        oStm3.setString(1, request.getParameter("gu_acourse"));
        oStm3.setString(2, sContactId);
      	oStm3.executeUpdate();
      }
    } // next

    oStm3.close();        
    oStm2.close();        
    oStm1.close();        
    oStmt.close();
    oStm2=null;
    oStmt=null;
    
    oConn.commit();
      
    oConn.close("bookings_edit_store");
  }
  catch (SQLException e) {
    if (oStm2!=null) { try { oStm2.close(); } catch (Exception ignore) {}  }
    if (oStmt!=null) { try { oStmt.close(); } catch (Exception ignore) {}  }
    disposeConnection(oConn,"bookings_edit_store");
    oConn = null;
    response.sendRedirect (response.encodeRedirectUrl ("../common/errmsg.jsp?title=SQLException&desc=" + e.getLocalizedMessage() + "&resume=_back"));
  }
  catch (NumberFormatException e) {
    if (oStmt!=null) { try { oStmt.close(); } catch (Exception ignore) {}  }
    disposeConnection(oConn,"bookings_edit_store");
    oConn = null;
    response.sendRedirect (response.encodeRedirectUrl ("../common/errmsg.jsp?title=NumberFormatException&desc=" + e.getMessage() + "&resume=_back"));
  }

  if (null==oConn) return;
  oConn = null;

  response.sendRedirect (response.encodeRedirectUrl ("bookings_edit.jsp?id_domain="+id_domain+"&gu_workarea="+gu_workarea+"&gu_acourse="+gu_acourse+"&bo_confirm=1&bo_payinfo="+bo_payinfo));
%>
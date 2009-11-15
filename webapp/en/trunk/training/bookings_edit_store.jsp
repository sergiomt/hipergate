<%@ page import="java.util.Date,java.text.SimpleDateFormat,java.math.BigDecimal,java.io.IOException,java.net.URLDecoder,java.sql.Timestamp,java.sql.Types,java.sql.PreparedStatement,java.sql.SQLException,com.knowgate.jdc.JDCConnection,com.knowgate.dataobjs.*,com.knowgate.training.*" language="java" session="false" contentType="text/plain;charset=UTF-8" %>
<%@ include file="../methods/dbbind.jsp" %><%@ include file="../methods/cookies.jspf" %><%@ include file="../methods/authusrs.jspf" %><%@ include file="../methods/nullif.jspf" %>
<% 

  /* Autenticate user cookie */
  
  if (autenticateSession(GlobalDBBind, request, response)<0) return;
      
  String id_domain = request.getParameter("id_domain");
  String gu_workarea = request.getParameter("gu_workarea");
  String gu_acourse = request.getParameter("gu_acourse");

  JDCConnection oConn = null;  
  PreparedStatement oStmt = null;
  PreparedStatement oStm2 = null;
  
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
    oStm2 = oConn.prepareStatement("UPDATE "+DB.k_x_course_bookings+" SET "+DB.bo_confirmed+"=?,"+DB.bo_waiting+"=?,"+DB.bo_canceled+"=?,"+DB.bo_paid+"=?,"+DB.im_paid+"=?,"+DB.dt_paid+"=? WHERE "+DB.gu_acourse+"=? AND "+DB.gu_contact+"=?");

    for (int c=0; c<iBooks; c++) {
      String sContactId = aBooks[c].getContact(oConn).getString(DB.gu_contact);
			Short iPaid = Short.parseShort(nullif(request.getParameter(sContactId+"_paid"),"0"));
			if (iPaid==0 || nullif(request.getParameter(sContactId+"_date")).length()==0) {
        oStmt.setShort(1, Short.parseShort(nullif(request.getParameter(sContactId+"_confirmed"),"0")));
        oStmt.setShort(2, Short.parseShort(nullif(request.getParameter(sContactId+"_waiting"),"0")));
        oStmt.setShort(3, Short.parseShort(nullif(request.getParameter(sContactId+"_canceled"),"0")));
        oStmt.setShort(4, iPaid);
        if (request.getParameter(sContactId+"_amount").length()==0)
          oStmt.setNull(5, Types.NUMERIC);
        else
          oStmt.setBigDecimal(5, new BigDecimal(request.getParameter(sContactId+"_amount")));
        oStmt.setString(6, request.getParameter("gu_acourse"));
        oStmt.setString(7, sContactId);
        oStmt.executeUpdate();
      } else {
        oStm2.setShort(1, Short.parseShort(nullif(request.getParameter(sContactId+"_confirmed"),"0")));
        oStm2.setShort(2, Short.parseShort(nullif(request.getParameter(sContactId+"_waiting"),"0")));
        oStm2.setShort(3, Short.parseShort(nullif(request.getParameter(sContactId+"_canceled"),"0")));
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
    } // next

    oStm2.close();        
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

  response.sendRedirect (response.encodeRedirectUrl ("bookings_edit.jsp?id_domain="+id_domain+"&gu_workarea="+gu_workarea+"&gu_acourse="+gu_acourse));
%>
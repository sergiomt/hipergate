<%@ page import="java.util.Date,java.io.IOException,java.net.URLDecoder,java.sql.PreparedStatement,java.sql.ResultSet,java.sql.SQLException,java.sql.Timestamp,com.knowgate.jdc.JDCConnection,com.knowgate.dataobjs.DB,com.knowgate.dataobjs.DBBind,com.knowgate.misc.Calendar,com.knowgate.misc.Gadgets" language="java" session="false" contentType="text/plain;charset=UTF-8" %>
<%@ include file="../methods/dbbind.jsp" %><%@ include file="../methods/cookies.jspf" %><%@ include file="../methods/authusrs.jspf" %><%@ include file="../methods/nullif.jspf" %><% 

  if (autenticateSession(GlobalDBBind, request, response)<0) return;

  String id_domain = request.getParameter("id_domain"); 
  String gu_workarea = request.getParameter("gu_workarea"); 
  String gu_calendar = request.getParameter("gu_calendar");
  String nu_selected = request.getParameter("selected");
  String nu_subselected = request.getParameter("subselected");
  int year = Integer.parseInt(request.getParameter("year"));
  int month = Integer.parseInt(request.getParameter("month"));
  int day = 1;
  int date = 10000*year+100*month+day;
  String[] aWrkDays = Gadgets.split(request.getParameter("workdays"),',');
  int nWrkDays = aWrkDays.length;

  Date oDtFrom = new Date(year-1900,month,1,0,0,0);
  Date oDtTo = new Date(oDtFrom.getTime()+(86400000l*((long)nWrkDays)));
  oDtTo.setHours(23);
  oDtTo.setMinutes(59);
  oDtTo.setSeconds(59);  

  short hh_start1 = Short.parseShort(request.getParameter("hh_start1"));
  short mi_start1 = Short.parseShort(request.getParameter("mi_start1"));
  short hh_end1   = Short.parseShort(request.getParameter("hh_end1"));
  short mi_end1   = Short.parseShort(request.getParameter("mi_end1"));
  short hh_start2 = Short.parseShort(request.getParameter("hh_start2"));
  short mi_start2 = Short.parseShort(request.getParameter("mi_start2"));
  short hh_end2   = Short.parseShort(request.getParameter("hh_end2"));  
  short mi_end2   = Short.parseShort(request.getParameter("mi_end2"));
                  
  JDCConnection oConn = null;  
  PreparedStatement oIns = null;
  PreparedStatement oUpd = null;
  PreparedStatement oCal = null;
  

  final short YES = (short) 1;
  final short NO = (short) 0;
  int nAffected;
  
  try {
    oConn = GlobalDBBind.getConnection("workcalendar_setdays_store");

    oConn.setAutoCommit(false);

    oIns = oConn.prepareStatement("INSERT INTO "+DB.k_working_time+" (dt_day,gu_calendar,bo_working_time,hh_start1,mi_start1,hh_end1,mi_end1,hh_start2,mi_start2,hh_end2,mi_end2,de_day) VALUES (?,?,?,?,?,?,?,?,?,?,?,NULL)");

	  if (-1!=hh_start1 || -1!=hh_start2) {

      oUpd = oConn.prepareStatement("UPDATE "+DB.k_working_time+" SET bo_working_time=?,hh_start1=?,mi_start1=?,hh_end1=?,mi_end1=?,hh_start2=?,mi_start2=?,hh_end2=?,mi_end2=? WHERE dt_day=? AND gu_calendar=?");

      for (int d=0; d<nWrkDays; d++) {
  	    oUpd.setShort(1, Short.parseShort(aWrkDays[d])>0 ? YES : NO);
  	    oUpd.setShort(2, hh_start1);
  	    oUpd.setShort(3, mi_start1);
  	    oUpd.setShort(4, hh_end1);
  	    oUpd.setShort(5, mi_end1);
  	    oUpd.setShort(6, hh_start2);
  	    oUpd.setShort(7, mi_start2);
  	    oUpd.setShort(8, hh_end2);
  	    oUpd.setShort(9, mi_end2);
  	    oUpd.setInt(10, date);
  	    oUpd.setString(11, gu_calendar);
        nAffected = oUpd.executeUpdate();
        if (0==nAffected) {
  	      oIns.setInt(1, date);
  	      oIns.setString(2, gu_calendar);
  	      oIns.setShort(3, Short.parseShort(aWrkDays[d])>0 ? YES : NO);
  	      oIns.setShort(4, hh_start1);
  	      oIns.setShort(5, mi_start1);
  	      oIns.setShort(6, hh_end1);
  	      oIns.setShort(7, mi_end1);
  	      oIns.setShort(8, hh_start2);
  	      oIns.setShort(9, mi_start2);
  	      oIns.setShort(10, hh_end2);
  	      oIns.setShort(11, mi_end2);
        } // fi (nAffected)      
  
        if (day<Calendar.LastDay(month,year)) {
          day++;
        } else {
          if (month<11) {
            day=1;
            month++;
          } else {
            day=1;
            month=0;
            year++;
          }
        }
        date = 10000*year+100*month+day;
      } // next
    } else {

      oUpd = oConn.prepareStatement("UPDATE "+DB.k_working_time+" SET bo_working_time=? WHERE dt_day=? AND gu_calendar=?");

      for (int d=0; d<nWrkDays; d++) {

  	    oUpd.setShort(1, Short.parseShort(aWrkDays[d])>0 ? YES : NO);
  	    oUpd.setInt(2, date);
  	    oUpd.setString(3, gu_calendar);
        nAffected = oUpd.executeUpdate();
        if (0==nAffected) {
  	      oIns.setInt(1, date);
  	      oIns.setString(2, gu_calendar);
  	      oIns.setShort(3, Short.parseShort(aWrkDays[d])>0 ? YES : NO);
  	      oIns.setShort(4, hh_start1);
  	      oIns.setShort(5, mi_start1);
  	      oIns.setShort(6, hh_end1);
  	      oIns.setShort(7, mi_end1);
  	      oIns.setShort(8, hh_start2);
  	      oIns.setShort(9, mi_start2);
  	      oIns.setShort(10, hh_end2);
  	      oIns.setShort(11, mi_end2);
        } // fi (nAffected)      

        if (day<Calendar.LastDay(month,year)) {
          day++;
        } else {
          if (month<11) {
            day=1;
            month++;
          } else {
            day=1;
            month=0;
            year++;
          }
        }
        date = 10000*year+100*month+day;
      } // next
    }
    
    oUpd.close();
    oUpd=null;

    oIns.close();
    oIns=null;
    
    oCal = oConn.prepareStatement("SELECT "+DB.dt_from+","+DB.dt_to+" FROM "+DB.k_working_calendar+" WHERE "+DB.gu_calendar+"=?");
    oCal.setString(1,gu_calendar);
    ResultSet oRst = oCal.executeQuery();
    oRst.next();
    Date oCalDtFrom = oRst.getDate(1);
    Date oCalDtTo = oRst.getDate(2);
    oRst.close();
    oCal.close();
    
    if (oCalDtFrom.compareTo(oDtFrom)<0) oDtFrom = oCalDtFrom;
    if (oCalDtTo.compareTo(oDtTo)>0) oDtTo = oCalDtTo;

    oCal = oConn.prepareStatement("UPDATE "+DB.k_working_calendar+" SET "+DB.dt_from+"=?,"+DB.dt_to+"=?,"+DB.dt_modified+"="+DBBind.Functions.GETDATE+" WHERE "+DB.gu_calendar+"=?");
    oCal.setTimestamp(1, new Timestamp(oCalDtFrom.getTime()));
    oCal.setTimestamp(2, new Timestamp(oCalDtTo.getTime()));
    oCal.setString(3,gu_calendar);
	  oCal.executeUpdate();
	  oCal.close();

    oConn.commit();
      
    oConn.close("workcalendar_setdays_store");
  }
  catch (Exception e) {
    if (oIns!=null) oIns.close();
    if (oUpd!=null) oUpd.close();
    disposeConnection(oConn,"workcalendar_setdays_store");
    oConn = null;
    response.sendRedirect (response.encodeRedirectUrl ("../common/errmsg.jsp?title=" + e.getClass().getName() + "&desc=" + e.getMessage() + "&resume=_back"));
  }
  
  if (null==oConn) return;    
  oConn = null;

  response.sendRedirect (response.encodeRedirectUrl ("workcalendar_setdays.jsp?gu_calendar="+gu_calendar+"&id_domain="+id_domain+"&gu_workarea="+gu_workarea+"&year="+String.valueOf(Integer.parseInt(request.getParameter("year"))-1900)+"&month="+String.valueOf(Integer.parseInt(request.getParameter("month")))+"&selected="+nu_selected+"&subselected="+nu_subselected));

%>
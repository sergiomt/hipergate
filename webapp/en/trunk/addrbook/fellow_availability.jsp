<%@ page import="java.text.SimpleDateFormat,java.io.IOException,java.net.URLDecoder,com.knowgate.jdc.JDCConnection,com.knowgate.addrbook.Fellow" language="java" session="false" contentType="text/plain;charset=UTF-8" %><%@ include file="../methods/dbbind.jsp" %><%@ include file="../methods/cookies.jspf" %><%@ include file="../methods/authusrs.jspf" %><%

  JDCConnection oConn = null;  
  SimpleDateFormat oDateHourMin = new SimpleDateFormat("yyyy-MM-dd HH:mm");

  try {
    oConn = GlobalDBBind.getConnection("fellow_availability");
    
    Fellow oFlw = new Fellow ();

    if (oFlw.load(oConn, request.getParameter("gu_fellow"))) {
	    if (oFlw.isAvailableAt(oConn, oDateHourMin.parse(request.getParameter("dt_hour")))) {
	      out.write("true");
	    } else {
	    	if (request.getParameter("gu_meeting").equals(oFlw.getMeetingAt(oConn, oDateHourMin.parse(request.getParameter("dt_hour"))))) {
	        out.write("true");	  
	      } else {
	        out.write("false");	  
	    	}
	    }
    } else {
	    out.write("not found");
    }
    oConn.close("fellow_availability");
  }
  catch (Exception e) {
    if (oConn!=null)
      if (!oConn.isClosed()) {
        oConn.close("fellow_availability");
      }
    oConn = null;
	  out.write("error: "+e.getClass().getName()+" "+e.getMessage());
  }
%>
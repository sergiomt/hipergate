<%@ page import="java.io.IOException,java.net.URLDecoder,java.sql.SQLException,com.knowgate.jdc.JDCConnection,com.knowgate.dataobjs.DB,com.knowgate.training.*" language="java" session="false" contentType="text/plain;charset=UTF-8" %><%@ include file="../methods/dbbind.jsp" %><%@ include file="../methods/cookies.jspf" %><%@ include file="../methods/authusrs.jspf" %><% 
  
  if (autenticateSession(GlobalDBBind, request, response)<0) return;
      
  String gu_course = request.getParameter("gu_course");
  String gu_acourse = request.getParameter("gu_acourse");

  JDCConnection oConn = null;  
      
  try {
    oConn = GlobalDBBind.getConnection("subjects_for_course", true);
    Subject[] aSbjts;
    if (null==gu_acourse)
      aSbjts = new Course(oConn, gu_course).getSubjects(oConn);
    else
      aSbjts = new AcademicCourse(oConn, gu_acourse).getSubjects(oConn);
    
    if (null!=aSbjts) {
      for (int s=0;s<aSbjts.length; s++) {
        if (s>0) out.write("\n"); 
        out.write(aSbjts[s].getString(DB.gu_subject)+";"+aSbjts[s].getString(DB.nm_subject));
      } // next
    } // fi

    oConn.close("subjects_for_course");
  }
  catch (SQLException e) {  
    if (oConn!=null)
      if (!oConn.isClosed()) {
        oConn.close("subjects_for_course");      
      }
    oConn = null;
    out.write (e.getMessage());
  }
  
  if (null==oConn) return;    
  oConn = null;

%>
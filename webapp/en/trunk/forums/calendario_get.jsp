<%@ page import="java.net.URL,javax.activation.DataHandler,java.io.ByteArrayOutputStream" language="java" session="false" contentType="text/plain;charset=UTF-8" %><% 
    URL oUrl = new URL("http://extranet.fundacioncomillasweb.com/forums/calendario_div.jsp"+(request.getParameter("year")==null ? "" : "?year="+request.getParameter("year"))+(request.getParameter("year")==null ? "" : "&month="+request.getParameter("month")));
    ByteArrayOutputStream oStrm = new ByteArrayOutputStream();
    DataHandler oHndlr = new DataHandler(oUrl);
    oHndlr.writeTo(oStrm);
    out.write(oStrm.toString("UTF-8");
    oStrm.close();
%>
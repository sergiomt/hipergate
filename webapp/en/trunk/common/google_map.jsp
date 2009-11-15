<%@ page import="java.io.IOException,java.net.URLDecoder,java.sql.SQLException,com.knowgate.jdc.JDCConnection,com.knowgate.dataobjs.DB,com.knowgate.hipergate.Address" language="java" session="false" contentType="text/html;charset=UTF-8" %>
<%@ include file="../methods/dbbind.jsp" %><%@ include file="../methods/cookies.jspf" %><%@ include file="../methods/authusrs.jspf" %><%@ include file="../methods/nullif.jspf" %>
<% 

  JDCConnection oConn = null;
  Address oAddr = new Address();
    
  try {
    oConn = GlobalDBBind.getConnection("google_map");
        
	  oAddr.load(oConn, request.getParameter("gu_address"));
	  
    oConn.close("google_map");
  }
  catch (Exception e) {
    if (oConn!=null)
      if (!oConn.isClosed()) {
        oConn.close("google_map");
      }
    oConn = null;
    response.sendRedirect (response.encodeRedirectUrl ("errmsg.jsp?title=" + e.getClass().getName() + "&desc=" + e.getMessage() + "&resume=_back"));
  }  
  if (null==oConn) return;    
  oConn = null;

%><!DOCTYPE html PUBLIC "-//W3C//DTD XHTML 1.0 Strict//EN"
  "http://www.w3.org/TR/xhtml1/DTD/xhtml1-strict.dtd">
<html xmlns="http://www.w3.org/1999/xhtml">
  <head>
    <meta http-equiv="content-type" content="text/html; charset=utf-8"/>
    <title><% if (!oAddr.isNull(DB.nm_company)) out.write(oAddr.getString(DB.nm_company)+" - "); out.write(oAddr.toLocaleString()); %></title>
    <script type="text/javascript" src="http://maps.google.com/maps?file=api&amp;v=2&amp;key=<%=GlobalDBBind.getProperty("googlemapskey")%>" ></script>
    <script type="text/javascript" src="http://www.google.com/uds/api?file=uds.js&v=1.0&source=uds-msw&key=<%=GlobalDBBind.getProperty("googlemapskey")%>"></script>
    <style type="text/css">
      @import url("http://www.google.com/uds/css/gsearch.css");
    </style>

    <script type="text/javascript"> window._uds_msw_donotrepair = true; </script>
    <script src="http://www.google.com/uds/solutions/mapsearch/gsmapsearch.js?mode=new" type="text/javascript"></script>
    <style type="text/css">
      @import url("http://www.google.com/uds/solutions/mapsearch/gsmapsearch.css");
    </style>

    <style type="text/css">
      .gsmsc-mapDiv {
        height : 275px;
      }
      .gsmsc-idleMapDiv {
        height : 275px;
      }
    </style>
    <script type="text/javascript">

    //<![CDATA[

    function loadMap() {
      if (GBrowserIsCompatible()) {
        var options = {
            zoomControl : GSmapSearchControl.ZOOM_CONTROL_ENABLE_ALL,
            title : "<% if (!oAddr.isNull(DB.nm_company)) out.write(oAddr.getString(DB.nm_company)+" - "); out.write(oAddr.toLocaleString()); %>",
            <% if (!oAddr.isNull(DB.url_addr)) out.write("url : \""+oAddr.getString(DB.url_addr)+"\","); %>
            idleMapZoom : GSmapSearchControl.ACTIVE_MAP_ZOOM,
            activeMapZoom : GSmapSearchControl.ACTIVE_MAP_ZOOM
            }

        new GSmapSearchControl(
            document.getElementById("gmap"),
            "<% out.write(oAddr.toLocaleString()); %>",
            options
            );
      } // fi (GBrowserIsCompatible)
    } // loadMap

    GSearch.setOnLoadCallback(LoadMapSearchControl);

    //]]>
    </script>
  </head>
  <body onload="loadMap()" onunload="GUnload()">
    <div id="gmap" style="width: 500px; height: 300px"></div>
  </body>
</html>
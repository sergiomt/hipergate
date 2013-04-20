<%@ page import="java.sql.SQLException,com.knowgate.jdc.JDCConnection" language="java" session="false" contentType="text/html;charset=UTF-8" %>
<%@ include file="../methods/dbbind.jsp" %><%@ include file="../methods/nullif.jspf" %><%@ include file="../methods/googleapis.jspf" %>
<%
  String nm_control = request.getParameter("control");
  String id_form = nullif(request.getParameter("id_form"), "0");
  if (id_form.length()==0) id_form="0";

%>
<HTML>
  <HEAD>
    <SCRIPT type="text/javascript" src="../javascript/getparam.js"></SCRIPT>
    <SCRIPT type="text/javascript" src="../javascript/xmlhttprequest.js"></SCRIPT>
    <SCRIPT type="text/javascript" src="http://maps.google.com/?key=<%=GlobalDBBind.getProperty("googlemapskey")%>&file=api&amp;v=2"></SCRIPT>
    <SCRIPT type="text/javascript">

    <!--
    var frm = document.forms[0];
    var gdir;

    // ------------------------------------------------------------------------

    function  setValueAtParent(km) {
      parent.frames[0].document.forms[<%=id_form%>].<%=nm_control%>.value = km;
    }

    // ------------------------------------------------------------------------
    
    function onBodyLoad() {
      
      var nkm = httpRequestText("distance_dbms.jsp"+document.location.search);
      
      if ("not found"==nkm) {
        if (GBrowserIsCompatible()) {      
          frm.lo_from.value = getURLParam("from");
          frm.lo_to.value = getURLParam("to");
          frm.id_locale.value = getURLParam("locale");
          var map = new GMap2(document.getElementById("map"));

          gdir = new GDirections(map);
          GEvent.addListener(gdir, "load", onGDirectionsLoad);
          GEvent.addListener(gdir, "error", handleErrors);

          gdir.load("from: " + frm.lo_from.value + " to: " + frm.lo_to.value,
                    { "locale": frm.id_locale.value });              

          // alert("from: " + fromAddress + " to: " + toAddress,
          //          { "locale": locale });
        } // fi      
      } else {
        setValueAtParent(nkm);
      }
    } // onBodyLoad

    // ------------------------------------------------------------------------

    function handleErrors(){
	   if (gdir.getStatus().code == G_GEO_UNKNOWN_ADDRESS){
	     setDirections("Spain, 08040", "Spain, "+zipcodes[document.getElementById("incheck").value], "es_ES");
	     alert("La calle registrada no aparece en google maps porque es incorrecta o aun no ha sido indexada. \nSe calculara la distancia seg� codigo postal");
	    }
	   else if (gdir.getStatus().code == G_GEO_SERVER_ERROR){
	     alert("A geocoding or directions request could not be successfully processed, yet the exact reason for the failure is not known.\n Error code: " + gdir.getStatus().code);
	   }
	   else if (gdir.getStatus().code == G_GEO_MISSING_QUERY){
	     alert("The HTTP q parameter was either missing or had no value. For geocoder requests, this means that an empty address was specified as input. For directions requests, this means that no query was specified in the input.\n Error code: " + gdir.getStatus().code);
			}
	//   else if (gdir.getStatus().code == G_UNAVAILABLE_ADDRESS)  <--- Doc bug... this is either not defined, or Doc is wrong
	//     alert("The geocode for the given address or the route for the given directions query cannot be returned due to legal or contractual reasons.\n Error code: " + gdir.getStatus().code);
	     
	   else if (gdir.getStatus().code == G_GEO_BAD_KEY){
	     alert("The given key is either invalid or does not match the domain for which it was given. \n Error code: " + gdir.getStatus().code);
		}
	   else if (gdir.getStatus().code == G_GEO_BAD_REQUEST){
	     alert("A directions request could not be successfully parsed.\n Error code: " + gdir.getStatus().code);
	   } 
	   else alert("An unknown error occurred.");	   
    } // handleErrors

    // ------------------------------------------------------------------------

    function onGDirectionsLoad(){ 
      // Use this function to access information about the latest load()

      document.forms[0].nu_km.value = String(gdir.getDistance().meters/1000);
      
      setValueAtParent(document.forms[0].nu_km.value);
      
      document.forms[0].submit();
    } // onGDirectionsLoad

    //-->
    </SCRIPT>
  </HEAD>
  <BODY onload="onBodyLoad()">
    <DIV id="map"></DIV>
    <FORM METHOD="POST" ACTION="distance_store.jsp">
      <INPUT type="hidden" name="lo_from">
      <INPUT type="hidden" name="lo_to">
      <INPUT type="hidden" name="nu_km">
      <INPUT type="hidden" name="id_locale">
    </FORM>
  </BODY>  
</HTML>
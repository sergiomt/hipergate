<%@ include file="../methods/dbbind.jsp" %>
<% String sLanguage = getNavigatorLanguage(request); %>

<HTML LANG="<% out.write(sLanguage); %>">
<HEAD> 
  <SCRIPT SRC="../javascript/cookies.js"></SCRIPT>
  <SCRIPT SRC="../javascript/setskin.js"></SCRIPT>
  <SCRIPT SRC="../javascript/getparam.js"></SCRIPT>
  
  <SCRIPT TYPE="text/javascript" DEFER="defer">
  <!--    
    function domClick() {
       var diputree = window.document.diputree;
                 
       // event
       var docElement = "#/1";
       var pEvent = "#xpointer(hasevent/*)";
       var event = diputree.lookup (docElement, pEvent);

       // source
       var pSourceURI = diputree.lookup(event,"#xpointer(hassource/uri/s)");
       var pSource = diputree.getValue( pSourceURI );
       var source = diputree.lookup(docElement, pSource);

       // destination category identifier
       var pDestination = diputree.lookup(source,"#xpointer(haslink/link/hasdestination/target/s)");
       var id_domain = diputree.getValue(pDestination);

       // category text
       var pText = diputree.lookup(source,"#xpointer(lt)");
       var n_domain = diputree.getValue( pText );
                  
       if (id_domain!="") {
         window.parent.domadmin.location = "domgrps.jsp?id_domain=" + id_domain + "&n_domain=" + escape(n_domain) + "&maxrows=10&skip=0";
       }
    }
    
  //-->
  </SCRIPT>
</HEAD>
<BODY  LEFTMARGIN="4" MARGINHEIGHT="0" TOPMARGIN="16" WIDTH="100%" SCROLL="no">    
    <TABLE BORDER="2" CELLSPACING="0" CELLPADDING="0"><TR><TD><APPLET NAME="diputree" CODE="diputree.class" ARCHIVE="diputree3.jar" CODEBASE="../applets" WIDTH="220" HEIGHT="320" MAYSCRIPT><PARAM NAME="xmlsource" VALUE="pickdoms.jsp"></APPLET></TD></TR></TABLE>
</BODY>
</HTML>

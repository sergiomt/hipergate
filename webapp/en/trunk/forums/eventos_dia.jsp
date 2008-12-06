<%@ page import="java.util.Date,java.io.IOException,java.net.URLDecoder,java.sql.SQLException,java.sql.Timestamp,com.knowgate.jdc.*,com.knowgate.dataobjs.*,com.knowgate.acl.*,com.knowgate.misc.Calendar,com.knowgate.misc.Gadgets,com.knowgate.forums.NewsMessage" language="java" session="false" contentType="text/html;charset=UTF-8" %>
<%@ include file="../methods/dbbind.jsp" %><%@ include file="../methods/cookies.jspf" %><%@ include file="../methods/authusrs.jspf" %><%@ include file="../methods/nullif.jspf" %><%

  String sGuNewsMsg = request.getParameter("gu_newsgrp");
  Date dtNow = new Date();
  String[] aDtDate;
  
  if (null==request.getParameter("dt_date"))
    aDtDate = new String[]{String.valueOf(dtNow.getYear()),String.valueOf(dtNow.getMonth()),String.valueOf(dtNow.getDate())};
  else
    aDtDate = Gadgets.split(request.getParameter("dt_date"),'-');

  Timestamp ts1 = new Timestamp(new Date(Integer.parseInt(aDtDate[0]),Integer.parseInt(aDtDate[1]),Integer.parseInt(aDtDate[2]),0,0,0).getTime());
  Timestamp ts2 = new Timestamp(new Date(Integer.parseInt(aDtDate[0]),Integer.parseInt(aDtDate[1]),Integer.parseInt(aDtDate[2]),23,59,59).getTime());

	DBSubset oMsgs = new DBSubset(DB.k_newsmsgs + " m," + DB.k_x_cat_objs + " x",
															  "m."+DB.tx_subject+",m."+DB.gu_product+",m."+DB.tx_msg,
    							 						  "x."+DB.gu_category+"=? AND x. "+DB.gu_object+"=m."+DB.gu_msg+" AND x."+DB.id_class+"="+String.valueOf(NewsMessage.ClassId)+" AND "+															    
																DBBind.Functions.ISNULL+"(m."+DB.dt_start+",m."+DB.dt_published+") BETWEEN ? AND ? ", 5);

  JDCConnection oConn = GlobalDBBind.getConnection("dayevents");  
  
  int nMsgs = oMsgs.load(oConn, new Object[]{sGuNewsMsg, ts1, ts2});
  
  oConn.close("dayevents");
  
%><!DOCTYPE html PUBLIC "-//W3C//DTD XHTML 1.0 Transitional//EN"
"http://www.w3.org/TR/xhtml1/DTD/xhtml1-transitional.dtd">
<html lang="es">
  <head>
    <base href="http://www.fundacioncomillasweb.com/" />
    <meta name="generator" content="HTML Tidy, see www.w3.org">
    <meta content="text/html; charset=UTF-8" http-equiv="Content-Type">
    <meta content="Pagina de inicio de la fundacion campus comillas" name="description">
    <meta content="cursos espa&ntilde;ol, comillas, fundacion" name="keywords">
    <meta content="all" name="robots">
    <meta content="NO-CACHE" http-equiv="CACHE-CONTROL">
    <meta content="NO-CACHE" http-equiv="PRAGMA">
    <link href="/es/layoutBody/favicon/comillas.ico" rel="Shortcut Icon">
<style type="text/css" media="screen">
    body {
        padding: 0px;
        margin: 0px;
        background-color: #FFFFFF;
                
    }
    a {
        color: 669900;text-decoration: none;
    }
    a:hover {
        text-decoration: underline;
    }
    
    .bodyTable {
        width: 960px;
        height: 450px;
        margin-right:auto;
        vertical-align:top;
    }
        
    /* Start Main Column */
    #mainColumn {
        width: 520px;
    }
    
    #mainColumn .line {
        border-top: 1px black solid;
        margin-top: 5px;
        padding-bottom: 5px;    
    }
            
    .mainColumn {
        vertical-align:top;
        height: 100%;
        padding-top: 0px;
        padding-left: 20px;
        padding-right: 20px;
        padding-bottom: 0px;
        
            background-color: #none;
        
        font-family: Verdana, Arial, "Sans Serif";
        font-size: 11px;
        line-height: 14px;
        color: #000000;
        
        border-right: none;
        border-left: none;
        border-top: none;
        border-bottom: none;            
    }
    .mainColumn H1 {
        color: black; margin-top: 0px; margin-bottom: 8px; font-size: 16px; line-height: 18px;
    }       
    .mainColumn H2 {
        color: black; margin-top: 0px; margin-bottom: 5px; font-size: 14px; line-height: 18px;
    }
    .mainColumn a {
        
    }
    .mainColumn a:hover {
        
    }
    /* End footer */    
    
    /* Start left column */
    #leftColumn {
        width: 200px;
        
    }
    #leftColumn .line {
        border-top: 1px black solid;
        margin-top: 5px;
        padding-bottom: 5px;    
    }
                    
    .leftColumn {
        vertical-align:top;
        height: 100%;
        padding-top: 0px;
        padding-left: 0px;
        padding-right: 0px;
        padding-bottom: 0px;
        
            background-color: #none;
                
        font-family: Verdana, Arial, "Sans Serif";
        font-size: 11px;
        line-height: 14px;
        color: #000000;
        
        
        border-right: none;
        border-left: none;
        border-top: none;
        border-bottom: none;
    }   
    .leftColumn H2 {
        color: black; margin-top: 0px; margin-bottom: 5px; font-size: 14px; line-height: 18px;
    }
    .leftColumn a {
        
    }
    .leftColumn a:hover {
        
    }
    /* End left column */

    /* Start right column */
    #rightColumn {
        width: 200px;
    }
    #rightColumn .line {
        border-top: 1px black solid;
        margin-top: 5px;
        padding-bottom: 5px;    
    }   
    
    
            
    .rightColumn {
        vertical-align:top;
        height: 100%;
        padding-top: 0px;
        padding-left: 0px;
        padding-right: 0px;
        padding-bottom: 0px;
        
            background-color: #none;
                    
        font-family: Verdana, Arial, "Sans Serif";
        font-size: 11px;
        line-height: 14px;
        color: #000000;
        
        border-right: none;
        border-left: none;
        border-top: none;
        border-bottom: none;        
    }   
    .rightColumn H2 {
        color: black; margin-top: 0px; margin-bottom: 5px; font-size: 14px; line-height: 18px;
    }
    .rightColumn a {
        
    }
    .rightColumn a:hover {
        
    }
    /* End right column */
    
    /* Start header */
    #header {
        min-height: auto;
    }
    /* for Internet Explorer */
    /*\*/
    * html #header {
    height: auto;
    }
    /**/
    #header .line {
        border-top: 1px black solid;
        margin-top: 5px;
        padding-bottom: 5px;    
    }
    
    
    
    
    
    .header {
        vertical-align:top;
        padding-top: 0px;
        padding-left: 0px;
        padding-right: 0px;
        padding-bottom: 0px;
        
            background-color: #none;
        
        font-family: Verdana, Arial, "Sans Serif";
        font-size: 11px;
        line-height: 14px;
        color: #000000;
        
        border-right: none;
        border-left: none;
        border-top: none;
        border-bottom: none;            
    }   
    .header H2 {
        color: black; margin-top: 0px; margin-bottom: 5px; font-size: 14px; line-height: 18px;
    }
    .header a {
        
    }
    .header a:hover {
        
    }
    /* End header */
    
    /* Start footer */
    #footer {
        min-height: auto;
    }
    /* for Internet Explorer */
    /*\*/
    * html #footer {
    height: auto;
    }
    /**/
    #footer .line {
        border-top: 1px black solid;
        margin-top: 5px;
        padding-bottom: 5px;    
    }
    
        
    .footer {
        vertical-align:top;
        padding-top: 0px;
        padding-left: 0px;
        padding-right: 0px;
        padding-bottom: 0px;
        
            background-color: #none;
                
        font-family: Verdana, Arial, "Sans Serif";
        font-size: 11px;
        line-height: 14px;
        color: #000000;
        
        border-right: none;
        border-left: none;
        border-top: none;
        border-bottom: none;        
    }   
    .footer H2 {
        color: black; margin-top: 0px; margin-bottom: 5px; font-size: 14px; line-height: 18px;
    }
    .footer a {
        
    }
    .footer a:hover {
        
    }
    /* End footer */            
    
    #imagen_center{
        text-align: center;
        
    }
    
</style>
<style type="text/css">
@import "/docroot/siteDesigner/css/pantalla.css";
</style>
<style media="screen" type="text/css">
            
    
/******* general *******/
/***********************/
#espublicoserviciosmapaWebmainColumnParagraphs0 ul.level1, #espublicoserviciosmapaWebmainColumnParagraphs0 ul.level2, #espublicoserviciosmapaWebmainColumnParagraphs0 ul.level3, #espublicoserviciosmapaWebmainColumnParagraphs0 ul.level4, #espublicoserviciosmapaWebmainColumnParagraphs0 ul.level5 {
    margin: 0px 0px 0px 0px; /* oben / rechts / unten / links */
    padding: 0px 0px 0px 0px; /* oben / rechts / unten / links */   
    list-style: none;
    width: 100%;
    
    
}
#espublicoserviciosmapaWebmainColumnParagraphs0 a {
    text-decoration: none;
    display: block;
        
}
#espublicoserviciosmapaWebmainColumnParagraphs0 a:hover {
    
}

/******* 1st level *******/
/*************************/
#espublicoserviciosmapaWebmainColumnParagraphs0 li {
    width: 100%;
    
}
#espublicoserviciosmapaWebmainColumnParagraphs0 li a:hover {
    
}

#espublicoserviciosmapaWebmainColumnParagraphs0 li.open {
    
}   
#espublicoserviciosmapaWebmainColumnParagraphs0 li.open a {
    
}
#espublicoserviciosmapaWebmainColumnParagraphs0 li.trail a {
    
}
#espublicoserviciosmapaWebmainColumnParagraphs0 li.trail a:hover {
    
}

#espublicoserviciosmapaWebmainColumnParagraphs0 li.active a {
    
    
}

#espublicoserviciosmapaWebmainColumnParagraphs0 li a {
    
    
    
    
    
    
    
        
}


/******* 2nd level *******/
/*************************/
#espublicoserviciosmapaWebmainColumnParagraphs0 li li a {
    margin-left: 0px;
}
#espublicoserviciosmapaWebmainColumnParagraphs0 li li.leaf a {
    
}
#espublicoserviciosmapaWebmainColumnParagraphs0 li li.leaf a:hover {
    
}

#espublicoserviciosmapaWebmainColumnParagraphs0 li li.active a {
    
}
#espublicoserviciosmapaWebmainColumnParagraphs0 li li.active a:hover {
    
}

/******* 3rd level *******/
/*************************/
#espublicoserviciosmapaWebmainColumnParagraphs0 li li li a {
    margin-left: 0px;
}

/******* 4rd level *******/
/*************************/
#espublicoserviciosmapaWebmainColumnParagraphs0 li li li li a {
    margin-left: 0px;
}
/******* 5th level *******/
/*************************/
#espublicoserviciosmapaWebmainColumnParagraphs0 li li li li li a {
    margin-left: 0px;
}
</style>
<style media="screen" type="text/css">
            
    
/******* general *******/
/***********************/
#espublicoserviciosmapaWebmainColumnParagraphs00 ul.level1, #espublicoserviciosmapaWebmainColumnParagraphs00 ul.level2, #espublicoserviciosmapaWebmainColumnParagraphs00 ul.level3, #espublicoserviciosmapaWebmainColumnParagraphs00 ul.level4, #espublicoserviciosmapaWebmainColumnParagraphs00 ul.level5 {
    margin: 0px 0px 0px 0px; /* oben / rechts / unten / links */
    padding: 0px 0px 0px 0px; /* oben / rechts / unten / links */   
    list-style: none;
    width: 100%;
    
    
}
#espublicoserviciosmapaWebmainColumnParagraphs00 a {
    text-decoration: none;
    display: block;
        
}
#espublicoserviciosmapaWebmainColumnParagraphs00 a:hover {
    
}

/******* 1st level *******/
/*************************/
#espublicoserviciosmapaWebmainColumnParagraphs00 li {
    width: 100%;
    
}
#espublicoserviciosmapaWebmainColumnParagraphs00 li a:hover {
    
}

#espublicoserviciosmapaWebmainColumnParagraphs00 li.open {
    
}   
#espublicoserviciosmapaWebmainColumnParagraphs00 li.open a {
    
}
#espublicoserviciosmapaWebmainColumnParagraphs00 li.trail a {
    
}
#espublicoserviciosmapaWebmainColumnParagraphs00 li.trail a:hover {
    
}

#espublicoserviciosmapaWebmainColumnParagraphs00 li.active a {
    
    
}

#espublicoserviciosmapaWebmainColumnParagraphs00 li a {
    
    
    
    
    
    
    
        
}


/******* 2nd level *******/
/*************************/
#espublicoserviciosmapaWebmainColumnParagraphs00 li li a {
    margin-left: 0px;
}
#espublicoserviciosmapaWebmainColumnParagraphs00 li li.leaf a {
    
}
#espublicoserviciosmapaWebmainColumnParagraphs00 li li.leaf a:hover {
    
}

#espublicoserviciosmapaWebmainColumnParagraphs00 li li.active a {
    
}
#espublicoserviciosmapaWebmainColumnParagraphs00 li li.active a:hover {
    
}

/******* 3rd level *******/
/*************************/
#espublicoserviciosmapaWebmainColumnParagraphs00 li li li a {
    margin-left: 0px;
}

/******* 4rd level *******/
/*************************/
#espublicoserviciosmapaWebmainColumnParagraphs00 li li li li a {
    margin-left: 0px;
}
/******* 5th level *******/
/*************************/
#espublicoserviciosmapaWebmainColumnParagraphs00 li li li li li a {
    margin-left: 0px;
}
</style>
    <title>
      Fundaci&oacute;n Comillas - Fundaci&oacute;n Comillas - - Noticias - Conferencia de Daniel Cassany
    </title>
<script src="/docroot/siteDesigner/js/functions.js" type="text/javascript">
</script>
<script src="/docroot/siteDesigner/js/form.js" type="text/javascript">
</script>
<style type="text/css">
        @import "/docroot/siteDesigner/css/main.css";   
        @import "/docroot/siteDesigner/css/paragraphs.css";
    
</style>
  </head>
  <body onload="blurAnchors();">
    <div id="pagina">
      <a name="mgnlTop"></a>
      <div style="position:absolute;top:0px;left:0px;width:100%;padding:0px;margin:0px;">
        <div id="mainbar">
        </div>
      </div>
      <div>
        <div id="cabecera">
          <h1 class="oculto">
            Fundaci&oacute;n Campus Comillas
          </h1>
          <div class="izda">
            <p id="idiomas">
              <a href="/es/publico/inicio.html">Espa&ntilde;ol</a> 
              <!-- | <a href="#">English</a> | <a href="#">Fran&ccedil;ais</a> | <a href="#">Deutsch</a> -->
            </p>
          </div>
          <div class="dcha">
            <p id="recursiva">
              <a href="/es/publico/inicio.html">Inicio</a> | <a href=
              "/es/publico/servicios/mapaWeb.html">Mapa web</a> | <a href=
              "/es/publico/servicios/contacto.html">Contacto</a> | <a href=
              "/es/publico/servicios/comollegar.html">C&oacute;mo llegar</a>
            </p>
            <form id="buscador_gnral" name="buscador_gnral" action="/es/publico/servicios/busqueda.html">
              <label class="oculto" for="campo_buscador_gnral">Buscador</label> <input type="text" class="campo_texto" id=
              "campo_buscador_gnral" name="query" value="Buscar"> <input type="image" id="btn_buscador_gnral" name=
              "btn_buscador_gnral" value="Buscar" src="/dms/comillas3/img/btn_buscador_gnral/btn_buscador_gnral.gif" alt=
              "Buscar">
            </form>
          </div>
        </div>
        <div id="cuerpo">
          <div id="col_lateral">
            <ul id="menu_dos">
              <li>
                <a href="/es/publico/servicios/laFundacion/informacion.html">La Fundaci&oacute;n Comillas</a>
              </li>
              <li>
                <a href="/es/publico/servicios/patrocinioyMecenazgo.html">Patrocinio y Mecenazgo</a>
              </li>
              <li>
                <a href="/es/publico/servicios/amigos.html">Club de amigos de la Fundaci&oacute;n</a>
              </li>
              <li>
                <a href="/es/publico/servicios/multimedia.html">Im&aacute;genes y multimedia</a>
              </li>
              <li>
                <a href="/es/publico/servicios/informacionAcademica.html">Informaci&oacute;n Acad&eacute;mica</a>
              </li>
              <li>
                <a href="/es/publico/servicios/vidaComunitaria/alojamiento.html">Vida Comunitaria</a>
              </li>
              <li>
                <a href="/es/publico/servicios/situacionyEntorno/villaComillas.html">Situaci&oacute;n y entorno</a>
              </li>
            </ul>
            <ul id="menu_tres">
              <li>
                <a href="/es/publico/secciones/ofertasDeEmpleo.html">Ofertas de Empleo</a>
              </li>
              <li>
                <a href="/es/publico/secciones/concursosyLicitaciones.html">Concursos y Licitaciones</a>
              </li>
              <li>
                <a href="/es/publico/secciones/noticias.html">Noticias</a>
              </li>
              <li>
                <a href="#">Eventos</a>
              </li>
            </ul>
          </div>
          <div class="interior_blanco" id="col_ppal">
            <div id="menu_ppal">
              <ul>
                <li class="li1">
                  <a href="/es/roles/direcyProfesionales.html">Directivos</a>
                </li>
                <li class="li2">
                  <a href="/es/roles/empresas.html">Instituciones</a>
                </li>
                <li class="li3">
                  <a href="/es/roles/profesores/informacionGeneral.html">Profesores</a>
                </li>
                <li class="li4">
                  <a href="/es/roles/estudiantes/informacion.html">Estudiantes</a>
                </li>
                <li class="li5">
                  <a href="/es/roles/agentes/bienvenida.html">Agentes</a>
                </li>
              </ul>
            </div>
            <div id="subcolppal_izda">
              <div class="paragraphInformationBoxLayout" id="mgnlParagraphContentTitle">
                Main title
              </div>
<% for (int e=0; e<nMsgs; e++) { %>
              <h2>
                <%=oMsgs.getStringNull(DB.tx_subject,e,"")%>
              </h2>
              <%=oMsgs.getStringNull(DB.tx_msg,e,"")%>
						  <br><br>
<% if (!oMsgs.isNull(DB.gu_product,e)) {
      oConn = GlobalDBBind.getConnection("dayevents");  
		  NewsMessage oMsg = new NewsMessage(oConn,sGuNewsMsg);
      DBSubset oLocs = oMsg.getAttachments(oConn);
      for (int a=0; a<oLocs.getRowCount(); a++)
        out.write("<A HREF=\"../servlet/HttpBinaryServlet?id_user=5911c98711446fb97b4100066f9490bb&id_product=" + oMsg.getString(DB.gu_product) + "&id_location=" + oLocs.getString(DB.gu_location,a) + "\" CLASS=\"linkplain\" TARGET=\"blank\" TITLE=\"Abrir/Descargar\">" + oLocs.getStringNull(DB.xfile,a,"archivo adjunto " + String.valueOf(a)) + "</A>&nbsp;(" + String.valueOf(oLocs.getInt(DB.len_file,a)/1024) + " Kb)<BR/>");
      oConn.close("dayevents");
    } // fi
} // next %>
					  <br/><br/><a href="#" onclick="window.history.back()">Volver</a>
            </div>
            <div id="subcolppal_dcha">
              <div class="pastilla_lateral">
                <a href="/es/publico/servicios/contacto.html"><img alt=
                "Tel: (+34) 942 050 100 - E-mail: info@campuscolillas.es" src=
                "/dms/comillas3/img/pastilla_contacto/pastilla_contacto.gif"></a>
              </div>
              <div class="pastilla_lateral foros">
                <a href="http://extranet.fundacioncomillasweb.com/foros.jsp" target="_blank">Foros</a>
              </div>
              <div class="pastilla_lateral blogs">
                <a href="http://blog.fundacioncomillasweb.com/blog/" target="_blank">Blogs</a>
              </div>
              <div class="pastilla_lateral">
                <object width="141" height="74" data="/dms/comillas3/img/mapa_cantabria/mapa_cantabria.swf" type=
                "application/x-shockwave-flash">
                  <param value="/dms/comillas3/img/mapa_cantabria/mapa_cantabria.swf" name="movie">
                  <img width="141" height="74" alt="Mapa de Cantabria" src=
                  "/dms/comillas3/img/mapa_cantabria_sustit/mapa_cantabria_sustit.gif">
                </object>
              </div>
              <div class="pastilla_lateral">
                <a target="_blank" title=
                "Ir a la p&aacute;gina de la Biblioteca Virtual Cervantes [[indicar si abre ventana nueva]" href=
                "http://www.cervantesvirtual.com"><img width="141" height="110" alt="Biblioteca Virtual Miguel de Cervantes"
                src="/dms/comillas3/img/pastilla_biblioteca_virtual_cervantes/pastilla_biblioteca_virtual_cervantes.jpg"></a>
              </div>
              <div class="pastilla_lateral ultima">
                <img alt="Comunidad de Cantabria - Gobierno de Espa&ntilde;a" src=
                "/dms/comillas3/img/pastilla_escudos/pastilla_escudos.jpg">
              </div>
            </div>
          </div>
        </div>
        <div id="pie">
          <a href="/es/publico/inicio.html">&copy; Fundaci&oacute;n Comillas - Santander (Cantabria)</a> | <a href=
          "#">Pol&iacute;tica de privacidad</a> | <a href=
          "/es/publico/servicios/accesibilidad.html">Accesibilidad</a> | <a href=
          "/es/publico/servicios/avisoLegal.html">Aviso legal</a>
        </div>
      </div>
    </div>
  </body>
</html>


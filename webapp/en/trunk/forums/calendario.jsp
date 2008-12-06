<%@ page import="java.text.SimpleDateFormat,java.util.ArrayList,java.util.Date,java.io.IOException,java.net.URLDecoder,java.sql.SQLException,com.knowgate.jdc.*,com.knowgate.dataobjs.*,com.knowgate.acl.*,com.knowgate.misc.Calendar,com.knowgate.misc.Gadgets,com.knowgate.forums.Forums" language="java" session="false" contentType="text/html;charset=UTF-8" %>
<%@ include file="../methods/dbbind.jsp" %><%@ include file="../methods/cookies.jspf" %><%@ include file="../methods/authusrs.jspf" %><%@ include file="../methods/nullif.jspf" %><%

  String sGuNewsGrp = GlobalDBBind.getProperty("events_es");
  String sLanguage = getNavigatorLanguage(request);

  Date dtNow = new Date();
  int year = dtNow.getYear();
  int month = dtNow.getMonth();

  final long lOneDayMilis = 24l*60l*60l*1000l;
  Date dtToday = new Date(year, month, 1);
  Date dtNextM = new Date(dtToday.getTime()+(((long)Calendar.LastDay(month,year+1900))*lOneDayMilis));
  Date dtLastD = new Date(dtNextM.getTime()-lOneDayMilis);
  String sMonth = Calendar.MonthName(month, sLanguage);
  int  FirstDay = 1;   // First day of the month. (1 = Monday)
  int  CurrentDay = 1; // Used to print dates in calendar
  int  LastDay = Calendar.LastDay(month, year+1900);

  JDCConnection oConn = GlobalDBBind.getConnection("monthevents");  
  
  ArrayList oDays = Forums.getDaysWithPosts(oConn, sGuNewsGrp, dtToday, dtLastD);

  /*  
	DBSubset oMsgs = new DBSubset(DB.k_newsmsgs + " m," + DB.k_x_cat_objs + " x",
															  "m."+DB.tx_subject+",m."+DB.gu_product+","+DBBind.Functions.ISNULL+"(m."+DB.dt_start+",m."+DB.dt_published+") AS dt_show,m."+DB.tx_msg,
    							 						  "x."+DB.gu_category+"=? AND x. "+DB.gu_object+"=m."+DB.gu_msg+" AND x."+DB.id_class+"="+String.valueOf(NewsMessage.ClassId)+
    							 						  " ORDER BY 3 DESC", 3);
  oMsgs.setMaxRows(3);		 						  
  int iMsgs = oMsgs.load(oConn, new Object[]{sGuNewsGrp});
  */

  oConn.close("monthevents");

%><!DOCTYPE html PUBLIC "-//W3C//DTD XHTML 1.0 Transitional//EN"
    	"http://www.w3.org/TR/xhtml1/DTD/xhtml1-transitional.dtd">
<html lang="es">
	<head>
	<base href="http://www.fundacioncomillasweb.com/" />
	<meta content="text/html; charset=UTF-8" http-equiv="Content-Type"/>
	<link href="/es/layoutBody/favicon/comillas.ico" rel="Shortcut Icon"/><style type="text/css" media="screen">
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
</style><style media="screen" type="text/css">            
    
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
</style><style media="screen" type="text/css">            
    
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
<html>
  <head>
    <meta name="generator" content="HTML Tidy, see www.w3.org">
    <title>
    </title>
  </head>
  <body>
    <div class="modulo_eventos">
      <h2>
        Eventos <span class="rojo"><%=String.valueOf(year+1900)%></span>
      </h2>
      <div class="foto_calendario">
        <img alt="[[Titular del evento]]" src="/dms/comillas3/archivos/113x118_1/113x118_1.jpg" class="img"> 
        <div class="calendario">
          <ol class="selectormes">
            <li>
              <%=sMonth%>&nbsp;<%=String.valueOf(year+1900)%>
            </li>
          </ol>
          <table class="tabla_mes" summary="Agenda de actividades">
            <thead>
              <tr>
                <th scope="col">
                  <abbr title="Lunes">L</abbr>
                </th>
                <th scope="col">
                  <abbr title="Martes">M</abbr>
                </th>
                <th scope="col">
                  <abbr title="Mi&eacute;rcoles">X</abbr>
                </th>
                <th scope="col">
                  <abbr title="Jueves">J</abbr>
                </th>
                <th scope="col">
                  <abbr title="Viernes">V</abbr>
                </th>
                <th scope="col">
                  <abbr title="S&aacute;bado">S</abbr>
                </th>
                <th scope="col">
                  <abbr title="Domingo">D</abbr>
                </th>
              </tr>
            </thead>
            <tbody>
<%	for (int row=0; row<6; row++) {
	    out.write("              <tr>");
	    for (int col=0; col<7; col++) {
        if ((CurrentDay<=LastDay) && (0!=row || col>FirstDay)) {
		      if (((Boolean) oDays.get(CurrentDay-1)).booleanValue())
	          out.write("<td class=\"diaconevento\"><a target=_top href='http://localhost:8080/hipergate/forums/eventos_dia.jsp?gu_newsgrp="+sGuNewsGrp+"&dt_date="+String.valueOf(year)+"-"+String.valueOf(month)+"-"+String.valueOf(CurrentDay)+"'>"+String.valueOf(CurrentDay)+"</a></td>");		    
		      else
	          out.write("<td>"+String.valueOf(CurrentDay)+"</td>");
		      CurrentDay++;
		    } else {
	        out.write("<td>&nbsp;</td>");		    
		    }
		  } // next
	    out.write("              </tr>\n");
    }
%>
            </tbody>
          </table>
        </div>
      </div>
      <div class="lista_eventos">
        <div class="modulo_textillo">
          <p>
            <strong>25-10-2007</strong>
          </p>
          <p>
            La Fundaci&oacute;n Comillas promociona sus actividades en el continente asi&aacute;tico. <a title=
            "Ampliar informaci&oacute;n sobre [[titular de la noticia]]" class="rojo" href="#">Ampliar</a>
          </p>
        </div>
        <div class="modulo_textillo">
          <p>
            <strong>1-11-2007</strong>
          </p>
          <p>
            I Encuentro de Profesionales del Espa&ntilde;ol como Lengua Extranjera (ELE). <a title=
            "Ampliar informaci&oacute;n sobre [[titular de la noticia]]" class="rojo" href="#">Ampliar</a>
          </p>
        </div>
        <p class="btn">
          <a href="../../es/publico/secciones/noticias.html"><img alt="Consultar todos" src=
          "/dms/comillas3/img/btn_consultartodos/btn_consultartodos.gif"></a>
        </p>
      </div>
    </div>
    <div class="subcols">
      <div class="subcol_izda">
        <h2>
          Noticias
        </h2>
        <div class="modulo_fotillo">
          <img alt="[[Titular de la noticia]]" src="/dms/comillas3/archivos/47x47_1/47x47_1.jpg" class="img"> 
          <div class="txt">
            <p>
              <strong>25-10-2007</strong>
            </p>
            <p>
              La Fundaci&oacute;n Comillas promociona sus actividades en el continente asi&aacute;tico. <a title=
              "Ampliar informaci&oacute;n sobre [[titular de la noticia]]" class="rojo" href="#">Ampliar</a>
            </p>
          </div>
        </div>
        <div class="modulo_fotillo">
          <img alt="[[Titular de la noticia]]" src="/dms/comillas3/archivos/47x47_2/47x47_2.jpg" class="img"> 
          <div class="txt">
            <p>
              <strong>1-11-2007</strong>
            </p>
            <p>
              ExpoELE Comillas. <a title="Ampliar informaci&oacute;n sobre [[titular de la noticia]]" class="rojo" href=
              "#">Ampliar</a>
            </p>
          </div>
        </div>
        <div class="modulo_fotillo">
          <img alt="[[Titular de la noticia]]" src="/dms/comillas3/archivos/47x47_3/47x47_3.jpg" class="img"> 
          <div class="txt">
            <p>
              <strong>24-10-2007</strong>
            </p>
            <p>
              XLII Congreso de la Asociaci&oacute;n Europea de Profesores de Espa&ntilde;ol. <a title=
              "Ampliar informaci&oacute;n sobre [[titular de la noticia]]" class="rojo" href="#">Ampliar</a>
            </p>
          </div>
        </div>
        <p class="btn">
          <a href="/es/publico/secciones/noticias.html"><img alt="Consultar todas" src=
          "/dms/comillas3/img/btn_consultartodas/btn_consultartodas.gif"></a>
        </p>
      </div>
    </div>
  </body>
</html>


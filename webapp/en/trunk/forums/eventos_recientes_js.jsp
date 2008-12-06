<%@ page import="java.text.SimpleDateFormat,java.util.ArrayList,java.util.Date,java.io.IOException,java.net.URLDecoder,java.sql.SQLException,com.knowgate.jdc.*,com.knowgate.dataobjs.*,com.knowgate.acl.*,com.knowgate.misc.Gadgets,com.knowgate.forums.NewsMessage" language="java" session="false" contentType="text/javascript;charset=UTF-8" %>
<%@ include file="../methods/dbbind.jsp" %><%@ include file="../methods/cookies.jspf" %><%@ include file="../methods/authusrs.jspf" %><%@ include file="../methods/nullif.jspf" %><%

	SimpleDateFormat oUrlDate = new SimpleDateFormat("yy-MM-dd");
	SimpleDateFormat oShortDate = new SimpleDateFormat("dd/MM/yyyy");
  String sGuNewsGrp = GlobalDBBind.getProperty("events_es");
  String sLanguage = getNavigatorLanguage(request);

  JDCConnection oConn = GlobalDBBind.getConnection("recentevents");  
  
	DBSubset oMsgs = new DBSubset(DB.k_newsmsgs + " m," + DB.k_x_cat_objs + " x",
															  "m."+DB.tx_subject+","+DBBind.Functions.ISNULL+"(m."+DB.dt_start+",m."+DB.dt_published+") AS dt_show",
    							 						  "x."+DB.gu_category+"=? AND x. "+DB.gu_object+"=m."+DB.gu_msg+" AND x."+DB.id_class+"="+String.valueOf(NewsMessage.ClassId)+
    							 						  " ORDER BY 2 DESC", 3);
  oMsgs.setMaxRows(3);
  int iMsgs = oMsgs.load(oConn, new Object[]{sGuNewsGrp});

  oConn.close("recentevents");

%>
document.write('      <div class="lista_eventos">');
<% for (int m=0; m<iMsgs; m++) { %> 
document.write('        <div class="modulo_textillo">');
document.write('          <p>');
document.write('            <strong><%=oShortDate.format(oMsgs.getDate(1,m))%></strong>');
document.write('          </p>');
document.write('          <p>');
document.write('             <%=oMsgs.getStringNull(0,m,"")%>');
document.write('             <a title="Ampliar informaci&oacute;n sobre [[titular de la noticia]]" class="rojo" href="<%="http://extranet.fundacioncomillasweb.com/forums/eventos_dia.jsp?gu_newsgrp="+sGuNewsGrp+"&dt_date=1"+oUrlDate.format(oMsgs.getDate(1,m))%>">Ampliar</a>');
document.write('          </p>');
document.write('        </div>');
<% } %>
document.write('        <p class="btn">');
document.write('          <a href="http://extranet.fundacioncomillasweb.com/forums/eventos_dia.jsp?gu_newsgrp=<%=sGuNewsGrp%>"><img alt="Consultar todos" src="/dms/comillas3/img/btn_consultartodos/btn_consultartodos.gif"></a>');
document.write('        </p>');
document.write('      </div>');
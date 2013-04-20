<%@ page import="java.util.HashMap,java.util.LinkedList,java.util.ListIterator,java.io.IOException,java.net.URLDecoder,java.sql.SQLException,java.sql.PreparedStatement,java.sql.ResultSet,com.knowgate.jdc.*,com.knowgate.dataobjs.*,com.knowgate.acl.*,com.knowgate.crm.*,com.knowgate.hipergate.DBLanguages,com.knowgate.hipergate.Term,com.knowgate.misc.Gadgets,com.knowgate.training.ContactEducation,com.knowgate.training.ContactShortCourses,com.knowgate.training.ContactComputerScience,com.knowgate.training.ContactLanguages,com.knowgate.training.ContactExperience,com.knowgate.lucene.*" language="java" session="false" contentType="text/html;charset=UTF-8" %>
<%@ include file="../methods/nullif.jspf" %><%@ include file="../methods/dbbind.jsp" %><%@ include file="../methods/cookies.jspf" %><%@ include file="../methods/authusrs.jspf" %>
<jsp:useBean id="GlobalCacheClient" scope="application" class="com.knowgate.cache.DistributedCachePeer"/><jsp:useBean id="GlobalDBLang" scope="application" class="com.knowgate.hipergate.DBLanguages"/>
<!DOCTYPE HTML PUBLIC "-//W3C//DTD HTML 4.0 Transitional//EN">
<%final String sLanguage = getNavigatorLanguage(request); %>
<HTML LANG="<%=sLanguage.toUpperCase()%>">
<HEAD>
  <SCRIPT SRC="../javascript/cookies.js"></SCRIPT>  
  <SCRIPT SRC="../javascript/setskin.js"></SCRIPT>
  <SCRIPT SRC="../javascript/getparam.js"></SCRIPT>
  <SCRIPT SRC="../javascript/usrlang.js"></SCRIPT>
  <SCRIPT SRC="../javascript/combobox.js"></SCRIPT>  
  <SCRIPT SRC="../javascript/trim.js"></SCRIPT>
  <SCRIPT SRC="../javascript/datefuncs.js"></SCRIPT>
<%	
	response.addHeader ("Pragma", "no-cache");
	response.addHeader ("cache-control", "no-store");
	response.setIntHeader("Expires", 0);
	
	/* Autenticate user cookie */
	if (autenticateSession(GlobalDBBind, request, response)<0) return;
	
	final String sSkin = getCookie(request, "skin", "xp");
	String gu_workarea = (String)request.getParameter("gu_workarea");
	String id_user = getCookie (request, "userid", null);
	String cadena = (String)request.getParameter("cadena");
	String id_language = getNavigatorLanguage(request);
		
	String values[] = null;
	String pares[]=null;
	boolean obligatorios[] = null;
	if(cadena!=null){
		pares = cadena.split("@");
		values = new String[pares.length];
		obligatorios = new boolean[pares.length];
		for(int i=0;i<pares.length;i++){
			String valores[] = pares[i].split("-");
			values[i] = valores[0];
			if(valores.length>1 && valores[1].trim().length()>0) obligatorios[i]=true;
			else obligatorios[i]=false;
		}
	}
	ContactRecord listado[] = null;
	if (null!=GlobalDBBind.getProperty("luceneindex") && cadena!=null) {
		listado = ContactSearcher.search(GlobalDBBind.getProperties(),gu_workarea,values,obligatorios);
	}

%>

</HEAD>
<BODY  TOPMARGIN="8" MARGINHEIGHT="8" >
    <DIV class="cxMnu1" style="width:350px"><DIV class="cxMnu2" style="width:350px">
    <SPAN class="hmMnuOff" onMouseOver="this.className='hmMnuOn'" onMouseOut="this.className='hmMnuOff'" onClick="history.back()"><IMG src="../images/images/toolmenu/historyback.gif" width="16" style="vertical-align:middle" height="16" border="0" alt="Back"> Back</SPAN>
    <SPAN class="hmMnuOff" onMouseOver="this.className='hmMnuOn'" onMouseOut="this.className='hmMnuOff'" onClick="location.reload(true)"><IMG src="../images/images/toolmenu/locationreload.gif" width="16" style="vertical-align:middle" height="16" border="0" alt="Refresh"> Refresh</SPAN>
    <SPAN class="hmMnuOff" onMouseOver="this.className='hmMnuOn'" onMouseOut="this.className='hmMnuOff'" onClick="window.print()"><IMG src="../images/images/toolmenu/windowprint.gif" width="16" height="16" style="vertical-align:middle" border="0" alt="Print"> Print</SPAN>
  	</DIV></DIV>
<SCRIPT TYPE="text/javascript" DEFER="defer">
	var cadena ='';  	

	var gu_workarea = <%=gu_workarea%>;
	
	function add(id){
		var tbody = document.getElementById(id).getElementsByTagName("TBODY")[0];
		var row = document.createElement("TR");
	 	var td1 = document.createElement("TD");
	 	var valor = document.getElementById("valor").value.toLowerCase();
		document.getElementById("valor").value='';
	  	td1.appendChild(document.createTextNode(valor));
	  	var td2 = document.createElement("TD");
	  	var obligatorio = "";
	  	if (document.getElementById("obligatorio").checked) obligatorio="*";
	  	document.getElementById("obligatorio").checked = false;
	  	td2.appendChild (document.createTextNode(obligatorio));
	  	row.appendChild(td1);
	  	row.appendChild(td2);
	  	tbody.appendChild(row);
	  	if(cadena.length==0) cadena = valor + '-' + obligatorio;
	  	else cadena = cadena + '@' + valor + '-' + obligatorio;
	}
	
	function delAll()
	{
		cadena='';
		var tabla = document.getElementById('values');
		for(i=0;i<40;i++){
				tabla.deleteRow(1);
		}
	}

	function search(){
		 window.location.href ="candidate_search.jsp?gu_workarea=<%=gu_workarea%>&cadena="+cadena;	
	}
  
  </SCRIPT>
<FORM NAME="" METHOD="get">
   		
    		<TABLE>
    			<TR><TD>
        			<TABLE WIDTH="100%" >
        				<TR>
            				<TD ALIGN="right" WIDTH="140"><FONT CLASS="formplain">Value</FONT></TD>
            				<TD ALIGN="left" WIDTH="460">
              					<INPUT ID="valor" TYPE="text" NAME="value" >
            				</TD>
          				</TR>
          				<TR>
            				<TD ALIGN="right" WIDTH="140"><FONT CLASS="formplain">Mandatory</FONT></TD>
            				<TD ALIGN="left" WIDTH="460">
              					<INPUT id="obligatorio" TYPE="checkbox" NAME="obligatorio">
              					<INPUT TYPE="button" ACCESSKEY="a" VALUE="Add" CLASS="closebutton" STYLE="width:80" TITLE="ALT+a" onclick="add('values')">
								<INPUT TYPE="button" ACCESSKEY="l" VALUE="Clear" CLASS="closebutton" STYLE="width:80" TITLE="ALT+l" onclick="delAll()">            				
            				</TD>
          				</TR>
          				<TR>
            				<TD COLSPAN="2"><HR></TD>
          				</TR>
          
        			</TABLE>
          		<TABLE ID="values" CELLSPACING="1" CELLPADDING="0" width="100%">
          		<tbody>
        			<TR>
			          	<TD CLASS="tableheader" BACKGROUND="../skins/<%=sSkin%>/tablehead.gif"><B>Value</B></TD>
			          	<TD CLASS="tableheader" BACKGROUND="../skins/<%=sSkin%>/tablehead.gif"><B>Mandatory</B></TD>
 			            <!--TD CLASS="tableheader" BACKGROUND="../skins/<%=sSkin%>/tablehead.gif"><A HREF="#" onclick="selectAll()" TITLE="Select All"><IMG SRC="../images/images/selall16.gif" BORDER="0" ALT="Select All"></A></TD-->
    			    </TR>
    			    </tbody>
      			</TABLE>
      			<INPUT TYPE="button" ACCESSKEY="a" VALUE="Query" CLASS="closebutton" STYLE="width:100" TITLE="ALT+a" onclick="search()"> 
      </TD></TR>
    	</TABLE>
   	</FORM>
   
   <!-- Resultado de los datos -->
   	<TABLE>
	<TR>
	<TD CLASS="tableheader" BACKGROUND="../skins/<%=sSkin%>/tablehead.gif">
		<B>Applicant</B>
	</TD>
	<TD CLASS="tableheader" BACKGROUND="../skins/<%=sSkin%>/tablehead.gif">
		<B>Score</B>
	</TD>
	
	<%
	if(values!=null)
	for(int i=0;i<values.length;i++){%>
		<TD CLASS="tableheader" BACKGROUND="../skins/<%=sSkin%>/tablehead.gif">
			<B><%=values[i]%></B>
		</TD>
	<%}%>
	</TR>
	
	<%if (listado!=null){
		for(int i=0;i<listado.length;i++){%>
		<TR>
			<TD><%=listado[i].getAuthor()%></TD>
			<TD><%=listado[i].getScore() %></TD>
			<%
			String auxPares[] = listado[i].getValue().split(ContactRecord.SEPARADOR_VALUE);
			for(int k=0;k<values.length;k++){
				String nivel=null;
				for(int j=0;j<auxPares.length;j++){
					if(auxPares[j].toLowerCase().contains(values[k])){
						String level[] = auxPares[j].split(ContactRecord.SEPARADOR_LEVEL);
						if(level.length>1){
							nivel=level[1];
						}else{
							nivel="Yes";	
						}
					}//if
				}//for
				if(nivel!=null){%>
					<TD><%=nivel %></TD>
				<%}else{%>
					<TD>No</TD>
				<%}
			}%>
		</TR>
	<%	}
	}else{%>
		<TR>
		<TD>No results</TD>
		</TR>
	<%} %>
	</TABLE>   	
</BODY>
</HTML>
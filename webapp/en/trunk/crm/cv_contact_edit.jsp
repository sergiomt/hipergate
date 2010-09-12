<%@ page import="java.util.HashMap,java.util.LinkedList,java.util.ListIterator,java.io.IOException,java.net.URLDecoder,java.sql.SQLException,java.sql.PreparedStatement,java.sql.ResultSet,com.knowgate.jdc.*,com.knowgate.dataobjs.*,com.knowgate.acl.*,com.knowgate.crm.*,com.knowgate.hipergate.DBLanguages,com.knowgate.hipergate.Term,com.knowgate.misc.Gadgets,com.knowgate.training.ContactEducation,com.knowgate.training.ContactShortCourses,com.knowgate.training.ContactComputerScience,com.knowgate.training.ContactLanguages,com.knowgate.training.ContactExperience" language="java" session="false" contentType="text/html;charset=UTF-8" %>
<%@ include file="../methods/nullif.jspf" %><%@ include file="../methods/dbbind.jsp" %><%@ include file="../methods/cookies.jspf" %><%@ include file="../methods/authusrs.jspf" %>
<jsp:useBean id="GlobalCacheClient" scope="application" class="com.knowgate.cache.DistributedCachePeer"/><jsp:useBean id="GlobalDBLang" scope="application" class="com.knowgate.hipergate.DBLanguages"/>
<%@ include file="cv_contact_edit.jspf" %>
<BODY  TOPMARGIN="8" MARGINHEIGHT="8" onLoad="setCombos();selectTab(<%=selectTab%>);" >
    <DIV class="cxMnu1" style="width:350px"><DIV class="cxMnu2" style="width:350px">
    <SPAN class="hmMnuOff" onMouseOver="this.className='hmMnuOn'" onMouseOut="this.className='hmMnuOff'" onClick="location.href='contact_edit.jsp?id_domain=<%=id_domain%>&n_domain='+ escape('<%=n_domain%>') +'&gu_contact=<%=gu_contact%>'"><IMG src="../images/images/toolmenu/historyback.gif" width="16" style="vertical-align:middle" height="16" border="0" alt="Person"> Person</SPAN>
    <SPAN class="hmMnuOff" onMouseOver="this.className='hmMnuOn'" onMouseOut="this.className='hmMnuOff'" onClick="location.reload(true)"><IMG src="../images/images/toolmenu/locationreload.gif" width="16" style="vertical-align:middle" height="16" border="0" alt="Refresh"> Refresh</SPAN>
    <SPAN class="hmMnuOff" onMouseOver="this.className='hmMnuOn'" onMouseOut="this.className='hmMnuOff'" onClick="window.print()"><IMG src="../images/images/toolmenu/windowprint.gif" width="16" height="16" style="vertical-align:middle" border="0" alt="Print"> Print</SPAN>
  </DIV></DIV>
  <br>
   <TABLE SUMMARY="Academic Degree" WIDTH="100%">
    <TR><TD><IMG SRC="../images/images/spacer.gif" HEIGHT="4" WIDTH="1" BORDER="0"></TD></TR>
    <TR><TD CLASS="striptitle"><FONT CLASS="title1">Curriculum of &nbsp;<%=sFullName%></FONT></TD></TR>
  </TABLE>
  <br>
  <DIV style="background-color:transparent; position: relative;width:800px;height:446px">
  <DIV id="p1panel1" class="panel" style="background-color:#eee;z-index:5">
  	 <fieldset>
		<legend>Academic degree</legend>
		 <%@ include file="cv_contact_education_edit.jsp" %> 
	</fieldset>
  </DIV>
  <DIV onclick="selectTab(1)" id="p1tab1" class="tab" style="background-color:#eee; height:26px; left:0px; top:0px; z-index:5"><SPAN onmouseover="this.style.cursor='hand';" onmouseout="this.style.cursor='auto';">Higher education academic degrees</SPAN></DIV>
  
  <!-- Panel Cursos Cortos -->
  <DIV id="p1panel2" class="panel" style="background-color:#eee;z-index:4">
  	 <fieldset>
		<legend>Short Courses</legend>
		<%@ include file="cv_contact_scourses_edit.jsp" %> 
	</fieldset>
  </DIV>
  <DIV onclick="selectTab(2)" id="p1tab2" class="tab" style="background-color:#ddd; height:26px; left:160px; top:0px; z-index:4"><SPAN onmouseover="this.style.cursor='hand';" onmouseout="this.style.cursor='auto';">Short Courses</SPAN></DIV>
  
  <!-- Panel Informatica -->
  <DIV id="p1panel3" class="panel" style="background-color:#eee;z-index:3">
  	 <fieldset>
		<legend>computer Science</legend>
		<%@ include file="cv_contact_computer_science_edit.jsp" %> 
	</fieldset>
  </DIV>
  <DIV onclick="selectTab(3)" id="p1tab3" class="tab" style="background-color:#ddd; height:26px; left:320px; top:0px; z-index:3"><SPAN onmouseover="this.style.cursor='hand';" onmouseout="this.style.cursor='auto';">computer Science</SPAN></DIV>
  
  <!-- Panel Idiomas -->
  <DIV id="p1panel4" class="panel" style="background-color:#eee;z-index:2">
  	 <fieldset>
		<legend>Languages</legend>
		<%@ include file="cv_contact_languages_edit.jsp" %> 
	</fieldset>
  </DIV>
  <DIV onclick="selectTab(4)" id="p1tab4" class="tab" style="background-color:#ddd; height:26px; left:480px; top:0px; z-index:2"><SPAN onmouseover="this.style.cursor='hand';" onmouseout="this.style.cursor='auto';">Languages</SPAN></DIV>
  
  
   <!-- Panel Experiencia -->
  <DIV id="p1panel5" class="panel" style="background-color:#eee;z-index:1">
  	 <fieldset>
		<legend>Experience</legend>
		<%@ include file="cv_contact_experience_edit.jsp" %> 
	</fieldset>
  </DIV>
  <DIV onclick="selectTab(5)" id="p1tab5" class="tab" style="background-color:#ddd; height:26px; left:640px; top:0px; z-index:1"><SPAN onmouseover="this.style.cursor='hand';" onmouseout="this.style.cursor='auto';">Experience</SPAN></DIV>
  </DIV>  

</BODY>
</HTML>
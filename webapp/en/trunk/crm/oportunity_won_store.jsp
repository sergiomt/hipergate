<%@ page import="java.util.ArrayList,java.text.SimpleDateFormat,java.io.IOException,java.net.URLDecoder,java.sql.SQLException,com.knowgate.debug.DebugFile,com.knowgate.jdc.JDCConnection,com.knowgate.dataobjs.*,com.knowgate.misc.Gadgets,com.knowgate.projtrack.Project,com.knowgate.hipermail.SendMail,com.knowgate.hipergate.Order,com.knowgate.crm.Contact,com.knowgate.crm.Company" language="java" session="false" contentType="text/html;charset=UTF-8" %>
<%@ include file="../methods/dbbind.jsp" %><%@ include file="../methods/cookies.jspf" %><%@ include file="../methods/authusrs.jspf" %><%@ include file="../methods/nullif.jspf" %>
<% 

  boolean bCreateProject = nullif(request.getParameter("bo_project"),"0").equals("1");
  boolean bSendMail = nullif(request.getParameter("bo_email"),"0").equals("1");
  boolean bNewOrder = nullif(request.getParameter("bo_order"),"0").equals("1");
  
  JDCConnection oConn = null;  
  Company oComp = new Company();
  Contact oCont = new Contact();
  Order oOrdr = new Order();
    
  try {
    oConn = GlobalDBBind.getConnection("oportunity_won_store");

    if (request.getParameter("gu_company").length()>0) {
      oComp.load(oConn, new Object[]{request.getParameter("gu_company")});
    }
    if (request.getParameter("gu_contact").length()>0) {
      oCont.load(oConn, new Object[]{request.getParameter("gu_contact")});
    }
    
    oConn.setAutoCommit(false);
    
    if (bCreateProject) {
      Project oProj = new Project(oConn, request.getParameter("sel_template"));		
      oProj = new Project(oConn, oProj.clone(oConn));
      if (request.getParameter("gu_company").length()>0) oProj.replace(DB.gu_company, request.getParameter("gu_company"));
      if (request.getParameter("gu_contact").length()>0) oProj.replace(DB.gu_contact, request.getParameter("gu_contact"));
		  if (request.getParameter("dt_start").length()  >0) oProj.replace(DB.dt_start, request.getParameter("dt_start"), new SimpleDateFormat("yyyy-MM-dd"));
      if (!oComp.isNull(DB.gu_company))
        oProj.replace(DB.nm_project, Gadgets.left(oProj.getString(DB.nm_project)+" ("+oComp.getStringNull(DB.nm_commercial,oComp.getString(DB.nm_legal))+")",50));
      else if (!oCont.isNull(DB.gu_contact))
        oProj.replace(DB.nm_project, Gadgets.left(oProj.getString(DB.nm_project)+" "+oCont.getStringNull(DB.tx_name,"")+" "+oCont.getStringNull(DB.tx_surname,"")+")",50));
      oProj.store(oConn);      
    }

    if (bSendMail) {
	    ArrayList aErrs = SendMail.send(GlobalDBBind.getProperties(), request.getParameter("tx_body"), request.getParameter("tx_subject"),
	    																"noreply@hipergate.org", "hipergate", "noreply@hipergate.org", Gadgets.split(request.getParameter("tx_recipients"),','));
      
      if (aErrs!=null && DebugFile.trace) {
        for (int e=0; e<aErrs.size(); e++) DebugFile.writeln("<JSP:oportunity_won_store "+aErrs.get(e));
      }
    }

    if (bNewOrder) {
      oOrdr.put(DB.gu_workarea, request.getParameter("gu_workarea"));
      oOrdr.put(DB.gu_shop, request.getParameter("sel_shop"));
      oOrdr.put(DB.de_order, request.getParameter("tx_subject"));
      oOrdr.put(DB.id_currency, "999");
      if (!oComp.isNull(DB.gu_company)) {
        oOrdr.put(DB.gu_company, oComp.getString("gu_company"));
        oOrdr.put(DB.nm_client, oComp.getString(DB.nm_legal));
        if (!oComp.isNull(DB.id_legal)) oOrdr.put(DB.id_legal, oComp.getString(DB.id_legal));
      }
      if (!oCont.isNull(DB.gu_contact)) {
        oOrdr.put(DB.gu_contact, oCont.getString("gu_contact"));
        oOrdr.put(DB.nm_client, Gadgets.left(oCont.getStringNull(DB.tx_name,"")+" "+oCont.getStringNull(DB.tx_surname,""),100));
        if (!oCont.isNull(DB.sn_passport)) oOrdr.put(DB.id_legal, oCont.getString(DB.sn_passport));
      }
      oOrdr.store(oConn);
    }
    
    oConn.commit();
      
    oConn.close("oportunity_won_store");
  }
  catch (SQLException e) {
    // Si algo peta 
    disposeConnection(oConn,"oportunity_won_store");
    oConn = null;
    response.sendRedirect (response.encodeRedirectUrl ("../common/errmsg.jsp?title=" + e.getClass().getName() + "&desc=" + e.getMessage() + "&resume=_back"));
  }
  
  if (null==oConn) return;    
  oConn = null;
%>
<HTML>
	<HEAD>
    <SCRIPT TYPE="text/javascript" SRC="../javascript/cookies.js"></SCRIPT>
		<SCRIPT language="JavaScript" type="text/javascript">
		  <!--
		    function closeWindow() {
<%        if (bNewOrder) { %>
		        open ("../shop/order_edit_f.jsp?id_domain=" + getCookie("domainid") + "&n_domain=" + escape(getCookie("domainnm")) + "&gu_workarea=" + getCookie("workarea") + "&gu_order=<%=oOrdr.getString(DB.gu_order)%>&n_order=", "editorder", "directories=no,scrollbars=yes,toolbar=no,menubar=no,width=760,height=" + String(Math.floor((520*screen.height)/600)));
<%        } %>
					close();
		    } // closeWindow
		  //-->
		</SCRIPT>
  </HEAD>
  <BODY onLoad="closeWindow()"></BODY>
</HTML>
<%@ page import="java.io.File,java.io.IOException,java.io.OutputStream,java.net.URLDecoder,java.sql.ResultSet,java.sql.PreparedStatement,java.sql.SQLException,java.sql.Types,com.knowgate.dataobjs.DB,com.knowgate.dataobjs.DBBind,com.knowgate.jdc.JDCConnection,com.knowgate.misc.Base64Decoder,com.knowgate.misc.Gadgets,com.knowgate.dfs.HttpRequest" language="java" session="false" %>
<%@ include file="../methods/dbbind.jsp" %><jsp:useBean id="GlobalCacheClient" scope="application" class="com.knowgate.cache.DistributedCachePeer"/><% 

  JDCConnection oConn = null;
  PreparedStatement oStmt = null;
  ResultSet oRSet = null;

  try {
    String sGuJob = request.getParameter("gu_job");
    int iPgAtm = Integer.parseInt(request.getParameter("pg_atom"));
    String sGuCm = request.getParameter("gu_company");
    if (sGuCm!=null) if (sGuCm.length()==0) sGuCm="";
    String sGuCn = request.getParameter("gu_contact");
    if (sGuCn!=null) if (sGuCn.length()==0) sGuCn="";
    String sEmail = request.getParameter("tx_email");
    if (sEmail!=null) if (sEmail.length()==0) sEmail="";
    String sIp = Gadgets.left(request.getRemoteAddr(),16);
    String sRedirectUrl = Base64Decoder.decode(request.getParameter("url"));
        
    oConn = GlobalDBBind.getConnection("web_clickthrough");

    oConn.setAutoCommit(true);

    String sWrkA = GlobalCacheClient.getString(sGuJob);

	  if (null==sWrkA) {
      oStmt = oConn.prepareStatement("SELECT "+DB.gu_workarea+" FROM "+DB.k_jobs+" WHERE "+DB.gu_job+"=?");
      oStmt.setString(1, sGuJob);
      oRSet = oStmt.executeQuery();
      if (oRSet.next()) {
        sWrkA = oRSet.getString(1);
      }
      oRSet.close();
      oStmt.close();
      GlobalCacheClient.put(sGuJob, sWrkA);
	  }

    String sGuUrl = null;
    oStmt = oConn.prepareStatement("SELECT gu_url FROM k_urls WHERE gu_workarea=? AND url_addr=?");
    oStmt.setString(1, sWrkA)
    oStmt.setString(2, sRedirectUrl)
    oRSet = oStmt.executeQuery();
    if (oRSet.next()) {
      sGuUrl = oRSet.getString(1);
    }
    oRSet.close();
    oStmt.close();
    
      if (null==sGuUrl) {
        String sTxTitle = ""; 
        try {
          HttpRequest oRq = new HttpRequest(sRedirectUrl);
          Object oPageSrc = oRq.get();
          String sPageSrc = null;
          if (oPageSrc!=null) {
            sRedirectUrl = oRq.url();
					  String sRcl = oPageSrc.getClass().getName();
    				if (sRcl.equals("[B")) {
						  sPageSrc = new String((byte[]) oPageSrc,"ASCII");
    				} else if (sRcl.equals("java.lang.String")) {
              sPageSrc = (String) oPageSrc;
    				}
    			} // fi    			
          if (sPageSrc!=null) {
					  int t = Gadgets.indexOfIgnoreCase(sPageSrc,"<title>",0);
					  if (t>0) {
					    int u = Gadgets.indexOfIgnoreCase(sPageSrc,"</title>",t+7);
					    if (u>0) {
					      sTxTitle = Gadgets.left(Gadgets.removeChars(sPageSrc.substring(t+7,u).trim(),"\t\n\r"),2000);
					    }
					  }         
          }
        } catch (Exception ignore) {}
        
        sGuUrl = Gadgets.generateUUID();
        oStmt = oConn.prepareStatement("INSERT INTO k_urls (gu_url,gu_workarea,url_addr,tx_title) VALUES (?,?,?,?)");
        oStmt.setString(1, sGuUrl);
        oStmt.setString(2, sWrkA);
        oStmt.setString(3, sRedirectUrl);
        oStmt.setString(4, sTxTitle);
        oStmt.executeUpdate();
        oStmt.close();
      }
    
    oStmt = oConn.prepareStatement("INSERT INTO k_job_atoms_clicks (gu_job,pg_atom,gu_company,gu_contact,ip_addr,tx_email,gu_url) VALUES (?,?,?,?,?,?,?)");
    oStmt.setString(1, sGuJob);
    oStmt.setInt(2, iPgAtm);
    if (null==sGuCm)
      oStmt.setNull(3, Types.CHAR);
    else
      oStmt.setString(3, sGuCm);
    if (null==sGuCn)
      oStmt.setNull(4, Types.CHAR);
    else
      oStmt.setString(4, sGuCn);
    if (null==sIp)
      oStmt.setNull(5, Types.VARCHAR);
    else
      oStmt.setString(5, sIp);
    if (null==sEmail)
      oStmt.setNull(6, Types.VARCHAR);
    else
      oStmt.setString(6, sEmail);
    oStmt.setString(7, sGuUrl);
    oStmt.executeUpdate();
	  oStmt.close();
	  oStmt=null;

    oStmt = oConn.prepareStatement("UPDATE k_urls SET nu_clicks="+DBBind.Functions.ISNULL+"(nu_clicks,0)+1,dt_last_visit="+DBBind.Functions.GETDATE+" WHERE gu_url=?");
    oStmt.setString(1, sGuUrl);
    oStmt.executeUpdate();
	  oStmt.close();
	  oStmt=null;
	  
    oConn.close("web_clickthrough");
    oConn = null;
    response.sendRedirect (response.encodeRedirectUrl (sRedirectUrl));
  }
  catch (Exception e) {
    if (oStmt!=null) oStmt.close(); 
    if (oConn!=null) if (!oConn.isClosed()) oConn.close("web_clickthrough");
  }
%>
<%@ page import="java.io.IOException,java.io.File,java.net.URLDecoder,com.knowgate.jdc.JDCConnection,com.knowgate.dataobjs.DB,com.knowgate.acl.*,com.knowgate.misc.Environment,com.knowgate.misc.Gadgets,com.knowgate.crm.DistributionList,com.knowgate.hipergate.datamodel.ImportExport,com.knowgate.hipergate.datamodel.ImportExportException" language="java" session="false" contentType="text/html;charset=UTF-8" %>
<%@ include file="../methods/dbbind.jsp" %><%@ include file="../methods/cookies.jspf" %><%@ include file="../methods/authusrs.jspf" %><%@ include file="../methods/nullif.jspf" %><%!

  public static String escapeFileSeparator(String sInput, String sEscFileSep) {
    if (sEscFileSep.length()==1) {
      return sInput;
    } else {
      int nChars = sInput.length();
      StringBuffer oBuff = new StringBuffer(nChars+20);
	    for (int c=0; c<nChars; c++) {
	      if (sInput.charAt(c)==File.separatorChar)
	        oBuff.append(sEscFileSep);
	      else
	        oBuff.append(sInput.charAt(c));	      	
	    } // next
	    return oBuff.toString();
    }
  } // escapeFileSeparator
%><%

  if (autenticateSession(GlobalDBBind, request, response)<0) return;
      
  String id_domain = request.getParameter("id_domain");
  String gu_workarea = request.getParameter("gu_workarea");
  String nm_workarea = request.getParameter("nm_workarea");
  String nm_file = request.getParameter("nm_file");
  String id_encoding = request.getParameter("id_encoding");
  String id_action = request.getParameter("id_action");
  String id_type = request.getParameter("id_type");
  String tx_delimiter = request.getParameter("tx_delimiter");
  String nu_maxerrors = request.getParameter("nu_maxerrors");
  String is_recoverable = request.getParameter("is_recoverable");
  String is_loadlookups = request.getParameter("is_loadlookups");
  String bo_allcaps = request.getParameter("bo_allcaps");
  String gu_list = request.getParameter("gu_list");
  String de_list = request.getParameter("de_list");
  boolean bo_colnames = nullif(request.getParameter("bo_colnames")).equals("1");
  String nu_cols = request.getParameter("nu_cols");
  int nCols = Integer.parseInt(nu_cols);
  
  String sColName, sColType;
  String sEscFileSep = (File.separator.equals("\\") ? File.separator+File.separator : File.separator);
  String sConnStr = Environment.getProfileVar(GlobalDBBind.getProfileName(), "dburl");
  String sUsr = Environment.getProfileVar(GlobalDBBind.getProfileName(), "dbuser");
  String sPwd = Environment.getProfileVar(GlobalDBBind.getProfileName(), "dbpassword");
  String sTmpDir = Environment.getProfileVar(GlobalDBBind.getProfileName(), "temp", Environment.getTempDir());
  String sWrkADir = Gadgets.chomp(escapeFileSeparator(sTmpDir,sEscFileSep),sEscFileSep)+gu_workarea+sEscFileSep;
  
  StringBuffer sCols = new StringBuffer(nCols*30);  
  sColName = request.getParameter("colname"+String.valueOf(1));
  sColType = request.getParameter("coltype"+String.valueOf(1));    
  if (sColName.length()==0)
    sCols.append("ignore NULL");
  else
    sCols.append(sColName+" "+sColType);  
  for (int c=2; c<=nCols; c++) {
    sColName = request.getParameter("colname"+String.valueOf(c));
    sColType = request.getParameter("coltype"+String.valueOf(c));    
    if (sColName.length()==0)
      sCols.append(",ignore NULL");
    else
      sCols.append(","+sColName+" "+sColType);      
  } // next (c)

  /*
  JDCConnection oConn = null;

  try {
    if (gu_list.equals("*new*")) {
      oConn = GlobalDBBind.getConnection("textloader3");
		  oConn.setAutoCommit(false);
      DistributionList oNewLst = new DistributionList();
      oNewLst.put(DB.gu_list, Gadgets.generateUUID());
      oNewLst.put(DB.gu_workarea, gu_workarea);
      oNewLst.put(DB.tp_list, DistributionList.TYPE_STATIC);
      oNewLst.put(DB.de_list, de_list);
      oNewLst.put(DB.tx_subject, de_list);
      oNewLst.store(oConn);
      gu_list = oNewLst.getString(DB.gu_list);
      oConn.close("textloader3");
    }
  }
  catch (Exception e) {
    disposeConnection(oConn,"textloader3");
    oConn = null;
    response.sendRedirect (response.encodeRedirectUrl ("../common/errmsg.jsp?title=" + e.getClass().getName() + "&desc=" + e.getMessage() + "&resume=_back"));
    return;
  }
  */

  ImportExport oImp = new ImportExport();
  int iErrCount = 0;
  
  try {
    iErrCount = oImp.perform(id_action+" "+id_type+" CONNECT "+sUsr+" TO \""+sConnStr+"\" IDENTIFIED BY "+sPwd+" WORKAREA "+nm_workarea+" "+is_recoverable+" "+is_loadlookups+" "+bo_allcaps+(gu_list.length()>0 ? " LIST \""+de_list+"\"" : "")+" SKIP "+(bo_colnames ? "1" : "0")+" MAXERRORS "+nu_maxerrors+" INPUTFILE \""+sWrkADir+nm_file+"\" CHARSET "+id_encoding+" ROWDELIM LF COLDELIM \""+tx_delimiter+"\" BADFILE \""+sWrkADir+"bad_"+nm_file+"\" DISCARDFILE \""+sWrkADir+"dis_"+nm_file+"\" ("+sCols.toString()+")");
    response.sendRedirect (response.encodeRedirectUrl ("textloader4f.jsp?gu_workarea="+gu_workarea+"&nm_file="+Gadgets.URLEncode(nm_file)+"&id_status="+(0==iErrCount ? "success" : "warning")));
  }
  catch (ImportExportException e) {  
    response.sendRedirect (response.encodeRedirectUrl ("textloader4f.jsp?gu_workarea="+gu_workarea+"&nm_file="+Gadgets.URLEncode(nm_file)+"&id_status=error&desc=" + e.getMessage()));
  }
%>
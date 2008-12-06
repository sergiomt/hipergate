<%@ page import="java.io.File,java.io.IOException,java.io.OutputStream,java.net.URLDecoder,org.jfree.report.JFreeReportBoot,org.jfree.report.JFreeReport,org.jfree.resourceloader.Resource,org.jfree.resourceloader.ResourceException,org.jfree.resourceloader.ResourceManager,org.jfree.report.modules.misc.datafactory.sql.DriverConnectionProvider,org.jfree.report.modules.misc.datafactory.sql.SQLReportDataFactory,org.jfree.report.modules.parser.base.ReportGenerator,org.jfree.report.modules.output.pageable.pdf.PdfReportUtil,org.jfree.report.modules.output.table.html.HtmlReportUtil,org.jfree.report.modules.output.table.csv.CSVReportUtil,org.jfree.resourceloader.ResourceCreationException,org.jfree.report.ReportProcessingException,org.jfree.util.StackableException" language="java" session="false" contentType="text/html;charset=Cp1252" %>
<%@ include file="../methods/dbbind.jsp" %><%@ include file="../methods/cookies.jspf" %><%@ include file="../methods/authusrs.jspf" %><%@ include file="../methods/nullif.jspf" %>
<% 
    
  try {

	  JFreeReportBoot.getInstance().start();
	  
    ResourceManager manager = new ResourceManager();
    manager.registerDefaults();
    Resource res = manager.createDirectly(new File("C:\\Meetings.report").toURL(), JFreeReport.class);
    
    DriverConnectionProvider provider = new DriverConnectionProvider();
    provider.setDriver(GlobalDBBind.getProperty("driver"));
    provider.setProperty("user", GlobalDBBind.getProperty("dbuser"));
    provider.setProperty("password", GlobalDBBind.getProperty("dbpassword"));
    provider.setUrl(GlobalDBBind.getProperty("dburl"));

    SQLReportDataFactory dataFactory = new SQLReportDataFactory(provider);
    dataFactory.setQuery("default", "SELECT dt_start,tx_meeting FROM k_meetings");
		javax.swing.table.TableModel oTbl = dataFactory.queryData("default", null);
		
    JFreeReport report = ReportGenerator.getInstance().parseReport(new File("C:\\Meetings.report"));

          
    //JFreeReport report = (JFreeReport) res.getResource();
    //report.setData(oTbl);
    //report.setDataFactory(dataFactory);            

    //OutputStream oOut = response.getOutputStream();
		//HtmlReportUtil.createStreamHTML(report, oOut);		
		//CSVReportUtil.createCSV(report, oOut,"Cp1252");		
    //oOut.flush();
		
		//if (true) return;
  }
  catch (ResourceCreationException e) {
		out.write(e.getMessage());
    //response.sendRedirect (response.encodeRedirectUrl ("../common/errmsg.jsp?title=" + e.getClass().getName() + "&desc=" + e.getMessage() + "&resume=_back"));
  }
  catch (ReportProcessingException e) {
		out.write(e.getMessage());
		//out.write(((StackableException)e.getParent()).getParent().getClass().getName()+" "+((StackableException)e.getParent()).getParent().getMessage());
  }
  

  /* TO DO: Write HTML or redirect to another page */
%>
package com.knowgate.sagesp;

import java.sql.DriverManager;
import java.sql.Connection;
import java.sql.SQLException;
import java.sql.Statement;
import java.sql.PreparedStatement;
import java.sql.ResultSet;
import java.sql.Timestamp;
import java.sql.Types;

import java.util.Date;
import java.util.ArrayList;
import java.util.LinkedList;
import java.util.HashMap;
import java.util.ListIterator;
import java.util.Properties;

import java.math.BigDecimal;

import com.knowgate.misc.Gadgets;
import com.knowgate.jdc.JDCConnection;
import com.knowgate.dfs.FileSystem;
import com.knowgate.debug.DebugFile;
import com.knowgate.dataobjs.DB;
import com.knowgate.dataobjs.DBBind;
import com.knowgate.dataobjs.DBSubset;
import com.knowgate.dataobjs.DBCommand;
import com.knowgate.hipergate.Category;

/**
 * This class writes data from hipergate to Sage SP Factura Plus
 */
public class SageSPDbf extends DBBind {

  private final int PADDING0 = 6;
  //private final String XBaseDriver = "com.hxtt.sql.dbf.DBFDriver";
  private final String XBaseDriver = "jstels.jdbc.dbf.DBFDriver";
  
  int nWritten, nErrors;
  private ArrayList oWarnings;
  private StringBuffer oActivityLog;
  private String sXBaseConnStr, sXBaseUser, sXBasePwd;
  
  // --------------------------------------------------------------------------

  /**
   * Create bridge between hipergate and Sage SP Factura Plus
   * @param oHipergateConn Opened JDBC connection to hipergate database
   * @param oSageSPConn Opened JDBC connection to Factura Plus XBase directory files
   */
   
  public SageSPDbf (String sDbfConnStr, String sDbfUser, String sDbfPwd)
  	throws ClassNotFoundException,SQLException {
    sXBaseConnStr=sDbfConnStr;
    sXBaseUser=sDbfUser;
    sXBasePwd=sDbfPwd;
	Class.forName(XBaseDriver);
    oWarnings = new ArrayList();
    nWritten = 0;
    nErrors = 0;
 
    oActivityLog=new StringBuffer();
 	log("***************************************************************");
 	log("Inicio "+new Date().toLocaleString());

  } //

  // --------------------------------------------------------------------------
 
  public LinkedList listCompanies() throws SQLException {
    LinkedList oRetVal = new LinkedList();
    Connection oSageConn = null;
	Statement oSageStmt = null;
  
    oSageConn = getConnectionXBase();
	
	oSageStmt = oSageConn.createStatement();
	
	ResultSet oSageRSet = oSageStmt.executeQuery("SELECT CODEMP,CNOMBRE FROM Empresa ORDER BY 1");
	
	while (oSageRSet.next()) {
	  HashMap oCompany = new HashMap(7);
	  oCompany.put("CODEMP" , oSageRSet.getString(1));
	  oCompany.put("CNOMBRE", oSageRSet.getString(2));
	  oRetVal.add(oCompany);
	} // wend
	
	oSageRSet.close();
	oSageStmt.close();
	oSageConn.close();
	
	return oRetVal;
  } // listCompanies
  
  // --------------------------------------------------------------------------

  public String logStr() {
  	return oActivityLog.toString();
  }

  // --------------------------------------------------------------------------

  public String logHtml() {
  	String sRetVal;
  	
    try {
      sRetVal = Gadgets.replace(oActivityLog.toString(),"\n","<BR/>");
    } catch (org.apache.oro.text.regex.MalformedPatternException neverthrown) { sRetVal = null; }

    return sRetVal;
  }

  // --------------------------------------------------------------------------

  public void writeLogToFile(String sFilePath) throws java.io.IOException {
	FileSystem oFs = new FileSystem();
	if (0==nErrors) {
	  oFs.writefilestr(sFilePath,
					   oActivityLog.toString()+"Proceso finalizado con éxito sin avisos"+
					   "***************************************************************\n",
					   "ISO8859_1");
	} else {
	  StringBuffer oWarns = new StringBuffer();
	  int nWarns = oWarnings.size();
	  for (int w=0; w<nWarns; w++) {
	  	oWarns.append(oWarnings.get(w));
	  	oWarns.append('\n');
	  }
	  oFs.writefilestr(sFilePath,
					   oActivityLog.toString()+"Errores encontrados "+String.valueOf(nErrors)+oWarns.toString()+
					   "***************************************************************\n",
					   "ISO8859_1");
	}  
  } // writeLogToFile

  // --------------------------------------------------------------------------

  private void log(String sTxt) {
    oActivityLog.append(sTxt);
    oActivityLog.append('\n');
  }
  
  // --------------------------------------------------------------------------

  public Connection getConnectionXBase() throws SQLException {
    return DriverManager.getConnection(sXBaseConnStr,sXBaseUser,sXBasePwd);
  }

  // --------------------------------------------------------------------------

  public boolean canRead(String sTableName) throws SQLException {
    Connection oSageConn = null;
	Statement oSageStmt = null;
	boolean bRetVal;
	try {
	  oSageConn = getConnectionXBase();
	  oSageStmt = oSageConn.createStatement();
	  ResultSet oSageRSet = oSageStmt.executeQuery("SELECT * FROM "+sTableName+" WHERE 1=0");
	  oSageRSet.close();
	  oSageStmt.close();
	  oSageStmt=null;
	  oSageConn.close();
	  oSageConn=null;
	  bRetVal=true;
	} catch (SQLException sqle) {
	  oWarnings.add(sTableName+" "+sqle.getMessage());
	  log(sTableName+" "+sqle.getMessage());
	  bRetVal=false;
	} finally {
	  if (null!=oSageStmt) if (oSageStmt.isClosed()) oSageStmt.close();
	  if (null!=oSageConn) if (oSageConn.isClosed()) oSageConn.close();
	}
	return bRetVal;
  } // canRead

  // --------------------------------------------------------------------------
  
  /**
   * Get maximum value of column CCODFAM from table FAMILIAS of Sage
   */
  public int getNextFamilyId() throws SQLException, NumberFormatException {
  	
  	if (DebugFile.trace) {
  	  DebugFile.writeln("Begin SageSPDbf.getNextFamilyId()");
  	  DebugFile.incIdent();
  	}

    Connection oSageConn = getConnectionXBase();
    String sCodFam = DBCommand.queryStr(oSageConn, "SELECT MAX(CCODFAM) FROM familias WHERE CCODFAM LIKE '[0-9]'");
    int iCodFam;
    if (null==sCodFam) {
      iCodFam = 1;
    } else {
      iCodFam = Integer.parseInt(sCodFam)+1;    	
    }
    oSageConn.close();

  	if (DebugFile.trace) {
  	  DebugFile.decIdent();
  	  DebugFile.writeln("End SageSPDbf.getNextFamilyId() : "+String.valueOf(iCodFam));
  	}

    return iCodFam;
  } // getNextFamilyId

  // --------------------------------------------------------------------------
  
  /**
   * Get maximum value of column CCODCLI from table CLIENTES of Sage
   */
  public int getNextCustomerId() throws SQLException, NumberFormatException {

  	if (DebugFile.trace) {
  	  DebugFile.writeln("Begin SageSPDbf.getNextCustomerId()");
  	  DebugFile.incIdent();
  	}

    Connection oSageConn = getConnectionXBase();
    String sCodCli = DBCommand.queryStr(oSageConn, "SELECT MAX(CCODCLI) FROM CLIENTES WHERE CCODCLI LIKE '[0-9]'");
    int iCodCli;
    if (null==sCodCli) {
      iCodCli = 1;
    } else {
      iCodCli = Integer.parseInt(sCodCli)+1;
    }
    oSageConn.close();

  	if (DebugFile.trace) {
  	  DebugFile.decIdent();
  	  DebugFile.writeln("End SageSPDbf.getNextCustomerId() : "+String.valueOf(iCodCli));
  	}

    return iCodCli;
  } // getNextCustomerId

  // --------------------------------------------------------------------------
    
  /**
   * Get maximum value of column NNUMALB from table ALBCLIT of Sage
   */
  public int getNextDespatchAdviceId() throws SQLException, NumberFormatException {

  	if (DebugFile.trace) {
  	  DebugFile.writeln("Begin SageSPDbf.getNextDespatchAdviceId()");
  	  DebugFile.incIdent();
  	}

    Connection oSageConn = getConnectionXBase();
    Integer iNum = DBCommand.queryInt(oSageConn, "SELECT MAX(NNUMALB) FROM ALBCLIT");
    
    if (null==iNum) {
      iNum = new Integer(1);
    } else {
      iNum = new Integer(iNum.intValue())+1;
    }
    oSageConn.close();

  	if (DebugFile.trace) {
  	  DebugFile.decIdent();
  	  DebugFile.writeln("End SageSPDbf.getNextDespatchAdviceId() : "+iNum.toString());
  	}

    return iNum.intValue();
  } // getNextDespatchAdviceId

  // --------------------------------------------------------------------------
    
  /**
   * Get maximum value of column CREF from table ARTICULO of Sage
   */
  public int getNextArticleId() throws SQLException, NumberFormatException {

  	if (DebugFile.trace) {
  	  DebugFile.writeln("Begin SageSPDbf.getNextArticleId()");
  	  DebugFile.incIdent();
  	}

    Connection oSageConn = getConnectionXBase();
    Integer iNum = DBCommand.queryInt(oSageConn, "SELECT MAX(CREF) FROM ARTICULO WHERE CREF LIKE '[0-9]'");
    
    if (null==iNum) {
      iNum = new Integer(1);
    } else {
      iNum = new Integer(iNum.intValue()+1);
    }
    oSageConn.close();

  	if (DebugFile.trace) {
  	  DebugFile.decIdent();
  	  DebugFile.writeln("End SageSPDbf.getNextArticleId() : "+iNum.toString());
  	}

    return iNum.intValue();
  } // getNextArticleId

  // --------------------------------------------------------------------------

  public ArrayList importPrices(String sShopId) throws SQLException {

  	if (DebugFile.trace) {
  	  DebugFile.writeln("Begin SageSPDbf.importPrices("+sShopId+")");
  	  DebugFile.incIdent();
  	}

    oWarnings.clear();
    nWritten = nErrors = 0;

	JDCConnection oHgteConn = getConnection("exportCustomers");
	oHgteConn.setAutoCommit(true);

	StringBuffer sCats = new StringBuffer();
	
	sCats.append("'"+sShopId+"'");
	Category oRoot = new Category(sShopId);
	LinkedList oCats = oRoot.browse(oHgteConn, Category.BROWSE_DOWN, Category.BROWSE_TOPDOWN);
		
	ListIterator oIter = oCats.listIterator();
	while (oIter.hasNext()) {
	  Category oChld = (Category) oIter.next();
	  sCats.append(",'"+oChld.getString(DB.gu_category)+"'");
	} // wend
	 	
 	PreparedStatement oProd = oHgteConn.prepareStatement("SELECT "+DB.gu_product+" p," + DB.k_x_cat_objs+ " x FROM "+DB.k_products+" WHERE "+DB.id_ref+"=? AND p."+DB.gu_product+"=x."+DB.gu_object+" AND x."+DB.gu_category+" IN ("+sCats.toString()+")");
 	PreparedStatement oUpdt = oHgteConn.prepareStatement("UPDATE "+DB.k_products+" SET "+DB.pr_list+"=?,"+DB.dt_modified+"=? WHERE "+DB.gu_product+"=?");

    Connection oSageConn = getConnectionXBase();
	oSageConn.setAutoCommit(true);
		
	Statement oArti = oSageConn.createStatement(ResultSet.TYPE_FORWARD_ONLY, ResultSet.CONCUR_READ_ONLY);
	ResultSet rArti = oArti.executeQuery("SELECT CREF,CDETALLE,NPVP,NDTO1,NDTO2,NDTO3,NDTO4,NDTO5,NDTO6 FROM articulo");
	
	while (rArti.next()) {
	  oProd.setString(1, rArti.getString(1));
	  ResultSet rProd = oProd.executeQuery();
	  if (rProd.next()) {
		String sGuProd = rProd.getString(1);
	  	rProd.close();
		BigDecimal oPrList = rArti.getBigDecimal(3);
		oUpdt.setBigDecimal(1, oPrList);
		oUpdt.setTimestamp(2, new Timestamp(new Date().getTime()));
		oUpdt.setString(3, sGuProd);

  		if (DebugFile.trace) {
  		  DebugFile.writeln("setting price for "+rArti.getString(2)+" to "+oPrList);
  	      DebugFile.writeln("executeUpdate(k_products)");
  		}

		oUpdt.executeUpdate();
		DBSubset oFares = new DBSubset(DB.k_prod_fares,
									   "gu_product,id_fare,pr_sale,tp_fare,id_currency,pct_tax_rate,is_tax_included,dt_start,dt_end",
									   DB.gu_product+"=?", 6);
		oFares.setMaxRows(6);
		int nFares = oFares.load(oHgteConn, new Object[]{sGuProd});
		for (int f=0; f<nFares; f++) {
  		  if (DebugFile.trace) {
  		    DebugFile.writeln("setting discount "+String.valueOf(f+1)+" to "+oPrList.multiply(BigDecimal.ONE.subtract(rArti.getBigDecimal(4+f).movePointLeft(2)))+"%");
  		  }
		  oFares.setElementAt(oPrList.multiply(BigDecimal.ONE.subtract(rArti.getBigDecimal(4+f).movePointLeft(2))), DB.pr_sale, f);
		} // next
		try {
		  oFares.store(oHgteConn, Class.forName("com.knowgate.hipergate.ProductFare"), true);
		} catch (java.lang.ClassNotFoundException cnfe) { }
	      catch (java.lang.IllegalAccessException ilae) { }
	      catch (java.lang.InstantiationException inse) { }
	  } else {
	  	rProd.close();
	  }
	} //wend
	rArti.close();
	oArti.close();

	if (oSageConn!=null) oSageConn.close();

	oUpdt.close();
	oProd.close();
	
	if (oHgteConn!=null) oHgteConn.close("importPrices");

  	if (DebugFile.trace) {
  	  DebugFile.decIdent();
  	  DebugFile.writeln("End SageSPDbf.importPrices()");
  	}

	return oWarnings;	
  } // importPrices

  // --------------------------------------------------------------------------

  public ArrayList exportCustomers(String sWorkArea) throws SQLException {
    
    if (DebugFile.trace) {
      DebugFile.writeln("Begin SageSPDbf.exportCustomers("+sWorkArea+")");
      DebugFile.incIdent();
    }

	JDCConnection oHgteConn = getConnection("exportCustomers");
	oHgteConn.setAutoCommit(true);
    
    String sCodCli = null;

    int iNextFree = getNextCustomerId(); 

	String sWrkAName = DBCommand.queryStr(oHgteConn, "SELECT "+DB.nm_workarea+" FROM "+DB.k_workareas+" WHERE "+DB.gu_workarea+"='"+sWorkArea+"'");

	log("***************************************************************");
	log("Área de Trabajo "+sWrkAName+" ("+sWorkArea+")");
	log("Exportando clientes a partir del "+Gadgets.leftPad(String.valueOf(iNextFree),'0',PADDING0));

    DBSubset oCust = new DBSubset(DB.k_companies,
    							  DB.gu_company+","+DB.id_legal+","+DB.nm_legal+","+DB.nm_commercial,    							  	
    							  DB.gu_workarea+"=? AND "+DB.id_ref+" IS NULL AND "+DB.id_legal+" IS NOT NULL",100);
    int nCust = oCust.load(oHgteConn, new Object[]{sWorkArea});

	switch (nCust) {
	  case 0:
	    log("No se encontró ningún nuevo cliente para exportar");
	  	break;
	  case 1:
	    log("Se encontró 1 nuevo cliente para exportar");
	  	break;
	  default:
	  	log("Se encontraron "+String.valueOf(nCust)+" nuevos clientes para exportar");
	} // end switch

    DBSubset oAddr = new DBSubset(DB.k_addresses+" a,"+DB.k_x_company_addr + " x",
    							  "a." + DB.tp_street+",a."+DB.nm_street+",a."+DB.nu_street+",a."+
    							  DB.mn_city+",a."+DB.zipcode+",a."+DB.work_phone+",a."+
    							  DB.fax_phone+",a."+DB.contact_person+",a."+DB.tx_email+",a."+DB.ix_address,
    							  "a."+DB.gu_address+"=x."+DB.gu_address+" AND"+" x."+DB.gu_company+"=? ORDER BY a."+DB.ix_address,10);
			
	PreparedStatement oUpdt = oHgteConn.prepareStatement("UPDATE "+DB.k_companies+" SET "+DB.id_ref+"=? WHERE "+DB.gu_company+"=?");

    Connection oSageConn = getConnectionXBase();
	oSageConn.setAutoCommit(true);
    
    PreparedStatement oCliente = oSageConn.prepareStatement("INSERT INTO clientes ("+
    							  "CCODCLI,CDNICIF,CNOMCLI,CNOMCOM,CDIRCLI,CPOBCLI,CPTLCLI,CTFO1CLI,CFAXCLI,CCONTACTO) "+
    							  "VALUES (?,?,?,?,?,?,?,?,?,?)");
    PreparedStatement oDirCli = oSageConn.prepareStatement("INSERT INTO dircli ("+
    							  "CCODCLI,CIDENDIR,CNOMCOM,CDIRCLI,CPOBCLI,CPTLCLI,CTFO1CLI,CNACCLI,EMAIL) "+
    							  "VALUES (?,?,?,?,?,?,?,'ESPA',?)");
    PreparedStatement oExiste = oSageConn.prepareStatement("SELECT CCODCLI FROM clientes WHERE CNOMCLI=?", ResultSet.TYPE_FORWARD_ONLY, ResultSet.CONCUR_READ_ONLY);

    for (int c=0; c<nCust; c++) {
	  oExiste.setString(1, oCust.getString(2,c));
	  ResultSet rExiste = oExiste.executeQuery();
	  boolean bYaExiste = rExiste.next();
	  if (bYaExiste) sCodCli = rExiste.getString(1);
	  rExiste.close();
	  if (!bYaExiste) {

	  	sCodCli = Gadgets.leftPad(String.valueOf(iNextFree++),'0',PADDING0);

        if (DebugFile.trace) {
          DebugFile.writeln("Exporting customer "+oCust.getString(2,c)+" as "+sCodCli);
        }

	  	int nAddr = oAddr.load(oHgteConn, new Object[]{oCust.getString(0,c)});

        if (DebugFile.trace) {
          DebugFile.writeln(String.valueOf(nAddr)+" addresses found");
        }

	  	oCliente.setString(1, sCodCli);
	    oCliente.setString(2, String.valueOf(oAddr.getInt(DB.ix_address,0)));
	    oCliente.setString(3, oCust.getString(2,c));
	    oCliente.setString(4, oCust.getStringNull(2,c,oCust.getString(2,c)));
		if (nAddr==0) {
	      oCliente.setNull(5, Types.VARCHAR);		
	      oCliente.setNull(6, Types.VARCHAR);		
	      oCliente.setNull(7, Types.VARCHAR);		
	      oCliente.setNull(8, Types.VARCHAR);		
	      oCliente.setNull(9, Types.VARCHAR);		
	      oCliente.setNull(10, Types.VARCHAR);		
		} else {
	      oCliente.setString(5 , Gadgets.left(oAddr.getStringNull(DB.tp_street,0,"")+" "+oAddr.getStringNull(DB.nm_street,0,"")+" "+oAddr.getStringNull(DB.nu_street,0,""),100));
	      oCliente.setString(6 , oAddr.getStringNull(DB.mn_city,0,null));
	      oCliente.setString(7 , oAddr.getStringNull(DB.zipcode,0,null));
	      oCliente.setString(8 , oAddr.getStringNull(DB.work_phone,0,null));
	      oCliente.setString(9 , oAddr.getStringNull(DB.fax_phone,0,null));
	      oCliente.setString(10, oAddr.getStringNull(DB.contact_person,0,null));
		}
	    try {

    	  if (DebugFile.trace) {
            DebugFile.writeln("executeUpdate(clientes)");            
          }

	      oCliente.executeUpdate();

	      nWritten++;

	      oUpdt.setString(1, sCodCli);
	      oUpdt.setString(2, oCust.getString(0,c));

    	  if (DebugFile.trace) {
            DebugFile.writeln("executeUpdate(k_companies) setting Sage reference "+sCodCli+" for hipergate company "+oCust.getString(0,c));
          }

	      oUpdt.executeUpdate();

	      log("Cliente "+oCust.getString(DB.nm_legal,c)+" exportado con numero "+sCodCli);

	      for (int a=0; a<nAddr; a++) {
	  	    oDirCli.setString(1, sCodCli);
	        oDirCli.setString(2, Gadgets.leftPad(String.valueOf(a+1),'0',2));
	        oDirCli.setString(3, oCust.getString(2,c));	        
	        oDirCli.setString(4, Gadgets.left(oAddr.getStringNull(DB.tp_street,a,"")+" "+oAddr.getStringNull(DB.nm_street,a,"")+" "+oAddr.getStringNull(DB.nu_street,a,""),100));
	        oDirCli.setString(5, oAddr.getStringNull(DB.mn_city,0,null));
	        oDirCli.setString(6, oAddr.getStringNull(DB.zipcode,0,null));
	        oDirCli.setString(7, oAddr.getStringNull(DB.work_phone,0,null));
	        oDirCli.setString(8, oAddr.getStringNull(DB.tx_email,0,null));

    	    if (DebugFile.trace) {
              DebugFile.writeln("executeUpdate(dircli)");
            }

	        oDirCli.executeUpdate();  

	        log("Direccion "+Gadgets.leftPad(String.valueOf(a+1),'0',2)+" \""+oAddr.getStringNull(DB.tp_street,a,"")+" "+oAddr.getStringNull(DB.nm_street,a,"")+" "+oAddr.getStringNull(DB.nu_street,a,"")+"\" exportada para el cliente "+sCodCli);

	      } // next
	    } catch (Exception xcpt) {
	      nErrors++;
    	  if (DebugFile.trace) {
            DebugFile.writeln(xcpt.getClass().getName()+" Customer "+oCust.getString(2,c)+" "+xcpt.getMessage());            
          }
	      oWarnings.add(xcpt.getClass().getName()+" Cliente "+oCust.getString(2,c)+" "+xcpt.getMessage());
	      break;
	    }
	  } else {
    	if (DebugFile.trace) {
            DebugFile.writeln("Company "+oCust.getString(2,c)+"("+oCust.getString(0,c)+") already exists at Sage");
        }
	  	log("El cliente "+oCust.getString(2,c)+" ya existe en Sage");

	    oUpdt.setString(1, sCodCli);
	    oUpdt.setString(2, oCust.getString(0,c));
	    oUpdt.executeUpdate();
	  }
    } // next

    if (oExiste!=null) oExiste.close();
    if (oCliente!=null) oCliente.close();
    if (oUpdt!=null) oUpdt.close();

	if (oHgteConn!=null) oHgteConn.close("exportCustomers");
	if (oSageConn!=null) oSageConn.close();
	
    if (DebugFile.trace) {
      DebugFile.decIdent();
      DebugFile.writeln("End SageSPDbf.exportCustomers("+sWorkArea+")");
    }

    return oWarnings;
  } // exportCustomers

  // --------------------------------------------------------------------------

  public ArrayList exportDespatchAdvices(String sShopId) throws SQLException {

    if (DebugFile.trace) {
      DebugFile.writeln("Begin SageSPDbf.exportDespatchAdvices("+sShopId+")");
      DebugFile.incIdent();
    }

    oWarnings.clear();
    nWritten = nErrors = 0;

    int iNextFree = getNextDespatchAdviceId();

	JDCConnection oHgteConn = getConnection("exportDespatchAdvices");
	oHgteConn.setAutoCommit(true);

	String sWrkA = DBCommand.queryStr(oHgteConn,"SELECT gu_workarea FROM k_shops where gu_shop='"+sShopId+"'");
	String sRoot = DBCommand.queryStr(oHgteConn,"SELECT gu_root_cat FROM k_shops where gu_shop='"+sShopId+"'");
	String sShop = DBCommand.queryStr(oHgteConn,"SELECT nm_shop FROM k_shops where gu_shop='"+sShopId+"'");

	log("***************************************************************");
	log("Catálogo "+sShop+" ("+sShopId+")");
	log("Exportando albaranes a partir del "+String.valueOf(iNextFree));
	
	exportCustomers(sWrkA);
	
	Category oRoot = new Category(sRoot);
	LinkedList oCats = oRoot.browse(oHgteConn, Category.BROWSE_DOWN, Category.BROWSE_TOPDOWN);

	log(String.valueOf(oCats.size()+" subcategorías encontradas en el catálogo"));
	
	exportArticles(sRoot);
	
	ListIterator oIter = oCats.listIterator();
	while (oIter.hasNext()) {
	  Category oChld = (Category) oIter.next();
	  exportArticles(oChld.getString(DB.gu_category));
	} // wend

    DBSubset oAdvcs = new DBSubset(DB.k_despatch_advices+" a,"+DB.k_companies+" c",
    							   "a."+DB.gu_despatch+",a."+DB.pg_despatch+","+
    							   "a."+DB.id_currency+",a."+DB.dt_created+","+
    							   "c."+DB.id_ref+" AS id_customer,a."+DB.de_despatch,
    							   "a.id_ref IS NULL AND a."+DB.id_status+"='PENDIENTE' AND "+
    							   "a.gu_shop=? AND "+
    							   "a."+DB.gu_company+"=c."+DB.gu_company+
    							   " ORDER BY "+DB.pg_despatch, 100);
    int nAdvcs = oAdvcs.load(oHgteConn, new Object[]{sShopId});

	switch (nAdvcs) {
	  case 0:
	    log("No se encontró ningún nuevo albarán para exportar");
	  	break;
	  case 1:
	    log("Se encontró 1 nuevo albarán para exportar");
	  	break;
	  default:
	  	log("Se encontraron "+String.valueOf(nAdvcs)+" nuevos albaranes para exportar");
	} // end switch
    
    DBSubset oLines = new DBSubset(DB.k_despatch_lines+" l,"+DB.k_products+" p",
    							   "l."+DB.pg_line+",l."+DB.pr_sale+",l."+DB.nu_quantity+","+
    							   "l."+DB.pr_total+",l."+DB.pct_tax_rate+","+
    							   "l."+DB.is_tax_included+",l."+DB.nm_product+","+"p."+DB.id_ref,
    							   "l.gu_despatch=? AND l."+DB.gu_product+"=p."+DB.gu_product+
    							   " ORDER BY "+DB.pg_line,100);
	PreparedStatement oUpdt = oHgteConn.prepareStatement("UPDATE "+DB.k_despatch_advices+" SET "+DB.id_ref+"=?,"+
							  DB.id_status+"='EXPORTADO',"+DB.dt_modified+"="+DBBind.Functions.GETDATE+" WHERE "+DB.gu_despatch+"=?");

    Connection oSageConn = getConnectionXBase();
	oSageConn.setAutoCommit(true);

    PreparedStatement oAlbclit = oSageConn.prepareStatement("INSERT INTO albclit ("+
    							"NNUMALB,DFECALB,CCODCLI,CIDENDIR,CCODALM,LFACTURADO,DFECENT,CSUPED,"+
    							"COBSERV,CCODPAGO,NBULTOS,NPORTES,CCODAGE,NCOMISION,NTIPOALB,LSELECT,"+
    						    "NETIQUETAS,CCODDIV,NVALDIV,CCODTRAN,LMULAGEN,LREGALO,NDPP,NDTOESP,"+
    							"CSERIE,LIMPRESO,NIVAPORTES,NENTCUENTA) VALUES ("+
    							"?,?,?,?,?,?,NULL,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?)");
    PreparedStatement oAlbclil = oSageConn.prepareStatement("INSERT INTO albclil ("+
    						    "NNUMALB,CREF,CDETALLE,NPREUNIT,NDTO,NIVA,NCANENT,LCONTROL,"+
    						    "NUNIDADES,NCOMISION,NSERVICIO,CCODAGE,CPROP1,CPROP2,NNUMPED,DFECPED,"+
    						    "NTOTPED,NLINEA,NPRECPROM,NDTOPROM,LMODIF,LREGALO,CCODBAR,NENTCUENTA,"+
    						    "NDTOLIN,NPREIVAANT,FPAGO,CLOTE,DFECTRAZA,DFECSTOCK) VALUES ("+
    						    "?,?,?,?,?,?,?,?,?,?,?,NULL,NULL,NULL,0,NULL,0,?,0,0,?,?,NULL,0,0,0,NULL,NULL,NULL,NULL)");

    for (int a=0; a<nAdvcs; a++) {
      oAlbclit.setInt    (1, iNextFree);
      oAlbclit.setDate   (2, oAdvcs.getSQLDate(DB.dt_created, a));
      oAlbclit.setString (3, oAdvcs.getString("id_customer",a));
      oAlbclit.setString (4, "0");
      oAlbclit.setString (5, "AL1");
      oAlbclit.setBoolean(6, false);
      oAlbclit.setString (7, String.valueOf(oAdvcs.getInt(DB.pg_despatch, a)));
      oAlbclit.setString (8, oAdvcs.getStringNull(DB.de_despatch, a, ""));
      oAlbclit.setString (9, "CO");
      oAlbclit.setInt    (10, 0);
      oAlbclit.setBigDecimal(11, new BigDecimal(0d));
      oAlbclit.setNull(12, Types.VARCHAR);
      oAlbclit.setBigDecimal(13, new BigDecimal(0d));
      oAlbclit.setBigDecimal(14, new BigDecimal("1"));
      oAlbclit.setBoolean(15, false);
      oAlbclit.setBigDecimal(16, new BigDecimal(0d));
      oAlbclit.setString (17, "EUR");
      oAlbclit.setBigDecimal (18, new BigDecimal("166.386"));
      oAlbclit.setString (19, "001");
      oAlbclit.setBoolean(20, false);
      oAlbclit.setBoolean(21, false);
      oAlbclit.setBigDecimal(22, new BigDecimal(0d));
      oAlbclit.setBigDecimal(23, new BigDecimal(0d));
      oAlbclit.setString(24, "A");
      oAlbclit.setBoolean(25, false);
      oAlbclit.setBigDecimal(26, new BigDecimal("16"));
      oAlbclit.setBigDecimal(27, new BigDecimal(0d));
      
	  try {
    	if (DebugFile.trace) {
          DebugFile.writeln("executeUpdate(albclit)");
    	}
	    oAlbclit.executeUpdate();

	    oUpdt.setString(1, String.valueOf(iNextFree));
	    oUpdt.setString(2, oAdvcs.getString(0,a));

    	if (DebugFile.trace) {
            DebugFile.writeln("executeUpdate(k_despatch_advices) setting Sage reference "+String.valueOf(iNextFree)+" for despatch advice "+oAdvcs.getString(0,a));
    	}

	    oUpdt.executeUpdate();

		int nLines = oLines.load(oHgteConn, new Object[]{oAdvcs.getString(0,a)});
		for (int l=0; l<nLines; l++){
          oAlbclil.setInt    (1, iNextFree);
          oAlbclil.setString (2, oLines.getStringNull(DB.id_ref,l,""));
          oAlbclil.setString (3, oLines.getStringNull(DB.nm_product,l,""));
          oAlbclil.setBigDecimal(4, oLines.getDecimal(DB.pr_sale,l));
          oAlbclil.setBigDecimal(5, new BigDecimal(0d));
          oAlbclil.setBigDecimal(6, new BigDecimal(oLines.getFloat(DB.pct_tax_rate,l)));
          oAlbclil.setBigDecimal(7, new BigDecimal(oLines.getFloat(DB.nu_quantity,l)));
          oAlbclil.setBoolean(8, false);
          oAlbclil.setBigDecimal(9,  new BigDecimal(0d));
          oAlbclil.setBigDecimal(10, new BigDecimal(0d));
          oAlbclil.setBigDecimal(11, new BigDecimal(0d));
          oAlbclil.setInt(12, oLines.getInt(DB.pg_line,l));
          oAlbclil.setBoolean(13, false);
          oAlbclil.setBoolean(14, false);

    	  if (DebugFile.trace) {
            DebugFile.writeln("executeUpdate(albclil)");
    	  }

          oAlbclil.executeUpdate();
		} // next l

		log ("Albarán "+String.valueOf(iNextFree)+" exportado con "+String.valueOf(nLines)+" de detalle");
	  } catch (Exception xcpt) {
	    nErrors++;
    	if (DebugFile.trace) {
          DebugFile.writeln(xcpt.getClass().getName()+" Despatch Advice "+oAdvcs.getString(0,a)+" "+xcpt.getMessage());
        }
	    oWarnings.add(xcpt.getClass().getName()+" Albaran "+oAdvcs.getString(0,a)+" "+xcpt.getMessage());
	  }
	  iNextFree++;
    } // next
    if (oAlbclil!=null) oAlbclil.close();
    if (oAlbclit!=null) oAlbclit.close();
    if (oSageConn!=null) oSageConn.close();

    oUpdt.close();
	oHgteConn.close("exportDespatchAdvices");

    if (DebugFile.trace) {
      DebugFile.decIdent();
      DebugFile.writeln("End SageSPDbf.exportDespatchAdvices()");
    }

    return oWarnings;
  } // exportDespatchAdvices

  // --------------------------------------------------------------------------

  public ArrayList exportArticles(String sCategory) throws SQLException {

    if (DebugFile.trace) {
      DebugFile.writeln("Begin SageSPDbf.exportArticles("+sCategory+")");
      DebugFile.incIdent();
    }

	ResultSet oRSet;
	JDCConnection oHgteConn = getConnection("exportArticles");
	oHgteConn.setAutoCommit(true);

	Category oCatg = new Category();
	if (!oCatg.load(oHgteConn,sCategory)) {
      DebugFile.decIdent();
	  throw new SQLException("SageDbf.exportArticles() Category "+sCategory+" does not exist");
	}
	
    int iNextFree = getNextArticleId();

	log("***************************************************************");
	log("Categoria "+oCatg.getString(DB.nm_category)+" ("+sCategory+")");
	log("Exportando artículos a partir del "+String.valueOf(iNextFree));

    Connection oSageConn = getConnectionXBase();
	oSageConn.setAutoCommit(true);

    DBSubset oProds = new DBSubset(DB.k_categories+" c,"+DB.k_x_cat_objs+" x,"+DB.k_products+" p",
    							   "c."+DB.nm_category+","+
    							   "p."+DB.gu_product+",p."+DB.de_product+",p."+DB.pr_list,
    							   "c."+DB.gu_category+"=? AND p."+DB.id_ref+" IS NULL AND "+
    							   "x."+DB.gu_object+"=p."+DB.gu_product+" AND "+
    							   "x."+DB.gu_category+"=c."+DB.gu_category, 100);
	int nProds = oProds.load(oHgteConn, new Object[]{sCategory});

    if (DebugFile.trace) {
      DebugFile.writeln(String.valueOf(nProds)+" products found");
    }

	switch (nProds) {
	  case 0:
	    log("No se encontró ningún nuevo artículo para exportar");
	  	break;
	  case 1:
	    log("Se encontró 1 nuevo artículo para exportar");
	  	break;
	  default:
	  	log("Se encontraron "+String.valueOf(nProds)+" nuevos artículos para exportar");
	} // end switch

	DBSubset oFares = new DBSubset(DB.k_prod_fares, DB.pr_sale, DB.gu_product+"=? ORDER BY "+DB.tp_fare, 6);
	oFares.setMaxRows(6);

	PreparedStatement oUpdt = oHgteConn.prepareStatement("UPDATE "+DB.k_products+" SET "+DB.id_ref+"=? WHERE "+DB.gu_product+"=?");
	
	PreparedStatement oEfamil = oSageConn.prepareStatement("SELECT CCODFAM FROM familias WHERE CNOMFAM=?",
	                                                       ResultSet.TYPE_FORWARD_ONLY,
														   ResultSet.CONCUR_READ_ONLY);
	
	PreparedStatement oExiste = oSageConn.prepareStatement("SELECT CREF FROM articulo WHERE CREF=?",
	                                                       ResultSet.TYPE_FORWARD_ONLY,
														   ResultSet.CONCUR_READ_ONLY);
														   
    PreparedStatement oArti = oSageConn.prepareStatement("INSERT INTO articulo (CREF,CDETALLE,CCODFAM,CTIPOIVA,CCODDIV,NPVP,NDTO1,NDTO2,NDTO3,NDTO4,NDTO5,NDTO6,NPENDSER,NUNIDADES) VALUES (?,?,?,'G','EUR',?,?,?,?,?,?,?,0,0)");

	for (int p=0; p<nProds; p++) {
      if (DebugFile.trace) {
        DebugFile.writeln("Processing product "+String.valueOf(p+1));
      }

	  try {
	    oExiste.setString(1, String.valueOf(iNextFree));
	    oRSet = oExiste.executeQuery();
	    boolean bExiste = oRSet.next();
	    oRSet.close();
	    if (!bExiste) {

	  	  oEfamil.setString(1, oProds.getString(DB.nm_category,p));
	      oRSet = oEfamil.executeQuery();
	      boolean bEfamil = oRSet.next();
	      String sCodFam;
	      if (!bEfamil) {
	        oRSet.close();
	        sCodFam = Gadgets.leftPad(String.valueOf(getNextFamilyId()),'0',5);
	        DBCommand.executeUpdate(oSageConn, "INSERT INTO familias (CCODFAM,CNOMFAM) VALUES('"+sCodFam+"','"+oProds.getString(DB.nm_category,p)+"')");
	        log("Familia "+sCodFam+" "+oProds.getString(DB.nm_category,p)+" exportada");
	      } else {
	        sCodFam = oRSet.getString(1);
	        oRSet.close();	      
	      } // fi (!bEfamil)
	  	
	  	  oArti.setString(1, String.valueOf(iNextFree));
	  	  oArti.setString(2, oProds.getStringNull(DB.de_product,p,"Desconocido"));
	  	  oArti.setString(3, sCodFam);
	  	  oArti.setBigDecimal(4, oProds.getDecimal(DB.pr_list, p));

	  	  int nFares = oFares.load(oHgteConn, new Object[]{oProds.getString(0,p)});
	  	  BigDecimal[] aDto = new BigDecimal[6];
	  	
		  for (int f=1; f<=6; f++) {		  
		    if (f<=nFares)
	  	      aDto[f-1] = new BigDecimal(100d-((oFares.getDecimal(DB.pr_sale, f-1).doubleValue()*100d)/oProds.getDecimal(DB.pr_list, p).doubleValue()));
		    else
		  	  aDto[f-1] = BigDecimal.ZERO;
	  	    oArti.setBigDecimal(4+f, aDto[f-1]);
		  } // next
		  oArti.executeUpdate();

		  oUpdt.setString(1, String.valueOf(iNextFree));
		  oUpdt.setString(2, oProds.getString(DB.gu_product,p));
		  oUpdt.executeUpdate();

	      log("Articulo "+String.valueOf(iNextFree)+" "+oProds.getStringNull(DB.de_product,p,"Desconocido")+" exportado. PVP "+oProds.getDecimal(DB.pr_list, p)+" Dto1="+aDto[0].toString()+"% Dto2="+aDto[1].toString()+"% Dto3="+aDto[2].toString()+"% Dto4="+aDto[3].toString()+"% Dto5="+aDto[4].toString()+"% Dto6="+aDto[5].toString());
	    
	      iNextFree++;
	    }	    
	  } catch (Exception xcpt) {
	    nErrors++;
    	if (DebugFile.trace) {
          DebugFile.writeln(xcpt.getClass().getName()+" Product "+oProds.getString(DB.gu_product,p)+" "+xcpt.getMessage());
        }
	    oWarnings.add(xcpt.getClass().getName()+" Artículo "+oProds.getString(DB.gu_product,p)+" "+xcpt.getMessage());	  	
	  }
	} // next (p)    

    oUpdt.close();
    oArti.close();
	oExiste.close();
	oEfamil.close();

    if (oSageConn!=null) oSageConn.close();

    //oUpdt.close();
	oHgteConn.close("exportArticles");

    if (DebugFile.trace) {
      DebugFile.decIdent();
      DebugFile.writeln("End SageSPDbf.exportArticles()");
    }

    return oWarnings;
  	
  } // exportArticles

  // --------------------------------------------------------------------------
  
  public static void main(String args[]) throws Exception {
  	
  	DebugFile.dumpTo = DebugFile.DUMP_TO_STDOUT;
  	
    //SageSPDbf oDbf = new SageSPDbf("jdbc:dbf:/C:/GrupoSP/FAE08R01/dbf", "supervisor", "esplenio");
    SageSPDbf oDbf = new SageSPDbf("jdbc:jstels:dbf:C:\\GrupoSP\\FAE08R01\\DBF02", "supervisor", "esplenio");
    oDbf.exportDespatchAdvices("3e571a1611715db7e34100000deaf199");
    oDbf.close();
    System.out.print(oDbf.logStr());
  }
}

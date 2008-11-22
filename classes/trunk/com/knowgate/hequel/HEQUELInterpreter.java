package com.knowgate.hequel;

import com.knowgate.debug.*;
import com.knowgate.jdc.*;
import com.knowgate.dataobjs.*;
import com.knowgate.dataxslt.*;
import com.knowgate.acl.*;

import com.knowgate.crm.*;
import com.knowgate.dfs.*;
import com.knowgate.ldap.*;
import com.knowgate.misc.*;
import com.knowgate.hipergate.*;
import com.knowgate.hipergate.datamodel.ModelManager;
import com.knowgate.hipergate.datamodel.ImportExport;
import com.knowgate.hipergate.datamodel.UNLoCode;
import com.knowgate.scheduler.*;
import com.knowgate.cache.DistributedCachePeer;
import com.knowgate.math.Money;
import com.knowgate.lucene.*;
import com.knowgate.math.CurrencyCode;

import com.knowgate.ole.*;
import org.apache.poi.hpsf.SummaryInformation;
import org.apache.poi.hpsf.Property;
import com.knowgate.surveys.*;

import com.knowgate.hipermail.SendMail;

import java.io.UnsupportedEncodingException;
import java.io.File;
import java.io.FileWriter;

import java.rmi.RemoteException;

import java.util.*;

import javax.mail.*;
import javax.mail.internet.*;

import java.sql.*;

import org.apache.oro.text.regex.*;

import javax.xml.transform.TransformerException;
import javax.xml.transform.TransformerConfigurationException;


public class HEQUELInterpreter  {
  public HEQUELInterpreter() {
    try {
      jbInit();
    }
    catch (Exception ex) {
      ex.printStackTrace();
    }
  }

  // ----------------------------------------------------------

  public static void main(String[] argv) throws Exception {
	
	System.out.println("hipergate.main()");

	/*
	String v;
	CSVParser p = new CSVParser();
	p.parseFile("C:\\clientes-gesco-3.txt","nm_legal;tx_name;tx_surname;nm_street;tp_street;mn_city;nm_state;zipcode;nm_country;fax_phone;work_phone;home_phone;mov_phone;tx_division;tx_email;url_addr;tx_comments");
	v = p.getField(0,2);
	System.out.println("v(0,2)="+v);
	*/
	
	//ShoppingBasket oBsk = new ShoppingBasket();
	//oBsk.parse("<ShoppingBasket><Address><gu>123456</gu><ix>1</ix></Address></ShoppingBasket>");
	
	//if (oBsk!=null) return;
	 	
	//NewsMessageIndexer.rebuild(oDbb.getProperties(),"k_newsmsgs");
	//NewsMessageRecord[] aRecs = NewsMessageSearcher.search(oDbb.getProperty("luceneindex"),"3e571a161170d6d6f50100003a257265",
	//				      								   "PERIQUITO~00001",null,"posteo",null,null,null,50,null);

	//String w = aRecs[0].getWorkArea();
	//String c = aRecs[0].getNewsGroupName();
	//String t = aRecs[0].getTitle();

	//SPDBF oDbf = new SPDBF (oDbb, "jstels.jdbc.dbf.DBFDriver");
	//oDbf.connect("jdbc:jstels:dbf:C:\\GrupoSP\\FAE08R01\\Dbf01","supervisor","esplenio");
	//System.out.println(oDbf.getNextCustomerId());
	//oDbf.close();
	
	//ImportExport  oImpExp = new ImportExport();
    //oImpExp.perform("APPEND FELLOWS CONNECT knowgate TO \"jdbc:mysql://127.0.0.1/hipergate4\" IDENTIFIED BY knowgate WORKAREA test_default INSERTLOOKUPS INPUTFILE \"C:\\\\Fellows.txt\" CHARSET ISO8859_1 ROWDELIM CRLF COLDELIM \"|\" BADFILE \"C:\\\\Fellows_bad.txt\" DISCARDFILE \"C:\\\\Fellows_discard.txt\" (nm_acl_group VARCHAR, tx_nickname VARCHAR,tx_pwd VARCHAR,tp_account VARCHAR,tx_main_email VARCHAR,nm_user VARCHAR,tx_surname1 VARCHAR, tx_surname2 VARCHAR, nm_company VARCHAR, tx_dept VARCHAR, de_title VARCHAR)");
			
	//SendMail.main(new String[]{"C:\\Temp\\sendmail.cnf"});
	
    // com.knowgate.hipergate.translator.Translate.main(new String[]{"translate","C:\\translate.cnf"});

    //Class mssql = Class.forName("com.microsoft.jdbc.sqlserver.SQLServerDriver");
	Class postgre = Class.forName("org.postgresql.Driver");
	//Class oracle = Class.forName("oracle.jdbc.driver.OracleDriver");
	//Class db2 = Class.forName("com.ibm.db2.jcc.DB2Driver");
	//Class mysql = Class.forName("com.mysql.jdbc.Driver");

    //UNLoCode.generateSQLScript("T:\\knowgate\\java\\src\\com\\knowgate\\hipergate\\datamodel\\data\\2005-2 UNLOCODE CodeList.txt","C:\\locode.sql", "C:\\countries.txt");
    //DBBind oDBB = new DBBind();



    //com.knowgate.ldap.LDAPNovell.main(new String[]{"C:\\WINNT\\hipergate.cnf", "load", "all"});

    final String sDataPath = "C:\\WorkingFolder\\kawa\\src\\com\\knowgate\\hipergate\\datamodel\\data\\";

    ModelManager oMan = new ModelManager();
    //ImportExport oImp = new ImportExport();

    try {
      //oImp.perform("APPENDUPDATE CONTACTS CONNECT sysadm TO \"jdbc:mysql://friki.kg.int/hgmysql1d\" IDENTIFIED BY LXCuU9qH7d97dcxf WORKAREA test_default INPUTFILE \"T:\\\\knowgate\\\\cargaprueba.txt\" CHARSET ISO8859_1 ROWDELIM CRLF COLDELIM \"|\" BADFILE \"C:\\\\Temp\\\\Contacts_bad.txt\" DISCARDFILE \"C:\\\\Temp\\\\Contacts_discard.txt\" (nm_legal VARCHAR, id_company_ref VARCHAR, tx_name VARCHAR, tx_surname VARCHAR, sn_passport VARCHAR, nm_street VARCHAR, nu_street VARCHAR, zipcode VARCHAR, mn_city VARCHAR, work_phone VARCHAR)");

      //oImp.perform("APPENDUPDATE USERS CONNECT sysadm TO \"jdbc:mysql://friki.kg.int/hgmysql1d\" IDENTIFIED BY LXCuU9qH7d97dcxf WORKAREA test_default INPUTFILE \"T:\\\\usuarios.txt\" CHARSET ISO8859_1 ROWDELIM CRLF COLDELIM \";\" BADFILE \"C:\\\\Users_bad.txt\" DISCARDFILE \"C:\\\\Users_discard.txt\" (id_domain INTEGER, nm_acl_group VARCHAR, tx_pwd VARCHAR, tx_nickname VARCHAR, ignore NULL, tx_main_email VARCHAR, nm_user VARCHAR, tx_surname1 VARCHAR, de_title VARCHAR)");

      //oImp.perform("APPENDUPDATE CONTACTS CONNECT knowgate TO \"jdbc:postgresql://192.168.1.10:10801/hgoltp8t\" IDENTIFIED BY knowgate WORKAREA test_default INPUTFILE \"C:\\\\Temp\\\\Contacts.txt\" CHARSET ISO8859_1 ROWDELIM CRLF COLDELIM \"|\" BADFILE \"C:\\\\Temp\\\\Contacts_bad.txt\" DISCARDFILE \"C:\\\\Temp\\\\Contacts_discard.txt\" (nm_legal VARCHAR, id_company_ref VARCHAR, tx_name VARCHAR, tx_surname VARCHAR, sn_passport VARCHAR, nm_street VARCHAR, nu_street VARCHAR, zipcode VARCHAR, mn_city VARCHAR, work_phone VARCHAR)");

      //oImp.perform("APPENDUPDATE PRODUCTS CONNECT knowgate TO \"jdbc:postgresql://192.168.1.10:5432/hgoltp2d\" IDENTIFIED BY knowgate WORKAREA test_default CATEGORY AMAZON~00001 INPUTFILE \"C:\\\\Temp\\\\Products.txt\" CHARSET ISO8859_1 ROWDELIM CRLF COLDELIM \"|\" BADFILE \"C:\\\\Temp\\\\Contacts_bad.txt\" DISCARDFILE \"C:\\\\Temp\\\\Contacts_discard.txt\" (nm_product VARCHAR,id_ref VARCHAR,de_product VARCHAR,id_fare VARCHAR,pr_list DECIMAL,pr_sale DECIMAL,id_currency VARCHAR,pct_tax_rate FLOAT,is_tax_included SMALLINT,dt_acknowledge DATE DD/MM/yyyy,id_cont_type INTEGER,id_prod_type VARCHAR,author VARCHAR,days_to_deliver SMALLINT,isbn VARCHAR,pages INTEGER,url_addr VARCHAR)");

      //oMan.connect("com.mysql.jdbc.Driver", "jdbc:mysql://127.0.0.1:3306/hipergate4", "", "knowgate", "knowgate");

      //oMan.connect("com.ibm.db2.jcc.DB2Driver", "jdbc:db2://db.kg.int:50000/hg_db2", "", "db2inst1", "123456");
      //oMan.connect("com.microsoft.jdbc.sqlserver.SQLServerDriver", "jdbc:microsoft:sqlserver://192.168.1.24:1433;DatabaseName=hipergate21", "dbo", "sa", "kg");

      //oMan.connect("org.postgresql.Driver", "jdbc:postgresql://127.0.0.1:5432/postgres", "", "postgres", "postgres");

      oMan.connect("oracle.jdbc.driver.OracleDriver", "jdbc:oracle:thin:@127.0.0.1:1521:XE", "HIPERGATE", "HIPERGATE", "HIPERGATE");

     //String[] creat = { "run", "MAIL", "C:\\WINNT\\hipergate.cnf",  "c0a80146f90a7fc187100134ee7a703c", "verbose" };
     //com.knowgate.scheduler.SingleThreadExecutor.main(creat);
     //oMan.main(creat);

     oMan.dropAll();
     oMan.clear();

     //String[] args = { "C:\\WINNT\\hipergate.cnf",  "script", "k_companies", "C:\\TEMP\\k_comapnies.sql" };
     //String[] args = { "C:\\WINNT\\hipergate.cnf",  "create", "database", "verbose" };
     //String[] args = { "C:\\WINNT\\hipergate.cnf",  "upgrade", "200", "210" };
     //ModelManager.main(args);

     //oMan.createDefaultDatabase();

     //oMan.cloneWorkArea("KG.kg_default", "KG.ldap");

     /*
     LDAPNovell oLDAP = new LDAPNovell();
     oLDAP.connect("ldap://fobos:389/dc=hipergate,dc=org");
     oLDAP.bind("cn=Manager,dc=hipergate,dc=org","manager");
     oLDAP.deleteWorkArea("KG", "ldap");
     oLDAP.loadWorkArea(oMan.getConnection(), "KG", "ldap");
     */

     oMan.disconnect();
     //oLDAP.disconnect();
    }
    catch (Exception e) {
      System.out.println(e.getMessage());
    }
    finally {
      File oLog = new File ("C:\\ModelManager.txt");
      oLog.delete();

      FileWriter oLogWrt = new FileWriter(oLog, true);

      oLogWrt.write(oMan.report());

      oLogWrt.close();

      if (null!=oMan) oMan.disconnect();
    }
  }

  private void jbInit() throws Exception {
  }
}

package com.knowgate.clocial;

import java.io.InputStream;
import java.io.IOException;
import java.io.InputStreamReader;

import java.sql.Types;

import java.math.BigDecimal;

import java.text.SimpleDateFormat;
import java.text.ParseException;

import java.util.ArrayList;
import java.util.Iterator;
import java.util.HashMap;
import java.util.Set;

import org.xml.sax.Attributes;
import org.xml.sax.Parser;
import org.xml.sax.SAXException;
import org.xml.sax.SAXParseException;
import org.xml.sax.XMLReader;
import org.xml.sax.InputSource;
import org.xml.sax.helpers.XMLReaderFactory;
import org.xml.sax.helpers.DefaultHandler;
import org.xml.sax.helpers.ParserAdapter;
import org.xml.sax.helpers.ParserFactory;

import com.knowgate.storage.Column;
import com.knowgate.storage.Record;

public final class MetaData extends DefaultHandler {

    private static MetaData Schema = new MetaData();

    private HashMap<String,ArrayList<Column>> oColumnCatalog;
    private HashMap<String,Record> oRecordCatalog;
    private String sTableName,sPojoClass,sSchemaName,sPackageName;
    private ArrayList<Column> oColDefs;
    private int iColPos;
	boolean bInitialized;

    public MetaData() {
      oColumnCatalog = new HashMap<String,ArrayList<Column>>();
      oRecordCatalog = new HashMap<String,Record>();
      bInitialized = false;
    }
    
    private void init() {

	  if (!bInitialized) {

        System.out.println("MetaData.init()");

        bInitialized = true;

        try {
      	
	      XMLReader oParser;
	      Parser oSax1Parser;

          try {
            oParser = XMLReaderFactory.createXMLReader("org.apache.xerces.parsers.SAXParser");
          }
          catch (Exception e) {
            oSax1Parser = ParserFactory.makeParser("org.apache.xerces.parsers.SAXParser");
            oParser = new ParserAdapter(oSax1Parser);
          }

          oParser.setContentHandler(this);

	      InputStream oInStm = getClass().getResourceAsStream("MetaData.xml");
	      InputSource oInSrc = new InputSource(oInStm);
	      oParser.parse(oInSrc);
	      oInStm.close();

        } catch (InstantiationException e) {
	      bInitialized = false;
          System.out.println("InstantiationException "+e.getMessage());
        } catch (ClassNotFoundException e) {
	      bInitialized = false;
          System.out.println("ClassNotFoundException "+e.getMessage());
        } catch (IllegalAccessException e) {
	      bInitialized = false;
          System.out.println("IllegalAccessException "+e.getMessage());
        } catch (IOException e) {
	      bInitialized = false;
          System.out.println("IOException "+e.getMessage());
        } catch (SAXException e) {
	      bInitialized = false;
          System.out.println("SAXException "+e.getMessage());
        }
	  } // fi
    }

    // -------------------------------------------------------------------------

    public static MetaData getDefaultSchema() {
      Schema.init();
      return Schema;
    }

    // -------------------------------------------------------------------------

    public String getSchemaName() {
      init();
      return sSchemaName;
    }

    // -------------------------------------------------------------------------

    public String getPackageName() {
      init();
      return sPackageName;
    }

    // -------------------------------------------------------------------------

    public ArrayList<Column> getColumns(String sTableName)
      throws ArrayIndexOutOfBoundsException {
      init();
      if (oColumnCatalog.containsKey(sTableName))
        return oColumnCatalog.get(sTableName);
      else if (oRecordCatalog.containsKey(sTableName))
      	return getColumns(oRecordCatalog.get(sTableName).getTableName());
      else
      	throw new ArrayIndexOutOfBoundsException("No Table nor Record found with name "+sTableName);
    }

    // -------------------------------------------------------------------------

    public HashMap<String,Record> getRecords() {
      init();
      return oRecordCatalog;
    } // getRecords()
    
    // -------------------------------------------------------------------------

    public void startDocument() throws SAXException {
      init();
    } // startDocument

    // -------------------------------------------------------------------------

    public void startElement(String uri, String local, String raw, Attributes attrs) throws SAXException {
        String sDefVal;
        Object oDefVal = null;
		
        if (local.equals("Record")) {
          oColDefs = new ArrayList<Column>();
          sTableName = attrs.getValue("table");
          sPojoClass = attrs.getValue("pojo");
          System.out.println("Reading definition for "+sTableName);
          iColPos = 0;
          if (null==sTableName) throw new SAXException("Table name is required");
        } else if (local.equals("Column")) {
          try {
          String sName = attrs.getValue("name");
          if (null==sName) throw new SAXException("Name for Column at "+sTableName+" is required");
          int iType = Types.VARCHAR;
          String sType = attrs.getValue("type");
          if (sType==null) {
            iType = Types.VARCHAR;
          } else if (sType.equalsIgnoreCase("VARCHAR")) {
            iType = Types.VARCHAR;
          } else if (sType.equalsIgnoreCase("INT") || sType.equalsIgnoreCase("INTEGER")) {
            iType = Types.INTEGER;
          } else if (sType.equalsIgnoreCase("DATETIME") || sType.equalsIgnoreCase("TIMESTAMP")) {
            iType = Types.TIMESTAMP;
          } else if (sType.equalsIgnoreCase("BOOLEAN")) {
            iType = Types.BOOLEAN;
          } else if (sType.equalsIgnoreCase("JAVA_OBJECT")) {
            iType = Types.JAVA_OBJECT;
		  } else if (sType.equalsIgnoreCase("VARBINARY")) {
            iType = Types.LONGVARBINARY;
		  } else if (sType.equalsIgnoreCase("LONGVARBINARY")) {
            iType = Types.LONGVARBINARY;                        
          } else {
            iType = Types.VARCHAR;
          }
          int iMaxLength = 0;
          if (attrs.getValue("maxlength")==null) {
          	switch (iType) {
			  case Types.BOOLEAN:
          	    iMaxLength = 5;
          		sDefVal = attrs.getValue("default");
				if (sDefVal!=null) oDefVal = Boolean.parseBoolean(sDefVal);
				break;
			  case Types.CHAR:
          		sDefVal = attrs.getValue("default");
				if (sDefVal!=null) oDefVal = sDefVal;
          	    iMaxLength = 256;
				break;
			  case Types.VARCHAR:
          		sDefVal = attrs.getValue("default");
				if (sDefVal!=null) oDefVal = sDefVal;
          	    iMaxLength = 8000;
				break;
			  case Types.LONGVARCHAR:
          		sDefVal = attrs.getValue("default");
				if (sDefVal!=null) oDefVal = sDefVal;
			  	iMaxLength = 2147483647;
				break;			  	
			  case Types.SMALLINT:
          		sDefVal = attrs.getValue("default");
				if (sDefVal!=null) oDefVal = new Short(sDefVal);
			  	iMaxLength = 5;
			  	break;
			  case Types.INTEGER:
          		sDefVal = attrs.getValue("default");
				if (sDefVal!=null)
				  if (sDefVal.equalsIgnoreCase("SERIAL"))
				    oDefVal = "SERIAL";
				  else
					oDefVal = new Integer(sDefVal);
			  	iMaxLength = 11;
			  	break;
			  case Types.DECIMAL:
			  case Types.NUMERIC:
          		sDefVal = attrs.getValue("default");
				if (sDefVal!=null) oDefVal = new BigDecimal(sDefVal);
			  	iMaxLength = 28;
			  	break;
			  case Types.DATE:
          		sDefVal = attrs.getValue("default");
				if (sDefVal!=null) {
				  if (sDefVal.equalsIgnoreCase("current_timestamp") || sDefVal.toLowerCase().startsWith("now")) {
				    oDefVal = new java.util.Date();
				  } else {
					SimpleDateFormat oFmt = new SimpleDateFormat("yyyy-MM-dd");
					try  { oDefVal = oFmt.parse(sDefVal); }
					catch (ParseException pe) { throw new SAXException(pe.getMessage(),pe); }
				  }
				}
			  	iMaxLength = 10;
			  	break;
			  case Types.TIMESTAMP:
          		sDefVal = attrs.getValue("default");
				if (sDefVal!=null) {
				  if (sDefVal.equalsIgnoreCase("current_timestamp") || sDefVal.toLowerCase().startsWith("now")) {
				    oDefVal = new java.util.Date();
				  } else {
					SimpleDateFormat oFmt = new SimpleDateFormat("yyyy-MM-dd HH:mm:ss");
					try  { oDefVal = oFmt.parse(sDefVal); }
					catch (ParseException pe) { throw new SAXException(pe.getMessage(),pe); }
				  }
				}
			  	iMaxLength = 24;
			  	break;
			  case Types.VARBINARY:
			  	iMaxLength = 65535;
				break;			  	
			  case Types.LONGVARBINARY:
			  case Types.JAVA_OBJECT:			  	
          	    iMaxLength = 2147483647;
				break;			  	
			  default:
          	    iMaxLength = 2147483647;
          	}
          } else {
            try {
              iMaxLength = Integer.parseInt(attrs.getValue("maxlength"));              
            } catch (NumberFormatException e) {
              throw new SAXException("Invalid maxlength attribute for column "+sName);
            }
            if (iMaxLength<0) {
              throw new SAXException("Invalid maxlength attribute for column "+sName+" cannot be a negative integer");
            }
          	switch (iType) {
			  case Types.BOOLEAN:
          		sDefVal = attrs.getValue("default");
				if (sDefVal!=null) oDefVal = Boolean.parseBoolean(sDefVal);
				break;
			  case Types.CHAR:
          		sDefVal = attrs.getValue("default");
				if (sDefVal!=null) oDefVal = sDefVal;
				break;
			  case Types.VARCHAR:
          		sDefVal = attrs.getValue("default");
				if (sDefVal!=null) oDefVal = sDefVal;
				break;
			  case Types.LONGVARCHAR:
          		sDefVal = attrs.getValue("default");
				if (sDefVal!=null) oDefVal = sDefVal;
				break;			  	
			  case Types.SMALLINT:
          		sDefVal = attrs.getValue("default");
				if (sDefVal!=null) oDefVal = new Short(sDefVal);
			  	break;
			  case Types.INTEGER:
          		sDefVal = attrs.getValue("default");
				if (sDefVal!=null)
				  if (sDefVal.equalsIgnoreCase("SERIAL"))
				    oDefVal = "SERIAL";
				  else
				    oDefVal = new Integer(sDefVal);
			  	break;
			  case Types.DECIMAL:
			  case Types.NUMERIC:
          		sDefVal = attrs.getValue("default");
				if (sDefVal!=null) oDefVal = new BigDecimal(sDefVal);
			  	break;
			  case Types.DATE:
          		sDefVal = attrs.getValue("default");
				if (sDefVal!=null) {
				  if (sDefVal.equalsIgnoreCase("current_timestamp") || sDefVal.toLowerCase().startsWith("now")) {
				    oDefVal = new java.util.Date();
				  } else {
					SimpleDateFormat oFmt = new SimpleDateFormat("yyyy-MM-dd");
					try  { oDefVal = oFmt.parse(sDefVal); }
					catch (ParseException pe) { throw new SAXException(pe.getMessage(),pe); }
				  }
				}
			  	break;
			  case Types.TIMESTAMP:
          		sDefVal = attrs.getValue("default");
				if (sDefVal!=null) {
				  if (sDefVal.equalsIgnoreCase("current_timestamp") || sDefVal.toLowerCase().startsWith("now")) {
				    oDefVal = new java.util.Date();
				  } else {
					SimpleDateFormat oFmt = new SimpleDateFormat("yyyy-MM-dd HH:mm:ss");
					try  { oDefVal = oFmt.parse(sDefVal); }
					catch (ParseException pe) { throw new SAXException(pe.getMessage(),pe); }
				  }
				}
			  	break;
          	}
          }
          boolean bIsPk;
          if (attrs.getValue("constraint")==null) {
            bIsPk = false;
          } else {
          	bIsPk = attrs.getValue("constraint").equalsIgnoreCase("primary key") ||
          		    attrs.getValue("constraint").equalsIgnoreCase("primarykey"); 
          }
          boolean bIndexed;
          if (attrs.getValue("indexed")==null) {
            bIndexed = false;
          } else {
            bIndexed = Boolean.parseBoolean(attrs.getValue("indexed"));
          }
          boolean bNullable;
          if (attrs.getValue("nullable")==null) {
            bNullable = true;
          } else {
            bNullable = Boolean.parseBoolean(attrs.getValue("nullable"));
          }
          String sForeignKey = attrs.getValue("foreignkey");

          String sCheck = attrs.getValue("check");
          if (iType==Types.TIMESTAMP && sCheck==null)
            sCheck = "\\d\\d\\d\\d-[01]\\d-[0123]\\d [012]\\d:[012345]\\d:[012345]\\d";
      	  oColDefs.add(new Column(++iColPos, sName, iType, iMaxLength,
      	  						  bNullable, bIndexed, sCheck, sForeignKey, oDefVal, bIsPk));
          } catch (org.apache.oro.text.regex.MalformedPatternException mpe) {
          	throw new SAXException("Malformed pattern "+attrs.getValue("check")+" for column "+attrs.getValue("name"),mpe);
          }          
        } else if (local.equals("Schema")) {
          System.out.println("Reading schema "+attrs.getValue("name")+" with package "+attrs.getValue("package"));
          sSchemaName = attrs.getValue("name");
          sPackageName = attrs.getValue("package");
        }
    } // startElement

    // -------------------------------------------------------------------------

	public void endElement(String uri, String local, String name) throws SAXException {
        if (local.equals("Record")) {
          try {
            oColumnCatalog.put(sTableName, oColDefs);
            if (sPojoClass!=null)
              if (sPojoClass.length()>0)
                oRecordCatalog.put(sPojoClass,
                                  (Record) Class.forName(sPackageName+"."+sPojoClass).newInstance());
            System.out.println("Definition for "+sTableName+" readed");
          } catch (ClassNotFoundException cnfe) {
            System.out.println("ClassNotFoundException "+sPackageName+"."+sPojoClass);
            throw new SAXException("Class not found "+sPackageName+"."+sTableName, cnfe);
          } catch (InstantiationException inse) {
            System.out.println("InstantiationException "+sPackageName+"."+sPojoClass);
            throw new SAXException("Instantiation exception "+sPackageName+"."+sTableName, inse);
          } catch (IllegalAccessException ilae) {
            System.out.println("IllegalAccessException "+sPackageName+"."+sPojoClass);
            throw new SAXException("Illegal access exception "+sPackageName+"."+sTableName, ilae);
          } finally {
            oColDefs = null;
            sTableName = null;
          }
        }
	} // endElement

    // -------------------------------------------------------------------------

}

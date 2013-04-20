package com.knowgate.clocial;

import java.io.InputStream;
import java.io.IOException;

import java.sql.Types;

import java.math.BigDecimal;

import java.text.SimpleDateFormat;
import java.text.ParseException;

import java.util.LinkedList;
import java.util.HashMap;

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

import com.knowgate.debug.DebugFile;
import com.knowgate.debug.StackTraceUtil;
import com.knowgate.storage.Column;
import com.knowgate.storage.Record;

public final class MetaData extends DefaultHandler {

    private static MetaData Schema = new MetaData();

    private HashMap<String,LinkedList<Column>> oColumnCatalog;
    private HashMap<String,Record> oRecordCatalog;
    private String sTableName,sPojoClass,sSchemaName,sPackageName;
    private LinkedList<Column> oColDefs;
    private int iColPos;
	boolean bInitialized;

    public MetaData() {
      oColumnCatalog = new HashMap<String,LinkedList<Column>>();
      oRecordCatalog = new HashMap<String,Record>();
      bInitialized = false;
    }
    
    private void init() {

	  if (!bInitialized) {

        if (DebugFile.trace) DebugFile.writeln("Begin MetaData.init()");

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

		  InputStream oInStm;
		  
		  if (DebugFile.trace) {
	        java.net.URL oResUrl = getClass().getResource("MetaData.xml");
	        if (oResUrl==null)
	          DebugFile.writeln("Could not get resource MetaData.xml");
	        else
	          DebugFile.writeln("Getting resource with URL "+oResUrl.toString());
	        oInStm = getClass().getResourceAsStream("MetaData.xml");
		    DebugFile.writeln("parsing");
		    int i;
		    char[] c = new char[1];
		    while ((i=oInStm.read())!=-1) {
		      c[0] = (char) i;
		      DebugFile.write(c);
		    } // wend
		    DebugFile.writeln("\n");
		  }
		  
	      oInStm = getClass().getResourceAsStream("MetaData.xml");
	      InputSource oInSrc = new InputSource(oInStm);
	      oParser.parse(oInSrc);
	      oInStm.close();

        } catch (InstantiationException e) {
	      bInitialized = false;
	      try {
          if (DebugFile.trace) DebugFile.writeln("InstantiationException "+e.getMessage()+"\n"+StackTraceUtil.getStackTrace(e));
	      } catch (IOException ignore) {}
        } catch (ClassNotFoundException e) {
	      bInitialized = false;
	      try {
          if (DebugFile.trace) DebugFile.writeln("ClassNotFoundException "+e.getMessage()+"\n"+StackTraceUtil.getStackTrace(e));
	      } catch (IOException ignore) {}
        } catch (IllegalAccessException e) {
	      bInitialized = false;
	      try {
          if (DebugFile.trace) DebugFile.writeln("IllegalAccessException "+e.getMessage()+"\n"+StackTraceUtil.getStackTrace(e));
	      } catch (IOException ignore) {}
        } catch (IOException e) {
	      bInitialized = false;
	      try {
          if (DebugFile.trace) DebugFile.writeln("IOException "+e.getMessage()+"\n"+StackTraceUtil.getStackTrace(e));
	      } catch (IOException ignore) {}
        } catch (SAXException e) {
	      bInitialized = false;
	      try {
          if (DebugFile.trace) DebugFile.writeln("SAXException "+e.getMessage()+"\n"+StackTraceUtil.getStackTrace(e));
	      } catch (IOException ignore) {}
        }

        if (DebugFile.trace) DebugFile.writeln("End MetaData.init()");

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

    public LinkedList<Column> getColumns(String sTableName)
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
        String sDefVal,sName=null,sCheck=null,sForeignKey=null;
        int iType = Types.NULL;
        int iMaxLength = 0;
        Object oDefVal = null;
        boolean bNullable=true,bIsPk=false,bIndexed=false;
		
        if (local.equals("Record")) {
          oColDefs = new LinkedList<Column>();
          sTableName = attrs.getValue("table");
          sPojoClass = attrs.getValue("pojo");
          if (DebugFile.trace) DebugFile.writeln("Reading definition for "+sTableName);
          iColPos = 0;
          if (null==sTableName) throw new SAXException("Table name is required");
        } else if (local.equals("Column")) {
          try {
          sName = attrs.getValue("name");
          if (null==sName) throw new SAXException("Name for Column at "+sTableName+" is required");
          iType = Types.VARCHAR;
          String sType = attrs.getValue("type");
          if (sType==null) {
            iType = Types.VARCHAR;
          } else if (sType.equalsIgnoreCase("VARCHAR")) {
            iType = Types.VARCHAR;
          } else if (sType.equalsIgnoreCase("INT") || sType.equalsIgnoreCase("INTEGER")) {
            iType = Types.INTEGER;
          } else if (sType.equalsIgnoreCase("BIGINT")) {
            iType = Types.BIGINT;
          } else if (sType.equalsIgnoreCase("DECIMAL")) {
            iType = Types.DECIMAL;
          } else if (sType.equalsIgnoreCase("DATETIME") || sType.equalsIgnoreCase("TIMESTAMP")) {
            iType = Types.TIMESTAMP;
          } else if (sType.equalsIgnoreCase("BOOLEAN")) {
            iType = Types.BOOLEAN;
		  } else if (sType.equalsIgnoreCase("VARBINARY")) {
            iType = Types.LONGVARBINARY;
		  } else if (sType.equalsIgnoreCase("LONGVARCHAR")) {
            iType = Types.LONGVARCHAR;
		  } else if (sType.equalsIgnoreCase("LONGVARBINARY")) {
            iType = Types.LONGVARBINARY;                        
          } else if (sType.equalsIgnoreCase("JAVA_OBJECT")) {
            iType = Types.JAVA_OBJECT;
          } else {
            iType = Types.VARCHAR;
          }
          
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
			  case Types.BIGINT:
          		sDefVal = attrs.getValue("default");
				if (sDefVal!=null)
				  if (sDefVal.equalsIgnoreCase("SERIAL"))
				    oDefVal = "SERIAL";
				  else
					oDefVal = new Long(sDefVal);
			  	iMaxLength = 21;
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
          if (attrs.getValue("constraint")==null) {
            bIsPk = false;
          } else {
          	bIsPk = attrs.getValue("constraint").equalsIgnoreCase("primary key") ||
          		    attrs.getValue("constraint").equalsIgnoreCase("primarykey"); 
          }
          if (attrs.getValue("indexed")==null) {
            bIndexed = false;
          } else {
            bIndexed = Boolean.parseBoolean(attrs.getValue("indexed"));
          }
          if (attrs.getValue("nullable")==null) {
            bNullable = true;
          } else {
            bNullable = Boolean.parseBoolean(attrs.getValue("nullable"));
          }
          sForeignKey = attrs.getValue("foreignkey");
          sCheck = attrs.getValue("check");
          if (iType==Types.TIMESTAMP && sCheck==null)
            sCheck = "\\d\\d\\d\\d-[01]\\d-[0123]\\d [012]\\d:[012345]\\d:[012345]\\d";
      	  oColDefs.add(new Column(++iColPos, sName, iType, iMaxLength,
      	  						  bNullable, bIndexed, sCheck, sForeignKey, oDefVal, bIsPk));
          } catch (org.apache.oro.text.regex.MalformedPatternException mpe) {
          	if (DebugFile.trace) DebugFile.writeln("MalformedPatternException "+attrs.getValue("check")+" for column "+attrs.getValue("name"));
          	throw new SAXException("Malformed pattern "+attrs.getValue("check")+" for column "+attrs.getValue("name"),mpe);
          }
		  if (DebugFile.trace) DebugFile.writeln("readed definition for column "+sName+" "+Column.typeName(iType)+"("+String.valueOf(iMaxLength)+") "+(bNullable ? "NULL" : "NOT NULL")+" "+(bIsPk ? "PRIMARY KEY" : bIndexed ? "INDEXED" : "")+" DEFAULT "+oDefVal+" CHECK "+sCheck+" REFERENCES "+sForeignKey);
		          
        } else if (local.equals("Schema")) {
          if (DebugFile.trace) DebugFile.writeln("Reading schema "+attrs.getValue("name")+" with package "+attrs.getValue("package"));
          sSchemaName = attrs.getValue("name");
          sPackageName = attrs.getValue("package");
        }
    } // startElement

    // -------------------------------------------------------------------------

	public void endElement(String uri, String local, String name) throws SAXException {
        if (local.equals("Record")) {
          try {
            if (DebugFile.trace) {
  	      	  String sColNames = "";
  	      	  for (Column c : oColDefs) sColNames += " "+c.getName();
              DebugFile.writeln("put "+sTableName+" table at columns catalog with columns"+sColNames);
            }
            oColumnCatalog.put(sTableName, oColDefs);
            if (sPojoClass!=null) {
              if (sPojoClass.length()>0) {
              	String sCls = sPojoClass.indexOf('.')>0 ? sPojoClass : sPackageName+"."+sPojoClass;
                if (DebugFile.trace) DebugFile.writeln("Getting Class.forName("+sCls+")");
                Class oCls = Class.forName(sCls);
                if (DebugFile.trace) DebugFile.writeln("Creating new instance of "+sCls+" with default constructor");
                oRecordCatalog.put(sCls, (Record) oCls.newInstance());
              }
            }
            if (DebugFile.trace) DebugFile.writeln("Definition for "+sTableName+" readed");
          } catch (ClassNotFoundException cnfe) {
            if (DebugFile.trace) DebugFile.writeln("ClassNotFoundException "+sPojoClass);
            throw new SAXException("Class not found "+sPojoClass, cnfe);
          } catch (InstantiationException inse) {
            if (DebugFile.trace) DebugFile.writeln("InstantiationException "+sPojoClass);
            throw new SAXException("Instantiation exception "+sPojoClass, inse);
          } catch (IllegalAccessException ilae) {
            if (DebugFile.trace) DebugFile.writeln("IllegalAccessException "+sPojoClass);
            throw new SAXException("Illegal access exception "+sPojoClass, ilae);
          } finally {
            oColDefs = null;
            sTableName = null;
          }
        }
	} // endElement

    // -------------------------------------------------------------------------

}

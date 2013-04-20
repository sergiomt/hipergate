package com.knowgate.storage;

import java.io.File;
import java.io.FileInputStream;
import java.io.InputStream;
import java.io.IOException;
import java.io.FileNotFoundException;

import java.net.URL;
import java.net.URLDecoder;

import java.sql.Types;

import java.math.BigDecimal;

import java.text.SimpleDateFormat;
import java.text.ParseException;

import java.util.LinkedList;
import java.util.HashMap;

import org.xml.sax.Attributes;
import org.xml.sax.Parser;
import org.xml.sax.SAXException;
import org.xml.sax.XMLReader;
import org.xml.sax.InputSource;
import org.xml.sax.helpers.XMLReaderFactory;
import org.xml.sax.helpers.DefaultHandler;
import org.xml.sax.helpers.ParserAdapter;
import org.xml.sax.helpers.ParserFactory;

import com.knowgate.debug.DebugFile;
import com.knowgate.debug.StackTraceUtil;

import com.knowgate.storage.Column;

public final class SchemaMetaData extends DefaultHandler {

    private HashMap<String,LinkedList<Column>> oColumnCatalog;
    private LinkedList<String> oRecordCatalog;
    private LinkedList<String> oTableCatalog;
    private String sTableName,sPojoClass,sSchemaName,sPackageName;
    private LinkedList<Column> oColDefs;
    private int iColPos;

    public SchemaMetaData() {
      oColumnCatalog = new HashMap<String,LinkedList<Column>>();
      oRecordCatalog = new LinkedList<String>();
  	  oTableCatalog = new LinkedList<String>();
    }

    public SchemaMetaData(String sPackagePath) throws FileNotFoundException, IOException, ClassNotFoundException {
      oColumnCatalog = new HashMap<String,LinkedList<Column>>();
      oRecordCatalog = new LinkedList<String>();
  	  oTableCatalog = new LinkedList<String>();
  	  load(new File(SchemaMetaData.getAbsolutePath(sPackagePath)+"tables"));	  
    }

    protected static String getAbsolutePath(String sPackagePath)
  	  throws FileNotFoundException, ClassNotFoundException {
      URL oPackURL;
    
      if (sPackagePath.endsWith("com/knowgate/clocial")) {
        Class oModMan = Class.forName("com.knowgate.clocial.ModelManager");
    	oPackURL = oModMan.getResource("/com/knowgate/clocial");
      } else {
        oPackURL = ClassLoader.class.getResource(sPackagePath.startsWith("/") ? sPackagePath : "/" + sPackagePath);
      }
      
      if (null==oPackURL)
        throw new FileNotFoundException("Could not find "+sPackagePath+" at CLASSPATH");
    
      String sAbsolutePath = URLDecoder.decode(oPackURL.toString());
	  if (sAbsolutePath.startsWith("file:")) sAbsolutePath = sAbsolutePath.substring(5);
	  if (sAbsolutePath.matches("/\\w:[/\\x5C]\\w.+")) sAbsolutePath = sAbsolutePath.substring(1);
	  if (!sAbsolutePath.endsWith(File.separator)) sAbsolutePath += File.separator;
	  return sAbsolutePath;
    } // 
    
    public void load(InputStream oInStm) {

        if (DebugFile.trace) DebugFile.writeln("Begin MetaData.load()");

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

	      InputSource oInSrc = new InputSource(oInStm);
	      oParser.parse(oInSrc);
	      oInStm.close();

        } catch (InstantiationException e) {
	      try {
          if (DebugFile.trace) DebugFile.writeln("InstantiationException "+e.getMessage()+"\n"+StackTraceUtil.getStackTrace(e));
	      } catch (IOException ignore) {}
        } catch (ClassNotFoundException e) {
	      try {
          if (DebugFile.trace) DebugFile.writeln("ClassNotFoundException "+e.getMessage()+"\n"+StackTraceUtil.getStackTrace(e));
	      } catch (IOException ignore) {}
        } catch (IllegalAccessException e) {
	      try {
          if (DebugFile.trace) DebugFile.writeln("IllegalAccessException "+e.getMessage()+"\n"+StackTraceUtil.getStackTrace(e));
	      } catch (IOException ignore) {}
        } catch (IOException e) {
	      try {
          if (DebugFile.trace) DebugFile.writeln("IOException "+e.getMessage()+"\n"+StackTraceUtil.getStackTrace(e));
	      } catch (IOException ignore) {}
        } catch (SAXException e) {
	      try {
          if (DebugFile.trace) DebugFile.writeln("SAXException "+e.getMessage()+"\n"+StackTraceUtil.getStackTrace(e));
	      } catch (IOException ignore) {}
        }

        if (DebugFile.trace) DebugFile.writeln("End MetaData.load()");
    }

    // -------------------------------------------------------------------------

    public void load(File oFle) throws FileNotFoundException, IOException {
  	  if (!oFle.exists()) throw new FileNotFoundException("File "+oFle.getAbsolutePath()+" not found");
	  if (oFle.isDirectory()) {
	  	File[] aFiles = oFle.listFiles();
  	  	for (int f=0; f<aFiles.length; f++) {
		  FileInputStream oFin = new FileInputStream(aFiles[f]);
		  load(oFin);
		  oFin.close();
  	  	} // next	  	
	  } else {
		FileInputStream oFin = new FileInputStream(oFle);
		load(oFin);
		oFin.close();
	  }
    }

    // -------------------------------------------------------------------------

    public String getSchemaName() {
      return sSchemaName;
    }

    // -------------------------------------------------------------------------

    public String getPackageName() {
      return sPackageName;
    }

    // -------------------------------------------------------------------------

    public LinkedList<Column> getColumns(String sTableName)
      throws ArrayIndexOutOfBoundsException {
      if (oColumnCatalog.containsKey(sTableName))
        return oColumnCatalog.get(sTableName);
      else
      	throw new ArrayIndexOutOfBoundsException("No Table nor Record found with name "+sTableName);
    }

    // -------------------------------------------------------------------------

    public LinkedList<String> getRecordsClassNames() {
      return oRecordCatalog;
    }

    // -------------------------------------------------------------------------

    public LinkedList<String> getTablesNames() {
      return oTableCatalog;
    }

    // -------------------------------------------------------------------------

    public void startDocument() throws SAXException {
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
            oTableCatalog.add(sTableName);
            if (sPojoClass!=null) {
              if (sPojoClass.length()>0) {
              	String sCls = sPojoClass.indexOf('.')>0 ? sPojoClass : sPackageName+"."+sPojoClass;
                if (DebugFile.trace) DebugFile.writeln("Getting Class.forName("+sCls+")");
                @SuppressWarnings("unused")
				Class oCls = Class.forName(sCls);
            	oColumnCatalog.put(sCls, oColDefs);
                oRecordCatalog.add(sCls);
              }
            }
            if (DebugFile.trace) DebugFile.writeln("Definition for "+sTableName+" readed");
          } catch (ClassNotFoundException cnfe) {
            if (DebugFile.trace) DebugFile.writeln("ClassNotFoundException "+sPojoClass);
            throw new SAXException("Class not found "+sPojoClass, cnfe);          
          } finally {
            oColDefs = null;
            sTableName = null;
          }
        }
	} // endElement

    // -------------------------------------------------------------------------

}

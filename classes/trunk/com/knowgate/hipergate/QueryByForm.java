/*
  Copyright (C) 2003  Know Gate S.L. All rights reserved.
                      C/Oña, 107 1º2 28050 Madrid (Spain)

  Redistribution and use in source and binary forms, with or without
  modification, are permitted provided that the following conditions
  are met:

  1. Redistributions of source code must retain the above copyright
     notice, this list of conditions and the following disclaimer.

  2. The end-user documentation included with the redistribution,
     if any, must include the following acknowledgment:
     "This product includes software parts from hipergate
     (http://www.hipergate.org/)."
     Alternately, this acknowledgment may appear in the software itself,
     if and wherever such third-party acknowledgments normally appear.

  3. The name hipergate must not be used to endorse or promote products
     derived from this software without prior written permission.
     Products derived from this software may not be called hipergate,
     nor may hipergate appear in their name, without prior written
     permission.

  This library is distributed in the hope that it will be useful,
  but WITHOUT ANY WARRANTY; without even the implied warranty of
  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.

  You should have received a copy of hipergate License with this code;
  if not, visit http://www.hipergate.org or mail to info@hipergate.org
*/

package com.knowgate.hipergate;

import java.io.OutputStream;
import java.io.UnsupportedEncodingException;

import java.sql.Connection;
import java.sql.SQLException;
import java.sql.Types;

import java.util.Vector;
import java.lang.StringBuffer;

import org.w3c.dom.Node;
import org.w3c.dom.Element;
import dom.DOMDocument;

import javax.servlet.http.HttpServletRequest;

import com.knowgate.jdc.JDCConnection;
import com.knowgate.dataobjs.DBSubset;
import com.knowgate.debug.DebugFile;

import com.knowgate.dataobjs.DB;
import com.knowgate.dataobjs.DBTable;
import com.knowgate.dataobjs.DBColumn;
import com.knowgate.dataobjs.DBPersist;

import com.knowgate.http.Cookies;

import com.knowgate.crm.DistributionList;

/**
 * <p>Query By Form XML parser and SQL composer.</p>
 * @author Sergio Montoro Ten
 * @version 7.0
 */

public class QueryByForm extends DBPersist {

  private DBTable oBaseTable;
  String sAlias;
  int iDBMS;
  DOMDocument oXMLDoc;


  // ----------------------------------------------------------

  /**
   * <p>Create an empty query by parsing an XML definition file.</p>
   * Input file must be encoded as ISO-8859-1
   * @param sQBFURI URI for query specification XML file (ej. file:///opt/storage/qbf/duties.xml)
   * @throws ClassNotFoundException
   * @throws IllegalAccessException
   */

  public QueryByForm(String sQBFURI)
    throws ClassNotFoundException, IllegalAccessException, Exception {
    super(DB.k_queries, "QueryByForm");
    parseURI(sQBFURI);
    iDBMS = JDCConnection.DBMS_GENERIC;
  }

  // ----------------------------------------------------------

  /**
   * <p>Create an empty query by parsing an XML definition file.</p>
   * Input file must be encoded as ISO-8859-1
   * @param sQBFURI URI for query specification XML file (ej. file:///opt/storage/qbf/duties.xml)
   * @throws ClassNotFoundException
   * @throws IllegalAccessException
   * @throws UnsupportedEncodingException
   * @since 3.0
   */

  public QueryByForm(String sQBFURI, String sEncoding)
    throws ClassNotFoundException, IllegalAccessException,
           UnsupportedEncodingException, Exception {
    super(DB.k_queries, "QueryByForm");
    parseURI(sQBFURI, sEncoding);
    iDBMS = JDCConnection.DBMS_GENERIC;
  }

  /**
   * <p>Load a query from k_queries table.</p>
   * @param oConn Database Connection
   * @param sBaseTable Query base table or view &lt;baseobject&gt; tag from XML query specification.
   * @param sTableAlias A base table alias for SQL fields
   * @param sQueryGUID Query GUID at k_queries table
   * @throws SQLException
   */
  public QueryByForm(JDCConnection oConn, String sBaseTable, String sTableAlias, String sQueryGUID) throws SQLException {
    super(DB.k_queries, "QueryByForm");
	String sSchema;
	
	iDBMS = oConn.getDataBaseProduct();
	switch (iDBMS) {
	  case JDCConnection.DBMS_POSTGRESQL:
	  	sSchema = "public";
	  	break;
	  case JDCConnection.DBMS_MSSQL:
	  	sSchema = "dbo";
	  	break;
	  default:
	  	sSchema = "";
	}
	
    oBaseTable = new DBTable(oConn.getCatalog(), sSchema, sBaseTable, 1);
    oBaseTable.readColumns(oConn, oConn.getMetaData());
    sAlias = sTableAlias;

    Object aQry[] = { sQueryGUID };

    load(oConn, aQry);
  }

  // ----------------------------------------------------------

  /**
   * <p>Parse query XML specification file.</p>
   * @param sURI URI for query specification XML file
   * @param sEncoding Character encoding used by XML input file
   * @throws ClassNotFoundException
   * @throws IllegalAccessException
   * @throws UnsupportedEncodingException
   * @since 3.0
   */
  public void parseURI(String sURI, String sEncoding)
    throws ClassNotFoundException, IllegalAccessException, Exception {

    if (DebugFile.trace) {
      DebugFile.writeln("Begin QueryByForm.parseURI(" + sURI + "," + sEncoding + ")");
      DebugFile.incIdent();
    }

    oXMLDoc = new DOMDocument();
    try {
      oXMLDoc.parseURI(sURI, sEncoding);
    }
    catch (Exception xcpt) {
      oXMLDoc = null;
      throw new Exception(xcpt.getMessage(), xcpt.getCause());
    }

    if (DebugFile.trace) {
      DebugFile.decIdent();
      DebugFile.writeln("End QueryByForm.parseURI()");
    }
  } // parseURI()

  // ----------------------------------------------------------

  /**
   * <p>Parse query XML specification file.</p>
   * @param sURI URI for query specification XML file
   * @throws ClassNotFoundException
   * @throws IllegalAccessException
   */
  public void parseURI(String sURI)
    throws ClassNotFoundException, IllegalAccessException, Exception {
    parseURI(sURI, null);
  }

  // ----------------------------------------------------------

  /**
   * @return DOMDocument object for parsed XML file.
   */
  public DOMDocument getDocument() {
    return oXMLDoc;
  }

  // ----------------------------------------------------------

  /**
   * @return &lt;action&gt; tag from XML query specification.
   * If tag &lt;action&gt; is not found then <b>null</b> is returned.
   */
  public String getAction() {
    if (DebugFile.trace) {
      DebugFile.writeln("Begin QueryByForm.getAction()");
      DebugFile.incIdent();
    }

    String sAction;

    // Obtener una referencia al nodo raiz del arbol DOM
    Node oTopNode = oXMLDoc.getRootNode().getFirstChild();
    if (oTopNode.getNodeName().equals("xml-stylesheet")) oTopNode = oTopNode.getNextSibling();

    Element oAction = (Element) oXMLDoc.seekChildByName(oTopNode, "action");

    if (null==oAction)
      sAction = null;
    else
      sAction = oXMLDoc.getTextValue(oAction);

    if (DebugFile.trace) {
      DebugFile.decIdent();
      DebugFile.writeln("End QueryByForm.getAction() : " + (sAction!=null ? sAction : "null"));
    }

    return sAction;
  } // getAction()

  // ----------------------------------------------------------

  /**
   * @return &lt;baseobject&gt; node contents.<br>
   * If tag &lt;baseobject&gt; is not found then <b>null</b> is returned.
   */
  public String getBaseObject() {
    if (DebugFile.trace) {
      DebugFile.writeln("Begin QueryByForm.getBaseObject()");
      DebugFile.incIdent();
    }

    String sBaseObj;

    // Obtener una referencia al nodo raiz del arbol DOM
    Node oTopNode = oXMLDoc.getRootNode().getFirstChild();
    if (oTopNode.getNodeName().equals("xml-stylesheet")) oTopNode = oTopNode.getNextSibling();

    Element oBaseObject = (Element) oXMLDoc.seekChildByName(oTopNode, "baseobject");

    if (null==oBaseObject)
      sBaseObj = null;
    else
      sBaseObj = oXMLDoc.getTextValue(oBaseObject);

    if (DebugFile.trace) {
      DebugFile.decIdent();
      DebugFile.writeln("End QueryByForm.getBaseObject() : " + (sBaseObj!=null ? sBaseObj : "null"));
    }

    return sBaseObj;
  } // getBaseObject()

  // ----------------------------------------------------------

  /**
   * <p>Get query base filter instantiated for given HttpServletRequest parameters.</p>
   * <p>Base filters are neccesary for separating data belonging to an specific
   * workarea for data belonging to other workareas.<br>
   * Typically every query specification have a base filter.<br>
   * The base filter may contain to types of wildcards ${cookie.<i>name</i>} and ${param.<i>name</i>}<br>
   * When one of this wildcards in encountered at base filter specification it is substituded at runtime
   * by the matching HttpServletRequest Cookie or Parameter value.</p>
   * @param oReq HttpServletRequest containing Cookies and Parameters to be substituted at base filter.
   * @return &lt;basefilter&gt; tag from XML query specification with
   * ${cookie.<i>name</i>} and ${param.<i>name</i>} wildcards substituded by
   * HttpServletRequest getCookies and getParameters values.
   */
  public String getBaseFilter(HttpServletRequest oReq) {
    if (DebugFile.trace) {
      DebugFile.writeln("Begin QueryByForm.getBaseFilter([HttpServletRequest])");
      DebugFile.incIdent();
    }

    // Obtener una referencia al nodo raiz del arbol DOM
    Node oTopNode = oXMLDoc.getRootNode().getFirstChild();
    if (oTopNode.getNodeName().equals("xml-stylesheet")) oTopNode = oTopNode.getNextSibling();

    Element oBaseObject = (Element) oXMLDoc.seekChildByName(oTopNode, "basefilter");
    String sFilter = oXMLDoc.getTextValue(oBaseObject);

    int iLength = sFilter.length();
    StringBuffer oFilter = new StringBuffer(iLength);
    int iClose;
    int iDot;
    String sItem;

    for (int c=0; c<iLength; c++) {
      if (sFilter.charAt(c)=='$' && c<iLength-1) {
        if (sFilter.charAt(c+1)=='{') {
          iDot = sFilter.indexOf('.', c);
          iClose = sFilter.indexOf('}', iDot);
          sItem = sFilter.substring(iDot+1, iClose);

          if (sFilter.substring(c+2,iDot).equals("cookie"))
            oFilter.append(Cookies.getCookie(oReq, sItem, ""));
          else if (sFilter.substring(c+2,iDot).equals("param"))
            oFilter.append(oReq.getParameter(sItem));

          c = iClose;
        }
      } // fi(sFilter[c]=='{')
      else
        oFilter.append(sFilter.charAt(c));
      } // next (c)

    if (DebugFile.trace) {
      DebugFile.decIdent();
      DebugFile.writeln("End QueryByForm.getBaseFilter() : " + oFilter.toString());
    }

    return oFilter.toString();
  } // getBaseFilter()

  // ----------------------------------------------------------

  /**
   * @return &lt;method&gt; tag from XML query specification.<br>
   * If tag &lt;method&gt; is not found then <b>null</b> is returned.
   * @throws NullPointerException if XML document was not previously set on the constructor or by calling parseURI()
   */
  public String getMethod() {
    if (DebugFile.trace) {
      DebugFile.writeln("Begin QueryByForm.getMethod()");
      DebugFile.incIdent();
    }

    if (null==oXMLDoc) {
      if (DebugFile.trace) DebugFile.decIdent();
      throw new NullPointerException("QueryByForm.getMethod() - XML document not set");
    }

    String sMethod;

    // Obtener una referencia al nodo raiz del arbol DOM
    Node oRootNode= oXMLDoc.getRootNode();
    Node oTopNode = oRootNode.getFirstChild();
    if (oTopNode.getNodeName().equals("xml-stylesheet")) oTopNode = oTopNode.getNextSibling();

    Element oMethod = (Element) oXMLDoc.seekChildByName(oTopNode, "method");

    if (null==oMethod)
      sMethod = null;
    else
      sMethod = oXMLDoc.getTextValue(oMethod);

    if (DebugFile.trace) {
      DebugFile.decIdent();
      DebugFile.writeln("End QueryByForm.getMethod() : " + (sMethod!=null ? sMethod : "null"));
    }

    return sMethod;
  } // getMethod()

  // ----------------------------------------------------------

  /**
   * @return &lt;title_<i>xx</i>&gt; tag from XML query specification, where xx==sLanguage<br>
   * If not title is found for given language then "Query" text is returned.
   * @throws NullPointerException if XML document was not previously set on the constructor or by calling parseURI()
   */
  public String getTitle(String sLanguage)
    throws NullPointerException {
    if (DebugFile.trace) {
      DebugFile.writeln("Begin QueryByForm.getTitle(" + sLanguage + ")");
      DebugFile.incIdent();
    }

    if (null==oXMLDoc) {
      if (DebugFile.trace) DebugFile.decIdent();
      throw new NullPointerException("QueryByForm.getTitle() - XML document not set");
    }

    String sTitle;

    // Obtener una referencia al nodo raiz del arbol DOM
    Node oTopNode = oXMLDoc.getRootNode().getFirstChild();
    if (oTopNode.getNodeName().equals("xml-stylesheet")) oTopNode = oTopNode.getNextSibling();

    Element oTitleNode = (Element) oXMLDoc.seekChildByName(oTopNode, "title_" + sLanguage);

    if (null!=oTitleNode)
      sTitle = oXMLDoc.getTextValue(oTitleNode);
    else
      sTitle = "Query";

    if (DebugFile.trace) {
      DebugFile.decIdent();
      DebugFile.writeln("End QueryByForm.getTitle() : " + sTitle);
    }

    return sTitle;
  } // getTitle()

  // ----------------------------------------------------------

  /**
   * @return Vector of org.w3c.dom.Element objects, one for each &lt;field&gt; tag
   */
  public Vector getFields() {
    // Obtener una referencia al nodo raiz del arbol DOM
    Node oTopNode = oXMLDoc.getRootNode().getFirstChild();
    if (oTopNode.getNodeName().equals("xml-stylesheet")) oTopNode = oTopNode.getNextSibling();

    Element oFieldsNode = (Element) oXMLDoc.seekChildByName(oTopNode, "fields");

    if (null==oFieldsNode)
      return new Vector();
    else
      return oXMLDoc.filterChildsByName(oFieldsNode, "field");
  } // getFields()

  // ----------------------------------------------------------

  /**
   * @return Vector of org.w3c.dom.Element objects, one for each &lt;sortable&gt; tag
   * if &lt;sortable&gt; tag is not found an empty vector is returned and no exception
   * is thrown.
   */
  public Vector getSortable() {
    // Obtener una referencia al nodo raiz del arbol DOM
    Node oTopNode = oXMLDoc.getRootNode().getFirstChild();
    if (oTopNode.getNodeName().equals("xml-stylesheet")) oTopNode = oTopNode.getNextSibling();

    Element oFieldsNode = (Element) oXMLDoc.seekChildByName(oTopNode, "sortable");

    if (null==oFieldsNode)
      return new Vector();
    else
      return oXMLDoc.filterChildsByName(oFieldsNode, "by");
  } // getSortable()

  // ----------------------------------------------------------

  /**
   * @return Vector of org.w3c.dom.Element objects, one for each &lt;column&gt; tag
   * @throws NullPointerException If tag &lt;columns&gt; is not found
   */
  public Vector getColumns() throws NullPointerException {
    // Obtener una referencia al nodo raiz del arbol DOM
    Node oTopNode = oXMLDoc.getRootNode().getFirstChild();
    if (oTopNode.getNodeName().equals("xml-stylesheet")) oTopNode = oTopNode.getNextSibling();

    Element oFieldsNode = (Element) oXMLDoc.seekChildByName(oTopNode, "columns");

    if (null==oFieldsNode)
      throw new NullPointerException("Cannot find <columns> tag");

    return oXMLDoc.filterChildsByName(oFieldsNode, "column");
  } // getSortable()

  // ----------------------------------------------------------

  /**
   * <p>Get SQL clause for a given field, comparison operator and value</p>
   * <p>The SQL clause is composed taking into account the operator and the value type.<br>
   * Base Object Alias is appended to each field name.<br>
   * For strings single quotes are added (ej. alias.de_duty='Walkthrought').<br>
   * Dates are escaped (ej. alias.dt_start>{d '2003-08-15'})</p>
   * @param fld Field Name
   * @param opr Comparison Operator, one of { =, <>, >, <, S, C, N, M }<br>
   * Operators S, C, N and M are translated as follows:<br>
   * S - alias.tx_job LIKE '%' + vle (field starts with)<br>
   * C - alias.tx_job LIKE '%' + vle + '%' (field contains)<br>
   * N - alias.tx_job IS NULL<br>
   * M - alias.tx_job IS NOT NULL<br>
   * @param vle Value for field
   * @return SQL clause for a given field, comparison operator and value.
   * @throws NullPointerException If field fld is not found at base table
   */
  private String getClause(String fld, String opr, String vle)
    throws NullPointerException {

  String ret;
    short type;
    DBColumn col;

    if (fld.equalsIgnoreCase(DB.dt_created)) {
      type = Types.TIMESTAMP;
    } else {
      col = oBaseTable.getColumnByName(fld.toLowerCase());
      if (null==col)
        throw new NullPointerException("Cannot find column " + fld + " on " + oBaseTable.getName());
      type = col.getSqlType();
    }

    if (type==Types.VARCHAR || type==Types.CHAR || type==Types.LONGVARCHAR || type==Types.CLOB) {
      if (opr.equals("S"))
        ret = sAlias + "." + fld + " LIKE '" + vle + "%' ";
      else if (opr.equals("C"))
        ret = sAlias + "." + fld + " LIKE '%" + vle + "%' ";
      else if (opr.equals("N"))
        ret = sAlias + "." + fld + " IS NULL ";
      else if (opr.equals("M"))
        ret = sAlias + "." + fld + " IS NOT NULL ";
      else
        ret = sAlias + "." + fld + " " + opr + " '" + vle + "' ";
    }
    else if (type==Types.DATE || type==Types.TIMESTAMP) {
      switch (iDBMS) {
        case JDCConnection.DBMS_MYSQL:
          ret = sAlias + "." + fld + opr + "CAST('" + vle + "' AS DATE) ";
		  break;
        case JDCConnection.DBMS_ORACLE:
          ret = sAlias + "." + fld + opr + "TO_DATE('" + vle + "','YYYY-MM-DD') ";
		  break;
        case JDCConnection.DBMS_POSTGRESQL:
          ret = sAlias + "." + fld + opr + "TIMESTAMP '" + vle + "' ";
		  break;
		default:
          ret = sAlias + "." + fld + opr + "{ d '" + vle + "'} ";
      }
    }
    else {
      ret = sAlias + "." + fld + opr + vle + " ";
    }
    return ret;
  } // getClause()

  // ----------------------------------------------------------

  /**
   * <p>Compose SQL WHERE clause by concatenating single clauses for each field</p>
   * <p>&lt;basefilter&gt; clause is not included in returned String.</p>
   * @return getClause("field1",...) [+ getClause("field2", ...) + [+ getClause("field3", ...)]]
   * @throws NullPointerException
   */

  public String composeSQL() throws NullPointerException {

    if (DebugFile.trace) {
      DebugFile.writeln("Begin QueryByForm.composeSQL()");
      DebugFile.incIdent();
    }

    String fld, opr, val, cod, qry = "";

    fld = getStringNull("nm_field1","");
    opr = getStringNull("nm_operator1","");
    val = getStringNull("tx_value1","");
    cod = getStringNull("vl_code1","");

   if (val.length()>0 || opr.equals("N") || opr.equals("M")) {
     qry = getClause(fld, opr, cod.length() > 0 ? cod : val);

     if (!isNull("tx_condition1")) {
       qry += " " + getString("tx_condition1") + " ";

       fld = getStringNull("nm_field2","");
       opr = getStringNull("nm_operator2","");
       val = getStringNull("tx_value2","");
       cod = getStringNull("vl_code2","");

       if (val.length()>0 || opr.equals("N") || opr.equals("M")) {
         qry += getClause(fld, opr, cod.length() > 0 ? cod : val);

         if (!isNull("tx_condition2")) {
           qry += " " + getString("tx_condition2") + " ";

           fld = getStringNull("nm_field3", "");
           opr = getStringNull("nm_operator3", "");
           val = getStringNull("tx_value3", "");
           cod = getStringNull("vl_code3", "");

           qry += getClause(fld, opr, cod.length() > 0 ? cod : val);
         } // fi (isNull("tx_condition2"))
       } // fi (val!="" || opr=="N" || opr=="M")
     } // fi (isNull("tx_condition1"))
   } // // fi (val!="" || opr=="N" || opr=="M")

   if (DebugFile.trace) {
     DebugFile.decIdent();
     DebugFile.writeln("End QueryByForm.composeSQL() : " + qry);
   }

   return qry;
  } // composeQuery()

  // ----------------------------------------------------------

  /**
   * <p>Execute query and print ResultSet to an OutputStream.</p>
   * <p>Rows are directly fetched from database and printed to OutputStream one by one.</p>
   * @param oConn Database Connection
   * @param sColumnList Columns to SELECT
   * @param sFilter Full SQL filter clause, including &lt;&gt;
   * @param oOutStrm OutputStream for printing results.
   * @param sShowAs Output Type<br>
   * <table>
   * <tr><td>TSV</td><td>Tab separated values</td><td>Columns are delimited by tabs and rows are delimited by line feeds</td></tr>
   * <tr><td>XLS</td><td>Excel Default</td><td>Columns are delimited by ';' and rows are delimited by line feeds</td></tr>
   * <tr><td>CSV</td><td>Comma separated values</td><td>Columns are delimited by ',' and rows are delimited by line feeds, text is qualified with double quoutes.</td></tr>
   * </table>
   * @throws SQLException
   */
  public void queryToStream(Connection oConn, String sColumnList, String sFilter, OutputStream oOutStrm, String sShowAs) throws SQLException {
    if (DebugFile.trace) {
      DebugFile.writeln("Begin QueryByForm.queryToStream([Connection]," + sColumnList + "," + sFilter + ", [OutputStream], " + sShowAs + ")");
      DebugFile.incIdent();
    }

    DBSubset oDBSS = new DBSubset(getBaseObject(), sColumnList, sFilter, 100);

    if (sShowAs.equalsIgnoreCase("TSV")) {
      oDBSS.setColumnDelimiter("\t");
      oDBSS.setRowDelimiter("\n");
      oDBSS.setTextQualifier("");
    }
    else if (sShowAs.equalsIgnoreCase("XLS")) {
      oDBSS.setColumnDelimiter(";");
      oDBSS.setRowDelimiter("\n");
      oDBSS.setTextQualifier("");
    }
    else {
      oDBSS.setColumnDelimiter(",");
      oDBSS.setRowDelimiter("\n");
      oDBSS.setTextQualifier("\"");
    }

    oDBSS.print(oConn, oOutStrm);

    if (DebugFile.trace) {
      DebugFile.decIdent();
      DebugFile.writeln("End QueryByForm.queryToStream()");
    }
  } // queryToStream()

  // ----------------------------------------------------------

  /**
   * <p>Delete QBF instance from database</p>
   * Dynamic Lists using this QBF will be deleted on cascade
   * @param oConn Database Connection
   * @param sQBFGUID GUID of QBF instance to be deleted.
   * @throws SQLException
   */
  public static boolean delete(JDCConnection oConn, String sQBFGUID) throws SQLException {
    if (DebugFile.trace) {
      DebugFile.writeln("Begin QueryByForm.delete([Connection]," + sQBFGUID + ")");
      DebugFile.incIdent();
    }

    DBSubset oLists = new DBSubset(DB.k_lists, DB.gu_list, DB.gu_query+"=?", 10);
    int iLists = oLists.load(oConn, new Object[]{sQBFGUID});

    for (int l=0; l<iLists; l++) {
      DistributionList.delete(oConn, oLists.getString(0,l));
    } // next

    DBPersist oDBP = new DBPersist(DB.k_queries, "QueryByForm");

    oDBP.put(DB.gu_query, sQBFGUID);

    boolean bRetVal = oDBP.delete(oConn);

    if (DebugFile.trace) {
      DebugFile.decIdent();
      DebugFile.writeln("End QueryByForm.delete() : " + String.valueOf(bRetVal));
    }

    return bRetVal;
  }

  // ----------------------------------------------------------

}

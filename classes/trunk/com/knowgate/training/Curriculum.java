/*
  Copyright (C) 2003-2011  Know Gate S.L. All rights reserved.

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
package com.knowgate.training;

import java.io.IOException;
import java.io.ByteArrayInputStream;

import java.sql.SQLException;

import org.xml.sax.ErrorHandler;
import org.w3c.dom.Document;

import javax.xml.XMLConstants;
import javax.xml.validation.Schema;
import javax.xml.validation.Validator;
import javax.xml.validation.SchemaFactory;
import javax.xml.parsers.DocumentBuilder;
import javax.xml.parsers.DocumentBuilderFactory;
import javax.xml.parsers.ParserConfigurationException;
import javax.xml.transform.dom.DOMSource;
import javax.xml.transform.stream.StreamSource;

import com.knowgate.jdc.JDCConnection;

import com.knowgate.misc.Gadgets;
import com.knowgate.debug.StackTraceUtil;
import com.knowgate.dataobjs.DB;
import com.knowgate.dataobjs.DBSubset;
import com.knowgate.dataobjs.DBCommand;
import com.knowgate.hipergate.DBLanguages;

import org.xml.sax.SAXException;
import org.xml.sax.SAXParseException;

public class Curriculum {

  public static final short ClassId = 69;

  class ValidationErrorsHandler implements ErrorHandler {
    private String sErrors;
    public ValidationErrorsHandler() {
      sErrors = "";
    }
    public void error(SAXParseException spe) {
      sErrors+= "Error "+spe.getMessage()+" at "+(spe.getLineNumber()>=0 ? " line "+String.valueOf(spe.getLineNumber()) : "")+(spe.getColumnNumber()>=0 ? " column "+String.valueOf(spe.getColumnNumber()) : "")+"\n";
    }
    public void fatalError(SAXParseException spe) {
      sErrors+= "Fatal Error "+spe.getMessage()+" at "+(spe.getLineNumber()>=0 ? " line "+String.valueOf(spe.getLineNumber()) : "")+(spe.getColumnNumber()>=0 ? " column "+String.valueOf(spe.getColumnNumber()) : "")+"\n";
    }
    public void warning(SAXParseException spe) {
      sErrors+= "Fatal Error "+spe.getMessage()+" at "+(spe.getLineNumber()>=0 ? " line "+String.valueOf(spe.getLineNumber()) : "")+(spe.getColumnNumber()>=0 ? " column "+String.valueOf(spe.getColumnNumber()) : "")+"\n";
    }
    public String getErrorInfo() {
      return sErrors;
    }
  }
  
  public ValidationErrorsHandler getHandler() {
  	return new ValidationErrorsHandler();
  }
  
  public static String validate(String sXMLInput)
  	throws IOException,SAXException,ParserConfigurationException {
	String[] aLines = Gadgets.split(sXMLInput,'\n');
    DocumentBuilder oParser = DocumentBuilderFactory.newInstance().newDocumentBuilder();
    try {
      Curriculum oCV = new Curriculum();
      ValidationErrorsHandler oMyHandler = oCV.getHandler();
      ByteArrayInputStream oInStrm = new ByteArrayInputStream(sXMLInput.getBytes("UTF-8"));    
      Document oDoc = oParser.parse(oInStrm);
      SchemaFactory oFactory = SchemaFactory.newInstance(XMLConstants.W3C_XML_SCHEMA_NS_URI);
      StreamSource oSchemaSrc = new StreamSource(oCV.getClass().getResourceAsStream("Curriculum.xsd"));
      Schema oSchema = oFactory.newSchema(oSchemaSrc);
      Validator oValid = oSchema.newValidator();
      oValid.setErrorHandler(oMyHandler);
      oValid.validate(new DOMSource(oDoc));
      return oMyHandler.getErrorInfo();
    } catch (SAXParseException spe) {
      return "SAXParseException "+spe.getMessage()+" at "+(spe.getLineNumber()>=0 ? " line "+String.valueOf(spe.getLineNumber()) : "")+(spe.getColumnNumber()>=0 ? " column "+String.valueOf(spe.getColumnNumber()) : "")+(aLines.length>=spe.getLineNumber() && spe.getLineNumber()>0 ? aLines[spe.getLineNumber()-1] : "")+"\n"+StackTraceUtil.getStackTrace(spe);
    }
  }
  
  private static String decode(JDCConnection oConn, String sXML, String sTableName, String sNodeName, String sWrkA) throws SQLException {
  	String sTxt;
  	if (sXML.indexOf("<"+sNodeName+">")<0) {
  	  return sXML;
  	} else {
  	  boolean bCData = (sXML.indexOf("<"+sNodeName+"><![CDATA[")>0);
  	  if (bCData)
  	    sTxt = Gadgets.substrBetween(sXML, "<"+sNodeName+"><![CDATA[","]]></"+sNodeName+">");
  	  else
  	    sTxt = Gadgets.substrBetween(sXML, "<"+sNodeName+">","</"+sNodeName+">");
  	  try {
  	    if (sTxt.length()==0) {
  	      return decode(oConn, Gadgets.replace(sXML,"<"+sNodeName+">"+(bCData ? "<!\\x5BCDATA\\x5B\\x5D\\x5D>" : "")+"</"+sNodeName+">","<"+sNodeName+" code=\"\">"+(bCData ? "<![CDATA[]]>" : "")+"</"+sNodeName+">"), sTableName, sNodeName, sWrkA);
  	    } else {
  	      return decode(oConn, Gadgets.replace(sXML,"<"+sNodeName+">"+(bCData ? "<!\\x5BCDATA\\x5B" : "")+Gadgets.escapeChars(sTxt,"()|[]{}*?+",'\\')+(bCData ? "\\x5D\\x5D>" : "")+"</"+sNodeName+">","<"+sNodeName+" code=\""+sTxt+"\">"+(bCData ? "<![CDATA[" : "")+DBLanguages.getLookUpTranslation(oConn, sTableName, sWrkA, sNodeName, "es", sTxt)+(bCData ? "]]>" : "")+"</"+sNodeName+">"), sTableName, sNodeName, sWrkA);
  	    }
  	  } catch (org.apache.oro.text.regex.MalformedPatternException mpe) { return "<error>"+mpe.getMessage()+"</error>"; }
  	}
  }

  private static String fkcode(JDCConnection oConn, String sXML, String sNodeName, String sTableName, String sCodeColumn, String sNameColumn, String sWrkA) throws SQLException {
  	String sTxt;
  	if (sXML.indexOf("<"+sNodeName+">")<0) {
  	  return sXML;
  	} else {
  	  boolean bCData = (sXML.indexOf("<"+sNodeName+"><![CDATA[")>0);
  	  if (bCData)
  	    sTxt = Gadgets.substrBetween(sXML, "<"+sNodeName+"><![CDATA[","]]></"+sNodeName+">");
  	  else
  	    sTxt = Gadgets.substrBetween(sXML, "<"+sNodeName+">","</"+sNodeName+">");  		
  	  try {
  	    if (sTxt.length()==0) {
  	      return fkcode(oConn, Gadgets.replace(sXML,"<"+sNodeName+">"+(bCData ? "<!\\x5BCDATA\\x5B\\x5D\\x5D>" : "")+"</"+sNodeName+">","<"+sNameColumn+" code=\"\">"+(bCData ? "<!\\x5BCDATA\\x5B\\x5D\\x5D>" : "")+"</"+sNameColumn+">"), sNodeName, sTableName, sCodeColumn, sNameColumn, sWrkA);
  	    } else {
  	      return fkcode(oConn, Gadgets.replace(sXML,"<"+sNodeName+">"+(bCData ? "<!\\x5BCDATA\\x5B" : "")+Gadgets.escapeChars(sTxt,"()|[]{}*?+",'\\')+(bCData ? "\\x5D\\x5D>" : "")+"</"+sNodeName+">","<"+sNameColumn+" code=\""+sTxt+"\">"+(bCData ? "<![CDATA[" : "")+DBCommand.queryStr(oConn, "SELECT "+sNameColumn+" FROM "+sTableName+" WHERE "+DB.gu_workarea+"='"+sWrkA+"' AND "+sCodeColumn+"='"+sTxt+"'")+(bCData ? "]]>" : "")+"</"+sNameColumn+">"), sNodeName, sTableName, sCodeColumn, sNameColumn, sWrkA);
  	    }
  	  } catch (org.apache.oro.text.regex.MalformedPatternException mpe) { return "<error>"+mpe.getMessage()+"</error>"; }
  	}
  }

  public static String forContact (JDCConnection oConn, String sGuContact) throws SQLException {
  	DBSubset oDbss;
  	String sWrkA, sXML;
  	StringBuffer oXML = new StringBuffer(8000);
  	
  	oXML.append("<curriculum gu_contact=\""+sGuContact+"\">\n");

  	oDbss = new DBSubset(DB.k_contacts, "gu_contact,gu_workarea,dt_created,dt_modified,id_ref,id_batch,id_bpartner,id_status,tx_name,tx_surname,de_title,tx_dept,tx_division,id_gender,dt_birth,ny_age,id_nationality,sn_passport,tp_passport,url_linkedin,url_facebook,url_twitter,tx_comments", DB.gu_contact+"=?", 1);
	oDbss.load(oConn, new Object[]{sGuContact});
	if (oDbss.getRowCount()==0) throw new SQLException("Contact "+sGuContact+" not found","01200",200);		
	if (!oDbss.isNull(DB.id_nationality,0)) oDbss.setElementAt(oDbss.getString(DB.id_nationality,0).trim(),DB.id_nationality,0);
  	sWrkA = oDbss.getString(1,0);
  	oXML.append(decode(oConn, oDbss.toXML("  ","contact"), DB.k_contacts_lookup, DB.de_title, sWrkA));

  	oDbss = new DBSubset(DB.k_companies, "gu_company,nm_legal,id_sector,de_company", DB.gu_company+" IN (SELECT "+DB.gu_company+" FROM "+DB.k_contacts+" WHERE "+DB.gu_contact+"=?)", 1);
	oDbss.load(oConn, new Object[]{sGuContact});
  	oXML.append(decode(oConn, oDbss.toXML("  ","company"), DB.k_companies_lookup, DB.id_sector, sWrkA));

  	oXML.append("<addresses>");
  	oDbss = new DBSubset(DB.k_addresses, "gu_address,ix_address,gu_workarea,dt_created,bo_active,dt_modified,tp_location,tp_street,nm_street,nu_street,tx_addr1,tx_addr2,id_country,nm_country,id_state,nm_state,mn_city,zipcode,work_phone,direct_phone,home_phone,mov_phone,fax_phone,other_phone,tx_email,tx_email_alt", DB.gu_address+" IN (SELECT "+DB.gu_address+" FROM "+DB.k_x_contact_addr+" WHERE "+DB.gu_contact+"=?) ORDER BY "+DB.ix_address, 4);
	oDbss.load(oConn, new Object[]{sGuContact});
	for (int a=0; a<oDbss.getRowCount(); a++)
	  if (!oDbss.isNull(DB.id_country,a)) oDbss.setElementAt(oDbss.getString(DB.id_country,a).trim(),DB.id_country,a);
  	oXML.append(decode(oConn, oDbss.toXML("  ","address"), DB.k_addresses_lookup, DB.tp_street, sWrkA));
  	oXML.append("</addresses>");

  	oXML.append("<experience>");
  	oDbss = new DBSubset(DB.k_contact_experience, "gu_experience,nm_company,bo_current_job,id_sector,de_title,tx_dt_from,tx_dt_to,contact_person,tx_comments", DB.gu_contact+"=? ORDER BY tx_dt_from", 10);
	oDbss.load(oConn, new Object[]{sGuContact});
  	oXML.append(decode(oConn, decode(oConn, oDbss.toXML("  ","position"), DB.k_companies_lookup, DB.id_sector, sWrkA), DB.k_contacts_lookup, DB.de_title, sWrkA));
  	oXML.append("</experience>");
  	
  	oXML.append("<education>");
  	oDbss = new DBSubset(DB.k_contact_education+" e,"+DB.k_education_degree+" d",
  					     "e.gu_degree,e.dt_created,e.bo_completed,e.gu_institution,e.nm_center,e.tp_degree,d.nm_degree,e.id_degree,e.lv_degree,e.ix_degree,e.tx_dt_from,e.tx_dt_to",
  						 "e."+DB.gu_degree+"=d."+DB.gu_degree+" AND "+DB.gu_contact+"=? ORDER BY 10", 10);
	oDbss.load(oConn, new Object[]{sGuContact});
	String sEdu = fkcode(oConn, oDbss.toXML("  ","degree"), "gu_institution", DB.k_education_institutions, DB.gu_institution, DB.nm_institution, sWrkA);
  	// sEdu = fkcode(oConn, sEdu, "id_degree", DB.k_education_degree, DB.id_degree, DB.nm_degree, sWrkA);
  	sEdu = decode(oConn, sEdu, DB.k_education_degree_lookup, DB.tp_degree, sWrkA);
  	oXML.append(sEdu);
  	oXML.append("</education>");

  	oXML.append("<courses>");
  	oDbss = new DBSubset(DB.k_contact_short_courses, "gu_scourse,nm_scourse,dt_created,nm_center,lv_scourse,ix_scourse,tx_dt_from,tx_dt_to,nu_credits", DB.gu_contact+"=? ORDER BY tx_dt_from", 10);
	oDbss.load(oConn, new Object[]{sGuContact});
  	oXML.append(oDbss.toXML("  ","course"));
  	oXML.append("</courses>");

  	oXML.append("<languages>");
  	oDbss = new DBSubset(DB.k_contact_languages, "id_language,lv_language_degree,lv_language_spoken,lv_language_written", DB.gu_contact+"=? ORDER BY lv_language_spoken DESC", 10);
	oDbss.load(oConn, new Object[]{sGuContact});
  	oXML.append(oDbss.toXML("  ","language"));
  	oXML.append("</languages>");
  	oXML.append("<computing>");
  	oDbss = new DBSubset(DB.k_contact_computer_science, "gu_ccsskill,nm_skill,lv_skill", DB.gu_contact+"=? ORDER BY lv_skill DESC", 10);
	oDbss.load(oConn, new Object[]{sGuContact});
  	oXML.append(decode(oConn, oDbss.toXML("  ","skill"), DB.k_contact_computer_science_lookup, DB.nm_skill, sWrkA));
  	oXML.append("</computing>");
  	oXML.append("</curriculum>");
  	
  	return oXML.toString();
  }
}

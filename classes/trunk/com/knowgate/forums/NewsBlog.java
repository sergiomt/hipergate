/*
  Copyright (C) 2009  Know Gate S.L. All rights reserved.

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

package com.knowgate.forums;

import java.text.SimpleDateFormat;
import java.util.ArrayList;
import java.util.Date;
import java.util.Properties;

import java.io.IOException;
import java.io.File;
import java.io.FileNotFoundException;
import java.io.UnsupportedEncodingException;
import java.io.FileInputStream;
import java.io.BufferedInputStream;

import java.sql.SQLException;
import java.sql.PreparedStatement;
import java.sql.ResultSet;
import java.sql.Timestamp;

import javax.xml.transform.TransformerException;

import org.jibx.runtime.IBindingFactory;
import org.jibx.runtime.IUnmarshallingContext;
import org.jibx.runtime.BindingDirectory;
import org.jibx.runtime.JiBXException;

import com.knowgate.jdc.JDCConnection;
import com.knowgate.misc.Calendar;
import com.knowgate.misc.Gadgets;
import com.knowgate.dfs.FileSystem;
import com.knowgate.debug.DebugFile;
import com.knowgate.dataobjs.DB;
import com.knowgate.dataobjs.DBSubset;
import com.knowgate.dataobjs.DBCommand;
import com.knowgate.dataxslt.StylesheetCache;
import com.knowgate.forums.Forums;
import com.knowgate.forums.NewsGroup;

public class NewsBlog extends NewsGroup {

  private String guid;
  private String blogpath;
  private String basehref;
  private String language;
  private String outputpath;
  private ArrayList<NewsBlogTemplate> templates;

  private class Month {
  	
  	public Month (int y, int m) { year = y; month = m; }

	public Date firstDay () { return new Date(year, month, 1, 0, 0, 0); }

	public Date lastDay () { return new Date(year, month, Calendar.LastDay(month, year+1900), 23, 59, 59); }

	public String toString() { return String.valueOf(year+1900)+"_"+Gadgets.leftPad(String.valueOf(month+1),'0',2); }

  	private int year;
  	private int month;  	
  }

  // ---------------------------------------------------------------------------

  public NewsBlog() {
    templates = new ArrayList<NewsBlogTemplate>(); 
  }

  // ---------------------------------------------------------------------------

  public String getGuid() {
  	return guid;
  }

  // ---------------------------------------------------------------------------

  public String getLanguage() {
  	return language;
  }

  // ---------------------------------------------------------------------------

  public String getBaseHref() {
  	return basehref;
  }

  // ---------------------------------------------------------------------------

  public String getBlogPath() {
  	return Gadgets.chomp(blogpath,File.separator);
  }

  // ---------------------------------------------------------------------------

  public String setBlogPath(String sPath) {
  	return blogpath = Gadgets.chomp(sPath,File.separator);
  }

  // ---------------------------------------------------------------------------

  public String getOutputPath() {
  	return Gadgets.chomp(outputpath, File.separator);
  }

  // ---------------------------------------------------------------------------

  public ArrayList<NewsBlogTemplate> getTemplates() {
  	return templates;
  }

  // ---------------------------------------------------------------------------

  public void rebuild(JDCConnection oConn, boolean bFullRebuild)
  	throws SQLException,IOException,TransformerException {

	String sMessageList;
	String sXMLDataSource;
	String sTagsList;
	ArrayList<Month> aMonthsWithPosts = new ArrayList<Month>();
	String sDaysWithPosts;
    SimpleDateFormat oFmt = new SimpleDateFormat("yyyy_MM_dd");
	FileSystem oFs = new FileSystem();
	File oOut;
	Date dtLastModified;
	Date dtFileModified;
	boolean bNeedsRebuild;
	String sFilePath;

    if (DebugFile.trace) {
      DebugFile.writeln("Begin NewsBlog.rebuild()");
      DebugFile.incIdent();
    }

    Properties oProps = new Properties();
	oProps.put("language", getLanguage());
	oProps.put("basehref", getBaseHref());

	DBSubset oLastModified = new DBSubset(DB.k_newsmsgs+" m,"+DB.k_x_cat_objs+" x",
										  "MAX(m."+DB.dt_modified+")",
		                                  "m."+DB.gu_msg+"=x."+DB.gu_object+" AND "+
		                                  "x."+DB.gu_category+"=? AND "+
		                                  "m."+DB.dt_published+" BETWEEN ? AND ?", 1);

	Date dtFirstPost = DBCommand.queryMinDate(oConn, "m."+DB.dt_published,
		                                      DB.k_newsmsgs+" m,"+DB.k_x_cat_objs+" x",
		                                      "m."+DB.gu_msg+"=x."+DB.gu_object+" AND "+
		                                      "x."+DB.gu_category+"='"+getGuid()+"'");
    Date dtLastPost =  DBCommand.queryMaxDate(oConn, "m."+DB.dt_published,
		                                      DB.k_newsmsgs+" m,"+DB.k_x_cat_objs+" x",
		                                      "m."+DB.gu_msg+"=x."+DB.gu_object+" AND "+
		                                      "x."+DB.gu_category+"='"+getGuid()+"'");

    ArrayList<Boolean> aDaysWithPosts = Forums.getDaysWithPosts(oConn, getGuid(), dtFirstPost, dtLastPost);

	Date dtFirstDayOfMonth = new Date(dtFirstPost.getYear(), dtFirstPost.getMonth(), 1, 0, 0, 0);
	Date dtLastDayOfMonth = new Date(dtFirstPost.getYear(), dtFirstPost.getMonth(), Calendar.LastDay(dtFirstPost.getMonth(), dtFirstPost.getYear()+1900), 23, 59, 59);

	PreparedStatement oStmt = oConn.prepareStatement("SELECT NULL FROM "+
													 DB.k_newsmsgs+" m,"+DB.k_x_cat_objs+" x WHERE "+
		                                             "m."+DB.gu_msg+"=x."+DB.gu_object+" AND "+
		                                             "x."+DB.gu_category+"=? AND "+
		                                             "m."+DB.dt_published+" BETWEEN ? AND ?");	

	while (dtLastPost.compareTo(dtLastDayOfMonth)<=0) {
	  oStmt.setString   (1, getGuid());
	  oStmt.setTimestamp(2, new Timestamp(dtFirstDayOfMonth.getTime()));
	  oStmt.setTimestamp(3, new Timestamp(dtLastDayOfMonth.getTime()));
	  ResultSet oRSet = oStmt.executeQuery();
	  boolean bMonthHasPosts = oRSet.next();
	  oRSet.close();
	  if (bMonthHasPosts) {
		aMonthsWithPosts.add(new Month(dtFirstDayOfMonth.getYear(),dtFirstDayOfMonth.getMonth()));
	  } // fi
	  dtFirstDayOfMonth = Calendar.addMonths(1, dtFirstDayOfMonth);
	  dtLastDayOfMonth = new Date(dtFirstDayOfMonth.getYear(), dtFirstDayOfMonth.getMonth(), Calendar.LastDay(dtFirstDayOfMonth.getMonth(), dtFirstDayOfMonth.getYear()+1900), 23, 59, 59);
	} // wend
	oStmt.close();
	
	for (NewsBlogTemplate t : templates) {

	  if (t.getFilter().equalsIgnoreCase("main")) {

        dtLastModified =  DBCommand.queryMaxDate(oConn, "m."+DB.dt_modified,
		                                         DB.k_newsmsgs+" m,"+DB.k_x_cat_objs+" x",
		                                         "m."+DB.gu_msg+"=x."+DB.gu_object+" AND "+
		                                         "x."+DB.gu_category+"='"+getGuid()+"'");
		if (null==dtLastModified) dtLastModified = new Date();
	    sFilePath = getOutputPath()+"main.html";
	    oOut = new File(sFilePath);
	    if (oOut.exists()) {
	      dtFileModified = new Date(oOut.lastModified());
	      oOut.delete();
	      bNeedsRebuild = (dtLastModified.compareTo(dtFileModified)<0) || (new File(getBlogPath()+t.getInputFilePath()).lastModified()>dtFileModified.getTime());
	    } else {
	      bNeedsRebuild = true;
	    }
	    
		if (bNeedsRebuild || bFullRebuild) {
	  	  sMessageList = Forums.XMLListTopLevelMessagesForGroup(oConn, t.getLimit(), 0, getGuid(), DB.dt_published);
	  	  sXMLDataSource = sMessageList;
	      oFs.writefilestr(sFilePath,
	                       StylesheetCache.transform(getBlogPath()+t.getInputFilePath(), sXMLDataSource, oProps), "UTF-8");
		} // fi (bNeedsRebuild)
			    
	  } else if (t.getFilter().equalsIgnoreCase("monthly")) {

		  for (Month m : aMonthsWithPosts) {

		    if (oLastModified.load(oConn, new Object[]{getGuid(), m.firstDay(), m.lastDay()})>0) {
		      dtLastModified = oLastModified.getDate(0,0);
		    } else {
		      dtLastModified = new Date();
		    }

	        sFilePath = getOutputPath()+"archives"+File.separator+m.toString()+".html";
	        oOut = new File(sFilePath);
	        if (oOut.exists()) {
	          dtFileModified = new Date(oOut.lastModified());
	          oOut.delete();
	          bNeedsRebuild = (dtLastModified.compareTo(dtFileModified)>0);
	        } else {
	          bNeedsRebuild = true;
	        }
			
		    if (bNeedsRebuild || bFullRebuild) {
			  sMessageList = Forums.XMLListTopLevelMessagesForGroup(oConn, m.firstDay(), m.lastDay(), getGuid(), DB.dt_published);
	  	      sXMLDataSource = sMessageList;
	          oFs.writefilestr(sFilePath,
	                           StylesheetCache.transform(getBlogPath()+t.getInputFilePath(), sXMLDataSource, oProps), "UTF-8");
		    } // fi
		    
		  } // next		  
	    } else if (t.getFilter().equalsIgnoreCase("daily")) {
	    	
	      Date dtDay00 = dtFirstPost;
	      Date dtDay23 = new Date(dtFirstPost.getYear(), dtFirstPost.getMonth(), dtFirstPost.getDate(), 23, 59, 59);

		  for (Boolean b : aDaysWithPosts) {

		    if (oLastModified.load(oConn, new Object[]{getGuid(), dtDay00, dtDay23})>0) {
		      dtLastModified = oLastModified.getDate(0,0);
		    } else {
		      dtLastModified = new Date();
		    }

	  	    sFilePath = getOutputPath()+"archives"+File.separator+oFmt.format(dtDay00)+".html";
	        oOut = new File(sFilePath);
	        if (oOut.exists()) {
	          dtFileModified = new Date(oOut.lastModified());
	          oOut.delete();
	          bNeedsRebuild = (dtLastModified.compareTo(dtFileModified)>0);
	        } else {
	          bNeedsRebuild = true;
	        }

		    if (bNeedsRebuild || bFullRebuild) {
			  sMessageList = Forums.XMLListTopLevelMessagesForGroup(oConn, dtDay00, dtDay23, getGuid(), DB.dt_published);
	  	      sXMLDataSource = sMessageList;
	          oFs.writefilestr(sFilePath,
	                           StylesheetCache.transform(getBlogPath()+t.getInputFilePath(), sXMLDataSource, oProps), "UTF-8");
		    } // fi

		  } // next
		  
	    } else if (t.getFilter().equalsIgnoreCase("single")) {

	      DBSubset  oPostsModified = new DBSubset (
	      	  DB.k_newsmsgs + " m," + DB.k_x_cat_objs + " x," + DB.k_newsgroups + " g," + DB.k_categories + " c",
    	      "m." + DB.dt_modified + ",m."+DB.gu_msg+",m."+DB.tx_subject,
    	      "m." + DB.id_status + "="+String.valueOf(NewsMessage.STATUS_VALIDATED)+" AND x." + DB.gu_category + "=" + "g." + DB.gu_newsgrp + " AND " +
    	      "c." + DB.gu_category + "=g." + DB.gu_newsgrp + " AND " +
    	      "m." + DB.gu_msg + "=x." + DB.gu_object + " AND g." + DB.gu_newsgrp + "=?", 10000);
		  int nPosts = oPostsModified.load(oConn, new Object[]{getGuid()});

		  for (int p=0; p<nPosts; p++) {
		    dtLastModified = oPostsModified.getDate(0,0);
		    
	  	    sFilePath = getOutputPath()+"archives"+File.separator+Gadgets.ASCIIEncode(oPostsModified.getStringNull(2, p, "")).toLowerCase()+".html";
	        oOut = new File(sFilePath);
	        if (oOut.exists()) {
	          dtFileModified = new Date(oOut.lastModified());
	          oOut.delete();
	          bNeedsRebuild = (dtLastModified.compareTo(dtFileModified)>0);
	        } else {
	          bNeedsRebuild = true;
	        }

		    if (bNeedsRebuild || bFullRebuild) {

			  sMessageList = Forums.XMLListMessagesForThread(oConn, oPostsModified.getString(1,0));
	  	      sXMLDataSource = sMessageList;
	          oFs.writefilestr(sFilePath,
	                           StylesheetCache.transform(getBlogPath()+t.getInputFilePath(), sXMLDataSource, oProps), "UTF-8");
		    } // fi
		    
		  } //next
	    } // fi
	  } // next (template)
	
    if (DebugFile.trace) {
      DebugFile.decIdent();
      DebugFile.writeln("End NewsBlog.rebuild()");
    }

  } // rebuild

  // ---------------------------------------------------------------------------

  /**
   * Create a NewsBlog object by parsing its definition from an XML file
   * @param oConn JDBC Database Connection
   * @param sXMLBlogPath String Directory path to blog definition files
   * @param sXMLFileName String Name of XML file containing the blog definition
   * @param sEnc String Character encoding, if <b>null</b> then UTF-8 is assumed.
   * @return Menu object
   * @throws JiBXException
   * @throws FileNotFoundException
   * @throws UnsupportedEncodingException
   * @throws IOException
   */
  public static NewsBlog parse(JDCConnection oConn, String sXMLBlogPath, String sXMLFileName, String sEnc)
    throws JiBXException, FileNotFoundException, UnsupportedEncodingException,
           IOException, SQLException {

    if (DebugFile.trace) {
      DebugFile.writeln("Begin NewsBlog.parse("+sXMLBlogPath+","+sXMLFileName+","+sEnc+")");
      DebugFile.incIdent();
    }

    if (sEnc==null) sEnc="UTF-8";
	
    IBindingFactory bfact = BindingDirectory.getFactory(NewsBlog.class);
    IUnmarshallingContext uctx = bfact.createUnmarshallingContext();

    final int BUFFER_SIZE = 8000;
    FileInputStream oFileStream = new FileInputStream(Gadgets.chomp(sXMLBlogPath,File.separator)+sXMLFileName);
    BufferedInputStream oXMLStream = new BufferedInputStream(oFileStream, BUFFER_SIZE);

    NewsBlog oBlog = (NewsBlog) uctx.unmarshalDocument (oXMLStream, sEnc);

    oXMLStream.close();
    oFileStream.close();

	oBlog.setBlogPath(sXMLBlogPath);
	oBlog.load(oConn, new Object[]{oBlog.getGuid()});

    if (DebugFile.trace) {
      DebugFile.decIdent();
      DebugFile.writeln("End NewsBlog.parse()");
    }

    return oBlog;
  } // parse

}



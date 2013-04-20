/*
  Copyright (C) 2009  Know Gate S.L. All rights reserved.
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

package com.knowgate.forums;

import java.text.SimpleDateFormat;
import java.util.ArrayList;
import java.util.Map;
import java.util.HashMap;
import java.util.Date;
import java.util.Properties;
import java.util.Calendar;
import java.util.GregorianCalendar;

import java.io.IOException;
import java.io.File;
import java.io.FileNotFoundException;


import java.sql.SQLException;
import java.sql.Timestamp;

import javax.xml.transform.TransformerException;

import com.knowgate.jdc.JDCConnection;
import com.knowgate.misc.Gadgets;
import com.knowgate.misc.Month;
import com.knowgate.dfs.FileSystem;
import com.knowgate.debug.DebugFile;
import com.knowgate.dataobjs.DB;
import com.knowgate.dataobjs.DBBind;
import com.knowgate.dataobjs.DBSubset;
import com.knowgate.dataobjs.DBCommand;
import com.knowgate.dataxslt.StylesheetCache;
import com.knowgate.forums.Forums;
import com.knowgate.forums.NewsGroup;

/**
 * <p>NewsGroupJournal</p>
 * <p>This class must be pre-processed with JiBX and journal-def-jixb.xml</p>
 * @author Sergio Montoro Ten
 * @version 7.0
 */
public class NewsGroupJournal {

  private String guid;
  private String blogpath;
  private String basehref;
  private String language;
  private String encoding;
  private String outputpath;
  private ArrayList<NewsGroupJournalPage> templates;

  // ---------------------------------------------------------------------------

  public NewsGroupJournal() {
    templates = new ArrayList<NewsGroupJournalPage>(); 
  }

  // ---------------------------------------------------------------------------

  public String getGuid() {
  	return guid;
  }

  // ---------------------------------------------------------------------------

  public String getEncoding() {
  	return encoding==null ? "UTF-8" : encoding;
  }

  // ---------------------------------------------------------------------------

  public String getLanguage() {
  	return language==null ? "es" : language;
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

  public ArrayList<NewsGroupJournalPage> getTemplates() {
  	return templates;
  }

  private String mergeXML(String sXMLHost, String sXMLJournal) {
    final String sXmlProlog = "<?xml version=\"1.0\" encoding=\""+getEncoding()+"\"?>\n";
    String sMergedXML;
    if (sXMLHost==null) {
      sMergedXML = sXmlProlog + sXMLJournal;
    } else {
      final int iJournal = sXMLHost.indexOf("&journal;");
      if (iJournal>0)
    	sMergedXML = sXMLHost.substring(0,iJournal) + sXMLJournal + sXMLHost.substring(iJournal+9);
      else
    	sMergedXML = sXMLHost;
    }
    return sMergedXML;
  }

  // ---------------------------------------------------------------------------

  /**
   * @since 7.0
   */
  
  public void rebuild(DBBind oDbb, Map<String,String> oXMLHosts, boolean bFullRebuild)
    throws NullPointerException,SQLException,FileNotFoundException,IOException,TransformerException {

	// String sMessageList;
	String sXmlTopLevelMessagesForGroup;
	String sXmlTopLevelMessagesForGroupRss2;
	String sXmlTopLevelMessagesBetweenDates;
	String sXmlTopLevelMessagesForThread;
	String sXmlTopLevelMessagesForTag;
	String sXMLDataSource;
    SimpleDateFormat oFmt = new SimpleDateFormat("yyyy_MM_dd");	
	File oOut;
	File oBase;
	Date dtFileModified;
	boolean bNeedsRebuild;
	String sBasePath;
	String sFilePath;
	JDCConnection oCon;

    if (DebugFile.trace) {
      DebugFile.writeln("Begin NewsGroupJournal.rebuild([JDCConnection], "+String.valueOf(bFullRebuild)+")");
      DebugFile.incIdent();
    }

	if (getGuid()==null) {
      if (DebugFile.trace) {
      	DebugFile.writeln("NewsGroupJournal.rebuild() GUID for NewsGroup is null");
        DebugFile.decIdent();
      }	
      throw new NullPointerException("NewsGroupJournal.rebuild() No NewsGroup with GUID "+getGuid()+" found at "+DB.k_newsgroups+" table");
	}

	Properties oProps = new Properties();
	oProps.put("language", getLanguage());
	oProps.put("basehref", getBaseHref());
	
	NewsGroup oNewsGrp = new NewsGroup();
	oCon = oDbb.getConnection("NewsGroupJournal.rebuild.1", true);
	boolean bExistsGroup = oNewsGrp.load(oCon, getGuid());
	oCon.close("NewsGroupJournal.rebuild.1");
	oCon = null;
	
	if (!bExistsGroup) {
      if (DebugFile.trace) {
      	DebugFile.writeln("NewsGroupJournal.rebuild() No NewsGroup with GUID "+getGuid()+" found at "+DB.k_newsgroups+" table");
        DebugFile.decIdent();
      }	
      throw new SQLException("NewsGroupJournal.rebuild() No NewsGroup with GUID "+getGuid()+" found at "+DB.k_newsgroups+" table");
	} // fi

	oCon = oDbb.getConnection("NewsGroupJournal.rebuild.2", true);
	
	String sNewsGrpXml = oNewsGrp.toXML(oCon);
	String sMonthsWithPosts = Forums.XMLListMonthsWithPosts(oCon, getGuid(), getLanguage());

	FileSystem oFs = new FileSystem();
	try { oFs.mkdirs("file://"+getOutputPath()+"archives"); } catch (Exception ignore) { }

    ArrayList<Boolean> aDaysWithPosts = Forums.getDaysWithPosts(oCon, getGuid(), null, null);

	DBSubset oLastModified = new DBSubset(DB.k_newsmsgs+" m,"+DB.k_x_cat_objs+" x",
										  "MAX(m."+DB.dt_modified+")",
		                                  "m."+DB.gu_msg+"=x."+DB.gu_object+" AND "+
		                                  "x."+DB.gu_category+"=? AND "+
		                                  "m."+DB.dt_published+" BETWEEN ? AND ?", 1);   
    // ***********************************
    // Perform all database accesses first

	Date dtMostRecentModification = DBCommand.queryMaxDate(oCon, "m."+DB.dt_modified, DB.k_newsmsgs+" m,"+DB.k_x_cat_objs+" x", "m."+DB.gu_msg+"=x."+DB.gu_object+" AND "+ "x."+DB.gu_category+"='"+getGuid()+"'"); 
    if (null==dtMostRecentModification) dtMostRecentModification = new Date();

    Date dtMostRecentOfTopLevel = DBCommand.queryMaxDate(oCon, "m."+DB.dt_modified, DB.k_newsmsgs+" m,"+DB.k_x_cat_objs+" x","m."+DB.gu_msg+"=x."+DB.gu_object+" AND "+"x."+DB.gu_category+"='"+getGuid()+"' AND "+ "m."+DB.gu_parent_msg+" IS NULL");
    if (null==dtMostRecentOfTopLevel) dtMostRecentOfTopLevel = new Date();

	oCon.close("NewsGroupJournal.rebuild.2");
	oCon = null;
    
    // **************************
    // Now do the XSLT processing
	
    for (NewsGroupJournalPage t : templates) {

      if (DebugFile.trace) {
        DebugFile.writeln("Processing "+t.getFilter()+" template");
      }

	  if (t.getFilter().equalsIgnoreCase("main")) {

        if (DebugFile.trace) {
          DebugFile.writeln("Most recent modified message date is "+dtMostRecentModification.toString());
        }

	    sFilePath = getOutputPath()+"main.html";

	    oOut = new File(sFilePath);
	    if (oOut.exists()) {
	      dtFileModified = new Date(oOut.lastModified());
          if (DebugFile.trace) {
            DebugFile.writeln("Output file path is "+sFilePath+" last modified at "+dtFileModified.toString());
          }
	      bNeedsRebuild = (dtMostRecentModification.compareTo(dtFileModified)>0) || (new File(getBlogPath()+t.getInputFilePath()).lastModified()>dtFileModified.getTime());
	      if (bNeedsRebuild || bFullRebuild) oOut.delete();
	    } else {
          if (DebugFile.trace) {
            DebugFile.writeln("Output file "+sFilePath+" does not exist");
          }
	      bNeedsRebuild = true;
	    }
	    
		if (bNeedsRebuild || bFullRebuild) {
		  oCon = oDbb.getConnection("NewsGroupJournal.rebuild.main", true);
	      sXmlTopLevelMessagesForGroup = Forums.XMLListTopLevelMessagesForGroup(oCon, t.getLimit(), 0, getGuid(), DB.dt_published);
	  	  oCon.close("NewsGroupJournal.rebuild.main");
	  	  oCon = null;
	      sXMLDataSource = mergeXML (oXMLHosts.get(t.getFilter()), "<Journal guid=\""+getGuid()+"\">\n" + sNewsGrpXml + "\n" + sMonthsWithPosts + "\n" + sXmlTopLevelMessagesForGroup + "</Journal>");
	  	  sXmlTopLevelMessagesForGroup = null;

		  if (DebugFile.trace) {
		  	oFs.delete(getOutputPath()+"main.xml");
		  	oFs.writefilestr(getOutputPath()+"main.xml", sXMLDataSource, getEncoding());
		  }

	      oFs.writefilestr(sFilePath, StylesheetCache.transform(getBlogPath()+t.getInputFilePath(), sXMLDataSource, oProps), getEncoding());
		} // fi (bNeedsRebuild)

      } else if (t.getFilter().equalsIgnoreCase("rss2")) {

        if (DebugFile.trace) {
          DebugFile.writeln("Last modified message date is "+dtMostRecentOfTopLevel.toString());
        }

	    sFilePath = getOutputPath()+"rss2.xml";

	    oOut = new File(sFilePath);
	    if (oOut.exists()) {
	      dtFileModified = new Date(oOut.lastModified());
          if (DebugFile.trace) {
            DebugFile.writeln("Output file path is "+sFilePath+" last modified at "+dtFileModified.toString());
          }
	      bNeedsRebuild = (dtMostRecentOfTopLevel.compareTo(dtFileModified)>0) || (new File(getBlogPath()+t.getInputFilePath()).lastModified()>dtFileModified.getTime());
	      if (bNeedsRebuild || bFullRebuild) oOut.delete();
	    } else {
          if (DebugFile.trace) {
            DebugFile.writeln("Output file "+sFilePath+" does not exist");
          }
	      bNeedsRebuild = true;
	    }
	    
		if (bNeedsRebuild || bFullRebuild) {
			
	      oCon = oDbb.getConnection("NewsGroupJournal.rebuild.rss2", true);
	      sXmlTopLevelMessagesForGroupRss2 = Forums.XMLListTopLevelMessagesForGroup(oCon, t.getLimit(), 0, getGuid(), DB.dt_published, "yyyy-MM-dd'T'hh:mm:ss"); 
	  	  oCon.close("NewsGroupJournal.rebuild.rss2");
	  	  oCon = null;

	      try {
	  		sXmlTopLevelMessagesForGroupRss2 = Gadgets.replace(sXmlTopLevelMessagesForGroupRss2,"<((IMG)|img) +((SRC)|(src))=\"/", "<img src=\""+getBaseHref()+"/");
	  	  } catch (org.apache.oro.text.regex.MalformedPatternException neverthrown) { }
	  	  sXMLDataSource = mergeXML(oXMLHosts.get(t.getFilter()), "<Journal guid=\""+getGuid()+"\">\n" + sNewsGrpXml + "\n" + sXmlTopLevelMessagesForGroupRss2 + "</Journal>");
	  	  sXmlTopLevelMessagesForGroupRss2 = null;
	  	
	      oFs.writefilestr(sFilePath,
	                       StylesheetCache.transform(getBlogPath()+t.getInputFilePath(), sXMLDataSource, oProps), getEncoding());
		  if (DebugFile.trace) {
	        oFs.writefilestr(sFilePath+".source.xml", sXMLDataSource, getEncoding());
		  }
		} // fi (bNeedsRebuild)

	  } else if (t.getFilter().equalsIgnoreCase("monthly")) {

	      oCon = oDbb.getConnection("NewsGroupJournal.rebuild.monthly", true);
		  ArrayList<Month> aMonthsWithPosts = Forums.getMonthsWithPosts(oCon, getGuid());
	  	  oCon.close("NewsGroupJournal.rebuild.monthly");
	  	  oCon = null;

		  sBasePath = getOutputPath()+"archives"+File.separator+t.getFilter();
		  oBase = new File (sBasePath);
		  if (!oBase.exists()) oBase.mkdir();
		  
		  for (Month m : aMonthsWithPosts) {

			oProps.put("year", String.valueOf(m.getYear()));
			oProps.put("month", String.valueOf(m.getMonth()));

			Date dtLastOfMonth;
			
		    oCon = oDbb.getConnection("NewsGroupJournal.rebuild.monthly", true);
		    if (oLastModified.load(oCon, new Object[]{getGuid(), new Timestamp(m.firstDay().getTime()), new Timestamp(m.lastDay().getTime())})>0) {
		      if (oLastModified.isNull(0,0))
		    	dtLastOfMonth = new Date();
		      else
		    	dtLastOfMonth = oLastModified.getDate(0,0);
		    } else {
		      dtLastOfMonth = new Date();
		    }
		  	oCon.close("NewsGroupJournal.rebuild.monthly");
		  	oCon = null;
			
            if (DebugFile.trace) {
              DebugFile.writeln("Last modified message date of month "+String.valueOf(m.getMonth()+1)+" "+String.valueOf(m.getYear()+1900)+" is "+dtLastOfMonth.toString());
            }

	        sFilePath = sBasePath+File.separator+m.toString()+".html";
	        oOut = new File(sFilePath);
	        if (oOut.exists()) {
	          dtFileModified = new Date(oOut.lastModified());
              if (DebugFile.trace) {
                DebugFile.writeln("Output file path is "+sFilePath+" last modified at "+dtFileModified.toString());
              }
	          bNeedsRebuild = (dtLastOfMonth.compareTo(dtFileModified)>0);
	          if (bNeedsRebuild || bFullRebuild) oOut.delete();
	        } else {
              if (DebugFile.trace) {
                DebugFile.writeln("Output file "+sFilePath+" does not exist");
              }
	          bNeedsRebuild = true;
	        }
			
		    if (bNeedsRebuild || bFullRebuild) {
			  oCon = oDbb.getConnection("NewsGroupJournal.rebuild.monthly", true);
			  sXmlTopLevelMessagesBetweenDates = Forums.XMLListTopLevelMessagesForGroup(oCon, m.firstDay(), m.lastDay(), getGuid(), DB.dt_published);
			  oCon.close("NewsGroupJournal.rebuild.monthly");
			  oCon = null;
			  sXMLDataSource = mergeXML(oXMLHosts.get(t.getFilter()), "<Journal guid=\""+getGuid()+"\">\n" + sNewsGrpXml + "\n" + sMonthsWithPosts + "\n" + sXmlTopLevelMessagesBetweenDates + "</Journal>");
			  sXmlTopLevelMessagesBetweenDates = null;
			  
		  	  if (DebugFile.trace) {
		  	    oFs.delete(Gadgets.dechomp(sFilePath,"html")+"xml");
		  	    oFs.writefilestr(Gadgets.dechomp(sFilePath,"html")+"xml", sXMLDataSource, getEncoding());
		      }

	          oFs.writefilestr(sFilePath, StylesheetCache.transform(getBlogPath()+t.getInputFilePath(), sXMLDataSource, oProps), getEncoding());
		    } // fi
		    
		  } // next		  

	  } else if (t.getFilter().equalsIgnoreCase("daily")) {

		  sBasePath = getOutputPath()+"archives"+File.separator+t.getFilter();
		  oBase = new File (sBasePath);
		  if (!oBase.exists()) oBase.mkdir();

		  oCon = oDbb.getConnection("NewsGroupJournal.rebuild.daily", true);
	      Date dt1stPost = DBCommand.queryMinDate(oCon, "m."+DB.dt_published,
		                                          DB.k_newsmsgs+" m,"+DB.k_x_cat_objs+" x",
		                                          "m."+DB.gu_msg+"=x."+DB.gu_object+" AND "+
		                                          "x."+DB.gu_category+"='"+getGuid()+"' AND "+
		                                          "m."+DB.id_status+"="+String.valueOf(NewsMessage.STATUS_VALIDATED));
		  oCon.close("NewsGroupJournal.rebuild.daily");
		  oCon = null;

		  if (dt1stPost!=null) {

	        Date dtDay00 = new Date(dt1stPost.getYear(), dt1stPost.getMonth(), dt1stPost.getDate(),  0,  0,  0);
	        Date dtDay23 = new Date(dt1stPost.getYear(), dt1stPost.getMonth(), dt1stPost.getDate(), 23, 59, 59);

		    for (Boolean b : aDaysWithPosts) {
		  	
		  	  if (b.booleanValue()) {

	            if (DebugFile.trace)
	              DebugFile.writeln("Processing date "+dtDay00.toString());
		  		
			    oProps.put("year", String.valueOf(dtDay00.getYear()));
			    oProps.put("month", String.valueOf(dtDay00.getMonth()));

			    Date dtLastOfDay;

				oCon = oDbb.getConnection("NewsGroupJournal.rebuild.daily", true);
		        if (oLastModified.load(oCon, new Object[]{getGuid(), new Timestamp(dtDay00.getTime()), new Timestamp(dtDay23.getTime())})>0) {
		          if (oLastModified.isNull(0,0))
		        	dtLastOfDay = new Date();
		          else
		        	dtLastOfDay = oLastModified.getDate(0,0);
		        } else {
		          dtLastOfDay = new Date();
		        }
				oCon.close("NewsGroupJournal.rebuild.daily");
				oCon = null;

                if (DebugFile.trace) {
                  DebugFile.writeln("Last modified message date for day is "+dtLastOfDay.toString());
                }

	  	        sFilePath = sBasePath+File.separator+oFmt.format(dtDay00)+".html";
	            oOut = new File(sFilePath);
	            if (oOut.exists()) {
	              dtFileModified = new Date(oOut.lastModified());
                  if (DebugFile.trace) {
                    DebugFile.writeln("Output file path is "+sFilePath+" last modified at "+dtFileModified.toString());
                  }
	              bNeedsRebuild = (dtLastOfDay.compareTo(dtFileModified)>0);
	              if (bNeedsRebuild || bFullRebuild) oOut.delete();
	            } else {
                  if (DebugFile.trace)
                    DebugFile.writeln("Output file "+sFilePath+" does not exist");
	              bNeedsRebuild = true;
	            }

		        if (bNeedsRebuild || bFullRebuild) {
				  oCon = oDbb.getConnection("NewsGroupJournal.rebuild.daily", true);
		          sXmlTopLevelMessagesBetweenDates = Forums.XMLListTopLevelMessagesForGroup(oCon, dtDay00, dtDay23, getGuid(), DB.dt_published);
		          oCon.close("NewsGroupJournal.rebuild.daily");
				  oCon = null;
			      sXMLDataSource = mergeXML(oXMLHosts.get(t.getFilter()), "<Journal guid=\""+getGuid()+"\">\n" + sNewsGrpXml + "\n" + sMonthsWithPosts + "\n" + sXmlTopLevelMessagesBetweenDates + "</Journal>");
			      sXmlTopLevelMessagesBetweenDates = null;
			      oFs.writefilestr(sFilePath, StylesheetCache.transform(getBlogPath()+t.getInputFilePath(), sXMLDataSource, oProps), getEncoding());
		        } // fi

		      } // fi (DaysWithPosts)
		  	  GregorianCalendar oCal = new GregorianCalendar();
		  	  oCal.setTime(dtDay00);
		  	  oCal.add(Calendar.DATE, 1);
			  dtDay00 = oCal.getTime();
		  	  oCal.setTime(dtDay23);
		  	  oCal.add(Calendar.DATE, 1);
			  dtDay23 = oCal.getTime();
		    } // next
		  } else {
            if (DebugFile.trace)
              DebugFile.writeln("No date for first post found rebuilding daily template");
		  } // fi

	    } else if (t.getFilter().equalsIgnoreCase("single")) {

		  sBasePath = getOutputPath()+"archives"+File.separator+t.getFilter();
		  oBase = new File (sBasePath);
		  if (!oBase.exists()) oBase.mkdir();
	    	
	      DBSubset oPostsModified = new DBSubset (
	      	  DB.k_newsmsgs + " m," + DB.k_x_cat_objs + " x," + DB.k_newsgroups + " g," + DB.k_categories + " c",
    	      "MAX(m." + DB.dt_modified + "),m."+DB.gu_thread_msg,
    	      "m." + DB.id_status + "="+String.valueOf(NewsMessage.STATUS_VALIDATED)+" AND x." + DB.gu_category + "=" + "g." + DB.gu_newsgrp + " AND " +
    	      "c." + DB.gu_category + "=g." + DB.gu_newsgrp + " AND " +
    	      "m." + DB.gu_msg + "=x." + DB.gu_object + " AND g." + DB.gu_newsgrp + "=? GROUP BY m."+DB.gu_thread_msg, 10000);

		  oCon = oDbb.getConnection("NewsGroupJournal.rebuild.single", true);
	      int nPosts = oPostsModified.load(oCon, new Object[]{getGuid()});
		  oCon.close("NewsGroupJournal.rebuild.single");
		  oCon = null;

		  for (int p=0; p<nPosts; p++) {
		    Date dtLastModified = oPostsModified.getDate(0,0);
		    if (null==dtLastModified) dtLastModified = new Date();

            if (DebugFile.trace) {
              DebugFile.writeln("Last modified message date is "+dtLastModified.toString());
            }
		    
	  	    sFilePath = sBasePath+File.separator+oPostsModified.getString(1,p)+".html";
	        oOut = new File(sFilePath);
	        if (oOut.exists()) {
	          dtFileModified = new Date(oOut.lastModified());
              if (DebugFile.trace) {
                DebugFile.writeln("Output file path is "+sFilePath+" last modified at "+dtFileModified.toString());
              }
	          bNeedsRebuild = (dtLastModified.compareTo(dtFileModified)>0);
	          if (bNeedsRebuild || bFullRebuild) oOut.delete();
	        } else {
              if (DebugFile.trace) {
                DebugFile.writeln("Output file "+sFilePath+" does not exist");
              }
	          bNeedsRebuild = true;
	        }

		    if (bNeedsRebuild || bFullRebuild) {

			  oCon = oDbb.getConnection("NewsGroupJournal.rebuild.single", true);
		      sXmlTopLevelMessagesForThread = Forums.XMLListMessagesForThread(oCon, oPostsModified.getString(1,p));
			  oCon.close("NewsGroupJournal.rebuild.single");
			  oCon = null;
	  	      sXMLDataSource = mergeXML(oXMLHosts.get(t.getFilter()), "<Journal guid=\""+getGuid()+"\">\n" + sNewsGrpXml + "\n" + sMonthsWithPosts + "\n" + sXmlTopLevelMessagesForThread + "</Journal>");
	  	      sXmlTopLevelMessagesForThread = null;
	          oFs.writefilestr(sFilePath,StylesheetCache.transform(getBlogPath()+t.getInputFilePath(), sXMLDataSource, oProps), getEncoding());
		  	  // if (DebugFile.trace)
		  	    // oFs.writefilestr(Gadgets.dechomp(sFilePath,"html")+"xml", sXMLDataSource, getEncoding());
		    } // fi
		    
		  } //next

	    } else if (t.getFilter().equalsIgnoreCase("bytag")) {

		  sBasePath = getOutputPath()+"archives"+File.separator+t.getFilter();
		  oBase = new File (sBasePath);
		  if (!oBase.exists()) oBase.mkdir();
	    	
		  oCon = oDbb.getConnection("NewsGroupJournal.rebuild.bytag", true);
          DBSubset oTags = Forums.getNewsGroupTags(oCon, getGuid());
		  oCon.close("NewsGroupJournal.rebuild.bytag");
		  oCon = null;
          int nTags = oTags.getRowCount();

          for (int g=0; g<nTags; g++) {
          	
            if (DebugFile.trace) {
                DebugFile.writeln("Rebuilding archive for tag "+oTags.getString(3,g));
            }

	        oProps.put("tag", oTags.getString(4,g));

	  	    sFilePath = sBasePath+File.separator+oTags.getString(4,g)+".html";
	        oOut = new File(sFilePath);
	        if (oOut.exists()) {
	          dtFileModified = new Date(oOut.lastModified());
              if (DebugFile.trace) {
                DebugFile.writeln("Output file path is "+sFilePath+" last modified at "+dtFileModified.toString());
              }
	          oOut.delete();
	        } else {
              if (DebugFile.trace) {
                DebugFile.writeln("Output file "+sFilePath+" does not exist");
              }
	        }

			oCon = oDbb.getConnection("NewsGroupJournal.rebuild.bytag", true);
	        sXmlTopLevelMessagesForTag = Forums.XMLListTopLevelMessagesForTag(oCon, 32767, 0, getGuid(), oTags.getString(0,g), DB.dt_published);
			oCon.close("NewsGroupJournal.rebuild.bytag");
			oCon = null;
	  	    sXMLDataSource = mergeXML(oXMLHosts.get(t.getFilter()), "<Journal guid=\""+getGuid()+"\">\n" + sNewsGrpXml + "\n" + sMonthsWithPosts + "\n" + sXmlTopLevelMessagesForTag + "</Journal>");
	  	    sXmlTopLevelMessagesForTag = null;
	        oFs.writefilestr(sFilePath, StylesheetCache.transform(getBlogPath()+t.getInputFilePath(), sXMLDataSource, oProps), getEncoding());

		  	if (DebugFile.trace) {
		  	  oFs.delete(Gadgets.dechomp(sFilePath,"html")+"xml");
		  	  oFs.writefilestr(Gadgets.dechomp(sFilePath,"html")+"xml", sXMLDataSource, getEncoding());
		    }
		  } //next	    
 	    } // fi	    

	  } // next (template)
	
    if (DebugFile.trace) {
      DebugFile.decIdent();
      DebugFile.writeln("End NewsGroupJournal.rebuild()");
    }
  } // rebuild

  // ---------------------------------------------------------------------------
  
  public void rebuild(DBBind oDbb, boolean bFullRebuild)
    throws NullPointerException,SQLException,FileNotFoundException,IOException,TransformerException {
	rebuild(oDbb, new HashMap<String,String>(), bFullRebuild);
  }
}



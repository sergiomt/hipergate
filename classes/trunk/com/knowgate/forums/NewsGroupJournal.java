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

import com.knowgate.jdc.JDCConnection;
import com.knowgate.misc.Calendar;
import com.knowgate.misc.Gadgets;
import com.knowgate.misc.Month;
import com.knowgate.dfs.FileSystem;
import com.knowgate.debug.DebugFile;
import com.knowgate.dataobjs.DB;
import com.knowgate.dataobjs.DBSubset;
import com.knowgate.dataobjs.DBCommand;
import com.knowgate.dataxslt.StylesheetCache;
import com.knowgate.forums.Forums;
import com.knowgate.forums.NewsGroup;

/**
 * <p>NewsGroupJournal</p>
 * @author Sergio Montoro Ten
 * @version 5.0
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

  // ---------------------------------------------------------------------------

  public void rebuild(JDCConnection oConn, boolean bFullRebuild)
  	throws NullPointerException,SQLException,FileNotFoundException,IOException,TransformerException {

	String sMessageList;
	String sXMLDataSource;
	String sDaysWithPosts;
    SimpleDateFormat oFmt = new SimpleDateFormat("yyyy_MM_dd");	
	File oOut;
	Date dtLastModified;
	Date dtFileModified;
	boolean bNeedsRebuild;
	String sFilePath;

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
	
	NewsGroup oNewsGrp = new NewsGroup();

	if (!oNewsGrp.load(oConn, getGuid())) {
      if (DebugFile.trace) {
      	DebugFile.writeln("NewsGroupJournal.rebuild() No NewsGroup with GUID "+getGuid()+" found at "+DB.k_newsgroups+" table");
        DebugFile.decIdent();
      }	
      throw new SQLException("NewsGroupJournal.rebuild() No NewsGroup with GUID "+getGuid()+" found at "+DB.k_newsgroups+" table");
	} // fi
	
	String sXmlProlog = "<?xml version=\"1.0\" encoding=\""+getEncoding()+"\"?>\n";
	String sNewsGrpXml = oNewsGrp.toXML(oConn);
	String sMonthsWithPosts = Forums.XMLListMonthsWithPosts(oConn, getGuid(), getLanguage());

	FileSystem oFs = new FileSystem();
	try { oFs.mkdirs("file://"+getOutputPath()+"archives"); } catch (Exception ignore) { }

    Properties oProps = new Properties();
	oProps.put("language", getLanguage());
	oProps.put("basehref", getBaseHref());

    ArrayList<Boolean> aDaysWithPosts = Forums.getDaysWithPosts(oConn, getGuid(), null, null);

	DBSubset oLastModified = new DBSubset(DB.k_newsmsgs+" m,"+DB.k_x_cat_objs+" x",
										  "MAX(m."+DB.dt_modified+")",
		                                  "m."+DB.gu_msg+"=x."+DB.gu_object+" AND "+
		                                  "x."+DB.gu_category+"=? AND "+
		                                  "m."+DB.dt_published+" BETWEEN ? AND ?", 1);
	
	for (NewsGroupJournalPage t : templates) {

      if (DebugFile.trace) {
        DebugFile.writeln("Processing "+t.getFilter()+" template");
      }

	  if (t.getFilter().equalsIgnoreCase("main")) {

        dtLastModified =  DBCommand.queryMaxDate(oConn, "m."+DB.dt_modified,
		                                         DB.k_newsmsgs+" m,"+DB.k_x_cat_objs+" x",
		                                         "m."+DB.gu_msg+"=x."+DB.gu_object+" AND "+
		                                         "x."+DB.gu_category+"='"+getGuid()+"'");
		if (null==dtLastModified) dtLastModified = new Date();

        if (DebugFile.trace) {
          DebugFile.writeln("Last modified message date is "+dtLastModified.toString());
        }

	    sFilePath = getOutputPath()+"main.html";

	    oOut = new File(sFilePath);
	    if (oOut.exists()) {
	      dtFileModified = new Date(oOut.lastModified());
          if (DebugFile.trace) {
            DebugFile.writeln("Output file path is "+sFilePath+" last modified at "+dtFileModified.toString());
          }
	      bNeedsRebuild = (dtLastModified.compareTo(dtFileModified)>0) || (new File(getBlogPath()+t.getInputFilePath()).lastModified()>dtFileModified.getTime());
	      if (bNeedsRebuild || bFullRebuild) oOut.delete();
	    } else {
          if (DebugFile.trace) {
            DebugFile.writeln("Output file "+sFilePath+" does not exist");
          }
	      bNeedsRebuild = true;
	    }
	    
		if (bNeedsRebuild || bFullRebuild) {
	  	  sMessageList = Forums.XMLListTopLevelMessagesForGroup(oConn, t.getLimit(), 0, getGuid(), DB.dt_published);
	  	  sXMLDataSource = sXmlProlog + "<Journal guid=\""+getGuid()+"\">\n" + sNewsGrpXml + "\n" + sMonthsWithPosts + "\n" + sMessageList + "</Journal>";

		  if (DebugFile.trace) {
		  	oFs.delete(getOutputPath()+"main.xml");
		  	oFs.writefilestr(getOutputPath()+"main.xml", sXMLDataSource, getEncoding());
		  }

	      oFs.writefilestr(sFilePath,
	                       StylesheetCache.transform(getBlogPath()+t.getInputFilePath(), sXMLDataSource, oProps), getEncoding());
		} // fi (bNeedsRebuild)

      } else if (t.getFilter().equalsIgnoreCase("rss2")) {

        dtLastModified =  DBCommand.queryMaxDate(oConn, "m."+DB.dt_modified,
		                                         DB.k_newsmsgs+" m,"+DB.k_x_cat_objs+" x",
		                                         "m."+DB.gu_msg+"=x."+DB.gu_object+" AND "+
		                                         "x."+DB.gu_category+"='"+getGuid()+"' AND "+
		                                         "m."+DB.gu_parent_msg+" IS NULL");
		if (null==dtLastModified) dtLastModified = new Date();

        if (DebugFile.trace) {
          DebugFile.writeln("Last modified message date is "+dtLastModified.toString());
        }

	    sFilePath = getOutputPath()+"rss2.xml";

	    oOut = new File(sFilePath);
	    if (oOut.exists()) {
	      dtFileModified = new Date(oOut.lastModified());
          if (DebugFile.trace) {
            DebugFile.writeln("Output file path is "+sFilePath+" last modified at "+dtFileModified.toString());
          }
	      bNeedsRebuild = (dtLastModified.compareTo(dtFileModified)>0) || (new File(getBlogPath()+t.getInputFilePath()).lastModified()>dtFileModified.getTime());
	      if (bNeedsRebuild || bFullRebuild) oOut.delete();
	    } else {
          if (DebugFile.trace) {
            DebugFile.writeln("Output file "+sFilePath+" does not exist");
          }
	      bNeedsRebuild = true;
	    }
	    
		if (bNeedsRebuild || bFullRebuild) {
			
	  	  sMessageList = Forums.XMLListTopLevelMessagesForGroup(oConn, t.getLimit(), 0, getGuid(), DB.dt_published, "yyyy-MM-dd'T'hh:mm:ss");
	  	  try {
	  	    sMessageList = Gadgets.replace(sMessageList,"<((IMG)|img) +((SRC)|(src))=\"/", "<img src=\""+getBaseHref()+"/");
	  	  } catch (org.apache.oro.text.regex.MalformedPatternException neverthrown) { }
	  	  sXMLDataSource = sXmlProlog + "<Journal guid=\""+getGuid()+"\">\n" + sNewsGrpXml + "\n" + sMessageList + "</Journal>";

	      oFs.writefilestr(sFilePath,
	                       StylesheetCache.transform(getBlogPath()+t.getInputFilePath(), sXMLDataSource, oProps), getEncoding());
		  if (DebugFile.trace) {
	        oFs.writefilestr(sFilePath+".source.xml", sXMLDataSource, getEncoding());
		  }
		} // fi (bNeedsRebuild)

	  } else if (t.getFilter().equalsIgnoreCase("monthly")) {

		  ArrayList<Month> aMonthsWithPosts = Forums.getMonthsWithPosts(oConn, getGuid());

		  for (Month m : aMonthsWithPosts) {

			oProps.put("year", String.valueOf(m.getYear()));
			oProps.put("month", String.valueOf(m.getMonth()));

		    if (oLastModified.load(oConn, new Object[]{getGuid(), new Timestamp(m.firstDay().getTime()), new Timestamp(m.lastDay().getTime())})>0) {
		      if (oLastModified.isNull(0,0))
		        dtLastModified = new Date();
		      else
		        dtLastModified = oLastModified.getDate(0,0);
		    } else {
		      dtLastModified = new Date();
		    }
			
            if (DebugFile.trace) {
              DebugFile.writeln("Last modified message date is "+dtLastModified.toString());
            }

	        sFilePath = getOutputPath()+"archives"+File.separator+m.toString()+".html";
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
			  sMessageList = Forums.XMLListTopLevelMessagesForGroup(oConn, m.firstDay(), m.lastDay(), getGuid(), DB.dt_published);
	  	      sXMLDataSource = sXmlProlog + "<Journal guid=\""+getGuid()+"\">\n" + sNewsGrpXml + "\n" + sMonthsWithPosts + "\n" + sMessageList + "</Journal>";

		  	  if (DebugFile.trace) {
		  	    oFs.delete(Gadgets.dechomp(sFilePath,"html")+"xml");
		  	    oFs.writefilestr(Gadgets.dechomp(sFilePath,"html")+"xml", sXMLDataSource, getEncoding());
		      }

	          oFs.writefilestr(sFilePath,
	                           StylesheetCache.transform(getBlogPath()+t.getInputFilePath(), sXMLDataSource, oProps), getEncoding());
		    } // fi
		    
		  } // next		  
	    } else if (t.getFilter().equalsIgnoreCase("daily")) {

	      Date dt1stPost = DBCommand.queryMinDate(oConn, "m."+DB.dt_published,
		                                          DB.k_newsmsgs+" m,"+DB.k_x_cat_objs+" x",
		                                          "m."+DB.gu_msg+"=x."+DB.gu_object+" AND "+
		                                          "x."+DB.gu_category+"='"+getGuid()+"' AND "+
		                                          "m."+DB.id_status+"="+String.valueOf(NewsMessage.STATUS_VALIDATED));
		  if (dt1stPost!=null) {

	        Date dtDay00 = new Date(dt1stPost.getYear(), dt1stPost.getMonth(), dt1stPost.getDate(),  0,  0,  0);
	        Date dtDay23 = new Date(dt1stPost.getYear(), dt1stPost.getMonth(), dt1stPost.getDate(), 23, 59, 59);

		    for (Boolean b : aDaysWithPosts) {
		  	
		  	  if (b.booleanValue()) {

			    oProps.put("year", String.valueOf(dtDay00.getYear()));
			    oProps.put("month", String.valueOf(dtDay00.getMonth()));

		        if (oLastModified.load(oConn, new Object[]{getGuid(), new Timestamp(dtDay00.getTime()), new Timestamp(dtDay23.getTime())})>0) {
		          if (oLastModified.isNull(0,0))
		            dtLastModified = new Date();
		          else
		            dtLastModified = oLastModified.getDate(0,0);
		        } else {
		          dtLastModified = new Date();
		        }

                if (DebugFile.trace) {
                  DebugFile.writeln("Last modified message date is "+dtLastModified.toString());
                }

	  	        sFilePath = getOutputPath()+"archives"+File.separator+oFmt.format(dtDay00)+".html";
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
			      sMessageList = Forums.XMLListTopLevelMessagesForGroup(oConn, dtDay00, dtDay23, getGuid(), DB.dt_published);
	  	          sXMLDataSource = sXmlProlog + "<Journal guid=\""+getGuid()+"\">\n" + sNewsGrpXml + "\n" + sMonthsWithPosts + "\n" + sMessageList + "</Journal>";
	              oFs.writefilestr(sFilePath,
	                               StylesheetCache.transform(getBlogPath()+t.getInputFilePath(), sXMLDataSource, oProps), getEncoding());
		        } // fi

		      } // fi (DaysWithPosts)
			  dtDay00 = new Date(dtDay00.getTime()+86400000l);
			  dtDay23 = new Date(dtDay23.getTime()+86400000l);
		    } // next
		  } else {
            if (DebugFile.trace)
              DebugFile.writeln("No date for first post found rebuilding daily template");
		  } // fi

	    } else if (t.getFilter().equalsIgnoreCase("single")) {

	      DBSubset  oPostsModified = new DBSubset (
	      	  DB.k_newsmsgs + " m," + DB.k_x_cat_objs + " x," + DB.k_newsgroups + " g," + DB.k_categories + " c",
    	      "MAX(m." + DB.dt_modified + "),m."+DB.gu_thread_msg,
    	      "m." + DB.id_status + "="+String.valueOf(NewsMessage.STATUS_VALIDATED)+" AND x." + DB.gu_category + "=" + "g." + DB.gu_newsgrp + " AND " +
    	      "c." + DB.gu_category + "=g." + DB.gu_newsgrp + " AND " +
    	      "m." + DB.gu_msg + "=x." + DB.gu_object + " AND g." + DB.gu_newsgrp + "=? GROUP BY m."+DB.gu_thread_msg, 100);
		  int nPosts = oPostsModified.load(oConn, new Object[]{getGuid()});

		  for (int p=0; p<nPosts; p++) {
		    dtLastModified = oPostsModified.getDate(0,0);
		    if (null==dtLastModified) dtLastModified = new Date();

            if (DebugFile.trace) {
              DebugFile.writeln("Last modified message date is "+dtLastModified.toString());
            }
		    
	  	    sFilePath = getOutputPath()+"archives"+File.separator+oPostsModified.getString(1,p)+".html";
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

			  sMessageList = Forums.XMLListMessagesForThread(oConn, oPostsModified.getString(1,p));
	  	      sXMLDataSource = sXmlProlog + "<Journal guid=\""+getGuid()+"\">\n" + sNewsGrpXml + "\n" + sMonthsWithPosts + "\n" + sMessageList + "</Journal>";
	          oFs.writefilestr(sFilePath,
	                           StylesheetCache.transform(getBlogPath()+t.getInputFilePath(), sXMLDataSource, oProps), getEncoding());
		  	  if (DebugFile.trace) {
		  	    oFs.writefilestr(Gadgets.dechomp(sFilePath,"html")+"xml", sXMLDataSource, getEncoding());
		      }
		    } // fi
		    
		  } //next

	    } else if (t.getFilter().equalsIgnoreCase("bytag")) {

          DBSubset oTags = Forums.getNewsGroupTags(oConn, getGuid());
          int nTags = oTags.getRowCount();

          for (int g=0; g<nTags; g++) {
          	
            if (DebugFile.trace) {
                DebugFile.writeln("Rebuilding archive for tag "+oTags.getString(3,g));
            }

	        oProps.put("tag", oTags.getString(4,g));

	  	    sFilePath = getOutputPath()+"archives"+File.separator+oTags.getString(4,g)+".html";
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

			sMessageList = Forums.XMLListTopLevelMessagesForTag(oConn, 32767, 0, getGuid(), oTags.getString(0,g), DB.dt_published);
	  	    sXMLDataSource = sXmlProlog + "<Journal guid=\""+getGuid()+"\">\n" + sNewsGrpXml + "\n" + sMonthsWithPosts + "\n" + sMessageList + "</Journal>";
	        oFs.writefilestr(sFilePath,
	                         StylesheetCache.transform(getBlogPath()+t.getInputFilePath(), sXMLDataSource, oProps), getEncoding());

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
}



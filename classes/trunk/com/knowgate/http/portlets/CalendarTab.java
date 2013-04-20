/*
  Copyright (C) 2003-2006  Know Gate S.L. All rights reserved.
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

package com.knowgate.http.portlets;

import java.io.File;
import java.io.IOException;
import java.io.ByteArrayOutputStream;
import java.io.ByteArrayInputStream;

import java.text.SimpleDateFormat;

import java.util.Date;
import java.util.Locale;
import java.util.Properties;
import java.util.Enumeration;

import java.sql.SQLException;
import java.sql.Timestamp;

import javax.xml.transform.TransformerException;
import javax.xml.transform.TransformerConfigurationException;

import javax.portlet.*;

import com.knowgate.debug.DebugFile;
import com.knowgate.jdc.JDCConnection;
import com.knowgate.dataobjs.*;
import com.knowgate.dataxslt.StylesheetCache;
import com.knowgate.misc.Gadgets;
import com.knowgate.dfs.FileSystem;

/**
 * Calendar Tabbed Dialog Portlet
 * @author Sergio Montoro Ten
 * @version 2.2
 */

public class CalendarTab  extends GenericPortlet {
  public CalendarTab() { }

  public CalendarTab(HipergatePortletConfig oConfig)
    throws javax.portlet.PortletException {

    init(oConfig);
  }

  // ---------------------------------------------------------------------------

  public String render(RenderRequest req, String sEncoding)
    throws PortletException, IOException, IllegalStateException {

    ByteArrayInputStream oInStream;
    ByteArrayOutputStream oOutStream;

    if (DebugFile.trace) {
      DebugFile.writeln("Begin CalendarTab.render()");
      DebugFile.incIdent();
    }

    FileSystem oFS = new FileSystem(FileSystem.OS_PUREJAVA);

    String sOutput;
    String sDomainId = req.getProperty("domain");
    String sWorkAreaId = req.getProperty("workarea");
    String sLanguageId = req.getProperty("language");
    String sUserId = req.getProperty("user");
    String sPublicId = req.getProperty("public");
    String sTemplatePath = req.getProperty("template");
    String sStorage = req.getProperty("storage");
    String sZone = req.getProperty("zone");
    String sMaxRows = req.getProperty("maxrows");
    if (null==sMaxRows) sMaxRows = "10";
    String sFileDir = "file://" + sStorage + "domains" + File.separator + sDomainId + File.separator + "workareas" + File.separator + sWorkAreaId + File.separator + "cache" + File.separator + sUserId;
    String sCachedFile = "calendartab_" + sZone + "_" + req.getWindowState().toString() + ".xhtm";

    if (DebugFile.trace) {
      DebugFile.writeln ("user=" + sUserId);
      DebugFile.writeln ("template=" + sTemplatePath);
      DebugFile.writeln ("cache dir=" + sFileDir);
      DebugFile.writeln ("modified=" + req.getAttribute("modified"));
      DebugFile.writeln ("encoding=" + sEncoding);
    }

    Date oDtModified = (Date) req.getAttribute("modified");

    if (null!=oDtModified) {
      try {
      if (DebugFile.trace) DebugFile.writeln ("new File("+sFileDir.substring(7)+File.separator+sCachedFile+")");
      	
        File oCached = new File(sFileDir.substring(7)+File.separator+sCachedFile);

        if (!oCached.exists()) {
          oFS.mkdirs(sFileDir);
        }
        else if (oCached.lastModified()>oDtModified.getTime()) {
          sOutput = new String(FileSystem.readfile(sFileDir+File.separator+sCachedFile, sEncoding==null ? "ISO8859_1" : sEncoding));

          if (DebugFile.trace) {
            DebugFile.writeln("cache hit " + sFileDir+File.separator+sCachedFile);
            DebugFile.decIdent();
            DebugFile.writeln("End CalendarTab.render()");
          }

          return sOutput;
        }
      }
      catch (Exception xcpt) {
        DebugFile.writeln(xcpt.getClass().getName() + " " + xcpt.getMessage());
      }
    }

    String sXML;

    int iToDo = 0, iMeetings = 0, iPublic = 0;

    if (req.getWindowState().equals(WindowState.MINIMIZED)) {
      if (DebugFile.trace) DebugFile.writeln ("WindowState.MINIMIZED");
      sXML = "<?xml version=\"1.0\" encoding=\"UTF-8\"?><?xml-stylesheet type=\"text/xsl\"?><calendar><todo/><today/></calendar>";
    }
    else {
      if (DebugFile.trace) DebugFile.writeln ("WindowState.NORMAL");

      String sTodayXML, sToDoXML, sPublicXML;

      SimpleDateFormat oFmt = new SimpleDateFormat("EEE dd MMM HH:mm", new Locale(sLanguageId==null ? "en" : "es"));

      Date dt00 = new Date();
      Date dt23 = new Date();

      dt00.setHours(0);
      dt00.setMinutes(0);
      dt00.setSeconds(0);

      dt23.setHours(23);
      dt23.setMinutes(59);
      dt23.setSeconds(59);

      DBBind oDBB = (DBBind) getPortletContext().getAttribute("GlobalDBBind");

      DBSubset oToDo = new DBSubset (DB.k_to_do, DB.gu_to_do + "," + DB.od_priority + "," + DB.tl_to_do,
                                     DB.gu_user + "=? AND (" + DB.tx_status + "='PENDING' OR " + DB.tx_status + " IS NULL) ORDER BY 2 DESC", 10);

      DBSubset oMeetings = new DBSubset (DB.k_meetings + " m," + DB.k_x_meeting_fellow + " f",
                                         "m." + DB.gu_meeting + ",m." + DB.gu_fellow + ",m." + DB.tp_meeting + ",m." + DB.tx_meeting + ", m." + DB.dt_start + ",m." + DB.dt_end,
                                         "m." + DB.gu_meeting + "=f." + DB.gu_meeting + " AND f." + DB.gu_fellow + "=? AND m." + DB.dt_start + " BETWEEN ? AND ? ORDER BY m." + DB.dt_start, 10);

      DBSubset oPublic = new DBSubset (DB.k_meetings + " m," + DB.k_x_meeting_fellow + " f",
              "m." + DB.gu_meeting + ",m." + DB.gu_fellow + ",m." + DB.tp_meeting + ",m." + DB.tx_meeting + ", m." + DB.dt_start + ",m." + DB.dt_end,
              "m." + DB.gu_meeting + "=f." + DB.gu_meeting + " AND f." + DB.gu_fellow + "=? AND m." + DB.dt_start + ">=? ORDER BY m." + DB.dt_start, 10);
      
      JDCConnection oCon = null;

      try  {
        oCon = oDBB.getConnection("CalendarTab_today");

        oToDo.setMaxRows(Integer.parseInt(sMaxRows));
        iToDo = oToDo.load (oCon, new Object[]{sUserId});

        for (int a=0; a<iToDo; a++) {
          if (oToDo.getStringNull(2, a,"").length()>40)
            oToDo.setElementAt(oToDo.getString(2, a).substring(0, 40) +"...", 2,a);
        }

        sToDoXML = oToDo.toXML("", "activity");

        iMeetings = oMeetings.load(oCon, new Object[]{sUserId, new Timestamp(dt00.getTime()), new Timestamp(dt23.getTime())});

        for (int m=0; m<iMeetings; m++) {

          if (oMeetings.isNull(3,m)) oMeetings.setElementAt("untitled", 3,m);

          Date oFrom = oMeetings.getDate(4,m);
          oMeetings.setElementAt(String.valueOf(oFrom.getHours())+":"+Gadgets.leftPad(String.valueOf(oFrom.getMinutes()),'0',2), 4, m);

          Date oTo = oMeetings.getDate(5,m);
          oMeetings.setElementAt(String.valueOf(oTo.getHours())+":"+Gadgets.leftPad(String.valueOf(oTo.getMinutes()),'0',2), 5, m);
        }

        if (sPublicId!=null) {
          if (sPublicId.length()>0) {
        	oPublic.setMaxRows(10);
            iPublic = oPublic.load(oCon, new Object[]{sPublicId, new Timestamp(dt00.getTime())});
          }
        }
        for (int p=0; p<iPublic; p++) {
          if (oPublic.isNull(3,p)) oPublic.setElementAt("untitled", 3,p);
          oPublic.setElementAt(oFmt.format(oPublic.getDate(4,p)), 4, p);
          oPublic.setElementAt(oFmt.format(oPublic.getDate(5,p)), 5, p);
        }
        
        oCon.close("CalendarTab_today");
        oCon = null;

        sTodayXML = oMeetings.toXML("","meeting");
        sPublicXML = oPublic.toXML("","meeting");
      }
      catch (SQLException e) {
        sToDoXML = "<todo></todo>";
        sTodayXML = "<today></today>";
        sPublicXML = "<public></public>";

        try {
          if (null != oCon)
            if (!oCon.isClosed())
              oCon.close("CalendarTab_today");
        } catch (SQLException ignore) { }
      }

      sXML = "<?xml version=\"1.0\" encoding=\"UTF-8\"?>\n<?xml-stylesheet type=\"text/xsl\"?>\n<calendar>\n";
      if (iToDo>0)
        sXML += "<todo>\n"+sToDoXML+"</todo>\n";
      else
        sXML += "<todo/>\n";

      if (iMeetings>0)
        sXML += "<today>\n"+sTodayXML+"</today>\n";
      else
        sXML += "<today/>\n";

      if (iPublic>0)
          sXML += "<public>\n"+sPublicXML+"</public>";
        else
          sXML += "<public/>";

      sXML += "\n</calendar>";
    }

     try {
       if (DebugFile.trace) DebugFile.writeln("new ByteArrayInputStream(" + String.valueOf(sXML.length()) + ")");

       if (sEncoding==null)
         oInStream = new ByteArrayInputStream(sXML.getBytes());
       else
         oInStream = new ByteArrayInputStream(sXML.getBytes(sEncoding));

       oOutStream = new ByteArrayOutputStream(4000);

       Properties oProps = new Properties();

       Enumeration oKeys = req.getPropertyNames();
       while (oKeys.hasMoreElements()) {
         String sKey = (String) oKeys.nextElement();
         if (null!=req.getProperty(sKey)) {
           if (DebugFile.trace) DebugFile.writeln("setProperty("+sKey+","+req.getProperty(sKey)+")");
           oProps.setProperty(sKey, req.getProperty(sKey));
         }
       } // wend

	   if (req.getWindowState()==null)
         oProps.setProperty("windowstate", "NORMAL");
       else if (req.getWindowState().equals(WindowState.MINIMIZED))
         oProps.setProperty("windowstate", "MINIMIZED");
       else
         oProps.setProperty("windowstate", "NORMAL");

       StylesheetCache.transform (sTemplatePath, oInStream, oOutStream, oProps);

       if (sEncoding==null)
         sOutput = oOutStream.toString();
       else
         sOutput = oOutStream.toString("UTF-8");

       oOutStream.close();

       oInStream.close();
       oInStream = null;

       oFS.writefilestr (sFileDir+File.separator+sCachedFile, sOutput, sEncoding==null ? "ISO8859_1" : sEncoding);
     }
     catch (TransformerConfigurationException tce) {
       if (DebugFile.trace) {
         DebugFile.writeln("TransformerConfigurationException " + tce.getMessageAndLocation());
         try {
           DebugFile.write("--------------------------------------------------------------------------------\n");
           DebugFile.write(FileSystem.readfile(sTemplatePath));
           DebugFile.write("\n--------------------------------------------------------------------------------\n");
           DebugFile.write(sXML);
           DebugFile.write("\n--------------------------------------------------------------------------------\n");
         }
         catch (java.io.IOException ignore) { }
         catch (com.enterprisedt.net.ftp.FTPException ignore) { }

         DebugFile.decIdent();
       }
       throw new PortletException("TransformerConfigurationException " + tce.getMessage(), tce);
     }
     catch (TransformerException tex) {
       if (DebugFile.trace) {
         DebugFile.writeln("TransformerException " + tex.getMessageAndLocation());

         try {
           DebugFile.write("--------------------------------------------------------------------------------\n");
           DebugFile.write(FileSystem.readfile(sTemplatePath));
           DebugFile.write("\n--------------------------------------------------------------------------------\n");
           DebugFile.write(sXML);
           DebugFile.write("\n--------------------------------------------------------------------------------\n");
         }
         catch (java.io.IOException ignore) { }
         catch (com.enterprisedt.net.ftp.FTPException ignore) { }

         DebugFile.decIdent();
       }
       throw new PortletException("TransformerException " + tex.getMessage(), tex);
     }

     if (DebugFile.trace) {
       DebugFile.decIdent();
       DebugFile.writeln("End CalendarTab.render()");
     }
     return sOutput;
   }

   // --------------------------------------------------------------------------

   public void render(RenderRequest req, RenderResponse res)
     throws PortletException, IOException, IllegalStateException {
     res.getWriter().write(render(req,res.getCharacterEncoding()));
   }
}

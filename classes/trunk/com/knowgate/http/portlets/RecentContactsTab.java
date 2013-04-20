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
package com.knowgate.http.portlets;

import java.io.File;
import java.io.IOException;
import java.io.ByteArrayOutputStream;
import java.io.ByteArrayInputStream;

import java.util.Date;
import java.util.Properties;
import java.util.Enumeration;

import java.sql.SQLException;
import java.sql.PreparedStatement;
import java.sql.ResultSet;

import javax.xml.transform.TransformerException;
import javax.xml.transform.TransformerConfigurationException;

import javax.portlet.*;

import com.knowgate.debug.DebugFile;
import com.knowgate.jdc.JDCConnection;
import com.knowgate.dataobjs.*;
import com.knowgate.dataxslt.StylesheetCache;
import com.knowgate.dfs.FileSystem;

/**
 * @author Sergio Montoro Ten
 * @version 2.2
 */

public class RecentContactsTab  extends GenericPortlet {
  public RecentContactsTab() { }

  public RecentContactsTab(HipergatePortletConfig oConfig)
    throws javax.portlet.PortletException {

    init(oConfig);
  }

  // ---------------------------------------------------------------------------

  public String render(RenderRequest req, String sEncoding)
    throws PortletException, IOException, IllegalStateException {

    ByteArrayInputStream oInStream;
    ByteArrayOutputStream oOutStream;

    if (DebugFile.trace) {
      DebugFile.writeln("Begin RecentContactsTab.render()");
      DebugFile.incIdent();
    }

    final int iMaxRecent = 8;

    FileSystem oFS = new FileSystem(FileSystem.OS_PUREJAVA);

    String sOutput;
    String sDomainId = req.getProperty("domain");
    String sWorkAreaId = req.getProperty("workarea");
    String sUserId = req.getProperty("user");
    String sZone = req.getProperty("zone");
    String sLang = req.getProperty("language");
    String sTemplatePath = req.getProperty("template");
    String sStorage = req.getProperty("storage");
    String sFileDir = "file://" + sStorage + "domains" + File.separator + sDomainId + File.separator + "workareas" + File.separator + sWorkAreaId + File.separator + "cache" + File.separator + sUserId;
    String sCachedFile = "recentcontactstab_" + req.getWindowState().toString() + ".xhtm";

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

        File oCached = new File(sFileDir.substring(7)+File.separator+sCachedFile);

        if (!oCached.exists()) {
          oFS.mkdirs(sFileDir);
        }
        else {
          if (DebugFile.trace) {
            DebugFile.writeln ("file modified " + new Date(oCached.lastModified()).toString());
            DebugFile.writeln ("last modified " + new Date(oDtModified.getTime()).toString());
          }
          if (oCached.lastModified()>oDtModified.getTime()) {
            sOutput = new String(FileSystem.readfile(sFileDir+File.separator+sCachedFile, sEncoding==null ? "ISO8859_1" : sEncoding));

            if (DebugFile.trace) {
              DebugFile.writeln("cache hit " + sFileDir+File.separator+sCachedFile);
              DebugFile.decIdent();
              DebugFile.writeln("End RecentContactsTab.render()");
            }

            return sOutput;
          } // fi (oCached.lastModified()>oDtModified.getTime())
        } // fi (!oCached.exists())
      }
      catch (Exception xcpt) {
        DebugFile.writeln(xcpt.getClass().getName() + " " + xcpt.getMessage());
      }
    }

    String sXML = "<?xml version=\"1.0\" encoding=\"UTF-8\"?><?xml-stylesheet type=\"text/xsl\"?>";

    int iCalls = 0;

    if (req.getWindowState().equals(WindowState.MINIMIZED)) {
      sXML += "<contacts/>";
    }
    else {

      DBBind oDBB = (DBBind) getPortletContext().getAttribute("GlobalDBBind");

      JDCConnection oCon = null;

      try  {
        oCon = oDBB.getConnection("RecentContactsTab");

        PreparedStatement oStm = oCon.prepareStatement("(SELECT dt_last_visit,gu_company,NULL AS gu_contact,nm_company,'' AS full_name,work_phone,tx_email FROM k_companies_recent WHERE gu_user=? UNION SELECT dt_last_visit,NULL AS gu_company,gu_contact,nm_company,full_name,work_phone,tx_email FROM k_contacts_recent WHERE gu_user=?) ORDER BY dt_last_visit DESC", ResultSet.TYPE_FORWARD_ONLY, ResultSet.CONCUR_READ_ONLY);
        oStm.setString (1, sUserId);
        oStm.setString (2, sUserId);
        ResultSet oRSet = oStm.executeQuery();

        int iRecentCount = 0;
        StringBuffer oXML = new StringBuffer();
        String sStr;

        while (oRSet.next() && iRecentCount<iMaxRecent) {
          oXML.append("<contact>");

          sStr = oRSet.getString(2);
          if (oRSet.wasNull()) oXML.append("<gu_company/>"); else oXML.append("<gu_company>"+oRSet.getString(2)+"</gu_company>");

          sStr = oRSet.getString(3);
          if (oRSet.wasNull()) oXML.append("<gu_contact/>"); else oXML.append("<gu_contact>"+oRSet.getString(3)+"</gu_contact>");

          sStr = oRSet.getString(4);
          if (oRSet.wasNull()) oXML.append("<nm_company/>"); else oXML.append("<nm_company><![CDATA["+oRSet.getString(4)+"]]></nm_company>");

          sStr = oRSet.getString(5);
          if (oRSet.wasNull()) oXML.append("<full_name/>"); else oXML.append("<full_name><![CDATA["+oRSet.getString(5)+"]]></full_name>");

          sStr = oRSet.getString(6);
          if (oRSet.wasNull()) oXML.append("<work_phone/>"); else oXML.append("<work_phone><![CDATA["+oRSet.getString(6)+"]]></work_phone>");

          sStr = oRSet.getString(7);
          if (oRSet.wasNull()) oXML.append("<tx_email/>"); else oXML.append("<tx_email><![CDATA["+oRSet.getString(7)+"]]></tx_email>");

          oXML.append("</contact>");

          iRecentCount++;
        } // wend

        oCon.close("RecentContactsTab");
        oCon = null;

        sXML += "<contacts>\n"+oXML.toString()+"</contacts>";
      }
      catch (SQLException e) {
        sXML += "<contacts/>";

        try {
          if (null != oCon)
            if (!oCon.isClosed())
              oCon.close("RecentContactsTab");
        } catch (SQLException ignore) { }
      }
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
         oProps.setProperty(sKey, req.getProperty(sKey));
       } // wend

       if (req.getWindowState().equals(WindowState.MINIMIZED))
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
       DebugFile.writeln("End RecentContactsTab.render()");
     }
     return sOutput;
   }

   // --------------------------------------------------------------------------

   public void render(RenderRequest req, RenderResponse res)
     throws PortletException, IOException, IllegalStateException {
     res.getWriter().write(render(req,res.getCharacterEncoding()));
    }
}

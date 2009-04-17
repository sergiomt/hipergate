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
import com.knowgate.misc.Gadgets;
import com.knowgate.dfs.FileSystem;

/**
 * Open Oportunities Tabbed Dialog Portlet
 * @author Sergio Montoro Ten
 * @version 2.2
 */

public class OportunitiesTab extends GenericPortlet {
  public OportunitiesTab() { }

  public OportunitiesTab(HipergatePortletConfig oConfig)
    throws javax.portlet.PortletException {

    init(oConfig);
  }

  // ---------------------------------------------------------------------------

  public String render(RenderRequest req, String sEncoding)
    throws PortletException, IOException, IllegalStateException {

    ByteArrayInputStream oInStream;
    ByteArrayOutputStream oOutStream;

    if (DebugFile.trace) {
      DebugFile.writeln("Begin OportunitiesTab.render()");
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
    String sCachedFile = "oportunitiestab_" + req.getWindowState().toString() + ".xhtm";

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
        else if (oCached.lastModified()>oDtModified.getTime()) {
          sOutput = new String(oFS.readfile(sFileDir+File.separator+sCachedFile, sEncoding==null ? "ISO8859_1" : sEncoding));

          if (DebugFile.trace) {
            DebugFile.writeln("cache hit " + sFileDir+File.separator+sCachedFile);
            DebugFile.decIdent();
            DebugFile.writeln("End OportunitiesTab.render()");
          }

          return sOutput;
        }
      }
      catch (Exception xcpt) {
        DebugFile.writeln(xcpt.getClass().getName() + " " + xcpt.getMessage());
      }
    }

    String sXML = "<?xml version=\"1.0\" encoding=\"UTF-8\"?><?xml-stylesheet type=\"text/xsl\"?>";

    int iCalls = 0;

    if (req.getWindowState().equals(WindowState.MINIMIZED)) {
      sXML += "<oportunities/>";
    }
    else {

      DBBind oDBB = (DBBind) getPortletContext().getAttribute("GlobalDBBind");

      JDCConnection oCon = null;
      PreparedStatement oStm = null;
      String sSQL, sInterval;

      try  {
        int iOprtnCount = 0;
        StringBuffer oXML = new StringBuffer();
        String[][] aOprtns = new String[6][iMaxRecent];

        oCon = oDBB.getConnection("OportunitiesTab");

        if (oCon.getDataBaseProduct()==JDCConnection.DBMS_POSTGRESQL)
          sInterval = "interval '10 years'";
        else
          sInterval = "3650";

        sSQL = "SELECT "+
               DB.gu_oportunity+","+DB.tl_oportunity+","+DB.gu_company+","+DB.gu_contact+","+DB.tx_company+","+DB.tx_contact+","+DB.dt_modified+","+DB.dt_next_action+","+
               DBBind.Functions.GETDATE+"-"+DB.dt_modified+ " AS nu_elapsed FROM "+DB.k_oportunities+" WHERE "+DB.id_status+" NOT IN ('PERDIDA','GANADA','ABANDONADA') AND "+
               DB.dt_modified+" IS NOT NULL AND " + DB.gu_workarea+"=? AND "+DB.gu_writer+"=? UNION SELECT "+
               DB.gu_oportunity+","+DB.tl_oportunity+","+DB.gu_company+","+DB.gu_contact+","+DB.tx_company+","+DB.tx_contact+","+DB.dt_modified+","+DB.dt_next_action+","+
               DBBind.Functions.ISNULL+"("+DB.dt_next_action+","+DBBind.Functions.GETDATE+"+" + sInterval + ")-"+DBBind.Functions.GETDATE+" AS nu_elapsed "+
               "FROM "+DB.k_oportunities+" WHERE "+DB.id_status+" NOT IN ('PERDIDA','GANADA','ABANDONADA') AND "+
               DB.gu_workarea+"=? AND "+DB.gu_writer+"=?";

        if (oCon.getDataBaseProduct()!=JDCConnection.DBMS_MYSQL) {
          sSQL = "(" + sSQL + ")";
        }
        sSQL += " ORDER BY "+DB.nu_elapsed;

        if (DebugFile.trace) DebugFile.writeln("Connection.prepareStatement("+sSQL+")");

        oStm = oCon.prepareStatement(sSQL,ResultSet.TYPE_FORWARD_ONLY, ResultSet.CONCUR_READ_ONLY);

        oStm.setString (1,sWorkAreaId);
        oStm.setString (2,sUserId);
        oStm.setString (3,sWorkAreaId);
        oStm.setString (4,sUserId);

        if (DebugFile.trace) DebugFile.writeln("PreparedStatement.executeQuery()");

        ResultSet oRSet = oStm.executeQuery();

        while (oRSet.next() && iOprtnCount<iMaxRecent) {

          boolean bListed = false;
          for (int n=0; n<iOprtnCount && !bListed; n++)
            bListed = oRSet.getString(1).equals(aOprtns[0][n]);

          if (!bListed) {
            aOprtns[0][iOprtnCount] = oRSet.getString(1);
            aOprtns[1][iOprtnCount] = oRSet.getString(2);
            aOprtns[2][iOprtnCount] = oRSet.getString(3);
            aOprtns[3][iOprtnCount] = oRSet.getString(4);
            aOprtns[4][iOprtnCount] = oRSet.getString(5);
            aOprtns[5][iOprtnCount] = oRSet.getString(6);

            iOprtnCount++;
          }
        } // wend

        oRSet.close();
        oRSet = null;

        oStm.close();
        oStm = null;

        oCon.close("OportunitiesTab");
        oCon = null;

        for (int o=0; o<iOprtnCount; o++)
          for (int f=0; f<6; f++)
            if (aOprtns[f][o]==null) aOprtns[f][o]="";

        oXML.append("<oportunities>\n");
        for (int q=0; q<iOprtnCount; q++) {
          oXML.append("<oportunity>\n");

          oXML.append("<gu_oportunity>"+aOprtns[0][q]+"</gu_oportunity>");
          oXML.append("<tl_oportunity><![CDATA["+aOprtns[1][q]+"]]></tl_oportunity>");
          oXML.append("<gu_company>"+aOprtns[2][q]+"</gu_company>");
          oXML.append("<gu_contact>"+aOprtns[3][q]+"</gu_contact>");
          oXML.append("<tx_company><![CDATA["+aOprtns[4][q]+"]]></tx_company>");
          oXML.append("<tx_contact><![CDATA["+aOprtns[5][q]+"]]></tx_contact>");
          oXML.append("<tx_contact_esc><![CDATA["+Gadgets.URLEncode(aOprtns[5][q])+"]]></tx_contact_esc>");
          oXML.append("<where><![CDATA["+Gadgets.URLEncode(" AND gu_contact='" + aOprtns[3][q] + "'")+"]]></where>");

          oXML.append("</oportunity>\n");
        }

        oXML.append("</oportunities>");

        sXML += oXML.toString();
      }
      catch (SQLException e) {
        sXML += "<oportunities/>";

        if (DebugFile.trace) DebugFile.writeln("SQLException " + e.getMessage());
        try {
          if (null != oStm)
              oStm.close();
        } catch (SQLException ignore) { }

        try {
          if (null != oCon)
            if (!oCon.isClosed())
              oCon.close("OportunitiesTab");
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
       DebugFile.writeln("End OportunitiesTab.render()");
     }
     return sOutput;
   }

   // --------------------------------------------------------------------------

   public void render(RenderRequest req, RenderResponse res)
     throws PortletException, IOException, IllegalStateException {
     res.getWriter().write(render(req,res.getCharacterEncoding()));
    }
}

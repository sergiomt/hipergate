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

import java.io.IOException;
import java.io.ByteArrayOutputStream;
import java.io.ByteArrayInputStream;

import java.util.Properties;
import java.util.Enumeration;

import java.sql.SQLException;

import javax.xml.transform.TransformerException;
import javax.xml.transform.TransformerConfigurationException;

import javax.portlet.*;

import com.knowgate.debug.DebugFile;
import com.knowgate.jdc.JDCConnection;
import com.knowgate.dfs.FileSystem;
import com.knowgate.dataobjs.*;
import com.knowgate.dataxslt.StylesheetCache;
import com.knowgate.hipergate.Category;

/**
 * Categories List for Microsites
 * @author Sergio Montoro Ten
 * @version 2.2
 */

public class CategoryList extends GenericPortlet {

  public CategoryList() { }

  public CategoryList(HipergatePortletConfig oConfig)
    throws javax.portlet.PortletException {

    init(oConfig);
  }

  // --------------------------------------------------------------------------

  public String render(RenderRequest req, String sEncoding)
    throws PortletException, IOException, IllegalStateException {

    DBBind dbb;
    DBSubset dbs, img;
    JDCConnection con = null;
    ByteArrayInputStream oInStream;
    ByteArrayOutputStream oOutStream;
    String sOutput, sParentId, sTemplatePath, sLanguageId, sLimit, sOffset, sWrkArGet, sWorkAreaId;
    int iOffset=0, iLimit=2147483647, iCatCount=0, iImgCount=0;

    if (DebugFile.trace) {
      DebugFile.writeln("Begin CategoryList.render()");
      DebugFile.incIdent();
    }

    sOffset = req.getParameter("offset");
    sLimit = req.getParameter("limit");

    sLanguageId = req.getParameter("language");

    if (null==sLanguageId) sLanguageId = "es";

    sParentId = (String) req.getAttribute("catalog");
    sTemplatePath = (String) req.getAttribute("template");

    sWorkAreaId = req.getProperty("workarea");
    sWrkArGet = req.getProperty("workareasget");

    if (DebugFile.trace) {
      DebugFile.writeln("template=" + sTemplatePath);
      DebugFile.writeln("catalog=" + sParentId);
      DebugFile.writeln("workarea=" + sWorkAreaId);
      DebugFile.writeln("workareasget=" + sWrkArGet);
    }

    try {
      if (null!=sOffset)
        iOffset = Integer.parseInt(sOffset);
    } catch (java.lang.NumberFormatException nfe) {
        if (DebugFile.trace) DebugFile.decIdent();
        throw new PortletException("NumberFormatException parameter offset is not a valid integer value", nfe);
    }

    try {
      if (null!=sLimit)
        iLimit = Integer.parseInt(sLimit);
    } catch (java.lang.NumberFormatException nfe) {
        if (DebugFile.trace) DebugFile.decIdent();
        throw new PortletException("NumberFormatException parameter limit is not a valid integer value", nfe);
    }

    try {
      dbb = (DBBind) getPortletContext().getAttribute("GlobalDBBind");

      dbs = new DBSubset (DB.v_cat_tree_labels + " l",
                          "l."+DB.gu_category + ",l." + DB.nm_category + ",l." + DB.tr_category + ",l." + DB.de_category,
                          "l."+DB.gu_parent_cat + "=? AND l." + DB.id_language + "=? ORDER BY 3", 10);

      img = new DBSubset (DB.k_images + " i," + DB.k_x_cat_objs + " x," + DB.k_cat_tree + " c",
                          "c." + DB.gu_child_cat + ",i." + DB.gu_image + ",i." + DB.path_image + ",i." + DB.nm_image + ",i." + DB.dm_width + ",i." + DB.dm_height + ",i." + DB.tl_image,
                          "c." + DB.gu_parent_cat + "=? AND i." + DB.tp_image + " LIKE 'category%' AND i." + DB.gu_image + "=x." + DB.gu_object + " AND x." + DB.id_class + "=13 AND x." + DB.gu_category + "=c." + DB.gu_child_cat + " ORDER BY 1", 10);

      con = dbb.getConnection("CategoryList");

      if (null!=sLimit) dbs.setMaxRows(iLimit);

      if (sOffset==null)
        iCatCount = dbs.load(con, new Object[]{sParentId,sLanguageId});
      else
        iCatCount = dbs.load(con, new Object[]{sParentId,sLanguageId}, iOffset);

      iImgCount = img.load(con, new Object[]{sParentId});
    }
    catch (SQLException sqle) {
      if (DebugFile.trace) DebugFile.writeln("SQLException " + sqle.getMessage());
      if (con!=null) {
        try { if (!con.isClosed()) con.close("CategoryList"); } catch (SQLException ignore) { }
      }
      if (DebugFile.trace) DebugFile.decIdent();
      throw new PortletException("SQLException " + sqle.getMessage(), sqle);
    }

    if (DebugFile.trace) DebugFile.writeln(String.valueOf(iCatCount) + " categories and " + String.valueOf(iImgCount) + " images found");

    StringBuffer oXML = new StringBuffer(8192);

    oXML.append("<?xml version=\"1.0\" encoding=\"UTF-8\"?>\n<?xml-stylesheet type=\"text/xsl\"?>\n<categories count=\"" + String.valueOf(iCatCount) + "\">\n");

    Category oCurrentCat = new Category();

    for (int c=0; c<iCatCount; c++) {
      oXML.append("  <category>");
      oXML.append("<gu_category>"+dbs.getString(0,c)+"</gu_category><nm_category>"+dbs.getString(1,c)+"</nm_category><tr_category><![CDATA["+dbs.getStringNull(2,c,"")+"]]></tr_category><de_category><![CDATA["+dbs.getStringNull(3,c,"")+"]]></de_category>");

      oXML.append("<images>");

      for (int i=0; i<iImgCount; i++) {
        int iCompare = dbs.getString(0,c).compareTo(img.getString(0,i));

        if (iCompare>0)
          break;
        else if (iCompare==0) {
          oXML.append("<image><gu_image>"+img.getString(1,i)+"</gu_image>");

          oCurrentCat.replace(DB.gu_category, dbs.getString(0,c));

          try {
            oXML.append("<src_image>"+sWrkArGet+"/"+sWorkAreaId+"/apps/Shop/"+oCurrentCat.getPath(con)+"/"+img.getStringNull(3,i,"")+"</src_image>");
          }
          catch (SQLException sqle) {
            if (DebugFile.trace) DebugFile.writeln("SQLException at Category.getPath(" + dbs.getString(0,c) + ") " + sqle.getMessage());
            oXML.append("<src_image></src_image>");
          }

          oXML.append("<nm_image><![CDATA["+img.getStringNull(3,i,"")+"]]></nm_image>");
          if (img.isNull(4,i)) oXML.append("<dm_width></dm_width>"); else oXML.append("<dm_width>" + img.get(4,i).toString() + "</dm_width>");
          if (img.isNull(5,i)) oXML.append("<dm_height></dm_height>"); else oXML.append("<dm_height>" + img.get(5,i).toString() + "</dm_height>");
          oXML.append("<tl_image>" + img.getStringNull(6,i,"") + "</tl_image></image>");
        }
      } // next (i)
      oXML.append("</images></category>\n");
    } // next (c)

    try {
      con.close("CategoryList");
      con = null;
    }
    catch (SQLException sqle) {
      if (DebugFile.trace) DebugFile.writeln("SQLException " + sqle.getMessage());
    }

    oXML.append("</categories>");

    try {
      if (DebugFile.trace) DebugFile.writeln("new ByteArrayInputStream(" + String.valueOf(oXML.length()) + ")");

      oInStream = new ByteArrayInputStream(oXML.toString().getBytes("UTF-8"));

      oOutStream = new ByteArrayOutputStream(40000);

      Properties oProps = new Properties();
      Enumeration oKeys = req.getPropertyNames();
      while (oKeys.hasMoreElements()) {
        String sKey = (String) oKeys.nextElement();
        oProps.setProperty(sKey, req.getProperty(sKey));
      } // wend

      StylesheetCache.transform (sTemplatePath, oInStream, oOutStream, oProps);

      sOutput = oOutStream.toString("UTF-8");

      oOutStream.close();

      oInStream.close();
      oInStream = null;
    }
    catch (TransformerConfigurationException tce) {
      if (DebugFile.trace) {
        DebugFile.writeln("TransformerConfigurationException " + tce.getMessageAndLocation());
        try {
          DebugFile.write("--------------------------------------------------------------------------------\n");
          DebugFile.write(FileSystem.readfile(sTemplatePath));
          DebugFile.write("\n--------------------------------------------------------------------------------\n");
          DebugFile.write(oXML.toString());
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
          DebugFile.write(oXML.toString());
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
      DebugFile.writeln("End CategoryList.render()");
    }

    return sOutput;
  } // render

  // --------------------------------------------------------------------------

  public void render(RenderRequest req, RenderResponse res)
    throws PortletException, IOException, IllegalStateException {
    res.getWriter().write(render(req,res.getCharacterEncoding()));
   }
}

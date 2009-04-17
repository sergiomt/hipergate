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
import com.knowgate.hipergate.Product;

/**
 * Product List for Microsites
 * @author Sergio Montoro Ten
 * @version 1.0
 */

public class ProductList extends GenericPortlet {

  public ProductList() { }

  public ProductList(HipergatePortletConfig oConfig)
    throws javax.portlet.PortletException {

    init(oConfig);
  }

  public String render(RenderRequest req, String sEncoding)
    throws PortletException, IOException, IllegalStateException {

    DBBind dbb;
    DBSubset dbs, img;
    JDCConnection con = null;
    ByteArrayInputStream oInStream;
    ByteArrayOutputStream oOutStream;
    String sOutput, sCategoryId, sTemplatePath, sLimit, sOffset, sWrkArGet, sWorkAreaId, sImagePath;
    int iOffset=0, iLimit=2147483647, iProdCount=0, iImgCount=0;

    if (DebugFile.trace) {
      DebugFile.writeln("Begin ProductList.render()");
      DebugFile.incIdent();
    }

    sOffset = req.getParameter("offset");
    sLimit = req.getParameter("limit");

    sCategoryId = (String) req.getAttribute("category");
    sTemplatePath = (String) req.getAttribute("template");

    sWorkAreaId = req.getProperty("workarea");
    sWrkArGet = req.getProperty("workareasget");

    if (DebugFile.trace) {
      DebugFile.writeln("template=" + sTemplatePath);
      DebugFile.writeln("category=" + sCategoryId);
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

      dbs = new DBSubset (DB.k_products + " p," + DB.k_x_cat_objs + " x",
                          "p." + DB.gu_product + ",p." + DB.nm_product + ",p." + DB.de_product +
                          ",p." + DB.pr_list + ",p." + DB.pr_sale + ",p." + DB.id_currency +
                          ",p." + DB.pct_tax_rate + ",p." + DB.is_tax_included +
                          ",p." + DB.dt_start + ",p." + DB.dt_end + ",p." + DB.tag_product + ",p." + DB.id_ref,
                          "p." + DB.gu_product + "=x." + DB.gu_object + " AND x." + DB.id_class + "=15 AND x." + DB.gu_category + "=? ORDER BY x." + DB.od_position, 20);

      con = dbb.getConnection("ProductList");

      if (null!=sLimit) dbs.setMaxRows(iLimit);

      if (sOffset==null)
        iProdCount = dbs.load(con, new Object[]{sCategoryId});
      else
        iProdCount = dbs.load(con, new Object[]{sCategoryId}, iOffset);

    }
    catch (SQLException sqle) {
      if (DebugFile.trace) DebugFile.writeln("SQLException " + sqle.getMessage());
      if (con!=null) {
        try { if (!con.isClosed()) con.close("ProductList"); } catch (SQLException ignore) { }
      }
      if (DebugFile.trace) DebugFile.decIdent();
      throw new PortletException("SQLException " + sqle.getMessage(), sqle);
    }

    if (DebugFile.trace) DebugFile.writeln(String.valueOf(iProdCount) + " products found");

    StringBuffer oXML = new StringBuffer(8192);

    oXML.append("<?xml version=\"1.0\" encoding=\"UTF-8\"?>\n<?xml-stylesheet type=\"text/xsl\"?>\n<products count=\"" + String.valueOf(iProdCount) + "\">\n");

    Product oCurrentProd = new Product();

    for (int c=0; c<iProdCount; c++) {
      oXML.append("  <product>");
      oXML.append("<gu_product>"+dbs.getString(0,c)+"</gu_product><nm_product>"+dbs.getString(1,c)+"</nm_product><tr_product><![CDATA["+dbs.getStringNull(2,c,"")+"]]></tr_product><de_product><![CDATA["+dbs.getStringNull(3,c,"")+"]]></de_product>");

      oCurrentProd.replace(DB.gu_product, dbs.getString(0,c));

      oXML.append("<images>");

      try {
        img = oCurrentProd.getImages(con);
        iImgCount = img.getRowCount();

        for (int i=0; i<iImgCount; i++) {
          oXML.append("<image tp=\"" + img.getString(DB.tp_image,i) + "\"><gu_image>"+img.getString(DB.gu_image,i)+"</gu_image>");

          sImagePath = img.getString(DB.path_image,i);

          oXML.append("<src_image><![CDATA["+sWrkArGet+"/"+sWorkAreaId+"/apps/Shop/"+sImagePath.substring(sImagePath.indexOf(sWorkAreaId)+43)+"]]></src_image>");

          oXML.append("<nm_image><![CDATA["+img.getStringNull(DB.nm_image,i,"")+"]]></nm_image>");
          if (img.isNull(DB.dm_width,i)) oXML.append("<dm_width></dm_width>"); else oXML.append("<dm_width>" + img.get(DB.dm_width,i).toString() + "</dm_width>");
          if (img.isNull(DB.dm_height,i)) oXML.append("<dm_height></dm_height>"); else oXML.append("<dm_height>" + img.get(DB.dm_height,i).toString() + "</dm_height>");
          oXML.append("<tl_image>" + img.getStringNull(DB.tl_image,i,"") + "</tl_image></image>");
        } // next (i)
      }
      catch (SQLException sqle) { }
      catch (NullPointerException npe) { }

      oXML.append("</images></product>\n");
    } // next (c)

    try {
      con.close("ProductList");
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
      DebugFile.writeln("End ProductList.render()");
    }
    return sOutput;
  } // render

  // --------------------------------------------------------------------------

  public void render(RenderRequest req, RenderResponse res)
    throws PortletException, IOException, IllegalStateException {
    res.getWriter().write(render(req,res.getCharacterEncoding()));
    }
}

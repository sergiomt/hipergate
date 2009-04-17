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
package com.knowgate.projtrack;

import java.io.IOException;
import java.io.FileNotFoundException;
import java.io.UnsupportedEncodingException;

import javax.xml.transform.TransformerException;
import javax.xml.transform.TransformerConfigurationException;

import java.util.Date;

import java.sql.SQLException;

import com.knowgate.jdc.JDCConnection;
import com.knowgate.dataobjs.DB;
import com.knowgate.dataobjs.DBPersist;
import com.knowgate.dataobjs.DBCommand;
import com.knowgate.dataxslt.StylesheetCache;
import com.knowgate.misc.Gadgets;

public class ProjectSnapshot {

  private Project   oProjct;
  private DBPersist oRecord;

  /**
   * Create an empty Project Snapshot
   */
  public ProjectSnapshot() {
  	oProjct = new Project();
  	oRecord = new DBPersist(DB.k_project_snapshots, "ProjectSnapshot");
  }

  /**
   * Create empty Snapshot for a given Project
   */

  public ProjectSnapshot(JDCConnection oConn, Project oProj) throws SQLException {
  	oProjct = oProj;
  	oRecord = new DBPersist(DB.k_project_snapshots, "ProjectSnapshot");
	oRecord.load(oConn, new Object[]{oProj.getString(DB.gu_project)});
  }

  public void setProject (String sGuProject) {
    oRecord.put(DB.gu_project, sGuProject);
  }

  public String getProject () {
    return oRecord.getString(DB.gu_project);
  }

  public void setTitle (String sTlSnapshot) {
    oRecord.put(DB.tl_snapshot, sTlSnapshot);
  }

  public String getTitle () {
    return oRecord.getString(DB.tl_snapshot);
  }

  public void setWriter (String sGuWriter) {
    oRecord.put(DB.gu_writer, sGuWriter);
  }

  public String getWriter () {
    return oRecord.getString(DB.gu_writer);
  }

  public void setData (String sXmlData) {
    oRecord.put(DB.tx_snapshot, sXmlData);
  }
  
  public boolean load (JDCConnection oConn, String sGuSnapshot) throws SQLException {
    boolean bExists = oRecord.load(oConn, new Object[]{sGuSnapshot});
    if (bExists) oProjct.load(oConn, new Object[]{oRecord.getString(DB.gu_project)});
    return bExists;
  }

  public void store (JDCConnection oConn) throws SQLException {
 
  	if (!oRecord.containsKey(DB.gu_snapshot)) oRecord.put(DB.gu_snapshot, Gadgets.generateUUID());
	if (!oRecord.containsKey(DB.tl_snapshot)) {
	  String sNmProject = DBCommand.queryStr(oConn, "SELECT "+DB.nm_project+" FROM "+DB.k_projects+" WHERE "+DB.gu_project+"='"+oRecord.getStringNull(DB.gu_project,"")+"'");
	  oRecord.put(DB.tl_snapshot, sNmProject+" "+new Date().toString());
	}
		
    oRecord.store(oConn);
  }

  public String toXML() {
  	return oRecord.getStringNull(DB.tx_snapshot,"<ProjectSnapshot/>");
  }

  /**
   * Export this ProjectSnapshot as a GanttProject .gan file
   * @since 5.0
   */
  public String toGantt()
  	throws IOException, FileNotFoundException, UnsupportedEncodingException,
           NullPointerException, TransformerException, TransformerConfigurationException {
    return StylesheetCache.transform(getClass().getResourceAsStream("GanttTemplate.xsl"), "<?xml version=\"1.0\" encoding=\"UTF-8\"?>\n"+toXML(), null);
  }

  // **********************************************************
  // Public Constants

  public static final short ClassId = 86;
  
}

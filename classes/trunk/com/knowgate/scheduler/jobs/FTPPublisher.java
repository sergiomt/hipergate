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

package com.knowgate.scheduler.jobs;

import java.io.IOException;

import com.knowgate.debug.DebugFile;
import com.knowgate.dataobjs.DB;
import com.knowgate.scheduler.Atom;
import com.knowgate.scheduler.Job;
import com.knowgate.dataxslt.FastStreamReplacer;
import com.knowgate.dfs.FileSystem;

/**
 * <p>Publishes Files via FTP</p>
 * @author Sergio Montoro Ten
 * @version 1.0
 */

public class FTPPublisher extends Job {

  // A reference to the replacer class witch maps tags of the form {#Section.Field}
  // to their corresponding database fields.
  private FastStreamReplacer oReplacer;

  private FileSystem oFileSys;

  public FTPPublisher() {
    oReplacer = new FastStreamReplacer();
    oFileSys = new FileSystem();
  }

  // ---------------------------------------------------------------------------

  /**
   * <p>Process PageSet pointed by Atom and sends transformed document throught FTP</p>
   * <p>Base workareas path is taken from "workareasput" property of hipergate.cnf<p>
   * @param oAtm Atom holding a reference to PageSet instance to be dumped<br>
   * Atom must have the following parameters set:<br>
   * <table border=1 cellpadding=4>
   * <tr><td>gu_workarea</td><td>GUID of WorkArea owner of document to be sent</td></tr>
   * <tr><td>gu_pageset</td><td>GUID of PageSet to be sent</td></tr>
   * <tr><td>nm_pageset</td><td>Name of PageSet document instance to be sent</td></tr>
   * <tr><td>tx_nickname</td><td>FTP User Nickname for login</td></tr>
   * <tr><td>tx_pwd</td><td>FTP User Password for login</td></tr>
   * <tr><td>nm_server</td><td>FTP server name or IP address</td></tr>
   * <tr><td>path</td><td>FTP target path</td></tr>
   * <tr><td>bo_mkpath</td><td>"1" if path must be created at target server</td></tr>
   * <tr><td>nm_file</td><td>Target file name for nm_pageset</td></tr>
   * </table>
   * @return String containing the final pos-processed document
   * @throws IOException
   */

  // ---------------------------------------------------------------------------

  public void free() {}

  public Object process(Atom oAtm) throws IOException {

    String sPathHTML;     // Full Path to Document Template File
    char cBuffer[];       // Internal Buffer for Document Template File Data
    Object oReplaced;     // Document Template File Data after FastStreamReplacer processing

    final String sSep = System.getProperty("file.separator"); // Alias for file.separator
    final String Yes = "1";

    if (DebugFile.trace) {
      DebugFile.writeln("Begin FTPPublisher.process([Job:" + getStringNull(DB.gu_job,"") + ", Atom:" + String.valueOf(oAtm.getInt(DB.pg_atom)) + "])");
      DebugFile.incIdent();
    }


    // *************************************************
    // Compose the full path to document template file

    // First get the storage base path from hipergate.cnf
    sPathHTML = getProperty("workareasput");
    if (!sPathHTML.endsWith(sSep)) sPathHTML += sSep;

    // Concatenate PageSet workarea guid and subpath to Mailwire application directory
    sPathHTML += getParameter("gu_workarea") + sSep + "apps" + sSep + "Mailwire" + sSep + "html" + sSep + getParameter("gu_pageset") + sSep;

    // Concatenate PageSet Name
    sPathHTML += getParameter("nm_pageset").replace(' ','_') + ".html";

    if (DebugFile.trace) DebugFile.writeln("PathHTML = " + sPathHTML);

    // *************************************************
    // Call FastStreamReplacer for {#Section.Field} tags

    oReplaced = oReplacer.replace(sPathHTML, oAtm.getItemMap());


    // **************************************
    // Send throught final replaced file data

    oFileSys.user(getParameter("tx_nickname"));
    oFileSys.password(getParameter("tx_pwd"));

    try {

      if (Yes.equals(getParameter("bo_path")))
        oFileSys.mkdirs("ftp://" + getParameter("nm_server") + "/" + getParameter("path"));

        oFileSys.copy( "file://" + sPathHTML,
                       "ftp://" + getParameter("nm_server") + "/" + getParameter("path") + "/" + getParameter("nm_file"));

    } catch (java.lang.Exception e) {
      throw new IOException(e.getMessage());
    }

    // Decrement de count of atoms peding of processing at this job
    iPendingAtoms--;

    if (DebugFile.trace) {
      DebugFile.writeln("End FTPPublisher.process([Job:" + getStringNull(DB.gu_job,"") + ", Atom:" + String.valueOf(oAtm.getInt(DB.pg_atom)) + "])");
      DebugFile.decIdent();
    }

    return oReplaced;
  } // process

} // FTPPublisher

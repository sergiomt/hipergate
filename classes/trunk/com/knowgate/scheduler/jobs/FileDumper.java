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

import java.lang.ref.SoftReference;

import java.io.IOException;
import java.io.FileReader;
import java.io.FileWriter;
import java.io.File;

import com.knowgate.debug.DebugFile;
import com.knowgate.dataobjs.DB;
import com.knowgate.scheduler.Atom;
import com.knowgate.scheduler.Job;
import com.knowgate.dataxslt.FastStreamReplacer;

/**
 * <p>Simple processor for PageSets with disk output</p>
 * @author Sergio Montoro Ten
 * @version 1.0
 */

public class FileDumper extends Job {

  // This flag is set if the first Job execution finds replacements of the form
  // {#Section.Field} witch is data retrived from the database and inserted
  // dynamically into the document final template.
  // If the execution of this job for the first Atom find no tags of the form
  // {#Section.Field} then the replacement subroutine can be skipped in next
  // execution saving CPU cycles.
  private boolean bHasReplacements;

  // This is a soft reference to a String holding the base document template
  // if virtual memory runs low the garbage collector can discard the soft
  // reference that would be reloaded from disk later upon the next atom processing
  private SoftReference oFileStr;

  // A reference to the replacer class witch maps tags of the form {#Section.Field}
  // to their corresponding database fields.
  private FastStreamReplacer oReplacer;

  // ---------------------------------------------------------------------------

  public FileDumper() {
    bHasReplacements = true;
    oFileStr = null;
    oReplacer = new FastStreamReplacer();
  }

  // ---------------------------------------------------------------------------

  public void free() {}

  // ---------------------------------------------------------------------------

  /**
   * <p>Process PageSet pointed by Atom and dumps result to disk</p>
   * <p>Base workareas path is taken from "workareasput" property of hipergate.cnf<p>
   * <p>Processed documents are saved under /web/workareas/apps/Mailwire/html/<i>gu_pageset</i>/</p>
   * @param oAtm Atom holding a reference to PageSet instance to be dumped<br>
   * Atom must have the following parameters set:<br>
   * <table border=1 cellpadding=4>
   * <tr><td>gu_workarea</td><td>GUID of WorkArea owner of document to be saved</td></tr>
   * <tr><td>gu_pageset</td><td>GUID of PageSet to be saved</td></tr>
   * <tr><td>nm_pageset</td><td>Name of PageSet document instance to be saved</td></tr>
   * </table>
   * @return String containing the final pos-processed document
   * @throws IOException
   */

  public Object process(Atom oAtm) throws IOException {

    File oFile;           // Document Template File
    FileReader oFileRead; // Document Template Reader
    String sPathHTML;     // Full Path to Document Template File
    char cBuffer[];       // Internal Buffer for Document Template File Data
    Object oReplaced;     // Document Template File Data after FastStreamReplacer processing

    final String sSep = System.getProperty("file.separator"); // Alias for file.separator

    if (DebugFile.trace) {
      DebugFile.writeln("Begin FileDumper.process([Job:" + getStringNull(DB.gu_job,"") + ", Atom:" + String.valueOf(oAtm.getInt(DB.pg_atom)) + "])");
      DebugFile.incIdent();
    }

    if (bHasReplacements) { // Initially the document is assumed to have tags to replace

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

      // Count number of replacements done and update bHasReplacements flag accordingly
      bHasReplacements = (oReplacer.lastReplacements()>0);
    }

    else {

      oReplaced = null;

      if (null!=oFileStr)
        oReplaced = oFileStr.get();

      if (null==oReplaced) {

        // If document template has no database replacement tags
        // then just cache the document template into a SoftReference String

        // Compose the full path to document template file
        sPathHTML = getProperty("workareasput");
        if (!sPathHTML.endsWith(sSep)) sPathHTML += sSep;
        sPathHTML += getParameter("gu_workarea") + sSep + "apps" + sSep + "Mailwire" + sSep + "html" + sSep + getParameter("gu_pageset") + sSep + getParameter("nm_pageset").replace(' ','_') + ".html";

        if (DebugFile.trace) DebugFile.writeln("PathHTML = " + sPathHTML);

        // ***************************
        // Read document template file

        oFile = new File(sPathHTML);

        cBuffer = new char[new Long(oFile.length()).intValue()];

        oFileRead = new FileReader(oFile);
        oFileRead.read(cBuffer);
        oFileRead.close();

        if (DebugFile.trace) DebugFile.writeln(String.valueOf(cBuffer.length) + " characters readed");

        // *********************************************************
        // Assign SoftReference to File cached in-memory as a String

        oReplaced = new String(cBuffer);
        oFileStr = new SoftReference(oReplaced);

      } // fi (oReplaced)

    } // fi (bHasReplacements)

    // ***********************************************
    // Write down to disk the final replaced file data

    // Compose job directory path
    String sPathJobDir = getProperty("storage");
    if (!sPathJobDir.endsWith(sSep)) sPathJobDir += sSep;
    sPathJobDir += "jobs" + sSep + getParameter("gu_workarea") + sSep + getString(DB.gu_job) + sSep;

    // Write final file data for each atom processed
    FileWriter oFileWrite = new FileWriter(sPathJobDir + getString(DB.gu_job) + "_" + String.valueOf(oAtm.getInt(DB.pg_atom)) + ".html", true);
    oFileWrite.write((String) oReplaced);
    oFileWrite.close();

    // Decrement de count of atoms peding of processing at this job
    iPendingAtoms--;

    if (DebugFile.trace) {
      DebugFile.writeln("End FileDumper.process([Job:" + getStringNull(DB.gu_job,"") + ", Atom:" + String.valueOf(oAtm.getInt(DB.pg_atom)) + "])");
      DebugFile.decIdent();
    }

    return oReplaced;
  } // process

} // FileDumper

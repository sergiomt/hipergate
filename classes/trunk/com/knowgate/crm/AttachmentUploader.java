/*
  Copyright (C) 2006  Know Gate S.L. All rights reserved.
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

package com.knowgate.crm;

import java.io.File;
import java.io.IOException;
import java.sql.PreparedStatement;
import java.sql.ResultSet;

import com.knowgate.debug.DebugFile;
import com.knowgate.debug.StackTraceUtil;
import com.knowgate.jdc.JDCConnection;
import com.knowgate.dataobjs.DB;
import com.knowgate.dataobjs.DBBind;
import com.knowgate.crm.Contact;

/**
 * Scan a directory structure and attach files to Contacts
 * @author Sergio Montoro Ten
 * @version 3.0
 */
public class AttachmentUploader {

  private AttachmentUploader() { }

  // ---------------------------------------------------------------------------

  public static void main(String[] argv) {

    if (argv.length<3 || argv.length>4) {
      System.out.println("");
      System.out.println("Usage:\n");
      System.out.println("AttachmentUploader profile_name base_path writer_guid delete_files");
      System.out.println("where");
      System.out.println("profile_name is the name without extension of a properties files for hipergate such as hipergate.cnf");
      System.out.println("base_path is a directory path. For example /tmp/upload/");
      System.out.println("writer_guid is a GUID of the user attaching the files");
      System.out.println("delete_files is true or false. The default value is true.");
    }

    File oBase = new File(argv[1]);
    if (!oBase.exists()) {
      System.out.println("Directory "+argv[1]+" does not exist");
    } else if (!oBase.isDirectory()) {
      System.out.println(argv[1]+" is not a directory");
    } else {
      boolean bDeleteFiles;
      if (argv.length==4)
        bDeleteFiles = new Boolean(argv[3]).booleanValue();
      else
        bDeleteFiles = true;

      try {
        File[] aDirs = oBase.listFiles();
        if (aDirs!=null) {
          DBBind oDbbd = new DBBind(argv[0]);
          Contact oCont = new Contact();
          JDCConnection oConn = oDbbd.getConnection("AttachmentUploader");
          PreparedStatement oStmt = oConn.prepareStatement("SELECT "+DB.gu_contact+","+DB.gu_workarea+" FROM "+DB.k_contacts+" WHERE "+DB.gu_contact+"=? OR "+DB.id_ref+"=? OR "+DB.sn_passport+"=?",
                                                           ResultSet.TYPE_FORWARD_ONLY, ResultSet.CONCUR_READ_ONLY);
          oConn.setAutoCommit(false);
          int nDirs = aDirs.length;
          for (int d=0; d<nDirs; d++) {
            if (aDirs[d].isDirectory()) {
              String sDirName = aDirs[d].getName();
              oStmt.setString(1, sDirName);
              oStmt.setString(2, sDirName);
              oStmt.setString(3, sDirName);
              ResultSet oRSet = oStmt.executeQuery();
              if (oRSet.next()) {
                oCont.replace(DB.gu_contact , oRSet.getString(1));
                oCont.replace(DB.gu_workarea, oRSet.getString(2));
                oRSet.close();
                oCont.addAttachments(oConn, argv[2], aDirs[d].getAbsolutePath(), true);
                oConn.commit();
                aDirs[d].delete();
              } else {
                DebugFile.writeln("AttachmentUploader.main() SQLException: No data found for Contact "+sDirName);
                oRSet.close();
              } // fi (next)
            } // fi (isDirectory)
          } // next
          oStmt.close();
          oConn.close("AttachmentUploader");
          oDbbd.close();
        } // fi (aDirs)
      } catch (Exception xcpt) {
        if (DebugFile.trace) {
          DebugFile.writeln(xcpt.getClass().getName()+" "+xcpt.getMessage());
          try { DebugFile.writeln(StackTraceUtil.getStackTrace(xcpt)); } catch (IOException ignore) {}
        }
        System.out.println(xcpt.getClass().getName()+" "+xcpt.getMessage());
      }
    } // fi
  } // main
}

/*
  Copyright (C) 2004  Know Gate S.L. All rights reserved.
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

package com.knowgate.hipermail;

import java.io.OutputStream;
import java.io.IOException;
import java.io.File;

import java.sql.Statement;
import java.sql.ResultSet;
import java.sql.SQLException;

import javax.mail.MessagingException;
import javax.mail.Multipart;
import javax.mail.BodyPart;
import javax.mail.Part;

import javax.mail.internet.MimePart;

import java.util.Vector;

import com.knowgate.dataobjs.DB;
import com.knowgate.debug.DebugFile;

/**
 * @author Sergio Montoro Ten
 * @version 1.0
 */

public class DBMimeMultipart extends Multipart {
  private Vector<Part> aParts = new Vector<Part>();
  private Part oParent;

  public DBMimeMultipart(Part oMessage) {
    oParent = oMessage;
  }

  // ---------------------------------------------------------------------------

  public Part getParent() {
    return oParent;
  }

  // ---------------------------------------------------------------------------

  public void addBodyPart(MimePart part)
    throws MessagingException {
    aParts.add(part);
  }

  // ---------------------------------------------------------------------------

  public int getCount() {
    return aParts.size();
  }

  // ---------------------------------------------------------------------------

  public BodyPart getBodyPart(int index)
    throws MessagingException {

	if (DebugFile.trace) {
	  DebugFile.writeln("Begin DBMimeMultipart.getBodyPart("+String.valueOf(index)+")");
	  DebugFile.incIdent();
	}

	BodyPart oRetVal = null;
    try {
      oRetVal = (BodyPart) aParts.get(index);
    }
    catch (ArrayIndexOutOfBoundsException aiob) {
      if (DebugFile.trace) {
    	DebugFile.writeln("Invalid message part index");
        DebugFile.decIdent();
      }
      throw new MessagingException("Invalid message part index", aiob);
    }
    
    if (DebugFile.trace) {
      DebugFile.decIdent();
      DebugFile.writeln("End DBMimeMultipart.getBodyPart() :" + oRetVal);
    }

    return oRetVal;
  }

  // ---------------------------------------------------------------------------

  /**
   * <p>Get body part given its Content-Id</p>
   * @param cid String Content-Id
   * @return BodyPart or <b>null</b> if no body part with such Content-Id is found
   * @throws MessagingException
   */
  public BodyPart getBodyPart(String cid)
    throws MessagingException {
    Object oPart = null;

    if (DebugFile.trace) {
      DebugFile.writeln("Begin DBMimeMultipart.getBodyPart("+cid+")");
      DebugFile.incIdent();
    }

    if (cid!=null) {
      final int iParts = aParts.size();
      if (DebugFile.trace) DebugFile.writeln("MimeMultiPart has "+String.valueOf(iParts)+" parts");
      for (int p=0; p<iParts; p++) {
        oPart = aParts.get(p);
        if (DebugFile.trace) DebugFile.writeln("Checking part "+String.valueOf(p)+" with Content-Id "+((MimePart)oPart).getContentID());
        if (cid.equals(((MimePart)oPart).getContentID()))
          break;
        else
          oPart = null;
      } // next
    } // fi (cid != null)

    if (DebugFile.trace) {
      DebugFile.decIdent();
      DebugFile.writeln("End DBMimeMultipart.getBodyPart() :" + oPart);
    }

    return (BodyPart) oPart;
  } // getBodyPart

  // ---------------------------------------------------------------------------

  public void removeBodyPart (int iPart)
    throws MessagingException, ArrayIndexOutOfBoundsException {

    if (DebugFile.trace) {
      DebugFile.writeln("Begin DBMimeMultipart.removeBodyPart("+String.valueOf(iPart)+")");
      DebugFile.incIdent();
    }

    DBMimeMessage oMsg = (DBMimeMessage) getParent();
    DBFolder oFldr = ((DBFolder)oMsg.getFolder());
    Statement oStmt = null;
    ResultSet oRSet = null;
    String sDisposition = null, sFileName = null;
    boolean bFound;

    try {
      oStmt = oFldr.getConnection().createStatement(ResultSet.TYPE_FORWARD_ONLY, ResultSet.CONCUR_READ_ONLY);

      if (DebugFile.trace) DebugFile.writeln("Statement.executeQuery(SELECT " + DB.id_disposition + "," + DB.file_name + " FROM " + DB.k_mime_parts + " WHERE " + DB.gu_mimemsg + "='" + oMsg.getMessageGuid() + "' AND " + DB.id_part + "=" + String.valueOf(iPart)+ ")");

      oRSet = oStmt.executeQuery("SELECT " + DB.id_disposition + "," + DB.file_name + " FROM " + DB.k_mime_parts + " WHERE " + DB.gu_mimemsg + "='" + oMsg.getMessageGuid() + "' AND " + DB.id_part + "=" + String.valueOf(iPart));
      bFound = oRSet.next();

      if (bFound) {
        sDisposition = oRSet.getString(1);
        if (oRSet.wasNull()) sDisposition = "inline";
        sFileName = oRSet.getString(2);
      }

      oRSet.close();
      oRSet = null;
      oStmt.close();
      oStmt = null;

      if (!bFound) {
        if (DebugFile.trace) DebugFile.decIdent();
        throw new MessagingException("Part not found");
      }
      if (!sDisposition.equals("reference") && !sDisposition.equals("pointer")) {
        if (DebugFile.trace) DebugFile.decIdent();
        throw new MessagingException("Only parts with reference or pointer disposition can be removed from a message");
      }
      else {
        if (sDisposition.equals("reference")) {
          try {
          File oRef = new File(sFileName);
          if (oRef.exists())
            oRef.delete();
          }
          catch (SecurityException se) {
            if (DebugFile.trace) DebugFile.writeln("SecurityException " + sFileName + " " + se.getMessage());
            if (DebugFile.trace) DebugFile.decIdent();
            throw new MessagingException("SecurityException " + sFileName + " " + se.getMessage(), se);
          }
        } // fi (reference)

        oStmt = oFldr.getConnection().createStatement();
        if (DebugFile.trace) DebugFile.writeln("Statement.executeUpdate(DELETE FROM " + DB.k_mime_parts + " WHERE " + DB.gu_mimemsg + "='" + oMsg.getMessageGuid() + "' AND " + DB.id_part + "=" + String.valueOf(iPart)+")");
        oStmt.executeUpdate("DELETE FROM " + DB.k_mime_parts + " WHERE " + DB.gu_mimemsg + "='" + oMsg.getMessageGuid() + "' AND " + DB.id_part + "=" + String.valueOf(iPart));
        oStmt.close();
        oStmt = null;
        oFldr.getConnection().commit();
      }
    }
    catch (SQLException sqle) {
      if (oRSet!=null) { try { oRSet.close(); } catch (Exception ignore) {} }
      if (oStmt!=null) { try { oStmt.close(); } catch (Exception ignore) {} }
      try { oFldr.getConnection().rollback(); } catch (Exception ignore) {}
      if (DebugFile.trace) DebugFile.decIdent();
      throw new MessagingException (sqle.getMessage(), sqle);
    }

    if (DebugFile.trace) {
      DebugFile.decIdent();
      DebugFile.writeln("End DBMimeMultipart.removeBodyPart()");
    }
  } // removeBodyPart

  // ---------------------------------------------------------------------------

  public void writeTo(OutputStream os)
    throws IOException, MessagingException {
    throw new UnsupportedOperationException("Method writeTo() not implemented for DBMimeMultipart");
  }

  // ---------------------------------------------------------------------------

}

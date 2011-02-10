/*
  Copyright (C) 2008  Know Gate S.L. All rights reserved.
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
package com.knowgate.marketing;

import java.io.File;
import java.io.FileNotFoundException;

import java.util.Date;
import java.util.ListIterator;

import java.sql.Statement;
import java.sql.CallableStatement;
import java.sql.SQLException;

import com.knowgate.jdc.JDCConnection;
import com.knowgate.debug.DebugFile;
import com.knowgate.acl.ACLDomain;
import com.knowgate.misc.Gadgets;
import com.knowgate.misc.Environment;
import com.knowgate.storage.Column;
import com.knowgate.dataobjs.DB;
import com.knowgate.dataobjs.DBBind;
import com.knowgate.dataobjs.DBCommand;
import com.knowgate.dataobjs.DBSubset;
import com.knowgate.dataobjs.DBPersist;
import com.knowgate.hipergate.Address;
import com.knowgate.hipergate.Product;
import com.knowgate.hipergate.ProductLocation;
import com.knowgate.workareas.FileSystemWorkArea;
import com.knowgate.marketing.ActivityAttachment;


/**
 * <p>Marketing Activity</p>
 * <p>Copyright: Copyright (c) KnowGate 2009</p>
 * @author Sergio Montoro Ten
 * @version 7.0
 */
 
public class Activity extends DBPersist {

  private Address oAddr;

  public Activity() {
    super(DB.k_activities,"Activity");
    oAddr = null;
  }
  
  /**
   * Create Activity and load fields from database.
   * @param oConn Database Connection
   * @param sGuActivity Activity GUID
   */
  public Activity(JDCConnection oConn, String sGuActivity) 
    throws SQLException {
    super(DB.k_activities, "Activity");
    load(oConn, sGuActivity);
  }

  /**
   * <p>Get address of Activity.</p>
   * Activity must has been previously loaded before trying to get its Address
   * @return Address
   */
  public Address getAddress() {
    return oAddr;
  }

  /**
   * @return Count of people from k_x_activity_audience which bo_confirmed status is CONFIRMED
   */

  public int getConfirmedAudienceCount(JDCConnection oConn) throws SQLException {
  	return DBCommand.queryCount(oConn, "*", DB.k_x_activity_audience, DB.gu_activity+"='"+getString(DB.gu_activity)+"' AND "+DB.bo_confirmed+"="+String.valueOf(ActivityAudience.CONFIRMED));
  }

  /**
   * @return Count of people from k_x_activity_audience which bo_confirmed status is NOTCONFIRMED
   */

  public int getNotConfirmedAudienceCount(JDCConnection oConn) throws SQLException {
  	return DBCommand.queryCount(oConn, "*", DB.k_x_activity_audience, DB.gu_activity+"='"+getString(DB.gu_activity)+"' AND "+DB.bo_confirmed+"="+String.valueOf(ActivityAudience.NOTCONFIRMED));
  }

  /**
   * @return Count of people from k_x_activity_audience which bo_confirmed status is REFUSED
   */
  public int getRefusedAudienceCount(JDCConnection oConn) throws SQLException {
  	return DBCommand.queryCount(oConn, "*", DB.k_x_activity_audience, DB.gu_activity+"='"+getString(DB.gu_activity)+"' AND "+DB.bo_confirmed+"="+String.valueOf(ActivityAudience.REFUSED));
  }

  /**
   * @return Total count of people from k_x_activity_audience for this Activity with any status
   */

  public int getTotalAudienceCount(JDCConnection oConn) throws SQLException {
  	return DBCommand.queryCount(oConn, "*", DB.k_x_activity_audience, DB.gu_activity+"='"+getString(DB.gu_activity)+"'");
  }

  public ActivityAudience[] getAudience(JDCConnection oConn) throws SQLException {
	ActivityAudience[] aAudience = null; 
	DBSubset oAudicence = new DBSubset (DB.k_x_activity_audience, DB.gu_contact, DB.gu_activity+"=?", 100);
	int iAudicence = oAudicence.load(oConn, new Object[]{getString(DB.gu_activity)});
	if (iAudicence>0) {
	  aAudience = new ActivityAudience[iAudicence];
	  for (int a=0; a<iAudicence; a++) {
		aAudience[a].load(oConn, new Object[]{getString(DB.gu_activity), oAudicence.getString(0,a)});
	  } // next
	} // fi
	return aAudience;
  } // getAudience

  public boolean load(JDCConnection oConn, Object[] PKVals) throws SQLException {
  	boolean bRetVal = super.load(oConn, PKVals);
  	if (bRetVal) {
  	  if (!isNull(DB.gu_address)) {  	  	
  	  	Object oActive = get(DB.bo_active);
  	  	oAddr = new Address(oConn, getString(DB.gu_address));
  	    putAll(oAddr.getItemMap());
  	    replace(DB.bo_active,oActive);
  	  }
  	}
	return bRetVal;
  }

  public boolean load(JDCConnection oConn, String sGuActivity) throws SQLException {
    return load(oConn, new Object[]{sGuActivity});
  }

  public boolean store(JDCConnection oConn) throws SQLException {
	boolean bRetVal;

	if (!AllVals.containsKey(DB.gu_activity)) {
	  put(DB.gu_activity, Gadgets.generateUUID());
	}  else {
	  replace(DB.dt_modified, new Date());
	}

	bRetVal = super.store(oConn);
	
	if (bRetVal) {
	  if (oAddr==null) oAddr = new Address();
	  boolean bHasAnyAddressValue = false;
	  ListIterator<Column> oIter = oAddr.getTable(oConn).getColumns().listIterator();
	  while (oIter.hasNext() && !bHasAnyAddressValue) {
	  	String sColunmName = oIter.next().getName();
	  	if (!sColunmName.equals(DB.gu_workarea))
	      bHasAnyAddressValue = AllVals.containsKey(sColunmName);
	  } // wend
	  if (bHasAnyAddressValue) {
	  	oAddr.putAll(getItemMap());
	  	oAddr.replace(DB.ix_address, 1);
	  	oAddr.replace(DB.bo_active, (short) 1);
	  	oAddr.store(oConn);
	  }
	}

	return bRetVal;
  } // store

  // ----------------------------------------------------------

  /**
   * <p>Delete Activity.</p>
   * The delete step by step is as follows:<br>
   * All Activity Attachments are deleted.<br>
   * Stored Procedure k_sp_del_activity is called
   * @param oConn Database Connection
   * @throws SQLException
   */

  public boolean delete(JDCConnection oConn) throws SQLException {

    DBSubset oAttachs = new DBSubset(DB.k_activity_attachs, DB.gu_product,
                                     DB.gu_activity + "='" + getString(DB.gu_activity) + "'" , 10);
    int iAttachs = oAttachs.load(oConn);
    Product oProd = new Product();
    for (int a=0;a<iAttachs; a++) {
      oProd.replace(DB.gu_product, oAttachs.getString(0,a));
      oProd.delete(oConn);
    } // next (a)
    oProd = null;
    oAttachs = null;

    if (oConn.getDataBaseProduct()==JDCConnection.DBMS_POSTGRESQL) {
      Statement oStmt = oConn.createStatement();
      oStmt.executeQuery("SELECT k_sp_del_activity ('"+getString(DB.gu_activity)+"')");
      oStmt.close();
    } else {
      CallableStatement oCall = oConn.prepareCall("{ call k_sp_del_activity ('"+getString(DB.gu_activity)+"') }");
	  oCall.execute();
	  oCall.close();
    }
    return true;
  } // delete

  // ----------------------------------------------------------

  /**
   * Add an Attachment to an Activity
   * @param oConn JDCConnection
   * @param sGuWriter String GUID of user (from k_users table) who is uploading the attachment
   * @param sDirPath String Physical path (directory) where file to be attached ir located
   * @param sFileName String Name of file to be attached
   * @param sDescription String File Description (up to 254 characters)
   * @param bDeleteOriginalFile boolean <b>true</b> if original file must be deleted after being attached
   * @return ActivityAttachment
   * @throws SQLException
   * @throws NullPointerException
   * @throws FileNotFoundException
   * @throws Exception
   * @since 5.5
   */
  public ActivityAttachment addAttachment(JDCConnection oConn, String sGuWriter,
                                          String sDirPath, String sFileName,
                                          String sDescription,
                                          boolean bDeleteOriginalFile)
    throws SQLException,NullPointerException,FileNotFoundException,Exception {

  if (DebugFile.trace) {
    DebugFile.writeln("Begin Activity.addAttachment([Connection],"+sGuWriter+","+
                      sDirPath+","+sFileName+","+sDescription+","+String.valueOf(bDeleteOriginalFile)+")" );
    DebugFile.incIdent();
  }

    Date dtNow = new Date();
    String sProfile;

    // Check that Contact is loaded
    if (isNull(DB.gu_activity) || isNull(DB.gu_workarea))
      throw new NullPointerException("Activity.addAttachment() Activity not loaded");

    if (null==sDirPath)
      throw new NullPointerException("Activity.addAttachment() File path may not be null");

    if (null==sFileName)
      throw new NullPointerException("Activity.addAttachment() File name may not be null");

    File oDir = new File(sDirPath);
    if (!oDir.isDirectory())
      throw new FileNotFoundException("Activity.addAttachment() "+sDirPath+" is not a directory");

    if (!oDir.exists())
      throw new FileNotFoundException("Activity.addAttachment() Directory "+sDirPath+" not found");

    File oFile = new File(Gadgets.chomp(sDirPath,File.separatorChar)+sFileName);
    if (!oFile.exists())
      throw new FileNotFoundException("Activity.addAttachment() File "+Gadgets.chomp(sDirPath,File.separatorChar)+sFileName+" not found");

    // Get Id. of Domain to which Contact belongs
    Integer iDom = ACLDomain.forWorkArea(oConn, getString(DB.gu_workarea));

    if (DebugFile.trace) DebugFile.writeln("id_domain="+iDom);

    String sCatPath = "apps/Marketing/"+getString(DB.gu_activity)+"/";

    if (DebugFile.trace) DebugFile.writeln("category path = "+sCatPath);

    if (null==oConn.getPool())
      sProfile = "hipergate";
    else
      sProfile = ((DBBind) oConn.getPool().getDatabaseBinding()).getProfileName();

    if (DebugFile.trace) DebugFile.writeln("profile = "+sProfile);

    FileSystemWorkArea oFileSys = new FileSystemWorkArea(Environment.getProfile(sProfile));
    oFileSys.mkstorpath(iDom.intValue(), getString(DB.gu_workarea), sCatPath);

    String sStorage = Environment.getProfilePath(sProfile, "storage");
    String sFileProtocol = Environment.getProfileVar(sProfile, "fileprotocol", "file://");
    String sFileServer = Environment.getProfileVar(sProfile, "fileserver", "localhost");

    String sWrkAHome = sStorage + "domains" + File.separator + iDom.toString() + File.separator + "workareas" + File.separator + getString(DB.gu_workarea) + File.separator;
    if (DebugFile.trace) DebugFile.writeln("workarea home = "+sWrkAHome);

    Product oProd = new Product();
    oProd.put(DB.nm_product,Gadgets.left(sFileName, 128));
    oProd.put(DB.gu_owner, sGuWriter);
    oProd.put(DB.dt_uploaded, dtNow);
    if (sDescription!=null) oProd.put(DB.de_product, Gadgets.left(sDescription,254));
    oProd.store(oConn);

    ProductLocation oLoca = new ProductLocation();
    oLoca.put(DB.gu_owner, sGuWriter);
    oLoca.put(DB.gu_product, oProd.get(DB.gu_product));
    oLoca.put(DB.dt_uploaded, dtNow);
    oLoca.setPath  (sFileProtocol, sFileServer, sWrkAHome + sCatPath, sFileName, sFileName);
    oLoca.setLength(oFile.length());
    oLoca.replace(DB.id_cont_type, oLoca.getContainerType());
    oLoca.store(oConn);

    if (sFileProtocol.equalsIgnoreCase("ftp://"))
      oLoca.upload(oConn, oFileSys, "file://" + sDirPath, sFileName, "ftp://" + sFileServer + sWrkAHome + sCatPath, sFileName);
    else
      oLoca.upload(oConn, oFileSys, "file://" + sDirPath, sFileName, sFileProtocol + sWrkAHome + sCatPath, sFileName);

    ActivityAttachment oAttach = new ActivityAttachment();
    oAttach.put(DB.gu_activity, getString(DB.gu_activity));
    oAttach.put(DB.gu_product, oProd.getString(DB.gu_product));
    oAttach.put(DB.gu_location, oLoca.getString(DB.gu_location));
    oAttach.put(DB.gu_writer, sGuWriter);
    oAttach.store(oConn);

    if (bDeleteOriginalFile) {
      if (DebugFile.trace) DebugFile.writeln("deleting file "+oFile.getAbsolutePath());
      oFile.delete();
      if (DebugFile.trace) DebugFile.writeln("deleting file "+sFileName+" deleted");
    }

    if (DebugFile.trace) {
      DebugFile.decIdent();
      DebugFile.writeln("End Activity.addAttachment() : " + String.valueOf(oAttach.getInt(DB.pg_product)));
    }

    return oAttach;
  } // addAttachment

  // ----------------------------------------------------------

  /**
   * Add an Attachment to an Activity
   * @param oConn JDCConnection
   * @param sGuWriter String GUID of user (from k_users table) who is uploading the attachment
   * @param sDirPath String Physical path (directory) where file to be attached ir located
   * @param sFileName String Name of file to be attached
   * @param bDeleteOriginalFile boolean <b>true</b> if original file must be deleted after being attached
   * @return Attachment
   * @throws SQLException
   * @throws NullPointerException
   * @throws FileNotFoundException
   * @throws Exception
   * @since 5.5
   */
  public ActivityAttachment addAttachment(JDCConnection oConn, String sGuWriter,
                                          String sDirPath, String sFileName,
                                          boolean bDeleteOriginalFile)
    throws SQLException,NullPointerException,FileNotFoundException,Exception {
    return addAttachment(oConn, sGuWriter, sDirPath, sFileName, null, bDeleteOriginalFile);
  }

  // ----------------------------------------------------------

  /**
   * Remove attachment
   * @param oConn JDCConnection
   * @param iPgAttachment int
   * @return boolean
   * @throws SQLException
   * @throws NullPointerException
   * @since 5.5
   */
  public boolean removeAttachment(JDCConnection oConn, int iPgAttachment)
    throws SQLException {
    ActivityAttachment oAttach = new ActivityAttachment();
    if (oAttach.load(oConn, new Object[]{get(DB.gu_activity),new Integer(iPgAttachment)}))
      return oAttach.delete(oConn);
    else
      return false;
  } // removeAttachment

  // ----------------------------------------------------------
  
  public static final short ClassId = (short) 310;

}

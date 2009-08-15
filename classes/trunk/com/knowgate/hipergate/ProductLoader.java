/*
  Copyright (C) 2005  Know Gate S.L. All rights reserved.
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

package com.knowgate.hipergate;

import java.util.Date;
import java.util.Iterator;
import java.util.Map;
import java.util.Arrays;

import java.sql.Connection;
import java.sql.SQLException;
import java.sql.PreparedStatement;
import java.sql.ResultSet;
import java.sql.Timestamp;
import java.sql.Types;

import com.knowgate.debug.DebugFile;
import com.knowgate.dataobjs.DB;
import com.knowgate.misc.Gadgets;
import com.knowgate.hipergate.Product;
import com.knowgate.hipergate.datamodel.ColumnList;
import com.knowgate.hipergate.datamodel.ImportLoader;

/**
 * <p>Load Product data from a single source</p>
 * @author Sergio Montoro Ten
 * @version 1.0
 */
public class ProductLoader implements ImportLoader {

  private Object[] aValues;

  private PreparedStatement oProdUpdt, oFareUpdt, oLocaUpdt, oAttrUpdt,
      oKeysDlte, oAddrUpdt;
  private PreparedStatement oProdInsr, oFareInsr, oLocaInsr, oAttrInsr,
      oKeysInsr, oAddrInsr;
  private PreparedStatement oCatgDlte, oCatgInsr;
  private String sLastCategoryGuid, sLastCategoryName, sLastOwnGuid;

  // ---------------------------------------------------------------------------

  private void init() {
    aValues = new Object[ColumnNames.length];
    for (int c = aValues.length - 1; c >= 0; c--) aValues[c] = null;
    oProdUpdt = oFareUpdt = oLocaUpdt = oAttrUpdt = oAddrUpdt = null;
    oProdInsr = oFareInsr = oLocaInsr = oAttrInsr = oAddrInsr = null;
    sLastCategoryGuid = sLastCategoryName = sLastOwnGuid = "";
  }

  // ---------------------------------------------------------------------------

  public ProductLoader() {
    init();
  }

  // ---------------------------------------------------------------------------

  /**
   * Create ProductLoader and call prepare() on Connection
   * @param oConn Connection
   * @throws SQLException
   */
  public ProductLoader(Connection oConn) throws SQLException {
    init();
    prepare(oConn, null);
  }

  // ---------------------------------------------------------------------------

  /**
   * <p>Prepare statements for execution</p>
   * This method needs to be called only once if the default constructor was used.<br>
   * If ProductLoader(Connection) constructor was used, there is no need to call prepare()
   * and a SQLException will be raised if the attempt is made.<br>
   * It is neccesary to call close() always for prepared instances as a failure
   * to do so will leave open cursors on the database causing it eventually to stop.
   * @param oConn Connection Open JDBC database connection
   * @param oColList ColumnList This parameter is ignored
   * @throws SQLException
   */
  public void prepare(Connection oConn, ColumnList oColList) throws
      SQLException {

    if (DebugFile.trace) {
      DebugFile.writeln("Begin ProductLoader.prepare()");
      DebugFile.incIdent();
    }

    if (oProdUpdt != null || oFareUpdt != null || oAttrUpdt != null ||
        oAddrUpdt != null) {
      if (DebugFile.trace) DebugFile.decIdent();
      throw new SQLException("Either ProductLoader.prepare() has already been called or statements were not properly closed",
                             "HY010");
    }

    oProdUpdt = oConn.prepareStatement("UPDATE " + DB.k_products + " SET gu_owner=?,nm_product=?,id_status=?,is_compound=?,gu_blockedby=?,dt_modified=?,dt_uploaded=?,id_language=?,de_product=?,pr_list=?,pr_sale=?,pr_discount=?,pr_purchase=?,id_currency=?,pct_tax_rate=?,is_tax_included=?,dt_start=?,dt_end=?,tag_product=?,id_ref=?,gu_address=? WHERE gu_product=?");
    oProdInsr = oConn.prepareStatement("INSERT INTO " + DB.k_products + " (gu_owner,nm_product,id_status,is_compound,gu_blockedby,dt_modified,dt_uploaded,id_language,de_product,pr_list,pr_sale,pr_discount,pr_purchase,id_currency,pct_tax_rate,is_tax_included,dt_start,dt_end,tag_product,id_ref,gu_address,gu_product) VALUES (?,?,?,?,?,NULL,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?)");
    oFareInsr = oConn.prepareStatement("INSERT INTO " + DB.k_prod_fares + " (pr_sale,tp_fare,id_currency,pct_tax_rate,is_tax_included,dt_start,dt_end,gu_product,id_fare) VALUES (?,?,?,?,?,?,?,?,?)");
    oFareUpdt = oConn.prepareStatement("UPDATE " + DB.k_prod_fares + " SET pr_sale=?,tp_fare=?,id_currency=?,pct_tax_rate=?,is_tax_included=?,dt_start=?,dt_end=? WHERE gu_product=? AND id_fare=?");
    oLocaInsr = oConn.prepareStatement("INSERT INTO " + DB.k_prod_locats + " (gu_location,gu_owner,pg_prod_locat,id_cont_type,id_prod_type,len_file,xprotocol,xhost,xport,xpath,xfile,xanchor,xoriginalfile,dt_modified,dt_uploaded,de_prod_locat,status,nu_current_stock,nu_reserved_stock,nu_min_stock,vs_stamp,tx_email,tag_prod_locat,gu_product) VALUES(?,?,1,?,?,?,?,?,?,?,?,?,?,NULL,?,?,?,?,?,?,?,?,?,?)");
    oLocaUpdt = oConn.prepareStatement("UPDATE " + DB.k_prod_locats + " SET gu_owner=?,id_cont_type=?,id_prod_type=?,len_file=?,xprotocol=?,xhost=?,xport=?,xpath=?,xfile=?,xanchor=?,xoriginalfile=?,dt_modified=?,dt_uploaded=?,de_prod_locat=?,status=?,nu_current_stock=?,nu_reserved_stock=?,nu_min_stock=?,vs_stamp=?,tx_email=?,tag_prod_locat=? WHERE gu_product=?");
    oAttrInsr = oConn.prepareStatement("INSERT INTO " + DB.k_prod_attr + " (adult_rated,alturl,author,availability,brand,client,color,contact_person,country_code,country,cover,days_to_deliver,department,disk_space,display,doc_no,dt_acknowledge,dt_expire,dt_out,email,fax,forward_to,icq_id,ip_addr,isbn,nu_lines,memory,mobilephone,office,ordinal,organization,pages,paragraphs,phone1,phone2,power,project,product_group,rank,reference_id,revised_by,rooms,scope,signature,size_x,size_y,size_z,speed,state_code,state,subject,target,template,typeof,upload_by,weight,words,zip_code,gu_product) VALUES (?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?)");
    oAttrUpdt = oConn.prepareStatement("UPDATE " + DB.k_prod_attr + " SET adult_rated=?,alturl=?,author=?,availability=?,brand=?,client=?,color=?,contact_person=?,country_code=?,country=?,cover=?,days_to_deliver=?,department=?,disk_space=?,display=?,doc_no=?,dt_acknowledge=?,dt_expire=?,dt_out=?,email=?,fax=?,forward_to=?,icq_id=?,ip_addr=?,isbn=?,nu_lines=?,memory=?,mobilephone=?,office=?,ordinal=?,organization=?,pages=?,paragraphs=?,phone1=?,phone2=?,power=?,project=?,product_group=?,rank=?,reference_id=?,revised_by=?,rooms=?,scope=?,signature=?,size_x=?,size_y=?,size_z=?,speed=?,state_code=?,state=?,subject=?,target=?,template=?,typeof=?,upload_by=?,weight=?,words=?,zip_code=? WHERE gu_product=?");
    oKeysInsr = oConn.prepareStatement("INSERT INTO " + DB.k_prod_keywords +
                                       " (gu_product,tx_keywords) VALUES (?,?)");
    oKeysDlte = oConn.prepareStatement("DELETE FROM " + DB.k_prod_keywords +
                                       " WHERE gu_product=?");
    oAddrUpdt = oConn.prepareStatement("UPDATE " + DB.k_addresses + " SET dt_modified=?,tp_location=?,nm_company=?,tp_street=?,nm_street=?,nu_street=?,tx_addr1=?,tx_addr2=?,id_country=?,nm_country=?,id_state=?,nm_state=?,mn_city=?,zipcode=?,work_phone=?,direct_phone=?,home_phone=?,mov_phone=?,fax_phone=?,other_phone=?,po_box=?,tx_email=?,tx_email_alt=?,url_addr=?,coord_x=?,coord_y=?,contact_person=?,tx_salutation=?,tx_remarks=? WHERE gu_address=?");
    oAddrInsr = oConn.prepareStatement("INSERT INTO " + DB.k_addresses + " (gu_address,ix_address,gu_workarea,bo_active,dt_modified,tp_location,nm_company,tp_street,nm_street,nu_street,tx_addr1,tx_addr2,id_country,nm_country,id_state,nm_state,mn_city,zipcode,work_phone,direct_phone,home_phone,mov_phone,fax_phone,other_phone,po_box,tx_email,tx_email_alt,url_addr,coord_x,coord_y,contact_person,tx_salutation,tx_remarks) VALUES (?,1,?,1,NULL,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?)");
    oCatgInsr = oConn.prepareStatement("INSERT INTO " + DB.k_x_cat_objs +
        " (gu_category,gu_object,id_class,bi_attribs,od_position) VALUES (?,?,15,0,?)");
    oCatgDlte = oConn.prepareStatement("DELETE FROM " + DB.k_x_cat_objs +
                                       " WHERE gu_object=? AND id_class=15");
  }

  // ---------------------------------------------------------------------------

  /**
   * <p>Close prepared statements</p>
   * This method must always be called before object is destroyed or else
   * cursors may be left open at the database
   * @throws SQLException
   */
  public void close() throws SQLException {
    if (null != oProdUpdt) {
      oProdUpdt.close();
      oProdUpdt = null;
    }
    if (null != oProdInsr) {
      oProdInsr.close();
      oProdInsr = null;
    }
    if (null != oFareInsr) {
      oFareInsr.close();
      oFareInsr = null;
    }
    if (null != oFareUpdt) {
      oFareUpdt.close();
      oFareUpdt = null;
    }
    if (null != oLocaInsr) {
      oLocaInsr.close();
      oLocaInsr = null;
    }
    if (null != oLocaUpdt) {
      oLocaUpdt.close();
      oLocaUpdt = null;
    }
    if (null != oAttrInsr) {
      oAttrInsr.close();
      oAttrInsr = null;
    }
    if (null != oAttrUpdt) {
      oAttrUpdt.close();
      oAttrUpdt = null;
    }
    if (null != oKeysInsr) {
      oKeysInsr.close();
      oKeysInsr = null;
    }
    if (null != oKeysDlte) {
      oKeysDlte.close();
      oKeysDlte = null;
    }
    if (null != oAddrUpdt) {
      oAddrUpdt.close();
      oAddrUpdt = null;
    }
    if (null != oAddrInsr) {
      oAddrInsr.close();
      oAddrInsr = null;
    }
    if (null != oCatgInsr) {
      oCatgInsr.close();
      oCatgInsr = null;
    }
    if (null != oCatgDlte) {
      oCatgDlte.close();
      oCatgDlte = null;
    }
  }

  // ---------------------------------------------------------------------------

  /**
   * Set all column values to null
   */
  public void setAllColumnsToNull() {
    if (DebugFile.trace) {
      DebugFile.writeln("Begin ProductLoader.setAllColumnsToNull()");
      DebugFile.incIdent();
    }

    for (int c = aValues.length - 1; c >= 0; c--)
      aValues[c] = null;

    if (DebugFile.trace) {
      DebugFile.decIdent();
      DebugFile.writeln("End ProductLoader.setAllColumnsToNull()");
    }
  } // setAllColumnsToNull

  // ---------------------------------------------------------------------------

  /**
   * <p>Get column index at ColumnNames array given its name</p>
   * This method performs binary search assuming that ColumnNames is sorted in
   * ascending order
   * @param sColumnName String Column name (case insensitive)
   * @return int Column index or -1 if not found
   */
  public int getColumnIndex(String sColumnName) {
    int iIndex = Arrays.binarySearch(ColumnNames, sColumnName,
                                     String.CASE_INSENSITIVE_ORDER);
    if (iIndex < 0) iIndex = -1;
    return iIndex;
  }

  // ---------------------------------------------------------------------------

  public int columnCount() {
    return aValues.length;
  }

  // ---------------------------------------------------------------------------

  public String[] columnNames() throws IllegalStateException {
    return ColumnNames;
  }

  // ---------------------------------------------------------------------------

  /**
   * Put value for a given column
   * @param iColumnIndex Column index [0..getColumnCount()-1]
   * @param oValue Value for column
   * @throws ArrayIndexOutOfBoundsException
   */
  public void put(int iColumnIndex, Object oValue) throws
      ArrayIndexOutOfBoundsException {
    aValues[iColumnIndex] = oValue;
  }

  // ---------------------------------------------------------------------------

  /**
   * <p>Put value for a given column</p>
   * If a previous value already exists then it is replaced
   * @param sColumnName Column name (case sensitive)
   * @param oValue Value for column
   * @throws ArrayIndexOutOfBoundsException
   */
  public void put(String sColumnName, Object oValue) throws
      ArrayIndexOutOfBoundsException {
    int iColumnIndex = getColumnIndex(sColumnName.toLowerCase());
    if ( -1 == iColumnIndex)throw new ArrayIndexOutOfBoundsException(
        "Cannot find column named " + sColumnName);
    aValues[iColumnIndex] = oValue;
  }

  // ---------------------------------------------------------------------------

  /**
   * Put all values from a map on their corresponding columns matching by name
   * @param oValues Map
   */
  public void putAll(Map oValues) {
    int iColumnIndex;
    String sColumnName;
    if (DebugFile.trace) {
      DebugFile.writeln("Begin ProductLoader.putAll()");
      DebugFile.incIdent();
    }
    Iterator oIter = oValues.keySet().iterator();
    while (oIter.hasNext()) {
      sColumnName = (String) oIter.next();
      iColumnIndex = getColumnIndex(sColumnName.toLowerCase());
      if (iColumnIndex > 0) {
        Object oVal = oValues.get(sColumnName);
        if (oVal == null)
          aValues[iColumnIndex] = null;
        else if (oVal.getClass().getName().startsWith("[L")) {
          aValues[iColumnIndex] = java.lang.reflect.Array.get(oVal, 0);
        }
        else {
          aValues[iColumnIndex] = oVal;
        }
        if (DebugFile.trace) DebugFile.writeln(sColumnName.toLowerCase() + "=" +
                                               aValues[iColumnIndex]);
      }
      else {
        if (DebugFile.trace) DebugFile.writeln(sColumnName + " not found");
      } // fi (iColumnIndex)
    } // wend
    if (DebugFile.trace) {
      DebugFile.decIdent();
      DebugFile.writeln("End ProductLoader.putAll()");
    }
  } // putAll

  // ---------------------------------------------------------------------------

  /**
   * Get column by index
   * @param iColumnIndex int Colunm index [0..getColumnCount()-1]
   * @return Object Column value
   * @throws ArrayIndexOutOfBoundsException
   */
  public Object get(int iColumnIndex) throws ArrayIndexOutOfBoundsException {
    return aValues[iColumnIndex];
  } // get

  // ---------------------------------------------------------------------------

  /**
   * Get column by name
   * @param sColumnName String Column name (case sensitive)
   * @return Object Column value
   * @throws ArrayIndexOutOfBoundsException If no column with sucjh name was found
   */
  public Object get(String sColumnName) throws ArrayIndexOutOfBoundsException {
    int iColumnIndex = getColumnIndex(sColumnName.toLowerCase());
    if ( -1 == iColumnIndex)throw new ArrayIndexOutOfBoundsException(
        "Cannot find column named " + sColumnName);
    return aValues[iColumnIndex];
  }

  // ---------------------------------------------------------------------------

  private static boolean test(int iInputValue, int iBitMask) {
    return (iInputValue & iBitMask) != 0;
  } // test

  // ---------------------------------------------------------------------------

  private String getColNull(int iColIndex) throws
      ArrayIndexOutOfBoundsException, ClassCastException {
    if (DebugFile.trace) {
      if (iColIndex < 0 || iColIndex >= aValues.length)
        throw new ArrayIndexOutOfBoundsException(
            "ProductLoader.getColNull() column index " +
            String.valueOf(iColIndex) + " must be in the range between 0 and " +
            String.valueOf(aValues.length));
      DebugFile.writeln("ProductLoader.getColNull(" + String.valueOf(iColIndex) +
                        ") : " + aValues[iColIndex]);
    }
    String sRetVal;
    if (null == aValues[iColIndex])
      sRetVal = null;
    else {
      try {
        sRetVal = aValues[iColIndex].toString();
      }
      catch (ClassCastException cce) {
        if (aValues[iColIndex] == null)
          throw new ClassCastException("ProductLoader.getColNull(" +
                                       String.valueOf(iColIndex) +
                                       ") could not cast null to String");
        else
          throw new ClassCastException("ProductLoader.getColNull(" +
                                       String.valueOf(iColIndex) +
                                       ") could not cast " +
                                       aValues[iColIndex].getClass().getName() +
                                       " " + aValues[iColIndex] + " to String");
      }
      if (sRetVal.length() == 0 || sRetVal.equalsIgnoreCase("null"))
        sRetVal = null;
    }
    return sRetVal;
  } // getColNull

  // ---------------------------------------------------------------------------

  private void storeAddress(Connection oConn, String sWorkArea) throws
      SQLException {

    if (DebugFile.trace) {
      DebugFile.writeln("Begin ProductLoader.storeAddress([Connection], " +
                        sWorkArea + ")");
      DebugFile.incIdent();
    }

    oAddrUpdt.setTimestamp(1, new Timestamp(new Date().getTime()));
    oAddrUpdt.setString(2, getColNull(tp_location));
    oAddrUpdt.setString(3, getColNull(nm_company));
    oAddrUpdt.setString(4, getColNull(tp_street));
    oAddrUpdt.setString(5, getColNull(nm_street));
    oAddrUpdt.setString(6, getColNull(nu_street));
    oAddrUpdt.setString(7, getColNull(tx_addr1));
    oAddrUpdt.setString(8, getColNull(tx_addr2));
    oAddrUpdt.setString(9, getColNull(id_country));
    oAddrUpdt.setString(10, getColNull(nm_country));
    oAddrUpdt.setString(11, getColNull(id_state));
    oAddrUpdt.setString(12, getColNull(nm_state));
    oAddrUpdt.setString(13, getColNull(mn_city));
    oAddrUpdt.setString(14, getColNull(zip_code));
    oAddrUpdt.setString(15, getColNull(work_phone));
    oAddrUpdt.setString(16, getColNull(direct_phone));
    oAddrUpdt.setString(17, getColNull(home_phone));
    oAddrUpdt.setString(18, getColNull(mov_phone));
    oAddrUpdt.setString(19, getColNull(fax_phone));
    oAddrUpdt.setString(20, getColNull(other_phone));
    oAddrUpdt.setString(21, getColNull(po_box));
    oAddrUpdt.setString(22, getColNull(tx_email));
    oAddrUpdt.setString(23, getColNull(tx_email_alt));
    oAddrUpdt.setString(24, getColNull(url_addr));
    if (null==aValues[coord_x])
      oAddrUpdt.setNull(25, Types.FLOAT);
    else
      oAddrUpdt.setObject(25, aValues[coord_x], Types.FLOAT);
    if (null==aValues[coord_y])
      oAddrUpdt.setNull(26, Types.FLOAT);
    else
      oAddrUpdt.setObject(26, aValues[coord_y], Types.FLOAT);
    oAddrUpdt.setString(27, getColNull(contact_person));
    oAddrUpdt.setString(28, getColNull(tx_salutation));
    oAddrUpdt.setString(29, getColNull(tx_remarks));
    oAddrUpdt.setObject(30, get(gu_address), Types.CHAR);
    if (DebugFile.trace) DebugFile.writeln("PreparedStatement.executeUpdate()");
    int iAffected = oAddrUpdt.executeUpdate();
    if (DebugFile.trace) DebugFile.writeln("iAffected = " +
                                           String.valueOf(iAffected));
    if (0 == iAffected) {
      oAddrInsr.setObject(1, get(gu_address), Types.CHAR);
      oAddrInsr.setObject(2, sWorkArea, Types.CHAR);
      oAddrInsr.setString(3, getColNull(tp_location));
      oAddrInsr.setString(4, getColNull(nm_company));
      oAddrInsr.setString(5, getColNull(tp_street));
      oAddrInsr.setString(6, getColNull(nm_street));
      oAddrInsr.setString(7, getColNull(nu_street));
      oAddrInsr.setString(8, getColNull(tx_addr1));
      oAddrInsr.setString(9, getColNull(tx_addr2));
      oAddrInsr.setString(10, getColNull(id_country));
      oAddrInsr.setString(11, getColNull(nm_country));
      oAddrInsr.setString(12, getColNull(id_state));
      oAddrInsr.setString(13, getColNull(nm_state));
      oAddrInsr.setString(14, getColNull(mn_city));
      oAddrInsr.setString(15, getColNull(zip_code));
      oAddrInsr.setString(16, getColNull(work_phone));
      oAddrInsr.setString(17, getColNull(direct_phone));
      oAddrInsr.setString(18, getColNull(home_phone));
      oAddrInsr.setString(19, getColNull(mov_phone));
      oAddrInsr.setString(20, getColNull(fax_phone));
      oAddrInsr.setString(21, getColNull(other_phone));
      oAddrInsr.setString(22, getColNull(po_box));
      oAddrInsr.setString(23, getColNull(tx_email));
      oAddrInsr.setString(24, getColNull(tx_email_alt));
      oAddrInsr.setString(25, getColNull(url_addr));
      if (null==aValues[coord_x])
        oAddrInsr.setNull(26, Types.FLOAT);
      else
        oAddrInsr.setObject(26, aValues[coord_x], Types.FLOAT);
      if (null==aValues[coord_y])
        oAddrInsr.setNull(27, Types.FLOAT);
      else
        oAddrInsr.setObject(27, aValues[coord_y], Types.FLOAT);
      oAddrInsr.setString(28, getColNull(contact_person));
      oAddrInsr.setString(29, getColNull(tx_salutation));
      oAddrInsr.setString(30, getColNull(tx_remarks));
      if (DebugFile.trace) DebugFile.writeln(
          "PreparedStatement.executeUpdate()");
      oAddrInsr.executeUpdate();
    }
    if (DebugFile.trace) {
      DebugFile.decIdent();
      DebugFile.writeln("End ProductLoader.storeAddress()");
    }
  } // storeAddress

  // ---------------------------------------------------------------------------

  private void storeFare(Connection oConn, boolean bNewPrd) throws SQLException {

    if (DebugFile.trace) {
      DebugFile.writeln("Begin ProductLoader.storeFare([Connection])");
      DebugFile.incIdent();
    }

    int iAffected = 0;

    if (!bNewPrd) {
      oFareUpdt.setObject(1, aValues[pr_sale], Types.DECIMAL);
      oFareUpdt.setObject(2, aValues[tp_fare], Types.VARCHAR);
      oFareUpdt.setObject(3, aValues[id_currency], Types.VARCHAR);
      oFareUpdt.setObject(4, aValues[pct_tax_rate], Types.FLOAT);
      oFareUpdt.setObject(5, aValues[is_tax_included], Types.SMALLINT);
      oFareUpdt.setObject(6, aValues[dt_start], Types.TIMESTAMP);
      oFareUpdt.setObject(7, aValues[dt_end], Types.TIMESTAMP);
      oFareUpdt.setObject(8, aValues[gu_product], Types.CHAR);
      oFareUpdt.setObject(9, aValues[id_fare], Types.VARCHAR);

      if (DebugFile.trace) DebugFile.writeln(
          "PreparedStatement.executeUpdate()");
      iAffected = oFareUpdt.executeUpdate();
      if (DebugFile.trace) DebugFile.writeln("iAffected = " +
                                             String.valueOf(iAffected));
    }

    if (0 == iAffected) {
      oFareInsr.setObject(1, aValues[pr_sale], Types.DECIMAL);
      oFareInsr.setObject(2, aValues[tp_fare], Types.VARCHAR);
      oFareInsr.setObject(3, aValues[id_currency], Types.VARCHAR);
      oFareInsr.setObject(4, aValues[pct_tax_rate], Types.FLOAT);
      oFareInsr.setObject(5, aValues[is_tax_included], Types.SMALLINT);
      oFareInsr.setObject(6, aValues[dt_start], Types.TIMESTAMP);
      oFareInsr.setObject(7, aValues[dt_end], Types.TIMESTAMP);
      oFareInsr.setObject(8, aValues[gu_product], Types.CHAR);
      oFareInsr.setObject(9, aValues[id_fare], Types.VARCHAR);
      oFareInsr.executeUpdate();
    }

    if (DebugFile.trace) {
      DebugFile.decIdent();
      DebugFile.writeln("End ProductLoader.storeFare()");
    }
  } // storeFare

  // ---------------------------------------------------------------------------

  private void storeAttr(Connection oConn, boolean bNewPrd) throws SQLException {

    if (DebugFile.trace) {
      DebugFile.writeln("Begin ProductLoader.storeAttr([Connection], "+String.valueOf(bNewPrd)+")");
      DebugFile.incIdent();
    }

    int iAffected = 0;
    int[] aColIdxs = new int[] {
        adult_rated, alturl, author, availability, brand, client, color,
        contact_person, country_code, country, cover, days_to_deliver,
        department, disk_space, display, doc_no, dt_acknowledge, dt_expire,
        dt_out, email, fax, forward_to, icq_id, ip_addr, isbn, nu_lines, memory,
        mobilephone, office, ordinal, organization, pages, paragraphs, phone1,
        phone2, power, project, product_group, rank, reference_id, revised_by,
        rooms, scope, signature, size_x, size_y, size_z, speed, state_code,
        state, subject, target, template, typeof, upload_by, weight, words,
        zip_code, gu_product};
    int nColIdxs = aColIdxs.length;

    if (!bNewPrd) {
      for (int c = 0; c < nColIdxs; c++) {
        oAttrUpdt.setObject(c + 1, aValues[aColIdxs[c]]);
      }
      if (DebugFile.trace) {
        DebugFile.writeln("gu_product="+aValues[aColIdxs[gu_product]]);
        DebugFile.writeln("PreparedStatement.executeUpdate()");
      }
      iAffected = oAttrUpdt.executeUpdate();
      if (DebugFile.trace) DebugFile.writeln("iAffected = " + String.valueOf(iAffected));
    }

    if (0 == iAffected) {
      for (int c = 0; c < nColIdxs; c++) {
        oAttrInsr.setObject(c + 1, aValues[aColIdxs[c]]);
      }
      if (DebugFile.trace) {
        DebugFile.writeln("gu_product="+aValues[aColIdxs[gu_product]]);
        DebugFile.writeln("PreparedStatement.executeUpdate()");
      }
      oAttrInsr.executeUpdate();
    }

    if (DebugFile.trace) {
      DebugFile.decIdent();
      DebugFile.writeln("End ProductLoader.storeAttr()");
    }
  } // storeAttr

  // ---------------------------------------------------------------------------

  private void storeLocation(Connection oConn, String sOwner,
                             boolean bNewPrd) throws SQLException {

    if (DebugFile.trace) {
      DebugFile.writeln("Begin ProductLoader.storeLocation([Connection], " +
                        sOwner + ", " + String.valueOf(bNewPrd) + ")");
      DebugFile.incIdent();
      DebugFile.writeln("len_file="+aValues[len_file]);
    }


    int iAffected = 0;

    if (!bNewPrd) {
      oLocaUpdt.setString(1, sOwner);
      if (null == aValues[id_cont_type])
        oLocaUpdt.setInt(2, 100);
      else
        oLocaUpdt.setObject(2, aValues[id_cont_type], Types.INTEGER);
      if (null == aValues[id_prod_type])
        oLocaUpdt.setString(3, "?");
      else
        oLocaUpdt.setObject(3, "".equals(aValues[id_prod_type]) ? "?" : aValues[id_prod_type], Types.VARCHAR);
      if (null == aValues[len_file])
        oLocaUpdt.setInt(4, 0);
      else
        oLocaUpdt.setObject(4, aValues[len_file], Types.INTEGER);
      if (null == aValues[xprotocol])
        oLocaUpdt.setString(5, "file://");
      else
        oLocaUpdt.setObject(5, aValues[xprotocol], Types.VARCHAR);
      if (null == aValues[xhost])
        oLocaUpdt.setString(6, "localhost");
      else
        oLocaUpdt.setObject(6, aValues[xhost], Types.VARCHAR);
      oLocaUpdt.setObject(7, aValues[xport], Types.INTEGER);
      oLocaUpdt.setObject(8, aValues[xoriginalfile], Types.VARCHAR);
      oLocaUpdt.setObject(9, new Timestamp(new Date().getTime()),
                          Types.TIMESTAMP);
      oLocaUpdt.setObject(10, aValues[dt_uploaded], Types.TIMESTAMP);
      oLocaUpdt.setObject(11, aValues[de_prod_locat], Types.VARCHAR);
      oLocaUpdt.setObject(12, aValues[status], Types.INTEGER);
      oLocaUpdt.setObject(13, aValues[nu_current_stock], Types.FLOAT);
      oLocaUpdt.setObject(14, aValues[nu_reserved_stock], Types.FLOAT);
      oLocaUpdt.setObject(15, aValues[nu_min_stock], Types.FLOAT);
      oLocaUpdt.setObject(16, aValues[vs_stamp], Types.VARCHAR);
      oLocaUpdt.setObject(17, aValues[tx_email], Types.VARCHAR);
      oLocaUpdt.setObject(18, aValues[tag_prod_locat], Types.VARCHAR);
      oLocaUpdt.setObject(19, aValues[gu_product], Types.VARCHAR);

      if (DebugFile.trace) DebugFile.writeln(
          "PreparedStatement.executeUpdate()");
      iAffected = oLocaUpdt.executeUpdate();
      if (DebugFile.trace) DebugFile.writeln("iAffected = " +
                                             String.valueOf(iAffected));
    }

    if (0 == iAffected) {
      oLocaInsr.setString(1, Gadgets.generateUUID());
      oLocaInsr.setString(2, sOwner);
      if (null == aValues[id_cont_type])
        oLocaInsr.setInt(3, 100);
      else
        oLocaInsr.setObject(3, aValues[id_cont_type], Types.INTEGER);
      if (null == aValues[id_prod_type])
        oLocaInsr.setString(4, "?");
      else
        oLocaInsr.setObject(4, "".equals(aValues[id_prod_type]) ? "?" : aValues[id_prod_type], Types.VARCHAR);
      if (null == aValues[len_file])
        oLocaInsr.setInt(5, 0);
      else
        oLocaInsr.setObject(5, aValues[len_file], Types.INTEGER);
      if (null == aValues[xprotocol])
        oLocaInsr.setString(6, "file://");
      else
        oLocaInsr.setObject(6, aValues[xprotocol], Types.VARCHAR);
      if (null == aValues[xhost])
        oLocaInsr.setString(7, "localhost");
      else
        oLocaInsr.setObject(7, aValues[xhost], Types.VARCHAR);
      oLocaInsr.setObject(8, aValues[xport], Types.INTEGER);
      oLocaInsr.setObject(9, aValues[xpath], Types.VARCHAR);
      oLocaInsr.setObject(10, aValues[xfile], Types.VARCHAR);
      oLocaInsr.setObject(11, aValues[xanchor], Types.VARCHAR);
      oLocaInsr.setObject(12, aValues[xoriginalfile], Types.VARCHAR);
      oLocaInsr.setObject(13, aValues[dt_uploaded], Types.TIMESTAMP);
      oLocaInsr.setObject(14, aValues[de_prod_locat], Types.VARCHAR);
      oLocaInsr.setObject(15, aValues[status], Types.INTEGER);
      oLocaInsr.setObject(16, aValues[nu_current_stock], Types.FLOAT);
      oLocaInsr.setObject(17, aValues[nu_reserved_stock], Types.FLOAT);
      oLocaInsr.setObject(18, aValues[nu_min_stock], Types.FLOAT);
      oLocaInsr.setObject(19, aValues[vs_stamp], Types.VARCHAR);
      oLocaInsr.setObject(20, aValues[tx_email], Types.VARCHAR);
      oLocaInsr.setObject(21, aValues[tag_prod_locat], Types.VARCHAR);
      oLocaInsr.setObject(22, aValues[gu_product], Types.VARCHAR);
      if (DebugFile.trace) DebugFile.writeln("PreparedStatement.executeInsert()");
      oLocaInsr.executeUpdate();
    }

    if (DebugFile.trace) {
      DebugFile.decIdent();
      DebugFile.writeln("End ProductLoader.storeLocation()");
    }
  } // storeLocation

  // ---------------------------------------------------------------------------

  private void storeKeywords(Connection oConn, boolean bNewPrd) throws
      SQLException {

    if (DebugFile.trace) {
      DebugFile.writeln("Begin ProductLoader.storeKeywords([Connection], " +
                        String.valueOf(bNewPrd) + ")");
      DebugFile.incIdent();
    }

    if (!bNewPrd) {
      oKeysDlte.setObject(1, aValues[gu_product], Types.CHAR);
      oKeysDlte.executeUpdate();
    }

    if (null != aValues[tx_keywords]) {
      oKeysInsr.setObject(1, aValues[gu_product], Types.CHAR);
      oKeysInsr.setObject(2, aValues[tx_keywords], Types.VARCHAR);
      oKeysInsr.executeUpdate();
    }

    if (DebugFile.trace) {
      DebugFile.decIdent();
      DebugFile.writeln("End ProductLoader.storeKeywords()");
    }
  } // storeKeywords

  // ---------------------------------------------------------------------------

  private void insertProduct(Connection oConn, String sOwner) throws
      SQLException,NullPointerException {

    if (DebugFile.trace) {
      DebugFile.writeln("Begin ProductLoader.insertProduct([Connection], " + sOwner + ")");
      if (null==aValues[gu_product]) throw new NullPointerException("ProductLoader.insertProduct() gu_product cannot be null");
      DebugFile.incIdent();
    }

    oProdInsr.setString(1, sOwner);
    oProdInsr.setObject(2, aValues[nm_product], Types.VARCHAR);
    oProdInsr.setObject(3, aValues[id_status], Types.SMALLINT);
    oProdInsr.setObject(4, aValues[is_compound], Types.SMALLINT);
    oProdInsr.setObject(5, aValues[gu_blockedby], Types.CHAR);
    oProdInsr.setObject(6, aValues[dt_uploaded], Types.TIMESTAMP);
    oProdInsr.setObject(7, aValues[id_language], Types.CHAR);
    oProdInsr.setObject(8, aValues[de_product], Types.VARCHAR);
    oProdInsr.setObject(9, aValues[pr_list], Types.DECIMAL);
    oProdInsr.setObject(10, aValues[pr_sale], Types.DECIMAL);
    oProdInsr.setObject(11, aValues[pr_discount], Types.DECIMAL);
    oProdInsr.setObject(12, aValues[pr_purchase], Types.DECIMAL);
    oProdInsr.setObject(13, aValues[id_currency], Types.VARCHAR);
    oProdInsr.setObject(14, aValues[pct_tax_rate], Types.FLOAT);
    oProdInsr.setObject(15, aValues[is_tax_included], Types.SMALLINT);
    oProdInsr.setObject(16, aValues[dt_start], Types.TIMESTAMP);
    oProdInsr.setObject(17, aValues[dt_end], Types.TIMESTAMP);
    oProdInsr.setObject(18, aValues[tag_product], Types.VARCHAR);
    oProdInsr.setObject(19, aValues[id_ref], Types.VARCHAR);
    oProdInsr.setObject(20, aValues[gu_address], Types.CHAR);
    oProdInsr.setObject(21, aValues[gu_product], Types.CHAR);
    oProdInsr.executeUpdate();

    if (DebugFile.trace) {
      DebugFile.decIdent();
      DebugFile.writeln("End ProductLoader.insertProduct() : " + aValues[gu_product]);
    }
  } // insertProduct

  // ---------------------------------------------------------------------------

  private void updateProduct(Connection oConn, String sOwner) throws
      SQLException,NullPointerException {

    if (DebugFile.trace) {
      DebugFile.writeln("Begin ProductLoader.updateProduct([Connection], " + sOwner + ")");
      if (null==aValues[gu_product]) throw new NullPointerException("ProductLoader.updateProduct() gu_product cannot be null");
      DebugFile.incIdent();
    }

    oProdUpdt.setString(1, sOwner);
    oProdUpdt.setObject(2, aValues[nm_product], Types.VARCHAR);
    oProdUpdt.setObject(3, aValues[id_status], Types.SMALLINT);
    oProdUpdt.setObject(4, aValues[is_compound], Types.SMALLINT);
    oProdUpdt.setObject(5, aValues[gu_blockedby], Types.CHAR);
    oProdUpdt.setObject(6, new Timestamp(new Date().getTime()), Types.TIMESTAMP);
    oProdUpdt.setObject(7, aValues[dt_uploaded], Types.TIMESTAMP);
    oProdUpdt.setObject(8, aValues[id_language], Types.CHAR);
    oProdUpdt.setObject(9, aValues[de_product], Types.VARCHAR);
    oProdUpdt.setObject(10, aValues[pr_list], Types.DECIMAL);
    oProdUpdt.setObject(11, aValues[pr_sale], Types.DECIMAL);
    oProdUpdt.setObject(12, aValues[pr_discount], Types.DECIMAL);
    oProdUpdt.setObject(13, aValues[pr_purchase], Types.DECIMAL);
    oProdUpdt.setObject(14, aValues[id_currency], Types.VARCHAR);
    oProdUpdt.setObject(15, aValues[pct_tax_rate], Types.FLOAT);
    oProdUpdt.setObject(16, aValues[is_tax_included], Types.SMALLINT);
    oProdUpdt.setObject(17, aValues[dt_start], Types.TIMESTAMP);
    oProdUpdt.setObject(18, aValues[dt_end], Types.TIMESTAMP);
    oProdUpdt.setObject(19, aValues[tag_product], Types.VARCHAR);
    oProdUpdt.setObject(20, aValues[id_ref], Types.VARCHAR);
    oProdUpdt.setObject(21, aValues[gu_address], Types.CHAR);
    oProdUpdt.setObject(22, aValues[gu_product], Types.CHAR);
    int iAffected = oProdUpdt.executeUpdate();

    if (DebugFile.trace) {
      DebugFile.decIdent();
      DebugFile.writeln("End ProductLoader.updateProduct() : " + String.valueOf(iAffected));
    }
  } // updateProduct

  // ---------------------------------------------------------------------------

  /**
   * Store properties curently held in RAM into the database
   * @param oConn Opened JDBC connection
   * @param sWorkArea String GUID of WorkArea to which inserted data will belong
   * @param iFlags int A boolean combination of {MODE_APPEND|MODE_UPDATE|WRITE_ADDRESSES|WRITE_LOOKUPS|NO_DUPLICATED_NAMES|NO_DUPLICATED_REFERENCES}
   * @throws SQLException
   * @throws IllegalArgumentException
   * @throws NullPointerException
   * @throws ClassCastException
   */
  public void store(Connection oConn, String sWorkArea, int iFlags) throws
      SQLException, IllegalArgumentException, NullPointerException,
      ClassCastException {

    boolean bNewPrd = false, bNewAdr = false;

    String sAdrGuid;
    String sPrdGuid;
    String sCatGuid;
    PreparedStatement oStmt;
    ResultSet oRSet;

    if (oProdUpdt == null || oFareUpdt == null || oAttrUpdt == null ||
        oAddrUpdt == null)
      throw new SQLException("Invalid command sequece. Must call ProductLoader.prepare() before ProductLoader.store()");

    if (!test(iFlags, MODE_APPEND) && !test(iFlags, MODE_UPDATE))
      throw new IllegalArgumentException("ProductLoader.store() Flags bitmask must contain either MODE_APPEND, MODE_UPDATE or both");

    if (null == sWorkArea)
      throw new NullPointerException(
          "ProductLoader.store() Default WorkArea cannot be null");

    if (null == getColNull(nm_product))
      throw new NullPointerException(
          "ProductLoader.store() nm_product cannot be null");

    if (null == getColNull(id_ref) && test(iFlags, NO_DUPLICATED_REFERENCES))
      throw new NullPointerException("ProductLoader.store() Product reference must be suplied at column id_ref if NO_DUPLICATED_REFERENCES is set");

    if (null == getColNull(nm_category) && null == getColNull(gu_category))
      throw new NullPointerException(
          "ProductLoader.store() a Category is requiered for placing the products");

    if (DebugFile.trace) {
      DebugFile.writeln("Begin Productloader.store([Connection], " + sWorkArea +
                        ", " + String.valueOf(iFlags) + ")");
      DebugFile.incIdent();
    }

    // ***************************************************
    // Parse URL substrings from url_addr if xhost is null

    if (null != aValues[url_addr] && null == aValues[xhost]) {
      ProductLocation oLoca = new ProductLocation();
      try {
        oLoca.setURL( (String) aValues[url_addr]);
      }
      catch (java.net.MalformedURLException badurl) {
        if (DebugFile.trace) DebugFile.decIdent();
        throw new IllegalArgumentException("Productloader.store() " +
                                           aValues[url_addr] +
                                           " does not have a valid URL syntax");
      }
      aValues[xprotocol] = oLoca.getStringNull(DB.xprotocol, "file://");
      aValues[xhost] = oLoca.getStringNull(DB.xhost, "localhost");
      aValues[xpath] = oLoca.getPath();
      if (oLoca.isNull(DB.xport))
        aValues[xport] = null;
      else
        aValues[xport] = oLoca.getInteger(DB.xport);
      aValues[xfile] = oLoca.getStringNull(DB.xfile, null);
      aValues[xanchor] = oLoca.getStringNull(DB.xanchor, null);
      oLoca = null;
    }

    // ***************************************************

    if (null != aValues[gu_category]) {

      // *************************************************************************
      // If gu_category is set then check whether or not it exists at the database

      boolean bExists;
      sCatGuid = (String) get(gu_category);

      if (sLastCategoryGuid.equals(sCatGuid)) {
        bExists = true;
      }
      else {
        if (DebugFile.trace)
          DebugFile.writeln("Connection.prepareStatement(SELECT " +
                            DB.nm_category + "," + DB.gu_owner +
                            " FROM " + DB.k_categories +
                            " WHERE " + DB.gu_category + "='" + sCatGuid + "')");

        oStmt = oConn.prepareStatement("SELECT " + DB.nm_category + "," + DB.gu_owner +
                                       " FROM " + DB.k_categories +
                                       " WHERE " +DB.gu_category + "=?",
                                       ResultSet.TYPE_FORWARD_ONLY,
                                       ResultSet.CONCUR_READ_ONLY);
        oStmt.setString(1, sCatGuid);
        oRSet = oStmt.executeQuery();
        bExists = oRSet.next();
        if (bExists) {
          sLastCategoryGuid = sCatGuid;
          sLastCategoryName = oRSet.getString(1);
          sLastOwnGuid = oRSet.getString(2);
        }
        oRSet.close();
        oStmt.close();
      }
      if (!bExists) {
        // If gu_category does not exist then raise and exception
        if (DebugFile.trace) DebugFile.decIdent();
        throw new SQLException("ProductLoader.store() Category " +
                               get(gu_category) + " does not exist", "01S06");
      }
    }
    else {

      // *******************************************************
      // If gu_category is not set then nm_category must be set.
      // Get category GUID from its name.

      if (DebugFile.trace)
        DebugFile.writeln("Connection.prepareStatement(SELECT " +
                          DB.gu_category + "," + DB.gu_owner +
                          " FROM " + DB.k_categories +
                          " WHERE " + DB.nm_category + "='" + get(nm_category) +
                          "')");
      oStmt = oConn.prepareStatement("SELECT " + DB.gu_category + "," + DB.gu_owner +
                                     " FROM " + DB.k_categories +
                                     " WHERE " + DB.nm_category + "=?",
                                     ResultSet.TYPE_FORWARD_ONLY,
                                     ResultSet.CONCUR_READ_ONLY);
      oStmt.setObject(1, get(nm_category), Types.VARCHAR);
      oRSet = oStmt.executeQuery();
      if (oRSet.next()) {
        sLastCategoryName = (String) get(nm_category);
        sLastCategoryGuid = sCatGuid = oRSet.getString(1);
        sLastOwnGuid = oRSet.getString(2);
      }
      else {
        sCatGuid = null;
        sLastCategoryGuid = sLastCategoryName = "";
      }
      oRSet.close();
      oStmt.close();

      if (null == sCatGuid)
        if (DebugFile.trace) DebugFile.decIdent();
      throw new SQLException("ProductLoader.store() Category " + get(nm_category) + " not found", "01S06");
    }

    if (null == aValues[gu_product]) {

      // ********************************************************************************
      // If gu_product is not set then check whether the product reference already exists

      if (null != getColNull(id_ref) && test(iFlags, NO_DUPLICATED_REFERENCES)) {
        sPrdGuid = Product.getIdFromReference(oConn, getColNull(id_ref),
                                              sWorkArea);
        // If reference does not exist then it is a new Product
        bNewPrd = (sPrdGuid != null);
      }
      else if (test(iFlags, NO_DUPLICATED_NAMES)) {
        // If there is no Product reference but no duplicated names are allowed,
        // then look for a product with the same name
        sPrdGuid = Product.getIdFromName(oConn, getColNull(nm_product),
                                         sWorkArea);
        // If a Product with same name does not exist then it is a new Product
        bNewPrd = (sPrdGuid != null);
      }
      else {
        // If there is no reference nor no duplicated product names is set then
        // this must be a new product
        bNewPrd = true;
        sPrdGuid = Gadgets.generateUUID();
      }
      put(gu_product, (sPrdGuid != null ? sPrdGuid : Gadgets.generateUUID()));
    }
    else {
      bNewPrd = false;
    }

    if (DebugFile.trace) DebugFile.writeln((bNewPrd ? "new" : "existing")+" gu_product="+get(gu_product));

    if (bNewPrd) {

      // ************************
      // If this is a new product

      if (null == getColNull(gu_address)) {
        if (DebugFile.trace)
          DebugFile.writeln("Connection.prepareStatement(SELECT " +
                            DB.gu_address + " FROM " + DB.k_products +
                            " WHERE " + DB.gu_product + "='" + get(gu_product) + "')");

        oStmt = oConn.prepareStatement("SELECT " + DB.gu_address + " FROM " +
                                       DB.k_products + " WHERE " +
                                       DB.gu_product + "=?",
                                       ResultSet.TYPE_FORWARD_ONLY, ResultSet.CONCUR_READ_ONLY);
        oStmt.setObject(1, get(gu_product), Types.CHAR);
        oRSet = oStmt.executeQuery();
        if (oRSet.next()) {
          sAdrGuid = oRSet.getString(1);
          if (oRSet.wasNull()) sAdrGuid = null;
        }
        else {
          sAdrGuid = null;
        }
        if ( (null == sAdrGuid) &&
            (aValues[nm_street] != null || aValues[tx_addr1] != null ||
             aValues[id_country] != null || aValues[nm_country] != null ||
             aValues[id_state] != null || aValues[nm_state] != null ||
             aValues[mn_city] != null || aValues[zip_code] != null ||
             aValues[work_phone] != null || aValues[direct_phone] != null ||
             aValues[home_phone] != null || aValues[mov_phone] != null ||
             aValues[po_box] != null || aValues[tx_email] != null ||
             aValues[url_addr] != null || aValues[coord_x] != null)) {
          sAdrGuid = Gadgets.generateUUID();
          bNewAdr = true;
        }
        else {
          bNewAdr = false;
        }
        put(gu_address, sAdrGuid);
      }
      else {
        bNewAdr = false;
      } // fi (gu_address==null)

      if (DebugFile.trace) DebugFile.writeln((bNewAdr ? "new" : "existing")+" gu_address="+get(gu_address));

      if (null != aValues[gu_address]) {
        storeAddress(oConn, sWorkArea);
      }

      insertProduct(oConn, sLastOwnGuid);

      if (null != aValues[id_fare]) storeFare(oConn, true);

      storeAttr(oConn, true);

      storeLocation(oConn, sLastOwnGuid, true);

      storeKeywords(oConn, true);

      oCatgInsr.setString(1, sLastCategoryGuid);
      oCatgInsr.setObject(2, aValues[gu_product], Types.CHAR);
      if (null == aValues[od_position])
        oCatgInsr.setInt(3, 0);
      else
        oCatgInsr.setObject(3, aValues[od_position], Types.INTEGER);
      oCatgInsr.executeUpdate();

    }
    else {

      // ****************************
      // If this is not a new product

      bNewAdr = aValues[nm_street] != null || aValues[tx_addr1] != null ||
          aValues[id_country] != null || aValues[nm_country] != null ||
          aValues[id_state] != null || aValues[nm_state] != null ||
          aValues[mn_city] != null || aValues[zip_code] != null ||
          aValues[work_phone] != null || aValues[direct_phone] != null ||
          aValues[home_phone] != null || aValues[mov_phone] != null ||
          aValues[po_box] != null || aValues[tx_email] != null ||
          aValues[url_addr] != null || aValues[coord_x] != null;

      if (bNewAdr) {
        put(gu_address, Gadgets.generateUUID());
      }

      if (null != aValues[gu_address]) {
        storeAddress(oConn, sWorkArea);
      }

      updateProduct(oConn, sLastOwnGuid);

      if (null != aValues[id_fare]) storeFare(oConn, false);

      storeAttr(oConn, false);

      storeLocation(oConn, sLastOwnGuid, false);

      storeKeywords(oConn, false);

      oCatgDlte.setObject(1, aValues[gu_product], Types.CHAR);
      oCatgDlte.executeUpdate();

      oCatgInsr.setString(1, sLastCategoryGuid);
      oCatgInsr.setObject(2, aValues[gu_product], Types.CHAR);
      if (null == aValues[od_position])
        oCatgInsr.setInt(3, 0);
      else
        oCatgInsr.setObject(3, aValues[od_position], Types.INTEGER);
      oCatgInsr.executeUpdate();

    } // fi (!bNewPrd)
  } // store

  // ---------------------------------------------------------------------------

  public static final int MODE_APPEND = ImportLoader.MODE_APPEND;
  public static final int MODE_UPDATE = ImportLoader.MODE_UPDATE;
  public static final int MODE_APPENDUPDATE = ImportLoader.MODE_APPENDUPDATE;
  public static final int WRITE_LOOKUPS = ImportLoader.WRITE_LOOKUPS;

  public static final int WRITE_ADDRESSES = 128;
  public static final int NO_DUPLICATED_NAMES = 256;
  public static final int NO_DUPLICATED_REFERENCES = 512;

  // ---------------------------------------------------------------------------

  // Keep this list sorted
  private static final String[] ColumnNames = { "", "adult_rated","alturl","author","availability","bo_active","brand","client","color","contact_person","coord_x","coord_y","country","country_code","cover","days_to_deliver","de_prod_locat","de_product","department","direct_phone","disk_space","display","doc_no","dt_acknowledge","dt_created","dt_end","dt_expire","dt_modified","dt_out","dt_start","dt_uploaded","email","fax","fax_phone","forward_to","gu_address","gu_blockedby","gu_category","gu_location","gu_owner","gu_product","gu_user","home_phone","icq_id","id_cont_type","id_country","id_currency","id_fare","id_language","id_prod_type","id_ref","id_state","id_status","ip_addr","is_compound","is_tax_included","isbn","ix_address","len_file","memory","mn_city","mobilephone","mov_phone","nm_category","nm_company","nm_country","nm_product","nm_state","nm_street","nu_current_stock","nu_lines","nu_min_stock","nu_reserved_stock","nu_street","od_position","office","ordinal","organization","other_phone","pages","paragraphs","pct_tax_rate","pg_prod_locat","phone1","phone2","po_box","power","pr_discount","pr_list","pr_purchase","pr_sale","product_group","project","rank","reference_id","revised_by","rooms","scope","signature","size_x","size_y","size_z","speed","state","state_code","status","subject","tag_prod_locat","tag_product","target","template","tp_fare","tp_location","tp_street","tx_addr1","tx_addr2","tx_email","tx_email_alt","tx_keywords","tx_remarks","tx_salutation","typeof","upload_by","url_addr","vs_stamp","weight","words","work_phone","xanchor","xfile","xhost","xoriginalfile","xpath","xport","xprotocol","zip_code" };

  public static int adult_rated = 1;
  public static int alturl = 2;
  public static int author = 3;
  public static int availability = 4;
  public static int bo_active = 5;
  public static int brand = 6;
  public static int client = 7;
  public static int color = 8;
  public static int contact_person = 9;
  public static int coord_x = 10;
  public static int coord_y = 11;
  public static int country = 12;
  public static int country_code = 13;
  public static int cover = 14;
  public static int days_to_deliver = 15;
  public static int de_prod_locat = 16;
  public static int de_product = 17;
  public static int department = 18;
  public static int direct_phone = 19;
  public static int disk_space = 20;
  public static int display = 21;
  public static int doc_no = 22;
  public static int dt_acknowledge = 23;
  public static int dt_created = 24;
  public static int dt_end = 25;
  public static int dt_expire = 26;
  public static int dt_modified = 27;
  public static int dt_out = 28;
  public static int dt_start = 29;
  public static int dt_uploaded = 30;
  public static int email = 31;
  public static int fax = 32;
  public static int fax_phone = 33;
  public static int forward_to = 34;
  public static int gu_address = 35;
  public static int gu_blockedby = 36;
  public static int gu_category = 37;
  public static int gu_location = 38;
  public static int gu_owner = 39;
  public static int gu_product = 40;
  public static int gu_user = 41;
  public static int home_phone = 42;
  public static int icq_id = 43;
  public static int id_cont_type = 44;
  public static int id_country = 45;
  public static int id_currency = 46;
  public static int id_fare = 47;
  public static int id_language = 48;
  public static int id_prod_type = 49;
  public static int id_ref = 50;
  public static int id_state = 51;
  public static int id_status = 52;
  public static int ip_addr = 53;
  public static int is_compound = 54;
  public static int is_tax_included = 55;
  public static int isbn = 56;
  public static int ix_address = 57;
  public static int len_file = 58;
  public static int memory = 59;
  public static int mn_city = 60;
  public static int mobilephone = 61;
  public static int mov_phone = 62;
  public static int nm_category = 63;
  public static int nm_company = 64;
  public static int nm_country = 65;
  public static int nm_product = 66;
  public static int nm_state = 67;
  public static int nm_street = 68;
  public static int nu_current_stock = 69;
  public static int nu_lines = 70;
  public static int nu_min_stock = 71;
  public static int nu_reserved_stock = 72;
  public static int nu_street = 73;
  public static int od_position = 74;
  public static int office = 75;
  public static int ordinal = 76;
  public static int organization = 77;
  public static int other_phone = 78;
  public static int pages = 79;
  public static int paragraphs = 80;
  public static int pct_tax_rate = 81;
  public static int pg_prod_locat = 82;
  public static int phone1 = 83;
  public static int phone2 = 84;
  public static int po_box = 85;
  public static int power = 86;
  public static int pr_discount = 87;
  public static int pr_list = 88;
  public static int pr_purchase = 89;
  public static int pr_sale = 90;
  public static int product_group = 91;
  public static int project = 92;
  public static int rank = 93;
  public static int reference_id = 94;
  public static int revised_by = 95;
  public static int rooms = 96;
  public static int scope = 97;
  public static int signature = 98;
  public static int size_x = 99;
  public static int size_y = 100;
  public static int size_z = 101;
  public static int speed = 102;
  public static int state = 103;
  public static int state_code = 104;
  public static int status = 105;
  public static int subject = 106;
  public static int tag_prod_locat = 107;
  public static int tag_product = 108;
  public static int target = 109;
  public static int template = 110;
  public static int tp_fare = 111;
  public static int tp_location = 112;
  public static int tp_street = 113;
  public static int tx_addr1 = 114;
  public static int tx_addr2 = 115;
  public static int tx_email = 116;
  public static int tx_email_alt = 117;
  public static int tx_keywords = 118;
  public static int tx_remarks = 119;
  public static int tx_salutation = 120;
  public static int typeof = 121;
  public static int upload_by = 122;
  public static int url_addr = 123;
  public static int vs_stamp = 124;
  public static int weight = 125;
  public static int words = 126;
  public static int work_phone = 127;
  public static int xanchor = 128;
  public static int xfile = 129;
  public static int xhost = 130;
  public static int xoriginalfile = 131;
  public static int xpath = 132;
  public static int xport = 133;
  public static int xprotocol = 134;
  public static int zip_code = 135;

}

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

package com.knowgate.scheduler;

import java.sql.ResultSet;
import java.sql.ResultSetMetaData;
import java.sql.SQLException;
import java.sql.Statement;
import java.sql.PreparedStatement;
import java.sql.Types;

import java.util.Map;
import java.util.Iterator;

import com.knowgate.jdc.JDCConnection;
import com.knowgate.dataobjs.DB;
import com.knowgate.dataobjs.DBPersist;
import com.knowgate.debug.DebugFile;
import com.knowgate.misc.Gadgets;

/**
 * <p>Job Atom</p>
 * Atoms hold single transaction units for Jobs.
 * @author Sergio Montoro Ten
 * @version 1.0
 */
public class Atom extends DBPersist {

  public Atom() {
    super(DB.k_job_atoms,"Atom");
  }

  /**
   * <p>Load Atom from an open ResultSet</p>
   * When loading an Atom standard aliases are created for several database fields.<br>
   * These aliases allow referencing database fields from document templates with a
   * user friendly syntax.<br>
   * When processing the Atom, all document references will be resolved to actual database
   * values for corresponding fields.<br>
   * <table border=1 cellpadding=4>
   * <tr><td><b>Database Field</b></td><td><b>English Alias</b></td><td><b>Spanish Alias</b></td></tr>
   * <tr><td>gu_company</td><td>Data.Company_Guid</td><td>Datos.Guid_Empresa</td></tr>
   * <tr><td>gu_contact</td><td>Data.Contact_Guid</td><td>Datos.Guid_Contacto</td></tr>
   * <tr><td>tx_name</td><td>Data.Name</td><td>Datos.Nombre</td></tr>
   * <tr><td>tx_surname</td><td>Data.Surname</td><td>Datos.Apellidos</td></tr>
   * <tr><td>tx_salutation</td><td>Data.Salutation</td><td>Datos.Saludo</td></tr>
   * <tr><td>nm_commercial</td><td>Data.Legal_Name</td><td>Datos.Razon_Social</td></tr>
   * <tr><td>tx_pwd</td><td>Data.Password</td><td>Datos.Password</td></tr>
   * <tr><td>url_addr</td><td>Address.URL</td><td>Direccion.URL</td></tr>
   * <tr><td>tx_email</td><td>Address.EMail</td><td>Direccion.EMail</td></tr>
   * <tr><td>tp_street</td><td>Address.Street_Type</td><td>Direccion.Tipo_Via</td></tr>
   * <tr><td>nm_street</td><td>Address.Street_Name</td><td>Direccion.Nombre_Via</td></tr>
   * <tr><td>nu_street</td><td>Address.Street_Num</td><td>Direccion.Numero_Via</td></tr>
   * <tr><td>tx_addr1</td><td>Address.Line1</td><td>Direccion.Linea1</td></tr>
   * <tr><td>tx_addr2</td><td>Address.Line2</td><td>Direccion.Linea2</td></tr>
   * <tr><td>nm_country</td><td>Address.Country</td><td>Direccion.Pais</td></tr>
   * <tr><td>nm_state</td><td>Address.State</td><td>Direccion.Provincia</td></tr>
   * <tr><td>mn_city</td><td>Address.City</td><td>Direccion.Ciudad</td></tr>
   * <tr><td>zipcode</td><td>Address.Zipcode</td><td>Direccion.Codigo_Postal</td></tr>
   * <tr><td>fax_phone</td><td>Address.Fax_Phone</td><td>Direccion.Telf_Fax</td></tr>
   * <tr><td>work_phone</td><td>Address.Proffesional_Phone</td><td>Direccion.Telf_Profesional</td></tr>
   * </table>
   * @param oRow Open ResultSet positioned at the row that must be loaded in this Atom
   * @param oMetaData ResultSetMetaData
   * @throws SQLException
   */
  public Atom(ResultSet oRow, ResultSetMetaData oMetaData) throws SQLException {
    super(DB.k_job_atoms, "Atom");

    int iCols = oMetaData.getColumnCount();
    String sCol;

    for (int c=1; c<=iCols; c++) {

      sCol = oMetaData.getColumnName(c);
      oRow.getObject(c);

      if (!oRow.wasNull()) {

        if (sCol.equalsIgnoreCase(DB.gu_company)) {
          put(DB.gu_company, oRow.getString(c));
          put("Data.Company_Guid", oRow.getString(c));
          put("Datos.Guid_Empresa", oRow.getString(c));        	
        }
        else if (sCol.equalsIgnoreCase(DB.gu_contact)) {
          put(DB.gu_contact, oRow.getString(c));
          put("Data.Contact_Guid", oRow.getString(c));
          put("Datos.Guid_Contacto", oRow.getString(c));        	
        }
        else if (sCol.equalsIgnoreCase(DB.tx_name)) {

          put(DB.tx_name, oRow.getString(c));
          put("Data.Name", oRow.getString(c));
          put("Datos.Nombre", oRow.getString(c));
        }
        else if (sCol.equalsIgnoreCase(DB.tx_surname)) {

          put(DB.tx_surname, oRow.getString(c));
          put("Data.Surname", oRow.getString(c));
          put("Datos.Apellidos", oRow.getString(c));
        }
        else if (sCol.equalsIgnoreCase(DB.tx_salutation)) {

          put(DB.tx_salutation, oRow.getString(c));
          put("Data.Salutation", oRow.getString(c));
          put("Datos.Saludo", oRow.getString(c));
        }
        else if (sCol.equalsIgnoreCase(DB.tx_pwd)) {

            put(DB.tx_pwd, oRow.getString(c));
            put("Data.Password", oRow.getString(c));
            put("Datos.Password", oRow.getString(c));
          }
        else if (sCol.equalsIgnoreCase(DB.nm_commercial)) {

          put(DB.nm_commercial, oRow.getString(c));
          put("Data.Legal_Name", oRow.getString(c));
          put("Datos.Razon_Social", oRow.getString(c));
        }
        else if (sCol.equalsIgnoreCase(DB.tx_email)) {

          put(DB.tx_email, oRow.getString(c));
          put("Address.EMail", oRow.getString(c));
          put("Direccion.EMail", oRow.getString(c));
        }
        else if (sCol.equalsIgnoreCase(DB.tp_street)) {

          put(DB.tp_street, oRow.getString(c));
          put("Address.Street_Type", oRow.getString(c));
          put("Direccion.Tipo_Via", oRow.getString(c));
        }
        else if (sCol.equalsIgnoreCase(DB.nm_street)) {

          put(DB.nm_street, oRow.getString(c));
          put("Address.Street_Name", oRow.getString(c));
          put("Direccion.Nombre_Via", oRow.getString(c));
        }
        else if (sCol.equalsIgnoreCase(DB.nu_street)) {

          put(DB.nu_street, oRow.getString(c));
          put("Address.Street_Num", oRow.getString(c));
          put("Direccion.Numero_Via", oRow.getString(c));
        }
        else if (sCol.equalsIgnoreCase(DB.tx_addr1)) {

          put(DB.tx_addr1, oRow.getString(c));
          put("Address.Line1", oRow.getString(c));
          put("Direccion.Linea1", oRow.getString(c));
        }
        else if (sCol.equalsIgnoreCase(DB.tx_addr2)) {

          put(DB.tx_addr2, oRow.getString(c));
          put("Address.Line2", oRow.getString(c));
          put("Direccion.Linea2", oRow.getString(c));
        }
        else if (sCol.equalsIgnoreCase(DB.nm_country)) {

          put(DB.nm_country, oRow.getString(c));
          put("Address.Country", oRow.getString(c));
          put("Direccion.Pais", oRow.getString(c));
        }
        else if (sCol.equalsIgnoreCase(DB.nm_state)) {

          put(DB.nm_state, oRow.getString(c));
          put("Address.State", oRow.getString(c));
          put("Direccion.Provincia", oRow.getString(c));
        }
        else if (sCol.equalsIgnoreCase(DB.mn_city)) {

          put(DB.mn_city, oRow.getString(c));
          put("Address.City", oRow.getString(c));
          put("Direccion.Ciudad", oRow.getString(c));
        }
        else if (sCol.equalsIgnoreCase(DB.zipcode)) {

          put(DB.zipcode, oRow.getString(c));
          put("Address.Zipcode", oRow.getString(c));
          put("Direccion.Codigo_Postal", oRow.getString(c));
        }
        else if (sCol.equalsIgnoreCase(DB.work_phone)) {

          put(DB.work_phone, oRow.getString(c));
          put("Address.Proffesional_Phone", oRow.getString(c));
          put("Direccion.Telf_Profesional", oRow.getString(c));
        }
        else if (sCol.equalsIgnoreCase(DB.fax_phone)) {

          put(DB.fax_phone, oRow.getString(c));
          put("Address.Fax_Phone", oRow.getString(c));
          put("Direccion.Telf_Fax", oRow.getString(c));
        }
        else if (sCol.equalsIgnoreCase(DB.mov_phone)) {

          put(DB.mov_phone, oRow.getString(c));
          put("Address.Mobile_Phone", oRow.getString(c));
          put("Direccion.Telf_Movil", oRow.getString(c));
        }
        else if (sCol.equalsIgnoreCase(DB.url_addr)) {

          put(DB.url_addr, oRow.getString(c));
          put("Address.URL", oRow.getString(c));
          put("Direccion.URL", oRow.getString(c));
        }
        else if (sCol.equalsIgnoreCase(DB.tx_parameters))

          // Si el campo recibido se llama tx_parameters
          // parsearlo para convertir en propiedades del objeto Atom
          // los campos empotrados dentro del texto.
          parseParameters(oRow.getString(c));

        else
          put(oMetaData.getColumnName(c).toLowerCase(), oRow.getString(c));

      } // fi (wasNull())
    } // next (c)
  }
  
  // ----------------------------------------------------------

  /**
   * <p>Load Atom from an open ResultSet</p>
   * When loading an Atom standard aliases are created for several database fields.<br>
   * These aliases allow referencing database fields from document templates with a
   * user friendly syntax.<br>
   * When processing the Atom, all document references will be resolved to actual database
   * values for corresponding fields.<br>
   * <table border=1 cellpadding=4>
   * <tr><td><b>Database Field</b></td><td><b>English Alias</b></td><td><b>Spanish Alias</b></td></tr>
   * <tr><td>gu_company</td><td>Data.Company_Guid</td><td>Datos.Guid_Empresa</td></tr>
   * <tr><td>gu_contact</td><td>Data.Contact_Guid</td><td>Datos.Guid_Contacto</td></tr>
   * <tr><td>tx_name</td><td>Data.Name</td><td>Datos.Nombre</td></tr>
   * <tr><td>tx_surname</td><td>Data.Surname</td><td>Datos.Apellidos</td></tr>
   * <tr><td>tx_salutation</td><td>Data.Salutation</td><td>Datos.Saludo</td></tr>
   * <tr><td>nm_commercial</td><td>Data.Legal_Name</td><td>Datos.Razon_Social</td></tr>
   * <tr><td>tx_pwd</td><td>Data.Password</td><td>Datos.Password</td></tr>
   * <tr><td>url_addr</td><td>Address.URL</td><td>Direccion.URL</td></tr>
   * <tr><td>tx_email</td><td>Address.EMail</td><td>Direccion.EMail</td></tr>
   * <tr><td>tp_street</td><td>Address.Street_Type</td><td>Direccion.Tipo_Via</td></tr>
   * <tr><td>nm_street</td><td>Address.Street_Name</td><td>Direccion.Nombre_Via</td></tr>
   * <tr><td>nu_street</td><td>Address.Street_Num</td><td>Direccion.Numero_Via</td></tr>
   * <tr><td>tx_addr1</td><td>Address.Line1</td><td>Direccion.Linea1</td></tr>
   * <tr><td>tx_addr2</td><td>Address.Line2</td><td>Direccion.Linea2</td></tr>
   * <tr><td>nm_country</td><td>Address.Country</td><td>Direccion.Pais</td></tr>
   * <tr><td>nm_state</td><td>Address.State</td><td>Direccion.Provincia</td></tr>
   * <tr><td>mn_city</td><td>Address.City</td><td>Direccion.Ciudad</td></tr>
   * <tr><td>zipcode</td><td>Address.Zipcode</td><td>Direccion.Codigo_Postal</td></tr>
   * <tr><td>fax_phone</td><td>Address.Fax_Phone</td><td>Direccion.Telf_Fax</td></tr>
   * <tr><td>work_phone</td><td>Address.Proffesional_Phone</td><td>Direccion.Telf_Profesional</td></tr>
   * </table>
   * @param oRow Open ResultSet positioned at the row that must be loaded in this Atom
   * @param oMetaData ResultSetMetaData
   * @throws SQLException
   * @since 7.0
   */
  public Atom(Map<String,Object> mCols) throws SQLException {
    super(DB.k_job_atoms, "Atom");

    String sCol;
    Object oCol;

    Iterator<String> oKeys = mCols.keySet().iterator();    
    while (oKeys.hasNext()) {

      sCol = oKeys.next();
      oCol = mCols.get(sCol);

      if (oCol!=null) {

        if (sCol.equalsIgnoreCase(DB.gu_company)) {
          put(DB.gu_company, oCol.toString());
          put("Data.Company_Guid", oCol.toString());
          put("Datos.Guid_Empresa", oCol.toString());        	
        }
        else if (sCol.equalsIgnoreCase(DB.gu_contact)) {
          put(DB.gu_contact, oCol.toString());
          put("Data.Contact_Guid", oCol.toString());
          put("Datos.Guid_Contacto", oCol.toString());
        }
        else if (sCol.equalsIgnoreCase(DB.tx_name)) {

          put(DB.tx_name, oCol.toString());
          put("Data.Name", oCol.toString());
          put("Datos.Nombre", oCol.toString());
        }
        else if (sCol.equalsIgnoreCase(DB.tx_surname)) {

          put(DB.tx_surname, oCol.toString());
          put("Data.Surname", oCol.toString());
          put("Datos.Apellidos", oCol.toString());
        }
        else if (sCol.equalsIgnoreCase(DB.tx_salutation)) {

          put(DB.tx_salutation, oCol.toString());
          put("Data.Salutation", oCol.toString());
          put("Datos.Saludo", oCol.toString());
        }
        else if (sCol.equalsIgnoreCase(DB.nm_commercial)) {

          put(DB.nm_commercial, oCol.toString());
          put("Data.Legal_Name", oCol.toString());
          put("Datos.Razon_Social", oCol.toString());
        }
        else if (sCol.equalsIgnoreCase(DB.tx_pwd)) {
          put(DB.tx_pwd, oCol.toString());
          put("Data.Password", oCol.toString());
          put("Datos.Password", oCol.toString());
        }
        else if (sCol.equalsIgnoreCase(DB.tx_email)) {

          put(DB.tx_email, oCol.toString());
          put("Address.EMail", oCol.toString());
          put("Direccion.EMail", oCol.toString());
        }
        else if (sCol.equalsIgnoreCase(DB.tp_street)) {

          put(DB.tp_street, oCol.toString());
          put("Address.Street_Type", oCol.toString());
          put("Direccion.Tipo_Via", oCol.toString());
        }
        else if (sCol.equalsIgnoreCase(DB.nm_street)) {

          put(DB.nm_street, oCol.toString());
          put("Address.Street_Name", oCol.toString());
          put("Direccion.Nombre_Via", oCol.toString());
        }
        else if (sCol.equalsIgnoreCase(DB.nu_street)) {

          put(DB.nu_street, oCol.toString());
          put("Address.Street_Num", oCol.toString());
          put("Direccion.Numero_Via", oCol.toString());
        }
        else if (sCol.equalsIgnoreCase(DB.tx_addr1)) {

          put(DB.tx_addr1, oCol.toString());
          put("Address.Line1", oCol.toString());
          put("Direccion.Linea1", oCol.toString());
        }
        else if (sCol.equalsIgnoreCase(DB.tx_addr2)) {

          put(DB.tx_addr2, oCol.toString());
          put("Address.Line2", oCol.toString());
          put("Direccion.Linea2", oCol.toString());
        }
        else if (sCol.equalsIgnoreCase(DB.nm_country)) {

          put(DB.nm_country, oCol.toString());
          put("Address.Country", oCol.toString());
          put("Direccion.Pais", oCol.toString());
        }
        else if (sCol.equalsIgnoreCase(DB.nm_state)) {

          put(DB.nm_state, oCol.toString());
          put("Address.State", oCol.toString());
          put("Direccion.Provincia", oCol.toString());
        }
        else if (sCol.equalsIgnoreCase(DB.mn_city)) {

          put(DB.mn_city, oCol.toString());
          put("Address.City", oCol.toString());
          put("Direccion.Ciudad", oCol.toString());
        }
        else if (sCol.equalsIgnoreCase(DB.zipcode)) {

          put(DB.zipcode, oCol.toString());
          put("Address.Zipcode", oCol.toString());
          put("Direccion.Codigo_Postal", oCol.toString());
        }
        else if (sCol.equalsIgnoreCase(DB.work_phone)) {

          put(DB.work_phone, oCol.toString());
          put("Address.Proffesional_Phone", oCol.toString());
          put("Direccion.Telf_Profesional", oCol.toString());
        }
        else if (sCol.equalsIgnoreCase(DB.fax_phone)) {

          put(DB.fax_phone, oCol.toString());
          put("Address.Fax_Phone", oCol.toString());
          put("Direccion.Telf_Fax", oCol.toString());
        }
        else if (sCol.equalsIgnoreCase(DB.mov_phone)) {

          put(DB.mov_phone, oCol.toString());
          put("Address.Mobile_Phone", oCol.toString());
          put("Direccion.Telf_Movil", oCol.toString());
        }
        else if (sCol.equalsIgnoreCase(DB.url_addr)) {

          put(DB.url_addr, oCol.toString());
          put("Address.URL", oCol.toString());
          put("Direccion.URL", oCol.toString());
        }
        else if (sCol.equalsIgnoreCase(DB.tx_parameters))

          // Si el campo recibido se llama tx_parameters
          // parsearlo para convertir en propiedades del objeto Atom
          // los campos empotrados dentro del texto.
          parseParameters((String) oCol);

        else
          put(sCol.toLowerCase(), oCol);

      } // fi (wasNull())
    } // next (c)
  }

  // ----------------------------------------------------------
  
  private void parseParameters(String sTxParams) {
    String aVariable[];
    String aParams[] = Gadgets.split(sTxParams, ",");

    for (int p=0; p<aParams.length; p++) {
      aVariable = Gadgets.split(aParams[p], ":");
      put(aVariable[0], aVariable[1]);
    } // next (p)

  } // parseParameters

  // ----------------------------------------------------------

  /**
   * <p>Move Atom from k_job_atoms table to k_job_atoms_archived</p>
   * @param oConn Database Connection
   * @throws SQLException
   */
  public void archive(JDCConnection oConn) throws SQLException {
    String sWhere, sSQL;
    Statement oStmt;

    if (DebugFile.trace) {
       DebugFile.writeln("Begin Atom.archive([Connection:"+oConn.pid()+"])");
       DebugFile.incIdent();
     }

    oStmt = oConn.createStatement();

    sWhere = " WHERE gu_job='" + getString(DB.gu_job) + "' AND pg_atom=" + String.valueOf(getInt(DB.pg_atom));

    sSQL = "INSERT INTO " + DB.k_job_atoms_archived + " (" + COLUMNS_LIST + ") " +
           "SELECT " + COLUMNS_LIST + " FROM " + DB.k_job_atoms + sWhere;

    if (DebugFile.trace) DebugFile.writeln("Statement.executeUpdate(" + sSQL + ")");

    oStmt.executeUpdate(sSQL);

    sSQL = "DELETE FROM " + DB.k_job_atoms + sWhere;

    if (DebugFile.trace) DebugFile.writeln("Statement.executeUpdate(" + sSQL + ")");

    oStmt.executeUpdate(sSQL);

    oStmt.close();

    if (DebugFile.trace) {
       DebugFile.decIdent();
       DebugFile.writeln("End Atom.archive()");
     }

  } // archive

  // ----------------------------------------------------------

  /**
   * Set atom status both in memory and at table k_job_atoms
   * @param oConn JDCConnection
   * @param iStatus short [STATUS_ABORTED | STATUS_FINISHED | STATUS_PENDING | STATUS_SUSPENDED | STATUS_RUNNING | STATUS_INTERRUPTED]
   * @param sLog Text to be logged as the cause of status change
   * @throws SQLException
   * @throws NullPointerException
   * @throws NumberFormatException
   */
  public void setStatus (JDCConnection oConn, short iStatus, String sLog)
    throws SQLException, NullPointerException,NumberFormatException {

    if (DebugFile.trace) {
       DebugFile.writeln("Begin Atom.setStatus([Connection:"+oConn.pid()+"], "+String.valueOf(iStatus)+", "+sLog+")");
       DebugFile.incIdent();
     }

    if (isNull(DB.gu_job))
      throw new NullPointerException("Atom.setStatus() Job GUID not set");
    if (isNull(DB.pg_atom))
      throw new NullPointerException("Atom.setStatus() Atom ordinal not set");

    int iPgAtom = getInt(DB.pg_atom);

    PreparedStatement oStmt = oConn.prepareStatement("UPDATE "+DB.k_job_atoms+" SET "+DB.id_status+"=?,"+DB.tx_log+"=? WHERE "+DB.gu_job+"=? AND "+DB.pg_atom+"=?");
    oStmt.setShort(1, iStatus);
    if (null==sLog)
      oStmt.setNull(2, Types.VARCHAR);
    else
      oStmt.setString(2, Gadgets.left(sLog,254));
    oStmt.setString(3, getString(DB.gu_job));
    oStmt.setInt(4, iPgAtom);
    oStmt.executeUpdate();
    oStmt.close();

    replace(DB.id_status, iStatus);

    if (sLog==null)
      remove(DB.tx_log);
    else
      replace(DB.tx_log, sLog);

    if (DebugFile.trace) {
       DebugFile.decIdent();
       DebugFile.writeln("End Atom.setStatus()");
     }
  } // setStatus
  	
  // ----------------------------------------------------------

  public static final short STATUS_ABORTED = Job.STATUS_ABORTED;
  public static final short STATUS_FINISHED = Job.STATUS_FINISHED;
  public static final short STATUS_PENDING = Job.STATUS_PENDING;
  public static final short STATUS_SUSPENDED = Job.STATUS_SUSPENDED;
  public static final short STATUS_RUNNING = Job.STATUS_RUNNING;
  public static final short STATUS_INTERRUPTED = Job.STATUS_INTERRUPTED;

  public static final String COLUMNS_LIST = DB.gu_job + "," + DB.pg_atom + "," + DB.dt_execution + "," + DB.id_status + "," + DB.id_format + "," + DB.gu_company + "," + DB.gu_contact + "," + DB.tx_email + "," + DB.tx_name + "," + DB.tx_surname + "," + DB.tx_salutation + "," + DB.nm_commercial + "," + DB.tp_street + "," + DB.nm_street + "," + DB.nu_street + "," + DB.tx_addr1 + "," + DB.tx_addr2 + "," + DB.nm_country + "," + DB.nm_state + "," + DB.mn_city	 + "," + DB.zipcode	 + "," + DB.work_phone + "," + DB.direct_phone + "," + DB.home_phone + "," + DB.mov_phone + "," + DB.fax_phone + "," + DB.other_phone + "," + DB.po_box + "," + DB.tx_log;

} // Atom

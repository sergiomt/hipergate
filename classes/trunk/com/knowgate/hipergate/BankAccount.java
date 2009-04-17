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

package com.knowgate.hipergate;

import java.sql.SQLException;
import java.sql.Statement;

import com.knowgate.debug.DebugFile;
import com.knowgate.jdc.JDCConnection;
import com.knowgate.dataobjs.DB;
import com.knowgate.dataobjs.DBBind;
import com.knowgate.dataobjs.DBPersist;

/**
 * <p>Bank Account</p>
 * @author Sergio Montoro Ten
 * @version 3.0
 */

public class BankAccount extends DBPersist {
  public BankAccount() {
    super(DB.k_bank_accounts, "BankAccount");
  }

  /**
   * <p>Delete Bank Account</p>
   * Associations of the bank account with companies and contacts are erased before deleting it.
   * @param oConn JDBC Database Connection
   * @throws SQLException
   */
  public boolean delete (JDCConnection oConn)
    throws SQLException {
    Statement oStmt;
    boolean bRetVal;

    if (DebugFile.trace) {
      DebugFile.writeln("Begin BankAccount.delete([Connection])");
      DebugFile.incIdent();
    }

    if (DBBind.exists(oConn, DB.k_x_company_bank, "U")) {
      oStmt = oConn.createStatement();

      if (DebugFile.trace)
        DebugFile.writeln("Statement.executeUpdate(DELETE FROM " + DB.k_x_company_bank + " WHERE " + DB.nu_bank_acc + "='" + getStringNull(DB.nu_bank_acc, "") + "' AND " + DB.gu_workarea + "='" + getStringNull(DB.gu_workarea, "") + "')");

      oStmt.executeUpdate("DELETE FROM " + DB.k_x_company_bank + " WHERE " + DB.nu_bank_acc + "='" + getStringNull(DB.nu_bank_acc, "") + "' AND " + DB.gu_workarea + "='" + getStringNull(DB.gu_workarea, "") + "'");
      oStmt.close();
    }

    if (DBBind.exists(oConn, DB.k_x_contact_bank, "U")) {
      oStmt = oConn.createStatement();

      if (DebugFile.trace)
        DebugFile.writeln("Statement.executeUpdate(DELETE FROM " + DB.k_x_contact_bank + " WHERE " + DB.nu_bank_acc + "='" + getStringNull(DB.nu_bank_acc, "") + "' AND " + DB.gu_workarea + "='" + getStringNull(DB.gu_workarea, "") + "')");

      oStmt.executeUpdate("DELETE FROM " + DB.k_x_contact_bank + " WHERE " + DB.nu_bank_acc + "='" + getStringNull(DB.nu_bank_acc, "") + "' AND " + DB.gu_workarea + "='" + getStringNull(DB.gu_workarea, "") + "'");
      oStmt.close();
    }

    bRetVal = super.delete(oConn);

    if (DebugFile.trace) {
      DebugFile.decIdent();
      DebugFile.writeln("End BankAccount.delete() : " + String.valueOf(bRetVal));
    }

    return bRetVal;
  } // delete

  public String getString(String sKey) throws NullPointerException {
    return AllVals.get(sKey).toString().trim();
  }

  public String getStringNull(String sKey, String sDefault) {
    Object oVal;
    if (AllVals.containsKey(sKey)) {
      oVal = AllVals.get(sKey);
      if (null==oVal)
        return sDefault;
      else
        return oVal.toString().trim();
    }
    else
      return sDefault;
  }

  /**
   * Return 20 digits bank account formated as XXXX XXXX XX XXXXXXXXXX
   * @return String
   * @throws NullPointerException if nu_bank_acc is <b>null</b>
   * @throws StringIndexOutOfBoundsException if nu_bank_acc length is not 20 characters
   */
  public String format20()
    throws NullPointerException, StringIndexOutOfBoundsException {
    if (isNull(DB.nu_bank_acc))
      throw new NullPointerException("BankAccount.format20() Bank account may not be null");
    else if (getString(DB.nu_bank_acc).length()!=20)
      throw new StringIndexOutOfBoundsException("BankAccount.format20 can only be called on 20 digits bank accounts");
    else {
      String a = getString(DB.nu_bank_acc);
      return a.substring(0,4)+" "+a.substring(4,8)+" "+a.substring(8,10)+" "+a.substring(10);
    }
  } // format20

  /**
   * Get control digits for 20 digits bank account
   * @return String 2 digits control number
   * @throws IllegalArgumentException if account length is not 20 characters
   * @throws NullPointerException if account is <b>null</b>
   * @since 3.0
   */
  public String getBankAccountDC()
    throws IllegalArgumentException,NullPointerException {
    if (isNull(DB.nu_bank_acc))
      throw new NullPointerException("BankAccount.getBankAccountDC() Bank account may not be null");
    String sBankAcc = getString(DB.nu_bank_acc);
    if (sBankAcc.length()!=20)
      throw new IllegalArgumentException("BankAccount.getBankAccountDC() Bank account must be of 20 characters");
    return BankAccount.getBankAccountDC(sBankAcc.substring(0,4),sBankAcc.substring(4,8), sBankAcc.substring(10));
  } // getBankAccountDC()

  /**
   * Get control digit for a bank account number
   * @param sAccountNumber String 10 digits bank account number
   * @return int Control digit [0..9]
   * @throws IllegalArgumentException if sAccountNumber length is not 10 characters
   * @throws NullPointerException if sAccountNumber is <b>null</b>
   * @since 3.0
   */
  public static int getBankAccountCtrl(String sAccountNumber)
    throws IllegalArgumentException,NullPointerException {
    int ccc;
    int suma = 0;
    int contpesos = 10;
    int[] mintpesos = new int[]{0, 6, 3, 7, 9, 10, 5, 8, 4, 2, 1};

    if (sAccountNumber.length()!=10)
      throw new IllegalArgumentException("BankAccount.getBankAccountCtrl() Bank account number must be 10 digits");

    for (int d=0; d<10; d++) {
      suma += (mintpesos[contpesos] * Integer.parseInt(sAccountNumber.substring(d,1)));
      contpesos-=1;
    } // next

    ccc = 11 - (suma % 11);
    if (ccc==10) ccc=1;
    if (ccc==11) ccc=0;

    return ccc;
  } // getBankAccountCtrl

  /**
   * Get control digits for full bank account entity+office+number
   * @param sEntity String 4 digits entity code
   * @param sOffice String 4 digits office code
   * @param sAccountNumber String 10 digits account number
   * @return String 2 digits control number
   * @since 3.0
   */
  public static String getBankAccountDC(String sEntity, String sOffice, String sAccountNumber)
    throws IllegalArgumentException,NullPointerException {
    if (sEntity.length()!=4)
      throw new IllegalArgumentException("BankAccount.getBankAccountDC() Bank Entity code must be 4 digits");
    if (sOffice.length()!=4)
      throw new IllegalArgumentException("BankAccount.getBankAccountDC() Bank office code must be 4 digits");
    return String.valueOf(getBankAccountCtrl("00" + sEntity + sOffice)) + String.valueOf(getBankAccountCtrl(sAccountNumber));
  } // getBankAccountDC

  // **********************************************************
  // Public Constants

  public static final short ClassId = 8;

}

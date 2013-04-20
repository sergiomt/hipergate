/*
  Copyright (C) 2003-2008  Know Gate S.L. All rights reserved.
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

package com.knowgate.acl;

import java.io.InputStream;

import java.sql.SQLException;
import java.sql.CallableStatement;
import java.sql.PreparedStatement;
import java.sql.ResultSet;

import java.util.Date;
import java.util.Properties;

import com.knowgate.debug.DebugFile;
import com.knowgate.jdc.JDCConnection;
import com.knowgate.misc.MD5;
import com.knowgate.misc.Base64Encoder;
import com.knowgate.misc.Base64Decoder;

/**
 *
 * <p>Top Level User Authentication and Access Control List Functions.</p>
 * @author Sergio Montoro Ten
 * @version 4.0
 */
public final class ACL {

  /**
   * Default Constructor
   */
  public ACL() {
  }

  /**
   * <p>Check if a captcha matches its signature and it has not expired</p>
   * @param lTimestamp Timestamp (in miliseconds) when sPlainCaptcha was generated
   * @param lTimemout Number of miliseconds after which sPlainCaptcha expires
   * @param sPlainCaptcha Captcha plain text
   * @param sPlainCaptchaMD5 Precomputed MD5 hash for String sPlainCaptcha+ACL.getRC4key()
   * @return
   * <ul>
   * <li> 0 (zero) means that the given key correspond to the captcha text and that it has not expired
   * <li>ACL.CAPTCHA_MISMATCH The computed MD5 hash for sPlainCaptcha+lTimestamp does not match sTimeCaptchaMD5
   * <li>ACL.CAPTCHA_TIMEOUT lTimestamp+lTimeout is before current datetime
   * </ul>
   * @since 4.0
   */
  public static short checkCaptcha(long lTimestamp, long lTimeout,
  								   String sPlainCaptcha, String sPlainCaptchaMD5) {
    short iRetVal;
    long lNow = new Date().getTime();
    if (lTimestamp+lTimeout<lNow) {
      iRetVal = CAPTCHA_TIMEOUT;
    } else {
      MD5 oCaptchaMd5 = new MD5(sPlainCaptcha+ACL.getRC4key());
      if (sPlainCaptchaMD5.equalsIgnoreCase(oCaptchaMd5.asHex()))
	    iRetVal = (short) 0;
	  else
        iRetVal = CAPTCHA_MISMATCH;
    } // fi (lTimestamp+lCaptchaTimeout<lNow)
    return iRetVal;
  } // checkCaptcha

  /**
   * <p>Checks whether or not password is valid for given user.</p>
   * <p>This method calls k_sp_autenticate stored procedure witch looks up tx_pwd field at k_users table and see if it is the same as sAuthStr parameter.</p>
   * @param oConn Opened Database Connection
   * @param sUserId User GUID
   * @param sAuthStr Authentication String (password)
   * @param iFlags Authentication String Flags
   * <ul>
   * <li>ACL.PWD_CLEAR_TEXT Authentication String is passed as clear text (no encryption)
   * <li>ACL.PWD_DTIP_RC4 Authentication String is given encrypted using RC4 algorithm
   * <li>ACL.PWD_DTIP_RC4_64 Authentication String is given encrypted using RC4 algorithm and base64 encoded
   * </ul>
   * @return
   * <ul>
   * <li>ACL.USER_NOT_FOUND sUserId not found at gu_user field from k_users table
   * <li>ACL.INVALID_PASSWORD sAuthStr parameter does not match tx_pwd field from k_users for sUserId
   * <li>ACL.PASSWORD_EXPIRED Password has expired (dt_pwd_expires field value is before current date)
   * <li>ACL.ACCOUNT_DEACTIVATED User account as been deactivated (field bo_active from k_users table set to zero)
   * <li>ACL.ACCOUNT_CANCELLED User account as been cancelled (field dt_cancel from k_users table set to date before now)
   * <li>ACL.INTERNAL_ERROR Internal error while trying to autenticate user
   * </ul>
   * @throws SQLException
   * @throws UnsupportedOperationException If k_sp_autenticate stored procedure is not found
   */

  public static short autenticate (JDCConnection oConn, String sUserId, String sAuthStr, int iFlags)
      throws SQLException, UnsupportedOperationException {
    short iStatus;
    CallableStatement oCall;
    PreparedStatement oStmt;
    ResultSet oRSet;
    String sPassword;

    if (DebugFile.trace) {
      DebugFile.writeln("Begin ACL.autenticate([Connection], " + sUserId + "," + sAuthStr + "," + iFlags + ")" );
      DebugFile.incIdent();
    }

    sPassword = decript(sAuthStr, iFlags);

    switch (oConn.getDataBaseProduct()) {

      case JDCConnection.DBMS_ORACLE:

        if (DebugFile.trace) DebugFile.writeln("  Connection.prepareCall({ call k_sp_autenticate (" + sUserId + "," + sPassword + ",?)})");

        oCall = oConn.prepareCall("{ call k_sp_autenticate (?,?,?)}");

        oCall.setString(1,sUserId);
        oCall.setString(2,sPassword);
        oCall.registerOutParameter(3, java.sql.Types.DECIMAL);

        if (DebugFile.trace) DebugFile.writeln("  java.sql.Connection.execute()");

        oCall.execute();
        iStatus = Short.parseShort(oCall.getBigDecimal(3).toString());
        oCall.close();
        break;

      case JDCConnection.DBMS_MSSQL:
      case JDCConnection.DBMS_MYSQL:

        if (DebugFile.trace) DebugFile.writeln("  Connection.prepareCall({ call k_sp_autenticate (" + sUserId + "," + sPassword + ",?)})");

        oCall = oConn.prepareCall("{ call k_sp_autenticate (?,?,?)}");

        oCall.setString(1,sUserId);
        oCall.setString(2,sPassword);
        oCall.registerOutParameter(3, java.sql.Types.SMALLINT);

        if (DebugFile.trace) DebugFile.writeln("  java.sql.Connection.execute()");

        oCall.execute();
        iStatus = oCall.getShort(3);
        oCall.close();
        break;

        case JDCConnection.DBMS_POSTGRESQL:
          oStmt = oConn.prepareStatement("SELECT k_sp_autenticate(?,?)", ResultSet.TYPE_FORWARD_ONLY, ResultSet.CONCUR_READ_ONLY);

          if (DebugFile.trace) DebugFile.writeln("  Statement.executeQuery(SELECT k_sp_autenticate('" + sUserId + "', '" + sPassword + "', ...))");

		  oStmt.setString(1, sUserId);
		  oStmt.setString(2, sPassword);		  
          oRSet = oStmt.executeQuery();
          oRSet.next();
          iStatus = oRSet.getShort(1);
          oRSet.close();
          oStmt.close();
          break;

        default:
          throw new UnsupportedOperationException("k_sp_autenticate procedure not found");
    }

    if (DebugFile.trace) {
      DebugFile.decIdent();
      DebugFile.writeln("End ACL.autenticate() : " + iStatus);
    }

    return iStatus;
  } // autenticate

  /**
   * <p>Checks password and captcha for a given user </p>
   * <p>This method calls k_sp_autenticate stored procedure witch looks up tx_pwd field at k_users table and see if it is the same as sAuthStr parameter.</p>
   * <p>Also it checks that the given captcha text corresponds to its signature and that it has not expired.</p>
   * @param oConn Opened Database Connection
   * @param sUserId User GUID
   * @param sAuthStr Authentication String (password)
   * @param iFlags Authentication String Flags
   * @param lTimestamp Timestamp (in miliseconds) when sPlainCaptcha was generated
   * @param lTimemout Number of miliseconds after which sPlainCaptcha expires
   * @param sPlainCaptcha Captcha plain text
   * @param sPlainCaptchaMD5 Precomputed MD5 hash for String sPlainCaptcha+ACL.getRC4key()
   * @return This method returns the same values as autenticate(JDCConnection,String,String,int) and also
   * <ul>
   * <li>ACL.CAPTCHA_MISMATCH The computed MD5 hash for sPlainCaptcha+lTimestamp does not match sTimeCaptchaMD5
   * <li>ACL.CAPTCHA_TIMEOUT lTimestamp+lTimeout is before current datetime
   * </ul>
   * @throws SQLException
   * @throws UnsupportedOperationException If k_sp_autenticate stored procedure is not found
   * @since 2.2
   */

  public static short autenticate (JDCConnection oConn, String sUserId,
                                   String sAuthStr, int iFlags,
                                   long lTimestamp, long lTimeout,
                                   String sPlainCaptcha,
                                   String sPlainCaptchaMD5)
    throws SQLException, UnsupportedOperationException {
    short iRetVal = autenticate(oConn, sUserId, sAuthStr, iFlags);
    if (iRetVal>=(short)0) {
      iRetVal = checkCaptcha(lTimestamp,lTimeout,sPlainCaptcha,sPlainCaptchaMD5);
    }
    return iRetVal;
  } // autenticate

  /**
   * <p>Decrypt String</p>
   * @param sStr Base64 encoded string to be decriptted
   * @param iFlags Encryption flags
   * <ul>
   * <li>ACL.PWD_CLEAR_TEXT Do not encrypt sStr (return as it is given)
   * <li>ACL.PWD_DTIP_RC4 Encrypt using RC4 algorithm
   * <li>ACL.PWD_DTIP_RC4_64 Decrypt by decoding base64 input and then using RC4 algorithm
   * </ul>
   * @return Decrypted string
   * @throws NullPointerException if sStr is <b>null</b>
   * @throws IllegalArgumentException if iFlags!=PWD_CLEAR_TEXT AND iFlags!=PWD_DTIP_RC4 AND iFlags!=PWD_DTIP_RC4_64
   * @since 4.0
   */

  public static String decript (String sStr, int iFlags)
    throws IllegalArgumentException, NullPointerException {

    String sDecrypted;

    if (iFlags!=PWD_CLEAR_TEXT && iFlags!=PWD_DTIP_RC4 && iFlags!=PWD_DTIP_RC4_64)
      throw new IllegalArgumentException("ACL.encript() encryption algorithm must be either PWD_CLEAR_TEXT or PWD_DTIP_RC4");

    if (DebugFile.trace) {
      DebugFile.writeln("Begin ACL.decript(...," + String.valueOf(iFlags) + ")" );
      DebugFile.incIdent();
    }

    if ((iFlags & ACL.PWD_DTIP_RC4)!=0) {
      RC4 oRc4 = new RC4(getRC4key());

	  // Clear Txt -RC-> Byte Array -Base64Encode-> Encryp TXT -Base64Decode-> Byte Array -RC4-> Clear TXT

	  if ((iFlags&ACL.PWD_DTIP_RC4_64)!=0)
        sDecrypted = new String(oRc4.rc4(Base64Decoder.decode(sStr)));
      else
        sDecrypted = new String(oRc4.rc4(sStr));     	
    } else {
      sDecrypted = sStr;
    }
	
    if (DebugFile.trace) {
      DebugFile.decIdent();
      DebugFile.writeln("End ACL.decript()");
    }

    return sDecrypted;
  } // decript

  /**
   * <p>Encrypt String</p>
   * @param sStr String to be encrypted
   * @param iFlags Encryption flags
   * <ul>
   * <li>ACL.PWD_CLEAR_TEXT Do not encrypt sStr (return as it is given)
   * <li>ACL.PWD_DTIP_RC4 Encrypt using RC4 algorithm
   * <li>ACL.PWD_DTIP_RC4_64 Encrypt using RC4 algorithm and then base64 encoding
   * </ul>
   * @return Encrypted string
   * @throws NullPointerException if sStr is <b>null</b>
   * @throws IllegalArgumentException if iFlags!=PWD_CLEAR_TEXT AND iFlags!=PWD_DTIP_RC4
   */

  public static String encript (String sStr, int iFlags)
    throws IllegalArgumentException, NullPointerException {

	byte[] byEncrypted = null;
    String sEncrypted;

    if (iFlags!=PWD_CLEAR_TEXT && iFlags!=PWD_DTIP_RC4 && iFlags!=PWD_DTIP_RC4_64)
      throw new IllegalArgumentException("ACL.encript() encryption algorithm must be either PWD_CLEAR_TEXT or PWD_DTIP_RC4");

    if (DebugFile.trace) {
      DebugFile.writeln("Begin ACL.encript(...," + String.valueOf(iFlags) + ")" );
      DebugFile.incIdent();
    }

    if ((iFlags & ACL.PWD_DTIP_RC4)!=0) {
      RC4 oRc4 = new RC4(getRC4key());
      
      byEncrypted = oRc4.rc4(sStr);

	  if ((iFlags&ACL.PWD_DTIP_RC4_64)!=0) {
	    sEncrypted = Base64Encoder.encode(byEncrypted);
	  } else {
	    sEncrypted = new String(byEncrypted);
	  }
    }
    else {
      sEncrypted = sStr;
    }

    if (DebugFile.trace) {
      DebugFile.decIdent();
      DebugFile.writeln("End ACL.encript()");
    }

    return sEncrypted;
  } // encript

  /**
   * <p>Get user unique id given its nickname.</p>
   * <p>Calls k_get_user_from_nick stored procedure and gets gu_user field from tx_nickname field</p>
   * @param oConn Database Connection
   * @param sNickName User nickname (tx_nickname from k_users table)
   * @param iDomain Domain Identifier (id_domain from k_users table)
   * @return User Unique Identifier (gu_user from k_users table)
   * @throws SQLException
   */
  public static String getUserIdFromNick (JDCConnection oConn, String sNickName, int iDomain) throws SQLException {
    String sUserId;

    if (oConn.getDataBaseProduct()==JDCConnection.DBMS_POSTGRESQL) {
      PreparedStatement oStmt = oConn.prepareStatement(
          "SELECT gu_user FROM k_users WHERE id_domain=? AND tx_nickname=?",
          ResultSet.TYPE_FORWARD_ONLY, ResultSet.CONCUR_READ_ONLY);
      oStmt.setInt(1, iDomain);
      oStmt.setString(2, sNickName);
      ResultSet oRSet = oStmt.executeQuery();
      if (oRSet.next())
        sUserId = oRSet.getString(1);
      else
        sUserId = null;
      oRSet.close();
      oStmt.close();
    }
    else {
      CallableStatement oCall = oConn.prepareCall("{ call k_get_user_from_nick (?,?,?)}");

      oCall.setInt(1, iDomain);
      oCall.setString(2, sNickName);
      oCall.registerOutParameter(3, java.sql.Types.CHAR);

      oCall.execute();

      if (JDCConnection.DBMS_ORACLE==oConn.getDataBaseProduct()) {
        sUserId = oCall.getString(3);
        if (null!=sUserId) sUserId = sUserId.trim();
      }
      else
        sUserId = oCall.getString(3);

      oCall.close();
    }

    return sUserId;
  } // getUserIdFromNick

  // ---------------------------------------------------------------------------

  /**
   * <p>Get RC4 default key for encryption</p>
   * Since version 4.0, the RC4 key may be readed from file acl.cnf
   * instead of being just hardwired inside ACL Java class as a
   * private static variable.
   * @return The value of property RC4PWD from acl.cnf file
   * or a default key if acl.cnf is not found or does not
   * contain a RC4PWD property. If RC4PWD has been changed by
   * calling setRC4key() then the new value is returned until
   * the class is reloaded.
   */
  public static String getRC4key() {
	if (null==RC4PWD){
	  try {
		InputStream oIoStrm = new ACL().getClass().getResourceAsStream("acl.cnf");
		if (oIoStrm!=null) {
		  Properties oProps = new Properties();
		  oProps.load(oIoStrm);
		  RC4PWD = oProps.getProperty("RC4PWD");
	  	  if (null==RC4PWD) {
	  	    if (DebugFile.trace) DebugFile.writeln("Warning: Cannot find property RC4PWD at file acl.cnf, setting signature key to default value");
	  	  }
		} else {
	  	  if (DebugFile.trace) DebugFile.writeln("Warning: Cannot load file acl.cnf, setting signature key to default value");
		}
	  } catch (Exception xcpt) {
	  	if (DebugFile.trace) DebugFile.writeln("Warning: "+xcpt.getClass().getName()+" "+xcpt.getMessage()+" Cannot load RC4PWD property from acl.cnf file, setting signature key to default value");
	  } finally {
		if (null==RC4PWD) RC4PWD = "LindtExcellence%70Degustation";
	  }
	}
    return RC4PWD;
  } // getRC4key

  /**
   * Set RC4 default key for encryption
   * @param sKey
   */
  public static void setRC4key(String sKey) {
    RC4PWD = sKey;
  }

  /**
   * <p>Encrypt text using RC4 algorithm and a default encryption key</p>
   * @param sTxt Text to be encrypted
   * @return String Encrypted text
   * @throws NullPointerException if sTxt is null
   * @see {@link http://www.clarenceho.net:8123/blog/articles/2005/11/21/rc4-encryption-in-java-april-2003}
   */

  public static String RC4EnDeCrypt(String sTxt)
    throws NullPointerException {
    RC4 oRc4 = new RC4(getRC4key());
    return new String(oRc4.rc4(sTxt));
  }

  /**
   * <p>Encrypt text using RC4 algorithm</p>
   * @param sTxt Text to be encrypted
   * @param sKey Encryption key
   * @see {@link http://www.clarenceho.net:8123/blog/articles/2005/11/21/rc4-encryption-in-java-april-2003}
   */
  public static String RC4EnDeCrypt(String sTxt, String sKey) {
    RC4 oRc4 = new RC4(sKey);
    return new String(oRc4.rc4(sTxt));
  } // RC4EnDeCrypt

  /**
   * <p>Gets permissions mask descriptive name for given language</p>
   * @param iACLMask Permissions Mask, any combination of ACL.PERMISSION_ constants
   * @param sLanguage Language for localized string {"en", "es"}
   * @return
   */
  public static String getLocalizedMaskName(int iACLMask, String sLanguage) throws IllegalArgumentException {
    int iName;
    String es[] = { "Desconocido", "Listar", "Leer", "Añadir", "Añadir y Leer", "Moderar", "Modificar", "Control Total"};
    String en[] = { "Unknown", "List", "Read", "Add", "Add & Read", "Moderate", "Modify", "Full Control"};

    if (PERMISSION_LIST==iACLMask)
      iName = 1;
    else if (PERMISSION_READ==iACLMask || (PERMISSION_LIST|PERMISSION_READ)==iACLMask)
      iName = 2;
    else if (PERMISSION_ADD==iACLMask || (PERMISSION_LIST|PERMISSION_ADD)==iACLMask)
      iName = 3;
    else if ((PERMISSION_ADD|PERMISSION_READ)==iACLMask || (PERMISSION_LIST|PERMISSION_ADD|PERMISSION_READ)==iACLMask)
      iName = 4;
    else if ((PERMISSION_MODERATE)==iACLMask ||
             (PERMISSION_READ|PERMISSION_MODERATE)==iACLMask ||
             (PERMISSION_LIST|PERMISSION_READ|PERMISSION_MODERATE)==iACLMask ||
             (PERMISSION_LIST|PERMISSION_READ|PERMISSION_ADD|PERMISSION_MODERATE)==iACLMask)
      iName = 5;
    else if ((PERMISSION_MODIFY&iACLMask)!=0 && iACLMask!=2147483647)
      iName = 6;
    else if (iACLMask>=255)
      iName = 7;
    else
      iName = 0;

    if (sLanguage.compareToIgnoreCase("es")==0)
      return es[iName];
    else if (sLanguage.compareToIgnoreCase("en")==0)
      return en[iName];
    else
      throw new IllegalArgumentException ("language must be \"en\" or \"es\"");
  } // getLocalizedMaskName

  // ---------------------------------------------------------------------------

  public static String getErrorMessage(short iErrCode) {
    if (iErrCode<0) {
      switch (iErrCode) {
        case USER_NOT_FOUND:
          return "User not found";
        case INVALID_PASSWORD:
          return "Invalid password";
        case ACCOUNT_DEACTIVATED:
          return "Account deactivated";
        case SESSION_EXPIRED:
          return "Session expired";
        case DOMAIN_NOT_FOUND:
          return "Domain not found";
        case WORKAREA_NOT_FOUND:
          return "WorkArea not found";
        case WORKAREA_NOT_SET:
          return "WorkArea not set";
        case WORKAREA_ACCESS_DENIED:
          return "WorkArea access denied";
        case ACCOUNT_CANCELLED:
          return "Account cancelled";
        case PASSWORD_EXPIRED:
          return "Password expired";
        case CAPTCHA_MISMATCH:
          return "Captcha mismatch";
        case CAPTCHA_TIMEOUT:
          return "Captcha mismatch";
        case INTERNAL_ERROR:
          return "Internal error";
        default:
          return "Undefined error";
      }
    }
    else
      return "";
  } // getErrorMessage

  // ---------------------------------------------------------------------------
  // just a random string for RC4 algorithm, change for your own implementation
  private static String RC4PWD = null;

  public static final int PERMISSION_LIST = 1;
  public static final int PERMISSION_READ = 2;
  public static final int PERMISSION_ADD = 4;
  public static final int PERMISSION_DELETE = 8;
  public static final int PERMISSION_MODIFY = 16;
  public static final int PERMISSION_MODERATE = 32;
  public static final int PERMISSION_SEND = 64;
  public static final int PERMISSION_GRANT = 128;
  public static final int PERMISSION_FULL_CONTROL = 2147483647;

  public static final int ROLE_NONE = 0;
  public static final int ROLE_ADMIN = 1;
  public static final int ROLE_POWERUSER = 2;
  public static final int ROLE_USER = 4;
  public static final int ROLE_GUEST = 4;

  public static final int PWD_CLEAR_TEXT = 0;
  public static final int PWD_DTIP_RC4 = 1;
  public static final int PWD_DTIP_RC4_64 = 3;
  

  public static final short USER_NOT_FOUND = -1;
  public static final short INVALID_PASSWORD = -2;
  public static final short ACCOUNT_DEACTIVATED = -3;
  public static final short SESSION_EXPIRED = -4;
  public static final short DOMAIN_NOT_FOUND = -5;
  public static final short WORKAREA_NOT_FOUND = -6;
  public static final short WORKAREA_NOT_SET = -7;
  public static final short ACCOUNT_CANCELLED = -8;
  public static final short PASSWORD_EXPIRED = -9;
  public static final short CAPTCHA_MISMATCH = -10;
  public static final short CAPTCHA_TIMEOUT = -11;
  public static final short WORKAREA_ACCESS_DENIED = -12;
  public static final short INTERNAL_ERROR = -255;

} // ACL

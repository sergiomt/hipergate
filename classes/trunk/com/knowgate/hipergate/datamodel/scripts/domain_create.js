/**
  * Create a Domain Cloned from MODEL (1025) Domain
  * Parameters:
  @param DomainNm Name of Domain to be dropped

  * Return Values:

  * ErrorCode    -> Integer, Native Error Code (0==No Error)
  * ErrorMessage -> String , Error Message
  * ReturnValue  -> Integer, New Domain Id. (null==Domain not created)

**/

  import java.sql.SQLException;
  import java.sql.Connection;
  import java.sql.Statement;
  import java.sql.PreparedStatement;
  import java.sql.ResultSet;

  import java.math.BigDecimal;

  import java.util.Properties;
  import java.util.Vector;

  import com.knowgate.dataobjs.*;
  import com.knowgate.datacopy.DataStruct;
  import com.knowgate.acl.ACLDomain;
  import com.knowgate.hipergate.datamodel.ModelManager;

  // MODEL Domain Id.
  final int MODEL = 1025;

  Integer ReturnValue;
  Integer ErrorCode;
  String  ErrorMessage;
  String  ClonXML;

  String DomainId = String.valueOf(DBBind.nextVal(AlternativeConnection, "seq_k_domains"));

  Object[] oPKOr = { null };
  Object[] oPKTr = { null };

  Properties oParams = new Properties();
  oParams.put("DomainId", DomainId);
  oParams.put("DomainNm", DomainNm);

  com.knowgate.datacopy.DataStruct oDS = new com.knowgate.datacopy.DataStruct();

  String sDBMS = DefaultConnection.getMetaData().getDatabaseProductName();

  ModelManager oModMan = new ModelManager();
  
  try {

    if (sDBMS.equals("Microsoft SQL Server")) {
      oPKOr[0] = new Integer(MODEL);
      oPKTr[0] = new Integer(DomainId);

      ClonXML = oModMan.getResourceAsString("scripts/mssql/domain_clon.xml", "ISO8859_1");

      oDS.parse(ClonXML, oParams);
    }
    else if (sDBMS.equals("PostgreSQL")) {
      oPKOr[0] = new Integer(MODEL);
      oPKTr[0] = new Integer(DomainId);

      ClonXML = oModMan.getResourceAsString("scripts/postgresql/domain_clon.xml", "ISO8859_1");

      oDS.parse(ClonXML, oParams);
    }
    else if (sDBMS.equals("MySQL")) {
      oPKOr[0] = new Integer(MODEL);
      oPKTr[0] = new Integer(DomainId);

      ClonXML = oModMan.getResourceAsString("scripts/mysql/domain_clon.xml", "ISO8859_1");

      oDS.parse(ClonXML, oParams);
    }
    else if (sDBMS.equals("Oracle")) {
      oPKOr[0] = new BigDecimal((double) MODEL);
      oPKTr[0] = new BigDecimal(DomainId);

      ClonXML = oModMan.getResourceAsString("scripts/oracle/domain_clon.xml", "ISO8859_1");

      oDS.parse(ClonXML, oParams);
    }

    // ******************
    // DataStruct Cloning

    oDS.setOriginConnection(DefaultConnection);
    oDS.setTargetConnection(AlternativeConnection);

    oDS.insert(oPKOr, oPKTr, 1);

    oDS.clear();

    // ***************************************************************************************
    // Re-Label root category for new Domain from "Model" to capitalized first new domain name

    PreparedStatement oStmt = AlternativeConnection.prepareStatement("UPDATE " + DB.k_cat_labels + " SET " + DB.tr_category + "=? WHERE " + DB.gu_category + " IN (SELECT " + DB.gu_category + " FROM " + DB.k_categories + " WHERE " + DB.nm_category + "=? AND " + DB.gu_owner + " IN (SELECT " + DB.gu_user + " FROM " + DB.k_users + " WHERE " + DB.id_domain + "=?))");
    oStmt.setString(1, Character.toUpperCase(DomainNm.charAt(0))+DomainNm.substring(1).toLowerCase());
    oStmt.setString(2, DomainNm);
    oStmt.setInt   (3, Integer.parseInt(DomainId));
    oStmt.executeUpdate();
    oStmt.close();

    // *******************************
    // Set Home Category for each User

    Vector vGUIDs = new Vector();
    Vector vNames = new Vector();

    Statement oCats = AlternativeConnection.createStatement(ResultSet.TYPE_FORWARD_ONLY, ResultSet.CONCUR_READ_ONLY);
    ResultSet rCats = oCats.executeQuery("SELECT " + DB.gu_category + "," + DB.nm_category + " FROM " + DB.k_categories + " WHERE " + DB.gu_owner + " IN (SELECT " + DB.gu_user + " FROM " + DB.k_users + " WHERE " + DB.id_domain + "=" + DomainId + ")");
    while (rCats.next()) {
      vGUIDs.add(rCats.getObject(1));
      vNames.add(rCats.getObject(2));
    }
    rCats.close();
    oCats.close();

    // For Each Category, seek User whose nickname is the same as the end of the Category name
    // Matching between Categories and Users is done by following the convention of naming
    // every User Category like : DOMAIN_usernick_category

    oStmt = AlternativeConnection.prepareStatement("UPDATE " + DB.k_users + " SET " + DB.gu_category + "=? WHERE " + DB.id_domain + "=" + DomainId + " AND " + DB.tx_nickname + "=?");

    int iUnderscore ;
    String sCatName ;
    String sCatGUID ;
    String sNickName;

    for (int c=0; c<vGUIDs.size(); c++) {

      sCatGUID = vGUIDs.get(c).toString();
      sCatName = vNames.get(c).toString();
      iUnderscore = sCatName.indexOf("_");
      if (iUnderscore>0) {
        sNickName = sCatName.substring(iUnderscore+1);

        oStmt.setString(1, sCatGUID );
        oStmt.setString(2, sNickName);
	oStmt.executeUpdate();
      } // fi()

    } // next (c)
    oStmt.close();

    if (null!=oPKTr[0])
      ReturnValue = new Integer(oPKTr[0].toString());
    else
      ReturnValue = null;

    ErrorCode = new Integer(0);
    ErrorMessage = "Domain (" + DomainId + "," + DomainNm + ") successfully created.";
  }
  catch (java.lang.NullPointerException n) {
    ReturnValue = null;
    ErrorCode = new Integer(-1);
    ErrorMessage = "NullPointerException: " + n.getMessage();
  }
  catch (java.lang.ArrayIndexOutOfBoundsException a) {
    ReturnValue = null;
    ErrorCode = new Integer(-1);
    ErrorMessage = "ArrayIndexOutOfBoundsException: " + a.getMessage();
  }
  catch (java.sql.SQLException e) {
    ReturnValue = null;
    ErrorCode = new Integer(e.getErrorCode());
    ErrorMessage = "SQLException: " + e.getMessage();
  }
  catch (Exception x) {
    ReturnValue = null;
    ErrorCode = new Integer(-1);
    ErrorMessage = x.getClass().getName() + ": " + x.getMessage();
  }

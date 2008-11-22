/**
  * Drop Domain
  * Parameters:
  @param DomainNm New Domain Name

  * Return Values:

  * ErrorCode    -> Integer, Native Error Code (0==No Error)
  * ErrorMessage -> String , Error Message
  * ReturnValue  -> Integer, Droped Domain Id. (null==Domain not found)

**/

  import java.sql.SQLException;
  import java.sql.Connection;
  import java.sql.Statement;
  import java.sql.ResultSet;

  import com.knowgate.acl.ACLDomain;
  import com.knowgate.hipergate.datamodel.ModelManager;


  Integer ReturnValue;
  Integer ErrorCode;
  String  ErrorMessage;

  try {

    Statement oStmt;
    ResultSet oRSet;
    int iDomainId;

    oStmt = DefaultConnection.createStatement(ResultSet.TYPE_FORWARD_ONLY, ResultSet.CONCUR_READ_ONLY);
    oRSet = oStmt.executeQuery("SELECT id_domain FROM k_domains WHERE nm_domain='" + DomainNm + "'");
    if (oRSet.next())
      iDomainId = oRSet.getInt(1);
    else
      iDomainId = 0;
    oRSet.close();
    oStmt.close();

    if (0!=iDomainId) {
      com.knowgate.jdc.JDCConnection oJDC = new com.knowgate.jdc.JDCConnection(DefaultConnection, null);
      com.knowgate.acl.ACLDomain.delete(oJDC, iDomainId);

      ReturnValue = (Integer) new Integer(iDomainId);
      ErrorCode = new Integer(0);
      ErrorMessage = "Domain (" + String.valueOf(iDomainId) + "," + DomainNm + ") successfully droped.";
    }
    else {
      ReturnValue = null;
      ErrorCode = new Integer(-1);
      ErrorMessage = "Domain (" + DomainNm + ") not found.";
    }
  }
  catch (Exception e) {
    ReturnValue = null;
    ErrorCode = new Integer(e.getErrorCode());
    ErrorMessage = "Exception: " + e.getMessage();
  }


package com.knowgate.jdc;

import java.util.Date;

/**
 * Information about a process serving a connection
 * @author Sergio Montoro Ten
 * @version 3.0
 */
public class JDCProcessInfo {

  private String datid, datname, procpid, usesysid, usename, query_text;
  private Date query_start;

  private JDCProcessInfo() { }

  protected JDCProcessInfo(String sDatId, String sDatName,
                        String sProcpId, String sUserSysId,
                        String sUserName, String sQueryText,
                        Date dtQueryStart) {
    datid=sDatId;
    datname=sDatName;
    procpid=sProcpId;
    usesysid=sUserSysId;
    usename=sUserName;
    query_text=sQueryText;
    query_start=dtQueryStart;
  }

  public String getProcessId() {
    return procpid;
  }

  public String getUserName() {
    return usename;
  }

  public String getQueryText() {
    return query_text==null ? "" : query_text;
  }

  public Date getQueryStart() {
    return query_start;
  }

}

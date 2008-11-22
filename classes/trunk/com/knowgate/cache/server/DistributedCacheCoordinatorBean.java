package com.knowgate.cache.server;

import java.lang.System;
import java.util.TreeMap;

import javax.ejb.CreateException;
import javax.ejb.SessionBean;
import javax.ejb.SessionContext;

public class DistributedCacheCoordinatorBean implements SessionBean {

  private static final long serialVersionUID = 1l;

  private SessionContext sessionContext;
  private TreeMap oBTree;

  // -----------------------------------------------------------------

  public void setSessionContext(SessionContext sessionContext) {
    this.sessionContext = sessionContext;
  }

  // -----------------------------------------------------------------

  public void ejbCreate() throws CreateException {
     oBTree = new TreeMap();
  }

  // -----------------------------------------------------------------

  public void ejbRemove() {
    oBTree.clear();
    oBTree = null;
  }

  // -----------------------------------------------------------------

  public void ejbActivate() { }

  // -----------------------------------------------------------------

  public void ejbPassivate() { }

  // -----------------------------------------------------------------

  public long now() {
    return System.currentTimeMillis();
  }

  // -----------------------------------------------------------------

  public long lastModified(String sKey) {
    Long oDt = (Long) oBTree.get(sKey);

    if (oDt==null) oDt = new Long((long) 0);

    return oDt.longValue();
  }

  // -----------------------------------------------------------------

  public long modify(String sKey) {
    Long oDt = new Long(System.currentTimeMillis());

    oBTree.remove(sKey);
    oBTree.put(sKey, oDt);

    return oDt.longValue();
  }

  // -----------------------------------------------------------------

  public void expire(String sKey) {
    oBTree.remove(sKey);
  }

  // -----------------------------------------------------------------

  public void flush() {
    oBTree.clear();
  }
}
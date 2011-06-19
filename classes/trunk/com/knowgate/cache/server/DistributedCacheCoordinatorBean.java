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

package com.knowgate.cache.server;

import java.util.TreeMap;
import java.util.SortedMap;
import java.util.Collections;

import javax.ejb.CreateException;
import javax.ejb.SessionBean;
import javax.ejb.SessionContext;

public class DistributedCacheCoordinatorBean implements SessionBean {

  private static final long serialVersionUID = 1l;

  private SessionContext sessionContext;
  private SortedMap oBTree;

  // -----------------------------------------------------------------

  public void setSessionContext(SessionContext sessionContext) {
    this.sessionContext = sessionContext;
  }

  // -----------------------------------------------------------------

  public void ejbCreate() throws CreateException {
     oBTree = Collections.synchronizedSortedMap(new TreeMap());
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
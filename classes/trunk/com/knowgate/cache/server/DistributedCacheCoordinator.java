package com.knowgate.cache.server;

import java.rmi.RemoteException;

public interface DistributedCacheCoordinator extends javax.ejb.EJBObject {
  public long now() throws RemoteException;
  public long lastModified(String sKey) throws RemoteException;
  public long modify(String sKey) throws RemoteException;
  public void expire(String sKey) throws RemoteException;
  public void flush() throws RemoteException;
}
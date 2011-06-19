package com.knowgate.cache.server;


import javax.ejb.CreateException;
import javax.ejb.EJBHome;
import java.rmi.RemoteException;

public interface DistributedCacheCoordinatorHome extends EJBHome {
  public DistributedCacheCoordinator create() throws CreateException, RemoteException;
}
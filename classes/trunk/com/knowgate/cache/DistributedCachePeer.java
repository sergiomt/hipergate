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

package com.knowgate.cache;

import java.rmi.RemoteException;

import java.io.ByteArrayOutputStream;
import java.io.IOException;

import java.util.Date;
import java.util.Properties;
import java.util.Iterator;

import java.net.URL;
import java.net.MalformedURLException;

import com.knowgate.debug.DebugFile;
import com.knowgate.misc.Environment;
import com.knowgate.dataobjs.DBSubset;

/**
 * <p>Distributed Cache Local Peer</p>
 * <p>Each distributed cache peer holds its own local copy of cached data.</p>
 * <p>On the simplest scenenario there is only one client cache peer witch
 * stores data localy for faster access and reduce network bandwitch consumption.</p>
 * <p>As data is kept localy at each peer, when more than one client peer concurrently
 * access the same data, a cache coordinator becomes necessary.</p>
 * <p>The cache coordinator is an EJB that must be installed at an application server
 * such as JBoss or BEA Weblogic. See cache.DistributedCacheCoordinatorBean for more
 * information about the cache coordinator.</p>
 * <br>
 * <p><b>Distributed Cache Tokens and Policies</b></p>
 * <p>A cache peer is essentially a named set of objects. Each object name is called
 * a "cache token". Cache Token associate a String (the object name) with the actual cached object.</p>
 * <p>Token have an usage count and a last usage date, each time a token is requested its usage count
 * and last usage dates are updated at the cache peer.</p>
 * <p>The cache peer the applies a customizable Policy for discarding objects as cache becomes full.</p>
 * <p>Currently only a Least Recently Used Cache Policy is provided.</p>
 * <p>By default the cache has a maximum of 400 objects slots.</p>
 * <p>There is no checking of memory consumption for the cache peer, it is the programmer's responsability
 * not to cache objects that are too large.</p>
 * <p>It is also the programmer's task to remove tokens from the cache peer when the cached data has been changed.</p>
 * <p><b>Comunnication between client cache peers and the cache coordinator</b></p>
 * <p>The cache coordinator is a single object instance that coordinates data cached by multiple cache peers,
 * at a given time a cache peer may change data that is already cache at another peer. When doing so the last usage date
 * for the token of cached data will be updated and the cache coordinator will be notified of this last usage change.</p>
 * <p>Each cache peer holds its own copy of data, and the cache coordinator keeps a record of all
 * last usage timestamp for every object at every cache peer. In this way, cached data is not be shared among peers,
 * but it is kept synchronized by discarding all tokens witch timestamp at the peer is older than the one at the cache coordinator.</p>
 * <p><b>UML</b></p>
 * <img src="doc-files/DistributedCache-1.gif">
 * @author Sergio Montoro Ten
 * @version 4.0
 */

public final class DistributedCachePeer {

  private Object oCtx;  // javax.naming.Context
  private Object oDCC;  // cache.DistributedCacheCoordinator
  private Object oHome; // cache.DistributedCacheCoordinatorHome

  private LRUCachePolicy oCacheStore;
  private Properties oEnvProps;
  private int iProviderProtocol;

  final private int PROTOCOL_NONE = -1;
  final private int PROTOCOL_UNKNOWN = 0;
  final private int PROTOCOL_HTTP = 1;
  final private int PROTOCOL_HTTPS = 2;
  final private int PROTOCOL_JNP = 3;

  /**
   * <p>Create a local cache peer.</p>
   * <p>The cache peer may be initialized to work in single-peer mode or in
   * multi-peer mode with a cache coordinator.</p>
   * <p>Initializacion properties for connecting with the cache coordinator
   * when working in multi-peer mode are passed in appserver.cnf properties file.
   * The appserver.cnf file is read using the singleton Environment object at
   * com.knowgate.misc package.</p>
   * <p>An example of a configuration file for JBoss may be as follows:</p>
   * #DistributedCachePeer JBoss configuration file<br><br>
   * #set this entry to "disabled" is working in single-peer mode<br>
   * threetiers=enabled<br><br>
   * java.naming.factory.initial=org.jnp.interfaces.NamingContextFactory<br>
   * java.naming.provider.url=jnp://127.1.0.0:1099/<br>
   * java.naming.factory.url.pkgs=org.jboss.naming:org.jnp.interfaces<br>
   * jnp.socketFactory=org.jnp.interfaces.TimedSocketFactory<br>
   * <p>An example of a configuration file for Tomcat may be as follows:</p>
   * #DistributedCachePeer Tomcat configuration file<br><br>
   * #set this entry to "disabled" is working in single-peer mode<br>
   * threetiers=enabled<br><br>
   * java.naming.factory.initial=<br>
   * java.naming.provider.url=http://www.remotehost.com:1099/cache/server.jsp<br>
   * java.naming.factory.url.pkgs=<br>
   * jnp.socketFactory=<br>
   * @throws InstantiationException
   * @throws RemoteException
   * @see Environment
   */

  public DistributedCachePeer()
    throws InstantiationException,RemoteException {

    long lServerTime, lClientTime;
    String s3Tiers;

    if (DebugFile.trace) {
      DebugFile.writeln("Begin DistributedCachePeer()");
      DebugFile.incIdent();
    }

    oCacheStore = new LRUCachePolicy(200, 400);

    oEnvProps = Environment.getProfile("appserver");
    s3Tiers = oEnvProps.getProperty("threetiers", "disabled");

    /* Only test and debugging purposes ****************************************

    oEnvProps = new Properties();
    oEnvProps.put("java.naming.factory.initial", "org.jnp.interfaces.NamingContextFactory");
    oEnvProps.put("java.naming.provider.url", "jnp://server:1099/");
    oEnvProps.put("java.naming.factory.url.pkgs", "org.jboss.naming:org.jnp.interfaces");
    oEnvProps.put("jnp.socketFactory", "org.jnp.interfaces.TimedSocketFactory");

    ***************************************************************************/

    if (DebugFile.trace) {
      DebugFile.writeln ("java.naming.factory.initial=" + oEnvProps.getProperty("java.naming.factory.initial",""));
      DebugFile.writeln ("java.naming.provider.url=" + oEnvProps.getProperty("java.naming.provider.url",""));
      DebugFile.writeln ("java.naming.factory.url.pkgs=" + oEnvProps.getProperty("java.naming.factory.url.pkgs",""));
      DebugFile.writeln ("jnp.socketFactory=" + oEnvProps.getProperty("jnp.socketFactory",""));
    }

    if (s3Tiers.equalsIgnoreCase("enabled") || s3Tiers.equalsIgnoreCase("yes") || s3Tiers.equalsIgnoreCase("true") || s3Tiers.equalsIgnoreCase("on") || s3Tiers.equals("1")) {

      String sProviderURL = oEnvProps.getProperty("java.naming.provider.url","").toLowerCase();

      if (sProviderURL.startsWith("http://"))
        iProviderProtocol = PROTOCOL_HTTP;
      else if (sProviderURL.startsWith("https://"))
        iProviderProtocol = PROTOCOL_HTTPS;
      else if (sProviderURL.startsWith("jnp://"))
        iProviderProtocol = PROTOCOL_JNP;
      else
        iProviderProtocol = PROTOCOL_UNKNOWN;

      if (PROTOCOL_HTTP!=iProviderProtocol && PROTOCOL_HTTPS!=iProviderProtocol) {

        try {

          if (DebugFile.trace) DebugFile.writeln ("Context oCtx = new InitialContext(Properties)");

          oCtx = new javax.naming.InitialContext(oEnvProps);

          if (DebugFile.trace)
            DebugFile.writeln("oHome = (DistributedCacheCoordinatorHome) oCtx.lookup(\"DistributedCacheCoordinator\")");

          oHome = ( (javax.naming.Context) oCtx).lookup("DistributedCacheCoordinator");

          if (DebugFile.trace)
            DebugFile.writeln("DistributedCacheCoordinator = DistributedCacheCoordinatorHome.create()");

          oDCC = ( (com.knowgate.cache.server.DistributedCacheCoordinatorHome) oHome).create();

          // Sincronizar la fecha del cliente con la del servidor
          lServerTime = ( (com.knowgate.cache.server.DistributedCacheCoordinator) oDCC).now();

          lClientTime = new Date().getTime();

          if (lClientTime < lServerTime) {
            lServerTime = ( (com.knowgate.cache.server.DistributedCacheCoordinator) oDCC).now() + 1000;
            Environment.updateSystemTime(lServerTime);
          } // fi (lClientTime < lServerTime)
        }
        catch (javax.naming.NamingException ne) {
          throw new java.lang.InstantiationException("javax.naming.NamingException " + ne.getMessage() + " " + ne.getExplanation());
        }
        catch (javax.ejb.CreateException ce) {
          throw new java.lang.InstantiationException("javax.ejb.CreateException " + ce.getMessage());
        }
      } // fi (iProviderProtocol)
      else
        oDCC = null;
    } // fi (threetiers)
    else {
      iProviderProtocol = PROTOCOL_NONE;
    }

    if (DebugFile.trace) {
      DebugFile.decIdent();
      DebugFile.writeln("End new DistributedCachePeer()");
    }

  } // DistributedCachePeer

  // ----------------------------------------------------------

  private static String trim(String s) {
    if (null==s)
      return null;
    else
      return (s.replace('\n',' ').replace('\r',' ').replace('\t',' ')).trim();
  }

  // ----------------------------------------------------------

  /**
   * Get an object from the cache peer.
   * @param sTokenKey Token of object to be retrieved
   * @return Reference to the requested object or <b>null</b> if object is not present at the local cache or it was modified by another cache peer.
   * @throws RemoteException
   */

  public Object get(String sTokenKey)
    throws RemoteException,NullPointerException {

    long lLastMod;
    long lLastLocal;
    Object oRetSet = null;

    if (DebugFile.trace) {
      DebugFile.writeln("Begin DistributedCachePeer.get(" + sTokenKey + ")");
      DebugFile.incIdent();
    }

    if (PROTOCOL_NONE==iProviderProtocol)
      // Si no existe ningún coordinador de cache distribuido configurado,
      // tener en cuenta sólo el cache local.
      oRetSet = oCacheStore.get(sTokenKey);
    else
    {
      // Recuperar la entrada del cache local
      oRetSet = oCacheStore.get(sTokenKey);

      if (null!=oRetSet ) {
        // Obtener la fecha de última modificación del coordinador de caches
        if (PROTOCOL_HTTP==iProviderProtocol || PROTOCOL_HTTPS==iProviderProtocol) {

          String sProviderURL = oEnvProps.getProperty("java.naming.provider.url");

          if (null==sProviderURL)
            throw new NullPointerException("Property java.naming.provider.url not set at appserver.cnf");

          else {
            String sLastMod = "";

            try {
              if (DebugFile.trace) DebugFile.writeln("new javax.activation.DataHandler(new URL(" + sProviderURL + "?method=get&key=" + sTokenKey + "))");

              javax.activation.DataHandler oDataHndlr = new javax.activation.DataHandler(new URL(sProviderURL+"?method=get&key=" + sTokenKey));

               ByteArrayOutputStream oURLBytes = new ByteArrayOutputStream(128);
               oDataHndlr.writeTo(oURLBytes);
               sLastMod = trim(oURLBytes.toString());
               oURLBytes.close();
               oURLBytes = null;

               if (DebugFile.trace) DebugFile.writeln("lLastMod=" + sLastMod);

               lLastMod = Long.parseLong(sLastMod);
            }
            catch (MalformedURLException badurl) {
              if (DebugFile.trace) DebugFile.writeln("MalformedURLException " + sProviderURL + "?method=get&key=" + sTokenKey);

              throw new RemoteException("MalformedURLException " + sProviderURL + "?method=get&key=" + sTokenKey);
            }
            catch (IOException badurl) {
              if (DebugFile.trace) DebugFile.writeln("IOException " + sProviderURL + "?method=get&key=" + sTokenKey);

              throw new RemoteException("IOException " + sProviderURL + "?method=get&key=" + sTokenKey);
            }
            catch (NumberFormatException nume) {
              if (DebugFile.trace) DebugFile.writeln("NumberFormatException " + sLastMod);

              throw new RemoteException("NumberFormatException " + sLastMod);
            }
          }
        }
        else {
          if (DebugFile.trace) DebugFile.writeln("DistributedCacheCoordinator.lastModified(" + sTokenKey + ")");

          lLastMod = ((com.knowgate.cache.server.DistributedCacheCoordinator) oDCC).lastModified(sTokenKey);

          if (DebugFile.trace) DebugFile.writeln("lLastMod=" + String.valueOf(lLastMod));
        }

        lLastLocal = oCacheStore.last(sTokenKey);

        if (DebugFile.trace) {
          if (lLastMod==0)
            DebugFile.writeln(sTokenKey + " not found at distributed cache");
          else
            DebugFile.writeln(sTokenKey + " has timestamp " + new Date(lLastMod).toString() + " at distributed cache");

          DebugFile.writeln(sTokenKey + " has timestamp " + new Date(lLastLocal).toString() + " at local cache");
        }

        if (lLastLocal>=lLastMod) {
          // Si la fecha local es mayor o igual que la del coordinador, devolver la entrada local
          if (DebugFile.trace) DebugFile.writeln("cache hit for " + sTokenKey);
        }
        else {
          // Si la fecha local es anterior a la del coordinador, la entrada local ya no es válida
          if (DebugFile.trace) DebugFile.writeln("cache outdated for " + sTokenKey);
          oCacheStore.remove(sTokenKey);
          oRetSet = null;
        }
      } // fi(oEntry)
      else {
        if (DebugFile.trace) DebugFile.writeln("cache miss for " + sTokenKey);
      }
    } // fi(oDCC)

    if (DebugFile.trace) {
      DebugFile.decIdent();
      DebugFile.writeln("End DistributedCachePeer.get()");
    }

    return oRetSet;
  } // getDBSubset

  // ----------------------------------------------------------

  /**
   * @return Same as DistributedCachePeer.get() but cast returned object to a {@link DBSubset}.
   * @return DBSubset or <b>null</b> if no value was found cached with given token
   * @throws ClassCastException
   */
  public DBSubset getDBSubset(String sTokenKey) throws RemoteException,ClassCastException {
    Object oObj = get (sTokenKey);

    if (null==oObj)
      return null;
    else
      return (DBSubset) get(sTokenKey);
  } // getDBSubset

  // ----------------------------------------------------------

  /**
   * @param sTokenKey Token of string value to be retrieved
   * @return Same as DistributedCachePeer.get() but cast returned object to a String.
   * @return String or <b>null</b> if no value was found cached with given token
   * @throws ClassCastException
   */
  public String getString(String sTokenKey) throws RemoteException,ClassCastException {
    Object oObj = get (sTokenKey);
    if (null==oObj)
      return null;
    else
      return (String) oObj;
  } // getString

  // ----------------------------------------------------------

  /**
   * @param sTokenKey Token of boolean value to be retrieved
   * @return Boolean or <b>null</b> if no value was found cached with given token
   * @throws ClassCastException
   */
  public Boolean getBoolean(String sTokenKey) throws RemoteException, ClassCastException {
    Object oObj = get (sTokenKey);
    if (null==oObj)
      return null;
    else
      return (Boolean) oObj;
  } // getBoolean

  // ----------------------------------------------------------

  /**
   * @param sTokenKey Token of float value to be retrieved
   * @return Float or <b>null</b> if no value was found cached with given token
   * @throws ClassCastException
   * @since 4.0
   */
  public Float getFloat(String sTokenKey) throws RemoteException, ClassCastException {
    Object oObj = get (sTokenKey);
    if (null==oObj)
      return null;
    else
      return (Float) oObj;
  } // getFloat

  // ----------------------------------------------------------

  /**
   * @param sTokenKey Token of integer value to be retrieved
   * @return Integer or <b>null</b> if no value was found cached with given token
   * @throws ClassCastException
   * @since 5.0
   */
  public Integer getInteger(String sTokenKey) throws RemoteException, ClassCastException {
    Object oObj = get (sTokenKey);
    if (null==oObj)
      return null;
    else
      return (Integer) oObj;
  } // getInteger

  // ----------------------------------------------------------

  /**
   * Return keys for entries in cache
   * @return Set of keys (Strings)
   */

  public java.util.Set keySet() {

    return oCacheStore.keySet();
  }

  // ----------------------------------------------------------

  /**
   * <p>Puts an Object into local cache.</p>
   * @param sTokenKey Token for object
   * @param oObj Object to be stored.
   * @throws RemoteException
   * @throws IllegalArgumentException If either sTokenKey or oObj is <b>null</b>.
   * @throws IllegalStateException If object with given token is already present at local cache.
   */
  public void put(String sTokenKey, Object oObj)
    throws IllegalStateException, IllegalArgumentException, RemoteException {
    long lDtServerModified;

    if (DebugFile.trace) {
      DebugFile.writeln("Begin DistributedCachePeer.put(" + sTokenKey + ", ...)");
      DebugFile.incIdent();
    }

    if (PROTOCOL_NONE==iProviderProtocol)

      lDtServerModified = System.currentTimeMillis();

    else if (PROTOCOL_HTTP==iProviderProtocol || PROTOCOL_HTTPS==iProviderProtocol) {

      String sProviderURL = oEnvProps.getProperty("java.naming.provider.url");

      if (null == sProviderURL)
        throw new NullPointerException("Property java.naming.provider.url not set at appserver.cnf");

      else {
        String sServerMod = "";

        try {
          if (DebugFile.trace) DebugFile.writeln("new javax.activation.DataHandler(new URL(" + sProviderURL + "?method=put&key=" + sTokenKey + "))");

          javax.activation.DataHandler oDataHndlr = new javax.activation.DataHandler(new URL(sProviderURL + "?method=put&key=" + sTokenKey));

          ByteArrayOutputStream oURLBytes = new ByteArrayOutputStream(128);
          oDataHndlr.writeTo(oURLBytes);
          sServerMod = trim(oURLBytes.toString());
          oURLBytes.close();
          oURLBytes = null;

          if (DebugFile.trace) DebugFile.writeln("lDtServerModified=" + sServerMod);

          lDtServerModified = Long.parseLong(sServerMod);
        }
        catch (MalformedURLException badurl) {
          if (DebugFile.trace) DebugFile.writeln("MalformedURLException " + sProviderURL + "?method=get&put=" + sTokenKey);

          throw new RemoteException("MalformedURLException " + sProviderURL + "?method=put&key=" + sTokenKey);
        }
        catch (IOException badurl) {
          if (DebugFile.trace) DebugFile.writeln("IOException " + sProviderURL + "?method=get&put=" + sTokenKey);

          throw new RemoteException("IOException " + sProviderURL + "?method=get&put=" + sTokenKey);
        }
        catch (NumberFormatException nume) {
          if (DebugFile.trace) DebugFile.writeln("NumberFormatException " + sServerMod);

          throw new RemoteException("NumberFormatException " + sServerMod);
        }
      }
    }
    else {

      if (DebugFile.trace) DebugFile.writeln("DistributedCacheCoordinator.modify(" + sTokenKey + ")");

      lDtServerModified = ((com.knowgate.cache.server.DistributedCacheCoordinator) oDCC).modify(sTokenKey);

      if (DebugFile.trace) DebugFile.writeln("lDtServerModified=" + String.valueOf(lDtServerModified));

    }

    if (DebugFile.trace) DebugFile.writeln("LRUCachePolicy.insert(" + sTokenKey + ", [Object], " + String.valueOf(lDtServerModified));

    oCacheStore.insert (sTokenKey, oObj, lDtServerModified);

    if (DebugFile.trace) {
      DebugFile.decIdent();
      DebugFile.writeln("End DistributedCachePeer.put()");
    }
  } // put

  // ----------------------------------------------------------

  /**
   * <p>Puts a DBSubset into local cache.</p>
   * @param sTokenKey Token for object
   * @param oObj Object to be stored.
   * @throws RemoteException
   * @throws IllegalArgumentException If either sTokenKey or oObj is <b>null</b>.
   * @throws IllegalStateException If object with given token is already present at local cache.
   */
  public void putDBSubset(String sTableName, String sTokenKey, DBSubset oDBSS) throws RemoteException {
    if (DebugFile.trace) {
      DebugFile.writeln("Begin DistributedCachePeer.putDBSubset(" + sTokenKey + ", ...)");
      DebugFile.incIdent();
    }

    put (sTokenKey, oDBSS);

    if (DebugFile.trace) {
      DebugFile.decIdent();
      DebugFile.writeln("End DistributedCachePeer.putDBSubset()");
    }
  } // putDBSubset
  
  // ----------------------------------------------------------

  /**
   * <b>Removes an Object from the cache and notify other cache peers that
   * the objects with the given token should no longer be considered valid.</p>
   * If Object with given token was not present at cache no error is raised.
   * @param sTokenKey Token of object to be removed from local cache.
   * @throws RemoteException
   * @throws IllegalArgumentException If sTkeney is <b>null</b>.
   * @throws IllegalStateException If local cache is empty.
   */
  public void expire(String sTokenKey) throws IllegalArgumentException, RemoteException {
    if (DebugFile.trace) {
      DebugFile.writeln("Begin DistributedCachePeer.expire(" + sTokenKey + ")");
      DebugFile.incIdent();
    }
    if (PROTOCOL_NONE!=iProviderProtocol) {

      if (PROTOCOL_HTTP==iProviderProtocol || PROTOCOL_HTTPS==iProviderProtocol) {

        String sProviderURL = oEnvProps.getProperty("java.naming.provider.url");

        if (null==sProviderURL)
          throw new NullPointerException("Property java.naming.provider.url not set at appserver.cnf");

        else {

          try {

            if (DebugFile.trace) DebugFile.writeln("new javax.activation.DataHandler(new URL(" + sProviderURL + "?method=expire&key=" + sTokenKey + "))");

            javax.activation.DataHandler oDataHndlr = new javax.activation.DataHandler(new URL(sProviderURL+"?method=expire&key=" + sTokenKey));

             ByteArrayOutputStream oURLBytes = new ByteArrayOutputStream(128);
             oDataHndlr.writeTo(oURLBytes);
             oURLBytes.close();
             oURLBytes = null;

          }
          catch (MalformedURLException badurl) {
            throw new RemoteException("MalformedURLException " + sProviderURL + "?method=expire&key=" + sTokenKey);
          }
          catch (IOException badurl) {
            throw new RemoteException("IOException " + sProviderURL + "?method=get&key=" + sTokenKey);
          }
        } // fi (null!=sProviderURL)
      }
      else {
        if (DebugFile.trace) DebugFile.writeln("DistributedCacheCoordinator.expire(" + sTokenKey + ")");

        ((com.knowgate.cache.server.DistributedCacheCoordinator) oDCC).expire(sTokenKey);
      }
    }
    oCacheStore.remove(sTokenKey);

    if (DebugFile.trace) {
      DebugFile.decIdent();
      DebugFile.writeln("End DistributedCachePeer.expire()");
    }
  } // expire

  // ----------------------------------------------------------

  /**
   * <p>Remove all objects from local cache and expire then and cache coordinator.</p>
   * @throws RemoteException
   */
  public void expireAll() throws RemoteException {
    if (DebugFile.trace) {
      DebugFile.writeln("Begin DistributedCachePeer.expireAll()");
      DebugFile.incIdent();
    }
    Iterator oKeys;

    if (PROTOCOL_NONE!=iProviderProtocol) {

      oKeys = oCacheStore.m_map.keySet().iterator();

      while(oKeys.hasNext()) expire((String) oKeys.next());

    } // fi (oDCC)

    oCacheStore.flush();

    if (DebugFile.trace) {
      DebugFile.decIdent();
      DebugFile.writeln("End DistributedCachePeer.expireAll()");
    }
  } // expireAll

  // ----------------------------------------------------------

  /**
   * <p>Number of entries in cache</p>
   */
  public int size() {
    return oCacheStore.size();
  }
} // DistributedCachePeer

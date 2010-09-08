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

package com.knowgate.dataobjs;

/**
 * @author Sergio Montoro Ten
 * @version 6.0
 */

import com.knowgate.dataobjs.DBBind;

import java.awt.Image;

import java.lang.ClassNotFoundException;
import java.lang.NoSuchMethodException;

import java.beans.SimpleBeanInfo;
import java.beans.BeanDescriptor;
import java.beans.MethodDescriptor;

public class DBBindBeanInfo extends SimpleBeanInfo {

  public DBBindBeanInfo() {
  }

  public BeanDescriptor getBeanDescriptor() {
    return new BeanDescriptor(beanClass);
  }

  public Image getIcon(int iconKind) {
    switch(iconKind) {
      case SimpleBeanInfo.ICON_MONO_16x16:
        return loadImage("dbbind16m.gif");
      case SimpleBeanInfo.ICON_COLOR_16x16:
        return loadImage("dbbind16c.gif");
      case SimpleBeanInfo.ICON_MONO_32x32:
        return loadImage("dbbind32m.gif");
      case SimpleBeanInfo.ICON_COLOR_32x32:
        return loadImage("dbbind32c.gif");
    }
  return null;
  }

  public MethodDescriptor[] getMethodDescriptors() {
    try {    	
        Class voidParams[] = {  };
        Class nextValParams[] = { Class.forName("java.sql.Connection"), String.class };
        Class getTableParams[] = { String.class };
        Class getPropertyParams[] = { String.class };
        Class getProperty2Params[] = { String.class,String.class };
        Class getConnection1Params[] = { String.class };
        Class getConnection2Params[] = { String.class,String.class };
        Class escapeParams[] = { Class.forName("java.util.Date"), String.class };
        Class existsParams[] = { Class.forName("com.knowgate.jdc.JDCConnection"), String.class, String.class };
        Class getDataModelParams[] = { Class.forName("com.knowgate.jdc.JDCConnection") };

        MethodDescriptor getProfileName =
            new MethodDescriptor(DBBind.class.getMethod("getProfileName", voidParams));
        MethodDescriptor getProperties =
            new MethodDescriptor(DBBind.class.getMethod("getProperties", voidParams));
        MethodDescriptor getProperty =
            new MethodDescriptor(DBBind.class.getMethod("getProperty", getPropertyParams));
        MethodDescriptor getProperty2 =
            new MethodDescriptor(DBBind.class.getMethod("getProperty", getProperty2Params));
        MethodDescriptor restartBind =
            new MethodDescriptor(DBBind.class.getMethod("restart", voidParams));
        MethodDescriptor closeBind =
            new MethodDescriptor(DBBind.class.getMethod("close", voidParams));
        MethodDescriptor nextVal =
            new MethodDescriptor(DBBind.class.getMethod("nextVal", nextValParams));
        MethodDescriptor getTable =
            new MethodDescriptor(DBBind.class.getMethod("getTable", getTableParams));
        MethodDescriptor getConnection0 =
            new MethodDescriptor(DBBind.class.getMethod("getConnection", voidParams));
        MethodDescriptor getConnection1 =
            new MethodDescriptor(DBBind.class.getMethod("getConnection", getConnection1Params));
        MethodDescriptor getConnection2 =
            new MethodDescriptor(DBBind.class.getMethod("getConnection", getConnection2Params));
        MethodDescriptor  getDataModelVersion =
            new MethodDescriptor(DBBind.class.getMethod("getDataModelVersion", getDataModelParams));
        MethodDescriptor  getDataModelVersionNumber =
            new MethodDescriptor(DBBind.class.getMethod("getDataModelVersionNumber", getDataModelParams));
        MethodDescriptor  getDatabaseProductName =
            new MethodDescriptor(DBBind.class.getMethod("getDatabaseProductName", voidParams));
        MethodDescriptor  getTime =
            new MethodDescriptor(DBBind.class.getMethod("getTime", voidParams));
        MethodDescriptor connectionPool =
            new MethodDescriptor(DBBind.class.getMethod("connectionPool", voidParams));
        MethodDescriptor escape =
            new MethodDescriptor(DBBind.class.getMethod("escape", escapeParams));
        MethodDescriptor exists =
            new MethodDescriptor(DBBind.class.getMethod("exists", existsParams));
        MethodDescriptor toXml =
            new MethodDescriptor(DBBind.class.getMethod("toXml", voidParams));

        MethodDescriptor rv[] = { getProfileName,getProperties,getProperty,getProperty2,
        						  restartBind, closeBind, nextVal, getTable,
        						  getConnection0, getConnection1, getConnection2,
        						  getDataModelVersion, getDataModelVersionNumber,
        						  getDatabaseProductName, getTime, connectionPool, escape, exists, toXml };
        return rv;
    } catch (ClassNotFoundException e) {
         throw new Error(e.toString());
    } catch (NoSuchMethodException e) {
         throw new Error(e.toString());
    }
  }

  private final static Class beanClass = DBBind.class;
}

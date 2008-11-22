package com.knowgate.cache.server;

import java.beans.*;

import java.awt.Image;

import java.lang.ClassNotFoundException;
import java.lang.NoSuchMethodException;

public class DistributedCacheCoordinatorBeanInfo extends SimpleBeanInfo {

  public DistributedCacheCoordinatorBeanInfo() {
  }
  public PropertyDescriptor[] getPropertyDescriptors() {
    PropertyDescriptor[] pds = new PropertyDescriptor[] { };
    return pds;
  }

  public Image getIcon(int iconKind) {
    switch (iconKind) {
      case BeanInfo.ICON_COLOR_16x16:
        return loadImage("dbbind16c.gif") ;
      case BeanInfo.ICON_COLOR_32x32:
        return loadImage("dbbind32c.gif") ;
      case BeanInfo.ICON_MONO_16x16:
        return loadImage("dbbind16m.gif") ;
      case BeanInfo.ICON_MONO_32x32:
        return loadImage("dbbind32m.gif") ;
    }
    return null;
  }

  public MethodDescriptor[] getMethodDescriptors() {
    try {
        Class noParams[] = {  };
        Class strParam[] = { Class.forName("String") };

        MethodDescriptor now =
            new MethodDescriptor(DistributedCacheCoordinator.class.getMethod("now", noParams));
        MethodDescriptor lastModified =
            new MethodDescriptor(DistributedCacheCoordinator.class.getMethod("lastModified", strParam));
        MethodDescriptor modify =
            new MethodDescriptor(DistributedCacheCoordinator.class.getMethod("modify", strParam));
        MethodDescriptor expire =
            new MethodDescriptor(DistributedCacheCoordinator.class.getMethod("expire", strParam));
        MethodDescriptor flush =
            new MethodDescriptor(DistributedCacheCoordinator.class.getMethod("flush", noParams));

        MethodDescriptor rv[] =
            {now, lastModified, modify, expire, flush};
        return rv;
    } catch (ClassNotFoundException e) {
         throw new Error(e.toString());
    } catch (NoSuchMethodException e) {
         throw new Error(e.toString());
    }
  }

  private final static Class beanClass = com.knowgate.cache.server.DistributedCacheCoordinator.class;

}
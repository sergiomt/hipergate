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

import com.knowgate.dataobjs.DB;

import java.awt.Image;

import java.beans.SimpleBeanInfo;
import java.beans.BeanDescriptor;
import java.beans.MethodDescriptor;

public class DBBeanInfo extends SimpleBeanInfo {

  public DBBeanInfo() {
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
    MethodDescriptor rv[] = {};
    return rv;
  }

  private final static Class beanClass = DB.class;
}
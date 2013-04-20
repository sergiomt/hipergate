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

package com.knowgate.hipergate;

import java.awt.Image;

import java.lang.ClassNotFoundException;
import java.lang.NoSuchMethodException;

import java.beans.SimpleBeanInfo;
import java.beans.BeanDescriptor;
import java.beans.MethodDescriptor;

/**
 * @author Sergio Montoro Ten
 * @version 4.0
 */
public class DBLanguagesBeanInfo extends SimpleBeanInfo {

  public DBLanguagesBeanInfo() {
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
        Class SQLConnection = Class.forName("java.sql.Connection");
        Class JDCConnection = Class.forName("com.knowgate.jdc.JDCConnection");
        Class LangString = Class.forName("java.lang.String");
        Class UtilHashMap = Class.forName("java.util.HashMap");
        Class DistribCache = Class.forName("com.knowgate.cache.DistributedCacheClient");

        Class toHTMLSelectParams[] = { SQLConnection, LangString };

        MethodDescriptor toHTMLSelect =
            new MethodDescriptor(DBLanguages.class.getMethod("toHTMLSelect", toHTMLSelectParams));

        Class getHTMLCountrySelectParams[] = { JDCConnection, LangString };

        Class getStateSelectParams[] = { JDCConnection, LangString, LangString };

        Class getTermSelectParams[] = { JDCConnection, int.class, LangString };

        Class getTermSelectWithScopeParams[] = { JDCConnection, int.class, LangString, LangString };
        
        MethodDescriptor getHTMLCountrySelect =
            new MethodDescriptor(DBLanguages.class.getMethod("getHTMLCountrySelect", getHTMLCountrySelectParams));

        MethodDescriptor getHTMLStateSelect =
            new MethodDescriptor(DBLanguages.class.getMethod("getHTMLStateSelect", getStateSelectParams));

        MethodDescriptor getHTMLTermSelect =
            new MethodDescriptor(DBLanguages.class.getMethod("getHTMLTermSelect", getTermSelectParams));

        MethodDescriptor getHTMLTermSelectWithScope =
                new MethodDescriptor(DBLanguages.class.getMethod("getHTMLTermSelect", getTermSelectWithScopeParams));

        MethodDescriptor getPlainTextStateList =
            new MethodDescriptor(DBLanguages.class.getMethod("getPlainTextStateList", getStateSelectParams));

        Class getHTMLSelectLookUpParams1[] = { JDCConnection, LangString, LangString, LangString, LangString };

        Class getHTMLSelectLookUpParams2[] = { DistribCache, JDCConnection, LangString, LangString, LangString, LangString };

        Class getHTMLSelectLookUpParams3[] = { JDCConnection, LangString, LangString, LangString, LangString, LangString };

        MethodDescriptor getHTMLSelectLookUp1 =
            new MethodDescriptor(DBLanguages.class.getMethod("getHTMLSelectLookUp", getHTMLSelectLookUpParams1));

        MethodDescriptor getHTMLSelectLookUp2 =
            new MethodDescriptor(DBLanguages.class.getMethod("getHTMLSelectLookUp", getHTMLSelectLookUpParams2));

        MethodDescriptor getHTMLSelectLookUp3 =
            new MethodDescriptor(DBLanguages.class.getMethod("getHTMLSelectLookUp", getHTMLSelectLookUpParams3));

        Class getLookUpTranslationParams[] = { SQLConnection, LangString, LangString, LangString, LangString, LangString };

        Class getLookUpMapParams[] = { SQLConnection, LangString, LangString, LangString, LangString, LangString };

        Class nextLookuUpProgressiveParams[] = {SQLConnection, LangString, LangString, LangString};

        MethodDescriptor getLookUpTranslation =
            new MethodDescriptor(DBLanguages.class.getMethod("getLookUpTranslation", getLookUpTranslationParams));

        MethodDescriptor getLookUpMap =
            new MethodDescriptor(DBLanguages.class.getMethod("getLookUpMap", getLookUpMapParams));

        MethodDescriptor nextLookuUpProgressive =
            new MethodDescriptor(DBLanguages.class.getMethod("nextLookuUpProgressive", nextLookuUpProgressiveParams));

        Class addLookupParams[] = {SQLConnection, LangString, LangString, LangString, LangString, UtilHashMap};

        MethodDescriptor addLookup =
            new MethodDescriptor(DBLanguages.class.getMethod("addLookup", addLookupParams));

        MethodDescriptor rv[] =
            {toHTMLSelect, getHTMLSelectLookUp1, getHTMLSelectLookUp2, getHTMLSelectLookUp3, getLookUpTranslation, getLookUpMap, getHTMLCountrySelect, getHTMLStateSelect, getHTMLTermSelect, getHTMLTermSelectWithScope, getPlainTextStateList, nextLookuUpProgressive, addLookup};
        return rv;
    } catch (ClassNotFoundException e) {
         throw new Error(e.toString());
    } catch (NoSuchMethodException e) {
         throw new Error(e.toString());
    }
  }

  private final static Class beanClass = DBLanguages.class;
}

/*
  Copyright (C) 2009  Know Gate S.L. All rights reserved.
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

package com.knowgate.yahoo;

import java.net.URL;
import java.io.IOException;
import java.io.ByteArrayOutputStream;
import java.io.ByteArrayInputStream;
import javax.activation.DataHandler;
import java.util.ArrayList;

import org.jibx.runtime.IBindingFactory;
import org.jibx.runtime.IUnmarshallingContext;
import org.jibx.runtime.BindingDirectory;
import org.jibx.runtime.JiBXException;

import com.knowgate.misc.Gadgets;

/**
 * Client interface for Yahoo! Search BOSS
 * @author Sergio Montoro Ten
 * @version 1.0
 */

public class Boss {

  private int responsecode;
  private String nextpage;
  private ResultsetWeb resultset;

  public int responseCode() {
    return responsecode;
  }

  public int count() {
    return resultset.count;
  }

  public ArrayList<Result> results() {
    return resultset.results;
  }

  /**
   * Search using Yahoo! BOSS
   * @param sKey Yahoo! App. Id. Key
   * @param sQuery String being searched
   * @param sSites Restrict search to selectect sites, if null no restriction is applied
   * @return YSearchResponse
   * @throws IOException
   */
  public YSearchResponse search(final String sKey, final String sQuery, final String sSites)
    throws IOException {
    YSearchResponse oYsr = null;
	URL oUrl = new URL("http://boss.yahooapis.com/ysearch/web/v1/"+Gadgets.URLEncode(sQuery)+
		               "?appid="+sKey+"&format=xml&type=html&style=raw"+
		              (sSites==null ? "" : "&sites="+sSites));
	try {
    IBindingFactory oIbf = BindingDirectory.getFactory(YSearchResponse.class);
    IUnmarshallingContext oUmc = oIbf.createUnmarshallingContext();

    ByteArrayOutputStream oOst = new ByteArrayOutputStream();
    DataHandler oHnd = new DataHandler(oUrl);
    oHnd.writeTo(oOst);
    ByteArrayInputStream oIst = new ByteArrayInputStream(oOst.toByteArray());
    oYsr = (YSearchResponse) oUmc.unmarshalDocument (oIst, "UTF8");    
    oIst.close();
    oOst.close();
	} catch (JiBXException jibxe) {
	  throw new IOException(jibxe.getMessage(), jibxe);
	}
    return oYsr;
  } // search

}

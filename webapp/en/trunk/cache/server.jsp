<%@ page language="java" session="false" contentType="text/html;charset=UTF-8" %><jsp:useBean id="CacheCoordinatorHttp" scope="application" class="java.util.TreeMap"/><%
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
  
  /* *******************************************
     Server Side Cache Coordinator Object
     This is just an application bean that
     holds a date in a TreeMap for every
     cached object. Actual object data is
     kept on local caches at client web servers
   ******************************************* */
     
  String sMethod = request.getParameter("method");
  String sKey = request.getParameter("key");
  Long   oDt;
  
  if (sMethod.equalsIgnoreCase("get")) {
    
    // Get last modification date on any client for an object
    
    oDt = (Long) CacheCoordinatorHttp.get(sKey);

    if (null==oDt)
      out.write ("0");
    else
      out.write (oDt.toString());    
  }
  else if (sMethod.equalsIgnoreCase("put")) {

    // Change last modification date for an object

    oDt = new Long(System.currentTimeMillis());

    CacheCoordinatorHttp.remove(sKey);
    CacheCoordinatorHttp.put(sKey, oDt);

    out.write (oDt.toString());
  }
  else if (sMethod.equalsIgnoreCase("expire")) {

    // Expire object

    CacheCoordinatorHttp.remove(sKey);

    out.write ("");
  }
  else {

    // Send error 400 if method is not recognized

    response.sendError(javax.servlet.http.HttpServletResponse.SC_BAD_REQUEST, "Unrecognized method " + sMethod);
  }
%>
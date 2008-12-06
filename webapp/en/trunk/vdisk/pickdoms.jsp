<%@ page import="java.sql.Connection,java.sql.SQLException,com.knowgate.jdc.*,com.knowgate.dataobjs.*" language="java" session="false" contentType="text/xml;charset=UTF-8" %>
<%@ include file="../methods/dbbind.jsp" %>
<%@ include file="../methods/cookies.jspf" %>
<%
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

  String sLanguage = getNavigatorLanguage(request);

  int iDoms;
  DBSubset oDoms;
  StringBuffer sXML;  
  JDCConnection oConn;
  
  sXML = new StringBuffer(4096);
      
  oDoms = new DBSubset (DB.k_domains + " d", DBBind.Functions.toChar("d." + DB.id_domain,6) + ",d." + DB.nm_domain, "", 100);

  oConn = GlobalDBBind.getConnection("pickdoms");
  try {
    iDoms = oDoms.load (oConn);
    oConn.close("pickdoms");
  }
  catch (SQLException e) {
    oConn.close("pickdoms");
    iDoms = 0;
    sXML.append("ERROR: " + e.getLocalizedMessage() + "\n");
  }
  oConn = null;
  
  sXML.append("<diputree>");
  sXML.append("<hasdefaulttemplate><l><haslabel><label><when><selected/></when><hascolor><rgb><i>0xFFFF00</i></rgb></hascolor><hasbackground><background><hascolor><rgb><i>0x00005F</i></rgb></hascolor></background></hasbackground></label></haslabel><hasicon><icon><when><opened/></when><hasimage><uri><s>../applets/domain.gif</s></uri></hasimage></icon><icon><when><closed/></when><hasimage><uri><s>../applets/domain.gif</s></uri></hasimage></icon></hasicon></l></hasdefaulttemplate>");
  sXML.append("<hasdispatcher><onclick><hashandler><uri><s>script:domClick();</s></uri></hashandler><hashandler><uri><s>default</s></uri></hashandler></onclick></hasdispatcher>");
  sXML.append("<has><b><lt>Dominios</lt><hasstate><opened/></hasstate><hashandle><none/></hashandle><hasicon><icon><when><opened/></when><hasimage><uri><s>../applets/domains.gif</s></uri></hasimage><when><closed/></when><hasimage><uri><s>../applets/domains.gif</s></uri></hasimage></icon></hasicon><has>");
      
  for (int i=0;i<iDoms; i++) {    
    sXML.append("<l><hasstate><closed/></hasstate><lt>" + oDoms.getString(1,i) + "</lt><haslink><link><hasdestination><target><s>" + oDoms.getString(0,i) + "</s></target></hasdestination></link></haslink></l>");
  }
    
  sXML.append("</has></b></has>");
  sXML.append("</diputree>");
            
  out.write(sXML.toString());
%>
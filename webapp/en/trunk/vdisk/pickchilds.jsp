<%@ page import="java.net.URLDecoder,java.sql.SQLException,java.sql.PreparedStatement,java.sql.ResultSet,com.knowgate.jdc.*,com.knowgate.acl.*,com.knowgate.dataobjs.*,com.knowgate.hipergate.*,com.knowgate.debug.DebugFile" language="java" session="false" contentType="text/xml;charset=UTF-8" %><%@ include file="../methods/dbbind.jsp" %><%@ include file="../methods/cookies.jspf" %><%@ include file="../methods/nullif.jspf" %><jsp:useBean id="GlobalCategories" scope="application" class="com.knowgate.hipergate.Categories"/><%
/*
  Copyright (C) 2003  Know Gate S.L. All rights reserved.
                      C/Oña 107 1º2 28050 Madrid (Spain)

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

  long lElapsed = System.currentTimeMillis();
  
  response.setIntHeader("Expires", 0);
  response.addHeader ("Pragma", "no-cache");
  response.addHeader ("cache-control", "no-store");

  String sUserId = request.getParameter("Uid");
  String sSkin = request.getParameter("Skin");  
  String sLanguage = request.getParameter("Lang");

  int iCats;
  DBSubset oCats;
  StringBuffer sXML;  
  JDCConnection oConn;
  PreparedStatement oStmt;
  ResultSet oRSet;
  Category oPrnt;
  
  int id_domain = 0;
  
  try {
    id_domain = Integer.parseInt(getCookie(request,"domainid",""));
  } catch (NumberFormatException nfe) { }
  
  String nm_domain = getCookie(request, "domainnm", "");
  String id_parent = request.getParameter("Parent");
  String tr_parent = nullif(request.getParameter("Label"));
  String id_category,tr_category,nm_icon, nm_icon2;
      
  sXML = new StringBuffer(4096);
    
  if (null==id_parent || tr_parent.equals("root")) {
  
    oConn = GlobalDBBind.getConnection("pickchilds1");

    try {
      if (null==id_parent) {
        oCats = GlobalCategories.getRootsNamed(oConn, sLanguage, GlobalCategories.ORDER_BY_NONE);
        iCats = GlobalCategories.getRootsCount();
      }
      else {
        oCats = GlobalCategories.getChildsNamed(oConn, id_parent, sLanguage, GlobalCategories.ORDER_BY_NONE);
        iCats = oCats.getRowCount();
      }
      oConn.close("pickchilds1");
    }
    catch (SQLException e) {
      if (DebugFile.trace) DebugFile.writeln("<JSP:pickchild.jsp SQLException " + e.getMessage());
      
      oConn.close("pickchilds1");
      iCats = 0;
      oCats = null;
      sXML.append("ERROR: " + e.getMessage() + "\n");
     
    }
    
    oConn = null;
    
    if (null!=oCats) {
      sXML.append("<?xml version=\"1.0\" encoding=\"UTF-8\"?>");
      sXML.append("<diputree>");
      sXML.append("<haspadding><offset><hasorigin><top/><bottom/><left/><right/></hasorigin><hasdistance><pixelcount><i>0</i></pixelcount></hasdistance></offset></haspadding>");
      sXML.append("<hasdefaulttemplate><b><hasicon><icon><when><opened/></when><hasimage><uri><s>../skins/" + sSkin + "/nav/folderopen_16x16.gif</s></uri></hasimage></icon><icon><when><closed/></when><hasimage><uri><s>../skins/" + sSkin + "/nav/folderclosed_16x16.gif</s></uri></hasimage></icon></hasicon><haslabel><label><when><selected/></when><hascolor><rgb><i>0xFFFFFF</i></rgb></hascolor><hasbackground><background><hascolor><rgb><i>0x800080</i></rgb></hascolor></background></hasbackground></label></haslabel></b></hasdefaulttemplate>");
      sXML.append("<hasdispatcher><onclick><hashandler><uri><s>script:dipuClick();</s></uri></hashandler><hashandler><uri><s>default</s></uri></hashandler></onclick></hasdispatcher>");
      sXML.append("<has>");

	    oConn = GlobalDBBind.getConnection("pickchilds3");
    
      for (int i=0;i<iCats; i++) {
        if (oCats.getString(1,i).startsWith(nm_domain) && oCats.getString(1,i).endsWith("_pwds")) {
          // Always Hide passwords category for user
        } else {
          sXML.append("<b>");
          id_category = oCats.getString(0,i);
          tr_category = oCats.getStringNull(2,i,oCats.getString(1,i));
          nm_icon = oCats.getStringNull(3,i,null);
          nm_icon2 = oCats.getStringNull(4,i,null);

			    Category oCatg = new Category(id_category);

			    if ((oCatg.getUserPermissions(oConn, sUserId)&ACL.PERMISSION_LIST)!=0) {
            if (null!=nm_icon) {
              sXML.append("<hasicon>");
              sXML.append("<icon><when><closed/></when><hasimage><uri><s>../skins/" + sSkin + "/nav/" + nm_icon + "</s></uri></hasimage></icon>");
              sXML.append("<icon><when><opened/></when><hasimage><uri><s>../skins/" + sSkin + "/nav/" + (null!=nm_icon2 ? nm_icon2 : nm_icon) + "</s></uri></hasimage></icon>");        
              sXML.append("</hasicon>");
            }
            sXML.append("<lt>" + tr_category + "</lt><hasstate><closed/></hasstate>" + "<haslink><link><hasdestination><target><s>" + id_category + "</s></target></hasdestination></link></haslink>");
            sXML.append("</b>");
          } // fi (User has at least list permission over current category)
        } // fi (nm_category.startsWith(nm_domain) && nm_category.endsWith("_pwds"))
      } // next

      if (tr_parent.equals("root") && id_domain!=1024 && id_domain!=1025) {

	    Category oDomainShared = GlobalCategories.getSharedFilesCategoryForDomain(oConn, id_domain);
	
	    if (null!=oDomainShared) {
	      int iUserPermissions = oDomainShared.getUserPermissions(oConn, sUserId);
	      if (iUserPermissions!=0) {
	        String sDomainLabel = oDomainShared.getLabel (oConn, sLanguage);
	        sXML.append("<b><lt>" + (sDomainLabel==null ? oDomainShared.getString(DB.nm_category) : sDomainLabel) + "</lt><hasicon><icon><when><closed/></when><hasimage><uri><s>../skins/" + sSkin + "/nav/" + oDomainShared.getStringNull(DB.nm_icon, "folderclosed_16x16.gif") + "</s></uri></hasimage></icon><icon><when><opened/></when><hasimage><uri><s>../skins/" + sSkin + "/nav/" + oDomainShared.getStringNull(DB.nm_icon, "folderopen_16x16.gif") + "</s></uri></hasimage></icon></hasicon><hasstate><closed/></hasstate><haslink><link><hasdestination><target><s>" + oDomainShared.getString(DB.gu_category) + "</s></target></hasdestination></link></haslink></b>");
	      }
	    }

      oConn.close("pickchilds3");

    } // fi (tr_parent=="root" && id_domain!=1024 && id_domain!=1025)
      
    sXML.append("</has>");
    sXML.append("</diputree>");
  } // fi (oCats)
    
  }
  else {
        
    oConn = GlobalDBBind.getConnection("pickchilds2");
    
    /* Caveat: Switching ordering on has a great impact on SQL Server 2000.
       The query for retrieving child categories can take up to 100 times!
       longer to execute when ORDER BY is requested */
       
    oCats = GlobalCategories.getChildsNamed(oConn, id_parent, sLanguage, GlobalCategories.ORDER_BY_NONE);
    iCats = oCats.getRowCount();
    
    oPrnt = new Category (oConn, id_parent);
    
    oConn.close("pickchilds2");
    oConn = null;
    
    sXML.append("<b>");
        
    sXML.append("<lt>" + tr_parent + "</lt>");

    if (!oPrnt.isNull(DB.nm_icon)) {	
      sXML.append("<hasicon>");
      sXML.append("<icon><when><closed/></when><hasimage><uri><s>../skins/" + sSkin + "/nav/" + oPrnt.getString(DB.nm_icon) + "</s></uri></hasimage></icon>");

      if (!oPrnt.isNull(DB.nm_icon2))        
        sXML.append("<icon><when><opened/></when><hasimage><uri><s>../skins/" + sSkin + "/nav/" + oPrnt.getString(DB.nm_icon2) + "</s></uri></hasimage></icon>");        
      else
        sXML.append("<icon><when><opened/></when><hasimage><uri><s>../skins/" + sSkin + "/nav/" + oPrnt.getString(DB.nm_icon) + "</s></uri></hasimage></icon>");        

      sXML.append("</hasicon>");
    } // fi (!isNull(DB.nm_icon))

    sXML.append("<hasstate><closed/></hasstate><haslink><link><hasdestination><target><s>" + id_parent + "</s></target></hasdestination></link></haslink>");

    sXML.append("<has>");
    
    for (int i=0;i<iCats; i++) {  
      sXML.append("<b>");
      id_category = oCats.getString(0,i);
      tr_category = (1024==id_domain ? oCats.getString(1,i) : oCats.getStringNull(2,i,oCats.getString(1,i)));
      nm_icon = oCats.getStringNull(3,i,null);
      nm_icon2 = oCats.getStringNull(4,i,null);

      if (null!=nm_icon) {
        sXML.append("<hasicon>");
        sXML.append("<icon><when><closed/></when><hasimage><uri><s>../skins/" + sSkin + "/nav/" + nm_icon + "</s></uri></hasimage></icon>");
        sXML.append("<icon><when><opened/></when><hasimage><uri><s>../skins/" + sSkin + "/nav/" + (null!=nm_icon2 ? nm_icon2 : nm_icon) + "</s></uri></hasimage></icon>");
        sXML.append("</hasicon>");
      }

      sXML.append("<lt>" + tr_category + "</lt><hasstate><closed/></hasstate><haslink><link><hasdestination><target><s>" + id_category + "</s></target></hasdestination></link></haslink>");
      sXML.append("</b>");
    } // next
    
    sXML.append("</has>");
    
    sXML.append("</b>");
  }
                  
  out.write(sXML.toString());
  
  if (DebugFile.trace) DebugFile.writeln("<JSP:pickchild.jsp  " + String.valueOf(iCats) + " categories readed in " + String.valueOf(System.currentTimeMillis()-lElapsed) + " ms");
    
%>

<%@ page import="java.net.URLDecoder,java.sql.SQLException,com.knowgate.acl.*,com.knowgate.jdc.JDCConnection,com.knowgate.dataobjs.DB,com.knowgate.dataobjs.DBBind,com.knowgate.dataobjs.DBSubset,com.knowgate.misc.Environment,com.knowgate.misc.Gadgets,com.knowgate.debug.DebugFile" language="java" session="false" contentType="text/html;charset=UTF-8" %>
<%@ include file="../methods/dbbind.jsp" %><%@ include file="../methods/cookies.jspf" %><%@ include file="../methods/authusrs.jspf" %>
<%
/*
  Copyright (C) 2004  Know Gate S.L. All rights reserved.
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

  if (autenticateSession(GlobalDBBind, request, response)<0) return;

  final int MAXROWS = 1000;
  
  String id_domain = getCookie(request,"domainid","");
  String id_user = getCookie (request, "userid", null); 
  String gu_workarea = getCookie (request, "workarea", null);

  JDCConnection oConn = null;

  DBSubset oLists = new DBSubset(DB.k_lists, DB.gu_list+","+DB.de_list+","+DB.tp_list+","+DB.gu_query,DB.gu_workarea+"=? AND "+DB.tp_list+"<>4 AND "+DB.de_list+" IS NOT NULL ORDER BY 2", 20);
  
  DBSubset oContacts = new DBSubset (DB.k_member_address, DBBind.Functions.ISNULL+"("+DB.tx_name+","+DB.nm_commercial+"),"+DB.tx_surname+","+DB.tx_email,
  				     DB.tx_email + " IS NOT NULL AND " + DB.gu_workarea+"=? AND ("+DB.bo_private+"=0 OR "+DB.gu_writer+"=?) ORDER BY 1,2", 500);

  DBSubset oUsers = new DBSubset (DB.k_users, DB.nm_user+","+DB.tx_surname1+","+DB.tx_surname2+","+DB.tx_main_email,
  				     DB.tx_main_email + " IS NOT NULL AND " + DB.id_domain+"=? AND "+DB.bo_active+"<>0 ORDER BY 1,2,3", 500);
  int iContacts=0, iUsers=0, iLists = 0;

  try {
    oConn = GlobalDBBind.getConnection("addrbook");  

    oContacts.setMaxRows(MAXROWS);    
    iContacts = oContacts.load(oConn, new Object[]{gu_workarea,id_user});
    
    iLists = oLists.load(oConn, new Object[]{gu_workarea});
    
    oUsers.setMaxRows(MAXROWS);    
    iUsers = oUsers.load(oConn, new Object[]{new Integer(id_domain)});
    
    oConn.close("addrbook");  
  }
  catch (SQLException e) {
   if (oConn!=null)
      if (!oConn.isClosed()) oConn.close("");
    oConn = null;
    response.sendRedirect (response.encodeRedirectUrl ("../common/errmsg.jsp?title=SQLException&desc=" + e.getMessage() + "&resume=_close"));  
  }
  catch (NumberFormatException e) {
   if (oConn!=null)
      if (!oConn.isClosed()) oConn.close("");
    oConn = null;
    response.sendRedirect (response.encodeRedirectUrl ("../common/errmsg.jsp?title=NumberFormatException&desc=" + e.getMessage() + "&resume=_close"));  
  }
  
  if (null==oConn) return;
  oConn = null;
%>
    <HTML>
      <HEAD>
  	<SCRIPT SRC="../javascript/cookies.js"></SCRIPT>  
        <SCRIPT SRC="../javascript/setskin.js"></SCRIPT>
        <SCRIPT SRC="../javascript/getparam.js"></SCRIPT>
        <SCRIPT SRC="../javascript/combobox.js"></SCRIPT>
	<SCRIPT TYPE="text/javascript">
	  <!--	    
            var jsTpList = new Array("1","1"<% if (iLists>0) out.write(",");  for (int l=0; l<iLists; l++) out.write((0==l ? "" : ",")+"\""+oLists.get(2,l)+"\""); %>);
            var jsGuQuery= new Array("",""<% if (iLists>0) out.write(","); for (int l=0; l<iLists; l++) out.write((0==l ? "" : ",")+"\""+oLists.get(3,l)+"\""); %>);
            
            // ----------------------------------------------------------------

            function findRecipient(opt,val) {
              var fnd = -1;
              
              for (var g=0; g<opt.length; g++) {
                if (opt[g].value==val) {
                  fnd = g;
                  break;
                }      
              }
              return fnd;
            }

            // ----------------------------------------------------------------
    	    
            function addRecipients(sel2) {
              var opt1 = document.forms[0].sel_addrbook.options;
              var opt2 = sel2.options;
              var opt;
              
              for (var g=0; g<opt1.length; g++) {
                if (opt1[g].selected && (-1==findRecipient(opt2,opt1[g].value))) {          
                  opt = new Option(opt1[g].text, opt1[g].value);
                  opt2[sel2.length] = opt;
                }
              } // next
            }
            
            // ----------------------------------------------------------------
            
            function removeRecipients(sel2) {
              var opt2 = sel2.options;
              
              for (var g=0; g<opt2.length; g++) {
                if (opt2[g].selected)
                  opt2[g--] = null;
              } // next
            }

            // ----------------------------------------------------------------
            
            function setRecipients() {
              var frm = window.parent.opener.document.forms[0];
              var opt;
              var m;
              
              opt = document.forms[0].sel_to.options;
                            
              for (m=0; m<opt.length; m++) {                  
              	  if (frm.TO.value.length==0)
              	    frm.TO.value = opt[m].value;
              	  else
              	    frm.TO.value += ";" + opt[m].value;              	  
              } // next m

              opt = document.forms[0].sel_cc.options;
              
              for (m=0; m<opt.length; m++) {
              	  if (frm.CC.value.length==0)
              	    frm.CC.value = opt[m].value;
              	  else
              	    frm.CC.value += ";" + opt[m].value;              	  
              } // next m

              opt = document.forms[0].sel_bcc.options;
              
              for (m=0; m<opt.length; m++) {
              	  if (frm.BCC.value.length==0)
              	    frm.BCC.value = opt[m].value;
              	  else
              	    frm.BCC.value += ";" + opt[m].value;              	  
              } // next m
            
              window.parent.close();
            }

            // ----------------------------------------------------------------
            
            function selectList(offset,search) {
              var frm=document.forms[0];
              var idx=frm.sel_list.selectedIndex;
              var opt=frm.sel_addrbook.options;
              
              if (getCombo(frm.sel_addrbook)!="loadingdata") {
                for (var i=opt.length-1; i>=0; i--)  
      	          opt[i] = null;

	        comboPush (frm.sel_addrbook, "Loading...", "loadingdata", true, true);
	      
	        frm.nu_skip.value = String(offset);

                window.parent.frames[1].document.location.href="addrload.jsp?nu_skip="+frm.nu_skip.value+"&gu_list="+getCombo(frm.sel_list)+"&tp_list="+jsTpList[idx]+"&gu_query="+jsGuQuery[idx]+"&tx_search="+search;
              }
            }
	  //-->
	</SCRIPT>
      </HEAD>
      
      <BODY bgcolor="white" topmargin="4" leftmargin="4" marginwidth="4" marginheight="4">
	<TABLE ALIGN="center" CELLPADDING="4">
        <FORM>
          <INPUT TYPE="hidden" NAME="nu_skip" VALUE="0">
	  <TR>
	    <TD ROWSPAN="3" BGCOLOR="#F7F3F7">
	      <TABLE BORDER="0" CELLSPACING="0" CELLPADDING="0" BGCOLOR="#F7F3F7">
	        <TR>
	          <TD VALIGN="middle"><IMG SRC="../images/images/hipermail/newuser.gif" BORDER="0" HSPACE="4" ALT="New Contact"/></TD><TD VALIGN="middle"><A HREF="#" onclick="window.open ('../crm/contact_new_f.jsp?id_domain=' + getCookie('domainid') + '&amp;gu_workarea=' + getCookie('workarea'), 'createcontact', 'directories=no,scrollbars=yes,toolbar=no,menubar=no,width=640,height=' + (screen.height>600 ? '600' : '520'))" CLASS="linksmall">New Contact</A></TD>
	          <TD><IMG SRC="../images/images/spacer.gif" WIDTH="8" HEIGHT="1" ALT="" BORDER="0"></TD>
	          <TD VALIGN="middle"><IMG SRC="../images/images/hipermail/uploadrecipients.gif" BORDER="0" HSPACE="4" WIDTH="27" HEIGHT="15" ALT="Load recipients list from a file"/></TD><TD VALIGN="middle"><A HREF="#" onclick="window.open ('../crm/contact_new_f.jsp?id_domain=' + getCookie('domainid') + '&amp;gu_workarea=' + getCookie('workarea'), 'createcontact', 'directories=no,scrollbars=yes,toolbar=no,menubar=no,width=640,height=' + (screen.height>600 ? '600' : '520'))" CLASS="linksmall">Load recipients</A></TD>
	        </TR>
	      </TABLE>
	      <SELECT NAME="sel_list" CLASS="selectsmall" STYLE="width:290px" onchange="document.forms[0].tx_search.value=''; selectList(0,'')">
	      <OPTION VALUE="" SELECTED>* All Contacts and Users</OPTION><OPTION VALUE="domainusers">* Only Users from current Domain</OPTION>
<% for (int l=0; l<iLists; l++) {
     out.write("<OPTION VALUE=\""+oLists.getString(0,l)+"\">"+Gadgets.HTMLEncode(oLists.getString(1,l))+"</OPTION>");
   } // next
%>	
	      </SELECT>
	      <A HREF="#" onclick="document.forms[0].tx_search.value=''; selectList(0,'');" TITLE="Refresh"><IMG SRC="../images/images/refresh.gif" WIDTH="13" HEIGHT="16" BORDER="0" ALT="Refresh"></A>
	      <INPUT TYPE="text" NAME="tx_search" VALUE="" CLASS="combomini" STYLE="width:220px">&nbsp;
	      <A HREF="#" CLASS="linksmall" onclick="document.forms[0].sel_list.selectedIndex=0; selectList(0,document.forms[0].tx_search.value)">Search</A>
	      <SELECT NAME="sel_addrbook" SIZE="26" MULTIPLE="true" CLASS="selectsmall" STYLE="width:340px" ondblclick="addRecipients(document.forms[0].sel_to)">
<% 
   int iContactIndex=0, iUserIndex=0;
   String sContactName, sUserName;

   for (int l=0; l<iLists; l++) {
     out.write("<OPTION VALUE=\"{"+oLists.getString(1,l)+"}\">{ "+Gadgets.HTMLEncode(oLists.getString(1,l))+" }</OPTION>");
   }
   
   do {
     if (iContactIndex<iContacts)
       sContactName = Gadgets.HTMLEncode(oContacts.getStringNull(0,iContactIndex,"")+" "+oContacts.getStringNull(1,iContactIndex,""));
     else
       sContactName = null;

     if (iUserIndex<iUsers)
       sUserName = Gadgets.HTMLEncode(oUsers.getStringNull(0,iUserIndex,"")+" "+oUsers.getStringNull(1,iUserIndex,"")+" "+oUsers.getStringNull(2,iUserIndex,""));
     else
       sUserName = null;
     
     if ((sContactName==null) && (sUserName!=null)) {
       out.write("<OPTION VALUE=\""+oUsers.getString(3,iUserIndex)+"\">"+sUserName+"&nbsp;&lt;"+oUsers.getString(3,iUserIndex)+"&gt;</OPTION>");
       iUserIndex++;
     }
     else if ((sContactName!=null) && (sUserName==null)) {
       out.write("<OPTION VALUE=\""+oContacts.getString(2,iContactIndex)+"\">"+sContactName+"&nbsp;&lt;"+oContacts.getString(2,iContactIndex)+"&gt;</OPTION>");     
       iContactIndex++;
     }
     else if ((sContactName!=null) && (sUserName!=null)) {
       if (sContactName.compareTo(sUserName)<0) {
         out.write("<OPTION VALUE=\""+oContacts.getString(2,iContactIndex)+"\">"+sContactName+"&nbsp;&lt;"+oContacts.getString(2,iContactIndex)+"&gt;</OPTION>");     
         iContactIndex++;
       }
       else {
         out.write("<OPTION VALUE=\""+oUsers.getString(3,iUserIndex)+"\">"+sUserName+"&nbsp;&lt;"+oUsers.getString(3,iUserIndex)+"&gt;</OPTION>");
         iUserIndex++;
       }
     }
   } while ((sContactName!=null) || (sUserName!=null));
%>
	      </SELECT>
	      <TABLE WIDTH="100%">
	        <TR><TD ALIGN="right">
	          &nbsp;&nbsp;
	          <A CLASS="linkplain" HREF="#" onclick="if (parseInt(document.forms[0].nu_skip.value)>0) selectList(parseInt(document.forms[0].nu_skip.value)-<%=String.valueOf(MAXROWS)%>,'')">Previous</A>
	          <A CLASS="linkplain" HREF="#" onclick="if (document.forms[0].sel_addrbook.options.length>=<%=MAXROWS%>) selectList(parseInt(document.forms[0].nu_skip.value)+<%=String.valueOf(MAXROWS)%>,'')">Next</A>
	      </TD></TR>
	      </TABLE>
	    </TD>
	    <TD ALIGN="center" VALIGN="middle" BGCOLOR="linen">
	      <INPUT TYPE="button" VALUE="To ++" CLASS="minibutton" STYLE="width:48px" onclick="addRecipients(document.forms[0].sel_to)"/>
	      <BR/><BR/>
	      <INPUT TYPE="button" VALUE="-- To" CLASS="minibutton" STYLE="width:48px" onclick="removeRecipients(document.forms[0].sel_to)"/>	      
	    </TD>
	    <TD BGCOLOR="linen">
	      <SELECT NAME="sel_to" SIZE="11" MULTIPLE="true" CLASS="selectsmall" STYLE="width:280px">
	      </SELECT>
	    </TD>
	  </TR>
	  <TR>
	    <TD ALIGN="center" VALIGN="middle" BGCOLOR="linen">
	      <INPUT TYPE="button" VALUE="Cc ++" CLASS="minibutton" STYLE="width:48px" onclick="addRecipients(document.forms[0].sel_cc)"/>
	      <BR/><BR/>
	      <INPUT TYPE="button" VALUE="-- Cc" CLASS="minibutton" STYLE="width:48px" onclick="removeRecipients(document.forms[0].sel_cc)"/>	      
	    </TD>
	    <TD BGCOLOR="linen">
	      <SELECT NAME="sel_cc" SIZE="11" MULTIPLE="true" CLASS="selectsmall" STYLE="width:280px">
	      </SELECT>
	    </TD>
	  </TR>
	  <TR>
	    <TD ALIGN="center" VALIGN="middle" BGCOLOR="linen">
	      <INPUT TYPE="button" VALUE="Bcc ++" CLASS="minibutton" STYLE="width:48px" onclick="addRecipients(document.forms[0].sel_bcc)"/>
	      <BR/><BR/>
	      <INPUT TYPE="button" VALUE="-- Bcc" CLASS="minibutton" STYLE="width:48px" onclick="removeRecipients(document.forms[0].sel_bcc)"/>
	    </TD>
	    <TD BGCOLOR="linen">
	      <SELECT NAME="sel_bcc" SIZE="11" MULTIPLE="true" CLASS="selectsmall" STYLE="width:280px">
	      </SELECT>
	    </TD>
	  </TR>
        </FORM>
	</TABLE>
	<HR/>
	<TABLE ALIGN="center">
	  <TR>
	    <TD><INPUT TYPE="button" CLASS="pushbutton" VALUE="Ok" onclick="setRecipients()"/></TD>
	    <TD WIDTH="20px"></TD>
            <TD><INPUT TYPE="button" CLASS="closebutton" VALUE="Cancel" onclick="window.parent.close()"/></TD>
	  </TR>
	</TABLE>
      </BODY>
    </HTML>

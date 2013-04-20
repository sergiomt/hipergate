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

package com.knowgate.http;

import java.lang.reflect.InvocationTargetException;

import java.io.IOException;

import java.util.Properties;
import java.util.Enumeration;
import java.util.HashMap;
import java.util.Iterator;

import java.text.SimpleDateFormat;
import java.text.ParseException;

import java.sql.Connection;
import java.sql.SQLException;
import java.sql.Types;

import javax.servlet.*;
import javax.servlet.http.*;

import com.knowgate.debug.DebugFile;
import com.knowgate.debug.StackTraceUtil;
import com.knowgate.jdc.JDCConnection;
import com.knowgate.dataobjs.DB;
import com.knowgate.dataobjs.DBBind;
import com.knowgate.dataobjs.DBTable;
import com.knowgate.dataobjs.DBColumn;
import com.knowgate.dataobjs.DBPersist;
import com.knowgate.dataobjs.DBSubset;
import com.knowgate.misc.Environment;
import com.knowgate.misc.Gadgets;
import com.knowgate.acl.ACL;
import com.knowgate.acl.ACLUser;
import com.knowgate.crm.MemberAddress;
import com.knowgate.crm.ContactLoader;
import com.knowgate.crm.CompanyLoader;
import com.knowgate.crm.OportunityLoader;
import com.knowgate.workareas.WorkArea;
import com.knowgate.hipergate.datamodel.ColumnList;
import com.knowgate.hipergate.datamodel.ImportLoader;

/**
 * @author Sergio Montoro Ten
 * @version 7.0
 */

public class HttpDataObjsServlet extends HttpServlet {

  private static HashMap<String,DBBind> oBindings;
  private static HashMap<String,HashMap<String,Boolean>> oWorkAreas;

  public HttpDataObjsServlet() {
    oBindings = new HashMap<String,DBBind>();
    oWorkAreas = new HashMap<String,HashMap<String,Boolean>>();
  }

  // ---------------------------------------------------------------------------

  private boolean hasSqlSignature(String s) {
    boolean bRetVal = false;
    try {
      bRetVal = Gadgets.matches(s, "(\\%27)|(\\')|(\\-\\-)|(\\%23)|(#)") ||
                Gadgets.matches(s, "((\\%3D)|(=))[^\\n]*((\\%27)|(\\')|(\\-\\-)|(\\%3B)|(;))") ||
                Gadgets.matches(s, "\\w*((\\%27)|(\\'))((\\%6F)|o|(\\%4F))((\\%72)|r|(\\%52))") ||
                Gadgets.matches(s, "((\\%27)|(\\'))union");
    } catch (org.apache.oro.text.regex.MalformedPatternException ignore) {
      // never thrown
    }
    return bRetVal;
  } // hasSqlSignature

  // ---------------------------------------------------------------------------

  private static synchronized boolean isUserAllowed(JDCConnection oCon, String sUser, String sWrkA)
      throws SQLException {

      if (DebugFile.trace) {
        DebugFile.writeln("Begin HttpDataObjsServlet.isUserAllowed("+sUser+","+sWrkA+")");
        DebugFile.incIdent();
      }

      HashMap<String,Boolean> oUserMap =  oWorkAreas.get(sWrkA);
      if (null==oUserMap) {
        oUserMap = new HashMap<String,Boolean>();
        oWorkAreas.put(sWrkA, oUserMap);
      }
      Boolean oAllowed = oUserMap.get(sUser);
      if (null==oAllowed) {
    	boolean bAllowed = WorkArea.isUser(oCon, sWrkA, sUser);
    	if (!bAllowed) bAllowed = WorkArea.isPowerUser(oCon, sWrkA, sUser);
    	if (!bAllowed) bAllowed = WorkArea.isAdmin(oCon, sWrkA, sUser);
    	oAllowed = new Boolean(bAllowed);
        oUserMap.put(sUser, oAllowed);
      }

      if (DebugFile.trace) {
        DebugFile.decIdent();
        DebugFile.writeln("End HttpDataObjsServlet.isUserAllowed() : " +
                          String.valueOf(oAllowed.booleanValue()));
      }

      return oAllowed.booleanValue();
  } // isUserAllowed

  // ---------------------------------------------------------------------------

  public void doGet(HttpServletRequest request, HttpServletResponse response)
    throws IOException, ServletException {

    String sCmd = request.getParameter("command");

    if (null==sCmd) {
      response.sendError(HttpServletResponse.SC_BAD_REQUEST, "Parameter command is requiered");
      return;
    }

	/*
    if (sCmd.equalsIgnoreCase("update")) {
      response.sendError(HttpServletResponse.SC_METHOD_NOT_ALLOWED, "Command " + sCmd + " only allowed for POST method");
      return;
    }
    */

    if (!sCmd.equalsIgnoreCase("ping") && !sCmd.equalsIgnoreCase("query") && !sCmd.equalsIgnoreCase("nextval") && !sCmd.equalsIgnoreCase("update")) {
      response.sendError(HttpServletResponse.SC_METHOD_NOT_ALLOWED, "Command " + sCmd + " not recognized");
      return;
    }

    if (sCmd.equalsIgnoreCase("ping")) {
      response.setContentType("text/plain");
      response.getOutputStream().print("HttpDataObjsServlet ping OK");
    } else if (sCmd.equalsIgnoreCase("query") || sCmd.equalsIgnoreCase("nextval") || sCmd.equalsIgnoreCase("update")) {
      doPost(request, response);
    }

  } // doGet

  // ---------------------------------------------------------------------------

  public void doPost(HttpServletRequest request, HttpServletResponse response)
     throws IOException, ServletException {

     DBBind oBnd = null;
     DBTable oMbr = null;
     DBTable oOpr = null;
     DBTable oCnt = null;
     DBColumn oCol;
     ColumnList oColList = null;
     JDCConnection oCon = null;

     short iAuth;
     boolean bAllowed;
     boolean bPrepared = false;
     String sDbb = request.getParameter("profile");
     String sUsr = request.getParameter("user");
     final String sPwd = request.getParameter("password");
     final String sCmd = request.getParameter("command");
     final String sCls = request.getParameter("class");
     final String sTbl = request.getParameter("table");
     final String sFld = request.getParameter("fields");
     final String sWhr = request.getParameter("where");
     final String sMax = request.getParameter("maxrows");
     final String sSkp = request.getParameter("skip");
     final String sCol = request.getParameter("coldelim");
     final String sRow = request.getParameter("rowdelim");
     final String sFlg = request.getParameter("flags");
     Integer iFlags = new Integer(0);
     if (sCls.equals("com.knowgate.crm.ContactLoader") || sCls.equals("com.knowgate.crm.OportunityLoader"))
       iFlags = new Integer(ContactLoader.MODE_APPENDUPDATE|ContactLoader.WRITE_CONTACTS|ContactLoader.WRITE_ADDRESSES|ContactLoader.NO_DUPLICATED_MAILS);
     else if (sCls.equals("com.knowgate.crm.CompanyLoader"))
       iFlags = new Integer(CompanyLoader.MODE_APPENDUPDATE|CompanyLoader.WRITE_ADDRESSES);

     if (sFlg!=null) {
       try {
         iFlags = new Integer(sFlg);
       } catch (NumberFormatException nfe) { }
     }
     
     if (DebugFile.trace) {
       DebugFile.writeln("Begin HttpDataObjsServlet.doPost(profile="+sDbb+",command="+sCmd+",class="+sCls+",table="+sTbl+",fields="+sFld+",where="+sWhr+")");
       DebugFile.incIdent();
     }

     if (null==sDbb) {
       sDbb = "hipergate";
     }
     if (null==sUsr) {
       if (DebugFile.trace) DebugFile.decIdent();
       response.sendError(HttpServletResponse.SC_BAD_REQUEST, "Parameter user is requiered");
       return;
     }
     if (null==sPwd) {
       if (DebugFile.trace) DebugFile.decIdent();
       response.sendError(HttpServletResponse.SC_BAD_REQUEST, "Parameter password is requiered");
       return;
     }
     if (null==sCmd) {
       if (DebugFile.trace) DebugFile.decIdent();
       response.sendError(HttpServletResponse.SC_BAD_REQUEST, "Parameter command is requiered");
       return;
     } else if (sCmd.equalsIgnoreCase("query")) {
       if (null==sFld) {
         if (DebugFile.trace) DebugFile.decIdent();
         response.sendError(HttpServletResponse.SC_BAD_REQUEST, "Parameter fields is requiered");
         return;
       } else if (hasSqlSignature(sFld)) {
         if (DebugFile.trace) DebugFile.decIdent();
         response.sendError(HttpServletResponse.SC_BAD_REQUEST, "Parameter fields has an invalid syntax");
         return;
       }
     }
     if (null==sTbl && null==sCls) {
       if (DebugFile.trace) DebugFile.decIdent();
       response.sendError(HttpServletResponse.SC_BAD_REQUEST, "Either table or class parameter is requiered");
       return;
     } else if (hasSqlSignature(sTbl)) {
       if (DebugFile.trace) DebugFile.decIdent();
       response.sendError(HttpServletResponse.SC_BAD_REQUEST, "Parameter table has an invalid syntax");
       return;
     } else if (hasSqlSignature(sFld)) {
       if (DebugFile.trace) DebugFile.decIdent();
         response.sendError(HttpServletResponse.SC_BAD_REQUEST, "Parameter fields has an invalid syntax");
         return;
     }

     Properties oEnv = Environment.getProfile(sDbb);

     if (null==oEnv) {
       if (DebugFile.trace) DebugFile.decIdent();
       response.sendError(HttpServletResponse.SC_SERVICE_UNAVAILABLE, "Databind " + sDbb + " is not available");
       return;
     }

     if (!sCmd.equalsIgnoreCase("ping") && !sCmd.equalsIgnoreCase("query") && !sCmd.equalsIgnoreCase("update") && !sCmd.equalsIgnoreCase("nextval")) {
       if (DebugFile.trace) DebugFile.decIdent();
       response.sendError(HttpServletResponse.SC_METHOD_NOT_ALLOWED, "Command " + sCmd + " not recognized");
       return;
     }

     if (sCmd.equalsIgnoreCase("ping")) {
       response.setContentType("text/plain");
       response.getOutputStream().print("HttpDataObjsServlet ping OK");
       if (DebugFile.trace) {
         DebugFile.decIdent();
         DebugFile.writeln("End HttpDataObjsServlet.doPost()");
       }
       return;
     }

     if (oBindings.containsKey(sDbb)) {
       oBnd = oBindings.get(sDbb);
     } else {
       oBnd = new DBBind(sDbb);
       oBindings.put(sDbb, oBnd);
     }

     if (sCmd.equalsIgnoreCase("query")) {
       int iMax;
       if (null==sMax)
         iMax = 500;
       else
         iMax = Integer.parseInt(sMax);
       int iSkp;
       if (null==sSkp)
         iSkp = 0;
       else
         iSkp = Integer.parseInt(sSkp);
       DBSubset oDbs = new DBSubset (sTbl, sFld, sWhr, iMax);
       if (null!=sRow) oDbs.setRowDelimiter(sRow);
       if (null!=sCol) oDbs.setColumnDelimiter(sCol);
       oDbs.setMaxRows(iMax);
       try {
         oCon = oBnd.getConnection("HttpDataObjsServlet");
         if (null==oCon) {
           if (DebugFile.trace) DebugFile.decIdent();
           throw new ServletException("ERROR Unable to get database connection from pool "+sDbb);
         }
         if (DBBind.exists(oCon, DB.k_users, "U")) {
           if (Gadgets.checkEMail(sUsr)) {
             sUsr = ACLUser.getIdFromEmail(oCon, sUsr);
             if (null==sUsr)
               iAuth = ACL.USER_NOT_FOUND;
             else
               iAuth = ACL.autenticate(oCon, sUsr, sPwd, ACL.PWD_CLEAR_TEXT);
           } else {
             iAuth = ACL.autenticate(oCon, sUsr, sPwd, ACL.PWD_CLEAR_TEXT);
           }
         } else {
           iAuth = 0;
         } // fi (exists k_users)
         if (iAuth<0) {
           response.sendError(HttpServletResponse.SC_FORBIDDEN, ACL.getErrorMessage(iAuth));
         } else {
           oDbs.load(oCon, iSkp);
           response.setContentType("text/plain");
           response.setCharacterEncoding("UTF-8");
           response.getOutputStream().write(oDbs.toString().getBytes("UTF-8"));         	 	
         }
         oCon.close("HttpDataObjsServlet");
         oCon = null;
       } catch (SQLException sqle) {
         if (null!=oCon) {
           try { oCon.close("HttpDataObjsServlet"); } catch (Exception ignore) {}
           oCon = null;
         }
         if (DebugFile.trace) DebugFile.decIdent();
         throw new ServletException("SQLException "+sqle.getMessage());
       }
     }
     else if (sCmd.equalsIgnoreCase("update")) {
       if (DebugFile.trace) DebugFile.writeln("command is update");
       Enumeration oParamNames = request.getParameterNames();
       DBPersist oDbp;
       ImportLoader oImp = null;
       Class oCls;

       if (null==sCls) {
         oDbp = new DBPersist(sTbl, "DBPersist");
         try {
           oCls = Class.forName("com.knowgate.dataobjs.DBPersist");
         } catch (ClassNotFoundException neverthrown) { oCls=null; }

       } else {
    	   
         try {
           oCls = Class.forName(sCls);
           if (sCls.equals("com.knowgate.crm.ContactLoader") || sCls.equals("com.knowgate.crm.OportunityLoader") || sCls.equals("com.knowgate.crm.CompanyLoader")) {
        	 oImp = (ImportLoader) oCls.newInstance();
        	 oMbr = oBnd.getDBTable(DB.k_member_address);
        	 oOpr = oBnd.getDBTable(DB.k_oportunities);
        	 oCnt = oBnd.getDBTable(DB.k_contacts);
        	 oDbp = new DBPersist(DB.k_contacts, "Contact");
        	 oColList = new ColumnList();
           } else {
        	 oImp = null;
             oDbp = (DBPersist) oCls.newInstance();
           }
         } catch (ClassNotFoundException nfe) {
           if (DebugFile.trace) DebugFile.decIdent();
           throw new ServletException("ClassNotFoundException "+nfe.getMessage()+" "+sCls);
         } catch (InstantiationException ine) {
           if (DebugFile.trace) DebugFile.decIdent();
           throw new ServletException("InstantiationException "+ine.getMessage()+" "+sCls);
         } catch (IllegalAccessException iae) {
           if (DebugFile.trace) DebugFile.decIdent();
           throw new ServletException("IllegalAccessException "+iae.getMessage()+" "+sCls);
         } catch (ClassCastException cce) {
           if (DebugFile.trace) DebugFile.decIdent();
           throw new ServletException("ClassCastException "+cce.getMessage()+" "+sCls);
         }

         if (sCls.equals("com.knowgate.hipergate.InvoicePayment") &&
       	   request.getParameter("gu_invoice")!=null & request.getParameter("pg_payment")!=null) {
           if (request.getParameter("gu_invoice").length()>0 &&
               request.getParameter("pg_payment").length()>0) {
             try {
               oCon = oBnd.getConnection("HttpDataObjsServlet.InvoicePayment", true);
               oDbp.load(oCon, new Object[]{request.getParameter("gu_invoice"), new Integer(request.getParameter("pg_payment"))});
               oCon.close("HttpDataObjsServlet.InvoicePayment");
               oCon=null;
             } catch (Exception xcpt) {
               if (DebugFile.trace) {
               	 DebugFile.writeln(xcpt.getClass().getName()+" "+xcpt.getMessage());
                 DebugFile.decIdent();
               }
               throw new ServletException(xcpt.getClass().getName()+" "+xcpt.getMessage(), xcpt);
             }
             finally {
               if (oCon!=null) { try { if (!oCon.isClosed()) { oCon.close("HttpDataObjsServlet.InvoicePayment"); } } catch (Exception ignore) { } }
             } // finally
           } // fi (gu_invoice && pg_payment)
         } // fi (sCls==InvoicePayment)
       } // fi 

       if (DebugFile.trace) DebugFile.writeln("class "+sCls+" instantiated");

       while (oParamNames.hasMoreElements()) {
         String sKey = (String) oParamNames.nextElement();
         if (DebugFile.trace) DebugFile.writeln("reading parameter "+sKey);
         sKey = sKey.trim();
         int iSpc = sKey.indexOf(' ');
         if (iSpc>0) {
           String sKeyName = sKey.substring(0, iSpc);
           iSpc++;
           if (iSpc<sKey.length()-1) {
             String sSQLType = sKey.substring(iSpc);
             if (DebugFile.trace) DebugFile.writeln("sqltype is "+sSQLType);
             if (sSQLType.toUpperCase().startsWith("DATE") || sSQLType.toUpperCase().startsWith("DATETIME") || sSQLType.toUpperCase().startsWith("TIMESTAMP")) {
               iSpc = sSQLType.indexOf(' ');
               String sDtFmt = "";
               try {
                 if (iSpc > 0) {
                   sDtFmt = sSQLType.substring(++iSpc);
                   if (DebugFile.trace) DebugFile.writeln("date format is "+sDtFmt);
                   oDbp.replace(sKeyName, request.getParameter(sKey), new SimpleDateFormat(sDtFmt));
                   if (oImp!=null) {
                     oCol = oMbr.getColumnByName(sKeyName);
                     if (null==oCol && oImp instanceof ContactLoader)
                       oCol = oCnt.getColumnByName(sKeyName);
                     if (null==oCol && oImp instanceof OportunityLoader)
                       oCol = oOpr.getColumnByName(sKeyName);
                     if (null!=oCol) {
                       oColList.add(oCol);
                       oImp.put(sKeyName, oDbp.get(sKeyName));
                       if (DebugFile.trace) DebugFile.writeln("setting "+sKeyName+"="+oDbp.get(sKeyName));
                     }
                   } // fi
                 } else {
                   oDbp.replace(sKeyName, request.getParameter(sKey), DBColumn.getSQLType(sSQLType));
                   if (oImp!=null) {
                     oCol = oMbr.getColumnByName(sKeyName);
                     if (null==oCol && oImp instanceof ContactLoader)
                         oCol = oCnt.getColumnByName(sKeyName);
                     if (null==oCol && oImp instanceof OportunityLoader)
                       oCol = oOpr.getColumnByName(sKeyName);
                     if (null!=oCol) {
                       oColList.add(oCol);
                       oImp.put(sKeyName, oDbp.get(sKeyName));
                       if (DebugFile.trace) DebugFile.writeln("setting "+sKeyName+"="+oDbp.get(sKeyName));
                     }
                   } // fi
                 }
               } catch (ParseException pe) {
                 if (DebugFile.trace) DebugFile.decIdent();
                 throw new ServletException("ERROR ParseException "+sKey+"|"+sDtFmt+"|"+request.getParameter(sKey)+" "+pe.getMessage());
               } catch (IllegalArgumentException ia) {
                 if (DebugFile.trace) DebugFile.decIdent();
                 throw new ServletException("ERROR IllegalArgumentException "+sKey+"|"+sDtFmt+"|"+request.getParameter(sKey)+ia.getMessage());
               }
             } else {
               try {
                 oDbp.replace(sKeyName, request.getParameter(sKey), DBColumn.getSQLType(sSQLType));
                 if (oImp!=null) {
                   if (sKeyName.equalsIgnoreCase("id_address_ref"))
                     oCol = new DBColumn(DB.k_addresses, DB.id_ref, (short) Types.VARCHAR, "VARCHAR", 50, 0, 1, 36);
                   else if (sKeyName.equalsIgnoreCase("id_contact_ref"))
                     oCol = new DBColumn(DB.k_contacts, DB.id_ref, (short) Types.VARCHAR, "VARCHAR", 50, 0, 1, 19);
                   else if (sKeyName.equalsIgnoreCase("id_company_ref"))
                     oCol = new DBColumn(DB.k_companies, DB.id_ref, (short) Types.VARCHAR, "VARCHAR", 50, 0, 1, 13);
                   else
                     oCol = oMbr.getColumnByName(sKeyName);
                   if (null==oCol && oImp instanceof ContactLoader)
                     oCol = oCnt.getColumnByName(sKeyName);
                   if (null==oCol && oImp instanceof OportunityLoader)
                     oCol = oOpr.getColumnByName(sKeyName);
                   if (null!=oCol) {
                	 oColList.add(oCol);
                     oImp.put(sKeyName, oDbp.get(sKeyName));                  
                     if (DebugFile.trace) DebugFile.writeln("setting "+sKeyName+"="+oDbp.get(sKeyName));
                   }
                 } // fi
               } catch (NumberFormatException nfe) {
                 if (DebugFile.trace) DebugFile.decIdent();
                 throw new ServletException("ERROR NumberFormatException "+sKey+" "+" "+request.getParameter(sKey)+" "+nfe.getMessage());
               }
             }
           } else {
             oDbp.replace(sKeyName, request.getParameter(sKey));
             if (oImp!=null) {
               if (sKeyName.equalsIgnoreCase("id_address_ref"))
                 oCol = new DBColumn(DB.k_addresses, DB.id_ref, (short) Types.VARCHAR, "VARCHAR", 50, 0, 1, 36);
               else if (sKeyName.equalsIgnoreCase("id_contact_ref"))
                 oCol = new DBColumn(DB.k_contacts, DB.id_ref, (short) Types.VARCHAR, "VARCHAR", 50, 0, 1, 19);
               else if (sKeyName.equalsIgnoreCase("id_company_ref"))
                 oCol = new DBColumn(DB.k_companies, DB.id_ref, (short) Types.VARCHAR, "VARCHAR", 50, 0, 1, 13);
               else
                 oCol = oMbr.getColumnByName(sKeyName);
               if (null==oCol && oImp instanceof ContactLoader)
                 oCol = oCnt.getColumnByName(sKeyName);
               if (null==oCol && oImp instanceof OportunityLoader)
                 oCol = oOpr.getColumnByName(sKeyName);
               if (null!=oCol) {
            	 oColList.add(oCol);
                 oImp.put(sKeyName, oDbp.get(sKeyName));
                 if (DebugFile.trace) DebugFile.writeln("setting "+sKeyName+"="+oDbp.get(sKeyName));
               }
             } // fi
           }
         } else {
           oDbp.replace(sKey, request.getParameter(sKey));
           if (oImp!=null) {
             if (sKey.equalsIgnoreCase("id_address_ref"))
               oCol = new DBColumn(DB.k_addresses, DB.id_ref, (short) Types.VARCHAR, "VARCHAR", 50, 0, 1, 36);
             else if (sKey.equalsIgnoreCase("id_contact_ref"))
               oCol = new DBColumn(DB.k_contacts, DB.id_ref, (short) Types.VARCHAR, "VARCHAR", 50, 0, 1, 19);
             else if (sKey.equalsIgnoreCase("id_company_ref"))
               oCol = new DBColumn(DB.k_companies, DB.id_ref, (short) Types.VARCHAR, "VARCHAR", 50, 0, 1, 13);
             else
               oCol = oMbr.getColumnByName(sKey);
             if (null==oCol && oImp instanceof ContactLoader)
               oCol = oCnt.getColumnByName(sKey);
             if (null==oCol && oImp instanceof OportunityLoader)
               oCol = oOpr.getColumnByName(sKey);
             if (null!=oCol) {
               oColList.add(oCol);
               oImp.put(sKey, oDbp.get(sKey));
               if (DebugFile.trace) DebugFile.writeln("setting "+sKey+"="+oDbp.get(sKey));
             }
           } // fi
         } // fi
       } // wend
       
       try {
         oCon = oBnd.getConnection("HttpDataObjsServlet");
         if (null==oCon) {
           if (DebugFile.trace) DebugFile.decIdent();
           throw new ServletException("ERROR Unable to get database connection from pool "+sDbb);
         }
         if (DBBind.exists(oCon, DB.k_users, "U")) {
           if (Gadgets.checkEMail(sUsr)) {
             sUsr = ACLUser.getIdFromEmail(oCon, sUsr);
             if (null==sUsr)
               iAuth = ACL.USER_NOT_FOUND;
             else
               iAuth = ACL.autenticate(oCon, sUsr, sPwd, ACL.PWD_CLEAR_TEXT);
           } else {
               iAuth = ACL.autenticate(oCon, sUsr, sPwd, ACL.PWD_CLEAR_TEXT);
           } // fi (checkEMail(sUsr))
         } else {
           iAuth = 0;
         } // fi (exists(DBk_users))
         if (iAuth<0) {
           response.sendError(HttpServletResponse.SC_FORBIDDEN, ACL.getErrorMessage(iAuth));
         } else {
           if (oDbp.isNull(DB.gu_workarea))
             bAllowed = true;
           else
             bAllowed = isUserAllowed(oCon, sUsr, oDbp.getString(DB.gu_workarea));
           if (bAllowed) {
               oCon.setAutoCommit(true);
               if (null==sCls) {
                 oDbp.store(oCon);
               } else {
                 if (oImp==null) {
                   if (DebugFile.trace) DebugFile.writeln(oCls.getName()+".getMethod(\"store\", new Class[]{Class.forName(\"com.knowgate.jdc.JDCConnection\")}).invoke(...)");
                   oCls.getMethod("store", new Class[]{Class.forName("com.knowgate.jdc.JDCConnection")}).invoke(oDbp, new Object[]{oCon});
                 } else {
                   if (DebugFile.trace) DebugFile.writeln(oCls.getName()+".getMethod(\"prepare\", new Class[]{Class.forName(\"java.sql.Connection\"), Class.forName(\"com.knowgate.hipergate.datamodel.ColumnList\")}).invoke(...)");
                   oCls.getMethod("prepare", new Class[]{Class.forName("java.sql.Connection"), Class.forName("com.knowgate.hipergate.datamodel.ColumnList")}).invoke(oImp, new Object[]{(Connection) oCon, oColList});
                   bPrepared = true;
                   if (DebugFile.trace) DebugFile.writeln(oCls.getName()+".getMethod(\"store\", new Class[]{Class.forName(\"java.sql.Connection\"), String.class, int.class}).invoke(...)");
                   oCls.getMethod("store", new Class[]{Class.forName("java.sql.Connection"), String.class, int.class}).invoke(oImp, new Object[]{(Connection) oCon, oDbp.getStringNull(DB.gu_workarea,null), iFlags});
                   oCls.getMethod("close", new Class[]{}).invoke(oImp, new Object[]{});
                 }
               } // fi (sCls)
               response.setContentType("text/plain");
               response.setCharacterEncoding("UTF-8");
               if (oImp!=null) {
                 if (sCls.equals("com.knowgate.crm.ContactLoader"))
            	   response.getOutputStream().print("SUCCESS "+oImp.get(DB.gu_contact));
            	 else if (sCls.equals("com.knowgate.crm.OportunityLoader"))
                   response.getOutputStream().print("SUCCESS "+oImp.get(DB.gu_oportunity));
                 else
                   response.getOutputStream().print("SUCCESS");
               } else {
                 response.getOutputStream().print("SUCCESS");  
               }
           } else {
             response.sendError(HttpServletResponse.SC_FORBIDDEN,
            		            "User "+sUsr+" does not have access to WorkArea "+oDbp.getString(DB.gu_workarea));
           } // fi (bAllowed)
         }
         oCon.close("HttpDataObjsServlet");
         oCon = null;
       } catch (InvocationTargetException ite) {
         if (null!=oCon) {
           try { oCon.close("HttpDataObjsServlet"); oCon = null;
           } catch (Exception ignore) {}
         } // fi
         if (DebugFile.trace) DebugFile.decIdent();
         throw new ServletException(ite.getCause().getClass().getName()+" "+ite.getCause().getMessage()+"\n"+StackTraceUtil.getStackTrace(ite));
       } catch (Exception xcpt) {
         if (oImp!=null && oCls!=null && bPrepared) {
           try { oCls.getMethod("close", new Class[]{}).invoke(oImp, new Object[]{});
           } catch (Exception ignore) {}
         }
    	 if (null!=oCon) {
           try { oCon.close("HttpDataObjsServlet"); oCon = null;
           } catch (Exception ignore) {}
         } // fi
         if (DebugFile.trace) DebugFile.decIdent();
         throw new ServletException(xcpt.getClass().getName()+" "+xcpt.getMessage()+"\n"+StackTraceUtil.getStackTrace(xcpt));
       }
     }
     else if (sCmd.equalsIgnoreCase("nextval")) {

       try {
         oCon = oBnd.getConnection("HttpDataObjsServlet");
         if (null==oCon) {
           if (DebugFile.trace) DebugFile.decIdent();
           throw new ServletException("ERROR Unable to get database connection from pool "+sDbb);
         }
         if (DBBind.exists(oCon, DB.k_users, "U")) {
           if (Gadgets.checkEMail(sUsr)) {
             sUsr = ACLUser.getIdFromEmail(oCon, sUsr);
             if (null==sUsr)
               iAuth = ACL.USER_NOT_FOUND;
             else
               iAuth = ACL.autenticate(oCon, sUsr, sPwd, ACL.PWD_CLEAR_TEXT);
           } else {
             iAuth = ACL.autenticate(oCon, sUsr, sPwd, ACL.PWD_CLEAR_TEXT);
           }
         } else {
           iAuth = 0;
         } // fi (exists k_users)
         switch (iAuth) {
             case ACL.ACCOUNT_CANCELLED:
               response.sendError(HttpServletResponse.SC_FORBIDDEN, "Account cancelled");
               break;
             case ACL.ACCOUNT_DEACTIVATED:
               response.sendError(HttpServletResponse.SC_FORBIDDEN, "Account deactivated");
               break;
             case ACL.INVALID_PASSWORD:
               response.sendError(HttpServletResponse.SC_FORBIDDEN, "Invalid password");
               break;
             case ACL.PASSWORD_EXPIRED:
               response.sendError(HttpServletResponse.SC_FORBIDDEN, "Password expired");
               break;
             case ACL.USER_NOT_FOUND:
               response.sendError(HttpServletResponse.SC_FORBIDDEN, "User not found");
               break;
             default:
               String sNextVal = String.valueOf(DBBind.nextVal(oCon, sTbl));
               response.setContentType("text/plain");
               response.setCharacterEncoding("ISO-8859-1");
               response.getOutputStream().write(sNextVal.getBytes("ISO8859_1"));
         } // end switch
         oCon.close("HttpDataObjsServlet");
         oCon = null;
       } catch (SQLException sqle) {
         if (null!=oCon) {
           try { oCon.close("HttpDataObjsServlet"); } catch (Exception ignore) {}
           oCon = null;
         }
         if (DebugFile.trace) DebugFile.decIdent();
         throw new ServletException("SQLException "+sqle.getMessage());
       }       
     } // fi
     if (DebugFile.trace) {
       DebugFile.decIdent();
       DebugFile.writeln("End HttpDataObjsServlet.doPost()");
     }
  } // doPost

  // ---------------------------------------------------------------------------
}

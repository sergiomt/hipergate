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

import java.text.SimpleDateFormat;
import java.text.ParseException;

import java.sql.SQLException;

import javax.servlet.*;
import javax.servlet.http.*;

import com.knowgate.debug.DebugFile;
import com.knowgate.debug.StackTraceUtil;
import com.knowgate.jdc.JDCConnection;
import com.knowgate.dataobjs.DB;
import com.knowgate.dataobjs.DBBind;
import com.knowgate.dataobjs.DBColumn;
import com.knowgate.dataobjs.DBPersist;
import com.knowgate.dataobjs.DBSubset;
import com.knowgate.misc.Environment;
import com.knowgate.misc.Gadgets;
import com.knowgate.acl.ACL;
import com.knowgate.acl.ACLUser;
import com.knowgate.workareas.WorkArea;

/**
 * @author Sergio Montoro Ten
 * @version 3.0
 */

public class HttpDataObjsServlet extends HttpServlet {

  private static HashMap oBindings;
  private static HashMap oWorkAreas;

  public HttpDataObjsServlet() {
    oBindings = new HashMap();
    oWorkAreas = new HashMap();
  }

  // ---------------------------------------------------------------------------

  private static synchronized boolean isUserAllowed(JDCConnection oCon, String sUser, String sWrkA)
      throws SQLException {

      if (DebugFile.trace) {
        DebugFile.writeln("Begin HttpDataObjsServlet.isUserAllowed("+sUser+","+sWrkA+")");
        DebugFile.incIdent();
      }

      HashMap oUserMap = (HashMap) oWorkAreas.get(sWrkA);
      if (null==oUserMap) {
        oUserMap = new HashMap();
        oWorkAreas.put(sWrkA, oUserMap);
      }
      Boolean oAllowed = (Boolean) oUserMap.get(sUser);
      if (null==oAllowed) {
        oAllowed = new Boolean(WorkArea.isAdmin(oCon, sWrkA, sUser) ||
                               WorkArea.isPowerUser(oCon, sWrkA, sUser) ||
                               WorkArea.isUser(oCon, sWrkA, sUser));
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

    if (sCmd.equalsIgnoreCase("update")) {
      response.sendError(HttpServletResponse.SC_METHOD_NOT_ALLOWED, "Command " + sCmd + " only allowed for POST method");
      return;
    }

    if (!sCmd.equalsIgnoreCase("ping") && !sCmd.equalsIgnoreCase("query")) {
      response.sendError(HttpServletResponse.SC_METHOD_NOT_ALLOWED, "Command " + sCmd + " not recognized");
      return;
    }

    if (sCmd.equalsIgnoreCase("ping")) {
      response.setContentType("text/plain");
      response.getOutputStream().print("HttpDataObjsServlet ping OK");
    } else if (sCmd.equalsIgnoreCase("query")){
      doPost(request, response);
    }

  } // doGet

  // ---------------------------------------------------------------------------

  public void doPost(HttpServletRequest request, HttpServletResponse response)
     throws IOException, ServletException {

     DBBind oBnd = null;
     JDCConnection oCon = null;

     short iAuth;
     boolean bAllowed;
     String sDbb = request.getParameter("profile");
     String sUsr = request.getParameter("user");
     String sPwd = request.getParameter("password");
     String sCmd = request.getParameter("command");
     String sCls = request.getParameter("class");
     String sTbl = request.getParameter("table");
     String sFld = request.getParameter("fields");
     String sWhr = request.getParameter("where");
     String sMax = request.getParameter("maxrows");
     String sSkp = request.getParameter("skip");
     String sCol = request.getParameter("coldelim");
     String sRow = request.getParameter("rowdelim");

     if (DebugFile.trace) {
       DebugFile.writeln("Begin HttpDataObjsServlet.doPost()");
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
     }
     if (null==sTbl) {
       if (DebugFile.trace) DebugFile.decIdent();
       response.sendError(HttpServletResponse.SC_BAD_REQUEST, "Parameter table is requiered");
       return;
     }

     Properties oEnv = Environment.getProfile(sDbb);

     if (null==oEnv) {
       if (DebugFile.trace) DebugFile.decIdent();
       response.sendError(HttpServletResponse.SC_SERVICE_UNAVAILABLE, "Databind " + sDbb + " is not available");
       return;
     }

     if (!sCmd.equalsIgnoreCase("ping") && !sCmd.equalsIgnoreCase("query") && !sCmd.equalsIgnoreCase("update")) {
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
       oBnd = (DBBind) oBindings.get(sDbb);
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
         if (oBnd.exists(oCon, DB.k_users, "U")) {
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
               oDbs.load(oCon, iSkp);
               response.setContentType("text/plain");
               response.setCharacterEncoding("UTF-8");
               response.getOutputStream().write(oDbs.toString().getBytes("UTF-8"));
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
     }
     else if (sCmd.equalsIgnoreCase("update")) {
       if (DebugFile.trace) DebugFile.writeln("command is update");
       Enumeration oParamNames = request.getParameterNames();
       DBPersist oDbp;
       Class oCls;
       if (null==sCls) {
         oDbp = new DBPersist(sTbl, "DBPersist");
         try {
           oCls = Class.forName("com.knowgate.dataobjs.DBPersist");
         } catch (ClassNotFoundException neverthrown) { oCls=null; }
       } else {
         try {
           oCls = Class.forName(sCls);
           oDbp = (DBPersist) oCls.newInstance();
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
       }
       if (DebugFile.trace) DebugFile.writeln("class "+oDbp.getClass().getName()+" instantiated");
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
                   oDbp.put(sKeyName, request.getParameter(sKey), new SimpleDateFormat(sDtFmt));
                 } else {
                   oDbp.put(sKeyName, request.getParameter(sKey), DBColumn.getSQLType(sSQLType));
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
                 oDbp.put(sKeyName, request.getParameter(sKey), DBColumn.getSQLType(sSQLType));
               } catch (NumberFormatException nfe) {
                 if (DebugFile.trace) DebugFile.decIdent();
                 throw new ServletException("ERROR NumberFormatException "+sKey+" "+" "+request.getParameter(sKey)+" "+nfe.getMessage());
               }
             }
           } else {
             oDbp.put(sKeyName, request.getParameter(sKey));
           }
         } else {
           oDbp.put(sKey, request.getParameter(sKey));
         }
       } // wend
       try {
         oCon = oBnd.getConnection("HttpDataObjsServlet");
         if (null==oCon) {
           if (DebugFile.trace) DebugFile.decIdent();
           throw new ServletException("ERROR Unable to get database connection from pool "+sDbb);
         }
         if (oBnd.exists(oCon, DB.k_users, "U")) {
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
             if (oDbp.isNull(DB.gu_workarea))
               bAllowed = true;
             else
               bAllowed = isUserAllowed(oCon, sUsr, oDbp.getString(DB.gu_workarea));
             if (bAllowed) {
               oCon.setAutoCommit(true);
               if (null==sCls) {
                 oDbp.store(oCon);
               } else {
                 if (DebugFile.trace) DebugFile.writeln(oCls.getName()+".getMethod(\"store\", new Class[]{Class.forName(\"com.knowgate.jdc.JDCConnection\")}).invoke(...)");
                 oCls.getMethod("store", new Class[]{Class.forName("com.knowgate.jdc.JDCConnection")}).invoke(oDbp, new Object[]{oCon});
               } // fi (sCls)
               response.setContentType("text/plain");
               response.setCharacterEncoding("UTF-8");
               response.getOutputStream().print("SUCCESS");
             } else {
               response.sendError(HttpServletResponse.SC_FORBIDDEN, "User does not have write permissions on target WorkArea");
             } // fi (bAllowed)
         } // end switch
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
         if (null!=oCon) {
           try { oCon.close("HttpDataObjsServlet"); oCon = null;
           } catch (Exception ignore) {}
         } // fi
         if (DebugFile.trace) DebugFile.decIdent();
         throw new ServletException(xcpt.getClass().getName()+" "+xcpt.getMessage()+"\n"+StackTraceUtil.getStackTrace(xcpt));
       }
     } // fi
     if (DebugFile.trace) {
       DebugFile.decIdent();
       DebugFile.writeln("End HttpDataObjsServlet.doPost()");
     }
  } // doPost

  // ---------------------------------------------------------------------------
}

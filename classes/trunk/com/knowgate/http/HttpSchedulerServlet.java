/*
  Copyright (C) 2003-2006  Know Gate S.L. All rights reserved.
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

import javax.servlet.*;
import javax.servlet.http.*;

import java.sql.SQLException;

import com.knowgate.debug.DebugFile;
import com.knowgate.misc.Environment;
import com.knowgate.misc.Gadgets;
import com.knowgate.scheduler.SchedulerDaemon;

/**
 * @author Sergio Montoro Ten
 * @version 3.0
 */

public class HttpSchedulerServlet extends HttpServlet {

  // ---------------------------------------------------------------------------

  private SchedulerDaemon oDaemon;
  private String sProfile;

  // ---------------------------------------------------------------------------

  public HttpSchedulerServlet() {
    oDaemon=null;
    sProfile=null;
  }

  // ---------------------------------------------------------------------------

  private static boolean isVoid(String sParam) {
    if (null==sParam)
      return true;
    else
      return (sParam.length()==0);
  }

  // ---------------------------------------------------------------------------

  public void init() throws ServletException {
    ServletConfig sconfig = getServletConfig();

    if (DebugFile.trace) {
      DebugFile.writeln("Begin HttpSchedulerServlet.init()");
      DebugFile.incIdent();
    }

    sProfile = sconfig.getInitParameter("profile");

    if (isVoid(sProfile)) {
      sProfile = Gadgets.chomp(Environment.getEnvVar("KNOWGATE_PROFILES",Environment.DEFAULT_PROFILES_DIR), java.io.File.separator) + "hipergate.cnf";
    }

    if (DebugFile.trace) DebugFile.writeln("profile is " + sProfile);

    if (DebugFile.trace) {
      DebugFile.decIdent();
      DebugFile.writeln("End HttpSchedulerServlet.init()");
    }
  } // init

  // ---------------------------------------------------------------------------

  public void destroy() {
    if (DebugFile.trace) {
      DebugFile.writeln("Begin HttpSchedulerServlet.destroy()");
      DebugFile.incIdent();
    }
    if (null!=oDaemon) {
      try {
        oDaemon.stopAll();
      }
      catch (IllegalStateException ise) {
        if (DebugFile.trace)
          DebugFile.writeln("IllegalStateException " + ise.getMessage());
      }
      catch (SQLException sql) {
        if (DebugFile.trace)
          DebugFile.writeln("SQLException " + sql.getMessage());
      }
      oDaemon = null;
    }
    if (DebugFile.trace) {
      DebugFile.decIdent();
      DebugFile.writeln("End HttpSchedulerServlet.destroy()");
    }
  } // destroy

  // ---------------------------------------------------------------------------

  private static void writeXML(HttpServletResponse response, String sTxt) throws ServletException {
    response.setContentType("text/xml");
    ServletOutputStream oOut = null;
    try {
      oOut = response.getOutputStream();
      oOut.print(sTxt);
    } catch (java.io.IOException ioe) {
      throw new ServletException(ioe.getMessage(), ioe);
    }
  } // writeXML

  // ---------------------------------------------------------------------------

  /**
   * <p>Perform action on SchedulerDaemon and return resulting status</p>
   * The output written to ServletOutputStream is an XML string of the form:<br>
   * &lt;scheduler&gt;&lt;status&gt;{start|stop|running|stopped}&lt;/status&gt;&lt;startdate&gt;Thu Jul 14 23:04:33 CEST 2005&lt;/startdate&gt;&lt;stopdate&gt;&lt;/stopdate&gt;&lt;runningtime&gt;98767&lt;/runningtime&gt;&lt;poolsize&gt;2&lt;/poolsize&gt;&lt;livethreads&gt;1&lt;/livethreads&gt;&lt;queuelength&gt;4&lt;/queuelength&gt;&lt;/scheduler&gt;
   * @param request Contains parameters: action = { start, stop, restart, info }
   * @param response HttpServletResponse
   * @throws ServletException
   */
  public void doGet(HttpServletRequest request, HttpServletResponse response)
     throws ServletException {

   String sAction = request.getParameter("action");
   if (null==sAction) sAction = "";

    if (DebugFile.trace) {
      DebugFile.writeln("Begin HttpSchedulerServlet.doGet("+sAction+")");
      DebugFile.incIdent();
    }

    if ((null!=oDaemon) && sAction.equals("restart")) {
      try {
        oDaemon.stopAll();
        oDaemon = null;
      } catch (Exception xcpt) {
        writeXML(response, "<scheduler><error><![CDATA["+xcpt.getClass().getName()+" "+xcpt.getMessage()+"]]></error></scheduler>");
      }
      if (null!=oDaemon) {
        if (DebugFile.trace) {
          DebugFile.writeln("HttpSchedulerServlet.doGet() : No scheduler instance found. Re-start failed");
          DebugFile.decIdent();
        }
        return;
      }
    } // fi (restart)

    String sStatus = "", sSize = "", sLive = "", sQueue = "", sStartDate = "", sStopDate = "", sRunning = "";

    if (sAction.equals("start") || sAction.equals("restart")) {
      if (null==oDaemon) {
        try {
          oDaemon = new SchedulerDaemon(sProfile);
          if (DebugFile.trace) {
            DebugFile.writeln("SchedulerDaemon.start()");
          }
          oDaemon.start();
          sStatus = "start";
        }
        catch (Exception xcpt) {
          if (DebugFile.trace) {
            DebugFile.writeln("HttpSchedulerServlet.doGet() : "+xcpt.getClass().getName()+" "+xcpt.getMessage());
          }
          if (oDaemon!=null) {
            try { oDaemon.stopAll(); }
            catch (Exception ignore) {
              DebugFile.writeln("HttpSchedulerServlet.doGet() : " + ignore.getClass().getName() + " " + ignore.getMessage());
            }
            oDaemon=null;
          }
          writeXML(response, "<scheduler><error><![CDATA["+xcpt.getClass().getName()+" "+xcpt.getMessage()+"]]></error></scheduler>");
        } // catch
        if (sStatus.length()==0) {
          if (DebugFile.trace) {
            DebugFile.writeln("Scheduler status is unknown");
            DebugFile.decIdent();
          }
          return;
        }
      }
      else {
        sStatus = "running";
      }
    }
    else if (sAction.equals("stop")) {
      if (null!=oDaemon) {
        try {
          oDaemon.stopAll();
          if (null!=oDaemon.stopDate()) sStopDate = oDaemon.stopDate().toString();
          oDaemon=null;
          sStatus = "stop";
        } catch (IllegalStateException ist) {
            DebugFile.writeln("HttpSchedulerServlet.doGet() : IllegalStateException " + ist.getMessage());
            writeXML(response, "<scheduler><error><![CDATA["+ist.getMessage()+"]]></error></scheduler>");
        } catch (SQLException sql) {
            DebugFile.writeln("HttpSchedulerServlet.doGet() : SQLException " + sql.getMessage());
            writeXML(response, "<scheduler><error><![CDATA["+sql.getMessage()+"]]></error></scheduler>");
        }
        if (null!=oDaemon) {
          if (oDaemon.isAlive()) { try { oDaemon.stop(); } catch (Exception ignore) {} }
          oDaemon=null;
        }
        if (sStatus.length()==0) {
          if (DebugFile.trace) {
            DebugFile.writeln("Scheduler status is unknown");
            DebugFile.decIdent();
          }
          return;
        }
      }
      else {
        sStatus = "stopped";
      }
    }
    else if (sAction.equals("info")) {
      if (null==oDaemon) {
        sStatus = "stopped";
      } else {
        if (oDaemon.isAlive())
          sStatus = "running";
        else
          sStatus = "death";
        if (null!=oDaemon.threadPool()) {
          sSize = String.valueOf(oDaemon.threadPool().size());
          sLive = String.valueOf(oDaemon.threadPool().livethreads());
        }
        if (null!=oDaemon.atomQueue())
          sQueue = String.valueOf(oDaemon.atomQueue().size());
      }
    }

    if (null!=oDaemon) {
      if (null!=oDaemon.startDate()) sStartDate = oDaemon.startDate().toString();
      if (null!=oDaemon.stopDate() ) sStopDate = oDaemon.stopDate().toString();
      if (null!=oDaemon.threadPool())
        sRunning = String.valueOf(oDaemon.threadPool().getRunningTimeMS());
    }

    writeXML(response, "<scheduler><error/><status>"+sStatus+"</status><startdate>"+sStartDate+"</startdate><stopdate>"+sStopDate+"</stopdate><runningtime>"+sRunning+"</runningtime><poolsize>"+sSize+"</poolsize><livethreads>"+sLive+"</livethreads><queuelength>"+sQueue+"</queuelength></scheduler>");

    if (DebugFile.trace) {
      DebugFile.writeln("start date="+sStartDate);
      DebugFile.writeln("stop date="+sStopDate);
      DebugFile.writeln("pool size="+sSize);
      DebugFile.writeln("live threads="+sLive);
      DebugFile.writeln("queue length="+sQueue);
      DebugFile.decIdent();
      DebugFile.writeln("End HttpSchedulerServlet.doGet() : " + sStatus);
    }
  } // doGet

  // ---------------------------------------------------------------------------
} // HttpSchedulerServlet

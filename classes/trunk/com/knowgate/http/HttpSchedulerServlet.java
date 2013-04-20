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

import java.io.File;
import java.io.FileNotFoundException;
import java.io.IOException;

import java.sql.SQLException;

import com.knowgate.dataobjs.DBBind;
import com.knowgate.debug.DebugFile;
import com.knowgate.debug.StackTraceUtil;
import com.knowgate.jdc.JDCConnection;
import com.knowgate.scheduler.Job;
import com.knowgate.misc.Environment;
import com.knowgate.misc.Gadgets;
import com.knowgate.scheduler.EventDaemon;
import com.knowgate.scheduler.SchedulerDaemon;

/**
 * @author Sergio Montoro Ten
 * @version 7.0
 */

public class HttpSchedulerServlet extends HttpServlet {
 
  private static final long serialVersionUID = 700l;

  // ---------------------------------------------------------------------------

  private EventDaemon oEventDaemon;
  private SchedulerDaemon oSchedDaemon;
  private String sProfile;

  // ---------------------------------------------------------------------------

  public HttpSchedulerServlet() {
    oSchedDaemon=null;
    oEventDaemon=null;
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
      sProfile = Gadgets.chomp(Environment.getEnvVar("KNOWGATE_PROFILES",Environment.DEFAULT_PROFILES_DIR), File.separator) + "hipergate.cnf";
    } else if (sProfile.indexOf('.')<0) {
      sProfile = Gadgets.chomp(Environment.getEnvVar("KNOWGATE_PROFILES",Environment.DEFAULT_PROFILES_DIR), File.separator) + sProfile + ".cnf";
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

	if (null!=oSchedDaemon) {
      try {
        oSchedDaemon.stopAll();
      }
      catch (IllegalStateException ise) {
        if (DebugFile.trace)
          DebugFile.writeln("IllegalStateException " + ise.getMessage());
      }
      catch (SQLException sql) {
        if (DebugFile.trace)
          DebugFile.writeln("SQLException " + sql.getMessage());
      }
      oSchedDaemon = null;
    }
    
    if (null!=oEventDaemon) {
      oEventDaemon.close();
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
   * @param request Contains parameters: action = { start, stop, restart, info, abort }
   * @param response HttpServletResponse
   * @throws ServletException
   */
  public void doGet(HttpServletRequest request, HttpServletResponse response)
     throws ServletException {

   DBBind oDbj;
   boolean bError = false;
   
   String sAction = request.getParameter("action");
   if (null==sAction) sAction = "";

   String sId = request.getParameter("id");

    if (DebugFile.trace) {
      DebugFile.writeln("Begin HttpSchedulerServlet.doGet("+sAction+")");
      DebugFile.incIdent();
    }

    if (sAction.equals("restart")) {
      if (null!=oSchedDaemon) {
        try {
          oSchedDaemon.stopAll();
          oSchedDaemon = null;
        } catch (Exception xcpt) {
          writeXML(response, "<scheduler><error><![CDATA["+xcpt.getClass().getName()+" "+xcpt.getMessage()+"]]></error></scheduler>");
        }
        if (null!=oSchedDaemon) {
          if (DebugFile.trace) {
          DebugFile.writeln("HttpSchedulerServlet.doGet("+sAction+") : No scheduler instance found. Re-start failed");
          DebugFile.decIdent();
          }
        return;
        }
      } // fi (null!=oSchedDaemon)

      if (null!=oEventDaemon) {
    	oEventDaemon.close();
    	oEventDaemon.run();
      }
    } // fi (restart)

    String sStatus = "", sSize = "", sLive = "", sQueue = "", sStartDate = "", sStopDate = "", sRunning = "";

    if (sAction.equals("start") || sAction.equals("restart")) {

      if (null==oSchedDaemon) {
        try {
          oSchedDaemon = new SchedulerDaemon(sProfile);
          if (DebugFile.trace)
            DebugFile.writeln("SchedulerDaemon.start()");
          oSchedDaemon.start();
          sStatus = "running";
        }
        catch (Exception xcpt) {
          if (DebugFile.trace) {
            DebugFile.writeln("HttpSchedulerServlet.doGet("+sAction+") : "+xcpt.getClass().getName()+" "+xcpt.getMessage());
          }
          if (oSchedDaemon!=null) {
            try { oSchedDaemon.stopAll(); }
            catch (Exception ignore) {
              DebugFile.writeln("HttpSchedulerServlet.doGet("+sAction+") : " + ignore.getClass().getName() + " " + ignore.getMessage());
            }
            oSchedDaemon=null;
          }
          bError = true;
          writeXML(response, "<scheduler><error><![CDATA["+xcpt.getClass().getName()+" "+xcpt.getMessage()+"]]></error></scheduler>");
        } // catch
        if (sStatus.length()==0) {
          if (DebugFile.trace) {
            DebugFile.writeln("Scheduler status is unknown");
            DebugFile.decIdent();
          }
          return;
        }
      } else {
    	if (sAction.equals("restart")) {
          oSchedDaemon.haltAll();
          if (DebugFile.trace)
            DebugFile.writeln("SchedulerDaemon.start()");
          oSchedDaemon.start();          
    	} else {
          if (DebugFile.trace)
            DebugFile.writeln("SchedulerDaemon was already started");
    	}
        sStatus = "running";
      }
      
      if (null==oEventDaemon) {
    	try {
		  oEventDaemon = new EventDaemon(sProfile);
	      oEventDaemon.run();
		} catch (IOException e) {
	      if (DebugFile.trace) DebugFile.writeln("IOException "+e.getMessage());
		}
      } else {
      	if (sAction.equals("restart")) {
      	  oEventDaemon.close();
		  try {
			oEventDaemon = new EventDaemon(sProfile);
		  } catch (IOException e) {
            if (DebugFile.trace) DebugFile.writeln("IOException "+e.getMessage());
		  }
	      oEventDaemon.run();
      	} else {
          if (DebugFile.trace)
        	DebugFile.writeln("EventDaemon was already started");      	
      	}
      }

    } else if (sAction.equals("reload")) {
      if (null!=oEventDaemon) oEventDaemon.close();
	  try {
		oEventDaemon = new EventDaemon(sProfile);
	  } catch (IOException e) {
	    if (DebugFile.trace) DebugFile.writeln("IOException "+e.getMessage());
	  }
      oEventDaemon.run();

    } else if (sAction.equals("stop")) {
      if (null!=oSchedDaemon) {
        try {
          oSchedDaemon.stopAll();
          if (null!=oSchedDaemon.stopDate()) sStopDate = oSchedDaemon.stopDate().toString();
          oSchedDaemon=null;
          sStatus = "stop";
        } catch (Exception xcpt) {
            bError = true;
            DebugFile.writeln("HttpSchedulerServlet.doGet(stop) : "+xcpt.getClass().getName()+" " + xcpt.getMessage());
            try { DebugFile.writeln(StackTraceUtil.getStackTrace(xcpt)); } catch (Exception ignore) {}
            writeXML(response, "<scheduler><error><![CDATA["+xcpt.getMessage()+"]]></error></scheduler>");
        }
        if (null!=oSchedDaemon) {
          if (oSchedDaemon.isAlive()) { try { oSchedDaemon.stop(); } catch (Exception ignore) {} }
          oSchedDaemon=null;
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
      
      if (oEventDaemon!=null) {
    	oEventDaemon.close();
    	oEventDaemon=null;
      }
    }

    else if (sAction.equals("info")) {
      if (null==oSchedDaemon) {
        sStatus = "stopped";
      } else {
        if (oSchedDaemon.isAlive())
          sStatus = "running";
        else
          sStatus = "death";
        if (null!=oSchedDaemon.threadPool()) {
          sSize = String.valueOf(oSchedDaemon.threadPool().size());
          sLive = String.valueOf(oSchedDaemon.threadPool().livethreads());
        }
        if (null!=oSchedDaemon.atomQueue())
          sQueue = String.valueOf(oSchedDaemon.atomQueue().size());
      }
    }

    else if (sAction.equals("abort")) {
      if (DebugFile.trace) DebugFile.writeln("aborting job "+sId);
      if (null!=sId) {
        if (null!=oSchedDaemon) {
      	  try {
      	    oSchedDaemon.abortJob(sId);
      	  } catch (Exception xcpt) {
              bError = true;
              DebugFile.writeln("HttpSchedulerServlet.doGet(abort) : " + xcpt.getClass().getName() + " " + xcpt.getMessage());
              writeXML(response, "<scheduler><error><![CDATA["+xcpt.getClass().getName()+" "+xcpt.getMessage()+"]]></error></scheduler>");
      	  }
        } else {
          oDbj = new DBBind(Gadgets.substrUpTo(sProfile.substring(sProfile.lastIndexOf(File.separator)+1),0,'.'));
		  JDCConnection oCon = null;
		  try {
		    oCon = oDbj.getConnection("SchedulerDaemon");
            Job.instantiate(oCon, sId, oDbj.getProperties()).abort(oCon);
            oCon.close("SchedulerDaemon");
            oCon=null;
		  } catch (Exception xcpt) {
              DebugFile.writeln("HttpSchedulerServlet.doGet(abort) : " + xcpt.getClass().getName() + " " + xcpt.getMessage());
              writeXML(response, "<scheduler><error><![CDATA["+xcpt.getClass().getName()+" "+xcpt.getMessage()+"]]></error></scheduler>");
		  } finally {
		  	try {
              if (null!=oCon) if (!oCon.isClosed()) oCon.close("SchedulerDaemon");
              oDbj.close();
		  	} catch (SQLException ignore) { }
		  }                    
        } // fi
      } // fi

    }

    else if (sAction.equals("stats")) {
      if (null==oSchedDaemon) {
        writeXML(response, "<scheduler><error><![CDATA[Job scheduler is not currently running]]></error></scheduler>");
      } else {
        writeXML(response, "<scheduler><stats><![CDATA["+oSchedDaemon.databaseBind().connectionPool().dumpStatistics()+"]]></stats></scheduler>");      	
      }
    } // fi

    if (null!=oSchedDaemon) {
      if (null!=oSchedDaemon.startDate()) sStartDate = oSchedDaemon.startDate().toString();
      if (null!=oSchedDaemon.stopDate() ) sStopDate = oSchedDaemon.stopDate().toString();
      if (null!=oSchedDaemon.threadPool())
        sRunning = String.valueOf(oSchedDaemon.threadPool().getRunningTimeMS());
    }

    if (!bError) writeXML(response, "<scheduler><error/><status>"+sStatus+"</status><startdate>"+sStartDate+"</startdate><stopdate>"+sStopDate+"</stopdate><runningtime>"+sRunning+"</runningtime><poolsize>"+sSize+"</poolsize><livethreads>"+sLive+"</livethreads><queuelength>"+sQueue+"</queuelength></scheduler>");

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

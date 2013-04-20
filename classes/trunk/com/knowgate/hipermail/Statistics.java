/*
  Copyright (C) 2010 Know Gate S.L. All rights reserved.

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

package com.knowgate.hipermail;

import java.io.PrintStream;

import java.util.Arrays;
import java.util.ArrayList;
import java.util.Date;
import java.util.HashMap;

import java.text.SimpleDateFormat;

import java.sql.DriverManager;
import java.sql.Connection;
import java.sql.ResultSet;
import java.sql.Statement;
import java.sql.PreparedStatement;
import java.sql.SQLException;
import java.sql.Timestamp;
import java.sql.Types;

import com.knowgate.jdc.JDCConnection;
import com.knowgate.debug.StackTraceUtil;
import com.knowgate.dataobjs.DB;
import com.knowgate.scheduler.Atom;
import com.knowgate.misc.Environment;

import java.util.Properties;

public class Statistics {

  private static String[] aAgents = { "Unknown", "Internet Explorer 6.0", "Internet Explorer 7.0", "Internet Explorer 8.0",
                                      "Firefox 2.0", "Firefox 3.0", "Firefox 3.5", "iPhone", "Android", "Minimo",
                                      "Lotus Notes", "Thunderbird", "Safari", "Google Chrome", "Outlook", "Evolution",
                                      "Other Gecko", "Other" };

  private Properties oEnvProps;
  private PrintStream oVerbose;
  
  public Statistics(Properties oProprts, PrintStream oPrntStrm) {
    oEnvProps = oProprts;
    oVerbose = oPrntStrm;
  }

  private static int indentifyUserAgent(String sUserAgent) {
    if (sUserAgent==null) {
      return 0;
    } else if (sUserAgent.length()==0) {
      return 0;    
    } else if (sUserAgent.indexOf("Outlook")>0) {
		  return 14; 
    } else if (sUserAgent.startsWith("Mozilla/4.0 (compatible; MSIE 6.0;")) {
		  return 1;    
    } else if (sUserAgent.startsWith("Mozilla/4.0 (compatible; MSIE 7.0;")) {
		  return 2;    
    } else if (sUserAgent.startsWith("Mozilla/4.0 (compatible; MSIE 8.0;")) {
		  return 3;    
    } else if (sUserAgent.indexOf("Firefox/2.0")>0) {
		  return 4;    
    } else if (sUserAgent.indexOf("Firefox/3.0")>0) {
		  return 5;    
    } else if (sUserAgent.indexOf("Firefox/3.5")>0) {
		  return 6;    
    } else if (sUserAgent.indexOf("iPhone")>0) {
		  return 7;    
    } else if (sUserAgent.indexOf("Android")>0) {
		  return 8;    
    } else if (sUserAgent.indexOf("Minimo")>0) {
		  return 9;    
    } else if (sUserAgent.indexOf("Lotus-Notes")>0) {
		  return 10;    
    } else if (sUserAgent.indexOf("Thunderbird")>0) {
		  return 11;    
    } else if (sUserAgent.indexOf("Safari")>0) {
		  return 12;  
    } else if (sUserAgent.indexOf("Chrome")>0) {
		  return 13; 
    } else if (sUserAgent.indexOf("Evolution")>0) {
		  return 15;
    } else if (sUserAgent.indexOf("Gecko")>0) {
		  return 16;
    } else {
		  return 17;
    }    
  }
 
  private long getIntervalMilis (Object obj)
    throws ArrayIndexOutOfBoundsException,ClassCastException {
   
    if (null==obj)
      return 0l;
    else if (obj.getClass().getName().equals("org.postgresql.util.PGInterval")) {
      final float SecMilis = 1000f;
      final long MinMilis = 60000l, HourMilis=3600000l, DayMilis=86400000l;
      long lInterval = 0;
      String[] aParts = obj.toString().trim().split("\\s");
	  for (int p=0; p<aParts.length-1; p+=2) {
	  	Float fPart = new Float(aParts[p]);
	  	if (fPart.floatValue()!=0f) {
	  	  if (aParts[p+1].startsWith("year"))
	  	  	lInterval += fPart.longValue()*DayMilis*365l;
	  	  else if (aParts[p+1].startsWith("mon"))
	  	  	lInterval += fPart.longValue()*DayMilis*30l;
	  	  else if (aParts[p+1].startsWith("day"))
	  	  	lInterval += fPart.longValue()*DayMilis;
	  	  else if (aParts[p+1].startsWith("hour"))
	  	  	lInterval += fPart.longValue()*HourMilis;
	  	  else if (aParts[p+1].startsWith("min"))
	  	  	lInterval += fPart.longValue()*MinMilis;
	  	  else if (aParts[p+1].startsWith("sec"))
	  	  	lInterval += new Float(fPart.floatValue()*SecMilis).longValue();	  	  	
	  	}
	  }
      return lInterval;
    }
    else
      throw new ClassCastException("Cannot cast "+obj.getClass().getName()+" to Timestamp");
  } // getIntervalMilis

  private void verbose(String sMsg) {
    if (oVerbose!=null)	oVerbose.println(sMsg);
  }
  
  public boolean collect(String sGuJobGroup) {

	boolean bRetVal = true;
    Date dtNow = new Date();
	long lTheDay;
	Timestamp tsNow = new Timestamp(dtNow.getTime());
	int iDBMS = JDCConnection.DBMS_GENERIC;
	Statement oStmt;
  	Connection oConn = null;
	PreparedStatement oPtmt = null;
	PreparedStatement oQtmt = null;
	ResultSet oRSet;
	String sJobs = "";
	ArrayList<String> aJobs = new ArrayList<String>();
	HashMap<String,String> mWrks = new HashMap<String,String>();
	SimpleDateFormat oYmd = new SimpleDateFormat("yyyy-MM-dd");

	verbose ("Begin statistics collection for job group "+sGuJobGroup);

	try {

  	  @SuppressWarnings("unused")
	  Class oDriver = Class.forName(oEnvProps.getProperty("driver"));

	  verbose ("Connecting to "+oEnvProps.getProperty("dburl")+" as user "+oEnvProps.getProperty("dbuser"));

  	  oConn = DriverManager.getConnection(oEnvProps.getProperty("dburl"),oEnvProps.getProperty("dbuser"),oEnvProps.getProperty("dbpassword"));

	  iDBMS = JDCConnection.getDataBaseProduct(oConn);
	  
	  oConn.setAutoCommit(true);
	  
	  // ****************************************
	  // Get the list of jobs from the job group
	  
	  oStmt = oConn.createStatement();
	  oRSet = oStmt.executeQuery("SELECT "+DB.gu_job+","+DB.gu_workarea+" FROM "+DB.k_jobs+" WHERE "+DB.gu_job_group+"='"+sGuJobGroup+"'");
	  while (oRSet.next()) {
	  	aJobs.add(oRSet.getString(1));
	  	mWrks.put(oRSet.getString(1), oRSet.getString(2));
	  	sJobs += (sJobs.length()==0 ? "('" : ",'") + oRSet.getString(1) + "'";
	  }
	  oRSet.close();
	  oStmt.close();
	  
	  // ****************************************
	  
	  if (sJobs.length()>0) {
	  	sJobs += ")";

	    verbose ("Job list is "+sJobs);
	  	
	    // ****************************************************
	  	// Set count of sent messages for each job of the group
	    oPtmt = oConn.prepareStatement("UPDATE "+DB.k_jobs+" SET "+DB.nu_sent+"=? WHERE "+DB.gu_job+"=?");
	    oStmt = oConn.createStatement();
	    oRSet = oStmt.executeQuery("SELECT COUNT(*) AS nu_messages,j."+DB.gu_job+" FROM "+DB.k_jobs+" j,"+DB.k_job_atoms_archived+" a WHERE "+"j."+DB.gu_job+"=a."+DB.gu_job+" AND "+"a."+DB.id_status+" IN ("+String.valueOf(Atom.STATUS_FINISHED)+","+String.valueOf(Atom.STATUS_RUNNING)+") AND j."+DB.gu_job+" IN "+sJobs+" GROUP BY 2");
        while (oRSet.next()) {
          oPtmt.setInt(1, oRSet.getInt(1));
          oPtmt.setString(2, oRSet.getString(2));
          oPtmt.executeUpdate();
          verbose ("Atoms count for job "+oRSet.getString(2)+" set to "+String.valueOf(oRSet.getInt(1)));
        }
	    oRSet.close();
	    oStmt.close();
	    oPtmt.close();

	    // ******************************************************
	  	// Set count of opened messages for each job of the group
	    oPtmt = oConn.prepareStatement("UPDATE "+DB.k_jobs+" SET "+DB.nu_opened+"=? WHERE "+DB.gu_job+"=?");
	    oStmt = oConn.createStatement();
	    oRSet = oStmt.executeQuery("SELECT COUNT(*) AS nu_messages,j."+DB.gu_job+" FROM "+DB.k_jobs+" j,"+DB.k_job_atoms_tracking+" a WHERE "+"j."+DB.gu_job+"=a."+DB.gu_job+" AND j."+DB.gu_job+" IN "+sJobs+" GROUP BY 2");
        while (oRSet.next()) {
          oPtmt.setInt(1, oRSet.getInt(1));
          oPtmt.setString(2, oRSet.getString(2));
          oPtmt.executeUpdate();
          verbose ("Read receipts count for job "+oRSet.getString(2)+" set to "+String.valueOf(oRSet.getInt(1)));
        }
	    oRSet.close();
	    oStmt.close();
	    oPtmt.close();

	    // ********************************************************
	  	// Set count of unique recipients for each job of the group
        
	    oPtmt = oConn.prepareStatement("UPDATE "+DB.k_jobs+" SET "+DB.nu_unique+"=? WHERE "+DB.gu_job+"=?");
		oQtmt = oConn.prepareStatement("SELECT COUNT(DISTINCT("+DB.tx_email+")) AS nu_unique_recipients FROM "+DB.k_job_atoms_archived+" WHERE "+DB.id_status+" IN ("+String.valueOf(Atom.STATUS_FINISHED)+","+String.valueOf(Atom.STATUS_RUNNING)+") AND "+DB.gu_job+"=?");
	    for (String j : aJobs) {
	      oQtmt.setString(1, j);
	      oRSet = oQtmt.executeQuery();
	      if (oRSet.next())
	        oPtmt.setInt(1, oRSet.getInt(1));
	      else
	        oPtmt.setInt(1, 0);
          verbose ("Unique e-mails count for job "+j+" set to "+String.valueOf(oRSet.getInt(1)));
	      oPtmt.setString(2, j);
	      oPtmt.executeUpdate();
	      oRSet.close();
	    } // next
	    oQtmt.close();
	    oPtmt.close();

	    // *********************************************
	  	// Set count of clicks for each job of the group
        
	    oPtmt = oConn.prepareStatement("UPDATE "+DB.k_jobs+" SET "+DB.nu_clicks+"=? WHERE "+DB.gu_job+"=?");
		oQtmt = oConn.prepareStatement("SELECT COUNT(*) AS nu_clicks FROM "+DB.k_job_atoms_clicks+" WHERE "+DB.gu_job+"=?");
	    for (String j : aJobs) {
	      oQtmt.setString(1, j);
	      oRSet = oQtmt.executeQuery();
	      if (oRSet.next())
	        oPtmt.setInt(1, oRSet.getInt(1));
	      else
	        oPtmt.setInt(1, 0);
          verbose ("Click-through count for job "+j+" set to "+String.valueOf(oRSet.getInt(1)));
	      oRSet.close();
	      oPtmt.setString(2, j);
	      oPtmt.executeUpdate();
	    }
	    oQtmt.close();
	    oPtmt.close();
	    	
	    // **********************************************************
	  	// Set count of message sent by day for each job of the group

		oStmt = oConn.createStatement();
		switch (iDBMS) {
		  case JDCConnection.DBMS_POSTGRESQL:
	        oPtmt = oConn.prepareStatement("SELECT COUNT(*) AS nu_messages,justify_days(age(current_timestamp,date_trunc('day',"+DB.dt_execution+"))) FROM "+DB.k_job_atoms_archived+" WHERE "+DB.id_status+" IN ("+String.valueOf(Atom.STATUS_FINISHED)+","+String.valueOf(Atom.STATUS_RUNNING)+") AND "+DB.gu_job+"=? GROUP BY 2");
		    break;
		  case JDCConnection.DBMS_MYSQL:
	        oPtmt = oConn.prepareStatement("SELECT COUNT(*) AS nu_messages,DATEDIFF(NOW(),"+DB.dt_execution+") FROM "+DB.k_job_atoms_archived+" WHERE "+DB.id_status+" IN ("+String.valueOf(Atom.STATUS_FINISHED)+","+String.valueOf(Atom.STATUS_RUNNING)+") AND "+DB.gu_job+"=? GROUP BY 2");
		  	break;
		  case JDCConnection.DBMS_MSSQL:
	        oPtmt = oConn.prepareStatement("SELECT COUNT(*) AS nu_messages,DATEDIFF(day, "+DB.dt_execution+", GETDATE()) FROM "+DB.k_job_atoms_archived+" WHERE "+DB.id_status+" IN ("+String.valueOf(Atom.STATUS_FINISHED)+","+String.valueOf(Atom.STATUS_RUNNING)+") AND "+DB.gu_job+"=? GROUP BY 2");
		  	break; 
		  case JDCConnection.DBMS_ORACLE:
	        oPtmt = oConn.prepareStatement("SELECT COUNT(*) AS nu_messages,TRUNC(SYSDATE-"+DB.dt_execution+") FROM "+DB.k_job_atoms_archived+" WHERE "+DB.id_status+" IN ("+String.valueOf(Atom.STATUS_FINISHED)+","+String.valueOf(Atom.STATUS_RUNNING)+") AND "+DB.gu_job+"=? GROUP BY 2");
		  	break;
		  default:
		  	throw new SQLException ("Unsupported RDBMS");
		}

	    oQtmt = oConn.prepareStatement("INSERT INTO "+DB.k_jobs_atoms_by_day+" (dt_execution,gu_job,gu_job_group,gu_workarea,nu_msgs) VALUES (?,?,'"+sGuJobGroup+"',?,?)");
	    for (String j : aJobs) {
	      oPtmt.setString(1, j);
	      oRSet = oPtmt.executeQuery();
          while (oRSet.next()) {
          	          	
		    switch (iDBMS) {
		    case JDCConnection.DBMS_POSTGRESQL:
          	  lTheDay = tsNow.getTime()-((getIntervalMilis(oRSet.getObject(2))/86400000l)*86400000l);
		      break;
		    case JDCConnection.DBMS_MSSQL:
		    case JDCConnection.DBMS_MYSQL:
		      lTheDay = tsNow.getTime()-((long)oRSet.getInt(2))*86400000l;
              break;
		    case JDCConnection.DBMS_ORACLE:
		      lTheDay = tsNow.getTime()-(oRSet.getBigDecimal(2).longValue()*86400000l);
              break;
            default:
              throw new SQLException ("Unsupported RDBMS");
		    }			
            oStmt.executeUpdate("DELETE FROM "+DB.k_jobs_atoms_by_day+" WHERE "+DB.gu_job+"='"+j+"'");
            oQtmt.setString(1, oYmd.format(new Date(lTheDay)));
            oQtmt.setString(2, j);
            oQtmt.setObject(3, mWrks.get(j), Types.CHAR);
            oQtmt.setInt(4, oRSet.getInt(1));
            oQtmt.executeUpdate();
            verbose ("Sent atoms for job "+j+" at "+oYmd.format(new Date(lTheDay))+" set to "+String.valueOf(oRSet.getInt(1)));
          } // wend
          oRSet.close();
	    }
	    oQtmt.close();
	    oPtmt.close();
		oStmt.close();

	    // ***********************************************************
	  	// Set count of message sent by hour for each job of the group

		oStmt = oConn.createStatement();
		switch (iDBMS) {
		  case JDCConnection.DBMS_POSTGRESQL:
	        oPtmt = oConn.prepareStatement("SELECT COUNT(*),date_part('hour',"+DB.dt_action+") FROM "+DB.k_job_atoms_tracking+" WHERE "+DB.gu_job+"=? GROUP BY 2");
		    break;
		  case JDCConnection.DBMS_MYSQL:
	        oPtmt = oConn.prepareStatement("SELECT COUNT(*),EXTRACT(HOUR FROM "+DB.dt_action+") FROM "+DB.k_job_atoms_tracking+" WHERE "+DB.gu_job+"=? GROUP BY 2");
		    break;
		  case JDCConnection.DBMS_MSSQL:
	        oPtmt = oConn.prepareStatement("SELECT COUNT(*),DATEPART(hour,"+DB.dt_action+") FROM "+DB.k_job_atoms_tracking+" WHERE "+DB.gu_job+"=? GROUP BY 2");
		    break;
		  case JDCConnection.DBMS_ORACLE:
	        oPtmt = oConn.prepareStatement("SELECT COUNT(*),DATEPART(hour,"+DB.dt_action+") FROM "+DB.k_job_atoms_tracking+" WHERE "+DB.gu_job+"=? GROUP BY 2");
		    break;
		}
	    oQtmt = oConn.prepareStatement("INSERT INTO "+DB.k_jobs_atoms_by_hour+" (dt_hour,gu_job,gu_job_group,gu_workarea,nu_msgs) VALUES (?,?,'"+sGuJobGroup+"',?,?)");
	    for (String j : aJobs) {
          oStmt.executeUpdate("DELETE FROM "+DB.k_jobs_atoms_by_hour+" WHERE "+DB.gu_job+"='"+j+"'");
	      oPtmt.setString(1, j);
	      oRSet = oPtmt.executeQuery();
          while (oRSet.next()) {
            oQtmt.setShort (1, (short) oRSet.getDouble(2));
            oQtmt.setString(2, j);
            oQtmt.setObject(3, mWrks.get(j), Types.CHAR);
            oQtmt.setInt   (4, oRSet.getInt(1));
            oQtmt.executeUpdate();          
            verbose ("Sent atoms for job "+j+" at time "+String.valueOf((short) oRSet.getDouble(2))+" set to "+String.valueOf(oRSet.getInt(1)));
          } // wend
          oRSet.close();
	    } // next
	    oQtmt.close();
	    oPtmt.close();
		oStmt.close();

	    // ************************************************
	  	// List email user agents for each job of the group

        int[] aAgCount = new int[aAgents.length];
	    Arrays.fill(aAgCount, 0);
		oStmt = oConn.createStatement();
		oPtmt = oConn.prepareStatement("SELECT "+DB.user_agent+" FROM "+DB.k_job_atoms_tracking+" WHERE "+DB.gu_job+"=?");
	    oQtmt = oConn.prepareStatement("INSERT INTO "+DB.k_jobs_atoms_by_agent+" (id_agent,gu_job,gu_workarea,gu_job_group,nu_msgs) VALUES (?,?,?,'"+sGuJobGroup+"',?)");
	    for (String j : aJobs) {
	      oPtmt.setString(1, j);
           oRSet = oPtmt.executeQuery();
           while (oRSet.next()) {
           	 int iAg = indentifyUserAgent(oRSet.getString(1));
             aAgCount[iAg] += 1;
           }
           oRSet.close();
           oStmt.executeUpdate("DELETE FROM "+DB.k_jobs_atoms_by_agent+" WHERE "+DB.gu_job+"='"+j+"'");
	       for (int a=0; a<aAgCount.length; a++) {
	       	 if (aAgCount[a]>0) {
	           oQtmt.setString(1, aAgents[a]);
	           oQtmt.setString(2, j);
	           oQtmt.setObject(3, mWrks.get(j), Types.CHAR);
	           oQtmt.setInt(4, aAgCount[a]);
	           oQtmt.executeUpdate();
	       	 }
	       }
	    } // next
	    oQtmt.close();
	    oPtmt.close();
	    oStmt.close();
	  } // fi
	} catch (Exception xcpt) {
	  bRetVal = false;
	  verbose (xcpt.getClass().getName()+" "+xcpt.getMessage());
	  try { verbose (StackTraceUtil.getStackTrace(xcpt));
	  } catch (java.io.IOException ignore) {}
	} finally {
	  verbose ("Closing conection");
	  try { if (oConn!=null) if (!oConn.isClosed()) oConn.close(); } catch (SQLException ignore) {}
	}
	verbose ("Done!");
	return bRetVal;
  } // collect

  public void collect()  {
  	Connection oConn = null;
	try {
  	  @SuppressWarnings("unused")
	  Class oDriver = Class.forName(oEnvProps.getProperty("driver"));	
  	  oConn = DriverManager.getConnection(oEnvProps.getProperty("dburl"),oEnvProps.getProperty("dbuser"),oEnvProps.getProperty("dbpassword"));
	  Statement oStmt = oConn.createStatement(ResultSet.TYPE_FORWARD_ONLY, ResultSet.CONCUR_READ_ONLY);
	  ResultSet oRSet = oStmt.executeQuery("SELECT DISTINCT("+DB.gu_job_group+") FROM "+DB.k_jobs+" WHERE "+DB.gu_job_group+" IS NOT NULL");
	  ArrayList<String> aGroups = new ArrayList<String>();
	  while (oRSet.next()) aGroups.add(oRSet.getString(1));
	  oRSet.close();
	  oStmt.close();
	  int n = 0;
	  for (String g : aGroups) {
	  	verbose ("Procesing group "+String.valueOf(++n)+" of "+String.valueOf(aGroups.size()));
	  	collect(g);
	  }
	} catch (Exception xcpt) {
	  verbose (xcpt.getClass().getName()+" "+xcpt.getMessage());
	  try { verbose (StackTraceUtil.getStackTrace(xcpt));
	  } catch (java.io.IOException ignore) {}
	} finally {
	  // verbose ("Closing conection");
	  try { if (oConn!=null) if (!oConn.isClosed()) oConn.close(); } catch (SQLException ignore) { }
	}  } // collect
  
  public static void main(String[] args) {
	  String sProfile = "hipergate";
	  if (args!=null) {
	  	if (args.length>0) sProfile = args[0];
	  }
	  Statistics oStats = new Statistics(Environment.getProfile(sProfile), System.out);
	  if (args==null) {
        oStats.collect();
	  } else {
	  	if (args.length>1)
	  	  oStats.collect(args[1]);
	    else
	      oStats.collect();
	  }
  } // main	
}

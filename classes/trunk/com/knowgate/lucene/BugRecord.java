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

package com.knowgate.lucene;

import java.util.Date;
import java.util.Comparator;
import java.text.SimpleDateFormat;

/**
 * @author Sergio Montoro Ten
 * @version 3.0
 */
public class BugRecord {

  public static class CompareAuthor implements Comparator {
    public int compare(Object o1, Object o2) {
      if (((BugRecord)o1).getAuthor()==null) return -1;
      return ((BugRecord)o1).getAuthor().compareTo(((BugRecord)o2).getAuthor());
    }
  }

  public static class CompareTitle implements Comparator {
    public int compare(Object o1, Object o2) {
      if (((BugRecord)o1).getTitle()==null) return -1;
      return ((BugRecord)o1).getTitle().compareTo(((BugRecord)o2).getTitle());
    }
  }

  public static class CompareDate implements Comparator {
    public int compare(Object o1, Object o2) {
      if (((BugRecord)o1).getDate()==null) return -1;
      return ((BugRecord)o1).getDate().compareTo(((BugRecord)o2).getDate());
    }
  }

  public static class ComparePriority implements Comparator {
    public int compare(Object o1, Object o2) {
      if (((BugRecord)o1).getPriority()==null) return -1;
      return ((BugRecord)o1).getPriority().compareTo(((BugRecord)o2).getPriority());
    }
  }

  public static class CompareSeverity implements Comparator {
    public int compare(Object o1, Object o2) {
      if (((BugRecord)o1).getSeverity()==null) return -1;
      return ((BugRecord)o1).getSeverity().compareTo(((BugRecord)o2).getSeverity());
    }
  }

  public static class CompareScore implements Comparator {
    public int compare(Object o1, Object o2) {
	  return new Float(((BugRecord)o1).getScore()-((BugRecord)o2).getScore()).intValue();
    }
  }

  private static SimpleDateFormat fmt = new SimpleDateFormat("yyyy-MM-dd HH:mm:ss");
  private float score;
  private int number;
  private String guid;
  private String project;
  private String title;
  private String author;
  private Date created;
  private String type;
  private String status;
  private Short priority;
  private Short severity;
  private String abstrct;

  public BugRecord() { }

  public BugRecord(float fScore, int iNumber, String sGuid, String sProject, String sTitle,
                   String sReportedBy, String sDate, String sType, String sStatus,
                   String sPriority, String sSeverity, String sAbstract) {
	score = fScore;
    number = iNumber;
    guid = sGuid;
    project = sProject;
    title = sTitle;
    author = sReportedBy;
    try { created = fmt.parse(sDate); } catch (Exception ignore) {}
    type = sType;
    if (null!=sPriority)
      priority = new Short(sPriority);
    else
      priority = null;
    if (null!=sSeverity)
      severity = new Short(sSeverity);
    else
      severity = null;
    abstrct = sAbstract;
  }

  public String getProject() {
    return project;
  }

  public int getNumber() throws NumberFormatException{
    return number;
  }

  public String getGuid() {
    return guid;
  }

  public String getTitle() {
    return title;
  }

  public String getAuthor() {
    return author;
  }

  public Date getDate() {
    return created;
  }

  public String getDateAsString() {
    return fmt.format(created);
  }

  public Short getPriority() {
    return priority;
  }

  public float getScore() {
    return score;
  }

  public Short getSeverity() {
    return severity;
  }

  public String getStatus() {
    return status;
  }

  public String getType() {
    return type;
  }

  public void setProject(String sProjectGUID) {
    project = sProjectGUID;
  }

  public void setGuid(String sGuid) {
    guid = sGuid;
  }

  public void setTitle(String sTitle) {
    title = sTitle;
  }

  public void setAuthor(String sAuthor) {
    author = sAuthor;
  }

  public void setDate(Date oDtCreated) {
    created = oDtCreated;
  }

  public void setPriority(Short oPriority) {
    priority=oPriority;
  }

  public void setSeverity(Short oSeverity) {
    severity=oSeverity;
  }

  public void setType(String sType) {
    type=sType;
  }

  public void setStatus(String sStatus) {
    status=sStatus;
  }

}

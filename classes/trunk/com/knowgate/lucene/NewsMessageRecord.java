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

public class NewsMessageRecord {

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

  public static class CompareScore implements Comparator {
    public int compare(Object o1, Object o2) {
	  return new Float(((BugRecord)o1).getScore()-((BugRecord)o2).getScore()).intValue();
    }
  }

  private static SimpleDateFormat fmt = new SimpleDateFormat("yyyy-MM-dd HH:mm:ss");
  private float score;
  private String wrka;
  private String guid;
  private String group;
  private String title;
  private String author;
  private Date created;
  private String abstrct;

  public NewsMessageRecord() { }
  

  public NewsMessageRecord(float fScore, String sWrkA, String sGuid, String sGroup, String sTitle,
                           String sAuthor, Date dtCreated, String sAbstract) {
	score = fScore;
    wrka = sWrkA;
    guid = sGuid;
    group = sGroup;
    title = sTitle;
    author = sAuthor;
    created = dtCreated;
    abstrct = sAbstract;
  }

  public String getAbstract() {
    return abstrct;
  }

  public String getWorkArea() {
    return wrka;
  }

  public String getGuid() {
    return guid;
  }

  public String getNewsGroupName() {
    return group;
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

  public float getScore() {
    return score;
  }

  public String toXML() {
    StringBuffer oBuffer = new StringBuffer(1000);
    oBuffer.append("<NewsMessageRecord>");
    oBuffer.append("<nu_score>"+String.valueOf(score)+"</nu_score>");
    oBuffer.append("<gu_msg>"+guid+"</gu_msg>");
    oBuffer.append("<gu_newsgrp>"+group+"</gu_newsgrp>");
    oBuffer.append("<nm_author><![CDATA["+author+"]]></nm_author>");
    oBuffer.append("<dt_published>"+getDateAsString()+"</dt_published>");
    oBuffer.append("<tx_subject><![CDATA["+title+"]]></tx_subject>");
    oBuffer.append("<tx_abstract><![CDATA["+abstrct+"]]></tx_abstract>");
    oBuffer.append("</NewsMessageRecord>");
    return oBuffer.toString();
  }
}

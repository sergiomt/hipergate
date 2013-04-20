/*
  Copyright (C) 2003-2011  Know Gate S.L. All rights reserved.

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
 * @version 7.0
 */

public class NewsMessageRecord {

  public static class CompareDate implements Comparator {
    public int compare(Object o1, Object o2) {
      if (((NewsMessageRecord)o1).getDate()==null) return -1;
      return ((NewsMessageRecord)o1).getDate().compareTo(((NewsMessageRecord)o2).getDate());
    }
  }

  public static class CompareScore implements Comparator {
    public int compare(Object o1, Object o2) {
	  return new Float(((NewsMessageRecord)o1).getScore()-((NewsMessageRecord)o2).getScore()).intValue();
    }
  }

  private static SimpleDateFormat fmt = new SimpleDateFormat("yyyy-MM-dd HH:mm:ss");
  private float score;
  private String wrka;
  private String guid;
  private String thrd;
  private String group;
  private String title;
  private String author;
  private Date created;
  private String abstrct;

  public NewsMessageRecord() { }
  

  public NewsMessageRecord(float fScore, String sWrkA, String sGuid, String sThread, String sGroup, String sTitle,
                           String sAuthor, Date dtCreated, String sAbstract) {
	score = fScore;
    wrka = sWrkA;
    guid = sGuid;
    thrd = sThread;
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
    oBuffer.append("<gu_thread_msg>"+thrd+"</gu_thread_msg>");
    oBuffer.append("<gu_newsgrp>"+group+"</gu_newsgrp>");
    oBuffer.append("<nm_author><![CDATA["+author+"]]></nm_author>");
    oBuffer.append("<dt_published>"+getDateAsString()+"</dt_published>");
    oBuffer.append("<tx_subject><![CDATA["+title+"]]></tx_subject>");
    oBuffer.append("<tx_abstract><![CDATA["+abstrct+"]]></tx_abstract>");
    oBuffer.append("</NewsMessageRecord>");
    return oBuffer.toString();
  }
}

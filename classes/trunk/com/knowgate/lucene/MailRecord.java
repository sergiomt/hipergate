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
public class MailRecord {

  public static class CompareAuthor implements Comparator {
    public int compare(Object o1, Object o2) {
      if (((MailRecord)o1).getAuthor()==null) return -1;
      return ((MailRecord)o1).getAuthor().compareTo(((MailRecord)o2).getAuthor());
    }
  }

  public static class CompareSubject implements Comparator {
    public int compare(Object o1, Object o2) {
      if (((MailRecord)o1).getSubject()==null) return -1;
      return ((MailRecord)o1).getSubject().compareTo(((MailRecord)o2).getSubject());
    }
  }

  public static class CompareDateSent implements Comparator {
    public int compare(Object o1, Object o2) {
      if (((MailRecord)o1).getDateSent()==null) return -1;
      return ((MailRecord)o1).getDateSent().compareTo(((MailRecord)o2).getDateSent());
    }
  }

  public static class CompareSize implements Comparator {
    public int compare(Object o1, Object o2) {
      return ((MailRecord)o1).getSize() - ((MailRecord)o2).getSize();
    }
  }

  public static class CompareFolder implements Comparator {
    public int compare(Object o1, Object o2) {
      if (((MailRecord)o1).getFolderName()==null) return -1;
      return ((MailRecord)o1).getFolderName().compareTo(((MailRecord)o2).getFolderName());
    }
  }

  private static SimpleDateFormat fmt = new SimpleDateFormat("yyyy-MM-dd HH:mm:ss");
  private String guid;
  private String subject;
  private String author;
  private String size;
  private String number;
  private String folder;
  private Date created;

  public MailRecord() { }

  public MailRecord(String sGuid, String sSubject, String sAuthor, String sDate,
                    String sSize, String sNumber, String sFolder) {
    guid = sGuid;
    subject = sSubject;
    author = sAuthor;
    try { created = fmt.parse(sDate); } catch (Exception ignore) {}
    size = sSize;
    number = sNumber;
    folder = sFolder;
  }

  public String getFolderName() {
    return folder;
  }

  public Date getDateSent() {
    return created;
  }

  public int getNumber() throws NumberFormatException{
    return Integer.parseInt(number);
  }

  public int getSize() throws NumberFormatException{
    return Integer.parseInt(size);
  }

  public String getGuid() {
    return guid;
  }

  public String getSubject() {
    return subject;
  }

  public String getAuthor() {
    return author;
  }

  public Date getDateCreated() {
    return created;
  }

  public String getDateCreatedAsString() {
    return fmt.format(created);
  }

  public void setFolderName(String sFolderName) {
    folder = sFolderName;
  }

  public void setGuid(String sGuid) {
    guid = sGuid;
  }

  public void setSubject(String sSubject) {
    subject = sSubject;
  }

  public void setAuthor(String sAuthor) {
    author = sAuthor;
  }

  public void setDateCreated(Date oDtCreated) {
    created = oDtCreated;
  }
}

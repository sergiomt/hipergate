/*
  Copyright (C) 2003-2005  Know Gate S.L. All rights reserved.
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

package com.knowgate.surveys;

import java.util.ArrayList;
import java.util.Date;
import java.util.LinkedList;
import java.util.ListIterator;
import java.sql.SQLException;

import com.knowgate.jdc.JDCConnection;
import com.knowgate.debug.DebugFile;
import com.knowgate.dataobjs.DB;
import com.knowgate.dataobjs.DBSubset;
import com.knowgate.dataobjs.DBTable;
import com.knowgate.dataobjs.DBColumn;
import com.knowgate.dataobjs.DBPersist;
import com.knowgate.misc.Gadgets;

/**
 * <p>Survey DataSheets</p>
 * This class represents a set of answers for a Survey
 * @author Sergio Montoro Ten
 * @version 1.0
 */
public class DataSheet extends DBPersist {

  //----------------------------------------------------------------------------

    protected String guid;
    protected Date lastupdate;
    protected ArrayList answers;
    protected Survey surveydef;

  //----------------------------------------------------------------------------

  /**
   * Create an empty DataSheet
   */
  public DataSheet() {
    super(DB.k_pageset_datasheets, "DataSheet");
    answers = new ArrayList();
    guid = null;
  }

  //----------------------------------------------------------------------------

  /**
   * Create an empty DataSheet for a given Survey definition
   * @param oSurveyDef Object which holds the Survey definition for this DataSheet
   */
  public DataSheet(Survey oSurveyDef) {
    super(DB.k_pageset_datasheets, "DataSheet");
    answers = new ArrayList();
    surveydef = oSurveyDef;
    guid = null;
  }

  //----------------------------------------------------------------------------

  /**
   * Get DataSheet Global Unique Identifier
   * @return String GUID
   */
  public String getGuid() {
    return guid;
  }

  //----------------------------------------------------------------------------

  /**
   * Set DataSheet Global Unique Identifier
   */
  public void setGuid(String sGuid) {
    guid = sGuid;
  }

  //----------------------------------------------------------------------------

  /**
   * Clear DataSheet
   */
  public void clear() {
    lastupdate = null;
    guid = null;
    super.clear();
    answers.clear();
  }

  //----------------------------------------------------------------------------

  /**
   * <p>Store a DataSheet at the database</p>
   * getGuid() property will be automatically set after calling this method
   * if it did not have a previous value.
   * @param oConn JDCConnection Open JDBC database connection
   * @throws IllegalStateException If Survey definition has not been set
   * @throws SQLException
   * @throws IllegalArgumentException
   * @throws ArrayIndexOutOfBoundsException
   * DataSheet GUID is null.
   */
  public boolean store(JDCConnection oConn)
    throws SQLException,IllegalStateException,ArrayIndexOutOfBoundsException,
           IllegalArgumentException {

    if (DebugFile.trace) {
      DebugFile.writeln("Begin DataSheet.store([JDCConnection])");
      DebugFile.incIdent();
    }

    if (null==surveydef) {
      DebugFile.decIdent();
      throw new IllegalStateException("Survey definition not set");
    }

    boolean bRetVal;

    final int count = answers.size();

    if (!AllVals.containsKey(DB.gu_datasheet)) {
      if (null==guid) {
        if (count>0) {
          if (!((Answer) answers.get(0)).isNull(DB.gu_datasheet)) {
            guid = ((Answer) answers.get(0)).getString(DB.gu_datasheet);
          }
          else {
            guid = Gadgets.generateUUID();
          }
        }
        else {
          guid = Gadgets.generateUUID();
        }
      }
      put(DB.gu_datasheet, guid);
    }
    else {
      if (null==guid)
        guid = getString(DB.gu_datasheet);
    }

    if (!AllVals.containsKey(DB.gu_pageset)) {
      put(DB.gu_pageset, surveydef.getString(DB.gu_pageset));
    }

    bRetVal = super.store(oConn);

    if (count>0) {
      Answer answr = (Answer) answers.get(0);
      DBTable answertbl = answr.getTable(oConn);
      DBColumn dt_modified_col = answertbl.getColumnByName(DB.dt_modified);
      DBColumn pg_answer_col = answertbl.getColumnByName(DB.pg_answer);
      int dt_modified_colpos = dt_modified_col.getPosition()-1;
      int pg_answer_colpos = pg_answer_col.getPosition()-1;
      LinkedList columns = answertbl.getColumns();
      DBSubset answerset = new DBSubset(DB.k_pageset_answers,
                                        answertbl.getColumnsStr(),
                                        null, count);
      answerset.ensureCapacity(answertbl.columnCount(), count);
      lastupdate = new Date();
      ListIterator coliter = columns.listIterator();
      int icol = 0;
      while (coliter.hasNext()) {
        DBColumn objcol = (DBColumn) coliter.next();
        for (int irow=0; irow<count; irow++) {
          answr = (Answer) answers.get(irow);
          answerset.setElementAt(answr.get(objcol.getName()), icol, irow);
          answerset.setElementAt(guid!=null ? guid : answr.getStringNull(DB.gu_datasheet,null), 0, irow);
          answerset.setElementAt(lastupdate, dt_modified_colpos, irow);
          answerset.setElementAt(new Integer(irow+1), pg_answer_colpos, irow);
        } // next
        icol++;
      } // wend
      try {
        answerset.store(oConn, Answer.class, true);
      } catch (IllegalAccessException neverthrown) {}
        catch (InstantiationException neverthrown) {}
    } // fi (answers>0)

    if (DebugFile.trace) {
      DebugFile.decIdent();
      DebugFile.writeln("End DataSheet.store() : " +  String.valueOf(bRetVal));
    }

    return bRetVal;
  } // store

  //----------------------------------------------------------------------------

  /**
   * Load DataSheet from the database into memory
   * @param oConn JDCConnection Open JDBC database connection
   * @param sDataSheetGuid GUID of DataSheet to be loaded
   * @param iPageNum Number of Page to be loaded.
   * @return Count of answers loaded
   * @throws SQLException
   */
  public int load(JDCConnection oConn, String sDataSheetGuid, int iPageNum)
    throws SQLException {

    if (DebugFile.trace) {
      DebugFile.writeln("Begin DataSheet.load([JDCConnection], gu_datasheet="+sDataSheetGuid+",pg_page="+String.valueOf(iPageNum)+")");
      DebugFile.incIdent();
    }

    if (super.load(oConn, new Object[]{sDataSheetGuid})) {
      guid = sDataSheetGuid;
      Answer answr = new Answer();
      DBTable answertbl = answr.getTable(oConn);
      String scols = answertbl.getColumnsStr();
      String[] acols = Gadgets.split(scols, ',');
      DBSubset answerset = new DBSubset(DB.k_pageset_answers, scols,
                                        DB.gu_datasheet+"=? AND " + DB.pg_page + "=? "+
                                        "ORDER BY "+DB.pg_answer, 50);
      final int cols = answertbl.columnCount();
      final int count = answerset.load(oConn, new Object[]{sDataSheetGuid,new Integer(iPageNum)});
      answers.clear();
      for (int a=0; a<count; a++) {
        answr = new Answer();
        for (int c=0; c<cols; c++)
          answr.put(acols[c], answerset.get(c,a));
        answers.add(answr);
      }
      if (DebugFile.trace) {
        DebugFile.decIdent();
        DebugFile.writeln("End DataSheet.load() : " + String.valueOf(count));
      }
      return count;
    }
    else {
      if (DebugFile.trace) {
        DebugFile.decIdent();
        DebugFile.writeln("End DataSheet.load() : not found");
      }
      return 0;
    }
  } // load

  //----------------------------------------------------------------------------

  /**
   * Load DataSheet from the database into memory
   * @param oConn JDCConnection Open JDBC database connection
   * @param sDataSheetGuid GUID of DataSheet to be loaded
   * @param sPageGuid GUID of Page to be loaded. If <b>null</b> all pages are loaded.
   * @return Count of answers loaded
   * @throws SQLException
   */
  public int load(JDCConnection oConn, String sDataSheetGuid, String sPageGuid)
    throws SQLException {

    if (DebugFile.trace) {
      DebugFile.writeln("Begin DataSheet.load([JDCConnection], gu_datasheet="+sDataSheetGuid+",gu_page="+sPageGuid+")");
      DebugFile.incIdent();
    }

    if (super.load(oConn, new Object[]{sDataSheetGuid})) {
      guid = sDataSheetGuid;
      Answer answr = new Answer();
      DBTable answertbl = answr.getTable(oConn);
      String scols = answertbl.getColumnsStr();
      String[] acols = Gadgets.split(scols, ',');
      DBSubset answerset;
      Object[] params;

      if (null==sPageGuid) {
        answerset = new DBSubset(DB.k_pageset_answers, scols,
                                 DB.gu_datasheet+"=? " +
                                 "ORDER BY "+DB.pg_page+","+DB.pg_answer, 50);
        params = new Object[]{sDataSheetGuid};
      }
      else {
        answerset = new DBSubset(DB.k_pageset_answers, scols,
                                 DB.gu_datasheet+"=? AND " + DB.gu_page + "=? "+
                                 "ORDER BY "+DB.pg_answer, 50);
        params = new Object[]{sDataSheetGuid, sPageGuid};
      }

      final int cols = answertbl.columnCount();
      final int count = answerset.load(oConn, params);
      answers.clear();
      for (int a=0; a<count; a++) {
        answr = new Answer();
        for (int c=0; c<cols; c++) answr.put(acols[c], answerset.get(c,a));
        answers.add(answr);
      } // next
      if (DebugFile.trace) {
        DebugFile.decIdent();
        DebugFile.writeln("End DataSheet.load() : " + String.valueOf(count));
      }
      return count;
    }
    else {
      if (DebugFile.trace) {
        DebugFile.decIdent();
        DebugFile.writeln("End DataSheet.load() : not found");
      }
      return 0;
    }
  } // load

  //----------------------------------------------------------------------------

  /**
   * <p>Overrides parent class load() method</p>
   * This method is equivalent to calling load(JDCConnection, PageSet GUID, null)
   * @param oConn Open JDBC database connection
   * @param PKVals Array which first element is the GUID of the DataSheet to be loaded
   * @return boolean <b>true</b> if DataSheet was found and loaded,
   * <b>false</b> if no DataSheet with such GUID was found at k_pageset_datasheets table.
   * @throws SQLException
   */
  public boolean load(JDCConnection oConn, Object[] PKVals) throws SQLException {
    DataSheet oTest = new DataSheet();
    oTest.put(DB.gu_datasheet, PKVals[0]);
    boolean bExists = oTest.exists(oConn);
    if (bExists) load (oConn, (String) PKVals[0], null);
    return bExists;
  } // load

  //----------------------------------------------------------------------------

  /**
   * Get number of answers loaded in this DataSheet
   * @return Answers count
   */
  public int countAnswers() {
    return answers.size();
  }

  //----------------------------------------------------------------------------

  /**
   *
   * @param iIndex Index of Answer to be retrieved [0..countAnswers()-1]
   * @return Answer Object reference
   * @throws ArrayIndexOutOfBoundsException
   */
  public Answer getAnswer(int iIndex) throws ArrayIndexOutOfBoundsException {
    return (Answer) answers.get(iIndex);
  } // getAnswer

  //----------------------------------------------------------------------------

  /**
   * Retrieve the index of an Answer given its name
   * @param sName Answer name
   * @return Position of Answer at the internal ArrayList,
   * or -1 if no answer with such name was found.
   * Returned index may be different from k_pageset_answers.pg_answer database field value.
   */
  public int getAnswerIndex(String sName) {
    if (DebugFile.trace) {
      DebugFile.writeln("Begin DataSheet.getAnswerIndex("+sName+")");
      DebugFile.incIdent();
    }

    int iRetVal = -1;
    final int count = answers.size();

    if (DebugFile.trace) DebugFile.writeln(String.valueOf(count)+ " answers on this DataSheet");

    if (null!=sName) {
      for (int a=0; a<count; a++) {
        if (sName.equals(((Answer) answers.get(a)).getName())) {
          iRetVal = a;
          break;
        } // fi
      } // next (a)
    } // fi (sName)

    if (DebugFile.trace) {
      if (-1==iRetVal) {
        StringBuffer oNames = new StringBuffer(); oNames.append("{");
        for (int n=0; n<count; n++) oNames.append(((Answer) answers.get(n)).getName()+(n==count-1 ? "}" : ","));
        DebugFile.writeln(oNames.toString());
      }
      DebugFile.decIdent();
      DebugFile.writeln("End DataSheet.getAnswerIndex() : " + String.valueOf(iRetVal));
    }

    return iRetVal;
  } // getAnswerIndex

  //----------------------------------------------------------------------------

  /**
   * <p>Set value for an Answer at a given index of the internal ArrayList</p>
   * The Answer is sought by name. If no Answer with the same name as answr is
   * found then a new Answer is added to the end of the answers ArrayList.
   * @param answr Answer to be modified or added
   * @return Index at which the Answer was added
   * @throws NullPointerException If answr.getName() is <b>null</b>
   * @throws IllegalArgumentException If answr DataSheet GUID does not match this DataSheet GUID.
   */
  public int setAnswer(Answer answr)
    throws NullPointerException, IllegalArgumentException {

    if (DebugFile.trace) {
      DebugFile.writeln("Begin DataSheet.setAnswer("+answr.getName()+")");
      if (null==answr.getName())
        throw new NullPointerException("Answer name may not be null");
      String sAnswrGuid = answr.getStringNull(DB.gu_datasheet, null);
      if (guid!=null && sAnswrGuid!=null) {
        if (!guid.equals(sAnswrGuid))
          throw new IllegalArgumentException("Answer DataSheet GUID ("+sAnswrGuid+") does not match this DataSheet GUID ("+guid+")");
      }
      DebugFile.incIdent();
    }
    int iPrevious = getAnswerIndex(answr.getName());
    if (-1==iPrevious) {
      answers.add(answr);
      iPrevious=answers.size()-1;
    }
    else {
      getAnswer(iPrevious).setValue(answr.getValue());
    }
    if (DebugFile.trace) {
      DebugFile.decIdent();
      DebugFile.writeln("End DataSheet.setAnswer() : " + String.valueOf(iPrevious));
    }
    return iPrevious;
  } // setAnswer

  //----------------------------------------------------------------------------

  /**
   * Add a new Answer to this DataSheet
   * @param answr Answer to be added
   * @throws NullPointerException If answr.getName() is <b>null</b>
   * @throws IllegalArgumentException If another Answer with the same name as
   * answr already exists at this DataSheet, or if answr DataSheet GUID does not
   * match this DataSheet GUID.
   */
  public void addAnswer(Answer answr) throws IllegalArgumentException {
    if (DebugFile.trace) {
      DebugFile.writeln("Begin DataSheet.addAnswer("+answr.getName()+")");
      if (null==answr.getName())
        throw new NullPointerException("Answer name may not be null");
      if (getAnswerIndex(answr.getName())!=-1) {
        throw new IllegalArgumentException("Answer "+answr.getName()+" already exists at DataSheet");
      }
      String sAnswrGuid = answr.getStringNull(DB.gu_datasheet, null);
      if (guid!=null && sAnswrGuid!=null) {
        if (!guid.equals(sAnswrGuid))
          throw new IllegalArgumentException("Answer DataSheet GUID ("+sAnswrGuid+") does not match this DataSheet GUID ("+guid+")");
      }
      DebugFile.incIdent();
    }

    answers.add(answr);

    if (DebugFile.trace) {
      DebugFile.decIdent();
      DebugFile.writeln("End DataSheet.addAnswer()");
    }
  } // setAnswer

  //----------------------------------------------------------------------------

} // DataSheet

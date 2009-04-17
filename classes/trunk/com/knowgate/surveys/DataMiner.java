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

import java.io.IOException;
import java.io.FileNotFoundException;
import java.io.UnsupportedEncodingException;

import java.util.Map;
import java.util.HashMap;
import java.util.Iterator;
import java.util.TreeMap;

import java.sql.SQLException;

import org.jibx.runtime.JiBXException;

import com.knowgate.jdc.JDCConnection;
import com.knowgate.debug.DebugFile;
import com.knowgate.dataobjs.DB;
import com.knowgate.dataobjs.DBSubset;
import com.knowgate.misc.Gadgets;

/**
 * <p>Data Minning routines for Surveys</p>
 * This is an experimental module, not yet ready for production purposes.
 * @author Sergio Montoro Ten
 * @version 0.1
 */
public class DataMiner {

  // ---------------------------------------------------------------------------

  public DataMiner() { }

  // ---------------------------------------------------------------------------

  public static String getAnswerResults(JDCConnection oConn, String sGuPageSet,
                                        String sStorage, String sEnc,
                                        String sNmQuestion,
                                        int iResultsType, int iOutputType)
    throws UnsupportedEncodingException,FileNotFoundException,IOException,
           SQLException,JiBXException,IllegalArgumentException,
           ArrayIndexOutOfBoundsException,OutOfMemoryError {

    if (DebugFile.trace) {
      DebugFile.writeln("Begin DataMiner.getAnswerResults([JDCConnection],"+
                        sGuPageSet+","+sStorage+","+sEnc+","+sNmQuestion+","+
                        (RESULTS_ABSOLUTE==iResultsType ? "RESULTS_ABSOLUTE" :
                        (RESULTS_PERCENTAGE==iResultsType ? "RESULTS_PERCENTAGE" :
                        String.valueOf(iResultsType)))+
                        (OUTPUT_CSV==iOutputType ? "OUTPUT_CSV" :
                        (OUTPUT_XML==iOutputType ? "OUTPUT_XML" :
                        (OUTPUT_TSV==iOutputType ? "OUTPUT_TSV" :
                         String.valueOf(iOutputType))))+")");
      DebugFile.incIdent();
    }

    if (null==sEnc) sEnc="UTF-8";

    // Retrive full set of answers into memory
    DBSubset oAnswers = new DBSubset(DB.k_pageset_answers,
                                     DB.gu_page+","+DB.tx_answer,
                                     DB.gu_pageset+"=? AND "+DB.nm_answer+"=?",
                                     2000);
    int iAnswers = oAnswers.load(oConn, new Object[]{sGuPageSet,sNmQuestion});
    if (DebugFile.trace) DebugFile.writeln(String.valueOf(iAnswers) + " answers found");
    String sRetVal;

    if (0==iAnswers) {
      // If there are no answers the return null
      sRetVal = null;
    }
    else {
      // Get Survey object for this PageSet
      Survey oSrvy = new Survey(oConn, sGuPageSet);
      // Get Page for requested Answer
      SurveyPage oPage = oSrvy.getPage(oConn, oAnswers.getString(0,0), sStorage, sEnc);
      // Get Question object description for Answer
      Question oQuest = oPage.getQuestion(sNmQuestion);
      // Grids for storing results while iterating and before printing
      String[][] oGrid;
      float[][] fGrid;
      int iRows=0, iCols=0;
      // A Map for storing the vertical positition of each value on the titles
      Map oValueMap;
      // Intermediate variables holding vertical position for value while iterating answers
      Integer oValuePos;
      int[] oValueXY;
      String sValue;
      String[] aValues;
      Iterator oValues;

      switch (oQuest.getClassId()) {

        // *********************************************************************
        // Process TEXT and MULTITEXT type answers

        case Question.SubTypes.TEXT:
        case Question.SubTypes.MULTITEXT:
        case Question.SubTypes.LICKERT:
          oValueMap = new TreeMap();
          if (oQuest.getClassId()==Question.SubTypes.TEXT) {
            if (DebugFile.trace) {
              DebugFile.writeln("Question type is TEXT");
              DebugFile.writeln("reading "+String.valueOf(iAnswers)+" answers");
            }
            for (int a = 0; a < iAnswers; a++) {
              sValue = oAnswers.getStringNull(1, a, "");
              if (sValue.length() > 0) {
                sValue = Gadgets.ASCIIEncode(sValue);
                if (oValueMap.containsKey(sValue)) {
                  oValuePos = (Integer) oValueMap.get(sValue);
                  oValueMap.remove(sValue);
                  oValueMap.put(sValue, new Integer(oValuePos.intValue() + 1));
                } else {
                  oValueMap.put(sValue, new Integer(1));
                }
              } // fi (sValue.length()>0)
            } // next
          } else if (oQuest.getClassId()==Question.SubTypes.MULTITEXT) {
            if (DebugFile.trace) {
              DebugFile.writeln("Question type is MULTITEXT");
              DebugFile.writeln("reading "+String.valueOf(iAnswers)+" answers");
            }
            for (int a = 0; a < iAnswers; a++) {
              sValue = oAnswers.getStringNull(1, a, "");
              if (sValue.length() > 0) {
                aValues = Gadgets.split(sValue, ';');
                for (int v=0; v<aValues.length; v++) {
                  sValue = Gadgets.ASCIIEncode(aValues[v]);
                  if (oValueMap.containsKey(sValue)) {
                    oValuePos = (Integer) oValueMap.get(sValue);
                    oValueMap.remove(sValue);
                    oValueMap.put(sValue, new Integer(oValuePos.intValue() + 1));
                  } else {
                  oValueMap.put(sValue, new Integer(1));
                  }
                } // next (v)
              } // fi (sValue.length()>0)
            } // next
          } else if (oQuest.getClassId()==Question.SubTypes.LICKERT) {
            if (DebugFile.trace) {
              DebugFile.writeln("Question type is LICKERT");
              DebugFile.writeln("reading "+String.valueOf(iAnswers)+" answers");
            }
            for (int a = 0; a < iAnswers; a++) {
              sValue = oAnswers.getStringNull(1, a, "");
              if (sValue.length() > 0) {
                if (oValueMap.containsKey(sValue)) {
                  oValuePos = (Integer) oValueMap.get(sValue);
                  oValueMap.remove(sValue);
                  oValueMap.put(sValue, new Integer(oValuePos.intValue() + 1));
                } else {
                  oValueMap.put(sValue, new Integer(1));
                }
              } // fi (sValue.length()>0)
            } // next
          }

          if (DebugFile.trace) DebugFile.writeln("writting words frecuency");
          oGrid = new String[2][oValueMap.size()+1];
          oGrid[0][0] = oQuest.getCaption();
          oGrid[1][0] = "";
          oValues = oValueMap.keySet().iterator();
          int iValueIndex = 1;
          while (oValues.hasNext()) {
            sValue = (String) oValues.next();
            oGrid[0][iValueIndex] = sValue;
            oGrid[1][iValueIndex] = ((Integer)oValueMap.get(sValue)).toString();
            iValueIndex++;
          } // wend
          break;

        // *********************************************************************
        // Process CHOICE and MULTICHOICE type answers

        case Question.SubTypes.CHOICE:
        case Question.SubTypes.MULTICHOICE:
        case Question.SubTypes.LISTCHOICE:
          if (DebugFile.trace) DebugFile.writeln("Question type is CHOICE");
          // Cast Question to Choice
          Choice oChoice = (Choice) oQuest;
          // Get count of distinct choice elements
          iRows = oChoice.getChoiceElementCount();
          iCols = 2;
          if (DebugFile.trace) DebugFile.writeln(String.valueOf(iRows) + " distinct choices");
          // Create map for holding the vertical position of each value on the grid
          oValueMap = new HashMap(iRows*2);
          oGrid = new String[3][iRows+1];
          fGrid = new float[2][iRows+1];
          // Fill the lefmost column of the grid with choice captions,
          // initialize map with value vertical positions and set all numeric
          // total to zero.
          for (int c=0; c<iRows; c++) {
            oValueMap.put(oChoice.getChoiceElement(c).value, new Integer(c));
            oGrid[0][c] = oChoice.getChoiceElement(c).getCaptionAlt();
            fGrid[0][c] = 0f;
          } // next
          // Print allowed values debug trace
          if (DebugFile.trace) {
            Iterator oKeySet = oValueMap.keySet().iterator();
            StringBuffer oValsBuff = new StringBuffer();
            oValsBuff.append("value set {");
            if (oKeySet.hasNext()) oValsBuff.append((String) oKeySet.next());
            while (oKeySet.hasNext()) oValsBuff.append("," + (String) oKeySet.next());
            oValsBuff.append("}");
            DebugFile.writeln(oValsBuff.toString());
            oValsBuff=null;
            oKeySet=null;
          }
          // Fill the last row for total
          oGrid[0][iRows] = "Total"; // Title
          fGrid[0][iRows] = 0f; // Total count
          fGrid[1][iRows] = 1f; // Percentage
          // Read all pre-fetched answers and compute totals
          if (oQuest.getClassId()==Question.SubTypes.CHOICE ||
              oQuest.getClassId()==Question.SubTypes.LISTCHOICE) {
            if (DebugFile.trace) DebugFile.writeln("Computing choice totals");
            for (int a=0; a<iAnswers; a++) {
              sValue = oAnswers.getStringNull(1,a,"");
              if (sValue.length()>0) {
                // Get vertical position of current value on the grid
                oValuePos = (Integer) oValueMap.get(sValue);
                if (null==oValuePos) {
                  // Raise exception if value readed from the database does not match
                  // with any value for choice elements
                  if (DebugFile.trace) {
                    DebugFile.writeln("Choices count is "+String.valueOf(oValueMap.size()));
                    DebugFile.writeln("Invalid value \"" + sValue + "\" for answer "
                                      + String.valueOf(a+1));
                    DebugFile.decIdent();
                  }
                  throw new SQLException("Invalid value \"" + sValue +
                                         "\" for answer " + String.valueOf(a+1),
                                         "23000", 23000);
                } else {
                  // Increment absolute count for this value and for total values
                  fGrid[0][oValuePos.intValue()] += 1;
                  fGrid[0][iRows] += 1;
                }
              } // fi (sValue!="")
            } // next (a)
          } else { // Question.SubTypes.MULTICHOICE
            if (DebugFile.trace) DebugFile.writeln("Computing multichoice totals");
            for (int a=0; a<iAnswers; a++) {
              sValue = oAnswers.getStringNull(1,a,"");
              if (sValue.length()>0) {
                String[] aChoiceValues = Gadgets.split(sValue,';');
                for (int v=0; v<aChoiceValues.length; v++) {
                  // Get vertical position of current value on the grid
                  if (aChoiceValues[v].length()>0) {
                    oValuePos = (Integer) oValueMap.get(aChoiceValues[v]);
                    if (null==oValuePos) {
                      // Raise exception if value readed from the database does not match
                      // with any value for choice elements
                      if (DebugFile.trace) DebugFile.decIdent();
                      throw new SQLException("Invalid value " +
                                             aChoiceValues[v] +
                                             " for answer " + String.valueOf(a+1) +
                                             " column " + String.valueOf(v+1),
                                             "23000", 23000);
                    } else {
                      // Increment absolute count for this value and for total values
                      fGrid[0][oValuePos.intValue()] += 1f;
                      fGrid[0][iRows] += 1f;
                    }
                  } // fi (aChoiceValues[v]!="")
                } // next (v)
              } // fi (sValue!="")
            } // next (a)
          }
          // Convert results to percentages
          if (DebugFile.trace) DebugFile.writeln("Converting results to percentages");
          float fTotalChoices = fGrid[0][iRows];
          for (int p=0; p<iRows; p++) {
            fGrid[1][p] = fGrid[0][p]/fTotalChoices;
          } // next
          if (DebugFile.trace) DebugFile.writeln("Casting percentages as text");
          for (int f=0; f<iRows; f++) {
            oGrid[1][f] = String.valueOf(fGrid[0][f]);
            oGrid[2][f] = String.valueOf(fGrid[1][f]);
          } // next f
          if (DebugFile.trace) DebugFile.writeln("Writting absolute and percentual total");
          oGrid[1][iRows] = String.valueOf(fGrid[0][iRows]);
          oGrid[2][iRows] = "1";
          iRows++;
          break;

        // *********************************************************************
        // Process MATRIX type answers

        case Question.SubTypes.MATRIX:
          if (DebugFile.trace) DebugFile.writeln("Question type is MATRIX");
          // Cast Question to Matrix
          Matrix oMtrx = (Matrix) oQuest;
          iRows = oMtrx.rowCount();
          iCols = oMtrx.columnCount();
          if (DebugFile.trace) DebugFile.writeln("rows="+String.valueOf(iRows)+" cols="+String.valueOf(iCols));
          // Create map for holding the vertical position of each value on the grid
          oValueMap = new HashMap((iRows*iCols*13)/10);
          oGrid = new String[iCols+1][iRows+2];
          fGrid = new float[iCols+1][iRows+2];

          if (oMtrx.uniquecolumns && oMtrx.uniquerows) {
            if (DebugFile.trace) DebugFile.writeln("Computing uniquecolumns && uniquerows totals");

            // *************
            // *** TO DO ***
            // *************

          }
          else if (oMtrx.uniquerows) {
            if (DebugFile.trace) DebugFile.writeln("Computing uniquerows totals");

            // Fill the top row of the grid with column captions
            for (int c=1; c<iCols; c++) {
              oGrid[c][0] = oMtrx.getCell(c,0).getCaptionAlt();
            } // next
            // Fill the lefmost column of the grid with row captions
            for (int r=0; r<iRows; r++) {
              oGrid[0][r] = oMtrx.getRow(r).getCaptionAlt();
            } // next
            oGrid[0][iRows] = "Total";

            // Initialize value maps, one map per row
            HashMap[] aRowMaps = new HashMap[iRows];
            for (int r=1; r<iRows; r++) {
              aRowMaps[r-1] = new HashMap(iCols*2);
              for (int c=0; c<iCols; c++) {
                fGrid[c][r] = 0f;
                aRowMaps[r-1].put(oMtrx.getCell(c,r).getValue(), new int[]{c,r});
              } // next (c)
              if (DebugFile.trace) {
                Iterator oRowSet = aRowMaps[r-1].keySet().iterator();
                StringBuffer oRowBuff = new StringBuffer();
                oRowBuff.append("value set for row "+String.valueOf(r)+" {");
                if (oRowSet.hasNext()) oRowBuff.append((String) oRowSet.next());
                while (oRowSet.hasNext()) oRowBuff.append("," + (String) oRowSet.next());
                oRowBuff.append("}");
                DebugFile.writeln(oRowBuff.toString());
                oRowBuff=null;
                oRowSet=null;
              } // fi (DegugFile.trace)
            } // next (r)
            if (DebugFile.trace)  DebugFile.writeln("Row maps successfully initialized");

            // Read all pre-fetched answers and compute totals
            for (int a=0; a<iAnswers; a++) {
              sValue = oAnswers.getStringNull(1,a,"");
              if (sValue.length()>0) {
                String[] aRowValues = Gadgets.split(sValue,'|');
                if (DebugFile.trace) {
                  if (aRowValues.length<iRows) {
                    DebugFile.writeln("Matrix row count ("+String.valueOf(iRows)+") is not equal to number of values ("+String.valueOf(aRowValues.length)+")");
                    DebugFile.decIdent();
                  throw new ArrayIndexOutOfBoundsException("Matrix row count ("+String.valueOf(iRows)+") is not equal to number of values ("+String.valueOf(aRowValues.length)+")");
                  }
                }
                for (int w=0; w<aRowValues.length; w++) {
                  // If value for this cell is not empty then find corresponding
                  // position in results grid.
                  if (aRowValues[w].length()>0) {
                    oValueXY = (int[]) aRowMaps[w].get(aRowValues[w]);
                    if (null==oValueXY) {
                      // Raise exception if value readed from the database does
                      // not match any value for cell elements.
                      if (DebugFile.trace) DebugFile.decIdent();
                      throw new SQLException("Invalid value " +
                                             aRowValues[w] +
                                             " for answer " + String.valueOf(a+1) +
                                             " row " + String.valueOf(w+1),
                                             "23000", 23000);
                    } else {
                      fGrid[oValueXY[0]][oValueXY[1]] += 1f;
                      fGrid[oValueXY[0]][iRows] += 1f;
                    }
                  } // fi (aRowValues[w]!="")
                } // next (w)
              } // fi (sValue!="")
            } // next (a)
            if (DebugFile.trace) DebugFile.writeln("Done filling the grid");
          }
          else if (oMtrx.uniquecolumns) {
            if (DebugFile.trace) DebugFile.writeln("Computing uniquecolumns totals");

            // Fill the top row of the grid with column captions
            for (int c=1; c<iCols; c++) {
              oGrid[c][0] = oMtrx.getCell(c,0).getCaptionAlt();
            } // next
            for (int r=0; r<iRows; r++) {
              oGrid[0][r] = oMtrx.getRow(r).getCaptionAlt();
            } // next
            oGrid[0][iRows] = "Total";

            // Initialize value maps, one map per column
            HashMap[] aColMaps = new HashMap[iCols];
            for (int c=0; c<iCols; c++) {
              aColMaps[c] = new HashMap(iRows*2);
              for (int r=0; r<iRows; r++) {
                fGrid[c][r] = 0f;
                aColMaps[c].put(oMtrx.getCell(c,r).getValue(), new int[]{c,r});
              } // next (c)
            } // next (r)
            if (DebugFile.trace)  DebugFile.writeln("Column maps successfully initialized");

            // Read all pre-fetched answers and compute totals
            for (int a=0; a<iAnswers; a++) {
              sValue = oAnswers.getStringNull(1,a,"");
              if (sValue.length()>0) {
                String[] aColValues = Gadgets.split(sValue,'|');

                for (int l=0; l<aColValues.length; l++) {
                  // If value for this cell is not empty then find corresponding
                  // position in results grid.
                  if (aColValues[l].length()>0) {
                    oValueXY = (int[]) aColMaps[l].get(aColValues[l]);
                    if (null==oValueXY) {
                      // Raise exception if value readed from the database does
                      // not match any value for cell elements.
                      if (DebugFile.trace) DebugFile.decIdent();
                      throw new SQLException("Invalid value " +
                                             aColValues[l] +
                                             " for answer " + String.valueOf(a+1) +
                                             " column " + String.valueOf(l+1),
                                             "23000", 23000);
                    } else {
                      fGrid[oValueXY[0]][oValueXY[1]] += 1f;
                      fGrid[oValueXY[0]][iRows] += 1f;
                    }
                  } // fi (aColValues[l]!="")
                } // next (l)
              } // fi (sValue!="")
            } // next (a)
            if (DebugFile.trace) DebugFile.writeln("Done filling the grid");
          }
          else {
            if (DebugFile.trace) DebugFile.writeln("Computing multirows & multicolumns totals");

            // Fill the top row of the grid with column captions
            for (int c=0; c<iCols; c++) {
              oGrid[c+1][0] = oMtrx.getCell(c,0).getCaptionAlt();
            } // next
            for (int r=0; r<iRows; r++) {
              oGrid[0][r] = oMtrx.getRow(r).getCaptionAlt();
            } // next
            oGrid[0][iRows] = "Total";

            // Initialize counter to zero
            for (int c=0; c<iCols; c++) for (int r=0; r<iRows; r++) fGrid[c][r] = 0f;

            for (int a=0; a<iAnswers; a++) {
              sValue = oAnswers.getStringNull(1, a, "");
              if (sValue.length() > 0) {
                String[] aRowValues = Gadgets.split(sValue, '|');
                int iRowVals = aRowValues.length;
                for (int r=0; r<iRowVals; r++) {
                  String[] aColvalues = Gadgets.split(aRowValues[r],';');
                  int iColVals = aColvalues.length;
                  for (int c=0; c<iColVals; c++) {
                    if (aColvalues[c].length()>0) {
                      fGrid[c+1][r+1] += 1f;
                      fGrid[c+1][iRows+1] += 1f;
                    } // fi (aColvalues[c]!="")
                  } // next (c)
                } // next (r)
              } // fi (sValue!="")
            } // next (answer)

          } // fi (oMtrx.uniquerows || oMtrx.uniquecolumns)

          // ******************************
          // Convert results to percentages
          if (RESULTS_PERCENTAGE==iResultsType) {
            if (DebugFile.trace) DebugFile.writeln("Converting results to percentages");
            for (int y=1; y<=iRows; y++) {
              for (int x=1; x<iCols; x++) {
                fGrid[x][y] *= 100f;
                fGrid[x][y] /= fGrid[x][iRows];
                oGrid[x][y] = String.valueOf(fGrid[x][y])+"%";
              } // next (x)
            } // next (y)
          } else {
            for (int y=1; y<=iRows; y++) {
              for (int x=1; x<iCols; x++) {
                oGrid[x][y] = String.valueOf(fGrid[x][y]);
              } // next (x)
            } // next (y)
          } // fi (RESULTS_PERCENTAGE)
          break;

        // *********************************************************************
        // Process HOTORNOT type answers

        case Question.SubTypes.HOTORNOT:
          if (DebugFile.trace) DebugFile.writeln("Question type is HOTORNOT");
          // Determine number of columns by looking at minimum and maximum values
          // for all lickerts on the HotOrNot question
          HotOrNot oHot = (HotOrNot) oQuest;
          float fMin = 100, fMax=-100;
          iRows = oHot.getLickertCount();
          for (int l=0; l<iRows; l++) {
            if (oHot.getLickert(l).leftTag()<fMin)
              fMin = oHot.getLickert(l).leftTag();
            if (oHot.getLickert(l).rightTag()>fMax)
              fMax = oHot.getLickert(l).rightTag();
          } // next (l)
          iRows++;
          iCols = (int) ((fMax-fMin)+2);
          // Allocate grid space
          oGrid = new String[iCols][iRows];
          fGrid = new float[iCols][iRows];
          // Initialize absolute frecuencies grid to zero
          for (int r=0; r<iRows; r++) {
            for (int c=0; c<iCols; c++) {
              if (0==r && c>0) oGrid[c][0]=String.valueOf((int)(fMin+c-1));
              if (0==c && r>0 && r<iRows-1) {
                if (oHot.getLickert(r-1).getCaption()!=null)
                  oGrid[0][r]=oHot.getLickert(r-1).getCaption();
                else
                  oGrid[0][r]=oHot.getLickert(r-1).leftcapt+" - "+oHot.getLickert(r-1).rightcapt;
              }
              fGrid[c][r]=0f;
            }
          }
          // Iterate answers
          for (int a=0; a<iAnswers; a++) {
            sValue = oAnswers.getStringNull(1,a,"");
            if (sValue.length()>0) {
              aValues = Gadgets.split(sValue, '|');
              for (int v=0; v<aValues.length; v++) {
                if (aValues[v].length()>0) {
                  fGrid[Integer.parseInt(aValues[v])-((int)fMin)+1][v+1]+=1f;
                }
              } // next (v)
            } // fi (sValue!="")
          } // next (a)
          for (int r=1; r<iRows; r++) {
            for (int c=1; c<iCols; c++) {
              oGrid[c][r]=String.valueOf((int) fGrid[c][r]);
            }
          }
          break;

        // *********************************************************************
        // Raise error if answer type is not recognized

        default:
          if (DebugFile.trace) {
            DebugFile.writeln("Unrecognized type "+String.valueOf(oQuest.getClassId())+" for question "+sNmQuestion);
            DebugFile.decIdent();
          }
          throw new IllegalArgumentException("Unrecognized type "+String.valueOf(oQuest.getClassId())+" for question "+sNmQuestion);
      }  // end switch

      // ***********************************************************************
      // Print results grid to a StringBuffer

      if (DebugFile.trace) DebugFile.writeln("Printing results grid to StringBuffer");
      StringBuffer oBuffer = new StringBuffer();
      if ((OUTPUT_CSV==iOutputType) || (OUTPUT_TSV==iOutputType )) {
        char cDelimiter = (OUTPUT_CSV==iOutputType ? ';' : '\t');
        final int iGridCols=oGrid.length;
        final int iGridRows=oGrid[0].length;
        for (int n=0; n<iGridRows; n++) {
          if (oGrid[0][n]!=null)
            oBuffer.append(oGrid[0][n]);
          for (int m=1; m<iGridCols; m++) {
            oBuffer.append(cDelimiter);
            if (oGrid[m][n]!=null) oBuffer.append(oGrid[m][n]);
          } // next
          oBuffer.append('\n');
        } // next
      } // fi
      sRetVal = oBuffer.toString();
    }

    // Done!

    if (DebugFile.trace) {
      DebugFile.writeln("End DataMiner.getAnswerResults()");
      DebugFile.decIdent();
    }
    return sRetVal;
  } // getAnswerResults

  // ---------------------------------------------------------------------------

  public static String getAnswerCross(JDCConnection oConn, String sGuPageSet,
                                      String sStorage, String sEnc,
                                      String sNmQuestion, String sNmCross,
                                      int iResultsType, int iOutputType)
    throws UnsupportedEncodingException,FileNotFoundException,IOException,
           SQLException,JiBXException,IllegalArgumentException,
           ArrayIndexOutOfBoundsException,OutOfMemoryError {

      if (DebugFile.trace) {
           DebugFile.writeln("Begin DataMiner.getAnswerCross([JDCConnection],"+
                             sGuPageSet+","+sStorage+","+sEnc+","+sNmQuestion+","+
                             sNmCross+","+
                             (RESULTS_ABSOLUTE==iResultsType ? "RESULTS_ABSOLUTE" :
                             (RESULTS_PERCENTAGE==iResultsType ? "RESULTS_PERCENTAGE" :
                             String.valueOf(iResultsType)))+
                             (OUTPUT_CSV==iOutputType ? "OUTPUT_CSV" :
                             (OUTPUT_XML==iOutputType ? "OUTPUT_XML" :
                             (OUTPUT_TSV==iOutputType ? "OUTPUT_TSV" :
                              String.valueOf(iOutputType))))+")");
           DebugFile.incIdent();
      }

      if (null==sEnc) sEnc="UTF-8";

      DBSubset oCross = new DBSubset(DB.k_pageset_datasheets,
                                     "DISTINCT("+sNmCross+")",
                                     DB.gu_pageset+"=? ORDER BY 1", 100);

      DBSubset oCrossVal = new DBSubset(DB.k_pageset_datasheets,
                                        sNmCross,
                                        DB.gu_datasheet+"=? ORDER BY 1", 100);

      // Retrive full set of answers into memory
      DBSubset oAnswers = new DBSubset(DB.k_pageset_answers,
                                       DB.gu_page+","+DB.tx_answer+","+DB.gu_datasheet,
                                       DB.gu_pageset+"=? AND "+DB.nm_answer+"=?",
                                       2000);
      int iAnswers = oAnswers.load(oConn, new Object[]{sGuPageSet,sNmQuestion});
      if (DebugFile.trace) DebugFile.writeln(String.valueOf(iAnswers) + " answers found");
      String sRetVal;

      if (0==iAnswers) {
        // If there are no answers the return null
        sRetVal = null;
      }
      else {
        int iCross = oCross.load(oConn, new Object[]{sGuPageSet});
        HashMap oCrossMap = new HashMap(iCross*2);
        for (int x=0; x<iCross; x++) {

        }

        // Get Survey object for this PageSet
        Survey oSrvy = new Survey(oConn, sGuPageSet);
        // Get Page for requested Answer
        SurveyPage oPage = oSrvy.getPage(oConn, oAnswers.getString(0, 0),
                                         sStorage, sEnc);
        // Get Question object description for Answer
        Question oQuest = oPage.getQuestion(sNmQuestion);
        // Grids for storing results while iterating and before printing
        String[][] oGrid;
        float[][] fGrid;
        int iRows = 0, iCols = 0;
        // A Map for storing the vertical positition of each value on the titles
        Map oValueMap;
        // Intermediate variables holding vertical position for value while iterating answers
        Integer oValuePos;
        int[] oValueXY;
        String sValue;
        String[] aValues;
        Iterator oValues;

        switch (oQuest.getClassId()) {

          // *********************************************************************
          // Process TEXT and MULTITEXT type answers

          case Question.SubTypes.CHOICE:
          case Question.SubTypes.LISTCHOICE:

        } // end switch
      } // fi
      return null;
    } // getAnswersCross

  // ---------------------------------------------------------------------------

  public static final int RESULTS_ABSOLUTE = 1;
  public static final int RESULTS_PERCENTAGE = 2;
  public static final int OUTPUT_XML = 4;
  public static final int OUTPUT_CSV = 8;
  public static final int OUTPUT_TSV = 16;
}

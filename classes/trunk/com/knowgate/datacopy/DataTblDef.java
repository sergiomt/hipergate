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


package com.knowgate.datacopy;

import com.knowgate.debug.DebugFile;

import java.sql.Connection;
import java.sql.DatabaseMetaData;
import java.sql.ResultSet;
import java.sql.ResultSetMetaData;
import java.sql.Statement;
import java.sql.SQLException;

/**
 * <p>Keeps information about each table definition.</p>
 * @author Sergio Montoro Ten
 * @version 0.5 alpha
 */

public class DataTblDef {

  public DataTblDef() { }

  // ----------------------------------------------------------

  private void alloc(int cCols) {
    // Nº total de columnas en la tabla
    ColCount = cCols;
    // Array con los nombres de las columnas
    ColNames = new String[cCols];
    // Array con los tipos SQL de las columnas
    ColTypes = new int[cCols];
    // Array con las longitudes de las columnas
    ColSizes = new int[cCols];
    // Para cada columna, tiene true si forma parte de la PK, false en caso contrario
    PrimaryKeyMarks = new boolean[cCols];
    // Inicializar todos los campos por defecto a No-PK
    for (int c=0;c<cCols;c++) PrimaryKeyMarks[c] = false;
  }

  // ----------------------------------------------------------

  /**
   * Read table metadata
   * @param oConn JDBC Connection
   * @param sTable Table Name (case insensitive)
   * @param sPK List of primary key columns delimited by commas
   * @throws SQLException
   */
  public void readMetaData(Connection oConn, String sTable, String sPK) throws SQLException {
    int lenPK;
    int iCurr;
    int cCols;
    Statement oStmt = null;
    ResultSet oRSet = null;
    ResultSetMetaData oMDat = null;

    if (DebugFile.trace) {
      DebugFile.writeln("Begin DataTblDef.readMetaData([Connection], \"" + sTable + "\",\"" + sPK + "\")");
      DebugFile.incIdent();
    }

    BaseTable = sTable;

    // **********************************
    // * Leer los valores de metadatos

    // Lanza una SELECT que no devuelve ningún registro y luego
    // hace una llamada a getMetaData para guardar en memoria
    // la definición de los campos leidos.
    // La clave primaria no se extrae de la SELECT sino que debe
    // pasarse externamente como parametro.

    try {
      oStmt = oConn.createStatement();

      if (DebugFile.trace) DebugFile.writeln ("Statement.executeQuery(SELECT * FROM " + sTable + " WHERE 1=0)");

      oRSet = oStmt.executeQuery("SELECT * FROM " + sTable + " WHERE 1=0");

      oMDat = oRSet.getMetaData();

      cCols = oMDat.getColumnCount();

      alloc(cCols); // Función interna de soporte

      for (int c=0; c<cCols; c++) {
        ColNames[c] = oMDat.getColumnName(c+1);
        ColTypes[c] = oMDat.getColumnType(c+1);
        ColSizes[c] = oMDat.getPrecision(c+1);

        if (DebugFile.trace) DebugFile.writeln(ColNames[c] + " SQLType " + String.valueOf(ColTypes[c]) + " precision "  + ColSizes[c]);
      }  // next (c)

      oMDat = null;
    }
    catch (SQLException sqle) {
      throw new SQLException (sqle.getMessage(), sqle.getSQLState(), sqle.getErrorCode());
    }
    finally {
      if (null!=oRSet) oRSet.close();
      if (null!=oStmt) oStmt.close();
    }

    // *********************************************************
    // * Almacenar los nombres de campos de la clave primaria

    if (null!=sPK) {
      lenPK = sPK.length()-1;

      cPKs = 1;
      // Cuenta el nº de comas que hay en la cadena de entrada
      for (int i=1; i<=lenPK; i++)
        if(sPK.charAt(i)==',') cPKs++;

      // El nº de campos es la cantidad de comas mas uno
      PrimaryKeys = new String[cPKs];

      // Parsea la cadena de entrada usando las coma como indicador de salto
      iCurr = 0;
      PrimaryKeys[0] = "";
      for (int j=0; j<=lenPK; j++)
        if (sPK.charAt(j)!=',') {
          PrimaryKeys[iCurr] += sPK.charAt(j);
        }
        else {
          if (DebugFile.trace) DebugFile.writeln("PrimaryKeys[" + String.valueOf(iCurr) + "]=" + PrimaryKeys[iCurr]);
          PrimaryKeys[++iCurr] = "";
        }

      if (DebugFile.trace) DebugFile.writeln("PrimaryKeys[" + String.valueOf(iCurr) + "]=" + PrimaryKeys[iCurr]);

      // Almacenar un indicador booleano para cada campo que forme parte de la PK

      for (int l=0; l<ColCount; l++) PrimaryKeyMarks[l] = false;

      for (int k=0; k<cPKs; k++) {
        for (int f=0;f<ColCount;f++) {
          PrimaryKeyMarks[f] |= PrimaryKeys[k].equalsIgnoreCase(ColNames[f]);
        } // next (f)
      }  // next (k)
    } // end if (null!=sPK)
    else {
      cPKs = 0;
      PrimaryKeys = null;
      }

      if (DebugFile.trace) {
        DebugFile.decIdent();
        DebugFile.writeln("End DataTblDef.readMetaData()");
      }

  } // readMetaData ()

  // ---------------------------------------------------------------------------

  /**
   * Get table primary key
   * @param oConn JDBC Connection
   * @param sSchema String Schema name
   * @param sCatalog String Catalog Name
   * @param sTable String Table Name (case sensitive)
   * @return String List of table primary key columns delimited by commas, if table does not have a
   * primary key then return value is <b>null</b>
   * @throws SQLException
   */
  public String getPrimaryKeys (Connection oConn, String sSchema, String sCatalog, String sTable)
    throws SQLException {

    String sPKCols = null;
    DatabaseMetaData oMDat = oConn.getMetaData();
    ResultSet oRSet = oMDat.getPrimaryKeys(sCatalog, sSchema, sTable);

    while (oRSet.next()) {
      if (null==sPKCols)
        sPKCols = oRSet.getString(4);
      else
        sPKCols += "," + oRSet.getString(4);

    } // wend

    oRSet.close();

    return sPKCols;
  }

  // ----------------------------------------------------------

  public int findColumnPosition(String sColName) {
    // Busca la posición de una columna por nombre
    // Devuelve -1 si no la encuentra

    int iCol = -1;

    for (int c=0; (c<ColCount) && (iCol==-1); c++)
      if(sColName.equalsIgnoreCase(ColNames[c]))
        iCol = c;

    return iCol;
  } // findColumnPosition

  // ----------------------------------------------------------

  public int findColumnType(String sColName)  {
    // Busca el tipo de una columna por nombre
    // Devuelve 0 si no la encuentra

    int iType = 0;

    for (int c=0; c<ColCount; c++)
      if(sColName.equalsIgnoreCase(ColNames[c])) {
        iType = ColTypes[c];
        break;
      }
    return iType;
  } // findColumnType

  // ----------------------------------------------------------

  public boolean inheritsPK(DataTblDef oTblDef)
    throws ArrayIndexOutOfBoundsException {

    if (DebugFile.trace) {
      DebugFile.writeln("Begin " + BaseTable + " DataTblDef.inheritsPK(" + oTblDef.BaseTable + ")");
      DebugFile.incIdent();
      DebugFile.writeln(BaseTable + " has " + String.valueOf(cPKs) +" pk columns");
    }

    // Comprueba si dos DataTblDef tienen la misma estructura de tipos
    // y longitudes en sus campos de la PK y, por consiguiente, con
    // gran probabilidad un DataTblDef hereda la PK del otro.
    boolean bSamePK;
    int pc, fc;

    int iMatchCount = 0;

    if (DebugFile.trace)
      if (cPKs<oTblDef.cPKs)
        DebugFile.writeln(BaseTable + " does not inherit PK from " + oTblDef.BaseTable + " because " + oTblDef.BaseTable + " has " + String.valueOf(oTblDef.cPKs) + " PK columns and " + BaseTable + " has only " + String.valueOf(cPKs) + " PK columns");

    bSamePK = (cPKs>=oTblDef.cPKs);

    if (bSamePK) {

      for (int fk=0; fk<cPKs; fk++) {

        if (DebugFile.trace) DebugFile.writeln("fk=" + String.valueOf(fk));

        fc = findColumnPosition(PrimaryKeys[fk]);

        if (DebugFile.trace && -1==fc) DebugFile.writeln("cannot find column " + PrimaryKeys[fk] + " on " + BaseTable);

        if (-1!=fc) {

          for (int pk=0; pk<oTblDef.cPKs; pk++) {

            if (DebugFile.trace) DebugFile.writeln("pk=" + String.valueOf(pk));

            pc = oTblDef.findColumnPosition(oTblDef.PrimaryKeys[pk]);

            if (DebugFile.trace && -1==pc) DebugFile.writeln("cannot find column " + oTblDef.PrimaryKeys[pk] + " on " + oTblDef.BaseTable);

            if (-1!=pc) {

              if (DebugFile.trace)
                DebugFile.writeln("trying " + BaseTable + "." + ColNames[fc] + " and " + oTblDef.BaseTable + "." + oTblDef.ColNames[pc]);

              if ((oTblDef.ColTypes[pc]==ColTypes[fc] && oTblDef.ColSizes[pc]==ColSizes[fc]) &&
                 ((cPKs==1 && oTblDef.ColNames[pc].equalsIgnoreCase(ColNames[fc])) || (cPKs>1))) {

                if (DebugFile.trace) {
                  if (cPKs>1)
                    DebugFile.writeln(BaseTable + "." + PrimaryKeys[fk] + " matches " + oTblDef.BaseTable + "." + oTblDef.PrimaryKeys[pk]);
                  else
                    DebugFile.writeln(BaseTable + "." + PrimaryKeys[fk] + " matches same column on " + oTblDef.BaseTable + "." + oTblDef.PrimaryKeys[pk]);
                }

                iMatchCount++;
                break;
              }
              else {
                if (DebugFile.trace) {
                  if (oTblDef.ColTypes[pc]!=ColTypes[fc])
                    DebugFile.writeln(BaseTable + "." + PrimaryKeys[fk] + " has SQLType " + ColTypes[fc] + " and " + oTblDef.BaseTable + "." + oTblDef.PrimaryKeys[pk] + " has SQLType " + oTblDef.ColTypes[pc]);
                  else if (oTblDef.ColSizes[pc]==ColSizes[fc])
                    DebugFile.writeln(BaseTable + "." + PrimaryKeys[fk] + " has size " + ColSizes[fc] + " and " + oTblDef.BaseTable + "." + oTblDef.PrimaryKeys[pk] + " has size " + oTblDef.ColSizes[pc]);
                  else if (cPKs==1 && !oTblDef.ColNames[pc].equalsIgnoreCase(ColNames[fc]))
                    DebugFile.writeln(BaseTable + "." + PrimaryKeys[fk] + " as same SQLType and size as " + oTblDef.BaseTable + "." + oTblDef.PrimaryKeys[pk] + " but it is not considered match because " + PrimaryKeys[fk] + " is a single primary key column and they don't have the same name");
                }
              }
            } // fi (-1!=pc)
          } // next (pk)
          if (iMatchCount==oTblDef.cPKs) break;

        } // fi (-1!=fc)
      } // next (fk)
    }

    if (DebugFile.trace) DebugFile.writeln("match count = " + String.valueOf(iMatchCount) + " , primary keys =" + String.valueOf(oTblDef.cPKs));

    if (iMatchCount<oTblDef.cPKs) bSamePK = false;

    if (DebugFile.trace) {
      DebugFile.decIdent();
      DebugFile.writeln("End DataTblDef.inheritsPK() : " + String.valueOf(bSamePK));
    }

    return bSamePK;
  } // inheritsPK

  // ----------------------------------------------------------

  public boolean bestMatch(int iThisCol, DataTblDef oTblDef, int iParentPK) {
    int[] aScores = new int[cPKs];
    int iPKPos;
    int iParentCol;
    int iPKRelativePos = 0;
    int iBestMatch = -1;
    int iBestScore = -1;

    if (DebugFile.trace) {
      DebugFile.writeln("Begin DataTblDef.bestMatch(" + BaseTable + "." + ColNames[iThisCol] + " , " + oTblDef.BaseTable + "." + oTblDef.PrimaryKeys[iParentPK] + ")");
      DebugFile.incIdent();
    }

    iParentCol = oTblDef.findColumnPosition(oTblDef.PrimaryKeys[iParentPK]);

    // Find seeked field relative position inside primary key
    for (int c=0; c<this.ColCount & iPKRelativePos<cPKs; c++)
      if (PrimaryKeyMarks[c] && !ColNames[c].equalsIgnoreCase(ColNames[iThisCol]))
        iPKRelativePos++;
      else if (PrimaryKeyMarks[c] && ColNames[c].equalsIgnoreCase(ColNames[iThisCol]))
        break;

    // For each key field, assign a score
    for (int k=0; k<cPKs; k++) {
      aScores[k] = 0;

      if (PrimaryKeys[k].equalsIgnoreCase(oTblDef.ColNames[iParentCol]))
        aScores[k] += 5; // Add 5 points if names match

      iPKPos = findColumnPosition(PrimaryKeys[k]);

      if (iPKPos>-1)
        if (ColTypes[iPKPos]==oTblDef.ColTypes[iParentCol] &&
            ColSizes[iPKPos]==oTblDef.ColSizes[iParentCol])
          aScores[k] += 1; // Add 1 point if types and sizes match
    } // next

    // Check if seeked field has the highest score
    for (int k=0; k<cPKs; k++) {
      if (aScores[k]>iBestScore) {
        iBestScore = aScores[k];
        iBestMatch = k;
      } // fi
    } // next

    if (DebugFile.trace) {
      DebugFile.writeln("pk relative position is " + String.valueOf(iPKRelativePos) + ", best match relative position is " + String.valueOf(iBestMatch));
      DebugFile.decIdent();
      DebugFile.writeln("End DataTblDef.bestMatch() : " + String.valueOf(iPKRelativePos==iBestMatch));
    }
    return (iPKRelativePos==iBestMatch);

  } // bestMatch

  // ----------------------------------------------------------

  public boolean isPrimaryKey(int iCol) {

    boolean bRetVal = PrimaryKeyMarks[iCol];

    return bRetVal;
  } // isPrimaryKey

  // ----------------------------------------------------------

  public boolean isPrimaryKey(String sCol) {
    boolean bRetVal;

    int iCol = findColumnPosition (sCol);

    if (-1==iCol)
      bRetVal = false;
    else
      bRetVal = PrimaryKeyMarks[iCol];

    return bRetVal;
  } // isPrimaryKey

  // *********************************************************
  // * Member Variables

  public int cPKs; // Nº total de campos en la PK
  public boolean bMayInheritPK;
  private boolean PrimaryKeyMarks[]; // Array con flags booleanos de PK / No-PK
  public String PrimaryKeys[]; // Nombre de los campos en la PK
  public String ColNames[]; // Nombres de todas las columnas (por orden de aparición)
  public int ColTypes[]; // Tipos de todas las columnas
  public int ColSizes[]; // Longitudes de todas las columnas
  public int ColCount; // Cuenta del nº total de columnas
  public String BaseTable;

  } // DataTblDef

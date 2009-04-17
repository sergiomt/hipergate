package com.knowgate.datacopy;

import java.sql.Date;
import java.sql.Timestamp;
import java.sql.SQLException;

import java.io.FileWriter;
import java.io.IOException;

import org.xml.sax.*;

import java.lang.ClassNotFoundException;

import java.util.Vector;

import com.knowgate.debug.DebugFile;

public class DataStructOrcl extends DataStruct {

  public DataStructOrcl() {
  }

  public DataStructOrcl(String sPathXMLFile) throws ClassNotFoundException, IllegalAccessException, InstantiationException, IOException, SAXException {
    super(sPathXMLFile);
  }

  // ----------------------------------------------------------

  private String sqlldr (Object oValue) {
    String sClass;
    String sRetVal;
    Date dtValue;
    Timestamp tsValue;

    if (null==oValue) {
      sRetVal = "NULL";
    }
    else {
      sClass = oValue.getClass().getName();

      if (sClass.equals("java.lang.String"))
        sRetVal = "\"" + oValue.toString() + "\"";
      else if (sClass.equals("java.util.Date") || sClass.equals("java.sql.Date")) {
        dtValue = (Date) oValue;
        sRetVal = String.valueOf(dtValue.getYear()+1900) + "-";
        sRetVal += (dtValue.getMonth()+1<10 ? "0" + String.valueOf(dtValue.getMonth()+1) : String.valueOf(dtValue.getMonth()+1)) + "-";
        sRetVal += (dtValue.getDay()+1<10 ? "0" + String.valueOf(dtValue.getDay()+1) : String.valueOf(dtValue.getDay()+1)) + " ";
        sRetVal += (dtValue.getHours()<10 ? "0" + String.valueOf(dtValue.getHours()) : String.valueOf(dtValue.getHours())) + ":";
        sRetVal += (dtValue.getMinutes()<10 ? "0" + String.valueOf(dtValue.getMinutes()) : String.valueOf(dtValue.getMinutes())) + ":";
        sRetVal += (dtValue.getSeconds()<10 ? "0" + String.valueOf(dtValue.getSeconds()) : String.valueOf(dtValue.getSeconds()));
        dtValue = null;
      }
      else if (sClass.equals("java.sql.Timestamp")) {
        tsValue = (Timestamp) oValue;
        sRetVal = String.valueOf(tsValue.getYear()+1900) + "-";
        sRetVal += (tsValue.getMonth()+1<10 ? "0" + String.valueOf(tsValue.getMonth()+1) : String.valueOf(tsValue.getMonth()+1)) + "-";
        sRetVal += (tsValue.getDay()+1<10 ? "0" + String.valueOf(tsValue.getDay()+1) : String.valueOf(tsValue.getDay()+1)) + " ";
        sRetVal += (tsValue.getHours()<10 ? "0" + String.valueOf(tsValue.getHours()) : String.valueOf(tsValue.getHours())) + ":";
        sRetVal += (tsValue.getMinutes()<10 ? "0" + String.valueOf(tsValue.getMinutes()) : String.valueOf(tsValue.getMinutes())) + ":";
        sRetVal += (tsValue.getSeconds()<10 ? "0" + String.valueOf(tsValue.getSeconds()) : String.valueOf(tsValue.getSeconds()));
        tsValue = null;
      }
      else {
        sRetVal = oValue.toString();
      }
    } // fi(null==oValue)

    return sRetVal;
  }

  // ----------------------------------------------------------

  public void createSQLLoaderFiles(String sBasePath) throws IOException,SQLException {
    DataRowSet oDatR;
    DataTblDef oTblD;
    FileWriter oFilW;

    if (DebugFile.trace) {
      DebugFile.writeln ("Begin DataStruct.createSQLLoaderFiles(" + sBasePath + ")");
      DebugFile.incIdent();
    }

    prepareStatements();

    for (int t=0; t<cTables; t++) {
      oDatR = getRowSet(t);
      oTblD = TrMetaData[t];
      oFilW = new FileWriter(sBasePath + oDatR.OriginTable + ".CTL", false);
      oFilW.write("LOAD DATA\n");
      oFilW.write("INFILE *\n");
      oFilW.write("REPLACE INTO TABLE " + oDatR.TargetTable +"\n");
      oFilW.write("FIELDS TERMINATED BY \"`\" OPTIONALLY ENCLOSED BY '\"'\n");
      oFilW.write("(\n");
      for (int c=0; c<oTblD.ColCount; c++) {
        oFilW.write("  " + oTblD.ColNames[c]);
        if (oTblD.ColTypes[c]==java.sql.Types.DATE || oTblD.ColTypes[c]==java.sql.Types.TIMESTAMP)
          oFilW.write(" DATE \"YYYY-MM-DD HH24-MI-SS\"");
        oFilW.write(" NULLIF (" + oTblD.ColNames[c] + " = \"NULL\")");
        oFilW.write(c<oTblD.ColCount-1 ? ",\n" : ")\n");
      } // next(c)
      oFilW.write("BEGINDATA\n");
      oFilW.close();
    } // next(t)

    if (DebugFile.trace) {
      DebugFile.decIdent();
      DebugFile.writeln ("End DataStruct.createSQLLoaderFiles()");
    }
  } // createSQLLoaderFiles()

  // ----------------------------------------------------------

  public void dump(Object[] OrPK, Object[] TrPK,  int cParams, String sBasePath) throws SQLException,IOException {
    // Inserta registros del Origen en el Destino,
    // si encuentra un registro duplicado lo actualiza sin dar ningún error,
    // si el registro no está, lo inserta

    DataTblDef oMDat;
    Object oValue;
    int iPK;
    FileWriter TblFiles[] = new FileWriter[cTables];

    if (DebugFile.trace) {
      DebugFile.writeln ("Begin DataStruct.dump(OrPK[], TrPK[], " + String.valueOf(cParams) + ", " + sBasePath + ")");
      DebugFile.incIdent();
    }

    for (int t=0; t<cTables; t++)
      TblFiles[t] = new FileWriter(sBasePath + getRowSet(t).OriginTable + ".CTL", true);

    execCommands("INIT", -1, OrPK, cParams);

    // Iterar sobre las tablas: para cada una de ellas leer sus registros e insertarlos en destino
    for (int s=0; s<cTables; s++) {
      if (DebugFile.trace) DebugFile.writeln ("processing rowset from " + getRowSet(s).OriginTable + " to " + getRowSet(s).TargetTable);

      execCommands("BEFORE", s, OrPK, cParams);

      getRows(OrPK, TrPK, cParams, s); // Modifica {iRows, iCols} como efecto lateral

      oMDat = TrMetaData[s];

      // Iterar sobre cada fila leida en origen y escribirla en el fichero correspondiente
      for (int r=0; r<iRows; r++) {
          iPK = 0;
          // Iterador de parametros de entrada
          for (int q=0; q<iCols; q++) {
            oValue = ((Vector) oResults.get(r)).get(q);

            if ((oMDat.isPrimaryKey(q))) {
              if (iPK>=cParams)
                TblFiles[s].write(sqlldr(oValue));
              else if (null==TrPK[iPK])
                TblFiles[s].write(sqlldr(oValue));
              else
                TblFiles[s].write(sqlldr(TrPK[iPK]));
              iPK++;
            }
            else
              TblFiles[s].write(sqlldr(oValue));
            if (q<iCols-1) TblFiles[s].write("`");
          } // end for (q)
      TblFiles[s].write("\n");
      } // end for (r)

      oResults.clear();
      oResults = null;

      execCommands("AFTER", s, OrPK, cParams);
    } // end for (s)

    execCommands("TERM", -1, OrPK, cParams);

    for (int t=0; t<cTables; t++)
      TblFiles[t].close();

    if (DebugFile.trace) {
      DebugFile.decIdent();
      DebugFile.writeln ("End DataStruct.dump()");
    }
  } // dump()
}
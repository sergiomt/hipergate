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

import java.util.HashMap;
import java.util.Iterator;

import java.sql.Connection;
import java.sql.Statement;
import java.sql.PreparedStatement;
import java.sql.ResultSet;
import java.sql.SQLException;

import com.knowgate.debug.DebugFile;
import com.knowgate.misc.Gadgets;

public class DataTransformation {

  public DataTransformation() {
    Values = new HashMap();
  }

  public DataTransformation(String sOpDesc, String sOrTable, String sOrField,
                                            String sTrTable, String sTrField) {
    Values = new HashMap();

    if (sOpDesc.equalsIgnoreCase("NEXTVAL") ||
        sOpDesc.equalsIgnoreCase("REFER")) {
      NextVals = new HashMap();
      NextVals.put(sTrTable + "." + sTrField, new Integer(0));
    }

    setOperation (sOpDesc);
    OriginTable = sOrTable;
    OriginField = sOrField;
    TargetTable = sTrTable;
    TargetField = sTrField;
  }

  public DataTransformation(int iOpCode, String sOrTable, String sOrField,
                                         String sTrTable, String sTrField,
                                         String sRfTable, String sRfField,
                                         String sIfNull) {
    Values = new HashMap();

    if (Operations.NEXTVAL==iOpCode || Operations.REFER==iOpCode) {
      NextVals = new HashMap();
      NextVals.put(sTrTable + "." + sTrField, new Integer(0));
    }

    OperationCode = iOpCode;
    OriginTable = sOrTable;
    OriginField = sOrField;
    TargetTable = sTrTable;
    TargetField = sTrField;
    ReferedTable= sRfTable;
    ReferedField= sRfField;
    IfNullValue = sIfNull;
  }

  // ----------------------------------------------------------

  private void setOperation(String sOpDesc) {
    /* Establece el tipo de operación que realizará este servicio de
      transformación de datos
      Parámetros:
        sOpDesc -> Descripción de la Operación.
                   Puede ser uno de los siguientes valores:
                   1) NEWGUID para que el campo en destino sea un nuevo GUID generado dinámicamente
                   2) NEXTVAL el campo en destino será MAX(campo)+1
                   3) IFNULL(valor) si el campo en origen es NULL se substituirá por el valor especificado
                   4) REFER(tablaref.camporef) el campo se substituirá por el valor que tenga tablaref.camporef
    */
    int iLeft;
    int iRight;
    int iDot;

    if (sOpDesc.equalsIgnoreCase("NEWGUID"))
      OperationCode = Operations.NEWGUID;
    else if (sOpDesc.equalsIgnoreCase("NEXTVAL")) {
      OperationCode = Operations.NEXTVAL;
    }
    else if (sOpDesc.equalsIgnoreCase("REFERENCED")) {
      OperationCode = Operations.REFERENCED;
    }
    else if (sOpDesc.startsWith("IFNULL")) {
      OperationCode = Operations.IFNULL;
      iLeft = sOpDesc.indexOf("(") + 1;
      iRight = sOpDesc.lastIndexOf(")");
      IfNullValue = sOpDesc.substring(iLeft, iRight).trim();
    }
    else if (sOpDesc.startsWith("REFER")) {
      OperationCode = Operations.REFER;
      iLeft = sOpDesc.indexOf("(") + 1;
      iRight = sOpDesc.lastIndexOf(")");
      iDot = sOpDesc.indexOf(".");
      ReferedTable = sOpDesc.substring(iLeft , iDot);
      ReferedField = sOpDesc.substring(iDot+1, iRight);
    }
  } // setOperation()

  // ----------------------------------------------------------

  public void setReferedValues(DataTransformation oDataTransf) {
    ReferedValues = oDataTransf.Values;
  }

  // ----------------------------------------------------------

  private String IncOffset(String sTrTable, String sTrField) {
    String  sKey = sTrTable + "." + sTrField;
    Integer iOldOffset = (Integer) NextVals.get(sKey);
    Integer iNewOffset = new Integer(iOldOffset.intValue()+1);

    NextVals.remove(sKey);
    NextVals.put(sKey, iNewOffset);

    return iNewOffset.toString();
  }

  // ----------------------------------------------------------

  private Integer getNextVal(Connection oTrConn) throws SQLException {
    Integer    oRetVal;
    Object     oMax;
    Statement  oStmt;
    ResultSet  oRSet;
    Iterator   oIter;

    oStmt = oTrConn.createStatement(ResultSet.TYPE_FORWARD_ONLY, ResultSet.CONCUR_READ_ONLY);

    oRSet = oStmt.executeQuery("SELECT MAX(" + TargetField + ")+" + IncOffset(TargetTable,TargetField) + " FROM " + TargetTable);

    if (oRSet.next()) {
      oMax = oRSet.getObject(1);
      if (oRSet.wasNull())
        oRetVal = new Integer(1);
      else
        oRetVal = new Integer(oMax.toString());
    }
    else {
      oRetVal = new Integer(1);
    }
    oRSet.close();
    oStmt.close();

    // Asegurar que el nextVal no mapea un campo al mismo valor que tiene
    // otro obtenido a través de referencia a otra tabla y no de autoincremento
    if (Operations.REFER==OperationCode) {
      oIter = ReferedValues.values().iterator();
      while (oIter.hasNext())
        if (((Integer) oIter.next()).intValue()==oRetVal.intValue()) {
          if (DebugFile.trace) DebugFile.writeln("Remapping " + TargetTable + "." + TargetField);
          oRetVal = getNextVal(oTrConn);
          break;
        }
      // wend
      oIter = null;
    }

    return oRetVal;
  } // getNextVal()

  // ----------------------------------------------------------

  public Object transform(Connection oOrConn, Connection oTrConn, Object oInput) throws SQLException {
    Object oNexVal;
    Object oRetVal;
    Iterator oIter;
    PreparedStatement oStmt;
    ResultSet oRSet;

    switch(OperationCode) {
     case Operations.NEWGUID:
       oRetVal = Gadgets.generateUUID();
       break;
     case Operations.NEXTVAL:
       oRetVal = getNextVal(oTrConn);
       break;
     case Operations.IFNULL:
        if (null==oInput) {
          if (IfNullValue.equalsIgnoreCase("SYSDATE")  ||
              IfNullValue.equalsIgnoreCase("GETDATE()")||
              IfNullValue.equalsIgnoreCase("NOW()") ||
              IfNullValue.equalsIgnoreCase("CURRENT_TIMESTAMP"))
            oRetVal = new java.sql.Date(new java.util.Date().getTime());
          else
            oRetVal = IfNullValue;
        }
        else if (oInput.getClass().getName().equals("java.lang.String"))
          oRetVal = oInput.toString().length()>0 ? oInput : IfNullValue;
        else
          oRetVal = oInput;
       break;
     case Operations.REFER:
       if (ReferedValues!=null) {
         // Busca el valor en la tabla de referencia,
         // si no lo encuentra, entonces crea un nuevo GUID
         if (ReferedValues.containsKey(oInput))
           oRetVal = ReferedValues.get(oInput);
         else if (oInput!=null) {
           // Si el campo no se encuentra en el mapa de memoria
           // pero ya existía en la tabla de destino,
           // entonces dejarlo tal cual en el mapeo.
           oStmt = oTrConn.prepareStatement("SELECT NULL FROM " + TargetTable + " WHERE " + TargetField + "=?");
           oStmt.setObject(1,oInput);
           oRSet = oStmt.executeQuery();
           if (oRSet.next())
             oRetVal = oInput;
           else
             oRetVal = null;
           oRSet.close();
           oStmt.close();

           if (null==oRetVal) {
             oIter = ReferedValues.values().iterator();
             if (oIter.hasNext()) {
               oNexVal = oIter.next();
               if (oNexVal.getClass().getName().equals("java.lang.String"))
                 oRetVal = Gadgets.generateUUID();
               else
                 oRetVal = getNextVal(oTrConn);
             }
             else
               oRetVal = Gadgets.generateUUID();
             oIter = null;
           }
         } // fi(oInput)
         else
           oRetVal = null;
       }
       else {
         throw new SQLException(this.OriginTable + " could not reference " + this.ReferedTable, "23000");
       } // fi(ReferedValues)
      break;
     case Operations.REFERENCED:
       oRetVal = oInput;
       break;
     default:
       oRetVal = oInput;
    }

    if (!Values.containsKey(oInput)) Values.put(oInput, oRetVal);

    return oRetVal;
  } // transform()

  // ----------------------------------------------------------

  public int OperationCode;  // Codigo de operacion
  public String IfNullValue; // Valor para reemplazar si el campo es NULL
  public String OriginField; // Nombre del campo origen
  public String TargetField; // Nombre de campo destino
  public String OriginTable; // Nombre de tabla origen
  public String TargetTable; // Nombre de tabla destino
  public String ReferedTable;
  public String ReferedField;
  public HashMap ReferedValues;
  public HashMap Values;
  public HashMap NextVals;

  public class Operations {
    public static final int NEWGUID = 1;
    public static final int NEXTVAL = 2;
    public static final int IFNULL = 4;
    public static final int REFERENCED = 8;
    public static final int REFER = 16;
  }
}
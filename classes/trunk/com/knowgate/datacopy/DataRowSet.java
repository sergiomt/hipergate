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

// ************************************************************
// Almacenamiento interno de datos del nodo ACTION para cada
// ROWSET definido en XML

package com.knowgate.datacopy;

public class DataRowSet {

  public DataRowSet() {
    FieldList = "*"; // Por defecto se leen todos los campos
    OriginTable = TargetTable = JoinTables = WhereClause = EraseClause = null;
  }

  public DataRowSet(String sOriginTable, String sTargetTable, String sJoinTables, String sWhereClause, String sEraseClause) {
    OriginTable = sOriginTable;
    TargetTable = sTargetTable;
    JoinTables = sJoinTables;
    WhereClause = sWhereClause;
    EraseClause = sEraseClause;
  }

  public String FieldList;   // Lista de campos (sólo si el nodo <FIELDLIST> existe en XML
  public String OriginTable; // Tabla Origen
  public String TargetTable; // Tabla Destino
  public String JoinTables;  // Tablas de JOIN (actualmente no se utiliza)
  public String WhereClause; // Claúsula WHERE
  public String EraseClause; // Claúsula de borrado
} // DataRowSet
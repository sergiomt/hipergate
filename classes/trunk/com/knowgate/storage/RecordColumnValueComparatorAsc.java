package com.knowgate.storage;

import java.sql.Types;
import java.util.Date;
import java.util.Comparator;

public class RecordColumnValueComparatorAsc implements Comparator<Record> {

    private String sColName;
    private int iColType;
    private String dtNull;
    
    public RecordColumnValueComparatorAsc(String sColumnName) {
      sColName = sColumnName;
      iColType = Types.NULL;
      dtNull = null;
    }

    public int compare(Record r1, Record r2) {
	  if (iColType==Types.NULL) {
	  	iColType = r1.getColumn(sColName).getType();
	    if (iColType==Types.DATE || iColType==Types.TIMESTAMP)
	      dtNull = "0000-01-01 00:00:00"; 
	  }
	  switch (iColType) {
	  	case Types.INTEGER:
	  	  if (r1.isNull(sColName) && r2.isNull(sColName))
	  	  	return 0;
	  	  else if (r1.isNull(sColName))
	  	  	return -1;
	  	  else if (r2.isNull(sColName))
	  	  	return 1;
	  	  else
	  	  	return r1.getInt(sColName)>r2.getInt(sColName) ? 1 : r1.getInt(sColName)<r2.getInt(sColName) ? -1 : 0;	  		
	  	case Types.CLOB:
	    case Types.CHAR:
	    case Types.NCHAR:
	    case Types.VARCHAR:
	    case Types.NVARCHAR:
	    case Types.LONGVARCHAR:
	    case Types.LONGNVARCHAR:	    
	      return r1.getString(sColName,"").compareTo(r2.getString(sColName,""));
	  	case Types.DATE:
	  	case Types.TIMESTAMP:
	  	  return r1.getString(sColName,dtNull).compareTo(r2.getString(sColName,dtNull));
		default:
		  throw new IllegalArgumentException("Column comparator not implemented for type");
	  }
    } // compare

    public boolean equals(Record r1, Record r2) {
	  if (iColType==Types.NULL) {
	  	iColType = r1.getColumn(sColName).getType();
	    if (iColType==Types.DATE || iColType==Types.TIMESTAMP)
	      dtNull = "0000-01-01 00:00:00";
	  }
	  switch (iColType) {
	  	case Types.INTEGER:
	  	  if (r1.isNull(sColName) || r2.isNull(sColName))
	  	    return false;
	  	  else
	  	  	return r1.getInt(sColName)==r2.getInt(sColName);
	  	case Types.CLOB:
	    case Types.CHAR:
	    case Types.NCHAR:
	    case Types.VARCHAR:
	    case Types.NVARCHAR:
	    case Types.LONGVARCHAR:
	    case Types.LONGNVARCHAR:
	      return r1.getString(sColName,"null").equals(r2.getString(sColName,"null"));
	  	case Types.DATE:
	  	case Types.TIMESTAMP:
	      return r1.getString(sColName,dtNull).equals(r2.getString(sColName,dtNull));
		default:
		  throw new IllegalArgumentException("Column comparator not implemented for type");
	  }
    } // equals
}

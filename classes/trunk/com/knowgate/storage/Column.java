package com.knowgate.storage;

import java.sql.Types;
import java.sql.Timestamp;

import java.math.BigDecimal;

import java.util.Date;
import java.util.HashMap;

import java.io.Serializable;

import org.apache.oro.text.regex.Pattern;
import org.apache.oro.text.regex.Perl5Matcher;
import org.apache.oro.text.regex.Perl5Compiler;
import org.apache.oro.text.regex.MalformedPatternException;

public class Column implements Serializable {

  private static final long serialVersionUID = 600000101201000100l;

  private int iPosition;
  private int nLength;
  private int iType;
  private String sName;
  private boolean bNullable;
  private boolean bIndexed;
  private boolean bPk;
  private String sForeignKey;
  private Object oDefault;
  private Pattern oPattern;

  private static HashMap<String,Pattern> oRegExps = new HashMap<String,Pattern>();
  private static Perl5Compiler oCompiler = new Perl5Compiler();
  private static Perl5Matcher oMatcher = new Perl5Matcher();

  public Column(int iColPos, String sColName, int iColType, int nColLen,
  				boolean bIsNullable, boolean bIsIndexed,
  				String sForeignKeyTableName, Object oDefaultValue,
  				boolean bIsPrimaryKey) {
  	iPosition = iColPos;
  	sName = sColName;
  	iType = iColType;
  	nLength = nColLen;
  	bNullable = bIsNullable;
  	bIndexed = bIsIndexed;
  	bPk = bIsPrimaryKey;
  	oDefault = oDefaultValue;
  	sForeignKey = sForeignKeyTableName;
  	oPattern = null;
  }
  
  public Column(int iColPos, String sColName, int iColType, int nColLen,
  				boolean bIsNullable, boolean bIsIndexed, String sCheckRegExp,
  				String sForeignKeyTableName, Object oDefaultValue,
  				boolean bIsPrimaryKey)
  	throws MalformedPatternException {
  	iPosition = iColPos;
  	sName = sColName;
  	iType = iColType;
  	nLength = nColLen;
  	bNullable = bIsNullable;
  	bIndexed = bIsIndexed;
  	bPk = bIsPrimaryKey;
  	oDefault = oDefaultValue;
  	sForeignKey = sForeignKeyTableName;
  	if (null==sCheckRegExp) {
  	  oPattern = null;
  	} else if (oRegExps.containsKey(sCheckRegExp)) {
	  oPattern = oRegExps.get(sCheckRegExp);
  	} else {
	  oPattern = oCompiler.compile(sCheckRegExp,Perl5Compiler.CASE_INSENSITIVE_MASK);
	  oRegExps.put(sCheckRegExp, oPattern);
  	}
  }

  public int getPosition() {
    return iPosition;
  }  

  public String getName() {
    return sName;
  }  

  public int getType() {
    return iType;
  }  

  public int getLength() {
    return nLength;
  }  

  public Object getDefaultValue() {
    return oDefault;
  }  

  public String getConstraint() {
  	if (getForeignKey()==null)
      if (oPattern==null)
        return null;
      else
        return oPattern.getPattern();
    else
      return "foreign key "+getForeignKey();
  }  

  public boolean isIndexed() {
    return bIndexed;
  }  

  public boolean isPrimaryKey() {
    return bPk;
  }  

  public boolean isNullable() {
    return bNullable;
  }  

  public String getForeignKey() {
    return sForeignKey;
  }  

  public boolean check(Object sValue) {
  	boolean bRetVal;
  	if (null==sValue) {
  	  bRetVal = bNullable;
  	} else {
  	  if (null==oPattern) {
		bRetVal = true;
      } else {
      	if (sValue instanceof String) {
      	  bRetVal = oMatcher.matches(sValue.toString(), oPattern) ||
      	  	        (bNullable && ((String)sValue).length()==0);
      	} else {
      	  switch (getType()) {
      	  	case Types.SMALLINT:
      	  	  bRetVal = sValue instanceof Short;
      	  	  if (bRetVal) bRetVal = oMatcher.matches(sValue.toString(), oPattern);
      	  	  break;
      	  	case Types.INTEGER:
      	  	  bRetVal = sValue instanceof Integer;
      	  	  if (bRetVal) bRetVal = oMatcher.matches(sValue.toString(), oPattern);
      	  	  break;
      	  	case Types.BIGINT:
      	  	  bRetVal = sValue instanceof Long;
      	  	  if (bRetVal) bRetVal = oMatcher.matches(sValue.toString(), oPattern);
      	  	  break;
      	  	case Types.FLOAT:
      	  	  bRetVal = sValue instanceof Float;
      	  	  if (bRetVal) bRetVal = oMatcher.matches(sValue.toString(), oPattern);
      	  	  break;
      	  	case Types.DOUBLE:
      	  	  bRetVal = sValue instanceof Double;
      	  	  if (bRetVal) bRetVal = oMatcher.matches(sValue.toString(), oPattern);
      	  	  break;
      	  	case Types.DECIMAL:
      	  	case Types.NUMERIC:
      	  	  bRetVal = sValue instanceof BigDecimal;
      	  	  if (bRetVal) bRetVal = oMatcher.matches(sValue.toString(), oPattern);
      	  	  break;
      	  	case Types.TIMESTAMP:
      	  	case Types.DATE:
      	      bRetVal = sValue instanceof Date || sValue instanceof Timestamp;
      	      break;
      	    default:
      	      bRetVal = false;
      	  }
      	}
      }
  	}
  	return bRetVal;
  } // check
}

/*
  Copyright (C) 2005  Know Gate S.L. All rights reserved.
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

package com.knowgate.hipergate.datamodel;

/**
 * @author Sergio Montoro Ten
 * @version 6.0
 */

import java.sql.DriverManager;
import java.sql.Connection;
import java.sql.SQLException;
import java.sql.PreparedStatement;
import java.sql.ResultSet;
import java.sql.Types;

import java.io.File;
import java.io.FileOutputStream;
import java.io.FileInputStream;
import java.io.FileWriter;
import java.io.BufferedInputStream;
import java.io.BufferedOutputStream;
import java.io.InputStreamReader;
import java.io.FileNotFoundException;
import java.io.IOException;

import java.util.HashMap;

import com.knowgate.debug.DebugFile;
import com.knowgate.misc.Gadgets;
import com.knowgate.misc.VCardParser;
import com.knowgate.acl.UserLoader;
import com.knowgate.crm.ContactLoader;
import com.knowgate.crm.CompanyLoader;
import com.knowgate.crm.DistributionList;
import com.knowgate.crm.VCardLoader;
import com.knowgate.crm.OportunityLoader;
import com.knowgate.addrbook.FellowLoader;
import com.knowgate.hipergate.ProductLoader;
import com.knowgate.hipergate.DespatchAdviceLoader;
import com.knowgate.dataobjs.DB;
import com.knowgate.dataobjs.DBSubset;
import com.knowgate.dataobjs.DBColumn;

public class ImportExport {

  private static String[] ReservedWords = { "ALLCAPS", "APPEND", "UPDATE", "APPENDUPDATE",
  "CONNECT", "TO", "IDENTIFIED", "BY", "SCHEMA", "INFILE", "INPUTFILE", "BADFILE",
  "DISCARDFILE", "CHARSET", "CHARACTERSET", "ROWDELIM", "COLDELIM", "RECOVERABLE",
  "UNRECOVERABLE", "PRESERVESPACE", "WORKAREA", "MAXERRORS", "INSERTLOOKUPS", "SKIP",
  "CATEGORY", "USERS", "CONTACTS", "COMPANIES", "PRODUCTS", "FELLOWS", "DESPATCHS","VCARDS",
  "OPORTUNITIES", "OPPORTUNITIES", "WITHOUT", "DUPLICATED", "NAMES", "EMAILS", "LIST" };

  // ---------------------------------------------------------------------------

  public ImportExport() { }

  // ---------------------------------------------------------------------------

  private boolean isReservedWord(String sWord) {
    for (int r=ReservedWords.length-1; r>=0; r--)
      if (ReservedWords[r].equalsIgnoreCase(sWord))
        return true;
    return false;
  }

  // ---------------------------------------------------------------------------

  /**
   * Perform an import or export command
   * @param sControlCmdLine String [APPEND|UPDATE|APPENDUPDATE] [CONTACTS|COMPANIES|PRODUCTS|USERS|FELLOWS|DESPATCHS|VCARDS|<I>table_name</I>] CONNECT user TO connection_string IDENTIFED BY password INPUTFILE "/tmp/filename.txt" BADFILE "/tmp/badfile.txt" DISCARDFILE "/tmp/discardfile.txt" CHARSET ISO8859_1 ROWDELIM CRLF COLDELIM "|" ([column type]+)<BR>
   * EXPORT <I>table_name</I> CONNECT user TO connection_string IDENTIFIED BY password OUTPUTFILE "/tmp/filename.txt"
   * @return Count of errors found or zero if operation was successfully completed
   * @throws ImportExportException
   */
  @SuppressWarnings("unused")
public int perform (final String sControlCmdLine)
    throws ImportExportException {

    if (DebugFile.trace) {
      DebugFile.writeln("Begin ImportExport.perform("+sControlCmdLine+")");
    }

    int iErrorCount = 0;
    int iMaxErrors = 2147483647;
    int i=-1, r=0, c=0;
    int iLine = 1;
    int iSkip = 0;
    int iRowDelimLen = -1;
    String sColDelim=";", sRowDelim="\n";
    String sCmd=null, sEntity=null, sCharSet="ISO8859_1", sInFile=null,
           sBadFile=null, sDiscardFile=null,sOutFile=null,
           sConnectStr=null, sUser=null, sPwd=null, sSchema=null,
           sWorkArea=null,sCategory=null,sWhere=null,sDeList=null,sGuList=null;
    int iFlags = 0;
    boolean bRecoverable=true, bPreserveSpace=false, bAllCaps=false;
    String sToken,sLine;
    String[] aLine;
    int iParenthesisNesting = 0;
    File oInFile = null;
    ColumnList oColumns = new ColumnList();
    DBColumn oCurrentColumn = null;
    ImportLoader oImplLoad=null;

    if (null==sControlCmdLine) return 0;
    if (sControlCmdLine.length()==0) return 0;

    // *********************
    // Tokenize command line

    String[] aCmdLine = Gadgets.tokenizeCmdLine(sControlCmdLine);
    final int nCmmds = aCmdLine.length;

    if (DebugFile.trace) DebugFile.writeln("  parsing command line...");

    // ******************************************
    // Check that the main command is a valid one
    if (aCmdLine[0].equalsIgnoreCase("APPEND") ||
        aCmdLine[0].equalsIgnoreCase("UPDATE") ||
        aCmdLine[0].equalsIgnoreCase("APPENDUPDATE")) {
      sCmd = aCmdLine[0];
      sEntity = aCmdLine[1];
      if (sEntity.equalsIgnoreCase("CONTACTS")) {
        oImplLoad = new ContactLoader();
        iFlags |= ContactLoader.WRITE_CONTACTS|ContactLoader.WRITE_COMPANIES|ContactLoader.WRITE_ADDRESSES;
      } else if (sEntity.equalsIgnoreCase("COMPANIES")) {
        oImplLoad = new CompanyLoader();
        iFlags |= ContactLoader.WRITE_ADDRESSES;
	  } else if (sEntity.equalsIgnoreCase("OPORTUNITIES") || sEntity.equalsIgnoreCase("OPPORTUNITIES")) {
        oImplLoad = new OportunityLoader();
        iFlags = 0;        
      } else if (sEntity.equalsIgnoreCase("USERS")) {
        oImplLoad = new UserLoader();
      } else if (sEntity.equalsIgnoreCase("FELLOWS")) {
        oImplLoad = new FellowLoader();
      } else if (sEntity.equalsIgnoreCase("PRODUCTS")) {
        oImplLoad = new ProductLoader();
      } else if (sEntity.equalsIgnoreCase("DESPATCHS")) {
      	if (!sCmd.equalsIgnoreCase("APPEND"))
          throw new ImportExportException("ONLY APPEND MODE IS SUPPORTED FOR DESPATCH ADVICES");
        oImplLoad = new DespatchAdviceLoader();
        iFlags |= DespatchAdviceLoader.MODE_APPEND;
      } else if (sEntity.equalsIgnoreCase("VCARDS")) {
        oImplLoad = new VCardLoader();
        iFlags |= VCardLoader.WRITE_ADDRESSES|VCardLoader.WRITE_CONTACTS|VCardLoader.WRITE_COMPANIES|VCardLoader.NO_DUPLICATED_NAMES|VCardLoader.NO_DUPLICATED_MAILS;
      }
      else {
        if (isReservedWord(sEntity)) {
          if (DebugFile.trace) { DebugFile.writeln("Expected CONTACTS,COMPANIES,PRODUCTS,USERS,FELLOWS,DESPATCHS,VCARDS or a table name but found reserved keyword "+sEntity); DebugFile.decIdent(); }
          throw new ImportExportException("Expected CONTACTS,COMPANIES,PRODUCTS,USERS,FELLOWS,DESPATCHS,VCARDS or a table name but found reserved keyword "+sEntity);
        } else {
          oImplLoad = new TableLoader(sEntity);
        }
      }
    } else if (aCmdLine[0].equalsIgnoreCase("EXPORT")) {
      sCmd = aCmdLine[0];
      sEntity = aCmdLine[1];
    } else {
      if (DebugFile.trace) { DebugFile.writeln("Cannot recognize command " + aCmdLine[0]); DebugFile.decIdent(); }
      throw new ImportExportException("Cannot recognize command " + aCmdLine[0]);
    }

    if (sCmd.equalsIgnoreCase("APPEND")) {
      iFlags |= ImportLoader.MODE_APPEND;
    } else if (sCmd.equalsIgnoreCase("UPDATE")) {
      iFlags |= ImportLoader.MODE_UPDATE;
    } else if (sCmd.equalsIgnoreCase("APPENDUPDATE")) {
      iFlags |= ImportLoader.MODE_APPENDUPDATE;
    }

    // ************************************************
    // Iterate throught tokens and set status variables

    for (int t=0; t<nCmmds; t++) {
      sToken = aCmdLine[t];

      // *******************************************
      // Process tokens before a parenthesis is found

      if (0==iParenthesisNesting) {
        if (sToken.equalsIgnoreCase("CHARACTERSET") || sToken.equalsIgnoreCase("CHARSET")) {
            if (t==nCmmds-1)
              throw new ImportExportException("CHARACTERSET attribute lacks of value specification");
            else
              sCharSet=aCmdLine[++t];
        if (DebugFile.trace) DebugFile.writeln("  CHARACTERSET="+sCharSet);
        } // fi
        if (sToken.equalsIgnoreCase("CONNECT")) {
            if (t>nCmmds-6) {
      		  if (DebugFile.trace) { DebugFile.writeln("CONNECT attribute lacks of value specification"); DebugFile.decIdent(); }
              throw new ImportExportException("CONNECT attribute lacks of value specification");
            } else {
              if (!aCmdLine[t+2].equalsIgnoreCase("TO")) {
      		    if (DebugFile.trace) { DebugFile.writeln("TO keyword expected but found " + aCmdLine[t+2]); DebugFile.decIdent(); }
                throw new ImportExportException("TO keyword expected but found " + aCmdLine[t+2]);
              }
              if (!aCmdLine[t+4].equalsIgnoreCase("IDENTIFIED")) {
      		    if (DebugFile.trace) { DebugFile.writeln("IDENTIFIED keyword expected but found " + aCmdLine[t+4]); DebugFile.decIdent(); }
                throw new ImportExportException("IDENTIFIED keyword expected but found " + aCmdLine[t+4]);
              }
              if (!aCmdLine[t+5].equalsIgnoreCase("BY")) {
      		    if (DebugFile.trace) { DebugFile.writeln("BY keyword expected but found " + aCmdLine[t+5]); DebugFile.decIdent(); }
                throw new ImportExportException("BY keyword expected but found " + aCmdLine[t+5]);
              }

              sUser=aCmdLine[++t]; // t+1
              t++; // skip TO
              sConnectStr=aCmdLine[++t]; // t+3
              t+=2; // skip IDENTIFIED BY
              sPwd=aCmdLine[++t]; // t+6
            } // fi
        if (DebugFile.trace) DebugFile.writeln("  CONNECT="+sConnectStr);
        } // fi
        if (sToken.equalsIgnoreCase("SCHEMA")) {
          if (t==nCmmds-1) {
      		if (DebugFile.trace) { DebugFile.writeln("SCHEMA attribute lacks of value specification"); DebugFile.decIdent(); }
            throw new ImportExportException("SCHEMA attribute lacks of value specification");
          } else {
            sSchema=aCmdLine[++t];
          }
        if (DebugFile.trace) DebugFile.writeln("  SCHEMA="+sSchema);
        } // fi
        if (sToken.equalsIgnoreCase("SKIP")) {
          if (t==nCmmds-1) {
      		if (DebugFile.trace) { DebugFile.writeln("SKIP attribute lacks of value specification"); DebugFile.decIdent(); }
            throw new ImportExportException("SKIP attribute lacks of value specification");
          } else {
            try {
              iSkip=Integer.parseInt(aCmdLine[++t]);
            } catch (NumberFormatException nfe) {
      		  if (DebugFile.trace) { DebugFile.writeln("SKIP attribute must be a positive integer value"); DebugFile.decIdent(); }
              throw new ImportExportException("SKIP attribute must be a positive integer value");
            }
            if (iSkip<0) {
      		  if (DebugFile.trace) { DebugFile.writeln("SKIP attribute must be a positive integer value"); DebugFile.decIdent(); }
              throw new ImportExportException("SKIP attribute must be a positive integer value");
            }
          }
        if (DebugFile.trace) DebugFile.writeln("  SKIP="+String.valueOf(iSkip));
        } // fi
        else if (sToken.equalsIgnoreCase("WORKAREA")) {
          if (t==nCmmds-1) {
      		if (DebugFile.trace) { DebugFile.writeln("WORKAREA attribute lacks of value specification"); DebugFile.decIdent(); }
            throw new ImportExportException("WORKAREA attribute lacks of value specification");
          } else {
            sWorkArea=aCmdLine[++t];
          }
        if (DebugFile.trace) DebugFile.writeln("  WORKAREA="+sWorkArea);
        }
        else if (sToken.equalsIgnoreCase("CATEGORY")) {
          if (!sEntity.equalsIgnoreCase("PRODUCTS"))
            throw new ImportExportException("CATEGORY attribute is only allowed for loading PRODUCTS, not "+sEntity);
          if (t==nCmmds-1)
            throw new ImportExportException("CATEGORY attribute lacks of value specification");
          else
            sCategory=aCmdLine[++t];
        if (DebugFile.trace) DebugFile.writeln("  CATEGORY="+sCategory);
        }
        else if (sToken.equalsIgnoreCase("WHERE")) {
          if (sCmd.equalsIgnoreCase("APPEND") || sCmd.equalsIgnoreCase("UPDATE") || sCmd.equalsIgnoreCase("APPENDUPDATE"))
            throw new ImportExportException(sToken + "parameter cannot de used with " + sCmd + " command");
          if (t==nCmmds-1)
            throw new ImportExportException(sToken+" attribute lacks of value specification");
          sWhere=aCmdLine[++t];
        }
        else if (sToken.equalsIgnoreCase("OUTPUTFILE") || sToken.equalsIgnoreCase("OUTFILE")) {
          if (sCmd.equalsIgnoreCase("APPEND") || sCmd.equalsIgnoreCase("UPDATE") || sCmd.equalsIgnoreCase("APPENDUPDATE"))
            throw new ImportExportException(sToken + "parameter cannot de used with " + sCmd + " command");
          if (t==nCmmds-1)
            throw new ImportExportException(sToken+" attribute lacks of value specification");
          sOutFile=aCmdLine[++t];
        }
        else if (sToken.equalsIgnoreCase("INPUTFILE") || sToken.equalsIgnoreCase("INFILE")) {
          if (t==nCmmds-1)
            throw new ImportExportException(sToken+" attribute lacks of value specification");
          else {
            sInFile=aCmdLine[++t];
            oInFile=new File(sInFile);
            if (!oInFile.exists()) throw new ImportExportException("Input file not found " + sInFile);
            if (oInFile.isDirectory()) throw new ImportExportException(sInFile+" must be a file but actually is a directory");
          }
          if (DebugFile.trace) DebugFile.writeln("  INPUTFILE="+sInFile);
        } // fi
        else if (sToken.equalsIgnoreCase("BADFILE")) {
          if (sCmd.equalsIgnoreCase("EXPORT"))
            throw new ImportExportException(sToken + "parameter cannot de used with " + sCmd + " command");
          if (t==nCmmds-1)
              throw new ImportExportException("BADFILE attribute lacks of value specification");
          else {
              sBadFile=aCmdLine[++t];
          }
          if (DebugFile.trace) DebugFile.writeln("  BADFILE="+sBadFile);
        } // fi
        else if (sToken.equalsIgnoreCase("DISCARDFILE")) {
          if (sCmd.equalsIgnoreCase("EXPORT"))
            throw new ImportExportException(sToken + "parameter cannot de used with " + sCmd + " command");
          if (t==nCmmds-1)
            throw new ImportExportException("DISCARDFILE attribute lacks of value specification");
          else {
            sDiscardFile=aCmdLine[++t];
          }
          if (DebugFile.trace) DebugFile.writeln("  DISCARDFILE="+sDiscardFile);
        } // fi
        else if (sToken.equalsIgnoreCase("INSERTLOOKUPS")) {
          if (sCmd.equalsIgnoreCase("EXPORT"))
            throw new ImportExportException(sToken + "parameter cannot de used with " + sCmd + " command");
          iFlags |= ImportLoader.WRITE_LOOKUPS;
          if (DebugFile.trace) DebugFile.writeln("  INSERTLOOKUPS set to true");
        } // fi
        else if (sToken.equalsIgnoreCase("MAXERRORS")) {
          if (t==nCmmds-1)
            throw new ImportExportException("MAXERRORS attribute lacks of value specification");
          else {
            try {
              iMaxErrors=Integer.parseInt(aCmdLine[++t]);
            } catch (NumberFormatException nfe) {
              throw new ImportExportException("MAXERRORS attribute must be a positive integer value");
            }
            if (iMaxErrors<0)
              throw new ImportExportException("MAXERRORS attribute must be a positive integer value");
          }
          if (DebugFile.trace) DebugFile.writeln("  MAXERRORS="+String.valueOf(iMaxErrors));
        } // fi
        else if (sToken.equalsIgnoreCase("RECOVERABLE")) {
          if (sCmd.equalsIgnoreCase("EXPORT"))
            throw new ImportExportException(sToken + "parameter cannot de used with " + sCmd + " command");
          bRecoverable=true;
          if (DebugFile.trace) DebugFile.writeln("  RECOVERABLE set to true");
        } // fi
        else if (sToken.equalsIgnoreCase("UNRECOVERABLE")) {
          if (sCmd.equalsIgnoreCase("EXPORT"))
            throw new ImportExportException(sToken + "parameter cannot de used with " + sCmd + " command");
          bRecoverable=false;
          if (DebugFile.trace) DebugFile.writeln("  RECOVERABLE set to false");
        } // fi
        else if (sToken.equalsIgnoreCase("ROWDELIM") || sToken.equalsIgnoreCase("ROWDELIMITER")) {
          if (t==nCmmds-1)
            throw new ImportExportException("ROWDELIM attribute lacks of value specification");
          else {
            sRowDelim=aCmdLine[++t];
            if (sRowDelim.equalsIgnoreCase("LF")) sRowDelim="\n";
            if (sRowDelim.equalsIgnoreCase("CR")) sRowDelim="\r";
            if (sRowDelim.equalsIgnoreCase("CRLF")) sRowDelim="\r\n";
            iRowDelimLen = sRowDelim.length();
          }
          if (DebugFile.trace) DebugFile.writeln("  ROWDELIM="+sRowDelim);
        } // fi
        else if (sToken.equalsIgnoreCase("COLDELIM") || sToken.equalsIgnoreCase("COLDELIMITER") ||
                 sToken.equalsIgnoreCase("COLUMNDELIM") || sToken.equalsIgnoreCase("COLUMNDELIMITER")) {
          if (t==nCmmds-1)
            throw new ImportExportException("COLDELIM attribute lacks of value specification");
          else {
            sColDelim=aCmdLine[++t];
            if (sColDelim.equalsIgnoreCase("TAB")) sColDelim="\t";
          }
          if (DebugFile.trace) DebugFile.writeln("  COLDELIM="+sColDelim);
        } // fi
        else if (sToken.equalsIgnoreCase("PRESERVESPACE")) {
          bPreserveSpace=true;
          if (DebugFile.trace) DebugFile.writeln("  PRESERVESPACE set to true");
        } // fi
        else if (sToken.equalsIgnoreCase("ALLCAPS")) {
          bAllCaps=true;
          if (DebugFile.trace) DebugFile.writeln("  ALLCAPS set to true");
        } // fi
        else if (sToken.equalsIgnoreCase("WITHOUT")) {
		  if (sEntity.equalsIgnoreCase("CONTACTS")){
            if (t>nCmmds-3)
              throw new ImportExportException("Reached end of statement before completing WITHOUT clause");
		    else {
              if (!aCmdLine[++t].equalsIgnoreCase("DUPLICATED"))
              throw new ImportExportException("Expected DUPLICATED keyword but found "+aCmdLine[t]);
		      else {
		  	    t++;
                if (!aCmdLine[t].equalsIgnoreCase("NAMES") && !aCmdLine[t].equalsIgnoreCase("EMAILS"))
                  throw new ImportExportException("Expected NAMES or EMAILS keyword but found "+aCmdLine[t]);
		  	    else {
				  if (aCmdLine[t].equalsIgnoreCase("NAMES"))
				  	iFlags |= ContactLoader.NO_DUPLICATED_NAMES;
				  else if (aCmdLine[t].equalsIgnoreCase("EMAILS"))
				  	iFlags |= ContactLoader.NO_DUPLICATED_MAILS;
		  	    }
		  	  }
		    }
		  } else {
            throw new ImportExportException("WITHOUT clause is only allowed for CONTACTS not for "+sEntity);
		  }
        } // fi
        else if (sToken.equalsIgnoreCase("LIST")) {
		  if (sEntity.equalsIgnoreCase("CONTACTS")) {
		    iFlags |= ContactLoader.ADD_TO_LIST;
		  } else if (sEntity.equalsIgnoreCase("COMPANIES")) {
		    iFlags |= CompanyLoader.ADD_TO_LIST;
		  } else {
            throw new ImportExportException("Only CONTACTS or COMPANIES may be added to a LIST");
		  }
          sDeList=aCmdLine[++t];
        } // fi
        else if (sToken.equalsIgnoreCase("(")) {
          iParenthesisNesting++;
          if (DebugFile.trace) DebugFile.writeln("open parenthesis, count is "+String.valueOf(iParenthesisNesting));
          oCurrentColumn = new DBColumn();
          oColumns.add(oCurrentColumn);
        }
        else if (sToken.equalsIgnoreCase(")")) {
          iParenthesisNesting--;
          if (DebugFile.trace) DebugFile.writeln("open parenthesis, count is "+String.valueOf(iParenthesisNesting));
        }
      } else {
        // *******************************************
        // Process tokens after a parenthesis is found
        // These are the column names and types definition

        if (sToken.equalsIgnoreCase("(")) {
          iParenthesisNesting++;
          if (DebugFile.trace) DebugFile.writeln("  open parenthesis, count is "+String.valueOf(iParenthesisNesting));
        }
        else if (sToken.equalsIgnoreCase(")")) {
          iParenthesisNesting--;
          if (DebugFile.trace) DebugFile.writeln("  close parenthesis, count is "+String.valueOf(iParenthesisNesting));
        }
        else if (sToken.equalsIgnoreCase(",")) {
          // after each comma, add a new column
          if (DebugFile.trace) DebugFile.writeln("  added column "+oCurrentColumn.getName()+" "+oCurrentColumn.getSqlTypeName());
          oCurrentColumn = new DBColumn();
          oColumns.add(oCurrentColumn);
        }
        else {
          int iSQType = DBColumn.getSQLType(sToken);
          if (iSQType!=Types.NULL) {
            if (iSQType==Types.DATE || iSQType==Types.TIMESTAMP) {
              if (t==nCmmds-1)
                throw new ImportExportException((iSQType==Types.DATE ? "DATE" : "TIMESTAMP")+" format is required");
              else  {
                oCurrentColumn.setSqlType(iSQType);
                try {
                  oCurrentColumn.setDateFormat(aCmdLine[++t]);
                } catch (IllegalArgumentException iae) {
                  throw new ImportExportException("Invalid date format "+sToken, iae);
                }
              }
            } else {
              oCurrentColumn.setSqlType(iSQType);
            }
          } else {
              oCurrentColumn.setName(sToken);
              oCurrentColumn.setSqlType(Types.NULL);
          } // fi (iSQType!=Types.NULL)
        }
      } // fi (1==iParenthesisNesting)
    } // next

    final int iColFmtsCount = oColumns.size();
    DBColumn oColFmt;

    if (DebugFile.trace) {
      StringBuffer oColumnsFmts = new StringBuffer();
      for (c=0; c<iColFmtsCount; c++) {
        oColFmt = oColumns.getColumn(c);
        oColumnsFmts.append(oColFmt.getName()+" "+oColFmt.getSqlTypeName());
        if (oColFmt.getDateFormat()!=null) oColumnsFmts.append(" "+oColFmt.getDateFormat().toPattern());
        oColumnsFmts.append(c<iColFmtsCount-1 ? "," : "}");
      } // next
      DebugFile.writeln("  Column definitions {"+oColumnsFmts.toString());
    } // fi (DebugFile.trace)

    // *************************************************************
    // Perform some basic verifications on command line completeness

    if (0!=iParenthesisNesting)
      throw new ImportExportException("Unterminated parenthesis (");
    if ((sCmd.equalsIgnoreCase("APPEND") || sCmd.equalsIgnoreCase("UPDATE") || sCmd.equalsIgnoreCase("APPENDUPDATE")) && null==sInFile)
      throw new ImportExportException("INFILE is required");
    if (sCmd.equalsIgnoreCase("EXPORT") && null==sOutFile)
      throw new ImportExportException("OUTFILE is required");
    if (sCmd.equalsIgnoreCase("EXPORT") && null==sWhere)
      throw new ImportExportException("WHERE clause is required");
    if (null==sConnectStr)
      throw new ImportExportException("ConnectionString is required");

    // *********************************************
    // Load JDBC drivers for all supported databases

    Class jdbcdriver;
    try {
      if (DebugFile.trace) DebugFile.writeln("  Class.forName(com.microsoft.jdbc.sqlserver.SQLServerDriver)");
      jdbcdriver = Class.forName("com.microsoft.jdbc.sqlserver.SQLServerDriver");
    } catch (ClassNotFoundException ignore) { if (DebugFile.trace) DebugFile.writeln("Class not found com.microsoft.jdbc.sqlserver.SQLServerDriver"); }
    try {
      if (DebugFile.trace) DebugFile.writeln("  Class.forName(org.postgresql.Driver)");
      jdbcdriver = Class.forName("org.postgresql.Driver");
    } catch (ClassNotFoundException ignore) { if (DebugFile.trace) DebugFile.writeln("Class not found org.postgresql.Driver"); }
    try {
      if (DebugFile.trace) DebugFile.writeln("  Class.forName(oracle.jdbc.driver.OracleDriver)");
      jdbcdriver = Class.forName("oracle.jdbc.driver.OracleDriver");
    } catch (ClassNotFoundException ignore) { if (DebugFile.trace) DebugFile.writeln("Class not found oracle.jdbc.driver.OracleDriver"); }
    try {
      if (DebugFile.trace) DebugFile.writeln("  Class.forName(com.ibm.db2.jcc.DB2Driver)");
      jdbcdriver = Class.forName("com.ibm.db2.jcc.DB2Driver");
    } catch (ClassNotFoundException ignore) { if (DebugFile.trace) DebugFile.writeln("Class not found com.ibm.db2.jcc.DB2Driver"); }
    try {
      if (DebugFile.trace) DebugFile.writeln("  Class.forName(com.mysql.jdbc.Driver)");
      jdbcdriver = Class.forName("com.mysql.jdbc.Driver");
    } catch (ClassNotFoundException ignore) { if (DebugFile.trace) DebugFile.writeln("Class not found com.mysql.jdbc.Driver"); }

    // ***********************
    // Connect to the database
    Connection oConn = null;
    try {
      if (DebugFile.trace) DebugFile.writeln("  DriverManager.getConnection("+sConnectStr+","+sUser+")");
      oConn = DriverManager.getConnection(sConnectStr, sUser, sPwd);
    } catch (SQLException sqle) {
      throw new ImportExportException(sqle.getMessage(), sqle);
    }

    // **************************
    // Check that WorkArea exists

    if (null!=sWorkArea) {
      boolean bSignalWorkAreaException = false;
      try {
        if (DebugFile.trace) DebugFile.writeln("  Connection.prepareStatement(SELECT gu_workarea FROM k_workareas WHERE gu_workarea='"+Gadgets.left(sWorkArea, 32)+"' OR nm_workarea='"+Gadgets.left(sWorkArea, 50)+"'");
        PreparedStatement oStmt = oConn.prepareStatement("SELECT gu_workarea FROM k_workareas WHERE gu_workarea=? OR nm_workarea=?",ResultSet.TYPE_FORWARD_ONLY, ResultSet.CONCUR_READ_ONLY);
        oStmt.setString(1, Gadgets.left(sWorkArea, 32));
        oStmt.setString(2, Gadgets.left(sWorkArea, 50));
        ResultSet oRSet = oStmt.executeQuery();
        if (oRSet.next())
          sWorkArea = oRSet.getString(1);
        else
          bSignalWorkAreaException = true;
        oRSet.close();
        oStmt.close();
        if (bSignalWorkAreaException) {
          oConn.close();
          throw new ImportExportException("WorkArea " + sWorkArea + " not found");
        }
      } catch (SQLException sqle) {
        try {oConn.close();} catch (SQLException ignore) {}
        throw new ImportExportException("SQLException " + sqle.getMessage());
      }
    } // fi

    // **************************
    // Check that Category exists

    if (null!=sCategory) {
      boolean bSignalCategoryException = false;
      try {
        if (DebugFile.trace) DebugFile.writeln("  Connection.prepareStatement(SELECT gu_workarea FROM k_categories WHERE gu_category='"+Gadgets.left(sCategory, 32)+"' OR nm_category='"+Gadgets.left(sCategory, 100)+"'");
        PreparedStatement oStmt = oConn.prepareStatement("SELECT gu_category FROM k_categories WHERE gu_category=? OR nm_category=?",ResultSet.TYPE_FORWARD_ONLY, ResultSet.CONCUR_READ_ONLY);
        oStmt.setString(1, Gadgets.left(sCategory, 32));
        oStmt.setString(2, Gadgets.left(sCategory, 100));
        ResultSet oRSet = oStmt.executeQuery();
        if (oRSet.next())
          sCategory = oRSet.getString(1);
        else
          bSignalCategoryException = true;
        oRSet.close();
        oStmt.close();
        if (bSignalCategoryException) {
          oConn.close();
          throw new ImportExportException("Category " + sCategory + " not found");
        }
      } catch (SQLException sqle) {
        try {oConn.close();} catch (SQLException ignore) {}
        throw new ImportExportException("SQLException " + sqle.getMessage());
      }
    } // fi

	// Get List GUID or create a new one
	if (sDeList!=null) {
      if (DebugFile.trace) DebugFile.writeln("  Retrieving GUID for list "+sDeList);
	  if (sWorkArea==null)  
        throw new ImportExportException("WORKAREA parameter is required when specifying a target LIST");
	  short iTpList = 0;
	  PreparedStatement oList = null;
	  ResultSet oRist = null;
	  try {
	    oList = oConn.prepareStatement("SELECT "+DB.gu_list+","+DB.tp_list+" FROM "+DB.k_lists+" WHERE "+DB.gu_workarea+"=? AND ("+DB.gu_list+"=? OR "+DB.de_list+"=?)",ResultSet.TYPE_FORWARD_ONLY, ResultSet.CONCUR_READ_ONLY);
        oList.setString(1, sWorkArea);
	    oList.setString(2, sDeList);
	    oList.setString(3, sDeList);
	    oRist = oList.executeQuery();
	    if (oRist.next()) {
	      sGuList = oRist.getString(1);
		  iTpList = oRist.getShort(2);
	    }
	    oRist.close();
	    oRist=null;
	    oList.close();
	    oList=null;
	    if (sGuList==null) {
	  	  sGuList = Gadgets.generateUUID();
	  	  oList = oConn.prepareStatement("INSERT INTO "+DB.k_lists+"("+DB.gu_list+","+DB.tp_list+","+DB.gu_workarea+","+DB.de_list+","+DB.tx_subject+") VALUES(?,?,?,?,?)");
		  oList.setString(1, sGuList);
		  oList.setShort (2, DistributionList.TYPE_STATIC);
		  oList.setString(3, sWorkArea);
		  oList.setString(4, sDeList);
		  oList.setString(5, sDeList);
		  oList.executeUpdate();
		  oList.close();	
	      oList=null;
	    } else if (iTpList!=DistributionList.TYPE_STATIC && iTpList!=DistributionList.TYPE_DIRECT)
          throw new ImportExportException(sEntity+" can only be loaded at STATIC or DIRECT lists");	  
        if (DebugFile.trace) DebugFile.writeln("  gu_list="+sGuList);
	  } catch (SQLException sqle) {
	    if (oRist!=null) { try { oRist.close(); } catch (SQLException ignore) {} }
	    if (oList!=null) { try { oList.close(); } catch (SQLException ignore) {} }
	  }	
	} // fi (sDeList)

    // ***************
    // File handlers

    // Data input file
    FileOutputStream oOutStrm = null;
    FileInputStream oInStrm = null;
    BufferedInputStream oInBuff;
    BufferedOutputStream oOutBuff;
    // File with a description of all errors
    FileWriter oBadWrtr = null;
    // File with just the rows that failed to be inserted
    FileWriter oDiscardWrtr = null;
    // Intermediate buffer for SQL composition
    StringBuffer oSQL = new StringBuffer();
    StringBuffer oRow = new StringBuffer();

      if (DebugFile.trace) DebugFile.writeln("  Begin inserting data...");

      // ********************
      // Open data input file

    if (sCmd.equalsIgnoreCase("APPEND") || sCmd.equalsIgnoreCase("UPDATE") || sCmd.equalsIgnoreCase("APPENDUPDATE")) {
      try {
        if (DebugFile.trace) {
          DebugFile.writeln("  new FileInputStream("+sInFile+")");
          DebugFile.writeln("  input file length is "+String.valueOf(oInFile.length())+" bytes");
        }
        oInStrm = new FileInputStream(oInFile);
      } catch (FileNotFoundException fnfe) {
        try { oConn.close(); } catch (Exception ignore) {}
        throw new ImportExportException("File not found opening stream "+sInFile, fnfe);
      }
      // Java direct I/O performance sucks so use an intermediate buffer
      oInBuff = new BufferedInputStream(oInStrm);

      // **********************************
      // Open bad and discard file writters

      if (sBadFile!=null) {
        try {
          if (DebugFile.trace) DebugFile.writeln("  new FileWriter("+sBadFile+")");
          oBadWrtr = new FileWriter(sBadFile, false);
        }
        catch (FileNotFoundException neverthrown) {}
        catch (IOException ioe) {
          try { oInBuff.close(); } catch (Exception ignore) {}
          try { oInStrm.close(); } catch (Exception ignore) {}
          try { oConn.close(); } catch (Exception ignore) {}
          throw new ImportExportException("IOException "+ioe.getMessage(), ioe);
        }
      }
      if (sDiscardFile!=null) {
        try {
          if (DebugFile.trace) DebugFile.writeln("  new FileWriter("+sDiscardFile+")");
          oDiscardWrtr = new FileWriter(sDiscardFile, false);

        }
        catch (FileNotFoundException neverthrown) {}
        catch (IOException ioe) {
          try { oBadWrtr.close(); } catch (Exception ignore) {}
          try { oInBuff.close(); } catch (Exception ignore) {}
          try { oInStrm.close(); } catch (Exception ignore) {}
          try { oConn.close(); } catch (Exception ignore) {}
          throw new ImportExportException("IOException "+ioe.getMessage(), ioe);
        }
      }

      // *****************************************************************
      // If RECOVERABLE mode is enabled then set AutoCommit OFF else switch
      // AutoCommit ON and commit each row just after insertion

      try {
        oImplLoad.prepare(oConn, oColumns);
        if (bRecoverable)
          oConn.setAutoCommit(false);
        else
          oConn.setAutoCommit(true);
      } catch (Exception xcpt) {
        try { oBadWrtr.close(); } catch (Exception ignore) {}
        try { oInBuff.close(); } catch (Exception ignore) {}
        try { oInStrm.close(); } catch (Exception ignore) {}
        try { oImplLoad.close(); } catch (Exception ignore) {}
        try { oConn.close(); } catch (Exception ignore) {}
        throw new ImportExportException(xcpt.getClass().getName()+" "+xcpt.getMessage(), xcpt);
      }

	  if (sEntity.equalsIgnoreCase("VCARDS")) {
        try {
			VCardParser oPrsr = new VCardParser();
			oPrsr.parse(oInBuff, sCharSet);
			VCardLoader oVCrdLoad = (VCardLoader) oImplLoad;
			for (HashMap<String,String> oVCard : oPrsr.vcards()) {
			  oVCrdLoad.put(oVCard);
			  try {
			    oVCrdLoad.store(oConn, sWorkArea, iFlags);
              } catch (Exception xcpt) {
                iErrorCount++;
                if (DebugFile.trace) DebugFile.writeln("  "+xcpt.getClass().getName()+": at line "+String.valueOf(iLine)+" "+xcpt.getMessage());
                if (bRecoverable) {
                  if (DebugFile.trace) DebugFile.writeln("  Connection.rollback()");
                  try { oConn.rollback(); } catch (SQLException ignore) {}
                } // fi (bRecoverable)
                if (oBadWrtr!=null) {
                  oBadWrtr.write(xcpt.getClass().getName()+": at card "+oVCard.get("N")+" "+xcpt.getMessage()+"\r\n");
                } // fi
                if (oDiscardWrtr!=null) {
                  oDiscardWrtr.write(oVCard.get("N")+sRowDelim);
                } // fi
              } // catch
			} // next

            if (oInBuff!=null) { oInBuff.close(); }
            oInBuff=null;
            if (oInStrm!=null) { oInStrm.close(); }
            oInStrm=null;
            if (oBadWrtr!=null) { oBadWrtr.close(); oBadWrtr=null; }
            if (oDiscardWrtr!=null) { oDiscardWrtr.close(); oDiscardWrtr=null; }

            oImplLoad.close();
            if (bRecoverable) {
            if (0==iErrorCount)
              oConn.commit();
            else
              oConn.rollback();
            }

            if (DebugFile.trace) DebugFile.writeln("Connection.close()");
            oConn.close();
        } catch (Exception xcpt) {
             if (DebugFile.trace) DebugFile.writeln("  "+xcpt.getClass().getName()+" "+xcpt.getMessage());
             try { if (null!=oDiscardWrtr) oDiscardWrtr.close(); } catch (Exception ignore) {}
             try { if (null!=oBadWrtr) oBadWrtr.close(); } catch (Exception ignore) {}
             try { if (null!=oInBuff) oInBuff.close(); } catch (Exception ignore) {}
             try { if (null!=oInStrm) oInStrm.close(); } catch (Exception ignore) {}
             try { oImplLoad.close(); } catch (Exception ignore) {}
             try { if (bRecoverable) oConn.rollback(); } catch (Exception ignore) {}
             try { oConn.close(); } catch (Exception ignore) {}
             throw new ImportExportException(xcpt.getClass().getName() + " " + xcpt.getMessage());
        } 
	  } else {

        // *******************************************************
        // Check that all column names on input file are valid
        // and resolve column names to positions for faster access
  
        if (DebugFile.trace) DebugFile.writeln("Resolving column names to positions...");
        for (c=0; c<iColFmtsCount; c++) {
          DBColumn oClmn = oColumns.getColumn(c);
          if (oClmn.getSqlType()!=Types.NULL) {
            int cIndex = oImplLoad.getColumnIndex(oClmn.getName());
            if (-1==cIndex) {
              throw new ImportExportException("SQLException column "+oClmn.getName()+" not found at base table");
            } else {
              oClmn.setPosition(cIndex);
            }
          }
        } // next (c)
  
        // ******************************************
        // Read data input file and insert row by row
  
        if (DebugFile.trace) DebugFile.writeln("Begin read data from text file...");

		InputStreamReader oInRdr = null;
        try {
          // Use an stream reader for decoding bytes into the proper charset
          if (DebugFile.trace) DebugFile.writeln("  new InputStreamReader(BufferedInputStream,"+sCharSet+")");
          oInRdr = new InputStreamReader(oInBuff, sCharSet);
        } catch (java.io.UnsupportedEncodingException uee) {
          try { oInBuff.close(); } catch (Exception ignore) {}
          try { oInStrm.close(); } catch (Exception ignore) {}
          try { oConn.close(); } catch (Exception ignore) {}
          throw new ImportExportException("Unsupported Encoding "+sCharSet, uee);
        }

        try {          
          if (DebugFile.trace) {
          	String sRowDelimChr = "", sColDelimChr = "";
          	for (int d=0; d<sRowDelim.length(); d++) sRowDelimChr += "Chr("+String.valueOf((int)sRowDelim.charAt(d))+")";
          	for (int d=0; d<sColDelim.length(); d++) sColDelimChr += "Chr("+String.valueOf((int)sColDelim.charAt(d))+")";
          	DebugFile.writeln("  Read input stream with row delimiter "+sRowDelimChr+" and col delimiter "+sColDelimChr);
          }
          int nCharCount = 0;
          // Read input file by one character at a time
          while (((i=oInRdr.read())!=-1) && (iErrorCount<=iMaxErrors)) {
            nCharCount++;
            // Skip row delimiter, let r be the relative position inside the row delimiter
            // then skip as many characters readed at i as they match with row delimiter + offset r
            r=0;
            while (i==sRowDelim.charAt(r) && i!=-1) {
              r++;
              i=oInRdr.read();
              if (r==iRowDelimLen) break;
            } // wend
            // If r>0 then the row delimiter has been reached Or
            // If i==-1 then it is the last line, so insert the row
            if (r==iRowDelimLen || i==-1) {
              if (iLine>iSkip) {
                if (DebugFile.trace) DebugFile.writeln("  Processing line "+String.valueOf(iLine));
                if (bPreserveSpace)
                  sLine = oRow.toString();
                else
                  sLine = oRow.toString().trim();
                if (sLine.length()>0) {
                  if (sColDelim.length()==1)
                    aLine = Gadgets.split(sLine, sColDelim.charAt(0));
                  else
                    aLine = Gadgets.split(sLine, sColDelim);
                  // If current line does have the same number of columns as in the
                  // file definition then report an error or raise an exception
                  if (aLine.length!=iColFmtsCount) {
                    iErrorCount++;
                    if (DebugFile.trace) DebugFile.writeln("  Error: at line "+String.valueOf(iLine)+" has "+String.valueOf(aLine.length)+" columns but should have "+String.valueOf(iColFmtsCount));
                    if (bRecoverable) {
                      if (DebugFile.trace) DebugFile.writeln("  Connection.rollback()");
                      try { oConn.rollback(); } catch (SQLException ignore) {}
                    }
                    if (oBadWrtr!=null) {
                      oBadWrtr.write("Error: at line "+String.valueOf(iLine)+" has "+String.valueOf(aLine.length)+" columns but should have "+String.valueOf(iColFmtsCount)+"\r\n");
                      oBadWrtr.write(sLine+"\r\n");
                    }
                    if (oDiscardWrtr!=null) {
                      oDiscardWrtr.write(sLine+sRowDelim);
                    }
                  } else {
                    // Up to here a single line as been readed and is kept in aLines array
                    try {
                      oImplLoad.setAllColumnsToNull();
                      if (bAllCaps) {
                        for (c=0; c<iColFmtsCount; c++) {
                          oColFmt = oColumns.getColumn(c);
                          if (oColFmt.getSqlType()!=Types.NULL) {
                          	String sColName = oColFmt.getName();
                            if (DebugFile.trace) DebugFile.writeln("  ImportLoader.put("+sColName+"("+String.valueOf(oColFmt.getPosition())+"),"+aLine[c]+")");
                            if (sColName.equalsIgnoreCase(DB.tx_email) ||
                            	sColName.equalsIgnoreCase(DB.tx_email_alt) ||
                                sColName.equalsIgnoreCase(DB.tx_alt_email) ||
                                sColName.equalsIgnoreCase(DB.tx_main_email) ||
                                sColName.equalsIgnoreCase(DB.tx_comments) ||
                                sColName.equalsIgnoreCase(DB.tx_remarks) ||
                                sColName.equalsIgnoreCase(DB.tx_nickname) ||
                                sColName.equalsIgnoreCase(DB.tx_pwd) ||
                                sColName.equalsIgnoreCase(DB.tx_pwd_sign) ||
                                sColName.startsWith("url_") ||
                                sColName.startsWith("de_") ||
                                sColName.startsWith("gu_") ||
                                sColName.startsWith("id_") ||
                                sColName.startsWith("tp_") )
                              oImplLoad.put(sColName, oColFmt.convert(aLine[c]));
                            else
                              oImplLoad.put(sColName, oColFmt.convert(aLine[c].toUpperCase()));
                          } // fi (getSqlType()!=NULL)
                        } // next c)
                      } else {
                        for (c=0; c<iColFmtsCount; c++) {
                          oColFmt = oColumns.getColumn(c);
                          if (oColFmt.getSqlType()!=Types.NULL) {
                            if (DebugFile.trace) DebugFile.writeln("  ImportLoader.put("+oColFmt.getName()+"("+String.valueOf(oColFmt.getPosition())+"),"+aLine[c]+")");
                            oImplLoad.put(oColFmt.getName(), oColFmt.convert(aLine[c]));
                          } // fi (getSqlType()!=NULL)
                        } // next c)
                      } // fi (ALLCAPS)
                      if (null!=sCategory) oImplLoad.put("gu_category", sCategory);
                      if (null!=sGuList) oImplLoad.put("gu_list", sGuList);
                      oImplLoad.store(oConn, sWorkArea, iFlags);
                    } catch (NumberFormatException xcpt) {
                      iErrorCount++;
                      if (DebugFile.trace) DebugFile.writeln("  NumberFormatException: at line "+String.valueOf(iLine)+" "+xcpt.getMessage());
                      if (bRecoverable) {
                        if (DebugFile.trace) DebugFile.writeln("  Connection.rollback()");
                        try { oConn.rollback(); } catch (SQLException ignore) {}
                      } // fi (bRecoverable)
                      if (oBadWrtr!=null) {
                        oBadWrtr.write("NumberFormatException: at line "+String.valueOf(iLine)+" "+xcpt.getMessage()+"\r\n");
                        oBadWrtr.write(sLine+"\r\n");
                      } // fi
                      if (oDiscardWrtr!=null) {
                        oDiscardWrtr.write(sLine+sRowDelim);
                      } // fi
                    } catch (SQLException xcpt) {
                      iErrorCount++;
                      if (DebugFile.trace) DebugFile.writeln("  SQLException: at line "+String.valueOf(iLine)+" "+xcpt.getMessage());
                      if (bRecoverable) {
                        if (DebugFile.trace) DebugFile.writeln("  Connection.rollback()");
                        try { oConn.rollback(); } catch (SQLException ignore) {}
                      } // fi (bRecoverable)
                      if (oBadWrtr!=null) {
                        oBadWrtr.write("SQLException: at line "+String.valueOf(iLine)+" "+xcpt.getMessage()+"\r\n");
                        oBadWrtr.write(sLine+"\r\n");
                      } // fi
                      if (oDiscardWrtr!=null) {
                        oDiscardWrtr.write(sLine+sRowDelim);
                      } // fi
                    } // catch
                  } // fi (aLine.length!=iColFmtsCount)
                } // fi (sLine!="")
              } else {
 				if (DebugFile.trace) DebugFile.writeln("  Skiping line "+String.valueOf(iLine));
              } // fi (iLine>iSkip)
              oRow.setLength(0);
              if (i!=-1) oRow.append((char)i);
              iLine++;
              if (-1==i) break;
            } else {
              oRow.append((char)i);
            }// fi (r==iRowDelimLen || i==-1)
          } // wend
  		  if (null!=oInRdr) oInRdr.close();

          if (DebugFile.trace) {
            DebugFile.writeln("End read data from text file. "+String.valueOf(nCharCount)+" characters readed with error count "+String.valueOf(iErrorCount));
          }

        if (oInBuff!=null) { oInBuff.close(); }
        oInBuff=null;
        if (oInStrm!=null) { oInStrm.close(); }
        oInStrm=null;
        if (oBadWrtr!=null) { oBadWrtr.close(); oBadWrtr=null; }
        if (oDiscardWrtr!=null) { oDiscardWrtr.close(); oDiscardWrtr=null; }

        oImplLoad.close();
        if (bRecoverable) {
          if (0==iErrorCount)
            oConn.commit();
          else
            oConn.rollback();
        }

        if (DebugFile.trace) DebugFile.writeln("Connection.close()");
        oConn.close();
      } catch (SQLException xcpt) {
        if (DebugFile.trace) DebugFile.writeln("  "+xcpt.getClass().getName()+": at row "+String.valueOf(r)+" "+xcpt.getMessage());
        try { if (null!=oDiscardWrtr) oDiscardWrtr.close(); } catch (Exception ignore) {}
        try { if (null!=oBadWrtr) oBadWrtr.close(); } catch (Exception ignore) {}
        try { if (null!=oInBuff) oInBuff.close(); } catch (Exception ignore) {}
        try { if (null!=oInStrm) oInStrm.close(); } catch (Exception ignore) {}
        try { oImplLoad.close(); } catch (Exception ignore) {}
        try { if (bRecoverable) oConn.rollback(); } catch (Exception ignore) {}
        try { oConn.close(); } catch (Exception ignore) {}
        throw new ImportExportException(xcpt.getClass().getName() + " " + xcpt.getMessage() + " at row " + String.valueOf(r));
      }
      catch (IOException xcpt) {
             if (DebugFile.trace) DebugFile.writeln("  "+xcpt.getClass().getName()+": at row "+String.valueOf(r)+" "+xcpt.getMessage());
             try { if (null!=oDiscardWrtr) oDiscardWrtr.close(); } catch (Exception ignore) {}
             try { if (null!=oBadWrtr) oBadWrtr.close(); } catch (Exception ignore) {}
             try { if (null!=oInBuff) oInBuff.close(); } catch (Exception ignore) {}
             try { if (null!=oInStrm) oInStrm.close(); } catch (Exception ignore) {}
             try { oImplLoad.close(); } catch (Exception ignore) {}
             try { if (bRecoverable) oConn.rollback(); } catch (Exception ignore) {}
             try { oConn.close(); } catch (Exception ignore) {}
             throw new ImportExportException(xcpt.getClass().getName() + " " + xcpt.getMessage() + " at row " + String.valueOf(r));
      }
      catch (java.text.ParseException xcpt) {
            if (DebugFile.trace) DebugFile.writeln("  "+xcpt.getClass().getName()+": at row "+String.valueOf(r)+" "+xcpt.getMessage());
            try { if (null!=oDiscardWrtr) oDiscardWrtr.close(); } catch (Exception ignore) {}
            try { if (null!=oBadWrtr) oBadWrtr.close(); } catch (Exception ignore) {}
            try { if (null!=oInBuff) oInBuff.close(); } catch (Exception ignore) {}
            try { if (null!=oInStrm) oInStrm.close(); } catch (Exception ignore) {}
            try { oImplLoad.close(); } catch (Exception ignore) {}
            try { if (bRecoverable) oConn.rollback(); } catch (Exception ignore) {}
            try { oConn.close(); } catch (Exception ignore) {}
            throw new ImportExportException(xcpt.getClass().getName() + " " + xcpt.getMessage() + " at row " + String.valueOf(r));
     }
	 } // fi

    } // fi (sCmd==APPEND || sCmd==UPDATE || sCmd==APPENDUPDATE)

    if (sCmd.equalsIgnoreCase("EXPORT")) {
      try {
        if (DebugFile.trace) DebugFile.writeln("  new FileOutputStream("+sOutFile+")");
        oOutStrm = new FileOutputStream(sOutFile);
        oOutBuff = new BufferedOutputStream(oOutStrm);
        // Use an stream reader for decoding bytes into the proper charset
      } catch (IOException ioe) {
        try { oConn.close(); } catch (Exception ignore) {}
        throw new ImportExportException("IOException "+ioe.getMessage(), ioe);
      } catch (SecurityException jse) {
        try { oConn.close(); } catch (Exception ignore) {}
        throw new ImportExportException("SecurityException "+jse.getMessage(), jse);
      }

      try {
        sToken = "";
        for (c = 0; c < iColFmtsCount; c++) {
          oColFmt = oColumns.getColumn(c);
          sToken = (sToken.length() == 0 ? "" : ",") + oColFmt.getName();
        } // next
        DBSubset oDbs = new DBSubset(sEntity, sToken, sWhere, 100);
        oDbs.setColumnDelimiter(sColDelim);
        oDbs.setRowDelimiter(sRowDelim);
        oDbs.print(oConn, oOutBuff);
        oOutBuff.close();
        oOutStrm.close();
      } catch (Exception xcpt) {
        try { oOutBuff.close(); } catch (Exception ignore) {}
        try { oOutStrm.close(); } catch (Exception ignore) {}
        try { oConn.close(); } catch (Exception ignore) {}
        throw new ImportExportException(xcpt.getClass().getName()+xcpt.getMessage(), xcpt);
      }
    } // fi (sCmd==EXPORT)

    if (DebugFile.trace) {
      DebugFile.writeln("End ImportExport.perform() : "+String.valueOf(iErrorCount));
    }
    return iErrorCount;
  } // perform
}

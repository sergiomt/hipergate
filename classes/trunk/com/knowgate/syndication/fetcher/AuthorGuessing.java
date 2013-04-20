/*
  Copyright (C) 2003-2011  Know Gate S.L. All rights reserved.

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

package com.knowgate.syndication.fetcher;

import java.io.InputStream;
import java.io.InputStreamReader;
import java.io.BufferedReader;
import java.io.IOException;
import java.io.FileNotFoundException;

import java.sql.SQLException;
import java.util.ArrayList;

import org.apache.oro.text.regex.Pattern;
import org.apache.oro.text.regex.Perl5Matcher;
import org.apache.oro.text.regex.Perl5Compiler;
import org.apache.oro.text.regex.MalformedPatternException;

import com.knowgate.misc.Gadgets;
import com.knowgate.debug.DebugFile;
import com.knowgate.storage.DataSource;
import com.knowgate.storage.Record;
import com.knowgate.storage.StorageException;
import com.knowgate.storage.Table;
import com.knowgate.clocial.UserAccount;
import com.knowgate.clocial.UserAccountAlias;

public class AuthorGuessing {

    private static Pattern[] aPat = null;
    private static int iPat = 0;

	/**
	 * Precompile regular expressions from AuthorsRegExp.cnf resource file
	 */
    private static void precompilePatterns() {
      if (aPat==null) {
    	if (DebugFile.trace) DebugFile.writeln("AbstractEntriesFetcher.init()");
        Perl5Compiler oP5c = new Perl5Compiler();
        String sLine = null;
        try {
     	  InputStream oIns = new AuthorGuessing().getClass().getResourceAsStream("AuthorsRegExp.cnf");
     	  if (null==oIns) throw new FileNotFoundException("AuthorsRegExp.cnf");
          BufferedReader oBr = new BufferedReader(new InputStreamReader(oIns));
          ArrayList<Pattern> oPats = new ArrayList<Pattern>(20);
          while ((sLine=oBr.readLine())!=null) {
            if (DebugFile.trace) DebugFile.writeln("compiling regular expression "+sLine);
            try {
              oPats.add(oP5c.compile(sLine, Perl5Compiler.CASE_INSENSITIVE_MASK));
            } catch (MalformedPatternException mpe) {
              if (DebugFile.trace) DebugFile.writeln("AbstractEntriesFetcher.init() Malformed URL pattern "+mpe.getMessage());
                throw new IllegalArgumentException("Malformed URL pattern "+mpe.getMessage());
            }
          } // wend
          oBr.close();
          oIns.close();
          if (oPats.size()>0) {
            aPat = oPats.toArray(new Pattern[oPats.size()]);
            iPat = aPat.length;
          }
        } catch (NullPointerException npe) {
          if (DebugFile.trace) DebugFile.writeln("AbstractEntriesFetcher.init() NullPointerException");
            throw new NullPointerException("NullPointerException");
        } catch (FileNotFoundException fnf) {
          if (DebugFile.trace) DebugFile.writeln("AbstractEntriesFetcher.init() FileNotFoundException "+fnf.getMessage());
            throw new NullPointerException("Could not load resource file "+fnf.getMessage());
        } catch (IOException ioe) {
          if (DebugFile.trace) DebugFile.writeln("AbstractEntriesFetcher.init() IOException "+ioe.getMessage());
            throw new IllegalArgumentException("IOException "+ioe.getMessage());
        }
      } // fi
    } // init

    /**
     * Try to extract author nickname from a URL
     */
    public static String extractAuthorFromURL(String sUrl) {
      if (DebugFile.trace) DebugFile.writeln("AbstractEntriesFetcher.matchesAuthor("+sUrl+")");
      String sInferedAuthor = null;
      Perl5Matcher oMtc = new Perl5Matcher();    
      precompilePatterns();
      for (int p=0; p<iPat; p++) {
        Pattern oPat = aPat[p];
    	if (DebugFile.trace) DebugFile.writeln("trying "+oPat.getPattern());
        if (oMtc.matches(sUrl, oPat)) {
    	    if (DebugFile.trace) DebugFile.writeln(sUrl+" matches "+oPat.getPattern());
          sInferedAuthor = Gadgets.left(oMtc.getMatch().group(1),100);
	  	  if (oPat.getPattern().startsWith("http://twitter\\x2Ecom") ||
              oPat.getPattern().startsWith("http://retwite\\x2E"))
            sInferedAuthor = "@" + sInferedAuthor;
          else
            sInferedAuthor = sInferedAuthor.replace('-',' ').replace('_',' ').replace('/',' ');
          if (DebugFile.trace) DebugFile.writeln("infered author is "+sInferedAuthor);
          break;
        } else {
    	    if (DebugFile.trace) DebugFile.writeln(sUrl+" does not match "+oPat.getPattern());
        }
      } // next
      return sInferedAuthor;
    } // extractAuthorFromURL

    public static Record lookupAuthor(DataSource oDts, String sAuthor, String sService)
      throws StorageException, InstantiationException {
      Record oAccount;
      String sGuAccount;
      if (null==sService)
        sGuAccount = UserAccountAlias.getUserAccountId(oDts, sAuthor);
      else
        sGuAccount = UserAccountAlias.getUserAccountId(oDts, sService, sAuthor);

      if (null==sGuAccount) {
        oAccount = null;
      } else {
    	try {
    	  oAccount = new UserAccount(oDts);
    	  Table oTbl = oDts.openTable(oAccount);
    	  oAccount = oTbl.load(sGuAccount);
    	  oTbl.close();
    	} catch (SQLException sqle) {
    	  throw new StorageException(sqle.getMessage(), sqle);
    	}
      }
      return oAccount;
    }

}

/*
  Copyright (C) 2009  Know Gate S.L. All rights reserved.
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

package com.knowgate.misc;

import java.io.IOException;
import java.io.InputStream;
import java.io.File;
import java.io.FileNotFoundException;

import java.util.ArrayList;
import java.util.HashMap;

import com.knowgate.misc.Gadgets;
import com.knowgate.misc.LINParser;

public class VCardParser {

	private ArrayList<HashMap<String,String>> aVCards;
	
	public VCardParser() {
		aVCards = new ArrayList<HashMap<String,String>>();
	}

	public int getVCardsCount() {
	  return aVCards.size();
	}

	public HashMap<String,String> vcard(int n) {
	  return aVCards.get(n);
	}

	public ArrayList<HashMap<String,String>> vcards() {
	  return aVCards;
	}
	
	private void parse(LINParser oLPrsr) {
		final int nLines = oLPrsr.getLineCount();
		HashMap<String,String> oVCard = null;

		aVCards.clear();

		for (int l=0; l<nLines; l++) {
			String sLine = oLPrsr.getLine(l);
			if (sLine.equalsIgnoreCase("BEGIN:VCARD")) {
				oVCard = new HashMap(19);				
			} else if(sLine.equalsIgnoreCase("END:VCARD")) {
				aVCards.add(oVCard);
			}	else {
				String[] aLine = Gadgets.split(sLine, ':');
				oVCard.put(aLine[0],aLine[1]);
			}
		} // next
	}
	
	public void parse(String sStr) throws NullPointerException {
		LINParser oLPrsr = new LINParser();
		oLPrsr.parseString(sStr);
		parse(oLPrsr);
	} // parse

	public void parse(File oFile)
		throws FileNotFoundException, IOException,NumberFormatException,
        ArrayIndexOutOfBoundsException,RuntimeException,
        NullPointerException,IllegalArgumentException {

		LINParser oLPrsr = new LINParser();
		oLPrsr.parseFile(oFile);
		parse(oLPrsr);
	} // parse

	public void parse(File oFile, String sCharSet)
		throws FileNotFoundException, IOException,NumberFormatException,
        ArrayIndexOutOfBoundsException,RuntimeException,
        NullPointerException,IllegalArgumentException {

		LINParser oLPrsr = new LINParser(sCharSet);
		oLPrsr.parseFile(oFile);
		parse(oLPrsr);
	} // parse

	public void parse(InputStream oStrm)
		throws FileNotFoundException, IOException,NumberFormatException,
        ArrayIndexOutOfBoundsException,RuntimeException,
        NullPointerException,IllegalArgumentException {

		LINParser oLPrsr = new LINParser();
		oLPrsr.parseStream(oStrm);
		parse(oLPrsr);
	} // parse

	public void parse(InputStream oStrm, String sCharSet)
		throws FileNotFoundException, IOException,NumberFormatException,
        ArrayIndexOutOfBoundsException,RuntimeException,
        NullPointerException,IllegalArgumentException {

		LINParser oLPrsr = new LINParser(sCharSet);
		oLPrsr.parseStream(oStrm);
		parse(oLPrsr);
	} // parse

}

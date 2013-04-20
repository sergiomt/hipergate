/*
  Copyright (C) 2009-2011  Know Gate S.L. All rights reserved.

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

package com.knowgate.forums;

/**
 * <p>NewsGroupJournal Page</p>
 * <p>This class must be pre-processed with JiBX and journal-def-jixb.xml</p>
 * @author Sergio Montoro Ten
 * @version 5.0
 */

public class NewsGroupJournalPage {

  private int limit;
  private String name;
  private String filter;
  private String inputfile;
  private String datafile;
  private String outputpattern;

  public NewsGroupJournalPage() {
    limit = 65535;
    name = filter = inputfile = datafile = outputpattern = null;
  }
  
  public int getLimit() { return limit; }
    	
  public String getName() { return name; }

  public String getFilter() { return filter; }

  public String getInputFilePath() { return inputfile; }

  public String getInputDataPath() { return datafile; }

  public String getOutputPattern() { return outputpattern; }
  
}

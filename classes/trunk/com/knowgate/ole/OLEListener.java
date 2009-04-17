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

package com.knowgate.ole;

import java.io.IOException;

import org.apache.poi.hpsf.PropertySetFactory;
import org.apache.poi.hpsf.SummaryInformation;
import org.apache.poi.hpsf.UnexpectedPropertySetTypeException;
import org.apache.poi.hpsf.MarkUnsupportedException;
import org.apache.poi.hpsf.NoPropertySetStreamException;

import org.apache.poi.poifs.eventfilesystem.POIFSReaderListener;
import org.apache.poi.poifs.eventfilesystem.POIFSReaderEvent;

import com.knowgate.debug.DebugFile;


/**
 * <p>Jakarta POI Listener Interface</p>
 * @author Sergio Montoro Ten
 * @version 1.0
 */

class OLEListener implements POIFSReaderListener
{
    SummaryInformation si;

    public OLEListener() {
      si = null;
    }

    public void processPOIFSReaderEvent(POIFSReaderEvent event)
    {
        try {
            si = (SummaryInformation) PropertySetFactory.create(event.getStream());
        }
        catch (MarkUnsupportedException ex) {
          if (DebugFile.trace) DebugFile.writeln("com.knowgate.ole.OLEListener MarkUnsupportedException " + event.getPath() + event.getName() + " " + ex.getMessage());
        }
        catch (NoPropertySetStreamException ex) {
          if (DebugFile.trace) DebugFile.writeln("com.knowgate.ole.OLEListener NoPropertySetStreamException " + event.getPath() + event.getName() + " " + ex.getMessage());
        }
        catch (IOException ex) {
          if (DebugFile.trace) DebugFile.writeln("com.knowgate.ole.OLEListener IOException " + event.getPath() + event.getName() + " " + ex.getMessage());
        }
    }

    public SummaryInformation getSummaryInformation() {
      return si;
    }
}

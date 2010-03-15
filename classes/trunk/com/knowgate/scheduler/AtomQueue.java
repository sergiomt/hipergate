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

package com.knowgate.scheduler;

import java.util.LinkedList;
import java.util.ListIterator;

import com.knowgate.dataobjs.DB;
import com.knowgate.debug.DebugFile;

/**
 * <p>Memory FIFO Queue for job atoms pending of processing</p>
 * @author Sergio Montoro Ten
 * @version 1.0
 */
public class AtomQueue extends LinkedList<Atom> {

  private int iMaxAtoms;
  private static final long serialVersionUID = 1l;
  
  /**
   * Create an empty queue with a maximum of 10000 atoms
   */
  public AtomQueue() {
    iMaxAtoms = 10000;
  }

  /**
   * Create an empty queue
   * @param iMaxSize Maximum number of atoms that the queue can mantain in memory
   */
  public AtomQueue(int iMaxSize) {
    iMaxAtoms = iMaxSize;
  }

  // ----------------------------------------------------------

  /**
   * @return Maximum number of atoms that the queue can mantain in memory
   */
  public int maxsize() {
    return iMaxAtoms;
  }

  // ----------------------------------------------------------

  /**
   * <p>Add an atom to the end of the queue</p>
   * @param oAtm Atom object to be added
   */

  public synchronized void push(Atom oAtm) {
    addLast(oAtm);
  }

  // ----------------------------------------------------------

  /**
   * <p>Pop first available atom from queue</p>
   */

  public synchronized Atom pop() {
	if (DebugFile.trace) {
	  DebugFile.writeln("Begin AtomQueue.pop()");
	  DebugFile.incIdent();
	}
    Atom oAtm;
    if (size()>0) {
      oAtm = (Atom) getFirst();
      removeFirst();
    } else {
      oAtm = null;
    }
	if (DebugFile.trace) {
	  DebugFile.decIdent();
	  if (oAtm==null)
	    DebugFile.writeln("End AtomQueue.pop() : null");
	  else
	    DebugFile.writeln("End AtomQueue.pop() : "+String.valueOf(oAtm.getInt(DB.pg_atom)));
	}
    return oAtm;
  } // pop

  // ----------------------------------------------------------

  /**
   * <p>Remove atoms from a given Job</p>
   * @param sGuJob String Job GUID
   * @return Count of atoms removed
   * @since 5.0
   */

  public synchronized int remove(String sGuJob) {  	
	if (DebugFile.trace) {
	  DebugFile.writeln("Begin AtomQueue.remove("+sGuJob+")");
	  DebugFile.incIdent();
	}

	int nRemoved = 0;
	
    ListIterator<Atom> oIter = listIterator();
    while (oIter.hasNext()) {
      Atom oAtm = oIter.next();
      if (oAtm.getString(DB.gu_job).equals(sGuJob)) {
      	oIter.remove();
      	nRemoved++;
      } // fi
    } // wend

	if (DebugFile.trace) {
	  DebugFile.decIdent();
	  DebugFile.writeln("End AtomQueue.remove() : "+String.valueOf(nRemoved));
	}

	return nRemoved;
  } // remove

} // AtomQueue
package com.knowgate.syndication.fetcher;

import java.io.IOException;
import java.io.ObjectInputStream;
import java.io.ObjectOutputStream;

import com.sleepycat.db.DatabaseEntry;

import com.sleepycat.util.FastInputStream;
import com.sleepycat.util.FastOutputStream;

import com.sleepycat.bind.serial.ClassCatalog;
import com.sleepycat.bind.serial.SerialBinding;
import com.sleepycat.bind.serial.StoredClassCatalog;
import com.sleepycat.bind.serial.SerialSerialBinding;

import com.sun.syndication.fetcher.impl.SyndFeedInfo;

public final class BDBSyndFeedInfoBinding extends SerialSerialBinding<String,byte[],SyndFeedInfo> {

	private static final Class CKEY = new String().getClass();
	private static final Class CDATA = new byte[1].getClass();
	
	public BDBSyndFeedInfoBinding(ClassCatalog oCtg, Class<String> cKey, Class<byte[]> cDat) {
		super(oCtg,cKey,cDat);
	} 

	public BDBSyndFeedInfoBinding(SerialBinding<String> oKey, SerialBinding<byte[]> oDat) {
		super(oKey,oDat);
	}

	public BDBSyndFeedInfoBinding(StoredClassCatalog oCtg) {
		super((ClassCatalog)oCtg,CKEY,CDATA);
	} 
	
	public SyndFeedInfo entryToObject(String sKey, byte[] aBytes) {
		SyndFeedInfo oEnt = null;
		try {
			FastInputStream oByIn = new FastInputStream(aBytes);
  			ObjectInputStream oObIn = new ObjectInputStream(oByIn);
  			oEnt = (SyndFeedInfo) oObIn.readObject();
  			oObIn.close();
  			oByIn.close();
		} catch (IOException xcpt) {
			String s = "";
			try { s = com.knowgate.debug.StackTraceUtil.getStackTrace(xcpt);
			} catch (Exception x) {}
			com.knowgate.debug.DebugFile.writeln("IOException "+xcpt.getMessage()+" "+s);
		} catch (ClassNotFoundException xcpt) {
			// ***
		}
  		return oEnt;
	}
	
	public String objectToKey(SyndFeedInfo oEnt) {
		return oEnt.getUrl().toString();
	}

	public byte[] objectToData(SyndFeedInfo oEnt) {
		byte[] aBytes = null;
		try {
			FastOutputStream oByOut = new FastOutputStream(4000);
  			ObjectOutputStream oObOut = new ObjectOutputStream(oByOut);
  			oObOut.writeObject(oEnt);  			
	  		aBytes = oByOut.toByteArray();
	  		oObOut.close();
			oByOut.close();
		} catch (IOException xcpt) {
			String s = "";
			try { s = com.knowgate.debug.StackTraceUtil.getStackTrace(xcpt);
			} catch (Exception x) {}
			com.knowgate.debug.DebugFile.writeln("IOException "+xcpt.getMessage()+" "+s);
		}
		return aBytes;
  	}	
  	
  	public SyndFeedInfo entryToObject(DatabaseEntry oKey, DatabaseEntry oDat) {
  		return entryToObject(new String(oKey.getData()), oDat.getData());
  	} 
 
}

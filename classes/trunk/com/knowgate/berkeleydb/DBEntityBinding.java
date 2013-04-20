package com.knowgate.berkeleydb;

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

import com.knowgate.debug.DebugFile;
import com.knowgate.debug.StackTraceUtil;

public final class DBEntityBinding extends SerialSerialBinding<String,byte[],DBEntity> {

	private static final Class CKEY = new String().getClass();
	private static final Class CDATA = new byte[1].getClass();
	
	public DBEntityBinding(ClassCatalog oCtg, Class<String> cKey, Class<byte[]> cDat) {
		super(oCtg,cKey,cDat);
	} 

	public DBEntityBinding(SerialBinding<String> oKey, SerialBinding<byte[]> oDat) {
		super(oKey,oDat);
	}

	public DBEntityBinding(StoredClassCatalog oCtg) {
		super((ClassCatalog)oCtg,CKEY,CDATA);
	} 
	
	public DBEntity entryToObject(String sKey, byte[] aBytes) {
		DBEntity oEnt = null;
		try {
			FastInputStream oByIn = new FastInputStream(aBytes);
  			ObjectInputStream oObIn = new ObjectInputStream(oByIn);
  			oEnt = (DBEntity) oObIn.readObject();
  			oObIn.close();
  			oByIn.close();
		} catch (IOException xcpt) {
			String s = "";
			try { s = StackTraceUtil.getStackTrace(xcpt); } catch (Exception x) {}
			if (DebugFile.trace) DebugFile.writeln("entryToObject("+sKey+", byte[]) IOException "+xcpt.getMessage()+" "+s);
		} catch (ClassNotFoundException xcpt) {
	 	  if (DebugFile.trace) DebugFile.writeln("entryToObject("+sKey+", byte[]) ClassNotFoundException "+xcpt.getMessage());
		}
  		return oEnt;
	}
	
	public String objectToKey(DBEntity oEnt) {
		return oEnt.getPrimaryKey();
	}

	public byte[] objectToData(DBEntity oEnt) {
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
			try { s = StackTraceUtil.getStackTrace(xcpt); } catch (Exception x) {}
			if (DebugFile.trace) DebugFile.writeln("IOException "+xcpt.getMessage()+"\n"+s);
		}
		return aBytes;
  	}	
  	
  	public DBEntity entryToObject(DatabaseEntry oKey, DatabaseEntry oDat) {
  		if (null==oKey)
  		  return entryToObject(null, oDat.getData());
  		else if (null==oKey.getData())
  		  return entryToObject(null, oDat.getData());
  		else
  		  return entryToObject(new String(oKey.getData()), oDat.getData());
  	} 
 
}

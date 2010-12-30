package com.knowgate.storage;

public enum Engine {

   BERKELYDB(1),
   MONGODB  (2);
   	   
   private final int iCode;

   Engine (int iEngineCode) {
     iCode = iEngineCode;
   }

   public String toString() {
   	return String.valueOf(iCode);
   }

   public final int intValue() {
   	return iCode;
   }

   public static final Engine DEFAULT = BERKELYDB;
}

package com.knowgate.clocial;

import java.io.IOException;
import java.io.FileNotFoundException;

import com.knowgate.dfs.FileSystem;
import com.knowgate.misc.Gadgets;

import com.knowgate.storage.Engine;
import com.knowgate.storage.RecordDelegator;

public class IPInfo extends RecordDelegator {

  private static final String tableName = "k_ip_info";

  private static final long serialVersionUID = Serials.Company;

  public IPInfo() {
  	super(Engine.DEFAULT,tableName,MetaData.getDefaultSchema().getColumns(tableName));
  }	

  public IPInfo(Engine eEngine) {
  	super(eEngine,tableName,MetaData.getDefaultSchema().getColumns(tableName));
  }	

  public static IPInfo forHost(Engine eEngine, String sIPAddress)
  	throws IOException,FileNotFoundException {
  	FileSystem oFs = new FileSystem();
  	String sInfoXML = null;
  	try {
  	  sInfoXML = oFs.readfilestr("http://api.hostip.info/?ip="+sIPAddress,"ISO8859_1");
  	} catch (java.net.MalformedURLException neverthrown) {}
  	  catch (com.enterprisedt.net.ftp.FTPException neverthrown) {}
    if (sInfoXML!=null) {
      IPInfo oIpInf = new IPInfo(eEngine);
      oIpInf.put("id_country", Gadgets.substrBetween(sInfoXML,"<countryAbbrev>","</countryAbbrev>").toLowerCase());
      oIpInf.put("nm_city",Gadgets.substrBetween(sInfoXML,"<gml:name>","</gml:name>"));
      if (sInfoXML.indexOf("<gml:Point srsName=")>0 && sInfoXML.indexOf("<gml:coordinates>")>0) {
        oIpInf.put("nm_point",Gadgets.substrBetween(sInfoXML,"<gml:Point srsName=\"","\">"));
        String sCoords = Gadgets.substrBetween(sInfoXML,"<gml:coordinates>","</gml:coordinates>");
        if (sCoords.length()>0) {
          String[] aCoords = Gadgets.split2(sCoords,','); 
          oIpInf.put("nu_coord1",new Float(aCoords[0]));
          oIpInf.put("nu_coord2",new Float(aCoords[1]));
        } // fi
      }
      return oIpInf;
    } else {
      return null;
    }
    
  }
}

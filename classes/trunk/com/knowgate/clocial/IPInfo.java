package com.knowgate.clocial;

import java.net.URL;
import java.net.InetAddress;
import java.net.UnknownHostException;
import java.net.MalformedURLException;

import java.io.IOException;
import java.io.FileNotFoundException;

import com.knowgate.debug.DebugFile;
import com.knowgate.dfs.FileSystem;
import com.knowgate.misc.Gadgets;

import com.knowgate.storage.Table;
import com.knowgate.storage.Manager;
import com.knowgate.storage.DataSource;
import com.knowgate.storage.RecordDelegator;

public class IPInfo extends RecordDelegator {

  private static final String tableName = "k_ip_info";

  private static final long serialVersionUID = Serials.IPInfo;

  public IPInfo(DataSource oDts) throws InstantiationException {
  	super(oDts,tableName);
  }	

  public static String getHostIPforUrl(String sUrl)
  	throws MalformedURLException,UnknownHostException {
  	String sIP = null;
  	URL oUrl = new URL(sUrl);
  	InetAddress[] aAdrs = InetAddress.getAllByName(oUrl.getHost());
  	if (aAdrs!=null) {
  	  if (aAdrs.length>0) {
  	  	sIP = aAdrs[0].getHostAddress();
  	  }
  	}
    if (DebugFile.trace) DebugFile.writeln("host ip for "+sUrl+" is "+sIP);
  	return sIP;
  }

  public static IPInfo forHost(DataSource oDts, String sIPAddress)
  	throws IOException,FileNotFoundException,InstantiationException  {
  	FileSystem oFs = new FileSystem();
  	String sInfoXML = null;
  	try {
  	  sInfoXML = oFs.readfilestr("http://api.hostip.info/?ip="+sIPAddress,"ISO8859_1");
  	} catch (java.net.MalformedURLException neverthrown) {}
  	  catch (com.enterprisedt.net.ftp.FTPException neverthrown) {}
    if (sInfoXML!=null) {
      IPInfo oIpInf = new IPInfo(oDts);
      oIpInf.put("ip_addr", sIPAddress);
      oIpInf.put("id_country", Gadgets.substrBetween(sInfoXML,"<countryAbbrev>","</countryAbbrev>").toLowerCase());
      oIpInf.put("nm_city",Gadgets.substrBetween(sInfoXML.substring(sInfoXML.indexOf("<Hostip>")),"<gml:name>","</gml:name>"));
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

  public static IPInfo forHost(Manager oStorMan, String sIPAddress) {
	IPInfo oIP = null;
	Table oTbl;
	DataSource oDts = null;
	try {
	  oDts = oStorMan.getDataSource();
	  oIP = new IPInfo(oDts);	  
	  oTbl = oDts.openTable(oIP);
	  boolean bAlreadyExists = oIP.load(oTbl, sIPAddress);
	  oTbl.close();
	  if (!bAlreadyExists) {
	  	oIP = forHost(oDts, sIPAddress);
	  	oStorMan.store(oIP, false);
	  }
	} catch (Exception xcpt) {
    } finally {
	  try { if (oDts!=null) oStorMan.free(oDts); } catch (Exception xcpt) {}
	}
	return oIP;
  }

  public static IPInfo forUrl(DataSource oDts, String sUrlAddress)
  	throws MalformedURLException, UnknownHostException, IOException, InstantiationException {
    if (DebugFile.trace) DebugFile.writeln("looking for info about "+sUrlAddress);
	String sIPAddress = getHostIPforUrl(sUrlAddress);
	IPInfo oIPi = null;
	if (null!=sIPAddress)
	  oIPi = forHost(oDts,sIPAddress);
    if (DebugFile.trace)
      if (oIPi==null)
        DebugFile.writeln("could not get IP address of "+sUrlAddress);
      else
        DebugFile.writeln("IP address of "+sUrlAddress+" is "+oIPi.getString("ip_addr"));      	
    return oIPi;
  }

}

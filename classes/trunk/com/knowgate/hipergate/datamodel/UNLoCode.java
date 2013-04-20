package com.knowgate.hipergate.datamodel;

import java.io.IOException;
import java.io.FileReader;
import java.io.FileWriter;
import java.io.LineNumberReader;

/**
 * UN/LOCODE loader
 * http://www.unece.org/etrades/download/downmain.htm#locode
 * @author Sergio Montoro Ten
 * @version 1.0
 */
public class UNLoCode {
  public UNLoCode() {
  }

  public static void generateSQLScript(String sInFile, String sOutFile, String sCountries)
    throws IOException {
    StringBuffer oCty = new StringBuffer(65000);
    String sLine, sCountryCode, sPlaceCode, sPlaceName, sPort, sRail, sRoad, sAirport, sPostal, sStatus, sIata, sLat, sLong;
    FileWriter oLC = new FileWriter(sOutFile);
    FileWriter oCC = new FileWriter(sCountries);
    FileReader oFR = new FileReader(sInFile);
    LineNumberReader oLR = new LineNumberReader(oFR);
    while ( null!= (sLine = oLR.readLine()) ) {
      sCountryCode = sLine.substring(3,5).toLowerCase();
      sPlaceCode = sLine.substring(6,9).toLowerCase();
      sPlaceName = sLine.substring(10,46).trim().replace((char)39,'´');
      if (sPlaceName.charAt(0)!='.') {
        sPort = (sLine.charAt(86)=='1' ? "1" : "0");
        sRail = (sLine.charAt(87)=='2' ? "1" : "0");
        sRoad = (sLine.charAt(88)=='3' ? "1" : "0");
        sAirport = (sLine.charAt(89)=='4' ? "1" : "0");
        sPostal = (sLine.charAt(90)=='5' ? "1" : "0");
        sStatus = sLine.substring(95,97).trim();
        sIata = sLine.substring(103,106).trim();
        if (sIata.length()>0)
          sIata = "'"+sIata+"'";
        else
          sIata = "null";
        sLat = sLine.substring(108,113).trim();
        if (sLat.length()>0)
          sLat = "'"+sLat+"'";
        else
          sLat = "null";
        sLong = sLine.substring(114,120).trim();
        if (sLong.length()>0)
          sLong = "'"+sLong+"'";
        else
          sLong = "null";
        oLC.write("INSERT INTO k_lu_unlocode (id_country,id_place,nm_place,bo_active,bo_port,bo_rail,bo_road,bo_airport,bo_postal,id_status,id_iata,coord_lat,coord_long) VALUES('"+sCountryCode+"','"+sPlaceCode+"','"+sPlaceName+"',1,"+sPort+","+sRail+","+sRoad+","+sAirport+","+sPostal+",'"+sStatus+"',"+sIata+","+sLat+","+sLong+");\n");
      } else {
        oCC.write(sCountryCode+" "+sPlaceName.substring(1)+"\n");
      }
    } // wend
    oLR.close();
    oFR.close();
    oCC.close();
    oLC.close();
  }
}

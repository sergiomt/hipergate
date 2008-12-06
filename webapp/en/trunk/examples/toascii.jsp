<%@ page import="java.io.IOException" language="java" session="false" contentType="text/html;charset=ISO-8859-1" %>
<%

  // *************************************************************************************
  // This codes reads a set of files encoded as UTF-8 and re-writes them as ISO-8859-1
  // using methods readfilestr() and writefilestr() from class com.knowgate.dfs.FileSystem

  // ****************************************************
  // Put here the base directory of files to be converted

  final String sBase = "/opt/knowgate/web-unicode/";

  // *******************************************************************
  // Put here the list of files to be converted from UTF-8 to ISO-8859-1

  String [] files = new String[]{"addrbook/adrbkhome.jsp","addrbook/editfellowtitle.jsp","addrbook/fellowtitle_delete.jsp" ...};

  // *****************************************
  // Actual encoding converting red/write loop

  com.knowgate.dfs.FileSystem oFS = new com.knowgate.dfs.FileSystem();

  String sFile;

  int iFiles = files.length;

  for (int f=0; f<iFiles; f++) {
    sFile = oFS.readfilestr(sBase+files[f], "UTF-8");
    oFS.writefilestr(sBase+files[f], sFile, "ISO-8859-1");
  }

%>
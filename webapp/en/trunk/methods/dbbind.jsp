<jsp:useBean id="GlobalDBBind" scope="application" class="com.knowgate.dataobjs.DBBind"/><% request.setCharacterEncoding("UTF-8"); %><%!

  // Always save this file as UNIX-ASCII or else some XML retrieval pages may raise de exception: declaraci�n de texto o XML en un lugar distinto del principio de la entidad
	
  public static void disposeConnection(com.knowgate.jdc.JDCConnection oConn, String sConnectionName)
    throws java.io.IOException {
    if (oConn!=null) {
      boolean bIsClosed = true;
      try { bIsClosed = oConn.isClosed(); }
        catch (Exception xcpt) {
          if (com.knowgate.debug.DebugFile.trace) {
            com.knowgate.debug.DebugFile.writeln("<JSP:dbbind.jsp "+xcpt.getClass().getName()+" "+xcpt.getMessage());
            com.knowgate.debug.DebugFile.writeln(com.knowgate.debug.StackTraceUtil.getStackTrace(xcpt));
          } // fi
        }
      if (!bIsClosed) {
        try {
          if (!oConn.getAutoCommit()) oConn.rollback();
        }
        catch (Exception xcpt) {
          if (com.knowgate.debug.DebugFile.trace) {
            com.knowgate.debug.DebugFile.writeln("<JSP:dbbind.jsp "+xcpt.getClass().getName()+" "+xcpt.getMessage());
            com.knowgate.debug.DebugFile.writeln(com.knowgate.debug.StackTraceUtil.getStackTrace(xcpt));
          } // fi
        }
        try {
          oConn.dispose(sConnectionName);
        }
        catch (Exception xcpt) {
          if (com.knowgate.debug.DebugFile.trace) {
            com.knowgate.debug.DebugFile.writeln("<JSP:dbbind.jsp "+xcpt.getClass().getName()+" "+xcpt.getMessage());
            com.knowgate.debug.DebugFile.writeln(com.knowgate.debug.StackTraceUtil.getStackTrace(xcpt));
          } // fi
        }
      } // fi (!isClosed)
    } // fi (!null)
  } // disposeConnection
%>
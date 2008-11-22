package com.knowgate.debug;

import java.io.Writer;
import java.io.StringWriter;
import java.io.PrintWriter;
import java.io.IOException;

/**
 * Simple utility to return the stack trace of an exception as a String.
 * @author John O'Hanley
 * @version 1.0
*/
public final class StackTraceUtil {

  public static String getStackTrace( Throwable aThrowable )
    throws IOException {
    final Writer result = new StringWriter();
    final PrintWriter printWriter = new PrintWriter( result );
    aThrowable.printStackTrace( printWriter );
    String sRetVal = result.toString();
    printWriter.close();
    result.close();
    return sRetVal;
  }
}

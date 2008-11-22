package com.knowgate.debug;

import java.io.IOException;
import java.io.PrintWriter;
import java.io.FileOutputStream;

/**
 * ErrorHandler.java
 * Created: Tue Feb  2 12:24:40 1999
 * @author Sebastian Schaffert
 * @version $Revision: 1.2 $
 */
public class ErrorHandler  {

    public ErrorHandler(Throwable ex) {
      PrintWriter oDebugWriter = null;
      FileOutputStream oDebugStrm = null;

      try {
        if (System.getProperty("os.name").startsWith("Windows"))
          oDebugStrm = new FileOutputStream("C:\\javatrc.txt", true);
        else
          oDebugStrm = new FileOutputStream("/tmp/javatrc.txt", true);

        oDebugWriter = new PrintWriter(oDebugStrm);

        ex.printStackTrace(oDebugWriter);

        if (null!=oDebugWriter) oDebugWriter.close();
        oDebugWriter = null;
        if (null!=oDebugStrm) oDebugStrm.close();
        oDebugStrm = null;

      }
      catch (IOException ioe) {
      }
    }

} // ErrorHandler

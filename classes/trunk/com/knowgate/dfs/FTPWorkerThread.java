package com.knowgate.dfs;

/**
 * <p>Direct piped copy from an FTP source to another FTP target.</p>
 * <p>This is an alpha state testing module.</p>
 * @author Sergio Montoro Ten
 * @version 0.3alpha
 */

import java.io.IOException;
import java.io.FileWriter;
import java.io.PrintWriter;
import java.io.PipedInputStream;
import java.io.PipedOutputStream;

import com.enterprisedt.net.ftp.FTPClient;
import com.enterprisedt.net.ftp.FTPException;
import com.enterprisedt.net.ftp.FTPTransferType;
import com.enterprisedt.net.ftp.FTPConnectMode;

import com.knowgate.debug.DebugFile;

public class FTPWorkerThread extends Thread {
  private FTPClient oFTPC;
  private boolean bLoged;
  private PipedOutputStream oOutPipe;
  private PipedInputStream oInPipe;
  private FileWriter oFW;
  private PrintWriter oPW;
  private int iCmd;
  private String sPar1;
  private FileSystem oFileSys;

  private int GET_PIPE = 16;
  private int PUT_PIPE = 32;
  private int MOV_PIPE = 64;

  public FTPWorkerThread(String sHost, String sUser, String sPassword) throws FTPException,IOException {
    bLoged = false;
    oFileSys = null;

    if (DebugFile.trace) DebugFile.writeln("new FTPClient(" + sHost + ")");

    oFTPC = new FTPClient(sHost);
    oFTPC.debugResponses(DebugFile.trace);

    if (DebugFile.trace) {
      oFW = new FileWriter("/tmp/javatrc.txt", true);
      oPW = new PrintWriter(oFW, true);
      oFTPC.setLogStream(oPW);
      DebugFile.writeln("FTPClient.login(" + sUser + "," + sPassword + ")");
    }

    oFTPC.login(sUser, sPassword);
    bLoged = true;

    oFTPC.setConnectMode(FTPConnectMode.ACTIVE);
    oFTPC.setType(FTPTransferType.BINARY);
  } // FTPWorkerThread()

  //-----------------------------------------------------------

  public PipedInputStream getInputPipe () throws IOException {
    return oInPipe;
  } // getInputPipe()

  //-----------------------------------------------------------

  public PipedOutputStream getOutputPipe () throws IOException {
    return oOutPipe;
  } // getOutputPipe()

  //-----------------------------------------------------------

  public void get (String sFile) throws IOException {
    oOutPipe = new PipedOutputStream();
    sPar1 = sFile;
    iCmd = GET_PIPE;
  }

  //-----------------------------------------------------------

  public void put (String sFile) throws IOException {
    oInPipe = new PipedInputStream();
    sPar1 = sFile;
    iCmd = PUT_PIPE;
  } // put()

  //-----------------------------------------------------------

  public void move (String sFile) throws IOException {
    oOutPipe = new PipedOutputStream();
    sPar1 = sFile;
    iCmd = MOV_PIPE;
  }

  //-----------------------------------------------------------

  public void connect (PipedInputStream oStrm) throws IOException {
    if (DebugFile.trace) DebugFile.writeln("FTPWorkerThread.connect([PipedInputStream])");
    oOutPipe.connect (oStrm);
  } // connect()

  //-----------------------------------------------------------

  public void connect (PipedOutputStream oStrm) throws IOException {
    if (DebugFile.trace) DebugFile.writeln("FTPWorkerThread.connect([PipedOutputStream])");
    oInPipe.connect (oStrm);
  } // connect()

  //-----------------------------------------------------------

  public void chdir (String sPath) throws FTPException,IOException {
    oFTPC.chdir(sPath);
  } // chdir()

  //-----------------------------------------------------------

  public void run() {
    try {
      if (GET_PIPE==iCmd) {
        if (DebugFile.trace) DebugFile.writeln("oFTPC.get([PipedOutputStream]," + sPar1 + ")");
        oFTPC.get(oOutPipe, sPar1);
        oFTPC.quit();
        bLoged=false;
      }
      else if (PUT_PIPE==iCmd) {
        if (DebugFile.trace) DebugFile.writeln("oFTPC.put([PipedInputStream]," + sPar1 + ")");
        oFTPC.put(oInPipe, sPar1);
        oFTPC.quit();
        bLoged=false;
      }
      else if (MOV_PIPE==iCmd) {
        if (DebugFile.trace) DebugFile.writeln("oFTPC.get([PipedOutputStream]," + sPar1 + ")");
        oFTPC.get(oOutPipe, sPar1);
        if (DebugFile.trace) DebugFile.writeln("oFTPC.delete([PipedOutputStream]," + sPar1 + ")");
        oFTPC.delete(sPar1);
        oFTPC.quit();
        bLoged=false;
      }
    }
    catch (FTPException ftpe) {
      if (DebugFile.trace) DebugFile.writeln("FTPException:" +  ftpe.getMessage());
    }
    catch (IOException ioe) {
      if (DebugFile.trace) DebugFile.writeln("IOException:" +  ioe.getMessage());
    }
  } // run()
} // FTPWorkerThread
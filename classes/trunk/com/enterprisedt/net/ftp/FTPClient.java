/**
 *
 *  Java FTP client library.
 *
 *  Copyright (C) 2000-2003  Enterprise Distributed Technologies Ltd
 *
 *  www.enterprisedt.com
 *
 *  This library is free software; you can redistribute it and/or
 *  modify it under the terms of the GNU Lesser General Public
 *  License as published by the Free Software Foundation; either
 *  version 2.1 of the License, or (at your option) any later version.
 *
 *  This library is distributed in the hope that it will be useful,
 *  but WITHOUT ANY WARRANTY; without even the implied warranty of
 *  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
 *  Lesser General Public License for more details.
 *
 *  You should have received a copy of the GNU Lesser General Public
 *  License along with this library; if not, write to the Free Software
 *  Foundation, Inc., 59 Temple Place, Suite 330, Boston, MA  02111-1307  USA
 *
 *  Bug fixes, suggestions and comments should be sent to bruce@enterprisedt.com
 *
 *  Change Log:
 *
 *        $Log: FTPClient.java,v $
 *        Revision 1.1.1.1  2005/06/23 15:23:01  smontoro
 *        hipergate backend
 *
 *        Revision 1.1  2004/02/07 03:15:20  hipergate
 *        v2.0 pre-alpha
 *
 *        Revision 1.6  2003/05/31 14:53:44  bruceb
 *        1.2.2 changes
 *
 *        Revision 1.5  2003/01/29 22:46:08  bruceb
 *        minor changes
 *
 *        Revision 1.4  2002/11/19 22:01:25  bruceb
 *        changes for 1.2
 *
 *        Revision 1.3  2001/10/09 20:53:46  bruceb
 *        Active mode changes
 *
 *        Revision 1.1  2001/10/05 14:42:03  bruceb
 *        moved from old project
 *
 */

package com.enterprisedt.net.ftp;

import java.io.IOException;
import java.io.LineNumberReader;
import java.io.InputStream;
import java.io.InputStreamReader;
import java.io.OutputStream;
import java.io.OutputStreamWriter;
import java.io.PrintWriter;
import java.io.BufferedWriter;
import java.io.FileWriter;
import java.io.DataInputStream;
import java.io.DataOutputStream;
import java.io.BufferedInputStream;
import java.io.BufferedOutputStream;
import java.io.ByteArrayOutputStream;
import java.io.FileOutputStream;
import java.io.FileInputStream;
import java.io.File;

import java.text.SimpleDateFormat;
import java.text.ParsePosition;

import java.net.InetAddress;
import java.util.Date;
import java.util.Vector;
import java.util.Properties;

/**
 *  Supports client-side FTP. Most common
 *  FTP operations are present in this class.
 *
 *  @author      Bruce Blackshaw
 *  @version     $Revision: 1.1.1.1 $
 *
 */
public class FTPClient {

    /**
     *  Revision control id
     */
    private static String cvsId = "@(#)$Id: FTPClient.java,v 1.1.1.1 2005/06/23 15:23:01 smontoro Exp $";

    /**
     *  Format to interpret MTDM timestamp
     */
    private SimpleDateFormat tsFormat =
        new SimpleDateFormat("yyyyMMddHHmmss");

    /**
     *  Socket responsible for controlling
     *  the connection
     */
    private FTPControlSocket control = null;

    /**
     *  Socket responsible for transferring
     *  the data
     */
    private FTPDataSocket data = null;

    /**
     *  Socket timeout for both data and control. In
     *  milliseconds
     */
    private int timeout = 0;

    /**
     *  Record of the transfer type - make the default ASCII
     */
    private FTPTransferType transferType = FTPTransferType.ASCII;

    /**
     *  Record of the connect mode - make the default PASV (as this was
     *  the original mode supported)
     */
    private FTPConnectMode connectMode = FTPConnectMode.PASV;

    /**
     *  Holds the last valid reply from the server on the control socket
     */
    private FTPReply lastValidReply;

    /**
     *  Constructor. Creates the control
     *  socket
     *
     *  @param   remoteHost  the remote hostname
     */
    public FTPClient(String remoteHost)
        throws IOException, FTPException {

        control = new FTPControlSocket(remoteHost, 
                                       FTPControlSocket.CONTROL_PORT,
                                       null, 0);
    }

    /**
     *  Constructor. Creates the control
     *  socket
     *
     *  @param   remoteHost  the remote hostname
     *  @param   controlPort  port for control stream
     */
    public FTPClient(String remoteHost, int controlPort)
        throws IOException, FTPException {

        control = new FTPControlSocket(remoteHost, controlPort, null, 0);
    }

    /**
     *  Constructor. Creates the control
     *  socket
     *
     *  @param   remoteAddr  the address of the
     *                       remote host
     */
    public FTPClient(InetAddress remoteAddr)
        throws IOException, FTPException {

        control = new FTPControlSocket(remoteAddr, 
                                       FTPControlSocket.CONTROL_PORT,
                                       null, 0);
    }

    /**
     *  Constructor. Creates the control
     *  socket. Allows setting of control port (normally
     *  set by default to 21).
     *
     *  @param   remoteAddr  the address of the
     *                       remote host
     *  @param   controlPort  port for control stream
     */
    public FTPClient(InetAddress remoteAddr, int controlPort)
        throws IOException, FTPException {

        control = new FTPControlSocket(remoteAddr, controlPort,
                                       null, 0);
    }

    /**
     *  Constructor. Creates the control
     *  socket
     *
     *  @param   remoteHost  the remote hostname
     *  @param  millis       the length of the timeout, in milliseconds
     */
    public FTPClient(String remoteHost, PrintWriter log, int timeout)
        throws IOException, FTPException {

        control = new FTPControlSocket(remoteHost, 
                                       FTPControlSocket.CONTROL_PORT,
                                       log, timeout);
    }

    /**
     *  Constructor. Creates the control
     *  socket
     *
     *  @param   remoteHost  the remote hostname
     *  @param   controlPort  port for control stream
     *  @param  millis       the length of the timeout, in milliseconds
     */
    public FTPClient(String remoteHost, int controlPort, 
                     PrintWriter log, int timeout)
        throws IOException, FTPException {

        control = new FTPControlSocket(remoteHost, controlPort,
                                       log, timeout);
    }

    /**
     *  Constructor. Creates the control
     *  socket
     *
     *  @param   remoteAddr  the address of the
     *                       remote host
     *  @param  millis       the length of the timeout, in milliseconds
     */
    public FTPClient(InetAddress remoteAddr, PrintWriter log, 
                     int timeout)
        throws IOException, FTPException {

        control = new FTPControlSocket(remoteAddr, 
                                       FTPControlSocket.CONTROL_PORT,
                                       log, timeout);
    }

    /**
     *  Constructor. Creates the control
     *  socket. Allows setting of control port (normally
     *  set by default to 21).
     *
     *  @param   remoteAddr  the address of the
     *                       remote host
     *  @param   controlPort port for control stream
     *  @param  millis       the length of the timeout, in milliseconds
     */
    public FTPClient(InetAddress remoteAddr, int controlPort, 
                     PrintWriter log, int timeout)
        throws IOException, FTPException {

        control = new FTPControlSocket(remoteAddr, controlPort, 
                                       log, timeout);
    }

    /**
     *   Set the TCP timeout on the underlying socket.
     *
     *   If a timeout is set, then any operation which
     *   takes longer than the timeout value will be
     *   killed with a java.io.InterruptedException. We
     *   set both the control and data connections
     *
     *   @param millis The length of the timeout, in milliseconds
     */
    public void setTimeout(int millis)
        throws IOException {

        this.timeout = millis;
        control.setTimeout(millis);
    }

    /**
     *  Set the connect mode
     *
     *  @param  mode  ACTIVE or PASV mode
     */
    public void setConnectMode(FTPConnectMode mode) {
        connectMode = mode;
    }

    /**
     *  Login into an account on the FTP server. This
     *  call completes the entire login process
     *
     *  @param   user       user name
     *  @param   password   user's password
     */
    public void login(String user, String password)
        throws IOException, FTPException {

        String response = control.sendCommand("USER " + user);
        lastValidReply = control.validateReply(response, "331");
        response = control.sendCommand("PASS " + password);
        lastValidReply = control.validateReply(response, "230");
    }


    /**
     *  Supply the user name to log into an account
     *  on the FTP server. Must be followed by the
     *  password() method - but we allow for
     *
     *  @param   user       user name
     *  @param   password   user's password
     */
    public void user(String user)
        throws IOException, FTPException {

        String reply = control.sendCommand("USER " + user);

        // we allow for a site with no password - 230 response
        String[] validCodes = {"230", "331"};
        lastValidReply = control.validateReply(reply, validCodes);
    }


    /**
     *  Supplies the password for a previously supplied
     *  username to log into the FTP server. Must be
     *  preceeded by the user() method
     *
     *  @param   user       user name
     *  @param   password   user's password
     */
    public void password(String password)
        throws IOException, FTPException {

        String reply = control.sendCommand("PASS " + password);

        // we allow for a site with no passwords (202)
        String[] validCodes = {"230", "202"};
        lastValidReply = control.validateReply(reply, validCodes);
    }

    /**
     *  Set up SOCKS v4/v5 proxy settings. This can be used if there
     *  is a SOCKS proxy server in place that must be connected thru.
     *  Note that setting these properties directs <b>all</b> TCP
     *  sockets in this JVM to the SOCKS proxy
     *
     *  @param  port  SOCKS proxy port
     *  @param  host  SOCKS proxy hostname
     */
    public static void initSOCKS(String port, String host) {
        Properties props = System.getProperties();
        props.put("socksProxyPort", port);
        props.put("socksProxyHost", host);
        System.setProperties(props);
    }

    /**
     *  Set up SOCKS username and password for SOCKS username/password
     *  authentication. Often, no authentication will be required
     *  but the SOCKS server may be configured to request these.
     *
     *  @param  username   the SOCKS username
     *  @param  password   the SOCKS password
     */
    public static void initSOCKSAuthentication(String username,
                                               String password) {
        Properties props = System.getProperties();
        props.put("java.net.socks.username", username);
        props.put("java.net.socks.password", password);
        System.setProperties(props);
    }

    /**
     *  Get the name of the remote host
     *
     *  @return  remote host name
     */
    String getRemoteHostName() {
        return control.getRemoteHostName();
    }


    /**
     *  Issue arbitrary ftp commands to the FTP server.
     *
     *  @param command     ftp command to be sent to server
     *  @param validCodes  valid return codes for this command
     */
    public void quote(String command, String[] validCodes)
        throws IOException, FTPException {

        String reply = control.sendCommand(command);

        // allow for no validation to be supplied
        if (validCodes != null && validCodes.length > 0)
            lastValidReply = control.validateReply(reply, validCodes);
    }


    /**
     *  Put a local file onto the FTP server. It
     *  is placed in the current directory.
     *
     *  @param  localPath   path of the local file
     *  @param  remoteFile  name of remote file in
     *                      current directory
     */
    public void put(String localPath, String remoteFile)
        throws IOException, FTPException {

        put(localPath, remoteFile, false);
    }

    /**
     *  Put a stream of data onto the FTP server. It
     *  is placed in the current directory.
     *
     *  @param  srcStream   input stream of data to put
     *  @param  remoteFile  name of remote file in
     *                      current directory
     */
    public void put(InputStream srcStream, String remoteFile)
        throws IOException, FTPException {

        put(srcStream, remoteFile, false);
    }


    /**
     *  Put a local file onto the FTP server. It
     *  is placed in the current directory. Allows appending
     *  if current file exists
     *
     *  @param  localPath   path of the local file
     *  @param  remoteFile  name of remote file in
     *                      current directory
     *  @param  append      true if appending, false otherwise
     */
    public void put(String localPath, String remoteFile,
                    boolean append)
        throws IOException, FTPException {

        // get according to set type
        if (getType() == FTPTransferType.ASCII) {
            putASCII(localPath, remoteFile, append);
        }
        else {
            putBinary(localPath, remoteFile, append);
        }
        validateTransfer();
     }

    /**
     *  Put a stream of data onto the FTP server. It
     *  is placed in the current directory. Allows appending
     *  if current file exists
     *
     *  @param  srcStream   input stream of data to put
     *  @param  remoteFile  name of remote file in
     *                      current directory
     *  @param  append      true if appending, false otherwise
     */
    public void put(InputStream srcStream, String remoteFile,
                    boolean append)
        throws IOException, FTPException {

        // get according to set type
        if (getType() == FTPTransferType.ASCII) {
            putASCII(srcStream, remoteFile, append);
        }
        else {
            putBinary(srcStream, remoteFile, append);
        }
        validateTransfer();
    }

    /**
     *  Validate that the put() or get() was successful
     */
    private void validateTransfer()
        throws IOException, FTPException {

        // check the control response
        String[] validCodes = {"226", "250"};
        String reply = control.readReply();
        lastValidReply = control.validateReply(reply, validCodes);
    }

    /**
     *  Request the server to set up the put
     *
     *  @param  remoteFile  name of remote file in
     *                      current directory
     *  @param  append      true if appending, false otherwise
     */
    private void initPut(String remoteFile, boolean append)
        throws IOException, FTPException {

        // set up data channel
        data = control.createDataSocket(connectMode);
        data.setTimeout(timeout);

        // send the command to store
        String cmd = append ? "APPE " : "STOR ";
        String reply = control.sendCommand(cmd + remoteFile);

        // Can get a 125 or a 150
        String[] validCodes = {"125", "150"};
        lastValidReply = control.validateReply(reply, validCodes);
    }


    /**
     *  Put as ASCII, i.e. read a line at a time and write
     *  inserting the correct FTP separator
     *
     *  @param localPath   full path of local file to read from
     *  @param remoteFile  name of remote file we are writing to
     *  @param  append      true if appending, false otherwise
     */
    private void putASCII(String localPath, String remoteFile, boolean append)
        throws IOException, FTPException {

        // create an inputstream & pass to common method
        InputStream srcStream = new FileInputStream(localPath);
        putASCII(srcStream, remoteFile, append);
    }

    /**
     *  Put as ASCII, i.e. read a line at a time and write
     *  inserting the correct FTP separator
     *
     *  @param  srcStream   input stream of data to put
     *  @param  remoteFile  name of remote file we are writing to
     *  @param  append      true if appending, false otherwise
     */
    private void putASCII(InputStream srcStream, String remoteFile,
                          boolean append)
        throws IOException, FTPException {

        // need to read line by line ...
        LineNumberReader in
            = new LineNumberReader(new InputStreamReader(srcStream));

        initPut(remoteFile, append);

        // get an character output stream to write to ... AFTER we
        // have the ok to go ahead AND AFTER we've successfully opened a
        // stream for the local file
        BufferedWriter out =
            new BufferedWriter(
                new OutputStreamWriter(data.getOutputStream()));

        // write line by line, writing \r\n as required by RFC959 after
        // each line
        String line = null;
        while ((line = in.readLine()) != null) {
            out.write(line, 0, line.length());
            out.write(FTPControlSocket.EOL, 0, FTPControlSocket.EOL.length());
        }
        in.close();
        out.flush();
        out.close();

        // and close the data socket
        try {
            data.close();
        }
        catch (IOException ignore) {}
    }


    /**
     *  Put as binary, i.e. read and write raw bytes
     *
     *  @param localPath   full path of local file to read from
     *  @param remoteFile  name of remote file we are writing to
     *  @param  append      true if appending, false otherwise
     */
    private void putBinary(String localPath, String remoteFile,
                           boolean append)
        throws IOException, FTPException {

        // open input stream to read source file ... do this
        // BEFORE opening output stream to server, so if file not
        // found, an exception is thrown
        InputStream srcStream = new FileInputStream(localPath);
        putBinary(srcStream, remoteFile, append);
    }

    /**
     *  Put as binary, i.e. read and write raw bytes
     *
     *  @param  srcStream   input stream of data to put
     *  @param  remoteFile  name of remote file we are writing to
     *  @param  append      true if appending, false otherwise
     */
    private void putBinary(InputStream srcStream, String remoteFile,
                           boolean append)
        throws IOException, FTPException {

        BufferedInputStream in =
            new BufferedInputStream(srcStream);

        initPut(remoteFile, append);

        // get an output stream
        BufferedOutputStream out =
            new BufferedOutputStream(
                new DataOutputStream(data.getOutputStream()));

        byte[] buf = new byte[512];

        // read a chunk at a time and write to the data socket
        long size = 0;
        int count = 0;
        while ((count = in.read(buf)) > 0) {
            out.write(buf, 0, count);
            size += count;
        }
        
        in.close();

        // flush and clean up
        out.flush();
        out.close();

        // and close the data socket
        try {
            data.close();
        }
        catch (IOException ignore) {}
        
		// log bytes transferred
		control.log("Transferred " + size + " bytes to remote host");
    }


    /**
     *  Put data onto the FTP server. It
     *  is placed in the current directory.
     *
     *  @param  data        array of bytes
     *  @param  remoteFile  name of remote file in
     *                      current directory
     */
    public void put(byte[] bytes, String remoteFile)
        throws IOException, FTPException {

        put(bytes, remoteFile, false);
    }

    /**
     *  Put data onto the FTP server. It
     *  is placed in the current directory. Allows
     *  appending if current file exists
     *
     *  @param  data        array of bytes
     *  @param  remoteFile  name of remote file in
     *                      current directory
     *  @param  append      true if appending, false otherwise
     */
    public void put(byte[] bytes, String remoteFile, boolean append)
        throws IOException, FTPException {

        initPut(remoteFile, append);

        // get an output stream
        BufferedOutputStream out =
            new BufferedOutputStream(
                new DataOutputStream(data.getOutputStream()));

        // write array
        out.write(bytes, 0, bytes.length);

        // flush and clean up
        out.flush();
        out.close();

        // and close the data socket
        try {
            data.close();
        }
        catch (IOException ignore) {}

        validateTransfer();
    }


    /**
     *  Get data from the FTP server. Uses the currently
     *  set transfer mode.
     *
     *  @param  localPath   local file to put data in
     *  @param  remoteFile  name of remote file in
     *                      current directory
     */
    public void get(String localPath, String remoteFile)
        throws IOException, FTPException {

        // get according to set type
        if (getType() == FTPTransferType.ASCII) {
            getASCII(localPath, remoteFile);
        }
        else {
            getBinary(localPath, remoteFile);
        }
        validateTransfer();
    }

    /**
     *  Get data from the FTP server. Uses the currently
     *  set transfer mode.
     *
     *  @param  destStream  data stream to write data to
     *  @param  remoteFile  name of remote file in
     *                      current directory
     */
    public void get(OutputStream destStream, String remoteFile)
        throws IOException, FTPException {

        // get according to set type
        if (getType() == FTPTransferType.ASCII) {
            getASCII(destStream, remoteFile);
        }
        else {
            getBinary(destStream, remoteFile);
        }
        validateTransfer();
    }


    /**
     *  Request to the server that the get is set up
     *
     *  @param  remoteFile  name of remote file
     */
    private void initGet(String remoteFile)
        throws IOException, FTPException {

        // set up data channel
        data = control.createDataSocket(connectMode);
        data.setTimeout(timeout);

        // send the retrieve command
        String reply = control.sendCommand("RETR " + remoteFile);

        // Can get a 125 or a 150
        String[] validCodes1 = {"125", "150"};
        lastValidReply = control.validateReply(reply, validCodes1);
    }


    /**
     *  Get as ASCII, i.e. read a line at a time and write
     *  using the correct newline separator for the OS
     *
     *  @param localPath   full path of local file to write to
     *  @param remoteFile  name of remote file
     */
    private void getASCII(String localPath, String remoteFile)
        throws IOException, FTPException {

        // B.McKeown:
        // Call initGet() before creating the FileOutputStream.
        // This will prevent being left with an empty file if a FTPException
        // is thrown by initGet().
        initGet(remoteFile);

        // B. McKeown: Need to store the local file name so the file can be
        // deleted if necessary.
        File localFile = new File(localPath);

        // create the buffered stream for writing
        BufferedWriter out =
            new BufferedWriter(
                new FileWriter(localPath));

        // get an character input stream to read data from ... AFTER we
        // have the ok to go ahead AND AFTER we've successfully opened a
        // stream for the local file
        LineNumberReader in =
            new LineNumberReader(
                new InputStreamReader(data.getInputStream()));

        // B. McKeown:
        // If we are in active mode we have to set the timeout of the passive
        // socket. We can achieve this by calling setTimeout() again.
        // If we are in passive mode then we are merely setting the value twice
        // which does no harm anyway. Doing this simplifies any logic changes.
        data.setTimeout(timeout);

        // read/write a line at a time
        IOException storedEx = null;
        String line = null;
        try {
            while ((line = in.readLine()) != null) {
                out.write(line, 0, line.length());
                out.newLine();
            }
        }
        catch (IOException ex) {
            storedEx = ex;
            localFile.delete();
        }
        finally {
            out.close();
        }

        try {
            in.close();
            data.close();
        }
        catch (IOException ignore) {}

        // if we failed to write the file, rethrow the exception
        if (storedEx != null)
            throw storedEx;
    }

    /**
     *  Get as ASCII, i.e. read a line at a time and write
     *  using the correct newline separator for the OS
     *
     *  @param destStream  data stream to write data to
     *  @param remoteFile  name of remote file
     */
    private void getASCII(OutputStream destStream, String remoteFile)
        throws IOException, FTPException {

        initGet(remoteFile);

        // create the buffered stream for writing
        BufferedWriter out =
            new BufferedWriter(
                new OutputStreamWriter(destStream));

        // get an character input stream to read data from ... AFTER we
        // have the ok to go ahead
        LineNumberReader in =
            new LineNumberReader(
                new InputStreamReader(data.getInputStream()));

        // B. McKeown:
        // If we are in active mode we have to set the timeout of the passive
        // socket. We can achieve this by calling setTimeout() again.
        // If we are in passive mode then we are merely setting the value twice
        // which does no harm anyway. Doing this simplifies any logic changes.
        data.setTimeout(timeout);

        // read/write a line at a time
        IOException storedEx = null;
        String line = null;
        try {
            while ((line = in.readLine()) != null) {
                out.write(line, 0, line.length());
                out.newLine();
            }
        }
        catch (IOException ex) {
            storedEx = ex;
        }
        finally {
            out.close();
        }

        try {
            in.close();
            data.close();
        }
        catch (IOException ignore) {}

        // if we failed to write the file, rethrow the exception
        if (storedEx != null)
            throw storedEx;
    }


    /**
     *  Get as binary file, i.e. straight transfer of data
     *
     *  @param localPath   full path of local file to write to
     *  @param remoteFile  name of remote file
     */
    private void getBinary(String localPath, String remoteFile)
        throws IOException, FTPException {

        // B.McKeown:
        // Call initGet() before creating the FileOutputStream.
        // This will prevent being left with an empty file if a FTPException
        // is thrown by initGet().
        initGet(remoteFile);

        // B. McKeown: Need to store the local file name so the file can be
        // deleted if necessary.
        File localFile = new File(localPath);

        // create the buffered output stream for writing the file
        BufferedOutputStream out =
            new BufferedOutputStream(
                new FileOutputStream(localPath, false));

        // get an input stream to read data from ... AFTER we have
        // the ok to go ahead AND AFTER we've successfully opened a
        // stream for the local file
        BufferedInputStream in =
            new BufferedInputStream(
                new DataInputStream(data.getInputStream()));

        // B. McKeown:
        // If we are in active mode we have to set the timeout of the passive
        // socket. We can achieve this by calling setTimeout() again.
        // If we are in passive mode then we are merely setting the value twice
        // which does no harm anyway. Doing this simplifies any logic changes.
        data.setTimeout(timeout);

        // do the retrieving
        long size = 0;
        int chunksize = 4096;
        byte [] chunk = new byte[chunksize];
        int count;
        IOException storedEx = null;

        // read from socket & write to file in chunks
        try {
            while ((count = in.read(chunk, 0, chunksize)) >= 0) {
                out.write(chunk, 0, count);
                size += count;
            }
        }
        catch (IOException ex) {
            storedEx = ex;
            localFile.delete();
        }
        finally {
            out.close();
        }

        // close streams
        try {
            in.close();
            data.close();
        }
        catch (IOException ignore) {}

        // if we failed to write the file, rethrow the exception
        if (storedEx != null)
            throw storedEx;
            
	    // log bytes transferred
    	control.log("Transferred " + size + " bytes from remote host");
    }

    /**
     *  Get as binary file, i.e. straight transfer of data
     *
     *  @param destStream  stream to write to
     *  @param remoteFile  name of remote file
     */
    private void getBinary(OutputStream destStream, String remoteFile)
        throws IOException, FTPException {

        initGet(remoteFile);

        // create the buffered output stream for writing the file
        BufferedOutputStream out =
            new BufferedOutputStream(destStream);

        // get an input stream to read data from ... AFTER we have
        // the ok to go ahead AND AFTER we've successfully opened a
        // stream for the local file
        BufferedInputStream in =
            new BufferedInputStream(
                new DataInputStream(data.getInputStream()));

        // B. McKeown:
        // If we are in active mode we have to set the timeout of the passive
        // socket. We can achieve this by calling setTimeout() again.
        // If we are in passive mode then we are merely setting the value twice
        // which does no harm anyway. Doing this simplifies any logic changes.
        data.setTimeout(timeout);

        // do the retrieving
		long size = 0;
        int chunksize = 4096;
        byte [] chunk = new byte[chunksize];
        int count;
        IOException storedEx = null;

        // read from socket & write to file in chunks
        try {
            while ((count = in.read(chunk, 0, chunksize)) >= 0) {
                out.write(chunk, 0, count);
				size += count;
            }
        }
        catch (IOException ex) {
            storedEx = ex;
        }
        finally {
            out.close();
        }

        // close streams
        try {
            in.close();
            data.close();
        }
        catch (IOException ignore) {}

        // if we failed to write to the stream, rethrow the exception
        if (storedEx != null)
            throw storedEx;
            
		// log bytes transferred
		control.log("Transferred " + size + " bytes from remote host");            
    }


    /**
     *  Get data from the FTP server. Transfers in
     *  whatever mode we are in. Retrieve as a byte array. Note
     *  that we may experience memory limitations as the
     *  entire file must be held in memory at one time.
     *
     *  @param  remoteFile  name of remote file in
     *                      current directory
     */
    public byte[] get(String remoteFile)
        throws IOException, FTPException {

        initGet(remoteFile);

        // get an input stream to read data from
        BufferedInputStream in =
            new BufferedInputStream(
                new DataInputStream(data.getInputStream()));

        // B. McKeown:
        // If we are in active mode we have to set the timeout of the passive
        // socket. We can achieve this by calling setTimeout() again.
        // If we are in passive mode then we are merely setting the value twice
        // which does no harm anyway. Doing this simplifies any logic changes.
        data.setTimeout(timeout);

        // do the retrieving
        int chunksize = 4096;
        byte [] chunk = new byte[chunksize];  // read chunks into
        byte [] resultBuf = null; // where we place result
        ByteArrayOutputStream temp =
            new ByteArrayOutputStream(chunksize); // temp swap buffer
        int count;  // size of chunk read

        // read from socket & write to file
        while ((count = in.read(chunk, 0, chunksize)) >= 0) {
            temp.write(chunk, 0, count);
        }
        temp.close();

        // get the bytes from the temp buffer
        resultBuf = temp.toByteArray();

        // close streams
        try {
            in.close();
            data.close();
        }
        catch (IOException ignore) {}
        
        validateTransfer();

        return resultBuf;
    }


    /**
     *  Run a site-specific command on the
     *  server. Support for commands is dependent
     *  on the server
     *
     *  @param  command   the site command to run
     *  @return true if command ok, false if
     *          command not implemented
     */
    public boolean site(String command)
        throws IOException, FTPException {

        // send the retrieve command
        String reply = control.sendCommand("SITE " + command);

        // Can get a 200 (ok) or 202 (not impl). Some
        // FTP servers return 502 (not impl)
        String[] validCodes = {"200", "202", "502"};
        lastValidReply = control.validateReply(reply, validCodes);

        // return true or false? 200 is ok, 202/502 not
        // implemented
        if (reply.substring(0, 3).equals("200"))
            return true;
        else
            return false;
    }


    /**
     *  List a directory's contents
     *
     *  @param  dirname  the name of the directory (<b>not</b> a file mask)
     *  @return a string containing the line separated
     *          directory listing
     *  @deprecated  As of FTP 1.1, replaced by {@link #dir(String)}
     */
    public String list(String dirname)
        throws IOException, FTPException {

        return list(dirname, false);
    }


    /**
     *  List a directory's contents as one string. A detailed
     *  listing is available, otherwise just filenames are provided.
     *  The detailed listing varies in details depending on OS and
     *  FTP server.
     *
     *  @param  dirname  the name of the directory(<b>not</b> a file mask)
     *  @param  full     true if detailed listing required
     *                   false otherwise
     *  @return a string containing the line separated
     *          directory listing
     *  @deprecated  As of FTP 1.1, replaced by {@link #dir(String,boolean)}
     */
    public String list(String dirname, boolean full)
        throws IOException, FTPException {

        String[] list = dir(dirname, full);

        StringBuffer result = new StringBuffer();
        String sep = System.getProperty("line.separator");

        // loop thru results and make into one string
        for (int i = 0; i < list.length; i++) {
            result.append(list[i]);
            result.append(sep);
        }

        return result.toString();
    }

    /**
     *  List current directory's contents as an array of strings of
     *  filenames.
     *
     *  @return  an array of current directory listing strings
     */
    public String[] dir()
        throws IOException, FTPException {

        return dir(null, false);
    }

    /**
     *  List a directory's contents as an array of strings of filenames.
     *
     *  @param   dirname  name of directory(<b>not</b> a file mask)
     *  @return  an array of directory listing strings
     */
    public String[] dir(String dirname)
        throws IOException, FTPException {

        return dir(dirname, false);
    }


    /**
     *  List a directory's contents as an array of strings. A detailed
     *  listing is available, otherwise just filenames are provided.
     *  The detailed listing varies in details depending on OS and
     *  FTP server. Note that a full listing can be used on a file
     *  name to obtain information about a file
     *
     *  @param  dirname  name of directory (<b>not</b> a file mask)
     *  @param  full     true if detailed listing required
     *                   false otherwise
     *  @return  an array of directory listing strings
     */
    public String[] dir(String dirname, boolean full)
        throws IOException, FTPException {

        // set up data channel
        data = control.createDataSocket(connectMode);
        data.setTimeout(timeout);

        // send the retrieve command
        String command = full ? "LIST ":"NLST ";
        if (dirname != null)
            command += dirname;

        // some FTP servers bomb out if NLST has whitespace appended
        command = command.trim();
        String reply = control.sendCommand(command);

        // check the control response. wu-ftp returns 550 if the
        // directory is empty, so we handle 550 appropriately. Similarly
        // proFTPD returns 450 
        String[] validCodes1 = {"125", "150", "450", "550"};
        lastValidReply = control.validateReply(reply, validCodes1);  

        // an empty array of files for 450/550
        String[] result = new String[0];

        // a normal reply ... extract the file list
        String replyCode = lastValidReply.getReplyCode();
        if (!replyCode.equals("450") && !replyCode.equals("550")) {
            // get an character input stream to read data from .
            LineNumberReader in =
                new LineNumberReader(
                     new InputStreamReader(data.getInputStream()));

            // read a line at a time
            Vector lines = new Vector();    
            String line = null;
            while ((line = in.readLine()) != null) {
                lines.add(line);
            }        
            try {
                in.close();
                data.close();
            }
            catch (IOException ignore) {}
                
            // check the control response
            String[] validCodes2 = {"226", "250"};
            reply = control.readReply();
            lastValidReply = control.validateReply(reply, validCodes2);

            // empty array is default
            if (!lines.isEmpty())
                result = (String[])lines.toArray(result);
        }
        return result;
    }

    /**
     *  Gets the latest valid reply from the server
     *
     *  @return  reply object encapsulating last valid server response
     */
    public FTPReply getLastValidReply() {
        return lastValidReply;
    }


    /**
     *  Switch debug of responses on or off
     *
     *  @param  on  true if you wish to have responses to
     *              the log stream, false otherwise
     */
    public void debugResponses(boolean on) {
        control.debugResponses(on);
    }

     /**
      *  Set the logging stream, replacing
      *  stdout
      *
      *  @param log  the new logging stream
      */
     public void setLogStream(PrintWriter log) {
         control.setLogStream(log);         
     }

    /**
     *  Get the current transfer type
     *
     *  @return  the current type of the transfer,
     *           i.e. BINARY or ASCII
     */
    public FTPTransferType getType() {
        return transferType;
    }

    /**
     *  Set the transfer type
     *
     *  @param  type  the transfer type to
     *                set the server to
     */
    public void setType(FTPTransferType type)
        throws IOException, FTPException {

        // determine the character to send
        String typeStr = FTPTransferType.ASCII_CHAR;
        if (type.equals(FTPTransferType.BINARY))
            typeStr = FTPTransferType.BINARY_CHAR;

        // send the command
        String reply = control.sendCommand("TYPE " + typeStr);
        lastValidReply = control.validateReply(reply, "200");

        // record the type
        transferType = type;
    }


    /**
     *  Delete the specified remote file
     *
     *  @param  remoteFile  name of remote file to
     *                      delete
     */
    public void delete(String remoteFile)
        throws IOException, FTPException {

        String reply = control.sendCommand("DELE " + remoteFile);
        lastValidReply = control.validateReply(reply, "250");
    }


    /**
     *  Rename a file or directory
     *
     * @param from  name of file or directory to rename
     * @param to    intended name
     */
    public void rename(String from, String to)
        throws IOException, FTPException {

        String reply = control.sendCommand("RNFR " + from);
        lastValidReply = control.validateReply(reply, "350");

        reply = control.sendCommand("RNTO " + to);
        lastValidReply = control.validateReply(reply, "250");
    }


    /**
     *  Delete the specified remote working directory
     *
     *  @param  dir  name of remote directory to
     *               delete
     */
    public void rmdir(String dir)
        throws IOException, FTPException {

        String reply = control.sendCommand("RMD " + dir);

        // some servers return 257, technically incorrect but
        // we cater for it ...
        String[] validCodes = {"250", "257"};
        lastValidReply = control.validateReply(reply, validCodes);
    }


    /**
     *  Create the specified remote working directory
     *
     *  @param  dir  name of remote directory to
     *               create
     */
    public void mkdir(String dir)
        throws IOException, FTPException {

        String reply = control.sendCommand("MKD " + dir);
        lastValidReply = control.validateReply(reply, "257");
    }


    /**
     *  Change the remote working directory to
     *  that supplied
     *
     *  @param  dir  name of remote directory to
     *               change to
     */
    public void chdir(String dir)
        throws IOException, FTPException {

        String reply = control.sendCommand("CWD " + dir);
        lastValidReply = control.validateReply(reply, "250");
    }

    /**
     *  Get modification time for a remote file
     *
     *  @param    remoteFile   name of remote file
     *  @return   modification time of file as a date
     */
    public Date modtime(String remoteFile)
        throws IOException, FTPException {

        String reply = control.sendCommand("MDTM " + remoteFile);
        lastValidReply = control.validateReply(reply, "213");

        // parse the reply string ...
        Date ts = tsFormat.parse(lastValidReply.getReplyText(),
                                 new ParsePosition(0));
        return ts;
    }

    /**
     *  Get the current remote working directory
     *
     *  @return   the current working directory
     */
    public String pwd()
        throws IOException, FTPException {

        String reply = control.sendCommand("PWD");
        lastValidReply = control.validateReply(reply, "257");

        // get the reply text and extract the dir
        // listed in quotes, if we can find it. Otherwise
        // just return the whole reply string
        String text = lastValidReply.getReplyText();
        int start = text.indexOf('"');
        int end = text.lastIndexOf('"');
        if (start >= 0 && end > start)
            return text.substring(start+1, end);
        else
            return text;
    }

    /**
     *  Get the type of the OS at the server
     *
     *  @return   the type of server OS
     */
    public String system()
        throws IOException, FTPException {

        String reply = control.sendCommand("SYST");
        lastValidReply = control.validateReply(reply, "215");
        return lastValidReply.getReplyText();
    }

    /**
     *  Get the help text for the specified command
     *
     *  @param  command  name of the command to get help on
     *  @return help text from the server for the supplied command
     */
    public String help(String command)
        throws IOException, FTPException {

        String reply = control.sendCommand("HELP " + command);
        String[] validCodes = {"211", "214"};
        lastValidReply = control.validateReply(reply, validCodes);
        return lastValidReply.getReplyText();
    }

    /**
     *  Quit the FTP session
     *
     */
    public void quit()
        throws IOException, FTPException {

        try {
            String reply = control.sendCommand("QUIT");
            String[] validCodes = {"221", "226"};
            lastValidReply = control.validateReply(reply, validCodes);
        }
        finally { // ensure we clean up the connection
            control.logout();
            control = null;
        }
    }

}




// Copyright (C) 1998-2001 by Jason Hunter <jhunter_AT_acm_DOT_org>.
// All rights reserved.  Use of this class is limited.
// Please see the LICENSE for more information.

package com.oreilly.servlet;

import java.io.*;
import java.util.*;
import javax.servlet.*;
import javax.servlet.http.*;

import java.util.Enumeration;
import java.util.Map;

import java.security.Principal;

import com.oreilly.servlet.multipart.MultipartParser;
import com.oreilly.servlet.multipart.Part;
import com.oreilly.servlet.multipart.FilePart;
import com.oreilly.servlet.multipart.ParamPart;
import com.oreilly.servlet.multipart.FileRenamePolicy;

/**
 * A utility class to handle <code>multipart/form-data</code> requests,
 * the kind of requests that support file uploads.  This class emulates the
 * interface of <code>HttpServletRequest</code>, making it familiar to use.
 * It uses a "push" model where any incoming files are read and saved directly
 * to disk in the constructor. If you wish to have more flexibility, e.g.
 * write the files to a database, use the "pull" model
 * <code>MultipartParser</code> instead.
 * <p>
 * This class can receive arbitrarily large files (up to an artificial limit
 * you can set), and fairly efficiently too.
 * It cannot handle nested data (multipart content within multipart content).
 * It <b>can</b> now with the latest release handle internationalized content
 * (such as non Latin-1 filenames).
 * <p>
 * To avoid collisions and have fine control over file placement, there's a
 * constructor variety that takes a pluggable FileRenamePolicy implementation.
 * A particular policy can choose to rename or change the location of the file
 * before it's written.
 * <p>
 * See the included upload.war for an example of how to use this class.
 * <p>
 * The full file upload specification is contained in experimental RFC 1867,
 * available at <a href="http://www.ietf.org/rfc/rfc1867.txt">
 * http://www.ietf.org/rfc/rfc1867.txt</a>.
 *
 * @see MultipartParser
 *
 * @author Jason Hunter
 * @author Geoff Soutter
 * @version 1.11, 2002/11/01, combine query string params in param list<br>
 * @version 1.10, 2002/05/27, added access to the original file names<br>
 * @version 1.9, 2002/04/30, added support for file renaming, thanks to
 *                           Changshin Lee<br>
 * @version 1.8, 2002/04/30, added support for internationalization, thanks to
 *                           Changshin Lee<br>
 * @version 1.7, 2001/02/07, made fields protected to increase user flexibility<br>
 * @version 1.6, 2000/07/21, redid internals to use MultipartParser,
 *                           thanks to Geoff Soutter<br>
 * @version 1.5, 2000/02/04, added auto MacBinary decoding for IE on Mac<br>
 * @version 1.4, 2000/01/05, added getParameterValues(),
 *                           WebSphere 2.x getContentType() workaround,
 *                           stopped writing empty "unknown" file<br>
 * @version 1.3, 1999/12/28, IE4 on Win98 lastIndexOf("boundary=")
 * workaround<br>
 * @version 1.2, 1999/12/20, IE4 on Mac readNextPart() workaround<br>
 * @version 1.1, 1999/01/15, JSDK readLine() bug workaround<br>
 * @version 1.0, 1998/09/18<br>
 */
public class MultipartRequest implements HttpServletRequest {

  private static final int DEFAULT_MAX_POST_SIZE = 1024 * 1024;  // 1 Meg

  protected Hashtable parameters = new Hashtable();  // name - Vector of values
  protected Hashtable files = new Hashtable();       // name - UploadedFile
  protected Cookie[] cookies;
  protected Locale requestlocale;
  protected String sessionid;
  protected String encoding;
  protected String servletpath;
  protected String requesturi;
  protected String remoteuser;
  protected String querystr;
  protected String ctxpath;
  protected String trnpath;
  protected String pathinfo;
  protected String formmethod;
  protected String contenttype;
  protected int contentlength;
  protected StringBuffer requesturl;
  protected String savedir;
  protected boolean bRequestedSessionIdFromURL;
  protected boolean bRequestedSessionIdFromCookie;
  protected boolean bRequestedSessionIdValid;

  /**
   * Constructs a new MultipartRequest to handle the specified request,
   * saving any uploaded files to the given directory, and limiting the
   * upload size to 1 Megabyte.  If the content is too large, an
   * IOException is thrown.  This constructor actually parses the
   * <tt>multipart/form-data</tt> and throws an IOException if there's any
   * problem reading or parsing the request.
   *
   * @param request the servlet request.
   * @param saveDirectory the directory in which to save any uploaded files.
   * @exception IOException if the uploaded content is larger than 1 Megabyte
   * or there's a problem reading or parsing the request.
   */
  public MultipartRequest(HttpServletRequest request,
                          String saveDirectory) throws IOException {
    this(request, saveDirectory, DEFAULT_MAX_POST_SIZE);
  }

  /**
   * Constructs a new MultipartRequest to handle the specified request,
   * saving any uploaded files to the given directory, and limiting the
   * upload size to the specified length.  If the content is too large, an
   * IOException is thrown.  This constructor actually parses the
   * <tt>multipart/form-data</tt> and throws an IOException if there's any
   * problem reading or parsing the request.
   *
   * @param request the servlet request.
   * @param saveDirectory the directory in which to save any uploaded files.
   * @param maxPostSize the maximum size of the POST content.
   * @exception IOException if the uploaded content is larger than
   * <tt>maxPostSize</tt> or there's a problem reading or parsing the request.
   */
  public MultipartRequest(HttpServletRequest request,
                          String saveDirectory,
                          int maxPostSize) throws IOException {
    this(request, saveDirectory, maxPostSize, null, null);
  }

  /**
   * Constructs a new MultipartRequest to handle the specified request,
   * saving any uploaded files to the given directory, and limiting the
   * upload size to the specified length.  If the content is too large, an
   * IOException is thrown.  This constructor actually parses the
   * <tt>multipart/form-data</tt> and throws an IOException if there's any
   * problem reading or parsing the request.
   *
   * @param request the servlet request.
   * @param saveDirectory the directory in which to save any uploaded files.
   * @param encoding the encoding of the response, such as ISO-8859-1
   * @exception IOException if the uploaded content is larger than
   * 1 Megabyte or there's a problem reading or parsing the request.
   */
  public MultipartRequest(HttpServletRequest request,
                          String saveDirectory,
                          String encoding) throws IOException {
    this(request, saveDirectory, DEFAULT_MAX_POST_SIZE, encoding, null);
  }

  /**
   * Constructs a new MultipartRequest to handle the specified request,
   * saving any uploaded files to the given directory, and limiting the
   * upload size to the specified length.  If the content is too large, an
   * IOException is thrown.  This constructor actually parses the
   * <tt>multipart/form-data</tt> and throws an IOException if there's any
   * problem reading or parsing the request.
   *
   * @param request the servlet request.
   * @param saveDirectory the directory in which to save any uploaded files.
   * @param maxPostSize the maximum size of the POST content.
   * @param encoding the encoding of the response, such as ISO-8859-1
   * @exception IOException if the uploaded content is larger than
   * <tt>maxPostSize</tt> or there's a problem reading or parsing the request.
   */
  public MultipartRequest(HttpServletRequest request,
                          String saveDirectory,
                          int maxPostSize,
                          FileRenamePolicy policy) throws IOException {
    this(request, saveDirectory, maxPostSize, null, policy);
  }

  /**
   * Constructs a new MultipartRequest to handle the specified request,
   * saving any uploaded files to the given directory, and limiting the
   * upload size to the specified length.  If the content is too large, an
   * IOException is thrown.  This constructor actually parses the
   * <tt>multipart/form-data</tt> and throws an IOException if there's any
   * problem reading or parsing the request.
   *
   * @param request the servlet request.
   * @param saveDirectory the directory in which to save any uploaded files.
   * @param maxPostSize the maximum size of the POST content.
   * @param encoding the encoding of the response, such as ISO-8859-1
   * @exception IOException if the uploaded content is larger than
   * <tt>maxPostSize</tt> or there's a problem reading or parsing the request.
   */
  public MultipartRequest(HttpServletRequest request,
                          String saveDirectory,
                          int maxPostSize,
                          String encoding) throws IOException {
    this(request, saveDirectory, maxPostSize, encoding, null);
  }

  /**
   * Constructs a new MultipartRequest to handle the specified request,
   * saving any uploaded files to the given directory, and limiting the
   * upload size to the specified length.  If the content is too large, an
   * IOException is thrown.  This constructor actually parses the
   * <tt>multipart/form-data</tt> and throws an IOException if there's any
   * problem reading or parsing the request.
   *
   * To avoid file collisions, this constructor takes an implementation of the
   * FileRenamePolicy interface to allow a pluggable rename policy.
   *
   * @param request the servlet request.
   * @param saveDirectory the directory in which to save any uploaded files.
   * @param maxPostSize the maximum size of the POST content.
   * @param encoding the encoding of the response, such as ISO-8859-1
   * @param policy a pluggable file rename policy
   * @exception IOException if the uploaded content is larger than
   * <tt>maxPostSize</tt> or there's a problem reading or parsing the request.
   */
  public MultipartRequest(HttpServletRequest request,
                          String saveDirectory,
                          int maxPostSize,
                          String encoding,
                          FileRenamePolicy policy) throws IOException {
    // Sanity check values
    if (request == null)
      throw new IllegalArgumentException("request cannot be null");
    if (saveDirectory == null)
      throw new IllegalArgumentException("saveDirectory cannot be null");
    if (maxPostSize <= 0) {
      throw new IllegalArgumentException("maxPostSize must be positive");
    }

    requestlocale = request.getLocale();
    encoding = request.getCharacterEncoding();
    sessionid = request.getRequestedSessionId();
    requesturl = request.getRequestURL();
    requesturi = request.getRequestURI();
    remoteuser = request.getRemoteUser();
    querystr = request.getQueryString();
    ctxpath = request.getContextPath();
    trnpath = request.getPathTranslated();
    pathinfo = request.getPathInfo();
    servletpath = request.getServletPath();
    formmethod = request.getMethod();
    cookies = request.getCookies();

    // Save the dir
    File dir = new File(saveDirectory);

    // Check saveDirectory is truly a directory
    if (!dir.isDirectory())
      throw new IllegalArgumentException("Not a directory: " + saveDirectory);

    // Check saveDirectory is writable
    if (!dir.canWrite())
      throw new IllegalArgumentException("Not writable: " + saveDirectory);

    savedir = saveDirectory;

    // Parse the incoming multipart, storing files in the dir provided,
    // and populate the meta objects which describe what we found
    MultipartParser parser = new MultipartParser(request, maxPostSize, true, true, encoding);

    // Some people like to fetch query string parameters from
    // MultipartRequest, so here we make that possible.  Thanks to
    // Ben Johnson, ben.johnson@merrillcorp.com, for the idea.
    if (request.getQueryString() != null) {
      // Let HttpUtils create a name->String[] structure
      Hashtable queryParameters =
        HttpUtils.parseQueryString(request.getQueryString());
      // For our own use, name it a name->Vector structure
      Enumeration queryParameterNames = queryParameters.keys();
      while (queryParameterNames.hasMoreElements()) {
        Object paramName = queryParameterNames.nextElement();
        String[] values = (String[])queryParameters.get(paramName);
        Vector newValues = new Vector();
        for (int i = 0; i < values.length; i++) {
          newValues.add(values[i]);
        }
        parameters.put(paramName, newValues);
      }
    }

    Part part;
    while ((part = parser.readNextPart()) != null) {
      String name = part.getName();
      if (part.isParam()) {
        // It's a parameter part, add it to the vector of values
        ParamPart paramPart = (ParamPart) part;
        String value = paramPart.getStringValue();
        Vector existingValues = (Vector)parameters.get(name);
        if (existingValues == null) {
          existingValues = new Vector();
          parameters.put(name, existingValues);
        }
        existingValues.addElement(value);
      }
      else if (part.isFile()) {
        // It's a file part
        FilePart filePart = (FilePart) part;
        String fileName = filePart.getFileName();
        if (fileName != null) {
          filePart.setRenamePolicy(policy);  // null policy is OK
          // The part actually contained a file
          filePart.writeTo(dir);
          files.put(name, new UploadedFile(dir.toString(),
                                           filePart.getFileName(),
                                           fileName,
                                           filePart.getContentType()));
        }
        else {
          // The field did not contain a file
          files.put(name, new UploadedFile(null, null, null, null));
        }
      }
    }
    bRequestedSessionIdFromURL = request.isRequestedSessionIdFromURL();
    bRequestedSessionIdFromCookie = request.isRequestedSessionIdFromCookie();
    bRequestedSessionIdValid = request.isRequestedSessionIdValid();
  }

  /**
   * Constructor with an old signature, kept for backward compatibility.
   * Without this constructor, a servlet compiled against a previous version
   * of this class (pre 1.4) would have to be recompiled to link with this
   * version.  This constructor supports the linking via the old signature.
   * Callers must simply be careful to pass in an HttpServletRequest.
   *
   */
  public MultipartRequest(ServletRequest request,
                          String saveDirectory) throws IOException {
    this((HttpServletRequest)request, saveDirectory);
  }

  /**
   * Constructor with an old signature, kept for backward compatibility.
   * Without this constructor, a servlet compiled against a previous version
   * of this class (pre 1.4) would have to be recompiled to link with this
   * version.  This constructor supports the linking via the old signature.
   * Callers must simply be careful to pass in an HttpServletRequest.
   *
   */
  public MultipartRequest(ServletRequest request,
                          String saveDirectory,
                          int maxPostSize) throws IOException {
    this((HttpServletRequest)request, saveDirectory, maxPostSize);
  }

  public Cookie[] getCookies() {
    return cookies;
  }

  public Locale getLocale() {
    return requestlocale;
  }

  /**
   * Returns the names of all the parameters as an Enumeration of
   * Strings.  It returns an empty Enumeration if there are no parameters.
   *
   * @return the names of all the parameters as an Enumeration of Strings.
   */
  public Enumeration getParameterNames() {
    return parameters.keys();
  }

  /**
   * @return number of uploaded files
   */

  public int getFileCount() {
    int iCount = 0;
    Enumeration oFiles = files.keys();
    Object oFileName;

    while (oFiles.hasMoreElements()) {
      oFileName = oFiles.nextElement();
      if (null!=oFileName)
        if (!oFileName.equals(""))
          iCount++;
    } // wend
    return iCount;
  } // getFileCount

  /**
   * Returns the names of all the uploaded files as an Enumeration of
   * Strings.  It returns an empty Enumeration if there are no uploaded
   * files.  Each file name is the name specified by the form, not by
   * the user.
   *
   * @return the names of all the uploaded files as an Enumeration of Strings.
   */
  public Enumeration getFileNames() {
    return files.keys();
  }

  /**
   * Returns the value of the named parameter as a String, or null if
   * the parameter was not sent or was sent without a value.  The value
   * is guaranteed to be in its normal, decoded form.  If the parameter
   * has multiple values, only the last one is returned (for backward
   * compatibility).  For parameters with multiple values, it's possible
   * the last "value" may be null.
   *
   * @param name the parameter name.
   * @return the parameter value.
   */
  public String getParameter(String name) {
    try {
      Vector values = (Vector)parameters.get(name);
      if (values == null || values.size() == 0) {
        return null;
      }
      String value = (String)values.elementAt(values.size() - 1);
      return value;
    }
    catch (Exception e) {
      return null;
    }
  }

  /**
   * Returns the values of the named parameter as a String array, or null if
   * the parameter was not sent.  The array has one entry for each parameter
   * field sent.  If any field was sent without a value that entry is stored
   * in the array as a null.  The values are guaranteed to be in their
   * normal, decoded form.  A single value is returned as a one-element array.
   *
   * @param name the parameter name.
   * @return the parameter values.
   */
  public String[] getParameterValues(String name) {
    try {
      Vector values = (Vector)parameters.get(name);
      if (values == null || values.size() == 0) {
        return null;
      }
      String[] valuesArray = new String[values.size()];
      values.copyInto(valuesArray);
      return valuesArray;
    }
    catch (Exception e) {
      return null;
    }
  }

  /**
   * Returns the filesystem name of the specified file, or null if the
   * file was not included in the upload.  A filesystem name is the name
   * specified by the user.  It is also the name under which the file is
   * actually saved.
   *
   * @param name the file name.
   * @return the filesystem name of the file.
   */
  public String getFilesystemName(String name) {
    try {
      UploadedFile file = (UploadedFile)files.get(name);
      return file.getFilesystemName();  // may be null
    }
    catch (Exception e) {
      return null;
    }
  }

  /**
   * Returns the original filesystem name of the specified file (before any
   * renaming policy was applied), or null if the file was not included in
   * the upload.  A filesystem name is the name specified by the user.
   *
   * @param name the file name.
   * @return the original file name of the file.
   */
  public String getOriginalFileName(String name) {
    try {
      UploadedFile file = (UploadedFile)files.get(name);
      return file.getOriginalFileName();  // may be null
    }
    catch (Exception e) {
      return null;
    }
  }

  public String getCharacterEncoding() {
    return encoding;
  }

  /**
   * Returns the content type of the specified file (as supplied by the
   * client browser), or null if the file was not included in the upload.
   *
   * @param name the file name.
   * @return the content type of the file.
   */
  public String getContentType(String name) {
    try {
      UploadedFile file = (UploadedFile)files.get(name);
      return file.getContentType();  // may be null
    }
    catch (Exception e) {
      return null;
    }
  }

  /**
   * Returns a File object for the specified file saved on the server's
   * filesystem, or null if the file was not included in the upload.
   * @param name the file name.
   * @return a File object for the named file.
   */
  public File getFile(String name) {
    try {
      UploadedFile file = (UploadedFile)files.get(name);
      return file.getFile();  // may be null
    }
    catch (Exception e) {
      return null;
    }
  }

  /**
   * Returns a File object for the specified uploaded file
   * @param number int [0..getFileCount()-1]
   * @return File
   */
  public File getFile(int number) {
    UploadedFile file = null;
    Enumeration fileenum = files.elements();
    try {
      for (int f=0; f<getFileCount(); f++)
        file = (UploadedFile) fileenum.nextElement();
      return file.getFile();  // may be null
    }
    catch (Exception e) {
      return null;
    }
  } // getFile

  public String getContentType() {
    return contenttype;
  }

  public int getContentLength() {
    return contentlength;
  }

  /**
   * <p>Returns the part of this request's URL that calls the servlet.</p>
   * Returns the part of this request's URL that calls the servlet.
   * This includes either the servlet name or a path to the servlet,
   * but does not include any extra path information or a query string.
   * Same as the value of the CGI variable SCRIPT_NAME.
   * @return  String containing the name or path of the servlet being called,
   * as specified in the request URL, decoded.
   */
  public String getServletPath() {
    return servletpath;
  }

  public String getContextPath() {
    return ctxpath;
  }

  public String getPathInfo() {
    return pathinfo;
  }

  public String getPathTranslated() {
    return trnpath;
  }

  public String getMethod() {
    return formmethod;
  }

  public String getRemoteUser() {
    return remoteuser;
  }

  public String getRequestURI() {
    return requesturi;
  }

  public StringBuffer getRequestURL() {
    return requesturl;
  }

  public String getRequestedSessionId() {
    return sessionid;
  }

  public String getQueryString() {
    return querystr;
  }

  public boolean isRequestedSessionIdFromURL() {
    return bRequestedSessionIdFromURL;
  }

  public boolean isRequestedSessionIdFromUrl() {
    return bRequestedSessionIdFromURL;
  }

  public boolean isRequestedSessionIdFromCookie() {
    return bRequestedSessionIdFromCookie;
  }

  public boolean isRequestedSessionIdValid() {
    return bRequestedSessionIdValid;
  }

  public Enumeration getAttributeNames() {
    throw new RuntimeException("HttpServletRequest.getAttributeNames() method not implemented for MultipartRequest");
  }

  public Object getAttribute(String sAttrName) {
    throw new RuntimeException("HttpServletRequest.getAttribute() method not implemented for MultipartRequest");
  }

  public void setAttribute(String sAttrName, Object sAttrVal) {
    throw new RuntimeException("HttpServletRequest.setAttribute() method not implemented for MultipartRequest");
  }

  public void removeAttribute(String sAttrName) {
    throw new RuntimeException("HttpServletRequest.removeAttribute() method not implemented for MultipartRequest");
  }

  public Enumeration getLocales() {
    throw new RuntimeException("HttpServletRequest.getLocales() method not implemented for MultipartRequest");
  }

  public boolean isSecure() {
    throw new RuntimeException("HttpServletRequest.isSecure() method not implemented for MultipartRequest");
  }

  public String getAuthType() {
    throw new RuntimeException("HttpServletRequest.getAuthType() method not implemented for MultipartRequest");
  }

  public int getLocalPort() {
    throw new RuntimeException("HttpServletRequest.getLocalPort() method not implemented for MultipartRequest");
  }

  public String getProtocol() {
    throw new RuntimeException("HttpServletRequest.getProtocol() method not implemented for MultipartRequest");
  }

  public Map getParameterMap() {
    throw new RuntimeException("HttpServletRequest.getParameterMap() method not implemented for MultipartRequest");
  }

  public String getScheme() {
    throw new RuntimeException("HttpServletRequest.getScheme() method not implemented for MultipartRequest");
  }

  public String getServerName() {
    throw new RuntimeException("HttpServletRequest.getServerName() method not implemented for MultipartRequest");
  }

  public int getServerPort() {
    throw new RuntimeException("HttpServletRequest.getServerPort() method not implemented for MultipartRequest");
  }

  public int getRemotePort() {
    throw new RuntimeException("HttpServletRequest.getRemotePort() method not implemented for MultipartRequest");
  }

  public String getLocalAddr() {
    throw new RuntimeException("HttpServletRequest.getLocalAddr() method not implemented for MultipartRequest");
  }

  public String getLocalName() {
    throw new RuntimeException("HttpServletRequest.getLocalName() method not implemented for MultipartRequest");
  }

  public String getRemoteAddr() {
    throw new RuntimeException("HttpServletRequest.getRemoteAddr() method not implemented for MultipartRequest");
  }

  public String getRemoteHost() {
    throw new RuntimeException("HttpServletRequest.getRemoteHost() method not implemented for MultipartRequest");
  }

  public HttpSession getSession() {
    throw new RuntimeException("HttpServletRequest.getSession() method not implemented for MultipartRequest");
  }

  public HttpSession getSession(boolean b) {
    throw new RuntimeException("HttpServletRequest.getSession() method not implemented for MultipartRequest");
  }

  public Principal getUserPrincipal()  {
    throw new RuntimeException("HttpServletRequest.getUserPrincipal() method not implemented for MultipartRequest");
  }

  public String getRealPath(String s) {
    throw new RuntimeException("HttpServletRequest.getRealPath() method not implemented for MultipartRequest");
  }

  public RequestDispatcher getRequestDispatcher(String s) {
    throw new RuntimeException("HttpServletRequest.getRequestDispatcher() method not implemented for MultipartRequest");
  }

  public boolean isUserInRole(String role)  {
    throw new RuntimeException("HttpServletRequest.isUserInRole() method not implemented for MultipartRequest");
  }

  public String getHeader(String hname)  {
    throw new RuntimeException("HttpServletRequest.getHeader() method not implemented for MultipartRequest");
  }

  public Enumeration getHeaders(String hname)  {
    throw new RuntimeException("HttpServletRequest.getHeaders() method not implemented for MultipartRequest");
  }

  public int getIntHeader(String hname)  {
    throw new RuntimeException("HttpServletRequest.getIntHeader() method not implemented for MultipartRequest");
  }

  public long getDateHeader(String hname)  {
    throw new RuntimeException("HttpServletRequest.getDateHeader() method not implemented for MultipartRequest");
  }

  public Enumeration getHeaderNames()  {
    throw new RuntimeException("HttpServletRequest.getHeaderNames() method not implemented for MultipartRequest");
  }

  public BufferedReader getReader() {
    throw new RuntimeException("HttpServletRequest.getReader() method not implemented for MultipartRequest");
  }

  public ServletInputStream getInputStream() {
    throw new RuntimeException("HttpServletRequest.getInputStream() method not implemented for MultipartRequest");
  }

  public void setCharacterEncoding(String sEncoding) {
    throw new RuntimeException("HttpServletRequest.setCharacterEncoding() method not implemented for MultipartRequest");
  }

  public boolean authenticate(HttpServletResponse response) {
	    return true;
	  }

      public void login(String username, String password) { }
  
  	  public void logout() { }
  
  	  /*
	  public javax.servlet.http.Part getPart(String name) {
	    return null;
	  }
	  
	  public Collection<javax.servlet.http.Part> getParts() {
	    return null;
	  }
	  
	  public AsyncContext getAsyncContext() { return null; }

	  public ServletContext getServletContext() { return null; }

	  public boolean isAsyncStarted() { return false; }

	  public boolean isAsyncSupported() { return false; }

	  public AsyncContext startAsync() { return null; }

	  public AsyncContext startAsync(ServletRequest request, ServletResponse response ) { return null; }

	  public DispatcherType getDispatcherType() { return null; }
	  */
}


// A class to hold information about an uploaded file.
//
class UploadedFile {

  private String dir;
  private String filename;
  private String original;
  private String type;

  UploadedFile(String dir, String filename, String original, String type) {
    this.dir = dir;
    this.filename = filename;
    this.original = original;
    this.type = type;
  }

  public String getContentType() {
    return type;
  }

  public String getFilesystemName() {
    return filename;
  }

  public String getOriginalFileName() {
    return original;
  }

  public File getFile() {
    if (dir == null || filename == null) {
      return null;
    }
    else {
      return new File(dir + File.separator + filename);
    }
  }
  
}


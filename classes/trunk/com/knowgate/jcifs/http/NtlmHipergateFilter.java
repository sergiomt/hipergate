package com.knowgate.jcifs.http;

import java.io.IOException;

import javax.servlet.ServletRequest;
import javax.servlet.ServletResponse;
import javax.servlet.ServletException;
import javax.servlet.FilterChain;

import javax.servlet.http.*;

import com.knowgate.jcifs.UniAddress;
import com.knowgate.jcifs.smb.SmbSession;
import com.knowgate.jcifs.smb.NtlmPasswordAuthentication;
import com.knowgate.jcifs.smb.SmbAuthException;
import com.knowgate.jcifs.netbios.NbtAddress;

import com.knowgate.debug.DebugFile;
import com.knowgate.misc.Base64Decoder;
import com.knowgate.misc.Gadgets;

/**
 * @author Sergio Montoro Ten
 * @version 0.9.1
 */

public class NtlmHipergateFilter extends NtlmHttpFilter {

  public NtlmHipergateFilter() { }

  public void doFilter( ServletRequest request,ServletResponse response, FilterChain chain )
      throws IOException, ServletException {

      NtlmPasswordAuthentication ntlm = null;
      HttpServletRequest req = (HttpServletRequest)request;
      HttpServletResponse resp = (HttpServletResponse)response;

      String msg = req.getHeader( "Authorization" );

      if (DebugFile.trace) DebugFile.writeln("NtlmHipergateFilter Authorization=" + msg);

      UniAddress dc;
      String user = "", password = "", domain = "";

      boolean offerBasic = enableBasic && (insecureBasic || req.isSecure());

      if (DebugFile.trace) DebugFile.writeln("offerBasic=" + String.valueOf(offerBasic));

      if( msg != null && (msg.startsWith( "NTLM " ) || (offerBasic && msg.startsWith("Basic ")))) {
          if( loadBalance ) {
              if (DebugFile.trace) DebugFile.writeln("new UniAddress(" + NbtAddress.getByName( domainController, 0x1C, null ) + ")");
              dc = new UniAddress( NbtAddress.getByName( domainController, 0x1C, null ));
          } else {
              if (DebugFile.trace) DebugFile.writeln("UniAddress.getByName( " + domainController + ", true)");
              dc = UniAddress.getByName( domainController, true );
          }

          if (msg.startsWith("NTLM ")) {
              req.getSession();
              byte[] challenge = SmbSession.getChallenge( dc );


              if (( ntlm = NtlmSsp.authenticate( req, resp, challenge )) == null ) {
                  if (DebugFile.trace) DebugFile.writeln("NtlmPasswordAuthentication = null");
                  return;
              }
          } else {
              String auth = new String (Base64Decoder.decodeToBytes(msg.substring(6)), "US-ASCII");

              int index = auth.indexOf(':');

              user = (index != -1) ? auth.substring(0, index) : auth;

              if (DebugFile.trace) DebugFile.writeln("user=" + user);

              password = (index != -1) ? auth.substring(index + 1) : "";

              index = user.indexOf('\\');
              if (index == -1) index = user.indexOf('/');
              domain = (index != -1) ? user.substring(0, index) : defaultDomain;

              if (DebugFile.trace) DebugFile.writeln("domain=" + domain);

              user = (index != -1) ? user.substring(index + 1) : user;

              ntlm = new NtlmPasswordAuthentication(domain, user, password);

          } // fi (msg.startsWith("NTLM "))

          try {
              if (DebugFile.trace && (dc!=null) && (ntlm!=null))
                DebugFile.writeln("SmbSession.logon(" + dc.toString() + "," + ntlm.toString());

              SmbSession.logon( dc, ntlm );

          } catch( SmbAuthException sae ) {
              if (DebugFile.trace) DebugFile.writeln("SmbAuthException" + Gadgets.toHexString(sae.getNtStatus(), 8) + " " + sae.getMessage());

              if( sae.getNtStatus() == sae.NT_STATUS_ACCESS_VIOLATION ) {
                  /* Server challenge no longer valid for
                   * externally supplied password hashes.
                   */
                  HttpSession ssn = req.getSession(false);
                  if (ssn != null) {
                      ssn.removeAttribute( "NtlmHttpAuth" );
                  }

                  if (DebugFile.trace) DebugFile.writeln("HttpServletResponse.sendRedirect(" + req.getRequestURL().toString() + ")");

                  resp.sendRedirect( req.getRequestURL().toString() );
                  return;
              }
              if (DebugFile.trace) DebugFile.writeln("HttpServletResponse.setHeader(WWW-Authenticate, NTLM)");

              resp.setHeader( "WWW-Authenticate", "NTLM" );
              if (offerBasic) {
                  resp.addHeader( "WWW-Authenticate", "Basic realm=\"" + realm + "\"");
              }
              resp.setHeader( "Connection", "close" );
              resp.setStatus( HttpServletResponse.SC_UNAUTHORIZED );
              resp.flushBuffer();
              return;
          }

          if (DebugFile.trace) DebugFile.writeln("HttpServletRequest.getSession().setAttribute(NtlmHttpAuth, " + ntlm.toString() + ")");

          req.getSession().setAttribute( "NtlmHttpAuth", ntlm );

          if (DebugFile.trace) DebugFile.writeln("HttpServletResponse.addCookie(domainnm, " + ntlm.getDomain().toUpperCase() + ")");
          if (DebugFile.trace) DebugFile.writeln("HttpServletResponse.addCookie(nickname, " + ntlm.getUsername() + ")");

          resp.addCookie(new Cookie("domainnm", ntlm.getDomain().toUpperCase()));
          resp.addCookie(new Cookie("NickCookie", ntlm.getUsername()));
          resp.addCookie(new Cookie("authstr", ntlm.getPassword()));

      } else {
          if (DebugFile.trace) DebugFile.writeln("HttpSession = HttpServletRequest.getSession(false)");

          HttpSession ssn = req.getSession(false);

          if (ssn == null || (ntlm = (NtlmPasswordAuthentication) ssn.getAttribute("NtlmHttpAuth")) == null) {

              resp.setHeader( "WWW-Authenticate", "NTLM" );

              if (DebugFile.trace) DebugFile.writeln("offerBasic=" + String.valueOf(offerBasic));

              if (offerBasic) {
                resp.addHeader( "WWW-Authenticate", "Basic realm=\"" + realm + "\"");
              }

              resp.setHeader( "Connection", "close" );
              resp.setStatus( HttpServletResponse.SC_UNAUTHORIZED );
              resp.flushBuffer();
              return;
          }
      }

      if (DebugFile.trace) DebugFile.writeln("FilterChain.doFilter(NtlmHttpServletRequest, HttpServletResponse)");

      chain.doFilter( new NtlmHttpServletRequest( req, ntlm ), response );
  }
}
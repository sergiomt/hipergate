/* jcifs smb client library in Java
 * Copyright (C) 2002  "Michael B. Allen" <jcifs at samba dot org>
 *                   "Jason Pugsley" <jcifs at samba dot org>
 *                   "skeetz" <jcifs at samba dot org>
 *                   "Eric Glass" <jcifs at samba dot org>
 *
 * This library is free software; you can redistribute it and/or
 * modify it under the terms of the GNU Lesser General Public
 * License as published by the Free Software Foundation; either
 * version 2.1 of the License, or (at your option) any later version.
 *
 * This library is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
 * Lesser General Public License for more details.
 *
 * You should have received a copy of the GNU Lesser General Public
 * License along with this library; if not, write to the Free Software
 * Foundation, Inc., 59 Temple Place, Suite 330, Boston, MA  02111-1307  USA
 */

package com.knowgate.jcifs.http;

import java.io.*;
import java.util.Enumeration;
import java.net.UnknownHostException;
import javax.servlet.*;
import javax.servlet.http.*;

import com.knowgate.jcifs.Config;
import com.knowgate.jcifs.UniAddress;
import com.knowgate.jcifs.smb.SmbSession;
import com.knowgate.jcifs.smb.NtlmPasswordAuthentication;
import com.knowgate.jcifs.smb.SmbAuthException;
import com.knowgate.jcifs.netbios.NbtAddress;

import com.knowgate.misc.Base64Decoder;

/**
 * This servlet Filter can be used to negotiate password hashes with
 * MSIE clients using NTLM SSP. This is similar to <tt>Authentication:
 * BASIC</tt> but weakly encrypted and without requiring the user to re-supply
 * authentication credentials.
 * <p>
 * Read <a href="../../../ntlmhttpauth.html">jCIFS NTLM HTTP Authentication and the Network Explorer Servlet</a> for complete details.
 * @version 0.9.1
 */

public class NtlmHttpFilter implements Filter {


    protected String defaultDomain;
    protected String domainController;
    protected boolean loadBalance;
    protected boolean enableBasic;
    protected boolean insecureBasic;
    protected String realm;

    public void init( FilterConfig filterConfig ) throws ServletException {
        String name;

        /* Set jcifs properties we know we want; soTimeout and cachePolicy to 10min.
         */
        Config.setProperty( "jcifs.smb.client.soTimeout", "300000" );
        Config.setProperty( "jcifs.netbios.cachePolicy", "600" );

        Enumeration e = filterConfig.getInitParameterNames();
        while( e.hasMoreElements() ) {
            name = (String)e.nextElement();
            if( name.startsWith( "jcifs." )) {
                Config.setProperty( name, filterConfig.getInitParameter( name ));
            }
        }
        defaultDomain = Config.getProperty("jcifs.smb.client.domain");
        domainController = Config.getProperty( "jcifs.http.domainController" );
        if( domainController == null ) {
            domainController = defaultDomain;
            loadBalance = Config.getBoolean( "jcifs.http.loadBalance", true );
        }
        enableBasic = Boolean.valueOf(
                Config.getProperty("jcifs.http.enableBasic")).booleanValue();
        insecureBasic = Boolean.valueOf(
                Config.getProperty("jcifs.http.insecureBasic")).booleanValue();
        realm = Config.getProperty("jcifs.http.basicRealm");
        if (realm == null) realm = "jCIFS";
    }

    public void destroy() {
    }

    public void doFilter( ServletRequest request,ServletResponse response, FilterChain chain )
        throws IOException, ServletException {

        HttpServletRequest req;
        HttpServletResponse resp;
        UniAddress dc;
        String msg;

        NtlmPasswordAuthentication ntlm = null;
        req = (HttpServletRequest)request;
        resp = (HttpServletResponse)response;
        msg = req.getHeader( "Authorization" );
        boolean offerBasic = enableBasic && (insecureBasic || req.isSecure());

        if( msg != null && (msg.startsWith( "NTLM " ) ||
                    (offerBasic && msg.startsWith("Basic ")))) {
            if( loadBalance ) {
                dc = new UniAddress( NbtAddress.getByName( domainController, 0x1C, null ));
            } else {
                dc = UniAddress.getByName( domainController, true );
            }
            if (msg.startsWith("NTLM ")) {
                req.getSession();
                byte[] challenge = SmbSession.getChallenge( dc );
                if(( ntlm = NtlmSsp.authenticate( req, resp, challenge )) == null ) {
                    return;
                }
            } else {
                String auth = new String(Base64Decoder.decodeToBytes(msg.substring(6)), "US-ASCII");
                int index = auth.indexOf(':');
                String user = (index != -1) ? auth.substring(0, index) : auth;
                String password = (index != -1) ? auth.substring(index + 1) :
                        "";
                index = user.indexOf('\\');
                if (index == -1) index = user.indexOf('/');
                String domain = (index != -1) ? user.substring(0, index) :
                        defaultDomain;
                user = (index != -1) ? user.substring(index + 1) : user;
                ntlm = new NtlmPasswordAuthentication(domain, user, password);
            }
            try {

                SmbSession.logon( dc, ntlm );

            } catch( SmbAuthException sae ) {
                if( sae.getNtStatus() == sae.NT_STATUS_ACCESS_VIOLATION ) {
                    /* Server challenge no longer valid for
                     * externally supplied password hashes.
                     */
                    HttpSession ssn = req.getSession(false);
                    if (ssn != null) {
                        ssn.removeAttribute( "NtlmHttpAuth" );
                    }
                    resp.sendRedirect( req.getRequestURL().toString() );
                    return;
                }
                resp.setHeader( "WWW-Authenticate", "NTLM" );
                if (offerBasic) {
                    resp.addHeader( "WWW-Authenticate", "Basic realm=\"" +
                            realm + "\"");
                }
                resp.setHeader( "Connection", "close" );
                resp.setStatus( HttpServletResponse.SC_UNAUTHORIZED );
                resp.flushBuffer();
                return;
            }
            req.getSession().setAttribute( "NtlmHttpAuth", ntlm );
        } else {
            HttpSession ssn = req.getSession(false);
            if (ssn == null || (ntlm = (NtlmPasswordAuthentication)
                    ssn.getAttribute("NtlmHttpAuth")) == null) {
                resp.setHeader( "WWW-Authenticate", "NTLM" );
                if (offerBasic) {
                    resp.addHeader( "WWW-Authenticate", "Basic realm=\"" +
                            realm + "\"");
                }
                resp.setHeader( "Connection", "close" );
                resp.setStatus( HttpServletResponse.SC_UNAUTHORIZED );
                resp.flushBuffer();
                return;
            }
        }

        chain.doFilter( new NtlmHttpServletRequest( req, ntlm ), response );
    }

    // Added by cgross to work with weblogic 6.1.
    public void setFilterConfig( FilterConfig f ) {
        try {
            init( f );
        } catch( Exception e ) {
            e.printStackTrace();
        }
    }
    public FilterConfig getFilterConfig() {
        return null;
    }
}


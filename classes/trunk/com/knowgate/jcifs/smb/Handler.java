/* jcifs smb client library in Java
 * Copyright (C) 2000  "Michael B. Allen" <jcifs at samba dot org>
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

package com.knowgate.jcifs.smb;

import java.net.URL;
import java.net.URLConnection;
import java.net.URLStreamHandler;
import java.io.IOException;
import java.io.UnsupportedEncodingException;

public class Handler extends URLStreamHandler {

    static final URLStreamHandler SMB_HANDLER = new Handler();

    static String unescape( String str ) throws NumberFormatException, UnsupportedEncodingException {
        char ch;
        int i, j, state, len;
        char[] out;
        byte[] b = new byte[1];

        if( str == null ) {
            return null;
        }

        len = str.length();
        out = new char[len];
        state = 0;
        for( i = j = 0; i < len; i++ ) {
            switch( state ) {
                case 0:
                    ch = str.charAt( i );
                    if( ch == '%' ) {
                        state = 1;
                    } else {
                        out[j++] = ch;
                    }
                    break;
                case 1:
                    /* Get ASCII hex value and convert to platform dependant
                     * encoding like EBCDIC perhaps
                     */
                    b[0] = (byte)(Integer.parseInt( str.substring( i, i + 2 ), 16 ) & 0xFF);
                    out[j++] = (new String( b, 0, 1, "ASCII" )).charAt( 0 );
                    i++;
                    state = 0;
            }
        }

        return new String( out, 0, j );
    }

    protected int getDefaultPort() {
        return 139;
    }
    public URLConnection openConnection( URL u ) throws IOException {
        return new SmbFile( u );
    }
    protected void parseURL( URL u, String spec, int start, int limit ) {
        String host = u.getHost();
        String userinfo, path, ref;
        if( spec.equals( "smb://" )) {
            spec = "smb:////";
            limit += 2;
        } else if( spec.startsWith( "smb://" ) == false &&
                    host != null && host.length() == 0 ) {
            spec = "//" + spec;
            limit += 2;
        }
        super.parseURL( u, spec, start, limit );
        userinfo = u.getUserInfo();
        path = u.getPath();
        ref = u.getRef();
        try {
            userinfo = unescape( userinfo );
        } catch( UnsupportedEncodingException uee ) {
        }
        if (ref != null) {
            path += '#' + ref;
        }
        setURL( u, "smb://", u.getHost(), getDefaultPort(),
                    u.getAuthority(), userinfo,
                    path, u.getQuery(), null );
    }
}

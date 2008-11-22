/* jcifs smb client library in Java
 * Copyright (C) 2000  "Michael B. Allen" <jcifs at samba dot org>
 *                  "Eric Glass" <jcifs at samba dot org>
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

import com.knowgate.jcifs.netbios.NbtSocket;
import com.knowgate.jcifs.netbios.NbtException;
import com.knowgate.jcifs.netbios.NbtAddress;
import com.knowgate.jcifs.UniAddress;
import com.knowgate.jcifs.Config;
import com.knowgate.debug.*;

import java.io.InputStream;
import java.io.OutputStream;
import java.io.PushbackInputStream;
import java.io.IOException;
import java.io.InterruptedIOException;
import java.net.InetAddress;
import java.net.UnknownHostException;

import java.util.LinkedList;
import java.util.ListIterator;
import java.util.Enumeration;
import java.util.HashMap;


class SmbTransport implements Runnable {

    private static final int DEFAULT_MAX_MPX_COUNT = 10;
    private static final int DEFAULT_RESPONSE_TIMEOUT = 10000;
    private static final int DEFAULT_SO_TIMEOUT = 15000;
    private static final int DEFAULT_RCV_BUF_SIZE = 60416;
    private static final int DEFAULT_SND_BUF_SIZE = 5000;
    private static final int DEFAULT_SSN_LIMIT = 250;

    private static final InetAddress LADDR = Config.getInetAddress( "jcifs.smb.client.laddr", null );
    private static final int LPORT = Config.getInt( "jcifs.smb.client.lport", 0 );
    private static final int SSN_LIMIT = Config.getInt( "jcifs.smb.client.ssnLimit", DEFAULT_SSN_LIMIT );
    private static final int MAX_MPX_COUNT = Config.getInt( "jcifs.smb.client.maxMpxCount", DEFAULT_MAX_MPX_COUNT );
    private static final int SND_BUF_SIZE = Config.getInt( "jcifs.smb.client.snd_buf_size", DEFAULT_SND_BUF_SIZE );
    private static final int RCV_BUF_SIZE = Config.getInt( "jcifs.smb.client.rcv_buf_size", DEFAULT_RCV_BUF_SIZE );
    private static final boolean USE_UNICODE = Config.getBoolean( "jcifs.smb.client.useUnicode", true );
    private static final boolean FORCE_UNICODE = Config.getBoolean( "jcifs.smb.client.useUnicode", false );
    private static final boolean USE_NTSTATUS = Config.getBoolean( "jcifs.smb.client.useNtStatus", true );
    private static final boolean SIGNPREF = Config.getBoolean("jcifs.smb.client.signingPreferred", false );
    private static final boolean USE_NTSMBS = Config.getBoolean( "jcifs.smb.client.useNTSmbs", true );
    private static final int DEFAULT_FLAGS2 =
                ServerMessageBlock.FLAGS2_LONG_FILENAMES |
                ServerMessageBlock.FLAGS2_EXTENDED_ATTRIBUTES |
                ( SIGNPREF ? ServerMessageBlock.FLAGS2_SECURITY_SIGNATURES : 0 ) |
                ( USE_NTSTATUS ? ServerMessageBlock.FLAGS2_STATUS32 : 0 ) |
                ( USE_UNICODE ? ServerMessageBlock.FLAGS2_UNICODE : 0 );
    private static final int DEFAULT_CAPABILITIES =
                ( USE_NTSMBS ? ServerMessageBlock.CAP_NT_SMBS : 0 ) |
                ( USE_NTSTATUS ? ServerMessageBlock.CAP_STATUS32 : 0 ) |
                ( USE_UNICODE ? ServerMessageBlock.CAP_UNICODE : 0 ) |
                ServerMessageBlock.CAP_DFS;
    private static final int FLAGS2 = Config.getInt( "jcifs.smb.client.flags2", DEFAULT_FLAGS2 );
    private static final int CAPABILITIES = Config.getInt( "jcifs.smb.client.capabilities", DEFAULT_CAPABILITIES );
    private static final int SO_TIMEOUT = Config.getInt( "jcifs.smb.client.soTimeout", DEFAULT_SO_TIMEOUT );
    private static final boolean TCP_NODELAY = Config.getBoolean( "jcifs.smb.client.tcpNoDelay", false );
    private static final int RESPONSE_TIMEOUT =
                Config.getInt( "jcifs.smb.client.responseTimeout", DEFAULT_RESPONSE_TIMEOUT );

    private static final int PUSHBACK_BUF_SIZE = 64;
    private static final int MID_OFFSET = 30;
    private static final int FLAGS_RESPONSE = 0x80;
    private static final int ST_GROUND = 0;
    private static final int ST_NEGOTIATING = 1;
    private static final LinkedList CONNECTIONS = new LinkedList();
    private static final int MAGIC[] = { 0xFF, 'S', 'M', 'B' };

private static byte[] snd_buf = new byte[0xFFFF];
private static byte[] rcv_buf = new byte[0xFFFF];

    private NbtSocket socket;
    private HashMap responseTable;
    private InputStream in;
    private OutputStream out;
    private int localPort;
    private InetAddress localAddr;
    private Thread thread;
    private Object outLock;
    private UniAddress address;
    private int port;
    private LinkedList sessions;
    private LinkedList referrals = new LinkedList();
    private int state;
    private Mid[] mids = new Mid[MAX_MPX_COUNT];
    private short mid_next;

    static final String NATIVE_OS =
            Config.getProperty( "jcifs.smb.client.nativeOs", System.getProperty( "os.name" ));
    static final String NATIVE_LANMAN =
            Config.getProperty( "jcifs.smb.client.nativeLanMan", "jCIFS" );
    static final int VC_NUMBER = 1;

    static final SmbTransport NULL_TRANSPORT = new SmbTransport();

    class Mid {
        short mid;

        public int hashCode() {
            return mid;
        }
        public boolean equals( Object obj ) {
            return ((Mid)obj).mid == mid;
        }
    }
    class ServerData {
        byte flags;
        int flags2;
        int maxMpxCount;
        int maxBufferSize;
        int sessionKey;
        // NT 4 Workstation is 0x43FD
        int capabilities;
        String oemDomainName;
        int securityMode;
        int security;
        boolean encryptedPasswords;
        boolean signaturesEnabled;
        boolean signaturesRequired;
        int maxNumberVcs;
        int maxRawSize;
        long serverTime;
        int serverTimeZone;
        int encryptionKeyLength;
        byte[] encryptionKey;
    }

    int flags2 = FLAGS2;
    int maxMpxCount = MAX_MPX_COUNT;
    int snd_buf_size = SND_BUF_SIZE;
    int rcv_buf_size = RCV_BUF_SIZE;
    int capabilities = CAPABILITIES;
    int sessionKey = 0x00000000;
    boolean useUnicode = USE_UNICODE;
    String tconHostName;
    ServerData server;
    SigningDigest digest = null;

    static synchronized SmbTransport getSmbTransport( UniAddress address, int port ) {
        return getSmbTransport( address, port, LADDR, LPORT );
    }
    static synchronized SmbTransport getSmbTransport( UniAddress address, int port,
                                    InetAddress localAddr, int localPort ) {
        SmbTransport conn;

        synchronized( CONNECTIONS ) {
            if( SSN_LIMIT != 1 ) {
                ListIterator iter = CONNECTIONS.listIterator();
                while( iter.hasNext() ) {
                    conn = (SmbTransport)iter.next();
                    if( conn.matches( address, port, localAddr, localPort ) &&
                            ( SSN_LIMIT == 0 || conn.sessions.size() < SSN_LIMIT )) {
                        return conn;
                    }
                }
            }

            conn = new SmbTransport( address, port, localAddr, localPort );
            CONNECTIONS.add( 0, conn );
        }

        return conn;
    }

    SmbTransport( UniAddress address, int port, InetAddress localAddr, int localPort ) {
        this.address = address;
        this.port = port;
        this.localAddr = localAddr;
        this.localPort = localPort;

        sessions = new LinkedList();
        responseTable = new HashMap();
        outLock = new Object();
        state = ST_GROUND;

        int i;
        for( i = 0; i < MAX_MPX_COUNT; i++ ) {
            mids[i] = new Mid();
        }
    }
    SmbTransport() {
    }

    synchronized SmbSession getSmbSession() {
        return getSmbSession( new NtlmPasswordAuthentication( null, null, null ));
    }
    synchronized SmbSession getSmbSession( NtlmPasswordAuthentication auth ) {
        SmbSession ssn;

        ListIterator iter = sessions.listIterator();
        while( iter.hasNext() ) {
            ssn = (SmbSession)iter.next();
            if( ssn.matches( auth )) {
                ssn.auth = auth;
                return ssn;
            }
        }
        ssn = new SmbSession( address, port, localAddr, localPort, auth );
        ssn.transport = this;
        sessions.add( ssn );

        return ssn;
    }
    boolean matches( UniAddress address, int port, InetAddress localAddr, int localPort ) {
        InetAddress defaultLocal = null;
        try {
            defaultLocal = InetAddress.getLocalHost();
        } catch( UnknownHostException uhe ) {
        }
        int p1 = ( port == 0 || port == 139 ) ? 0 : port;
        int p2 = ( this.port == 0 || this.port == 139 ) ? 0 : this.port;
        InetAddress la1 = localAddr == null ? defaultLocal : localAddr;
        InetAddress la2 = this.localAddr == null ? defaultLocal : this.localAddr;
        return address.equals( this.address ) &&
                    p1 == p2 &&
                    la1.equals( la2 ) &&
                    localPort == this.localPort;
    }
    boolean hasCapability( int cap ) throws SmbException {
        if (state == ST_GROUND) {
            negotiate();
        }
        return (capabilities & cap) == cap;
    }
    boolean isSignatureSetupRequired( NtlmPasswordAuthentication auth ) {
        return ( flags2 & ServerMessageBlock.FLAGS2_SECURITY_SIGNATURES ) != 0 &&
                digest == null &&
                auth != NtlmPasswordAuthentication.NULL &&
                NtlmPasswordAuthentication.NULL.equals( auth ) == false;
    }
    void ensureOpen() throws IOException {
        if( socket == null ) {
            Object obj;
            NbtAddress naddr;
            String calledName;

            obj = address.getAddress();
            if( obj instanceof NbtAddress ) {
                naddr = (NbtAddress)obj;
            } else {
                try {
                    naddr = NbtAddress.getByName( ((InetAddress)obj).getHostAddress() );
                } catch( UnknownHostException uhe ) {
                    naddr = null; // never happen
                }
            }

            calledName = address.firstCalledName();
            do {
                try {
                    socket = new NbtSocket( naddr, calledName, port, localAddr, localPort );
                    break;
                } catch( NbtException ne ) {
                    if( ne.errorClass == NbtException.ERR_SSN_SRVC &&
                                ( ne.errorCode == NbtException.CALLED_NOT_PRESENT ||
                                ne.errorCode == NbtException.NOT_LISTENING_CALLED )) {
                        if( DebugFile.trace )
                            new ErrorHandler(ne);
                    } else {
                        throw ne;
                    }
                }
            } while(( calledName = address.nextCalledName()) != null );

            if( calledName == null ) {
                throw new IOException( "Failed to establish session with " + address );
            }

            /* Save the calledName for using on SMB_COM_TREE_CONNECT
             */
            if( calledName == NbtAddress.SMBSERVER_NAME ) {
                tconHostName = address.getHostAddress();
            } else {
                tconHostName = calledName;
            }

            if( TCP_NODELAY ) {
                socket.setTcpNoDelay( true );
            }
            in = new PushbackInputStream( socket.getInputStream(), PUSHBACK_BUF_SIZE );
            out = socket.getOutputStream();
            thread = new Thread( this, "JCIFS-SmbTransport" );
            thread.setDaemon( true );
            thread.start();
        }
    }
    void tryClose( boolean inError ) {
        SmbSession ssn;

        if( socket == null ) {
            inError = true;
        }

        ListIterator iter = sessions.listIterator();
        while( iter.hasNext() ) {
            ssn = (SmbSession)iter.next();
            ssn.logoff( inError );
        }
        if( socket != null ) {
            try {
                socket.close();
            } catch( IOException ioe ) {
            }
        }
        digest = null;
        in = null;
        out = null;
        socket = null;
        thread = null;
        responseTable.clear();
        referrals.clear();
        sessions.clear();
        synchronized( CONNECTIONS ) {
            CONNECTIONS.remove( this );
        }
        state = ST_GROUND;
    }
    public void run() {
        Mid mid = new Mid();
        int i, m, nbtlen;
        ServerMessageBlock response;

        while( thread == Thread.currentThread() ) {
            try {
                socket.setSoTimeout( SO_TIMEOUT );

                m = 0;
                while( m < 4 ) {
                    if(( i = in.read() ) < 0 ) {
                        return;
                    }
                    if(( i & 0xFF ) == MAGIC[m] ) {
                        m++;
                    } else if(( i & 0xFF ) == 0xFF ) {
                        m = 1;
                    } else {
                        m = 0;
                    }
                }

                nbtlen = 4 + in.available();

synchronized( rcv_buf ) {
                rcv_buf[0] = (byte)0xFF;
                rcv_buf[1] = (byte)'S';
                rcv_buf[2] = (byte)'M';
                rcv_buf[3] = (byte)'B';

                if( in.read( rcv_buf, 4, ServerMessageBlock.HEADER_LENGTH - 4 ) !=
                                    ( ServerMessageBlock.HEADER_LENGTH - 4 )) {
                    /* Read on a netbios SocketInputStream does not
                     * return until len bytes have been read or the stream is
                     * closed. This must be the latter case.
                     */
                    break;
                }
                ((PushbackInputStream)in).unread( rcv_buf, 0, ServerMessageBlock.HEADER_LENGTH );
                if( rcv_buf[0] != (byte)0xFF ||
                                rcv_buf[1] != (byte)'S' ||
                                rcv_buf[2] != (byte)'M' ||
                                rcv_buf[3] != (byte)'B' ) {
                    if( DebugFile.trace )
                        DebugFile.writeln( "bad smb header, purging session message: " + address );
                    in.skip( in.available() );
                    continue;
                }
                if(( rcv_buf[ServerMessageBlock.FLAGS_OFFSET] &
                            ServerMessageBlock.FLAGS_RESPONSE ) ==
                            ServerMessageBlock.FLAGS_RESPONSE ) {
                    mid.mid = (short)(ServerMessageBlock.readInt2( rcv_buf, MID_OFFSET ) & 0xFFFF);

                    response = (ServerMessageBlock)responseTable.get( mid );
                    if( response == null ) {
                        if( DebugFile.trace) {
                            DebugFile.writeln( "no handler for mid=" + mid.mid +
                                    ", purging session message: " + address );
                        }
                        in.skip( in.available() );
                        continue;
                    }
                    synchronized( response ) {
                        response.useUnicode = useUnicode;

                        if( DebugFile.trace )
                            DebugFile.writeln( "new data read from socket: " + address );

                        if( response instanceof SmbComTransactionResponse ) {
                            Enumeration e = (Enumeration)response;
                            if( e.hasMoreElements() ) {
                                e.nextElement();
                            } else {
                                if( DebugFile.trace )
                                    DebugFile.writeln( "more responses to transaction than expected" );
                                continue;
                            }
                            if((m = response.readWireFormat( in, rcv_buf, 0 )) != nbtlen ) {
                                if( DebugFile.trace ) {
                                    DebugFile.writeln( "decoded " + m + " but nbtlen=" +
                                            nbtlen + ", purging session message" );
                                }
                                in.skip( in.available() );
                            }
                            response.received = true;

                            if( response.errorCode != 0 || e.hasMoreElements() == false ) {
                                ((SmbComTransactionResponse)response).hasMore = false;
                                if( digest != null ) {
                                    synchronized( outLock ) {
                                        digest.verify(rcv_buf, 0, response);
                                    }
                                }
                                response.notify();
                            } else {
                                ensureOpen();
                            }
                        } else {
                            response.readWireFormat( in, rcv_buf, 0 );
                            response.received = true;

                            if( digest != null ) {
                                synchronized( outLock ) {
                                    digest.verify(rcv_buf, 0, response);
                                }
                            }

                            response.notify();
                        }
                    }
                } else {
                    // it's a request(break oplock)
                }
}
            } catch( InterruptedIOException iioe ) {
                if( responseTable.size() == 0 ) {
                    tryClose( false );
                } else if( DebugFile.trace ) {
                    DebugFile.writeln( "soTimeout has occured but there are " +
                            responseTable.size() + " pending requests" );
                }
            } catch( IOException ioe ) {
                synchronized( this ) {
                    tryClose( true );
                }
                if( DebugFile.trace &&
                            ioe.getMessage().startsWith( "Connection reset" ) == false ) {
                    DebugFile.writeln( ioe.getMessage() + ": " + address );
                    new ErrorHandler(ioe);
                }
            }
        }
    }

    synchronized DfsReferral getDfsReferral( NtlmPasswordAuthentication auth, String path ) throws SmbException {
        String subpath, node, host;
        DfsReferral dr = new DfsReferral();
        int p, n, i, s;
        UniAddress addr;

        SmbTree ipc = getSmbSession( auth ).getSmbTree( "IPC$", null );
        Trans2GetDfsReferralResponse resp = new Trans2GetDfsReferralResponse();
        ipc.sendTransaction( new Trans2GetDfsReferral( path ), resp );

        subpath = path.substring( 0, resp.pathConsumed );
        node = resp.referral.node;
        if( subpath.charAt( 0 ) != '\\' ||
                (i = subpath.indexOf( '\\', 1 )) < 2 ||
                (p = subpath.indexOf( '\\', i + 1 )) < (i + 2) ||
                node.charAt( 0 ) != '\\' ||
                (s = node.indexOf( '\\', 1 )) < 2) {
            throw new SmbException( "Invalid DFS path: " + path );
        }
        if ((n = node.indexOf( '\\', s + 1 )) == -1) {
            n = node.length();
        }

        dr.path = subpath.substring( p );
        dr.node = node.substring( 0, n );
        dr.nodepath = node.substring( n );
        dr.server = node.substring( 1, s );
        dr.share = node.substring( s + 1, n );
        dr.resolveHashes = auth.hashesExternal;
                        /* NTLM HTTP Authentication must be re-negotiated
                         * with challenge from 'server' to access DFS vol. */
        return dr;
    }
    synchronized DfsReferral lookupReferral( String unc ) {
        DfsReferral dr;
        ListIterator iter = referrals.listIterator();
        int i, len;

        while( iter.hasNext() ) {
            dr = (DfsReferral)iter.next();
            len = dr.path.length();
            for( i = 0; i < len && i < unc.length(); i++ ) {
                if( dr.path.charAt( i ) != unc.charAt( i )) {
                    break;
                }
            }
            if( i == len && (len == unc.length() || unc.charAt( len ) == '\\')) {
                return dr;
            }
        }

        return null;
    }
    void send( ServerMessageBlock request,
                            ServerMessageBlock response ) throws SmbException {
        Mid mid = null;

        if (state == ST_GROUND) {
            negotiate();
        }

        request.flags2 |= flags2;
        request.useUnicode = useUnicode;

        if( response == null ) {
            try {
                synchronized( outLock ) {
                    mid = aquireMid();
                    request.mid = mid.mid;
                    ensureOpen();
synchronized( snd_buf ) {
                    request.digest = digest;
                    request.response = null;
                    int length = request.writeWireFormat(snd_buf, 4);
                    out.write(snd_buf, 4, length);
                    out.flush();
}
                }
            } catch( IOException ioe ) {
                tryClose( true );
                throw new SmbException( "An error occured sending the request.", ioe );
            } finally {
                synchronized( outLock ) {
                    releaseMid( mid );
                }
            }

            return;
        }

        // now for the normal case where response is not null

        try {
            synchronized( response ) {
                synchronized( outLock ) {
                    response.received = false;
                    mid = aquireMid();
                    request.mid = mid.mid;
                    responseTable.put( mid, response );
                    ensureOpen();
synchronized( snd_buf ) {
                    if( digest != null ) {
                        request.digest = digest;
                        request.response = response;
                    }
                    int length = request.writeWireFormat(snd_buf, 4);
                    out.write(snd_buf, 4, length);
                    out.flush();
}
                }

                // default it 1 so that 0 can be used as forever
                response.wait( response.responseTimeout == 1 ? RESPONSE_TIMEOUT : response.responseTimeout );
            }
        } catch( InterruptedException ie ) {
            tryClose( true );
        } catch( IOException ioe ) {
            tryClose( true );
            throw new SmbException( "An error occured sending the request.", ioe );
        } finally {
            synchronized( outLock ) {
                responseTable.remove( mid );
                releaseMid( mid );
            }
        }

        if( response.received == false ) {
            tryClose( true );
            throw new SmbException( "Timeout waiting for response from server: " + address );
        } else if( response.verifyFailed ) {
            tryClose( true );
            throw new SmbException( "Unverifiable signature: " + address );
        }
        response.errorCode = SmbException.getStatusByCode( response.errorCode );
        switch( response.errorCode ) {
            case NtStatus.NT_STATUS_OK:
                break;
            case NtStatus.NT_STATUS_ACCESS_DENIED:
            case NtStatus.NT_STATUS_WRONG_PASSWORD:
            case NtStatus.NT_STATUS_LOGON_FAILURE:
            case NtStatus.NT_STATUS_ACCOUNT_RESTRICTION:
            case NtStatus.NT_STATUS_INVALID_LOGON_HOURS:
            case NtStatus.NT_STATUS_INVALID_WORKSTATION:
            case NtStatus.NT_STATUS_PASSWORD_EXPIRED:
            case NtStatus.NT_STATUS_ACCOUNT_DISABLED:
            case NtStatus.NT_STATUS_ACCOUNT_LOCKED_OUT:
                throw new SmbAuthException( response.errorCode );
            case NtStatus.NT_STATUS_PATH_NOT_COVERED:
                if( request.auth == null ) {
                    throw new SmbException( response.errorCode, null );
                }
                DfsReferral dr = getDfsReferral( request.auth, request.path );
                referrals.add( dr );
                throw dr;
            default:
                throw new SmbException( response.errorCode, null );
        }
    }
    void sendTransaction( SmbComTransaction request,
                            SmbComTransactionResponse response ) throws SmbException {
        Mid mid = null;

        negotiate();

        request.flags2 |= flags2;
        request.useUnicode = useUnicode;
        request.maxBufferSize = snd_buf_size;
        response.received = false;
        response.hasMore = true;
        response.isPrimary = true;

        try {
            request.txn_buf = BufferCache.getBuffer();
            response.txn_buf = BufferCache.getBuffer();

            request.nextElement();
            if( request.hasMoreElements() ) {
                // multi-part request

                SmbComBlankResponse interimResponse = new SmbComBlankResponse();

                synchronized( interimResponse ) {
                    synchronized( outLock ) {
                        mid = aquireMid();
                        request.mid = mid.mid;
                        responseTable.put( mid, interimResponse );
                        ensureOpen();
synchronized(snd_buf) {
                        request.digest = digest;
                        request.response = response;
                        int length = request.writeWireFormat(snd_buf, 4);
                        out.write(snd_buf, 4, length);
                        out.flush();
}
                    }

                    interimResponse.wait( RESPONSE_TIMEOUT );

                    if( interimResponse.received == false ) {
                        throw new SmbException( "Timeout waiting for response from server: " + address );
                    }
                    interimResponse.errorCode = SmbException.getStatusByCode( interimResponse.errorCode );
                    switch( interimResponse.errorCode ) {
                        case NtStatus.NT_STATUS_OK:
                            break;
                        case NtStatus.NT_STATUS_ACCESS_DENIED:
                        case NtStatus.NT_STATUS_WRONG_PASSWORD:
                        case NtStatus.NT_STATUS_LOGON_FAILURE:
                        case NtStatus.NT_STATUS_ACCOUNT_RESTRICTION:
                        case NtStatus.NT_STATUS_INVALID_LOGON_HOURS:
                        case NtStatus.NT_STATUS_INVALID_WORKSTATION:
                        case NtStatus.NT_STATUS_PASSWORD_EXPIRED:
                        case NtStatus.NT_STATUS_ACCOUNT_DISABLED:
                        case NtStatus.NT_STATUS_ACCOUNT_LOCKED_OUT:
                            throw new SmbAuthException( interimResponse.errorCode );
                        case NtStatus.NT_STATUS_PATH_NOT_COVERED:
                            if( request.auth == null ) {
                                throw new SmbException( interimResponse.errorCode, null );
                            }
                            DfsReferral dr = getDfsReferral( request.auth, request.path );
                            referrals.add( dr );
                            throw dr;
                        default:
                            throw new SmbException( interimResponse.errorCode, null );
                    }
                }
                request.nextElement();
            }

            synchronized( response ) {
                synchronized( outLock ) {
                    mid = aquireMid();
                    request.mid = mid.mid;
                    responseTable.put( mid, response );
                }
                do {
                    synchronized( outLock ) {
                        ensureOpen();
synchronized( snd_buf ) {
                        request.digest = digest;
                        request.response = response;
                        int length = request.writeWireFormat(snd_buf, 4);
                        out.write(snd_buf, 4, length);
                        out.flush();
}
                    }
                } while( request.hasMoreElements() && request.nextElement() != null );

                do {
                    // default it 1 so that 0 can be used as forever
                    response.received = false;
                    response.wait( response.responseTimeout == 1 ? RESPONSE_TIMEOUT : response.responseTimeout );
                } while( response.received && response.hasMoreElements() );
            }
        } catch( InterruptedException ie ) {
            tryClose( true );
        } catch( IOException ioe ) {
            tryClose( true );
            throw new SmbException( "An error occured sending the request.", ioe );
        } finally {
            synchronized( outLock ) {
                responseTable.remove( mid );
                releaseMid( mid );
            }
            BufferCache.releaseBuffer( request.txn_buf );
            BufferCache.releaseBuffer( response.txn_buf );
        }

        if( response.received == false ) {
            tryClose( true );
            throw new SmbException( "Timeout waiting for response from server: " + address );
        } else if( response.verifyFailed ) {
            tryClose( true );
            throw new SmbException( "Unverifiable signature: " + address );
        }
        response.errorCode = SmbException.getStatusByCode( response.errorCode );
        switch( response.errorCode ) {
            case NtStatus.NT_STATUS_OK:
                break;
            case NtStatus.NT_STATUS_ACCESS_DENIED:
            case NtStatus.NT_STATUS_WRONG_PASSWORD:
            case NtStatus.NT_STATUS_LOGON_FAILURE:
            case NtStatus.NT_STATUS_ACCOUNT_RESTRICTION:
            case NtStatus.NT_STATUS_INVALID_LOGON_HOURS:
            case NtStatus.NT_STATUS_INVALID_WORKSTATION:
            case NtStatus.NT_STATUS_PASSWORD_EXPIRED:
            case NtStatus.NT_STATUS_ACCOUNT_DISABLED:
            case NtStatus.NT_STATUS_ACCOUNT_LOCKED_OUT:
                throw new SmbAuthException( response.errorCode );
            case NtStatus.NT_STATUS_PATH_NOT_COVERED:
                if( request.auth == null ) {
                    throw new SmbException( response.errorCode, null );
                }
                DfsReferral dr = getDfsReferral( request.auth, request.path );
                referrals.add( dr );
                throw dr;
            default:
                throw new SmbException( response.errorCode, null );
        }
    }
    synchronized void negotiate() throws SmbException {

        if( this == NULL_TRANSPORT ) {
            throw new RuntimeException( "Null transport cannot be used" );
        }
        if( state >= ST_NEGOTIATING ) {
            return;
        }
        state = ST_NEGOTIATING;

        if( DebugFile.trace )
            DebugFile.writeln( "requesting negotiation with " + address );

        /*
         * Negotiate Protocol Request / Response
         */

        SmbComNegotiateResponse response = new SmbComNegotiateResponse();
        send( new SmbComNegotiate(), response );

        if( response.dialectIndex > 10 ) {
            tryClose( true );
            throw new SmbException( "This client does not support the negotiated dialect." );
        }

        server = new ServerData();
        server.securityMode = response.securityMode;
        server.security = response.security;
        server.encryptedPasswords = response.encryptedPasswords;
        server.signaturesEnabled = response.signaturesEnabled;
        server.signaturesRequired = response.signaturesRequired;
        server.maxMpxCount = response.maxMpxCount;
        server.maxNumberVcs = response.maxNumberVcs;
        server.maxBufferSize = response.maxBufferSize;
        server.maxRawSize = response.maxRawSize;
        server.sessionKey = response.sessionKey;
        server.capabilities = response.capabilities;
        server.serverTime = response.serverTime;
        server.serverTimeZone = response.serverTimeZone;
        server.encryptionKeyLength = response.encryptionKeyLength;
        server.encryptionKey = response.encryptionKey;
        server.oemDomainName = response.oemDomainName;

        if (server.signaturesRequired || (server.signaturesEnabled && SIGNPREF)) {
            flags2 |= ServerMessageBlock.FLAGS2_SECURITY_SIGNATURES;
        } else {
            flags2 &= 0xFFFF ^ ServerMessageBlock.FLAGS2_SECURITY_SIGNATURES;
        }

        maxMpxCount = maxMpxCount < server.maxMpxCount ? maxMpxCount : server.maxMpxCount;
        maxMpxCount = maxMpxCount < 1 ? 1 : maxMpxCount;

        snd_buf_size = snd_buf_size < server.maxBufferSize ? snd_buf_size : server.maxBufferSize;

        capabilities &= server.capabilities;
        if(( capabilities & ServerMessageBlock.CAP_UNICODE ) == 0 ) {
            // server doesn't want unicode
            if( FORCE_UNICODE ) {
                capabilities |= ServerMessageBlock.CAP_UNICODE;
            } else {
                useUnicode = false;
                flags2 &= 0xFFFF ^ ServerMessageBlock.FLAGS2_UNICODE;
            }
        }
    }
    public String toString() {
        String ret = "SmbTransport[address=" + address;
        if( socket == null ) {
            ret += ",port=,localAddr=,localPort=]";
        } else {
            ret += ",port=" + socket.getPort() +
            ",localAddr=" + socket.getLocalAddress() +
            ",localPort=" + socket.getLocalPort() + "]";
        }
        return ret;
    }

    /* Manage MIDs */

    Mid aquireMid() throws SmbException {
        int i;

        if( mid_next == 0 ) {
            mid_next++;
        }

        for( ;; ) {
            for( i = 0; i < maxMpxCount; i++ ) {
                if( mids[i].mid == 0 ) {
                    break;
                }
            }
            if( i == maxMpxCount ) {
                try {
                    outLock.wait();
                } catch( InterruptedException ie ) {
                    throw new SmbException( "Interrupted aquiring mid", ie );
                }
            } else {
                break;
            }
        }

        mids[i].mid = mid_next++;

        return mids[i];
    }
    void releaseMid( Mid mid ) {
        int i;

        for( i = 0; i < maxMpxCount; i++ ) {
            if( mids[i].mid == mid.mid ) {
                mid.mid = 0;
                outLock.notify();
                return;
            }
        }
        if( DebugFile.trace )
            DebugFile.writeln( "mid not found" );
    }
}

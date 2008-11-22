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

import com.knowgate.jcifs.Config;

import com.knowgate.debug.DebugFile;

class SmbTree {

    private static final String DEFAULT_SERVICE = Config.getProperty( "jcifs.smb.client.serviceType", "?????" );

    private int tid;
    private String share;

    String service = DEFAULT_SERVICE;
    SmbSession session;
    boolean treeConnected, inDfs;

    SmbTree( SmbSession session, String share, String service ) {
        this.session = session;
        this.share = share.toUpperCase();
        if( service != null && service.startsWith( "??" ) == false ) {
            this.service = service;
        }
    }

    boolean matches( String share, String service ) {
        return this.share.equalsIgnoreCase( share ) &&
                ( service == null || service.startsWith( "??" ) ||
                this.service.equalsIgnoreCase( service ));
    }
    void sendTransaction( SmbComTransaction request,
                            SmbComTransactionResponse response ) throws SmbException {
        // transactions are not batchable
        treeConnect( null, null );
        if( service.equals( "A:" ) == false ) {
            switch( ((SmbComTransaction)request).subCommand & 0xFF ) {
                case SmbComTransaction.NET_SHARE_ENUM:
                case SmbComTransaction.NET_SERVER_ENUM2:
                case SmbComTransaction.NET_SERVER_ENUM3:
                case SmbComTransaction.TRANS_PEEK_NAMED_PIPE:
                case SmbComTransaction.TRANS_WAIT_NAMED_PIPE:
                case SmbComTransaction.TRANS_CALL_NAMED_PIPE:
                case SmbComTransaction.TRANS_TRANSACT_NAMED_PIPE:
                case SmbComTransaction.TRANS2_GET_DFS_REFERRAL:
                    break;
                default:
                    throw new SmbException( "Invalid operation for " + service + " service" );
            }
        }
        request.tid = tid;
        if( inDfs && request.path != null && request.path.length() > 0 ) {
            request.path = '\\' + session.transport().tconHostName + '\\' + share + request.path;
        }
        session.sendTransaction( request, response );
    }
    void send( ServerMessageBlock request,
                            ServerMessageBlock response ) throws SmbException {
        if( response != null ) {
            response.received = false;
        }
        treeConnect( request, response );
        if( request == null || (response != null && response.received )) {
            return;
        }
        if( service.equals( "A:" ) == false ) {
            switch( request.command ) {
                case ServerMessageBlock.SMB_COM_OPEN_ANDX:
                case ServerMessageBlock.SMB_COM_NT_CREATE_ANDX:
                case ServerMessageBlock.SMB_COM_READ_ANDX:
                case ServerMessageBlock.SMB_COM_WRITE_ANDX:
                case ServerMessageBlock.SMB_COM_CLOSE:
                case ServerMessageBlock.SMB_COM_TREE_DISCONNECT:
                    break;
                default:
                    throw new SmbException( "Invalid operation for " + service + " service" );
            }
        }
        request.tid = tid;
        if( inDfs && request.path != null && request.path.length() > 0 ) {
            request.flags2 = ServerMessageBlock.FLAGS2_RESOLVE_PATHS_IN_DFS;
            request.path = '\\' + session.transport().tconHostName + '\\' + share + request.path;
        }
        session.send( request, response );
    }
    void treeConnect( ServerMessageBlock andx,
                            ServerMessageBlock andxResponse ) throws SmbException {
        String unc;
synchronized( session.transport() ) {

        if( treeConnected ) {
            return;
        }

        /* The hostname to use in the path is only known for
         * sure if the NetBIOS session has been successfully
         * established.
         */

        session.transport.negotiate();

        unc = "\\\\" + session.transport.tconHostName + '\\' + share;

        /*
         * Tree Connect And X Request / Response
         */

        if( DebugFile.trace )
            DebugFile.writeln( "treeConnect: unc=" + unc + ",service=" + service );

        SmbComTreeConnectAndXResponse response =
                                    new SmbComTreeConnectAndXResponse( andxResponse );
        SmbComTreeConnectAndX request =
                                    new SmbComTreeConnectAndX( session, unc, service, andx );
        session.send( request, response );

        tid = response.tid;
        service = response.service;
        inDfs = response.shareIsInDfs;
        treeConnected = true;
}
    }
    void treeDisconnect( boolean inError ) {
synchronized( session.transport ) {
        if( treeConnected == false ) {
            return;
        }
        if( !inError ) {
            try {
                send( new SmbComTreeDisconnect(), null );
            } catch( SmbException se ) {
            }
        }
        treeConnected = false;
}
    }

    public String toString() {
        return "SmbTree[share=" + share +
            ",service=" + service +
            ",tid=" + tid +
            ",inDfs=" + inDfs +
            ",treeConnected=" + treeConnected + "]";
    }
}

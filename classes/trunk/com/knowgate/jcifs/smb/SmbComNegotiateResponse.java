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

import java.util.Date;
import java.io.UnsupportedEncodingException;

import com.knowgate.debug.*;
import com.knowgate.misc.Gadgets;

class SmbComNegotiateResponse extends ServerMessageBlock {

    int dialectIndex,
        securityMode,
        security,
        maxMpxCount,
        maxNumberVcs,
        maxBufferSize,
        maxRawSize,
        sessionKey,
        capabilities,
        serverTimeZone,
        encryptionKeyLength;
    boolean encryptedPasswords,
        signaturesEnabled,
        signaturesRequired;
    long serverTime;
    byte[] encryptionKey;
    String oemDomainName;

    SmbComNegotiateResponse() {
    }

    int writeParameterWordsWireFormat( byte[] dst, int dstIndex ) {
        return 0;
    }
    int writeBytesWireFormat( byte[] dst, int dstIndex ) {
        return 0;
    }
    int readParameterWordsWireFormat( byte[] buffer,
                                    int bufferIndex ) {
        int start = bufferIndex;
        dialectIndex        = readInt2( buffer, bufferIndex );
        bufferIndex += 2;
        if( dialectIndex > 10 ) {
            return bufferIndex - start;
        }
        securityMode        = buffer[bufferIndex++] & 0xFF;
        security            = securityMode & 0x01;
        encryptedPasswords  = ( securityMode & 0x02 ) == 0x02 ? true : false;
        signaturesEnabled   = ( securityMode & 0x04 ) == 0x04 ? true : false;
        signaturesRequired  = ( securityMode & 0x08 ) == 0x08 ? true : false;
        maxMpxCount         = readInt2( buffer, bufferIndex );
        bufferIndex += 2;
        maxNumberVcs        = readInt2( buffer, bufferIndex );
        bufferIndex += 2;
        maxBufferSize       = readInt4( buffer, bufferIndex );
        bufferIndex += 4;
        maxRawSize          = readInt4( buffer, bufferIndex );
        bufferIndex += 4;
        sessionKey          = readInt4( buffer, bufferIndex );
        bufferIndex += 4;
        capabilities        = readInt4( buffer, bufferIndex );
        bufferIndex += 4;
        serverTime          = readTime( buffer, bufferIndex );
        bufferIndex += 8;
        serverTimeZone      = readInt2( buffer, bufferIndex );
        bufferIndex += 2;
        encryptionKeyLength = buffer[bufferIndex++] & 0xFF;
        return bufferIndex - start;
    }
    int readBytesWireFormat( byte[] buffer,
                                    int bufferIndex ) {
        int start = bufferIndex;
        encryptionKey = new byte[encryptionKeyLength];
        System.arraycopy( buffer, bufferIndex,
                        encryptionKey, 0, encryptionKeyLength );
        bufferIndex += encryptionKeyLength;

        if( byteCount > encryptionKeyLength ) {
            int len = 0;
            if(( flags2 & FLAGS2_UNICODE ) == FLAGS2_UNICODE ) {
                while( buffer[bufferIndex + len] != (byte)0x00 ||
                                            buffer[bufferIndex + len + 1] != (byte)0x00 ) {
                    len += 2;
                    if( len > 256 ) {
                        throw new RuntimeException( "zero termination not found" );
                    }
                }
                try {
                    oemDomainName = new String( buffer, bufferIndex, len, "UnicodeLittle" );
                } catch( UnsupportedEncodingException uee ) {
                    if( DebugFile.trace )
                        new ErrorHandler(uee);
                }
            } else {
                while( buffer[bufferIndex + len] != (byte)0x00 ) {
                    len++;
                    if( len > 256 ) {
                        throw new RuntimeException( "zero termination not found" );
                    }
                }
                try {
                    oemDomainName = new String( buffer, bufferIndex, len, ServerMessageBlock.OEM_ENCODING );
                } catch( UnsupportedEncodingException uee ) {
                }
            }
            bufferIndex += len;
        } else {
            oemDomainName = new String();
        }

        return bufferIndex - start;
    }
    public String toString() {
        return new String( "SmbComNegotiateResponse[" +
            super.toString() +
            ",wordCount="           + wordCount +
            ",dialectIndex="        + dialectIndex +
            ",securityMode=0x"      + Gadgets.toHexString( securityMode, 1 ) +
            ",security="            + ( security == SECURITY_SHARE ? "share" : "user" ) +
            ",encryptedPasswords="  + encryptedPasswords +
            ",maxMpxCount="         + maxMpxCount +
            ",maxNumberVcs="        + maxNumberVcs +
            ",maxBufferSize="       + maxBufferSize +
            ",maxRawSize="          + maxRawSize +
            ",sessionKey=0x"        + Gadgets.toHexString( sessionKey, 8 ) +
            ",capabilities=0x"      + Gadgets.toHexString( capabilities, 8 ) +
            ",serverTime="          + new Date( serverTime ) +
            ",serverTimeZone="      + serverTimeZone +
            ",encryptionKeyLength=" + encryptionKeyLength +
            ",byteCount="           + byteCount +
            ",encryptionKey=0x"     + Gadgets.toHexString( encryptionKey,
                                                0,
                                                encryptionKeyLength * 2 ) +
            ",oemDomainName="       + oemDomainName + "]" );
    }
}

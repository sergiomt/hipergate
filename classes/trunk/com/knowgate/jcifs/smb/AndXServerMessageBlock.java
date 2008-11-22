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

import java.io.InputStream;
import java.io.IOException;

import com.knowgate.misc.Gadgets;

abstract class AndXServerMessageBlock extends ServerMessageBlock {

    private static final int ANDX_COMMAND_OFFSET  = 1;
    private static final int ANDX_RESERVED_OFFSET = 2;
    private static final int ANDX_OFFSET_OFFSET   = 3;

    private byte andxCommand        = (byte)0xFF;
    private int andxOffset          = 0;

    ServerMessageBlock andx = null;

    AndXServerMessageBlock() {
    }
    AndXServerMessageBlock( ServerMessageBlock andx ) {
        this.andx = andx;
        if( andx != null ) {
            andxCommand = andx.command;
        }
    }

    /* The SmbComReadAndXResponse can read from the InputStream
     * directly by implementing this method. The default
     * behavior is to arraycopy all bytes into the buffer and call
     * readBytesWireFormat. The alternative would have been to overload
     * the readAndXWireFormat method but that would have resulted in
     * copying a fairly large chunck of code into the subclass.
     */

    abstract int readBytesDirectWireFormat( InputStream in, int byteCount,
                byte[] buffer, int bufferIndex ) throws IOException;

    int getBatchLimit( byte command ) {
        /* the default limit is 0 batched messages before this
         * one, meaning this message cannot be batched.
         */
        return 0;
    }

    /*
     * We overload this method from ServerMessageBlock because
     * we want writeAndXWireFormat to write the parameterWords
     * and bytes. This is so we can write batched smbs because
     * all but the first smb of the chaain do not have a header
     * and therefore we do not want to writeHeaderWireFormat. We
     * just recursivly call writeAndXWireFormat.
     */

    int writeWireFormat( byte[] dst, int dstIndex ) {
        int start = headerStart = dstIndex;

        dstIndex += writeHeaderWireFormat( dst, dstIndex );
        dstIndex += writeAndXWireFormat( dst, dstIndex );
        length = dstIndex - start;

        if( digest != null ) {
            digest.sign( dst, headerStart, length, this, response );
        }

        return length;
    }

    /*
     * We overload this because we want readAndXWireFormat to
     * read the parameter words and bytes. This is so when
     * commands are batched together we can recursivly call
     * readAndXWireFormat without reading the non-existent header.
     */

    int readWireFormat( InputStream in,
                                    byte[] buffer,
                                    int bufferIndex )
                                    throws IOException {
        int start = bufferIndex;

        if( in.read( buffer, bufferIndex, HEADER_LENGTH ) != HEADER_LENGTH ) {
            throw new IOException( "unexpected EOF reading smb header" );
        }
        bufferIndex += readHeaderWireFormat( buffer, bufferIndex );
        bufferIndex += readAndXWireFormat( in, buffer, bufferIndex );

        length = bufferIndex - start;
        return length;
    }
    int writeAndXWireFormat( byte[] dst, int dstIndex ) {
        int start = dstIndex;

        wordCount = writeParameterWordsWireFormat( dst,
                                                start + ANDX_OFFSET_OFFSET + 2 );
        wordCount += 4; // for command, reserved, and offset
        dstIndex += wordCount + 1;
        wordCount /= 2;
        dst[start] = (byte)( wordCount & 0xFF );

        byteCount = writeBytesWireFormat( dst, dstIndex + 2 );
        dst[dstIndex++] = (byte)( byteCount & 0xFF );
        dst[dstIndex++] = (byte)(( byteCount >> 8 ) & 0xFF );
        dstIndex += byteCount;

        /* Normally, without intervention everything would batch
         * with everything else. If the below clause evaluates true
         * the andx command will not be written and therefore the
         * response will not read a batched command and therefore
         * the 'received' member of the response object will not
         * be set to true indicating the send and sendTransaction
         * methods that the next part should be sent. This is a
         * very indirect and simple batching control mechanism.
         */


        if( andx == null || USE_BATCHING == false ||
                                batchLevel >= getBatchLimit( andx.command )) {
            andxCommand = (byte)0xFF;
            andx = null;

            dst[start + ANDX_COMMAND_OFFSET] = (byte)0xFF;
            dst[start + ANDX_RESERVED_OFFSET] = (byte)0x00;
            dst[start + ANDX_OFFSET_OFFSET] = (byte)0x00;
            dst[start + ANDX_OFFSET_OFFSET + 1] = (byte)0x00;

            // andx not used; return
            return dstIndex - start;
        }

        /* The message provided to batch has a batchLimit that is
         * higher than the current batchLevel so we will now encode
         * that chained message. Before doing so we must increment
         * the batchLevel of the andx message in case it itself is an
         * andx message and needs to perform the same check as above.
         */

        andx.batchLevel = batchLevel + 1;


        dst[start + ANDX_COMMAND_OFFSET] = andxCommand;
        dst[start + ANDX_RESERVED_OFFSET] = (byte)0x00;
        andxOffset = dstIndex - headerStart;
        writeInt2( andxOffset, dst, start + ANDX_OFFSET_OFFSET );

        andx.useUnicode = useUnicode;
        if( andx instanceof AndXServerMessageBlock ) {

            /*
             * A word about communicating header info to andx smbs
             *
             * This is where we recursively invoke the provided andx smb
             * object to write it's parameter words and bytes to our outgoing
             * array. Incedentally when these andx smbs are created they are not
             * necessarily populated with header data because they're not writing
             * the header, only their body. But for whatever reason one might wish
             * to populate fields if the writeXxx operation needs this header data
             * for whatever reason. I copy over the uid here so it appears correct
             * in logging output. Logging of andx segments of messages inadvertantly
             * print header information because of the way toString always makes a
             * super.toString() call(see toString() at the end of all smbs classes).
             */

            andx.uid = uid;
            dstIndex += ((AndXServerMessageBlock)andx).writeAndXWireFormat( dst, dstIndex );
        } else {
            // the andx smb is not of type andx so lets just write it here and
            // were done.
            int andxStart = dstIndex;
            andx.wordCount = andx.writeParameterWordsWireFormat( dst, dstIndex );
            dstIndex += andx.wordCount + 1;
            andx.wordCount /= 2;
            dst[andxStart] = (byte)( andx.wordCount & 0xFF );

            andx.byteCount = andx.writeBytesWireFormat( dst, dstIndex + 2 );
            dst[dstIndex++] = (byte)( andx.byteCount & 0xFF );
            dst[dstIndex++] = (byte)(( andx.byteCount >> 8 ) & 0xFF );
            dstIndex += andx.byteCount;
        }

        return dstIndex - start;
    }
    int readAndXWireFormat( InputStream in,
                                    byte[] buffer,
                                    int bufferIndex )
                                    throws IOException {
        int start = bufferIndex;

        /*
         * read wordCount
         */

        if(( wordCount = in.read() ) == -1 ) {
            throw new IOException( "unexpected EOF reading smb wordCount" );
        }
        buffer[bufferIndex++] = (byte)( wordCount & 0xFF );

        /*
         * read parameterWords
         */

        if( wordCount != 0 ) {
            if( in.read( buffer, bufferIndex, wordCount * 2 ) != ( wordCount * 2 )) {
                throw new IOException( "unexpected EOF reading andx parameter words" );
            }

            /*
             * these fields are common to all andx commands
             * so let's populate them here
             */

            andxCommand = buffer[bufferIndex];
            bufferIndex += 2;
            andxOffset = readInt2( buffer, bufferIndex );
            bufferIndex += 2;

            if( andxOffset == 0 ) { /* Snap server workaround */
                andxCommand = (byte)0xFF;
            }

            /*
             * no point in calling readParameterWordsWireFormat if there are no more
             * parameter words. besides, win98 doesn't return "OptionalSupport" field
             */

            if( wordCount > 2 ) {
                bufferIndex += readParameterWordsWireFormat( buffer, bufferIndex );
            }
        }

        /*
         * read byteCount
         */

        if( in.read( buffer, bufferIndex, 2 ) != 2 ) {
            throw new IOException( "unexpected EOF reading smb byteCount" );
        }
        byteCount = readInt2( buffer, bufferIndex );
        bufferIndex += 2;

        /*
         * read bytes
         */

        if( byteCount != 0 ) {
            int n;
            n = readBytesDirectWireFormat( in, byteCount, buffer, bufferIndex );
            if( n == 0 ) {
                if( in.read( buffer, bufferIndex, byteCount ) != byteCount ) {
                    throw new IOException( "unexpected EOF reading andx bytes" );
                }
                n = readBytesWireFormat( buffer, bufferIndex );
            }
            bufferIndex += byteCount;
        }

        /*
         * if there is an andx and it itself is an andx then just recur by
         * calling this method for it. otherwise just read it's parameter words
         * and bytes as usual. Note how we can't just call andx.readWireFormat
         * because there's no header.
         */

        if( errorCode != 0 || andxCommand == (byte)0xFF ) {
            andxCommand = (byte)0xFF;
            andx = null;
        } else if( andx == null ) {
            andxCommand = (byte)0xFF;
            throw new IOException( "no andx command supplied with response" );
        } else {

            /*
             * This is where we take into account andxOffset
             *
             * Before we call readAndXWireFormat on the next andx
             * part we must take into account the andxOffset. The
             * input stream must be positioned at this location. The
             * new location is the just read andxOffset(say 68)
             * minus the current bufferIndex(say 65). But this packet
             * construction/deconstruction technique does not require that
             * the bufferIndex begin at 0. The header might be at another
             * location(say 4). So we must subtract the current buffer
             * index from the real start of the header and substract that
             * from the andxOffset(like 68 - ( 65 - 0 ) if headerStart
             * were 0 or 68 - ( 69 - 4 ) if the headerStart were 4. We
             * also need to communicate to our newly instantiated andx
             * smb the headerStart value so that it may perform the same
             * calculation as this is a recursive process.
             */

            bufferIndex += in.read( buffer, bufferIndex,
                                    andxOffset - ( bufferIndex - headerStart ));

            andx.headerStart = headerStart;
            andx.command = andxCommand;
            andx.errorCode = errorCode;
            andx.flags = flags;
            andx.flags2 = flags2;
            andx.tid = tid;
            andx.pid = pid;
            andx.uid = uid;
            andx.mid = mid;
            andx.useUnicode = useUnicode;

            if( andx instanceof AndXServerMessageBlock ) {
                bufferIndex += ((AndXServerMessageBlock)andx).readAndXWireFormat(
                                                in, buffer, andxOffset - headerStart );
            } else {

                /*
                 * Just a plain smb. Read it as normal.
                 */

                /*
                 * read wordCount
                 */

                if(( andx.wordCount = in.read() ) == -1 ) {
                    throw new IOException( "unexpected EOF reading smb wordCount" );
                }
                buffer[bufferIndex++] = (byte)( andx.wordCount & 0xFF );

                /*
                 * read parameterWords
                 */

                if( andx.wordCount != 0 ) {
                    if( in.read( buffer, bufferIndex, andx.wordCount * 2 ) !=
                                                                ( andx.wordCount * 2 )) {
                        throw new IOException( "unexpected EOF reading andx parameter words" );
                    }

                    /*
                     * no point in calling readParameterWordsWireFormat if there are no more
                     * parameter words. besides, win98 doesn't return "OptionalSupport" field
                     */

                    if( andx.wordCount > 2 ) {
                        bufferIndex +=
                                andx.readParameterWordsWireFormat( buffer, bufferIndex );
                    }
                }

                /*
                 * read byteCount
                 */

                if( in.read( buffer, bufferIndex, 2 ) != 2 ) {
                    throw new IOException( "unexpected EOF reading smb byteCount" );
                }
                andx.byteCount = readInt2( buffer, bufferIndex );
                bufferIndex += 2;

                /*
                 * read bytes
                 */

                if( andx.byteCount != 0 ) {
                    if( in.read( buffer, bufferIndex, andx.byteCount ) != andx.byteCount ) {
                        throw new IOException( "unexpected EOF reading andx bytes" );
                    }
                    andx.readBytesWireFormat( buffer, bufferIndex );
                    bufferIndex += andx.byteCount;
                }
            }
            andx.received = true;
        }

        return bufferIndex - start;
    }

    public String toString() {
        return new String( super.toString() +
            ",andxCommand=0x" + Gadgets.toHexString( andxCommand, 2 ) +
            ",andxOffset=" + andxOffset );
    }
}

package com.knowgate.jcifs.smb;

import java.security.MessageDigest;
import java.security.NoSuchAlgorithmException;

import com.knowgate.debug.*;
import com.knowgate.jcifs.Config;

/**
 * To filter 0 len updates and for debugging
 */

public class SigningDigest {

    private static final int LM_COMPATIBILITY = Config.getInt( "jcifs.smb.lmCompatibility", 0);


    private MessageDigest digest;
    private byte[] macSigningKey;
    private int updates;
    private int signSequence;

    public SigningDigest( SmbTransport transport,
                NtlmPasswordAuthentication auth ) throws SmbException {
        try {
            digest = MessageDigest.getInstance("MD5");
        } catch (NoSuchAlgorithmException ex) {
            if( DebugFile.trace )
                new ErrorHandler(ex);
            throw new SmbException( "MD5", ex );
        }

        try {
            switch (LM_COMPATIBILITY) {
            case 0:
            case 1:
            case 2:
                macSigningKey = new byte[40];
                auth.getUserSessionKey(transport.server.encryptionKey, macSigningKey, 0);
                System.arraycopy(auth.getUnicodeHash(transport.server.encryptionKey),
                            0, macSigningKey, 16, 24);
                break;
            case 3:
            case 4:
            case 5:
                macSigningKey = new byte[16];
                auth.getUserSessionKey(transport.server.encryptionKey, macSigningKey, 0);
                break;
            default:
                macSigningKey = new byte[40];
                auth.getUserSessionKey(transport.server.encryptionKey, macSigningKey, 0);
                System.arraycopy(auth.getUnicodeHash(transport.server.encryptionKey),
                            0, macSigningKey, 16, 24);
                break;
            }
        } catch( Exception ex ) {
            throw new SmbException( "", ex );
        }
        if( DebugFile.trace ) {
            DebugFile.writeln( "LM_COMPATIBILITY=" + LM_COMPATIBILITY );
        }
    }

    public void update( byte[] input, int offset, int len ) {
        if( DebugFile.trace ) {
            DebugFile.writeln( "update: " + updates + " " + offset + ":" + len );
        }
        if( len == 0 ) {
            return; /* CRITICAL */
        }
        digest.update( input, offset, len );
        updates++;
    }
    public byte[] digest() {
        byte[] b;

        b = digest.digest();

        if( DebugFile.trace ) {
            DebugFile.writeln( "digest: " );
        }
        updates = 0;

        return b;
    }

    /**
     * Performs MAC signing of the SMB.  This is done as follows.
     * The signature field of the SMB is overwritted with the sequence number;
     * The MD5 digest of the MAC signing key + the entire SMB is taken;
     * The first 8 bytes of this are placed in the signature field.
     *
     * @param data The data.
     * @param offset The starting offset at which the SMB header begins.
     * @param length The length of the SMB data starting at offset.
     */
    void sign(byte[] data, int offset, int length,
                ServerMessageBlock request, ServerMessageBlock response) {
        request.signSeq = signSequence;
        if( response != null ) {
            response.signSeq = signSequence + 1;
            response.verifyFailed = false;
        }

        try {
            update(macSigningKey, 0, macSigningKey.length);
            int index = offset + ServerMessageBlock.SIGNATURE_OFFSET;
            for (int i = 0; i < 8; i++) data[index + i] = 0;
            ServerMessageBlock.writeInt4(signSequence, data, index);
            update(data, offset, length);
            System.arraycopy(digest(), 0, data, index, 8);
        } catch (Exception ex) {
            if( DebugFile.trace )
                new ErrorHandler(ex);
        } finally {
            signSequence += 2;
        }
    }

    /**
     * Performs MAC signature verification.  This calculates the signature
     * of the SMB and compares it to the signature field on the SMB itself.
     *
     * @param data The data.
     * @param offset The starting offset at which the SMB header begins.
     * @param length The length of the SMB data starting at offset.
     */
    boolean verify(byte[] data, int offset, ServerMessageBlock response) {
        update(macSigningKey, 0, macSigningKey.length);
        int index = offset;
        update(data, index, ServerMessageBlock.SIGNATURE_OFFSET);
        index += ServerMessageBlock.SIGNATURE_OFFSET;
        byte[] sequence = new byte[8];
        ServerMessageBlock.writeInt4(response.signSeq, sequence, 0);
        update(sequence, 0, sequence.length);
        index += 8;
        if( response.command == ServerMessageBlock.SMB_COM_READ_ANDX ) {
            /* SmbComReadAndXResponse reads directly from the stream into separate byte[] b.
             */
            SmbComReadAndXResponse raxr = (SmbComReadAndXResponse)response;
            int length = response.length - raxr.dataLength;
            update(data, index, length - ServerMessageBlock.SIGNATURE_OFFSET - 8);
            update(raxr.b, raxr.off, raxr.dataLength);
        } else {
            update(data, index, response.length - ServerMessageBlock.SIGNATURE_OFFSET - 8);
        }
        byte[] signature = digest();
        for (int i = 0; i < 8; i++) {
            if (signature[i] != data[offset + ServerMessageBlock.SIGNATURE_OFFSET + i]) {
                if( DebugFile.trace ) {
                    DebugFile.writeln( "signature verification failure" );
                }
                return response.verifyFailed = true;
            }
        }

        return response.verifyFailed = false;
    }
}


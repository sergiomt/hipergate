/* jcifs smb client library in Java
 * Copyright (C) 2004  "Michael B. Allen" <jcifs at samba dot org>
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

public interface NtStatus {

    /* Don't bother to edit this. Everthing within the interface
     * block is automatically generated from the ntstatus package.
     */

    public static final int NT_STATUS_OK = 0x00000000;
    public static final int NT_STATUS_UNSUCCESSFUL = 0xC0000001;
    public static final int NT_STATUS_NOT_IMPLEMENTED = 0xC0000002;
    public static final int NT_STATUS_INVALID_INFO_CLASS = 0xC0000003;
    public static final int NT_STATUS_ACCESS_VIOLATION = 0xC0000005;
    public static final int NT_STATUS_INVALID_HANDLE = 0xC0000008;
    public static final int NT_STATUS_NO_SUCH_FILE = 0xC000000f;
    public static final int NT_STATUS_ACCESS_DENIED = 0xC0000022;
    public static final int NT_STATUS_OBJECT_NAME_INVALID = 0xC0000033;
    public static final int NT_STATUS_OBJECT_NAME_NOT_FOUND = 0xC0000034;
    public static final int NT_STATUS_OBJECT_NAME_COLLISION = 0xC0000035;
    public static final int NT_STATUS_PORT_DISCONNECTED = 0xC0000037;
    public static final int NT_STATUS_OBJECT_PATH_NOT_FOUND = 0xC000003a;
    public static final int NT_STATUS_OBJECT_PATH_SYNTAX_BAD = 0xC000003b;
    public static final int NT_STATUS_SHARING_VIOLATION = 0xC0000043;
    public static final int NT_STATUS_DELETE_PENDING = 0xC0000056;
    public static final int NT_STATUS_NO_SUCH_USER = 0xC0000064;
    public static final int NT_STATUS_WRONG_PASSWORD = 0xC000006a;
    public static final int NT_STATUS_LOGON_FAILURE = 0xC000006d;
    public static final int NT_STATUS_ACCOUNT_RESTRICTION = 0xC000006e;
    public static final int NT_STATUS_INVALID_LOGON_HOURS = 0xC000006f;
    public static final int NT_STATUS_INVALID_WORKSTATION = 0xC0000070;
    public static final int NT_STATUS_PASSWORD_EXPIRED = 0xC0000071;
    public static final int NT_STATUS_ACCOUNT_DISABLED = 0xC0000072;
    public static final int NT_STATUS_INSTANCE_NOT_AVAILABLE = 0xC00000ab;
    public static final int NT_STATUS_PIPE_NOT_AVAILABLE = 0xC00000ac;
    public static final int NT_STATUS_INVALID_PIPE_STATE = 0xC00000ad;
    public static final int NT_STATUS_PIPE_BUSY = 0xC00000ae;
    public static final int NT_STATUS_PIPE_DISCONNECTED = 0xC00000b0;
    public static final int NT_STATUS_PIPE_CLOSING = 0xC00000b1;
    public static final int NT_STATUS_PIPE_LISTENING = 0xC00000b3;
    public static final int NT_STATUS_FILE_IS_A_DIRECTORY = 0xC00000ba;
    public static final int NT_STATUS_BAD_NETWORK_NAME = 0xC00000cc;
    public static final int NT_STATUS_NOT_A_DIRECTORY = 0xC0000103;
    public static final int NT_STATUS_CANNOT_DELETE = 0xC0000121;
    public static final int NT_STATUS_PIPE_BROKEN = 0xC000014b;
    public static final int NT_STATUS_LOGON_TYPE_NOT_GRANTED = 0xC000015b;
    public static final int NT_STATUS_ACCOUNT_LOCKED_OUT = 0xC0000234;
    public static final int NT_STATUS_PATH_NOT_COVERED = 0xC0000257;

    static final int[] NT_STATUS_CODES = {
        NT_STATUS_OK,
        NT_STATUS_UNSUCCESSFUL,
        NT_STATUS_NOT_IMPLEMENTED,
        NT_STATUS_INVALID_INFO_CLASS,
        NT_STATUS_ACCESS_VIOLATION,
        NT_STATUS_INVALID_HANDLE,
        NT_STATUS_NO_SUCH_FILE,
        NT_STATUS_ACCESS_DENIED,
        NT_STATUS_OBJECT_NAME_INVALID,
        NT_STATUS_OBJECT_NAME_NOT_FOUND,
        NT_STATUS_OBJECT_NAME_COLLISION,
        NT_STATUS_PORT_DISCONNECTED,
        NT_STATUS_OBJECT_PATH_NOT_FOUND,
        NT_STATUS_OBJECT_PATH_SYNTAX_BAD,
        NT_STATUS_SHARING_VIOLATION,
        NT_STATUS_DELETE_PENDING,
        NT_STATUS_NO_SUCH_USER,
        NT_STATUS_WRONG_PASSWORD,
        NT_STATUS_LOGON_FAILURE,
        NT_STATUS_ACCOUNT_RESTRICTION,
        NT_STATUS_INVALID_LOGON_HOURS,
        NT_STATUS_INVALID_WORKSTATION,
        NT_STATUS_PASSWORD_EXPIRED,
        NT_STATUS_ACCOUNT_DISABLED,
        NT_STATUS_INSTANCE_NOT_AVAILABLE,
        NT_STATUS_PIPE_NOT_AVAILABLE,
        NT_STATUS_INVALID_PIPE_STATE,
        NT_STATUS_PIPE_BUSY,
        NT_STATUS_PIPE_DISCONNECTED,
        NT_STATUS_PIPE_CLOSING,
        NT_STATUS_PIPE_LISTENING,
        NT_STATUS_FILE_IS_A_DIRECTORY,
        NT_STATUS_BAD_NETWORK_NAME,
        NT_STATUS_NOT_A_DIRECTORY,
        NT_STATUS_CANNOT_DELETE,
        NT_STATUS_PIPE_BROKEN,
        NT_STATUS_LOGON_TYPE_NOT_GRANTED,
        NT_STATUS_ACCOUNT_LOCKED_OUT,
        NT_STATUS_PATH_NOT_COVERED,
    };

    static final String[] NT_STATUS_MESSAGES = {
        "The operation completed successfully.",
        "A device attached to the system is not functioning.",
        "Incorrect function.",
        "The parameter is incorrect.",
        "Invalid access to memory location.",
        "The handle is invalid.",
        "The system cannot find the file specified.",
        "Access is denied.",
        "The filename, directory name, or volume label syntax is incorrect.",
        "The system cannot find the file specified.",
        "Cannot create a file when that file already exists.",
        "The handle is invalid.",
        "The system cannot find the path specified.",
        "The specified path is invalid.",
        "The process cannot access the file because it is being used by another process.",
        "Access is denied.",
        "The specified user does not exist.",
        "The specified network password is not correct.",
        "Logon failure: unknown user name or bad password.",
        "Logon failure: user account restriction.",
        "Logon failure: account logon time restriction violation.",
        "Logon failure: user not allowed to log on to this computer.",
        "Logon failure: the specified account password has expired.",
        "Logon failure: account currently disabled.",
        "All pipe instances are busy.",
        "All pipe instances are busy.",
        "The pipe state is invalid.",
        "All pipe instances are busy.",
        "No process is on the other end of the pipe.",
        "The pipe is being closed.",
        "Waiting for a process to open the other end of the pipe.",
        "Access is denied.",
        "The network name cannot be found.",
        "The directory name is invalid.",
        "Access is denied.",
        "The pipe has been ended.",
        "Logon failure: the user has not been granted the requested logon type at this computer.",
        "The referenced account is currently locked out and may not be logged on to.",
        "The remote system is not reachable by the transport.",
    };
}


/**
 *
 *  Java FTP client library.
 *
 *  Copyright (C) 2000-2003 Enterprise Distributed Technologies Ltd
 *
 *  www.enterprisedt.com
 *
 *  This library is free software; you can redistribute it and/or
 *  modify it under the terms of the GNU Lesser General Public
 *  License as published by the Free Software Foundation; either
 *  version 2.1 of the License, or (at your option) any later version.
 *
 *  This library is distributed in the hope that it will be useful,
 *  but WITHOUT ANY WARRANTY; without even the implied warranty of
 *  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
 *  Lesser General Public License for more details.
 *
 *  You should have received a copy of the GNU Lesser General Public
 *  License along with this library; if not, write to the Free Software
 *  Foundation, Inc., 59 Temple Place, Suite 330, Boston, MA  02111-1307  USA
 *
 *  Bug fixes, suggestions and comments should be sent to bruce@enterprisedt.com
 *
 *  Change Log:
 *
 *        $Log: FTPReply.java,v $
 *        Revision 1.1.1.1  2005/06/23 15:23:01  smontoro
 *        hipergate backend
 *
 *        Revision 1.1  2004/02/07 03:15:20  hipergate
 *        v2.0 pre-alpha
 *
 *        Revision 1.1  2002/11/19 22:01:25  bruceb
 *        changes for 1.2
 *
 *
 */

package com.enterprisedt.net.ftp;

/**
 *  Encapsulates the FTP server reply
 *
 *  @author      Bruce Blackshaw
 *  @version     $Revision: 1.1.1.1 $
 */
public class FTPReply {

    /**
     *  Revision control id
     */
    private static String cvsId = "@(#)$Id: FTPReply.java,v 1.1.1.1 2005/06/23 15:23:01 smontoro Exp $";

    /**
     *  Reply code
     */
    private String replyCode;

    /**
     *  Reply text
     */
    private String replyText;


    /**
     *  Constructor. Only to be constructed
     *  by this package, hence package access
     *
     *  @param  replyCode  the server's reply code
     *  @param  replyText  the server's reply text
     */
    FTPReply(String replyCode, String replyText) {
        this.replyCode = replyCode;
        this.replyText = replyText;
    }

    /**
     *  Getter for reply code
     *
     *  @return server's reply code
     */
    public String getReplyCode() {
        return replyCode;
    }

    /**
     *  Getter for reply text
     * 
     *  @return server's reply text
     */
    public String getReplyText() {
        return replyText;
    }

}

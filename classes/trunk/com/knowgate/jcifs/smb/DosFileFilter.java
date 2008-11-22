/* jcifs smb client library in Java
 * Copyright (C) 2003  "Michael B. Allen" <jcifs at samba dot org>
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

public class DosFileFilter implements SmbFileFilter {

    protected String wildcard;
    protected int attributes;

    public DosFileFilter( String wildcard, int attributes ) {
        this.wildcard = wildcard;
        this.attributes = attributes;
    }

    /**
     * This always returns <tt>true</tt> as the wildcard and
     * attributes members are passed to the server which uses them to
     * filter on behalf of the client. Sub-classes might overload this
     * method to further filter the list however.
     */
    public boolean accept( SmbFile file ) throws SmbException {
        return true;
    }
}

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

public class DfsReferral extends SmbException {

	private static final long serialVersionUID = 1l;
	
    public String path;     // Path relative to tree from which this referral was thrown
    public String node;     // Server and share
    public String server;   // Server
    public String share;    // Share
    public String nodepath; // Path relative to tree
    public boolean resolveHashes;

    public String toString() {
        return "DfsReferral[path=" + path +
            ",node=" + node +
            ",server=" + server +
            ",share=" + share +
            ",nodepath=" + nodepath +
            ",resolveHashes=" + resolveHashes + "]";
    }
}

package com.knowgate.misc;

import java.io.InputStream;
import java.io.Serializable;
import java.io.EOFException;

import com.knowgate.debug.DebugFile;

/*
 * ByteStore.java
 *
 *
 * Created: Sun Sep 19 17:22:13 1999
 *
 * Copyright (C) 1999-2000 Sebastian Schaffert
 *
 * This program is free software; you can redistribute it and/or
 * modify it under the terms of the GNU General Public License
 * as published by the Free Software Foundation; either version 2
 * of the License, or (at your option) any later version.
 *
 * This program is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 * GNU General Public License for more details.
 *
 * You should have received a copy of the GNU General Public License
 * along with this program; if not, write to the Free Software
 * Foundation, Inc., 59 Temple Place - Suite 330, Boston, MA  02111-1307, USA.
 */

/**
 *
 * @author Sebastian Schaffert
 * @version
 */
@SuppressWarnings("serial")
public class ByteStore implements Serializable {

    byte[] bytes;

    String content_type=null;
    String content_encoding=null;
    String name;
    String description="";

    public ByteStore(byte[] b, String sContentType) {
	bytes=b;
        content_type = sContentType;
    }

    public void setDescription(String s) {
	description=s;
    }

    public String getDescription() {
	return description;
    }

    public void setContentType(String s) {
	content_type=s;
    }

    public String getContentType() {
	return content_type;
    /*
    if(content_type != null) {
	    return content_type;
	} else {
	    content_type=WebMailServer.getStorage().getMimeType(name);
	    return content_type;
	}
      */
    }

    public void setContentEncoding(String s) {
	content_encoding=s;
    }

    public String getContentEncoding() {
	return content_encoding;
    }

    public byte[] getBytes() {
	return bytes;
    }

    public void setName(String s) {
	name=s;
    }

    public String getName() {
	return name;
    }

    public int getSize() {
	return bytes.length;
    }


    /**
     * Create a ByteStore out of an InputStream
     */
    public static ByteStore getBinaryFromIS(InputStream in, int nr_bytes_to_read, String sContentType) {
	byte[] s=new byte[nr_bytes_to_read+100];
	int count=0;
	int lastread=0;
	if(in != null) {
	    synchronized(in) {
		while(count < s.length) {
		    try {
			lastread=in.read(s,count,nr_bytes_to_read-count);
		    } catch(EOFException ex) {
                        if (DebugFile.trace) DebugFile.writeln("EOFException " + ex.getMessage());
			lastread=0;
		    } catch(Exception z) {
                        if (DebugFile.trace) DebugFile.writeln(z.getClass().getName() + " " + z.getMessage());
			lastread=0;
		    }
		    count+=lastread;
		    if(lastread < 1) break;
		}
	    }
	    byte[] s2=new byte[count+1];
	    for(int i=0; i<count+1;i++) {
		s2[i]=s[i];
	    }
	    ByteStore d=new ByteStore(s2, sContentType);
	    return d;
	} else {
	    return null;
	}
    }
} // ByteStore

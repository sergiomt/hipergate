package org.jical;

import java.io.IOException;
import java.io.InputStream;
import java.io.InputStreamReader;
import java.io.BufferedReader;
import java.io.Reader;
import java.io.UnsupportedEncodingException;
import java.util.Iterator;
import java.util.List;
import java.util.ArrayList;

public class LineIterator implements Iterator {

    private BufferedReader m_reader;
    private List m_lines = new ArrayList();

    public LineIterator( InputStream stream ) {
	this( new InputStreamReader( stream ) );
    }
    public LineIterator( InputStream stream, String enc ) throws UnsupportedEncodingException {
	this( new InputStreamReader( stream, enc ) );
    }
    public LineIterator( Reader reader ) {
	if ( reader instanceof BufferedReader ) {
	    m_reader = (BufferedReader) reader;
	} else {
	    m_reader = new BufferedReader( reader );
	}
    }

    public boolean hasNext() {
	checkLines();
	return ( !m_lines.isEmpty() );
    }
    public Object next() {
	if ( hasNext() ) {
	    return m_lines.remove( 0 );
	}
	return null;
    }
    public void remove() throws UnsupportedOperationException {
	throw new UnsupportedOperationException();
    }


    private void checkLines() {
	synchronized ( m_lines ) {
	    if ( (m_lines.size()) < 1 && (m_reader != null) ) {
		try {
		    String line = m_reader.readLine();
		    if ( line != null ) {
			m_lines.add( new StringBuffer( line ) );
			checkLines();
		    } else {
			m_reader.close();
			m_reader = null;
		    }
		}
		catch ( IOException ex ) {
		    ex.printStackTrace();
		}
	    }
	}
    }
}

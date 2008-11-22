package org.jical;

/*
 * Never used..
import java.io.IOException;
import java.io.InputStream;
import java.io.InputStreamReader;
import java.io.BufferedReader;
import java.io.UnsupportedEncodingException;
*/
import java.io.Reader;
import java.util.Iterator;
import java.util.List;
import java.util.ArrayList;

public class UnfoldingLineIterator implements Iterator {

	private Iterator m_iterator;
	private List m_lines = new ArrayList();

	public UnfoldingLineIterator( Reader reader ) {
		this( new LineIterator( reader ) );
	}
	public UnfoldingLineIterator( Iterator iterator ) {
		m_iterator = iterator;
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
			if ( m_lines.size() < 2 && m_iterator.hasNext() ) {
				StringBuffer line = (StringBuffer) m_iterator.next();
				if ( line != null ) {
					m_lines.add( line );
					unfoldLines();
					checkLines();
				}
			}
		}
	}
	
	private void unfoldLines() {
		synchronized ( m_lines ) {
			int i = 1;
			while ( i < m_lines.size() ) {
				StringBuffer line = (StringBuffer) m_lines.get( i );
				char c = line.charAt( 0 );
				if ( c == ' ' || c == '\t' ) {
					m_lines.remove( i );
					StringBuffer pline = (StringBuffer) m_lines.get( i - 1 );
					line.deleteCharAt( 0 );
					pline.append( line );
				} else {
					i++;
				}
			}
		}
	}

	
}

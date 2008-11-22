package org.jical;

import java.io.FileInputStream;
import java.io.InputStreamReader;
import java.io.Reader;
import java.util.Iterator;
//import java.util.Map;
//import java.util.regex.Pattern;
//import java.util.regex.Matcher;

public class ContentLineIterator implements Iterator {
    private Iterator m_iterator;

    public ContentLineIterator( Reader reader ) {
	this( new  UnfoldingLineIterator( new LineIterator( reader ) ) );
    }
    public ContentLineIterator( Iterator iterator ) {
	m_iterator = iterator;
    }

    public boolean hasNext() {
	return m_iterator.hasNext();
    }
    public Object next() {
	if ( hasNext() ) {
	    CharSequence cs = (CharSequence) m_iterator.next();
	    ContentLine cl = ContentLineParser.parse( cs );
	    if ( cl != null ) {
		return cl;
	    }
	}
	return null;
    }
    public void remove() throws UnsupportedOperationException {
	throw new  UnsupportedOperationException();
    }


    public static void main( String[] args ) throws Exception {
	Iterator it = new ContentLineIterator( new InputStreamReader( new FileInputStream ( args[0] ) ) );
	while ( it.hasNext() ) {
	    ContentLine cl = (ContentLine) it.next();
	    System.out.println( cl.toString() );
	}
    }
}

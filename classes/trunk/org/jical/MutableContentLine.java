package org.jical;

import java.util.Collections;
import java.util.HashMap;
import java.util.Iterator;
import java.util.Map;

public class MutableContentLine implements ContentLine {
    private String m_name;
    private String m_value;
    private Map m_parameters = new HashMap();
    private Map m_unmodifiableParameters = Collections.unmodifiableMap( m_parameters );

    public String getName() {
	return m_name;
    }
    public void setName( String name ) {
	m_name = name;
    }
    public String getValue() {
	return m_value;
    }
    public void setValue( String value ) {
	m_value = value;
    }
    public Map getParameters() {
	return m_unmodifiableParameters;
    }
    public Map getMutableParameters() {
	return m_parameters;
    }

    public String toString() {
	String s = getName();
	Iterator it = getParameters().entrySet().iterator();
	while ( it.hasNext() ) {
	    Map.Entry e = (Map.Entry) it.next();
	    s += ";" + e.getKey() + "=\"" + e.getValue() +"\"";
	}
	s+= ":"+getValue();
	return s;
    }

    private String m_rawline;
    public String getRawLine() {
	return m_rawline;
    }
    public void setRawLine( String rawline ) {
	m_rawline = rawline;
    }
}

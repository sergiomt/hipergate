package org.jical;

//import java.io.InputStreamReader;
//import java.io.FileInputStream;
//import java.util.Iterator;
import java.util.Map;
import java.util.regex.Matcher;
import java.util.regex.Pattern;

public class ContentLineParser {

    private static final String RR_ALPHA = "A-Za-z";
    private static final String RR_DIGIT = "0-9";
    private static final String RR_DQUOTE = "\\\"";
    private static final String RR_WSP = " \\t";
    private static final String RR_CTL = "\\x00-\\x08\\x0A-\\x1F\\x7F";
    private static final String RR_SEP = ";:,";

    private static final String R_QSAFE_CHAR = "[^"+RR_CTL+RR_DQUOTE+"]";
    private static final String R_SAFE_CHAR = "[^"+RR_CTL+RR_DQUOTE+RR_SEP+"]";
    private static final String R_VALUE_CHAR = "[^"+RR_CTL+"]";
    private static final String R_NAME_CHAR = "[\\-"+RR_ALPHA+RR_DIGIT+"]";

    private static final String RC_PARAM_VALUE = "(?:(?:"+RR_DQUOTE+"("+R_QSAFE_CHAR+"*)"+RR_DQUOTE+")|("+R_SAFE_CHAR+"*))";
    private static final String RC_PARAM = "("+R_NAME_CHAR+"*)="+RC_PARAM_VALUE+"[;:]";
    private static final String RC_NAME = "("+R_NAME_CHAR+"*)[;:]";

    private static final Pattern NAME_PATTERN = Pattern.compile( RC_NAME );
    private static final Pattern PARAM_PATTERN = Pattern.compile( RC_PARAM );

    public static ContentLine parse( CharSequence cs ) {
	Matcher nameMatcher = NAME_PATTERN.matcher( cs );
	Matcher paramMatcher = PARAM_PATTERN.matcher( cs );
	int start = 0;
	if ( nameMatcher.find( start ) ) {
	    MutableContentLine contentLine = new MutableContentLine();
	    {
		contentLine.setRawLine( cs.toString() );
	    }
	    {
		contentLine.setName( nameMatcher.group( 1 ) );
		start = nameMatcher.end();
	    }
	    if ( cs.charAt( start - 1 ) == ';' ) {
		Map params = contentLine.getMutableParameters();
		while ( paramMatcher.find( start ) ) {
		    String key = paramMatcher.group(1);
		    String val = paramMatcher.group(2);
		    if ( val == null ) {
			val = paramMatcher.group(3);
		    }
		    params.put( key, val );
		    start = paramMatcher.end();
		}
	    }
	    {
		contentLine.setValue( cs.subSequence( start, cs.length() ).toString() );
	    }
	    return contentLine;
	}
	return null;
    }
}

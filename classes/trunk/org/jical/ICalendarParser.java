/*
 * iCalenderParser.java
 *
 * Created on August 1, 2002, 9:01 PM
 *
 * Stores an icalendar as a java object.
 * Can parse an ICalendar file and create the ICalendar Java Object from
 * that ICalendar file.
 *
 * Currently, this is a partial implementation. Its purpose is to parse an iCal file
 * and create a freebusy string loadable out to a file or as a web-response if
 * a URL.
 *
 */

package org.jical;

/**
 *
 * @author  sfg
 * RFC 2445
 *
 */

import java.io.BufferedReader;
import java.io.File;
import java.io.FileInputStream;
import java.io.InputStreamReader;
import java.text.SimpleDateFormat;
import java.util.Date;
import java.util.StringTokenizer;
import java.util.TimeZone;
import java.util.logging.Logger;

public class ICalendarParser {

    private String              thisLine;
    private ICalendar           ical;
    private ICalendarVEvent     iCalEvent;
    private ICalendarTimeZone   icalTimeZone;
    // If parsing timezone cannot be parsing others.
    private boolean             icalTimeZoneParser;
    private boolean             icalEventParser;
    private String              timeZoneType;
    private TimeZone            gmt;

    private int                 lineCtr;

    // Java logger for all error/interesting messages.
    private Logger logger = Logger.getLogger(this.getClass().getName());



    /** Creates a new instance of ICalendar. */
    public ICalendarParser() {
    }

    /** Read ICalendar from file.
     * @param iCalFilePath File name.
     * @return The ICalendar.
     */
    public ICalendar parse(java.lang.String iCalFilePath) {
        File iCalFile = new File(iCalFilePath);
        if (iCalFile.isFile())
        {
            parse(iCalFile);
        }
        else
        {
            logger.fine("The input file is not a file! File provided:" + iCalFilePath);
            ical = null;
        }
        return ical;
    }

    /** Read ICalendar from file.
     * @param iCalFile File.
     * @return The ICalendar.
     */
    public ICalendar parse(File iCalFile) {
        return parse(iCalFile,null);
    }

    public ICalendar parse(File iCalFile, String enc) {
        // Setup Log4J stuff..
        gmt = TimeZone.getTimeZone("GMT");
        //logcat = Category.getInstance(ICalendarParser.class.getName());
        // Must run, Initialisation stuff.
        //logcat.info("Reading:" + iCalFile.toString());
        // Read ICalendar File in and parse it creating the relevant attributes.
        // File iCalFile = new File(iCalFilePath);
        try
        {
            FileInputStream fin     = new FileInputStream(iCalFile);
            BufferedReader myInput = null;
            if (enc == null)
                myInput = new BufferedReader(new InputStreamReader(fin));
            else
                myInput = new BufferedReader(new InputStreamReader(fin, enc));
            String buildLine        = null;

            /* Two loops, first joins lines together, second processes lines..
             */
            while((thisLine = myInput.readLine()) != null)
            {
                /*
                * 4.1 Content Lines
                * That is, a long
                * line can be split between any two characters by inserting a CRLF
                * immediately followed by a single linear white space character (i.e.,
                * SPACE, US-ASCII decimal 32 or HTAB, US-ASCII decimal 9)
                *
                */

                lineCtr++;
                if (thisLine.startsWith(" ")
                ||  thisLine.startsWith("\u0032 ")
                ||  thisLine.startsWith("\u0009") )
                {
                    buildLine = buildLine + thisLine.substring(1);
                }
                else if (buildLine != null) {
                    try {
                        processLine (buildLine);
                    }
                    catch (Exception e) {
                        logger.fine("Error processing line of ICalendar, line:" + lineCtr
                                            + "iCal Line = " + buildLine
                                            + "Exception" + e);
                    }

                    buildLine = thisLine;
                }
                else
                {
                    buildLine = thisLine;
                }
            }
        }
        catch(Exception e)
        {
            e.printStackTrace(System.err);
        }
        return ical;
    }
    public void processLine(java.lang.String iCalLine) {

    	if (iCalLine.startsWith("BEGIN:VCALENDAR") )
        {
            // Start a new ICalendar. Null all values.
            // This should be the first item in the calendar.
            /*
             4.4 ICalendar Object
             The Calendaring and Scheduling Core Object is a collection of
            calendaring and scheduling information. Typically, this information
            will consist of a single ICalendar object. However, multiple
            ICalendar objects can be sequentially grouped together. The first
            line and last line of the ICalendar object MUST contain a pair of
            ICalendar object delimiter strings. The syntax for an ICalendar
            object is as follows:
                icalobject = 1*("BEGIN" ":" "VCALENDAR" CRLF
                      icalbody
                        "END" ":" "VCALENDAR" CRLF)
             The following is a simple example of an ICalendar object:
             BEGIN:VCALENDAR
             VERSION:2.0
             PRODID:-//hacksw/handcal//NONSGML v1.0//EN
             BEGIN:VEVENT
             DTSTART:19970714T170000Z
             DTEND:19970715T035959Z
             SUMMARY:Bastille Day Party
             END:VEVENT
             END:VCALENDAR
             */
            ical = new ICalendar();
        }
        else if (iCalLine.startsWith("END:VCALENDAR") )
        {

        }
        else if (iCalLine.startsWith("CALSCALE") )
        {
            /*
            4.7 Calendar Properties

               The Calendar Properties are attributes that apply to the ICalendar
               object, as a whole. These properties do not appear within a calendar
               component. They SHOULD be specified after the "BEGIN:VCALENDAR"
               property and prior to any calendar component.

            4.7.1 Calendar Scale

               Property Name: CALSCALE

               Purpose: This property defines the calendar scale used for the
               calendar information specified in the ICalendar object.
               Value Type: TEXT

               Property Parameters: Non-standard property parameters can be
               specified on this property.

               Conformance: Property can be specified in an ICalendar object. The
               default value is "GREGORIAN".

               Description: This memo is based on the Gregorian calendar scale. The
               Gregorian calendar scale is assumed if this property is not specified
               in the ICalendar object. It is expected that other calendar scales
               will be defined in other specifications or by future versions of this
               memo.

               Format Definition: The property is defined by the following notation:

                 calscale   = "CALSCALE" calparam ":" calvalue CRLF

                 calparam   = *(";" xparam)

                 calvalue   = "GREGORIAN" / iana-token

               Example: The following is an example of this property:

                 CALSCALE:GREGORIAN

            */

            ical.setCalScale(extractAttribute(iCalLine, "CALSCALE"));
        }

        else if (iCalLine.startsWith("PRODID") )
        {
            /*
             4.7.3 Product Identifier

               Property Name: PRODID

               Purpose: This property specifies the identifier for the product that
               created the ICalendar object.

               Value Type: TEXT

               Property Parameters: Non-standard property parameters can be
               specified on this property.

               Conformance: The property MUST be specified once in an ICalendar
               object.

               Description: The vendor of the implementation SHOULD assure that this
               is a globally unique identifier; using some technique such as an FPI
               value, as defined in [ISO 9070].

               This property SHOULD not be used to alter the interpretation of an
               ICalendar object beyond the semantics specified in this memo. For
               example, it is not to be used to further the understanding of non-
               standard properties.

               Format Definition: The property is defined by the following notation:

                 prodid     = "PRODID" pidparam ":" pidvalue CRLF
                 pidparam   = *(";" xparam)

                 pidvalue   = text
                 ;Any text that describes the product and version
                 ;and that is generally assured of being unique.

               Example: The following is an example of this property. It does not
               imply that English is the default language.

                 PRODID:-//ABC Corporation//NONSGML My Product//EN

             */
            ical.setProdId(extractAttribute(iCalLine, "PRODID"));
        }
        else if (iCalLine.startsWith("VERSION") )
        {
            /*
             4.7.4 Version

               Property Name: VERSION

               Purpose: This property specifies the identifier corresponding to the
               highest version number or the minimum and maximum range of the
               ICalendar specification that is required in order to interpret the
               ICalendar object.

               Value Type: TEXT

               Property Parameters: Non-standard property parameters can be
               specified on this property.

               Conformance: This property MUST be specified by an ICalendar object,
               but MUST only be specified once.

               Description: A value of "2.0" corresponds to this memo.

               Format Definition: The property is defined by the following notation:

                 version    = "VERSION" verparam ":" vervalue CRLF

                 verparam   = *(";" xparam)

                 vervalue   = "2.0"         ;This memo
                            / maxver
                            / (minver ";" maxver)

                 minver     = <A IANA registered ICalendar version identifier>
                 ;Minimum ICalendar version needed to parse the ICalendar object

                 maxver     = <A IANA registered ICalendar version identifier>
                 ;Maximum ICalendar version needed to parse the ICalendar object

               Example: The following is an example of this property:

                 VERSION:2.0

             */
            ical.setVersion(extractAttribute(iCalLine, "VERSION"));
        }
        else if (iCalLine.startsWith("ATTACH") )
        {
            /*
            4.8 Component Properties

               The following properties can appear within calendar components, as
               specified by each component property definition.

            4.8.1 Descriptive Component Properties

               The following properties specify descriptive information about
               calendar components.

            4.8.1.1 Attachment

               Property Name: ATTACH

               Purpose: The property provides the capability to associate a document
               object with a calendar component.

               Value Type: The default value type for this property is URI. The
               value type can also be set to BINARY to indicate inline binary
               encoded content information.

               Property Parameters: Non-standard, inline encoding, format type and
               value data type property parameters can be specified on this
               property.

               Conformance: The property can be specified in a "VEVENT", "VTODO",
               "VJOURNAL" or "VALARM" calendar components.

               Description: The property can be specified within "VEVENT", "VTODO",
               "VJOURNAL", or "VALARM" calendar components. This property can be
               specified multiple times within an ICalendar object.

               Format Definition: The property is defined by the following notation:

                 attach     = "ATTACH" attparam ":" uri  CRLF

                 attach     =/ "ATTACH" attparam ";" "ENCODING" "=" "BASE64"
                               ";" "VALUE" "=" "BINARY" ":" binary

                 attparam   = *(

                            ; the following is optional,
                            ; but MUST NOT occur more than once

                            (";" fmttypeparam) /

                            ; the following is optional,
                            ; and MAY occur more than once

                            (";" xparam)

                            )

               Example: The following are examples of this property:

                 ATTACH:CID:jsmith.part3.960817T083000.xyzMail@host1.com

                 ATTACH;FMTTYPE=application/postscript:ftp://xyzCorp.com/pub/
                  reports/r-960812.ps

             */
        	if (icalEventParser)
            {
                iCalEvent.setAttach(extractAttribute(iCalLine, "ATTACH"));
            }

        }
        else if (iCalLine.startsWith("CATEGORIES") )
        {
            /*
             4.8.1.2 Categories

               Property Name: CATEGORIES

               Purpose: This property defines the categories for a calendar
               component.

               Value Type: TEXT

               Property Parameters: Non-standard and language property parameters
               can be specified on this property.

               Conformance: The property can be specified within "VEVENT", "VTODO"
               or "VJOURNAL" calendar components.

               Description: This property is used to specify categories or subtypes
               of the calendar component. The categories are useful in searching for
               a calendar component of a particular type and category. Within the
               "VEVENT", "VTODO" or "VJOURNAL" calendar components, more than one
               category can be specified as a list of categories separated by the
               COMMA character (US-ASCII decimal 44).

               Format Definition: The property is defined by the following notation:

                 categories = "CATEGORIES" catparam ":" text *("," text)
                              CRLF

                 catparam   = *(

                            ; the following is optional,
                            ; but MUST NOT occur more than once

                            (";" languageparam ) /

                            ; the following is optional,
                            ; and MAY occur more than once

                            (";" xparam)

                            )

               Example: The following are examples of this property:

                 CATEGORIES:APPOINTMENT,EDUCATION

                 CATEGORIES:MEETING
             */
        	if (icalEventParser)
            {
                iCalEvent.setCategories(extractAttribute(iCalLine, "CATEGORIES"));
            }
        }
        else if (iCalLine.startsWith("CLASS") )
        {
            /*
            4.8.1.3 Classification

            Property Name: CLASS

            Purpose: This property defines the access classification for a
            calendar component.

            Value Type: TEXT

            Property Parameters: Non-standard property parameters can be
            specified on this property.

            Conformance: The property can be specified once in a "VEVENT",
            "VTODO" or "VJOURNAL" calendar components.

            Description: An access classification is only one component of the
            general security system within a calendar application. It provides a
            method of capturing the scope of the access the calendar owner
            intends for information within an individual calendar entry. The
            access classification of an individual ICalendar component is useful
            when measured along with the other security components of a calendar
            system (e.g., calendar user authentication, authorization, access
            rights, access role, etc.). Hence, the semantics of the individual
            access classifications cannot be completely defined by this memo
            alone. Additionally, due to the "blind" nature of most exchange
            processes using this memo, these access classifications cannot serve
            as an enforcement statement for a system receiving an ICalendar
            object. Rather, they provide a method for capturing the intention of
            the calendar owner for the access to the calendar component.

            Format Definition: The property is defined by the following notation:

             class      = "CLASS" classparam ":" classvalue CRLF
             classparam = *(";" xparam)
             classvalue = "PUBLIC" / "PRIVATE" / "CONFIDENTIAL" / iana-token
                        / x-name
             ;Default is PUBLIC

            Example: The following is an example of this property:

             CLASS:PUBLIC

             */
            if (icalEventParser)
            {
                iCalEvent.setEventClass(extractAttribute(iCalLine, "CLASS"));
            }
        }
        else if (iCalLine.startsWith("COMMENT") )
        {
            /*
             4.8.1.4 Comment

               Property Name: COMMENT

               Purpose: This property specifies non-processing information intended
               to provide a comment to the calendar user.

               Value Type: TEXT

               Property Parameters: Non-standard, alternate text representation and
               language property parameters can be specified on this property.

               Conformance: This property can be specified in "VEVENT", "VTODO",
               "VJOURNAL", "VTIMEZONE" or "VFREEBUSY" calendar components.

               Description: The property can be specified multiple times.

               Format Definition: The property is defined by the following notation:

                 comment    = "COMMENT" commparam ":" text CRLF

                 commparam  = *(

                            ; the following are optional,
                            ; but MUST NOT occur more than once

                            (";" altrepparam) / (";" languageparam) /

                            ; the following is optional,
                            ; and MAY occur more than once

                            (";" xparam)

                            )

               Example: The following is an example of this property:

                 COMMENT:The meeting really needs to include both ourselves
                   and the customer. We can't hold this  meeting without them.
                   As a matter of fact\, the venue for the meeting ought to be at
                   their site. - - John

               The data type for this property is TEXT.

             */
        	if (icalEventParser)
            {
                iCalEvent.setComment(extractAttribute(iCalLine, "COMMENT"));
            }
        }
        else if (iCalLine.startsWith("DESCRIPTION") )
        {
            /*
             4.8.1.5 Description

               Property Name: DESCRIPTION

               Purpose: This property provides a more complete description of the
               calendar component, than that provided by the "SUMMARY" property.

               Value Type: TEXT

               Property Parameters: Non-standard, alternate text representation and
               language property parameters can be specified on this property.

               Conformance: The property can be specified in the "VEVENT", "VTODO",
               "VJOURNAL" or "VALARM" calendar components. The property can be
               specified multiple times only within a "VJOURNAL" calendar component.

               Description: This property is used in the "VEVENT" and "VTODO" to
               capture lengthy textual decriptions associated with the activity.

               This property is used in the "VJOURNAL" calendar component to capture
               one more textual journal entries.

               This property is used in the "VALARM" calendar component to capture
               the display text for a DISPLAY category of alarm, to capture the body
               text for an EMAIL category of alarm and to capture the argument
               string for a PROCEDURE category of alarm.

               Format Definition: The property is defined by the following notation:

                 description        = "DESCRIPTION" descparam ":" text CRLF

                 descparam  = *(

                            ; the following are optional,
                            ; but MUST NOT occur more than once

                            (";" altrepparam) / (";" languageparam) /

                            ; the following is optional,
                            ; and MAY occur more than once

                            (";" xparam)

                            )
               Example: The following is an example of the property with formatted
               line breaks in the property value:

                 DESCRIPTION:Meeting to provide technical review for "Phoenix"
                   design.\n Happy Face Conference Room. Phoenix design team
                   MUST attend this meeting.\n RSVP to team leader.

               The following is an example of the property with folding of long
               lines:

                 DESCRIPTION:Last draft of the new novel is to be completed
                   for the editor's proof today.
             */
            if (icalEventParser)
            {
                iCalEvent.setDescription(extractAttribute(iCalLine, "DESCRIPTION"));
            }
        }
        else if (iCalLine.startsWith("GEO") )
        {
            /*
             4.8.1.6 Geographic Position

               Property Name: GEO

               Purpose: This property specifies information related to the global
               position for the activity specified by a calendar component.

               Value Type: FLOAT. The value MUST be two SEMICOLON separated FLOAT
               values.

               Property Parameters: Non-standard property parameters can be
               specified on this property.

               Conformance: This property can be specified in  "VEVENT" or "VTODO"
               calendar components.

               Description: The property value specifies latitude and longitude, in
               that order (i.e., "LAT LON" ordering). The longitude represents the
               location east or west of the prime meridian as a positive or negative
               real number, respectively. The longitude and latitude values MAY be
               specified up to six decimal places, which will allow for accuracy to
               within one meter of geographical position. Receiving applications
               MUST accept values of this precision and MAY truncate values of
               greater precision.

               Values for latitude and longitude shall be expressed as decimal
               fractions of degrees. Whole degrees of latitude shall be represented
               by a two-digit decimal number ranging from 0 through 90. Whole
               degrees of longitude shall be represented by a decimal number ranging
               from 0 through 180. When a decimal fraction of a degree is specified,
               it shall be separated from the whole number of degrees by a decimal
               point.

               Latitudes north of the equator shall be specified by a plus sign (+),
               or by the absence of a minus sign (-), preceding the digits
               designating degrees. Latitudes south of the Equator shall be
               designated by a minus sign (-) preceding the digits designating
               degrees. A point on the Equator shall be assigned to the Northern
               Hemisphere.

               Longitudes east of the prime meridian shall be specified by a plus
               sign (+), or by the absence of a minus sign (-), preceding the digits
               designating degrees. Longitudes west of the meridian shall be
               designated by minus sign (-) preceding the digits designating
               degrees. A point on the prime meridian shall be assigned to the
               Eastern Hemisphere. A point on the 180th meridian shall be assigned
               to the Western Hemisphere. One exception to this last convention is
               permitted. For the special condition of describing a band of latitude
               around the earth, the East Bounding Coordinate data element shall be
               assigned the value +180 (180) degrees.

               Any spatial address with a latitude of +90 (90) or -90 degrees will
               specify the position at the North or South Pole, respectively. The
               component for longitude may have any legal value.

               With the exception of the special condition described above, this
               form is specified in Department of Commerce, 1986, Representation of
               geographic point locations for information interchange (Federal
               Information Processing Standard 70-1):  Washington,  Department of
               Commerce, National Institute of Standards and Technology.

               The simple formula for converting degrees-minutes-seconds into
               decimal degrees is:

                 decimal = degrees + minutes/60 + seconds/3600.

               Format Definition: The property is defined by the following notation:

                 geo        = "GEO" geoparam ":" geovalue CRLF

                 geoparam   = *(";" xparam)

                 geovalue   = float ";" float
                 ;Latitude and Longitude components

               Example: The following is an example of this property:

                 GEO:37.386013;-122.082932

             */
        	if (icalEventParser)
            {

                // Get X/Y from..
                String geo = extractAttribute(iCalLine, "GEO");
                iCalEvent.setGeo(geo);
                StringTokenizer st = new StringTokenizer(geo,":");
                try
				{
                	iCalEvent.setGeoX(new Float(st.nextToken()).floatValue());
                	iCalEvent.setGeoY(new Float(st.nextToken()).floatValue());
				}
                catch (Exception e)
				{
                	// This means the Geo is probably badly formed, so set geoX/Y to -1
                	iCalEvent.setGeoX(-1);
                	iCalEvent.setGeoY(-1);
	        		logger.severe("Exception parsing int from line "+iCalLine);
	        		e.printStackTrace(System.err);
				}
            }
        }
        else if (iCalLine.startsWith("LOCATION") )
        {
            /*
            4.8.1.7 Location

               Property Name: LOCATION

               Purpose: The property defines the intended venue for the activity
               defined by a calendar component.

               Value Type: TEXT

               Property Parameters: Non-standard, alternate text representation and
               language property parameters can be specified on this property.

               Conformance: This property can be specified in "VEVENT" or "VTODO"
               calendar component.

               Description: Specific venues such as conference or meeting rooms may
               be explicitly specified using this property. An alternate
               representation may be specified that is a URI that points to
               directory information with more structured specification of the
               location. For example, the alternate representation may specify
               either an LDAP URI pointing to an LDAP server entry or a CID URI
               pointing to a MIME body part containing a vCard [RFC 2426] for the
               location.

               Format Definition: The property is defined by the following notation:

                 location   = "LOCATION locparam ":" text CRLF

                 locparam   = *(

                            ; the following are optional,
                            ; but MUST NOT occur more than once

                            (";" altrepparam) / (";" languageparam) /

                            ; the following is optional,
                            ; and MAY occur more than once

                            (";" xparam)

                            )

               Example: The following are some examples of this property:

                 LOCATION:Conference Room - F123, Bldg. 002

                 LOCATION;ALTREP="http://xyzcorp.com/conf-rooms/f123.vcf":
                  Conference Room - F123, Bldg. 002

             */
        	if (icalEventParser)
            {
        		iCalEvent.setLocation(extractAttribute(iCalLine, "LOCATION"));
            }
        }
        else if (iCalLine.startsWith("PERCENT-COMPLETE") )
        {
            /*
             4.8.1.8 Percent Complete

               Property Name: PERCENT-COMPLETE

               Purpose: This property is used by an assignee or delegatee of a to-do
               to convey the percent completion of a to-do to the Organizer.

               Value Type: INTEGER

               Property Parameters: Non-standard property parameters can be
               specified on this property.

               Conformance: This property can be specified in a "VTODO" calendar
               component.

               Description: The property value is a positive integer between zero
               and one hundred. A value of "0" indicates the to-do has not yet been
               started. A value of "100" indicates that the to-do has been
               completed. Integer values in between indicate the percent partially
               complete.

               When a to-do is assigned to multiple individuals, the property value
               indicates the percent complete for that portion of the to-do assigned
               to the assignee or delegatee. For example, if a to-do is assigned to
               both individuals "A" and "B". A reply from "A" with a percent
               complete of "70" indicates that "A" has completed 70% of the to-do
               assigned to them. A reply from "B" with a percent complete of "50"
               indicates "B" has completed 50% of the to-do assigned to them.

               Format Definition: The property is defined by the following notation:

                 percent = "PERCENT-COMPLETE" pctparam ":" integer CRLF

                 pctparam   = *(";" xparam)

               Example: The following is an example of this property to show 39%
               completion:

                 PERCENT-COMPLETE:39

             */
        	if (icalEventParser)
            {
        		iCalEvent.setPercentComplete(extractAttribute(iCalLine, "PERCENT-COMPLETE"));
            }
        }
        else if (iCalLine.startsWith("PRIORITY") )
        {
            /*
             4.8.1.9 Priority

               Property Name: PRIORITY

               Purpose: The property defines the relative priority for a calendar
               component.

               Value Type: INTEGER

               Property Parameters: Non-standard property parameters can be
               specified on this property.

               Conformance: The property can be specified in a "VEVENT" or "VTODO"
               calendar component.

               Description: The priority is specified as an integer in the range
               zero to nine. A value of zero (US-ASCII decimal 48) specifies an
               undefined priority. A value of one (US-ASCII decimal 49) is the
               highest priority. A value of two (US-ASCII decimal 50) is the second
               highest priority. Subsequent numbers specify a decreasing ordinal
               priority. A value of nine (US-ASCII decimal 58) is the lowest
               priority.

               A CUA with a three-level priority scheme of "HIGH", "MEDIUM" and
               "LOW" is mapped into this property such that a property value in the
               range of one (US-ASCII decimal 49) to four (US-ASCII decimal 52)
               specifies "HIGH" priority. A value of five (US-ASCII decimal 53) is
               the normal or "MEDIUM" priority. A value in the range of six (US-
               ASCII decimal 54) to nine (US-ASCII decimal 58) is "LOW" priority.

               A CUA with a priority schema of "A1", "A2", "A3", "B1", "B2", ...,
               "C3" is mapped into this property such that a property value of one
               (US-ASCII decimal 49) specifies "A1", a property value of two (US-
               ASCII decimal 50) specifies "A2", a property value of three (US-ASCII
               decimal 51) specifies "A3", and so forth up to a property value of 9
               (US-ASCII decimal 58) specifies "C3".

               Other integer values are reserved for future use.

               Within a "VEVENT" calendar component, this property specifies a
               priority for the event. This property may be useful when more than
               one event is scheduled for a given time period.

               Within a "VTODO" calendar component, this property specified a
               priority for the to-do. This property is useful in prioritizing
               multiple action items for a given time period.

               Format Definition: The property is specified by the following
               notation:

                 priority   = "PRIORITY" prioparam ":" privalue CRLF
                 ;Default is zero

                 prioparam  = *(";" xparam)

                 privalue   = integer       ;Must be in the range [0..9]
                    ; All other values are reserved for future use

               The following is an example of a property with the highest priority:

                 PRIORITY:1

               The following is an example of a property with a next highest
               priority:

                 PRIORITY:2

               Example: The following is an example of a property with no priority.
               This is equivalent to not specifying the "PRIORITY" property:

                 PRIORITY:0

             */
        	if (icalEventParser)
            {
	        	try
				{
	        		iCalEvent.setPriority(Integer.parseInt(extractAttribute(iCalLine, "PRIORITY")));
				}
	        	catch (Exception e)
				{
	        		logger.severe("Exception parsing int from line "+iCalLine);
	        		e.printStackTrace(System.err);
				}
            }
        }
        else if (iCalLine.startsWith("RESOURCES") )
        {
            /*
            4.8.1.10 Resources

               Property Name: RESOURCES

               Purpose: This property defines the equipment or resources anticipated
               for an activity specified by a calendar entity..

               Value Type: TEXT

               Property Parameters: Non-standard, alternate text representation and
               language property parameters can be specified on this property.

               Conformance: This property can be specified in "VEVENT" or "VTODO"
               calendar component.

               Description: The property value is an arbitrary text. More than one
               resource can be specified as a list of resources separated by the
               COMMA character (US-ASCII decimal 44).

               Format Definition: The property is defined by the following notation:

                 resources  = "RESOURCES" resrcparam ":" text *("," text) CRLF

                 resrcparam = *(

                            ; the following are optional,
                            ; but MUST NOT occur more than once

                            (";" altrepparam) / (";" languageparam) /

                            ; the following is optional,
                            ; and MAY occur more than once

                            (";" xparam)

                            )

               Example: The following is an example of this property:

                 RESOURCES:EASEL,PROJECTOR,VCR

                 RESOURCES;LANGUAGE=fr:1 raton-laveur

             */
        	if (icalEventParser)
            {
        		iCalEvent.setResources(extractAttribute(iCalLine, "RESOURCES"));
            }
        }
        else if (iCalLine.startsWith("STATUS") )
        {
            /*
            4.8.1.11 Status

               Property Name: STATUS

               Purpose: This property defines the overall status or confirmation for
               the calendar component.

               Value Type: TEXT

               Property Parameters: Non-standard property parameters can be
               specified on this property.

               Conformance: This property can be specified in "VEVENT", "VTODO" or
               "VJOURNAL" calendar components.

               Description: In a group scheduled calendar component, the property is
               used by the "Organizer" to provide a confirmation of the event to the
               "Attendees". For example in a "VEVENT" calendar component, the
               "Organizer" can indicate that a meeting is tentative, confirmed or
               cancelled. In a "VTODO" calendar component, the "Organizer" can
               indicate that an action item needs action, is completed, is in
               process or being worked on, or has been cancelled. In a "VJOURNAL"
               calendar component, the "Organizer" can indicate that a journal entry
               is draft, final or has been cancelled or removed.

               Format Definition: The property is defined by the following notation:

                 status     = "STATUS" statparam] ":" statvalue CRLF

                 statparam  = *(";" xparam)

                 statvalue  = "TENTATIVE"           ;Indicates event is
                                                    ;tentative.
                            / "CONFIRMED"           ;Indicates event is
                                                    ;definite.
                            / "CANCELLED"           ;Indicates event was
                                                    ;cancelled.
                    ;Status values for a "VEVENT"

                 statvalue  =/ "NEEDS-ACTION"       ;Indicates to-do needs action.
                            / "COMPLETED"           ;Indicates to-do completed.
                            / "IN-PROCESS"          ;Indicates to-do in process of
                            / "CANCELLED"           ;Indicates to-do was cancelled.
                    ;Status values for "VTODO".

                 statvalue  =/ "DRAFT"              ;Indicates journal is draft.
                            / "FINAL"               ;Indicates journal is final.
                            / "CANCELLED"           ;Indicates journal is removed.
                    ;Status values for "VJOURNAL".

               Example: The following is an example of this property for a "VEVENT"
               calendar component:

                 STATUS:TENTATIVE

               The following is an example of this property for a "VTODO" calendar
               component:

                 STATUS:NEEDS-ACTION

               The following is an example of this property for a "VJOURNAL"
               calendar component:

                 STATUS:DRAFT
             */
        	if (icalEventParser)
            {
        		iCalEvent.setResources(extractAttribute(iCalLine, "STATUS"));
            }
        }
        else if (iCalLine.startsWith("SUMMARY") )
        {
            /*
            4.8.1.12 Summary

               Property Name: SUMMARY

               Purpose: This property defines a short summary or subject for the
               calendar component.

               Value Type: TEXT

               Property Parameters: Non-standard, alternate text representation and
               language property parameters can be specified on this property.

               Conformance: The property can be specified in "VEVENT", "VTODO",
               "VJOURNAL" or "VALARM" calendar components.

               Description: This property is used in the "VEVENT", "VTODO" and
               "VJOURNAL" calendar components to capture a short, one line summary
               about the activity or journal entry.

               This property is used in the "VALARM" calendar component to capture
               the subject of an EMAIL category of alarm.

               Format Definition: The property is defined by the following notation:

                 summary    = "SUMMARY" summparam ":" text CRLF

                 summparam  = *(

                            ; the following are optional,
                            ; but MUST NOT occur more than once

                            (";" altrepparam) / (";" languageparam) /

                            ; the following is optional,
                            ; and MAY occur more than once

                            (";" xparam)

                            )

               Example: The following is an example of this property:

                 SUMMARY:Department Party
             */
            if (icalEventParser)
            {
                iCalEvent.setSummary(extractAttribute(iCalLine, "SUMMARY"));
            }
        }
        else if (iCalLine.startsWith("COMPLETED") )
        {
            /*
             4.8.2 Date and Time Component Properties

               The following properties specify date and time related information in
               calendar components.

            4.8.2.1 Date/Time Completed

               Property Name: COMPLETED

               Purpose: This property defines the date and time that a to-do was
               actually completed.

               Value Type: DATE-TIME

               Property Parameters: Non-standard property parameters can be
               specified on this property.

               Conformance: The property can be specified in a "VTODO" calendar
               component.

               Description: The date and time MUST be in a UTC format.

               Format Definition: The property is defined by the following notation:

                 completed  = "COMPLETED" compparam ":" date-time CRLF
                 compparam  = *(";" xparam)

               Example: The following is an example of this property:

                 COMPLETED:19960401T235959Z

             */

        }
        else if (iCalLine.startsWith("DTEND") )
        {
            /*
             4.8.2.2 Date/Time End

               Property Name: DTEND

               Purpose: This property specifies the date and time that a calendar
               component ends.

               Value Type: The default value type is DATE-TIME. The value type can
               be set to a DATE value type.

               Property Parameters: Non-standard, value data type, time zone
               identifier property parameters can be specified on this property.

               Conformance: This property can be specified in "VEVENT" or
               "VFREEBUSY" calendar components.

               Description: Within the "VEVENT" calendar component, this property
               defines the date and time by which the event ends. The value MUST be
               later in time than the value of the "DTSTART" property.

               Within the "VFREEBUSY" calendar component, this property defines the
               end date and time for the free or busy time information. The time
               MUST be specified in the UTC time format. The value MUST be later in
               time than the value of the "DTSTART" property.

               Format Definition: The property is defined by the following notation:

                 dtend      = "DTEND" dtendparam":" dtendval CRLF

                 dtendparam = *(

                            ; the following are optional,
                            ; but MUST NOT occur more than once

                            (";" "VALUE" "=" ("DATE-TIME" / "DATE")) /
                            (";" tzidparam) /

                            ; the following is optional,
                            ; and MAY occur more than once
                            (";" xparam)

                            )



                 dtendval   = date-time / date
                 ;Value MUST match value type

               Example: The following is an example of this property:

                 DTEND:19960401T235959Z

                 DTEND;VALUE=DATE:19980704

             */
            if (icalEventParser == true)
            {
                iCalEvent.setDateEnd(convertIcalDate(extractAttribute(iCalLine, "DTEND")));
            }
        }
        else if (iCalLine.startsWith("DUE") )
        {
            /*
             4.8.2.3 Date/Time Due

               Property Name: DUE

               Purpose: This property defines the date and time that a to-do is
               expected to be completed.

               Value Type: The default value type is DATE-TIME. The value type can
               be set to a DATE value type.

               Property Parameters: Non-standard, value data type, time zone
               identifier property parameters can be specified on this property.

               Conformance: The property can be specified once in a "VTODO" calendar
               component.

               Description: The value MUST be a date/time equal to or after the
               DTSTART value, if specified.

               Format Definition: The property is defined by the following notation:

                 due        = "DUE" dueparam":" dueval CRLF

                 dueparam   = *(
                            ; the following are optional,
                            ; but MUST NOT occur more than once

                            (";" "VALUE" "=" ("DATE-TIME" / "DATE")) /
                            (";" tzidparam) /

                            ; the following is optional,
                            ; and MAY occur more than once

                              *(";" xparam)

                            )



                 dueval     = date-time / date
                 ;Value MUST match value type

               Example: The following is an example of this property:

                 DUE:19980430T235959Z

             */
        }
        else if (iCalLine.startsWith("DTSTART") )
        {
            /*
            4.8.2.4 Date/Time Start

               Property Name: DTSTART

               Purpose: This property specifies when the calendar component begins.

               Value Type: The default value type is DATE-TIME. The time value MUST
               be one of the forms defined for the DATE-TIME value type. The value
               type can be set to a DATE value type.

               Property Parameters: Non-standard, value data type, time zone
               identifier property parameters can be specified on this property.

               Conformance: This property can be specified in the "VEVENT", "VTODO",
               "VFREEBUSY", or "VTIMEZONE" calendar components.

               Description: Within the "VEVENT" calendar component, this property
               defines the start date and time for the event. The property is
               REQUIRED in "VEVENT" calendar components. Events can have a start
               date/time but no end date/time. In that case, the event does not take
               up any time.

               Within the "VFREEBUSY" calendar component, this property defines the
               start date and time for the free or busy time information. The time
               MUST be specified in UTC time.

               Within the "VTIMEZONE" calendar component, this property defines the
               effective start date and time for a time zone specification. This
               property is REQUIRED within each STANDARD and DAYLIGHT part included
               in "VTIMEZONE" calendar components and MUST be specified as a local
               DATE-TIME without the "TZID" property parameter.

               Format Definition: The property is defined by the following notation:

                 dtstart    = "DTSTART" dtstparam ":" dtstval CRLF

                 dtstparam  = *(

                            ; the following are optional,
                            ; but MUST NOT occur more than once

                            (";" "VALUE" "=" ("DATE-TIME" / "DATE")) /
                            (";" tzidparam) /

                            ; the following is optional,
                            ; and MAY occur more than once

                              *(";" xparam)

                            )



                 dtstval    = date-time / date
                 ;Value MUST match value type

               Example: The following is an example of this property:

                 DTSTART:19980118T073000Z

            */

            if (icalTimeZoneParser == true){
                if (timeZoneType.equalsIgnoreCase("STANDARD") )
                {
                   icalTimeZone.setstandardDtStart(convertIcalDate(extractAttribute(iCalLine, "DTSTART")));
                }
                else
                {
                   icalTimeZone.setdaylightDtStart(convertIcalDate(extractAttribute(iCalLine, "DTSTART")));
                }
            }
            else if (icalEventParser == true)
            {
                iCalEvent.setDateStart(convertIcalDate(extractAttribute(iCalLine, "DTSTART")));
            }
        }
        else if (iCalLine.startsWith("DURATION") )
        {
            /*
            4.8.2.5 Duration

               Property Name: DURATION

               Purpose: The property specifies a positive duration of time.

               Value Type: DURATION

               Property Parameters: Non-standard property parameters can be
               specified on this property.

               Conformance: The property can be specified in "VEVENT", "VTODO",
               "VFREEBUSY" or "VALARM" calendar components.

               Description: In a "VEVENT" calendar component the property may be
               used to specify a duration of the event, instead of an explicit end
               date/time. In a "VTODO" calendar component the property may be used
               to specify a duration for the to-do, instead of an explicit due
               date/time. In a "VFREEBUSY" calendar component the property may be
               used to specify the interval of free time being requested. In a
               "VALARM" calendar component the property may be used to specify the
               delay period prior to repeating an alarm.

               Format Definition: The property is defined by the following notation:

                 duration   = "DURATION" durparam ":" dur-value CRLF
                              ;consisting of a positive duration of time.

                 durparam   = *(";" xparam)

               Example: The following is an example of this property that specifies
               an interval of time of 1 hour and zero minutes and zero seconds:

                 DURATION:PT1H0M0S

               The following is an example of this property that specifies an
               interval of time of 15 minutes.

                 DURATION:PT15M

             */
            if (icalEventParser == true)
            {
                iCalEvent.setDuration(extractAttribute(iCalLine, "DURATION"));
            }
        }

        else if (iCalLine.startsWith("BEGIN:VEVENT") )
        {
            /*
             4.6.1 Event Component
             Component Name: "VEVENT"
             Purpose: Provide a grouping of component properties that describe an event.
             Format Definition: A "VEVENT" calendar component is defined by the following
             notation:      eventc     = "BEGIN" ":" "VEVENT" CRLF
                  eventprop *alarmc
                  "END" ":" "VEVENT" CRLF
                 BEGIN:VEVENT
                 UID:19970901T130000Z-123401@host.com
                 DTSTAMP:19970901T1300Z
                 DTSTART:19970903T163000Z
                 DTEND:19970903T190000Z
                 SUMMARY:Annual Employee Review
                 CLASS:PRIVATE
                 CATEGORIES:BUSINESS,HUMAN RESOURCES
                 END:VEVENT

               Description: A "VEVENT" calendar component is a grouping of component
               properties, and possibly including "VALARM" calendar components, that
               represents a scheduled amount of time on a calendar. For example, it
               can be an activity; such as a one-hour long, department meeting from
               8:00 AM to 9:00 AM, tomorrow. Generally, an event will take up time
               on an individual calendar. Hence, the event will appear as an opaque
               interval in a search for busy time. Alternately, the event can have
               its Time Transparency set to "TRANSPARENT" in order to prevent
               blocking of the event in searches for busy time.
               The "VEVENT" is also the calendar component used to specify an
               anniversary or daily reminder within a calendar. These events have a
               DATE value type for the "DTSTART" property instead of the default
               data type of DATE-TIME. If such a "VEVENT" has a "DTEND" property, it
               MUST be specified as a DATE value also. The anniversary type of
               "VEVENT" can span more than one date (i.e, "DTEND" property value is
               set to a calendar date after the "DTSTART" property value).
               The "DTSTART" property for a "VEVENT" specifies the inclusive start
               of the event. For recurring events, it also specifies the very first
               instance in the recurrence set. The "DTEND" property for a "VEVENT"
               calendar component specifies the non-inclusive end of the event. For
               cases where a "VEVENT" calendar component specifies a "DTSTART"
               property with a DATE data type but no "DTEND" property, the events
               non-inclusive end is the end of the calendar date specified by the
               "DTSTART" property. For cases where a "VEVENT" calendar component
               specifies a "DTSTART" property with a DATE-TIME data type but no
               "DTEND" property, the event ends on the same calendar date and time
               of day specified by the "DTSTART" property.
               The "VEVENT" calendar component cannot be nested within another
               calendar component. However, "VEVENT" calendar components can be
               related to each other or to a "VTODO" or to a "VJOURNAL" calendar
               component with the "RELATED-TO" property.
             */
            icalEventParser = true;
            iCalEvent = new ICalendarVEvent();
            iCalEvent.setEventClass("");
        }
        else if (iCalLine.startsWith("UID:") )
        {
            if (icalEventParser)
            {
                iCalEvent.setUid(extractAttribute(iCalLine, "UID"));
            }
        }
        else if (iCalLine.startsWith("END:VEVENT") )
        {
            if (icalEventParser == true)
            {
                ical.icalEventCollection.add(iCalEvent);
                icalEventParser = false;
            }
        }
        else if (iCalLine.startsWith("BEGIN:VTODO") )
        {
            /*
             4.6.2 To-do Component
             Component Name: VTODO    Purpose: Provide a grouping of calendar properties that describe a to-do.
             Formal Definition: A "VTODO" calendar component is defined by the following
             notation:      todoc      = "BEGIN" ":" "VTODO" CRLF
                  todoprop *alarmc
                  "END" ":" "VTODO" CRLF
                todoprop   = *(                 ; the following are optional,
                ; but MUST NOT occur more than once
                    class / completed / created / description / dtstamp /
                    dtstart / geo / last-mod / location / organizer /
                    percent / priority / recurid / seq / status /
                    summary / uid / url /
             ; either 'due' or 'duration' may appear in
             ; a 'todoprop', but 'due' and 'duration'
             ; MUST NOT occur in the same 'todoprop'
                    due / duration /
             ; the following are optional,
             ; and MAY occur more than once
                attach / attendee / categories / comment / contact /
                exdate / exrule / rstatus / related / resources /
                rdate / rrule / x-prop                 )
             Description: A "VTODO" calendar component is a grouping of component
               properties and possibly "VALARM" calendar components that represent
               an action-item or assignment. For example, it can be used to
               represent an item of work assigned to an individual; such as "turn in
               travel expense today".    The "VTODO" calendar component cannot be nested within another
               calendar component. However, "VTODO" calendar components can be
               related to each other or to a "VTODO" or to a "VJOURNAL" calendar
               component with the "RELATED-TO" property.
             A "VTODO" calendar component without the "DTSTART" and "DUE" (or
                "DURATION") properties specifies a to-do that will be associated with
                each successive calendar date, until it is completed.
             Example: The following is an example of a "VTODO" calendar component:
             BEGIN:VTODO
             UID:19970901T130000Z-123404@host.com
             DTSTAMP:19970901T1300Z
             DTSTART:19970415T133000Z
             DUE:19970416T045959Z
             SUMMARY:1996 Income Tax Preparation
             CLASS:CONFIDENTIAL
             CATEGORIES:FAMILY,FINANCE
             PRIORITY:1
             STATUS:NEEDS-ACTION
             END:VTODO
             */
        }
        else if (iCalLine.startsWith("END:VTODO") )
        {
            /*
             We will probably not do vtodos just yet..
             */
        }
        else if (iCalLine.startsWith("BEGIN:VJOURNAL") )
        {
             /*
             Not implemented.
             */
        }
        else if (iCalLine.startsWith("END:VJOURNAL") )
        {
             /*
             Not Implemented.
             */
        }
        else if (iCalLine.startsWith("BEGIN:VFREEBUSY") )
        {
             /*
              *4.6.4 Free/Busy Component
              freebusyc  = "BEGIN" ":" "VFREEBUSY" CRLF
                  fbprop
                  "END" ":" "VFREEBUSY" CRLF
              fbprop     = *(
                ; the following are optional,
                ; but MUST NOT occur more than once
                    contact / dtstart / dtend / duration / dtstamp /
                    organizer / uid / url /
              ; the following are optional,
              ; and MAY occur more than once
              attendee / comment / freebusy / rstatus / x-prop
              )
              Description: A "VFREEBUSY" calendar component is a grouping of
               component properties that represents either a request for, a reply to
               a request for free or busy time information or a published set of
               busy time information.    When used to request free/busy time information, the "ATTENDEE"
               property specifies the calendar users whose free/busy time is being
               requested; the "ORGANIZER" property specifies the calendar user who
               is requesting the free/busy time; the "DTSTART" and "DTEND"
               properties specify the window of time for which the free/busy time is
               being requested; the "UID" and "DTSTAMP" properties are specified to
               assist in proper sequencing of multiple free/busy time requests.
               When used to reply to a request for free/busy time, the "ATTENDEE"
               property specifies the calendar user responding to the free/busy time
               request; the "ORGANIZER" property specifies the calendar user that
               originally requested the free/busy time; the "FREEBUSY" property
               specifies the free/busy time information (if it exists); and the
               "UID" and "DTSTAMP" properties are specified to assist in proper
               sequencing of multiple free/busy time replies.
               When used to publish busy time, the "ORGANIZER" property specifies
               the calendar user associated with the published busy time; the
               "DTSTART" and "DTEND" properties specify an inclusive time window
               that surrounds the busy time information; the "FREEBUSY" property
               specifies the published busy time information; and the "DTSTAMP"
               property specifies the date/time that ICalendar object was created.
               The "VFREEBUSY" calendar component cannot be nested within another
               calendar component. Multiple "VFREEBUSY" calendar components can be
               specified within an ICalendar object. This permits the grouping of
               Free/Busy information into logical collections, such as monthly
               groups of busy time information.
               The "VFREEBUSY" calendar component is intended for use in ICalendar
               object methods involving requests for free time, requests for busy
               time, requests for both free and busy, and the associated replies.
               Free/Busy information is represented with the "FREEBUSY" property.
               This property provides a terse representation of time periods. One or
               more "FREEBUSY" properties can be specified in the "VFREEBUSY"
               calendar component.
               When present in a "VFREEBUSY" calendar component, the "DTSTART" and
               "DTEND" properties SHOULD be specified prior to any "FREEBUSY"
               properties. In a free time request, these properties can be used in
               combination with the "DURATION" property to represent a request for a
               duration of free time within a specified window of time.
               The recurrence properties ("RRULE", "EXRULE", "RDATE", "EXDATE") are
               not permitted within a "VFREEBUSY" calendar component. Any recurring
               events are resolved into their individual busy time periods using the
               "FREEBUSY" property.
               Example: The following is an example of a "VFREEBUSY" calendar
               component used to request free or busy time information:
                 BEGIN:VFREEBUSY
                 ORGANIZER:MAILTO:jane_doe@host1.com
                 ATTENDEE:MAILTO:john_public@host2.com
                 DTSTART:19971015T050000Z
                 DTEND:19971016T050000Z
                 DTSTAMP:19970901T083000Z
                 END:VFREEBUSY
               The following is an example of a "VFREEBUSY" calendar component used
               to reply to the request with busy time information:
                 BEGIN:VFREEBUSY
                 ORGANIZER:MAILTO:jane_doe@host1.com
                 ATTENDEE:MAILTO:john_public@host2.com
                 DTSTAMP:19970901T100000Z
                 FREEBUSY;VALUE=PERIOD:19971015T050000Z/PT8H30M,
                  19971015T160000Z/PT5H30M,19971015T223000Z/PT6H30M
                 URL:http://host2.com/pub/busy/jpublic-01.ifb
                 COMMENT:This ICalendar file contains busy time information for
                  the next three months.
                 END:VFREEBUSY
              The following is an example of a "VFREEBUSY" calendar component used
              to publish busy time information.
                 BEGIN:VFREEBUSY
                 ORGANIZER:jsmith@host.com
                 DTSTART:19980313T141711Z
                 DTEND:19980410T141711Z
                 FREEBUSY:19980314T233000Z/19980315T003000Z
                 FREEBUSY:19980316T153000Z/19980316T163000Z
                 FREEBUSY:19980318T030000Z/19980318T040000Z
                 URL:http://www.host.com/calendar/busytime/jsmith.ifb
                 END:VFREEBUSY
             */

        }
        else if (iCalLine.startsWith("END:VFREEBUSY") )
        {
             /*
             Not Implemented. We generate this!
             */
        }
        else if (iCalLine.startsWith("BEGIN:VTIMEZONE") )
        {
             /*
             4.6.5 Time Zone Component

           Component Name: VTIMEZONE

           Purpose: Provide a grouping of component properties that defines a
           time zone.

           Formal Definition: A "VTIMEZONE" calendar component is defined by the
           following notation:

             timezonec  = "BEGIN" ":" "VTIMEZONE" CRLF

                          2*(

                          ; 'tzid' is required, but MUST NOT occur more
                          ; than once

                        tzid /

                          ; 'last-mod' and 'tzurl' are optional,
                        but MUST NOT occur more than once

                        last-mod / tzurl /

                          ; one of 'standardc' or 'daylightc' MUST occur
                        ..; and each MAY occur more than once.

                        standardc / daylightc /

                        ; the following is optional,
                        ; and MAY occur more than once

                          x-prop

                          )

                          "END" ":" "VTIMEZONE" CRLF

             standardc  = "BEGIN" ":" "STANDARD" CRLF

                          tzprop

                          "END" ":" "STANDARD" CRLF

             daylightc  = "BEGIN" ":" "DAYLIGHT" CRLF

                          tzprop

                          "END" ":" "DAYLIGHT" CRLF

             tzprop     = 3*(

                        ; the following are each REQUIRED,
                        ; but MUST NOT occur more than once

                        dtstart / tzoffsetto / tzoffsetfrom /

                        ; the following are optional,
                        ; and MAY occur more than once

                        comment / rdate / rrule / tzname / x-prop

                        )

           Description: A time zone is unambiguously defined by the set of time
           measurement rules determined by the governing body for a given
           geographic area. These rules describe at a minimum the base  offset
           from UTC for the time zone, often referred to as the Standard Time
           offset. Many locations adjust their Standard Time forward or backward
           by one hour, in order to accommodate seasonal changes in number of
           daylight hours, often referred to as Daylight  Saving Time. Some
           locations adjust their time by a fraction of an hour. Standard Time
           is also known as Winter Time. Daylight Saving Time is also known as
           Advanced Time, Summer Time, or Legal Time in certain countries. The
           following table shows the changes in time zone rules in effect for
           New York City starting from 1967. Each line represents a description
           or rule for a particular observance.

             Effective Observance Rule

             Date       (Date/Time)             Offset  Abbreviation

             1967-*     last Sun in Oct, 02:00  -0500   EST

             1967-1973  last Sun in Apr, 02:00  -0400   EDT

             1974-1974  Jan 6,  02:00           -0400   EDT

             1975-1975  Feb 23, 02:00           -0400   EDT

             1976-1986  last Sun in Apr, 02:00  -0400   EDT

             1987-*     first Sun in Apr, 02:00 -0400   EDT

                Note: The specification of a global time zone registry is not
                addressed by this document and is left for future study.
                However, implementers may find the Olson time zone database [TZ]
                a useful reference. It is an informal, public-domain collection
                of time zone information, which is currently being maintained by
                volunteer Internet participants, and is used in several
                operating systems. This database contains current and historical
                time zone information for a wide variety of locations around the
                globe; it provides a time zone identifier for every unique time
                zone rule set in actual use since 1970, with historical data
                going back to the introduction of standard time.

           Interoperability between two calendaring and scheduling applications,
           especially for recurring events, to-dos or journal entries, is
           dependent on the ability to capture and convey date and time
           information in an unambiguous format. The specification of current
           time zone information is integral to this behavior.

           If present, the "VTIMEZONE" calendar component defines the set of
           Standard Time and Daylight Saving Time observances (or rules) for a
           particular time zone for a given interval of time. The "VTIMEZONE"
           calendar component cannot be nested within other calendar components.
           Multiple "VTIMEZONE" calendar components can exist in an ICalendar
           object. In this situation, each "VTIMEZONE" MUST represent a unique
           time zone definition. This is necessary for some classes of events,
           such as airline flights, that start in one time zone and end in
           another.

           The "VTIMEZONE" calendar component MUST be present if the ICalendar
           object contains an RRULE that generates dates on both sides of a time
           zone shift (e.g. both in Standard Time and Daylight Saving Time)
           unless the ICalendar object intends to convey a floating time (See
           the section "4.1.10.11 Time" for proper interpretation of floating
           time). It can be present if the ICalendar object does not contain
           such a RRULE. In addition, if a RRULE is present, there MUST be valid
           time zone information for all recurrence instances.

           The "VTIMEZONE" calendar component MUST include the "TZID" property
           and at least one definition of a standard or daylight component. The
           standard or daylight component MUST include the "DTSTART",
           "TZOFFSETFROM" and "TZOFFSETTO" properties.

           An individual "VTIMEZONE" calendar component MUST be specified for
           each unique "TZID" parameter value specified in the ICalendar object.

           Each "VTIMEZONE" calendar component consists of a collection of one
           or more sub-components that describe the rule for a particular
           observance (either a Standard Time or a Daylight Saving Time
           observance). The "STANDARD" sub-component consists of a collection of
           properties that describe Standard Time. The "DAYLIGHT" sub-component
           consists of a collection of properties that describe Daylight Saving
           Time. In general this collection of properties consists of:

                - the first onset date-time for the observance

                - the last onset date-time for the observance, if a last onset
                  is known.

                - the offset to be applied for the observance

                - a rule that describes the day and time when the observance
                  takes effect

                - an optional name for the observance

           For a given time zone, there may be multiple unique definitions of
           the observances over a period of time. Each observance is described
           using either a "STANDARD" or "DAYLIGHT" sub-component. The collection
           of these sub-components is used to describe the time zone for a given
           period of time. The offset to apply at any given time is found by
           locating the observance that has the last onset date and time before
           the time in question, and using the offset value from that observance.

           The top-level properties in a "VTIMEZONE" calendar component are:

           The mandatory "TZID" property is a text value that uniquely
           identifies the VTIMZONE calendar component within the scope of an
           ICalendar object.

           The optional "LAST-MODIFIED" property is a UTC value that specifies
           the date and time that this time zone definition was last updated.

           The optional "TZURL" property is url value that points to a published
           VTIMEZONE definition. TZURL SHOULD refer to a resource that is
           accessible by anyone who might need to interpret the object. This
           SHOULD NOT normally be a file: URL or other URL that is not widely-
           accessible.

           The collection of properties that are used to define the STANDARD and
           DAYLIGHT sub-components include:

           The mandatory "DTSTART" property gives the effective onset date and
           local time for the time zone sub-component definition. "DTSTART" in
           this usage MUST be specified as a local DATE-TIME value.

           The mandatory "TZOFFSETFROM" property gives the UTC offset which is
           in use when the onset of this time zone observance begins.
           "TZOFFSETFROM" is combined with "DTSTART" to define the effective
           onset for the time zone sub-component definition. For example, the
           following represents the time at which the observance of Standard
           Time took effect in Fall 1967 for New York City:

             DTSTART:19671029T020000

             TZOFFSETFROM:-0400

           The mandatory "TZOFFSETTO " property gives the UTC offset for the
           time zone sub-component (Standard Time or Daylight Saving Time) when
           this observance is in use.

           The optional "TZNAME" property is the customary name for the time
           zone. It may be specified multiple times, to allow for specifying
           multiple language variants of the time zone names. This could be used
           for displaying dates.

           If specified, the onset for the observance defined by the time zone
           sub-component is defined by either the "RRULE" or "RDATE" property.
           If neither is specified, only one sub-component can be specified in
           the "VTIMEZONE" calendar component and it is assumed that the single
           observance specified is always in effect.

           The "RRULE" property defines the recurrence rule for the onset of the
           observance defined by this time zone sub-component. Some specific
           requirements for the usage of RRULE for this purpose include:

                - If observance is known to have an effective end date, the
                "UNTIL" recurrence rule parameter MUST be used to specify the
                last valid onset of this observance (i.e., the UNTIL date-time
                will be equal to the last instance generated by the recurrence
                pattern). It MUST be specified in UTC time.

                - The "DTSTART" and the "TZOFFSETTO" properties MUST be used
                when generating the onset date-time values (instances) from the
                RRULE.

           Alternatively, the "RDATE" property can be used to define the onset
           of the observance by giving the individual onset date and times.
           "RDATE" in this usage MUST be specified as a local DATE-TIME value in
           UTC time.

           The optional "COMMENT" property is also allowed for descriptive
           explanatory text.

           Example: The following are examples of the "VTIMEZONE" calendar
           component:

           This is an example showing time zone information for the Eastern
           United States using "RDATE" property. Note that this is only suitable
           for a recurring event that starts on or later than April 6, 1997 at
           03:00:00 EDT (i.e., the earliest effective transition date and time)
           and ends no later than April 7, 1998 02:00:00 EST (i.e., latest valid
           date and time for EST in this scenario). For example, this can be
           used for a recurring event that occurs every Friday, 8am-9:00 AM,
           starting June 1, 1997, ending December 31, 1997.

             BEGIN:VTIMEZONE
             TZID:US-Eastern
             LAST-MODIFIED:19870101T000000Z
             BEGIN:STANDARD
             DTSTART:19971026T020000
             RDATE:19971026T020000
             TZOFFSETFROM:-0400
             TZOFFSETTO:-0500
             TZNAME:EST
             END:STANDARD
             BEGIN:DAYLIGHT
             DTSTART:19971026T020000
             RDATE:19970406T020000
             TZOFFSETFROM:-0500
             TZOFFSETTO:-0400
             TZNAME:EDT
             END:DAYLIGHT
             END:VTIMEZONE

           This is a simple example showing the current time zone rules for the
           Eastern United States using a RRULE recurrence pattern. Note that
           there is no effective end date to either of the Standard Time or
           Daylight Time rules. This information would be valid for a recurring
           event starting today and continuing indefinitely.

             BEGIN:VTIMEZONE
             TZID:US-Eastern
             LAST-MODIFIED:19870101T000000Z
             TZURL:http://zones.stds_r_us.net/tz/US-Eastern
             BEGIN:STANDARD
             DTSTART:19671029T020000
             RRULE:FREQ=YEARLY;BYDAY=-1SU;BYMONTH=10
             TZOFFSETFROM:-0400
             TZOFFSETTO:-0500
             TZNAME:EST
             END:STANDARD
             BEGIN:DAYLIGHT
             DTSTART:19870405T020000
             RRULE:FREQ=YEARLY;BYDAY=1SU;BYMONTH=4
             TZOFFSETFROM:-0500
             TZOFFSETTO:-0400
             TZNAME:EDT
             END:DAYLIGHT
             END:VTIMEZONE

           This is an example showing a fictitious set of rules for the Eastern
           United States, where the Daylight Time rule has an effective end date
           (i.e., after that date, Daylight Time is no longer observed).

             BEGIN:VTIMEZONE
             TZID:US--Fictitious-Eastern
             LAST-MODIFIED:19870101T000000Z
             BEGIN:STANDARD
             DTSTART:19671029T020000
             RRULE:FREQ=YEARLY;BYDAY=-1SU;BYMONTH=10
             TZOFFSETFROM:-0400
             TZOFFSETTO:-0500
             TZNAME:EST
             END:STANDARD
             BEGIN:DAYLIGHT
             DTSTART:19870405T020000
             RRULE:FREQ=YEARLY;BYDAY=1SU;BYMONTH=4;UNTIL=19980404T070000Z
             TZOFFSETFROM:-0500
             TZOFFSETTO:-0400
             TZNAME:EDT
             END:DAYLIGHT
             END:VTIMEZONE

           This is an example showing a fictitious set of rules for the Eastern
           United States, where the first Daylight Time rule has an effective
           end date. There is a second Daylight Time rule that picks up where
           the other left off.

             BEGIN:VTIMEZONE
             TZID:US--Fictitious-Eastern
             LAST-MODIFIED:19870101T000000Z
             BEGIN:STANDARD
             DTSTART:19671029T020000
             RRULE:FREQ=YEARLY;BYDAY=-1SU;BYMONTH=10
             TZOFFSETFROM:-0400
             TZOFFSETTO:-0500
             TZNAME:EST
             END:STANDARD
             BEGIN:DAYLIGHT
             DTSTART:19870405T020000
             RRULE:FREQ=YEARLY;BYDAY=1SU;BYMONTH=4;UNTIL=19980404T070000Z
             TZOFFSETFROM:-0500
             TZOFFSETTO:-0400
             TZNAME:EDT
             END:DAYLIGHT
             BEGIN:DAYLIGHT
             DTSTART:19990424T020000
             RRULE:FREQ=YEARLY;BYDAY=-1SU;BYMONTH=4
             TZOFFSETFROM:-0500
             TZOFFSETTO:-0400
             TZNAME:EDT
             END:DAYLIGHT
             END:VTIMEZONE

            */
            icalTimeZone = new ICalendarTimeZone();
            icalTimeZoneParser = true;
        }
        else if (iCalLine.startsWith("END:VTIMEZONE") )
        {
            icalTimeZoneParser = false;
            if (icalTimeZone == null){}
            else {
                ical.icaltimeZoneCollection.add(icalTimeZone);
            }
        }
        else if (iCalLine.startsWith("BEGIN:VALARM") )
        {
             /*
            4.6.6 Alarm Component

               Component Name: VALARM

               Purpose: Provide a grouping of component properties that define an
               alarm.
               Formal Definition: A "VALARM" calendar component is defined by the
               following notation:

                      alarmc     = "BEGIN" ":" "VALARM" CRLF
                                   (audioprop / dispprop / emailprop / procprop)
                                   "END" ":" "VALARM" CRLF

                 audioprop  = 2*(

                            ; 'action' and 'trigger' are both REQUIRED,
                            ; but MUST NOT occur more than once

                            action / trigger /

                            ; 'duration' and 'repeat' are both optional,
                            ; and MUST NOT occur more than once each,
                            ; but if one occurs, so MUST the other

                            duration / repeat /

                            ; the following is optional,
                            ; but MUST NOT occur more than once

                            attach /

                            ; the following is optional,
                            ; and MAY occur more than once

                            x-prop

                            )



                 dispprop   = 3*(

                            ; the following are all REQUIRED,
                            ; but MUST NOT occur more than once

                            action / description / trigger /

                            ; 'duration' and 'repeat' are both optional,
                            ; and MUST NOT occur more than once each,
                            ; but if one occurs, so MUST the other

                            duration / repeat /

                            ; the following is optional,
                            ; and MAY occur more than once

                            *x-prop

                            )



                 emailprop  = 5*(

                            ; the following are all REQUIRED,
                            ; but MUST NOT occur more than once

                            action / description / trigger / summary

                            ; the following is REQUIRED,
                            ; and MAY occur more than once

                            attendee /

                            ; 'duration' and 'repeat' are both optional,
                            ; and MUST NOT occur more than once each,
                            ; but if one occurs, so MUST the other

                            duration / repeat /

                            ; the following are optional,
                            ; and MAY occur more than once

                            attach / x-prop

                            )



                 procprop   = 3*(

                            ; the following are all REQUIRED,
                            ; but MUST NOT occur more than once

                            action / attach / trigger /

                            ; 'duration' and 'repeat' are both optional,
                            ; and MUST NOT occur more than once each,
                            ; but if one occurs, so MUST the other

                            duration / repeat /

                            ; 'description' is optional,
                            ; and MUST NOT occur more than once

                            description /

                            ; the following is optional,
                            ; and MAY occur more than once

                            x-prop

                            )

               Description: A "VALARM" calendar component is a grouping of component
               properties that is a reminder or alarm for an event or a to-do. For
               example, it may be used to define a reminder for a pending event or
               an overdue to-do.

               The "VALARM" calendar component MUST include the "ACTION" and
               "TRIGGER" properties. The "ACTION" property further constrains the
               "VALARM" calendar component in the following ways:

               When the action is "AUDIO", the alarm can also include one and only
               one "ATTACH" property, which MUST point to a sound resource, which is
               rendered when the alarm is triggered.

               When the action is "DISPLAY", the alarm MUST also include a
               "DESCRIPTION" property, which contains the text to be displayed when
               the alarm is triggered.

               When the action is "EMAIL", the alarm MUST include a "DESCRIPTION"
               property, which contains the text to be used as the message body, a
               "SUMMARY" property, which contains the text to be used as the message
               subject, and one or more "ATTENDEE" properties, which contain the
               email address of attendees to receive the message. It can also
               include one or more "ATTACH" properties, which are intended to be
               sent as message attachments. When the alarm is triggered, the email
               message is sent.

               When the action is "PROCEDURE", the alarm MUST include one and only
               one "ATTACH" property, which MUST point to a procedure resource,
               which is invoked when the alarm is triggered.

               The "VALARM" calendar component MUST only appear within either a
               "VEVENT" or "VTODO" calendar component. "VALARM" calendar components
               cannot be nested. Multiple mutually independent "VALARM" calendar
               components can be specified for a single "VEVENT" or "VTODO" calendar
               component.

               The "TRIGGER" property specifies when the alarm will be triggered.
               The "TRIGGER" property specifies a duration prior to the start of an
               event or a to-do. The "TRIGGER" edge may be explicitly set to be
               relative to the "START" or "END" of the event or to-do with the
               "RELATED" parameter of the "TRIGGER" property. The "TRIGGER" property
               value type can alternatively be set to an absolute calendar date and
               time of day value.

               In an alarm set to trigger on the "START" of an event or to-do, the
               "DTSTART" property MUST be present in the associated event or to-do.
               In an alarm in a "VEVENT" calendar component set to trigger on the
               "END" of the event, either the "DTEND" property MUST be present, or
               the "DTSTART" and "DURATION" properties MUST both be present. In an
               alarm in a "VTODO" calendar component set to trigger on the "END" of
               the to-do, either the "DUE" property MUST be present, or the
               "DTSTART" and "DURATION" properties MUST both be present.

               The alarm can be defined such that it triggers repeatedly. A
               definition of an alarm with a repeating trigger MUST include both the
               "DURATION" and "REPEAT" properties. The "DURATION" property specifies
               the delay period, after which the alarm will repeat. The "REPEAT"
               property specifies the number of additional repetitions that the
               alarm will triggered. This repitition count is in addition to the
               initial triggering of the alarm. Both of these properties MUST be
               present in order to specify a repeating alarm. If one of these two
               properties is absent, then the alarm will not repeat beyond the
               initial trigger.

               The "ACTION" property is used within the "VALARM" calendar component
               to specify the type of action invoked when the alarm is triggered.
               The "VALARM" properties provide enough information for a specific
               action to be invoked. It is typically the responsibility of a
               "Calendar User Agent" (CUA) to deliver the alarm in the specified
               fashion. An "ACTION" property value of AUDIO specifies an alarm that
               causes a sound to be played to alert the user; DISPLAY specifies an
               alarm that causes a text message to be displayed to the user; EMAIL
               specifies an alarm that causes an electronic email message to be
               delivered to one or more email addresses; and PROCEDURE specifies an
               alarm that causes a procedure to be executed. The "ACTION" property
               MUST specify one and only one of these values.

               In an AUDIO alarm, if the optional "ATTACH" property is included, it
               MUST specify an audio sound resource. The intention is that the sound
               will be played as the alarm effect. If an "ATTACH" property is
               specified that does not refer to a sound resource, or if the
               specified sound resource cannot be rendered (because its format is
               unsupported, or because it cannot be retrieved), then the CUA or
               other entity responsible for playing the sound may choose a fallback
               action, such as playing a built-in default sound, or playing no sound
               at all.

               In a DISPLAY alarm, the intended alarm effect is for the text value
               of the "DESCRIPTION" property to be displayed to the user.

               In an EMAIL alarm, the intended alarm effect is for an email message
               to be composed and delivered to all the addresses specified by the
               "ATTENDEE" properties in the "VALARM" calendar component. The
               "DESCRIPTION" property of the "VALARM" calendar component MUST be
               used as the body text of the message, and the "SUMMARY" property MUST
               be used as the subject text. Any "ATTACH" properties in the "VALARM"
               calendar component SHOULD be sent as attachments to the message.

               In a PROCEDURE alarm, the "ATTACH" property in the "VALARM" calendar
               component MUST specify a procedure or program that is intended to be
               invoked as the alarm effect. If the procedure or program is in a
               format that cannot be rendered, then no procedure alarm will be
               invoked. If the "DESCRIPTION" property is present, its value
               specifies the argument string to be passed to the procedure or
               program. "Calendar User Agents" that receive an ICalendar object with
               this category of alarm, can disable or allow the "Calendar User" to
               disable, or otherwise ignore this type of alarm. While a very useful
               alarm capability, the PROCEDURE type of alarm SHOULD be treated by
               the "Calendar User Agent" as a potential security risk.

               Example: The following example is for a "VALARM" calendar component
               that specifies an audio alarm that will sound at a precise time and
               repeat 4 more times at 15 minute intervals:

                 BEGIN:VALARM
                 TRIGGER;VALUE=DATE-TIME:19970317T133000Z
                 REPEAT:4
                 DURATION:PT15M
                 ACTION:AUDIO
                 ATTACH;FMTTYPE=audio/basic:ftp://host.com/pub/sounds/bell-01.aud
                 END:VALARM

               The following example is for a "VALARM" calendar component that
               specifies a display alarm that will trigger 30 minutes before the
               scheduled start of the event or the due date/time of the to-do it is
               associated with and will repeat 2 more times at 15 minute intervals:

                 BEGIN:VALARM
                 TRIGGER:-PT30M
                 REPEAT:2
                 DURATION:PT15M
                 ACTION:DISPLAY
                 DESCRIPTION:Breakfast meeting with executive\n
                  team at 8:30 AM EST.
                 END:VALARM

               The following example is for a "VALARM" calendar component that
               specifies an email alarm that will trigger 2 days before the
               scheduled due date/time of a to-do it is associated with. It does not
               repeat. The email has a subject, body and attachment link.

                 BEGIN:VALARM
                 TRIGGER:-P2D
                 ACTION:EMAIL
                 ATTENDEE:MAILTO:john_doe@host.com
                 SUMMARY:*** REMINDER: SEND AGENDA FOR WEEKLY STAFF MEETING ***
                 DESCRIPTION:A draft agenda needs to be sent out to the attendees
                   to the weekly managers meeting (MGR-LIST). Attached is a
                   pointer the document template for the agenda file.
                 ATTACH;FMTTYPE=application/binary:http://host.com/templates/agen
                  da.doc
                 END:VALARM

               The following example is for a "VALARM" calendar component that
               specifies a procedural alarm that will trigger at a precise date/time
               and will repeat 23 more times at one hour intervals. The alarm will
               invoke a procedure file.

                 BEGIN:VALARM
                 TRIGGER;VALUE=DATE-TIME:19980101T050000Z
                 REPEAT:23
                 DURATION:PT1H
                 ACTION:PROCEDURE
                 ATTACH;FMTTYPE=application/binary:ftp://host.com/novo-
                  procs/felizano.exe
                 END:VALARM

             */
        }
        else if (iCalLine.startsWith("TRANSP:") )
        {
             /*
             4.8.2.7 Time Transparency

               Property Name: TRANSP

               Purpose: This property defines whether an event is transparent or not
               to busy time searches.

               Value Type: TEXT

               Property Parameters: Non-standard property parameters can be
               specified on this property.

               Conformance: This property can be specified once in a "VEVENT"
               calendar component.

               Description: Time Transparency is the characteristic of an event that
               determines whether it appears to consume time on a calendar. Events
               that consume actual time for the individual or resource associated

               with the calendar SHOULD be recorded as OPAQUE, allowing them to be
               detected by free-busy time searches. Other events, which do not take
               up the individual's (or resource's) time SHOULD be recorded as
               TRANSPARENT, making them invisible to free-busy time searches.

               Format Definition: The property is specified by the following
               notation:

                 transp     = "TRANSP" tranparam ":" transvalue CRLF

                 tranparam  = *(";" xparam)

                 transvalue = "OPAQUE"      ;Blocks or opaque on busy time searches.
                            / "TRANSPARENT" ;Transparent on busy time searches.
                    ;Default value is OPAQUE

               Example: The following is an example of this property for an event
               that is transparent or does not block on free/busy time searches:

                 TRANSP:TRANSPARENT

               The following is an example of this property for an event that is
               opaque or blocks on free/busy time searches:

                 TRANSP:OPAQUE

             */
            if (icalEventParser)
            {
                iCalEvent.setTransparency(extractAttribute(iCalLine, "TRANSP"));
            }
        }
        else if (iCalLine.startsWith("TZID") )
        {
             /*
            4.8.3 Time Zone Component Properties

               The following properties specify time zone information in calendar
               components.

            4.8.3.1 Time Zone Identifier

               Property Name: TZID

               Purpose: This property specifies the text value that uniquely
               identifies the "VTIMEZONE" calendar component.

               Value Type: TEXT

               Property Parameters: Non-standard property parameters can be
               specified on this property.

               Conformance: This property MUST be specified in a "VTIMEZONE"
               calendar component.

               Description:
               This is the label by which a time zone calendar
               component is referenced by any ICalendar properties whose data type
               is either DATE-TIME or TIME and not intended to specify a UTC or a
               "floating" time. The presence of the SOLIDUS character (US-ASCII
               decimal 47) as a prefix, indicates that this TZID represents an
               unique ID in a globally defined time zone registry (when such
               registry is defined).

                    Note: This document does not define a naming convention for time
                    zone identifiers. Implementers may want to use the naming
                    conventions defined in existing time zone specifications such as
                    the public-domain Olson database [TZ]. The specification of
                    globally unique time zone identifiers is not addressed by this
                    document and is left for future study.

               Format Definition: This property is defined by the following
               notation:

                 tzid       = "TZID" tzidpropparam ":" [tzidprefix] text CRLF

                 tzidpropparam      = *(";" xparam)

                 ;tzidprefix        = "/"
                 ; Defined previously. Just listed here for reader convenience.

               Example: The following are examples of non-globally unique time zone
               identifiers:

                 TZID:US-Eastern

                 TZID:California-Los_Angeles

               The following is an example of a fictitious globally unique time zone
               identifier:

                 TZID:/US-New_York-New_York

             */
            if (icalTimeZoneParser)
            {
                icalTimeZone.setTzID(extractAttribute(iCalLine, "TZID"));
            }
        }
        else if (iCalLine.startsWith("BEGIN:STANDARD") )
        {
            // Time Zone Standard
            timeZoneType = "STANDARD";
        }
        else if (iCalLine.startsWith("BEGIN:DAYLIGHT") )
        {
            // Time Zone Daylight
            timeZoneType = "DAYLIGHT";
        }
        else if (iCalLine.startsWith("TZNAME") )
        {
             /*
            4.8.3.2 Time Zone Name

               Property Name: TZNAME

               Purpose: This property specifies the customary designation for a time
               zone description.

               Value Type: TEXT

               Property Parameters: Non-standard and language property parameters
               can be specified on this property.

               Conformance: This property can be specified in a "VTIMEZONE" calendar
               component.

               Description: This property may be specified in multiple languages; in
               order to provide for different language requirements.

               Format Definition: This property is defined by the following
               notation:

                 tzname     = "TZNAME" tznparam ":" text CRLF

                 tznparam   = *(

                            ; the following is optional,
                            ; but MUST NOT occur more than once

                            (";" languageparam) /

                            ; the following is optional,
                            ; and MAY occur more than once

                            (";" xparam)

                            )

               Example: The following are example of this property:

                 TZNAME:EST

               The following is an example of this property when two different
               languages for the time zone name are specified:

                 TZNAME;LANGUAGE=en:EST
                 TZNAME;LANGUAGE=fr-CA:HNE

             */
            if (icalTimeZoneParser)
            {
                if (timeZoneType.equalsIgnoreCase("STANDARD") )
                {
                    icalTimeZone.setstandardTzName(extractAttribute(iCalLine, "TZNAME"));
                }
                else
                {
                    icalTimeZone.setdaylightTzName(extractAttribute(iCalLine, "TZNAME"));
                }
            }
        }
        else if (iCalLine.startsWith("TZOFFSETFROM") )
        {
             /*
            4.8.3.3 Time Zone Offset From

               Property Name: TZOFFSETFROM

               Purpose: This property specifies the offset which is in use prior to
               this time zone observance.

               Value Type: UTC-OFFSET

               Property Parameters: Non-standard property parameters can be
               specified on this property.

               Conformance: This property MUST be specified in a "VTIMEZONE"
               calendar component.

               Description: This property specifies the offset which is in use prior
               to this time observance. It is used to calculate the absolute time at
               which the transition to a given observance takes place. This property
               MUST only be specified in a "VTIMEZONE" calendar component. A
               "VTIMEZONE" calendar component MUST include this property. The
               property value is a signed numeric indicating the number of hours and
               possibly minutes from UTC. Positive numbers represent time zones east
               of the prime meridian, or ahead of UTC. Negative numbers represent
               time zones west of the prime meridian, or behind UTC.

               Format Definition: The property is defined by the following notation:

                 tzoffsetfrom       = "TZOFFSETFROM" frmparam ":" utc-offset
                                      CRLF

                 frmparam   = *(";" xparam)

               Example: The following are examples of this property:

                 TZOFFSETFROM:-0500

                 TZOFFSETFROM:+1345

            */
            if (icalTimeZoneParser)
            {
                String offSetVal = iCalLine.substring("TZOFFSETFROM:".length());
                if (offSetVal.startsWith("+"))
                {
                    offSetVal = offSetVal.substring(1);
                }
                if (timeZoneType.equalsIgnoreCase("STANDARD") )
                {
                    icalTimeZone.setstandardTzOffsetFrom(java.lang.Integer.parseInt(offSetVal));
                }
                else
                {
                    icalTimeZone.setdaylightTzOffsetFrom(java.lang.Integer.parseInt(offSetVal));
                }
            }
        }
        else if (iCalLine.startsWith("TZOFFSETTO") )
        {
             /*
            4.8.3.4 Time Zone Offset To

               Property Name: TZOFFSETTO

               Purpose: This property specifies the offset which is in use in this
               time zone observance.

               Value Type: UTC-OFFSET

               Property Parameters: Non-standard property parameters can be
               specified on this property.

               Conformance: This property MUST be specified in a "VTIMEZONE"
               calendar component.

               Description: This property specifies the offset which is in use in
               this time zone observance. It is used to calculate the absolute time
               for the new observance. The property value is a signed numeric
               indicating the number of hours and possibly minutes from UTC.
               Positive numbers represent time zones east of the prime meridian, or
               ahead of UTC. Negative numbers represent time zones west of the prime
               meridian, or behind UTC.

               Format Definition: The property is defined by the following notation:

                 tzoffsetto = "TZOFFSETTO" toparam ":" utc-offset CRLF

                 toparam    = *(";" xparam)

               Example: The following are examples of this property:

                 TZOFFSETTO:-0400

                 TZOFFSETTO:+1245

             */
        }
        else if (iCalLine.startsWith("TZURL") )
        {
             /*
            4.8.3.5 Time Zone URL

               Property Name: TZURL

               Purpose: The TZURL provides a means for a VTIMEZONE component to
               point to a network location that can be used to retrieve an up-to-
               date version of itself.

               Value Type: URI

               Property Parameters: Non-standard property parameters can be
               specified on this property.

               Conformance: This property can be specified in a "VTIMEZONE" calendar
               component.

               Description: The TZURL provides a means for a VTIMEZONE component to
               point to a network location that can be used to retrieve an up-to-
               date version of itself. This provides a hook to handle changes
               government bodies impose upon time zone definitions. Retrieval of
               this resource results in an ICalendar object containing a single
               VTIMEZONE component and a METHOD property set to PUBLISH.

               Format Definition: The property is defined by the following notation:

                 tzurl      = "TZURL" tzurlparam ":" uri CRLF

                 tzurlparam = *(";" xparam)

               Example: The following is an example of this property:

                 TZURL:http://timezones.r.us.net/tz/US-California-Los_Angeles

             */
        }
        else if (iCalLine.startsWith("ATTENDEE") )
        {
             /*
                4.8.4 Relationship Component Properties

                   The following properties specify relationship information in calendar
                   components.

                4.8.4.1 Attendee

                   Property Name: ATTENDEE

                   Purpose: The property defines an "Attendee" within a calendar
                   component.

                   Value Type: CAL-ADDRESS

                   Property Parameters: Non-standard, language, calendar user type,
                   group or list membership, participation role, participation status,
                   RSVP expectation, delegatee, delegator, sent by, common name or
                   directory entry reference property parameters can be specified on
                   this property.

                   Conformance: This property MUST be specified in an ICalendar object
                   that specifies a group scheduled calendar entity. This property MUST
                   NOT be specified in an ICalendar object when publishing the calendar
                   information (e.g., NOT in an ICalendar object that specifies the
                   publication of a calendar user's busy time, event, to-do or journal).
                   This property is not specified in an ICalendar object that specifies
                   only a time zone definition or that defines calendar entities that
                   are not group scheduled entities, but are entities only on a single
                   user's calendar.

                   Description: The property MUST only be specified within calendar
                   components to specify participants, non-participants and the chair of
                   a group scheduled calendar entity. The property is specified within
                   an "EMAIL" category of the "VALARM" calendar component to specify an
                   email address that is to receive the email type of ICalendar alarm.

                   The property parameter CN is for the common or displayable name
                   associated with the calendar address; ROLE, for the intended role
                   that the attendee will have in the calendar component; PARTSTAT, for
                   the status of the attendee's participation; RSVP, for indicating
                   whether the favor of a reply is requested; CUTYPE, to indicate the
                   type of calendar user; MEMBER, to indicate the groups that the
                   attendee belongs to; DELEGATED-TO, to indicate the calendar users
                   that the original request was delegated to; and DELEGATED-FROM, to
                   indicate whom the request was delegated from; SENT-BY, to indicate
                   whom is acting on behalf of the ATTENDEE; and DIR, to indicate the
                   URI that points to the directory information corresponding to the
                   attendee. These property parameters can be specified on an "ATTENDEE"
                   property in either a "VEVENT", "VTODO" or "VJOURNAL" calendar
                   component. They MUST not be specified in an "ATTENDEE" property in a
                   "VFREEBUSY" or "VALARM" calendar component. If the LANGUAGE property
                   parameter is specified, the identified language applies to the CN
                   parameter.

                   A recipient delegated a request MUST inherit the RSVP and ROLE values
                   from the attendee that delegated the request to them.

                   Multiple attendees can be specified by including multiple "ATTENDEE"
                   properties within the calendar component.

                   Format Definition: The property is defined by the following notation:

                     attendee   = "ATTENDEE" attparam ":" cal-address CRLF

                     attparam   = *(

                                ; the following are optional,
                                ; but MUST NOT occur more than once

                                (";" cutypeparam) / (";"memberparam) /
                                (";" roleparam) / (";" partstatparam) /
                                (";" rsvpparam) / (";" deltoparam) /
                                (";" delfromparam) / (";" sentbyparam) /
                                (";"cnparam) / (";" dirparam) /
                                (";" languageparam) /

                                ; the following is optional,
                                ; and MAY occur more than once

                                (";" xparam)

                                )

                   Example: The following are examples of this property's use for a to-
                   do:

                     ORGANIZER:MAILTO:jsmith@host1.com
                     ATTENDEE;MEMBER="MAILTO:DEV-GROUP@host2.com":
                      MAILTO:joecool@host2.com
                     ATTENDEE;DELEGATED-FROM="MAILTO:immud@host3.com":
                      MAILTO:ildoit@host1.com

                   The following is an example of this property used for specifying
                   multiple attendees to an event:

                     ORGANIZER:MAILTO:jsmith@host1.com
                     ATTENDEE;ROLE=REQ-PARTICIPANT;PARTSTAT=TENTATIVE;CN=Henry Cabot
                      :MAILTO:hcabot@host2.com
                     ATTENDEE;ROLE=REQ-PARTICIPANT;DELEGATED-FROM="MAILTO:bob@host.com"
                      ;PARTSTAT=ACCEPTED;CN=Jane Doe:MAILTO:jdoe@host1.com

                   The following is an example of this property with a URI to the
                   directory information associated with the attendee:

                     ATTENDEE;CN=John Smith;DIR="ldap://host.com:6666/o=eDABC%
                      20Industries,c=3DUS??(cn=3DBJim%20Dolittle)":MAILTO:jimdo@
                      host1.com

                   The following is an example of this property with "delegatee" and
                   "delegator" information for an event:

                     ORGANIZER;CN=John Smith:MAILTO:jsmith@host.com
                     ATTENDEE;ROLE=REQ-PARTICIPANT;PARTSTAT=TENTATIVE;DELEGATED-FROM=
                      "MAILTO:iamboss@host2.com";CN=Henry Cabot:MAILTO:hcabot@
                      host2.com
                     ATTENDEE;ROLE=NON-PARTICIPANT;PARTSTAT=DELEGATED;DELEGATED-TO=
                      "MAILTO:hcabot@host2.com";CN=The Big Cheese:MAILTO:iamboss
                      @host2.com
                     ATTENDEE;ROLE=REQ-PARTICIPANT;PARTSTAT=ACCEPTED;CN=Jane Doe
                      :MAILTO:jdoe@host1.com

                   Example: The following is an example of this property's use when
                   another calendar user is acting on behalf of the "Attendee":

                     ATTENDEE;SENT-BY=MAILTO:jan_doe@host1.com;CN=John Smith:MAILTO:
                      jsmith@host1.com
             */
        	// This should be implemented as a collection under the VEVENT. Some other time
        }
        else if (iCalLine.startsWith("CONTACT") )
        {
             /*
             4.8.4.2 Contact

               Property Name: CONTACT

               Purpose: The property is used to represent contact information or
               alternately a reference to contact information associated with the
               calendar component.

               Value Type: TEXT

               Property Parameters: Non-standard, alternate text representation and
               language property parameters can be specified on this property.

               Conformance: The property can be specified in a "VEVENT", "VTODO",
               "VJOURNAL" or "VFREEBUSY" calendar component.

               Description: The property value consists of textual contact
               information. An alternative representation for the property value can
               also be specified that refers to a URI pointing to an alternate form,
               such as a vCard [RFC 2426], for the contact information.

               Format Definition: The property is defined by the following notation:

                 contact    = "CONTACT" contparam ":" text CRLF

                 contparam  = *(
                            ; the following are optional,
                            ; but MUST NOT occur more than once

                            (";" altrepparam) / (";" languageparam) /

                            ; the following is optional,
                            ; and MAY occur more than once

                            (";" xparam)

                            )

               Example: The following is an example of this property referencing
               textual contact information:

                 CONTACT:Jim Dolittle\, ABC Industries\, +1-919-555-1234

               The following is an example of this property with an alternate
               representation of a LDAP URI to a directory entry containing the
               contact information:

                 CONTACT;ALTREP="ldap://host.com:6666/o=3DABC%20Industries\,
                  c=3DUS??(cn=3DBJim%20Dolittle)":Jim Dolittle\, ABC Industries\,
                  +1-919-555-1234

               The following is an example of this property with an alternate
               representation of a MIME body part containing the contact
               information, such as a vCard [RFC 2426] embedded in a [MIME-DIR]
               content-type:

                 CONTACT;ALTREP="CID=<part3.msg970930T083000SILVER@host.com>":Jim
                   Dolittle\, ABC Industries\, +1-919-555-1234

               The following is an example of this property referencing a network
               resource, such as a vCard [RFC 2426] object containing the contact
               information:

                 CONTACT;ALTREP="http://host.com/pdi/jdoe.vcf":Jim
                   Dolittle\, ABC Industries\, +1-919-555-1234

             */
        	if (icalEventParser)
        	{
        		// We will break this field into currently two bits. One is the original iCalendar data
        		// 'organizer' the other is the email address.
        		iCalEvent.setContact(extractAttribute(iCalLine, "CONTACT"));
        	}
        }
        else if (iCalLine.startsWith("ORGANIZER") )
        {
             /*
            4.8.4.3 Organizer

               Property Name: ORGANIZER

               Purpose: The property defines the organizer for a calendar component.

               Value Type: CAL-ADDRESS

               Property Parameters: Non-standard, language, common name, directory
               entry reference, sent by property parameters can be specified on this
               property.

               Conformance: This property MUST be specified in an ICalendar object
               that specifies a group scheduled calendar entity. This property MUST
               be specified in an ICalendar object that specifies the publication of
               a calendar user's busy time. This property MUST NOT be specified in
               an ICalendar object that specifies only a time zone definition or
               that defines calendar entities that are not group scheduled entities,
               but are entities only on a single user's calendar.

               Description: The property is specified within the "VEVENT", "VTODO",
               "VJOURNAL calendar components to specify the organizer of a group
               scheduled calendar entity. The property is specified within the
               "VFREEBUSY" calendar component to specify the calendar user
               requesting the free or busy time. When publishing a "VFREEBUSY"
               calendar component, the property is used to specify the calendar that
               the published busy time came from.

               The property has the property parameters CN, for specifying the
               common or display name associated with the "Organizer", DIR, for
               specifying a pointer to the directory information associated with the
               "Organizer", SENT-BY, for specifying another calendar user that is
               acting on behalf of the "Organizer". The non-standard parameters may
               also be specified on this property. If the LANGUAGE property
               parameter is specified, the identified language applies to the CN
               parameter value.

               Format Definition: The property is defined by the following notation:

                 organizer  = "ORGANIZER" orgparam ":"
                              cal-address CRLF

                 orgparam   = *(

                            ; the following are optional,
                            ; but MUST NOT occur more than once

                            (";" cnparam) / (";" dirparam) / (";" sentbyparam) /
                            (";" languageparam) /

                            ; the following is optional,
                            ; and MAY occur more than once

                            (";" xparam)

                            )

               Example: The following is an example of this property:

                 ORGANIZER;CN=John Smith:MAILTO:jsmith@host1.com

               The following is an example of this property with a pointer to the
               directory information associated with the organizer:

                 ORGANIZER;CN=JohnSmith;DIR="ldap://host.com:6666/o=3DDC%20Associ
                  ates,c=3DUS??(cn=3DJohn%20Smith)":MAILTO:jsmith@host1.com

               The following is an example of this property used by another calendar
               user who is acting on behalf of the organizer, with responses
               intended to be sent back to the organizer, not the other calendar
               user:

                 ORGANIZER;SENT-BY="MAILTO:jane_doe@host.com":
                  MAILTO:jsmith@host1.com

             */
        	//        	 Add support for parsing the iCal Event Organizer
        	if (icalEventParser)
        	{
        		// We will break this field into currently two bits. One is the original iCalendar data
        		// 'organizer' the other is the email address.
        		parseOrganizer(iCalEvent, extractAttribute(iCalLine, "ORGANIZER"));
        	}
        	else // iCal level
        		ical.setOrganizer(extractAttribute(iCalLine, "ORGANIZER"));
        }
        else if (iCalLine.startsWith("RECURRENCE-ID") )
        {
             /*
             4.8.4.4 Recurrence ID

               Property Name: RECURRENCE-ID

               Purpose: This property is used in conjunction with the "UID" and
               "SEQUENCE" property to identify a specific instance of a recurring
               "VEVENT", "VTODO" or "VJOURNAL" calendar component. The property
               value is the effective value of the "DTSTART" property of the
               recurrence instance.

               Value Type: The default value type for this property is DATE-TIME.
               The time format can be any of the valid forms defined for a DATE-TIME
               value type. See DATE-TIME value type definition for specific
               interpretations of the various forms. The value type can be set to
               DATE.

               Property Parameters: Non-standard property, value data type, time
               zone identifier and recurrence identifier range parameters can be
               specified on this property.

               Conformance: This property can be specified in an ICalendar object
               containing a recurring calendar component.

               Description: The full range of calendar components specified by a
               recurrence set is referenced by referring to just the "UID" property
               value corresponding to the calendar component. The "RECURRENCE-ID"
               property allows the reference to an individual instance within the
               recurrence set.

               If the value of the "DTSTART" property is a DATE type value, then the
               value MUST be the calendar date for the recurrence instance.

               The date/time value is set to the time when the original recurrence
               instance would occur; meaning that if the intent is to change a
               Friday meeting to Thursday, the date/time is still set to the
               original Friday meeting.

               The "RECURRENCE-ID" property is used in conjunction with the "UID"
               and "SEQUENCE" property to identify a particular instance of a
               recurring event, to-do or journal. For a given pair of "UID" and
               "SEQUENCE" property values, the "RECURRENCE-ID" value for a
               recurrence instance is fixed. When the definition of the recurrence
               set for a calendar component changes, and hence the "SEQUENCE"
               property value changes, the "RECURRENCE-ID" for a given recurrence
               instance might also change.The "RANGE" parameter is used to specify
               the effective range of recurrence instances from the instance
               specified by the "RECURRENCE-ID" property value. The default value
               for the range parameter is the single recurrence instance only. The
               value can also be "THISANDPRIOR" to indicate a range defined by the
               given recurrence instance and all prior instances or the value can be
               "THISANDFUTURE" to indicate a range defined by the given recurrence
               instance and all subsequent instances.

               Format Definition: The property is defined by the following notation:

                 recurid    = "RECURRENCE-ID" ridparam ":" ridval CRLF

                 ridparam   = *(

                            ; the following are optional,
                            ; but MUST NOT occur more than once

                            (";" "VALUE" "=" ("DATE-TIME" / "DATE)) /
                            (";" tzidparam) / (";" rangeparam) /
                            ; the following is optional,
                            ; and MAY occur more than once

                            (";" xparam)

                            )

                 ridval     = date-time / date
                 ;Value MUST match value type

               Example: The following are examples of this property:

                 RECURRENCE-ID;VALUE=DATE:19960401

                 RECURRENCE-ID;RANGE=THISANDFUTURE:19960120T120000Z

             */

        	// Added to support fixing single occurrence Exceptions
        	// for a recurring event
        	if (icalEventParser)
        	{
        		iCalEvent.setRecurrenceId(true);
        	}


        }
        else if (iCalLine.startsWith("RELATED-TO") )
        {
             /*
            4.8.4.5 Related To

               Property Name: RELATED-TO

               Purpose: The property is used to represent a relationship or
               reference between one calendar component and another.

               Value Type: TEXT

               Property Parameters: Non-standard and relationship type property
               parameters can be specified on this property.

               Conformance: The property can be specified one or more times in the
               "VEVENT", "VTODO" or "VJOURNAL" calendar components.

               Description: The property value consists of the persistent, globally
               unique identifier of another calendar component. This value would be
               represented in a calendar component by the "UID" property.

               By default, the property value points to another calendar component
               that has a PARENT relationship to the referencing object. The
               "RELTYPE" property parameter is used to either explicitly state the
               default PARENT relationship type to the referenced calendar component
               or to override the default PARENT relationship type and specify
               either a CHILD or SIBLING relationship. The PARENT relationship
               indicates that the calendar component is a subordinate of the
               referenced calendar component. The CHILD relationship indicates that
               the calendar component is a superior of the referenced calendar
               component. The SIBLING relationship indicates that the calendar
               component is a peer of the referenced calendar component.

               Changes to a calendar component referenced by this property can have
               an implicit impact on the related calendar component. For example, if
               a group event changes its start or end date or time, then the
               related, dependent events will need to have their start and end dates
               changed in a corresponding way. Similarly, if a PARENT calendar
               component is canceled or deleted, then there is an implied impact to
               the related CHILD calendar components. This property is intended only
               to provide information on the relationship of calendar components. It
               is up to the target calendar system to maintain any property
               implications of this relationship.

               Format Definition: The property is defined by the following notation:

                 related    = "RELATED-TO" [relparam] ":" text CRLF

                 relparam   = *(

                            ; the following is optional,
                            ; but MUST NOT occur more than once

                            (";" reltypeparam) /

                            ; the following is optional,
                            ; and MAY occur more than once

                            (";" xparm)

                            )

               The following is an example of this property:

                 RELATED-TO:<jsmith.part7.19960817T083000.xyzMail@host3.com>

                 RELATED-TO:<19960401-080045-4000F192713-0052@host1.com>

             */
        	if (icalEventParser)
        	{
        		iCalEvent.setRelatedTo(extractAttribute(iCalLine, "RELATED-TO"));
        	}
        }
        else if (iCalLine.startsWith("URL") )
        {
             /*
            4.8.4.6 Uniform Resource Locator

               Property Name: URL

               Purpose: This property defines a Uniform Resource Locator (URL)
               associated with the ICalendar object.

               Value Type: URI

               Property Parameters: Non-standard property parameters can be
               specified on this property.

               Conformance: This property can be specified once in the "VEVENT",
               "VTODO", "VJOURNAL" or "VFREEBUSY" calendar components.

               Description: This property may be used in a calendar component to
               convey a location where a more dynamic rendition of the calendar
               information associated with the calendar component can be found. This
               memo does not attempt to standardize the form of the URI, nor the
               format of the resource pointed to by the property value. If the URL
               property and Content-Location MIME header are both specified, they
               MUST point to the same resource.

               Format Definition: The property is defined by the following notation:

                 url        = "URL" urlparam ":" uri CRLF

                 urlparam   = *(";" xparam)

               Example: The following is an example of this property:

                 URL:http://abc.com/pub/calendars/jsmith/mytime.ics

             */
        	// Add support for parsing and iCal Event URL
        	if (icalEventParser)
        	{
        		String url = extractAttribute(iCalLine, "URL");
        		if (url.startsWith("VALUE=URI:")) {
        		    url = url.substring(10);
        		}
        		iCalEvent.setUrl(url);
        	}



        }
        else if (iCalLine.startsWith("EXDATE") )
        {
             /*
            4.8.5 Recurrence Component Properties

               The following properties specify recurrence information in calendar
               components.

            4.8.5.1 Exception Date/Times

               Property Name: EXDATE

               Purpose: This property defines the list of date/time exceptions for a
               recurring calendar component.

               Value Type: The default value type for this property is DATE-TIME.
               The value type can be set to DATE.

               Property Parameters: Non-standard, value data type and time zone
               identifier property parameters can be specified on this property.

               Conformance: This property can be specified in an ICalendar object
               that includes a recurring calendar component.

               Description: The exception dates, if specified, are used in computing
               the recurrence set. The recurrence set is the complete set of
               recurrence instances for a calendar component. The recurrence set is
               generated by considering the initial "DTSTART" property along with
               the "RRULE", "RDATE", "EXDATE" and "EXRULE" properties contained
               within the ICalendar object. The "DTSTART" property defines the first
               instance in the recurrence set. Multiple instances of the "RRULE" and
               "EXRULE" properties can also be specified to define more
               sophisticated recurrence sets. The final recurrence set is generated
               by gathering all of the start date-times generated by any of the
               specified "RRULE" and "RDATE" properties, and then excluding any
               start date and times which fall within the union of start date and
               times generated by any specified "EXRULE" and "EXDATE" properties.
               This implies that start date and times within exclusion related
               properties (i.e., "EXDATE" and "EXRULE") take precedence over those
               specified by inclusion properties (i.e., "RDATE" and "RRULE"). Where
               duplicate instances are generated by the "RRULE" and "RDATE"
               properties, only one recurrence is considered. Duplicate instances
               are ignored.

               The "EXDATE" property can be used to exclude the value specified in
               "DTSTART". However, in such cases the original "DTSTART" date MUST
               still be maintained by the calendaring and scheduling system because
               the original "DTSTART" value has inherent usage dependencies by other
               properties such as the "RECURRENCE-ID".

               Format Definition: The property is defined by the following notation:

                 exdate     = "EXDATE" exdtparam ":" exdtval *("," exdtval) CRLF

                 exdtparam  = *(

                            ; the following are optional,
                            ; but MUST NOT occur more than once

                            (";" "VALUE" "=" ("DATE-TIME" / "DATE")) /

                            (";" tzidparam) /

                            ; the following is optional,
                            ; and MAY occur more than once

                            (";" xparam)

                            )

                 exdtval    = date-time / date
                 ;Value MUST match value type

               Example: The following is an example of this property:

                 EXDATE:19960402T010000Z,19960403T010000Z,19960404T010000Z

             */
            if (icalEventParser)
            {
            	// Fix a bug parsing recurring event Exception Dates
				parseExDate(iCalEvent,iCalLine.substring(7));

                //iCalEvent.exDateCollection.add(iCalLine.substring(18));
                iCalEvent.setExDatesExist(true);
            }
        }
        else if (iCalLine.startsWith("RRULE") )
        {
             /*
            4.8.5.4 Recurrence Rule

               Property Name: RRULE

               Purpose: This property defines a rule or repeating pattern for
               recurring events, to-dos, or time zone definitions.

               Value Type: RECUR

               Property Parameters: Non-standard property parameters can be
               specified on this property.

               Conformance: This property can be specified one or more times in
               recurring "VEVENT", "VTODO" and "VJOURNAL" calendar components. It
               can also be specified once in each STANDARD or DAYLIGHT sub-component
               of the "VTIMEZONE" calendar component.

               Description: The recurrence rule, if specified, is used in computing
               the recurrence set. The recurrence set is the complete set of
               recurrence instances for a calendar component. The recurrence set is
               generated by considering the initial "DTSTART" property along with
               the "RRULE", "RDATE", "EXDATE" and "EXRULE" properties contained
               within the ICalendar object. The "DTSTART" property defines the first
               instance in the recurrence set. Multiple instances of the "RRULE" and
               "EXRULE" properties can also be specified to define more
               sophisticated recurrence sets. The final recurrence set is generated
               by gathering all of the start date/times generated by any of the
               specified "RRULE" and "RDATE" properties, and excluding any start
               date/times which fall within the union of start date/times generated
               by any specified "EXRULE" and "EXDATE" properties. This implies that
               start date/times within exclusion related properties (i.e., "EXDATE"
               and "EXRULE") take precedence over those specified by inclusion
               properties (i.e., "RDATE" and "RRULE"). Where duplicate instances are
               generated by the "RRULE" and "RDATE" properties, only one recurrence
               is considered. Duplicate instances are ignored.

               The "DTSTART" and "DTEND" property pair or "DTSTART" and "DURATION"
               property pair, specified within the ICalendar object defines the
               first instance of the recurrence. When used with a recurrence rule,
               the "DTSTART" and "DTEND" properties MUST be specified in local time
               and the appropriate set of "VTIMEZONE" calendar components MUST be
               included. For detail on the usage of the "VTIMEZONE" calendar
               component, see the "VTIMEZONE" calendar component definition.

               Any duration associated with the ICalendar object applies to all
               members of the generated recurrence set. Any modified duration for
               specific recurrences MUST be explicitly specified using the "RDATE"
               property.

               Format Definition: This property is defined by the following
               notation:

                 rrule      = "RRULE" rrulparam ":" recur CRLF

                 rrulparam  = *(";" xparam)

               Example: All examples assume the Eastern United States time zone.

               Daily for 10 occurrences:

                 DTSTART;TZID=US-Eastern:19970902T090000
                 RRULE:FREQ=DAILY;COUNT=10

                 ==> (1997 9:00 AM EDT)September 2-11

               Daily until December 24, 1997:

                 DTSTART;TZID=US-Eastern:19970902T090000
                 RRULE:FREQ=DAILY;UNTIL=19971224T000000Z

                 ==> (1997 9:00 AM EDT)September 2-30;October 1-25
                     (1997 9:00 AM EST)October 26-31;November 1-30;December 1-23

               Every other day - forever:

                 DTSTART;TZID=US-Eastern:19970902T090000
                 RRULE:FREQ=DAILY;INTERVAL=2
                 ==> (1997 9:00 AM EDT)September2,4,6,8...24,26,28,30;
                      October 2,4,6...20,22,24
                     (1997 9:00 AM EST)October 26,28,30;November 1,3,5,7...25,27,29;
                      Dec 1,3,...

               Every 10 days, 5 occurrences:
              *
                 DTSTART;TZID=US-Eastern:19970902T090000
                 RRULE:FREQ=DAILY;INTERVAL=10;COUNT=5

                 ==> (1997 9:00 AM EDT)September 2,12,22;October 2,12

               Everyday in January, for 3 years:

                 DTSTART;TZID=US-Eastern:19980101T090000
                 RRULE:FREQ=YEARLY;UNTIL=20000131T090000Z;
                  BYMONTH=1;BYDAY=SU,MO,TU,WE,TH,FR,SA
                 or
                 RRULE:FREQ=DAILY;UNTIL=20000131T090000Z;BYMONTH=1

                 ==> (1998 9:00 AM EDT)January 1-31
                     (1999 9:00 AM EDT)January 1-31
                     (2000 9:00 AM EDT)January 1-31

               Weekly for 10 occurrences

                 DTSTART;TZID=US-Eastern:19970902T090000
                 RRULE:FREQ=WEEKLY;COUNT=10

                 ==> (1997 9:00 AM EDT)September 2,9,16,23,30;October 7,14,21
                     (1997 9:00 AM EST)October 28;November 4

               Weekly until December 24, 1997

                 DTSTART;TZID=US-Eastern:19970902T090000
                 RRULE:FREQ=WEEKLY;UNTIL=19971224T000000Z

                 ==> (1997 9:00 AM EDT)September 2,9,16,23,30;October 7,14,21
                     (1997 9:00 AM EST)October 28;November 4,11,18,25;
                                       December 2,9,16,23
               Every other week - forever:

                 DTSTART;TZID=US-Eastern:19970902T090000
                 RRULE:FREQ=WEEKLY;INTERVAL=2;WKST=SU

                 ==> (1997 9:00 AM EDT)September 2,16,30;October 14
                     (1997 9:00 AM EST)October 28;November 11,25;December 9,23
                     (1998 9:00 AM EST)January 6,20;February
                 ...

               Weekly on Tuesday and Thursday for 5 weeks:

                DTSTART;TZID=US-Eastern:19970902T090000
                RRULE:FREQ=WEEKLY;UNTIL=19971007T000000Z;WKST=SU;BYDAY=TU,TH
                or

                RRULE:FREQ=WEEKLY;COUNT=10;WKST=SU;BYDAY=TU,TH

                ==> (1997 9:00 AM EDT)September 2,4,9,11,16,18,23,25,30;October 2

               Every other week on Monday, Wednesday and Friday until December 24,
               1997, but starting on Tuesday, September 2, 1997:

                 DTSTART;TZID=US-Eastern:19970902T090000
                 RRULE:FREQ=WEEKLY;INTERVAL=2;UNTIL=19971224T000000Z;WKST=SU;
                  BYDAY=MO,WE,FR
                 ==> (1997 9:00 AM EDT)September 2,3,5,15,17,19,29;October
                 1,3,13,15,17
                     (1997 9:00 AM EST)October 27,29,31;November 10,12,14,24,26,28;
                                       December 8,10,12,22

               Every other week on Tuesday and Thursday, for 8 occurrences:

                 DTSTART;TZID=US-Eastern:19970902T090000
                 RRULE:FREQ=WEEKLY;INTERVAL=2;COUNT=8;WKST=SU;BYDAY=TU,TH

                 ==> (1997 9:00 AM EDT)September 2,4,16,18,30;October 2,14,16

               Monthly on the 1st Friday for ten occurrences:

                 DTSTART;TZID=US-Eastern:19970905T090000
                 RRULE:FREQ=MONTHLY;COUNT=10;BYDAY=1FR

                 ==> (1997 9:00 AM EDT)September 5;October 3
                     (1997 9:00 AM EST)November 7;Dec 5
                     (1998 9:00 AM EST)January 2;February 6;March 6;April 3
                     (1998 9:00 AM EDT)May 1;June 5

               Monthly on the 1st Friday until December 24, 1997:

                 DTSTART;TZID=US-Eastern:19970905T090000
                 RRULE:FREQ=MONTHLY;UNTIL=19971224T000000Z;BYDAY=1FR

                 ==> (1997 9:00 AM EDT)September 5;October 3
                     (1997 9:00 AM EST)November 7;December 5

               Every other month on the 1st and last Sunday of the month for 10
               occurrences:

                 DTSTART;TZID=US-Eastern:19970907T090000
                 RRULE:FREQ=MONTHLY;INTERVAL=2;COUNT=10;BYDAY=1SU,-1SU

                 ==> (1997 9:00 AM EDT)September 7,28
                     (1997 9:00 AM EST)November 2,30
                     (1998 9:00 AM EST)January 4,25;March 1,29
                     (1998 9:00 AM EDT)May 3,31

               Monthly on the second to last Monday of the month for 6 months:

                 DTSTART;TZID=US-Eastern:19970922T090000
                 RRULE:FREQ=MONTHLY;COUNT=6;BYDAY=-2MO

                 ==> (1997 9:00 AM EDT)September 22;October 20
                     (1997 9:00 AM EST)November 17;December 22
                     (1998 9:00 AM EST)January 19;February 16

               Monthly on the third to the last day of the month, forever:

                 DTSTART;TZID=US-Eastern:19970928T090000
                 RRULE:FREQ=MONTHLY;BYMONTHDAY=-3

                 ==> (1997 9:00 AM EDT)September 28
                     (1997 9:00 AM EST)October 29;November 28;December 29
                     (1998 9:00 AM EST)January 29;February 26
                 ...

               Monthly on the 2nd and 15th of the month for 10 occurrences:

                 DTSTART;TZID=US-Eastern:19970902T090000
                 RRULE:FREQ=MONTHLY;COUNT=10;BYMONTHDAY=2,15

                 ==> (1997 9:00 AM EDT)September 2,15;October 2,15
                     (1997 9:00 AM EST)November 2,15;December 2,15
                     (1998 9:00 AM EST)January 2,15

               Monthly on the first and last day of the month for 10 occurrences:

                 DTSTART;TZID=US-Eastern:19970930T090000
                 RRULE:FREQ=MONTHLY;COUNT=10;BYMONTHDAY=1,-1

                 ==> (1997 9:00 AM EDT)September 30;October 1
                     (1997 9:00 AM EST)October 31;November 1,30;December 1,31
                     (1998 9:00 AM EST)January 1,31;February 1

               Every 18 months on the 10th thru 15th of the month for 10
               occurrences:

                 DTSTART;TZID=US-Eastern:19970910T090000
                 RRULE:FREQ=MONTHLY;INTERVAL=18;COUNT=10;BYMONTHDAY=10,11,12,13,14,
                  15

                 ==> (1997 9:00 AM EDT)September 10,11,12,13,14,15
                     (1999 9:00 AM EST)March 10,11,12,13

               Every Tuesday, every other month:

                 DTSTART;TZID=US-Eastern:19970902T090000
                 RRULE:FREQ=MONTHLY;INTERVAL=2;BYDAY=TU

                 ==> (1997 9:00 AM EDT)September 2,9,16,23,30
                     (1997 9:00 AM EST)November 4,11,18,25
                     (1998 9:00 AM EST)January 6,13,20,27;March 3,10,17,24,31
                 ...

               Yearly in June and July for 10 occurrences:

                 DTSTART;TZID=US-Eastern:19970610T090000
                 RRULE:FREQ=YEARLY;COUNT=10;BYMONTH=6,7
                 ==> (1997 9:00 AM EDT)June 10;July 10
                     (1998 9:00 AM EDT)June 10;July 10
                     (1999 9:00 AM EDT)June 10;July 10
                     (2000 9:00 AM EDT)June 10;July 10
                     (2001 9:00 AM EDT)June 10;July 10
                 Note: Since none of the BYDAY, BYMONTHDAY or BYYEARDAY components
                 are specified, the day is gotten from DTSTART

               Every other year on January, February, and March for 10 occurrences:

                 DTSTART;TZID=US-Eastern:19970310T090000
                 RRULE:FREQ=YEARLY;INTERVAL=2;COUNT=10;BYMONTH=1,2,3

                 ==> (1997 9:00 AM EST)March 10
                     (1999 9:00 AM EST)January 10;February 10;March 10
                     (2001 9:00 AM EST)January 10;February 10;March 10
                     (2003 9:00 AM EST)January 10;February 10;March 10

               Every 3rd year on the 1st, 100th and 200th day for 10 occurrences:

                 DTSTART;TZID=US-Eastern:19970101T090000
                 RRULE:FREQ=YEARLY;INTERVAL=3;COUNT=10;BYYEARDAY=1,100,200

                 ==> (1997 9:00 AM EST)January 1
                     (1997 9:00 AM EDT)April 10;July 19
                     (2000 9:00 AM EST)January 1
                     (2000 9:00 AM EDT)April 9;July 18
                     (2003 9:00 AM EST)January 1
                     (2003 9:00 AM EDT)April 10;July 19
                     (2006 9:00 AM EST)January 1

               Every 20th Monday of the year, forever:

                 DTSTART;TZID=US-Eastern:19970519T090000
                 RRULE:FREQ=YEARLY;BYDAY=20MO

                 ==> (1997 9:00 AM EDT)May 19
                     (1998 9:00 AM EDT)May 18
                     (1999 9:00 AM EDT)May 17
                 ...

               Monday of week number 20 (where the default start of the week is
               Monday), forever:

                 DTSTART;TZID=US-Eastern:19970512T090000
                 RRULE:FREQ=YEARLY;BYWEEKNO=20;BYDAY=MO

                 ==> (1997 9:00 AM EDT)May 12
                     (1998 9:00 AM EDT)May 11
                     (1999 9:00 AM EDT)May 17
                 ...

               Every Thursday in March, forever:

                 DTSTART;TZID=US-Eastern:19970313T090000
                 RRULE:FREQ=YEARLY;BYMONTH=3;BYDAY=TH

                 ==> (1997 9:00 AM EST)March 13,20,27
                     (1998 9:00 AM EST)March 5,12,19,26
                     (1999 9:00 AM EST)March 4,11,18,25
                 ...

               Every Thursday, but only during June, July, and August, forever:

                 DTSTART;TZID=US-Eastern:19970605T090000
                 RRULE:FREQ=YEARLY;BYDAY=TH;BYMONTH=6,7,8

                 ==> (1997 9:00 AM EDT)June 5,12,19,26;July 3,10,17,24,31;
                                   August 7,14,21,28
                     (1998 9:00 AM EDT)June 4,11,18,25;July 2,9,16,23,30;
                                   August 6,13,20,27
                     (1999 9:00 AM EDT)June 3,10,17,24;July 1,8,15,22,29;
                                   August 5,12,19,26
                 ...

               Every Friday the 13th, forever:

                 DTSTART;TZID=US-Eastern:19970902T090000
                 EXDATE;TZID=US-Eastern:19970902T090000
                 RRULE:FREQ=MONTHLY;BYDAY=FR;BYMONTHDAY=13

                 ==> (1998 9:00 AM EST)February 13;March 13;November 13
                     (1999 9:00 AM EDT)August 13
                     (2000 9:00 AM EDT)October 13
                 ...

               The first Saturday that follows the first Sunday of the month,
                forever:

                 DTSTART;TZID=US-Eastern:19970913T090000
                 RRULE:FREQ=MONTHLY;BYDAY=SA;BYMONTHDAY=7,8,9,10,11,12,13

                 ==> (1997 9:00 AM EDT)September 13;October 11
                     (1997 9:00 AM EST)November 8;December 13
                     (1998 9:00 AM EST)January 10;February 7;March 7
                     (1998 9:00 AM EDT)April 11;May 9;June 13...
                 ...

               Every four years, the first Tuesday after a Monday in November,
               forever (U.S. Presidential Election day):

                 DTSTART;TZID=US-Eastern:19961105T090000
                 RRULE:FREQ=YEARLY;INTERVAL=4;BYMONTH=11;BYDAY=TU;BYMONTHDAY=2,3,4,
                  5,6,7,8

                 ==> (1996 9:00 AM EST)November 5
                     (2000 9:00 AM EST)November 7
                     (2004 9:00 AM EST)November 2
                 ...

               The 3rd instance into the month of one of Tuesday, Wednesday or
               Thursday, for the next 3 months:

                 DTSTART;TZID=US-Eastern:19970904T090000
                 RRULE:FREQ=MONTHLY;COUNT=3;BYDAY=TU,WE,TH;BYSETPOS=3

                 ==> (1997 9:00 AM EDT)September 4;October 7
                     (1997 9:00 AM EST)November 6

               The 2nd to last weekday of the month:

                 DTSTART;TZID=US-Eastern:19970929T090000
                 RRULE:FREQ=MONTHLY;BYDAY=MO,TU,WE,TH,FR;BYSETPOS=-2

                 ==> (1997 9:00 AM EDT)September 29
                     (1997 9:00 AM EST)October 30;November 27;December 30
                     (1998 9:00 AM EST)January 29;February 26;March 30
                 ...

               Every 3 hours from 9:00 AM to 5:00 PM on a specific day:

                 DTSTART;TZID=US-Eastern:19970902T090000
                 RRULE:FREQ=HOURLY;INTERVAL=3;UNTIL=19970902T170000Z

                 ==> (September 2, 1997 EDT)09:00,12:00,15:00

               Every 15 minutes for 6 occurrences:

                 DTSTART;TZID=US-Eastern:19970902T090000
                 RRULE:FREQ=MINUTELY;INTERVAL=15;COUNT=6

                 ==> (September 2, 1997 EDT)09:00,09:15,09:30,09:45,10:00,10:15

               Every hour and a half for 4 occurrences:

                 DTSTART;TZID=US-Eastern:19970902T090000
                 RRULE:FREQ=MINUTELY;INTERVAL=90;COUNT=4

                 ==> (September 2, 1997 EDT)09:00,10:30;12:00;13:30

               Every 20 minutes from 9:00 AM to 4:40 PM every day:

                 DTSTART;TZID=US-Eastern:19970902T090000
                 RRULE:FREQ=DAILY;BYHOUR=9,10,11,12,13,14,15,16;BYMINUTE=0,20,40
                 or
                 RRULE:FREQ=MINUTELY;INTERVAL=20;BYHOUR=9,10,11,12,13,14,15,16

                 ==> (September 2, 1997 EDT)9:00,9:20,9:40,10:00,10:20,
                                            ... 16:00,16:20,16:40
                     (September 3, 1997 EDT)9:00,9:20,9:40,10:00,10:20,
                                           ...16:00,16:20,16:40
                 ...

               An example where the days generated makes a difference because of
               WKST:

                 DTSTART;TZID=US-Eastern:19970805T090000
                 RRULE:FREQ=WEEKLY;INTERVAL=2;COUNT=4;BYDAY=TU,SU;WKST=MO

                 ==> (1997 EDT)Aug 5,10,19,24

                 changing only WKST from MO to SU, yields different results...

                 DTSTART;TZID=US-Eastern:19970805T090000
                 RRULE:FREQ=WEEKLY;INTERVAL=2;COUNT=4;BYDAY=TU,SU;WKST=SU
                 ==> (1997 EDT)August 5,17,19,31

            */
            try{
                if (icalTimeZoneParser)
                {
                    if (timeZoneType.equalsIgnoreCase("STANDARD") )
                    {
                       icalTimeZone.setstandardRRule(extractAttribute(iCalLine, "RRULE"));
                    }
                    else
                    {
                        icalTimeZone.setdaylightRRule(extractAttribute(iCalLine, "RRULE"));
                    }
                }
                if (icalEventParser)
                {
                    iCalEvent.setRRule(extractAttribute(iCalLine,"RRULE"));
                    RepeatRules rr = new RepeatRules();
                    rr.parseRepeatRules(iCalEvent.getRRule());
                    // Move parsed values back into iCalEvent.
                    iCalEvent.setRepeatRules(rr);
                }
            }
            catch (Exception e)
            {
                logger.fine("Error processing RRULE line of ICalendar, line:" + lineCtr
                   + "Exception" + e);
            }
        }
        else if (iCalLine.startsWith("CREATED") )
        {
             /*
            4.8.7 Change Management Component Properties

               The following properties specify change management information in
               calendar components.

            4.8.7.1 Date/Time Created

               Property Name: CREATED

               Purpose: This property specifies the date and time that the calendar
               information was created by the calendar user agent in the calendar
               store.

                    Note: This is analogous to the creation date and time for a file
                    in the file system.

               Value Type: DATE-TIME

               Property Parameters: Non-standard property parameters can be
               specified on this property.

               Conformance: The property can be specified once in "VEVENT", "VTODO"
               or "VJOURNAL" calendar components.

               Description: The date and time is a UTC value.

               Format Definition: The property is defined by the following notation:

                 created    = "CREATED" creaparam ":" date-time CRLF

                 creaparam  = *(";" xparam)

               Example: The following is an example of this property:

                 CREATED:19960329T133000Z
             */
        	if (icalEventParser)
        		iCalEvent.setCreated(convertIcalDate(extractAttribute(iCalLine, "CREATED")));
        }
        else if (iCalLine.startsWith("DTSTAMP") )
        {
             /*
            4.8.7.2 Date/Time Stamp

               Property Name: DTSTAMP

               Purpose: The property indicates the date/time that the instance of
               the ICalendar object was created.

               Value Type: DATE-TIME

               Property Parameters: Non-standard property parameters can be
               specified on this property.

               Conformance: This property MUST be included in the "VEVENT", "VTODO",
               "VJOURNAL" or "VFREEBUSY" calendar components.

               Description: The value MUST be specified in the UTC time format.

               This property is also useful to protocols such as [IMIP] that have
               inherent latency issues with the delivery of content. This property
               will assist in the proper sequencing of messages containing ICalendar
               objects.

               This property is different than the "CREATED" and "LAST-MODIFIED"
               properties. These two properties are used to specify when the
               particular calendar data in the calendar store was created and last
               modified. This is different than when the ICalendar object
               representation of the calendar service information was created or
               last modified.

               Format Definition: The property is defined by the following notation:

                 dtstamp    = "DTSTAMP" stmparam ":" date-time CRLF

                 stmparam   = *(";" xparam)

               Example:

                 DTSTAMP:19971210T080000Z

             */
        	if (icalEventParser)
        		iCalEvent.setDateStamp(convertIcalDate(extractAttribute(iCalLine, "DTSTAMP")));
        }
        else if (iCalLine.startsWith("LAST-MODIFIED") )
        {
             /*
            4.8.7.3 Last Modified

               Property Name: LAST-MODIFIED

               Purpose: The property specifies the date and time that the
               information associated with the calendar component was last revised
               in the calendar store.

                    Note: This is analogous to the modification date and time for a
                    file in the file system.

               Value Type: DATE-TIME

               Property Parameters: Non-standard property parameters can be
               specified on this property.

               Conformance: This property can be specified in the "EVENT", "VTODO",
               "VJOURNAL" or "VTIMEZONE" calendar components.

               Description: The property value MUST be specified in the UTC time
               format.

               Format Definition: The property is defined by the following notation:

                 last-mod   = "LAST-MODIFIED" lstparam ":" date-time CRLF

                 lstparam   = *(";" xparam)

               Example: The following is are examples of this property:

                 LAST-MODIFIED:19960817T133000Z

             */
        	if (icalEventParser)
        		iCalEvent.setLastModified(convertIcalDate(extractAttribute(iCalLine, "LAST-MODIFIED")));
        }
        else if (iCalLine.startsWith("SEQUENCE") )
        {
             /*
            4.8.7.4 Sequence Number

               Property Name: SEQUENCE

               Purpose: This property defines the revision sequence number of the
               calendar component within a sequence of revisions.

               Value Type: integer

               Property Parameters: Non-standard property parameters can be
               specified on this property.

               Conformance: The property can be specified in "VEVENT", "VTODO" or
               "VJOURNAL" calendar component.

               Description: When a calendar component is created, its sequence
               number is zero (US-ASCII decimal 48). It is monotonically incremented
               by the "Organizer's" CUA each time the "Organizer" makes a
               significant revision to the calendar component. When the "Organizer"
               makes changes to one of the following properties, the sequence number
               MUST be incremented:

                 .  "DTSTART"

                 .  "DTEND"

                 .  "DUE"

                 .  "RDATE"

                 .  "RRULE"

                 .  "EXDATE"

                 .  "EXRULE"

                 .  "STATUS"

               In addition, changes made by the "Organizer" to other properties can
               also force the sequence number to be incremented. The "Organizer" CUA
               MUST increment the sequence number when ever it makes changes to
               properties in the calendar component that the "Organizer" deems will
               jeopardize the validity of the participation status of the
               "Attendees". For example, changing the location of a meeting from one
               locale to another distant locale could effectively impact the
               participation status of the "Attendees".

               The "Organizer" includes this property in an ICalendar object that it
               sends to an "Attendee" to specify the current version of the calendar
               component.

               The "Attendee" includes this property in an ICalendar object that it
               sends to the "Organizer" to specify the version of the calendar
               component that the "Attendee" is referring to.

               A change to the sequence number is not the mechanism that an
               "Organizer" uses to request a response from the "Attendees". The
               "RSVP" parameter on the "ATTENDEE" property is used by the
               "Organizer" to indicate that a response from the "Attendees" is
               requested.

               Format Definition: This property is defined by the following
               notation:

                 seq = "SEQUENCE" seqparam ":" integer CRLF
                 ; Default is "0"

                 seqparam   = *(";" xparam)

               Example: The following is an example of this property for a calendar
               component that was just created by the "Organizer".

                 SEQUENCE:0

               The following is an example of this property for a calendar component
               that has been revised two different times by the "Organizer".

                 SEQUENCE:2

             */
            if (icalEventParser)
            {
            	try
				{
            		iCalEvent.setSequence(Integer.parseInt((extractAttribute(iCalLine, "SEQUENCE"))));
				}
            	catch (Exception e)
				{
            		logger.severe("Parse Integer error on data :"+extractAttribute(iCalLine, "SEQUENCE")
            				+ "Exception is : "+e);
            		e.printStackTrace(System.err);
				}
            }
        }
        else if (iCalLine.startsWith("X-") )
        {
             /*
            4.8.8 Miscellaneous Component Properties

               The following properties specify information about a number of
               miscellaneous features of calendar components.

            4.8.8.1 Non-standard Properties

               Property Name: Any property name with a "X-" prefix

               Purpose: This class of property provides a framework for defining
               non-standard properties.

               Value Type: TEXT

               Property Parameters: Non-standard and language property parameters
               can be specified on this property.

               Conformance: This property can be specified in any calendar
               component.

               Description: The MIME Calendaring and Scheduling Content Type
               provides a "standard mechanism for doing non-standard things". This
               extension support is provided for implementers to "push the envelope"
               on the existing version of the memo. Extension properties are
               specified by property and/or property parameter names that have the
               prefix text of "X-" (the two character sequence: LATIN CAPITAL LETTER
               X character followed by the HYPEN-MINUS character). It is recommended
               that vendors concatenate onto this sentinel another short prefix text
               to identify the vendor. This will facilitate readability of the
               extensions and minimize possible collision of names between different
               vendors. User agents that support this content type are expected to
               be able to parse the extension properties and property parameters but
               can ignore them.

               At present, there is no registration authority for names of extension
               properties and property parameters. The data type for this property
               is TEXT. Optionally, the data type can be any of the other valid data
               types.

               Format Definition: The property is defined by the following notation:

                 x-prop     = x-name *(";" xparam) [";" languageparam] ":" text CRLF
                    ; Lines longer than 75 octets should be folded

               Example: The following might be the ABC vendor's extension for an
               audio-clip form of subject property:

                 X-ABC-MMSUBJ;X-ABC-MMSUBJTYPE=wave:http://load.noise.org/mysubj.wav

             */
        }
        else if (iCalLine.startsWith("REQUEST-STATUS") )
        {
             /*
            4.8.8.2 Request Status

               Property Name: REQUEST-STATUS

               Purpose: This property defines the status code returned for a
               scheduling request.

               Value Type: TEXT

               Property Parameters: Non-standard and language property parameters
               can be specified on this property.

               Conformance: The property can be specified in "VEVENT", "VTODO",
               "VJOURNAL" or "VFREEBUSY" calendar component.

               Description: This property is used to return status code information
               related to the processing of an associated ICalendar object. The data
               type for this property is TEXT.

               The value consists of a short return status component, a longer
               return status description component, and optionally a status-specific
               data component. The components of the value are separated by the
               SEMICOLON character (US-ASCII decimal 59).

               The short return status is a PERIOD character (US-ASCII decimal 46)
               separated 3-tuple of integers. For example, "3.1.1". The successive
               levels of integers provide for a successive level of status code
               granularity.

               The following are initial classes for the return status code.
               Individual ICalendar object methods will define specific return
               status codes for these classes. In addition, other classes for the
               return status code may be defined using the registration process
               defined later in this memo.

                 |==============+===============================================|
                 | Short Return | Longer Return Status Description              |
                 | Status Code  |                                               |
                 |==============+===============================================|
                 |    1.xx      | Preliminary success. This class of status     |
                 |              | of status code indicates that the request has |
                 |              | request has been initially processed but that |
                 |              | completion is pending.                        |
                 |==============+===============================================|
                 |    2.xx      | Successful. This class of status code         |
                 |              | indicates that the request was completed      |
                 |              | successfuly. However, the exact status code   |
                 |              | can indicate that a fallback has been taken.  |
                 |==============+===============================================|
                 |    3.xx      | Client Error. This class of status code       |
                 |              | indicates that the request was not successful.|
                 |              | The error is the result of either a syntax or |
                 |              | a semantic error in the client formatted      |
                 |              | request. Request should not be retried until  |
                 |              | the condition in the request is corrected.    |
                 |==============+===============================================|
                 |    4.xx      | Scheduling Error. This class of status code   |
                 |              | indicates that the request was not successful.|
                 |              | Some sort of error occurred within the        |
                 |              | calendaring and scheduling service, not       |
                 |              | directly related to the request itself.       |
                 |==============+===============================================|

               Format Definition: The property is defined by the following notation:

                 rstatus    = "REQUEST-STATUS" rstatparam ":"
                              statcode ";" statdesc [";" extdata]

                 rstatparam = *(

                            ; the following is optional,
                            ; but MUST NOT occur more than once

                            (";" languageparm) /

                            ; the following is optional,
                            ; and MAY occur more than once

                            (";" xparam)

                            )

                 statcode   = 1*DIGIT *("." 1*DIGIT)
                 ;Hierarchical, numeric return status code

                 statdesc   = text
                 ;Textual status description

                 extdata    = text
                 ;Textual exception data. For example, the offending property
                 ;name and value or complete property line.

               Example: The following are some possible examples of this property.
               The COMMA and SEMICOLON separator characters in the property value
               are BACKSLASH character escaped because they appear in a  text value.

                 REQUEST-STATUS:2.0;Success

                 REQUEST-STATUS:3.1;Invalid property value;DTSTART:96-Apr-01

                 REQUEST-STATUS:2.8; Success\, repeating event ignored. Scheduled
                  as a single event.;RRULE:FREQ=WEEKLY\;INTERVAL=2

                 REQUEST-STATUS:4.1;Event conflict. Date/time is busy.

                 REQUEST-STATUS:3.7;Invalid calendar user;ATTENDEE:
                  MAILTO:jsmith@host.com

             */
        	if (icalEventParser)
            {
       	 		iCalEvent.setRequestStatus(extractAttribute(iCalLine, "REQUEST-STATUS"));
            }
        }
        else
        {
        	logger.fine("Line not parsed (probably correct but check):"+iCalLine);
        }
    }

    public Date convertIcalDate (String iCalString)
    {
        /*
         * DTSTART:19970714T133000            ;Local time
         * DTSTART:19970714T173000Z           ;UTC time
         * DTSTART;TZID=US-Eastern:19970714T133000    ;Local time and time
         *               ; zone reference
         *DTSTART;VALUE=DATE;
           TZID=/softwarestudio.org/Olson_20011030_5/Europe/Amsterdam:20030902
         *
         * Point of all this, return date as local.
        */
//logger.fine(iCalEvent.getSummary());
//logger.fine(iCalString);

        String iCalFormat   = null;
        int    startPoint   = 0;
        String tzName       = null;

        TimeZone offsetZone = java.util.TimeZone.getDefault();

        if (iCalString.startsWith("TZID=")){
            // Time for a specific Time Zone
            startPoint = iCalString.indexOf(":") + 1;
            // Get timezone.
            offsetZone = getTimeZoneFromDate(iCalString, startPoint);
/*
            if (iCalString.indexOf("TZID=/softwarestudio.org/Olson_20011030_5/") != -1)
            {
                tzName = iCalString.substring("TZID=/softwarestudio.org/Olson_20011030_5/".length(),startPoint -1);
            }
            else
            {
                tzName = iCalString.substring("TZID=".length(),startPoint -1);
            }
            offsetZone = TimeZone.getTimeZone(tzName);
 **/
            //logger.fine("TZID St Pt = " + startPoint + " String " + iCalString);
            iCalString = iCalString.substring(startPoint ,startPoint  + 8) + iCalString.substring(startPoint  + 9, startPoint + 15);
            iCalFormat = "yyyyMMddHHmmss";
            // Need to do the offset thing to get in local date/time.
            // Currently expect that all time is local.
        }
        else if (iCalString.startsWith("VALUE=DATE:"))
        {
            startPoint = iCalString.indexOf(":") + 1;
            iCalString = iCalString.substring(startPoint ,startPoint  + 8);
            // + "000000" ;
            iCalFormat = "yyyyMMdd";
        }
        else if (iCalString.startsWith("VALUE=DATE;"))
        {
            // decipher dates of type: VALUE=DATE;TZID=/softwarestudio.org/Olson_20011030_5/Australia/Sydney:20020918
            startPoint = iCalString.indexOf(";") + 1;
            iCalString = iCalString.substring(startPoint);
            startPoint = iCalString.indexOf(":") + 1;
            // Get timezone.
            //logger.fine("TZID 2 St Pt = " + startPoint + " String " + iCalString);
            offsetZone = getTimeZoneFromDate(iCalString,startPoint);
            //iCalString = iCalString.substring(startPoint ,startPoint  + 8) + iCalString.substring(startPoint  + 10, startPoint + 16);
            iCalString = iCalString.substring(startPoint);
            iCalFormat = "yyyyMMdd";
        }
        else if (iCalString.startsWith("VALUE=DATE-TIME;"))
        {
            // decipher dates of type: VALUE=DATE-TIME;TZID=/softwarestudio.org/Olson_20011030_5/Australia/Sydney:20020918T120000
            startPoint = iCalString.indexOf(";") + 1;
            iCalString = iCalString.substring(startPoint);
            startPoint = iCalString.indexOf(":") + 1;
            // Get timezone.
            //logger.fine("TZID 2 St Pt = " + startPoint + " String " + iCalString);
            offsetZone = getTimeZoneFromDate(iCalString,startPoint);
            //iCalString = iCalString.substring(startPoint ,startPoint  + 8) + iCalString.substring(startPoint  + 10, startPoint + 16);
            iCalString = iCalString.substring(startPoint);
            iCalFormat = "yyyyMMdd'T'HHmmss";
        }
        else if (iCalString.startsWith("VALUE=DATE-TIME:"))
        {
            // decipher dates of type: VALUE=DATE-TIME:20020918T120000
            startPoint = iCalString.indexOf(":") + 1;
            offsetZone = gmt;
            iCalString = iCalString.substring(startPoint);
            iCalFormat = "yyyyMMdd'T'HHmmss";
        }
        else if (iCalString.endsWith("Z"))
        {
            // UTC Time
            offsetZone = gmt;
            iCalString = iCalString.substring(0,8) + iCalString.substring(9,15);
            iCalFormat = "yyyyMMddHHmmss";
        }
        else if (iCalString.substring(8,9).equalsIgnoreCase("T"))
        {
            // Local Time
            iCalString = iCalString.substring(0,8) + iCalString.substring(9);
            iCalFormat = "yyyyMMddHHmmss";
        }
        else
        {
            logger.fine("Date Type not known:(" + iCalString + ")");
            return null;
        }

        Date date = null;
        try
        {
            SimpleDateFormat formatter = new SimpleDateFormat(iCalFormat);
            formatter.setTimeZone(offsetZone);
            //logger.fine("Parsing:" + iCalFormat + "with:" + iCalString );
            date = (Date)formatter.parse(iCalString);
        }
        catch (Exception e)
        {
            System.err.print("Parse error - " + e);
        }
        return date;
    }

    public TimeZone getTimeZoneFromDate(String iCalString, int startPoint)
    {
        TimeZone tz = null;
        try {
            String tzName = null;
            if (iCalString.indexOf("TZID=/softwarestudio.org/Olson_20011030_5/") != -1)
            {
                tzName = iCalString.substring("TZID=/softwarestudio.org/Olson_20011030_5/".length(),startPoint -1);
            }
            else
            {
                tzName = iCalString.substring("TZID=".length(),startPoint -1);
            }
            tz = TimeZone.getTimeZone(tzName);
        }
        catch (Exception e)
        {
            System.err.print("iCal Line - " + lineCtr + "Parse error - " + e);
        }
        return tz;
    }
    public String extractAttribute(String attribLine, String attribName)
    {
        String attr = "";
        /*
        if (attribName.equals("TRANSP"))
        {
            logger.fine (attribLine
                        + attribLine.length()
                                );
        }
         */
        // Returns Attribute Value.. Add 1 for the colon :
        try {
            attr = attribLine.substring(attribName.length() + 1);
        }
        catch (Exception e)
        {
            logger.fine ("iCal Line - " + lineCtr + "Parse error when extracting Attribute - "
                            + attribName + " from Attribute Line - " +  attribLine
                            + "Parse error is: " + e);
        }
        // Fix bugs where escaped characters were not being unescaped
		// Convert "\n" to a LF and "\r" to a CR
		attr = attr.replaceAll("\\\\n","\n");
		attr = attr.replaceAll("\\\\r","\r");
		attr = attr.replaceAll("\\\\,",",");
		attr = attr.replaceAll("\\\\\"","\"");
		attr = attr.replaceAll("\\\\;",";");

        return attr;
    }

    public void parseOrganizer(ICalendarVEvent iCalEvent, String organizer)
    {
    	String iCalOrganizer =  extractAttribute(organizer,"ORGANIZER");
    	iCalEvent.setOrganizer(iCalOrganizer);

        int startPoint = -1;
        int ii = 0;
        boolean mailto = false;
        while (organizer != null && ii < 10) {
            ii++;
            String attr = null;
            startPoint = organizer.indexOf(":");
            if (startPoint != -1) {
                attr = organizer.substring(0,startPoint);
                organizer = organizer.substring(startPoint + 1);
            } else {
                attr = organizer;
                organizer = null;
            }
            if (attr.toUpperCase().startsWith("CN=")) {
                attr = attr.substring(3);
                if (attr.startsWith("\"")) {
                    attr = attr.substring(1);
                }
                if (attr.endsWith("\"")) {
                    attr = attr.substring(0,attr.length()-1);
                }
                iCalEvent.setOrganizer(attr);
            } else if (attr.toUpperCase().startsWith("MAILTO")) {
                mailto = true;
            } else if (mailto) {
                mailto = false;
                iCalEvent.setOrganizerEmail(attr);
            }
        }
    }
    public void parseExDate(ICalendarVEvent iCalEvent, String exDate)
    {
        int startPoint = -1;
        int ii = 0;
        boolean mailto = false;
        while (exDate != null && ii < 10) {
            ii++;
            String attr = null;
            startPoint = exDate.indexOf(":");
            if (startPoint != -1) {
                attr = exDate.substring(0,startPoint);
                exDate = exDate.substring(startPoint + 1);
            } else {
                attr = exDate;
                exDate = null;
            }
            if (!attr.toUpperCase().startsWith("TZID=")) {
                StringTokenizer st = new StringTokenizer(attr,",");
                while (st.hasMoreTokens()) {
                    String exdate = st.nextToken();
                    logger.fine("iCalendarParser.parseExDate() add " + exdate);
                    iCalEvent.exDateCollection.add(exdate);
                }
            }
        }
    }

    /*
     * Stuff left to parse..
     * @author sfg
     *
     * TODO To change the template for this generated type comment go to
     * Window - Preferences - Java - Code Style - Code Templates
     *
     *
     *
     		Parameter Name: ALTREP
           Purpose: To specify an alternate text representation for the property
           value.    Format Definition: The property parameter is defined by the following
           notation:
           STUART: ALTREP is used within another parameter..
           Look at the bits between the = double quotes.

           Parameter Name CN
           ecify the common name to be associated with the
        // calendar user specified by the property.
        // CN=parameter value
    	//ical.setCommonName(extractAttribute(iCalLine,ICalendarParser.CN));

    }
    else if (iCalLine.startsWith(ICalendarParser.CUTYPE) )
    {

        Parameter Name: CUTYPE    Purpose: To specify the type of calendar user specified by the
       property.    Format Definition: The property parameter is defined by the following
       notation:      cutypeparam        = "CUTYPE" "="
                             ("INDIVIDUAL"          ; An individual
                            / "GROUP"               ; A group of individuals
                            / "RESOURCE"            ; A physical resource
                            / "ROOM"                ; A room resource
                            / "UNKNOWN"             ; Otherwise not known
                            / x-name                ; Experimental type
                            / iana-token)           ; Other IANA registered
                                                    ; type
         ; Default is INDIVIDUAL
           Description: This parameter can be specified on properties with a
           CAL-ADDRESS value type. The parameter identifies the type of calendar
           user specified by the property. If not specified on a property that
           allows this parameter, the default is INDIVIDUAL.

    	//ical.setCuType(extractAttribute(iCalLine,ICalendarParser.CUTYPE));
    }
    else if (iCalLine.startsWith("DELEGATED-FROM") )
    {

       Parameter Name: DELEGATED-FROM
        Purpose: To specify the calendar users that have delegated their
        participation to the calendar user specified by the property.
        Format Definition: The property parameter is defined by the following
        notation:
        delfromparam       = "DELEGATED-FROM" "=" DQUOTE cal-address DQUOTE
                      *("," DQUOTE cal-address DQUOTE)
        Description: This parameter can be specified on properties with a
        CAL-ADDRESS value type. This parameter can be specified on a property
        that has a value type of calendar address. This parameter specifies
        those calendar uses that have delegated their participation in a
        group scheduled event or to-do to the calendar user specified by the
        property. The value MUST be a MAILTO URI as defined in [RFC 1738].
        The individual calendar address parameter values MUST each be
        specified in a quoted-string.
        Example:      ATTENDEE;DELEGATED-FROM="MAILTO:jsmith@host.com":MAILTO:
         jdoe@host.com

    	//ical.setDelegatedFrom(extractAttribute(iCalLine,ICalendarParser.DELETEGATEDFROM));
    }
    else if (iCalLine.startsWith("DELEGATED-TO") )
    {

        Parameter Name: DELEGATED-TO
        Purpose: To specify the calendar users to whom the calendar user
                specified by the property has delegated participation.
        Format Definition: The property parameter is defined by the following
        notation:      deltoparam = "DELEGATED-TO" "=" DQUOTE cal-address DQUOTE
                      *("," DQUOTE cal-address DQUOTE)
        Description: This parameter can be specified on properties with a
                    CAL-ADDRESS value type. This parameter specifies those calendar users
                    whom have been delegated participation in a group scheduled event or
                    to-do by the calendar user specified by the property. The value MUST
                    be a MAILTO URI as defined in [RFC 1738]. The individual calendar
                    address parameter values MUST each be specified in a quoted-string.
        Example:      ATTENDEE;DELEGATED-TO="MAILTO:jdoe@host.com","MAILTO:jqpublic@
                    host.com":MAILTO:jsmith@host.com
           	ical.setDelegatedTo(extractAttribute(iCalLine,ICalendarParser.DELEGATEDTO));
    }

            4.2.6 Directory Entry Reference
                    Parameter Name: DIR
                    Purpose: To specify reference to a directory entry associated with
                            the calendar user specified by the property.
                    Format Definition: The property parameter is defined by the following notation

                    dirparam   = "DIR" "=" DQUOTE uri DQUOTE
                    Description: This parameter can be specified on properties with a
                                CAL-ADDRESS value type. The parameter specifies a reference to the
                                directory entry associated with the calendar user specified by the
                                property. The parameter value is a URI. The individual URI parameter
                                values MUST each be specified in a quoted-string.
                    Example:      ORGANIZER;DIR="ldap://host.com:6666/o=eDABC%20Industries,c=3DUS??
                                  (cn=3DBJim%20Dolittle)":MAILTO:jimdo@host1.com



            4.2.7 Inline Encoding
            Parameter Name: ENCODING
            Purpose: To specify an alternate inline encoding for the property value.
            Format Definition: The property parameter is defined by the following
                notation:
            encodingparam      = "ENCODING" "="
                          ("8BIT" ; "8bit" text encoding is defined in [RFC 2045]
                                        / "BASE64"
                        ; "BASE64" binary encoding format is defined in [RFC 2045]
                                        / iana-token
                        ; Some other IANA registered ICalendar encoding type
                                        / x-name)
                        ; A non-standard, experimental encoding type
            Description: The property parameter identifies the inline encoding
                   used in a property value. The default encoding is "8BIT",
                   corresponding to a property value consisting of text. The "BASE64"
                   encoding type corresponds to a property value encoded using the
                   "BASE64" encoding defined in [RFC 2045].
            If the value type parameter is ";VALUE=BINARY", then the inline
                   encoding parameter MUST be specified with the value
                   ";ENCODING=BASE64".
            Example:      ATTACH;FMTYPE=IMAGE/JPEG;ENCODING=BASE64;VALUE=BINARY:MIICajC
                      CAdOgAwIBAgICBEUwDQYJKoZIhvcNAQEEBQAwdzELMAkGA1UEBhMCVVMxLDA
                      qBgNVBAoTI05ldHNjYXBlIENvbW11bmljYXRpb25zIENvcnBvcmF0aW9uMRw
                      <...remainder of "BASE64" encoded binary data...>


        }


            4.2.8 Format Type
            Parameter Name: FMTTYPE
            Purpose: To specify the content type of a referenced object.
            Format Definition: The property parameter is defined by the following
            notation:      fmttypeparam       = "FMTTYPE" "=" iana-token
                                        ; A IANA registered content type
                                     / x-name
                                        ; A non-standard content type
            Description: This parameter can be specified on properties that are
                           used to reference an object. The parameter specifies the content type
                           of the referenced object. For example, on the "ATTACH" property, a
                           FTP type URI value does not, by itself, necessarily convey the type
                           of content associated with the resource. The parameter value MUST be
                           the TEXT for either an IANA registered content type or a non-standard
                           content type.
            Example:       ATTACH;FMTTYPE=application/binary:ftp://domain.com/pub/docs/agenda.doc

            4.2.9 Free/Busy Time Type
            Parameter Name: FBTYPE
            Purpose: To specify the free or busy time type.
            Format Definition: The property parameter is defined by the following
            notation:      fbtypeparam        = "FBTYPE" "=" ("FREE" / "BUSY"
                        / "BUSY-UNAVAILABLE" / "BUSY-TENTATIVE"
                        / x-name
                    ; Some experimental ICalendar data type.
                        / iana-token)
            *
            Description: The parameter specifies the free or busy time type. The
               value FREE indicates that the time interval is free for scheduling.
               The value BUSY indicates that the time interval is busy because one
               or more events have been scheduled for that interval. The value
               BUSY-UNAVAILABLE indicates that the time interval is busy and that
               the interval can not be scheduled. The value BUSY-TENTATIVE indicates
               that the time interval is busy because one or more events have been
               tentatively scheduled for that interval. If not specified on a
               property that allows this parameter, the default is BUSY.
            Example: The following is an example of this parameter on a FREEBUSY property.
            FREEBUSY;FBTYPE=BUSY:19980415T133000Z/19980415T170000Z

        }
        else
                   if (iCalLine.startsWith("LANGUAGE") )
        {

           4.2.10 Language
           Parameter Name: LANGUAGE
           Purpose: To specify the language for text values in a property or property parameter.
           Format Definition: The property parameter is defined by the following
           notation:      languageparam =    "LANGUAGE" "=" language
                language = <Text identifying a language, as defined in [RFC 1766]>
           Description: This parameter can be specified on properties with a
           text value type. The parameter identifies the language of the text in
           the property or property parameter value. The value of the "language"
           property parameter is that defined in [RFC 1766].
           For transport in a MIME entity, the Content-Language header field can
           be used to set the default language for the entire body part.
           Otherwise, no default language is assumed.
            Example:      SUMMARY;LANGUAGE=us-EN:Company Holiday Party
                            LOCATION;LANGUAGE=en:Germany
                            LOCATION;LANGUAGE=no:Tyskland


        }

                                 if (iCalLine.startsWith("MEMBER") )
        {

            4.2.11  Group or List Membership
            Parameter Name: MEMBER
            Purpose: To specify the group or list membership of the calendar user
            specified by the property.
            Format Definition: The property parameter is defined by the following
            notation:      memberparam        = "MEMBER" "=" DQUOTE cal-address DQUOTE
                          *("," DQUOTE cal-address DQUOTE)
            Description: This parameter can be specified on properties with a
            CAL-ADDRESS value type. The parameter identifies the groups or list
            membership for the calendar user specified by the property. The
            parameter value either a single calendar address in a quoted-string
            or a COMMA character (US-ASCII decimal 44) list of calendar
            addresses, each in a quoted-string. The individual calendar address
            parameter values MUST each be specified in a quoted-string.
            Example:      ATTENDEE;MEMBER="MAILTO:ietf-calsch@imc.org":MAILTO:jsmith@host.com
            ATTENDEE;MEMBER="MAILTO:projectA@host.com","MAILTO:projectB@host.com":MAILTO:janedoe@host.com

        }
        else if (iCalLine.startsWith("PARTSTAT") )
        {

            4.2.12 Participation Status
            Parameter Name: PARTSTAT
            Purpose: To specify the participation status for the calendar user
            specified by the property.
            Format Definition: The property parameter is defined by the following
            notation:      partstatparam      = "PARTSTAT" "="
                         ("NEEDS-ACTION"        ; Event needs action
                        / "ACCEPTED"            ; Event accepted
                        / "DECLINED"            ; Event declined Dawson & Stenerson
                        / "TENTATIVE"           ; Event tentatively
                                                ; accepted
                        / "DELEGATED"           ; Event delegated
                        / x-name                ; Experimental status
                        / iana-token)           ; Other IANA registered
                                                ; status
             ; These are the participation statuses for a "VEVENT". Default is
             ; NEEDS-ACTION
            partstatparam      /= "PARTSTAT" "="
                         ("NEEDS-ACTION"        ; To-do needs action
                        / "ACCEPTED"            ; To-do accepted
                        / "DECLINED"            ; To-do declined
                        / "TENTATIVE"           ; To-do tentatively
                                                ; accepted
                        / "DELEGATED"           ; To-do delegated
                        / "COMPLETED"           ; To-do completed.
                                                ; COMPLETED property has
                                                ;date/time completed.
                        / "IN-PROCESS"          ; To-do in process of
                                                ; being completed
                        / x-name                ; Experimental status
                        / iana-token)           ; Other IANA registered
                                                ; status
             ; These are the participation statuses for a "VTODO". Default is
             ; NEEDS-ACTION      partstatparam      /= "PARTSTAT" "="
                         ("NEEDS-ACTION"        ; Journal needs action
                        / "ACCEPTED"            ; Journal accepted
                        / "DECLINED"            ; Journal declined
                        / x-name                ; Experimental status
                        / iana-token)           ; Other IANA registered
                                                ; status
             ; These are the participation statuses for a "VJOURNAL". Default is
             ; NEEDS-ACTION
                Description: This parameter can be specified on properties with a
               CAL-ADDRESS value type. The parameter identifies the participation
               status for the calendar user specified by the property value. The
               parameter values differ depending on whether they are associated with
               a group scheduled "VEVENT", "VTODO" or "VJOURNAL". The values MUST
               match one of the values allowed for the given calendar component. If
               not specified on a property that allows this parameter, the default
               value is NEEDS-ACTION.    Example:      ATTENDEE;PARTSTAT=DECLINED:MAILTO:jsmith@host.com

        }
        else

    	if (iCalLine.startsWith("RANGE") )
        {

            4.2.13  Recurrence Identifier Range
            Parameter Name: RANGE
            Purpose: To specify the effective range of recurrence instances from
            the instance specified by the recurrence identifier specified by the
            property.
            Format Definition: The property parameter is defined by the following
            notation:      rangeparam = "RANGE" "=" ("THISANDPRIOR"
                ; To specify all instances prior to the recurrence identifier
                            / "THISANDFUTURE")
                ; To specify the instance specified by the recurrence identifier
                ; and all subsequent recurrence instances
            Description: The parameter can be specified on a property that
            specifies a recurrence identifier. The parameter specifies the
            effective range of recurrence instances that is specified by the
            property. The effective range is from the recurrence identified
            specified by the property. If this parameter is not specified an
            allowed property, then the default range is the single instance
            specified by the recurrence identifier value of the property. The
            parameter value can be "THISANDPRIOR" to indicate a range defined by
            the recurrence identified value of the property and all prior
            instances. The parameter value can also be "THISANDFUTURE" to
            indicate a range defined by the recurrence identifier and all
            subsequent instances.

            Example:      RECURRENCE-ID;RANGE=THISANDPRIOR:19980401T133000Z



    		// TODO Should implement this
        }
        else if (iCalLine.startsWith("RELATED") )
        {

            4.2.14 Alarm Trigger Relationship
            Parameter Name: RELATED
            Purpose: To specify the relationship of the alarm trigger with
            respect to the start or end of the calendar component.
            Format Definition: The property parameter is defined by the following
            notation:      trigrelparam       = "RELATED" "="
                             ("START"       ; Trigger off of start
                            / "END")        ; Trigger off of end Dawson & Stenerson
            Description: The parameter can be specified on properties that
               specify an alarm trigger with a DURATION value type. The parameter
               specifies whether the alarm will trigger relative to the start or end
               of the calendar component. The parameter value START will set the
               alarm to trigger off the start of the calendar component; the
               parameter value END will set the alarm to trigger off the end of the
               calendar component. If the parameter is not specified on an allowable
               property, then the default is START.

            Example:      TRIGGER;RELATED=END:PT5M

        }
        else if (iCalLine.startsWith("RELTYPE") )
        {

            4.2.15 Relationship Type
            Parameter Name: RELTYPE
            Purpose: To specify the type of hierarchical relationship associated
            with the calendar component specified by the property.
            Format Definition: The property parameter is defined by the following
            notation:      reltypeparam       = "RELTYPE" "="
                         ("PARENT"      ; Parent relationship. Default.
                        / "CHILD"       ; Child relationship
                        / "SIBLING      ; Sibling relationship
                        / iana-token    ; Some other IANA registered
                                        ; ICalendar relationship type
                        / x-name)       ; A non-standard, experimental
                                        ; relationship type
            Description: This parameter can be specified on a property that
               references another related calendar. The parameter specifies the
               hierarchical relationship type of the calendar component referenced
               by the property. The parameter value can be PARENT, to indicate that
               the referenced calendar component is a superior of calendar
               component; CHILD to indicate that the referenced calendar component
               is a subordinate of the calendar component; SIBLING to indicate that
               the referenced calendar component is a peer of the calendar
               component. If this parameter is not specified on an allowable
               property, the default relationship type is PARENT.
            Example:      RELATED-TO;RELTYPE=SIBLING:<19960401-080045-4000F192713@host.com>

        }
        else if (iCalLine.startsWith("ROLE") )
        {

            4.2.16 Participation Role
            Parameter Name: ROLE
            Purpose: To specify the participation role for the calendar user
            specified by the property.
            Format Definition: The property parameter is defined by the following
            notation:      roleparam  = "ROLE" "="
                 ("CHAIR"               ; Indicates chair of the
                                        ; calendar entity
                / "REQ-PARTICIPANT"     ; Indicates a participant whose
                                        ; participation is required
                / "OPT-PARTICIPANT"     ; Indicates a participant whose
                                        ; participation is optional
                / "NON-PARTICIPANT"     ; Indicates a participant who is
                                        ; copied for information
                                        ; purposes only
                / x-name                ; Experimental role
                / iana-token)           ; Other IANA role
            ; Default is REQ-PARTICIPANT
            Description: This parameter can be specified on properties with a
            CAL-ADDRESS value type. The parameter specifies the participation
            role for the calendar user specified by the property in the group
            schedule calendar component. If not specified on a property that
            allows this parameter, the default value is REQ-PARTICIPANT.
            Example:      ATTENDEE;ROLE=CHAIR:MAILTO:mrbig@host.com

        }
        else if (iCalLine.startsWith("RSVP") )
        {

            4.2.17  RSVP Expectation
            Parameter Name: RSVP
            Purpose: To specify whether there is an expectation of a favor of a
            reply from the calendar user specified by the property value.
            Format Definition: The property parameter is defined by the following
            notation:      rsvpparam = "RSVP" "=" ("TRUE" / "FALSE")
                ; Default is FALSE
            Description: This parameter can be specified on properties with a
               CAL-ADDRESS value type. The parameter identifies the expectation of a
               reply from the calendar user specified by the property value. This
               parameter is used by the "Organizer" to request a participation
               status reply from an "Attendee" of a group scheduled event or to-do.
               If not specified on a property that allows this parameter, the
                default value is FALSE.
            Example:      ATTENDEE;RSVP=TRUE:MAILTO:jsmith@host.com


        }
        else if (iCalLine.startsWith("SENT-BY") )
        {

            4.2.18  Sent By
            Parameter Name: SENT-BY
            Purpose: To specify the calendar user that is acting on behalf of the
            calendar user specified by the property.
            Format Definition: The property parameter is defined by the following
            notation:      sentbyparam        = "SENT-BY" "=" DQUOTE cal-address DQUOTE
            Description: This parameter can be specified on properties with a
           CAL-ADDRESS value type. The parameter specifies the calendar user
           that is acting on behalf of the calendar user specified by the
           property. The parameter value MUST be a MAILTO URI as defined in [RFC
           1738]. The individual calendar address parameter values MUST each be
           specified in a quoted-string.
            Example:      ORGANIZER;SENT-BY:"MAILTO:sray@host.com":MAILTO:jsmith@host.com

        }
        else if (iCalLine.startsWith("VALUE") )
        {

            4.2.20 Value Data Types
            Parameter Name: VALUE
            Purpose: To explicitly specify the data type format for a property value.
            Format Definition: The "VALUE" property parameter is defined by the following
            notation:      valuetypeparam = "VALUE" "=" valuetype      valuetype  = ("BINARY"
                / "BOOLEAN"
                / "CAL-ADDRESS"
                / "DATE"
                / "DATE-TIME"
                / "DURATION"
                / "FLOAT"
                / "INTEGER"
                / "PERIOD"
                / "RECUR"
                / "TEXT"
                / "TIME"
                / "URI"
                / "UTC-OFFSET"
                / x-name
                ; Some experimental ICalendar data type.
                / iana-token)
                ; Some other IANA registered ICalendar data type.
            Description: The parameter specifies the data type and format of the
               property value. The property values MUST be of a single value type.
               For example, a "RDATE" property cannot have a combination of DATE-
               TIME and TIME value types.    If the property's value is the default value type, then this
               parameter need not be specified. However, if the property's default
               value type is overridden by some other allowable value type, then
               this parameter MUST be specified.

        }


        else

else if (iCalLine.startsWith("METHOD") )
        {

            4.7.2 Method

               Property Name: METHOD

               Purpose: This property defines the ICalendar object method associated
               with the calendar object.

               Value Type: TEXT

               Property Parameters: Non-standard property parameters can be
               specified on this property.

               Conformance: The property can be specified in an ICalendar object.

               Description: When used in a MIME message entity, the value of this
               property MUST be the same as the Content-Type "method" parameter
               value. This property can only appear once within the ICalendar
               object. If either the "METHOD" property or the Content-Type "method"
               parameter is specified, then the other MUST also be specified.

               No methods are defined by this specification. This is the subject of
               other specifications, such as the ICalendar Transport-independent

               Interoperability Protocol (iTIP) defined by [ITIP].

               If this property is not present in the ICalendar object, then a
               scheduling transaction MUST NOT be assumed. In such cases, the
               ICalendar object is merely being used to transport a snapshot of some
               calendar information; without the intention of conveying a scheduling
               semantic.

               Format Definition: The property is defined by the following notation:

                 method     = "METHOD" metparam ":" metvalue CRLF

                 metparam   = *(";" xparam)

                 metvalue   = iana-token

               Example: The following is a hypothetical example of this property to
               convey that the ICalendar object is a request for a meeting:

                 METHOD:REQUEST

        }

       else if (iCalLine.startsWith("FREEBUSY") )
        {

             4.8.2.6 Free/Busy Time

               Property Name: FREEBUSY

               Purpose: The property defines one or more free or busy time
               intervals.

               Value Type: PERIOD. The date and time values MUST be in an UTC time
               format.

               Property Parameters: Non-standard or free/busy time type property
               parameters can be specified on this property.

               Conformance: The property can be specified in a "VFREEBUSY" calendar
               component.

               Property Parameter: "FBTYPE" and non-standard parameters can be
               specified on this property.

               Description: These time periods can be specified as either a start
               and end date-time or a start date-time and duration. The date and
               time MUST be a UTC time format.

               "FREEBUSY" properties within the "VFREEBUSY" calendar component
               SHOULD be sorted in ascending order, based on start time and then end
               time, with the earliest periods first.

               The "FREEBUSY" property can specify more than one value, separated by
               the COMMA character (US-ASCII decimal 44). In such cases, the
               "FREEBUSY" property values SHOULD all be of the same "FBTYPE"
               property parameter type (e.g., all values of a particular "FBTYPE"
               listed together in a single property).

               Format Definition: The property is defined by the following notation:

                 freebusy   = "FREEBUSY" fbparam ":" fbvalue
                              CRLF

                 fbparam    = *(
                            ; the following is optional,
                            ; but MUST NOT occur more than once

                            (";" fbtypeparam) /

                            ; the following is optional,
                            ; and MAY occur more than once

                            (";" xparam)

                            )

                 fbvalue    = period *["," period]
                 ;Time value MUST be in the UTC time format.

               Example: The following are some examples of this property:

                 FREEBUSY;FBTYPE=BUSY-UNAVAILABLE:19970308T160000Z/PT8H30M

                 FREEBUSY;FBTYPE=FREE:19970308T160000Z/PT3H,19970308T200000Z/PT1H

                 FREEBUSY;FBTYPE=FREE:19970308T160000Z/PT3H,19970308T200000Z/PT1H,
                  19970308T230000Z/19970309T000000Z


        }

        else if (iCalLine.startsWith("EXRULE") )
        {

            4.8.5.2 Exception Rule

               Property Name: EXRULE

               Purpose: This property defines a rule or repeating pattern for an
               exception to a recurrence set.

               Value Type: RECUR

               Property Parameters: Non-standard property parameters can be
               specified on this property.

               Conformance: This property can be specified in "VEVENT", "VTODO" or
               "VJOURNAL" calendar components.

               Description: The exception rule, if specified, is used in computing
               the recurrence set. The recurrence set is the complete set of
               recurrence instances for a calendar component. The recurrence set is
               generated by considering the initial "DTSTART" property along with
               the "RRULE", "RDATE", "EXDATE" and "EXRULE" properties contained
               within the ICalendar object. The "DTSTART" defines the first instance
               in the recurrence set. Multiple instances of the "RRULE" and "EXRULE"
               properties can also be specified to define more sophisticated
               recurrence sets. The final recurrence set is generated by gathering
               all of the start date-times generated by any of the specified "RRULE"
               and "RDATE" properties, and excluding any start date and times which
               fall within the union of start date and times generated by any
               specified "EXRULE" and "EXDATE" properties. This implies that start
               date and times within exclusion related properties (i.e., "EXDATE"
               and "EXRULE") take precedence over those specified by inclusion
               properties (i.e., "RDATE" and "RRULE"). Where duplicate instances are
               generated by the "RRULE" and "RDATE" properties, only one recurrence
               is considered. Duplicate instances are ignored.

               The "EXRULE" property can be used to exclude the value specified in
               "DTSTART". However, in such cases the original "DTSTART" date MUST
               still be maintained by the calendaring and scheduling system because
               the original "DTSTART" value has inherent usage dependencies by other
               properties such as the "RECURRENCE-ID".

               Format Definition: The property is defined by the following notation:

                 exrule     = "EXRULE" exrparam ":" recur CRLF

                 exrparam   = *(";" xparam)

               Example: The following are examples of this property. Except every
               other week, on Tuesday and Thursday for 4 occurrences:

                 EXRULE:FREQ=WEEKLY;COUNT=4;INTERVAL=2;BYDAY=TU,TH

               Except daily for 10 occurrences:

                 EXRULE:FREQ=DAILY;COUNT=10

               Except yearly in June and July for 8 occurrences:

                 EXRULE:FREQ=YEARLY;COUNT=8;BYMONTH=6,7


        }
        else if (iCalLine.startsWith("RDATE") )
        {

            4.8.5.3 Recurrence Date/Times

               Property Name: RDATE

               Purpose: This property defines the list of date/times for a
               recurrence set.

               Value Type: The default value type for this property is DATE-TIME.
               The value type can be set to DATE or PERIOD.

               Property Parameters: Non-standard, value data type and time zone
               identifier property parameters can be specified on this property.

               Conformance: The property can be specified in "VEVENT", "VTODO",
               "VJOURNAL" or "VTIMEZONE" calendar components.

               Description: This property can appear along with the "RRULE" property
               to define an aggregate set of repeating occurrences. When they both
               appear in an ICalendar object, the recurring events are defined by
               the union of occurrences defined by both the "RDATE" and "RRULE".

               The recurrence dates, if specified, are used in computing the
               recurrence set. The recurrence set is the complete set of recurrence
               instances for a calendar component. The recurrence set is generated
               by considering the initial "DTSTART" property along with the "RRULE",
               "RDATE", "EXDATE" and "EXRULE" properties contained within the
               ICalendar object. The "DTSTART" property defines the first instance
               in the recurrence set. Multiple instances of the "RRULE" and "EXRULE"
               properties can also be specified to define more sophisticated
               recurrence sets. The final recurrence set is generated by gathering
               all of the start date/times generated by any of the specified "RRULE"
               and "RDATE" properties, and excluding any start date/times which fall
               within the union of start date/times generated by any specified
               "EXRULE" and "EXDATE" properties. This implies that start date/times
               within exclusion related properties (i.e., "EXDATE" and "EXRULE")
               take precedence over those specified by inclusion properties (i.e.,
               "RDATE" and "RRULE"). Where duplicate instances are generated by the
               "RRULE" and "RDATE" properties, only one recurrence is considered.
               Duplicate instances are ignored.

               Format Definition: The property is defined by the following notation:

                 rdate      = "RDATE" rdtparam ":" rdtval *("," rdtval) CRLF

                 rdtparam   = *(

                            ; the following are optional,
                            ; but MUST NOT occur more than once

                            (";" "VALUE" "=" ("DATE-TIME" / "DATE" / "PERIOD")) /
                            (";" tzidparam) /

                            ; the following is optional,
                            ; and MAY occur more than once

                            (";" xparam)

                            )

                 rdtval     = date-time / date / period
                 ;Value MUST match value type

               Example: The following are examples of this property:

                 RDATE:19970714T123000Z

                 RDATE;TZID=US-EASTERN:19970714T083000

                 RDATE;VALUE=PERIOD:19960403T020000Z/19960403T040000Z,
                  19960404T010000Z/PT3H

                 RDATE;VALUE=DATE:19970101,19970120,19970217,19970421
                  19970526,19970704,19970901,19971014,19971128,19971129,19971225


        }
                      else if (iCalLine.startsWith("ACTION") )
        {

            4.8.6 Alarm Component Properties

               The following properties specify alarm information in calendar
               components.

            4.8.6.1 Action

               Property Name: ACTION

               Purpose: This property defines the action to be invoked when an alarm
               is triggered.

               Value Type: TEXT

               Property Parameters: Non-standard property parameters can be
               specified on this property.

               Conformance: This property MUST be specified once in a "VALARM"
               calendar component.

               Description: Each "VALARM" calendar component has a particular type
               of action associated with it. This property specifies the type of
               action

               Format Definition: The property is defined by the following notation:

                 action     = "ACTION" actionparam ":" actionvalue CRLF

                 actionparam        = *(";" xparam)

                 actionvalue        = "AUDIO" / "DISPLAY" / "EMAIL" / "PROCEDURE"
                                    / iana-token / x-name

               Example: The following are examples of this property in a "VALARM"
               calendar component:

                 ACTION:AUDIO

                 ACTION:DISPLAY

                 ACTION:PROCEDURE

        }

                else if (iCalLine.startsWith("REPEAT") )
        {

            4.8.6.2 Repeat Count

               Property Name: REPEAT

               Purpose: This property defines the number of time the alarm should be
               repeated, after the initial trigger.

               Value Type: INTEGER

               Property Parameters: Non-standard property parameters can be
               specified on this property.

               Conformance: This property can be specified in a "VALARM" calendar
               component.

               Description: If the alarm triggers more than once, then this property
               MUST be specified along with the "DURATION" property.

               Format Definition: The property is defined by the following notation:

                 repeatcnt  = "REPEAT" repparam ":" integer CRLF
                 ;Default is "0", zero.

                 repparam   = *(";" xparam)

               Example: The following is an example of this property for an alarm
               that repeats 4 additional times with a 5 minute delay after the
               initial triggering of the alarm:

                 REPEAT:4
                 DURATION:PT5M


        }
        else if (iCalLine.startsWith("TRIGGER") )
        {

                4.8.6.3 Trigger

                   Property Name: TRIGGER

                   Purpose: This property specifies when an alarm will trigger.

                   Value Type: The default value type is DURATION. The value type can be
                   set to a DATE-TIME value type, in which case the value MUST specify a
                   UTC formatted DATE-TIME value.

                   Property Parameters: Non-standard, value data type, time zone
                   identifier or trigger relationship property parameters can be
                   specified on this property. The trigger relationship property
                   parameter MUST only be specified when the value type is DURATION.

                   Conformance: This property MUST be specified in the "VALARM" calendar
                   component.

                   Description: Within the "VALARM" calendar component, this property
                   defines when the alarm will trigger. The default value type is
                   DURATION, specifying a relative time for the trigger of the alarm.
                   The default duration is relative to the start of an event or to-do
                   that the alarm is associated with. The duration can be explicitly set
                   to trigger from either the end or the start of the associated event
                   or to-do with the "RELATED" parameter. A value of START will set the
                   alarm to trigger off the start of the associated event or to-do. A
                   value of END will set the alarm to trigger off the end of the
                   associated event or to-do.

                   Either a positive or negative duration may be specified for the
                   "TRIGGER" property. An alarm with a positive duration is triggered
                   after the associated start or end of the event or to-do. An alarm
                   with a negative duration is triggered before the associated start or
                   end of the event or to-do.

                   The "RELATED" property parameter is not valid if the value type of
                   the property is set to DATE-TIME (i.e., for an absolute date and time
                   alarm trigger). If a value type of DATE-TIME is specified, then the
                   property value MUST be specified in the UTC time format. If an
                   absolute trigger is specified on an alarm for a recurring event or
                   to-do, then the alarm will only trigger for the specified absolute
                   date/time, along with any specified repeating instances.

                   If the trigger is set relative to START, then the "DTSTART" property
                   MUST be present in the associated "VEVENT" or "VTODO" calendar
                   component. If an alarm is specified for an event with the trigger set
                   relative to the END, then the "DTEND" property or the "DSTART" and
                   "DURATION' properties MUST be present in the associated "VEVENT"
                   calendar component. If the alarm is specified for a to-do with a
                   trigger set relative to the END, then either the "DUE" property or
                   the "DSTART" and "DURATION' properties MUST be present in the
                   associated "VTODO" calendar component.

                   Alarms specified in an event or to-do which is defined in terms of a
                   DATE value type will be triggered relative to 00:00:00 UTC on the
                   specified date. For example, if "DTSTART:19980205, then the duration
                   trigger will be relative to19980205T000000Z.

                   Format Definition: The property is defined by the following notation:

                     trigger    = "TRIGGER" (trigrel / trigabs)

                     trigrel    = *(

                                ; the following are optional,
                                ; but MUST NOT occur more than once

                                  (";" "VALUE" "=" "DURATION") /
                                  (";" trigrelparam) /

                                ; the following is optional,
                                ; and MAY occur more than once

                                  (";" xparam)
                                  ) ":"  dur-value

                     trigabs    = 1*(

                                ; the following is REQUIRED,
                                ; but MUST NOT occur more than once

                                  (";" "VALUE" "=" "DATE-TIME") /

                                ; the following is optional,
                                ; and MAY occur more than once

                                  (";" xparam)

                                  ) ":" date-time

                   Example: A trigger set 15 minutes prior to the start of the event or
                   to-do.

                     TRIGGER:-P15M

                   A trigger set 5 minutes after the end of the event or to-do.

                     TRIGGER;RELATED=END:P5M

                   A trigger set to an absolute date/time.

                     TRIGGER;VALUE=DATE-TIME:19980101T050000Z

        }


    */

}

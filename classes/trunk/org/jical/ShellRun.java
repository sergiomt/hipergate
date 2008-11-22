package org.jical;
import java.io.ByteArrayInputStream;
import java.io.File;
import java.io.FileInputStream;
import java.io.InputStream;

import javax.xml.transform.Result;
import javax.xml.transform.Source;
import javax.xml.transform.Transformer;
import javax.xml.transform.TransformerFactory;
import javax.xml.transform.stream.StreamResult;
import javax.xml.transform.stream.StreamSource;
/*
 *  Version 1.2
 *  Provides extra XSLT capabilities.
 *
 */
public class ShellRun {
    /** Version number. */
    public static final String VERSION = "1.4";
    
    public static void main(String args[]) {
        /*
         *  The idea here is to provide user who are stuck on the command line and have no access to jboss with
         *  a way to run the JiCal options from CRON. Not really adviseable as it will incur a penalty of starting
         *  java each time but...
         *
         */
        if (args.length == 0
        || args[0].equalsIgnoreCase("-help")) {
            System.out.println(
            "================================================================================\n"+
            "JICAL v"+VERSION+" SHELL INTERFACE. GDAY - GOOD START! YOU FOUND ME!\n"+
            "\n"+
            "Your Options:\n"+
            " -ical2fburl           <calendarLocation> <fburl> <Organiser> <Email>                <DaysForward>\n"+
            " -ical2jicalxml        <calendarLocation>         <Organiser> <Email>                <DaysForward>\n"+
            " -ical2jicaldisplayxml <calendarLocation>         <Organiser> <Email>                <DaysForward> <timerange>\n"+
            " -xslt                 <calendarLocation>         <Organiser> <Email> <xsl document> <DaysForward>\n"+
            " -xsltonly                                                            <xsl document> <xml document>\n"+
            "\n"+
            "Parameters explained:\n"+
            "<calendarLocation>  - your iCal location\n"+
            "                      eg /home/sfg/evolution/local/Calendar/calendar.ics\n"+
            "<fburl>             - the internet URL for this FBURL before the username.ifb file\n"+
            "                      eg http://www.eurekait.com/\n"+
            "<Organiser>         - this is used to name the free busy file. (sfg.ifb)\n"+
            "                      eg sfg\n"+
            "<Email>             - the organisers email address\n"+
            "                      eg sfg@eurekait.com\n"+
            "<DaysForwardOrDateRange> - how far into the future do we project repeat events\n"+
            "                         eg1: 180\n"+
            "                         eg2: 20021215153500-20021215164500 Date formats are reverse ccyyMMddHHMMss\n"+
            "                              in the form fromdate-todate with the dash showing the start of the new date.\n"+
            "<timerange>         - If required, will only show events that fall within the time range\n"+
            "                         eg: 0730-1800 for 7:30am to 6:00pm \n"+
            "<xsl document>      - The Stylesheet to translate the XML to something else\n"+
            "                    eg HTML\n"+
            "<xml document>      - The xml to translate with the Stylesheet.\n"+
            "\n"+
            "Learn by example:\n"+
            "java -jar jical.jar -ical2fburl /home/sfg/evolution/local/Calendar/calendar.ics http://www.eurekait.com/ sfg sfg@eurekait.com 180 > /www/website.live/sfg.ifb\n"+
            "java -jar jical.jar -ical2jicalxml /home/sfg/evolution/local/Calendar/calendar.ics sfg sfg@eurekait.com 180 > /www/website.live/sfg.xml\n"+
            "java -jar jical.jar -xslt /home/sfg/evolution/local/Calendar/calendar.ics sfg sfg@eurekait.com xsl/htmllist.xsl 180 > /www/website.live/sfg-yag.html\n"+
            "java -jar jical.jar -xsltonly fred.xsl jicaldisplayonyl.xml > /www/website.live/sfg.svg\n"+
            "java -jar jical.jar -ical2jicaldisplayxml /home/sfg/evolution/local/Calendar/calendar.ics sfg sfg@eurekait.com 180 0630-2230 > /www/website.live/jicaldisplay.xml\n"+
            "================================================================================");
        }
        else if (args[0].equalsIgnoreCase("-ical2fburl")) {
            /* We will be processing as per jboss run but for a single entry. */
            if (args.length != 6) {
                System.err.println(
                "Syntax is:  -ical2fburl <calendarLocation> <FBURL> <Organiser> <Email> <DaysForwardOrDateRange>\n"+
                "Example:\n"+
                "java -jar jical.jar -ical2FBURL /home/sfg/evolution/local/Calendar/calendar.ics http://www.eurekait.com/ sfg sfg@eurekait.com 180 > /www/website.live/sfg.ifb");
                return;
            }
            ICalendarParser icp = new ICalendarParser();
            ICalendar ical = icp.parse(args[1]);
            ical.setFBUrl(args[2]);
            ical.setOrganizer(args[3]);
            ical.setOrganizerEmail(args[4]);
            //int DaysForwardOrDateRange = java.lang.Integer.parseInt(args[5]);
            //System.out.println(ical.getFBString(DaysForwardOrDateRange));
            try {
                System.out.println(ical.getFBString(args[5]));
            }
            catch (Exception e) {
                System.err.println(e);
                e.printStackTrace();
            }
        }
        else if (args[0].equalsIgnoreCase("-ical2jicalxml")) {
            /* We will be processing as per jboss run but for a single entry. */
            if (args.length < 5) {
                System.err.println(
                "Syntax is:  -ical2jicalxml <calendarLocation> <Organiser> <Email> <DaysForwardOrDateRange>\n"+
                "Example:\n"+
                "java -jar jical.jar -ical2jicalxml /home/sfg/evolution/local/Calendar/calendar.ics sfg sfg@eurekait.com 180 0630-2000 > /www/website.live/sfg.xml");
                return;
            }
            ICalendarParser icp = new ICalendarParser();
            ICalendar ical = icp.parse(args[1]);
            ical.setOrganizer(args[2]);
            ical.setOrganizerEmail(args[3]);
            //int DaysForwardOrDateRange = java.lang.Integer.parseInt(args[4]);
            //System.out.println(ical.getJiCalXML(DaysForwardOrDateRange));
            try {
                if (args.length == 5)
                    System.out.println(ical.getJiCalXML(args[4], null ));
                else
                    System.out.println(ical.getJiCalXML(args[4], args[5]));
            }
            catch (Exception e) {
                System.err.println(e);
                e.printStackTrace();
            }
        }
        else if (args[0].equalsIgnoreCase("-ical2jicaldisplayxml")) {
            /* This option should make it easier to generate calendars of peoples dairies for two reasons..
               Every day is included, so spacing empty days requires no programming in XSLT.
               Ugly events that span days are shown as seperate events per day. ie 7 day event is 7 single daily events.
               Repeat events are broken into their individual events. */
            if (args.length < 5) {
                System.err.println(
                "Syntax is:  -ical2jicaldisplayxml <calendarLocation> <Organiser> <Email> <DaysForwardOrDateRange> <timerange>\n"+
                "Example:\n"+
                "java -jar jical.jar -ical2jicaldisplayxml /home/sfg/evolution/local/Calendar/calendar.ics sfg sfg@eurekait.com 180 0630-1800 > /www/website.live/sfg-jicaldisplay.xml\n"+
                "Note - timerange is optional.");
                return;
            }

            ICalendarParser icp = new ICalendarParser();
            ICalendar ical = icp.parse(args[1]);
            ical.setOrganizer(args[2]);
            ical.setOrganizerEmail(args[3]);
            //int DaysForwardOrDateRange = java.lang.Integer.parseInt(args[4]);
            
            try {
                if (args.length == 5)
                    System.out.println(ical.getJiCaldisplayXML(args[4], null ));
                else
                    System.out.println(ical.getJiCaldisplayXML(args[4], args[5]));
                
            }
            catch (Exception e) {
                System.err.println(e);
                e.printStackTrace();
            }
        }
        else if (args[0].equalsIgnoreCase("-xslt")) {
            /* Use XALAN to transform an iCal to XML then via a given Style sheet to a new format. */
            if (args.length != 6) {
                System.err.println(
                "Syntax is:  -xslt <calendarLocation> <Organiser> <Email> <DaysForwardOrDateRange> <xsl document>\n"+
                "Example:\n"+
                "java -jar jical.jar -xslt /home/sfg/evolution/local/Calendar/calendar.ics sfg sfg@eurekait.com 180 xsl/yag.xsl > /www/website.live/sfg-yag.html");
                return;
            }
            ICalendarParser icp = new ICalendarParser();
            ICalendar ical = icp.parse(args[1]);
            ical.setOrganizer(args[2]);
            ical.setOrganizerEmail(args[3]);
            //int DaysForwardOrDateRange = java.lang.Integer.parseInt(args[5]);
            //String xmlCalString = ical.getJiCalXML(DaysForwardOrDateRange);
            String xmlCalString = null;
            try {
                xmlCalString = ical.getJiCalXML(args[5], null);
            }
            catch (Exception e) {
                System.err.println(e);
                e.printStackTrace();
            }
            // Now translate..
            try {
                
                // 1. Instantiate a TransformerFactory.
                javax.xml.transform.TransformerFactory tFactory =
                javax.xml.transform.TransformerFactory.newInstance();
                
                // 2. Use the TransformerFactory to process the stylesheet Source and
                //    generate a Transformer.
                
                javax.xml.transform.Transformer transformer = tFactory.newTransformer
                (new javax.xml.transform.stream.StreamSource(args[4])); //XSL File Name
                
                // 3. Use the Transformer to transform an XML Source and send the
                //    output to a Result object.
                ByteArrayInputStream bais = new ByteArrayInputStream(xmlCalString.getBytes());
                transformer.transform
                (new javax.xml.transform.stream.StreamSource(bais), // "foo.xml"
                //new javax.xml.transform.stream.StreamResult ( new java.io.FileOutputStream("foo.out"))
                new javax.xml.transform.stream.StreamResult(System.out)
                );
            }
            catch (Exception e) {
                System.err.println("JiCal -xsl error in translation: " + e);
                e.printStackTrace();
            }
        }
        else if (args[0].equalsIgnoreCase("-xsltonly")) {
            /* Use XALAN to do a XSLT.  This is just so its easy. */
            if (args.length != 3) {
                System.err.println(
                "Syntax is:  -xsltonly <xsl document> <xml input document>\n"+
                "Example:\n"+
                "java -jar jical.jar -xslt /www/website.live/jicaldisplay.xml xsl/svg.xsl > /www/website.live/sfg-yag.svg");
                return;
            }
            File styleFile = new File(args[1]);  // stylesheet
            File dataFile  = new File(args[2]);  // data
            try {
                InputStream dataStream = new FileInputStream(dataFile);
                InputStream styleStream = new FileInputStream(styleFile);
                // create XSLT Source and Result objects
                Source data = new StreamSource(dataStream);
                Source style = new StreamSource(styleStream);
                Result output = new StreamResult(System.out);
                // create Transformer and perform the tranfomation
                Transformer xslt =  TransformerFactory.newInstance().newTransformer(style);
                xslt.transform(data, output);
            }
            catch (Exception e) {
                System.err.println("JiCal -xsltonly error in translation: " + e);
                e.printStackTrace();
            }
        }
        else {
            System.out.println(
            "================================================================================\n"+
            "JICAL v"+VERSION+" SHELL INTERFACE. GDAY - GOOD START! YOU FOUND ME!\n"+
            "Unfortunately, you got the option wrong. try -help for a list\n"+
            "================================================================================");
        }
    }
}


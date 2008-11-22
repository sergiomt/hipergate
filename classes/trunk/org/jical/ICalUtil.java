/*
 * Created on 29-Oct-2004
 *
 * TODO To change the template for this generated file go to
 * Window - Preferences - Java - Code Style - Code Templates
 */
package org.jical;

import java.util.Date;

/**
 * @author sfg
 *
 * TODO To change the template for this generated type comment go to
 * Window - Preferences - Java - Code Style - Code Templates
 */
public class ICalUtil {
	
	public static String makeVEventLines(String type, String text)
	{
		if (text == null)
			return "";
		StringBuffer textLine = new StringBuffer();
		textLine.append(type).append(text).append("\n");
		
		// Now check for the fold over effect.
		//DESCRIPTION:This is a really big event line. I need to make this as I'm testing
		//  this stuff.
		
		
		if (textLine.length() <= 75)
			return textLine.toString();
		
		StringBuffer newLines = new StringBuffer();
		while (textLine.length() > 75)
		{
			newLines.append(textLine.substring(0,75)).append("\n");
			// Make text line from 78th char on.
			String newTextLine = " "+textLine.substring(75);
			textLine = new StringBuffer().append(newTextLine);
		}
			
		return newLines.toString()+textLine;
	}

	/*
	 * TODO, all these renderings should be here in a util class.
	 */
    public String getJiCaldisplayXML(ICalendar icalendar, Date dateFrom, Date dateTo, String timeRange)
    {
//        if (icalendar.getOrganizerEmail() == null
//        ||  icalendar.getOrganizer() == null) {
//            //logger.severe("Cannot create XML unless OrganizerEmail are Organizer provided to ICalendar");
//            return "";
//        }
//
//        /* 
//         * This is more useful for rendering as HTML or PDF an
//         * Evolution Calendar.
//         *
//         */
//
//        StringBuffer XMLString = new StringBuffer("<jicaldisplay>\n");
//        XMLString.append("\t<organizer>").append( icalendar.getOrganizer()).append("</organizer>\n");
//        XMLString.append("\t<organizeremail>").append(icalendar.getOrganizerEmail()).append("</organizeremail>\n");
//        XMLString.append("\t<datestart>").append(dateFormatter.format(dateFrom)).append("</datestart>\n");
//        XMLString.append("\t<dateend>").append(dateFormatter.format(dateTo)).append("</dateend>\n");
//
//        // Hmmm... If we truely want to represent this date range, we must get all dates from . 
//        // to the To range. Reason being that some might start before this date and repeat in 
//        // this range....
//        
//        // Make starting date really old!!
//
//        Date trueStartDate = new Date(0);
//        getIcalExpandedEvents(trueStartDate, dateTo, timeRange);
//
//        /*
//         * This is the tricky bit, iterate from the datefrom date, through the 
//         * days to the dateto date. All days in between get some XML.
//         */
//        
//        //int dateRepeatUnit = Calendar.HOUR_OF_DAY;
//        
//        Calendar repeatXMLDateStart = new GregorianCalendar();
//        repeatXMLDateStart.setTime(dateFrom);
//        
//        XMLString.append("<days>\n");
//        
//        while (repeatXMLDateStart != null
//        && !   repeatXMLDateStart.getTime().after(dateTo))
//        {
//            XMLString.append("\t\t<day>\n");
//            XMLString.append("\t\t\t<dayofweek>").append(dayOfWeek.format(repeatXMLDateStart.getTime())).append("</dayofweek>\n");
//            XMLString.append("\t\t\t<monthofyear>").append(monthOfYear.format(repeatXMLDateStart.getTime())).append("</monthofyear>\n");            
//            XMLString.append("\t\t\t<weeknumber>").append(weekNumber.format(repeatXMLDateStart.getTime())).append("</weeknumber>\n");
//            XMLString.append("\t\t\t<date>").append(dateOnlyFormat.format(repeatXMLDateStart.getTime())).append("</date>\n");
//            XMLString.append("\t\t\t<vevents>\n");
//            // Now find all events that match this date.
//            Calendar thisDateFrom = new GregorianCalendar();
//            thisDateFrom.setTime(repeatXMLDateStart.getTime());
//            thisDateFrom.set(Calendar.HOUR_OF_DAY, 0);
//            thisDateFrom.set(Calendar.MINUTE, 0);
//            thisDateFrom.set(Calendar.SECOND, 0);
//
//            Date thisTimeFrom = thisDateFrom.getTime();
//            // Altered as was excluding all day events which END at 00:00 on the next day..
//            Calendar thisDateTo = new GregorianCalendar();
//            thisDateTo.setTime(repeatXMLDateStart.getTime());
//            thisDateTo.set(Calendar.HOUR_OF_DAY,24);
//            thisDateTo.set(java.util.Calendar.MINUTE,0);
//            thisDateTo.set(java.util.Calendar.SECOND,0);
//            Date thisTimeTo = thisDateTo.getTime();
//            
//            Iterator eeIterator = sortedExpandedEvents.iterator();        
//            while (eeIterator.hasNext())
//            {
//		ICalendarVEvent icalEvent = (ICalendarVEvent) eeIterator.next();
//                /* There are four conditions for inclusion of this event
//                 in this day. 
//                 1) Runs right across this date and others.
//                 *  ie day 23/2/2004. Event goes 22/2/2004 to 25/2/2004
//                 2) Falls within the day
//                 **  ie day 23/2/2004. Event goes 23/2/2004 to 23/2/2004
//                 3) End period falls within the start day point or 
//                 *   ie day 23/2/2004. Event goes 22/2/2004 to 23/2/2004 5am
//                 4) Start period falls within the end day point. 
//                 *   ie day 23/2/2004. Event goes 23/2/2004 12 noon to 25/2/2004
//                */
//                Date icalDateStart = icalEvent.getDateStart();
//                Date icalDateEnd   = icalEvent.getDateEnd();
//
//                /*
//                 * Whole day events are not handled well with this method as they run
//                 * exactly on the 24hr time line. We need to recognise them and
//                 * for the purposes of testing conditions, reduce the seconds so
//                 * that they fit within a day.
//                 */
//                thisDateFrom.setTime(icalDateStart);
//                thisDateTo.setTime(icalDateEnd);
//                
//                // Condition 1.
//                if ((thisTimeFrom.after(icalDateStart)
//                ||   thisTimeFrom.equals(icalDateStart))
//                &&  (thisTimeTo.before(icalDateEnd)
//                ||   thisTimeTo.equals(icalDateEnd)))
//                {
//                    // Create an all day event as this event wraps this day and others.
//                    icalEvent.setDateStart(thisTimeFrom);
//                    icalEvent.setDateEnd(thisTimeTo);                    
//                    XMLString.append("\t\t");
//                    XMLString.append(icalEvent.toXML());
//                    XMLString.append("\n");
//                }
//                // Condition 2.
//                else if (thisTimeFrom.before(icalDateStart)
//                &&       thisTimeTo.after(icalDateEnd))
//                {
//                    // Create event as is.
////                    XMLString.append("Cond2");
//                    XMLString.append("\t\t");
//                    XMLString.append(icalEvent.toXML());
//                    XMLString.append("\n");
//                }    
//                // Condition 3.
//                else if (thisTimeFrom.before(icalDateEnd)
//                &&       thisTimeTo.after(icalDateEnd))
//                {
//                    // Create event with end time as thisTimeTo, start time as speced.
////                    XMLString.append("Cond3" + thisTimeFrom + thisTimeTo);
//                    icalEvent.setDateStart(thisTimeFrom);
//                    icalEvent.setDateEnd(icalDateEnd);
//                    XMLString.append("\t\t");
//                    XMLString.append(icalEvent.toXML());
//                    XMLString.append("\n");
//                }    
//                // Condition 4.
//                else if (thisTimeFrom.before(icalDateStart)
//                &&       thisTimeTo.after(icalDateStart))
//                {
//                    // Create event with starttime time as thisTimeFrom, end time as speced.
////                    XMLString.append("Cond4");
//                    icalEvent.setDateStart(icalDateStart);
//                    icalEvent.setDateEnd(thisTimeTo);
//                    XMLString.append("\t\t");
//                    XMLString.append(icalEvent.toXML());
//                    XMLString.append("\n");
//                }
//                else {
//                    //Event rejected for this date
//                }
//            }
//
//            XMLString.append("\t\t\t</vevents>");
//            XMLString.append("\t\t</day>\n");
//
//            // On to the next day..
//            repeatXMLDateStart.add(Calendar.HOUR_OF_DAY, 24);
//            
//        }
//        
//        XMLString.append("\t</days>\n");
//        XMLString.append("</jicaldisplay>\n");
//        return XMLString.toString();
    	return "";
    }
}

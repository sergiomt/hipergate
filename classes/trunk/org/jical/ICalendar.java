/*
 *
 * Created on August 1, 2002, 9:01 PM
 *
 * Stores an icalendar as a java object.
 * Included in the ICalendar is a collection of iCalendarVEvents
 * 
 * Rules for these objects:
 * All dates to be recorded as GMT time. ie if this is EST (Sydney) we record
 * based on that time -11h
 * The advantage of this is that it becomes easy to compare dates and to convert
 * to FBURL if required...
 *
 * Event objects that are re-curring are expanded there and then out for
 * a year or whatever the Max Extension parameter states.
 *
 *
 * Can parse an ICalendar file and create the ICalendar Java Object from
 * that ICalendar file.
 *
 * Currently, this is a partial implementation. 
 *
 * 1) Altered method to sort FBURLS so that they are in date/time sequence, not as found.
 *>>> Up To Here.
 * 2) Altering logic to include a blow out of events as a vector under the name
 *    icalExpandedEventCollection. This is the true list of events for this calendar
 *    expanded for as far as the parameter dictates.
 * 3) Represent XML version of ICalendar expanded events. The outside world has no interest
 *    in the repetition, only that the event occurs.
 *
 */

package org.jical;

/**
 *
 * @author  sfg
 * RFC 2445
 *
 */

import java.text.SimpleDateFormat;
import java.util.ArrayList;
import java.util.Calendar;
import java.util.Collection;
import java.util.Date;
import java.util.GregorianCalendar;
import java.util.Iterator;
import java.util.Set;
import java.util.TimeZone;
import java.util.TreeSet;
import java.util.logging.Logger;

public class ICalendar {

    private String          calScale;
    private String          prodId;
    private String          iCalVersion;
    private TimeZone        defaultTimeZone;
    public  Collection      icaltimeZoneCollection;
    
    // The most important one, the list of vevents.
    public  Collection      icalEventCollection;
    
    private static SimpleDateFormat hoursMinutes = new SimpleDateFormat("HHmm");
    private static SimpleDateFormat formatter = new SimpleDateFormat("yyyyMMdd'T'HHmmss'Z'");
    private static SimpleDateFormat dateFormatter = new SimpleDateFormat("yyyyMMddHHmmss");
    private static SimpleDateFormat dateOnlyFormat = new SimpleDateFormat("yyyyMMdd");    
    private static SimpleDateFormat dayOfWeek = new SimpleDateFormat("EEEEEEEE");    
    private static SimpleDateFormat monthOfYear = new SimpleDateFormat("MMMMMMMMMMMM");        
    private static SimpleDateFormat weekNumber = new SimpleDateFormat("ww");    
    private static SimpleDateFormat dayNumber = new SimpleDateFormat("d");
    private static SimpleDateFormat year = new SimpleDateFormat("yyyy");
    private static Date DEFAULTSTARTDATE = new Date(1);
    
    Calendar repeatDateStart = new GregorianCalendar();
    Calendar repeatDateEnd   = new GregorianCalendar();
    private Logger logger = Logger.getLogger(this.getClass().getName());
    
    /**
     * The sorted Expanded Events set holds all events from repeat
     * events sorted by startdate/uid.
     **/
    public  Set         sortedExpandedEvents;

    /** Holds value of property organizer. */
    private String organizer;
    
    /** Holds value of property FBUrl. */
    private String FBUrl;
    
    /** Holds value of property organizerEmail. */
    private String organizerEmail;

    /** Creates a new instance of ICalendar. */
    public ICalendar() {
        icaltimeZoneCollection      = new ArrayList();
        icalEventCollection         = new ArrayList();
        defaultTimeZone             = TimeZone.getDefault();
        sortedExpandedEvents        = new TreeSet( new ICalendarVEvent.StartDateUIDComparator() );
    }
    
    /** Getter for property calScale.
     * @return Value of property calScale.
     */
    public String getCalScale ()
    {
        return calScale;
    }

    /** Setter for property calScale.
     * @param calScale New value of property calScale.
     */
    public void setCalScale (String calScale)
    {
        this.calScale = calScale;
    }

    /** Getter for property prodId.
     * @return Value of property prodId.
     */
    public String getProdId ()
    {
        return prodId;
    }

    /** Setter for property prodId.
     * @param prodId New value of property prodId.
     */
    public void setProdId (String prodId)
    {
        this.prodId = prodId;
    }

    /** Getter for property version.
     * @return Value of property version.
     */
    public String getVersion()
    {
        return iCalVersion;
    }

    /** Setter for property version.
     * @param iCalVersion New value of property version.
     */
    public void setVersion (String iCalVersion)
    {
        this.iCalVersion = iCalVersion;
    }

    /** Getter for property organizer.
     * @return Value of property organizer.
     */
    public String getOrganizer() {
        return this.organizer;
    }
    
    /** Setter for property organizer.
     * @param organizer New value of property organizer.
     */
    public void setOrganizer(String organizer) {
        this.organizer = organizer;
    }
    
    /** Getter for property FBUrl.
     * @return Value of property FBUrl.
     */
    public String getFBUrl() {
        return this.FBUrl;
    }
    
    /** Setter for property FBUrl.
     * @param FBUrl New value of property FBUrl.
     */
    public void setFBUrl(String FBUrl) {
        this.FBUrl = FBUrl;
    }
    
    /** Getter for property organizerEmail.
     * @return Value of property organizerEmail.
     */
    public String getOrganizerEmail() {
        return this.organizerEmail;
    }
    
    /** Setter for property organizerEmail.
     * @param organizerEmail New value of property organizerEmail.
     */
    public void setOrganizerEmail(String organizerEmail) {
        this.organizerEmail = organizerEmail;
    }
    /*
     * TODO Refactor soon
     * This is not the optimal place for this but it works!
     * 
     */
    public Date getDateFrom(String dateRangeOrDaysForward) throws Exception
    {
        try 
        {
            return (Date)dateFormatter.parse(dateRangeOrDaysForward.substring(0,14));
        }
        catch (Exception e)
        {
            throw e;
        }
    }
    public Date getDateTo(String dateRangeOrDaysForward)  throws Exception
    {
        // Gets the From Date
        try 
        {
            return (Date)dateFormatter.parse(dateRangeOrDaysForward.substring(15));
        }
        catch (Exception e)
        {
            throw e;
        }
    }
    /*
     * TODO Moved to DateTimeRange utility.
     */
    public long getDaysForwardNumeric(String dateRangeOrDaysForward) throws Exception
    {
        try 
        {
            return java.lang.Integer.parseInt(dateRangeOrDaysForward);
        }
        catch (Exception e)
        {
            throw e;
        }
    }
    /*
     * TODO retire once refactored
     */
    public Date getDateToFromDaysForward(long daysForward)
    {
        Date dateTo = new Date();
        long rollMicroSecs = 86400000 * daysForward;
        dateTo.setTime(dateTo.getTime() + (rollMicroSecs));
        return dateTo;
    }

    public void getIcalExpandedEvents(Date dateFrom, Date dateTo, String timeRange)
    {
        /*
         * Get time ranges.
         */

        int timeFrom = 0;// new Integer(0);
        int timeTo = 2400; //new Integer(2400);
        if (timeRange != null)
        {
            timeFrom=Integer.parseInt(timeRange.substring(0,4));
            timeTo=Integer.parseInt(timeRange.substring(5));
        }

        formatter.setTimeZone(TimeZone.getTimeZone("GMT"));
                
        for(Iterator i=icalEventCollection.iterator(); i.hasNext(); )
        {
            ICalendarVEvent icalEvent = (ICalendarVEvent)i.next();
            Date dateStart = icalEvent.getDateStart();
            Date dateEnd   = icalEvent.getDateEnd();

            if ( (dateStart.after(dateFrom)
            &&   dateStart.before(dateTo))
			||   dateStart.equals(dateFrom)
            ||   dateStart.equals(dateTo) )
            {
            	logger.fine("Create This date: "+dateStart);
                // This is a qualified Event with no repeat rules!
                createExpandedEvent(dateStart, dateEnd, icalEvent, dateFrom, dateTo, timeFrom, timeTo);
            }

            if (icalEvent.getRRule() != null)                
            {
            	logger.fine("Repeat Rule is not null");
                /*
                 * Moved to parser
                    RepeatRules rr = new RepeatRules();
                    icalEvent.getRepeatRules().parseRepeatRules(icalEvent.getRRule());
                */
                /* 
                 * We have now parsed the repeat rules.
                 *
                 * Now evaluate the repeat rules all together.
                   From RFC 2445 

                 Here is an example of evaluating multiple BYxxx rule parts.

                        DTSTART;TZID=US-Eastern:19970105T083000
                        RRULE:FREQ=YEARLY;INTERVAL=2;BYMONTH=1;BYDAY=SU;BYHOUR=8,9;
                        BYMINUTE=30

                        First, the "INTERVAL=2" would be applied to "FREQ=YEARLY" to arrive
                        at "every other year". Then, "BYMONTH=1" would be applied to arrive
                        at "every January, every other year". Then, "BYDAY=SU" would be
                        applied to arrive at "every Sunday in January, every other year".
                        Then, "BYHOUR=8,9" would be applied to arrive at "every Sunday in
                        January at 8 AM and 9 AM, every other year". Then, "BYMINUTE=30"
                        would be applied to arrive at "every Sunday in January at 8:30 AM and
                        9:30 AM, every other year". Then, lacking information from RRULE, the
                        second is derived from DTSTART, to end up in "every Sunday in January
                        at 8:30:00 AM and 9:30:00 AM, every other year". Similarly, if the
                        BYMINUTE, BYHOUR, BYDAY, BYMONTHDAY or BYMONTH rule part were
                        missing, the appropriate minute, hour, day or month would have been
                        retrieved from the "DTSTART" property.
                 *
                 * 
                 */

                // Move on to the first repeatable date.
            	Calendar newCal = new GregorianCalendar();
            	newCal.setTime(icalEvent.getDateStart());
                setRepeatDateStart(newCal);
                newCal = new GregorianCalendar();
            	newCal.setTime(icalEvent.getDateEnd());
            	setRepeatDateEnd(newCal);

                getNextRepeatDate(icalEvent);
                
                logger.fine("Repeat Date next date: "+getRepeatDateStart().getTime()
                		+ " Interval "+icalEvent.getRepeatRules().interval
						+ " Repeat Unit "+icalEvent.getRepeatRules().dateRepeatUnit);

                Date repeatUntilDate = icalEvent.getRepeatRules().repeatUntilDate;
                if (repeatUntilDate == null)
                    repeatUntilDate = dateTo;
                if (repeatUntilDate.after(dateTo))
                    repeatUntilDate = dateTo;

                // In case we are creating up to a counter point, record the
                // count of events for this loop.
                int createCtr = 0;

                while (getRepeatDateStart() != null 
                		&& !getRepeatDateStart().getTime().after(repeatUntilDate))
                {
                    processRepeatEvent(icalEvent.getRepeatRules(), icalEvent.getRepeatRules().dateRepeatUnit, icalEvent, dateFrom, dateTo, timeFrom, timeTo);
                    
                    // Next repeat date to check.
                    getNextRepeatDate(icalEvent);
                    
                    logger.fine("Repeat Date next date: "+repeatDateStart.getTime()
                    		+ " Interval "+icalEvent.getRepeatRules().interval
    						+ " Repeat Unit "+icalEvent.getRepeatRules().dateRepeatUnit);

                    //repeatDateStart.add(icalEvent.getRepeatRules().dateRepeatUnit, icalEvent.getRepeatRules().interval);
                    //repeatDateEnd.add(icalEvent.getRepeatRules().dateRepeatUnit, icalEvent.getRepeatRules().interval);
                }
            }
        }
    }
    
    public void getNextRepeatDate(ICalendarVEvent icalEvent)
    {
    	logger.fine("dateStart: "+getRepeatDateStart().getTime());
    	Calendar newDate = getRepeatDateStart();
    	Calendar newDateEnd = getRepeatDateEnd();
        if (icalEvent.getRepeatRules().dateRepeatUnit==Calendar.DAY_OF_WEEK)
        { 
        	logger.fine("DAY_OF_WEEK: "+getRepeatDateStart().getTime() + " date: "+ newDate.getTime());
        	newDate.add(Calendar.DATE, 7 * icalEvent.getRepeatRules().interval);
        	logger.fine("DAY_OF_WEEK2 : "+newDate.getTime());
        	setRepeatDateStart(newDate);
        	newDate = getRepeatDateEnd();
        	newDate.add(Calendar.DATE, 7 * icalEvent.getRepeatRules().interval);
            setRepeatDateEnd(newDate);                    	
        }
        else
        {
        	// 
        	logger.fine("about to step to next repeat event unit:"+icalEvent.getRepeatRules().dateRepeatUnit
        			+ " Interval: " +icalEvent.getRepeatRules().interval);
        	
        	newDate.add(icalEvent.getRepeatRules().dateRepeatUnit, icalEvent.getRepeatRules().interval);
        	setRepeatDateStart(newDate);
        	
        	newDateEnd.add(icalEvent.getRepeatRules().dateRepeatUnit, icalEvent.getRepeatRules().interval);
        	setRepeatDateEnd(newDateEnd);
        	logger.fine("After date add - DateStart: "+getRepeatDateStart().getTime());
        }
    }
    
    public void processRepeatEvent(RepeatRules repeatRules, int dateConstraint,
                    ICalendarVEvent icalEvent, Date dateFrom, Date dateTo, int timeFrom, int timeTo){
        /* 
         * @Comment. This method will process an event and see if further examination is required prior to creating
         * an expanded event.
         */
        if (dateConstraint == Calendar.YEAR){
            if (repeatRules.repeatByYearDay !=null)
                repeatByYearDay(repeatDateStart, repeatDateEnd, repeatRules, dateConstraint,icalEvent, dateFrom, dateTo, timeFrom, timeTo);
            else if (repeatRules.repeatByMonth !=null)
                repeatByMonth(repeatDateStart, repeatDateEnd, repeatRules, dateConstraint,icalEvent, dateFrom, dateTo, timeFrom, timeTo);
            	// Too hard at present. if (repeatRules.repeatByWeekNo !=null)
            	// repeatByWeekNo(repeatDateStart, repeatDateEnd, repeatRules, dateConstraint);            
            else {
                // CREATE REPEATED EVENT!!!!
            	logger.fine("Year: Create: "+getRepeatDateStart().getTime());
                createExpandedEvent(repeatDateStart.getTime(), repeatDateEnd.getTime(), icalEvent, dateFrom, dateTo, timeFrom, timeTo);
            }
        } 
        else if (dateConstraint == Calendar.MONTH)            
        {
        	logger.fine("Repeat by Month, repeat by monthday:"+repeatRules.repeatByMonthDay );
        	logger.fine("Repeat by Month, repeat by day:"+repeatRules.repeatByDay );
            if (repeatRules.repeatByMonthDay != null)
            {
                repeatByMonthDay(repeatDateStart, repeatDateEnd, repeatRules, dateConstraint, icalEvent, dateFrom, dateTo, timeFrom, timeTo);
            }
            else if (repeatRules.repeatByDay != null)
            {
                repeatByDay(repeatRules, dateConstraint,icalEvent, dateFrom, dateTo, timeFrom, timeTo);
            } 
            else {
                // CREATE REPEATED EVENT!!!!
            	logger.fine("MONTH: Create: "+getRepeatDateStart().getTime());
                createExpandedEvent(repeatDateStart.getTime(), repeatDateEnd.getTime(), icalEvent, dateFrom, dateTo, timeFrom, timeTo);                
            }
        }
        // ie. Weekly.
        else if (dateConstraint == Calendar.DAY_OF_WEEK)
        {
            if (repeatRules.repeatByDay != null)
            {
            	logger.fine("RepeatByDay:"+repeatRules.repeatByDay);
                repeatByWeekDay(repeatRules, dateConstraint, icalEvent, dateFrom, dateTo, timeFrom, timeTo);
                logger.fine("End RepeatByDay");
            }
            else
            {
            	logger.fine("Create Weekly Event"+getRepeatDateStart().getTime());
            	createExpandedEvent(getRepeatDateStart().getTime(), getRepeatDateEnd().getTime(), icalEvent, dateFrom, dateTo, timeFrom, timeTo);
            }
        }
        else if (dateConstraint == Calendar.DATE)
        {
            // This is probably the lowest common denominator at present.
        	logger.fine("DATE: Create: "+getRepeatDateStart().getTime());
            createExpandedEvent(repeatDateStart.getTime(), repeatDateEnd.getTime(), icalEvent, dateFrom, dateTo, timeFrom, timeTo);
        }
        else if (dateConstraint == Calendar.HOUR)
        {
        	logger.fine("HOUR: Create: "+getRepeatDateStart().getTime());
            createExpandedEvent(repeatDateStart.getTime(), repeatDateEnd.getTime(), icalEvent, dateFrom, dateTo, timeFrom, timeTo);
        }
        else if (dateConstraint == Calendar.MINUTE)
        {
        	logger.fine("MINUTE: Create: "+getRepeatDateStart().getTime());
            createExpandedEvent(repeatDateStart.getTime(), repeatDateEnd.getTime(), icalEvent, dateFrom, dateTo, timeFrom, timeTo);
        }
        else if (dateConstraint == Calendar.SECOND)
        {
        	logger.fine("SECOND: Create: "+getRepeatDateStart().getTime());
            createExpandedEvent(repeatDateStart.getTime(), repeatDateEnd.getTime(), icalEvent, dateFrom, dateTo, timeFrom, timeTo);
        }
        else {
            logger.severe("NO MATCHING INTERVAL");
        }
    }
    public void repeatByYearDay(Calendar repeatDateStart, Calendar repeatDateEnd, RepeatRules repeatRules, int dateRepeatUnit,
                    ICalendarVEvent icalEvent, Date dateFrom, Date dateTo, int timeFrom, int timeTo)
    {
        /*
         * 
         * This routine will find the days of the year for which we require to repeat this event then 
         * create zoom into those days for more rules.
         *
         */
        java.util.StringTokenizer st = new java.util.StringTokenizer(repeatRules.repeatByYearDay,",");
        while (st.hasMoreTokens()) 
        {
            String rule = st.nextToken();
            int firstLast = 0;
            int dayOfYear = 0;
            if (rule.startsWith("-"))
            {
                // We are doing the Last X thingo.
                firstLast = 1;
            }
            try {
                dayOfYear = Integer.parseInt(rule);
            }
            catch (Exception e){
                logger.severe("Error parsing integer value from repeatByYearDay: " +rule);
                return;
            }
            // OK so we know what day of year, now find it!
            Calendar getDate = new GregorianCalendar();
            getDate.setTime(repeatDateStart.getTime());
            if (firstLast == 0)
            {
                // Set to start of year then add the days to that.
                getDate.set(Calendar.DAY_OF_MONTH,1);
                getDate.set(Calendar.MONTH,1);
                getDate.add(Calendar.DATE,dayOfYear - 1);
            } else
            {
                getDate.set(Calendar.MONTH,Calendar.DECEMBER);
                getDate.set(Calendar.DAY_OF_MONTH,31);
                getDate.add(Calendar.DATE, -1 * dayOfYear);
            }
            // Now move that back to the repeat date Start/End.
            repeatDateStart.set(Calendar.DAY_OF_MONTH, 1);
            repeatDateStart.set(Calendar.MONTH, getDate.get(Calendar.MONTH));
            repeatDateStart.set(Calendar.DAY_OF_MONTH, getDate.get(Calendar.DAY_OF_MONTH));
            repeatDateEnd.set(Calendar.DAY_OF_MONTH, 1);
            repeatDateEnd.set(Calendar.MONTH, getDate.get(Calendar.MONTH));
            repeatDateEnd.set(Calendar.DAY_OF_MONTH, getDate.get(Calendar.DAY_OF_MONTH));
            
            // This Date has been selected for processing. It may require further processing based upon the 
            // further contents of the repeatRule..
            processRepeatEvent(repeatRules, Calendar.DATE, icalEvent, dateFrom, dateTo, timeFrom, timeTo);
        }
    }    
    
    public void repeatByMonthDay(Calendar repeatDateStart, Calendar repeatDateEnd, RepeatRules repeatRules, int dateRepeatUnit,
                    ICalendarVEvent icalEvent, Date dateFrom, Date dateTo, int timeFrom, int timeTo)
    {
        /*
         * 
         * This routine will find the days of the Month for which we require to repeat this event then 
         *
         */
        java.util.StringTokenizer st = new java.util.StringTokenizer(repeatRules.repeatByMonthDay,",");
        while (st.hasMoreTokens()) 
        {
            String rule = st.nextToken();
            int firstLast = 0;
            int dayOfMonth = 0;
            
            logger.fine("rule:"+rule);
            
            if (rule.startsWith("-"))
            {
                // We are doing the Last X thingo.
                firstLast = 1;
            }
            try {
                dayOfMonth = Integer.parseInt(rule);
            }
            catch (Exception e){
                logger.severe("Error parsing integer value from repeatByYearDay: " +rule);
                return;
            }
            // OK so we know what day of year, now find it!
            Calendar getDate = new GregorianCalendar();
            getDate.setTime(repeatDateStart.getTime());
            if (firstLast == 0)
            {
                // Set to start of year then add the days to that.
                getDate.set(Calendar.DAY_OF_MONTH,1);
                getDate.add(Calendar.DATE,dayOfMonth-1);
            } else
            {
                // Get the last day of the month by going forward a month then back a day.
                getDate.set(Calendar.DAY_OF_MONTH,1);                
                getDate.add(Calendar.MONTH,1);
                getDate.add(Calendar.DATE,-1);
                // Now we are on the last day of the month, subtract the days (+1).
                getDate.set(Calendar.DATE,1+dayOfMonth);
            }
            // Now move that back to the repeat date Start/End.
            repeatDateStart.set(Calendar.DAY_OF_MONTH, 1);
            repeatDateStart.set(Calendar.MONTH, getDate.get(Calendar.MONTH));
            repeatDateStart.set(Calendar.DAY_OF_MONTH, getDate.get(Calendar.DAY_OF_MONTH));
            repeatDateEnd.set(Calendar.DAY_OF_MONTH, 1);
            repeatDateEnd.set(Calendar.MONTH, getDate.get(Calendar.MONTH));
            repeatDateEnd.set(Calendar.DAY_OF_MONTH, getDate.get(Calendar.DAY_OF_MONTH));
            
            // This Date has been selected for processing. It may require further processing based upon the 
            // further contents of the repeatRule..
            processRepeatEvent(repeatRules, Calendar.DATE, icalEvent, dateFrom, dateTo, timeFrom, timeTo);
        }
    }    
    
    public void repeatByMonth(Calendar repeatDateStart, Calendar repeatDateEnd, RepeatRules repeatRules, int dateRepeatUnit,
                    ICalendarVEvent icalEvent, Date dateFrom, Date dateTo, int timeFrom, int timeTo)
    {
        /*
         * 
         * This routine will find the days of the year for which we require to repeat this event then 
         * zoom into those days for more rules.
         *
         */
        java.util.StringTokenizer st = new java.util.StringTokenizer(repeatRules.repeatByMonth,",");
        while (st.hasMoreTokens()) 
        {
            int monthOfYear = 0;
            String rule = st.nextToken();
            try
            {
                monthOfYear = Integer.parseInt(rule);            
            }
            catch (Exception e)
            {
                logger.severe("Error parsing integer value from repeatByYearDay: " +rule);
                return;
            }
            
            // Now move that back to the repeat date Start/End.
            
            //logger.severe(repeatDateStart.getTime());
            repeatDateStart.set(Calendar.MONTH, monthOfYear - 1);
            if (repeatDateStart.get(Calendar.MONTH) != monthOfYear - 1)
            {
                
                logger.severe("Error setting MonthOfYear for date: " +repeatDateStart.getTime()
                                    +" to Month "+ monthOfYear
                                    +" From DateStartMonth"+repeatDateStart.get(Calendar.MONTH)
                                    +" Event: "+ icalEvent.getSummary());
                return;
            }

            //logger.severe(repeatDateEnd.getTime());
            repeatDateEnd.set(Calendar.MONTH, monthOfYear - 1);
            if (repeatDateEnd.get(Calendar.MONTH) != monthOfYear - 1)
            {
                logger.severe("Error setting MonthOfYear for date: " +repeatDateEnd.getTime()
                                    +" to Month "+ monthOfYear
                                    +" From DateEndMonth"+repeatDateEnd.get(Calendar.MONTH)
                                    +" Event: "+ icalEvent.getSummary());
                return;
            }
            // This Date has been selected for processing. It may require further processing based upon the 
            // further contents of the repeatRule..
            processRepeatEvent(repeatRules, Calendar.MONTH, icalEvent, dateFrom, dateTo, timeFrom, timeTo);
        }
    }  
    /*
     * Introduced to get weekly multi-day repeats correct.
     */
    public void repeatByWeekDay(RepeatRules repeatRules, int dateRepeatUnit,
            ICalendarVEvent icalEvent, Date dateFrom, Date dateTo, int timeFrom, int timeTo)
	{
    	
    	// Assumes starting date is set as repeatDateStart
    	// Does NOT increment it as we need to enable iterating through week but NOT upsetting the
    	// overall week incrementer.
    	java.util.StringTokenizer st = new java.util.StringTokenizer(repeatRules.repeatByDay,",");
        while (st.hasMoreTokens()) 
        {
        	
            String rule = st.nextToken();
            int dayOfWeek = ("SUMOTUWETHFRSA".indexOf(rule.substring(0,2)) / 2) + 1;
            if (dayOfWeek == -1)
            	return;
            
            // Find this DOW in the next 7 days..
            int iDayCtr = 0;
            Calendar workDateFrom = new GregorianCalendar();
            workDateFrom.setTime(repeatDateStart.getTime());
            Calendar workDateTo   = new GregorianCalendar();
            workDateTo.setTime(repeatDateEnd.getTime());
            logger.fine("Going to loop 7 days from "+workDateFrom.getTime() +" as long as "+workDateTo.getTime()+ " is before "+dateTo
            		+" and this" +!workDateTo.equals(dateTo)+ " is true");
            // Loop through the 7 days and create for this day..
            while(iDayCtr <= 7 && ( workDateTo.getTime().before(dateTo) && !workDateTo.equals(dateTo)))
            {
            	iDayCtr++;
            	workDateFrom.add(Calendar.DATE,1);
            	workDateTo.add(Calendar.DATE,1);
            	logger.fine("Up to "+workDateFrom.getTime());
            	if (workDateFrom.get(Calendar.DAY_OF_WEEK) == dayOfWeek)
            	{
            		logger.fine("Create expanded event "+workDateFrom.getTime());
            		createExpandedEvent(workDateFrom.getTime(), workDateTo.getTime(), icalEvent, dateFrom, dateTo, timeFrom, timeTo);
            		// found this dow so next dow of concern
            		break;
            	}
            }
            
        }
    	
	}
    public void repeatByDay(RepeatRules repeatRules, int dateRepeatUnit,
                    ICalendarVEvent icalEvent, Date dateFrom, Date dateTo, int timeFrom, int timeTo)
    {
        /*
         * 
         * This routine will find the days of the year for which we require to repeat this event then 
         * create zoom into those days for more rules.
         *
         */
        java.util.StringTokenizer st = new java.util.StringTokenizer(repeatRules.repeatByDay,",");
        while (st.hasMoreTokens()) 
        {
            String rule = st.nextToken();
            
            logger.fine("Next Rule: "+rule);
            
            int firstLast = 0;
            int sequenceInMonth = 9999;
            int dayOfWeek = 0;

            Calendar workDateFrom = new GregorianCalendar();
            workDateFrom.setTime(repeatDateStart.getTime());
            Calendar workDateTo   = new GregorianCalendar();
            workDateTo.setTime(repeatDateEnd.getTime());

            if (rule.startsWith("-"))
            {
                // We are doing the Last X thingo.
                firstLast = 1;
                try{
                    sequenceInMonth = Integer.parseInt(rule.substring(1,1));
                    //dayOfWeek = ("SUMOTUWETHFRSA".indexOf(rule.substring(2,2)) / 2) + 1;
                    // Fix a bug where the wrong index was being used in
                    // the substring for the dayOfWeek
                    dayOfWeek = ("SUMOTUWETHFRSA".indexOf(rule.substring(2,4)) / 2) + 1;
                }
                catch(Exception e){
                    logger.severe("Error Parsing Day RRULE, rule: " +rule);
                    e.printStackTrace(System.err);
                    return;
                }
            }
            //else if ("0123456789".indexOf(rule.substring(0)) != -1)
        	else if ("0123456789".indexOf(rule.substring(0,1)) != -1)
            {
                try{
                    // We have a 1st/last Sunday in Jan type of situ.
                    sequenceInMonth = Integer.parseInt(rule.substring(0));
                    dayOfWeek = ("SUMOTUWETHFRSA".indexOf(rule.substring(1,2)) / 2) + 1;
                }
                catch(Exception e){
                    logger.severe("Error Parsing Day RRULE, rule: " +rule);
                    e.printStackTrace(System.err);
                    return;
                }
            }
            else 
            {
                // A (not so) simple day of week.
                dayOfWeek = ("SUMOTUWETHFRSA".indexOf(rule.substring(0,2)) / 2) + 1;;
            }
            
            logger.fine("RepeatRulesBySetPos"+repeatRules.repeatBySetPos);
            if (repeatRules.repeatBySetPos != null){
                sequenceInMonth = repeatRules.getRepeatBySetPos().intValue();
            }
            
            /*
             * Now check the RepeatByDay rule for days of the week. 
             * If it exists, create an event for each of those days subject to
             * date range etc, etc
             *
             */
            
             // First the repeated day of week.. ie MO,TU etc.
             if (sequenceInMonth == 9999){
                 if (dateRepeatUnit == Calendar.MONTH) {
                    // Run through the month and processEvent every Calendar Day that matches.
                    // This is like the 3rd Monday in the Month type of thing.
                    int thisMonth = workDateFrom.get(Calendar.MONTH);
                    while (workDateFrom.get(Calendar.MONTH) == thisMonth)
                    {
                        if (workDateFrom.get(Calendar.DAY_OF_WEEK) == dayOfWeek)
                        {
                        	setRepeatDateStart(workDateFrom);
                            setRepeatDateEnd(workDateTo);
                            processRepeatEvent(repeatRules, Calendar.DATE, icalEvent, dateFrom, dateTo, timeFrom, timeTo);
                        }
                        workDateFrom.add(Calendar.DATE, 1);
                        workDateTo.add(Calendar.DATE, 1);
                        setRepeatDateStart(workDateFrom);
                        setRepeatDateEnd(workDateTo);
                    }
                 }
                 if (dateRepeatUnit == Calendar.DAY_OF_WEEK) {
                     // Run through the days of the week and create an event for the day inferred.
                     // Like Every Monday type of thing.
                     int weekCount = 1;
                     while (weekCount < 8)
                     {
                        if (workDateFrom.get(Calendar.DAY_OF_WEEK) == dayOfWeek)
                            processRepeatEvent(repeatRules, Calendar.MONTH, icalEvent, dateFrom, dateTo, timeFrom, timeTo);
                        workDateFrom.add(Calendar.DATE,1);
                        workDateTo.add(Calendar.DATE,1);
                        setRepeatDateStart(workDateFrom);
                        setRepeatDateEnd(workDateTo);
                        weekCount++;
                    }
                 }
            }
            else
            {
            	logger.fine("Attempting nth DD in Month from "+ workDateFrom.getTime());
                // Looking for the xth Sunday of the month etc etc.
                Calendar getDate = new GregorianCalendar();
                getDate.setTime(workDateFrom.getTime());
                int thisMonth = workDateFrom.get(Calendar.MONTH);
                int dayIncrement = 0;
                int occuranceCtr = 0;
                logger.fine("sequenceInMonth: "+sequenceInMonth);
                if (sequenceInMonth < 0)
                {
                    // Set last day of month.
                    getDate.set(Calendar.DAY_OF_MONTH,1);  
                    // Add one month,
                    getDate.add(Calendar.MONTH,1);
                    // Substract 1 day should get last day of month.
                    getDate.add(Calendar.DATE,-1);
                    logger.fine("Start from last day of month: "+getDate.getTime());
                    // This determines that we are counting BACKWARDS.
                    dayIncrement  = -1;
                    
                }
                else {
                    getDate.set(Calendar.DAY_OF_MONTH,1);
                    dayIncrement  = +1;
                }

                while (getDate.get(Calendar.MONTH) == thisMonth)
                {
                    if (getDate.get(Calendar.DAY_OF_WEEK) == dayOfWeek)
                    {
                    	logger.fine("Found that day of week:"+getDate.getTime());
                    	
                        occuranceCtr++;
                        if (occuranceCtr == sequenceInMonth * dayIncrement)
                        {
                            workDateFrom.set(Calendar.DAY_OF_MONTH, getDate.get(Calendar.DAY_OF_MONTH));
                            workDateTo.set(Calendar.DAY_OF_MONTH, getDate.get(Calendar.DAY_OF_MONTH));
                            setRepeatDateStart(workDateFrom);
                            setRepeatDateEnd(workDateTo);
                            logger.fine("Found one!"+workDateFrom);
                            processRepeatEvent(repeatRules, Calendar.DATE, icalEvent, dateFrom, dateTo, timeFrom, timeTo);
                            return;                            
                        }
                    }
                    
                    getDate.add(Calendar.DATE,dayIncrement);
                    logger.fine("Next date is : "+getDate.getTime());
                }                 
            }
             
        } // Has More Days to process.
    }        
    public void createExpandedEvent(Date dateStartIn, Date dateEndIn, ICalendarVEvent iCalEventIn, Date dateFrom, Date dateTo, int  timeFrom, int timeTo)
    {
        /*
         * Moved repeat Exception check to where all repeat events are created.
         */
    	
    	logger.fine("Create Expanded Event: "+dateStartIn);
    	
    	// Fix a NPE for repeating event with no end
		if (dateEndIn == null) {
			dateEndIn = iCalEventIn.getDateEnd();
		}
		
		// Make sure date of event is within the date range we want
		if (dateEndIn.before(dateFrom) || dateStartIn.after(dateTo)) 
			return;
		
		
    	
        int testTimeStart = Integer.parseInt(hoursMinutes.format(dateStartIn));
        int testTimeEnd   = Integer.parseInt(hoursMinutes.format(dateEndIn));

       /* There are four conditions for inclusion of this event
         in this day based on a time range. 
         1) Runs right across this date and others.
        *  ie day 23/2/2004. Event goes 22/2/2004 to 25/2/2004
         2) Falls within the day
        **  ie day 23/2/2004. Event goes 23/2/2004 to 23/2/2004
         3) End period falls within the start day point or 
        *   ie day 23/2/2004. Event goes 22/2/2004 to 23/2/2004 5am
         4) Start period falls within the end day point. 
        *   ie day 23/2/2004. Event goes 23/2/2004 12 noon to 25/2/2004
        */
        
        // Condition 1.
        if ( testTimeStart < timeFrom
        &&   testTimeEnd   > timeTo){}
        // Condition 2.
        else if (testTimeStart >= timeFrom
        &&       testTimeEnd   <= timeTo){}    
        // Condition 3.
        else if (testTimeEnd   > timeTo
        &&       testTimeStart <= timeTo) {}
        // Condition 4.
        else if (testTimeEnd >= timeFrom
        &&       testTimeStart < timeFrom)  {}
        // All Day Event!!
        else if (testTimeStart == 0
        &&       testTimeEnd   == 0) {}
        else 
            return;
        
        if (iCalEventIn.isExDatesExist())
        {
            boolean foundExDate = false;

            for(Iterator itr=iCalEventIn.exDateCollection.iterator(); itr.hasNext(); )
            {
                String exDate = (String)itr.next();
                // Bug fix 2004/10
            	if (exDate.startsWith(dateOnlyFormat.format(dateStartIn))) 
                   return;
            }
        }
        
        if (iCalEventIn.getRepeatRules().repeatUntilCount <= iCalEventIn.getRepeatCount())
        {
            return;
        }

        iCalEventIn.setRepeatCount(iCalEventIn.getRepeatCount()+1);
		try {
		    ICalendarVEvent iCalEventNew = (ICalendarVEvent) iCalEventIn.clone();
		    iCalEventNew.setDateStart(dateStartIn);
		    iCalEventNew.setDateEnd(dateEndIn);
		    
		    if ((iCalEventNew.getOrganizer() == null || iCalEventNew.getOrganizer().length() == 0) &&
		       (iCalEventNew.getOrganizer() == null || iCalEventNew.getOrganizer().length() == 0)) 
		    {
		    	//iCalEventNew.setOrganizer(getOrganizer());
		    	iCalEventNew.setOrganizer(getOrganizer());
		    }
		    // Make sure single custom events for a recurring event are added
		    if (sortedExpandedEvents.contains(iCalEventNew)) 
		    {
		    	if (iCalEventNew.isRecurrenceId()) 
		    	{
		    		// Replace default recurring event with a custom single occurrence
		    		sortedExpandedEvents.remove(iCalEventNew);
		    	 }
		    }
		    sortedExpandedEvents.add( iCalEventNew );
		    
		    logger.fine("Create This date: "+dateStartIn);
		    logger.fine("Create UID: "+iCalEventNew.getUid());
		    logger.fine("RepeatSummary: "+iCalEventNew.getSummary());
		}
		catch ( Exception ex ) {
			logger.severe(ex.toString());
		    ex.printStackTrace();
		}
		
		
		
    }
    
    public String getFBString(String dateRangeOrDaysForward) throws Exception
    {
        Date dateFrom = null;
        Date dateTo   = null; 
        try 
        {
            long daysForward = getDaysForwardNumeric(dateRangeOrDaysForward);
            try 
            {
                return getFBString(daysForward);
            }
            catch (Exception e)
            {
                logger.severe("Cannot create FBURL due to error: " +e);
                return "";
            }
        }
        catch (Exception e)
        {
            try 
            {
                dateFrom = getDateFrom(dateRangeOrDaysForward);
                dateTo   = getDateTo(dateRangeOrDaysForward);
                
            }
            catch (Exception ee)
            {
                logger.severe("1.Unable to read your input dates: "
                                    + dateRangeOrDaysForward
                                    + "They must be of the form ccYYmmDDhhMMss-ccYYmmDDhhMMss"
                                    + ee);
                throw ee;
            }
        }            
        return getFBString(dateFrom , dateTo);
    }    
    
    public String getFBString(long daysForward)
    {
        Date dateFrom = new Date();
        Date dateTo = getDateToFromDaysForward(daysForward);
        /*
         * Currently, keep this dateFrom/To as coarse. ie, dateFrom/To are DAYS not DAY/HH:MM
         * ie for FROM date, set to time of 0000, for TO date set to time of 235959
         */
        try
        {
            dateFrom = (Date)dateOnlyFormat.parse(dateOnlyFormat.format(dateFrom));
            dateTo   = (Date)dateFormatter.parse(dateOnlyFormat.format(dateTo) + "235959");
        }
        catch (Exception e)
        {
            logger.severe(e.toString());
        }
        return getFBString(dateFrom, dateTo);
    }
    
    public String getFBString(Date dateFrom, Date dateTo)
    {
        /* Build a FBURL String for submitting to somewhere.
         * Remember to take into account all repeating events.
         */
        
        /* Read through all Vevents.
            The following is  an example of a "VFREEBUSY" calendar component used
            to publish busy time information.      *
                 FREEBUSY;FBTYPE=BUSY-UNAVAILABLE:19970308T160000Z/PT8H30M
                 FREEBUSY;FBTYPE=FREE:19970308T160000Z/PT3H,19970308T200000Z/PT1H
                 FREEBUSY;FBTYPE=FREE:19970308T160000Z/PT3H,19970308T200000Z/PT1H,
                  19970308T230000Z/19970309T000000Z
         
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
        if (this.getFBUrl() == null
        ||  this.getOrganizerEmail() == null
        ||  this.getOrganizer() == null) {
            logger.severe("Cannot create FBURL unless FBURL, OrganizerEmail are Organizer provided to ICalendar");
            return "";
        }
        
        StringBuffer FBString = new StringBuffer("BEGIN:VCALENDAR\nBEGIN:VFREEBUSY\n");
        FBString.append("ORGANIZER:").append(this.getOrganizerEmail()).append("\n");
        FBString.append("DTSTART:").append(formatter.format(dateFrom)).append("\n");
        FBString.append("DTEND:").append(formatter.format(dateTo)).append("\n");
        
        // Must always work out expanded events from year dot as otherwise previous 
        // dates where they repeat into this date range are missed.
        
        Date trueStartDate = new Date(0);
        
        //  2004-10 patch - um. Don't think this is right.. Ignored.
        //Fix bug where expanded events were only generated from the
        //current time rather than from the start date jical was started with
        //        getIcalExpandedEvents(null);
        
        
        
        
        getIcalExpandedEvents(trueStartDate, dateTo, null);        

        Iterator eeIterator = sortedExpandedEvents.iterator();
        while (eeIterator.hasNext())
        {
	    ICalendarVEvent icalEvent = (ICalendarVEvent) eeIterator.next();
	    
            /* There are four conditions for inclusion of this event
             in this day. 
             1) Runs right across this date and others.
             *  ie day 23/2/2004. Event goes 22/2/2004 to 25/2/2004
             2) Falls within the day
             **  ie day 23/2/2004. Event goes 23/2/2004 to 23/2/2004
             3) End period falls within the start day point or 
             *   ie day 23/2/2004. Event goes 22/2/2004 to 23/2/2004 5am
             4) Start period falls within the end day point. 
             *   ie day 23/2/2004. Event goes 23/2/2004 12 noon to 25/2/2004
            */
            Date icalDateStart = icalEvent.getDateStart();
            Date icalDateEnd   = icalEvent.getDateEnd();

            /*
             * Whole day events are not handled well with this method as they run
             * exactly on the 24hr time line. We need to recognise them and
             * for the purposes of testing conditions, reduce the seconds so
             * that they fit within a day.
             */
            Date thisTimeFrom = dateFrom;
            Date thisTimeTo   = dateTo;

            // Condition 1.
            if ((thisTimeFrom.after(icalDateStart)
            ||   thisTimeFrom.equals(icalDateStart))
            &&  (thisTimeTo.before(icalDateEnd)
            ||   thisTimeTo.equals(icalDateEnd)))
            {
                // Create an all day event as this event wraps this day and others.
                icalEvent.setDateStart(thisTimeFrom);
                icalEvent.setDateEnd(thisTimeTo);                    
                FBString.append(createFBRow(formatter, icalEvent.getDateStart(), icalEvent.getDateEnd()));                
            }
            // Condition 2.
            else if (thisTimeFrom.before(icalDateStart)
            &&       thisTimeTo.after(icalDateEnd))
            {
                // Create event as is.
                FBString.append(createFBRow(formatter, icalEvent.getDateStart(), icalEvent.getDateEnd()));
            }    
            // Condition 3.
            else if (thisTimeFrom.before(icalDateEnd)
            &&       thisTimeTo.after(icalDateEnd))
            {
                // Create event with end time as thisTimeTo, start time as speced.
                icalEvent.setDateStart(thisTimeFrom);
                icalEvent.setDateEnd(icalDateEnd);
                FBString.append(createFBRow(formatter, icalEvent.getDateStart(), icalEvent.getDateEnd()));
            }    
            // Condition 4.
            else if (thisTimeFrom.before(icalDateStart)
            &&       thisTimeTo.after(icalDateStart))
            {
                // Create event with starttime time as thisTimeFrom, end time as speced.
                icalEvent.setDateStart(icalDateStart);
                icalEvent.setDateEnd(thisTimeTo);
                FBString.append(createFBRow(formatter, icalEvent.getDateStart(), icalEvent.getDateEnd()));
            }
            else {
                //Event rejected for this date
            }
        }

        //URL:http://www.host.com/calendar/busytime/jsmith.ifb
        FBString.append("URL:");
        FBString.append( this.getFBUrl()); // Expect this to start with http:// and end in /
        FBString.append( this.getOrganizer());
        FBString.append( ".ifb");
        FBString.append( "\n");
        FBString.append( "END:VFREEBUSY\nEND:VCALENDAR");
        FBString.append( "\n");
        return FBString.toString();
    }
    
    public String createFBRow(SimpleDateFormat formatter, Date repeatDateStart, Date repeatDateEnd)
    {
        StringBuffer FBData = new StringBuffer();
        FBData.append("FREEBUSY;FBTYPE=BUSY:");
        FBData.append(formatter.format(repeatDateStart));
        FBData.append("/");
        FBData.append(formatter.format(repeatDateEnd));
        FBData.append("\n");
        return FBData.toString();
    }
    
    /*
     * This returns the whole calendar as a string.
     * Of course, if you haven't filled in all the required bits, 
     * it will be unreadable.
     */
    public String getVCalendar()
    {
		StringBuffer vCalBuffer = new StringBuffer();
		vCalBuffer.append(ICalUtil.makeVEventLines("BEGIN:VCALENDAR",""));
		vCalBuffer.append(ICalUtil.makeVEventLines("PRODID:",this.getProdId()));
		vCalBuffer.append(ICalUtil.makeVEventLines("VERSION:",this.getVersion()));
		vCalBuffer.append("\n");
		
		// Now loop through the current collection of VEVENTs and append them to the ultimate buffer.
		for(Iterator i=icalEventCollection.iterator(); i.hasNext(); )
        {
            ICalendarVEvent icalEvent = (ICalendarVEvent)i.next();
            vCalBuffer.append(icalEvent.toVEvent()).append("\n");
        }
		
		vCalBuffer.append(ICalUtil.makeVEventLines("END:VCALENDAR",""));

    	return vCalBuffer.toString();
    }
    
    
    public String getJiCalXML(String dateRangeOrDaysForward, String timeRange) throws Exception
    {
        Date dateFrom = null;
        Date dateTo   = null; 
        try 
        {
            long daysForward = getDaysForwardNumeric(dateRangeOrDaysForward);
            try 
            {
                return getJiCalXML(daysForward, timeRange);            
            }
            catch (Exception e)
            {   
                logger.severe("Error:" + e);
            }
        }
        catch (Exception e)
        {
            try 
            {
                dateFrom = getDateFrom(dateRangeOrDaysForward);
                dateTo   = getDateTo(dateRangeOrDaysForward);
                
            }
            catch (Exception ee)
            {
                logger.severe("Unable to read your input dates: "
                                    + dateRangeOrDaysForward
                                    + "They must be of the form ccYYmmDDhhMMss-ccYYmmDDhhMMss"
                                    + ee);
                throw ee;
            }
        }
        return getJiCalXML(dateFrom , dateTo, timeRange);
    }
    public String getJiCalXML(long daysForward, String timeRange)
    {
        Date dateFrom = new Date();
        Date dateTo = getDateToFromDaysForward(daysForward);

        /*
         * Currently, keep this dateFrom/To as coarse. ie, dateFrom/To are DAYS not DAY/HH:MM
         * ie for FROM date, set to time of 0000, for TO date set to time of 235959
         */
        try
        {
            dateFrom = (Date)dateOnlyFormat.parse(dateOnlyFormat.format(dateFrom));
            dateTo   = (Date)dateFormatter.parse(dateOnlyFormat.format(dateTo) + "235959");
        }
        catch (Exception e)
        {
        }
        return getJiCalXML(dateFrom, dateTo, timeRange);
    }

    public String getJiCalXML(Date dateFrom, Date dateTo, String timeRange)
    {
        if (this.getOrganizerEmail() == null
        ||  this.getOrganizer() == null) {
            logger.severe("Cannot create XML unless OrganizerEmail are Organizer provided to ICalendar");
            return "";
        }

        /* 
         * XML Initial take
         * This is NOT a version of XCAL as it unravels the events to their 
         * detail level. It is more useful for rendering as HTML or PDF an
         * Evolution Calendar.
         *
         */

        StringBuffer XMLString= new StringBuffer("<jicalxml>\n");
        XMLString.append("\t<organizer>").append( this.getOrganizer()).append("</organizer>\n");
        XMLString.append("\t<organizeremail>").append(this.getOrganizerEmail()).append("</organizeremail>\n");
        XMLString.append("\t<datestart>").append(dateFormatter.format(dateFrom)).append("</datestart>\n");
        XMLString.append("\t<dateend>").append(dateFormatter.format(dateTo)).append("</dateend>\n");
        XMLString.append("<vevents>\n");
        /*
         * Modified to make sure repeat events pick up EVERYTHING!
         */
        Date trueStartDate = new Date(0);
        getIcalExpandedEvents(trueStartDate, dateTo, timeRange);

        Iterator eeIterator = sortedExpandedEvents.iterator();        
        while (eeIterator.hasNext())
        {
	    ICalendarVEvent icalEvent = (ICalendarVEvent) eeIterator.next();
            /* There are four conditions for inclusion of this event
             in this day. 
             1) Runs right across this date and others.
             *  ie day 23/2/2004. Event goes 22/2/2004 to 25/2/2004
             2) Falls within the day
             **  ie day 23/2/2004. Event goes 23/2/2004 to 23/2/2004
             3) End period falls within the start day point or 
             *   ie day 23/2/2004. Event goes 22/2/2004 to 23/2/2004 5am
             4) Start period falls within the end day point. 
             *   ie day 23/2/2004. Event goes 23/2/2004 12 noon to 25/2/2004
            */
            Date icalDateStart = icalEvent.getDateStart();
            Date icalDateEnd   = icalEvent.getDateEnd();

            /*
             * Whole day events are not handled well with this method as they run
             * exactly on the 24hr time line. We need to recognise them and
             * for the purposes of testing conditions, reduce the seconds so
             * that they fit within a day.
             */
            Date thisTimeFrom = dateFrom;
            Date thisTimeTo   = dateTo;

            // Condition 1.
            if ((thisTimeFrom.after(icalDateStart)
            ||   thisTimeFrom.equals(icalDateStart))
            &&  (thisTimeTo.before(icalDateEnd)
            ||   thisTimeTo.equals(icalDateEnd)))
            {
                // Create an all day event as this event wraps this day and others.
                icalEvent.setDateStart(thisTimeFrom);
                icalEvent.setDateEnd(thisTimeTo);                    
                XMLString.append("\t\t");
                XMLString.append(icalEvent.toXML());
                XMLString.append("\n");
            }
            // Condition 2.
            else if (thisTimeFrom.before(icalDateStart)
            &&       thisTimeTo.after(icalDateEnd))
            {
                // Create event as is.
//                    XMLString.append("Cond2");
                XMLString.append("\t\t");
                XMLString.append(icalEvent.toXML());
                XMLString.append("\n");
            }    
            // Condition 3.
            else if (thisTimeFrom.before(icalDateEnd)
            &&       thisTimeTo.after(icalDateEnd))
            {
                // Create event with end time as thisTimeTo, start time as speced.
//                    XMLString.append("Cond3" + thisTimeFrom + thisTimeTo);
                icalEvent.setDateStart(thisTimeFrom);
                icalEvent.setDateEnd(icalDateEnd);
                XMLString.append("\t\t");
                XMLString.append(icalEvent.toXML());
                XMLString.append("\n");
            }    
            // Condition 4.
            else if (thisTimeFrom.before(icalDateStart)
            &&       thisTimeTo.after(icalDateStart))
            {
                // Create event with starttime time as thisTimeFrom, end time as speced.
//                    XMLString.append("Cond4");
                icalEvent.setDateStart(icalDateStart);
                icalEvent.setDateEnd(thisTimeTo);
                XMLString.append("\t\t");
                XMLString.append(icalEvent.toXML());
                XMLString.append("\n");
            }
            else {
                //Event rejected for this date
            }
        }
        
        XMLString.append("</vevents></jicalxml>\n");
        return XMLString.toString();
    }    
    
    public String getJiCaldisplayXML(String dateRangeOrDaysForward, String timeRange) throws Exception
    {
    	DateTimeRange dtr = new DateTimeRange();
    	dtr.calcDateTimeRange(dateRangeOrDaysForward,timeRange);
    	
//        Date dateFrom = null;
//        Date dateTo   = null; 
//        try 
//        {
//            long daysForward = getDaysForwardNumeric(dateRangeOrDaysForward);
//            try 
//            {
//                return getJiCaldisplayXML(daysForward, timeRange);            
//            }
//            catch (Exception e)
//            {   
//                logger.severe("Error:" + e);
//            }
//        }
//        catch (Exception e)
//        {
//            try 
//            {
//                dateFrom = getDateFrom(dateRangeOrDaysForward);
//                dateTo   = getDateTo(dateRangeOrDaysForward);
//                
//            }
//            catch (Exception ee)
//            {
//            	logger.severe("Unable to read your input dates: "
//                                    + dateRangeOrDaysForward
//                                    + "They must be of the form ccYYmmDDhhMMss-ccYYmmDDhhMMss"
//                                    + ee);
//                throw ee;
//            }
//        }            
        return getJiCaldisplayXML(dtr.dateFrom , dtr.dateTo, timeRange);
    }
//    public String getJiCaldisplayXML(long daysForward, String timeRange)
//    {
//        Date dateFrom = new Date();
//        Date dateTo = getDateToFromDaysForward(daysForward);
//        /*
//         * Currently, keep this dateFrom/To as coarse. ie, dateFrom/To are DAYS not DAY/HH:MM
//         * ie for FROM date, set to time of 0000, for TO date set to time of 235959
//         */
//        try
//        {
//            dateFrom = (Date)dateOnlyFormat.parse(dateOnlyFormat.format(dateFrom));
//            dateTo   = (Date)dateFormatter.parse(dateOnlyFormat.format(dateTo) + "235959");
//        }
//        catch (Exception e)
//        {
//            logger.severe("Error setting dates to process full day range." + e);
//        }
//        return getJiCaldisplayXML(dateFrom, dateTo, timeRange);
//    }

    public String getJiCaldisplayXML(Date dateFrom, Date dateTo, String timeRange)
    {
        if (this.getOrganizerEmail() == null
        ||  this.getOrganizer() == null) {
            logger.severe("Cannot create XML unless OrganizerEmail are Organizer provided to ICalendar");
            return "";
        }

        /* 
         * This is more useful for rendering as HTML or PDF an
         * Evolution Calendar.
         *
         */

        StringBuffer XMLString = new StringBuffer("<jicaldisplay>\n");
        XMLString.append("\t<organizer>").append( this.getOrganizer()).append("</organizer>\n");
        XMLString.append("\t<organizeremail>").append(this.getOrganizerEmail()).append("</organizeremail>\n");
        XMLString.append("\t<datestart>").append(dateFormatter.format(dateFrom)).append("</datestart>\n");
        XMLString.append("\t<dateend>").append(dateFormatter.format(dateTo)).append("</dateend>\n");

        // Hmmm... If we truely want to represent this date range, we must get all dates from . 
        // to the To range. Reason being that some might start before this date and repeat in 
        // this range....
        
        // Make starting date really old!!

        Date trueStartDate = new Date(0);
        getIcalExpandedEvents(trueStartDate, dateTo, timeRange);

        /*
         * This is the tricky bit, iterate from the datefrom date, through the 
         * days to the dateto date. All days in between get some XML.
         */
        
        //int dateRepeatUnit = Calendar.HOUR_OF_DAY;
        
        Calendar repeatXMLDateStart = new GregorianCalendar();
        repeatXMLDateStart.setTime(dateFrom);
        
        XMLString.append("<days>\n");
        
        while (repeatXMLDateStart != null
        && !   repeatXMLDateStart.getTime().after(dateTo))
        {
            XMLString.append("\t\t<day>\n");
            XMLString.append("\t\t\t<dayofweek>").append(dayOfWeek.format(repeatXMLDateStart.getTime())).append("</dayofweek>\n");
            XMLString.append("\t\t\t<monthofyear>").append(monthOfYear.format(repeatXMLDateStart.getTime())).append("</monthofyear>\n");            
            XMLString.append("\t\t\t<weeknumber>").append(weekNumber.format(repeatXMLDateStart.getTime())).append("</weeknumber>\n");
            XMLString.append("\t\t\t<date>").append(dateOnlyFormat.format(repeatXMLDateStart.getTime())).append("</date>\n");
            // Add two new XML elements which can be used when styling with XSL
			XMLString.append("\t\t\t<dayofweeknum>").append(repeatDateStart.get(Calendar.DAY_OF_WEEK)).append("</dayofweeknum>\n");
			XMLString.append("\t\t\t<dayofmonth>").append(dayNumber.format(repeatDateStart.getTime())).append("</dayofmonth>\n");
			XMLString.append("\t\t\t<year>").append(year.format(repeatDateStart.getTime())).append("</year>\n");            
            XMLString.append("\t\t\t<vevents>\n");
            // Now find all events that match this date.
            Calendar thisDateFrom = new GregorianCalendar();
            thisDateFrom.setTime(repeatXMLDateStart.getTime());
            thisDateFrom.set(Calendar.HOUR_OF_DAY, 0);
            thisDateFrom.set(Calendar.MINUTE, 0);
            thisDateFrom.set(Calendar.SECOND, 0);

            Date thisTimeFrom = thisDateFrom.getTime();
            // Altered as was excluding all day events which END at 00:00 on the next day..
            Calendar thisDateTo = new GregorianCalendar();
            thisDateTo.setTime(repeatXMLDateStart.getTime());
            thisDateTo.set(Calendar.HOUR_OF_DAY,24);
            thisDateTo.set(java.util.Calendar.MINUTE,0);
            thisDateTo.set(java.util.Calendar.SECOND,0);
            Date thisTimeTo = thisDateTo.getTime();
            
            Iterator eeIterator = sortedExpandedEvents.iterator();        
            while (eeIterator.hasNext())
            {
		ICalendarVEvent icalEvent = (ICalendarVEvent) eeIterator.next();
                /* There are four conditions for inclusion of this event
                 in this day. 
                 1) Runs right across this date and others.
                 *  ie day 23/2/2004. Event goes 22/2/2004 to 25/2/2004
                 2) Falls within the day
                 **  ie day 23/2/2004. Event goes 23/2/2004 to 23/2/2004
                 3) End period falls within the start day point or 
                 *   ie day 23/2/2004. Event goes 22/2/2004 to 23/2/2004 5am
                 4) Start period falls within the end day point. 
                 *   ie day 23/2/2004. Event goes 23/2/2004 12 noon to 25/2/2004
                */
                Date icalDateStart = icalEvent.getDateStart();
                Date icalDateEnd   = icalEvent.getDateEnd();

                /*
                 * Whole day events are not handled well with this method as they run
                 * exactly on the 24hr time line. We need to recognise them and
                 * for the purposes of testing conditions, reduce the seconds so
                 * that they fit within a day.
                 */
                thisDateFrom.setTime(icalDateStart);
                thisDateTo.setTime(icalDateEnd);
                
                // Condition 1.
                if ((thisTimeFrom.after(icalDateStart)
                ||   thisTimeFrom.equals(icalDateStart))
                &&  (thisTimeTo.before(icalDateEnd)
                ||   thisTimeTo.equals(icalDateEnd)))
                {
                    // Create an all day event as this event wraps this day and others.
                    icalEvent.setDateStart(thisTimeFrom);
                    icalEvent.setDateEnd(thisTimeTo);                    
                    XMLString.append("\t\t");
                    XMLString.append(icalEvent.toXML());
                    XMLString.append("\n");
                }
                // Condition 2.
                else if (thisTimeFrom.before(icalDateStart)
                &&       thisTimeTo.after(icalDateEnd))
                {
                    // Create event as is.
//                    XMLString.append("Cond2");
                    XMLString.append("\t\t");
                    XMLString.append(icalEvent.toXML());
                    XMLString.append("\n");
                }    
                // Condition 3.
                else if (thisTimeFrom.before(icalDateEnd)
                &&       thisTimeTo.after(icalDateEnd))
                {
                    // Create event with end time as thisTimeTo, start time as speced.
//                    XMLString.append("Cond3" + thisTimeFrom + thisTimeTo);
                    icalEvent.setDateStart(thisTimeFrom);
                    icalEvent.setDateEnd(icalDateEnd);
                    XMLString.append("\t\t");
                    XMLString.append(icalEvent.toXML());
                    XMLString.append("\n");
                }    
                // Condition 4.
                else if (thisTimeFrom.before(icalDateStart)
                &&       thisTimeTo.after(icalDateStart))
                {
                    // Create event with starttime time as thisTimeFrom, end time as speced.
//                    XMLString.append("Cond4");
                    icalEvent.setDateStart(icalDateStart);
                    icalEvent.setDateEnd(thisTimeTo);
                    XMLString.append("\t\t");
                    XMLString.append(icalEvent.toXML());
                    XMLString.append("\n");
                }
                else {
                    //Event rejected for this date
                }
            }

            XMLString.append("\t\t\t</vevents>");
            XMLString.append("\t\t</day>\n");

            // On to the next day..
            repeatXMLDateStart.add(Calendar.HOUR_OF_DAY, 24);
            
        }
        
        XMLString.append("\t</days>\n");
        XMLString.append("</jicaldisplay>\n");
        return XMLString.toString();
    }
    /**
	 * @return Returns the repeatDateEnd.
	 */
	public Calendar getRepeatDateEnd() {
		return repeatDateEnd;
	}
	/**
	 * @param repeatDateEnd The repeatDateEnd to set.
	 */
	public void setRepeatDateEnd(Calendar repeatDateEndIn) {
		this.repeatDateEnd = repeatDateEndIn;
	}
	/**
	 * @return Returns the repeatDateStart.
	 */
	public Calendar getRepeatDateStart() {
		return repeatDateStart;
	}
	/**
	 * @param repeatDateStart The repeatDateStart to set.
	 */
	public void setRepeatDateStart(Calendar repeatDateStartIn) {
		this.repeatDateStart = repeatDateStartIn;
	}
}

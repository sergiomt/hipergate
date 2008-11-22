/*
 * Created on 31-Oct-2004
 *
 * Purpose is to get the date time range to use for a jical calc.
 */
package org.jical;

import java.text.SimpleDateFormat;
import java.util.Date;
import java.util.logging.Logger;

/**
 * @author sfg
 *
 * TODO To change the template for this generated type comment go to
 * Window - Preferences - Java - Code Style - Code Templates
 */
public class DateTimeRange {
	Date dateFrom;
	Date dateTo;
	private static final SimpleDateFormat DATEONLY = new SimpleDateFormat("yyyyMMdd");
	private static final SimpleDateFormat DATETIME = new SimpleDateFormat("yyyyMMddHHmmss");
	private static String CURRENT  = "CURRENT";

	private Logger logger = Logger.getLogger(this.getClass().getName());
    /*
     * TODO Work out dateFrom dateTo and timeRange.
     * 
     */
    public void calcDateTimeRange(String dateRangeOrDaysForward, String timeRange)
    {
    	dateFrom = null;
        dateTo   = null; 
        
        // Allow CURRENT to fetch all calendar details up to today. 
        if (dateRangeOrDaysForward.equalsIgnoreCase(CURRENT))
        {
        	dateFrom = new Date(1);
        	dateTo   = new Date();
        }
        else
        	// Check for a range
        	if (dateRangeOrDaysForward.indexOf("-") != -1)
        	{
        		try
				{
        			dateFrom = getDateFrom(dateRangeOrDaysForward);
        			dateFrom = getDateTo(dateRangeOrDaysForward);
				}
        		catch (Exception e)
				{
        			logger.severe("Cannot read your datefrom/to parameter! RTFM. 14chars - 14 chars, exception:"+e);
        			dateFrom = null;
        			dateTo = null;
				}
        		
        	}
    	else  // Assume a 'days forward'.
    	{
    		 long daysForward = getDaysForwardNumeric(dateRangeOrDaysForward);
    	     calcDateRangeFromDaysForward(daysForward);
    	}
    }
    
    public long getDaysForwardNumeric(String dateRangeOrDaysForward)
    {
        try 
        {
            return java.lang.Integer.parseInt(dateRangeOrDaysForward);
        }
        catch (Exception e)
        {
        	e.printStackTrace();
            logger.severe("Really bad days forward parameter of "+dateRangeOrDaysForward+" caused exception: "+e);
            // Allow proceed but with zero days forward.
            return 0;
        }
        
    }
    private void calcDateRangeFromDaysForward(long daysForward)
    {
	    Date dateFrom = new Date();
	    Date dateTo = getDateToFromDaysForward(daysForward);
	    /*
	     * Currently, keep this dateFrom/To as coarse. ie, dateFrom/To are DAYS not DAY/HH:MM
	     * ie for FROM date, set to time of 0000, for TO date set to time of 235959
	     */
	    try
	    {
	        dateFrom = (Date)DATEONLY.parse(DATEONLY.format(dateFrom));
	        dateTo   = (Date)DATETIME.parse(DATEONLY.format(dateTo) + "235959");
	    }
	    catch (Exception e)
	    {
	        logger.severe("Error setting dates to process full day range." + e);
	    }
    }
    public Date getDateToFromDaysForward(long daysForward)
    {
        Date dateTo = new Date();
        long rollMicroSecs = 86400000 * daysForward;
        dateTo.setTime(dateTo.getTime() + (rollMicroSecs));
        return dateTo;
    }
    /*
     * This is not the optimal place for this but it works!
     * 
     */
    public Date getDateFrom(String dateRangeOrDaysForward) throws Exception
    {
        try 
        {
            return (Date)DATETIME.parse(dateRangeOrDaysForward.substring(0,14));
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
            return (Date)DATETIME.parse(dateRangeOrDaysForward.substring(15));
        }
        catch (Exception e)
        {
            throw e;
        }
    }
}

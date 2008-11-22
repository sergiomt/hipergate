/*
 *
 * Created on August 3, 2002, 9:01 PM
 *
 * Stores an icalendar Time Zone as a java object.
 * There can be more than one iCal time zone per Calendar.
 *  
 */

package org.jical;

/**
 *
 * @author  sfg
 * RFC 2445
 *
 */

import java.util.Date;

public class ICalendarTimeZone {

    private String  TzID;
    private String  XLicLocation;
    private int     standardTzOffsetFrom;
    private int     standardTzOffsetTo;
    private String  standardTzName;
    private Date    standardDtStart;
    private String  standardRRule;
    private int     daylightTzOffsetFrom;
    private int     daylightTzOffsetTo;
    private String  daylightTzName;
    private Date    daylightDtStart;
    private String  daylightRRule;

    /* 
     BEGIN:VTIMEZONE
    TZID:/softwarestudio.org/Olson_20011030_5/Australia/Sydney
    X-LIC-LOCATION:Australia/Sydney
    BEGIN:STANDARD
    TZOFFSETFROM:+1100
    TZOFFSETTO:+1000
    TZNAME:EST
    DTSTART:19700329T030000
    RRULE:FREQ=YEARLY;INTERVAL=1;BYDAY=-1SU;BYMONTH=3
    END:STANDARD
    BEGIN:DAYLIGHT
    TZOFFSETFROM:+1000
    TZOFFSETTO:+1100
    TZNAME:EST
    DTSTART:19701025T020000
    RRULE:FREQ=YEARLY;INTERVAL=1;BYDAY=-1SU;BYMONTH=10
    END:DAYLIGHT
    END:VTIMEZONE
     */
    
    /** Creates a new instance of ICalendar. */
    public ICalendarTimeZone() {
    }
    
    /** Getter for property TzID.
     * @return Value of property TzID.
     */
    public String getTzID ()
    {
        return TzID;
    }
    /** Setter for property TzID.
     * @param TzID New value of property TzID.
     */
    public void setTzID (String TzID)
    {
        this.TzID = TzID;
    }
    /** Getter for property XLicLocation.
     * @return Value of property XLicLocation.
     */
    public String getXLicLocation ()
    {
        return XLicLocation;
    }
    /** Setter for property XLicLocation.
     * @param XLicLocation New value of property XLicLocation.
     */
    public void setXLicLocation (String XLicLocation)
    {
        this.XLicLocation = XLicLocation;
    }
    /** Getter for property standardTzOffsetFrom.
     * @return Value of property standardTzOffsetFrom.
     */
    public int getstandardTzOffsetFrom ()
    {
        return standardTzOffsetFrom;
    }
    /** Setter for property standardTzOffsetFrom.
     * @param standardTzOffsetFrom New value of property standardTzOffsetFrom.
     */
    public void setstandardTzOffsetFrom (int standardTzOffsetFrom)
    {
        this.standardTzOffsetFrom = standardTzOffsetFrom;
    }
    /** Getter for property standardTzOffsetTo.
     * @return Value of property standardTzOffsetTo.
     */
    public int getstandardTzOffsetTo ()
    {
        return standardTzOffsetTo;
    }
    /** Setter for property standardTzOffsetTo.
     * @param standardTzOffsetTo New value of property standardTzOffsetTo.
     */
    public void setstandardTzOffsetTo (int standardTzOffsetTo)
    {
        this.standardTzOffsetTo = standardTzOffsetTo;
    }
    /** Getter for property standardTzName.
     * @return Value of property standardTzName.
     */
    public String getstandardTzName ()
    {
        return standardTzName;
    }
    /** Setter for property standardTzName.
     * @param standardTzName New value of property standardTzName.
     */
    public void setstandardTzName (String standardTzName)
    {
        this.standardTzName = standardTzName;
    }
    /** Getter for property standardDtStart.
     * @return Value of property standardDtStart.
     */
    public Date getstandardDtStart ()
    {
        return standardDtStart;
    }
    /** Setter for property standardDtStart.
     * @param standardDtStart New value of property standardDtStart.
     */
    public void setstandardDtStart (Date standardDtStart)
    {
        this.standardDtStart = standardDtStart;
    }
    /** Getter for property standardRRule.
     * @return Value of property standardRRule.
     */
    public String getstandardRRule()
    {
        return standardRRule;
    }
    /** Setter for property standardRRule.
     * @param standardRRule New value of property standardRRule.
     */
    public void setstandardRRule (String standardRRule)
    {
        this.standardRRule = standardRRule;
    }
    /** Getter for property daylightTzOffsetFrom.
     * @return Value of property daylightTzOffsetFrom.
     */
    public int getdaylightTzOffsetFrom ()
    {
        return daylightTzOffsetFrom;
    }
    /** Setter for property daylightTzOffsetFrom.
     * @param daylightTzOffsetFrom New value of property daylightTzOffsetFrom.
     */
    public void setdaylightTzOffsetFrom (int daylightTzOffsetFrom)
    {
        this.daylightTzOffsetFrom = daylightTzOffsetFrom;
    }
    /** Getter for property daylightTzOffsetTo.
     * @return Value of property daylightTzOffsetTo.
     */
    public int getdaylightTzOffsetTo ()
    {
        return daylightTzOffsetTo;
    }
    /** Setter for property daylightTzOffsetTo.
     * @param daylightTzOffsetTo New value of property daylightTzOffsetTo.
     */
    public void setdaylightTzOffsetTo (int daylightTzOffsetTo)
    {
        this.daylightTzOffsetTo = daylightTzOffsetTo;
    }
    /** Getter for property daylightTzName.
     * @return Value of property daylightTzName.
     */
    public String getdaylightTzName ()
    {
        return daylightTzName;
    }
    /** Setter for property daylightTzName.
     * @param daylightTzName New value of property daylightTzName.
     */
    public void setdaylightTzName (String daylightTzName)
    {
        this.daylightTzName = daylightTzName;
    }
    /** Getter for property daylightDtStart.
     * @return Value of property daylightDtStart.
     */
    public Date getdaylightDtStart ()
    {
        return daylightDtStart;
    }
    /** Setter for property daylightDtStart.
     * @param daylightDtStart New value of property daylightDtStart.
     */
    public void setdaylightDtStart (Date daylightDtStart)
    {
        this.daylightDtStart = daylightDtStart;
    }
    /** Getter for property daylightRRule.
     * @return Value of property daylightRRule.
     */
    public String getdaylightRRule()
    {
        return daylightRRule;
    }
    /** Setter for property daylightRRule.
     * @param daylightRRule New value of property daylightRRule.
     */
    public void setdaylightRRule (String daylightRRule)
    {
        this.daylightRRule = daylightRRule;
    }
}

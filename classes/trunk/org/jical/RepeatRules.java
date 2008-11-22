/*
 *
 * Created on August 3, 2002, 9:01 PM
 *
 * Stores a repeat rule object for 
 * manipulation by the expand events methods.
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
import java.util.Calendar;
import java.util.Date;

/**
 * @hibernate.class
 *     table="ICALREPEATRULES"
 *     dynamic-update="false"
 *     dynamic-insert="false"
 *
 * @hibernate.discriminator
 *     column="class"
 */

public class RepeatRules {

    private String          id;

   /**
    *
    * @hibernate.id 
    *     generator-class="uuid.hex"
    *     column="ID"
    *
    * @hibernate.column
    *     name="ID"
    *     sql-type="VARCHAR(255)"
    *
    */

    public String getId()
    {
        return this.id;
    }

    public void setId(String id)
    {
        this.id = id;
    }

    private String uid;

   /**
    *
    * @hibernate.property
    *     column="UID"
    *
    * @hibernate.column
    *     name="uid"
    *     sql-type="VARCHAR(255)"
    *
    */

    public String getUid()
    {
        return uid;
    }

    public void setUid(String uid)
    {
        this.uid = uid;
    }

    int    interval = 0;

   /**
    *
    * @hibernate.property
    *     column="INTERVAL"
    *
    * @hibernate.column
    *     name="uid"
    *     sql-type="INTEGER"
    *
    */

    public int getInterval()
    {
        return interval;
    }

    public void setInterval(int interval)
    {
        this.interval = interval;
    }

    int    dateRepeatUnit = Calendar.DATE;                    

   /**
    *
    * @hibernate.property
    *     column="DATEREPEATUNIT"
    *
    * @hibernate.column
    *     name="dateRepeatUnit"
    *     sql-type="INTEGER"
    *
    */

    public int getDateRepeatUnit()
    {
        return dateRepeatUnit;
    }

    public void setDateRepeatUnit(int dateRepeatUnit)
    {
        this.dateRepeatUnit = dateRepeatUnit;
    }

    String frequency = null;

   /**
    *
    * @hibernate.property
    *     column="FREQUENCY"
    *
    * @hibernate.column
    *     name="frequency"
    *     sql-type="VARCHAR(255)"
    *
    */

    public String getFrequency()
    {
        return frequency;
    }

    public void setFrequency(String frequency)
    {
        this.frequency = frequency;
    }

    String repeatUntil    = null;

   /**
    *
    * @hibernate.property
    *     column="REPEATUNTIL"
    *
    * @hibernate.column
    *     name="repeatUntil"
    *     sql-type="VARCHAR(255)"
    *
    */

    public String getRepeatUntil()
    {
        return repeatUntil;
    }

    public void setRepeatUntil(String repeatUntil)
    {
        this.repeatUntil = repeatUntil;
    }

    String repeatByDay    = null;

   /**
    *
    * @hibernate.property
    *     column="REPEATBYDAY"
    *
    * @hibernate.column
    *     name="repeatByDay"
    *     sql-type="VARCHAR(255)"
    *
    */

    public String getRepeatByDay()
    {
        return repeatByDay;
    }

    public void setRepeatByDay(String repeatByDay)
    {
        this.repeatByDay = repeatByDay;
    }

    String repeatByMonth  = null;

   /**
    *
    * @hibernate.property
    *     column="REPEATBYMONTH"
    *
    * @hibernate.column
    *     name="repeatByMonth"
    *     sql-type="VARCHAR(255)"
    *
    */

    public String getRepeatByMonth()
    {
        return repeatByMonth;
    }

    public void setRepeatByMonth(String repeatByMonth)
    {
        this.repeatByMonth = repeatByMonth;
    }

    String repeatBySecond = null;

   /**
    *
    * @hibernate.property
    *     column="REPEATBYSECOND"
    *
    * @hibernate.column
    *     name="repeatBySecond"
    *     sql-type="VARCHAR(255)"
    *
    */

    public String getRepeatBySecond()
    {
        return repeatBySecond;
    }

    public void setRepeatBySecond(String repeatBySecond)
    {
        this.repeatBySecond = repeatBySecond;
    }

    String repeatByMinute = null;

   /**
    *
    * @hibernate.property
    *     column="REPEATBYMINUTE"
    *
    * @hibernate.column
    *     name="repeatByMinute"
    *     sql-type="VARCHAR(255)"
    *
    */

    public String getRepeatByMinute()
    {
        return repeatByMinute;
    }

    public void setRepeatByMinute(String repeatByMinute)
    {
        this.repeatByMinute = repeatByMinute;
    }

    String repeatByHour   = null;

   /**
    *
    * @hibernate.property
    *     column="REPEATBYHOUR"
    *
    * @hibernate.column
    *     name="repeatByHour"
    *     sql-type="VARCHAR(255)"
    *
    */

    public String getRepeatByHour()
    {
        return repeatByHour;
    }

    public void setRepeatByHour(String repeatByHour)
    {
        this.repeatByHour = repeatByHour;
    }

    String repeatByMonthDay = null;

   /**
    *
    * @hibernate.property
    *     column="REPEATBYMONTHDAY"
    *
    * @hibernate.column
    *     name="repeatByMonthDay"
    *     sql-type="VARCHAR(255)"
    *
    */

    public String getRepeatByMonthDay()
    {
        return repeatByMonthDay;
    }

    public void setRepeatByMonthDay(String repeatByMonthDay)
    {
        this.repeatByMonthDay = repeatByMonthDay;
    }

    String repeatByYearDay = null;

   /**
    *
    * @hibernate.property
    *     column="REPEATBYYEARDAY"
    *
    * @hibernate.column
    *     name="repeatByYearDay"
    *     sql-type="VARCHAR(255)"
    *
    */

    public String getRepeatByYearDay()
    {
        return repeatByYearDay;
    }

    public void setRepeatByYearDay(String repeatByYearDay)
    {
        this.repeatByYearDay = repeatByYearDay;
    }

    String repeatByWeekNo = null;

   /**
    *
    * @hibernate.property
    *     column="REPEATBYWEEKNO"
    *
    * @hibernate.column
    *     name="repeatByWeekNo"
    *     sql-type="VARCHAR(255)"
    *
    */

    public String getRepeatByWeekNo()
    {
        return repeatByWeekNo;
    }

    public void setRepeatByWeekNo(String repeatByWeekNo)
    {
        this.repeatByWeekNo = repeatByWeekNo;
    }

    // Altered to Integer as was using -1 to represent null while -1 was a valid value!!!
    Integer    repeatBySetPos = null;

   /**
    *
    * @hibernate.property
    *     column="REPEATBYSETPOS"
    *
    * @hibernate.column
    *     name="repeatBySetPos"
    *     sql-type="INTEGER"
    *
    */

    public Integer getRepeatBySetPos()
    {
        return repeatBySetPos;
    }

    public void setRepeatBySetPos(Integer repeatBySetPos)
    {
        this.repeatBySetPos = repeatBySetPos;
    }

    int    repeatUntilCount = 99999999;

   /**
    *
    * @hibernate.property
    *     column="REPEATUNTILCOUNT"
    *
    * @hibernate.column
    *     name="repeatUntilCount"
    *     sql-type="INTEGER"
    *
    */

    public int getRepeatUntilCount()
    {
        return repeatUntilCount;
    }

    public void setRepeatUntilCount(int repeatUntilCount)
    {
        this.repeatUntilCount = repeatUntilCount;
    }

    Date   repeatUntilDate = null;

   /**
    *
    * @hibernate.property
    *     column="REPEATUNTILDATE"
    *
    * @hibernate.column
    *     name="repeatUntilDate"
    *     sql-type="DATE"
    *
    */

    public Date getRepeatUntilDate()
    {
        return repeatUntilDate;
    }

    public void setRepeatUntilDate(Date repeatUntilDate)
    {
        this.repeatUntilDate = repeatUntilDate;
    }


    private SimpleDateFormat dateFormatter = new SimpleDateFormat("yyyyMMddHHmmss");    
    
    public RepeatRules() {
    }
    
    public void parseRepeatRules (String rRule)
    {
        int startPoint = -1;
        int ii = 0;                    
        while (rRule != null && ii < 10) 
        {
            ii++;
            String thisRule = null;
            startPoint = rRule.indexOf(";");
            if (startPoint != -1)
            {
                thisRule = rRule.substring(0,startPoint);
                rRule = rRule.substring(startPoint + 1);
            }
            else
            {
                thisRule = rRule;
                rRule = null;
            }
            // Now evaluate the parameter.. 
            // This is a weird one! Evolution-EndDate?
            if (thisRule.startsWith("X-EVOLUTION-ENDDATE="))
            {
                startPoint = thisRule.indexOf(":");
                String newRule = thisRule.substring(0,startPoint);
                String evoEndDate = newRule.substring(20);
                thisRule = thisRule.substring(startPoint +1);
            }

            if (thisRule.startsWith("FREQ="))
            {
                frequency = thisRule.substring(5);
            }
            else if (thisRule.startsWith("INTERVAL="))
            {
                try{
                    Long Lint = (new Long(thisRule.substring(9)));
                    interval = Lint.intValue();
                }
                catch (Exception e){
                    System.err.println("INTERVAL Parse Error on " + thisRule + e);
                }
            }  
            else if (thisRule.startsWith("UNTIL="))
            {
                repeatUntil = thisRule;
                if (repeatUntil != null) {
                    repeatUntil = repeatUntil.substring(6);
                    //UNTIL=20020919
                    //UNTIL=20020919T000000
                    if (repeatUntil.length() == 8) {
                        repeatUntil = repeatUntil + "235959";
                    }
                    try
                    {
                        if (repeatUntil.charAt(8) == 'T') 
                        {
                            repeatUntil = repeatUntil.substring(0,8) + repeatUntil.substring(9);
                        }
                        /*
                         * When frequency is more than one day and UNTIL time = 000000
                         * time must be adjusted to 235959
                         */
                        if ((dateRepeatUnit != Calendar.HOUR) && 
                            (dateRepeatUnit != Calendar.MINUTE) &&
                            (dateRepeatUnit != Calendar.SECOND)) 
                        {
                            if (repeatUntil.substring(8).equals("000000")) {
                                repeatUntil = repeatUntil.substring(0,8) + "235959";
                            }
                        }
                        repeatUntilDate = dateFormatter.parse(repeatUntil);
                    }
                    catch (Exception e)
                    {
                        System.err.println("Exception getting RepeatUntilDate" +e);
                        System.err.println("Exception for date string" +thisRule);
                        repeatUntilDate = null;
                    }
                }    
            }
            else if (thisRule.startsWith("BYDAY="))
            {
                // Example: MO,TU,TH,FR
                repeatByDay = thisRule.substring(6);
            }
            else if (thisRule.startsWith("BYMONTH="))
            {
                // Example: 1 or 11 or 12
                // Comma delim list potentially.
                repeatByMonth = thisRule.substring(8);
            }
            else if (thisRule.startsWith("BYSECOND="))
            {
                // Example: 1 or 11 or 12
                // Comma delim list potentially.
                repeatBySecond = thisRule.substring(9);
            }                        
            else if (thisRule.startsWith("BYMINUTE="))
            {
                // Example: 1 or 11 or 12
                // Comma delim list potentially.
                repeatByMinute = thisRule.substring(9);
            }                        
            else if (thisRule.startsWith("BYHOUR="))
            {
                // Example: 1 or 11 or 12
                // Comma delim list potentially.
                repeatByHour = thisRule.substring(7);
            }
            else if (thisRule.startsWith("BYMONTHDAY="))
            {
                // Example: 1,11,12
                // Comma delim list potentially.
                repeatByMonthDay = thisRule.substring(11);
            }                        
            else if (thisRule.startsWith("BYYEARDAY="))
            {
                // Example: -50 50th last day of year.
                // Comma delim list potentially.
                repeatByYearDay = thisRule.substring(10);
            }
            else if (thisRule.startsWith("BYWEEKNO="))
            {
                // Example: 50 50th week of year.
                // Comma delim list potentially.
                repeatByWeekNo = thisRule.substring(9);
            }
            /*
                The BYSETPOS rule part specifies a COMMA character (US-ASCII decimal
                44) separated list of values which corresponds to the nth occurrence
                within the set of events specified by the rule. Valid values are 1 to
                366 or -366 to -1. It MUST only be used in conjunction with another
                BYxxx rule part. For example "the last work day of the month" could
                be represented as:

                RRULE:FREQ=MONTHLY;BYDAY=MO,TU,WE,TH,FR;BYSETPOS=-1                        
             */
            else if (thisRule.startsWith("BYSETPOS="))
            {
                //repeatBySetPos = new Integer(thisRule.substring(9)).intValue();
            	// No need to create an object, use static method
                repeatBySetPos = new Integer(thisRule.substring(9));
            }                        
            else if (thisRule.startsWith("COUNT="))
            {
                // Single integer.
                try{
                	//repeatUntilCount = new Integer(thisRule.substring(6)).intValue();
                	// No need to create an object, use static method
                	repeatUntilCount = Integer.parseInt(thisRule.substring(6));
                    
                }
                catch(Exception e){
                    System.err.println("BYSETPOS= Parse Error on " + thisRule + e);                                
                }
            }
        }
        
        // Now settle the dateRepeatUnit!
        if (frequency.equalsIgnoreCase("YEARLY"))
        {
            dateRepeatUnit = Calendar.YEAR;
        } else if (frequency.equalsIgnoreCase("MONTHLY"))
        {
            dateRepeatUnit = Calendar.MONTH;
        } else if (frequency.equalsIgnoreCase("WEEKLY"))
        {
            dateRepeatUnit = Calendar.DAY_OF_WEEK;
        } else if (frequency.equalsIgnoreCase("DAILY"))
        {
            dateRepeatUnit = Calendar.DATE;
        } else if (frequency.equalsIgnoreCase("HOURLY"))
        {
            dateRepeatUnit = Calendar.HOUR;
        } else if (frequency.equalsIgnoreCase("MINUTELY"))
        {
            dateRepeatUnit = Calendar.MINUTE;
        } else if (frequency.equalsIgnoreCase("SECONDLY"))
        {
            dateRepeatUnit = Calendar.SECOND;
        }
        else {
            System.err.println("RepeatRules =- No Matching rule for frequency " +frequency);
        }
    }
    
}

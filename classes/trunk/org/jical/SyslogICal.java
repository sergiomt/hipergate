/*
 * Created on 29-Oct-2004
 *
 * TODO To change the template for this generated file go to
 * Window - Preferences - Java - Code Style - Code Templates
 */
package org.jical;

import java.io.BufferedReader;
import java.io.BufferedWriter;
import java.io.FileInputStream;
import java.io.FileWriter;
import java.io.InputStreamReader;
import java.text.SimpleDateFormat;
import java.util.Date;
import java.util.LinkedList;

/**
 * @author sfg
 *
 * TODO To change the template for this generated type comment go to
 * Window - Preferences - Java - Code Style - Code Templates
 */
public class SyslogICal {

	public static void main(String[] args) {
		
		SimpleDateFormat formatter = new SimpleDateFormat("yyyy:MM:dd HH:mm:ss");
		SimpleDateFormat touchformatter = new SimpleDateFormat("yyyyMMddHHmm.ss");
		SimpleDateFormat syslogformatter = new SimpleDateFormat("yyyy MMM dd HH:mm:ss");
		
		// Parameters 
		// 1 - input file - ie syslog
		// 2 - output cal file.
		// 3 - keyword to start event.
		// 4 - keyword to stop event.
		// 5 - Event Summary Line

    	ICalendar iCal = new ICalendar();
    	iCal.icalEventCollection = new LinkedList();
    	iCal.setProdId("JICAL");
    	iCal.setVersion("2.0");
		int iCtr = 0;

		try
		{
			FileInputStream fin     = new FileInputStream(args[0]);
	        BufferedReader myInput = null;
	        
            myInput = new BufferedReader(new InputStreamReader(fin));
	        String buildLine        = null;
	        String thisLine = "";
	        Date startDate = null;
	        Date endDate = null;
	        /* Two loops, first joins lines together, second processes lines..
	         */
	        while((thisLine = myInput.readLine()) != null) 
	        {
	        	// Parse the syslog. If the right one comes up, create an event.
	        	 // This is the bit where we create a VEVENT!
	        	if (thisLine.indexOf(args[2]) != -1)
	        	{
	        		startDate = syslogformatter.parse("2004 "+thisLine.substring(0,15));
	        		System.out.println(thisLine);
	        	}
	        	
	        	if (thisLine.indexOf(args[3]) != -1
        			&& startDate != null)
	        	{
	        		endDate = syslogformatter.parse("2004 "+thisLine.substring(0,15));
	        		System.out.println(thisLine);
		            ICalendarVEvent vevent = new ICalendarVEvent();
		            
		        	Date workDate = new Date();
		        	
		        	vevent.setDateStart(startDate);
		        	vevent.setDateEnd(endDate);
		        	vevent.setSummary(args[4]);
		        	vevent.setDescription("");
		        	vevent.setSequence(0);
		        	vevent.setEventClass("PUBLIC");
		        	vevent.setTransparency("OPAQUE");
		    		vevent.setDateStamp(workDate);
		    		vevent.setCreated(workDate);
		    		vevent.setLastModified(workDate);
		    		//vevent.setAttach(photoFile.toURL().toString());
		    		vevent.setOrganizer("MAILTO:sfg@eurekait.com");
		    		iCtr++;
		    		//System.out.println(iCtr);
		        	vevent.setUid("jical-"+touchformatter.format(workDate)+"-"+iCtr);
		        	vevent.setPriority(3);
		        	
		        	//System.out.println(vevent.toVEvent());
		        	
		        	iCal.icalEventCollection.add(vevent);
		        	startDate = null;
	        	}
			
	        }
		}
		catch(Exception e)
		{
			e.printStackTrace();
	    	System.err.println("SomethingBad Happened:"+e);
		}
		
		
		try{

    	// Now write to string and view as file.
    	//System.out.println(iCal.getVCalendar());
    	
			BufferedWriter out = new BufferedWriter(new FileWriter(args[1]));
	        out.write(iCal.getVCalendar());
	        out.close();
			
		}
		catch (Exception e)
		{
			e.printStackTrace();
	    	System.err.println("SomethingBad Happened:"+e);
		}
    	
		//System.out.println("Rendered new SYSLOGICAL calendar file: "+args[1]);
			   
	}
}

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
import java.util.StringTokenizer;

/**
 * @author sfg
 *
 * TODO To change the template for this generated type comment go to
 * Window - Preferences - Java - Code Style - Code Templates
 */
public class Text2ICal {

	public static void main(String[] args) {
		
		SimpleDateFormat touchformatter = new SimpleDateFormat("yyyyMMddHHmm.ss");

		
		// Parameters 
		// 1 - input file - ie archlog
		// 2 - output cal file.
		// 3 - field=row/startcol/endcol/parseString,field=row/startcol/endcol/parseString,...etc
		// 4 - rows per event
		
		System.out.println("Input File is :"+args[0]);
		String inputFile = args[0];
		System.out.println("Output (Calendar) File is :"+args[1]);
		String outputFile = args[1];
		System.out.println("Field Details are  :"+args[2]);
		String fieldDetails= args[2];
		System.out.println("Rows per event is :"+args[3]);
		
		Integer rowsPerEvent= new Integer(args[3]);
		

    	ICalendar iCal = new ICalendar();
    	iCal.icalEventCollection = new LinkedList();
    	iCal.setProdId("JICAL-Text2ICal");
    	iCal.setVersion("2.0");
		int iCtr = 0;
		
		
		// First get the fields and locations.
		int row[] = new int[100];
		int col[] = new int[100];
		int endCol[] = new int[100];
		String iCalField[] = new String[100]; 
		String parseString[] = new String[100];
		
		int iFieldCtr = 0;
		StringTokenizer st = new StringTokenizer(args[2],",");
		while(st.hasMoreTokens())
		{
			String fieldDetail = (String)st.nextToken();
			StringTokenizer fdtok = new StringTokenizer(fieldDetail,"=");
			iCalField[iFieldCtr] = (String)fdtok.nextToken();
			String rowColStr = (String)fdtok.nextToken();
			StringTokenizer rowColTok = new StringTokenizer(rowColStr,"/");
			row[iFieldCtr] = new  Integer(rowColTok.nextToken()).intValue();
			col[iFieldCtr] = new  Integer(rowColTok.nextToken()).intValue();
			endCol[iFieldCtr] = new  Integer(rowColTok.nextToken()).intValue();
			if (rowColTok.hasMoreTokens())
				parseString[iFieldCtr] = (String)rowColTok.nextToken();

			iFieldCtr++;
		}
		
		System.out.println("Found "+iFieldCtr+ " fields");
		System.out.println("Import: "+args[0]);
		
		try
		{
			FileInputStream fin     = new FileInputStream(args[0]);
	        BufferedReader myInput = null;
	        
            myInput = new BufferedReader(new InputStreamReader(fin));
	        
	        String thisLine = "";
	        
	        int iRowCtr = 0;
	        // There had better be a parm 4!!
	        if (rowsPerEvent.intValue() == 0)
	        {
	        	System.err.println("You forgot parm 4 - rows per event");
	        	return;
	        }
	        String storeRow[] = new String[rowsPerEvent.intValue()+1];
	        /* Two loops, first joins lines together, second processes lines..
	         */
	        while((thisLine = myInput.readLine()) != null) 
	        {
	        	iRowCtr++;
	        	//System.out.println("ROW:"+thisLine);
	        	storeRow[iRowCtr] = thisLine;
	        	if (iRowCtr == rowsPerEvent.intValue())
	        	{
	        		// Here we are, create an event..
	        		ICalendarVEvent vevent = new ICalendarVEvent();
	        		//SimpleDateFormat syslogformatter = new SimpleDateFormat("yyyy MMM dd HH:mm:ss");
	        		for (int fieldIdx = 0;  fieldIdx < iFieldCtr; fieldIdx++)
	        		{
	        			Date workDate = new Date();
	        			// Extract required row for this field.
	        			String fieldValue =storeRow[row[fieldIdx]];
	        			//System.out.println("Row is:"+fieldValue);
	        			
	        			if (fieldValue.length() < col[fieldIdx]-1)
	        				System.err.println("Ick, line too short:" +fieldValue.length()+" col starts:"+col[fieldIdx]+ " for field val: "+fieldValue);
	        			else
        				if (endCol[fieldIdx]-1 > fieldValue.length()) 
        				{
        					//System.out.println("option1:"+col[fieldIdx]);
        					fieldValue = fieldValue.substring(col[fieldIdx]-1);
        				}
	        			else
	        			{
	        				//System.out.println("option2:"+col[fieldIdx]);
	        				fieldValue = fieldValue.substring(col[fieldIdx]-1,endCol[fieldIdx]-1);
	        			}
	        			
	        			//System.out.println("Field is :"+ iCalField[fieldIdx]+ " value is: "+fieldValue);
	        			
	        			// Process a field into the event.
	        			if (iCalField[fieldIdx].equalsIgnoreCase("startdate"))
	        			{
	        				// This should be done once only!
	        				//System.out.println("Parse this:"+fieldValue+ " with this" +parseString[fieldIdx]);
	        				SimpleDateFormat startDateFormatter = new SimpleDateFormat(parseString[fieldIdx]);
	        				//System.out.println("Parse this:"+fieldValue+ " with this" +parseString[fieldIdx]+" Parsed Results: "+startDateFormatter.parse(fieldValue));
	        				vevent.setDateStart(startDateFormatter.parse(fieldValue));
	        			}
	        			else
        				if (iCalField[fieldIdx].equalsIgnoreCase("enddate"))
	        			{
        					SimpleDateFormat endDateFormatter = new SimpleDateFormat(parseString[fieldIdx]);
        					//System.out.println("Parse this:"+fieldValue+ " with this" +parseString[fieldIdx]+" Parsed Results: "+endDateFormatter.parse(fieldValue));
        					vevent.setDateEnd(endDateFormatter.parse(fieldValue));
	        			}
        				else
        				if (iCalField[fieldIdx].equalsIgnoreCase("summary"))
	        			{
	        				vevent.setSummary(fieldValue);
	        			}
        				else if (iCalField[fieldIdx].equalsIgnoreCase("description"))
	        			{
        					vevent.setDescription(fieldValue);
	        			}
        				else 
        				{
        					System.err.println("Invalid field: "+iCalField[fieldIdx]);
						}
	        			
	        			if (vevent.getDateStart()!=null
    					&&  vevent.getDateEnd() !=null)
	        			{
	        				vevent.setSequence(0);
	    		        	vevent.setEventClass("PUBLIC");
	    		        	vevent.setTransparency("OPAQUE");
	    		    		vevent.setDateStamp(workDate);
	    		    		vevent.setCreated(workDate);
	    		    		vevent.setLastModified(workDate);
	    		    		//vevent.setAttach(photoFile.toURL().toString());
	    		    		vevent.setOrganizer("MAILTO:sfg@eurekait.com");
	    		    		iCtr++;
	    		    		System.out.println(iCtr);
	    		        	vevent.setUid("jical-"+touchformatter.format(workDate)+"-"+iCtr);
	    		        	vevent.setPriority(3);
	    		        	
	    		        	//System.out.println(vevent.toVEvent());
	
	    		        	iCal.icalEventCollection.add(vevent);
	        			}
	        		}
	        		iRowCtr = 0;
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
    	
		System.out.println("Rendered new TEXT2ICAL calendar file: "+args[1]);
			   
	}
}

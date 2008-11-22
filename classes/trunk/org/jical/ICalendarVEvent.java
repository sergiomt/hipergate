/*
 *
 * Created on August 3, 2002, 9:01 PM
 *
 * Stores an icalendar Time Zone as a java object.
 * There can be more than one iCal time zone per Calendar.
 * To make it easy, all times are recorded as GMT.
 *  
 */

package org.jical;

/**
 * 
 * @author sfg RFC 2445
 * @author David Wellington
 *  
 */

import java.io.ByteArrayInputStream;
import java.text.SimpleDateFormat;
import java.util.ArrayList;
import java.util.Calendar;
import java.util.Collection;
import java.util.Comparator;
import java.util.Date;
import java.util.GregorianCalendar;
import java.util.TimeZone;

import javax.xml.parsers.DocumentBuilder;
import javax.xml.parsers.DocumentBuilderFactory;

import org.w3c.dom.Document;
import org.w3c.dom.Node;
import org.w3c.dom.NodeList;

/**
 * @hibernate.class
 *     table="ICALVEVENT"
 *     dynamic-update="false"
 *     dynamic-insert="false"
 *
 * @hibernate.discriminator
 *     column="class"
 */

public class ICalendarVEvent implements Cloneable {

	private static SimpleDateFormat localDateFormatter = new SimpleDateFormat("yyyyMMdd'T'HHmmss");
	private static SimpleDateFormat formatter = new SimpleDateFormat("yyyyMMddHHmmss");
	private static final SimpleDateFormat VEVENTformatter = new SimpleDateFormat("yyyyMMdd'T'HHmmss'Z'");


	private Date 	dateStamp;
	private String 	organizer;
	private String  organizerEmail;
	private Date 	created;
	private Date 	lastModified;
	private int 	priority;
	private String  attach;
	private String  location;
	private String  percentComplete;
	private String  status;
	private String  comment;
	private boolean recurrenceId;
	private String url;
	private String geo;
	private float  geoX;
	private float  geoY;
	private String resources;
	private String contact;
	private String relatedTo;
	private String requestStatus;
	
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

    private String transparency;

   /**
    *
    * @hibernate.property
    *     column="TRANSPARENCY"
    *
    * @hibernate.column
    *     name="transparency"
    *     sql-type="VARCHAR(255)"
    *
    */

    public String getTransparency() {
        return this.transparency;
    }
    
    public void setTransparency(String transparency) {
        this.transparency = transparency;
    }
    
    private Date dateStart;
    
   /**
    *
    * @hibernate.property
    *     column="DATE_START"
    *
    * @hibernate.column
    *     name="dateStart"
    *     sql-type="TIMESTAMP"
    *
    */
    
    public Date getDateStart() {
        return this.dateStart;
    }
    
    public void setDateStart(Date dateStart) {
        this.dateStart = dateStart;
    }
    
    private Date dateEnd;

   /**
    *
    * @hibernate.property
    *     column="DATE_END"
    *
    * @hibernate.column
    *     name="dateEnd"
    *     sql-type="TIMESTAMP"
    *
    */

    public Date getDateEnd() {
        return this.dateEnd;
    }

    public void setDateEnd(Date dateEnd) {
        this.dateEnd = dateEnd;
    }
    
    private String duration;    

    /** Getter for property duration.
   /**
    *
    * @hibernate.property
    *     column="DURATION"
    *
    * @hibernate.column
    *     name="duration"
    *     sql-type="VARCHAR(255)"
    *
    */

    public String getDuration() {
        return this.duration;
    }

	public void setDuration(String duration) {
		this.duration = duration;
		/*
		 * Currently, use this duration to create a DateEnd. This is not optimal
		 * but works for Apple iCal and is strictly true.
		 */
		if (getDateStart() != null && getDateEnd() == null) {
			//System.err.println("Generating a DateEnd");
			// PT15M
			char durationArray[] = duration.substring(2).toCharArray();
			// Now read each char and build up numerics into a number and
			// non-numerics
			// indicate a unit of time. Convert all units of time into secs then
			// add
			// to the result.
			String timeBuilt = "";
			int totalSecs = 0;
			for (int ctr = 0; ctr < durationArray.length; ctr++) {
				String thisChar = String.valueOf(durationArray[ctr]);
				// Is this a number or a letter.
				int timeUnit = thisChar.indexOf("HMS");
				if (timeUnit != -1) {
					// This is a time unit! Multiply by seconds
					if (timeUnit == 0)
						totalSecs = totalSecs + Integer.parseInt(timeBuilt)
								* 3600;
					if (timeUnit == 1)
						totalSecs = totalSecs + Integer.parseInt(timeBuilt)
								* 60;
					if (timeUnit == 2)
						totalSecs = totalSecs + Integer.parseInt(timeBuilt);
					timeBuilt = "";
				} else {
					// Build up total time for time unit.
					timeBuilt = timeBuilt.concat(thisChar);
				}
			}
			// Now adjust the dateEnd to dateStart + secs.
			int dateRepeatUnit = Calendar.SECOND;
			Calendar workDateEnd = new GregorianCalendar();
			workDateEnd.setTime(getDateStart());
			workDateEnd.add(dateRepeatUnit, totalSecs);
			setDateEnd(workDateEnd.getTime());
		}
	}
    
    private String description;

   /**
    *
    * @hibernate.property
    *     column="DESCRIPTION"
    *
    * @hibernate.column
    *     name="description"
    *     sql-type="VARCHAR(255)"
    *
    */
    
    public String getDescription() {
        return this.description;
    }
    
    public void setDescription(String description) {
        this.description = description;
    }
    
    private String summary;

   /**
    *
    * @hibernate.property
    *     column="SUMMARY"
    *
    * @hibernate.column
    *     name="summary"
    *     sql-type="VARCHAR(255)"
    *
    */
    
    public String getSummary() {
        return this.summary;
    }
    
    public void setSummary(String summary) {
        this.summary = summary;
    }
    
    private int sequence;

   /**
    *
    * @hibernate.property
    *     column="SEQUENCE"
    *
    * @hibernate.column
    *     name="sequence"
    *     sql-type="INTEGER"
    *
    */
    
    public int getSequence() {
        return this.sequence;
    }
    
    public void setSequence(int sequence) {
        this.sequence = sequence;
    }
    
    private String categories;

   /**
    *
    * @hibernate.property
    *     column="CATEGORIES"
    *
    * @hibernate.column
    *     name="categories"
    *     sql-type="VARCHAR(255)"
    *
    */
    
    public String getCategories() {
        return this.categories;
    }
    
    public void setCategories(String categories) {
        this.categories = categories;
    }
    
    private String eventClass;

   /**
    *
    * @hibernate.property
    *     column="CLASS_OF_EVENT"
    *
    * @hibernate.column
    *     name="classOfEvent"
    *     sql-type="VARCHAR(255)"
    *
    */
    
    public String getEventClass() {
        return this.eventClass;
    }
    
    public void setEventClass(String eventClass) {
        this.eventClass = eventClass;
//System.err.println("icalevent>>" +eventClass);
    }
    
    private String rRule;

   /**
    *
    * @hibernate.property
    *     column="RRULE"
    *
    * @hibernate.column
    *     name="rrule"
    *     sql-type="VARCHAR(255)"
    *
    */

    public String getRRule() {
        return this.rRule;
    }
    
    public void setRRule(String rRule) {
        this.rRule = rRule;
    }

    private int repeatCount;

   /**
    *
    * @hibernate.property
    *     column="REPEAT_COUNT"
    *
    * @hibernate.column
    *     name="repeatCount"
    *     sql-type="INTEGER"
    *
    */
    
    public int getRepeatCount() {
        return this.repeatCount;
    }
    
    public void setRepeatCount(int repeatCount) {
        this.repeatCount = repeatCount;
    }

    public Collection exDateCollection;
    
    public Collection getExDateCollection() {
        return this.exDateCollection;
    }
    
    public void setExDateCollection(Collection exDateCollection) {
        this.exDateCollection = exDateCollection;
    }

    
    private boolean exDatesExist;

   /**
    *
    * @hibernate.property
    *     column="EXDATES_EXIST"
    *
    * @hibernate.column
    *     name="exDatesExist"
    *     sql-type="Boolean"
    *
    */
    
    public boolean isExDatesExist() {
        return this.exDatesExist;
    }
    
    public void setExDatesExist(boolean exDatesExist) {
        this.exDatesExist = exDatesExist;
    }

    /** Holds value of property repeatRules. */
    private RepeatRules repeatRules;

    /** Getter for property repeatRules.
     * @return Value of property repeatRules.
     *
     */
    public RepeatRules getRepeatRules() {
        return this.repeatRules;
    }
    
    /** Setter for property repeatRules.
     * @param repeatRules New value of property repeatRules.
     *
     */
    public void setRepeatRules(RepeatRules repeatRules) {
        this.repeatRules = repeatRules;
    }


    public ICalendarVEvent() {
        this.exDateCollection  = new ArrayList();
        this.eventClass = null;
        this.repeatCount = 0;
        this.repeatRules = new RepeatRules();
        this.categories = null;
        this.dateStart = null;
        this.dateEnd = null;
        this.description = null;
        this.duration = null;
        this.eventClass = null;
        this.exDatesExist = false;
        this.rRule = null;
        this.sequence = 0;
        this.summary = null;
        this.transparency = null;
        this.uid = null;
    }
    
    public ICalendarVEvent(Date dateStart, Date dateEnd, String description, String duration,
    		String summary, ArrayList exDates, RepeatRules repRules)
    {
		this.exDateCollection  = exDates;
		this.eventClass = null;
		this.repeatCount = 0;
		this.repeatRules = repRules;
		this.categories = null;
		this.dateStart = dateStart;
		this.dateEnd = dateEnd;
		this.description = description;
		this.duration = duration;
		this.eventClass = null;
		this.exDatesExist = false;
		this.rRule = null;
		this.sequence = 0;
		this.summary = summary;
		this.transparency = null;
		this.uid = null;
    }

	public Object clone() throws CloneNotSupportedException {
		return super.clone();
	}

	
	/*
	 * To VEVENT
	 * 
	 * 
	 * This will create a VEVENT if applicable.
	 * 
	 * Note there is plenty to be improved here. Not least the rule that wraps lines to 78 chars..
	 * 
	 * 
			BEGIN:VEVENT
			DTSTAMP:20041029T184718Z
			ORGANIZER:MAILTO:sfg@eurekait.com
			CREATED:20041029T021927Z
			UID:libkcal-2020175830.1064
			SEQUENCE:0
			LAST-MODIFIED:20041029T021927Z
			SUMMARY:Hibernate integrate to Claims
			CLASS:PUBLIC
			PRIORITY:3
			DTSTART:20041028T131500Z
			DTEND:20041028T223000Z
			TRANSP:OPAQUE
			END:VEVENT

	 * 
	 */
	public String toVEvent() {
		
		//VEVENTformatter.setTimeZone(TimeZone.getDefault().getTimeZone("GMT"));
		
		StringBuffer vEventBuffer = new StringBuffer();
		vEventBuffer.append(ICalUtil.makeVEventLines("BEGIN:VEVENT",""));
		vEventBuffer.append(ICalUtil.makeVEventLines("UID:",this.uid));
		vEventBuffer.append(ICalUtil.makeVEventLines("TRANSP:",this.transparency));
		vEventBuffer.append(ICalUtil.makeVEventLines("DTSTART;",getVEventLocalTime(this.dateStart)));
		vEventBuffer.append(ICalUtil.makeVEventLines("DTEND;",getVEventLocalTime(this.dateEnd)));
		vEventBuffer.append(ICalUtil.makeVEventLines("DTSTAMP:",VEVENTformatter.format(this.dateStamp)));
		vEventBuffer.append(ICalUtil.makeVEventLines("ORGANIZER:",this.organizer));
		vEventBuffer.append(ICalUtil.makeVEventLines("CREATED:",VEVENTformatter.format(this.created)));
		vEventBuffer.append(ICalUtil.makeVEventLines("LAST-MODIFIED:",VEVENTformatter.format(this.lastModified)));
		vEventBuffer.append(ICalUtil.makeVEventLines("SUMMARY:",this.summary));
		vEventBuffer.append(ICalUtil.makeVEventLines("DESCRIPTION:",this.description));
		vEventBuffer.append(ICalUtil.makeVEventLines("SEQUENCE:",new Integer(this.sequence).toString()));
		vEventBuffer.append(ICalUtil.makeVEventLines("CLASS:",this.eventClass));
		vEventBuffer.append(ICalUtil.makeVEventLines("ATTACH:",this.attach));
		vEventBuffer.append(ICalUtil.makeVEventLines("END:VEVENT",""));		
		
		return vEventBuffer.toString();
	}
	
	/*
	 * Make this locale dependent...
	 */
	public String getVEventLocalTime(Date localTime)
	{
		if (localTime!=null)
			return "VALUE=DATE-TIME;TZID=/softwarestudio.org/Olson_20011030_5/"+TimeZone.getDefault().getID()+":"+localDateFormatter.format(localTime);
		else
			return "";
	}
	
	/*
	 * To XML method Originally built so as to enable a collection of expanded
	 * dates to be created.
	 */
	
    public String toXML() {
        StringBuffer buffer = new StringBuffer();
        buffer.append("<vevent>");
        buffer.append("<uid>").append(this.uid).append("</uid>");
        // Only add element if it has a value
        if ( this.transparency != null && this.transparency.length() > 0) {
            buffer.append("<transparency>");
            buffer.append(this.transparency);
            buffer.append("</transparency>");
        }
        // Add new elements for additional iCal fields added
        if ( this.location != null && this.location.length() > 0) {
            buffer.append("<location>");
            buffer.append("<![CDATA[");
            buffer.append(this.location);
            buffer.append("]]>");
            buffer.append("</location>");
        }
        if ( this.url != null && this.url.length() > 0) {
            buffer.append("<url>");
            buffer.append(this.url);
            buffer.append("</url>");
        }
        if ( this.organizer != null && this.organizer.length() > 0) {
            buffer.append("<organizer>");
            buffer.append(this.organizer);
            buffer.append("</organizer>");
        }
        if ( this.organizerEmail != null && this.organizerEmail.length() > 0) {
            buffer.append("<organizeremail>");
            buffer.append("<![CDATA[");
            buffer.append(this.organizerEmail);
            buffer.append("]]>");
            buffer.append("</organizeremail>");
        }
        if ( getStatus() != null && getStatus().length() > 0) {
            buffer.append("<status>");
            buffer.append(getStatus());
            buffer.append("</status>");
        }
        buffer.append("<datestart>");
        if ( this.dateStart != null )
            buffer.append(formatter.format(this.dateStart));
        buffer.append("</datestart>");
        buffer.append("<dateend>");
        if ( this.dateEnd != null )
            buffer.append(formatter.format(this.dateEnd));
        buffer.append("</dateend>");

        if ( this.description != null && this.description.length() > 0) {
            buffer.append("<description>");
            buffer.append("<![CDATA[").append(this.description).append("]]>");
            buffer.append("</description>");
        }
        buffer.append("<summary>");
        if ( this.summary != null )
            buffer.append("<![CDATA[").append(this.summary).append("]]>");
        buffer.append("</summary>");
        buffer.append("<sequence>");
        if ( java.lang.Integer.toString(this.sequence) != null )
            buffer.append(java.lang.Integer.toString(this.sequence));
        buffer.append("</sequence>");
        if ( this.categories != null && this.categories.length() > 0) {
            buffer.append("<categories>");
            buffer.append(this.categories);
            buffer.append("</categories>");
        }
        if ( this.eventClass != null && this.eventClass.length() > 0) {
            buffer.append("<eventclass>");
            buffer.append(this.eventClass);
            buffer.append("</eventclass>");
        }
        buffer.append("</vevent>");
        return buffer.toString();
    }	


	/*
	 * Reads XML back into event class Originally built so as to enable a
	 * collection of expanded dates to be created.
	 */
	public void fromXML(String inXML) {
		try {
			DocumentBuilderFactory docuBuilderFactory = DocumentBuilderFactory
					.newInstance();
			docuBuilderFactory.setValidating(false);
			DocumentBuilder docuBuilder = docuBuilderFactory
					.newDocumentBuilder();
			ByteArrayInputStream bais = new ByteArrayInputStream(inXML
					.getBytes());
			Document doc = docuBuilder.parse(bais);
			NodeList nl = doc.getFirstChild().getChildNodes();

			for (int ctr = 0; ctr < nl.getLength(); ctr++) {
				Node ni = nl.item(ctr);
				//                System.err.println("ctr:" +ctr);
				String nodeName = ni.getNodeName();
				Node nodeChild = ni.getFirstChild();
				String nodeValue = "";
				try {
					nodeValue = nodeChild.getNodeValue();
				} catch (Exception e) {
					// Ignore catch, process next.. as NULL
				}
				//                System.err.println("Node/Value:" +nodeName +nodeValue);
				if (nodeValue != null) {
					if (nodeName.equals("uid"))
						this.setUid(nodeValue);
					else if (nodeName.equals("transparency"))
						this.setTransparency(nodeValue);
					else if (nodeName.equals("datestart"))
						this.setDateStart((Date) formatter.parse(nodeValue));
					else if (nodeName.equals("dateend"))
						this.setDateEnd((Date) formatter.parse(nodeValue));
					else if (nodeName.equals("description"))
						this.setDescription(nodeValue);
					else if (nodeName.equals("summary"))
						this.setSummary(nodeValue);
					else if (nodeName.equals("categories"))
						this.setCategories(nodeValue);
					else if (nodeName.equals("eventclass"))
						this.setEventClass(nodeValue);
					// Add new iCal fields
					else if (nodeName.equals("location"))
				        this.setLocation(nodeValue);
					else if (nodeName.equals("url"))
					    this.setUrl(nodeValue);
					else if (nodeName.equals("organizer"))
					    this.setOrganizer(nodeValue);
					else if (nodeName.equals("organizeremail"))
					    this.setOrganizerEmail(nodeValue);
					else if (nodeName.equals("status"))
				        this.setPercentComplete(nodeValue);					
				}
			}
		} catch (Exception e) {
			System.err.println("XML Parser exception: fromXML:" + e);
		}
	}


	public boolean equals(Object o) {
		if (o instanceof ICalendarVEvent) {
			ICalendarVEvent e = (ICalendarVEvent) o;
			return uid.equals(e.uid) && dateStart.equals(e.dateStart)
					&& dateEnd.equals(e.dateEnd);
		}
		return false;
	}

	public int hashCode() {
		return uid.hashCode() ^ dateStart.hashCode() ^ dateEnd.hashCode();
	}

	public static class StartDateComparator implements Comparator {
		public int compare(Object o1, Object o2) {
			ICalendarVEvent e1 = (ICalendarVEvent) o1;
			ICalendarVEvent e2 = (ICalendarVEvent) o2;
			return e1.getDateStart().compareTo(e2.getDateStart());
		}

		public boolean equals(Object obj) {
			return (obj instanceof StartDateComparator);
		}
	}

	public static class StartDateUIDComparator implements Comparator {
		public int compare(Object o1, Object o2) {
			ICalendarVEvent e1 = (ICalendarVEvent) o1;
			ICalendarVEvent e2 = (ICalendarVEvent) o2;
			int out = e1.getDateStart().compareTo(e2.getDateStart());
			if (out == 0) {
				out = e1.getUid().compareTo(e2.getUid());
			}
			return out;
		}

		public boolean equals(Object obj) {
			return (obj instanceof StartDateUIDComparator);
		}
	}

   /**
    *
    * @hibernate.property
    *     column="DATE_CREATED"
    *
    * @hibernate.column
    *     name="created"
    *     sql-type="TIMESTAMP"
    *
    */
	public Date getCreated() {
		return created;
	}
	public void setCreated(Date created) {
		this.created = created;
	}
    /**
    *
    * @hibernate.property
    *     column="DATE_STAMP"
    *
    * @hibernate.column
    *     name="dateStamp"
    *     sql-type="TIMESTAMP"
    *
    */
	public Date getDateStamp() {
		return dateStamp;
	}
	public void setDateStamp(Date dateStamp) {
		this.dateStamp = dateStamp;
	}
	 /**
    *
    * @hibernate.property
    *     column="LAST_MODIFIED"
    *
    * @hibernate.column
    *     name="lastModified"
    *     sql-type="TIMESTAMP"
    *
    */
	public Date getLastModified() {
		return lastModified;
	}
	public void setLastModified(Date lastModified) {
		this.lastModified = lastModified;
	}
	 /**
    *
    * @hibernate.property
    *     column="ORGANIZER"
    *
    * @hibernate.column
    *     name="organizer"
    *     sql-type="VARCHAR"
    *
    */
	public String getOrganizer() {
		return organizer;
	}
	public void setOrganizer(String organizer) {
		this.organizer = organizer;
	}

   /**
    *
    * @hibernate.property
    *     column="PRIORITY"
    *
    * @hibernate.column
    *     name="priority"
    *     sql-type="INTEGER"
    *
    */
	public int getPriority() {
		return priority;
	}
	public void setPriority(int priority) {
		this.priority = priority;
	}
	/**
    *
    * @hibernate.property
    *     column="ATTACH"
    *
    * @hibernate.column
    *     name="attach"
    *     sql-type="VARCHAR(255)"
    *
    */
	public String getAttach() {
		return attach;
	}
	public void setAttach(String attach) {
		this.attach = attach;
	}
	/**
    *
    * @hibernate.property
    *     column="LOCATION"
    *
    * @hibernate.column
    *     name="location"
    *     sql-type="VARCHAR(255)"
    *
    */
	public String getLocation() {
		return location;
	}
	public void setLocation(String location) {
		this.location = location;
	}
	/**
    *
    * @hibernate.property
    *     column="PERCENTCOMPLETE"
    *
    * @hibernate.column
    *     name="percentComplete"
    *     sql-type="VARCHAR(255)"
    *
    */
	public String getPercentComplete() {
		return percentComplete;
	}
	public void setPercentComplete(String percentComplete) {
		this.percentComplete = percentComplete;
	}
	public boolean isRecurrenceId() {
		return recurrenceId;
	}
	public void setRecurrenceId(boolean recurrenceId) {
		this.recurrenceId = recurrenceId;
	}
	/**
    *
    * @hibernate.property
    *     column="URL"
    *
    * @hibernate.column
    *     name="url"
    *     sql-type="VARCHAR(255)"
    *
    */
	public String getUrl() {
		return url;
	}
	public void setUrl(String url) {
		this.url = url;
	}
	/**
    *
    * @hibernate.property
    *     column="ORGANISEREMAIL"
    *
    * @hibernate.column
    *     name="organizerEmail"
    *     sql-type="VARCHAR(255)"
    *
    */
	public String getOrganizerEmail() {
		return organizerEmail;
	}
	public void setOrganizerEmail(String organizerEmail) {
		this.organizerEmail = organizerEmail;
	}
	public String getStatus()
	{
		return status;
	}
	public void setStatus(String s)
	{
		status = s;
	}
	
	public String getComment() {
		return comment;
	}
	public void setComment(String comment) {
		this.comment = comment;
	}
	public String getGeo() {
		return geo;
	}
	public void setGeo(String geo) {
		this.geo = geo;
	}
	public float getGeoX() {
		return geoX;
	}
	public void setGeoX(float geoX) {
		this.geoX = geoX;
	}
	public float getGeoY() {
		return geoY;
	}
	public void setGeoY(float geoY) {
		this.geoY = geoY;
	}
	public String getResources() {
		return resources;
	}
	public void setResources(String resources) {
		this.resources = resources;
	}
	public String getContact() {
		return contact;
	}
	public void setContact(String contact) {
		this.contact = contact;
	}
	public String getRelatedTo() {
		return relatedTo;
	}
	public void setRelatedTo(String relatedTo) {
		this.relatedTo = relatedTo;
	}
	public String getRequestStatus() {
		return requestStatus;
	}
	public void setRequestStatus(String requestStatus) {
		this.requestStatus = requestStatus;
	}
}


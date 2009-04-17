/*
  Copyright (C) 2003-2005  Know Gate S.L. All rights reserved.
                           C/Oña, 107 1º2 28050 Madrid (Spain)
cm
  Redistribution and use in source and binary forms, with or without
  modification, are permitted provided that the following conditions
  are met:

  1. Redistributions of source code must retain the above copyright
     notice, this list of conditions and the following disclaimer.

  2. The end-user documentation included with the redistribution,
     if any, must include the following acknowledgment:
     "This product includes software parts from hipergate
     (http://www.hipergate.org/)."
     Alternately, this acknowledgment may appear in the software itself,
     if and wherever such third-party acknowledgments normally appear.

  3. The name hipergate must not be used to endorse or promote products
     derived from this software without prior written permission.
     Products derived from this software may not be called hipergate,
     nor may hipergate appear in their name, without prior written
     permission.

  This library is distributed in the hope that it will be useful,
  but WITHOUT ANY WARRANTY; without even the implied warranty of
  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.

  You should have received a copy of hipergate License with this code;
  if not, visit http://www.hipergate.org or mail to info@hipergate.org
*/

package com.knowgate.hipergate;

import java.util.ArrayList;
import java.util.Iterator;

import com.knowgate.debug.DebugFile;
import com.knowgate.misc.Gadgets;

/**
 * hipergate menu option JiBX handler
 * @author Sergio Montoro Ten
 * @version 1.1
 */
public class MenuOption {

  private String name;
  private String mask;
  private String title;
  private String href;
  private String forbid;
  private boolean access;
  private boolean selected;
  private ArrayList suboptions;

  // ---------------------------------------------------------------------------

  /**
   * Default constructor
   */
  public MenuOption() {
    mask = "0";
    forbid = href = title = name = null;
    selected = access = false;
    suboptions = new ArrayList();
  }

  // ---------------------------------------------------------------------------

  /**
   * Get suboption
   * @param nIndex int Suboption index [0..countSubOptions()-1)
   * @return MenuOption
   * @throws ArrayIndexOutOfBoundsException if n<0 or n>=countSubOptions()
   */
  public MenuOption getSubOption(int nIndex) throws ArrayIndexOutOfBoundsException {
    return (MenuOption) suboptions.get(nIndex);
  }

  // ---------------------------------------------------------------------------

  /**
   * Get suboption by name
   * @param sname String Suboption name
   * @return MenuOption
   * @throws ArrayIndexOutOfBoundsException if no option with such name was found
   */
  public MenuOption getSubOption(String sName) throws ArrayIndexOutOfBoundsException {
    final int nOptCount = countSubOptions();
    for (int o=0;o<nOptCount;o++) {
      if (((MenuOption)suboptions.get(o)).getName().equalsIgnoreCase(sName))
        return (MenuOption) suboptions.get(o);
    } // next
    throw new ArrayIndexOutOfBoundsException(sName + " menu option not found");
  }

  // ---------------------------------------------------------------------------

  /**
   * Get count of suboptions
   * @return int
   */
  public int countSubOptions() {
    return suboptions.size();
  }

  // ---------------------------------------------------------------------------

  /**
   * Get this option name
   * @return String
   */
  public String getName() {
    return name;
  }

  // ---------------------------------------------------------------------------

  /**
   * <p>Get this option permissions mask</p>
   * The mask is an Integer value between 0 and 31 or an ArrayList of Integer values or a String either "admin" or "owner"
   * @return Object May be a String (either "admin" or "owner") or an Integer or <b>null</b>
   * @throws NumberFormatException If mask value is neither "admin" nor "owner" and it is
   * not an integer value.
   */
  public Object getMask() throws NumberFormatException {
    if (null==mask)
      return null;
    else if (mask.length()==0)
      return null;
    else if (mask.equalsIgnoreCase("admin"))
      return "admin";
    else if (mask.equalsIgnoreCase("owner"))
      return "owner";
    else if (mask.indexOf(",")>0) {
      String[] aMask = Gadgets.split(mask,',');
      ArrayList oMask = new ArrayList(aMask.length);
      for (int m=0; m<aMask.length; m++)
        oMask.add(new Integer(aMask[m]));
      return oMask;
    } else
      return new Integer(mask);
  } // getMask

  // ---------------------------------------------------------------------------

  /**
   * <p>Get permissions mask encoded as a 32bit integer</p>
   * @return int If mask is empty string or null Then return value is zero,
   * If mask is "admin" or "owner" Then return value is -1
   * Else the return value is 1<<mask
   * If mask has multiple values delmited by commas then the returned value
   * is the bitwise OR of all values 1<<mask[0] | 1<<mask[1] | 1<<mask[2] ...
   */
  public int getBitMask() {
    int iMask;
    if (null==mask)
      return 0;
    else if (mask.equalsIgnoreCase("admin") || mask.equalsIgnoreCase("owner"))
      return -1;
    else if (mask.indexOf(",")>0) {
      String[] aMask = Gadgets.split(mask,',');
      iMask = 0;
      for (int m=0; m<aMask.length; m++)
        iMask |= 1<<Integer.parseInt(aMask[m]);
      return iMask;
    } else {
      try {
        iMask=1<<Integer.parseInt(mask);
      }
      catch (NumberFormatException ignore) {
        if (DebugFile.trace) DebugFile.writeln("MenuOption.getBitMask() NumberFormatException "+mask);
        iMask=0;
      }
      return iMask;
    }
  } // getBitMask

  // ---------------------------------------------------------------------------

  /**
   * <p>Determine access to this menu option for an application mask</p>
   * Get whether or not a user with the given application mask and roles can
   * access this menu option. Application Masks are 32 bit integers with one
   * bit flags per application.<br>
   * <table><tr><td colspan="3"><b>Standard application masks</b></td></tr>
   * <tr><td><b>Application</b></td><td>Bit Position</td><td>Int Mask</td></tr>
   * <tr><td>Bug Tracker</td><td>10</td><td>1024</td></tr>
   * <tr><td>Duty Manager</td><td>11</td><td>1024</td></tr>
   * <tr><td>Project Manager</td><td>12</td><td>4096</td></tr>
   * <tr><td>Mailwire</td><td>13</td><td>8192</td></tr>
   * <tr><td>Web Builder</td><td>14</td><td>16384</td></tr>
   * <tr><td>Virtual Disk</td><td>15</td><td>32768</td></tr>
   * <tr><td>Sales</td><td>16</td><td>65536</td></tr>
   * <tr><td>Collaborative Tools</td><td>17</td><td>131072</td></tr>
   * <tr><td>Marketing Tools</td><td>18</td><td>262144</td></tr>
   * <tr><td>Directory</td><td>19</td><td>524288</td></tr>
   * <tr><td>Shop</td><td>20</td><td>1048576</td></tr>
   * <tr><td>Hipermail</td><td>21</td><td>2097152</td></tr>
   * <tr><td>Training</td><td>22</td><td>4194304</td></tr>
   * <tr><td>Surveys</td><td>23</td><td>8388608</td></tr>
   * <tr><td>Configuration</td><td>30</td><td>1073741824</td></tr>
   * </table>
   * @param iAppMask int Application mask
   * @param bAdmin boolean <b>true</b> if user has administrator role
   * @param bOwner boolean <b>true</b> if user is owner of his WorkArea
   * @return boolean <b>true</b> if user is administrator or owner and mask is
   * "admin" or "owner" respectively. Or <b>true</b> if getBitMask() bitwise-and iAppMask
   * is not zero (getBitMask()&iAppMask!=0).
   */
  public boolean hasAccess(int iAppMask, boolean bAdmin, boolean bOwner) {
    if (DebugFile.trace) DebugFile.writeln("Begin MenuOption.hasAccess("+
                                           String.valueOf(iAppMask)+","+
                                           String.valueOf(bAdmin)+","+
                                           String.valueOf(bOwner)+")");
    final int iBitMask = getBitMask();
    boolean bRetVal;
    if (0==iBitMask) {
      bRetVal = true;
    }
    else if (-1==iBitMask) {
      if (DebugFile.trace) DebugFile.writeln("  mask="+mask);
      bRetVal = (mask.equalsIgnoreCase("admin") && bAdmin) || (mask.equalsIgnoreCase("owner") && bOwner);
    } else {
      if (DebugFile.trace) DebugFile.writeln("  bitmask="+String.valueOf(iBitMask));
      bRetVal = ((iBitMask&iAppMask)!=0);
    }
    if (DebugFile.trace) DebugFile.writeln("End MenuOption.hasAccess() : "+String.valueOf(bRetVal));
    return bRetVal;
  } // hasAccess

  // ---------------------------------------------------------------------------

  /**
   * Get menu option title
   * @return String &lt;title&gt; tag value or empty string if title is not set
   */
  public String getTitle() {
    if (null!=title)
      return title;
    else
      return "";
  }

  // ---------------------------------------------------------------------------

  /**
   * Get menu option href
   * @return String &lt;href&gt; tag value or empty string if href is not set
   */
  public String getHRef() {
    if (null!=href)
      return href;
    else
      return "";
  }

  // ---------------------------------------------------------------------------

  /**
   * Get menu option alternative href used when a user has not enought permissions
   * to access standard href. Whether to use href or forbid must be determined by
   * the caller program at runtime.
   * @return String &lt;forbid&gt; tag value or empty string if forbid is not set
   */
  public String getForbid() {
    if (null!=forbid)
      return forbid;
    else
      return "";
  }

  // ---------------------------------------------------------------------------
  
  /**
   * <p>Get if a user must see this menu option</p>
   * Access is an externaly set flag to signal whether or not a user can see this menu option,
   * access is not set at the XML configuration file, but usually set by calling hasAccess()
   * @return boolean
   * @since 4.0
   */
  public boolean getAccess() {
    return access;
  }

  // ---------------------------------------------------------------------------

  /**
   * <p>Set if a user must see this menu option</p>
   * @param boolean
   * @since 4.0
   */
  public void setAccess(boolean bHasAcess) {
    access=bHasAcess;
  }

  // ---------------------------------------------------------------------------

  public boolean getSelected() {
    return selected;
  }

  // ---------------------------------------------------------------------------

  public void setSelected(boolean bIsSelected) {
    selected=bIsSelected;
  }

  // ---------------------------------------------------------------------------

  public void selectSubOption(int nSubOption) {
    final int nSubOpts = suboptions.size();
    for (int o=0; o<nSubOpts; o++) {
      ((MenuOption) suboptions.get(o)).setSelected(0==nSubOption);
    } // next
  } // selectSubOption

  // ---------------------------------------------------------------------------
  
  /**
   * <p>Get XML for menu option</p>
   * The returned XML is like &lt;option name="hipermail" access="false" selected="false"&gt;&lt;mask/&gt;&lt;title&gt;&lt;![CDATA[e-mail]]&gt;&lt;/title&gt;&lt;href&gt;../hipermail/mail_top_f.htm?selected=1&amp;subselected=0&lt;/href&gt;&lt;forbid&gt;&lt;![CDATA[javascript:alert('e-mail is disabled, please edit hipergate.cnf for activating it')]]&gt;&lt;/forbid&gt;&lt;suboptions/&gt;&lt;/option&gt;
   * @return String
   * @since 4.0
   */
  public String toXML() {
    StringBuffer oXML;
    if (suboptions.size()==0)
      oXML = new StringBuffer(1024);
    else
      oXML = new StringBuffer(6144);
	oXML.append("<option name=\"");
	oXML.append(getName());
	oXML.append("\" access=\"");
	oXML.append(getAccess());
	oXML.append("\" selected=\"");
	oXML.append(getSelected());
	oXML.append("\">\n");
	Object oMsk = getMask();
	if (null==oMsk)
	  oXML.append("<mask/>");
	else
	  oXML.append("<mask>"+oMsk.toString()+"</mask>");
	oXML.append("<title><![CDATA[");
	oXML.append(getTitle());
	oXML.append("]]></title>");
	oXML.append("<href>");
	oXML.append(getHRef());
	oXML.append("</href>");
	if (getForbid().length()==0)
	  oXML.append("<forbid/>");
	else
	  oXML.append("<forbid><![CDATA["+getForbid()+"]]></forbid>");
    if (suboptions.size()==0) {
	  oXML.append("<suboptions count=\"0\" />");
    } else {
	  oXML.append("<suboptions count=\""+String.valueOf(suboptions.size())+"\">\n");
	  Iterator iter = suboptions.iterator();
	  while (iter.hasNext()) {
	    MenuOption opt = (MenuOption) iter.next();
	    oXML.append(opt.toXML());
	    oXML.append("\n");
	  } // wend
	  oXML.append("</suboptions>\n");
	} // fi
	oXML.append("</option>");
    return oXML.toString();
  } // toXML

}

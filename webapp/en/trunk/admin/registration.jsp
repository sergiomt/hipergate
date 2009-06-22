<%@ page import="com.knowgate.dataobjs.*" language="java" session="false" contentType="text/html;charset=UTF-8" %><% 
/*
  Copyright (C) 2008  Know Gate S.L. All rights reserved.
                      C/Oña, 107 1º2 28050 Madrid (Spain)

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
%>

<HTML>
<HEAD>
  <META HTTP-EQUIV="Content-Type" CONTENT="text/html; charset=UTF-8">
  <SCRIPT LANGUAGE="JavaScript" TYPE="text/javascript" SRC="../javascript/cookies.js"></SCRIPT>  
  <SCRIPT LANGUAGE="JavaScript" TYPE="text/javascript" SRC="../javascript/setskin.js"></SCRIPT>
  <SCRIPT LANGUAGE="JavaScript" TYPE="text/javascript" SRC="../javascript/email.js"></SCRIPT>
  <SCRIPT LANGUAGE="JavaScript" TYPE="text/javascript">
    <!--

      // ----------------------------------------------------

      var intervalId;
      var winclone;

      // This function is called every 100 miliseconds for testing
      // whether or not e-mail lookup request has finished.
      
        function readLookUpResults() {
        
          if (winclone.closed) {
            clearInterval(intervalId);
            setCombo(document.forms[0].sel_searched, "<%=DB.nm_legal%>");
            document.forms[0].find.value = jsInstanceNm;
            findInstance();
          }
        } // findCloned()

      function checkEMail() {
      	ver eml = document.forms[0].tx_email;
      	
        if (!check_email(eml.value)) {
        	document.getElementById("emailmsg").innerHTML = "[~La dirección de e-mail no es válida~]";        	
        } else {
        	window.parent.hiddenframe.location = "check_email_registration.jsp"
        }
      }
    //-->
  </SCRIPT>
</HEAD>
<BODY >
<TABLE WIDTH="98%"><TR><TD CLASS="striptitle"><FONT CLASS="title1">[~Registro de producto~]</FONT></TD></TR></TABLE> 
<BR>
<TABLE>
  <TR>
    <TD COLSPAN="3" CLASS="textplain">
      [~Para mejorar nuestra capacidad de darle servicio, le sugerimos que registre gratuitamente su copia de hipergate.~]
      <BR/>
      [~Puede consultar los términos del registro en nuestra~]&nbsp;<A CLASS="linkplain" HREF="../common/privacy.htm">[~Pol&iacute;tica de Privacidad~]</A>
    </TD>
  </TR>
  <TR>
    <TD CLASS="textstrong">[~E-mail~]</TD>
    <TD><INPUT TYPE="text" MAXLENGTH="100" SIZE="50" STYLE="text-transform:lowercase" NAME="tx_email" onblur="checkEMail()"></TD>
    <TD><DIV ID="emailmsg"></TD>
  </TR>
  <TR>
    <TD CLASS="textstrong">Country</TD>
    <TD><SELECT NAME="id_country"></SELECT></TD>
    <TD><DIV ID="countrymsg"></TD>
  </TR>
  <TR>
    <TD CLASS="textplain">[~Estado/Provincia~]</TD>
    <TD CLASS="textplain"><INPUT TYPE="text" MAXLENGTH="30" SIZE="20" NAME="nm_state">&nbsp;&nbsp;&nbsp;[~C&oacute;digo Postal~]&nbsp;<INPUT TYPE="text" MAXLENGTH="16" SIZE="10" NAME="zipcode"></TD>
    <TD><DIV ID="statemsg"></TD>
  </TR>
  <TR>
    <TD CLASS="textstrong">[~Nombre~]</TD>
    <TD><INPUT TYPE="text" MAXLENGTH="100" SIZE="50" NAME="tx_name"></TD>
    <TD><DIV ID="namemsg"></TD>
  </TR>
  <TR>
    <TD CLASS="textstrong">[~Apellidos~]</TD>
    <TD><INPUT TYPE="text" MAXLENGTH="100" SIZE="50" NAME="tx_surname"></TD>
    <TD><DIV ID="surnamemsg"></TD>
  </TR>
  <TR>
    <TD CLASS="textplain">[~Te&eacute;fono~]</TD>
    <TD><INPUT TYPE="text" MAXLENGTH="16" SIZE="16" NAME="work_phone"></TD>
    <TD></TD>
  </TR>
  <TR>
    <TD CLASS="textplain">[~Empresa~]</TD>
    <TD><INPUT TYPE="text" MAXLENGTH="70" SIZE="50" NAME="nm_company"></TD>
    <TD></TD>
  </TR>
  <TR>
    <TD CLASS="textplain">[~Empleados~]</TD>
    <TD><SELECT NAME="nu_employees"></SELECT></TD>
    <TD></TD>
  </TR>
  <TR>
    <TD CLASS="textplain">[~Sector~]</TD>
    <TD><SELECT NAME="id_sector">
          <OPTION VALUE="" selected>[~Escoger sector...~]</OPTION><OPTION VALUE="47" class="corp fin">Accounting</OPTION><OPTION VALUE="94" class="man tech tran">Airlines/Aviation</OPTION><OPTION VALUE="120" class="leg org">Alternative Dispute Resolution</OPTION><OPTION VALUE="125" class="hlth">Alternative Medicine</OPTION><OPTION VALUE="127" class="art med">Animation</OPTION><OPTION VALUE="19" class="good">Apparel &amp; Fashion</OPTION><OPTION VALUE="50" class="cons">Architecture &amp; Planning</OPTION><OPTION VALUE="111" class="art med rec">Arts and Crafts</OPTION><OPTION VALUE="53" class="man">Automotive</OPTION><OPTION VALUE="52" class="gov man">Aviation &amp; Aerospace</OPTION><OPTION VALUE="41" class="fin">Banking</OPTION><OPTION VALUE="12" class="gov hlth tech">Biotechnology</OPTION><OPTION VALUE="36" class="med rec">Broadcast Media</OPTION><OPTION VALUE="49" class="cons">Building Materials</OPTION><OPTION VALUE="138" class="corp man">Business Supplies and Equipment</OPTION><OPTION VALUE="129" class="fin">Capital Markets</OPTION><OPTION VALUE="54" class="man">Chemicals</OPTION><OPTION VALUE="90" class="org serv">Civic &amp; Social Organization</OPTION><OPTION VALUE="51" class="cons gov">Civil Engineering</OPTION><OPTION VALUE="128" class="cons corp fin">Commercial Real Estate</OPTION><OPTION VALUE="118" class="tech">Computer &amp; Network Security</OPTION><OPTION VALUE="109" class="med rec">Computer Games</OPTION><OPTION VALUE="3" class="tech">Computer Hardware</OPTION><OPTION VALUE="5" class="tech">Computer Networking</OPTION><OPTION VALUE="4" class="tech">Computer Software</OPTION><OPTION VALUE="48" class="cons">Construction</OPTION><OPTION VALUE="24" class="good man">Consumer Electronics</OPTION><OPTION VALUE="25" class="good man">Consumer Goods</OPTION><OPTION VALUE="91" class="org serv">Consumer Services</OPTION><OPTION VALUE="18" class="good">Cosmetics</OPTION><OPTION VALUE="65" class="agr">Dairy</OPTION><OPTION VALUE="1" class="gov tech">Defense &amp; Space</OPTION><OPTION VALUE="99" class="art med">Design</OPTION><OPTION VALUE="69" class="edu">Education Management</OPTION><OPTION VALUE="132" class="edu org">E-Learning</OPTION><OPTION VALUE="112" class="good man">Electrical/Electronic Manufacturing</OPTION><OPTION VALUE="28" class="med rec">Entertainment</OPTION><OPTION VALUE="86" class="org serv">Environmental Services</OPTION><OPTION VALUE="110" class="corp rec serv">Events Services</OPTION><OPTION VALUE="76" class="gov">Executive Office</OPTION><OPTION VALUE="122" class="corp serv">Facilities Services</OPTION><OPTION VALUE="63" class="agr">Farming</OPTION><OPTION VALUE="43" class="fin">Financial Services</OPTION><OPTION VALUE="38" class="art med rec">Fine Art</OPTION><OPTION VALUE="66" class="agr">Fishery</OPTION><OPTION VALUE="34" class="rec serv">Food &amp; Beverages</OPTION><OPTION VALUE="23" class="good man serv">Food Production</OPTION><OPTION VALUE="101" class="org">Fund-Raising</OPTION><OPTION VALUE="26" class="good man">Furniture</OPTION><OPTION VALUE="29" class="rec">Gambling &amp; Casinos</OPTION><OPTION VALUE="145" class="cons man">Glass, Ceramics &amp; Concrete</OPTION><OPTION VALUE="75" class="gov">Government Administration</OPTION><OPTION VALUE="148" class="gov">Government Relations</OPTION><OPTION VALUE="140" class="art med">Graphic Design</OPTION><OPTION VALUE="124" class="hlth rec">Health, Wellness and Fitness</OPTION><OPTION VALUE="68" class="edu">Higher Education</OPTION><OPTION VALUE="14" class="hlth">Hospital &amp; Health Care</OPTION><OPTION VALUE="31" class="rec serv tran">Hospitality</OPTION><OPTION VALUE="137" class="corp">Human Resources</OPTION><OPTION VALUE="134" class="corp good tran">Import and Export</OPTION><OPTION VALUE="88" class="org serv">Individual &amp; Family Services</OPTION><OPTION VALUE="147" class="cons man">Industrial Automation</OPTION><OPTION VALUE="84" class="med serv">Information Services</OPTION><OPTION VALUE="96" class="tech">Information Technology and Services</OPTION><OPTION VALUE="42" class="fin">Insurance</OPTION><OPTION VALUE="74" class="gov">International Affairs</OPTION><OPTION VALUE="141" class="gov org tran">International Trade and Development</OPTION><OPTION VALUE="6" class="tech">Internet</OPTION><OPTION VALUE="45" class="fin">Investment Banking</OPTION><OPTION VALUE="46" class="fin">Investment Management</OPTION><OPTION VALUE="73" class="gov leg">Judiciary</OPTION><OPTION VALUE="77" class="gov leg">Law Enforcement</OPTION><OPTION VALUE="9" class="leg">Law Practice</OPTION><OPTION VALUE="10" class="leg">Legal Services</OPTION><OPTION VALUE="72" class="gov leg">Legislative Office</OPTION><OPTION VALUE="30" class="rec serv tran">Leisure, Travel &amp; Tourism</OPTION><OPTION VALUE="85" class="med rec serv">Libraries</OPTION><OPTION VALUE="116" class="corp tran">Logistics and Supply Chain</OPTION><OPTION VALUE="143" class="good">Luxury Goods &amp; Jewelry</OPTION><OPTION VALUE="55" class="man">Machinery</OPTION><OPTION VALUE="11" class="corp">Management Consulting</OPTION><OPTION VALUE="95" class="tran">Maritime</OPTION><OPTION VALUE="80" class="corp med">Marketing and Advertising</OPTION><OPTION VALUE="97" class="corp">Market Research</OPTION><OPTION VALUE="135" class="cons gov man">Mechanical or Industrial Engineering</OPTION><OPTION VALUE="126" class="med rec">Media Production</OPTION><OPTION VALUE="17" class="hlth">Medical Devices</OPTION><OPTION VALUE="13" class="hlth">Medical Practice</OPTION><OPTION VALUE="139" class="hlth">Mental Health Care</OPTION><OPTION VALUE="71" class="gov">Military</OPTION><OPTION VALUE="56" class="man">Mining &amp; Metals</OPTION><OPTION VALUE="35" class="art med rec">Motion Pictures and Film</OPTION><OPTION VALUE="37" class="art med rec">Museums and Institutions</OPTION><OPTION VALUE="115" class="art rec">Music</OPTION><OPTION VALUE="114" class="gov man tech">Nanotechnology</OPTION><OPTION VALUE="81" class="med rec">Newspapers</OPTION><OPTION VALUE="100" class="org">Non-Profit Organization Management</OPTION><OPTION VALUE="57" class="man">Oil &amp; Energy</OPTION><OPTION VALUE="113" class="med">Online Media</OPTION><OPTION VALUE="123" class="corp">Outsourcing/Offshoring</OPTION><OPTION VALUE="87" class="serv tran">Package/Freight Delivery</OPTION><OPTION VALUE="146" class="good man">Packaging and Containers</OPTION><OPTION VALUE="61" class="man">Paper &amp; Forest Products</OPTION><OPTION VALUE="39" class="art med rec">Performing Arts</OPTION><OPTION VALUE="15" class="hlth tech">Pharmaceuticals</OPTION><OPTION VALUE="131" class="org">Philanthropy</OPTION><OPTION VALUE="136" class="art med rec">Photography</OPTION><OPTION VALUE="117" class="man">Plastics</OPTION><OPTION VALUE="107" class="gov org">Political Organization</OPTION><OPTION VALUE="67" class="edu">Primary/Secondary Education</OPTION><OPTION VALUE="83" class="med rec">Printing</OPTION><OPTION VALUE="105" class="corp">Professional Training &amp; Coaching</OPTION><OPTION VALUE="102" class="corp org">Program Development</OPTION><OPTION VALUE="79" class="gov">Public Policy</OPTION><OPTION VALUE="98" class="corp">Public Relations and Communications</OPTION><OPTION VALUE="78" class="gov">Public Safety</OPTION><OPTION VALUE="82" class="med rec">Publishing</OPTION><OPTION VALUE="62" class="man">Railroad Manufacture</OPTION><OPTION VALUE="64" class="agr">Ranching</OPTION><OPTION VALUE="44" class="cons fin good">Real Estate</OPTION><OPTION VALUE="40" class="rec serv">Recreational Facilities and Services</OPTION><OPTION VALUE="89" class="org serv">Religious Institutions</OPTION><OPTION VALUE="144" class="gov man org">Renewables &amp; Environment</OPTION><OPTION VALUE="70" class="edu gov">Research</OPTION><OPTION VALUE="32" class="rec serv">Restaurants</OPTION><OPTION VALUE="27" class="good man">Retail</OPTION><OPTION VALUE="121" class="corp org serv">Security and Investigations</OPTION><OPTION VALUE="7" class="tech">Semiconductors</OPTION><OPTION VALUE="58" class="man">Shipbuilding</OPTION><OPTION VALUE="20" class="good rec">Sporting Goods</OPTION><OPTION VALUE="33" class="rec">Sports</OPTION><OPTION VALUE="104" class="corp">Staffing and Recruiting</OPTION><OPTION VALUE="22" class="good">Supermarkets</OPTION><OPTION VALUE="8" class="gov tech">Telecommunications</OPTION><OPTION VALUE="60" class="man">Textiles</OPTION><OPTION VALUE="130" class="gov org">Think Tanks</OPTION><OPTION VALUE="21" class="good">Tobacco</OPTION><OPTION VALUE="108" class="corp gov serv">Translation and Localization</OPTION><OPTION VALUE="92" class="tran">Transportation/Trucking/Railroad</OPTION><OPTION VALUE="59" class="man">Utilities</OPTION><OPTION VALUE="106" class="fin tech">Venture Capital &amp; Private Equity</OPTION><OPTION VALUE="16" class="hlth">Veterinary</OPTION><OPTION VALUE="93" class="tran">Warehousing</OPTION><OPTION VALUE="133" class="good">Wholesale</OPTION><OPTION VALUE="142" class="good man rec">Wine and Spirits</OPTION><OPTION VALUE="119" class="tech">Wireless</OPTION><OPTION VALUE="103" class="art med rec">Writing and Editing</OPTION></select>


    	  </SELECT>
    </TD>
    <TD></TD>
  </TR>
  <TR>
    <TD></TD>
    <TD><FORM ACTION="http://www.hipergate.org/registration/do.jsp" TARGET="hiddenframe"><INPUT TYPE="submit" CLASS="pushbutton" VALUE="[~Registar~]"></FORM></TD>
    <TD></TD>
  </TR>
</TABLE>
</BODY>
</HTML>
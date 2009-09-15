/***************************************************************
  JavaScript Functions for local plain text files read and write
*/

function makeFileName() {
	return "cs-"+ dateToString(new Date(), "d")+".log";
} // makeFileName

function includeFile(filePath,charenc) {
  var tf = new ActiveXObject("Scripting.FileSystemObject").OpenTextFile(filePath, 1, false, charenc);
  while (!tf.AtEndOfStream) document.write(tf.ReadLine());
  tf.close();
} // includeFile

// ----------------------------------------------------------------------------

function readLine(fn, id) {
	var la;                // Line Array
	var ln;	               // Line String
	var lo = new Object(); // Line Object
	var il = id.length;    // Id. length
  var cl = ColumnNames.length;
	var fs = new ActiveXObject('Scripting.FileSystemObject');
  var tf = fs.OpenTextFile(fn, 1, false, -1);
  while (!tf.AtEndOfStream) {
    ln = tf.ReadLine();
    if (ln.substr(0,i)==id) {
      la = ln.split("|");
      for (var c=0; c<cl; c++) {
        lo[ColumnNames[c]] = la[c];
      } // next
    } // fi
  } // wend
  tf.close();
  return lo;
} // readLine

// ----------------------------------------------------------------------------

function writeLine(fn, ln) {
	var fl;
	var fs = new ActiveXObject('Scripting.FileSystemObject');
	try {
		ln = ln.replace(/\r/g,'');
		ln = ln.replace(/\n/g,'');
		if (fs.fileExists(fn)) {
			fl = fs.OpenTextFile(fn, 8, false, -1);
		} else {
			fl = fs.CreateTextFile(fn, false, true);
		}
		fl.WriteLine(ln);
		fl.close();
	} catch (fileException) {
		alert('Error al grabar el fichero' + ' ' + fn + '\n[' + String(fileException.number) + '] ' + fileException.description);
		return false;
	}
	fl = null;
	fs = null;
	return true;
} // writeLine

// ----------------------------------------------------------------------------

function saveRecord(frm) {
  var frm = document.forms[0];

  if (frm.gu_record.value.length==0) {
    alert ("Record identifier is empty");
    return false;
  }
  
  var ln = getValueOf(frm.elements[ColumnNames[0]]);
	for (var c=1; c<ColumnNames.length; c++) {
	  ln += "|" + getValueOf(frm.elements[ColumnNames[c]]);
  } // next
        
  var ok = false;
        
  ok = writeLine(makeFileName(), ln);
  if (ok) {
    ok = writeLine("_sync\\"+frm.gu_record.value+".csv", ColumnNames.join("|"));
    ok = writeLine("_sync\\"+frm.gu_record.value+".csv", ln);
    writeLine("emails.log", frm.tx_email.value);
  }
  document.getElementById("feedback").innerHTML = (ok ? "Registro Grabado con Éxito" : "No fue posible grabar el registro correctamente");
} // saveRecord

// ----------------------------------------------------------------------------

function seekZipcode(zipcode,city) {
	var c = 0;
	var fs = new ActiveXObject('Scripting.FileSystemObject');
  var f = fs.OpenTextFile(zipcode.substr(0,2), 1, false, -1);
  var l;
  var e = "";
  var a = "";
  while (!f.AtEndOfStream) {
    l = f.ReadLine().split("|");
		if (l[1]==zipcode) {
			c++;
		  e = '<rs id="'+l[1]+'" info=""><![CDATA['+l[0]+']]></rs>';
		} else if (l[0].length>city.length) {
		  
		}
  }
} // seekZipcode

// ----------------------------------------------------------------------------

function setDefaultValues(frm) {
  frm.gu_record.value = uidgen();
  frm.dt_created.value = dateToString(new Date(), "ts"); 
  frm.gu_workarea.value = target_workarea;
  frm.gu_activity.value = target_activity;
  frm.gu_writer.value = writer_user;
  frm.nm_machine.value = new ActiveXObject("WScript.NetWork").ComputerName;
  frm.url_host_webapp.value = host_webapp_url;
}

// ----------------------------------------------------------------------------

function checkEmail() {
			var frm = document.forms[0];
			if (frm.tx_email.value.length>0) {
			  if (!check_email(frm.tx_email.value.toLowerCase())) {
		      alert (Resources["msg_tx_email_invalid"]);
		      return false;
			  }
			  
				var dup = false;
			  var fs = new ActiveXObject('Scripting.FileSystemObject');
			  if (fs.fileExists("emails.log")) {
			    var fl = fs.OpenTextFile("emails.log", 1, false, -1);
  		    while (!fl.AtEndOfStream && !dup) {
            dup = (fl.ReadLine()==frm.tx_email.value);
          }
          fl.close();
        }

				if (dup) {
          alert (Resources["msg_tx_email_duplicated"]);
				  document.forms[0].tx_email.focus();          	  
					return false;
				}			  

			  if (!req) {
			    req = createXMLHttpRequest();
			    req.onreadystatechange = processMailLookUp;
  				try {
			      req.open("GET", server_webapp_url+"marketing/activity_addr_exists.jsp?email="+frm.tx_email.value+"&workarea="+frm.gu_workarea.value+"&activity="+frm.gu_activity.value, true);
			      req.send(null);
			    } catch (xcpt) {
			      req = false;
			    }
			  } // fi
			}
} // checkEmail


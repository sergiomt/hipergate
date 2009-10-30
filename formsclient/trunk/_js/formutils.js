
// ----------------------------------------------------------------------------

var ColumnNames = new Array("gu_record","nm_machine","dt_created","gu_activity","gu_address","gu_company","gu_contact","gu_geozone","gu_list","gu_sales_man","gu_workarea","id_batch","gu_writer","id_transact","ix_address","bo_allows_ads","bo_confirmed","bo_paid","bo_private","bo_went","contact_person","de_title","direct_phone","dt_birth","dt_confirmed","dt_paid","fax_phone","full_addr","home_phone","id_country","id_gender","id_legal","id_ref","id_sector","id_state","id_status","im_paid","im_revenue","mn_city","mov_phone","nm_commercial","nm_country","nm_legal","nm_state","nm_street","nu_employees","nu_street","ny_age","other_phone","po_box","sn_passport","tp_billing","tp_company","tp_location","tp_origin","tp_street","tr_title","tx_addr1","tx_addr2","tx_comments","tx_dept","tx_division","tx_email","tx_franchise","tx_name","tx_remarks","tx_salutation","tx_surname","url_addr","work_phone","zipcode","id_data1","de_data1","tx_data1","id_data2","de_data2","tx_data2","id_data3","de_data3","tx_data3","id_data4","de_data4","tx_data4","id_data5","de_data5","tx_data5","id_data6","de_data6","tx_data6","id_data7","de_data7","tx_data7","id_data8","de_data8","tx_data8","id_data9","de_data9","tx_data9");

/********************************
  Data entry validation functions 
*/

function uidgen() {
  var uid  = "";
	var chst = "abcdefghijklmnopqrstuvwxyz0123456789";
	var clen = chst.length;
	for (var c=0; c<32; c++) {
	  uid += chst.charAt(Math.random()*clen);
	} // next
	return uid;
} // uidgen

// ----------------------------------------------------------------------------

function acceptOnlyNumbers(obj) {
  var notnum = /[^[\d]/g
  obj.value = obj.value.replace(notnum,'');
} // acceptOnlyNumbers

// ----------------------------------------------------------------------------

function check_email(email) {
  var ok = "1234567890qwertyuiop[]asdfghjklzxcvbnm.@-_QWERTYUIOPASDFGHJKLZXCVBNM";
  var re_one;
  var re_two;
  var elen = email.length;
      
  for (var i=0; i<elen; i++)
    if (ok.indexOf(email.charAt(i))<0)
      return (false);
  
    re_one = /(@.*@)|(\.\.)|(^\.)|(^@)|(@$)|(\.$)|(@\.)/;
    re_two = /^.+\@(\[?)[a-zA-Z0-9\-\.]+\.([a-zA-Z]{2}|[0-9]{1,3}|aero|biz|cat|com|coop|edu|gov|info|int|jobs|mil|mobi|museum|name|net|org|pro|tel|travel)(\]?)$/;
      
    if (!email.match(re_one) && email.match(re_two))
      return (true);		
  
  return (false);
} // check_email

/**
  * Letra de control de un numero de DNI
*/      
function letraControl(numero) {
     var Dig = "ATRWAGMYFPDXBNJZSQVHLCKE";      

     return Dig.charCodeAt((numero%23)+1);
} // letraControl

// ----------------------------------------------------------------------------

/**
  * Devuelve solo los numeros contenidos en una cadena
*/    
function parteNumerica (cadena) {      
     var len = cadena.length;
     var num = "";
     var cod;
      
     for (var i=0; i<len; i++) {
  	cod = cadena.charCodeAt(i); 
        if (cod>=48 && cod<=57) num+=cadena.charAt(i);
     } // next()
      
     return parseInt(num);
} // parteNumerica
    
// ----------------------------------------------------------------------------

/**
  * Verfica si una cadena contiene sólo caracteres numéricos [0..9]
*/
function CadenaNumerica_Var(cadena) {
     var long_cad=cadena.length;
      
     for ( var i=0; i < long_cad; i++ ) {
       if ( (cadena.charCodeAt(i) < 48) || (cadena.charCodeAt(i) > 57) )
          return false;     
               
     } // next (i)
     return true;
} // CadenaNumerica_Var

// ----------------------------------------------------------------------------

/**
  * Valida la primera letra de un NIF español
*/        
function validarNIF (nif) {
     var letra;
     var Aupr = 65;
     var Zupr = 90;
      
     letra = nif.charCodeAt(0);
     if (letra<Aupr || letra>Zupr)
          letra = nif.charCodeAt(nif.length-1);
     if (letra<Aupr || letra>Zupr)
	  return false;      
            
     return (letra==letraControl(parteNumerica(nif)));      
} // validarNIF

// ----------------------------------------------------------------------------

function isIntValue(str) {
  var reUnsignedInt = /^\d+$/

  var reSignedInt = /^[+-]?\d+$/

  if ((str == null) || (str.length == 0)) 
    return false;
  else 
    return reUnsignedInt.test(str) || reSignedInt.test(str);
} // isIntValue

// ----------------------------------------------------------------------------

function hasForbiddenChars(str) {
  return (str.indexOf("|")>=0 || str.indexOf('"')>=0 || str.indexOf("*")>=0 || str.indexOf("?")>=0 || str.indexOf("&")>=0 || str.indexOf(";")>=0 || str.indexOf("`")>=0 || str.indexOf("\\")>=0)
} // hasForbiddenChars

// ============================================================================

/*********************************************
  JavaScript Functions for Date Validation
*/

/**
  * Get last day of month taking into account leap years.
  * @param month [0..11]
  * @param year  (4 digits)
*/
  function getLastDay(month, year) {

    switch(month) {
      case 0:
      case 2:
      case 4:
      case 6:
      case 7:
      case 9:
      case 11:
        return 31;
      case 3:
      case 5:
      case 8:
      case 10:
        return 30;
      case 1:
	return ( (year%400==0) || ((year%4==0) && (year%100!=0)) ) ? 29 : 28;
    } // end switch()
    return 0;
  } // getLastDay()
  
  // ----------------------------------------------------------
  
  /**
    * Verify that a string represents a valid date
    * @param Input string
    * @param Date format. "d" for dates with format "YYYY-MM-DD"
                          "s" for dates with format "DD/MM/YYYY"
  */
  function isDate (dtexpr, dtformat) {
    var exp;
    var ser;
    var ret;
    var yy;
    var mm;
    var dd;
  
    if (dtformat=="d") {
      exp = new RegExp("[0-9]{4}-[0-9]{2}-[0-9]{2}");
      if (exp.test(dtexpr)) {
        ser = dtexpr.split("-");
        yy = parseInt(ser[0],10);
        mm = parseFloat(ser[1],10)-1;
        dd = parseFloat(ser[2],10);
      
        if (mm<0 || mm>12) {
          ret = false;
        }
        else if (dd>getLastDay(mm,yy)) {
          ret = false;
        }
        else
          ret = true;                
      }
      else {
        ret = false;
      }
    } else if (dtformat=="s") {
      exp = new RegExp("[0-9]{2}/[0-9]{2}/[0-9]{4}");
      if (exp.test(dtexpr)) {
        ser = dtexpr.split("/");
        yy = parseInt(ser[2],10);
        mm = parseFloat(ser[1],10)-1;
        dd = parseFloat(ser[0],10);
      
        if (mm<0 || mm>12) {
          ret = false;
        }
        else if (dd>getLastDay(mm,yy)) {
          ret = false;
        }
        else
          ret = true;                
      }
      else {
        ret = false;
      }
    }
    else {
      ret = false;
    }
    
    return ret;
  } // isDate()

  // ----------------------------------------------------------

  function dateToString(dt, dtformat) {
    var year = dt.getYear();
    if (year<1970) year+=1900;
    if ("d"==dtformat) {
      return String(year)+"-"+(dt.getMonth()+1<=9 ? "0" : "")+String(dt.getMonth()+1)+"-"+(dt.getDate()<=9 ? "0" : "")+String(dt.getDate());
    } else if ("s"==dtformat) {
      return (dt.getDate()<=9 ? "0" : "")+String(dt.getDate())+"/"+(dt.getMonth()+1<=9 ? "0" : "")+String(dt.getMonth()+1)+"/"+String(year);
    } if ("ts"==dtformat) {
      return String(year)+"-"+(dt.getMonth()+1<=9 ? "0" : "")+String(dt.getMonth()+1)+"-"+(dt.getDate()<=9 ? "0" : "")+String(dt.getDate())+" "+(dt.getHours()<=9 ? "0" : "")+String(dt.getHours())+":"+(dt.getMinutes()<=9 ? "0" : "")+String(dt.getMinutes())+":"+(dt.getSeconds()<=9 ? "0" : "")+String(dt.getSeconds());
    }
  } // dateToString

// ============================================================================

/*********************************************
  JavaScript Functions for ComboBox Management
*/

/**
  * Move ComboBox Selection to a given value
  * @param objCombo HTML <SELECT> Object
  * @param idValue Value to find inside ComboBox 
*/
function setCombo (objCombo, idValue) {
  var opt = objCombo.options;
  var len = opt.length;
  
  for (var i=0;i<len;i++)
    if (opt[i].value == idValue || opt[i].text == idValue) {
	opt.selectedIndex = i;
	break;
    } // fi()    
} // setCombo

// ----------------------------------------------------------------------------

/**
  * Get Index of a value inside a ComboBox
  * @param objCombo HTML <SELECT> Object
  * @param idValue Value to find inside ComboBox
  * return Index of value inside COmboBox or -1 if value was not found
*/
function comboIndexOf (objCombo, idValue) {
  var opt = objCombo.options;
  var len = opt.length;
  var idx = -1;
  
  for (var i=0;i<len;i++)
    if (opt[i].value == idValue || opt[i].text == idValue) {
      idx = i;
      break;
    } // fi()
  return idx; 
} // comboIndexOf

// ----------------------------------------------------------------------------

/**
  * Add a value to a ComboBox
*/

function comboPush (objCombo, txValue, idValue, defSel, curSel) {
  var opt = new Option(txValue, idValue, defSel, curSel);
  objCombo.options[objCombo.options.length] = opt;
}

// ----------------------------------------------------------------------------

/**
  * Get Selected Value for a ComboBox
  * @param objCombo HTML <SELECT> Object
  * @return Value for selected option or
  *         null if no option is selected
*/

function getCombo (objCombo) {

  if (objCombo.selectedIndex == -1)
    return null;
  else
    return objCombo[objCombo.selectedIndex].value;
}

// ----------------------------------------------------------------------------

/**
  * Get Selected Text for a ComboBox
  * @param objCombo HTML <SELECT> Object
  * @return Text for selected option or
  *         null if no option is selected
*/

function getComboText (objCombo) {
  var opt = objCombo.options;

  if (-1==opt.selectedIndex)
    return null;
  else  
    return opt[opt.selectedIndex].text;
}

// ----------------------------------------------------------------------------

/**
  * Clear all options for a ComboBox
*/
function clearCombo (objCombo) {
  var opt = objCombo.options;
  
  for (var i=opt.length-1; i>=0; i--)  
    // opt.remove(i);
    opt[i] = null;
}

// ----------------------------------------------------------------------------

/**
  * Sort ComboBox texts
*/
function sortCombo (objCombo) {
   var copyOption = new Array();
   var optCount = objCombo.options.length;
   
   for (var i=0; i<optCount; i++)   
     copyOption[i] = new Array(objCombo[i].value, objCombo[i].text);

   copyOption.sort(function(a,b) { if (isNaN(a[1]) || isNaN(b[1])) return (a[1]>b[1] ? 1 : (a[1]<b[1] ? -1 : 0)); else return (a[1]-b[1]); });

   clearCombo (objCombo);
      	
   for (var i=0; i<copyOption.length; i++)
     comboPush (objCombo, copyOption[i][1], copyOption[i][0], false, false)
} // sortCombo

// ----------------------------------------------------------------------------

function getCheckedValue(objRadio) {
  var cval = null;
  if (objRadio.length) {
    for (var r=0; r<objRadio.length && cval==null; r++) {
      if (objRadio[r].checked) cval = objRadio[r].value;
    } // next
  } else if (objRadio.checked) {
    cval = objRadio.value;
  }
  return cval;
} // getCheckedValue

// ----------------------------------------------------------------------------

function setCheckedValue(objRadio,idValue) {
  var cval = null;
  if (objRadio.length) {
    for (var r=0; r<objRadio.length; r++) {
      if (objRadio[r].value==idValue) {
        objRadio[r].checked = true;
        break;
      }
    } // next
  } else {
    objRadio.checked = (objRadio.value==idValue);
  }
} // setCheckedValue

// ============================================================================

/****************************************
    URL query string processing functions
*/

function getURLParam(name) {    
  var params = "&" + window.location.search.substr(1);    
  var indexa = params.indexOf("&" + name);
  var indexb;
  var retval;        
  if (-1==indexa)
    retval = null;
  else {
    indexa += name.length+2;
    indexb = params.indexOf("&", indexa);
    indexb = (indexb==-1 ? params.length-1 : indexb-1);      
    retval = params.substring(indexa, indexb+1);
  }            
  return unescape(retval).replace(/\+/g," ");
} // getURLParam

// ----------------------------------------------------------------------------

function readURLParamIntoForm(frm, paramname) {
	var up;
	var tp;
	var fe = frm.elements[paramname];
	if (fe) {
	  var up = getURLParam(paramname);
	      up = (up==null || up=="null" || up=="NULL" ? "" : up);
	  if (up.length>0) {
	    var tp = frm.elements[paramname].type;
	    if (tp=="text" || tp=="hidden") {
	      frm.elements[paramname].value = up;
	    } else if (tp=="select-one") {
	      setCombo(frm.elements[paramname], up);
	    } else if (frm.elements[paramname].length) {
	      setCheckedValue(frm.elements[paramname],up);
	    } else {
	      frm.elements[paramname].checked = (frm.elements[paramname].value==up);
	    }
	  }
	} else {
	  alert ("Element "+paramname+" not found at form");
	}
} // readURLParamIntoForm

// ----------------------------------------------------------------------------

function readPredefinedURLParamsIntoForm(frm) {
  var ncols = ColumnNames.length;
  for (var c=0; c<ncols; c++) {
    readURLParamIntoForm(frm, ColumnNames[c]);
  } // next
  if (isDate(frm.dt_birth.value,"d")) {
    var dt = frm.dt_birth.value.split("-");
    setCombo(document.forms[0].sel_birth_year, dt[0]);
    setCombo(document.forms[0].sel_birth_month, dt[1]);
    setCombo(document.forms[0].sel_birth_day, dt[2]);
  }
} // readPredefinedURLParamsIntoForm

// ----------------------------------------------------------------------------

function getValueOf(obj) {
	var tp = obj.type;
	if (tp=="text" || tp=="hidden") {
	  return obj.value;
	} else if (tp=="select-one") {
	  return getCombo(obj);
	} else if (obj.length) {
	  return getCheckedValue(obj);
	} else {
		return obj.checked ? obj.value : "";
	}
} // getValueOf

// ----------------------------------------------------------------------------

/*******************************************
  JavaScript Functions for validating inputs
*/

function check_name(frm) {
  if (frm.tx_name.style.visibility=="visible") {
	  if (frm.tx_name.className.indexOf("required")>=0 && frm.tx_name.value.length==0) {
		  alert (Resources["msg_tx_name_required"]);
		  frm.tx_name.focus();
		  return false;
		} else if (hasForbiddenChars(frm.tx_name.value)) {
		  alert (Resources["msg_tx_name_forbidden"]);
		  frm.tx_name.focus();
		  return false;		    	
		}	else {
		  if (frm.tx_name.className.indexOf("ttu")>=0)
		    frm.tx_name.value = frm.tx_name.value.toUpperCase();
		}
  }
  return true;
} // check_name

function check_surname(frm) {
  if (frm.tx_name.style.visibility=="visible") {
    if (frm.tx_surname.value.length==0) {
		  alert (Resources["msg_tx_surname_required"]);
		  frm.tx_surname.focus();
		  return false;
		} else if (hasForbiddenChars(frm.tx_surname.value)) {
		  alert (Resources["msg_tx_surname_forbidden"]);
		  frm.tx_surname.focus();
		  return false;		    	
		}	else {
		  if (frm.tx_surname.className.indexOf("ttu")>=0)
		    frm.tx_surname.value = frm.tx_surname.value.toUpperCase();
		}
  }
  return true;
} // check_surname

function check_mail(frm) {
  if (frm.tx_email.style.visibility=="visible") {
    if (frm.tx_email.value.length==0) {
		  alert (Resources["msg_tx_email_required"]);
		  frm.tx_email.focus();
		  return false;
		} else if (!check_email(frm.tx_email.value.toLowerCase())) {
		  alert (Resources["msg_tx_email_invalid"]);
		  frm.tx_email.focus();
		  return false;
		} else {
		  if (frm.tx_surname.className.indexOf("ttl")>=0)
		    frm.tx_email.value = frm.tx_email.value.toLowerCase();
		}
  }
  return true;
}	

function check_gender(frm) {
  if (frm.id_gender.style.visibility=="visible") {
    if (getCheckedValue(frm.id_gender)==null) {
		  alert (Resources["msg_id_gender_required"]);
		  return false;
		}
  }
  return true;
}

function check_zipcode(frm,countrycode) {
  var cpe = /[0-5][\d]{4}/;
  if (frm.zipcode.style.visibility=="visible") {
    if (countrycode=="es" && !frm.zipcode.value.match(cpe)) {
	    alert (Resources["msg_zipcode_invalid"]);
		  frm.zipcode.focus();
		  return false;
		}
    if (frm.id_state.style.visibility=="visible" && getCombo(frm.id_state)!=frm.zipcode.value.substring(0,2)) {
	    alert (Resources["msg_zipcode_mismatch"]);
		  frm.zipcode.focus();
		  return false;    	
    }
  }
  return true;
} // check_zipcode

function check_city(frm) {
  if (frm.mn_city.style.visibility=="visible") {
    if (frm.mn_city.value.length==0) {
		  alert (Resources["msg_mn_city_required"]);
		  frm.mn_city.focus();
		  return false;
		} else if (hasForbiddenChars(frm.mn_city.value)) {
		  alert (Resources["msg_mn_city_forbidden"]);
		  frm.mn_city.focus();
		  return false;		    	
		}	else {
		  if (frm.mn_city.className.indexOf("ttu")>=0)
		    frm.mn_city.value = frm.mn_city.value.toUpperCase();
		}
  }
  return true;
} // check_city

function check_birth_date(frm) {
  if (frm.dt_birth.style.visibility=="visible" || frm.sel_birth_day.style.visibility=="visible") {
    if (frm.dt_birth.value.length==0) {
      alert (Resources["msg_dt_birth_required"]);
		  return false;		    	
    } else if (!isDate (frm.dt_birth.value, "d")) {
      alert (Resources["msg_dt_birth_invalid"]);
		  return false;		    	    
    }
  }
  return true;
} // check_birth_date

function check_passport(frm,countrycode) {
  var cpe = /[0-5][\d]{4}/;
  if (frm.sn_passport.style.visibility=="visible") {
    if (frm.sn_passport.value.length==0) {
      alert (Resources["msg_sn_passport_required"]);
      frm.sn_passport.focus();
		  return false;   	
    }
  }
  return true;
} // check_passport

// ----------------------------------------------------------------------------

function check_all(frm,countrycode) {
  return check_name(frm) && check_surname(frm) && check_mail(frm) && check_gender(frm) && check_city(frm) && check_zipcode(frm,countrycode) &&
         check_passport(frm,countrycode) && check_birth_date(frm);
} // check_all

// ----------------------------------------------------------------------------


var req = false;		  

function processMailLookUp() {
        if (req.readyState == 4) {
          if (req.status == 200) {
          	if (req.responseText.substr(0,5)=="found") {
          	  alert (Resources["msg_tx_email_duplicated"]);
							document.forms[0].tx_email.focus();          	  
          	}
          	req = false;
          } else {
            // No conectivity to host available
            // alert ("status="+String(req.status));
          }
        }
} // processMailLookUp


/***************************************************
  JavaScript Functions for displaying data on screen
*/

var tabidx = 1;

function D (id, tp, lf, nm) {
  var dv = document.getElementById("div_"+id);
  var lb = document.getElementById("lbl_"+id);
  if (id=="sel_birth") {
    ui = document.getElementById(id+"_year");
    ui.style.visibility = "visible";
    ui.style.display = "block";  
    ui.tabIndex = tabidx++;
    if (nm.length>0) ui.className = nm;
    ui = document.getElementById(id+"_month");
    ui.style.visibility = "visible";
    ui.style.display = "block";  
    ui.tabIndex = tabidx++;
    if (nm.length>0) ui.className = nm;
    ui = document.getElementById(id+"_day");
    ui.style.visibility = "visible";
    ui.style.display = "block";  
    ui.tabIndex = tabidx++;
    if (nm.length>0) ui.className = nm;
    if (lb) lb.innerHTML = Resources["dt_birth"];
  } else {
  	ui = document.getElementById(id);
  	if (ui.length && ui.type!="select-one") {
		  for (var e=0; e<ui.length; e++) {
        ui[e].tabIndex = tabidx++;
        if (nm.length>0) ui[e].className = nm;
      } // next    
		} else {
      ui.style.visibility = "visible";
      ui.style.display = "block";  
      ui.tabIndex = tabidx++;
      if (nm.length>0) ui.className = nm;
		}
    if (lb) lb.innerHTML = Resources[id];
  }
  dv.style.top = tp;
  dv.style.left= lf;
  dv.style.visibility = "visible";
  dv.style.display = "block";  
} // D

function B (id, tp, lf, tx) {
  var div = document.getElementById("div_"+id);
	
	div.style.display="block";
	div.style.visibility="visible";
	div.style.top=tp;
  div.style.left=lf;
	document.getElementById("btn_"+id).value = tx;
}

// ----------------------------------------------------------------------------

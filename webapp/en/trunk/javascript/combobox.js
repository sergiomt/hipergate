/*********************************************
  JavaScript Functions for ComboBox Management
*/

//---------------------------------------------------------

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
	    if (objCombo.type=="select-one")
	      opt.selectedIndex = i;
	    else
	      opt[i].selected = true;
	    break;
    } // fi()    
} // setCombo

//---------------------------------------------------------

/**
  * Set multiple options from a combo
  * @param objCombo HTML <SELECT> Object
  * @param sVals String of delimited values 
  * @param sDelim String Delimiter 
*/
function setComboMult (objCombo, sVals, sDelim) {
  var opt = objCombo.options;
  var len = opt.length;
  var vals = sVals.split(sDelim);
  var vlen = vals.length;
  var v;
   
  for (var i=0; i<len; i++) {
		var b = false;
		for (v=0; v<vlen && !b; v++)
		  b = (opt[i].value == vals[v] || opt[i].text == vals[v]);
		opt[i].selected = b;
  } 
} // setComboMult

//---------------------------------------------------------

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

//---------------------------------------------------------

/**
  * Add a value to a ComboBox
*/

function comboPush (objCombo, txValue, idValue, defSel, curSel) {
  var opt = new Option(txValue, idValue, defSel, curSel);
  objCombo.options[objCombo.options.length] = opt;
}

//---------------------------------------------------------

/**
  * Get Selected Value for a ComboBox
  * If ComboBox type is select-one then
  * the value of the selectedIndex option is returned.
  * If ComboBox type is select-multiple then
  * a list of comma separated selected values is returned.
  * @param objCombo HTML <SELECT> Object
  * @return Value for selected option or
  *         null if no option is selected
*/

function getCombo (objCombo) {

  if (objCombo.type=="select-one") {
    if (objCombo.selectedIndex == -1)
      return null;
    else
      return objCombo[objCombo.selectedIndex].value;
  } else if (objCombo.type=="select-multiple") {
    var opts = objCombo.options;
    var vals = "";
    for (var o=0; o<opts.length; o++) {
      if (opts[o].selected) vals += (vals.length==0 ? "" : ",") + opts[o].value;
    } // next
    return vals;
  } // fi
} // getCombo

//---------------------------------------------------------

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

//---------------------------------------------------------

/**
  * Clear all options for a ComboBox
*/
function clearCombo (objCombo) {
  var opt = objCombo.options;
  
  for (var i=opt.length-1; i>=0; i--)  
    // opt.remove(i);
    opt[i] = null;
}

//---------------------------------------------------------

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

//---------------------------------------------------------

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

//---------------------------------------------------------

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
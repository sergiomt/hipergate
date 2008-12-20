function createXMLHttpRequest() {
  var req = false;
  // branch for native XMLHttpRequest object
  if (window.XMLHttpRequest) {
    try {
      req = new XMLHttpRequest();
    } catch(e) {
      alert("new XMLHttpRequest() failed"); req = false;
    }
  } else if(window.ActiveXObject) {
    try {
      req = new ActiveXObject("Msxml2.XMLHTTP");
    } catch(e) {
      try {
        req = new ActiveXObject("Microsoft.XMLHTTP");
      } catch(e) {
      	alert("ActiveXObject(Microsoft.XMLHTTP) failed"); req = false; }
      }
   } // fi
   return req;
} // createXMLHttpRequest

function getElementAttribute(parent, name, attr) {
  var node = parent.getElementsByTagName(name)[0];
  if (node) {
    return node.attributes.item(attr).value;
  } else {
  return null;
  }
} // getElementAttribute

function getElementText(parent, name){      
  var node = parent.getElementsByTagName(name)[0];
  if (node) {
    if (node.childNodes.length > 1)
      if (node.childNodes[1])
        return node.childNodes[1].nodeValue;
      else
        return null;
    else
      if (node.firstChild)
        return node.firstChild.nodeValue;
      else
        return null;
  } else
    return null;
} // getElementText

var PrivateSelectRequest = false;

function loadComboCallback() {
  if (PrivateSelectRequest.readyState == 4) {
    if (PrivateSelectRequest.status == 200) {
      var res = PrivateSelectRequest.responseXML;
      var frm = getElementText(res,"form");
      var cmb = document.forms[(isNaN(frm) ? frm : parseInt(frm))].elements[getElementText(res,"name")].options;
      var opt = res.getElementsByTagName("option");
      var len = opt.length;
      for (var o=0; o<len; o++) {
        cmb[cmb.length] = new Option(opt[o].firstChild.nodeValue, opt[o].attributes.item("value").value, false, false);        	
      }
      PrivateSelectRequest = false;
    }
  }
}

function loadCombo(fromurl, comboname, formid, domainid, workareaid, tablename, valcolumn, txtcolumn, where, orderby, skip, limit) {
  if (!skip) skip = 0;
  if (!limit) limit = 1000;
  if (!where) where = "";
  if (!orderby) orderby = "";
  PrivateSelectRequest = createXMLHttpRequest();
  if (PrivateSelectRequest) {
    PrivateSelectRequest.onreadystatechange = loadComboCallback;
    PrivateSelectRequest.open("GET", "select_xml.jsp?nm_select="+comboname+"&id_form="+formid+(domainid!=null ? "&id_domain="+String(domainid) : "")+(workareaid!=null ? "&gu_workarea="+workareaid : "")+"&nm_table="+tablename+"&nm_value="+escape(valcolumn)+"&nm_text="+escape(txtcolumn)+(where!=null ? "&tx_where="+escape(where) : "")+"&tx_order="+escape(orderby)+"&nu_skip="+String(skip)+"&nu_limit="+String(limit), true);
    PrivateSelectRequest.send(null);
  }
}

function httpRequestText(fromurl) {
  var PrivateTextRequest = createXMLHttpRequest();
  PrivateTextRequest.open("GET",fromurl,false);
  PrivateTextRequest.send(null);
  return PrivateTextRequest.responseText;
}


// ----------------------------------------------------------------------------

function check_url(the_url) {
  return the_url.match(new RegExp("((https?|ftp|gopher|telnet|file|notes|ms-help):((//)|(\\\\))+[\w\d:#@%/;$()~_?\+-=\\\.&]*)"));
}

// ----------------------------------------------------------------------------

function check_nick(nick) {
  var nlen = nick.length;
  var ccod;

  var dolar = 36;  
  var zero = 48;
  var nine = 57;
  var Aupr = 65;
  var Zupr = 90;
  var alwr = 97;
  var zlwr = 122;
  var underscore = 95;
    
  for (var i=0; i<nlen; i++) {
    ccod = nick.charCodeAt();
    if ((ccod<zero && ccod!=dolar) || (ccod>nine && ccod<Aupr) || (ccod>Zupr && ccod<alwr && ccod!=underscore) || (ccod>zlwr))
      return false;
  } // next

  return nick.match(/^[a-zA-Z0-9]+$/);
}

// ----------------------------------------------------------------------------

function check_email(email) {
  var ok = "1234567890qwertyuiop[]asdfghjklzxcvbnm.@-_QWERTYUIOPASDFGHJKLZXCVBNM";
  var re_one;
  var re_two;
  var elen = email.length;
      
  for (var i=0; i<elen; i++)
    if (ok.indexOf(email.charAt(i))<0)
      return (false);
  
  if (document.images) {
    re_one = /(@.*@)|(\.\.)|(^\.)|(^@)|(@$)|(\.$)|(@\.)/;
    re_two = /^.+\@(\[?)[a-zA-Z0-9\-\.]+\.([a-zA-Z]{2}|[0-9]{1,3}|aero|biz|cat|com|coop|edu|gov|info|int|jobs|mil|mobi|museum|name|net|org|pro|tel|travel)(\]?)$/;
      
    if (!email.match(re_one) && email.match(re_two))
      return (true);		
  } // fi()
  
  return (false);
} // check_email

// ----------------------------------------------------------------------------

function lookup_email(email,serverpageurl) {
  var req = false;
  var ret;
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
  if (req) {
    req.open("GET", serverpageurl+"?email="+escape(email), false);
    req.send(null);
  }
  return (req.responseText=="found");
}

// ----------------------------------------------------------------------------

function lookup_nickname(domainid,nickname,serverpageurl) {
  var req = false;
  var ret;
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
  if (req) {
    req.open("GET", serverpageurl+"?domainid="+String(domainid)+"&nickname="+escape(nickname), false);
    req.send(null);
  }
  return (req.responseText=="found");
}
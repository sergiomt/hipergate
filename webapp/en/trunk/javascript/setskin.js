    var sSkinCookieValue = getCookie("skin");
    
    if (sSkinCookieValue!=null && sSkinCookieValue!='undefined' && sSkinCookieValue!="") {
      if (sSkinCookieValue=="ss")
      document.write ('<LINK REL="stylesheet" TYPE="text/css" HREF="../skins/' + sSkinCookieValue + '/selfserv.css">');
        else
      document.write ('<LINK REL="stylesheet" TYPE="text/css" HREF="../skins/' + sSkinCookieValue + '/styles.css">');
    } else {
      document.write ('<LINK REL="stylesheet" TYPE="text/css" HREF="../skins/xp/styles.css">');
    }
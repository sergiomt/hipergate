
// Browser sniffer.
// Written by PerlScriptsJavaScripts.com

v3 = 0; op = 0; ie4  = 0; ie5 = 0; nn4 = 0; nn6 = 0; 
isMac = 0; aol = 0;

if(document.images){
    if(navigator.userAgent.indexOf("Opera") != -1){
        op = 1;
    } else {
        if(navigator.userAgent.indexOf("AOL") != -1){
            aol = 1;
        } else {
            ie4 = (document.all && !document.getElementById);
            nn4 = (document.layers);
            ie5 = (document.all && document.getElementById);
            nn6 = (document.addEventListener);
        }
    }
} else {
    v3 = 1;	
}

if(navigator.userAgent.indexOf("Mac") != -1){
    isMac = 1;
}



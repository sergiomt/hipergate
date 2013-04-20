/***********************************************************
  JavaScript Functions for finding a substring inside a page
*/

var g_pos = 0;

function findit (sValue) {
    var lpatt = new RegExp( "^ *(.*)$" );
    var parse = sValue.match( lpatt );
    
    if (null==parse)
      sValue = "";
    else
      sValue = parse[1];
      
    if (sValue == "") {        
        alert("[~The string to be searched may not be empty~]");
        return;
    }
    
    if (document.all) {
        var found = false;
        var text = document.body.createTextRange();
        for (var i=0; i<=g_pos && (found=text.findText(sValue)) != false; i++) {
            text.moveStart("character", 1);
            text.moveEnd("textedit");
        }
        if (found) {
            text.moveStart("character", -1);
            text.findText(sValue);
            text.select();
            text.scrollIntoView();
            g_pos++;
        }
        else {
            if (g_pos == '0')
                alert(sValue + "[~ not found~]");
            else
                alert("[~No more occurences of ~]" + sValue + "[~ where found~]");
            g_pos=0;
        }
    }
    else {
        find(sValue,false);
    }
}
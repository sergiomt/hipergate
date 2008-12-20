/*************************************************************/
/* Codigo DynFloat                                           */
/*************************************************************/

var Xoffset= 0;
var Yoffset= 0;

var nav;
var old;
var skn;
var iex=(document.all);

// Esta variable sirve para llevar inicialmente la capa fuera del navegador
var yyy=-1000;

var onShow = false;

if (navigator.appName=="Netscape") {
  (document.layers) ? nav=true : old=true;
}

if (!old) {
  skn=(nav) ? document.divHolder : divHolder.style;
  if (nav) {
    document.captureEvents(Event.MOUSECLICK);
  } // fi (nav)
  document.onclick=hideAllDivs;
} // fi (!old)

//-------------------------------------------------------------

function showDiv(sHiddenFrame,sVisibleFrame,sVisibleForm,sURL) {
  var divContent = "";
  var augmentedURL = sURL+"&visible_frame="+sVisibleFrame+"&visible_form="+sVisibleForm;
  
  if (document.forms[sVisibleForm].divField.value == "") {
    top.frames[sHiddenFrame].document.location=augmentedURL;
    setTimeout("showDiv('"+sHiddenFrame+"','"+sVisibleFrame+"','"+sVisibleForm+"','"+augmentedURL+"')",1000);
  } else {
    divContent = '<table bgcolor="#efefef" cellpadding="4" cellspacing="0" width="200" border="1"><tr height="100"><td valign="top" class="textsmall">'+document.forms[sVisibleForm].divField.value+'</td></tr></table>';
  }

  if (old) {
    alert(msg);
    return;
  } else {
    // Trae la capa que estaba fuera (yyy==-1000) a Yoffset pixels de distancia del click
    yyy=Yoffset;
    if (nav) {
      skn.document.write(divContent);
      skn.document.close();
      skn.visibility="visible"
    }
    if (iex) {
      document.all("divHolder").innerHTML=divContent;
      skn.visibility="visible"
    }
  }
  divVisible = true;
} // showDiv()

//-------------------------------------------------------------

function get_mouse(e) {
  var x; // posicion horizontal del click
  var y; // posicion vertical del click

  if (onShow == false) {
    x = (nav) ? e.pageX : event.x+document.body.scrollLeft;
    y = (nav) ? e.pageY : event.y+document.body.scrollTop;

    // Posicionar la capa en y + YOffset - 110
    skn.top=y+yyy-120;
    skn.left=x;
    onShow = true;
  }
}

//-------------------------------------------------------------

function hideDiv() {
  onShow = false;
  document.forms['divForm'].divField.value = "";
  if(!old) {
    yyy=-1000;
    skn.visibility="hidden"
  }
}

/*************************************************************/
/* Codigo RightMenu                                          */
/*************************************************************/

function showRightMenu() {
  document.all.rightMenuDiv.style.visibility = "visible";
  var rightedge = document.body.clientWidth-event.clientX;
  var bottomedge = document.body.clientHeight-event.clientY;

  if (rightedge < document.all.rightMenuDiv.offsetWidth)
    document.all.rightMenuDiv.style.left = document.body.scrollLeft + event.clientX - document.all.rightMenuDiv.offsetWidth;
  else
    document.all.rightMenuDiv.style.left = document.body.scrollLeft + event.clientX;
  if (bottomedge < document.all.rightMenuDiv.offsetHeight)
    document.all.rightMenuDiv.style.top = document.body.scrollTop + event.clientY - document.all.rightMenuDiv.offsetHeight;
  else
    document.all.rightMenuDiv.style.top = document.body.scrollTop + event.clientY;

  return false;
}

function enableRightMenuOption(op) {
  var opt = String(op);
  if (op<10) opt = "0" + opt;
  eval ("document.all.menuOpt" + opt + ".style.color = '#000000';");
}

function disableRightMenuOption(op) {
  var opt = String(op);
  if (op<10) opt = "0" + opt;
  eval ("document.all.menuOpt" + opt + ".style.color = '#848484';");
}

function isRightMenuOptionEnabled(op) {
  var opt = String(op);
  var yes;
  
  if (op<10) opt = "0" + opt;
  eval ("yes = (document.all.menuOpt" + opt + ".style.color == '#ffffff');");
  
  return yes;
}

function hideRightMenu() {
  document.all.rightMenuDiv.style.visibility = "hidden";
  document.all.rightMenuDiv.style.top = -1000;
}

function menuHighLight(o) {
  var fgc = o.currentStyle.color.toUpperCase();
  var bgc = o.currentStyle.backgroundColor.toUpperCase();
  var fgn = "";
  var bgn = "";
  var efn = "#000000";
  var ebn = "#D6D3CE";
  var efo = "#FFFFFF";
  var ebo = "#08246B";
  var dfn = "#848484";
  var dbn = "#D6D3CE";
  var dfo = "#FFFFFE";
  var dbo = "#08246A";

  if (fgc==efn&&bgc==ebn) { fgn=efo;bgn=ebo; }
  if (fgc==efo&&bgc==ebo) { fgn=efn;bgn=ebn; }
  if (fgc==dfn&&bgc==dbn) { fgn=dfo;bgn=dbo; }
  if (fgc==dfo&&bgc==dbo) { fgn=dfn;dgn=ebn; }
  o.style.color = fgn;
  o.style.backgroundColor = bgn;
  o.style.cursor = "default";
}


/*********************************************************/
/* Codigo Común                                          */
/*********************************************************/

function hideAllDivs() {
  get_mouse();
  hideRightMenu();
}

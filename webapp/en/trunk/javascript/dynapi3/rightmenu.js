var menuOptions = new Array();
var rightMenuHTML = "";

function showRightMenu(ev) {
  ev = (ev) ? ev : window.event;
  hideRightMenu();

  var isIE = navigator.userAgent.indexOf("compatible; MSIE")!=-1;
  var r = document.body.clientWidth  - ev.clientX; // Right
  var b = document.body.clientHeight - ev.clientY; // Bottom
  var w = menuLayer.getWidth();  // Layer Width
  var h = menuLayer.getHeight(); // Layer Height
  var posX = ev.clientX + (isIE ? document.body.scrollLeft : window.pageXOffset); // Event X
  var posY = ev.clientY + (isIE ? document.body.scrollTop  : window.pageYOffset); // Event Y

/*
  if (r<w)
    posX = posX - w;
  if (b<h)
    posY = posY - h;
*/

  menuLayer.setX(posX+6);
  menuLayer.setY(posY+6);
  menuLayer.setHTML(rightMenuHTML);
  menuLayer.setZIndex(1000);
  DynAPI.document.addChild(menuLayer);
  return false;
}
function hideRightMenu() {
  menuLayer.deleteFromParent();
}

function addMenuOption(txt,clk,cls) {
  menuOptions.push(new Array(txt,clk,cls));
  buildMenu();
}
function addMenuSeparator() {
  menuOptions.push(new Array("","",99));
  buildMenu();
}
function enableRightMenuOption(itm) {
  if (menuOptions.length>=itm)
    eval("menuOptions["+itm+"][2]=0");
  buildMenu();
}
function disableRightMenuOption(itm) {
  if (menuOptions.length>=itm)
    eval("menuOptions["+itm+"][2]=2");
  buildMenu();
}
function isRightMenuOptionEnabled(itm) {
  return menuOptions[itm][2]!=2;
}
function buildMenu() {
  var tmp = '<DIV class="cxMnu1" style="width:140px"><DIV class="cxMnu2">\n';
  for (var i=0;i<menuOptions.length;i++) {
    var s1 = "cmMnuOptOff";
    var s2 = "cmMnuOptOn";
    
    if(menuOptions[i][2]==99) {
      // Separator
      tmp += '<DIV class="cmMnuSp"><IMG src="spacer.gif" width="1" height="1" border="0"></DIV>';
    } else {
      if (menuOptions[i][2]==1) {
        // Bold class, cmMnuOptOffBold, cmMnuOptOnBold
        s1 += "Bold"; s2 += "Bold";
      } else if (menuOptions[i][2]==2) {
      	// Disabled class, cmMnuOptOffDisb, cmMnuOptOnDisb
        s1 += "Disb"; s2 += "Disb";
      } else {
      	// Normal class, cmMnuOptOffNorm, cmMnuOptOnNorm
        s1 += "Norm"; s2 += "Norm";
      }
      if (menuOptions[i][2]==0 || menuOptions[i][2]==1) {
        // Enabled, bold or normal
        tmp += '<DIV class="'+s1+'" onMouseOver="this.className=\''+s2+'\'" onMouseOut="this.className=\''+s1+'\'" onClick=\''+menuOptions[i][1]+'\'>'+menuOptions[i][0]+'</DIV>'    
      } else {
      	// Disabled, on onClick event
        tmp += '<DIV class="'+s1+'" onMouseOver="this.className=\''+s2+'\'" onMouseOut="this.className=\''+s1+'\'">'+menuOptions[i][0]+'</DIV>'    
      }
    } 
  } // for
  tmp += '</DIV></DIV>\n';
  rightMenuHTML = tmp; 
}
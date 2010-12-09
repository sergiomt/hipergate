function showDiv(ev,url) {
  ev = (ev) ? ev : window.event;
  hideDiv();
  
  var isIE = navigator.userAgent.indexOf("compatible; MSIE")!=-1;
  var r = document.body.clientWidth  - ev.clientX; // Right
  var b = document.body.clientHeight - ev.clientY; // Bottom
  var w = addrLayer.getWidth();  // Layer Width
  var h = addrLayer.getHeight(); // Layer Height
  var posX = ev.clientX + (isIE ? document.body.scrollLeft : window.pageXOffset); // Event X
  var posY = ev.clientY + (isIE ? document.body.scrollTop  : window.pageYOffset); // Event Y

  addrLayer.setVisible(false);
  
  window.status = ev.pageX+":"+ev.pageY;

  if (r < w)
    posX -= w;
  if (b < h)
    posY -= h;

  addrLayer.setX(posX+16);
  addrLayer.setY(posY+16);
  
  // addrLayer.setHTML('<IFRAME src="'+url+'" border="0" frameborder="0" width="200" height="102" scrolling="no"></IFRAME>');
  document.body.style.cursor = "wait";
  DynAPI.document.addChild(addrLayer);
  addrIFrame.document.location = url;
  return false;
}
function hideDiv() {
  addrLayer.deleteFromParent();
}

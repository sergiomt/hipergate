
var Xoffset=-60;    // modify these values to ...
var Yoffset= 20;    // change the popup position.

var nav;
var old;
var skn;
var iex=(document.all);
var yyy=-1000;

if (navigator.appName=="Netscape")
  (document.layers) ? nav=true : old=true;

if (!old)
  {
  skn=(nav) ? document.dek : dek.style;
  if (nav)
    document.captureEvents(Event.MOUSEMOVE);
  document.onmousemove=get_mouse;
  }

function popover(msg)
  {
  if (navigator.appName!="Microsoft Internet Explorer") return;
  
  var content="<TABLE WIDTH='220' CLASS='poptip'><TR><TD ALIGN='left'><FONT CLASS='textsmall'>"+msg+"</FONT></TD></TR></TABLE>";

  if (old)
    {
    alert(msg);
    return
    }
  else
    {
    yyy=Yoffset;
    if (nav)
      {
      skn.document.write(content);
      skn.document.close();
      skn.visibility="visible"
      }
    if (iex)
      {
      document.all("dek").innerHTML=content;
      skn.visibility="visible"
      }
    }
  }

function get_mouse(e)
  {
  var x = (nav) ? e.pageX : event.x+document.body.scrollLeft;
  if (x<590)
    skn.left=x+Xoffset;
  var y = (nav) ? e.pageY : event.y+document.body.scrollTop;
  skn.top=y+yyy
  }

function popout()
  {
  if (navigator.appName!="Microsoft Internet Explorer") return;

  if(!old)
    {
    yyy=-1000;
    skn.visibility="hidden"
    }
  }

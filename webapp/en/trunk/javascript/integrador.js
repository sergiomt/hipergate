/* ************************************************************** */
/* Esta es la parte común del integrador, no se debería tocar...  */
/* ************************************************************** */

editMode = '_';

function mostrarInt() {
  this.myLayer.setVisible(true);
}

function ocultarIntegrador() {  
  myLayer.setVisible(false);
}

function ocultarInt() {
  this.myLayer.setVisible(false);
}

/***************************************************/
/* Funciones de scrolling			   */
/***************************************************/

function bajarInt() {	
}

function subirInt() {
}

function pararInt() {
}

/***************************************************/

function MM_swapImgRestore() { //v3.0
  var i,x,a=document.MM_sr; for(i=0;a&&i<a.length&&(x=a[i])&&x.oSrc;i++) x.src=x.oSrc;
}
function MM_preloadImages() { //v3.0
  var d=document; if(d.images){ if(!d.MM_p) d.MM_p=new Array();
  var i,j=d.MM_p.length,a=MM_preloadImages.arguments; for(i=0; i<a.length; i++)
  if (a[i].indexOf("#")!=0){ d.MM_p[j]=new Image; d.MM_p[j++].src=a[i];}}
}
function MM_findObj(n, d) { //v4.0
  var p,i,x;  if(!d) d=document; if((p=n.indexOf("?"))>0&&parent.frames.length) {
  d=parent.frames[n.substring(p+1)].document; n=n.substring(0,p);}
  if(!(x=d[n])&&d.all) x=d.all[n]; for (i=0;!x&&i<d.forms.length;i++) x=d.forms[i][n];
  for(i=0;!x&&d.layers&&i<d.layers.length;i++) x=MM_findObj(n,d.layers[i].document);
  if(!x && document.getElementById) x=document.getElementById(n); return x;
}
function MM_swapImage() { //v3.0
  var i,j=0,x,a=MM_swapImage.arguments; document.MM_sr=new Array; for(i=0;i<(a.length-2);i+=3)
  if ((x=MM_findObj(a[i]))!=null){document.MM_sr[j++]=x; if(!x.oSrc) x.oSrc=x.src; x.src=a[i+2];}
}

DynObject = function() {
	this.setID("DynObject"+(DynObject.Count++));
	this.isChild = false;
	this.created = false;
	this.parent = null;
	this.children = [];
	//added to counter inheritance bug (#425789)
	this.eventListeners = [];
	this.hasEventListeners = false;
};
DynObject.prototype.getClass = function() { return this.constructor };
DynObject.prototype.setID = function(id) {
	if (this.id) delete DynObject.all[this.id];
	this.id = id;
	DynObject.all[this.id] = this;
};
DynObject.prototype.addChild = function(c) {
	if(c.isChild) c.parent.removeChild(c);
	c.isChild = true;
	c.parent = this;
	if(this.created) c.create()
	this.children[this.children.length] = c;
	return c;
};
DynObject.prototype.removeChild = function(c) {
	var l = this.children.length;
	for(var i=0;i<l && this.children[i]!=c;i++);
	if(i!=l) {
		c.invokeEvent("beforeremove");
		c.specificRemove();
		c.created=false;
		c.invokeEvent("remove");
		c.isChild = false;
		c.parent = null;
		this.children[i] = this.children[l-1];
		this.children[l-1] = null;
		this.children.length--;
	}
};
DynObject.prototype.deleteFromParent = function () {
	if(this.parent) this.parent.deleteChild(this);
};
DynObject.prototype.removeFromParent = function () {
	if(this.parent) this.parent.removeChild(this);
};
DynObject.prototype.create = function() {
	this.flagPrecreate();
	this.specificCreate();
	this.created = true;
	var l = this.children.length;
	for(var i=0;i<l;i++) this.children[i].create()
	this.invokeEvent("create");
};
DynObject.prototype.flagPrecreate = function() {
	if (this.precreated) return;
	var l=this.children.length;
	for (var i=0; i<l;  i++) this.children[i].flagPrecreate();
	this.invokeEvent('precreate');
	this.precreated=true;
};
DynObject.prototype.del = function() {
	this.deleteAllChildren();
	this.invokeEvent("beforeremove");
	this.specificRemove();
	this.precreated = this.created = false;
	this.invokeEvent("remove");
	};
DynObject.prototype.deleteChild = function(c) {
	var l = this.children.length;
	for(var i=0;i<l && this.children[i]!=c;i++);
	if(i!=l) {
		this.children[i] = this.children[l-1];
		this.children[l-1] = null;
		this.children.length--;
		c.del()
		c = null;
	}
};
DynObject.prototype.deleteAllChildren = function() {
	var l = this.children.length;
	for(var i=0;i<l;i++) {
		this.children[i].del();
		delete this.children[i];
	}
	this.children = [];
};
DynObject.prototype.toString = function() {
	return "DynObject.all."+this.id
};
DynObject.prototype.getAll = function() {
	var ret = [];
	var temp;
	var l = this.children.length;
	for(var i=0;i<l;i++) {
		ret[this.children[i].id] = this.children[i];
		temp = this.children[i].getAll();
		for(var j in temp) ret[j] = temp[j];
	}
	return ret
};
DynObject.prototype.isParentOf = function(obj,equality) {
	if(!obj) return false
	return (equality && this==obj) || this.getAll()[obj.id]==obj
}
DynObject.prototype.isChildOf = function(obj,equality) {
	if(!obj) return false
	return (equality && this==obj) || obj.getAll()[this.id]==this
}
DynObject.prototype.specificCreate	= function() {};
DynObject.prototype.specificRemove	= function() {};
DynObject.prototype.invokeEvent		= function() {};
DynObject.Count = 0;
DynObject.all = [];
Methods = {
	removeFromArray : function(array, index, id) {
		var which=(typeof(index)=="object")?index:array[index];
		if (id) delete array[which.id];
        	else for (var i=0; i<array.length; i++)
			if (array[i] == which) {
				if(array.splice) array.splice(i,1);
				else {	for(var x=i; x<array.length-1; x++) array[x]=array[x+1];
         				array.length -= 1; }
			break;
			}
		return array;
	},
	getContainerLayerOf : function(element) {
		if(!element) return null
		if(is.def&&!is.ie) while (!element.lyrobj && element.parentNode && element.parentNode!=element) element=element.parentNode;
		else if(is.ie) while (!element.lyrobj && element.parentElement && element.parentElement!=element) element=element.parentElement;
		return element.lyrobj
	}
};
DynAPIObject = function() {
	this.DynObject = DynObject;
	this.DynObject();

	this.loaded = false;
	this.librarypath = '';
	this.packages = [];
	this.errorHandling = true;
	this.returnErrors = true;
	this.onLoadCodes = [];
	this.onUnLoadCodes = [];
	this.onResizeCodes = [];
}
DynAPIObject.prototype = new DynObject();
DynAPIObject.prototype.setLibraryPath = function(path) {
	if (path.substring(path.length-1)!='/') path+='/';
	this.librarypath=path;
}
DynAPIObject.prototype.addPackage = function(pckg) {
	if (this.packages[pckg]) return;
	this.packages[pckg] = { libs: [] };
}
DynAPIObject.prototype.addLibrary = function(path,files) {
	var pckg = path.substring(0,path.indexOf('.'));
	if (!pckg) {
		alert("DynAPI Error: Incorrect DynAPI.addLibrary usage");
		return;
	}
	var name = path.substring(path.indexOf('.')+1);
	if (!this.packages[pckg]) this.addPackage(pckg);
	if (this.packages[pckg].libs[name]) {
		alert("DynAPI Error: Library "+name+" already exists");
		return;
	}
	this.packages[pckg].libs[name] = files;
}
DynAPIObject.prototype.include = function(src,pth) {
	src=src.split('.');
	if (src[src.length-1] == 'js') src.length -= 1;
	var path=pth||this.librarypath||'';
	if (path.substr(path.length-1) != "/") path += "/";
	var pckg=src[0];
	var grp=src[1];
	var file=src[2];
	if (file=='*') {
		if (this.packages[pckg]) group=this.packages[pckg].libs[grp];
		if (group) for (var i=0;i<group.length;i++) document.write('<script language="Javascript1.2" src="'+path+pckg+'/'+grp+'/'+group[i]+'.js"><\/script>');
		else alert('include()\n\nThe following package could not be loaded:\n'+src+'\n\nmake sure you specified the correct path.');
	} else document.write('<script language="Javascript1.2" src="'+path+src.join('/')+'.js"><\/script>');
}
DynAPIObject.prototype.errorHandler = function (msg, url, lno) {
	if (!this.loaded || !this.errorHandling) return false;
	if (is.ie) {
		lno-=1;
		alert("DynAPI reported an error\n\nError in project: '" + url + "'.\nLine number: " + lno + ".\n\nMessage: " + msg);
	} else if (is.ns) {
		alert("DynAPI reported an error\n\nError in file: '" + url + "'.\nLine number: " + lno + ".\n\nMessage: " + msg);
	} else return false;
	return this.returnErrors;
}
DynAPIObject.prototype.addLoadFunction = function(f) {
	this.onLoadCodes[this.onLoadCodes.length] = f;
}
DynAPIObject.prototype.addUnLoadFunction = function(f) {
	this.onUnLoadCodes[this.onUnLoadCodes.length] = f;
}
DynAPIObject.prototype.addResizeFunction = function(f) {
	this.onResizeCodes[this.onResizeCodes.length] = f;
}
DynAPIObject.prototype.loadHandler = function() {
	this.create();
	eval(this.onLoadCodes.join(";"));
	if (this.onLoad) this.onLoad();
	this.loaded=true;
}
DynAPIObject.prototype.unloadHandler = function() {
	if (!is.ns4) this.deleteAllChildren();
	eval(this.onUnLoadCodes.join(";"));
	if (this.onUnload) this.onUnload();
}
DynAPIObject.prototype.resizeHandler = function() {
	eval(this.onResizeCodes.join(";"));
	if (this.onResize) this.onResize();
}

// Create base objects
DynAPI = new DynAPIObject();
DynLayer=DynDocument=null

// Native events
onload = function() { DynAPI.loadHandler(); }
onunload = function() { DynAPI.unloadHandler(); }
onerror = function(msg, url, lno) { DynAPI.errorHandler(msg, url, lno); }
onresize = function() { DynAPI.resizeHandler(); }

// Add base packages
DynAPI.addPackage('dynapi');
DynAPI.addLibrary('dynapi.api'  ,["browser","dyndocument","dynlayer"]);
DynAPI.addLibrary('dynapi.event',["listeners","mouse","dragevent","keyboard"]);
DynAPI.addLibrary('dynapi.ext'  ,["inline","layer","dragdrop","functions"]);
DynAPI.addLibrary('dynapi.gui'  ,["viewport","dynimage","button","buttonimage","label","list","loadpanel","pushpanel","scrollbar","scrollpane","sprite"]);
DynAPI.addLibrary('dynapi.util' ,["circleanim","cookies","debug","thread","hoveranim","imganim","pathanim","console"]);

DynAPI.setLibraryPath(webserver_param + '/lib/')
DynAPI.include('dynapi.api.*');
DynAPI.include('dynapi.event.*');

DynAPI.onLoad=function() {
  
  // Layer para el botón de cerrar integrador
  myLayer = new DynLayer();
  myLayer.setSize(330,410);
  myLayer.setBgColor('');
  myLayer.moveTo(420,120);
  //myLayer.setHTML('<MAP NAME="fondo_integrador1"><AREA SHAPE=RECT COORDS="290,6,300,16" HREF="javascript:ocultarIntegrador()" ALT="[~Cerrar Panel de Edición~]"><AREA SHAPE=RECT COORDS="296,40,302,49" onMouseOut="pararInt()" onMouseOver="subirInt()"><AREA SHAPE=RECT COORDS="296,357,303,367" onMouseOut="pararInt()" onMouseOver="bajarInt()"></MAP><table cellspacing="0" cellpadding="0"><tr><td oncontextmenu="return false"><img src="../images/images/integrador/fondo_integrador.gif" usemap="#fondo_integrador1" width="320" height="400" border="0" galleryimg="no" oncontextmenu="return false"></td></tr></table>');
  myLayer.setHTML('<MAP NAME="fondo_integrador1"><AREA SHAPE=RECT COORDS="270,6,300,26" HREF="javascript:ocultarIntegrador()" ALT="[~Cerrar Panel de Edición~]"></MAP><table cellspacing="0" cellpadding="0"><tr><td oncontextmenu="return false"><img src="../../../../../../images/images/integrador/fondo_integrador.gif" usemap="#fondo_integrador1" width="320" height="400" border="0" galleryimg="no" oncontextmenu="return false"></td></tr></table>');
  this.document.addChild(myLayer);
  myLayer.css.paddingTop="1px";
  myLayer.css.visibility="inherit";


  
  // Layer para el menu de bloques
  myDragLayer = new DynLayer();
  myDragLayer.setSize(283,340);
  myDragLayer.setBgColor('');
  myDragLayer.moveTo(20,22);
  myDragLayer.setHTML(integradorHTML);  
  myLayer.addChild(myDragLayer);
  myDragLayer.css.paddingTop="1px";
  myDragLayer.css.visibility="inherit";

  DragEvent.setDragBoundary(myLayer,0,screen.width-20,1000,0);
  DragEvent.enableDragEvents(myLayer);
  myListener = new EventListener(DynAPI.document);
  myListener.onmousedown=function(e) { e.setBubble(false); }
  myDragLayer.addEventListener(myListener);
  a=0;
}

/*
   DynAPI Distribution
   Inline Layers Extensions

   The DynAPI Distribution is distributed under the terms of the GNU LGPL license.

   Requirements: 
	dynapi.api [dynlayer, dyndocument, browser]
*/
DynObject.prototype.findLayers=function() {
	var divs=[];
	if (is.def&&!is.ie) divs=this.doc.getElementsByTagName("DIV");
	else if (is.ie) divs=this.doc.all.tags("DIV");
	else if (is.ns4) divs=this.doc.layers;
	else return;
	for (var i=0; i<divs.length; i++) {
		if(Methods.isDirectChildOf(divs[i],this.elm)) {
			var id=is.ns4? divs[i].name : divs[i].id;
			var dlyr=new DynLayer(id);
			dlyr.parent=this;
			dlyr.created=true;
			dlyr.isChild=true;
			dlyr.elm=divs[i];
			if (is.def) {
				dlyr.css=dlyr.elm.style;
				dlyr.doc=this.doc
			}
			else if (is.ns4) { 
				dlyr.css=dlyr.elm;
				dlyr.doc=dlyr.elm.document;
			}
			dlyr.frame=this.frame;
			//Event stuff
			dlyr.elm.lyrobj=dlyr.doc.lyrobj=dlyr;
			if(is.ns4) {
				for (var j in dlyr.doc.images) dlyr.doc.images[j].lyrobj=dlyr; 
				for (j=0;j<dlyr.doc.links.length;j++) dlyr.doc.links[j].lyrobj=dlyr;
			}
			// DynObject.all[dlyr.id]=dlyr;
			// JM: Constructors take care of this
			this.children[this.children.length]=dlyr;
			dlyr.updateValues();
			dlyr.findLayers();
		}
	}
};
DynLayer.prototype.updateValues=function() {
	if (is.def) {
		this.x=this.elm.offsetLeft;
		this.y=this.elm.offsetTop;
		this.w=is.ie4? this.css.pixelWidth||this.getContentWidth() : this.elm.offsetWidth;
		this.h=is.ie4? this.css.pixelHeight||this.getContentHeight() : this.elm.offsetHeight;
		this.bgImage = this.css.backgroundImage;
		this.bgColor = this.css.backgroundColor;
		this.html = this.innerHTML = this.elm.innerHTML;
	}
	else if (is.ns4) {
		this.x=parseInt(this.css.left);
		this.y=parseInt(this.css.top);
		this.w=this.css.clip.width;
		this.h=this.css.clip.height;
		this.clip=[this.css.clip.top,this.css.clip.right,this.css.clip.bottom,this.css.clip.left];
		this.bgColor=this.doc.bgColor!="this.doc.bgColor"?this.doc.bgColor:null;
		this.bgImage=this.elm.background.src!=""?this.elm.background.src:null;
		this.html=this.innerHTML = this.elm.innerHTML = "";
	}
	this.z=this.css.zIndex;
	var b=this.css.visibility;
	this.visible=(b=="inherit"||b=="show"||b=="visible"||b=="");
};
Methods.isDirectChildOf = function(l, parent) {
	if(is.def&&!is.ie) {
		for(var p=l.parentNode;p;p=p.parentNode) if(p.nodeName.toLowerCase()=='div') return p==parent;
		return !parent.nodeName;
	}
	else if (is.ie) {
		for(var p=l.parentElement;p;p=p.parentElement) if(p.tagName.toLowerCase()=='div') return p==parent;
		return !parent.tagName;
	}
	else if(is.ns4) return (l.parentLayer == parent);
};
/* Place Initialization code */
DynDocument.prototype._OldI_specificCreate = DynDocument.prototype.specificCreate
DynDocument.prototype.specificCreate = function() {
	this._OldI_specificCreate()
	this.findLayers()
}

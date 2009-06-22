/*
   DynAPI Distribution
   DragDrop Extension

   The DynAPI Distribution is distributed under the terms of the GNU LGPL license.

   Requirements: 
	dynapi.api.*
*/ 
DynObject.prototype.DragDrop=function(s,e){
	if (!this.children.length>0) return false;
	var ch,chX,chY,eX,eY;
	eX = e.getX();
	eY = e.getY();
	for (var i in this.children) {
		ch=this.children[i];
		if(ch!=s) {
			chX=ch.getPageX();
			chY=ch.getPageY();
			if (chX<eX && chX+ch.w>eX && chY<eY && chY+ch.h>eY)  {
				if (ch.DragDrop(s,e)) return true;
				ch.invokeEvent("drop");
				return true;
			}
		}
	}
	return false;
};

/*
   DynAPI Distribution
   Simple event classes. 
   The DynAPI Distribution is distributed under the terms of the GNU LGPL license.
*/ 
if (typeof(DynObject.prototype.invokeEvent)=="function") {
	DynObject.prototype._oldInvokeEvent = DynObject.prototype.invokeEvent;
} else {
	DynObject.prototype._oldInvokeEvent = function() {return true;};
}
DynObject.prototype.invokeEvent = function(type,e,args) {
	var ret = true;
	if(this["on"+type]) ret = this["on"+type](e,args)
	if(ret && this._oldInvokeEvent(type,e,args) && this.parent) this.parent.invokeEvent(type,e,args);
}

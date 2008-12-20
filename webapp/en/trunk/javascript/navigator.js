editMode = '';

function callPage(page) { 
	document.location = "./" + page + editMode + ".html"; 
}

function MM_openBrWindow(theURL,winName,features) { 
	window.open(theURL,winName,features);
}

function mOvr(src,clrOver) {
	if (!src.contains(event.fromElement)) {
		src.style.cursor = 'default';src.bgColor = clrOver;
	}
}

function mOut(src,clrIn) {
	if (!src.contains(event.toElement)) {
		src.style.cursor = 'default';src.bgColor = clrIn;
	}
}

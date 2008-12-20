var panelID = "p1"
var numDiv = 6
var numRows = 2
var tabsPerRow = 4
var numLocations = numRows * tabsPerRow
var tabWidth = 100
var tabHeight = 30
var vOffset = 8
var hOffset = 10

var divLocation = new Array(numLocations)
var newLocation = new Array(numLocations)

for(var i=0; i<numLocations; ++i) {
	divLocation[i] = i
	newLocation[i] = i
}

function getDiv(s,i) {
	var div
	if (document.layers) {
		div = document.layers[panelID].layers[panelID+s+i]
	} else if (document.all && !document.getElementById) {
		div = document.all[panelID+s+i]
	} else {
		div = document.getElementById(panelID+s+i)
	}
	return div
}

function setZIndex(div, zIndex) {
	if (document.layers) div.style = div;
	div.style.zIndex = zIndex
}

function updatePosition(div, newPos) {
	newClip=tabHeight*(Math.floor(newPos/tabsPerRow)+1)
	if (document.layers) {
		div.style=div;
		div.clip.bottom=newClip; // clip off bottom
		} else {
		div.style.clip="rect(0 auto "+newClip+" 0)"
		}
	div.style.top = (numRows-(Math.floor(newPos/tabsPerRow) + 1)) * (tabHeight-vOffset)
	div.style.left = (newPos % tabsPerRow) * tabWidth +	(hOffset * (Math.floor(newPos / tabsPerRow)))
}

function selectTab(n) {
	// n is the ID of the division that was clicked
	// firstTab is the location of the first tab in the selected row
	var firstTab = Math.floor(divLocation[n] / tabsPerRow) * tabsPerRow
	// newLoc is its new location
	for(var i=0; i<numDiv; ++i) {
		// loc is the current location of the tab
		var loc = divLocation[i]
		// If in the selected row
		if(loc >= firstTab && loc < (firstTab + tabsPerRow)) newLocation[i] = (loc - firstTab)
		else if(loc < tabsPerRow) newLocation[i] = firstTab+(loc % tabsPerRow)
		else newLocation[i] = loc
	}
	// Set tab positions & zIndex
	// Update location
	for(var i=0; i<numDiv; ++i) {
		var loc = newLocation[i]
		var div = getDiv("panel",i)
		if(i == n) setZIndex(div, numLocations +1)
		else setZIndex(div, numLocations - loc)
		divLocation[i] = loc
		div = getDiv("tab",i)
		updatePosition(div, loc)
		if(i == n) setZIndex(div, numLocations +1)
		else setZIndex(div,numLocations - loc)
	}
}

// Nav4: position component into a table
function positionPanel() {
	document.p1.top=document.panelLocator.pageY;
	document.p1.left=document.panelLocator.pageX;
}
if (document.layers) window.onload=positionPanel;

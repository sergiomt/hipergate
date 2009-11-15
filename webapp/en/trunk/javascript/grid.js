/************************************************************************
  JavaScript Functions for creating and modifying HTML tables dynamically
*/

//-----------------------------------------------------------------------------

function GridCreate(iRows,iCols) {
  oGrid = new Object;
  
  if (iRows>0)
    oGrid.rows = new Array();
  else
    oGrid.rows = null;
    
  oGrid.rowcount = iRows;
  oGrid.colcount = iCols;
  oGrid.inputclass = "combomini";
  
  return oGrid;  
} // GridCreate

//-----------------------------------------------------------------------------

function GridCreateRow(oGrid,sId) {
  oGridRow = new Object;
  oGridRow.id = sId;
  oGridRow.cols = new Array(oGrid.colcount);
    
  for (var c=0;c<oGrid.colcount; c++)
    (oGridRow.cols)[c] = null;
  
  if (oGrid.rowcount>0) {
          
    var oRows = oGrid.rows;
         
    oRows.push(oGridRow);
  }
  else {

    oGrid.rows = new Array(oGridRow);
  }  
  oGrid.rowcount = oGrid.rowcount + 1;
  
  return oGridRow;
} // GridCreateRow

//-----------------------------------------------------------------------------

function GridFindRow(oGrid,sId) {
  var iRows = oGrid.rowcount;
  var aRows = oGrid.rows;
  var oId;
  
  for (var r=0; r<iRows; r++) {    
    if (null!=aRows[r]) {
      oId = aRows[r].id; 
      if (oId == sId)
        return r;
    } // fi (aRows[r])
  } // next
  
  return -1;
} // GridFindRow

//-----------------------------------------------------------------------------

function GridRemoveRow(oGrid,iRow) {
  (oGrid.rows)[iRow] = null;
}

//-----------------------------------------------------------------------------

function GridCreateCell(oGridRow,iCol,sId,sName,sType,sValue) {
  oGridCell = new Object;
  oGridCell.id = sId;
  oGridCell.name = sName;
  oGridCell.type = sType;
  oGridCell.size = null;
  oGridCell.maxlen = null;  
  oGridCell.value = sValue;
  oGridCell.tags = "";
  (oGridRow.cols)[iCol] = oGridCell;
  
  return oGridCell;
}

//-----------------------------------------------------------------------------

function GridCreateInputCell(oGridRow,iCol,sId,sName,sType,sValue,iSize,iMaxLength,sTags) {
  oGridCell = new Object;
  oGridCell.id = sId;
  oGridCell.name = sName;
  oGridCell.type = sType;
  oGridCell.size = iSize;
  oGridCell.maxlen = iMaxLength;  
  oGridCell.value = sValue;
  oGridCell.tags = sTags;
  (oGridRow.cols)[iCol] = oGridCell;
  
  return oGridCell;
}
//-----------------------------------------------------------------------------

function GridDrawCell(oCell) {
  if ("html"==oCell.type) {    
    return "<TD>" + oCell.value + "</TD>";
  }
  else if ("text"==oCell.type) {
    return "<TD><INPUT TYPE=text NAME=" + oCell.name + " SIZE=" + String(oCell.size) + " MAXLENGTH=" + String(oCell.maxlen) + " VALUE='" + oCell.value + "'" + (oGrid.inputclass==null ? "" : " CLASS="+oGrid.inputclass) + " " + oCell.tags + "></TD>";
  }
  else if ("hidden"==oCell.type) {
    return "<TD><INPUT TYPE=hidden NAME=" + oCell.name + " VALUE='" + oCell.value + "' " + oCell.tags + "></TD>";  
  }
}

//-----------------------------------------------------------------------------

function GridDraw(oGrid,sOnElement,sHeader,sFooter) {
  var iRows = oGrid.rowcount;
  var iCols = oGrid.colcount;
  var oElement = document.getElementById(sOnElement);
  var oGridRow;
  var sHTML;
  
  sHTML = sHeader;
  
  for (var r=0;r<iRows; r++) {
    oGridRow = (oGrid.rows)[r];
    if (null!=oGridRow) {
      sHTML += "</TR>";
      for (var c=0;c<iCols; c++) {
        sHTML += GridDrawCell((oGridRow.cols)[c]);
      } // next
      sHTML += "</TR>";
    } // fi (oGridRow)
  } // next
      
  oElement.innerHTML = sHTML + sFooter;
}

//-----------------------------------------------------------------------------

function RemoveHTMLTags(str) {
  var len = str.length;
  var wrt = true;
  var ret = "";
  var chr;
  
  for (var c=0; c<len; c++) {
    chr = str.charAt(c); 
    switch (chr) {
      case '<':
        wrt = false;
        break;
      case '>':
        wrt = true;
        break;
      default:
        if (wrt) ret += chr;  
    }
  } // next
  
  return ret;
} 

//-----------------------------------------------------------------------------

function GridGetCellValue(oGrid,iCol,iRow) {
  var oRow = (oGrid.rows)[iRow];
  var oCel;
  
  if (null==oRow)
    return null;
  else {
    oCel = (oRow.cols)[iCol];
    if ("html"==oCel.type)
      return RemoveHTMLTags(oCel.value);
    else
      return String(oCel.value==null ? "" : oCel.value);
  }
}

//-----------------------------------------------------------------------------

function GridSetCellValue(oGrid,iCol,iRow,sValue) {	
  var oRow = (oGrid.rows)[iRow];
  var oCel;
  
  oCel = (oRow.cols)[iCol];
  oCel.value = sValue;    
}

//-----------------------------------------------------------------------------

function GridToString(oGrid,sColDelimiter,sRowDelimiter) {
  var iRows = oGrid.rowcount;
  var iCols = oGrid.colcount;
  var oGridRow;
  var oGridCell;
  var sRetVal = "";
  
  for (var r=0;r<iRows; r++) {
    oGridRow = (oGrid.rows)[r];
    if (null!=oGridRow) {
      if (r>0) sRetVal += sRowDelimiter;
      for (var c=0;c<iCols; c++) {
        oGridCell = (oGridRow.cols)[c];  
        if (c>0) sRetVal += sColDelimiter;
        if ("hidden"==oGridCell.type || "text"==oGridCell.type)
	        sRetVal += oGridCell.value;
	      else if ("html"==oGridCell.type)
	        sRetVal += RemoveHTMLTags(oGridCell.value);
      } // next (c)
    } // fi (oGridRow)
  } // next (r)
  
  return sRetVal;
} // GridToString

//-----------------------------------------------------------------------------

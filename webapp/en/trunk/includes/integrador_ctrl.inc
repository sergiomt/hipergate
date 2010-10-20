<table border="0" cellpadding="2" cellspacing="0">
  <tr>
    <td><img src="../../../../../../skins/xp/hglogopeq.jpg" border="0" align="middle"></img></td>
    <td align="middle" valign="middle"><a style="color:#0066cc" href="javascript:mostrarInt()"><font face="Verdana,Arial,Helvetica,sans-serif" size="1" color="#0066cc" bgcolor="#ffffff"><b>Edit Panel</b></font></a></td>
    <td>&nbsp;&nbsp;&nbsp;&nbsp;</td>
    <td align="middle" valign="middle"><a style="color:#0066cc" href="javascript:document.location='../../../../../../webbuilder/list_choose.jsp?gu_pageset='+frmLstBlocks.gu_pageset.value+'&id_command=MAIL'"><font face="Verdana,Arial,Helvetica,sans-serif" size="1" color="#0066cc" bgcolor="#ffffff"><b>Schedule Batch</b></font></a></td>
  </tr>
</table>
<script language="JavaScript" type="text/javascript">
var background = "";
var wNewBlock = null;
function setNull() {
	wNewBlock = null;
}
function setFocus() {
	if (wNewBlock!=null) 
	{
	  if (!wNewBlock.closed)
	  {
	   wNewBlock.focus();	
	   self.setTimeout('setFocus()', 1000);
	  }
	}
}
function setFocus2() {
	if (wNewBlock!=null) 
	  if (!wNewBlock.closed)
	   wNewBlock.focus();	
}

function reload()
{
	var lastLocation = document.location;
	document.location = lastLocation;
}

function changeStyles()
{
	var sPage = new String("../../../../../../webbuilder/wb_style_edit.jsp?doctype=newsletter&file_template=" + frmLstBlocks.file_template.value + "&file_pageset=" + frmLstBlocks.file_pageset.value + "&gu_microsite=" + frmLstBlocks.gu_microsite.value + "&gu_workarea=" + frmLstBlocks.gu_workarea.value + "&gu_pageset=" + frmLstBlocks.gu_pageset.value + "&gu_page=" + frmLstBlocks.gu_page.value + "&file_pageset=" + frmLstBlocks.file_pageset.value);
	var wNewBlock = window.open(sPage,"wChangeStyle","top=100,left=100,height=260,width=200");
}

function addNewBlock()
{
	var sPage = new String("../../../../../../webbuilder/wb_metablocklist.jsp?gu_microsite=" + frmLstBlocks.gu_microsite.value + "&gu_workarea=" + frmLstBlocks.gu_workarea.value + "&gu_pageset=" + frmLstBlocks.gu_pageset.value + "&gu_page=" + frmLstBlocks.gu_page.value + "&file_pageset=" + frmLstBlocks.file_pageset.value + "&doctype=" + frmLstBlocks.doctype.value);
	wNewBlock = window.open(sPage,"wNewBlock","top=100,left=100,height=520,width=200");
	self.setTimeout('setFocus()', 1000);
}

function activateBlock(id)
{
  eval("if (document.getElementById('"+id+"')) document.getElementById('"+id+"').style.backgroundColor=background;");
}

function deactivateBlock(id)
{
  eval("if (document.getElementById('"+id+"')) document.getElementById('"+id+"').style.backgroundColor=background;");
}

function deleteCheckedBlocks()
{
	var i;
	var encontrados = 0;
	var sPage = new String("../../../../../../webbuilder/wb_removeblock.jsp?gu_workarea=" + frmLstBlocks.gu_workarea.value + "&gu_pageset=" + frmLstBlocks.gu_pageset.value + "&gu_page=" + frmLstBlocks.gu_page.value + "&file_pageset=" + frmLstBlocks.file_pageset.value + "&doctype=" + frmLstBlocks.doctype.value + "&");
	var sBlockList = new String("block_list=");
	for(i=0; i<frmLstBlocks.elements.length; i++)
	{
		if (frmLstBlocks.elements[i].checked)
		{
		  encontrados++;
		  sBlockList += frmLstBlocks.elements[i].name + ",";
		}
	}
	if (encontrados==0) 
	{
		alert("There are not selected blocks");
	}
	else
	{	if (window.confirm("Do you want to remove definetively&nbsp;" + encontrados + " selected blocks?"))
		{
			sBlockList = sBlockList.substr(0,sBlockList.length-1);
			var w = window.open(sPage + sBlockList,"wRemoveBlock","top=20,left=20,height=120,width=240,menubar=no");

		}
	}
}

</script>
<hr/>
<br/>

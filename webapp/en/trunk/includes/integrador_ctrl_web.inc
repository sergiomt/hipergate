<table border="0" cellpadding="2" cellspacing="0">
  <tr>
    <td valign="top"><img src="../../../../../../skins/xp/hglogopeq.jpg" border="0"></td>
    <td valign="top"><a style="color:#0066cc" href="javascript:mostrarInt()"><font face="Verdana" size="1" color="#0066cc"><b>Control Panel</b></font></a>&nbsp;|&nbsp;
      <a style="color:#0066cc" href="javascript:addPage()"><font face="Verdana" size="1"><b>New Page</b></font></a>&nbsp;|&nbsp;
      <a style="color:#0066cc" href="javascript:goPage()"><font face="Verdana" size="1"><b>Edit Page</b></font></a>
    </td>
    <td><select style="font-size:14" name="selPage" id="selPage">:selPageOptions</select></td>
    <td valign="top"><a style="color:#0066cc" href="javascript:delPage()"><font face="Verdana" size="1"><b>Delete this Page</b></font></a>&nbsp;|&nbsp;</td>
  </tr>
  <tr>
    <td></td>
    <td colspan="3"><!--navigation--></td>
  </tr>
</table>
<script language="JavaScript" type="text/javascript">
var background="";
var wNewBlock = null;
function setNull() {
  wNewBlock = null;
}
function setFocus() {
  if (wNewBlock!=null)  {
    if (!wNewBlock.closed) {
      wNewBlock.focus();	
      self.setTimeout('setFocus()', 1000);
    }
  }
}
function goPage() {
  var x=document.all.selPage.options[document.all.selPage.selectedIndex].text;
  document.location = "../../../../../../webbuilder/wb_document.jsp?gu_workarea="+frmLstBlocks.gu_workarea.value+"&gu_pageset="+frmLstBlocks.gu_pageset.value+"&doctype=website&gu_page=" + document.all.selPage.options[document.all.selPage.selectedIndex].value + "&page="+x.replace(" ","_");
}
function goPageN(nm,id) {
  var x=document.all.selPage.options[document.all.selPage.selectedIndex].text;
  document.location = "../../../../../../webbuilder/wb_document.jsp?gu_workarea="+frmLstBlocks.gu_workarea.value+"&gu_pageset="+frmLstBlocks.gu_pageset.value+"&doctype=website&gu_page=" + document.all.selPage.options[document.all.selPage.selectedIndex].value + "&page="+x.replace(" ","_")+"&"+nm+"="+id;
}
function reload() {
  var lastLocation = document.location;document.location=lastLocation;
}
function changeStyles() {
  var sPage=new String("../../../../../../webbuilder/wb_style_edit.jsp?doctype=website&file_template="+frmLstBlocks.file_template.value+"&file_pageset="+frmLstBlocks.file_pageset.value+"&gu_microsite="+frmLstBlocks.gu_microsite.value+"&gu_workarea="+frmLstBlocks.gu_workarea.value+"&gu_pageset="+frmLstBlocks.gu_pageset.value+"&gu_page="+frmLstBlocks.gu_page.value+"&file_pageset="+frmLstBlocks.file_pageset.value);ç
  wNewBlock=window.open(sPage,"wChangeStyle","top=100,left=100,height=260,width=200");
}
function delPage() {
  var sPage=new String("../../../../../../webbuilder/wb_page_delete.jsp?file_template="+frmLstBlocks.file_template.value+"&gu_page="+frmLstBlocks.gu_page.value+"&gu_workarea="+frmLstBlocks.gu_workarea.value+"&gu_pageset="+frmLstBlocks.gu_pageset.value+"&file_pageset="+frmLstBlocks.file_pageset.value);document.location=sPage;
}
function addPage() {
  var sPage=new String("../../../../../../webbuilder/wb_containerlist.jsp?id_domain="+frmLstBlocks.id_domain.value+"&gu_microsite="+frmLstBlocks.gu_microsite.value+"&gu_workarea="+frmLstBlocks.gu_workarea.value+"&gu_pageset="+frmLstBlocks.gu_pageset.value+"&gu_page="+frmLstBlocks.gu_page.value+"&file_pageset="+frmLstBlocks.file_pageset.value);
  var wNewPage=window.open(sPage,"wNewPage","top=100,left=100,height=320,width=400");
}
function addNewBlock() { 
  var sPage=new String("../../../../../../webbuilder/wb_metablocklist.jsp?doctype="+frmLstBlocks.doctype.value+"&page="+escape(frmLstBlocks.page_title.value)+"&gu_microsite="+frmLstBlocks.gu_microsite.value+"&gu_workarea="+frmLstBlocks.gu_workarea.value+"&gu_pageset="+frmLstBlocks.gu_pageset.value+"&gu_page="+frmLstBlocks.gu_page.value+"&file_pageset="+frmLstBlocks.file_pageset.value);
  wNewBlock=window.open(sPage,"wNewBlock","top=100,left=100,height=320,width=200");
  self.setTimeout('setFocus()', 1000);
}
function activateBlock(id) {
  eval("if (document.getElementById('"+id+"')) { background=document.getElementById('"+id+"').style.backgroundColor; document.getElementById('"+id+"').style.backgroundColor='#FFC511'; }");
}
function deactivateBlock(id) {
  eval("if (document.getElementById('"+id+"')) document.getElementById('"+id+"').style.backgroundColor=background;");
}
function deleteCheckedBlocks(){
  var fnd=0;
  var sPage=new String("/webbuilder/wb_removeblock.jsp?gu_workarea="+frmLstBlocks.gu_workarea.value+"&gu_pageset="+frmLstBlocks.gu_pageset.value+"&gu_page="+frmLstBlocks.gu_page.value+"&file_pageset="+frmLstBlocks.file_pageset.value+"&doctype="+frmLstBlocks.doctype.value+"&");
  var sBlockList=new String("block_list=");
  for (var i=0;i<frmLstBlocks.elements.length;i++) {
    if (frmLstBlocks.elements[i].checked){
      fnd++;
      sBlockList+=frmLstBlocks.elements[i].name+",";
    }
  } // next (i)
  if (fnd==0)
    alert("There are not selected blocks");
  else {
    if (window.confirm("Do you want to remove selected blocks?")) {
      sBlockList=sBlockList.substr(0,sBlockList.length-1);var w=window.open(sPage+sBlockList,"wRemoveBlock","top=20,left=20,height=120,width=240,menubar=no");
    }
  }
}
</script>
<hr/>

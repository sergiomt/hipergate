
  /*
  Functions to add/remove rows dinamicaly
  Given table :
  <TABLE ID='myTable'>
  	<tr>
  		<td colspan=4></td>
  	</tr>
  </TABLE>		
  
  and variable
  
  var fila;
    
  fila = '<TD CLASS="formstrong" WIDTH="1" BGCOLOR="#666666"><IMG SRC="../images/images/spacer.gif" WIDTH="1" BORDER="0"></TD>';            
  fila += '<TD CLASS="formstrong" >&nbsp;Dominio:</Td>';
  fila += '<TD CLASS="formstrong" ><INPUT TYPE="text" CLASS="textsmall" NAME="nm_domain" STYLE="height:20" MAXLENGTH="32" SIZE="16" VALUE="TEST1"></TD>';
  fila += '<TD CLASS="formstrong" WIDTH="1" BGCOLOR="#666666"><IMG SRC="../images/images/spacer.gif" WIDTH="1" BORDER="0"></TD>';            
  
  
  addRow('myTable','fila1',fila,1)
  adds a rows of 4 cells to row identified by 'fila1' : <TR ID='fila1' .... at position 1
  notes :
  	(posicion > 0 and posicion < number of table's rows)
  	never put blank spaces in the tags: '</TD>' bien, '</TD > � < /TD>...' mal
  
  deleteRow(('myTable','fila1')
  removes a row
      
  */
  
      
  function addRow(idTable,IdTr,sHtmlTr,iIndex)
  {
    var pos = -1;
    if (iIndex != null)
      	pos = iIndex;
      	
    if (document.all[idTable].rows(IdTr) == null)
    {
    	var table = document.all[idTable];
    	var tr = table.insertRow(pos);
    	tr.id = IdTr;
    	
    	    	
    	strcells = new String(sHtmlTr);
    	rExp = new REgExp("<[/][Tt][Dd]>","gi");
    	strcells = strcells.replace(rExp,'</td>');
    	
    	    	    	   	
    	var array_lcells = strcells.split('</td>');
    	for (var i=0;i<array_lcells.length-1;i++)
    	{
    		
    		arrayTd_attr_text = array_lcells[i].split('>');
    		strAttr = arrayTd_attr_text[0];
    		
    		pos_mayor = array_lcells[i].indexOf('>');
    		strText = array_lcells[i].substring(pos_mayor+1,array_lcells[i].length);
    		
    	    		
    		var td1 = document.createElement(strAttr + '>')
    		td1.innerHTML = strText;
    		
    		tr.appendChild(td1);
    		
      	}	
    	
    }
    
  }
  
    
  function deleteRow(idTable,IdTr)
  {
     if (document.all[idTable].rows(IdTr) != null)
     	document.all[idTable].rows(IdTr).removeNode(true);
  }
  
    
  function Maximiza(idTable)
  {
  	addRow(idTable,'dominio',fila4,5);
  	
  	addRow(idTable,'area',fila5,6);
  	document.all['flecha'].innerHTML='<a style="text-decoration:none" href="javascript:Minimiza(\'myTable\')">&lt;&lt;</a>';
  	//falta el focus sobre el dominio
  	
  	addRow(idTable,'dominio','<td WIDTH="1" bgColor="#666666">dominio</td><td atributos >row1_column1</td>',2);
  	addRow(idTable,'area','<td>area</td><td>row1_column1</td>',3);
  }
  
  function Minimiza(idTable)
  {
  	deleteRow(idTable,'dominio');
  	deleteRow(idTable,'area');
  	document.all['flecha'].innerHTML='<a style="text-decoration:none" href="javascript:Maximiza(\'myTable\')">&gt;&gt;</a>';
  	
  }
  
               
  
//  End -->

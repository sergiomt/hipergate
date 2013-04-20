//----------Popup Menu Created using AllWebMenus ver 1.3-#360.---------------
awmLibraryPath='/awmdata';
awmImagesPath='/awmdata';
if (awmAltUrl!='') {
if (navigator.appName + navigator.appVersion.substring(0,1)!="Netscape5" && !document.all && !document.layers) window.location.replace(awmAltUrl);
}
var awmMenuPath;
if (!awmMenuPath) {
if (document.all) mpi=document.all['awmMenuPathImg'].src;
if (document.layers) mpi=document.images['awmMenuPathImg'].src;
if (navigator.appName + navigator.appVersion.substring(0,1)=="Netscape5") mpi=document.getElementById('awmMenuPathImg').src;
awmMenuPath=mpi.substring(0,mpi.length-16);}
document.write("<SCRIPT SRC='"+awmMenuPath+awmLibraryPath+"/awm13.js'><\/SCRIPT>");
function awmBuildMenu(){
document.write('<STYLE>.ST1 {position:absolute; top:0; left:0; visibility:hidden;}.ST2 {position:absolute; visibility:inherit; border-style:outset; border-width:2; border-color:#C0C0C0;}.ST3 {position:absolute; visibility:hidden; z-index:1000;}</STYLE>');
var n=null;
awmm=new Array();
awmm[0]=new awmCreateM(1,1,1,0,4,4,1,-4,1);
awmm[0].cont[0]=awmCreateCont(0,0,0,"ST3","ST1","ST2","><TD ALIGN=CENTER><FONT FACE=sans-serif SIZE=2 COLOR=#FFFFFF><NOBR>[~Archivo~]:</NOBR></FONT></TD></TABLE>","#5B5B5B","#C0C0C0",n,0,2,0,1,4);
awmm[0].cont[0].it[0]=new awmCreateIt("ST1","ST1","ST1","LEFT","sans-serif","2","#000000",0,0,0,"",0,0,0,"[~Nuevo~]","Nuevo","",0,0,0,"LEFT","sans-serif","2","#FFFFFF",0,0,0,"",0,0,0,"[~Nuevo~]","Nuevo","",0,0,0,n,n,n,n,n,n,n,n,n,n,n,n,n,n,n,n,n,n,"#000080","#000080",n,n,n,0,0,0,n,n,"new","",1,3);
awmm[0].cont[0].it[1]=new awmCreateIt("ST1","ST1","ST1","LEFT","sans-serif","2","#000000",0,0,0,"",0,0,0,"[~Edición~]","Edición","",0,0,0,"LEFT","sans-serif","2","#FFFFFF",0,0,0,"",0,0,0,"[~Edición~]","Edición","",0,0,0,n,n,n,n,n,n,n,n,n,n,n,n,n,n,n,n,n,n,"#000080","#000080",n,n,n,0,0,0,n,n,"new","",2,3);
awmm[0].cont[0].it[2]=new awmCreateIt("ST1","ST1","ST1","LEFT","sans-serif","2","#000000",0,0,0,"",0,0,0,"[~Ver~]","Ver","",0,0,0,"LEFT","sans-serif","2","#FFFFFF",0,0,0,"",0,0,0,"[~Ver~]","Ver","",0,0,0,n,n,n,n,n,n,n,n,n,n,n,n,n,n,n,n,n,n,"#000080","#000080",n,n,n,0,0,0,n,n,"new","",3,3);
awmm[0].cont[0].it[3]=new awmCreateIt("ST1","ST1","ST1","CENTER","sans-serif","2","#000000",0,0,0,"",0,0,0,"[~Eliminar~]","Eliminar","",0,0,0,"CENTER","sans-serif","2","#FFFFFF",0,0,0,"",0,0,0,"[~Eliminar~]","Eliminar","",0,0,0,n,n,n,n,n,n,n,n,n,n,n,n,n,n,n,n,n,n,"#000080","#000080",n,n,n,0,0,0,"deleteProducts()",n,n,"",0,3);
awmm[0].cont[1]=new awmCreateCont(1,0,0,"ST3","","ST2","","#5B5B5B","#C0C0C0",n,0,2,1,0,0);
awmm[0].cont[1].it[0]=new awmCreateIt("ST1","ST1","ST1","LEFT","sans-serif","2","#000000",0,0,0,"",0,0,0,"[~Enlace~]","Enlace","",0,0,0,"LEFT","sans-serif","2","#FFFFFF",0,0,0,"",0,0,0,"[~Enlace~]","Enlace","",0,0,0,n,n,n,n,n,n,n,n,n,n,n,n,n,n,n,n,n,n,"#000080","#000080",n,n,n,0,0,0,"createLink()",n,n,"",0,3);
awmm[0].cont[1].it[1]=new awmCreateIt("ST1","ST1","ST1","LEFT","sans-serif","2","#000000",0,0,0,"",0,0,0,"[~Documento~]","Documento","",0,0,0,"LEFT","sans-serif","2","#FFFFFF",0,0,0,"",0,0,0,"[~Documento~]","Documento","",0,0,0,n,n,n,n,n,n,n,n,n,n,n,n,n,n,n,n,n,n,"#000080","#000080",n,n,n,0,0,0,"createDocument()",n,n,"",0,3);
awmm[0].cont[2]=new awmCreateCont(2,0,0,"ST3","","ST2","","#5B5B5B","#C0C0C0",n,0,2,1,0,4);
awmm[0].cont[2].it[0]=new awmCreateIt("ST1","ST1","ST1","LEFT","sans-serif","2","#000000",0,0,0,"",0,0,0,"[~Buscar~]...","Buscar...","",0,0,0,"LEFT","sans-serif","2","#FFFFFF",0,0,0,"",0,0,0,"[~Buscar~]...","Buscar...","",0,0,0,n,n,n,n,n,n,n,n,n,n,n,n,n,n,n,n,n,n,"#000080","#000080",n,n,n,0,0,0,"searchProduct()",n,n,"",0,3);
awmm[0].cont[2].it[1]=new awmCreateIt("ST1","ST1","ST1","LEFT","sans-serif","2","#000000",0,0,0,"",0,0,0,"[~Copiar a la Categoría~]...","Copiar_a_la_Categoría...","",0,0,0,"LEFT","sans-serif","2","#FFFFFF",0,0,0,"",0,0,0,"[~Copiar a la Categoría~]...","Copiar_a_la_Categoría...","",0,0,0,n,n,n,n,n,n,n,n,n,n,n,n,n,n,n,n,n,n,"#000080","#000080",n,n,n,0,0,0,"copyProduct()",n,n,"",0,3);
awmm[0].cont[2].it[2]=new awmCreateIt("ST1","ST1","ST1","LEFT","sans-serif","2","#000000",0,0,0,"",0,0,0,"[~Mover a la Categoría~]...","Mover_a_la_Categoría...","",0,0,0,"LEFT","sans-serif","2","#FFFFFF",0,0,0,"",0,0,0,"[~Mover a la Categoría~]...","Mover_a_la_Categoría...","",0,0,0,n,n,n,n,n,n,n,n,n,n,n,n,n,n,n,n,n,n,"#000080","#000080",n,n,n,0,0,0,"moveProduct()",n,n,"",0,3);
awmm[0].cont[2].it[3]=new awmCreateIt("ST1","ST1","ST1","LEFT","sans-serif","2","#000000",0,0,0,"",0,0,0,"[~Seleccionar todo~]","Seleccionar_todo","",0,0,0,"LEFT","sans-serif","2","#FFFFFF",0,0,0,"",0,0,0,"[~Seleccionar todo~]","Seleccionar_todo","",0,0,0,n,n,n,n,n,n,n,n,n,n,n,n,n,n,n,n,n,n,"#000080","#000080",n,n,n,0,0,0,"selectAll()",n,n,"",0,3);
awmm[0].cont[2].it[4]=new awmCreateIt("ST1","ST1","ST1","LEFT","sans-serif","2","#000000",0,0,0,"",0,0,0,"[~Invertir Selección~]","Invertir_Selección","",0,0,0,"LEFT","sans-serif","2","#FFFFFF",0,0,0,"",0,0,0,"[~Invertir Selección~]","Invertir_Selección","",0,0,0,n,n,n,n,n,n,n,n,n,n,n,n,n,n,n,n,n,n,"#000080","#000080",n,n,n,0,0,0,"invertSelection()",n,n,"",0,3);
awmm[0].cont[3]=new awmCreateCont(3,0,0,"ST3","","ST2","","#5B5B5B","#C0C0C0",n,0,2,1,0,4);
awmm[0].cont[3].it[0]=new awmCreateIt("ST1","ST1","ST1","LEFT","sans-serif","2","#000000",0,0,0,"",0,0,0,"[~Elegir columnas~]...","Elegir_columnas...","",0,0,0,"LEFT","sans-serif","2","#FFFFFF",0,0,0,"",0,0,0,"[~Elegir columnas~]...","Elegir_columnas...","",0,0,0,n,n,n,n,n,n,n,n,n,n,n,n,n,n,n,n,n,n,"#000080","#000080",n,n,n,0,0,0,"chooseColumns()",n,n,"",0,3);
awmm[0].cont[3].it[1]=new awmCreateIt("ST1","ST1","ST1","LEFT","sans-serif","2","#000000",0,0,0,"",0,0,0,"[~Imprimir lista~]...","Imprimir_lista...","",0,0,0,"LEFT","sans-serif","2","#FFFFFF",0,0,0,"",0,0,0,"[~Imprimir lista~]...","Imprimir_lista...","",0,0,0,n,n,n,n,n,n,n,n,n,n,n,n,n,n,n,n,n,n,"#000080","#000080",n,n,n,0,0,0,"printList()",n,n,"",0,3);
awmm[0].cont[3].it[2]=new awmCreateIt("ST1","ST1","ST1","LEFT","sans-serif","2","#000000",0,0,0,"",0,0,0,"[~Actualizar~]","Actualizar","",0,0,0,"LEFT","sans-serif","2","#FFFFFF",0,0,0,"",0,0,0,"[~Actualizar~]","Actualizar","",0,0,0,n,n,n,n,n,n,n,n,n,n,n,n,n,n,n,n,n,n,"#000080","#000080",n,n,n,0,0,0,"updateList()",n,n,"",0,3);
awmInitMenu();}

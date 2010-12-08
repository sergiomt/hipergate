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
awmm[0]=new awmCreateM(1,0,1,0,12,34,1,-4,1);
awmm[0].cont[0]=awmCreateCont(0,0,0,"ST3","ST1","ST2","><TD ALIGN=CENTER><FONT FACE=sans-serif SIZE=2 COLOR=#FFFFFF><NOBR>[~Permisos~]:</NOBR></FONT></TD></TABLE>","#5B5B5B","#C0C0C0",n,0,2,0,1,6);
awmm[0].cont[0].it[0]=new awmCreateIt("ST1","ST1","ST1","CENTER","sans-serif","2","#000000",0,0,0,"",0,0,0,"[~Usuarios~]","Usuarios","",0,0,0,"CENTER","sans-serif","2","#FFFFFF",0,0,0,"",0,0,0,"[~Usuarios~]","Usuarios","",0,0,0,n,n,n,n,n,n,n,n,n,n,n,n,n,n,n,n,n,n,"#000080","#000080",n,n,n,0,0,0,"editUserPerms()",n,n,"",0,3);
awmm[0].cont[0].it[1]=new awmCreateIt("ST1","ST1","ST1","CENTER","sans-serif","2","#000000",0,0,0,"",0,0,0,"[~Grupos~]","Grupos","",0,0,0,"CENTER","sans-serif","2","#FFFFFF",0,0,0,"",0,0,0,"[~Grupos~]","Grupos","",0,0,0,n,n,n,n,n,n,n,n,n,n,n,n,n,n,n,n,n,n,"#000080","#000080",n,n,n,0,0,0,"editGroupPerms()",n,n,"",0,3);
awmInitMenu();}

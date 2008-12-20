
    var g_cdoc = parent.catadmin;
    var g_cexe = parent.catexec;
  
    // event
    var g_event;
    var g_sourceURI;
    var g_source;
    var g_destination;
    var g_parent;
    var g_defaultparent;
    var g_text;
    var g_location;

    var id_category = "";
    var id_parent_category = "";    
    var tr_category = "";

    // ----------------------------------------------------------------
    
    function expandDipuTree(dipuapplet, base, category) {
      var xptr = "#xpointer(has/*/haslink/link/hasdestination/target/s)";
      var ptrs = diputree.lookupAll(base, xptr, ",").split(",");
      var catn;
      var catg;
      var prnt;
      var stat;
      
      for (var p=0; p<ptrs.length; p++) {
        catg = dipuapplet.getValue(ptrs[p]);
        if ((category==catg) || (("#"+category)==catg)) {          
          prnt = dipuapplet.lookup(base,"#xpointer(has/*[" + (p+1) + "])");	                  

          dipuapplet.unbindAll(prnt,"#xpointer(has/*)");
	  
            window.status = "Cargando categorías...";
            dipuapplet.loadFromURI (prnt, "pickchilds.jsp?Skin=" + getCookie("skin") + "&Lang=" + getUserLanguage() + "&Parent=" + catg + "&Label=" + escape("cerdito"));
            window.status = "";
            
          
        } // fi()
      } // next            
    } // expandDipuTree()

    // ----------------------------------------------------------------
    
    function handleDipuEvent(dipuapplet) {    
      
      // event
      g_event = dipuapplet.lookup ("#/1", "#xpointer(hasevent/*)");
    
      // source
      g_sourceURI = dipuapplet.lookup(g_event,"#xpointer(hassource/uri/s)");
      g_source = diputree.lookup("#/1", dipuapplet.getValue(g_sourceURI));
      
      // destination category identifier
      g_destination = dipuapplet.lookup(g_source,"#xpointer(haslink/link/hasdestination/target/s)");
      
      if (g_source.length>7)
        g_parent = dipuapplet.lookup(g_source.substr(0,g_source.length-4),"#xpointer(haslink/link/hasdestination/target/s)");
      else
        g_parent = dipuapplet.lookup(g_source.substr(0,g_source.length),"#xpointer(haslink/link/hasdestination/target/s)");
        
      // category text
      g_text = dipuapplet.lookup(g_source,"#xpointer(lt)");

      g_location = dipuapplet.lookup(g_event,"#xpointer(haslocation/*)");      
	
      id_category = diputree.getValue(g_destination);       
      if (id_category.charCodeAt(0)==35) id_category = id_category.substr(1);

      tr_category = diputree.getValue(g_text);
      
      if (g_parent.length>0) {
        id_parent_category = diputree.getValue(g_parent);
        if (id_parent_category.charCodeAt(0)==35) id_parent_category = id_parent_category.substr(1);
      }
      else
        id_parent_category = "";
        
    } // handleDipuEvent()

    // ----------------------------------------------------------------
    
    function dipuClick() {
       var diputree = window.document.diputree;
       
       if (navigator.appName=="Microsoft Internet Explorer")
         window.document.body.style.cursor = "wait";
       
       handleDipuEvent(diputree);
                         
       // solo cargar los hijos cuando se pincha en el handle 

       if ("handle"==diputree.getName(g_location)) {      

	 // handle state
         var state = diputree.lookup(g_source,"#xpointer(hasstate)");
	 	 
	 if ("closed"==diputree.getName(state+"/1")) {
           
           // si el id de la categoria empieza por una almohadilla
           // entonces es que sus hijos ya han sido cargados
           
           if (35!=id_category.charCodeAt(0)) {
             window.status = "Cargando categorías...";
             diputree.loadFromURI (g_source, "pickchilds.jsp?Skin=" + getCookie("skin") + "&Lang=" + getUserLanguage() + "&Parent=" + id_category + "&Label=" + escape(tr_category));
             window.status = "";
             
             g_destination = diputree.lookup(g_source,"#xpointer(haslink/link/hasdestination/target/s)");
             diputree.setValue(g_destination,"#"+id_category); 
           } // endif (loaded)
           
         } // endif (closed)
       }      
       else // Mostrar la categoría seleccionada actualmente en la textbox bajo el menu
         document.forms[0].catname.value = tr_category;
       // endif (handle) 

       if (navigator.appName=="Microsoft Internet Explorer")
         window.document.body.style.cursor = "auto";

       // g_cdoc.document.location = "catprods.jsp?id_category=" + (35!=id_category.charCodeAt(0) ? id_category : id_category.substr(1)) + "&tr_category=" + escape(tr_category);             
    } // dipuClick()         

    // ----------------------------------------------------------------
        
    function createCategory() {
      var diputree = window.document.diputree;
                    
      if (diputree.getValue(g_destination).length==0 && g_defaultparent.length==0)
	alert ("[~Debe seleccionar primero una categoria padre para poder crear otra nueva categoria.~]");        
      else {
        if (id_parent_category.length==0 && g_defaultparent.length==0) {
          alert ("[~No esta permitido crear categorias raiz~]");
      	  return false;
      	}
      	
      	if (id_parent_category.length==0) {
          self.open ("catedit.jsp?id_domain=" + getCookie("domainid") + "&id_parent_cat=" + g_defaultparent, "newcategory", "directories=no,toolbar=no,menubar=no,width=480,height=420");
      	} else {
          if (id_category.charCodeAt(0)==35)
            self.open ("catedit.jsp?id_domain=" + getCookie("domainid") + "&id_parent_cat=" + id_category.substr(1), "newcategory", "directories=no,toolbar=no,menubar=no,width=480,height=420");
          else
            self.open ("catedit.jsp?id_domain=" + getCookie("domainid") + "&id_parent_cat=" + id_category, "newcategory", "directories=no,toolbar=no,menubar=no,width=480,height=420");
        }
      }
    } // createCategory()

    // ----------------------------------------------------------------

    function modifyCategory() {
      var diputree = window.document.diputree;
            	
      if (id_category.length==0) {
        alert ("[~Debe seleccionar una categoría en el árbol antes de poder editarla~]");
      } else {
        var id_cat = (id_category.charCodeAt(0)==35 ? id_category.substr(1) : id_category);
        var id_par = (id_parent_category.charCodeAt(0)==35 ? id_parent_category.substr(1) : id_parent_category);
          self.open ("catedit.jsp?id_domain=" + getCookie("domainid") + "&id_category=" + id_cat + "&id_parent_cat=" + id_par, "", "directories=no,toolbar=no,menubar=no,width=480,height=460");
      }
    } // modifyCategory()

    // ----------------------------------------------------------------

    function deleteCategory() {
      var diputree = window.document.diputree;

      if (id_category.length==0) {
        alert ("[~Para eliminar una Categoria debe seleccionarla primero en el arbol de navegacion~]");
      } else {                   
        if (id_parent_category.length==0 && g_defaultparent.length==0) {
	  alert ("No esta permitido eliminar categorias raiz");	  
        } else if (window.confirm("[~Esta seguro de que desea eliminar la categoria seleccionada?~]")) {
          if (id_category.charCodeAt(0)==35)
            self.open ("catedit_del.jsp?checkeditems=" + id_category.substr(1), "", "directories=no,toolbar=no,menubar=no,width=400,height=300");
          else
            self.open ("catedit_del.jsp?checkeditems=" + id_category, "", "directories=no,toolbar=no,menubar=no,width=400,height=300");
        }
      }
    } // deleteCategory()
      
    // ----------------------------------------------------------------
    
    function showFiles () {
      var frm = document.forms[0];
      var cad = window.parent.parent.catadmin;
      
      if (frm.catname.value.length>0)     
        cad.location = "catprods.jsp?id_category=" + id_category + "&tr_category=" + escape(frm.catname.value);
      } // showFiles()

    // --------------------------------------------------------
    
    function searchFile () {
      var cad = window.parent.parent.catadmin;
      var sought = window.prompt("[~Introduzca el nombre de archivo, enlace o categoría a buscar~]","");
      
      if (null!=sought)
        if (sought.length>0)
          cad.location = "catfind.jsp?tx_sought=" + escape(sought);
    }
    
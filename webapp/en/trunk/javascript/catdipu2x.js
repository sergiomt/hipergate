    var g_bLoading  = false;
    var g_intervalID;
    var g_cRetry;
    var g_idParent;

    var g_cdoc = parent.catadmin;
    var g_cexe = parent.catexec;
        
    function onAddNodes(idParent) {
      g_cdoc.document.location = "catprods.jsp?id_category=" + idParent + "&tr_category=" + escape(document.diputree.getField("entries", idParent, 1));      
      }

    function createCategory()
      {
      var dipu = document.diputree;
      var idpc = dipu.getSelected();
      
      if ("root"==idpc)
	alert ("No esta permitido crear categorias raiz");
      else      
        self.open ("catedit.jsp?id_parent_cat=" + dipu.getField("entries", idpc, 0), "editcategory", "directories=no,toolbar=no,menubar=no,width=480,height=420");
        
        // Abrir la edición en el marco derecho
        // g_cdoc.document.location = "catedit.jsp?id_parent_cat=" + dipu.getField("entries", idpc, 0);
      }

    function modifyCategory()
      {
      var dipu = document.diputree;
      var idpc = dipu.getSelected();
      
      if (""==dipu.getField("entries", idpc, 0))      
        alert ("Debe seleccionar una categoría en el árbol antes de poder editarla");
      else
        self.open ("catedit.jsp?id_category=" + dipu.getField("entries", idpc, 0) + "&id_parent_cat=" + dipu.getField("entries", idpc, 2), "editcategory", "directories=no,toolbar=no,menubar=no,width=480,height=460");      
      }

    function deleteCategory()
      {
      var dipu = document.diputree;
      var idpc = dipu.getSelected();
      var icat = dipu.getField("entries", idpc, 0);
      
      if (""==idpc)
        alert ("Para eliminar una Categoria debe seleccionarla primero en el arbol de navegacion");
      else                   
        if ("root"==idpc)
	  alert ("No esta permitido borrar categorias raiz");
        else {
          if (window.confirm("Esta seguro de que desea borrar la categoria seleccionada?")) {
            g_cexe.document.location = "catedit_delete.jsp?id_category=" + dipu.getField("entries", idpc, 0);	    
	  }
        }     
      }    

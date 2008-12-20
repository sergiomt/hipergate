    function addChilds(idParent)
      {
      var iPos;
      var i1st;
      var sCat;
      var sLnk;

      var docData = parent.response.document.title;
      
      if (docData.substr(0,1)=="@")
	{
	if (docData.length>12)
	  {	
	  // Add link to the current node
	  i1st = docData.length-1;
          for (iPos=0; iPos<docData.length; iPos++) {
	    if (docData.charAt(iPos)=="^") {
	      i1st = iPos;
	      break;
	      }
	    }

	  sLnk = docData.substring(1, i1st+1);
	  if (sLnk.length>0 && docData.charAt(iPos)!="^")
            document.diputree.addRecords ("links", "^link" + parseInt(idParent) + "|" + sLnk);

	  if (i1st<docData.length-1) {
	    docData = docData.substring(i1st);
	  
	    // Add childs nodes to DipuTree       
            document.diputree.addRecords("entries", docData);

            for (iPos=0; iPos<docData.length; iPos++) {
	      if (docData.charAt(iPos)=="^") {
	        i1st = ++iPos;
	        while (iPos<docData.length-1 && docData.charAt(iPos+1)!="|")
	          iPos++;
	        sCat = docData.substr(i1st, iPos-i1st+1), 10;
		// parent.catexec.location.pathname
                document.diputree.addRecords("externalhandlers", "^load" + sCat + "|addNodes(" + sCat + ",'catchilds.jsp')");
                document.diputree.addRecords("selected", "^" + sCat + "|++load" + sCat);
	        }    
	      } // endfor (iPos)	       
	    } // endif (i1st<docData.length-1)

          document.diputree.setField ("entries", String(idParent), 4, "o");
	  } // endif (docData.length()>12)
	
        parent.response.location = "blank.htm";

        g_bLoading=false;
	} // end if (docData.substr(0,1)=="@")     
      }

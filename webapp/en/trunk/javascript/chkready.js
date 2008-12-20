    function clearResponse()
      {
      clearInterval(g_intervalID);
      g_intervalID = 0;
      parent.response.location = "blank.htm";
      g_bLoading=false;
      }

    function checkReady()
      {    
      var sNewData;
      var MaxRetries = 100; // Max retries for 10 seconds
      	
      sNewData = parent[1].document.title;

      if (!defined(sNewData))
	{
	if (++g_cRetry>MaxRetries) 
	  {
	  clearResponse();
	  alert ("Timeout for reading node childs expired. No child ResultSet.");
	  }
	}
      else
        {
        if (sNewData.substr(0,1)=="@")
	  // When asynchronous category exploring finishes
	  // response.title changes from "" to "@link_name^id_category|...|...|"
	  {
	  clearInterval(g_intervalID);
	  g_intervalID = 0;
	  addChilds(g_idParent);
	  }
        else
	  {
	  if (++g_cRetry>MaxRetries)
	    {
	    clearResponse();
	    alert ("Timeout for reading node childs expired. Bad child ResultSet: " + sNewData);
	    }
	  }
        }
      }

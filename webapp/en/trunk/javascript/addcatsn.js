        
    function addNodes(idParent, GetCatsServerPagePath)
      {
      // Prevent re-entering the node expansion routines
      if (g_bLoading) return;
      
      g_bLoading = true;
            
      parent.response.location = GetCatsServerPagePath + "?Parent="+parseInt(idParent);

      onAddNodes(idParent);
            
      g_cRetry=0;
      g_idParent=idParent;
      g_intervalID = setInterval(checkReady, 100);
      }

      function nullif(p) {
        return p==null ? "" : p;	
      }

      function ltrim( s )
      {
        var lpatt = new RegExp( "^ *(.*)$" );
        var parse = s.match( lpatt );
        if (null==parse)
          return "";
        else
          return parse[1];
      }

      function rtrim( s )
      {
        var rpatt = new RegExp( "^(.*[^ ]) *$" );
        var parse = s.match( rpatt );
        if (null==parse)
          return "";
	      else
          return parse[1];
      }

      function transformCase() {
        if (document.getElementById && document.createTextNode) {
          var fields = document.getElementsByTagName("input");
          for (var f=0; f<fields.length; f++) {
            if (fields[f].className.indexOf("ttu")>=0)
              fields[f].value = fields[f].value.toUpperCase();
            else if (fields[f].className.indexOf("ttl")>=0)
              fields[f].value = fields[f].value.toLowerCase();
          } // next
        } // fi
      }
      
			String.prototype.trim = function(){return (this.replace(/^[\s\xA0]+/, "").replace(/[\s\xA0]+$/, ""))}
			
			String.prototype.startsWith = function(str) {return (this.match("^"+str)==str)}
			
			String.prototype.endsWith = function(str) {return (this.match(str+"$")==str)}
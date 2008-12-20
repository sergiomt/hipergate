  function getURLParam(name,target) {
    if (null==target) target = window;
    
    var params = "&" + target.location.search.substr(1);    
    var indexa = params.indexOf("&" + name);
    var indexb;
    var retval;
        
    if (-1==indexa)
      retval = null;
    else {
      indexa += name.length+2;
      indexb = params.indexOf("&", indexa);
      indexb = (indexb==-1 ? params.length-1 : indexb-1);
      
      retval = params.substring(indexa, indexb+1);
    }
            
    return retval;        
  }
  
  function replaceURLParam(name,newvalue,target) {
    if (null==target) target = window;
    var srh = target.location.search;
    var par = srh.indexOf("&"+name+"=");
    if (par<0) {
      return srh+"&"+name+"="+escape(newvalue);
    } else {
      var amp = srh.indexOf("&",par+2);
      if (amp<0) {
      	return srh.substring(0,par)+"&"+name+"="+escape(newvalue);
      } else {
      	return srh.substring(0,par)+"&"+name+"="+escape(newvalue)+srh.substring(amp);
      }
    } // fi
  } // replaceURLParam

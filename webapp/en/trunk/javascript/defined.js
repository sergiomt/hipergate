function defined(vVar)
  {
  if (navigator.appName=="Microsoft Internet Explorer")
    if (null==vVar)
      return false;
    else
      return true ;
  else
    if (undefined==vVar)
      return false;
    else
      return true ;
  }

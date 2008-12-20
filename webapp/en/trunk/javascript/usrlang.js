  function getUserLanguage() {
    var sLang;
    
    if (navigator.appName=="Microsoft Internet Explorer")
      sLang = navigator.userLanguage.substring(0,2).toLowerCase();
    else
      sLang = navigator.language.substring(0,2).toLowerCase();

    if (sLang!="es" && sLang!="en" && sLang!="fr" && sLang!="de" && sLang!="it" && sLang!="pt" && sLang!="ca" && sLang!="eu" && sLang!="ja" && sLang!="cn" && sLang!="tw" && sLang!="fi" && sLang!="ru" && sLang!="nl" && sLang!="th" && sLang!="cs" && sLang!="uk" && sLang!="no" && sLang!="sk") sLang ="en";
    
    return sLang;
  }
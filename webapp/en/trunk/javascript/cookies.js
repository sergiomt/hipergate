/*****************************************************
  JavaScript Functions for reading and writing cookies
*/

//---------------------------------------------------------


function setCookie (name, value, expire) {
  var expires;
  
  if (expire)
   expires = "; expires=" + expire.toGMTString();
  else
    expires = "";
  
  document.cookie = name + "=" + escape(value) + expires +  "; path=/";
} // setCookie

//---------------------------------------------------------

function getCookie (Name) {
  var end;
  var search;
  var offset;
  var value;
  var allcookies = document.cookie;
  
  search = Name + "=";

  if (allcookies.length > 0) {    
    offset = allcookies.indexOf(search);

    if (offset != -1) {
      offset += search.length;
      // set index of beginning of value
      end = allcookies.indexOf(";", offset);
      // set index of end of cookie value
      if (end == -1) end = allcookies.length;

      value = unescape(allcookies.substring(offset, end));
    }
    else
      value = null;
  }
  else
    value = null;
    
  return value;
} // getCookie

//---------------------------------------------------------

function deleteCookie (name) {
  if (""!=getCookie(name)) {
    // document.cookie = name + "=" + "; expires=Fri, 01-Jan-70 00:00:01 GMT; path=/";
    document.cookie = name + "=" + "; expires=; path=/";
  }
}
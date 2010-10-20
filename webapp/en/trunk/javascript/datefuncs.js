/*********************************************
  JavaScript Functions for Date Validation
*/


/**
  * Get last day of month taking into account leap years.
  * @param month [0..11]
  * @param year  (4 digits)
*/
  function getLastDay(month, year) {

    switch(month) {
      case 0:
      case 2:
      case 4:
      case 6:
      case 7:
      case 9:
      case 11:
        return 31;
      case 3:
      case 5:
      case 8:
      case 10:
        return 30;
      case 1:
	      return ( (year%400==0) || ((year%4==0) && (year%100!=0)) ) ? 29 : 28;
    } // end switch()
    return 0;
  } // getLastDay()
  
  // ----------------------------------------------------------
  
  /**
    * Verify that a string represents a valid date
    * @param Input string
    * @param Date format. "d"  for dates with format "yyyy-MM-dd"
                          "s"  for dates with format "dd/MM/yyyy"
                          "ts" for dates with format "yyyy-MM-dd HH:mm:ss"
  */
  function isDate (dtexpr, dtformat) {
    var exp;
    var ser;
    var ret;
    var yy;
    var mm;
    var dd;
  
    if (dtformat=="d") {
      exp = new RegExp("[0-9]{4}-[0-9]{2}-[0-9]{2}");
      if (exp.test(dtexpr)) {
        ser = dtexpr.split("-");
        yy = parseInt(ser[0],10);
        mm = parseFloat(ser[1],10)-1;
        dd = parseFloat(ser[2],10);
      
        if (mm<0 || mm>12) {
          ret = false;
        }
        else if (dd>getLastDay(mm,yy)) {
          ret = false;
        }
        else
          ret = true;                
      }
      else {
        ret = false;
      }
    } else if (dtformat=="s") {
      exp = new RegExp("[0-9]{2}/[0-9]{2}/[0-9]{4}");
      if (exp.test(dtexpr)) {
        ser = dtexpr.split("/");
        yy = parseInt(ser[2],10);
        mm = parseFloat(ser[1],10)-1;
        dd = parseFloat(ser[0],10);
      
        if (mm<0 || mm>12) {
          ret = false;
        }
        else if (dd>getLastDay(mm,yy)) {
          ret = false;
        }
        else
          ret = true;                
      }
      else {
        ret = false;
      }
    } else if (dtformat=="ts") {
      exp = new RegExp("[0-9]{4}-[0-9]{2}-[0-9]{2}.[0-9]{2}:[0-9]{2}:[0-9]{2}");
      if (exp.test(dtexpr)) {
        ret = isDate(dtexpr.substr(0,10), "d");
      } else {
        ret = false;
      }      
    } else {
      ret = false;
    }
    
    return ret;
  } // isDate()
  
  // ----------------------------------------------------------
  
  /**
    * Get a Date object from a string
  */
  function parseDate(dtexpr, dtformat) {
    var d;
    var t;
    
    if (dtexpr.length==0) return null;
    
    if ("d"==dtformat) {
      d = dtexpr.split("-");
      return new Date(parseInt(d[0],10), parseFloat(d[1],10)-1, parseFloat(d[2],10));
    }
    else if ("s"==dtformat) {
      d = dtexpr.split("/");
      return new Date(parseInt(d[2],10), parseFloat(d[1],10)-1, parseFloat(d[0],10));
    }
    else if ("ts"==dtformat) {
      d = dtexpr.substr(0,10).split("-");
      t = dtexpr.substr(11).split(":");
      return new Date(parseInt(d[0],10), parseFloat(d[1],10)-1, parseFloat(d[2],10), parseFloat(t[0],10), parseFloat(t[1],10), parseFloat(t[2],10));    
    }
    else
      return null;
  } // parseDate

  // ----------------------------------------------------------

  function dateToString(dt, dtformat) {
    var year = dt.getYear();
    if (year<1970) year+=1900;
    if ("d"==dtformat) {
      return String(year)+"-"+(dt.getMonth()+1<=9 ? "0" : "")+String(dt.getMonth()+1)+"-"+(dt.getDate()<=9 ? "0" : "")+String(dt.getDate());
    } else if ("s"==dtformat) {
      return (dt.getDate()<=9 ? "0" : "")+String(dt.getDate())+"/"+(dt.getMonth()+1<=9 ? "0" : "")+String(dt.getMonth()+1)+"/"+String(year);
    } if ("ts"==dtformat) {
      return String(year)+"-"+(dt.getMonth()+1<=9 ? "0" : "")+String(dt.getMonth()+1)+"-"+(dt.getDate()<=9 ? "0" : "")+String(dt.getDate())+" "+(dt.getHours()<=9 ? "0" : "")+String(dt.getHours())+":"+(dt.getMinutes()<=9 ? "0" : "")+String(dt.getMinutes())+":"+(dt.getSeconds()<=9 ? "0" : "")+String(dt.getSeconds());
    }
  } // dateToString

 // -----------------------------------------------------------
 
   function daysDiff(dt1, dt2) {
     return Math.floor((dt1.getTime()-dt2.getTime())/86400000);
   }

 // -----------------------------------------------------------
 
   function addHours(dt1, hrs) {
     var dt2 = new Date();
     dt2.setTime(dt1.getTime()+(hrs*3600000));
     return dt2;
   }

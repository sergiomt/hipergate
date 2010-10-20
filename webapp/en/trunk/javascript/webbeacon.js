var HipergateWebBeacon = false;

function setWebBeaconCookie() {
  if (HipergateWebBeacon.readyState == 4) {
    if (HipergateWebBeacon.status == 200) {
      var ack = HipergateWebBeacon.responseText.split("|");
      if (ack[0]=="OK")
        setCookie("webbeaconid",ack[1]);
      else
      	alert ("Web Beacon Error: "+ack[1]);
      HipergateWebBeacon = false;
    }
  }
}

function webBeaconHit(url,obj) {
  if (!HipergateWebBeacon) {
    HipergateWebBeacon = createXMLHttpRequest();
    if (HipergateWebBeacon) {
			var param;
			var params = "url_page="+escape(document.URL);
      if (document.referrer!=null) params += "&url_referrer="+escape(document.referrer);

      param = getCookie("webbeaconid");
      if (param!=null && param!="") params += "&id_webbeacon="+param;

      param = getCookie("userid");
      if (param!=null && param!="") params += "&gu_user="+param;

			if (obj) params += "&gu_object="+obj;
			
			HipergateWebBeacon.onreadystatechange = setWebBeaconCookie;
	    HipergateWebBeacon.open("POST", url, true);
			HipergateWebBeacon.setRequestHeader("Content-type", "application/x-www-form-urlencoded");
			HipergateWebBeacon.setRequestHeader("Content-length", params.length);
			HipergateWebBeacon.setRequestHeader("Connection", "close");
			HipergateWebBeacon.send(params);
    }
  }
}
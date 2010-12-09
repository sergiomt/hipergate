    function validate() {
    	  var frm = document.forms[1];
		    var pag = document.getElementById("wholepage");
        if (!check_email(frm.tx_email.value)) {
        	document.getElementById("emailmsg").innerHTML = "The e-maill address is not valid";        	
          frm.tx_email.focus();
          return false;
        }
      	if (frm.tx_name.value.length==0) {
        	document.getElementById("namemsg").innerHTML = "The name is required";
          frm.tx_name.focus();
          return false;
      	}
      	if (frm.tx_surname.value.length==0) {
        	document.getElementById("surnamemsg").innerHTML = "The surname is required";
          frm.tx_surname.focus();
          return false;
      	}
        document.getElementById("registration").style.display="none";
        document.getElementById("reglink").style.display="none";
        var reg = httpPostForm("../common/registration.jsp", frm);
        if (navigator.appCodeName=="Mozilla")
          pag.style.opacity=1;
    	  else if (navigator.appName=="Microsoft Internet Explorer")
          pag.style.filter="alpha(opacity=100)";
        setCookie ("registration","1");
    } // validate

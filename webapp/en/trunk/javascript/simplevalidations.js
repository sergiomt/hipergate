/*****************************************
  JavaScript Functions for Data Validation  
*/

//---------------------------------------------------------

function hasForbiddenChars(str) {
  return (str.indexOf("'")>=0 || str.indexOf('"')>=0 || str.indexOf("|")>=0 || str.indexOf("*")>=0 || str.indexOf("?")>=0 || str.indexOf("&")>=0 || str.indexOf("?")>=0 || str.indexOf(";")>=0 || str.indexOf("`")>=0 || str.indexOf("/")>=0 || str.indexOf("\\")>=0)
} // hasForbiddenChars

//---------------------------------------------------------

function acceptOnlyNumbers(obj) {
  var notnum = /[^[\d]/g
  obj.value = obj.value.replace(notnum,'');
  // return ((ev.keyCode)>=48 && (ev.keyCode)<=57) ? true : false;
} // acceptOnlyNumbers

//---------------------------------------------------------

function isIntValue(str) {
  var reUnsignedInt = /^\d+$/

  var reSignedInt = /^[+-]?\d+$/

  if ((str == null) || (str.length == 0)) 
    return false;
  else 
    return reUnsignedInt.test(str) || reSignedInt.test(str);
} // isIntValue

//---------------------------------------------------------

function isFloatValue(str) {

  var len;
  var txt;
  var dot = false;

  if (str==null) return false;
    
  if (len==0) return false;
 
  len = str.length;
  
  // trim input string first
  var lpatt = new RegExp( "^ *(.*)$" );
  var rpatt = new RegExp( "^(.*[^ ]) *$" );
  var parse;
  
  parse=str.match(rpatt);   
  txt = (parse==null ? "" : parse[1]);
  parse=str.match(lpatt);   
  txt = (parse==null ? "" : parse[1]);
  
  for (var c=0; c<len; c++) {
    if ((txt.charCodeAt(c)<48 || txt.charCodeAt(c)>57) || 
       (txt.charAt(c)=='.' && dot) || (txt.charAt(c)==',' && dot) || (txt.charAt(c)=='-' && c>0) ||
       (c==len-1 && txt.charCodeAt(c)<48))
      return false;
    if (!dot) dot = (txt.charAt(c)=='.' || txt.charAt(c)==',');
  }    
  return true;

} // isFloatValue

// ********************************************************
// Subrutinas para validar DNIs/NIFs


/**
  * Validar DNI o NIF
  * @param cadena alfanumerica del documento
  * @param Codigo de 1 caracter identificativo del
  *        tipo de documento: N=NIF, D="DNI"
*/
function validarDocumento (documento,tipodocumento) {      
      
        //var frm = document.forms[formname];
      
        var snPassport = ltrim(rtrim(documento.toUpperCase()));
        var tpPassport = tipodocumento;      
      
        //frm.sTpPassport.value = tpPassport;
 
        if (snPassport.length==0)
    	  return false;
        else {
    	
    	  if (tpPassport=="N") {
    	    if (!validarNIF(snPassport))
              return false;
    	    else
              return true;
    	  }
    	  else if (tpPassport=="D") {
    	    if (!CadenaNumerica_Var(snPassport))
    	      return false;
    	    else
              return true;
    	  }
          else
            return true;
        } // fi (snPassport)
        return true;
} // validarDocumento()

//---------------------------------------------------------

// Get checked value from radio button.

function getRadioButtonValue (radio)
{   for (var i = 0; i < radio.length; i++)
    {   if (radio[i].checked) { break }
    }
    return radio[i].value
}

//---------------------------------------------------------

function siNsaltaaCampo(obj,N,objAsaltar) {
  if (obj.value.length == N)
    objAsaltar.focus();	
}

//---------------------------------------------------------

/**
  * Letra de control de un n?mero de DNI
*/      
function letraControl(numero) {
     var Dig = "ATRWAGMYFPDXBNJZSQVHLCKE";      

     return Dig.charCodeAt((numero%23)+1);
} // letraControl

//---------------------------------------------------------

/**
  * Devuelve solo los numeros contenidos en una cadena
*/    
function parteNumerica (cadena) {      
     var len = cadena.length;
     var num = "";
     var cod;
      
     for (var i=0; i<len; i++) {
  	cod = cadena.charCodeAt(i); 
        if (cod>=48 && cod<=57) num+=cadena.charAt(i);
     } // next()
      
     return parseInt(num);
} // parteNumerica
    
//---------------------------------------------------------

/**
  * Verfica si una cadena contiene s?lo caracteres num?ricos [0..9]
*/
function CadenaNumerica_Var(cadena) {
     var long_cad=cadena.length;
      
     for ( var i=0; i < long_cad; i++ ) {
       if ( (cadena.charCodeAt(i) < 48) || (cadena.charCodeAt(i) > 57) )
          return false;     
               
     } // next (i)
     return true;
} // CadenaNumerica_Var

//---------------------------------------------------------

/**
  * Valida la primera letra de un NIF espa�ol
*/        
function validarNIF (nif) {
     var letra;
     var Aupr = 65;
     var Zupr = 90;
      
     letra = nif.charCodeAt(0);
     if (letra<Aupr || letra>Zupr)
          letra = nif.charCodeAt(nif.length-1);
     if (letra<Aupr || letra>Zupr)
	  return false;      
            
     return (letra==letraControl(parteNumerica(nif)));      
} // validarNIF


// ********************************************************
// Bank Account Validation functions

/**
  * Get Bank Account Number Control Digit
*/
function getBankAccountDigit(cc) {

  var ccc;
  var suma = 0;
  var contpesos = 10;
  var mintpesos = Array(0, 6, 3, 7, 9, 10, 5, 8, 4, 2, 1);
			
  if (cc.length!=10) return false;
	
  for (var d=0; d<10; d++) {
    suma += (mintpesos[contpesos] * parseInt(cc.charAt(d)))
    contpesos-=1; 
  } // next

  ccc = 11 - (suma % 11);  
  if (ccc==10) ccc=1;  	
  if (ccc==11) ccc=0;
	
  return ccc;	
} // getBankAccountDigit

//---------------------------------------------------------

/**
  * Get Bank Account Number Control Digits Pair
  * @param Bank Entity  identifier (4 characters)
  * @param Bank Office  identifier (4 characters)
  * @param Bank Account number (10 characters)  
*/

function getBankAccountDC(entity,office,cc) {

	var dc = new String(getBankAccountDigit("00" + entity + office) + "" + getBankAccountDigit(cc));
  
  	return dc;
} // getBankAccountDC

//---------------------------------------------------------
      
function isBankAccountold(cc,dc) {	
  return (getBankAccountDigit(cc)==parseInt(dc.charAt(1)));
} // isBankAccountold

//---------------------------------------------------------

/**
  * Check Full ank Account Control Digits
  * @param Bank Entity    identifier (4 characters)
  * @param Bank Office    identifier (4 characters)
  * @param Control Digits number (2 characters)  
  * @param Bank Account   number (10 characters)
  * @return true if computed control digits match the supplied ones
*/
function isBankAccount(entity,office,dc,cc) {	
  
  return (getBankAccountDC(entity,office,cc)==dc);
} // isBankAccount

/**
  * Remove thousands delimter from string representing a number
  * and use dot as a decimal delimiter instead of comma
  * @param num Floating point number
  * @return String of the form 99999.99
*/

function removeThousandsDelimiter(num) {
  var com = num.indexOf(",");
  var dot = num.indexOf(".");
  var ret;
  
  if (com>=0 && dot>=0) {
    if (com>dot) {
      // num is of the form: 99.999,99
      ret = num.replace(/\x2e/,"");  // remove dot thousands delimiter
      ret = ret.replace(/\x2c/,"."); // replace comma by dot
    } else {
      // num is of the form: 99,999.99
      ret = num.replace(/\x2c/,"");  // remove comma thousands delimiter      
    }
  } else if (com>=0) {
    // num is of the form: 99999,99
    ret = num.replace(/\x2c/,".");  // replace comma by dot      
  } else {
    ret = num;
  }
  return ret;
} // removeThousandsDelimiter

/**
* Calculates the strength of a password
* @param {Object} p The password that needs to be calculated
* @return {int} intScore The strength score of the password
*/
function calcStrength(p) {
	var intScore = 0;

	// PASSWORD LENGTH
	intScore += p.length;

	if(p.length > 0 && p.length <= 4) {                    // length 4 or less
		intScore += p.length;
	}
	else if (p.length >= 5 && p.length <= 7) {	// length between 5 and 7
		intScore += 6;
	}
	else if (p.length >= 8 && p.length <= 15) {	// length between 8 and 15
		intScore += 12;
	}
	else if (p.length >= 16) {               // length 16 or more
		intScore += 18;
	}

	// LETTERS (Not exactly implemented as dictacted above because of my limited understanding of Regex)
	if (p.match(/[a-z]/)) {              // [verified] at least one lower case letter
		intScore += 1;
	}
	if (p.match(/[A-Z]/)) {              // [verified] at least one upper case letter
		intScore += 5;
	}
	// NUMBERS
	if (p.match(/\d/)) {             	// [verified] at least one number
		intScore += 5;
	}
	if (p.match(/.*\d.*\d.*\d/)) {            // [verified] at least three numbers
		intScore += 5;
	}

	// SPECIAL CHAR
	if (p.match(/[!,@,#,$,%,^,&,_]/)) {           // [verified] at least one special character
		intScore += 5;
	}
	// [verified] at least two special characters
	if (p.match(/.*[!,@,#,$,%,^,&,_].*[!,@,#,$,%,^,&,_]/)) {
		intScore += 5;
	}

	// COMBOS
	if (p.match(/(?=.*[a-z])(?=.*[A-Z])/)) {        // [verified] both upper and lower case
		intScore += 2;
	}
	if (p.match(/(?=.*\d)(?=.*[a-z])(?=.*[A-Z])/)) { // [verified] both letters and numbers
		intScore += 2;
	}
	// [verified] letters, numbers, and special characters
	if (p.match(/(?=.*\d)(?=.*[a-z])(?=.*[A-Z])(?=.*[!,@,#,$,%,^,&,_])/)) {
		intScore += 2;
	}

	return intScore;

}

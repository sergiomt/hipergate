/*  ================================================================
    Credit card verification functions
    Originally included as Starter Application 1.0.0 in LivePayment.
    18 Feb 1997 created Eric Krock
    20 Feb 1997 modified by egk:

    Original JavaScript 1.0-only version (works on Nav2.x and higher)
    available at http://developer.netscape.com/docs/examples/javascript/formval/overview.html

    (c) 1997 Netscape Communications Corporation

    ================================================================ */


// Validate credit card info.

function checkCreditCard (radio, theField)
{   var cardType = getRadioButtonValue (radio)
    var normalizedCCN = stripCharsInBag(theField.value, creditCardDelimiters)
    if (!isCardMatch(cardType, normalizedCCN)) 
       return warnInvalid (theField, iCreditCardPrefix + cardType + iCreditCardSuffix);
    else 
    {  theField.value = normalizedCCN
       return true
    }
}



/*  ================================================================
    FUNCTION:  isCreditCard(st)
 
    INPUT:     st - a string representing a credit card number

    RETURNS:  true, if the credit card number passes the Luhn Mod-10
		    test.
	      false, otherwise
    ================================================================ */

function isCreditCard(st) {
  // Encoding only works on cards with less than 19 digits
  if (st.length > 19)
    return (false);

  sum = 0; mul = 1; l = st.length;
  for (i = 0; i < l; i++) {
    digit = st.substring(l-i-1,l-i);
    tproduct = parseInt(digit ,10)*mul;
    if (tproduct >= 10)
      sum += (tproduct % 10) + 1;
    else
      sum += tproduct;
    if (mul == 1)
      mul++;
    else
      mul--;
  }
// Uncomment the following line to help create credit card numbers
// 1. Create a dummy number with a 0 as the last digit
// 2. Examine the sum written out
// 3. Replace the last digit with the difference between the sum and
//    the next multiple of 10.

//  document.writeln("<BR>Sum      = ",sum,"<BR>");
//  alert("Sum      = " + sum);

  if ((sum % 10) == 0)
    return (true);
  else
    return (false);

} // END FUNCTION isCreditCard()



/*  ================================================================
    FUNCTION:  isVisa()
 
    INPUT:     cc - a string representing a credit card number

    RETURNS:  true, if the credit card number is a valid VISA number.
		    
	      false, otherwise

    Sample number: 4111 1111 1111 1111 (16 digits)
    ================================================================ */

function isVisa(cc)
{
  if (((cc.length == 16) || (cc.length == 13)) &&
      (cc.substring(0,1) == 4))
    return isCreditCard(cc);
  return false;
}  // END FUNCTION isVisa()




/*  ================================================================
    FUNCTION:  isMasterCard()
 
    INPUT:     cc - a string representing a credit card number

    RETURNS:  true, if the credit card number is a valid MasterCard
		    number.
		    
	      false, otherwise

    Sample number: 5500 0000 0000 0004 (16 digits)
    ================================================================ */

function isMasterCard(cc)
{
  firstdig = cc.substring(0,1);
  seconddig = cc.substring(1,2);
  if ((cc.length == 16) && (firstdig == 5) &&
      ((seconddig >= 1) && (seconddig <= 5)))
    return isCreditCard(cc);
  return false;

} // END FUNCTION isMasterCard()





/*  ================================================================
    FUNCTION:  isAmericanExpress()
 
    INPUT:     cc - a string representing a credit card number

    RETURNS:  true, if the credit card number is a valid American
		    Express number.
		    
	      false, otherwise

    Sample number: 340000000000009 (15 digits)
    ================================================================ */

function isAmericanExpress(cc)
{
  firstdig = cc.substring(0,1);
  seconddig = cc.substring(1,2);
  if ((cc.length == 15) && (firstdig == 3) &&
      ((seconddig == 4) || (seconddig == 7)))
    return isCreditCard(cc);
  return false;

} // END FUNCTION isAmericanExpress()




/*  ================================================================
    FUNCTION:  isDinersClub()
 
    INPUT:     cc - a string representing a credit card number

    RETURNS:  true, if the credit card number is a valid Diner's
		    Club number.
		    
	      false, otherwise

    Sample number: 30000000000004 (14 digits)
    ================================================================ */

function isDinersClub(cc)
{
  firstdig = cc.substring(0,1);
  seconddig = cc.substring(1,2);
  if ((cc.length == 14) && (firstdig == 3) &&
      ((seconddig == 0) || (seconddig == 6) || (seconddig == 8)))
    return isCreditCard(cc);
  return false;
}



/*  ================================================================
    FUNCTION:  isCarteBlanche()
 
    INPUT:     cc - a string representing a credit card number

    RETURNS:  true, if the credit card number is a valid Carte
		    Blanche number.
		    
	      false, otherwise
    ================================================================ */

function isCarteBlanche(cc)
{
  return isDinersClub(cc);
}




/*  ================================================================
    FUNCTION:  isDiscover()
 
    INPUT:     cc - a string representing a credit card number

    RETURNS:  true, if the credit card number is a valid Discover
		    card number.
		    
	      false, otherwise

    Sample number: 6011000000000004 (16 digits)
    ================================================================ */

function isDiscover(cc)
{
  first4digs = cc.substring(0,4);
  if ((cc.length == 16) && (first4digs == "6011"))
    return isCreditCard(cc);
  return false;

} // END FUNCTION isDiscover()





/*  ================================================================
    FUNCTION:  isEnRoute()
 
    INPUT:     cc - a string representing a credit card number

    RETURNS:  true, if the credit card number is a valid enRoute
		    card number.
		    
	      false, otherwise

    Sample number: 201400000000009 (15 digits)
    ================================================================ */

function isEnRoute(cc)
{
  first4digs = cc.substring(0,4);
  if ((cc.length == 15) &&
      ((first4digs == "2014") ||
       (first4digs == "2149")))
    return isCreditCard(cc);
  return false;
}



/*  ================================================================
    FUNCTION:  isJCB()
 
    INPUT:     cc - a string representing a credit card number

    RETURNS:  true, if the credit card number is a valid JCB
		    card number.
		    
	      false, otherwise
    ================================================================ */

function isJCB(cc)
{
  first4digs = cc.substring(0,4);
  if ((cc.length == 16) &&
      ((first4digs == "3088") ||
       (first4digs == "3096") ||
       (first4digs == "3112") ||
       (first4digs == "3158") ||
       (first4digs == "3337") ||
       (first4digs == "3528")))
    return isCreditCard(cc);
  return false;

} // END FUNCTION isJCB()



/*  ================================================================
    FUNCTION:  isAnyCard()
 
    INPUT:     cc - a string representing a credit card number

    RETURNS:  true, if the credit card number is any valid credit
		    card number for any of the accepted card types.
		    
	      false, otherwise
    ================================================================ */

function isAnyCard(cc)
{
  if (!isCreditCard(cc))
    return false;
  if (!isMasterCard(cc) && !isVisa(cc) && !isAmericanExpress(cc) && !isDinersClub(cc) &&
      !isDiscover(cc) && !isEnRoute(cc) && !isJCB(cc)) {
    return false;
  }
  return true;

} // END FUNCTION isAnyCard()


/*  ================================================================
    FUNCTION:  isAnyAcceptedCard()
 
    INPUT:     cc - a string representing a credit card number

    RETURNS:  true, if the credit card number is any valid credit
		    card number for any of the accepted card types.
		    
	      false, otherwise
    Variación: Los tipos de tarjeta son cargados en un array y de esta manera seleccionar
               las tarjetas permitidas en la validacion simplemente modificando el contenido	      
               de la variable Array AcceptedCards
    ================================================================ */

var acceptedCards = Array("VISA","MASTERCARD","AMERICANEXPRESS","DISCOVER","JCB","DINERS","CARTEBLANCHE","ENROUTE");

function isAnyAcceptedCard(cc)
{
  var n_cards = acceptedCards.length;
  
  if (!isCreditCard(cc))
    return false;
    
  for (i=0;i<n_cards;i++)
  {
    	var cardType = acceptedCards[i];
    	if (!isCardMatch(cardType, cc))
    	    return false;
  }
  return true;

} // END FUNCTION isAnyAcceptedCard()



/*  ================================================================
    FUNCTION:  isCardMatch()
 
    INPUT:    cardType - a string representing the credit card type
	      cardNumber - a string representing a credit card number

    RETURNS:  true, if the credit card number is valid for the particular
	      credit card type given in "cardType".
		    
	      false, otherwise
    ================================================================ */

function isCardMatch (cardType, cardNumber)
{

	cardType = cardType.toUpperCase();
	var doesMatch = true;

	if ((cardType == "VISA") && (!isVisa(cardNumber)))
		doesMatch = false;
	if ((cardType == "MASTERCARD") && (!isMasterCard(cardNumber)))
		doesMatch = false;
	if ( ( (cardType == "AMERICANEXPRESS") || (cardType == "AMEX") )
                && (!isAmericanExpress(cardNumber))) doesMatch = false;
	if ((cardType == "DISCOVER") && (!isDiscover(cardNumber)))
		doesMatch = false;
	if ((cardType == "JCB") && (!isJCB(cardNumber)))
		doesMatch = false;
	if ((cardType == "DINERS") && (!isDinersClub(cardNumber)))
		doesMatch = false;
	if ((cardType == "CARTEBLANCHE") && (!isCarteBlanche(cardNumber)))
		doesMatch = false;
	if ((cardType == "ENROUTE") && (!isEnRoute(cardNumber)))
		doesMatch = false;
	return doesMatch;

}  // END FUNCTION CardMatch()


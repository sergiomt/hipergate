function ShoppingBasket() {

  this.customer = null;
  this.properties = new Object();
  this.addresses = new Array();
  this.lines = new Array();

  this.setCustomer = function (cu) { this.customer = cu; }
  
  this.getCustomer = function (cu) { return this.customer; }
  
  this.setProperty = function (pname,pvalue) { this.properties[pname] = pvalue; }
  
  this.getProperty = function (pname) { return this.properties[pname]; }
  
  this.addAddress = function (addr) { this.addresses[this.addresses.length] = addr; }
  
  this.getAddress = function (n) { return this.addresses[n]; }
  
  this.addLine = function (line) { this.lines[this.lines.length] = line; }
  
  this.getLine = function (n) { return this.lines[n]; }
    
  this.toXML = function () {
    var xml = "<ShoppingBasket>";

    if (this.customer==null)
      xml += "<Customer/>";
    else
    	xml += "<Customer>"+xml+"</Customer>";
  
    xml += "<Properties>";
    for (var pname in this.properties)
      xml += "<"+pname+">"+this.properties[pname]+"</"+pname+">";
    xml += "</Properties>";
    xml += "<Addresses>";
    for (var a=0; a<this.addresses.length; a++) {
      xml += "<Address>";
      for (var aname in this.addresses[a])
        xml += "<"+aname+">"+this.properties[aname]+"</"+aname+">";
      xml += "</Address>";
    }
    xml += "</Addresses>";
    xml += "<Lines>";
    for (var l=0; a<this.lines.length; l++) {
      xml += "<Line>";
      for (var lname in this.lines[l])
        xml += "<"+lname+">"+this.properties[lname]+"</"+lname+">";    
      xml += "</Line>";
    }
    xml += "</Lines>";
    xml += "</ShoppingBasket>";
    return xml;
  } // toXML
}

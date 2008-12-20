var id = "";
var I = 0;
var factor = 1;
var paso = 100;

function pabajo() {
  window.status = "";
  if (I >= 700) { clearTimeout(id); factor = 1; }
  else  {
    tree.scroll(1,I);
    I = eval(I + factor);
    if (I % paso == 0) { factor++ }
    //window.status = factor + "," + I;
    id = setTimeout("pabajo()", 10)
  }
}

function parriba() {
  window.status = "";
  if (I <= 0) { clearTimeout(id); factor = 1; }
  else  {
    tree.scroll(1,I);
    I = eval(I - factor);
    if (I % paso == 0) { factor++ }
    //window.status = factor + "," + I;
    id = setTimeout("parriba()", 10)
  }
}

function parar() { clearTimeout(id); factor = 1; }
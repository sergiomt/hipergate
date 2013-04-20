<%@ page import="java.awt.*,java.awt.image.*,java.awt.geom.*,java.lang.Math,java.lang.*,com.sun.image.codec.jpeg.*,java.io.*,java.util.Vector,com.knowgate.acl.ACL,com.knowgate.misc.Gadgets,com.knowgate.debug.*" session="false"%><% 
  
  // Set final image width and height
  int iImageWidth = 70;
  int iImageHeight = 25;

  String sWord;			// "Magic" word
  BufferedImage ImagenFinal;	// Abstract image object
  Graphics2D GraphicsFinal;	// Final image to send back
  JPEGImageEncoder encoder;	// JPEG Codec
  int x1=0,y1=0;		// x/y coordinates to draw the grid
  
  try {
    sWord = "";
    
    // Generate random string from this alphabet (some letters removed to prevent typos)
    // Upper/Lowercase: String aLetters[] = {"a","b","c","d","e","f","g","h","i","j","k","m","n","q","r","s","t","w","x","y","z","A","B","C","D","E","F","G","H","J","K","M","N","Q","R","S","W","X","Y","Z"};
    String aLetters[] = {"a","b","c","d","e","f","g","h","i","j","k","m","n","q","r","s","t","w","x","y","z","2","3","5","6","7","8","9"};
    for (int i=0;i<6;i++) {
      sWord += aLetters[(int)(aLetters.length*Math.random())];
    }
    
    // Another example using numbers only (000000 to 999999)
    /*
    sWord = (int)(1000000*Math.random())+"";
    while (sWord.length()<6) {
      sWord = "0" + sWord;
    }
    */
    
    // Yet another example using random words, in this example use up to 6 letter words
    /*
    String aWords[] = {
      "apple",
      "tomato",
      "juice"
    };
    sWord = aWords[(int)(aWords.length*Math.random())];
    */
    
    // You can even load them from file, one word per line
    /*
    Vector tempVector = new Vector();
    BufferedReader in = new BufferedReader(new FileReader("/path/to/words.file"));
    String aLine;
    while ((aLine = in.readLine()) != null) {
      // Limit here your word length
      // if (aLine.length()>=6 && aLine.length()<=8)
      tempVector.addElement(aLine);
    }
    in.close();
    sWord = tempVector.get((int)(tempVector.size()*Math.random())+1)+"";
    */
    
    // Once you have your "magic word", encrypt it and send back to the browser
    Cookie resCookie;
    java.util.Date oNow = new java.util.Date();
    com.knowgate.misc.MD5 oMD5 = new com.knowgate.misc.MD5(sWord+ACL.getRC4key());
    String sKey = oMD5.asHex();

    resCookie = new Cookie("captcha_key", sKey);
    resCookie.setMaxAge(-1);
    resCookie.setPath("/");
    response.addCookie(resCookie);

    resCookie = new Cookie("captcha_timestamp", String.valueOf(oNow.getTime()));
    resCookie.setMaxAge(-1);
    resCookie.setPath("/");
    response.addCookie(resCookie);
    
    // Set content type, prevent client-side caching
    response.setContentType("image/jpeg"); 
    response.setHeader("Pragma", "no-cache");
    response.setHeader("Cache-Control", "no-cache");
    response.setDateHeader("Expires",0); 
    
    ImagenFinal = new BufferedImage(iImageWidth,iImageHeight,BufferedImage.TYPE_INT_RGB);
    GraphicsFinal = ImagenFinal.createGraphics(); 
    
    // Draw gray background
    GraphicsFinal.setBackground(new Color(224,224,224));
    GraphicsFinal.clearRect(0,0,iImageWidth,iImageHeight);
    
    // Draw grid
    GraphicsFinal.setColor(new Color(192,192,192));

    // Vertical Grid
    for(int c=5;c<iImageWidth;c=c+5) {
      GraphicsFinal.drawLine(c,0,c,iImageHeight);
    }
    
    // Horizontal Grid
    for(int c=5;c<iImageHeight;c=c+5) {
      GraphicsFinal.drawLine(0,c,iImageWidth,c);
    }

    // Add "noise"
    GraphicsFinal.setColor(new Color(192,192,192));
    for(int c=0;c<50;c++) {
      x1 = (int)(iImageWidth*Math.random());
      y1 = (int)(iImageHeight*Math.random());
      GraphicsFinal.drawLine(x1,y1,x1,y1);
    } 

    // Draw word
    Font font = new Font("MonoSpaced",Font.BOLD,16);
    font.deriveFont(Font.BOLD);
    GraphicsFinal.setFont(font);
    GraphicsFinal.setColor(new Color(128,128,128));
    GraphicsFinal.drawString(sWord,6,17);

    // Finaly, add black border
    GraphicsFinal.setColor(new Color(0,0,0));
    GraphicsFinal.drawRect(0,0,iImageWidth-1,iImageHeight-1);

    GraphicsFinal.dispose();

    // Encode image using JPEG codec
    encoder = JPEGCodec.createJPEGEncoder(response.getOutputStream());
    JPEGEncodeParam jp = encoder.getDefaultJPEGEncodeParam(ImagenFinal);

    // You can lower quality to 0.75f so some noise will be added
    jp.setQuality(0.95f,true);
    
    // Finaly, send back image to browser
    encoder.encode(ImagenFinal, jp);
    
  } catch (Exception e) {
    if (DebugFile.trace) {
      DebugFile.writeln("<JSP:captcha.jsp "+e.getClass().getName()+" "+e.getMessage());
      DebugFile.writeln(StackTraceUtil.getStackTrace(e));
    }
    response.sendRedirect (response.encodeRedirectUrl ("captchaerror.jsp?desc=" + Gadgets.URLEncode(e.getClass().getName()+" "+e.getMessage())));
  } catch (NoClassDefFoundError e) {
    if (DebugFile.trace) {
      DebugFile.writeln("<JSP:captcha.jsp "+e.getClass().getName()+" "+e.getMessage());
      DebugFile.writeln(StackTraceUtil.getStackTrace(e));
    }
    response.sendRedirect (response.encodeRedirectUrl ("captchaerror.jsp?desc=" + Gadgets.URLEncode(e.getClass().getName()+" "+e.getMessage())));  
  }
  
  // Make sure that there is not any space nor life feed after % > end tag
%>
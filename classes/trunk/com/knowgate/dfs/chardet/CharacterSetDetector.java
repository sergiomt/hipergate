package com.knowgate.dfs.chardet;

import java.io.File;
import java.io.IOException;
import java.io.InputStream;
import java.io.FileInputStream;

import com.knowgate.dfs.chardet.nsICharsetDetectionObserver;

public class CharacterSetDetector implements nsICharsetDetectionObserver {

  private boolean bDetectedCharset;

  private String sDetectedCharset;
  
  private nsDetector oDetector;

  public CharacterSetDetector() {
	bDetectedCharset = false;
	sDetectedCharset = null;
	oDetector = new nsDetector(nsPSMDetector.ALL);
  }

  public void Notify(String sCharSet) {
  	sDetectedCharset = sCharSet;
    bDetectedCharset = true ;
  }

  public String detect(InputStream oInStrm, String sDefaultCharset)
  	throws IOException {

	byte[] aBytes = new byte[1024] ;
	int iLen;
	boolean bDone = false ;
	boolean bIsAscii = true ;

	oDetector.Init(this);
	   
	while( (iLen=oInStrm.read(aBytes,0,aBytes.length)) != -1) {

	  // Check if the stream is only ascii.
	  if (bIsAscii) bIsAscii = oDetector.isAscii(aBytes,iLen);

	  // DoIt if non-ascii and not done yet.
		if (!bIsAscii && !bDone) bDone = oDetector.DoIt(aBytes, iLen, false);
	} // wend
	
	oDetector.DataEnd();

	if (bIsAscii) {	   
	   bDetectedCharset = true;
	   sDetectedCharset = "ASCII";
	}

	if (!bDetectedCharset) {
	  if (sDefaultCharset==null)	  	
	    sDetectedCharset = oDetector.getProbableCharsets()[0];  	
	  else
	  	sDetectedCharset = sDefaultCharset;
    } // fi

	return sDetectedCharset;
  } // detect

  public String detect(File oFile, String sDefaultCharset)
  	throws IOException {

    FileInputStream oInStrm = new FileInputStream(oFile);
  
    String sRetVal = detect(oInStrm, sDefaultCharset);
    
  	oInStrm.close();
  
    return sRetVal;
  }
  	
  public String detect(String sFile, String sDefaultCharset)
  	throws IOException {

    return detect(new File(sFile), sDefaultCharset);
  } // detect

}

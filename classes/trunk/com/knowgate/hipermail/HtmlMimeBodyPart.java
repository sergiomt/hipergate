package com.knowgate.hipermail;

/*
  Copyright (C) 2009-2011  Know Gate S.L. All rights reserved.

  Redistribution and use in source and binary forms, with or without
  modification, are permitted provided that the following conditions
  are met:

  1. Redistributions of source code must retain the above copyright
     notice, this list of conditions and the following disclaimer.

  2. The end-user documentation included with the redistribution,
     if any, must include the following acknowledgment:
     "This product includes software parts from hipergate
     (http://www.hipergate.org/)."
     Alternately, this acknowledgment may appear in the software itself,
     if and wherever such third-party acknowledgments normally appear.

  3. The name hipergate must not be used to endorse or promote products
     derived from this software without prior written permission.
     Products derived from this software may not be called hipergate,
     nor may hipergate appear in their name, without prior written
     permission.

  This library is distributed in the hope that it will be useful,
  but WITHOUT ANY WARRANTY; without even the implied warranty of
  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.

  You should have received a copy of hipergate License with this code;
  if not, visit http://www.hipergate.org or mail to info@hipergate.org
*/

import java.io.IOException;
import java.util.ArrayList;
import java.util.HashMap;

import java.util.regex.Matcher;
import java.util.regex.PatternSyntaxException;

import org.apache.oro.text.regex.Pattern;
import org.apache.oro.text.regex.PatternMatcher;
import org.apache.oro.text.regex.PatternCompiler;
import org.apache.oro.text.regex.Perl5Matcher;
import org.apache.oro.text.regex.Perl5Compiler;
import org.apache.oro.text.regex.PatternMatcherInput;
import org.apache.oro.text.regex.MalformedPatternException;

import org.htmlparser.Parser;
import org.htmlparser.util.NodeList;
import org.htmlparser.util.NodeIterator;
import org.htmlparser.util.ParserException;
import org.htmlparser.Tag;
import org.htmlparser.tags.LinkTag;
import org.htmlparser.tags.ImageTag;
import org.htmlparser.tags.TableTag;
import org.htmlparser.tags.TableColumn;
import org.htmlparser.filters.TagNameFilter;
import org.htmlparser.visitors.NodeVisitor;

import com.knowgate.misc.Gadgets;
import com.knowgate.misc.Base64Encoder;
import com.knowgate.debug.DebugFile;
import com.knowgate.debug.StackTraceUtil;

/**
 * <p>Used to perform some maipulations in HTML source code for e-mails</p>
 * @author Sergio Montoro Ten
 * @version 7.0
 */
public class HtmlMimeBodyPart {

  private PatternMatcher oMatcher = new Perl5Matcher();
  private static PatternCompiler oCompiler = new Perl5Compiler();

  private static Pattern oFullHref = null;
  private static Pattern oGoodHref = null;
  private static Pattern oHostHref = null;
  private static Pattern oFullSrc = null;
  private static Pattern oGoodSrc = null;
  private static Pattern oHostSrc = null;

  private String sBody;
  private String sEnc;
  
  private HashMap<String,String> oImgs;
  
  public HtmlMimeBodyPart(String sHtml, String sEncoding) {
    sBody = sHtml;
    sEnc = sEncoding;
    oImgs = new HashMap<String,String>(23);
  }

  public void setHtml(String sHtml) {
  	sBody = sHtml;
  }

  public ArrayList<String> extractHrefs() {

    ArrayList<String> aHrefs = new ArrayList<String>();
	try {
      if (null==oFullHref) oFullHref = oCompiler.compile("<a ((accesskey|charset|class|coords|dir|hreflang|id|lang|name|rel|rev|shape|style|tabindex|target|title)\\s*=\\s*[\"']?([^'\"\\r\\n]+)[\"']?)* href\\s*=\\s*[\"']?([^'\"\\r\\n]+)[\"']?", Perl5Compiler.CASE_INSENSITIVE_MASK);
  	  PatternMatcherInput oPinpt = new PatternMatcherInput(sBody);
      while (oMatcher.contains(oPinpt, oFullHref)) {
	    aHrefs.add(oMatcher.getMatch().group(4));
	    if (oPinpt.endOfInput()) break;
      } // wend
    } catch (MalformedPatternException neverthrown) { } 
    return aHrefs;
  } // extractHrefs()

  /**
   * Get a list of <img src="..." tags that point to a local resource
   * such as src="/tmp/myfile.gif" or src="http://localhost/imgs/myfile.gif"
   */
  public ArrayList<String> extractLocalUrls()
  	throws ArrayIndexOutOfBoundsException {

    ArrayList<String> aLocalUrls = new ArrayList<String>();
    PatternMatcherInput oPinpt;
    String sSrcUrl, sHrefUrl;
    
    try {
      synchronized(oCompiler) {
        if (null==oFullHref) oFullHref = oCompiler.compile("<a( (accesskey|charset|class|coords|dir|hreflang|id|lang|name|rel|rev|shape|style|tabindex|target|title)\\s*=\\s*[\"']?([^'\"\\r\\n]+)[\"']?)* href\\s*=\\s*[\"']?([^'\"\\r\\n]+)[\"']?", Perl5Compiler.CASE_INSENSITIVE_MASK);
        if (null==oGoodHref) oGoodHref = oCompiler.compile("<a( (accesskey|charset|class|coords|dir|hreflang|id|lang|name|rel|rev|shape|style|tabindex|target|title)\\s*=\\s*[\"']?([^'\"\\r\\n]+)[\"']?)* href\\s*=\\s*[\"']?(http://|https://|mailto:)\\w+([^'\"\\r\\n]+)[\"']?", Perl5Compiler.CASE_INSENSITIVE_MASK);
        if (null==oHostHref) oHostHref = oCompiler.compile("<a( (accesskey|charset|class|coords|dir|hreflang|id|lang|name|rel|rev|shape|style|tabindex|target|title)\\s*=\\s*[\"']?([^'\"\\r\\n]+)[\"']?)* href\\s*=\\s*[\"']?(http://|https://)localhost([^'\"\\r\\n]+)[\"']?", Perl5Compiler.CASE_INSENSITIVE_MASK);
        if (null==oFullSrc) oFullSrc = oCompiler.compile("<img( (align|alt|border|class|dir|height|hspace|id|ismap|lang|longdesc|style|title|usemap|vspace|width)\\s*=\\s*[\"']?([^'\"\\r\\n]+)[\"']?)* src\\s*=\\s*[\"']?([^'\"\\r\\n]+)[\"']?", Perl5Compiler.CASE_INSENSITIVE_MASK);
	    if (null==oGoodSrc) oGoodSrc = oCompiler.compile("<img( (align|alt|border|class|dir|height|hspace|id|ismap|lang|longdesc|style|title|usemap|vspace|width)\\s*=\\s*[\"']?([^'\"\\r\\n]+)[\"']?)* src\\s*=\\s*[\"']?(cid:|http://|https://)([^'\"\\r\\n]+)[\"']?", Perl5Compiler.CASE_INSENSITIVE_MASK);
	    if (null==oHostSrc) oHostSrc = oCompiler.compile("<img( (align|alt|border|class|dir|height|hspace|id|ismap|lang|longdesc|style|title|usemap|vspace|width)\\s*=\\s*[\"']?([^'\"\\r\\n]+)[\"']?)* src\\s*=\\s*[\"']?(http://localhost|https://localhost)([^'\"\\r\\n]+)[\"']?", Perl5Compiler.CASE_INSENSITIVE_MASK);
      }

  	  oPinpt = new PatternMatcherInput(sBody);
      while (oMatcher.contains(oPinpt, oFullSrc)) {
	    sSrcUrl = oMatcher.getMatch().toString();
	    if (!oMatcher.matches(sSrcUrl, oGoodSrc))
		  aLocalUrls.add(sSrcUrl);
	    if (oPinpt.endOfInput()) break;
      } // wend

  	  oPinpt.setCurrentOffset(oPinpt.getBeginOffset());
      while (oMatcher.contains(oPinpt, oFullSrc)) {
	    sSrcUrl = oMatcher.getMatch().toString();
		if (oMatcher.matches(sSrcUrl, oHostSrc))
		  aLocalUrls.add(sSrcUrl);
	    if (oPinpt.endOfInput()) break;
      } // wend
      
  	  oPinpt.setCurrentOffset(oPinpt.getBeginOffset());
      while (oMatcher.contains(oPinpt, oFullHref)) {
		sHrefUrl = oMatcher.getMatch().toString();
	    if (!oMatcher.matches(sHrefUrl, oGoodHref))
		  aLocalUrls.add(sHrefUrl);
	    if (oPinpt.endOfInput()) break;
      } // wend

  	  oPinpt.setCurrentOffset(oPinpt.getBeginOffset());
      while (oMatcher.contains(oPinpt, oFullHref)) {
		sHrefUrl = oMatcher.getMatch().toString();
		if (oMatcher.matches(sHrefUrl, oHostHref))
		  aLocalUrls.add(sHrefUrl);		
	    if (oPinpt.endOfInput()) break;
      } // wend
    } catch (MalformedPatternException neverthrown) { } 

	return aLocalUrls;
  } // extractLocalUrls
  	
  public HashMap getImagesCids() {
    return oImgs;
  }

  private String doSubstitution(final String sBase, final String sAttributeName,
		                        final String sFormerValue, final String sNewValue)
  	throws ParserException {
  	
  	String sMatch = "";
  	
  	if (DebugFile.trace) DebugFile.writeln("HtmlMomeBodyPart.doSubstitution(..., "+sAttributeName+","+sFormerValue+","+sNewValue+")");

    final String sPattern = "("+sAttributeName.toLowerCase()+"|"+sAttributeName.toUpperCase()+"|"+sAttributeName+")\\s*=\\s*(\"|')?" + sFormerValue + "(\"|')?";

    try {

      if (DebugFile.trace) DebugFile.writeln("Pattern.compile(\""+sPattern+"\")");
      java.util.regex.Pattern oPattrn = java.util.regex.Pattern.compile(sPattern);
      Matcher oMatchr = oPattrn.matcher(sBase);
      
      if (oMatchr.find()) {
    	sMatch = oMatchr.group();

    	if (sMatch.length()==0) throw new ParserException("Match could not be retrieved for pattern " + sPattern);
      	else if (DebugFile.trace) DebugFile.writeln("match found "+sMatch);
      	
    	final int iDquote = sMatch.indexOf('"');
      	final int iSquote = sMatch.indexOf("'");
      	char cQuote = (char) 0;
      	if (iDquote>0 && iSquote>0)
      	  cQuote = iDquote<iSquote ? (char)34 : (char)39;
      	else if (iDquote>0)
      	  cQuote = (char)34;
      	else if (iSquote>0)
      	  cQuote = (char)39;
		try {
          if (cQuote==(char)0) {
		    if (DebugFile.trace) DebugFile.writeln("Matcher.replaceAll("+sMatch.substring(0,sAttributeName.length())+"="+sNewValue+")");
		    return oMatchr.replaceAll(sMatch.substring(0,sAttributeName.length())+"="+sNewValue);
		  } else {
	        if (DebugFile.trace) DebugFile.writeln("Matcher.replaceAll("+sMatch.substring(0,sAttributeName.length())+"="+cQuote+sNewValue+cQuote+")");            
	        return oMatchr.replaceAll(sMatch.substring(0,sAttributeName.length())+"="+cQuote+sNewValue+cQuote);
		  }
      	} catch (Exception xcpt) { throw new ParserException(xcpt.getMessage()); }
      } else {
      	return sBase;
      } // fi (oMatcher.contains())
    } catch (PatternSyntaxException mpe) {
      if (DebugFile.trace) {
        DebugFile.writeln("PatternSyntaxException " + mpe.getMessage());
        try { DebugFile.writeln(StackTraceUtil.getStackTrace(mpe)); } catch (Exception ignore) { }
      }
      throw new ParserException("PatternSyntaxException " + mpe.getMessage()+ " pattern " + sPattern + " substitution " + sNewValue, mpe);        
    }
    catch (ArrayIndexOutOfBoundsException aiob) {
      String sStack = "";
      try { sStack =  StackTraceUtil.getStackTrace(aiob); } catch (Exception ignore) { }
      if (DebugFile.trace) {
        DebugFile.writeln("ArrayIndexOutOfBoundsException " + aiob.getMessage());
        DebugFile.writeln(sStack);
      }
      int iAt = sStack.indexOf("at "); 
      if (iAt>0) {
      	int iLf = sStack.indexOf("\n",iAt);
      	if (iLf>iAt)
          throw new ParserException("ArrayIndexOutOfBoundsException " + sStack.substring(iAt,iLf) + " " + aiob.getMessage()+ " attribute " + sAttributeName + " pattern " + sPattern + " match " + sMatch + " former value " + sFormerValue + " substitution " + sNewValue, aiob);
        else
          throw new ParserException("ArrayIndexOutOfBoundsException " + sStack.substring(iAt) + " " + aiob.getMessage()+ " attribute " + sAttributeName + " pattern " + sPattern + " match " + sMatch + " former value " + sFormerValue + " substitution " + sNewValue, aiob);        	
      } else {
        throw new ParserException("ArrayIndexOutOfBoundsException " + aiob.getMessage()+ " attribute " + sAttributeName + " pattern " + sPattern + " match " + sMatch + " former value " + sFormerValue + " substitution " + sNewValue, aiob);
      }
    }
  } // doSubstitution
  
  /**
   * <p>Add a preffix to &lt;IMG SRC="..."&gt; &lt;TABLE BACKGROUND="..."&gt; and &lt;TD BACKGROUND="..."&gt; tags</p>
   * @param sPreffix String preffix to be added to &lt;img&gt; src attribute and &lt;table&gt; and &lt;td&gt; background
   * @return New HTML source with preffixed attributes
   * @throws ParserException
   */
  public String addPreffixToImgSrc(String sPreffix)
  	throws ParserException {

    if (DebugFile.trace) {
      DebugFile.writeln("Begin HtmlMimeBodyPart.addPreffixToImgSrc("+sPreffix+")");
      DebugFile.incIdent();
    }
    
    int iSlash;
    Parser oPrsr;
    String sCid, sSrc;
    String sBodyCid = sBody;
    NodeList oCollectionList;
    TagNameFilter oImgFilter;

	// **********************************************************************
	// Replace <IMG SRC="..." >

    oPrsr = Parser.createParser(sBodyCid, sEnc);
		
    oCollectionList = new NodeList();
    oImgFilter = new TagNameFilter ("IMG");
    for (NodeIterator e = oPrsr.elements(); e.hasMoreNodes();)
      e.nextNode().collectInto(oCollectionList, oImgFilter);

    int nImgs = oCollectionList.size();

    if (DebugFile.trace) DebugFile.writeln("Images NodeList.size() = " + String.valueOf(nImgs));

    for (int i=0; i<nImgs; i++) {
		ImageTag oImgTag = (ImageTag) oCollectionList.elementAt(i);
			
        sSrc = oImgTag.extractImageLocn().replace('\\','/');
        
        if (sSrc.length()==0) throw new ParserException("image src is empty for tag "+oImgTag.toHtml());
		
		if (DebugFile.trace) DebugFile.writeln("Processing image location "+sSrc);
		
        // Keep a reference to every related image name so that the same image is not included twice in the message
        if (!oImgs.containsKey(sSrc)) {

          // Find last slash from image url
          iSlash = sSrc.lastIndexOf('/');
		  
          // Take image name
          if (iSlash>=0) {
            while (sSrc.charAt(iSlash)=='/') { if (++iSlash==sSrc.length()) break; }
              sCid = sSrc.substring(iSlash);
          }
          else {
            sCid = sSrc;
          }
          if (DebugFile.trace) DebugFile.writeln("HashMap.put("+sSrc+","+sCid+")");

          if  (sCid.length()>0) {
            oImgs.put(sSrc, sCid);
            sBodyCid = doSubstitution (sBodyCid, "Src", Gadgets.replace(Gadgets.replace(oImgTag.extractImageLocn(),'\\',"\\\\"),'.',"\\x2E"), sPreffix+oImgs.get(sSrc));        
          }
        } // fi (!oImgs.containsKey(sSrc))
    } // next

	// **********************************************************************
	// Replace <TABLE BACKGROUND="..." >
	  
    oCollectionList = new NodeList();
    TagNameFilter oTableFilter = new TagNameFilter("TABLE");
    oPrsr = Parser.createParser(sBodyCid, sEnc);
    for (NodeIterator e = oPrsr.elements(); e.hasMoreNodes();)
      e.nextNode().collectInto(oCollectionList, oTableFilter);
          
    nImgs = oCollectionList.size();

    if (DebugFile.trace) DebugFile.writeln("Tables NodeList.size() = " + String.valueOf(nImgs));

    for (int i=0; i<nImgs; i++) {

      sSrc = ((TableTag) oCollectionList.elementAt(i)).getAttribute("background");
      if (sSrc!=null) {
        if (sSrc.length()>0) {
          sSrc = sSrc.replace('\\','/');

		  if (DebugFile.trace) DebugFile.writeln("Processing background location "+sSrc);

          // Keep a reference to every related image name so that the same image is not included twice in the message
          if (!oImgs.containsKey(sSrc)) {

            // Find last slash from image url
            iSlash = sSrc.lastIndexOf('/');

            // Take image name
            if (iSlash>=0) {
              while (sSrc.charAt(iSlash)=='/') { if (++iSlash==sSrc.length()) break; }
                sCid = sSrc.substring(iSlash);
            } // fi
            else {
              sCid = sSrc;
            }

            if (DebugFile.trace) DebugFile.writeln("HashMap.put("+sSrc+","+sCid+")");

            oImgs.put(sSrc, sCid);
          } // fi (!oImgs.containsKey(sSrc))
		  
		  sBodyCid = doSubstitution (sBodyCid, "Background", Gadgets.replace(Gadgets.replace(((TableTag) oCollectionList.elementAt(i)).getAttribute("background"),'\\',"\\\\"),'.',"\\x2E"), sPreffix+oImgs.get(sSrc));

        } // fi
      } // fi
    } // next

	// **********************************************************************
	// Replace <TD BACKGROUND="..." >
	  
    oCollectionList = new NodeList();
    TagNameFilter oTDFilter = new TagNameFilter("TD");
    oPrsr = Parser.createParser(sBodyCid, sEnc);
    for (NodeIterator e = oPrsr.elements(); e.hasMoreNodes();)
      e.nextNode().collectInto(oCollectionList, oTDFilter);
          
    nImgs = oCollectionList.size();

    if (DebugFile.trace) DebugFile.writeln("TD NodeList.size() = " + String.valueOf(nImgs));

    for (int i=0; i<nImgs; i++) {

      sSrc = ((TableColumn) oCollectionList.elementAt(i)).getAttribute("background");
      if (sSrc!=null) {
        if (sSrc.length()>0) {
          sSrc = sSrc.replace('\\','/');

		  if (DebugFile.trace) DebugFile.writeln("Processing td bg location "+sSrc);

          // Keep a reference to every related image name so that the same image is not included twice in the message
          if (!oImgs.containsKey(sSrc)) {

            // Find last slash from image url
            iSlash = sSrc.lastIndexOf('/');

            // Take image name
            if (iSlash>=0) {
              while (sSrc.charAt(iSlash)=='/') { if (++iSlash==sSrc.length()) break; }
                sCid = sSrc.substring(iSlash);
            } // fi
            else {
              sCid = sSrc;
            }

            if (DebugFile.trace) DebugFile.writeln("HashMap.put("+sSrc+","+sCid+")");

            oImgs.put(sSrc, sCid);
          } // fi (!oImgs.containsKey(sSrc))
		  
		  sBodyCid = doSubstitution(sBodyCid, "Background", Gadgets.replace(Gadgets.replace(((TableColumn) oCollectionList.elementAt(i)).getAttribute("background"),'\\',"\\\\"),'.',"\\x2E"), sPreffix+oImgs.get(sSrc));
        } // fi
      } // fi
    } // next

    if (DebugFile.trace) {
	  DebugFile.write(sBodyCid);
      DebugFile.decIdent();
      DebugFile.writeln("End HtmlMimeBodyPart.addPreffixToImgSrc()");
    }

    return sBodyCid;
  } // addPreffixToImgSrcs


  /**
   * <p>Remove a preffix from &lt;IMG SRC="..."&gt; &lt;TABLE BACKGROUND="..."&gt; and &lt;TD BACKGROUND="..."&gt; tags</p>
   * @param sPreffix String preffix to be removed from &lt;img&gt; src attribute and &lt;table&gt; and &lt;td&gt; background
   * @return New HTML source with unpreffixed attributes
   * @throws ParserException
   */
  public String removePreffixFromImgSrcs(String sPreffix)
  	throws ParserException {

    if (DebugFile.trace) {
      DebugFile.writeln("Begin HtmlMimeBodyPart.removePreffixFromImgSrcs("+sPreffix+")");
      DebugFile.incIdent();
    }

    int iSlash;
    Parser oPrsr;
    String sCid, sSrc;
    String sBodyCid = sBody;
    NodeList oCollectionList;
    TagNameFilter oImgFilter;

	// **********************************************************************
	// Replace <IMG SRC="..." >

    oPrsr = Parser.createParser(sBodyCid, sEnc);
		
    oCollectionList = new NodeList();
    oImgFilter = new TagNameFilter ("IMG");
    for (NodeIterator e = oPrsr.elements(); e.hasMoreNodes();)
      e.nextNode().collectInto(oCollectionList, oImgFilter);

    int nImgs = oCollectionList.size();

    if (DebugFile.trace) DebugFile.writeln("Images NodeList.size() = " + String.valueOf(nImgs));

    for (int i=0; i<nImgs; i++) {

        sSrc = (((ImageTag) oCollectionList.elementAt(i)).extractImageLocn()).replace('\\','/');

        // Keep a reference to every related image name so that the same image is not included twice in the message
        if (!oImgs.containsKey(sSrc)) {

          // Find last slash from image url
          iSlash = sSrc.lastIndexOf('/');
		  
          // Take image name
          if (iSlash>=0) {
            while (sSrc.charAt(iSlash)=='/') { if (++iSlash==sSrc.length()) break; }
              sCid = sSrc.substring(iSlash);
          }
          else {
            sCid = sSrc;
          }

          // String sUid = Gadgets.generateUUID();
          // sCid = sUid.substring(0,12)+"$"+sUid.substring(12,20)+"$"+sUid.substring(20,28)+"@hipergate.org";

          if (DebugFile.trace) DebugFile.writeln("HashMap.put("+sSrc+","+sCid+")");

          oImgs.put(sSrc, sCid);
        } // fi (!oImgs.containsKey(sSrc))
        
        String sImgSrc = ((ImageTag) oCollectionList.elementAt(i)).extractImageLocn();
        if (sImgSrc.startsWith(sPreffix)) {
          sBodyCid = doSubstitution(sBodyCid, "Src", Gadgets.replace(Gadgets.replace(sImgSrc,'\\',"\\\\"),'.',"\\x2E"), sImgSrc.substring(sPreffix.length()));
        }
        
    } // next

	// **********************************************************************
	// Replace <TABLE BACKGROUND="..." >
	  
    oCollectionList = new NodeList();
    TagNameFilter oTableFilter = new TagNameFilter("TABLE");
    oPrsr = Parser.createParser(sBodyCid, sEnc);
    for (NodeIterator e = oPrsr.elements(); e.hasMoreNodes();)
      e.nextNode().collectInto(oCollectionList, oTableFilter);
          
    nImgs = oCollectionList.size();

    if (DebugFile.trace) DebugFile.writeln("Tables NodeList.size() = " + String.valueOf(nImgs));

    for (int i=0; i<nImgs; i++) {

      sSrc = ((TableTag) oCollectionList.elementAt(i)).getAttribute("background");
      if (sSrc!=null) {
        if (sSrc.length()>0) {
          sSrc = sSrc.replace('\\','/');

          // Keep a reference to every related image name so that the same image is not included twice in the message
          if (!oImgs.containsKey(sSrc)) {

            // Find last slash from image url
            iSlash = sSrc.lastIndexOf('/');

            // Take image name
            if (iSlash>=0) {
              while (sSrc.charAt(iSlash)=='/') { if (++iSlash==sSrc.length()) break; }
                sCid = sSrc.substring(iSlash);
            } // fi
            else {
              sCid = sSrc;
            }

            if (DebugFile.trace) DebugFile.writeln("HashMap.put("+sSrc+","+sCid+")");

            oImgs.put(sSrc, sCid);
          } // fi (!oImgs.containsKey(sSrc))

          String sBckGrnd = ((TableTag) oCollectionList.elementAt(i)).getAttribute("background");
          if (sBckGrnd.startsWith(sPreffix)) {
            sBodyCid = doSubstitution(sBodyCid, "Background", Gadgets.replace(Gadgets.replace(sBckGrnd,'\\',"\\\\"),'.',"\\x2E"), sBckGrnd.substring(sPreffix.length()));
          }          
          
        } // fi
      } // fi
    } // next

	// **********************************************************************
	// Replace <TD BACKGROUND="..." >
	  
    oCollectionList = new NodeList();
    TagNameFilter oTDFilter = new TagNameFilter("TD");
    oPrsr = Parser.createParser(sBodyCid, sEnc);
    for (NodeIterator e = oPrsr.elements(); e.hasMoreNodes();)
      e.nextNode().collectInto(oCollectionList, oTDFilter);
          
    nImgs = oCollectionList.size();

    if (DebugFile.trace) DebugFile.writeln("TD NodeList.size() = " + String.valueOf(nImgs));

    for (int i=0; i<nImgs; i++) {

      sSrc = ((TableColumn) oCollectionList.elementAt(i)).getAttribute("background");
      if (sSrc!=null) {
        if (sSrc.length()>0) {
          sSrc = sSrc.replace('\\','/');

          // Keep a reference to every related image name so that the same image is not included twice in the message
          if (!oImgs.containsKey(sSrc)) {

            // Find last slash from image url
            iSlash = sSrc.lastIndexOf('/');

            // Take image name
            if (iSlash>=0) {
              while (sSrc.charAt(iSlash)=='/') { if (++iSlash==sSrc.length()) break; }
                sCid = sSrc.substring(iSlash);
            } // fi
            else {
              sCid = sSrc;
            }

            if (DebugFile.trace) DebugFile.writeln("HashMap.put("+sSrc+","+sCid+")");

            oImgs.put(sSrc, sCid);

            String sTdBckg = ((TableColumn) oCollectionList.elementAt(i)).getAttribute("background");
            if (sTdBckg.startsWith(sPreffix)) {
              sBodyCid = doSubstitution(sBodyCid, "Background", Gadgets.replace(Gadgets.replace(sTdBckg,'\\',"\\\\"),'.',"\\x2E"), sTdBckg.substring(sPreffix.length()));
            }          
          } // fi (!oImgs.containsKey(sSrc))
        } // fi
      } // fi
    } // next

    if (DebugFile.trace) {
	  DebugFile.write(sBodyCid);
      DebugFile.decIdent();
      DebugFile.writeln("End HtmlMimeBodyPart.removePreffixFromImgSrcs()");
    }

    return sBodyCid;
  } // removePreffixFromImgSrcs

  /**
   * <p>Replace a preffix from &lt;IMG SRC="..."&gt; &lt;TABLE BACKGROUND="..."&gt; and &lt;TD BACKGROUND="..."&gt; tags with another one</p>
   * @param sFormerPreffix String
   * @param sNewPreffix String
   * @return New HTML source with replaced preffixed attributes
   * @throws ParserException
   */

  public String replacePreffixFromImgSrcs(String sFormerPreffix, String sNewPreffix)
  	throws ParserException {
	HtmlMimeBodyPart oHtml = new HtmlMimeBodyPart(removePreffixFromImgSrcs(sFormerPreffix), sEnc);
	return oHtml.addPreffixToImgSrc(sNewPreffix);
  } // replacePreffixFromImgSrcs


  /**
   * <p>Replace HREF targets with an intermediate page for tracking click through</p>
   * @param sRedirectorUrl String Full HTTP path where all HREF URLs must be redirected
   * @return New HTML source with replaced HREF attributes
   * @throws ParserException
   */

  public String addClickThroughRedirector(final String sRedirectorUrl)
  	throws ParserException {

    if (DebugFile.trace) {
      DebugFile.writeln("Begin HtmlMimeBodyPart.addClickThroughRedirector("+sRedirectorUrl+")");
      DebugFile.incIdent();
    }
    
    final NodeVisitor linkVisitor = new NodeVisitor() {

        public void visitTag(Tag tag) {
            // Process any tag/node in your HTML 
            String name = tag.getTagName();
            // Set the Link's target to _blank if the href is external
            if ("a".equalsIgnoreCase(name)) {
            	LinkTag lnk = (LinkTag) tag;
            	String sUrl = lnk.extractLink();
                if(sUrl.startsWith("http://") || sUrl.startsWith("https://")) {
                    lnk.setLink(sRedirectorUrl+Gadgets.URLEncode(Base64Encoder.encode(sUrl)));
                }
            }
        }
    };

    Parser parser = Parser.createParser(sBody, sEnc);
    NodeList list = parser.parse(null);
    list.visitAllNodesWith(linkVisitor);

    if (DebugFile.trace) {
      DebugFile.decIdent();
      DebugFile.writeln("End HtmlMimeBodyPart.addClickThroughRedirector()");
    }

    return list.toHtml();
  } // addClickThroughRedirector

}

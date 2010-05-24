package com.knowgate.hipermail;

/*
  Copyright (C) 2009  Know Gate S.L. All rights reserved.

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

import java.util.HashMap;
import java.net.URL;

import org.apache.oro.text.regex.Pattern;
import org.apache.oro.text.regex.PatternMatcher;
import org.apache.oro.text.regex.PatternCompiler;
import org.apache.oro.text.regex.StringSubstitution;
import org.apache.oro.text.regex.Perl5Matcher;
import org.apache.oro.text.regex.Perl5Compiler;
import org.apache.oro.text.regex.MalformedPatternException;
import org.apache.oro.text.regex.Util;

import org.htmlparser.Parser;
import org.htmlparser.Node;
import org.htmlparser.util.NodeList;
import org.htmlparser.util.NodeIterator;
import org.htmlparser.util.ParserException;
import org.htmlparser.Tag;
import org.htmlparser.tags.LinkTag;
import org.htmlparser.tags.ImageTag;
import org.htmlparser.tags.TableTag;
import org.htmlparser.tags.TableColumn;
import org.htmlparser.beans.StringBean;
import org.htmlparser.filters.TagNameFilter;
import org.htmlparser.visitors.NodeVisitor;

import com.knowgate.misc.Gadgets;
import com.knowgate.debug.DebugFile;
import com.knowgate.debug.StackTraceUtil;

/**
 * <p>Used to perform some maipulations in HTML source code for e-mails</p>
 * @author Sergio Montoro Ten
 * @version 5.0
 */
public class HtmlMimeBodyPart {

  private static PatternMatcher oMatcher = new Perl5Matcher();
  private static PatternCompiler oCompiler = new Perl5Compiler();

  private String sBody;
  private String sEnc;
  
  private HashMap<String,String> oImgs;
  
  public HtmlMimeBodyPart(String sHtml, String sEncoding) {
    sBody = sHtml;
    sEnc = sEncoding;
    oImgs = new HashMap<String,String>(23);
  }

  public HashMap getImagesCids() {
    return oImgs;
  }

  private String doSubstitution(String sBase, String sAttributeName, String sFormerValue, String sNewValue)
  	throws ParserException {
  	
  	if (DebugFile.trace) DebugFile.writeln("HtmlMomeBodyPart.doSubstitution(..., "+sAttributeName+","+sFormerValue+","+sNewValue);

    StringSubstitution oSrcSubs = new StringSubstitution();

    String sPattern = "("+sAttributeName.toLowerCase()+"|"+sAttributeName.toUpperCase()+"|"+sAttributeName+")\\x20*=\\x20*(\"|')?" + sFormerValue + "(\"|')?";

    try {

      if (DebugFile.trace) DebugFile.writeln("Perl5Compiler.compile(\""+sPattern+"\", Perl5Compiler.SINGLELINE_MASK)");
      Pattern oPattern = oCompiler.compile(sPattern, Perl5Compiler.SINGLELINE_MASK);

      if (oMatcher.contains(sBase, oPattern)) {
      	String sMatch = oMatcher.getMatch().toString();
      	int iDquote = sMatch.indexOf('"');
      	int iSquote = sMatch.indexOf("'");
      	char cQuote = (char) 0;
      	if (iDquote>0 && iSquote>0)
      	  cQuote = iDquote<iSquote ? (char)34 : (char)39;
      	else if (iDquote>0)
      	  cQuote = (char)34;
      	else if (iSquote>0)
      	  cQuote = (char)39;
		if (cQuote==(char)0)
          oSrcSubs.setSubstitution(sMatch.substring(0,sAttributeName.length())+"="+sNewValue);
        else
          oSrcSubs.setSubstitution(sMatch.substring(0,sAttributeName.length())+"="+cQuote+sNewValue+cQuote);
    	return Util.substitute(oMatcher, oPattern, oSrcSubs, sBase);			
      } else {
      	return sBase;
      } // fi (oMatcher.contains())
    } catch (MalformedPatternException mpe) {
      if (DebugFile.trace) {
        DebugFile.writeln("MalformedPatternException " + mpe.getMessage());
        try { DebugFile.writeln(StackTraceUtil.getStackTrace(mpe)); } catch (Exception ignore) { }
      }
      throw new ParserException("ArrayIndexOutOfBoundsException " + mpe.getMessage()+ " pattern " + sPattern + " substitution " + sNewValue, mpe);        
    }
    catch (ArrayIndexOutOfBoundsException aiob) {
      if (DebugFile.trace) {
        DebugFile.writeln("ArrayIndexOutOfBoundsException " + aiob.getMessage());
        try { DebugFile.writeln(StackTraceUtil.getStackTrace(aiob)); } catch (Exception ignore) { }
      }
      throw new ParserException("ArrayIndexOutOfBoundsException " + aiob.getMessage()+ " pattern " + sPattern + " substitution " + sNewValue, aiob);
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

		/*
        try {
          sPattern = Gadgets.replace(oImgTag.extractImageLocn(),'\\',"\\\\");
          if (DebugFile.trace) DebugFile.writeln("Perl5Compiler.compile(\""+sPattern+"\", Perl5Compiler.SINGLELINE_MASK)");
          Pattern oPattern = oCompiler.compile(sPattern, Perl5Compiler.SINGLELINE_MASK);
          oSrcSubs.setSubstitution(sPreffix+oImgs.get(sSrc));
          if (DebugFile.trace) DebugFile.writeln("Util.substitute([PatternMatcher],"+ sSrc + ","+sPreffix+oImgs.get(sSrc)+",...)");
            sBodyCid = Util.substitute(oMatcher, oPattern, oSrcSubs, sBodyCid);
        } catch (MalformedPatternException neverthrown) { }
          catch (ArrayIndexOutOfBoundsException aiob) {
          	if (DebugFile.trace) {
          	  DebugFile.writeln("ArrayIndexOutOfBoundsException " + aiob.getMessage());
          	  try { DebugFile.writeln(StackTraceUtil.getStackTrace(aiob)); } catch (Exception ignore) { }
          	}
          	throw new ParserException("ArrayIndexOutOfBoundsException " + aiob.getMessage()+ " pattern " + sPattern + " substitution " + sPreffix+oImgs.get(sSrc),aiob);
        }
        */
        
        sBodyCid = doSubstitution (sBodyCid, "Src", Gadgets.replace(oImgTag.extractImageLocn(),'\\',"\\\\"), sPreffix+oImgs.get(sSrc));
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

		  /*
          try {
            Pattern oPattern = oCompiler.compile(Gadgets.replace(((TableTag) oCollectionList.elementAt(i)).getAttribute("background"),'\\',"\\\\"),
            									 Perl5Compiler.SINGLELINE_MASK);
            oSrcSubs.setSubstitution(sPreffix+oImgs.get(sSrc));
            if (DebugFile.trace) DebugFile.writeln("Util.substitute([PatternMatcher],"+ sSrc + ","+sPreffix+oImgs.get(sSrc)+",...)");
            sBodyCid = Util.substitute(oMatcher, oPattern, oSrcSubs, sBodyCid);
          } catch (MalformedPatternException neverthrown) { }
		  */
		  
		  sBodyCid = doSubstitution (sBodyCid, "Background", Gadgets.replace(((TableTag) oCollectionList.elementAt(i)).getAttribute("background"),'\\',"\\\\"), sPreffix+oImgs.get(sSrc));

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
          } // fi (!oImgs.containsKey(sSrc))

		  /*
          try {
            Pattern oPattern = oCompiler.compile(Gadgets.replace(((TableColumn) oCollectionList.elementAt(i)).getAttribute("background"),'\\',"\\\\"),
            									 Perl5Compiler.SINGLELINE_MASK);
            oSrcSubs.setSubstitution(sPreffix+oImgs.get(sSrc));
            if (DebugFile.trace) DebugFile.writeln("Util.substitute([PatternMatcher],"+ sSrc + ","+sPreffix+oImgs.get(sSrc)+",...)");
            sBodyCid = Util.substitute(oMatcher, oPattern, oSrcSubs, sBodyCid);
          } catch (MalformedPatternException neverthrown) { }
		  */
		  
		  sBodyCid = doSubstitution(sBodyCid, "Background", Gadgets.replace(((TableColumn) oCollectionList.elementAt(i)).getAttribute("background"),'\\',"\\\\"), sPreffix+oImgs.get(sSrc));
        } // fi
      } // fi
    } // next

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

		/*
        try {
          String sImgSrc = ((ImageTag) oCollectionList.elementAt(i)).extractImageLocn();
          if (sImgSrc.startsWith(sPreffix)) {
            Pattern oPattern = oCompiler.compile(Gadgets.replace(sImgSrc,'\\',"\\\\"),
            								     Perl5Compiler.SINGLELINE_MASK);
            oSrcSubs.setSubstitution(sImgSrc.substring(sPreffix.length()));
            if (DebugFile.trace) DebugFile.writeln("Util.substitute([PatternMatcher],"+ sSrc + ","+sImgSrc.substring(sPreffix.length())+",...)");
              sBodyCid = Util.substitute(oMatcher, oPattern, oSrcSubs, sBodyCid);
          }
        } catch (MalformedPatternException neverthrown) { }
        */
        
        String sImgSrc = ((ImageTag) oCollectionList.elementAt(i)).extractImageLocn();
        if (sImgSrc.startsWith(sPreffix)) {
          sBodyCid = doSubstitution(sBodyCid, "Src", Gadgets.replace(sImgSrc,'\\',"\\\\"), sImgSrc.substring(sPreffix.length()));
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

		  /*
          try {
          	String sBckGrnd = ((TableTag) oCollectionList.elementAt(i)).getAttribute("background");
            if (sBckGrnd.startsWith(sPreffix)) {
              Pattern oPattern = oCompiler.compile(Gadgets.replace(sBckGrnd,'\\',"\\\\"),
            									   Perl5Compiler.SINGLELINE_MASK);
              oSrcSubs.setSubstitution(sBckGrnd.substring(sPreffix.length()));
              if (DebugFile.trace) DebugFile.writeln("Util.substitute([PatternMatcher],"+ sSrc + ","+sBckGrnd.substring(sPreffix.length())+",...)");
              sBodyCid = Util.substitute(oMatcher, oPattern, oSrcSubs, sBodyCid);
            } 
          } catch (MalformedPatternException neverthrown) { }
          */

          String sBckGrnd = ((TableTag) oCollectionList.elementAt(i)).getAttribute("background");
          if (sBckGrnd.startsWith(sPreffix)) {
            sBodyCid = doSubstitution(sBodyCid, "Background", Gadgets.replace(sBckGrnd,'\\',"\\\\"), sBckGrnd.substring(sPreffix.length()));
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
          } // fi (!oImgs.containsKey(sSrc))

          /*
          try {
          	String sTdBckg = ((TableColumn) oCollectionList.elementAt(i)).getAttribute("background");
            if (sTdBckg.startsWith(sPreffix)) {
              Pattern oPattern = oCompiler.compile(Gadgets.replace(sTdBckg,'\\',"\\\\"),
            									 Perl5Compiler.SINGLELINE_MASK);
              oSrcSubs.setSubstitution(sTdBckg.substring(sPreffix.length()));
              if (DebugFile.trace) DebugFile.writeln("Util.substitute([PatternMatcher],"+ sSrc + ","+sPreffix.length()+",...)");
              sBodyCid = Util.substitute(oMatcher, oPattern, oSrcSubs, sBodyCid);
            }
          } catch (MalformedPatternException neverthrown) { }
		  */

          String sTdBckg = ((TableColumn) oCollectionList.elementAt(i)).getAttribute("background");
          if (sTdBckg.startsWith(sPreffix)) {
            sBodyCid = doSubstitution(sBodyCid, "Background", Gadgets.replace(sTdBckg,'\\',"\\\\"), sTdBckg.substring(sPreffix.length()));
          }

        } // fi
      } // fi
    } // next

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

  public String addClickThroughRedirector(final String sRedirectorUrl)
  	throws ParserException {
    final NodeVisitor linkVisitor = new NodeVisitor() {

        public void visitTag(Tag tag) {
            // Process any tag/node in your HTML 
            String name = tag.getTagName();

            // Set the Link's target to _blank if the href is external
            if ("a".equalsIgnoreCase(name)) {
            	LinkTag lnk = (LinkTag) tag;
            	String sUrl = lnk.extractLink();
                if(sUrl.startsWith("http://") || sUrl.startsWith("https://")) {
                    lnk.setLink(sRedirectorUrl+Gadgets.URLEncode(sUrl));
                }
            }
        }
    };

    Parser parser = Parser.createParser(sBody, sEnc);
    NodeList list = parser.parse(null);
    list.visitAllNodesWith(linkVisitor);
    return list.toHtml();
  } // addClickThroughRedirector

}

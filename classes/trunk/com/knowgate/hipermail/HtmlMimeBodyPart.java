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
import org.htmlparser.tags.ImageTag;
import org.htmlparser.tags.TableTag;
import org.htmlparser.tags.TableColumn;
import org.htmlparser.beans.StringBean;
import org.htmlparser.filters.TagNameFilter;

import com.knowgate.misc.Gadgets;
import com.knowgate.debug.DebugFile;

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

  /**
   * <p>Add a preffix to &lt;IMG SRC="..."&gt; &lt;TABLE BACKGROUND="..."&gt; and &lt;TD BACKGROUND="..."&gt; tags</p>
   * @param sPreffix String preffix to be added to &lt;img&gt; src attribute and &lt;table&gt; and &lt;td&gt; background
   * @return New HTML source with preffixed attributes
   */
  public String addPreffixToImgSrc(String sPreffix)
  	throws ParserException {

    int iSlash;
    Parser oPrsr;
    String sCid, sSrc;
    String sBodyCid = sBody;
    NodeList oCollectionList;
    TagNameFilter oImgFilter;
    StringSubstitution oSrcSubs = new StringSubstitution();

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

        try {
          Pattern oPattern = oCompiler.compile(Gadgets.replace(((ImageTag) oCollectionList.elementAt(i)).extractImageLocn(),'\\',"\\\\"),
            								   Perl5Compiler.SINGLELINE_MASK);
          oSrcSubs.setSubstitution(sPreffix+oImgs.get(sSrc));
          if (DebugFile.trace) DebugFile.writeln("Util.substitute([PatternMatcher],"+ sSrc + ","+sPreffix+oImgs.get(sSrc)+",...)");
            sBodyCid = Util.substitute(oMatcher, oPattern, oSrcSubs, sBodyCid);
        } catch (MalformedPatternException neverthrown) { }
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

          try {
            Pattern oPattern = oCompiler.compile(Gadgets.replace(((TableTag) oCollectionList.elementAt(i)).getAttribute("background"),'\\',"\\\\"),
            									 Perl5Compiler.SINGLELINE_MASK);
            oSrcSubs.setSubstitution(sPreffix+oImgs.get(sSrc));
            if (DebugFile.trace) DebugFile.writeln("Util.substitute([PatternMatcher],"+ sSrc + ","+sPreffix+oImgs.get(sSrc)+",...)");
            sBodyCid = Util.substitute(oMatcher, oPattern, oSrcSubs, sBodyCid);
          } catch (MalformedPatternException neverthrown) { }

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

          try {
            Pattern oPattern = oCompiler.compile(Gadgets.replace(((TableColumn) oCollectionList.elementAt(i)).getAttribute("background"),'\\',"\\\\"),
            									 Perl5Compiler.SINGLELINE_MASK);
            oSrcSubs.setSubstitution(sPreffix+oImgs.get(sSrc));
            if (DebugFile.trace) DebugFile.writeln("Util.substitute([PatternMatcher],"+ sSrc + ","+sPreffix+oImgs.get(sSrc)+",...)");
            sBodyCid = Util.substitute(oMatcher, oPattern, oSrcSubs, sBodyCid);
          } catch (MalformedPatternException neverthrown) { }

        } // fi
      } // fi
    } // next

    return sBodyCid;
  } // addPreffixToImgSrcs


  /**
   * <p>Remove a preffix from &lt;IMG SRC="..."&gt; &lt;TABLE BACKGROUND="..."&gt; and &lt;TD BACKGROUND="..."&gt; tags</p>
   * @param sPreffix String preffix to be removed from &lt;img&gt; src attribute and &lt;table&gt; and &lt;td&gt; background
   * @return New HTML source with unpreffixed attributes
   */
  public String removePreffixFromImgSrcs(String sPreffix)
  	throws ParserException {

    int iSlash;
    Parser oPrsr;
    String sCid, sSrc;
    String sBodyCid = sBody;
    NodeList oCollectionList;
    TagNameFilter oImgFilter;
    StringSubstitution oSrcSubs = new StringSubstitution();

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

        } // fi
      } // fi
    } // next

    return sBodyCid;
  } // removePreffixFromImgSrcs

  public String replacePreffixFromImgSrcs(String sFormerPreffix, String sNewPreffix)
  	throws ParserException {
	HtmlMimeBodyPart oHtml = new HtmlMimeBodyPart(removePreffixFromImgSrcs(sFormerPreffix), sEnc);
	return oHtml.addPreffixToImgSrc(sNewPreffix);
  } // replacePreffixFromImgSrcs
}

/*
  Copyright (C) 2003-2005  Know Gate S.L. All rights reserved.
                           C/Oña, 107 1º2 28050 Madrid (Spain)

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

package com.knowgate.surveys;

import org.mozilla.javascript.Context;
import org.mozilla.javascript.Scriptable;
import org.mozilla.javascript.JavaScriptException;

import com.knowgate.debug.DebugFile;

/**
 * @version 1.0
 */
public class RouteCase {

  // ---------------------------------------------------------------------------

  protected int page;
  protected String test;

  // ---------------------------------------------------------------------------

  public RouteCase() {
    page=-1;
    test="undefined";
  }

  // ---------------------------------------------------------------------------

  public int getPageNumber() {
    return page;
  }

  // ---------------------------------------------------------------------------

  public void setPageNumber(int num) {
    page=num;
  }

  // ---------------------------------------------------------------------------

  public String getTestExpr() {
    return test;
  }

  // ---------------------------------------------------------------------------

  public void setTestExpr(String jsExpr) {
    test = jsExpr;
  }

  // ---------------------------------------------------------------------------

  public static boolean eval(String expr)
    throws JavaScriptException,ClassCastException {
    if (DebugFile.trace) {
      DebugFile.writeln("Begin RouteCase.eval("+expr+")");
      DebugFile.incIdent();
    }
    Context jscx = Context.enter();
    Scriptable scope = jscx.initStandardObjects();
    Boolean bool = (Boolean) jscx.evaluateString(scope, expr, "jsexpr", 1, null);
    Context.exit();
    if (DebugFile.trace) {
      DebugFile.decIdent();
      DebugFile.writeln("End RouteCase.eval() : " + bool.toString());
    }
    return bool.booleanValue();
  } // eval

  // ---------------------------------------------------------------------------

  public boolean eval()
    throws JavaScriptException,ClassCastException {
    if (DebugFile.trace) {
      DebugFile.writeln("Begin RouteCase.eval()");
      DebugFile.incIdent();
      DebugFile.writeln("testExpr="+test);
    }
    Context jscx = Context.enter();
    Scriptable scope = jscx.initStandardObjects();
    Boolean bool = (Boolean) jscx.evaluateString(scope, test, "jsexpr", 1, null);
    Context.exit();
    if (DebugFile.trace) {
      DebugFile.decIdent();
      DebugFile.writeln("End RouteCase.eval() : " + bool.toString());
    }
    return bool.booleanValue();
  } // eval

  // ---------------------------------------------------------------------------
} // RouteCase

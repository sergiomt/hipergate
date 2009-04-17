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

import java.util.ArrayList;

import org.mozilla.javascript.JavaScriptException;

import com.knowgate.debug.DebugFile;

/**
 * @author Sergio Montoro Ten
 * @version 1.0
 */
public class CaseRoute {

  // ---------------------------------------------------------------------------

  protected ArrayList routecases;
  protected RouteCase elseroute;

  // ---------------------------------------------------------------------------

  public CaseRoute() {
    routecases = new ArrayList();
    elseroute = null;
  }

  // ---------------------------------------------------------------------------

  /**
   *
   * @param datasht DataSheet object with parameters for evaluating CaseRoute JavaScript expression
   * @return Number of next page or -1 no no caseroute expression evaluates to true and no elseroute is set
   * @throws ClassCastException
   * @throws JavaScriptException
   */
  public int getPageNumber(DataSheet datasht)
    throws ClassCastException,JavaScriptException {

    if (DebugFile.trace) {
      DebugFile.writeln("Begin CaseRoute.getPageNumber()");
      DebugFile.incIdent();
    }
    int pagnum = -1;
    final int routes = routecases.size();
    final int answers= datasht.countAnswers();
    StringBuffer buff;
    String expr;
    RouteCase route;
    int dollar = -1;
    int brackt = -1;

    for (int r=0; r<routes; r++) {
      route = (RouteCase) routecases.get(r);
      expr = route.getTestExpr();
      dollar = expr.indexOf("{$");
      while (dollar>=0) {
        brackt = expr.indexOf('}', dollar);
        if (dollar>=0 && brackt>=0) {
          for (int a=0; a<answers; a++) {
            if (datasht.getAnswer(a).getName().equals(expr.substring(dollar+2,brackt))) {
              if (DebugFile.trace) DebugFile.writeln(expr.substring(dollar+2,brackt)+"="+datasht.getAnswer(a).getValue());
              buff = new StringBuffer(expr.length());
              if (dollar>0) buff.append(expr.substring(0,dollar));
              buff.append(datasht.getAnswer(a).getValue());
              if (brackt<expr.length()-1) buff.append(expr.substring(brackt+1));
              expr = buff.toString();
            } // fi (answer.name=={$...})
          } // next (a)
        } // fi (dollar>=0 && brackt>=0)
        else break;
        dollar = expr.indexOf("{$");
      } // wend

      if (RouteCase.eval(expr)) {
        pagnum = route.getPageNumber();
        break;
      }
    } // next

    if (pagnum==-1) {
      if (null!=elseroute) {
        pagnum = elseroute.getPageNumber();
        if (DebugFile.trace) DebugFile.writeln("getting elseroute page number " + String.valueOf(pagnum));
      }
      else {
        if (DebugFile.trace) DebugFile.writeln("No RouteCase evaluated to true and no elseroute was set");
      }
    } // fi (pagnum==-1)

    if (DebugFile.trace) {
      DebugFile.decIdent();
      DebugFile.writeln("End CaseRoute.getPageNumber() : " + String.valueOf(pagnum));
    }
    return pagnum;
  } // url

  // ---------------------------------------------------------------------------
}

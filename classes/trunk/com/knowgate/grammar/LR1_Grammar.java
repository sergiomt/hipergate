
package com.knowgate.grammar;


/**
* <p>This class implements an LR(1) parser around a {@link Grammar}. The parser adapts to changes in the underlying <code>Grammar</code>. <code>Semantics</code> in a phrase are evaluated during a bottom-up parse, from left to right after all subtrees rooted in the phrase have been constructed. Attributes throughout the phrase are available during evaluation. LR(1) parsing considers context-specific lookahead terminals to more accurately choose between applicable phrases. LR(1) parsing is the default method used for a <code>Grammar</code> around which no parser has been explicitly constructed, and is the recommended method.</p>
*
* @version 0.9
* @author &copy; 1999-2000 <a href="http://www.csupomona.edu/~carich/">Craig A. Rich</a> &lt;<a href="mailto:carich@acm.org">carich@acm.org</a>&gt;
* @see <a href="../../../src/gi/LR1_Grammar.java">Source code</a>
*/
public class LR1_Grammar extends LR0_Grammar {

	/**
	* <p>Constructs an LR(1) parser around a new empty <code>Grammar</code>.</p>
	*/
	protected LR1_Grammar() {
		Set follow = new Set(1);
		follow.append(END_OF_SOURCE);
		this.start.follow = follow;
	}

	/**
	* <p>Constructs an LR(1) parser around an existing <code>Grammar</code>.</p>
	*
	* @param grammar the <code>Grammar</code> around which the parser is constructed.
	*/
	protected LR1_Grammar(Grammar grammar) {
		super(grammar);
		Set follow = new Set(1);
		follow.append(END_OF_SOURCE);
		this.start.follow = follow;
	}
}

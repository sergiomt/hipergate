
package com.knowgate.grammar;


/**
* <p>This class implements an SLR(1) parser around a {@link Grammar}. The parser adapts to changes in the underlying <code>Grammar</code>. <code>Semantics</code> in a phrase are evaluated during a bottom-up parse, from left to right after all subtrees rooted in the phrase have been constructed. Attributes throughout the phrase are available during evaluation. SLR(1) parsing is more space- and time-efficient than LR(1) parsing; however, SLR(1) parsing is more easily confused than LR(1) parsing, since it considers lookahead terminals generally following a nonterminal (rather than specifically following it in a context) to choose between applicable phrases.</p>
*
* @version 0.9
* @author &copy; 1999-2000 <a href="http://www.csupomona.edu/~carich/">Craig A. Rich</a> &lt;<a href="mailto:carich@acm.org">carich@acm.org</a>&gt;
* @see <a href="../../../src/gi/SLR1_Grammar.java">Source code</a>
*/
public class SLR1_Grammar extends LR0_Grammar {

	/**
	* <p>Constructs an SLR(1) parser around a new empty <code>Grammar</code>.</p>
	*/
	protected SLR1_Grammar() {}

	/**
	* <p>Constructs an SLR(1) parser around an existing <code>Grammar</code>.</p>
	*
	* @param grammar the <code>Grammar</code> around which the parser is constructed.
	*/
	protected SLR1_Grammar(Grammar grammar) {
		super(grammar);
	}


	/**
	* <p>Computes the <code>Production</code> to use in a reverse rightmost derivation.</p>
	*
	* @param state the <code>State</code>.
	* @param lookahead the lookahead terminal.
	* @return the highest priority <code>Production</code> underlying an applicable reduce <code>Context</code> in <code>state</code>; returns <code>null</code> if none.
	*/
	Production parse(State state, Object lookahead) {
		Object start_nonterminal = this.start.production.nonterminal;
		int state_size = state.size;
		Context[] state_contexts = state.contexts;
		Production parse = null;

		for (int i = 0; i < state_size; i++) {
			Context context = state_contexts[i];
			Production production = context.production;
			if (context.position < production.phrase.length) continue;

			Object nonterminal = production.nonterminal;
			if ((nonterminal != start_nonterminal) ? !follow(nonterminal).contains(lookahead) : lookahead != END_OF_SOURCE) continue;

			if (parse == null || parse.number < production.number) parse = production;
		}
		return parse;
	}
}

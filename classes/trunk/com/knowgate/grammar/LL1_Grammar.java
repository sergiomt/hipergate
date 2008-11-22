
package com.knowgate.grammar;


import java.io.*;

/**
* <p>This class implements an LL(1) parser around a {@link Grammar}. The parser adapts to changes in the underlying <code>Grammar</code>. <code>Semantics</code> in a phrase are evaluated during a top-down left-to-right recursive descent parse, when they are first visited. Attributes above or to the left of the <code>Semantics</code> are available during evaluation. A <code>Grammar</code> with left-recursive productions can cause infinite recursion, unless productions that terminate recursion have priority over productions that recurse.</p>
*
* @version 0.9
* @author &copy; 1999-2000 <a href="http://www.csupomona.edu/~carich/">Craig A. Rich</a> &lt;<a href="mailto:carich@acm.org">carich@acm.org</a>&gt;
* @see <a href="../../../src/gi/LL1_Grammar.java">Source code</a>
*/
public class LL1_Grammar extends Grammar {

	/**
	* <p>The lookahead terminal.</p>
	*/
	private Object lookahead;

	/**
	* <p>Constructs an LL(1) parser around a new empty <code>Grammar</code>.</p>
	*/
	protected LL1_Grammar() {}

	/**
	* <p>Constructs an LL(1) parser around an existing <code>Grammar</code>.</p>
	*
	* @param grammar the <code>Grammar</code> around which the parser is constructed.
	*/
	protected LL1_Grammar(Grammar grammar) {
		super(grammar);
	}


	/**
	* <p>Interprets a source character stream by LL(1) recursive descent.</p>
	*
	* @param source the source character stream.
	* @return the <code>ParseTree</code> constructed by interpreting <code>source</code>.
	* @throws Lexicon.Exception if an I/O, lexical, syntax or semantic error occurs.
	*/
	ParseTree interpret(LineNumberReader source) throws Exception {
		this.lookahead = grab(source);
		ParseTree tree = new ParseTree(this.start, null, null);
		descend(source, tree);
		return tree;
	}

	/**
	* <p>Completes a seed <code>ParseTree</code> by LL(1) recursive descent.</p>
	*
	* @param source the source character stream.
	* @param root a seed <code>ParseTree</code> to be completed by interpreting <code>source</code>.
	* @throws Lexicon.Exception if an I/O, lexical, syntax or semantic error occurs.
	*/
	private void descend(BufferedReader source, ParseTree root) throws Exception {
		Object lookahead = this.lookahead;
		Object root_symbol = root.symbol;

		if (terminal(root_symbol)) {
			if (root_symbol != lookahead) throw new Exception("expected " + root_symbol).extend(source);
			root.attribute = word();
			this.lookahead = grab(source);
		}
		else {
			Production production = parse(root_symbol, lookahead);
			if (production == null) throw new Exception("expected " + expected(root_symbol)).extend(source);
			Object[] phrase = production.phrase;
			int phrase_length = phrase.length;
			ParseTree[] root_phrase = new ParseTree[phrase_length];
			root.phrase = root_phrase;
			for (int i = 0; i < phrase_length; i++) root_phrase[i] = new ParseTree(phrase[i], null, null);

			for (int i = 0; i < phrase_length; i++) {
				Object symbol = phrase[i];

				if (symbol instanceof Semantics) try {
					((Semantics)symbol).evaluate(root);
				}
				catch (Exception exception) {
					throw exception.extend(source);
				}
				else descend(source, root_phrase[i]);
			}
		}
	}


	/**
	* <p>Computes a <code>Production</code> to use in a leftmost derivation.</p>
	*
	* @param nonterminal the expected nonterminal.
	* @param lookahead the lookahead terminal.
	* @return the highest priority <code>Production</code> with which to replace the expected nonterminal and eventually match the lookahead terminal; returns <code>null</code> if none.
	*/
	private Production parse(Object nonterminal, Object lookahead) {
		Set productions = (Set)this.productions.get(nonterminal);
		int productions_size = productions.size;
		Object[] productions_elements = productions.elements;

		for (int i = productions_size; --i >= 0;) {
			Production production = (Production)productions_elements[i];
			Set first = first(production.phrase, 0);
			if (first.contains(lookahead) || (first.contains(null) && follow(nonterminal).contains(lookahead))) return production;
		}
		return null;
	}

	/**
	* <p>Computes the terminals matching a nonterminal.</p>
	*
	* @param nonterminal the expected nonterminal.
	* @return the terminals matching the expected nonterminal.
	*/
	private Set expected(Object nonterminal) {
		Set expected = new Set(-50);
		Set first = first(nonterminal);
		expected.add(first, 0);
		if (first.contains(null)) expected.add(follow(nonterminal), 0);
		return expected;
	}
}

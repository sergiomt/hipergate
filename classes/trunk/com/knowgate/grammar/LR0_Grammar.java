
package com.knowgate.grammar;


import java.io.*;

/**
* <p>This class implements an LR(0) parser around a {@link Grammar}. The parser adapts to changes in the underlying <code>Grammar</code>. <code>Semantics</code> in a phrase are evaluated during a bottom-up parse, from left to right after all subtrees rooted in the phrase have been constructed. Attributes throughout the phrase are available during evaluation. LR(0) parsing is not very practical, since it ignores lookahead information and is easily confused, but it forms a basis around which SLR(1) and LR(1) parsers are constructed.</p>
*
* @version 0.9
* @author &copy; 1999-2000 <a href="http://www.csupomona.edu/~carich/">Craig A. Rich</a> &lt;<a href="mailto:carich@acm.org">carich@acm.org</a>&gt;
* @see <a href="../../../src/gi/LR0_Grammar.java">Source code</a>
*/
public class LR0_Grammar extends Grammar {

	/**
	* <p>The start <code>Context</code>.</p>
	*/
	final Context start = new Context(new Production(new String("START"), new Object[1]), 0);

	/**
	* <p>The states through which this parser transitions.</p>
	*/
	private final Set states = new Set(200);

	/**
	* <p>The parse trees through which this parser transitions.</p>
	*/
	private final Set trees = new Set(200);


	/**
	* <p>Constructs an LR(0) parser around a new empty <code>Grammar</code>.</p>
	*/
	protected LR0_Grammar() {
		State initial = new State();
		initial.size = 1;
		initial.contexts[0] = this.start;
		this.states.append(initial);
		this.trees.append(null);
	}

	/**
	* <p>Constructs an LR(0) parser around an existing <code>Grammar</code>.</p>
	*
	* @param grammar the <code>Grammar</code> around which the parser is constructed.
	*/
	protected LR0_Grammar(Grammar grammar) {
		super(grammar);
		State initial = new State();
		initial.size = 1;
		initial.contexts[0] = this.start;
		this.states.append(initial);
		this.trees.append(null);
	}


	/**
	* <p>This class implements a shift/reduce {@link LR0_Grammar.Context <code>Context</code>}.</p>
	*
	* @version 0.9
	* @author &copy; 1999-2000 <a href="http://www.csupomona.edu/~carich/">Craig A. Rich</a> &lt;<a href="mailto:carich@acm.org">carich@acm.org</a>&gt;
	*/
	static class Context {

		/**
		* <p>The <code>Production</code> in this <code>Context</code>.</p>
		*/
		Production production;

		/**
		* <p>The progress position in this <code>Context</code>.</p>
		*/
		int position;

		/**
		* <p>The follow <code>Set</code> in this <code>Context</code>. If <code>null</code>, this <code>Context</code> is an LR(0) <code>Context</code>; otherwise it is an LR(1) <code>Context</code>.</p>
		*/
		Set follow;

		/**
		* <p>The frontier beyond which null-closure has not been pursued.</p>
		*/
		private int frontier;

		/**
		* <p>Constructs a shift/reduce <code>Context</code>.</p>
		*
		* @param production the <code>Production</code> in this <code>Context</code>.
		* @param position the progress position in this <code>Context</code>.
		*/
		Context(Production production, int position) {
			this.production = production;
			this.position = position;
		}


		/**
		* <p>Returns a string representation of this <code>Context</code>.</p>
		*
		* @return the string representation of this <code>Context</code>.
		*/
		public String toString() {
			StringBuffer result = new StringBuffer(132);
			result.append(this.position);
			result.append(' ');
			result.append(this.frontier);
			result.append(' ');
			result.append(this.production);
			Set follow = this.follow;

			if (follow != null) {
				result.append(' ');
				result.append(follow);
			}
			return result.toString();
		}
	}


	/**
	* <p>This class implements a {@link LR0_Grammar.State <code>State</code>} in an LR parser.</p>
	*
	* @version 0.9
	* @author &copy; 1999-2000 <a href="http://www.csupomona.edu/~carich/">Craig A. Rich</a> &lt;<a href="mailto:carich@acm.org">carich@acm.org</a>&gt;
	*/
	static class State {

		/**
		* <p>The number of <code>Context</code>s in this <code>State</code>.</p>
		*/
		int size;

		/**
		* <p>The <code>Context</code>s in this <code>State</code>.</p>
		*/
		Context[] contexts = new Context[150];

		/**
		* <p>Returns a string representation of this <code>State</code>.</p>
		*
		* @return the string representation of this <code>State</code>.
		*/
		public String toString() {
			int size = this.size;
			Context[] contexts = this.contexts;
			StringBuffer result = new StringBuffer(132);

			for (int i = 0; i < size; i++) {
				result.append("\n\t\t");
				result.append(contexts[i]);
			}
			return result.toString();
		}


		/**
		* <p>Appends a <code>Context</code> to this <code>State</code>.</p>
		*
		* @param production the <code>Production</code> to be appended.
		* @param int the progress position to be appended.
		* @param follow the follow <code>Set</code> to be appended.
		*
		* @return the index in this <code>State</code> at which the <code>Context</code> occurs.
		*/
		private int append(Production production, int position, Set follow) {
			int size = this.size;
			Context[] contexts = this.contexts;

			if (size == contexts.length) System.arraycopy(contexts, 0, this.contexts = contexts = new Context[size + 100], 0, size);
			Context context = contexts[size];

			if (context != null) {
				context.production = production;
				context.position = position;
				context.frontier = 0;
			}
			else contexts[size] = context = new Context(production, position);
			this.size++;

			if (follow != null) {
				Set context_follow = context.follow;
				if (context_follow == null) context.follow = context_follow = new Set(-50);
				else context_follow.size = 0;
				context_follow.add(follow, 0);
			}
			return size;
		}

		/**
		* <p>Adds a <code>Context</code> to this <code>State</code>.</p>
		*
		* @param production the <code>Production</code> to be added.
		* @param int the progress position to be added.
		* @param follow the follow <code>Set</code> to be added.
		*
		* @return the index in this <code>State</code> at which the <code>Context</code> occurs if this <code>State</code> changed; otherwise the size of this <code>State</code>.
		*/
		private int add(Production production, int position, Set follow) {
			int size = this.size;
			Context[] contexts = this.contexts;

			for (int i = 0; i < size; i++) {
				Context context = contexts[i];
				if (context.production == production && context.position == position) return (follow == null || !context.follow.add(follow, 0)) ? size : i;
			}
			return append(production, position, follow);
		}
	}


	/**
	* <p>Interprets a source character stream by LR shift-reduce ascent.</p>
	*
	* @param source the source character stream.
	* @throws Lexicon.Exception if an I/O, lexical, syntax or semantic error occurs.
	* @return the <code>ParseTree</code> constructed by interpreting <code>source</code>.
	*/
	ParseTree interpret(LineNumberReader source) throws Exception {
		Context start = this.start;
		Set states = this.states;
		Set trees = this.trees;
		Production start_production = start.production;
		Object start_nonterminal = start_production.nonterminal;
		int top = 0;
		State initial = (State)states.elements[top];
		Object lookahead = grab(source);

		start_production.phrase[0] = super.start;
		start.frontier = 0;
		initial.size = 1;
		closure(initial);


		while (true) {

			if (top + 1 == states.size) {
				states.append(new State());
				trees.append(null);
			}
			State from = (State)states.elements[top];
			State to = closure(transition(from, lookahead, (State)states.elements[top + 1]));
			ParseTree tree;

			if (to.size != 0) {
				tree = new ParseTree(lookahead, word(), null);
				lookahead = grab(source);
			}
			else {
				Production production = parse(from, lookahead);
				if (production == null) throw new Exception("expected " + expected(from)).extend(source);
				Object nonterminal = production.nonterminal;
				if (nonterminal == start_nonterminal) return (ParseTree)trees.elements[top];
				Object[] phrase = production.phrase;
				int phrase_length = phrase.length;
				ParseTree[] tree_phrase = new ParseTree[phrase_length];
				tree = new ParseTree(nonterminal, null, tree_phrase);

				for (int i = phrase_length; --i >= 0;) {
					Object symbol = phrase[i];
					tree_phrase[i] = (symbol instanceof Semantics) ? new ParseTree(symbol, null, null) : (ParseTree)trees.elements[top--];
				}
				for (int i = 0; i < phrase_length; i++) {
					Object symbol = phrase[i];

					if (symbol instanceof Semantics) try {
						((Semantics)symbol).evaluate(tree);
					}
					catch (Exception exception) {
						throw exception.extend(source);
					}
				}
				from = (State)states.elements[top];
				to = closure(transition(from, nonterminal, (State)states.elements[top + 1]));
			}
			trees.elements[++top] = tree;
		}
	}


	/**
	* <p>Computes the <code>Production</code> to use in a reverse rightmost derivation.</p>
	*
	* @param state the <code>State</code>.
	* @param lookahead the lookahead terminal.
	* @return the highest priority <code>Production</code> underlying an applicable reduce <code>Context</code> in <code>state</code>; returns <code>null</code> if none.
	*/
	Production parse(State state, Object lookahead) {
		int state_size = state.size;
		Context[] state_contexts = state.contexts;
		Production parse = null;

		for (int i = 0; i < state_size; i++) {
			Context context = state_contexts[i];
			Production production = context.production;
			if (context.position < production.phrase.length) continue;

			Set follow = context.follow;
			if (follow != null && !follow.contains(lookahead)) continue;

			if (parse == null || parse.number < production.number) parse = production;
		}
		return parse;
	}

	/**
	* <p>Computes a transition from a <code>State</code> on a symbol.</p>
	*
	* @param from the <code>State</code> from which the transition is made.
	* @param on the symbol on which the transition is made.
	* @param to the <code>State</code> to which the transition is made.
	* @return the <code>State</code> to which the transition is made.
	*/
	private static State transition(State from, Object on, State to) {
		int from_size = from.size;
		Context[] from_contexts = from.contexts;
		to.size = 0;

		for (int i = 0; i < from_size; i++) {
			Context context = from_contexts[i];
			Production production = context.production;
			int position = context.position;
			Object[] phrase = production.phrase;
			if (position < phrase.length && phrase[position] == on) to.append(production, position + 1, context.follow);
		}
		return to;
	}


	/**
	* <p>Computes the null-closure of a <code>State</code>.</p>
	*
	* @param from the <code>State</code> whose null-closure is computed.
	* @return the reflexive transitive closure of <code>from</code> under null transition.
	*/
	private State closure(State from) {

		while (true) {
			boolean closed = true;

			for (int i = 0; i < from.size; i++) {
				Context context = from.contexts[i];
				Set follow = context.follow;
				int frontier = context.frontier;

				if (follow != null) {
					int follow_size = follow.size;
					if (frontier == follow_size) continue;
					context.frontier = follow_size;
				}
				Production production = context.production;
				int position = context.position;
				Object[] phrase = production.phrase;
				int phrase_length = phrase.length;
				while (position < phrase_length && phrase[position] instanceof Semantics) context.position = ++position;
				if (position == phrase_length) continue;

				Object symbol = phrase[position];
				Set symbol_productions = (Set)this.productions.get(symbol);
				if (symbol_productions == null) continue;

				int symbol_productions_size = symbol_productions.size;
				Set symbol_follow = null;

				if (follow != null) {
					symbol_follow = first(phrase, position + 1);

					if (symbol_follow.contains(null)) {
						symbol_follow.size--;
						if (frontier > 0) symbol_follow.size = 0;
						symbol_follow.add(follow, frontier);
					}
				}
				for (int j = 0; j < symbol_productions_size; j++) {
					Production symbol_production = (Production)symbol_productions.elements[j];
					if (from.add(symbol_production, 0, symbol_follow) <= i) closed = false;
				}
			}
			if (closed) break;
		}
		return from;
	}


	/**
	* <p>Computes the terminals expected in a <code>State</code>.</p>
	*
	* @param state the <code>State</code>.
	* @return the terminals matching a shift or reduce <code>Context</code> in <code>state</code>.
	*/
	private Set expected(State state) {
		int state_size = state.size;
		Context[] state_contexts = state.contexts;
		Set expected = new Set(-50);

		for (int i = 0; i < state_size; i++) {
			Context context = state_contexts[i];
			Production production = context.production;
			int position = context.position;
			Object[] phrase = production.phrase;

			if (position < phrase.length) {
				Object symbol = phrase[position];
				if (terminal(symbol)) expected.add(symbol);
			}
			else {
				Set follow = context.follow;
				expected.add((follow != null) ? follow : follow(production.nonterminal), 0);
			}
		}
		return expected;
	}
}

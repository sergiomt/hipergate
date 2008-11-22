
package com.knowgate.grammar;

import java.io.*;
import java.util.*;

/**
* <p>This class implements a {@link Grammar}.</p>
*
* @version 0.9
* @author &copy; 1999-2000 <a href="http://www.csupomona.edu/~carich/">Craig A. Rich</a> &lt;<a href="mailto:carich@acm.org">carich@acm.org</a>&gt;
* @see <a href="../../../src/gi/Grammar.java">Source code</a>
*/
public class Grammar extends Lexicon {

	/**
	* <p>The number of <code>Production</code>s constructed.</p>
	*/
	private static int size = 0;

	/**
	* <p>The start symbol of this <code>Grammar</code>. It is the nonterminal on the left-hand side of the <code>Production</code> first put into this <code>Grammar</code>.</p>
	*/
	Object start;


	/**
	* <p>The <code>Production</code>s put into this <code>Grammar</code>. It is a mapping from a nonterminal to its <code>Production</code>s.</p>
	*/
	final Map productions;

	/**
	* <p>The terminals put into this <code>Grammar</code>. When empty, there is a need to discover terminals. It is computed only on demand created by {@link #grab(BufferedReader) <code>grab(source)</code>}.</p>
	*/
	private final HashSet terminals;

	/**
	* <p>The mapping from a nonterminal to its first set in this <code>Grammar</code>. When empty, there is a need to compute current first sets. It is computed only on demand created by {@link #first(Object) <code>first(nonterminal)</code>}.</p>
	*/
	private final Map firsts;

	/**
	* <p>The mapping from a nonterminal to its follow set in this <code>Grammar</code>. When empty, there is a need to compute current follow sets. It is computed only on demand created by {@link #follow(Object) <code>follow(nonterminal)</code>}.</p>
	*/
	private final Map follows;

	/**
	* <p>The first set computed by {@link #first(Object[],int) <code>first(phrase, start)</code>}.</p>
	*/
	private final Set first;

	/**
	* <p>Constructs an empty <code>Grammar</code>.</p>
	*/
	protected Grammar() {
		this.productions = new HashMap(500);
		this.terminals = new HashSet(500);
		this.firsts = new HashMap(500);
		this.follows = new HashMap(500);
		this.first = new Set(-200);
	}

	/**
	* <p>Constructs a <code>Grammar</code> that is a shallow copy of <code>grammar</code>. The fields of the new <code>Grammar</code> refer to the same objects as those in <code>grammar</code>.</p>
	*
	* @param grammar the <code>Grammar</code> to be copied.
	*/
	Grammar(Grammar grammar) {
		super(grammar);
		this.start = grammar.start;
		this.productions = grammar.productions;
		this.terminals = grammar.terminals;
		this.firsts = grammar.firsts;
		this.follows = grammar.follows;
		this.first = grammar.first;
	}


	/**
	* <p>This class implements a {@link Grammar.ParseTree <code>ParseTree</code>} constructed by interpreting a source stream.</p>
	*
	* @version 0.9
	* @author &copy; 1999-2000 <a href="http://www.csupomona.edu/~carich/">Craig A. Rich</a> &lt;<a href="mailto:carich@acm.org">carich@acm.org</a>&gt;
	*/
	protected static class ParseTree {

		/**
		* <p>The last string representation of a <code>ParseTree</code> returned.</p>
		*/
		private static StringBuffer tree;

		/**
		* <p>The symbol at the root of this <code>ParseTree</code>. <code>symbol</code> can be a nonterminal, a terminal or <code>Semantics</code>.</p>
		*/
		public Object symbol;

		/**
		* <p>The attribute at the root of this <code>ParseTree</code>. If <code>symbol</code> is a terminal, <code>attribute</code> is initially the source word <code>symbol</code> matches; otherwise, <code>attribute</code> is initially <code>null</code>. <code>attribute</code> may be modified when interpreting by evaluation of embedded <code>Semantics</code>.</p>
		*/
		public Object attribute;

		/**
		* <p>The subtrees of the root of this <code>ParseTree</code>. If <code>symbol</code> is a nonterminal, <code>phrase</code> is the array of subtrees produced by <code>symbol</code>; otherwise, <code>phrase</code> is <code>null</code>.</p>
		*/
		public ParseTree[] phrase;

		/**
		* <p>Constructs a <code>ParseTree</code> with a root and its subtrees.</p>
		*
		* @param symbol the symbol at the root.
		* @param phrase the array of subtrees produced by <code>symbol</code>.
		*/
		ParseTree(Object symbol, Object attribute, ParseTree[] phrase) {
			this.symbol = symbol;
			this.attribute = attribute;
			this.phrase = phrase;
		}


		/**
		* <p>Returns a string representation of this <code>ParseTree</code>. The symbols in the <code>ParseTree</code> are shown in outline form, with children below their parent indented two columns. Each symbol is followed by its attribute value, if it is not <code>null</code> and differs from the symbol.</p>
		*
		* @return the string representation of this <code>ParseTree</code>.
		*/
		public String toString() {
			StringBuffer tree = ParseTree.tree;
			if (tree == null) ParseTree.tree = tree = new StringBuffer(4000);
			else tree.setLength(0);
			toString(0);
			return tree.toString();
		}

		/**
		* <p>Returns a string representation of this <code>ParseTree</code>.</p>
		*
		* @return the string representation of this <code>ParseTree</code>.
		*/
		private void toString(int depth) {
			StringBuffer tree = ParseTree.tree;
			Object symbol = this.symbol;
			Object attribute = this.attribute;
			ParseTree[] phrase = this.phrase;
			if (symbol instanceof Semantics) return;
			for (int i = 0; i < depth; i++) tree.append("| ");
			tree.append(symbol);

			if (attribute != null && !symbol.equals(attribute)) {
				tree.append(' ');
				tree.append(attribute);
			}
			tree.append('\n');

			if (phrase != null) {
				int phrase_length = phrase.length;
				for (int i = 0; i < phrase_length; i++) phrase[i].toString(depth + 1);
			}
		}
	}


	/**
	* <p>This class implements {@link Grammar.Semantics <code>Semantics</code>} embedded in productions and evaluated when interpreting.</p>
	*
	* @version 0.9
	* @author &copy; 1999-2000 <a href="http://www.csupomona.edu/~carich/">Craig A. Rich</a> &lt;<a href="mailto:carich@acm.org">carich@acm.org</a>&gt;
	*/
	protected static class Semantics {

		/**
		* <p>Constructs <code>Semantics</code>.</p>
		*/
		protected Semantics() {}

		/**
		* <p>Evaluates attributes in a <code>ParseTree</code> when interpreting. <code>evaluate</code> is invoked when a production containing this <code>Semantics</code> is applied to the <code>ParseTree</code>. <code>tree</code> provides the context in which attribute evaluation occurs. <code>tree.symbol</code> and <code>tree.phrase</code> are the left- and right-hand side of the production in which this <code>Semantics</code> is embedded.</p>
		* <p>During top-down {@link LL1_Grammar LL(1)} parsing, the <code>ParseTree</code> is constructed from the top down by leftmost derivation. This is a depth-first left-to-right traversal, in which embedded <code>Semantics</code> are evaluated when first visited. Evaluation should not depend on attributes produced by <code>Semantics</code> below or to the right of this <code>Semantics</code>. In other words, LL parsing supports evaluation of L-attributed semantic specifications.</p>
		* <p>During bottom-up {@link LR0_Grammar LR(0)}, {@link SLR1_Grammar SLR(1)} or {@link LR1_Grammar LR(1)} parsing, the <code>ParseTree</code> is constructed from the bottom up by reverse rightmost derivation. Embedded <code>Semantics</code> are evaluated after all subtrees rooted in the phrase to be reduced have been visited.</p>
		*
		* @param tree the <code>ParseTree</code> in which attribute evaluation occurs.
		*/
		//protected void evaluate(ParseTree tree) throws Exception {};
		protected void evaluate(ParseTree tree) throws Exception {};

	}


	/**
	* <p>This class implements a {@link Grammar.Production <code>Production</code>}.</p>
	*
	* @version 0.9
	* @author &copy; 1999-2000 <a href="http://www.csupomona.edu/~carich/">Craig A. Rich</a> &lt;<a href="mailto:carich@acm.org">carich@acm.org</a>&gt;
	*/
	static class Production {

		/**
		* <p>The nonterminal on the left-hand side of this <code>Production</code>.</p>
		*/
		final Object nonterminal;

		/**
		* <p>The phrase on the right-hand side of this <code>Production</code>.</p>
		*/
		final Object[] phrase;

		/**
		* <p>The number of this <code>Production</code>. It is the priority of this <code>Production</code> when resolving parse conflicts.</p>
		*/
		final int number;

		/**
		* <p>Constructs a <code>Production</code> with a nonterminal and phrase.</p>
		*
		* @param nonterminal the nonterminal on the left-hand side.
		* @param phrase the phrase on the right-hand side.
		*/
		Production(Object nonterminal, Object[] phrase) {
			this.nonterminal = nonterminal;
			this.phrase = phrase;
			this.number = ++Grammar.size;
		}


		/**
		* <p>Returns a string representation of this <code>Production</code>.</p>
		*
		* @return the string representation of this <code>Production</code>.
		*/
		public String toString() {
			StringBuffer result = new StringBuffer(80);
			result.append(this.nonterminal);
			result.append(" ->");
			Object[] phrase = this.phrase;
			int phrase_length = phrase.length;

			for (int i = 0; i < phrase_length; i++) {
				Object symbol = phrase[i];
				result.append(' ');
				if (symbol instanceof Semantics) result.append('@');
				else result.append(symbol);
			}
			return result.toString();
		}
	}


	/**
	* <p>Interprets a source character stream using this <code>Grammar</code>.</p>
	*
	* @param source the source character stream.
	* @return the <code>ParseTree</code> constructed by interpreting <code>source</code>.
	* @throws Lexicon.Exception if an I/O, lexical, syntax or semantic error occurs.
	*/
	public ParseTree interpret(Reader source) throws Exception {
		return interpret(new LineNumberReader(source));
	}

	/**
	* <p>Interprets a source file using this <code>Grammar</code>.</p>
	*
	* @param source the source file.
	* @return the <code>ParseTree</code> constructed by interpreting <code>source</code>.
	* @throws FileNotFoundException if the source file cannot be found.
	* @throws Lexicon.Exception if an I/O, lexical, syntax or semantic error occurs.
	*/
	public ParseTree interpret(File source) throws FileNotFoundException, Exception {
		return interpret(new FileReader(source));
	}

	/**
	* <p>Interprets a source byte stream using this <code>Grammar</code>.</p>
	*
	* @param source the source byte stream.
	* @return the <code>ParseTree</code> constructed by interpreting <code>source</code>.
	* @throws Lexicon.Exception if an I/O, lexical, syntax or semantic error occurs.
	*/
	public ParseTree interpret(InputStream source) throws Exception {
		return interpret(new InputStreamReader(source));
	}


	/**
	* <p>Interprets a source pipe using this <code>Grammar</code>.</p>
	*
	* @param source the source pipe.
	* @return the <code>ParseTree</code> constructed by interpreting <code>source</code>.
	* @throws IOException if the source pipe cannot be connected.
	* @throws Lexicon.Exception if an I/O, lexical, syntax or semantic error occurs.
	*/
	public ParseTree interpret(PipedWriter source) throws IOException, Exception {
		return interpret(new PipedReader(source));
	}

	/**
	* <p>Interprets a source string using this <code>Grammar</code>.</p>
	*
	* @param source the source string.
	* @return the <code>ParseTree</code> constructed by interpreting <code>source</code>.
	* @throws Lexicon.Exception if an I/O, lexical, syntax or semantic error occurs.
	*/
	public ParseTree interpret(String source) throws Exception {
		return interpret(new StringReader(source));
	}

	/**
	* <p>Interprets the standard input stream using this <code>Grammar</code>.</p>
	*
	* @return the <code>ParseTree</code> constructed by interpreting the standard input stream.
	* @throws Lexicon.Exception if an I/O, lexical, syntax or semantic error occurs.
	*/
	public ParseTree interpret() throws Exception {
		return interpret(System.in);
	}


	/**
	* <p>Interprets by command-line arguments using this <code>Grammar</code>. When interpreting, the parser used will be (in order):
	* <blockquote><ul>
	*	<li> The parser most recently constructed by preceding command-line arguments.
	*	<li> The parser originally around this <code>Grammar</code>.
	*	<li> An LR(1) parser.
	* </ul></blockquote>
	* The first I/O, lexical, syntax or semantic error that occurs when interpreting is printed to the standard error stream. If requested, each <code>ParseTree</code> is printed to the standard error stream after interpreting.</p>
	*
	* @param argv the command-line arguments controlling the interpreter.
	* <blockquote>
	* The following arguments may appear zero or more times, are processed in order, and have the following effects:
	* <blockquote><dl>
	*	<dt><code>-tree</code></dt>
	*	<dd>Print each <code>ParseTree</code> subsequently constructed by interpreting a source stream.</dd>
	* 	<dt><code>-ll1</code></dt>
	* 	<dd>Construct an {@link LL1_Grammar LL(1) parser} around this <code>Grammar</code>.</dd>
	* 	<dt><code>-lr0</code></dt>
	* 	<dd>Construct an {@link LR0_Grammar LR(0) parser} around this <code>Grammar</code>.</dd>
	* 	<dt><code>-slr1</code></dt>
	* 	<dd>Construct an {@link SLR1_Grammar SLR(1) parser} around this <code>Grammar</code>.</dd>
	* 	<dt><code>-lr1</code></dt>
	* 	<dd>Construct an {@link LR1_Grammar LR(1) parser} around this <code>Grammar</code>.</dd>
	*	<dt><code>-</code></dt>
	*	<dd>Interpret the standard input stream using this <code>Grammar</code>.</dd>
	* 	<dt><code><var>filename</var></code></dt>
	* 	<dd>Interpret source file <code><var>filename</var></code> using this <code>Grammar</code>.</dd>
	* </dl></blockquote>
	* If no <code><var>filename</var></code> arguments are given, the standard input stream is interpreted.
	* </blockquote>
	* @return the last <code>ParseTree</code> constructed by interpreting a source stream.
	*/
	public ParseTree interpret(String[] argv) {
		Grammar grammar = this;
		ParseTree tree = null;
		boolean printTrees = false;
		boolean sourceSpecified = false;


		for (int i = 0; i < argv.length; i++) {
			String argument = argv[i];
			if (argument.equalsIgnoreCase("-tree")) printTrees = true;
			else if (argument.equalsIgnoreCase("-ll1")) grammar = new LL1_Grammar(this);
			else if (argument.equalsIgnoreCase("-lr0")) grammar = new LR0_Grammar(this);
			else if (argument.equalsIgnoreCase("-slr1")) grammar = new SLR1_Grammar(this);
			else if (argument.equalsIgnoreCase("-lr1")) grammar = new LR1_Grammar(this);
			else try {
				sourceSpecified = true;
				if (argument.equals("-")) tree = grammar.interpret();
				else tree = grammar.interpret(new FileReader(new File(argument)));
				if (printTrees) System.err.println(tree);
			}
			catch (FileNotFoundException exception) {
				System.err.println(exception.getMessage());
			}
			catch (Exception exception) {
				System.err.println(exception.getMessage());
			}
		}
		if (!sourceSpecified) try {
			tree = grammar.interpret();
			if (printTrees) System.err.println(tree);
		}
		catch (Exception exception) {
			System.err.println(exception.getMessage());
		}
		return tree;
	}


	/**
	* <p>Grabs terminals from a source character stream using this <code>Grammar</code>. Invokes {@link Lexicon#grab(BufferedReader) <code>Lexicon.grab(source)</code>} until it returns a terminal occurring in a phrase of this <code>Grammar</code> or end of source. Blocks until a character is available, an I/O error occurs, or the end of the source stream is reached.</p>
	*
	* @param source the source character stream.
	* @return the first terminal occurring in a phrase of this <code>Grammar</code>.
	* @throws Lexicon.Exception if an I/O or lexical error occurs.
	*/
	public Object grab(BufferedReader source) throws Exception {
		HashSet terminals = this.terminals;

		if (terminals.isEmpty()) {
			terminals.add(END_OF_SOURCE);

			for (Iterator i = this.productions.entrySet().iterator(); i.hasNext();) {
				Map.Entry entry = (Map.Entry)i.next();
				Object nonterminal = entry.getKey();
				Set productions = (Set)entry.getValue();
				int productions_size = productions.size;
				Object[] productions_elements = productions.elements;

				for (int j = 0; j < productions_size; j++) {
					Object[] phrase = ((Production)productions_elements[j]).phrase;
					int phrase_length = phrase.length;

					for (int k = 0; k < phrase_length; k++) {
						Object symbol = phrase[k];
						if (symbol instanceof Semantics || nonterminal(symbol)) continue;

						if (symbol instanceof String && !super.terminal(symbol)) put(symbol, new Singleton((String)symbol));
						terminals.add(symbol);
					}
				}
			}
		}
		while (true) {
			Object lookahead = super.grab(source);
			if (terminal(lookahead)) return lookahead;
		}
	}


	/**
	* <p>Puts a production into this <code>Grammar</code>. The start symbol is the first nonterminal put in this <code>Grammar</code>.</p>
	*
	* @param nonterminal the nonterminal to be added to this <code>Grammar</code>.
	* @param phrase the phrase produced by <code>nonterminal</code>. <code>phrase</code> may contain nonterminals, terminals, and <code>Semantics</code>.
	*/
	protected void put(Object nonterminal, Object[] phrase) {
		if (this.start == null) this.start = nonterminal;
		Map productions = this.productions;
		Set nonterminal_productions = (Set)productions.get(nonterminal);
		if (nonterminal_productions == null) productions.put(nonterminal, nonterminal_productions = new Set(20));
		nonterminal_productions.append(new Production(nonterminal, phrase));
		this.terminals.clear();
		this.firsts.clear();
		this.follows.clear();
	}

	/**
	* <p>Puts productions into this <code>Grammar</code>. The productions are successively added using {@link #put(Object, Object[]) <code>put(nonterminal, phrase)</code>}.</p>
	*
	* @param nonterminal the nonterminal on the left-hand side of the production.
	* @param phrases the phrases produced by <code>nonterminal</code>. Each phrase in <code>phrases</code> may contain nonterminals, terminals, and {@link Grammar.Semantics <code>Semantics</code>}.
	*/
	protected void put(Object nonterminal, Object[][] phrases) {
		int phrases_length = phrases.length;
		for (int i = 0; i < phrases_length; i++) put(nonterminal, phrases[i]);
	}


	/**
	* <p>Interprets a source character stream using an {@link LR1_Grammar LR(1) parser} around this <code>Grammar</code>. This method is overridden by all parsers, so it is only invoked when this <code>Grammar</code> has not been extended by a parser.</p>
	*
	* @param source the source character stream.
	* @return the <code>ParseTree</code> constructed by interpreting <code>source</code>.
	* @throws Lexicon.Exception if an I/O, lexical, syntax or semantic error occurs.
	*/
	ParseTree interpret(LineNumberReader source) throws Exception {
		return new LR1_Grammar(this).interpret(source);
	}

	/**
	* <p>Indicates whether a symbol is a nonterminal in this <code>Grammar</code>.</p>
	*
	* @param symbol the symbol whose status is requested.
	* @return <code>true</code> if <code>symbol</code> is a nonterminal in this <code>Grammar</code>; <code>false</code> otherwise.
	*/
	boolean nonterminal(Object symbol) {
		return this.productions.containsKey(symbol);
	}

	/**
	* <p>Indicates whether a symbol is a terminal in this <code>Grammar</code>.</p>
	*
	* @param symbol the symbol whose status is requested.
	* @return <code>true</code> if <code>symbol</code> is a terminal in this <code>Grammar</code>; <code>false</code> otherwise.
	*/
	boolean terminal(Object symbol) {
		return this.terminals.contains(symbol);
	}


	/**
	* <p>Computes the first set of a phrase.</p>
	*
	* @param phrase the phrase whose first set is computed.
	* @param start the index at which to start computing the first set.
	* @return the first set of <code>phrase</code>.
	*/
	Set first(Object[] phrase, int start) {
		Set first = this.first;
		first.size = 0;
		int phrase_length = phrase.length;

		for (int k = start; k < phrase_length; k++) {
			Object symbol = phrase[k];
			if (symbol instanceof Semantics) continue;

			if (terminal(symbol)) {
				first.add(symbol);
				return first;
			}
			else {
				Set contribution = first(symbol);
				first.add(contribution, 0);
				if (!contribution.contains(null)) return first;
			}
		}
		first.append(null);
		return first;
	}


	/**
	* <p>Returns the first set of a nonterminal.</p>
	*
	* @param nonterminal the nonterminal whose first set is requested.
	* @return <code>{@link #firsts}.get(nonterminal)</code>, computing {@link #firsts} if there is a need to compute current first sets.
	*/
	Set first(Object nonterminal) {
		Map productions = this.productions;
		Map firsts = this.firsts;

		if (firsts.isEmpty()) {
			for (Iterator i = productions.keySet().iterator(); i.hasNext();) firsts.put(i.next(), new Set(50));

			while (true) {
				boolean closed = true;

				for (Iterator i = productions.entrySet().iterator(); i.hasNext();) {
					Map.Entry entry = (Map.Entry)i.next();
					Object lhs = entry.getKey();
					Set lhs_productions = (Set)entry.getValue();
					Set lhs_first = (Set)firsts.get(lhs);
					int lhs_productions_size = lhs_productions.size;
					Object[] lhs_productions_elements = lhs_productions.elements;

					for (int j = 0; j < lhs_productions_size; j++) {
						Object[] phrase = ((Production)lhs_productions_elements[j]).phrase;
						if (lhs_first.add(first(phrase, 0), 0)) closed = false;
					}
				}
				if (closed) break;
			}
		}
		return (Set)firsts.get(nonterminal);
	}


	/**
	* <p>Returns the follow set of a nonterminal.</p>
	*
	* @param nonterminal the nonterminal whose follow set is requested.
	* @return <code>{@link #follows}.get(nonterminal)</code>, computing {@link #follows} if there is a need to compute current follow sets.
	*/
	Set follow(Object nonterminal) {
		Map productions = this.productions;
		Map follows = this.follows;

		if (follows.isEmpty()) {
			for (Iterator i = productions.keySet().iterator(); i.hasNext();) follows.put(i.next(), new Set(-50));
			if (start != null) ((Set)follows.get(start)).add(END_OF_SOURCE);

			while (true) {
				boolean closed = true;

				for (Iterator i = productions.entrySet().iterator(); i.hasNext();) {
					Map.Entry entry = (Map.Entry)i.next();
					Object lhs = entry.getKey();
					Set lhs_productions = (Set)entry.getValue();
					int lhs_productions_size = lhs_productions.size;
					Object[] lhs_productions_elements = lhs_productions.elements;

					for (int j = 0; j < lhs_productions_size; j++) {
						Object[] phrase = ((Production)lhs_productions_elements[j]).phrase;
						int phrase_length = phrase.length;

						for (int k = 0; k < phrase_length; k++) {
							Object symbol = phrase[k];
							Set follow = (Set)follows.get(symbol);
							if (follow == null) continue;

							Set first = first(phrase, k + 1);
							if (follow.add(first, 0)) closed = false;
							if (first.contains(null) && follow.add((Set)follows.get(lhs), 0)) closed = false;
						}
					}
				}
				if (closed) break;
			}
		}
		return (Set)follows.get(nonterminal);
	}
}

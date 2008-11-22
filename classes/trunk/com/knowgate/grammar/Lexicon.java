
package com.knowgate.grammar;

import java.lang.Character;
import java.io.*;
import java.util.*;

/**
* <p>This class implements a {@link Lexicon}.</p>
*
* @version 0.9
* @author &copy; 1999-2000 <a href="http://www.csupomona.edu/~carich/">Craig A. Rich</a> &lt;<a href="mailto:carich@acm.org">carich@acm.org</a>&gt;
* @see <a href="../../../src/gi/Lexicon.java">Source code</a>
*/
public class Lexicon {

	/**
	* <p>The terminal matching the character at the end of a source stream.</p>
	*/
	protected static final String END_OF_SOURCE = new String("END_OF_SOURCE");

	/**
	* <p>The number of NFA states in the lexical NFA.</p>
	*/
	private static int size = 0;

	/**
	* <p>The transition function of the lexical NFA.</p>
	*/
	private static final Set transitions = new Set(2000);

	/**
	* <p>The <code>Expression</code> denoting the set containing the character at the end of a source stream.</p>
	*/
	private static final Expression END_OF_SOURCE_EXPRESSION = new Match((char)-1);


	/**
	* <p>The terminals put into this <code>Lexicon</code>. It is a mapping from a terminal to the NFA initial state recognizing the language denoted by the associated <code>Expression</code>.</p>
	*/
	private final Map terminals;

	/**
	* <p>The initial state of this <code>Lexicon</code>. When empty, there is a need to compute the current initial state. It is computed only on demand created by {@link #initial()}.</p>
	*/
	private final Set initial;

	/**
	* <p>The states through which this <code>Lexicon</code> transitions.</p>
	*/
	private final Set[] states;

	/**
	* <p>The mapping from an NFA accept state to the terminal it recognizes in this <code>Lexicon</code>. When empty, there is a need to compute current NFA accept states. It is computed only on demand created by {@link #initial()}.</p>
	*/
	private final Map accepts;

	/**
	* <p>The <code>StringBuffer</code> containing the word most recently grabbed.</p>
	*/
	private final StringBuffer word;

	/**
	* <p>Constructs an empty <code>Lexicon</code>.</p>
	*/
	protected Lexicon() {
		this.terminals = new HashMap(500);
		this.initial = new Set(200);
		this.states = new Set[]{new Set(200), new Set(200)};
		this.accepts = new HashMap(500);
		this.word = new StringBuffer(4000);
		put(END_OF_SOURCE, END_OF_SOURCE_EXPRESSION);
	}

	/**
	* <p>Constructs a <code>Lexicon</code> that is a shallow copy of <code>lexicon</code>. The fields of the new <code>Lexicon</code> refer to the same objects as those in <code>lexicon</code>.</p>
	*
	* @param lexicon the <code>Lexicon</code> to be copied.
	*/
	Lexicon(Lexicon lexicon) {
		this.terminals = lexicon.terminals;
		this.initial = lexicon.initial;
		this.states = lexicon.states;
		this.accepts = lexicon.accepts;
		this.word = lexicon.word;
	}


	/**
	* <p>This class implements an {@link Lexicon.Expression <code>Expression</code>} denoting a regular language.</p>
	*
	* @version 0.9
	* @author &copy; 1999-2000 <a href="http://www.csupomona.edu/~carich/">Craig A. Rich</a> &lt;<a href="mailto:carich@acm.org">carich@acm.org</a>&gt;
	*/
	abstract static class Expression {

		/**
		* <p>The initial state of the NFA recognizing the language denoted by this <code>Expression</code>.</p>
		*/
		Integer initial;

		/**
		* <p>The accept state of the NFA recognizing the language denoted by this <code>Expression</code>.</p>
		*/
		Integer accept;

		/**
		* <p>Creates a copy of this <code>Expression</code>. The NFA recognizing the language denoted by this <code>Expression</code> is replicated.</p>
		*
		* @return a copy of this <code>Expression</code>.
		*/
		abstract Expression copy();
	}


	/**
	* <p>This class implements an {@link Lexicon.Expression <code>Expression</code>} denoting a set of characters.</p>
	*
	* @version 0.9
	* @author &copy; 1999-2000 <a href="http://www.csupomona.edu/~carich/">Craig A. Rich</a> &lt;<a href="mailto:carich@acm.org">carich@acm.org</a>&gt;
	*/
	abstract static class Alphabet extends Expression {

		/**
		* <p>Indicates whether a character is in this <code>Alphabet</code>.</p>
		*
		* @param c the character whose status is requested.
		* @return <code>true</code> if <code>c</code> is in this <code>Alphabet</code>; <code>false</code> otherwise.
		*/
		abstract boolean contains(char c);
	}


	/**
	* <p>This class implements an {@link Lexicon.Expression <code>Expression</code>} denoting the union of two regular languages.</p>
	*
	* @version 0.9
	* @author &copy; 1999-2000 <a href="http://www.csupomona.edu/~carich/">Craig A. Rich</a> &lt;<a href="mailto:carich@acm.org">carich@acm.org</a>&gt;
	*/
	protected static class Union extends Expression {

		/**
		* <p>The <code>Expression</code> denoting the left language.</p>
		*/
		private final Expression left;

		/**
		* <p>The <code>Expression</code> denoting the right language.</p>
		*/
		private final Expression right;

		/**
		* <p>Constructs an <code>Expression</code> denoting the union of two regular languages. An NFA recognizing the language denoted by this <code>Expression</code> is constructed.</p>
		*
		* @param left the <code>Expression</code> denoting the left language.
		* @param right the <code>Expression</code> denoting the right language.
		*/
		public Union(Expression left, Expression right) {
			this.left = left;
			this.right = right;
			Integer initial = state();
			Integer accept = state();
			put(initial, null, left.initial);
			put(initial, null, right.initial);
			put(left.accept, null, accept);
			put(right.accept, null, accept);
			this.initial = initial;
			this.accept = accept;
		}

		/**
		* <p>Creates a copy of this <code>Expression</code>. The NFA recognizing the language denoted by this <code>Expression</code> is replicated.</p>
		*
		* @return a copy of this <code>Expression</code>.
		*/
		Expression copy() {
			return new Union(this.left, this.right);
		}
	}


	/**
	* <p>This class implements an {@link Lexicon.Expression <code>Expression</code>} denoting the concatenation of two regular languages.</p>
	*
	* @version 0.9
	* @author &copy; 1999-2000 <a href="http://www.csupomona.edu/~carich/">Craig A. Rich</a> &lt;<a href="mailto:carich@acm.org">carich@acm.org</a>&gt;
	*/
	protected static class Concatenation extends Expression {

		/**
		* <p>The <code>Expression</code> denoting the left language.</p>
		*/
		private final Expression left;

		/**
		* <p>The <code>Expression</code> denoting the right language.</p>
		*/
		private final Expression right;

		/**
		* <p>Constructs an <code>Expression</code> denoting the concatenation of two regular languages. An NFA recognizing the language denoted by this <code>Expression</code> is constructed.</p>
		*
		* @param left the <code>Expression</code> denoting the left language.
		* @param right the <code>Expression</code> denoting the right language.
		*/
		public Concatenation(Expression left, Expression right) {
			this.left = left;
			this.right = right;
			put(left.accept, null, right.initial);
			this.initial = left.initial;
			this.accept = right.accept;
		}

		/**
		* <p>Creates a copy of this <code>Expression</code>. The NFA recognizing the language denoted by this <code>Expression</code> is replicated.</p>
		*
		* @return a copy of this <code>Expression</code>.
		*/
		Expression copy() {
			return new Concatenation(this.left, this.right);
		}
	}


	/**
	* <p>This class implements an {@link Lexicon.Expression <code>Expression</code>} denoting the repetition of a regular language.</p>
	*
	* @version 0.9
	* @author &copy; 1999-2000 <a href="http://www.csupomona.edu/~carich/">Craig A. Rich</a> &lt;<a href="mailto:carich@acm.org">carich@acm.org</a>&gt;
	*/
	protected static class Repetition extends Expression {

		/**
		* <p>The <code>Expression</code> denoting the language whose repetition is expressed.</p>
		*/
		private final Expression kernel;

		/**
		* <p>The minimum number of times <code>kernel</code> is repeated.</p>
		*/
		private final int min;

		/**
		* <p>The maximum number of times <code>kernel</code> is repeated.</p>
		*/
		private final int max;


		/**
		* <p>Constructs an <code>Expression</code> denoting the repetition of a regular language. An NFA recognizing the language denoted by this <code>Expression</code> is constructed. Large finite values for the minimum or maximum cause the kernel NFA to be cloned many times, resulting in a space-inefficient NFA.</p>
		*
		* @param kernel the <code>Expression</code> denoting the language whose repetition is expressed.
		* @param min the minimum number of times <code>kernel</code> is repeated. If negative, it is assumed to be zero.
		* @param max the maximum number of times <code>kernel</code> is repeated. If negative, it is assumed to be infinity.
		*/
		public Repetition(Expression kernel, int min, int max) {
			this.kernel = kernel;
			this.min = min = Math.max(min, 0);
			this.max = max;
			Integer initial = (min == 0) ? state() : kernel.initial;
			Integer accept = (min == 0) ? initial : kernel.accept;
			this.initial = initial;

			if (min == 0 && max < 0) {
				put(initial, null, kernel.initial);
				put(kernel.accept, null, initial);
			}
			else {

				for (int i = 2; i <= min; i++) {
					Expression copy = kernel.copy();
					put(accept, null, initial = copy.initial);
					accept = copy.accept;
				}
				if (max > min) {
					Integer tail = accept;
					put(tail, null, accept = state());

					for (int i = min + 1; i <= max; i++) {
						Expression copy = (i == 1) ? kernel : kernel.copy();
						put(tail, null, initial = copy.initial);
						put(tail = copy.accept, null, accept);
					}
				}
				else if (max < 0) put(accept, null, initial);
			}
			this.accept = accept;
		}

		/**
		* <p>Creates a copy of this <code>Expression</code>. The NFA recognizing the language denoted by this <code>Expression</code> is replicated.</p>
		*
		* @return a copy of this <code>Expression</code>.
		*/
		Expression copy() {
			return new Repetition(this.kernel, this.min, this.max);
		}
	}


	/**
	* <p>This class implements an {@link Lexicon.Expression <code>Expression</code>} denoting the set containing a string.</p>
	*
	* @version 0.9
	* @author &copy; 1999-2000 <a href="http://www.csupomona.edu/~carich/">Craig A. Rich</a> &lt;<a href="mailto:carich@acm.org">carich@acm.org</a>&gt;
	*/
	protected static class Singleton extends Expression {

		/**
		* <p>The string whose singleton set is denoted.</p>
		*/
		private final String string;

		/**
		* <p>Constructs an <code>Expression</code> denoting the set containing a string. An NFA recognizing the language denoted by this <code>Expression</code> is constructed.</p>
		*
		* @param string the string whose singleton set is denoted.
		*/
		public Singleton(String string) {
			this.string = string;
			Integer initial = state();
			Integer accept = initial;
			this.initial = initial;
			int string_length = string.length();
			for (int i = 0; i < string_length; i++) new Match(accept, string.charAt(i), accept = state());
			this.accept = accept;
		}

		/**
		* <p>Creates a copy of this <code>Expression</code>. The NFA recognizing the language denoted by this <code>Expression</code> is replicated.</p>
		*
		* @return a copy of this <code>Expression</code>.
		*/
		Expression copy() {
			return new Singleton(this.string);
		}
	}


	/**
	* <p>This class implements an {@link Lexicon.Expression <code>Expression</code>} denoting the set of characters in a string.</p>
	*
	* @version 0.9
	* @author &copy; 1999-2000 <a href="http://www.csupomona.edu/~carich/">Craig A. Rich</a> &lt;<a href="mailto:carich@acm.org">carich@acm.org</a>&gt;
	*/
	protected static class Match extends Alphabet {

		/**
		* <p>The string whose set of characters is denoted.</p>
		*/
		String string;

		/**
		* <p>The character whose singleton set is denoted.</p>
		*/
		char c;

		/**
		* <p>The <code>Alphabet</code> list whose set is denoted.</p>
		*/
		Set list;


		/**
		* <p>Constructs an <code>Expression</code> denoting the set of characters in a string. An NFA recognizing the language denoted by this <code>Expression</code> is constructed.</p>
		*
		* @param string the string of characters whose set is denoted.
		*/
		public Match(String string) {
			this.string = string;
			put(this.initial = state(), this, this.accept = state());
		}

		/**
		* <p>Constructs an <code>Expression</code> denoting the set containing a character. An NFA recognizing the language denoted by this <code>Expression</code> is constructed.</p>
		*
		* @param c the character whose singleton set is denoted.
		*/
		public Match(char c) {
			this.c = c;
			put(this.initial = state(), this, this.accept = state());
		}

		/**
		* <p>Constructs an <code>Expression</code> denoting the set containing a character. An NFA recognizing the language denoted by this <code>Expression</code> is constructed.</p>
		*
		* @param c the character whose singleton set is denoted.
		*/
		Match(Integer from, char c, Integer to) {
			this.c = c;
			put(this.initial = from, this, this.accept = to);
		}

		/**
		* <p>Constructs an <code>Expression</code> denoting the set of characters in an <code>Alphabet</code> list. An NFA recognizing the language denoted by this <code>Expression</code> is constructed.</p>
		*
		* @param list the <code>Alphabet</code> list whose set is denoted.
		*/
		Match(Set list) {
			this.list = list;
			put(this.initial = state(), this, this.accept = state());
		}


		/**
		* <p>Indicates whether a character is in the set denoted by this <code>Expression</code>.</p>
		*
		* @param c the character whose status is requested.
		* @return <code>true</code> if <code>c</code> is in the set denoted by this <code>Expression</code>; <code>false</code> otherwise.
		*/
		boolean contains(char c) {
			String string = this.string;
			if (string != null) return string.indexOf(c) != -1;
			Set list = this.list;

			if (list != null) {
				int list_size = list.size;
				for (int i = 0; i < list_size; i++) if (((Alphabet)list.elements[i]).contains(c)) return true;
				return false;
			}
			return this.c == c;
		}

		/**
		* <p>Creates a copy of this <code>Expression</code>. The NFA recognizing the language denoted by this <code>Expression</code> is replicated.</p>
		*
		* @return a copy of this <code>Expression</code>.
		*/
		Expression copy() {
			String string = this.string;
			if (string != null) return new Match(string);
			Set list = this.list;
			if (list != null) return new Match(list);
			return new Match(this.c);
		}
	}


	/**
	* <p>This class implements an {@link Lexicon.Expression <code>Expression</code>} denoting the set of characters not in a string.</p>
	*
	* @version 0.9
	* @author &copy; 1999-2000 <a href="http://www.csupomona.edu/~carich/">Craig A. Rich</a> &lt;<a href="mailto:carich@acm.org">carich@acm.org</a>&gt;
	*/
	protected static class NonMatch extends Match {

		/**
		* <p>Constructs an <code>Expression</code> denoting the set of characters not in a string. An NFA recognizing the language denoted by this <code>Expression</code> is constructed.</p>
		*
		* @param string the string of characters whose complement is denoted.
		*/
		public NonMatch(String string) {
			super(string);
		}

		/**
		* <p>Constructs an <code>Expression</code> denoting the set of characters except one. An NFA recognizing the language denoted by this <code>Expression</code> is constructed.</p>
		*
		* @param c the character whose complement is denoted.
		*/
		public NonMatch(char c) {
			super(c);
		}

		/**
		* <p>Constructs an <code>Expression</code> denoting the set of characters not in an <code>Alphabet</code> list. An NFA recognizing the language denoted by this <code>Expression</code> is constructed.</p>
		*
		* @param list the <code>Alphabet</code> list whose complement is denoted.
		*/
		NonMatch(Set list) {
			super(list);
		}


		/**
		* <p>Indicates whether a character is in the set denoted by this <code>Expression</code>.</p>
		*
		* @param c the character whose status is requested.
		* @return <code>true</code> if <code>c</code> is in the set denoted by this <code>Expression</code>; <code>false</code> otherwise.
		*/
		boolean contains(char c) {
			return c != (char)-1 && !super.contains(c);
		}

		/**
		* <p>Creates a copy of this <code>Expression</code>. The NFA recognizing the language denoted by this <code>Expression</code> is replicated.</p>
		*
		* @return a copy of this <code>Expression</code>.
		*/
		Expression copy() {
			String string = this.string;
			if (string != null) return new NonMatch(string);
			Set list = this.list;
			if (list != null) return new NonMatch(list);
			return new NonMatch(this.c);
		}
	}


	/**
	* <p>This class implements an {@link Lexicon.Expression <code>Expression</code>} denoting the set of characters in a range.</p>
	*
	* @version 0.9
	* @author &copy; 1999-2000 <a href="http://www.csupomona.edu/~carich/">Craig A. Rich</a> &lt;<a href="mailto:carich@acm.org">carich@acm.org</a>&gt;
	*/
	protected static class Range extends Alphabet {

		/**
		* <p>The first character in the range.</p>
		*/
		private final char first;

		/**
		* <p>The last character in the range.</p>
		*/
		private final char last;

		/**
		* <p>Constructs an <code>Expression</code> denoting the set of characters in a range. An NFA recognizing the language denoted by this <code>Expression</code> is constructed.</p>
		*
		* @param first the first character in the range.
		* @param last the last character in the range.
		*/
		public Range(char first, char last) {
			this.first = first;
			this.last = last;
			put(this.initial = state(), this, this.accept = state());
		}


		/**
		* <p>Indicates whether a character is in the set denoted by this <code>Expression</code>.</p>
		*
		* @param c the character whose status is requested.
		* @return <code>true</code> if <code>c</code> is in this <code>Range</code>; <code>false</code> otherwise.
		*/
		boolean contains(char c) {
			return this.first <= c && c <= this.last;
		}

		/**
		* <p>Creates a copy of this <code>Expression</code>. The NFA recognizing the language denoted by this <code>Expression</code> is replicated.</p>
		*
		* @return a copy of this <code>Expression</code>.
		*/
		Expression copy() {
			return new Range(this.first, this.last);
		}
	}


	/**
	* <p>This class implements an {@link Lexicon.Expression <code>Expression</code>} denoting the set of characters in a POSIX class.</p>
	*
	* @version 0.9
	* @author &copy; 1999-2000 <a href="http://www.csupomona.edu/~carich/">Craig A. Rich</a> &lt;<a href="mailto:carich@acm.org">carich@acm.org</a>&gt;
	*/
	protected static class PosixClass extends Alphabet {

		/**
		* <p>The POSIX class whose set is denoted.</p>
		*/
		private final int posixclass;

		/**
		* <p>Constructs an <code>Expression</code> denoting the set of characters in a POSIX class. An NFA recognizing the language denoted by this <code>Expression</code> is constructed.</p>
		*
		* @param class the POSIX class whose set is denoted.
		*/
		private PosixClass(int posixclass) {
			this.posixclass = posixclass;
			put(this.initial = state(), this, this.accept = state());
		}


		/**
		* <p>Creates an <code>Expression</code> denoting the set of uppercase alphabetic characters.</p>
		*/
		public static Expression upper() {
			return new PosixClass(0x0001);
		}

		/**
		* <p>Creates an <code>Expression</code> denoting the set of lowercase alphabetic characters.</p>
		*/
		public static Expression lower() {
			return new PosixClass(0x0002);
		}

		/**
		* <p>Creates an <code>Expression</code> denoting the set of alphabetic characters.</p>
		*/
		public static Expression alpha() {
			return new PosixClass(0x0004);
		}

		/**
		* <p>Creates an <code>Expression</code> denoting the set of decimal digit characters.</p>
		*/
		public static Expression digit() {
			return new PosixClass(0x0008);
		}

		/**
		* <p>Creates an <code>Expression</code> denoting the set of hexadecimal digit characters.</p>
		*/
		public static Expression xdigit() {
			return new PosixClass(0x0010);
		}

		/**
		* <p>Creates an <code>Expression</code> denoting the set of alphanumeric characters.</p>
		*/
		public static Expression alnum() {
			return new PosixClass(0x0020);
		}


		/**
		* <p>Creates an <code>Expression</code> denoting the set of punctuation characters.</p>
		*/
		public static Expression punct() {
			return new PosixClass(0x0040);
		}

		/**
		* <p>Creates an <code>Expression</code> denoting the set of graphical characters.</p>
		*/
		public static Expression graph() {
			return new PosixClass(0x0080);
		}

		/**
		* <p>Creates an <code>Expression</code> denoting the set of printable characters.</p>
		*/
		public static Expression print() {
			return new PosixClass(0x0100);
		}

		/**
		* <p>Creates an <code>Expression</code> denoting the set of blank characters.</p>
		*/
		public static Expression blank() {
			return new PosixClass(0x0200);
		}

		/**
		* <p>Creates an <code>Expression</code> denoting the set of space characters.</p>
		*/
		public static Expression space() {
			return new PosixClass(0x0400);
		}

		/**
		* <p>Creates an <code>Expression</code> denoting the set of control characters.</p>
		*/
		public static Expression cntrl() {
			return new PosixClass(0x0001);
		}


		/**
		* <p>Indicates whether a character is in the set denoted by this <code>Expression</code>.</p>
		*
		* @param c the character whose status is requested.
		* @return <code>true</code> if <code>c</code> is in this <code>PosixClass</code>; <code>false</code> otherwise.
		*/
		boolean contains(char c) {
			int UPPER = 0x0001; int LOWER = 0x0002;
			int ALPHA = 0x0004; int DIGIT = 0x0008;
			int XDIGIT = 0x0010; int ALNUM = 0x0020;
			int PUNCT = 0x0040; int GRAPH = 0x0080;
			int PRINT = 0x0100; int BLANK = 0x0200;
			int SPACE = 0x0400; int CNTRL = 0x0800;
			int classes = 0;

			switch (Character.getType(c)) {
				default: break;
				case Character.UPPERCASE_LETTER:
					classes |= UPPER | ALPHA | (('a' <= c && c <= 'f') ? XDIGIT : 0) | ALNUM | GRAPH | PRINT; break;
				case Character.LOWERCASE_LETTER:
					classes |= LOWER | ALPHA | (('a' <= c && c <= 'f') ? XDIGIT : 0) | ALNUM | GRAPH | PRINT; break;
				case Character.TITLECASE_LETTER:
				case Character.MODIFIER_LETTER:
				case Character.OTHER_LETTER:
					classes |= ALPHA | ALNUM | GRAPH | PRINT; break;
				case Character.NON_SPACING_MARK:
				case Character.ENCLOSING_MARK:
				case Character.COMBINING_SPACING_MARK:
					classes |= PUNCT | GRAPH | PRINT; break;
				case Character.DECIMAL_DIGIT_NUMBER:
					classes |= DIGIT | XDIGIT | ALNUM | GRAPH | PRINT; break;
				case Character.LETTER_NUMBER:
				case Character.OTHER_NUMBER:
					classes |= ALNUM | GRAPH | PRINT; break;
				case Character.SPACE_SEPARATOR:
					classes |= PRINT | BLANK | SPACE; break;
				case Character.CONTROL:
					classes |= ((c == '\t') ? BLANK : 0) | ((c == '\t' || c == '\n' || c == '\013' || c == '\f' || c == '\r') ? SPACE : 0) | CNTRL; break;
				case Character.DASH_PUNCTUATION:
				case Character.START_PUNCTUATION:
				case Character.END_PUNCTUATION:
				case Character.CONNECTOR_PUNCTUATION:
				case Character.OTHER_PUNCTUATION:
				case Character.MATH_SYMBOL:
				case Character.CURRENCY_SYMBOL:
				case Character.MODIFIER_SYMBOL:
				case Character.OTHER_SYMBOL:
					classes |= PUNCT | GRAPH | PRINT; break;
			}
			return (classes & this.posixclass) != 0;
		}


		/**
		* <p>Creates a copy of this <code>Expression</code>. The NFA recognizing the language denoted by this <code>Expression</code> is replicated.</p>
		*
		* @return a copy of this <code>Expression</code>.
		*/
		Expression copy() {
			return new PosixClass(this.posixclass);
		}
	}


	/**
	* <p>This class implements an {@link Lexicon.Expression <code>Expression</code>} denoting the set of characters in a Unicode category.</p>
	*
	* @version 0.9
	* @author &copy; 1999-2000 <a href="http://www.csupomona.edu/~carich/">Craig A. Rich</a> &lt;<a href="mailto:carich@acm.org">carich@acm.org</a>&gt;
	*/
	protected static class UnicodeCategory extends Alphabet {

		/**
		* <p>The Unicode category whose set is denoted.</p>
		*/
		private final byte category;

		/**
		* <p>Constructs an <code>Expression</code> denoting the set of characters in a Unicode category. An NFA recognizing the language denoted by this <code>Expression</code> is constructed. The class {@link Character} defines byte constants for each of the Unicode category types.</p>
		*
		* @param category the Unicode category whose set is denoted.
		* @see Character
		*/
		public UnicodeCategory(byte category) {
			this.category = category;
			put(this.initial = state(), this, this.accept = state());
		}

		/**
		* <p>Indicates whether a character is in the set denoted by this <code>Expression</code>.</p>
		*
		* @param c the character whose status is requested.
		* @return <code>true</code> if <code>c</code> is in this <code>UnicodeCategory</code>; <code>false</code> otherwise.
		*/
		boolean contains(char c) {
			return Character.getType(c) == this.category;
		}

		/**
		* <p>Creates a copy of this <code>Expression</code>. The NFA recognizing the language denoted by this <code>Expression</code> is replicated.</p>
		*
		* @return a copy of this <code>Expression</code>.
		*/
		Expression copy() {
			return new UnicodeCategory(this.category);
		}
	}


	/**
	* <p>This class implements an {@link Lexicon.Exception <code>Exception</code>}.</p>
	*
	* @version 0.9
	* @author &copy; 1999-2000 <a href="http://www.csupomona.edu/~carich/">Craig A. Rich</a> &lt;<a href="mailto:carich@acm.org">carich@acm.org</a>&gt;
	*/
	protected class Exception extends java.lang.Exception {

		private static final long serialVersionUID = 1l;

		/**
		* <p>The extended error message.</p>
		*/
		private StringBuffer message;

		/**
		* <p>Constructs an <code>Exception</code> with a message.</p>
		*
		* @param message the error message.
		*/
		public Exception(String message) {
			super(message);
		}


		/**
		* <p>Returns the error message.</p>
		*/
		public String getMessage() {
			StringBuffer message = this.message;
			return (message == null) ? super.getMessage() : message.toString();
		}

		/**
		* <p>Extends the error message in this <code>Exception</code>. The extended message includes the line number, message and source characters following the error.</p>
		*
		* @param source the source character stream.
		* @return this <code>Exception</code> with an extended message.
		*/
		Exception extend(BufferedReader source) {
			StringBuffer message = this.message;
			if (message == null) this.message = message = new StringBuffer(132);
			else message.setLength(0);

			if (source instanceof LineNumberReader) {
				message.append("line ");
				message.append(((LineNumberReader)source).getLineNumber() + 1);
				message.append(": ");
			}
			message.append(super.getMessage());
			message.append("\n...");
			message.append(Lexicon.this.word());
			try {
				String rest = source.readLine();
				if (rest != null) message.append(rest);
			}
			catch (IOException exception) {}
			message.append("\n   ^");
			return this;
		}
	}


	/**
	* <p>This class implements a {@link Lexicon.Set <code>Set</code>}.</p>
	*
	* @version 0.9
	* @author &copy; 1999-2000 <a href="http://www.csupomona.edu/~carich/">Craig A. Rich</a> &lt;<a href="mailto:carich@acm.org">carich@acm.org</a>&gt;
	*/
	static class Set {

		/**
		* <p>The size of this <code>Set</code>.</p>
		*/
		int size;

		/**
		* <p>The elements in this <code>Set</code>.</p>
		*/
		Object[] elements;

		/**
		* <p>The null exclusion indicator. If <code>true</code>, <code>add</code> methods will not add <code>null</code> to this <code>Set</code>.</p>
		*/
		private final boolean exclude;

		/**
		* <p>Constructs a <code>Set</code> with an initial capacity.</p>
		*
		* @param capacity the initial capacity. The magnitude of <code>capacity</code> is the initial capacity. The null exclusion indicator is set to <code>true</code> if <code>capacity</code> is negative.
		*/
		Set(int capacity) {
			this.elements = new Object[Math.abs(capacity)];
			this.exclude = (capacity < 0);
		}

		/**
		* <p>Returns a string representation of this <code>Set</code>.</p>
		*/
		public String toString() {
			int size = this.size;
			Object[] elements = this.elements;
			StringBuffer result = new StringBuffer(80);
			result.append('[');
			if (size > 0) result.append(elements[0]);

			for (int i = 1; i < size; i++) {
				result.append(' ');
				result.append(elements[i]);
			}
			result.append(']');
			return result.toString();
		}


		/**
		* <p>Appends an element to this <code>Set</code>. The element is always appended, without regard for the null exclusion indicator or whether it occurs in this <code>Set</code>. The capacity is expanded by 50% if necessary.</p>
		*
		* @param object the element to be appended.
		* @return <code>true</code> since this <code>Set</code> is changed.
		*/
		boolean append(Object object) {
			int size = this.size;
			Object[] elements = this.elements;
			if (size == elements.length) System.arraycopy(elements, 0, this.elements = elements = new Object[3 * size / 2], 0, size);
			elements[this.size++] = object;
			return true;
		}

		/**
		* <p>Adds an element to this <code>Set</code>. The element is not added if it occurs in this <code>Set</code> or it is <code>null</code> and the null exclusion indicator is <code>true</code>. The capacity is expanded if necessary.</p>
		*
		* @param object the element to be added.
		* @return <code>true</code> if this <code>Set</code> is changed; <code>false</code> otherwise.
		*/
		boolean add(Object object) {
			if (object == null && this.exclude) return false;
			int size = this.size;
			Object[] elements = this.elements;
			for (int i = size; --i >= 0;) if (elements[i] == object) return false;
			return append(object);
		}

		/**
		* <p>Adds a <code>Set</code> of elements to this <code>Set</code>. An element is not added if it occurs in this <code>Set</code> or it is <code>null</code> and the null exclusion indicator is <code>true</code>. The capacity is expanded if necessary.</p>
		*
		* @param from the <code>Set</code> to be added.
		* @param start the index in <code>from</code> beyond which elements are added.
		* @return <code>true</code> if this <code>Set</code> is changed; <code>false</code> otherwise.
		*/
		boolean add(Set from, int start) {
			if (from == null) return false;
			boolean exclude = this.exclude;
			int from_size = from.size;
			Object[] from_elements = from.elements;
			boolean append = (this.size == 0);
			boolean changed = false;

			for (int i = start; i < from_size; i++) {
				Object element = from_elements[i];
				if (element == null && exclude) continue;

				if (append ? append(element) : add(element)) changed = true;
			}
			return changed;
		}


		/**
		* <p>Indicates if an element occurs in this <code>Set</code>.</p>
		*
		* @param object the element whose membership if requested.
		* @return <code>true</code> if <code>object</code> occurs in this <code>Set</code>; <code>false</code> otherwise.
		*/
		boolean contains(Object object) {
			int size = this.size;
			Object[] elements = this.elements;
			for (int i = size; --i >= 0;) if (elements[i] == object) return true;
			return false;
		}
	}


	/**
	* <p>Grabs a terminal from a source character stream using this <code>Lexicon</code>. The variable returned by {@link #word()} is set to the longest nonempty prefix of the remaining source characters matching an <code>Expression</code> in this <code>Lexicon</code>. If no nonempty prefix matches an <code>Expression</code>, a <code>Lexicon.Exception</code> is thrown. If the longest matching prefix matches more than one <code>Expression</code>, the terminal associated with the <code>Expression</code> most recently constructed is returned. Blocks until a character is available, an I/O error occurs, or the end of the source stream is reached.</p>
	*
	* @param source the source character stream.
	* @return the terminal grabbed from <code>source</code>.
	* @throws Lexicon.Exception if an I/O or lexical error occurs.
	*/
	public Object grab(BufferedReader source) throws Exception {
		Object lookahead = null;
		Set from = initial();
		Set[] to = this.states;
		StringBuffer word = this.word;
		word.setLength(0);
		int length = 0;
		try {
			source.mark(word.capacity());
			do {
				int c = source.read();
				from = closure(transition(from, (char)c, to[word.length() % 2]));
				if (from.size == 0) break;
				if (c != -1) word.append((char)c);
				else word.append(END_OF_SOURCE);
				Object recognize = recognize(from);

				if (recognize != null) {
					lookahead = recognize;
					length = word.length();
					source.mark(word.capacity());
				}
			} while (lookahead != END_OF_SOURCE);
			word.setLength(length);
			source.reset();
		}
		catch (IOException exception) {
			throw new Exception(exception.getMessage());
		}
		if (lookahead == null) throw new Exception("lexical error").extend(source);
		return lookahead;
	}

	/**
	* <p>Returns the word most recently grabbed using this <code>Lexicon</code>.</p>
	*
	* @return the word most recently grabbed by {@link #grab(java.io.BufferedReader) <code>grab(source)</code>}.
	*/
	public String word() {
		return this.word.substring(0);
	}


	/**
	* <p>Creates an <code>Expression</code> by interpreting a POSIX extended regular expression (ERE), as used in egrep. The syntax and semantics for EREs is formally specified by the <a href="../../../src/gi/ERE.java">ERE <code>Grammar</code></a>. Provides a convenient method for constructing an <code>Expression</code>, at the cost of an LR(1) parse. Implementations seeking maximum speed should avoid this method and use explicit <code>Expression</code> subclass constructors; for example,</p>
	* <blockquote><code>new Union(new NonMatch("0"), new Singleton("foo"))</code></blockquote>
	* instead of
	* <blockquote><code>Lexicon.expression("[^0]|foo")</code></blockquote>
	*
	* @param string the POSIX extended regular expression (ERE) to be interpreted.
	* @return the <code>Expression</code> constructed by interpreting <code>string</code>.
	* @throws Lexicon.Exception if a syntax error occurs.
	*/
	protected static Expression expression(String string) throws Exception {
		return ERE.parse(string);
	}

	/**
	* <p>Puts a terminal and associated <code>Expression</code> into this <code>Lexicon</code>. The <code>Expression</code> supersedes any previously associated with the terminal.</p>
	*
	* @param terminal the terminal to be added.
	* @param expression the <code>Expression</code> associated with <code>terminal</code>. When grabbing, the language denoted by <code>expression</code> matches <code>terminal</code>.
	*/
	protected void put(Object terminal, Expression expression) {
		this.terminals.put(terminal, expression);
		this.initial.size = 0;
		this.accepts.clear();
	}

	/**
	* <p>Indicates whether a symbol is a terminal in this <code>Lexicon</code>.</p>
	*
	* @param symbol the symbol whose status is requested.
	* @return <code>true</code> if <code>symbol</code> is a terminal in this <code>Lexicon</code>; <code>false</code> otherwise.
	*/
	boolean terminal(Object symbol) {
		return this.terminals.containsKey(symbol);
	}


	/**
	* <p>Creates a new state in the lexical NFA.</p>
	*
	* @return the new state in the lexical NFA.
	*/
	private static Integer state() {
		return new Integer(Lexicon.size++);
	}

	/**
	* <p>Puts a transition into the lexical NFA.</p>
	*
	* @param from the state from which the transition is made.
	* @param on the <code>Alphabet</code> on which the transition is made.
	* @param to the state to which the transition is made.
	*/
	private static void put(Integer from, Alphabet on, Integer to) {
		int index = from.intValue();
		int extent = Math.max(index, to.intValue());
		for (int i = transitions.size; i <= extent; i++) transitions.append(null);
		Set transition = (Set)transitions.elements[index];
		if (transition == null) transitions.elements[index] = transition = new Set(4);
		transition.append(on);
		transition.append(to);
	}


	/**
	* <p>Returns the initial state of this <code>Lexicon</code>.</p>
	*
	* @return {@link #initial}, computing it and {@link #accepts} if there is a need to compute the current initial state and NFA accept states.
	*/
	private Set initial() {
		Set initial = this.initial;

		if (initial.size == 0) {
			Map accepts = this.accepts;

			for (Iterator i = this.terminals.entrySet().iterator(); i.hasNext();) {
				Map.Entry entry = (Map.Entry)i.next();
				Expression expression = (Expression)entry.getValue();
				initial.add(expression.initial);
				accepts.put(expression.accept, entry.getKey());
			}
			closure(initial);
		}
		return initial;
	}

	/**
	* <p>Computes a transition using the lexical NFA.</p>
	*
	* @param from the state from which the transition is made.
	* @param on the character on which the transition is made.
	* @param to the state to which the transition is made.
	* @return the state to which the transition is made.
	*/
	private static Set transition(Set from, char on, Set to) {
		Object[] transitions_elements = transitions.elements;
		int from_size = from.size;
		Object[] from_elements = from.elements;
		to.size = 0;

		for (int i = 0; i < from_size; i++) {
			int index = ((Integer)from_elements[i]).intValue();
			Set transition = (Set)transitions_elements[index];
			if (transition == null) continue;

			int transition_size = transition.size;
			Object[] transition_elements = transition.elements;

			for (int j = 0; j < transition_size; j += 2) {
				Object alphabet = transition_elements[j];
				if (alphabet == null) break;
				if (((Alphabet)alphabet).contains(on)) to.add(transition_elements[j + 1]);
			}
		}
		return to;
	}


	/**
	* <p>Computes a null-closure using the lexical NFA. The null-closure is computed in place by a breadth-first search expanding <code>from</code>.</p>
	*
	* @param from the state whose null-closure is computed.
	* @return the reflexive transitive closure of <code>from</code> under null transition.
	*/
	private static Set closure(Set from) {
		Object[] transitions_elements = transitions.elements;

		for (int i = 0; i < from.size; i++) {
			int index = ((Integer)from.elements[i]).intValue();
			Set transition = (Set)transitions_elements[index];
			if (transition == null) continue;

			int transition_size = transition.size;
			Object[] transition_elements = transition.elements;

			for (int j = 0; j < transition_size; j += 2) {
				Object alphabet = transition_elements[j];
				if (alphabet != null) break;
				from.add(transition_elements[j + 1]);
			}
		}
		return from;
	}

	/**
	* <p>Computes the terminal recognized by a state in this <code>Lexicon</code>.</p>
	*
	* @param state the state.
	* @return the highest priority terminal associated with an NFA accept state in <code>state</code>. Returns <code>null</code> if <code>state</code> contains no NFA accept states.
	*/
	private Object recognize(Set state) {
		Map accepts = this.accepts;
		int state_size = state.size;
		Object[] state_elements = state.elements;
		Integer accept = null;
		Object lookahead = null;

		for (int i = 0; i < state_size; i++) {
			Integer nfa_state = (Integer)state_elements[i];
			Object label = accepts.get(nfa_state);

			if (label != null && (accept == null || accept.compareTo(nfa_state) < 0)) {
				accept = nfa_state;
				lookahead = label;
			}
		}
		return lookahead;
	}
}

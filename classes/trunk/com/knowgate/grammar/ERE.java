
package com.knowgate.grammar;

/**
* <p>This class implements a {@link Grammar} for interpreting POSIX extended regular expressions (EREs).</p>
*
* @version 0.9
* @author &copy; 1999-2000 <a href="http://www.csupomona.edu/~carich/">Craig A. Rich</a> &lt;<a href="mailto:carich@acm.org">carich@acm.org</a>&gt;
* @see <a href="../../../src/gi/ERE.java">Source code</a>
*/
class ERE extends LR1_Grammar {

	/**
	* <p>The <code>Grammar</code> for POSIX extended regular expressions (EREs).</p>
	*/
	private static Grammar ere;

	/**
	* <p>Constructs a <code>Grammar</code> for POSIX extended regular expressions (EREs).</p>
	*/
	ERE() {

		/**
		* Lexical Specification
		*/
		put("BASIC_ELEM", new NonMatch("^-].[$()|*+?{\\}"));
		put("DIGIT", new UnicodeCategory(Character.DECIMAL_DIGIT_NUMBER));


		/**
		* Semantic Specification
		*/
		Semantics union = new Semantics() {
			protected void evaluate(ParseTree tree) {
				ParseTree[] phrase = tree.phrase;
				Expression left = (Expression)phrase[0].attribute;
				Expression right = (Expression)phrase[2].attribute;
				tree.attribute = new Union(left, right);
			}
		};
		Semantics concatenation = new Semantics() {
			protected void evaluate(ParseTree tree) {
				ParseTree[] phrase = tree.phrase;
				Expression left = (Expression)phrase[0].attribute;
				Expression right = (Expression)phrase[1].attribute;
				tree.attribute = new Concatenation(left, right);
			}
		};
		Semantics repetition = new Semantics() {
			protected void evaluate(ParseTree tree) {
				ParseTree[] phrase = tree.phrase;
				int length = phrase.length;
				Expression kernel = (Expression)phrase[0].attribute;
				int min = 0;
				int max = -1;

				if (length == 3) {
					String power = (String)phrase[1].attribute;
					if (power.equals("+")) min = 1;
					else if (power.equals("?")) max = 1;
				}
				else {
					min = Integer.parseInt((String)phrase[2].attribute);
					if (length == 5) max = min;
					else if (length > 6) max = Integer.parseInt((String)phrase[4].attribute);
				}
				tree.attribute = new Repetition(kernel, min, max);
			}
		};
		Semantics any = new Semantics() {
			protected void evaluate(ParseTree tree) {
				tree.attribute = new NonMatch("");
			}
		};

		Semantics match = new Semantics() {
			protected void evaluate(ParseTree tree) {
				ParseTree[] phrase = tree.phrase;
				Object list = phrase[phrase.length - 2].attribute;
				tree.attribute = (list instanceof String) ? new Match((String)list) : new Match((Lexicon.Set)list);
			}
		};
		Semantics nonmatch = new Semantics() {
			protected void evaluate(ParseTree tree) {
				ParseTree[] phrase = tree.phrase;
				Lexicon.Set list = (Lexicon.Set)phrase[1].attribute;
				tree.attribute = new NonMatch(list);
			}
		};
		Semantics range = new Semantics() {
			protected void evaluate(ParseTree tree) {
				ParseTree[] phrase = tree.phrase;
				char from = ((String)phrase[0].attribute).charAt(0);
				char to = ((String)phrase[1].attribute).charAt(0);
				tree.attribute = new Range(from, to);
			}
		};
		Semantics posixclass = new Semantics() {
			protected void evaluate(ParseTree tree) throws Exception {
				String name = (String)tree.phrase[2].attribute;
				Expression expression;
				if (name.equalsIgnoreCase("upper")) expression = PosixClass.upper();
				else if (name.equalsIgnoreCase("lower")) expression = PosixClass.lower();
				else if (name.equalsIgnoreCase("alpha")) expression = PosixClass.alpha();
				else if (name.equalsIgnoreCase("digit")) expression = PosixClass.digit();
				else if (name.equalsIgnoreCase("xdigit")) expression = PosixClass.xdigit();
				else if (name.equalsIgnoreCase("alnum")) expression = PosixClass.alnum();
				else if (name.equalsIgnoreCase("punct")) expression = PosixClass.punct();
				else if (name.equalsIgnoreCase("graph")) expression = PosixClass.graph();
				else if (name.equalsIgnoreCase("print")) expression = PosixClass.print();
				else if (name.equalsIgnoreCase("blank")) expression = PosixClass.blank();
				else if (name.equalsIgnoreCase("space")) expression = PosixClass.space();
				else if (name.equalsIgnoreCase("cntrl")) expression = PosixClass.cntrl();
				else throw new Exception("invalid POSIX character class name");
				tree.attribute = expression;
			}
		};
		Semantics list = new Semantics() {
			protected void evaluate(ParseTree tree) {
				ParseTree[] phrase = tree.phrase;
				int length = phrase.length;
				Lexicon.Set bracket = (length == 2) ? new Lexicon.Set(10) : (Lexicon.Set)phrase[0].attribute;
				bracket.append(phrase[length - 2].attribute);
				tree.attribute = bracket;
			}
		};

		Semantics empty = new Semantics() {
			protected void evaluate(ParseTree tree) {
				tree.attribute = "";
			}
		};
		Semantics append = new Semantics() {
			protected void evaluate(ParseTree tree) {
				ParseTree[] phrase = tree.phrase;
				tree.attribute = (String)phrase[0].attribute + (String)phrase[1].attribute;
			}
		};
		Semantics first = new Semantics() {
			protected void evaluate(ParseTree tree) {
				tree.attribute = tree.phrase[0].attribute;
			}
		};
		Semantics second = new Semantics() {
			protected void evaluate(ParseTree tree) {
				tree.attribute = tree.phrase[1].attribute;
			}
		};
		Semantics third = new Semantics() {
			protected void evaluate(ParseTree tree) {
				tree.attribute = tree.phrase[2].attribute;
			}
		};


		/**
		* Syntax Specification
		*
		* IEEE P1003.2 Draft 11.2
		* Copyright (c) 1991 IEEE
		*/
		put("ERE", new Object[][] {
			{"AnchoredERE", first},
			{"NonAnchoredERE", first},
			{"ERE", "|", "NonAnchoredERE", union},
			{"ERE", "|", "AnchoredERE", union}
		});
		put("AnchoredERE", new Object[][] {
			{"^", "NonAnchoredERE", second},
			{"^", "NonAnchoredERE", "$", second},
			{"NonAnchoredERE", "$", first},
			{"^", empty},
			{"$", empty},
			{"^", "$", empty}
		});
		put("NonAnchoredERE", new Object[][] {
			{"ERExpression", first},
			{"NonAnchoredERE", "ERExpression", concatenation}
		});
		put("ERExpression", new Object[][] {
			{"OneCharacterERE", first},
			{"(", "ERE", ")", second},
			{"ERExpression", "*", repetition},
			{"ERExpression", "+", repetition},
			{"ERExpression", "?", repetition},
			{"ERExpression", "{", "Digits", "}", repetition},
			{"ERExpression", "{", "Digits", ",", "}", repetition},
			{"ERExpression", "{", "Digits", ",", "Digits", "}", repetition}
		});
		put("Digits", new Object[][] {
			{"DIGIT", first},
			{"Digits", "DIGIT", append}
		});
		put("OneCharacterERE", new Object[][] {
			{"OrdChar", match},
			{"\\", "AnyChar", match},
			{".", any},
			{"BracketExpression", first}
		});


		/**
		* Syntax Specification for Bracket Expressions
		*
		* IEEE P1003.2 Draft 11.2
		* Copyright (c) 1991 IEEE
		*/
		put("BracketExpression", new Object[][] {
			{"[", "MatchingList", "]", second},
			{"[", "NonMatchingList", "]", second}
		});
		put("MatchingList", new Object[][] {
			{"BracketList", match}
		});
		put("NonMatchingList", new Object[][] {
			{"^", "BracketList", nonmatch}
		});
		put("BracketList", new Object[][] {
			{"FollowList", first},
			{"FollowList", "-", list}
		});
		put("FollowList", new Object[][] {
			{"ExpressionTerm", list},
			{"FollowList", "ExpressionTerm", list}
		});
		put("ExpressionTerm", new Object[][] {
			{"SingleExpression", first},
			{"RangeExpression", first}
		});
		put("SingleExpression", new Object[][] {
			{"EndRange", match},
			{"CharacterClass", first}
		});
		put("RangeExpression", new Object[][] {
			{"StartRange", "EndRange", range},
			{"StartRange", "-", range}
		});
		put("StartRange", new Object[][] {
			{"EndRange", "-", first}
		});
		put("EndRange", new Object[][] {
			{"CollElem", first},
			{"^", first},
			{"-", first},
//			{"]", first},
			{"CollatingSymbol", first}
		});
		put("CollatingSymbol", new Object[][] {
			{"[", ".", "CollElem", ".", "]", third},
			{"[", ".", "^", ".", "]", third},
			{"[", ".", "-", ".", "]", third},
			{"[", ".", "]", ".", "]", third},
			{"\\", "AnyChar", second}
		});

		put("CharacterClass", new Object[][] {
			{"[", ":", "ClassName", ":", "]", posixclass}
		});
		put("ClassName", new Object[][] {
			{"BASIC_ELEM", first},
			{"ClassName", "BASIC_ELEM", append}
		});

		/**
		* pseudo-terminal symbols
		*/
		put("CollElem", new Object[][] { // new NonMatch("^-]")
			{"BASIC_ELEM", first},
			{"DIGIT", first},
			{"SpecCharNoAnchor", first},
			{"}", first}
		});
		put("AnyChar", new Object[][] { // new NonMatch("")
			{"CollElem", first},
			{"^", first},
			{"-", first},
			{"]", first}
		});
		put("SpecCharNoAnchor", new Object[][] { // new Match(".[$()|*+?{\\"))
			{".", first},
			{"[", first},
			{"$", first},
			{"(", first},
			{")", first},
			{"|", first},
			{"*", first},
			{"+", first},
			{"?", first},
			{"{", first},
			{"\\", first}
		});
		put("SpecChar", new Object[][] { // new Match("^.[$()|*+?{\\"))
			{"^", first},
			{"SpecCharNoAnchor", first}
		});
		put("OrdChar", new Object[][] { // new NonMatch("^.[$()|*+?{\\"))
			{"BASIC_ELEM", first},
			{"DIGIT", first},
			{"-", first},
			{"]", first},
			{"}", first}
		});
	}

	/**
	* <p>Creates an <code>Expression</code> by interpreting a POSIX extended regular expression (ERE), as used in egrep.</p>
	*
	* @param string the POSIX extended regular expression (ERE) to be interpreted.
	* @return the <code>Expression</code> constructed by interpreting <code>string</code>.
	* @throws Lexicon.Exception if a syntax error occurs.
	*/
	static Expression parse(String string) throws Exception {
		Grammar ere = ERE.ere;
		if (ere == null) ERE.ere = ere = new ERE();
		return (Expression)ere.interpret(string).attribute;
	}
}

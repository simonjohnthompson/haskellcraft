Glossary
========

We include this glossary to give a quick reference to the most widely used terminology in the book. Words appearing in **bold** in the descriptions have their own entries. Further references and examples are to be found by consulting the index.

**Abstract type** <a id="ix-glossary-abstract-data-type"></a> An abstract type definition consists of the type name, the **signature** of the type, and the implementation equations for the names in the signature.

**Algebraic type** <a id="ix-glossary-algebraic-type"></a> An algebraic type definition states what are the **constructors** of the type. For instance, the declaration

```haskell
data Tree = Leaf Int | 
            Node Tree Tree
```

says that the two constructors of the `Tree` type are `Leaf` and `Node`, and that their types are, respectively,

```haskell
Leaf :: Int->Tree
Node :: Tree->Tree->Tree
```

**Application** <a id="ix-glossary-function-application"></a> This means giving values to (some of) the arguments of a function. If an `n`-argument function is given fewer than `n` arguments, this is called a **partial application**. Application is written using **juxtaposition**.

**Argument** <a id="ix-glossary-argument"></a> A **function** takes one or more arguments into an **output**. Arguments are also known as **inputs** and **parameters**.

**Associativity** <a id="ix-glossary-associativity"></a> The way in which an expression involving two applications of an operator is interpreted. If `x#y#z` is interpreted as `(x#y)#z` then `#` is left associative, if as `x#(y#z)` it is right associative; if both bracketings give the same result then `#` is called associative.

**Base types** <a id="ix-glossary-type-base"></a> The types of numbers, including `Int` and `Float`, **Booleans**, `Bool`, and **characters**, `Char`.

**Binding power** <a id="ix-glossary-operator-binding-power-of"></a> The 'stickiness' of an operator, expressed as an integer; the higher the number the stickier the operator. For example, `2+3*4` is interpreted as `2+(3*4)` as '`*`' has higher binding power -- binds more tightly -- than '`+`'.

**Booleans** <a id="ix-glossary-booleans"></a> The type containing the two 'truth values' `True` and `False`.

**Calculation** <a id="ix-glossary-calculation"></a> A calculation is a line-by-line **evaluation** of a Haskell **expression** on paper. Calculations use the **definitions** which are contained in a **script** as well as the built-in definitions.

**Cancellation** <a id="ix-glossary-type-checking-rule-of-cancellation"></a> The rule for finding the type of a partial application.

**Character** <a id="ix-glossary-characters"></a> A single letter, such as `’s’` or `’\t’`, the tab character. They form the `Char` type.

**Class** <a id="ix-glossary-classes"></a> A collection of types. A class is defined by specifying a **signature**; a type is made an **instance** of the class by supplying an implementation of the definitions of the signature over the type.

**Clause** <a id="ix-glossary-clause"></a> A clause is one of the alternatives making up a **conditional equation**. A clause consists of a **guard** followed by an **expression**. When evaluating a function application, the first clause whose guard evaluates to `True` is chosen.

**Combinator** Another name for a **function**.

**Comment** <a id="ix-glossary-comment"></a> Part of a **script** which plays no computational role; it is there for the reader to read and observe. Comments are specified in two ways: the part of the line to the right is made a comment by the symbol `–`; a comment of arbitrary length is enclosed by `{-` and `-}`.

**Complexity** <a id="ix-glossary-complexity"></a> A measurement of the time or space behaviour of a function.

**Composition** <a id="ix-glossary-function-composition"></a> The combination of two functions by passing the **output** of one to the **input** of the other.

**Concatenate** <a id="ix-glossary-concatenate"></a> To put together a number of lists into a single list.

**Conditional equation** <a id="ix-glossary-conditional-equation"></a> A conditional equation consists of a left-hand side followed by a number of **clauses**. Each clause consists of a **guard** followed by an expression which is to be equated with the left-hand side of the **equation** if that particular clause is chosen during evaluation. The clause chosen is the first whose guard evaluates to `True`.

**Conformal pattern match** <a id="ix-glossary-pattern-matching-conformal"></a> An equation in which a pattern appears on the left-hand side of an equation, as in

```haskell
(x,y) = ....
```

**Constructor** <a id="ix-glossary-constructor"></a> An **algebraic type** is specified by its constructors, which are the functions which build elements of the algebraic type. In the example in the entry for algebraic types, elements of the type are constructed using `Leaf` and `Node`; the elements are `Leaf n` where `n::Int` and `Node s t` where `s` and `t` are trees.

**Context** <a id="ix-glossary-context"></a> The hypotheses which appear before `=>` in type and class declarations. A context `M a` means that the type `a` must belong to the class `M` for the function or class definition to apply. For instance, to apply a function of type

```haskell
Eq a => [a] -> a -> Bool
```

to a list and object, these must come from types over which equality is defined.

**Curried function** <a id="ix-glossary-currying"></a> A function of at least two arguments which takes its arguments one at a time, so having the type

```haskell
t1 -> t2 -> ... -> t
```

in contrast to the *uncurried* version

```haskell
(t1,t2,...) -> t
```

The name is in honour of Haskell B. Curry, after whom the Haskell language is also named.

**Declaration** <a id="ix-glossary-declaration"></a> A **definition** can be accompanied by a statement of the **type** of the object defined; these are often called type declarations.

**Default** <a id="ix-glossary-default"></a> A default holds in the absence of any other definition. Used in `class` definitions to give definitions of some of the operations in terms of others; an example is the definition of `/=` in the `Eq` class.

**Definition** <a id="ix-glossary-definition"></a> A definition associates a **value** or a **type** with a **name**.

**Design** <a id="ix-glossary-design"></a> In writing a system, the effort expended *before* implementation is started.

**Derived class instance** <a id="ix-glossary-instance-derived"></a> An instance of a standard class which is derived by the system, rather than put in explicitly by the programmer.

**Enumerated type** <a id="ix-glossary-enumerated-type"></a> An **algebraic type** with each constructor having no arguments.

**Equation** <a id="ix-glossary-equation"></a><a id="ix-glossary-equation-conditional"></a> A **definition** in Haskell consists of a number of equations. On the left-hand side of the equation is a **name** applied to zero or more **patterns**; on the right-hand side is a value. In many cases the equation is **conditional** and has two or more **clauses**. Where the meaning is clear we shall sometimes take 'equation' as shorthand for 'equation or conditional equation'.

**Evaluation** <a id="ix-glossary-evaluation"></a> Every **expression** in Haskell has a value; evaluation is the process of finding that value. A **calculation** evaluates an expression, as does an interactive Haskell system when that expression is typed to the prompt.

**Export** <a id="ix-glossary-export"></a> The process of defining which definitions will be visible when a module is **imported** by another.

**Expression** <a id="ix-glossary-expression"></a> An expression is formed by applying a **function** or **operator** to its arguments; these arguments can be **literal** values, or expressions themselves. A simple numerical expression is

```haskell
(2+8)-10
```

in which the operator '`-`' is applied to two arguments.

**Extensionality** <a id="ix-glossary-extensionality-principle"></a> The principle of proof which says that two functions are equal if they give equal results for every input.

**Filter** <a id="ix-glossary-filter"></a> To pick out those elements of a list which have a particular property, represented by a **Boolean**-valued function.

**Floating-point number** <a id="ix-glossary-numbers-floating-point"></a> A number which is given in decimal (e.g. 456.23) or exponent (e.g. `4.5623e+2`) form; these numbers form the type `Float`.

**Fold** <a id="ix-glossary-folding"></a> To combine the elements of a list using a binary **operation**.

**Forward composition** <a id="ix-glossary-forward-composition"></a> Used for the operator '`>.>`' with the definition

```haskell
f >.> g = g . f
```

`f >.> g` can be read '`f` then `g`'.

**Function** <a id="ix-glossary-function"></a> A function is an object which returns a **value**, called the **output** or **result** when it is applied to its **inputs**. The inputs are also known as its **parameters** or **arguments**.

Examples include the square root function, whose input and output are numbers, and the function which returns the borrowers (output) of a book (input) in a database (input).

**Function types** The type of a **function** is a function type, so that, for instance, the function which checks whether its integer argument is even has type `Int->Bool`. This is the type of functions with **input** type `Int` and **output** type `Bool`.

**Generalization** <a id="ix-glossary-generalization"></a> Replacing an object by something of which the original object is an instance. This might be the replacement of a function by a polymorphic function from which the original is obtained by passing the appropriate parameter, or replacing a logical formula by one which implies the original.

**Guard** <a id="ix-glossary-guard"></a> The **Boolean** expression appearing to the right of '`|`' and to the left of '`=`' in a **clause** of a **conditional equation** in a Haskell **definition**.

**Higher-order function** <a id="ix-glossary-higher-order-function"></a> A **function** is higher-order if either one of its **arguments** or its **result**, or both, are functions.

**Identifier** <a id="ix-glossary-identifier"></a> Another word for **name**.

**Implementation** The particular **definitions** which make a design concrete; for an **abstract data type**, the definitions of the objects named in the **signature**.

**Import** The process of including the **exported** definitions of one module in another.

**Induction** <a id="ix-glossary-induction"></a> The name for a collection of methods of proof, by which statements of the form 'for all `x` ...' are proved.

**Infix** <a id="ix-glossary-function-infix"></a> An **operation** which appears between its **arguments**. Infix functions are called **operators**.

**Inheritance** <a id="ix-glossary-inheritance"></a> One **class** inherits the operations of another if the first class is in the **context** of the definition of the second. For instance, of the standard classes, `Ord` inherits (in)equality from `Eq`.

**Input** <a id="ix-glossary-input"></a> A **function** takes one or more inputs into an **output**. Inputs are also known as **arguments** and **parameters**. The 'square' function takes a single numerical input, for instance.

**Instance** <a id="ix-glossary-instance"></a><a id="ix-glossary-instance-of-variable"></a> <a id="ix-glossary-instance-of-class"></a> The term 'instance' is used in two different ways in Haskell. An instance of a **type** is a type which is given by **substituting** a type expression for a type **variable**. For example, `[(Bool,b)]` is an instance of `[a]`, given by substituting the type `(Bool,b)` for the variable `a`. An instance of a **class**, such as `Eq (a,b)`, is given by declaring how the function(s) of the class, in this case `==`, are defined over the given type (here `(a,b)`). Here we would say

```haskell
(x,y) == (z,w)
  = (x==z) && (y==w)
```

**Integers** <a id="ix-glossary-numbers-integers"></a> The positive and negative whole numbers. In Haskell the type `Int` represents the integers in a fixed size, while the type `Integer` represents them exactly, so that evaluating `2` to the power `1000` will give a result consisting of some three hundred digits.

**Interactive program** A program which reads from and writes to the terminal; reading and writing will be *interleaved*, in general.

**Interface** <a id="ix-glossary-interface"></a> The common information which is shared between two program modules.

**Juxtaposition** <a id="ix-glossary-juxtaposition"></a> Putting one thing next to another; this is the way in which function application is written down in Haskell.

**Lambda expression** <a id="ix-glossary-lambda-expression"></a> An **expression** which denotes a **function**. After a '`\`' we list the arguments of the function, then an '`->`' and then the result. For instance, to add a number to the length of a list we could write

```haskell
\xs n -> length xs + n
```

The term 'lambda' is used since '`\`' is close to the Greek letter '`λ`', or lambda, which is used in a similar way in Church's lambda calculus.

**Lazy evaluation** <a id="ix-glossary-lazy-evaluation"></a> The sort of expression **evaluation** in Haskell. In a function application only those arguments whose values are *needed* will be evaluated, and moreover, only the parts of structures which are needed will be examined.

**Linear complexity** <a id="ix-glossary-complexity-linear"></a> Order `1`, `O(n)`, behaviour.

**Lists** <a id="ix-glossary-lists"></a> A list consists of a collection of elements of a particular type, given in some order, potentially containing a particular item more than once. The list `[2,1,3,2]` is of type `[Int]`, for example.

**Literal** <a id="ix-glossary-literal"></a> Something that is 'literally' a value: it needs no **evaluation**. Examples include `34`, `[23]` and `"string"`.

**Local definitions** <a id="ix-glossary-local-definitions"></a> The definitions appearing in a `where` clause or a `let` expression. Their **scope** is the equation or expression to which the clause or `let` is attached.

**Map** <a id="ix-glossary-mapping"></a> To apply an operation to every element of a list.

**Mathematical induction** <a id="ix-glossary-mathematical-induction"></a> A method of proof for statements of the form 'for all natural numbers `n`, the statement `P(n)` holds'. The proof is in two parts: the base case, at zero, and the induction step, at which `P(n)` is proved on the assumption that `P(n-1)` holds.

**Memoization** <a id="ix-glossary-memoization"></a> Keeping the value of a sub-computation (in a list, say) so that it can be reused rather than recomputed, when it is needed.

**Module** <a id="ix-glossary-modules"></a> Another name for a **script**; used particularly when more than one script is used to build a program.

**Monad** <a id="ix-glossary-monad"></a> A monad consists of a type with (at least) two functions, `return` and `>>=`. Informally, a monad can be seen as performing some sorts of action before returning an object. The two monad functions respectively return a value without any action, and sequence two monadic operations.

**Monomorphic** <a id="ix-glossary-type-monomorphic"></a> A type is **monomorphic** if it is not **polymorphic**.

**Most general type** <a id="ix-glossary-type-most-general"></a> The most general type of an expression is the type `t` with the property that every other type for the expression is an **instance** of `t`.

**Mutual recursion** <a id="ix-glossary-recursion-mutual"></a> Two definitions, each of which depends upon the other.

**Name** <a id="ix-glossary-name"></a> A **definition** associates a name or **identifier** with a value. Names of **classes**, **constructors** and **types** must begin with capital letters; names of **values**, **variables** and **type variables** begin with small letters. After the first letter, any letter, digit, '`’`' or '`_`' can be used.

**Natural numbers** <a id="ix-glossary-numbers-natural-numbers"></a> The non-negative whole numbers: `0`, `1`, `2`, ... .

**Offside rule** <a id="ix-glossary-offside-rule"></a> The way in which the end of a part of a definition is expressed using the *layout* of a **script**, rather than an explicit symbol for the end.

**Operation** Another name for **function**.

**Operator** <a id="ix-glossary-operator"></a> A **function** which is written in infix form, between its **arguments**. The function `f` is made infix thus: `‘f‘`.

**Operator section** <a id="ix-glossary-operator-sections"></a> A partially applied operator.

**Output** <a id="ix-glossary-output"></a> When a **function** is applied to one or more **inputs**, the resulting value is called the output, or **result**. Applying the 'square' function to `(-2)` gives the output `4`, for example.

**Overloading** <a id="ix-glossary-overloading"></a> The use of the same **name** to mean two (or more) different things, at different types. The equality operation, `==`, is an example. Overloading is supported in Haskell by the **class** mechanism.

**Parameter** <a id="ix-glossary-parameter"></a> A **function** takes one or more parameters into an **output**. Parameters are also known as **arguments** and **inputs**, and applying a function to its inputs is sometimes known as 'passing its parameters'.

**Parsing** <a id="ix-glossary-parsing"></a> Revealing the structure of a sentence in a formal language.

**Partial application** <a id="ix-glossary-partial-application"></a> A **function** of type `t1->t2->…->tn->t` can be applied to `n` arguments, or less. In the latter case, the **application** is partial, since the result can itself be passed further parameters.

**Pattern** <a id="ix-glossary-pattern"></a> A pattern is either a **variable**, a **literal**, a **wild card** or the application of a **constructor** to other patterns. The term 'pattern' is also used as short for a 'pattern of computation' such as 'applying an operation to every member of a list', a pattern which in Haskell is realised by the `map` function.

**Polymorphism** <a id="ix-glossary-polymorphism"></a> A type is polymorphic if it contains type **variables**; such a type will have many **instances**.

**Prefix** <a id="ix-glossary-function-prefix"></a> An **operation** which appears before its **arguments**.

**Primitive recursion** <a id="ix-glossary-primitive-recursion"></a> Over the natural numbers, defining the values of a function outright at zero, and at `n` greater than zero using the value at `n-1`.

Over an **algebraic type** defining the function by cases over the constructors; recursion is permitted at arguments to a constructor which are of the type in question.

**Proof** <a id="ix-glossary-proof"></a> A logical argument which leads us to accept a logical statement as being valid.

**Pure programming language** <a id="ix-glossary-functional-programming-pure"></a> A functional programming language is pure if it does not allow **side-effects**.

**Quadratic complexity** <a id="ix-glossary-complexity-quadratic"></a> Order two, `O(n)`, behaviour.

**Recursion** <a id="ix-glossary-recursion"></a> Using the name of a value or type in its own **definition**.

**Result** <a id="ix-glossary-result"></a> When a **function** is applied to one or more **inputs**, the resulting value is called the result, or **output**.

**Scope** <a id="ix-glossary-scope"></a> The area of a program in which a **definition** or definitions are applicable.

In Haskell the scope of top-level definitions is by default the whole **script** in which they appear; it may be extended by importing the module into another. More limited scopes are given by **local definitions**.

**Script** <a id="ix-glossary-script"></a> A script is a file containing **definitions**, **declarations** and module statements.

**Set** <a id="ix-glossary-sets"></a> A collection of objects for which the order of elements and the number of occurrences of each element are irrelevant.

**Side-effect** <a id="ix-glossary-side-effect"></a> In a language like Pascal, evaluating an expression can cause other things to happen besides a value being computed. These might be I/O operations, or changes in values stored. In Haskell this does not happen, but a **monad** can be used to give a similar effect, without compromising the simple model of evaluation underlying the language. Examples are `IO` and `State`.

**Signature** <a id="ix-glossary-signature"></a> A sequence of type **declarations**. These declarations state what are the types of the operations (or functions) over an **abstract type** or a **class** which can be used to manipulate elements of that type.

**Stream** <a id="ix-glossary-stream"></a> A stream is a channel upon which items arrive in sequence; in Haskell we can think of **lazy** lists in this way, so it becomes a synonym for lazy list.

**String** <a id="ix-glossary-strings"></a> The type `String` is a **synonym** for lists of characters, `[Char]`.

**Structural induction** <a id="ix-glossary-structural-induction"></a> A method of proof for statements of the form 'for all finite lists `xs`, the statement `P(xs)` holds of `xs`'. The proof is in two parts: the base case, at `[]`, and the induction step, at which `P(y:ys)` is proved on the assumption that `P(ys)` holds.

Also used of the related principle for any algebraic type.

**Substitution** <a id="ix-glossary-substitution"></a> The replacement of a **variable** by an **expression**. For example, `(9+12)` is given by substituting `12` for `n` in `(9+n)`. Types can also be substituted for type variables; see the entry for **instance**.

**Synonym** <a id="ix-glossary-type-synonym"></a> Naming a type is called a type synonym. The keyword `type` is used for synonyms.

**Syntax** <a id="ix-glossary-syntax"></a> The description of the properly formed programs (or sentences) of a language.

**Transformation** <a id="ix-glossary-program-transformation"></a> Turning one program into another program which computes identical results, but with different behaviour in other respects such as time or space efficiency.

**Tuples** <a id="ix-glossary-tuples"></a> A tuple type is built up from a number of component types. Elements of the type consist of tuples of elements of the component types, so that

```haskell
(2,True,3) :: (Int,Bool,Int)
```

for instance.

**Type** <a id="ix-glossary-type"></a> A collection of values. Types can be built from the **base** types using **tuple**, **list** and **function types**. New types can be defined using the **algebraic** and **abstract** type mechanisms, and types can be named using the type **synonym** mechanism.

**Type variable** <a id="ix-glossary-type-variable"></a> A **variable** which appears in a **polymorphic type**. An **identifier** beginning with a small letter can be used as a type variable; in this text we use the letters at the start of the alphabet, `a`, `b`, `c` and so on.

**Undefinedness** <a id="ix-glossary-undefinedness"></a> The result of an expression whose evaluation continues forever, rather than giving a *defined* result.

**Unification** <a id="ix-glossary-unification"></a> The process of finding a common **instance** of two (type) expressions containing (type) variables.

**Value** <a id="ix-glossary-value"></a> A value is a member of some **type**; the value of an **expression** is the result of **evaluating** the expression.

**Variable** <a id="ix-glossary-variable"></a> A variable stands for an *arbitrary* value, or in the case of type variables, an arbitrary type. Variables and type variables have the same syntax as **names**.

**Verification** Proving that a function or functions have particular logical properties.

**Where clause** Definitions **local** to a (conditional) **equation**.

**Wild card** <a id="ix-glossary-pattern-wild-card"></a> The name for the pattern '`_`', which is matched by any value of the appropriate type.

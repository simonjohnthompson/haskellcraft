Functional, imperative and OO programming {#vs}
=========================================

<a id="ix-appendix1-imperative-programming"></a>

In this appendix we compare programming in Haskell to more traditional notions in imperative languages like Pascal and C and object-oriented (OO) languages such as C\#, C++ and Java.

Values and states {#values-and-states .unnumbered}
-----------------

<a id="ix-appendix1-value"></a>

<a id="ix-appendix1-state"></a>

Consider the example of finding the sum of squares of natural numbers up to a particular number. A functional program describes the values that are to be calculated, directly.

```haskell
sumSquares :: Int -> Int
sumSquares 0 = 0
sumSquares n = n*n + sumSquares (n-1)
```

These equations state what the sum of squares is for a natural number argument. In the first case it is a direct description; in the second it states that the sum to non-zero `n` is got by finding the sum to `n-1` and adding the square of `n`.

A typical imperative program might solve the problem thus

```haskell
s = 0 ;
i = 0 ;
while i<n do 
  begin
    i = i+1 ;
    s = i*i + s ;
  end 
```

The sum is the final value of the variable `s`, which is changed repeatedly during program execution, as is the 'count' variable, `i`. The effect of the program can only be seen by following the sequence of changes made to these variables by the commands in the program, while the functional program can be read as a series of equations defining the sum of squares. This meaning is **explicit** in the functional program, whereas the imperative program has an overall effect which is not obvious from the program itself.

The link between these two approaches is given by a tail-recursive solution to the problem in Haskell:

```haskell
sumSquares n = ssAcc 0 0 n

ssAcc i s n
  | i<n       = ssAcc (i+1) ((i+1)^2+s) n
  | otherwise = s
```

Here the three argument positions play the role of three variables -- `i`, `s` and `n` -- whose values are changed on each call to the loop.

A more striking algorithm still is one which is completely explicit: 'to find the sum of squares, build the list of numbers `1` to `n`, square each of them, and sum the result'. This program, which uses neither complex control flow, as does the imperative example, nor recursion as seen in the function `sumSquares`, can be written in a functional style, thus:

```haskell
newSumSq :: Int -> Int
newSumSq n = sum (map square [1 .. n])
```

where `square x = x*x`, the operation `map` applies its first argument to every member of a list, and `sum` finds the sum of a list of numbers. More examples of this sort of **data-directed** programming<a id="ix-appendix1-data-directed-programming"></a> can be seen in the body of the text.

Functions and variables {#functions-and-variables .unnumbered}
-----------------------

An important difference between the two styles is what is meant by some of the terminology. Both 'function' and 'variable' have different interpretations.

<a id="ix-appendix1-function"></a>

As was explained earlier, a function in a functional program is simply something which returns a value which depends upon some inputs. In imperative and object-oriented languages like Pascal, C, C++ and Java a function is rather different. It will return a value depending upon its arguments, but in general it will also change the values of variables. Rather than being a pure function it is really a procedure which returns a value when it terminates.

<a id="ix-appendix1-variable"></a>

In a functional program a variable stands for an **arbitrary** or **unknown** value. Every occurrence of a variable in an equation is interpreted in the same way. They are just like variables in logical formulas, or the mathematical variables familiar from equations like

```haskell
a^2 - b^2 = (a-b)(a+b)
```

In any particular case, the value of all three occurrences of `a` will be the same. In exactly the same way, in

```haskell
sumSquares n = n*n + sumSquares (n-1)
```

all occurrences of `n` will be interpreted by the same value. For example

```haskell
sumSquares 7 = 7*7 + sumSquares (7-1)
```

The crucial motto is 'variables in functional programs *do not vary*'.

On the other hand, the value of a variable in an imperative program changes throughout its lifetime. In the sum of squares program above, the variable `s` will take the values `0,1,5,…` successively. Variables in imperative programs *do* vary over time, on the other hand.

Program verification {#program-verification .unnumbered}
--------------------

<a id="ix-appendix1-proof"></a>

Probably the most important difference between functional and imperative programs is logical. As well as being a program, a functional definition is a logical equation describing a **property** of the function. Functional programs are **self-describing**, as it were. Using the definitions, other properties of the functions can be deduced.

To take a simple example, for all `n>0`, it is the case that

```haskell
sumSquares n > 0
```

To start with,

```haskell
sumSquares 1 
= 1*1 + sumSquares 0
= 1*1 + 0
= 1
```

which is greater than 0. In general, for `n` greater than zero,

```haskell
sumSquares n = n*n + sumSquares (n-1)
```

Now, `n*n` is positive, and if `sumSquares (n-1)` is positive, their sum, `sumSquares n`, must be. This proof can be formalized using **mathematical induction**<a id="ix-appendix1-mathematical-induction"></a>. The body of the text contains numerous examples of proofs by induction over the structure of data structures like lists and trees, as well as over numbers.

Program verification is possible for imperative programs as well, but imperative programs are not self-describing in the way functional ones are. To describe the effect of an imperative program, like the 'sum of squares' program above, we need to add to the program logical formulas or assertions which describe the state of the program at various points in its execution. These methods are both more indirect and more difficult, and verification seems very difficult indeed for 'real' languages like Pascal and C. Another aspect of program verification is **program transformation** in which programs are transformed to other programs which have the same effect but better performance, for example. Again, this is difficult for traditional imperative languages.

Records and tuples {#records-and-tuples .unnumbered}
------------------

<a id="ix-appendix1-tuples"></a>

<a id="ix-appendix1-records"></a>

In [Data types, tuples and lists](5.md#tupleList) the tuple types of Haskell are introduced. In particular we saw the definition

```haskell
type Person = (String,String,Int)
```

This compares with a Pascal declaration of a record

```haskell
type Person = record 
  name  : String;
  phone : String;
  age   : Integer
end;
```

which has three fields which have to be named. In Haskell the fields of a tuple can be accessed by pattern matching, but it is possible to define functions called **selectors** which behave in a similar way, if required:

```haskell
name  :: Person -> String
name (n,p,a) = n
```

and so on. If `per :: Person` then `name per :: String`, similarly to `r.name` being a string variable if `r` is a variable of type `Person` in Pascal.

We could instead use an algebraic type to represent a person:

```haskell
data Person = Person {name::String, phone::String, age::Integer}
              deriving (Show,Eq)
```

In an object-oriented language like Java or C\# this type would be represented by an *object* wit three attributes, one for each of the name, phone and age. The methods modifying these values would also be part of the definition of the object.

To implement the analogue of an algebraic data type with more than one constructor in Java it is necessary to work rather harder. The type itself is modelled as a class with abstract methods, implemented in a number of sub-classes, one per constructor. Each sub-class contains the attributes for a particular constructor, together with the implementation of the methods over that sub-class. This approach works well for methods that work over one member of a class, but is more problematic for binary methods, and in particular for equality.

Lists and pointers {#lists-and-pointers .unnumbered}
------------------

<a id="ix-appendix1-pointer"></a>

Haskell contains the type of lists built in, and other recursive types such as trees can be defined directly. We can think of the type of linked lists given by pointers in Pascal as an **implementation** of lists, since in Haskell it is not necessary to think of pointer values, or of storage allocation ( `new` and `dispose`) as it is in Pascal. Indeed, we can think of Haskell programs as **designs** for Pascal list programs. If we define <a id="ix-appendix1-lists-as-pascal-type"></a>

```haskell
type list = ^node;
type node = record
   head : value;
   tail : list
end;
```

then we have the following correspondence, where the Haskell `head` and `tail` functions give the head and tail of a list.

```haskell
            []                        nil
            head ys                   ys^.head 
            tail ys                   ys^.tail 
            (x:xs)                    cons(x,xs) 
```

The function `cons` in Pascal has the definition

```haskell
function cons(y:value;ys:list):list;
  var xs:list;
  begin
    new(xs);
    xs^.head := y;
    xs^.tail := ys;
    cons := xs
  end;
```

Functions such as

```haskell
sumList []     = 0 
sumList (x:xs) = x + sumList xs 
```

can then be transferred to Pascal in a straightforward way.

```haskell
function sumList(xs:list):integer;
  begin
    if xs=nil 
      then sumList := 0
      else sumList := xs^.head + sumList(xs^.tail)
  end;
```

A second example is

```haskell
doubleAll []     = []
doubleAll (x:xs) = (2*x) : doubleAll xs
```

where we use `cons` in the Pascal definition of the function

```haskell
function doubleAll(xs:list):list;
  begin
    if xs=nil 
      then doubleAll := nil
      else doubleAll := cons( 2*xs^.head , doubleAll(xs^.tail) )
  end;
```

If we define the functions

```haskell
function head(xs:list):value;     function tail(xs:list):list;
  begin                            begin
    head := xs^.head                 tail := xs^.tail
  end;                             end;
```

then the correspondence is even clearer:

```haskell
function doubleAll(xs:list):list;
  begin
    if xs=nil 
      then doubleAll := nil
      else doubleAll := cons( 2*head(xs) , doubleAll( tail(xs) ) )
  end;
```

This is strong evidence that a functional approach can be useful even if we are writing in an imperative language: the functional language can be the high-level *design*<a id="ix-appendix1-design"></a> language for the imperative implementation. Making this separation can give us substantial help in finding imperative programs -- we can think about the design and the lower level implementation *separately*, which makes each problem smaller, simpler and therefore easier to solve.

Higher-order functions {#higher-order-functions .unnumbered}
----------------------

<a id="ix-appendix1-higher-order-function"></a>

Traditional imperative languages give little scope for higher-order programming; Pascal, Java and C allow functions as arguments, so long as those functions are not themselves higher-order, but has no facility for returning functions as results. In C++ it is possible to return objects which represent functions by overloading the function application operator! This underlies the genericity hailed in the C++ Standard Template Library, which requires advanced features of the language to implement functions like `map` and `filter`.

Control structures like `if-then-else` bear some resemblance to higher-order functions, as they take commands, `c1`, `c2` etc. into other commands,

```haskell
if b then c1 else c2      while b do c1
```

just as `map` takes one function to another. Turning the analogy around, we can think of higher-order functions in Haskell as **control structures** which we can define ourselves. This perhaps explains why we form libraries of polymorphic functions: they are the control structures we use in programming particular sorts of system. Examples in the text include libraries for building parsers ([Case study: parsing expressions](17.md#parsing)) and interactive I/O programs ([Playing the game: I/O in Haskell](8.md#io)), as well as the built-in list-processing functions.

Polymorphism {#polymorphism .unnumbered}
------------

<a id="ix-appendix1-polymorphism"></a>

Again, this aspect is poorly represented in many imperative languages; the best we can do in `Pascal`, say, is to use a text editor to copy and modify the list processing code from one type of lists for use with another. Of course, we then run the risk that the different versions of the programs are not modified in step, unless we are very careful to keep track of modifications, and so on.

Polymorphism in Haskell is what is commonly known as **generic** polymorphism: the same 'generic' code works over a whole collection of types. A simple example is the function which reverses the elements in a list.

Haskell classes support what is known as 'ad hoc' polymorphism, or in object-oriented terminology simply 'polymorphism', in which different programs implement the same operation over different types. An example of this is the `Eq` class of types carrying an equality operation: the way in which equality is checked is completely different at different types. Another way of viewing classes is as **interfaces**<a id="ix-appendix1-interface"></a> which different types can implement in different ways; in this way they resemble the interfaces of object-oriented languages like Java.

As is argued in the text, polymorphism is one of the mechanisms which helps to make programs *reusable* in Haskell; it remains to be seen whether this will also be true of advanced imperative languages.

Defining types and classes {#defining-types-and-classes .unnumbered}
--------------------------

The algebraic type mechanism of Haskell, explained in [Algebraic types](14.md#algTypes), <a id="ix-appendix1-algebraic-type"></a> subsumes various traditional type definitions. Enumerated types are given by algebraic types all of whose constructors are 0-ary (take no arguments); variant records can be implemented as algebraic types with more then one constructor, and **recursive** types usually implemented by means of pointers become recursive algebraic types.

Just as we explained for lists, Haskell programs over trees and so on can be seen as *designs* for programs in imperative languages manipulating the pointer implementations of the types.

The abstract data types<a id="ix-appendix1-abstract-data-type"></a>, introduced in [Abstract data types](16.md#adt), are very like the abstract data types of `Modula-2` and so on; the design methods we suggest for use of abstract data types mirror aspects of the **object-based** approach advocated for modern imperative languages such as `Ada`.

<a id="ix-appendix1-classes"></a>

The Haskell class system also has object-oriented aspects, as we saw in [Algebraic types and type classes](14.md#algClasses). It is important to note that Haskell classes are in some ways quite different from the classes of, for instance, `C++`. In Haskell classes are made up of types, which themselves have members; in `C++` a class is like a type, in that it contains objects. Because of this many of the aspects of object-oriented design in `C++` are seen as issues of type design in Haskell.

List comprehensions {#list-comprehensions .unnumbered}
-------------------

<a id="ix-appendix1-list-comprehensions"></a>

List comprehensions provide a convenient notation for **iteration** along lists: the analogue of a `for` loop, which can be used to run through the indices of an array. For instance, to sum all pairs of elements of `xs` and `ys`, we write

```haskell
[ a+b | a <- xs , b <- ys ]
```

The order of the iteration is for a value `a` from the list `xs` to be fixed and then for `b` to run through the possible values from `ys`; this is then repeated with the next value from `xs`, until the list is exhausted. Just the same happens for a **nested** `for` loop

```haskell
for i:=0 to xLen-1 do
  for j:=0 to yLen-1 do  -- (twoFor)
    write( x[i]+y[j] ) 
```

where we fix a value for `i` while running through all values for `j`.

In the `for` loop, we have to run through the indices; a list generator runs through the values directly. The indices of the list `xs` are given by

```haskell
[0 .. length xs - 1]
```

and so a Haskell analogue of `(twoFor)` can be written thus:

```haskell
[ xs!!i + ys!!j | i <- [0 .. length xs - 1] , 
                  j <- [0 .. length ys - 1] ]
```

if we so wish.

Lazy evaluation {#lazy-evaluation .unnumbered}
---------------

<a id="ix-appendix1-lazy-evaluation"></a>

Lazy evaluation and imperative languages do not mix well. In `Pascal`, for instance, we can write the function definition

```haskell
function succ(x : integer):integer;
begin
  y    := y+1;
  succ := x+1
end;
```

This function adds one to its argument, but also has the **side-effect** of increasing `y` by one. If we evaluate `f(y,succ(z))` we cannot predict the effect it will have.

-   If `f` evaluates its second argument first, `y` will be increased before being passed to `f`;

-   on the other hand, if `f` needs its first argument first (and perhaps its second argument not at all), the value passed to `f` will not be increased, even if it is increased before the function call terminates.

In general, it will not be possible to predict the behaviour of even the simplest programs. Since evaluating an expression can cause a change of the state, the order of expression evaluation determines the overall effect of a program, and so a lazy implementation can behave differently (in unforeseen ways) from the norm.

State, infinite lists and monads {#state-infinite-lists-and-monads .unnumbered}
--------------------------------

<a id="ix-appendix1-lists-infinite"></a>

<a id="ix-appendix1-monad"></a>

[Infinite lists](17.md#infLists) introduced infinite lists, and one of the first examples given there was an infinite list of random numbers. This list could be supplied to a function requiring a supply of random numbers; because of lazy evaluation, these numbers will only be generated on demand.

If we were to implement this imperatively, we would probably keep in a variable the last random number generated, and at each request for a number we would update this store. We can see the infinite list as supplying *all the values that the variable will take* as a single structure; we therefore do not need to keep the state, and hence have an **abstraction** from the imperative view.

We have seen in [Monads: languages for functional programming](18.md#monadFP) that there has been recent important work on integrating side-effecting programs into a functional system by a monadic approach.

Conclusion {#conclusion .unnumbered}
----------

Clearly there are parallels between the functional and the imperative, as well as clear differences. The functional view of a system is often higher-level, and so even if we ultimately aim for an imperative solution, a functional design or **prototype** can be most useful.

We have seen that monads can be used to give an interface to imperative features within a functional framework. Many of the Haskell implementations offer these facilities, and so give a method of uniting the best features of two important programming paradigms without compromising the purity of the language. Other languages, including Standard ML ([Milner et al. 1990](bibliography.md#defsml)) and F\# ([Smith 2009](bibliography.md#Fsharp)), combine the functional and the imperative, but these systems tend to lose their pure functional properties in the process.

It is interesting to see the influence of ideas from modern functional programming languages in the design of Java extensions. One of the main drawbacks of Java for a long time was that it lacked generic polymorphism. The current mechanism for generics in the Java standard owes its inspiration and much of its detail to Haskell polymorphism.

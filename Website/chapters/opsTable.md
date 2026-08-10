Haskell operators {#hsOps}
=================

<a id="ix-opsTable-operator-table-of-properties"></a>

<a id="ix-opsTable-floating-point-operators"></a>

The operators in the Haskell prelude are listed below in decreasing order of binding power: see [Operators](3.md#operators) for a discussion of associativity and binding power.

|     | Left associative                    | Non-associative                           | Right associative |
|:----|:------------------------------------|:------------------------------------------|:------------------|
| 9   | `!!`                                |                                           | .                 |
| 8   |                                     |                                           | `**, ^, ^^`       |
| 7   | `*, /, ‘div‘, ‘mod‘, ‘rem‘, ‘quot‘` |                                           |                   |
| 6   | `+, -`                              |                                           | ``                |
| 5   | ``                                  |                                           | `:, ++`           |
| 4   |                                     | `/=, <, <=, ==, >, >=, ‘elem‘, ‘notElem‘` |                   |
| 3   |                                     |                                           | `&&`              |
| 2   |                                     |                                           | `\|\|`              |
| 1   | `>>, >>=`                           |                                           |                   |
| 0   |                                     |                                           | `$, $!, ‘seq‘`    |

<a id="ix-opsTable-mod"></a>

<a id="ix-opsTable-div"></a>

<a id="ix-opsTable-rem"></a>

<a id="ix-opsTable-quot"></a>

<a id="ix-opsTable-elem"></a>

<a id="ix-opsTable-notelem"></a>

<a id="ix-opsTable-seq"></a>

Also defined in this text are the operators <a id="ix-opsTable-sc8beaa"></a> <a id="ix-opsTable-sb9031d"></a> <a id="ix-opsTable-sf17c6f"></a>

|     |       |     |       |
|:----|:------|:----|:------|
| 9   | `>.>` |     |       |
| 5   |       |     | `>*>` |

The restrictions on names of operators, which are formed using the characters

```haskell
! # $ % & * + . / < = > ? @  ^ | : - ~
```

are that operators must not start with a colon; this character starts an infix *constructor*. The operators `-` and `!` can be user-defined, but note that they have a special meaning in certain circumstances -- the obvious advice here is not to use them. Finally, certain combinations of symbols are reserved, and cannot be used: `.. : :: => = @ \ | ^ <- ->`.

To change the associativity or binding power of an operator, `&&&` say, we make a declaration like<a id="ix-opsTable-fixity-declaration"></a>

```haskell
infixl 7 &&&
```

which states that `&&&` has binding power 7, and is a left associative operator. We can also declare operators as non-associative (`infix`) and right associative (`infixr`). Omitting the binding power gives a default of 9. These declarations can also be used for back-quoted function names, as in

```haskell
infix 0 `poodle`
```

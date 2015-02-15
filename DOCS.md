Documentation
====

# The basics

Anything that is stressed with *italics* is an important concept.  You should have a somewhat solid idea of what these terms mean before reading on unless the next sentence specifically states that it will be discussed later.

I would not say I'm too experienced with stack-based or concatenative languages yet, so there may be some errors.

## What is a stack-based language?

A stack-based language is different kind of language than something like the C family.  Most stack-based language are also concatenative languages.  A concatenative is essentially a language that focuses more on *function composition* rather than *function application*.  Concatenative languages, function composition, and function application will be discussed later.

Here is an example of adding 1 and 1 in a stack-based language:

`1 2 +`

It may seem like an odd notation, but trying thinking of it like a stack.

Essentially, imagine you have a stack.  A stack is when you put things on top of eachother.  Something important about a stack is that you can only put something on top of the stack, or take what is on top off of the stack.  You cannot take anything in the middle of the stack off. Now, read from left-to-right, and place the first two of the three terms shown in the example on a 'stack':

```TOP: 2
     1```

Here is the stack, with TOP being the top of the stack. First, `1` is *pushed* to the top of the stack.  Pushing something to the stack essentially means putting it on top of the stack.  Then, `2` is pushed to the stack.  In the end, you have `2` on top with `1` under it.  What is left in the first expression is `+`.  Think of `+` in a mathematical sense.  You need two numbers to add together, or two *arguments* (or parameters), which is the term used to describe what values a function takes (for example: the function, `+`, takes 2 arguments).

You will notice that we have 2 items on the stack.  We will now push `+` to the stack:

```TOP: +
     2
     1```

What `+` will now do is it will *pop* the two numbers.  Pop means that it takes the item on the top of the stack.  Because `+` requires two arguments, it pops the `2` from the stack, and then the `1`.  They will be added together, and the sum of the two is now pushed to the stack:

```TOP: 3```

This is essentially how a stack-based language works, pushing things to the stack, and then using functions to pop things to use.  However, there may be one question: Why?

## What is a concatenative language?

A concatenative language, as explained above, is a language that is based on function composition rather than application, as seen in other language.  What this means is that instead of applying a function to its arguments, you are more focused on composing functions through other functions.  Here is an example of an infix-style `+` in any C-style language:

`+(1,1);`

Here is the same expression in a stack-based concatenative language:

`1 1 +`

Not much is shown here, both expressions convey the same thing in similar ways.  However, consider these two:

`+(+(1,1),2);`

`1 1 + 2 +`

Here is where it is a bit different.  The two are still exactly the same, but in the first one, it is shown as the addition of the addition of 1 and 1 with 2.  The concatenative one is different.  In terms of a stack-based language, it is essentially pushing two 1's, adding them, pushing the result, and then adding two and that result.  The example does not fully show the capability of concatenative languages, and it is difficult to show it.

## About the language

### Hello world

Of course, the most simple example of a program in most languages is the "Hello, world!" proram.  Here it is in ULCL:

```
'stdio in-ffi
"hello, world!\n" printf
```

The example has two function calls.  First, the *symbol* (essentially acts as a literal identifier), "stdio" is pushed, and the 'in-ffi' function is called on it.  'in-ffi' simple imports whatever C-library is given to it as a parameter.  Then, the "hello, world~\n" string is pushed, and the 'printf' function from stdtio is called on it.

### Partial application

Here is an example of adding two numbers:

```
import 'prelude
1 1 +
```

(prelude is basically the standard library)

The expression, '1 1 +', works just as it should, pushing two '1's and then '+'.  However, take a look at the 'import' function.  'import' is exactly the same as 'in-ffi' in how many parameters it takes, though here, the parameters is pushed after the function call.  This is where the *partial application* comes in.  Look at these other examples of addition:

```
1 1 +
1 + 1
+ 1 1
```

All three examples are exactly the same.  However, the difference is in where the '+' is placed.  Partial application is the idea of applying a function to only a few of its arguments, instead of only applying it to all of them.  The first expression works as expected, but the second one a bit differently.  

In the second expression, '1' is pushed.  '+' is called, but '+' only has 1 argument to work with.  Because of this, '(+ 1)' is pushed to the stack.  This essentially means that the '+' function along with one of its arguments, '1', is pushed to the stack.  Once the second '1' is pushed to the stack, it is taken by the '+' function, and it evaulates to '2', as it should.

The third is similar; '(+)' is pushed, then the first '1', adding it to the '+' function, making it '(+ 1)', then the second '1' is pushed, making '+' evaulate its arguments, pushing '2'.

The concept of partial application is the main difference between ULCL and other stack-based languages.  By using partial application, the user can call a function however they want.

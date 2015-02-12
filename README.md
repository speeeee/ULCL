ULCL - A stack-based language based on partial application
====

#What is it?

ULCL is a *stack-based concatenative* language based on *partial application*.  The language uses the stack and partial application to make it so that you can call functions however you want.  Parenthesized, and braced expressions also contribute to how you call functions.

#Why is it?

The point of the language is to be readable.  By use of partial application, the user may write `1 + 1' instead of `1 1 +' as seen in normal stack-based languages.  Of course, this also means that code can be as unreadable as possible by orienting the function calls in obscure ways, but hopefully that will not happen...

#What is it made in?

ULCL is made in Racket.  It is a bit different than how languages are normally handled in Racket, but that is because of some early-on decisions.  The language compiles to C.  It is also possible to easily import the C standard library directly in the code.

#Documentation

Documentation is in DOCS.md.  The documentation is unfinished as of now, but will be improved in the future.

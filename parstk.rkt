#lang racket/base
(require "parapp.rkt"
         racket/list
         racket/string)

;NOTE: the source code isn't anything special.

;typedef struct val { char *v; int t; struct val *lst; } val;
;possibly linked-list?

;important corner-case: { { 1 } + { 2 } } will parse the function within
;                     : the braces even though it shouldn't.  Fix it.

;make exec which takes a list and process what's in it like an expression.

;NOTE: sorry about the global stack; I'm trying to keep the program as pure as
;      possible, but I made this to make it a bit easier to implement.
;USE: expressions are pushed into this stack, where they will stay until they
;     are popped to be used in another expression; it's to keep the stack
;     outside of the compiled program.
(define stk* '())
(define (push! s) (set! stk* (push stk* s)))
(define (pop!) (if (empty? stk*) '()
                   (let ([x (pop stk*)])
                     (set! stk* (ret-pop stk*)) 
                     x)))

(define funs* (list (list "+" '("X" "Y") (list (list "&" 'ret)))
                    (list ":" '("name" "params" "output" "def") (list (list "$" 'spec)))
                    (list "eval" '("a") '())
                    (list "%OUT" '("a") '())))

;(define cla (current-command-line-arguments))

; TODO: make a push-n~
(define (push-n~ stk lst)
  (if (empty? lst) stk (push-n~ (push~ stk (car lst)) (cdr lst))))

(define st '())
(set! st (push-n st (list (list "2" 'lit) (list "1" 'lit) (list "+" 'id))))

(define (add-up stk)
  (foldr + 0 (map (λ (x) (cond [(equal? (second x) 'lit) 1]
                               [(equal? (second x) 'id)
                                (let ([f (find-fun (car x) funs*)])
                                  (- (length (third f)) (length (second f))))]
                               [(list? (car x)) (add-up x)]
                               [else 0])) stk)))

(define (out-rkt f)
  (cond [(string=? (caar f) ":")
         (let* ([a (car (cdr f))] [b (if (equal? (second (first (cdr (second (cdr f))))) 'temp)
                                        '() (cdr (second (cdr f))))] 
                                  [d (filter (λ (x) (not (equal? x (list "~" 'temp)))) (cdr (third (cdr f))))]
                                  [c (if (equal? b '()) (cdr (fourth (cdr f)))
                                         (append (cdr (second (cdr f))) (cdr (fourth (cdr f)))))])
           (set! funs* (push funs* (list (caar (cdr f)) b 
                                         (make-list (length d) (list "&" 'ret)))))
           (fprintf (current-output-port) "(define (~a " (caar (cdr f)))
           (map (λ (x) (fprintf (current-output-port) "~a " x)) (map car b))
           (fprintf (current-output-port) ")~n   " )
           (process-line (map (λ (x) (if (and (equal? (second x) 'lit) (equal? (second (lex (car x))) 'id)) 
                                         (list->string (append (list #\') (string->list (car x)))) (car x))) c) '()) 
           (fprintf (current-output-port) (pop!)) (fprintf (current-output-port) ")~n"))]
        [(string=? (caar f) "eval")
         (let ([e (cdr (second f))])
           (process-line (map car e) '()))]
        [(string=? (caar f) "%OUT")
         (let ([e (cdar (second f))])
           (fprintf (current-output-port) (car e)))]
        [else (let ([o (open-output-string)])
         (begin (fprintf o "(~a " (caar f))
             (map (lambda (x) (if (and (list? (car x)) (equal? (second (car x)) 'full)) 
                                  (begin (fprintf o "'(")
                                         (map (λ (y) (fprintf o "~a " (car y))) (cdr x))
                                         (fprintf o ") "))
                                  (fprintf o "~a " 
                                           (if (equal? (second x) 'ret) (pop!) (car x))))) (cdr f))
             (fprintf o ")~n") (push! (get-output-string o))))]))
(define (out-c f) ; same as out-rkt but prints C instead; will probably take out
                  ; out-rkt all together once I can effectively print C.
  (cond [(string=? (caar f) ":")
         (let* ([a (car (cdr f))] [b (if (equal? (second (first (cdr (second (cdr f))))) 'temp)
                                        '() (cdr (second (cdr f))))] 
                                  [d (filter (λ (x) (not (equal? x (list "~" 'temp)))) (cdr (third (cdr f))))]
                                  [c (if (equal? b '()) (cdr (fourth (cdr f)))
                                         (append (map (λ (x) (list (string-join (list "'a" (number->string x)) "") 
                                                                   'lit)) 
                                                      (range 0 (length (cdr (second (cdr f)))))) 
                                                 (cdr (fourth (cdr f)))))])
           (set! funs* (push funs* (list (caar (cdr f)) b 
                                         (make-list (length d) (list "&" 'ret)))))
           (fprintf (current-output-port) "~a ~a(" (if (empty? d) "void" (caar d)) (caar (cdr f)))
           (for ([i (in-range 0 (length b))] [o (map car b)]) 
             (fprintf (current-output-port) "~a a~a, " o i))
           (fprintf (current-output-port) ") {~n   " )
           (process-line (map (λ (x) (if (and (equal? (second x) 'lit) (equal? (second (lex (car x))) 'id)) 
                                         (list->string (append (list #\') (string->list (car x)))) (car x))) c) '()) 
           (fprintf (current-output-port) "~a;~n" (pop!)) (fprintf (current-output-port) "}~n"))]
        [(string=? (caar f) "eval")
         (let ([e (cdr (second f))])
           (process-line (map car e) '()))]
        [(string=? (caar f) "%OUT")
         (let ([e (second f)])
           (fprintf (current-output-port) (car e)))]
        [else (let ([o (open-output-string)])
         (begin (fprintf o "~a(" (caar f))
             (map (lambda (x) (if (and (list? (car x)) (equal? (second (car x)) 'full)) 
                                  (begin (fprintf o "{")
                                         (map (λ (y) (fprintf o "~a, " (car y))) (cdr x))
                                         (fprintf o "} "))
                                  (fprintf o "~a, " 
                                           (if (equal? (second x) 'ret) (pop!) (car x))))) (cdr f))
             (fprintf o ")") (push! (get-output-string o))))]))
(define (test-full e)
  (if (full-cons? (pop e))
      (if (string=? (caar (pop e)) "eval")
          (let ([g (cdr (second (pop e)))])
            (process-line (map car g) '()))
          (begin (out-c (pop e))
                 (push-n (ret-pop e) (third (car (pop e))))))
      e))

(define (lst? s) (and (list? s) (not (empty? s)) (equal? (car s) '("$" full))))

(define (push~ stk s) ;NEXT: fix embedded array issue.
  (cond [(and (not (empty? stk)) (not (empty? (pop stk))) (list? (car (pop stk))) (or (not (equal? (second s) 'lclos)) (> (caar (pop stk)) 0))
              (list? (car (pop stk))) (equal? (cadar (pop stk)) 'prog))
         (if (or (equal? (second s) 'lopen) (equal? (second s) 'lclos))
             (push (ret-pop stk) 
                   (push (append (list (list (+ (caar (pop stk)) (if (equal? (second s) 'lopen) 1 -1)) 'prog)) (cdr (pop stk))) s))
             (push (ret-pop stk) (push (pop stk) s)))]
        [(equal? (second s) 'open) 
         (if (and (not (empty? stk)) (list? (car (pop stk))) (equal? (cadar (pop stk)) 'prog)) 
                                     (push stk s) (push stk '()))]
        [(equal? (second s) 'lopen) (push stk '((0 prog)))]
        [(equal? (second s) 'lclos) 
         (if (< (length (pop stk)) 2) (push~ (ret-pop stk) (list '("$" full) '("~" temp)))
             (push~ (ret-pop stk) (cons '("$" full) (cdr (pop stk)))))]
        [(equal? (second s) 'close) 
         (if (equal? (cadar (pop stk)) 'prog)
            (push (ret-pop stk) (push (pop stk) s)) 
            (push-n~ (ret-pop stk) (process-line (if (list? (car (pop stk))) (pop stk) (map car (pop stk))) '())))]
        [(and (not (empty? stk)) (or (empty? (pop stk)) (and (list? (car (pop stk))) (not (equal? (second (car (pop stk))) 'full)))) 
              (not (fcons? (pop stk) funs*)))
         (push (ret-pop stk) (push (pop stk) s))] ; the list case
        [(and (not (empty? stk)) (fcons? (pop stk) funs*) (not (full-cons? (pop stk))))
         (let ([e (push (ret-pop stk) (push (pop stk) s))])
           (test-full e))] ; function test
        [(equal? (second s) 'lit) (push stk s)]
        [(equal? (second s) 'id) 
         (let ([e (push-cons (push stk s) funs*)])
           (test-full e))]
        [else (push stk s)]))

(define (process-line s stk)
  (if (empty? s) stk (process-line (cdr s) (push~ stk (lex (car s))))))


(define (tok str lst)
  (if (empty? str) (list (list->string lst) "")
    (let ([c (car str)])
      (if (and (not (empty? lst)) (equal? (car lst) #\"))
          (if (equal? c #\") (list (list->string (append lst (list c))) (list->string (cdr str)))
              (tok (cdr str) (append lst (list c))))
          (if (or (char-whitespace? c)) (if (empty? lst) (tok (cdr str) lst) (list (list->string lst) (list->string str)))
              (tok (cdr str) (append lst (list c))))))))
; make another string-split referencing read-char.
(define (string-split-spec str)
  (splt str '()))
(define (splt str lst)
  (if (empty? (string->list str)) lst
      (splt (cadr (tok (string->list str) '())) (append lst (list (car (tok (string->list str) '())))))))

(define (main)
  (write (process-line (string-split-spec (read-line)) '()))
  (fprintf (current-output-port) (if (empty? stk*) "\n" (string-join (list (pop!) ";~n") "")))
  (main))

(define (main-2+ cla)
  (let ([i (open-input-file cla)])
    (define (per-line stk) (let ([x (read-line i)])
      (if (eof-object? x) stk
          (per-line (process-line (string-split-spec x) stk)))))
    (per-line '())))
(define (main-2)
  (main-2+ (car (vector->list (current-command-line-arguments))))
  (fprintf (current-output-port) (if (empty? stk*) "\n" (string-join (list (pop!) ";~n") ""))))

(main-2)
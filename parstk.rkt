#lang racket/base
(require "parapp.rkt"
         racket/list
         racket/string
         racket/dict)

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
;USE: line number
(define ln* 0)
(define (push! s) (set! stk* (push stk* s)))
(define (pop!) (if (empty? stk*) '()
                   (let ([x (pop stk*)])
                     (set! stk* (ret-pop stk*)) 
                     x)))

(define funs* (list (list ":" '("name" "params" "output" "def") '())
                    (list "<<" '("val" "type" "name") '())
                    (list "eval" '("a") '())
                    (list "%OUT" '("a") '())
                    (list "%RET" '() '())
                    (list "if" '("a" "b" "c") '())
                    (list "in-ffi" '("a") '())
                    (list "import" '("a") '())
                    (list "%err" '("str") '())))

;(define cla (current-command-line-arguments))

(define f* '())
(define uf* '())
(define h* '())

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

(define (taken ls)
  (define (taken$ lst nlst e)
    (cond [(or (equal? (cadar lst) 'open)
               (equal? (cadar lst) 'lopen)) (taken$ (cdr lst) nlst (add1 e))]
          [(or (equal? (cadar lst) 'close) 
               (equal? (cadar lst) 'lclos)) (taken$ (cdr lst) nlst (sub1 e))]
          [(equal? (cadar lst) 'id) (if (= e 0) nlst
                                        (taken$ (cdr lst) (push nlst (car lst)) (add1 e)))]
          [else (taken$ (cdr lst) (push nlst (car lst)) (add1 e))]))
  (taken$ ls '() 0))

(define (add-return lst)
  (let ([c (taken (reverse lst))]) 
    (append (take lst (- (length lst) (length c))) (list (list "%RET" 'id)) (drop lst (- (length lst) (length c))))))

(define (out-rkt f)
  (cond [(string=? (caar f) ":")
         (let* ([a (car (cdr f))] [b (if (equal? (second (first (cdr (second (cdr f))))) 'temp)
                                        '() (cdr (second (cdr f))))] 
                                  [d (filter (λ (x) (not (equal? x (list "~" 'temp)))) (cdr (third (cdr f))))]
                                  [c (if (equal? b '()) (cdr (fourth (cdr f)))
                                         (append (cdr (second (cdr f))) (cdr (fourth (cdr f)))))])
           (set! funs* (push funs* (list (caar (cdr f)) b 
                                         (make-list (length d) (list "&" 'ret)))))
           (fprintf uf* (car (pop funs*))) (fprintf uf* " {+ ")
           (map (λ (x) (fprintf uf* "~a " x)) (second (pop funs*))) (fprintf uf* "+} {- ")
           (map (λ (x) (fprintf uf* "~a " x)) (third (pop funs*))) (fprintf uf* "-}~n")
           (fprintf f* "(define (~a " (caar (cdr f)))
           (map (λ (x) (fprintf f* "~a " x)) (map car b))
           (fprintf f* ")~n   " )
           (process-line (map (λ (x) (if (and (equal? (second x) 'lit) (equal? (second (lex (car x))) 'id)) 
                                         (list->string (append (list #\') (string->list (car x)))) (car x))) c) '()) 
           (fprintf f* (pop!)) (fprintf f* ")~n"))]
        [(string=? (caar f) "eval")
         (let ([e (cdr (second f))])
           (process-line (map car e) '()))]
        [(string=? (caar f) "%OUT")
         (let ([e (cdar (second f))])
           (fprintf f* (car e)))]
        [else (let ([o (open-output-string)])
         (begin (fprintf o "(~a " (caar f))
             (map (lambda (x) (if (and (list? (car x)) (equal? (second (car x)) 'full)) 
                                  (begin (fprintf o "'(")
                                         (map (λ (y) (fprintf o "~a " (car y))) (cdr x))
                                         (fprintf o ") "))
                                  (fprintf o "~a " 
                                           (if (equal? (second x) 'ret) (polish (pop!)) (car x))))) (cdr f))
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
                                                 (cdr (fourth (cdr f)))))]
                                  [e (add-return c)])
           (set! funs* (push funs* (list (caar (cdr f)) b 
                                         (make-list (length d) (list "&" 'ret)))))
           (fprintf uf* (car (pop funs*))) (fprintf uf* " {+ ")
           (map (λ (x) (fprintf uf* "~a " x)) (map car (second (pop funs*)))) (fprintf uf* "+} {- ")
           (map (λ (x) (fprintf uf* "~a " x)) (map car d)) (fprintf uf* "-}~n")
           (fprintf f* "~a ~a(" (if (empty? d) "void" (caar d)) (polish (caar (cdr f))))
           (for ([i (in-range 0 (- (length b) 1))] [o (map car b)]) 
             (fprintf f* "~a a~a, " o i))
           (if (empty? b) (fprintf f* ") {~n")
               (fprintf f* "~a a~a) {~n" (car (last b)) (- (length b) 1)))
           (process-line (map (λ (x) (if (and (equal? (second x) 'lit) (equal? (second (lex (car x))) 'id)) 
                                         (list->string (append (list #\') (string->list (car x)))) (car x))) e) '())
           (let ([lst (stk->list! '())])
             (map (λ (x) (fprintf f* "  ~a;~n" x)) lst))
           (fprintf f* "; }~n"))]
        [(string=? (caar f) "eval")
         (let ([e (cdr (second f))])
           (process-line (map car e) '()))]
        [(string=? (caar f) "<<")
         (fprintf f* "~a ~a = ~a;~n" (caaddr f) (car (cadddr f)) (caadr f))]
        [(string=? (caar f) "%OUT")
         (let ([e (second f)])
           (fprintf f* (if (char=? (car (string->list (car e))) #\") (list->string (cdr (ret-pop (string->list (car e)))))
                           (car e))))]
        [(string=? (caar f) "%RET")
         (fprintf f* "return ")]
        [(string=? (caar f) "in-ffi")
         (let ([e (second f)])
           (fprintf f* "#include <~a.h>~n" (car e))
           (fprintf h* "#include <~a.h>~n" (car e))
           (imp (open-input-file (string-join (list (car e) ".ufns") ""))))]
        [(string=? (caar f) "import")
         (let ([e (second f)])
           (fprintf f* "#include \"~a.h\"~n" (car e))
           (fprintf h* "#include \"~a.h\"~n" (car e))
           (imp (open-input-file (string-join (list (car e) ".ufns") ""))))]
        [(string=? (caar f) "if")
         (let ([a (cdr (second f))] [b (cdr (third f))] [c (cdr (fourth f))])
           (map (λ (x) (process-line (map car x) '())) (list a b c))
           (fprintf f* "if(~a) {~n  ~a;~n}~nelse {~n  ~a;~n}~n"
                    (polish (pop!)) (polish (pop!)) (polish (pop!))))]
        [(string=? (caar f) "%err")
         (fprintf (current-output-port) "ERROR:~a: ~a~n" ln* (list->string (cdr (ret-pop (string->list (car (second f)))))))]
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
         (let ([e (if (fexists? (car s) funs*) (push-cons (push stk s) funs*) '())])
           (if (empty? e) (begin (fprintf (current-output-port) "ERROR:~a: function `~a' does not exist.~n" ln* (car s))
                                 stk)
               (test-full e)))]
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

(define (polish str)
  (let ([s (filter (λ (x) (not (equal? x #\space))) (string->list str))])
    (define (remove-commas i o)
      (if (empty? i) o (if (= (length i) 1) (append o (list (car i)))
          (if (and (equal? (car i) #\,) (equal? (second i) #\))) (remove-commas (cdr i) o)
              (remove-commas (cdr i) (append o (list (car i))))))))
    (define (change-ops i o)
      (let ([test-op (case (car i) [(#\+) (list #\a #\d #\d)]
                                     [(#\-) (list #\s #\u #\b)]
                                     [(#\*) (list #\t #\i)] [(#\/) (list #\d #\i #\v)]
                                     [else (list (car i))])])
        (if (empty? i) o 
            (if (= (length i) 1) (append o test-op) (change-ops (cdr i) (append o test-op))))))
    (list->string (change-ops (remove-commas s '()) '()))))

(define (imp f)
  (let* ([e (read-line f)]
         [s (string-split (if (eof-object? e) "" e))] [in (if (not (empty? s)) 
                                                              (takef (cddr s) (λ (x) (not (string=? x "+}"))))
                                                              '())]
         [out (if (not (empty? s)) (takef (drop s (+ (length in) 4)) (λ (x) (not (string=? x "-}")))) '())])
    (if (empty? s) '()
        (begin (set! funs* (push funs* (list (car s) (map (λ (x) (append (list x) (list 'lit))) in) 
                                                     (map (λ (x) (append (list x) (list 'ret))) out))))
               (imp f)))))
   
(define (stk->list! stk)
  (if (empty? stk*) (reverse stk) (stk->list! (append stk (list (polish (pop!))))))) 

(define (main)
  (write (process-line (string-split-spec (read-line)) '()))
  (fprintf f* (if (empty? stk*) "\n" 
                                     (string-join (list (pop!) ";~n") "")))
  (main))

(define (main-2+ cla)
  (let ([i (open-input-file cla)])
    (define (per-line stk) (let ([x (read-line i)]) (set! ln* (add1 ln*))
      (if (eof-object? x) stk
          (per-line (process-line (string-split-spec x) stk)))))
    (per-line '())))
(define (main-2) (let* ([c (vector->list (current-command-line-arguments))])
  (set! f* (if (empty? c) '() (open-output-file (string-join (list (car c) ".c") "") #:exists 'replace)))
  (set! uf* (if (empty? c) '() (open-output-file (string-join (list (car c) ".ufns") "") #:exists 'replace)))
  (set! h* (if (empty? c) '() (open-output-file (string-join (list (car c) ".h") "") #:exists 'replace)))
  (main-2+ (if (empty? c) (string-join (list (path->string (current-directory)) "test.ulcl") "") (string-join (list (car c) ".ulcl") "")))
  (let ([lst (stk->list! '())])
    (map (λ (x) (fprintf f* (string-join (list x ";~n") ""))) lst)
    (fprintf f* "~n"))
  (close-output-port f*) (close-output-port uf*)
  (make-h (if (empty? c) '() 
              (open-input-file (string-join (list (car c) ".ufns") ""))))
  (close-output-port h*)))

(define (make-h f)
  (let* ([e (read-line f)] [s (if (not (eof-object? e)) (string-split e) '())]
                            [in (if (not (empty? s)) 
                                    (takef (cddr s) (λ (x) (not (string=? x "+}"))))
                                    '())]
         [out (if (not (empty? s)) (takef (drop s (+ (length in) 4)) (λ (x) (not (string=? x "-}")))) '())])
    (if (empty? s) '()
        (begin (fprintf h* "~a ~a(" (car out) (polish (car s)))
               (for ([i (in-range 0 (- (length in) 1))] [o in]) 
                 (fprintf h* "~a a~a, " o i))
               (if (empty? in) (fprintf h* ");~n")
                   (fprintf h* "~a a~a);~n" (last in) (- (length in) 1)))
               (make-h f)))))
            
    
(main-2)
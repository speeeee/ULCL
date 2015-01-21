#lang racket
(require racket/list)
(provide push pop ret-pop pop-n
         push-n lex get-tok find-fun
         cons-fun push-cons fcons? 
         full-cons? exec-cons fexists?)

; stack-based cell-based(?) partial application-based language

(define funs* (list (list "+" '(X Y) (list (list "out" 'id)))))
; (name (parameters) (predicate))

(define (push stk elt) (append stk (list elt)))
(define (pop stk) (car (reverse stk)))
(define (ret-pop stk) (reverse (cdr (reverse stk))))
(define (pop-n stk n) (list (take stk (- (length stk) n)) (drop stk (- (length stk) n))))
(define (push-n stk elts) (append stk elts))

(define (lex x) 
  (cond [(list? x) x]
        [(char-numeric? (string-ref x 0)) (list x 'lit)]
        [(equal? (string-ref x 0) #\~) (list x 'temp)]
        [(equal? (string-ref x 0) #\#) (list (string-ref x 1) 'lit)]
        [(equal? (string-ref x 0) #\") (list x 'lit)]
        [(or (equal? (string-ref x 0) #\()) (list x 'open)]
        [(equal? (string-ref x 0) #\{) (list x 'lopen)]
        [(equal? (string-ref x 0) #\)) (list x 'close)]
        [(equal? (string-ref x 0) #\}) (list x 'lclos)]
        [(equal? (string-ref x 0) #\&) (list x 'ret)]
        [(equal? (string-ref x 0) #\') (list (list->string (cdr (string->list x))) 'lit)]
        [else (list x 'id)]))

(define (*get-tok* f lst) 
  (let ([c (read-char f)]) (displayln c)
    (if (and (not (empty? lst)) (equal? (first lst) #\"))
        (if (equal? c #\") (string lst) (*get-tok* f (append lst (list c))))
        (if (or (equal? c #\space) (equal? c eof)) (string lst) 
            (*get-tok* f (append lst (list c)))))))
(define (get-tok f) (lex (string (*get-tok* f '()))))

(define (find-fun s fs)
  (car (filter (lambda (x) (string=? s (car x))) fs)))
(define (cons-fun stk fs)
  (let ([f (find-fun (car (pop stk)) fs)])
    (append (list f) 
            (if (< (- (length stk) 1) (length (second f))) (ret-pop stk)
                (second (pop-n (ret-pop stk) (length (second f))))))))
(define (push-cons stk fs)
  (let ([f (find-fun (car (pop stk)) fs)] [g (cons-fun stk fs)])
    (if (< (- (length stk) 1) (length (second f))) (push '() g)
        (push (car (pop-n stk (+ 1 (length (second f))))) g))))
(define (fcons? f fs)
  (and (not (empty? f)) (ormap (lambda (x) (equal? (car f) x)) fs)))
(define (fexists? s fs)
  (ormap (lambda (x) (string=? x s)) (map car fs)))
(define (full-cons? f) (= (length (cdr f)) (length (second (car f)))))
(define (exec-cons stk fs)
  (push-n (push-n (ret-pop (push-cons stk fs)) (cdr (cons-fun stk fs))) (caddar (cons-fun stk fs))))

(define stk '())
(set! stk (push-n stk (list (list "2" 'lit) (list "1" 'lit) (list "+" 'id))))


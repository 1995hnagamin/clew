(use file.util)
(use gauche.sequence)
(use rfc.json)
(use text.html-lite)
(use text.tree)

(define (path->filepath path)
  (format "~A.html" (string-join (reverse path) "__")))

(define (path->string path)
  (string-join (reverse path) "/"))

(define (json->pages path repo jvalue)
  (cond
   ((string? jvalue) (values repo (format "str:~S" jvalue)))
   ((number? jvalue) (values repo (format "num:~D" jvalue)))
   ((symbol? jvalue) (values repo (symbol->string jvalue)))
   ((list? jvalue)
    (let loop ((pairs jvalue) (repo repo) (children '()))
      (if (null? pairs)
          (let* ((lst (apply html:ul (map (lambda (pair)
                                            (html:li (car pair)
                                                     ": "
                                                     (cdr pair)))
                                          (reverse children))))
                 (page (html:body (html:h2 (path->string path)) lst)))
            (values (cons (cons path page) repo)
                    (html:a :href (path->filepath path) "object")))
          (let* ((key (caar pairs))
                 (value (cdar pairs))
                 (path (cons key path)))
            (receive (repo elem) (json->pages path repo value)
                     (loop (cdr pairs)
                           repo
                           (cons (cons key elem) children)))))))
   ((vector? jvalue)
    (let loop ((index 0) (elems (vector->list jvalue)) (repo repo) (children '()))
      (if (null? elems)
          (let* ((lst (apply html:ul (map-with-index (lambda (index elem)
                                                       (html:li index ": " elem))
                                                     (reverse children))))
                 (page (html:body (html:h2 (path->string path)) lst)))
            (values (cons (cons path page) repo)
                    (html:a :href (path->filepath path) "array")))
          (let ((elem (car elems)) (path (cons (number->string index) path)))
            (receive (repo elem) (json->pages path repo elem)
                     (loop (+ index 1)
                           (cdr elems)
                           repo
                           (cons elem children)))))))))

(define (make-pages jvalue)
  (receive (repo _) (json->pages '("json") '() jvalue)
           (map (lambda (pair)
                  (let ((path (path->filepath (car pair)))
                        (page (cdr pair)))
                    (call-with-output-file path
                      (lambda (oport)
                        (display (tree->string page) oport)
                        (display "\n" oport)))))
                repo)))

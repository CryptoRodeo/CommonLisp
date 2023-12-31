;; DB for cds
(defvar *db* nil)

;; Make CD record
(defun make-cd (title artist rating ripped)
  ;; make property list (poor-man's hash map) with cd attributes and values
  (list :title title :artist artist :rating rating :ripped ripped))

;; Method to add CD records to DB
(defun add-record (cd)
  (push cd *db*))

;; Dump DB contents
(defun dump-db ()
  ;; Loop through db contents with loop var cd
  (dolist (cd *db*)
    ;; attribute - colon - 10 column length - attribute - newline
    (format t "~{~a:~10t~a~%~}~%" cd)))

;; read user input
(defun prompt-read (prompt)
  ;; format the input stream with the prompt value
  (format *query-io* "~a: " prompt)
  ;; dont wait for a newline before printing prompt
  (force-output *query-io*)
  ;; return the value from the input stream
  (read-line *query-io*))

;; build CD record using user input
(defun prompt-for-cd ()
  (make-cd
   (prompt-read "Title")
   (prompt-read "Artist")
   (or (parse-integer (prompt-read "Rating") :junk-allowed t) 0)
   (y-or-n-p "Ripped [y/n]: ")))

;; Loop to add CD records until user inputs n or N
(defun add-cds ()
  (loop (add-record (prompt-for-cd))
   (if (not (y-or-n-p "Another? [y/n]: "))
       (return))))

;; export DB values onto a user inputted file
(defun save-db (filename)
  ;; out: name of variable we'll write to filename using the file stream
  ;; specify that we want to write to the file
  ;; overwrite existing file if it already exists
  (with-open-file (file filename
                   :direction :output
                   :if-exists :supersede)
  ;; ensure that variables are set to their standard values
  ;; print out *db* contents onto the file
    (with-standard-io-syntax (print *db* file))))

;; load the DB data from the file specified
(defun load-db (filename)
  (with-open-file (file filename)
    (with-standard-io-syntax
      (setf *db* (read file)))))

;; generic selector function
;; selector-p: function to select cd values
(defun select (selector-fn)
  (remove-if-not selector-fn *db*))

(defun update (selector-fn &key title artist rating (ripped nil ripped-p))
  (setf *db*
        (mapcar
         #'(lambda (row)
             (when (funcall selector-fn row)
               (if title (setf (getf row :title) title))
               (if artist (setf (getf row :artist) artist))
               (if rating (setf (getf row :rating) rating))
               (if ripped-p (setf (getf row :ripped) ripped)))
             row) *db*)))

;; delete db entry
(defun delete-rows (selector-fn)
  (setf *db* (remove-if selector-fn *db*)))

;; generates comparison expressions
(defun make-comparison-expr (field value)
  `(equal (getf cd ,field) ,value))

;; take the elements in the list 'fields'
;; and collect the results generated by make-comparison-expr on each pair
(defun make-comparisons-list (fields)
  (loop while fields
    collecting (make-comparison-expr (pop fields) (pop fields))))

;; returns  CD matching one of the passed keyword values
;;
;; wrap the list returned by make-comparison in and AND inside
;; an anonymous function.
(defmacro where (&rest clauses)
  `#'(lambda (cd) (and ,@(make-comparisons-list clauses))))

;; returns  CD matching one of the passed keyword values
;; original - obsolete (see above)
;; (defun where (&key title artist rating (ripped nil ripped-p))
;;   #'(lambda (cd)
;;       (and
;;        (if title (equal (getf cd :title) title) t)
;;        (if artist (equal (getf cd :artist) artist) t)
;;        (if rating (equal (getf cd :rating) rating) t)
;;        (if ripped-p (equal (getf cd :ripped) ripped) t))))

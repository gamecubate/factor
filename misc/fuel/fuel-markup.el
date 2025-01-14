;;; fuel-markup.el -- printing factor help markup -*- lexical-binding: t -*-

;; Copyright (C) 2009 Jose Antonio Ortega Ruiz
;; See https://factorcode.org/license.txt for BSD license.

;; Author: Jose Antonio Ortega Ruiz <jao@gnu.org>
;; Keywords: languages, fuel, factor
;; Start date: Thu Jan 01, 2009 21:43

;;; Comentary:

;; Utilities for printing Factor's help markup.

;;; Code:

(require 'fuel-eval)
(require 'fuel-base)
(require 'fuel-table)

(require 'button)


;;; Customization:

(defface fuel-font-lock-markup-title '((t (:inherit bold)))
  "article titles in help buffers"
  :group 'fuel-help
  :group 'fuel-faces
  :group 'faces)

(defface fuel-font-lock-markup-heading '((t (:inherit bold)))
  "headlines in help buffers"
  :group 'fuel-help
  :group 'fuel-faces
  :group 'faces)

(defface fuel-font-lock-markup-link '((t (:inherit link)))
  "links to topics in help buffers"
  :group 'fuel-help
  :group 'fuel-faces
  :group 'faces)

(defface fuel-font-lock-markup-emphasis '((t (:inherit italic)))
  "emphasized words in help buffers"
  :group 'fuel-help
  :group 'fuel-faces
  :group 'faces)

(defface fuel-font-lock-markup-strong '((t (:inherit link)))
  "bold words in help buffers"
  :group 'fuel-help
  :group 'fuel-faces
  :group 'faces)


;;; Links:

(defvar-local fuel-markup--follow-link-function 'fuel-markup--echo-link)

(define-button-type 'fuel-markup--button
  'action 'fuel-markup--follow-link
  'face 'fuel-font-lock-markup-link
  'follow-link t)

(defun fuel-markup--follow-link (button)
  (when fuel-markup--follow-link-function
    (funcall fuel-markup--follow-link-function
             (button-get button 'markup-link)
             (button-get button 'markup-label)
             (button-get button 'markup-link-type))))

(defun fuel-markup--echo-link (link label type)
  (message "Link %s pointing to %s named %s" label type link))

(defun fuel-markup--insert-button (label link type)
  (let ((label (format "%s" label))
        (link (if (listp link) link (format "%s" link))))
    (insert-text-button label
                        :type 'fuel-markup--button
                        'markup-link link
                        'markup-label label
                        'markup-link-type type
                        'help-echo (format "%s (%s)" label type))))

(defun fuel-markup--article-title (name)
  (let ((name (if (listp name) (cons :seq name) name)))
    (fuel-eval--retort-result
     (fuel-eval--send/wait `(:fuel* ((,name fuel-get-article-title)) "fuel")))))

(defun fuel-markup--link-at-point ()
  (let ((button (condition-case nil (forward-button 0) (error nil))))
    (when button
      (list (button-get button 'markup-link)
            (button-get button 'markup-label)
            (button-get button 'markup-link-type)))))

(defun fuel-markup--nav-crumbs (e)
  (fuel-markup--links e " > ")
  (newline))

;;; Markup printers:

(defconst fuel-markup--printers
  '(($all-tags . fuel-markup--all-tags)
    ($all-authors . fuel-markup--all-authors)
    ($author . fuel-markup--author)
    ($authors . fuel-markup--authors)
    ($class-description . fuel-markup--class-description)
    ($code . (lambda (e) (fuel-markup--code e t)))
    ($command . fuel-markup--command)
    ($command-map . fuel-markup--null)
    ($complex-shuffle . fuel-markup--complex-shuffle)
    ($contract . fuel-markup--contract)
    ($curious . fuel-markup--curious)
    ($definition . fuel-markup--definition)
    ($description . fuel-markup--description)
    ($doc-path . fuel-markup--doc-path)
    ($emphasis . fuel-markup--emphasis)
    ($error-description . fuel-markup--error-description)
    ($errors . fuel-markup--errors)
    ($example . (lambda (e) (fuel-markup--code e t)))
    ($examples . fuel-markup--examples)
    ($fuel-nav-crumbs . fuel-markup--nav-crumbs)
    ($heading . fuel-markup--heading)
    ($index . fuel-markup--index)
    ($instance . fuel-markup--instance)
    ($io-error . fuel-markup--io-error)
    ($link . fuel-markup--link)
    ($links . (lambda (e) (fuel-markup--links e ", ")))
    ($list . fuel-markup--list)
    ($low-level-note . fuel-markup--low-level-note)
    ($markup-example . fuel-markup--markup-example)
    ($maybe . fuel-markup--maybe)
    ($sequence . fuel-markup--sequence)
    ($methods . fuel-markup--methods)
    ($next-link . (lambda (e) (fuel-markup--prefixed-link "Next:" e)))
    ($nl . fuel-markup--newline)
    ($notes . fuel-markup--notes)
    ($operation . fuel-markup--link)
    ($or . fuel-markup--or)
    ($parsing-note . fuel-markup--parsing-note)
    ($predicate . fuel-markup--predicate)
    ($prettyprinting-note . fuel-markup--prettyprinting-note)
    ($prev-link . (lambda (e) (fuel-markup--prefixed-link "Prev:" e)))
    ($quotation . fuel-markup--quotation)
    ($references . fuel-markup--references)
    ($related . fuel-markup--related)
    ($see . fuel-markup--word-info)
    ($see-also . fuel-markup--see-also)
    ($shuffle . fuel-markup--shuffle)
    ($side-effects . fuel-markup--side-effects)
    ($slot . fuel-markup--snippet)
    ($snippet . fuel-markup--snippet)
    ($strong . fuel-markup--strong)
    ($subheading . fuel-markup--subheading)
    ($subsection . fuel-markup--subsection)
    ($subsections . fuel-markup--subsections)
    ($synopsis . fuel-markup--word-info)
    ($syntax . fuel-markup--syntax)
    ($table . fuel-markup--table)
    ($tag . fuel-markup--tag)
    ($tags . fuel-markup--tags)
    ($unchecked-example . (lambda (e) (fuel-markup--code e t)))
    ($url . fuel-markup--url)
    ($value . fuel-markup--value)
    ($values . fuel-markup--values)
    ($values-x/y . fuel-markup--values-x/y)
    ($var-description . fuel-markup--var-description)
    ($vocab . fuel-markup--vocab)
    ($vocab-link . fuel-markup--vocab-link)
    ($vocab-links . fuel-markup--vocab-links)
    ($vocab-subsection . fuel-markup--vocab-subsection)
    ($warning . fuel-markup--warning)
    (article . fuel-markup--article)
    (describe-words . fuel-markup--describe-words)
    (vocab-list . fuel-markup--vocab-list)))

(defvar-local fuel-markup--maybe-nl nil)

(defun fuel-markup--print (e)
  (cond ((null e) (insert "f"))
        ((stringp e) (fuel-markup--insert-string e))
        ((and (listp e) (symbolp (car e))
              (assoc (car e) fuel-markup--printers))
         (funcall (alist-get (car e) fuel-markup--printers) e))
        ((and (symbolp e)
              (assoc e fuel-markup--printers))
         (funcall (alist-get e fuel-markup--printers) e))
        ((listp e) (mapc 'fuel-markup--print e))
        ((symbolp e) (fuel-markup--print (list '$link e)))
        (t (insert (format "\n%S\n" e)))))

(defun fuel-markup--print-str (e)
  (with-temp-buffer
    (fuel-markup--print e)
    (buffer-string)))

(defun fuel-markup--maybe-nl ()
  (setq fuel-markup--maybe-nl (point)))

(defun fuel-markup--insert-newline (&optional justification nosqueeze)
  (fill-region (save-excursion (beginning-of-line) (point))
               (point)
               (or justification 'left)
               nosqueeze)
  (newline))

(defsubst fuel-markup--insert-nl-if-nb (&optional no-fill)
  (unless (eq (save-excursion (beginning-of-line) (point)) (point))
    (if no-fill (newline) (fuel-markup--insert-newline))))

(defsubst fuel-markup--put-face (txt face)
  (put-text-property 0 (length txt) 'font-lock-face face txt)
  txt)

(defun fuel-markup--insert-heading (txt &optional no-nl)
  (fuel-markup--insert-nl-if-nb)
  (delete-blank-lines)
  (unless (bobp) (newline))
  (fuel-markup--put-face txt 'fuel-font-lock-markup-heading)
  (fuel-markup--insert-string txt)
  (unless no-nl (newline)))

(defun fuel-markup--insert-string (str)
  (when fuel-markup--maybe-nl
    (newline 2)
    (setq fuel-markup--maybe-nl nil))
  (insert str))

(defun fuel-markup--article (e)
  (setq fuel-markup--maybe-nl nil)
  (insert (fuel-markup--put-face (cadr e) 'fuel-font-lock-markup-title))
  (newline 1)
  (fuel-markup--print (car (cddr e))))

(defun fuel-markup--heading (e)
  (fuel-markup--insert-heading (cadr e)))

(defun fuel-markup--subheading (e)
  (fuel-markup--insert-heading (cadr e)))

(defun fuel-markup--subsection (e)
  (fuel-markup--insert-nl-if-nb)
  (insert "  - ")
  (fuel-markup--link (cons '$link (cdr e)))
  (fuel-markup--maybe-nl))

(defun fuel-markup--subsections (e)
  (dolist (link (cdr e))
    (fuel-markup--insert-nl-if-nb)
    (insert "  - ")
    (fuel-markup--link (list '$link link))
    (fuel-markup--maybe-nl)))

(defun fuel-markup--vocab-subsection (e)
  (fuel-markup--insert-nl-if-nb)
  (insert "  - ")
  (fuel-markup--vocab-link (cons '$vocab-link (cdr e)))
  (fuel-markup--maybe-nl))

(defun fuel-markup--newline (e)
  (fuel-markup--insert-newline)
  (newline))

(defun fuel-markup--doc-path (e)
  (fuel-markup--insert-heading "Related topics")
  (insert "  ")
  (dolist (art (cdr e))
    (fuel-markup--insert-button (car art) (cadr art) 'article)
    (insert ", "))
  (delete-char -2)
  (fuel-markup--insert-newline 'left))

(defun fuel-markup--emphasis (e)
  (when (stringp (cadr e))
    (fuel-markup--put-face (cadr e) 'fuel-font-lock-markup-emphasis)
    (insert (cadr e))))

(defun fuel-markup--strong (e)
  (when (stringp (cadr e))
    (fuel-markup--put-face (cadr e) 'fuel-font-lock-markup-strong)
    (insert (cadr e))))

(define-button-type 'fuel-markup--url
  'action 'fuel-markup--follow-url
  'face 'fuel-font-lock-markup-link
  'follow-link nil)

(defun fuel-markup--follow-url (button)
  (browse-url (button-get button 'markup-link)))

(defun fuel-markup--url (e)
  (let ((url (cadr e)))
    (insert-text-button url
                        :type 'fuel-markup--url
                        'markup-link url)))

(defun fuel-markup--snippet (e)
  (insert (mapconcat #'(lambda (s)
                        (if (stringp s)
                            (factor-font-lock-string s)
                          (fuel-markup--print-str s)))
                     (cdr e)
                     " ")))

(defun fuel-markup--code (e indent)
  (fuel-markup--insert-nl-if-nb)
  (newline)
  (dolist (snip (cdr e))
    (unless (stringp snip)
      (error "snip is not a string"))
    (dolist (line (split-string (factor-font-lock-string snip) "\n"))
      (when indent (insert "    "))
      (insert line)
      (newline)))
  (newline))

(defun fuel-markup--command (e)
  (fuel-markup--snippet (list '$snippet (nth 3 e))))

(defun fuel-markup--syntax (e)
  (fuel-markup--insert-heading "Syntax")
  (fuel-markup--print (cons '$code (cdr e)))
  (newline))

(defun fuel-markup--markup-example (e)
  (fuel-markup--insert-newline)
  (fuel-markup--snippet (cons '$snippet (cdr e))))

(defun fuel-markup--link (e)
  (let* ((link (or (nth 1 e) 'f))
         (type (or (nth 3 e) (if (symbolp link) 'word 'article)))
         (label (or (nth 2 e)
                    (and (eq type 'article)
                         (fuel-markup--article-title link))
                    link)))
    (fuel-markup--insert-button label link type)))

(defun fuel-markup--links (e sep)
  "Inserts a sequence of links. Used for rendering see also lists
and breadcrumb navigation. The items in e can either be strings
or lists."
  (let ((links (cdr e)))
    (when links
      (dolist (link links)
        (message (format "link %s" link))
        (fuel-markup--link
         (if (listp link)
             (cons '$link link)
           (list '$link link)))
        (insert sep))
      (delete-char (- (length sep))))))

(defun fuel-markup--index-quotation (q)
  (cond ((null q) nil)
        ((listp q) (vconcat (mapcar 'fuel-markup--index-quotation q)))
        (t q)))

(defun fuel-markup--index (e)
  (let* ((q (fuel-markup--index-quotation (cadr e)))
         (cmd `(:fuel* ((,q fuel-index)) "fuel"
                       ("assocs" "builtins" "classes" "classes.builtin"
                        "classes.intersection" "classes.predicate"
                        "classes.singleton"  "classes.tuple" "classes.union"
                        "help" "help.topics" "namespaces" "sequences"
                        "vocabs" "words")))
         (subs (fuel-eval--retort-result (fuel-eval--send/wait cmd 200))))
    (when subs
      (let ((start (point))
            (sort-fold-case nil))
        (fuel-markup--print subs)
        (sort-lines nil start (point))))))

(defun fuel-markup--vocab-link (e)
  (fuel-markup--insert-button (cadr e) (or (car (cddr e)) (cadr e)) 'vocab))

(defun fuel-markup--vocab-links (e)
  (dolist (link (cdr e))
    (insert " ")
    (fuel-markup--vocab-link (list '$vocab-link link))
    (insert " ")))

(defun fuel-markup--vocab-list (e)
  (let ((rows (mapcar #'(lambda (elem)
                         (list (list '$vocab-link (car elem))
                               (cadr elem)))
                      (cdr e))))
    (fuel-markup--table (cons '$table rows))))

(defun fuel-markup--vocab (e)
  (fuel-markup--insert-nl-if-nb)
  (let* ((cmd `(:fuel* ((,(cadr e) fuel-vocab-help)) "fuel" t))
         (res (fuel-eval--retort-result (fuel-eval--send/wait cmd))))
    (when res (fuel-markup--print res))))

(defun fuel-markup--parse-classes ()
  (let ((elems))
    (while (looking-at ".+ classes$")
      (let ((heading `($heading ,(match-string-no-properties 0)))
            (rows))
        (forward-line)
        (when (looking-at "Class *.+$")
          (push (split-string (match-string-no-properties 0) nil t) rows)
          (forward-line))
        (while (not (looking-at "$"))
          (let* ((objs (split-string (thing-at-point 'line) nil t))
                 (class (list '$link (car objs) (car objs) 'word))
                 (super (and (cadr objs)
                             (list (list '$link (cadr objs) (cadr objs) 'word))))
                 (slots (when (cddr objs)
                          (list (mapcar #'(lambda (s) (list s " ")) (cddr objs))))))
            (push `(,class ,@super ,@slots) rows))
          (forward-line))
        (push `(,heading ($table ,@(reverse rows))) elems))
      (forward-line))
    (reverse elems)))

(defun fuel-markup--parse-words ()
  (let ((elems))
    (while (looking-at ".+ words\\|Primitives$")
      (let ((heading `($heading ,(match-string-no-properties 0)))
            (rows))
        (forward-line)
        (when (looking-at "Word *\\(Stack effect\\|Syntax\\)$")
          (push (list "Word" (match-string-no-properties 1)) rows)
          (forward-line))
        (while (looking-at " ?\\(.+?\\)\\( +\\(.+\\)\\)?$")
          (let ((word `($link ,(match-string-no-properties 1)
                              ,(match-string-no-properties 1)
                              word))
                (se (and (match-string-no-properties 3)
                         `(($snippet ,(match-string-no-properties 3))))))
            (push `(,word ,@se) rows))
          (forward-line))
        (push `(,heading ($table ,@(reverse rows))) elems))
      (forward-line))
    (reverse elems)))

(defun fuel-markup--parse-words-desc (desc)
  "This function parses the text description of the vocab that
the 'words.' word emits."
  (with-temp-buffer
    (insert desc)
    (goto-char (point-min))
    (when (re-search-forward "^Words$" nil t)
      (forward-line 2)
      (let ((elems '(($heading "Words"))))
        (push (fuel-markup--parse-classes) elems)
        (push (fuel-markup--parse-words) elems)
        (reverse (remove nil elems))))))

(defun fuel-markup--describe-words (e)
  (when (cadr e)
    (fuel-markup--print (fuel-markup--parse-words-desc (cadr e)))))

(defun fuel-markup--tag (e)
  (fuel-markup--link (list '$link (cadr e) (cadr e) 'tag)))

(defun fuel-markup--tags (e)
  (when (cdr e)
    (fuel-markup--insert-heading "Tags: " t)
    (dolist (tag (cdr e))
      (fuel-markup--tag (list '$tag tag))
      (insert ", "))
    (delete-char -2)
    (fuel-markup--insert-newline)))

(defun fuel-markup--all-tags (e)
  (let* ((cmd `(:fuel* (all-tags) "fuel" t))
         (tags (fuel-eval--retort-result (fuel-eval--send/wait cmd))))
    (fuel-markup--list
     (cons '$list (mapcar (lambda (tag) (list '$link tag tag 'tag)) tags)))))

(defun fuel-markup--author (e)
  (fuel-markup--link (list '$link (cadr e) (cadr e) 'author)))

(defun fuel-markup--authors (e)
  (when (cdr e)
    (fuel-markup--insert-heading "Authors: " t)
    (dolist (a (cdr e))
      (fuel-markup--author (list '$author a))
      (insert ", "))
    (delete-char -2)
    (fuel-markup--insert-newline)))

(defun fuel-markup--all-authors (e)
  (let* ((cmd `(:fuel* (all-authors) "fuel" t))
         (authors (fuel-eval--retort-result (fuel-eval--send/wait cmd))))
    (fuel-markup--list
     (cons '$list (mapcar (lambda (a) (list '$link a a 'author)) authors)))))

(defun fuel-markup--complex-shuffle (e)
  (fuel-markup--description
   `($description "Shuffle word. Rearranges the top of the datastack as "
                  "indicated in the stack effect pattern."))
  (fuel-markup--elem-with-heading
   `(nil "The data flow represented by this shuffle word can be more clearly "
         "expressed using " ($vocab-link "Lexical variables" "locals") ".")
   "This word is deprecated"))

(defun fuel-markup--list (e)
  (fuel-markup--insert-nl-if-nb)
  (dolist (elt (cdr e))
    (insert " - ")
    (fuel-markup--print elt)
    (fuel-markup--insert-newline)))

(defun fuel-markup--table (e)
  (fuel-markup--insert-newline)
  (delete-blank-lines)
  (newline)
  (fuel-table--insert
   (mapcar #'(lambda (row) (mapcar 'fuel-markup--print-str row)) (cdr e)))
  (newline))

(defun fuel-markup--instance (e)
  (insert " an instance of ")
  (fuel-markup--print (cadr e)))

(defun fuel-markup--maybe (e)
  (fuel-markup--instance (cons '$instance (cdr e)))
  (insert " or f "))

(defun fuel-markup--sequence (e)
  (insert "a ")
  (fuel-markup--link (list '$link 'sequence 'sequence 'word))
  (insert " of ")
  (fuel-markup--print (cadr e))
  (insert "s"))

(defun fuel-markup--or (e)
  (let ((fst (car (cdr e)))
        (mid (butlast (cddr e)))
        (lst (car (last (cdr e)))))
    (insert (format "%s" fst))
    (dolist (m mid) (insert (format ", %s" m)))
    (insert (format " or %s" lst))))

(defun fuel-markup--values (e)
  (fuel-markup--insert-heading "Inputs and outputs")
  (dolist (val (cdr e))
    (insert " " (car val) " - ")
    (fuel-markup--print (cdr val))
    (newline)))

(defun fuel-markup--predicate (e)
  (fuel-markup--values '($values ("object" object) ("?" "a boolean")))
  (let ((word (make-symbol (substring (format "%s" (cadr e)) 0 -1))))
  (fuel-markup--description
   `($description "Tests if the object is an instance of the "
                  ($link ,word) " class."))))

(defun fuel-markup--side-effects (e)
  (fuel-markup--insert-heading "Side effects")
  (insert "Modifies ")
  (fuel-markup--print (cdr e))
  (fuel-markup--insert-newline))

(defun fuel-markup--definition (e)
  (fuel-markup--insert-heading "Definition")
  (fuel-markup--code (cons '$code (cdr e)) nil))

(defun fuel-markup--methods (e)
  (fuel-markup--insert-heading "Methods")
  (fuel-markup--code (cons '$code (cdr e)) nil))

(defun fuel-markup--value (e)
  (fuel-markup--insert-heading "Variable value")
  (insert "Current value in global namespace: ")
  (fuel-markup--snippet (cons '$snippet (cdr e)))
  (newline))

(defun fuel-markup--values-x/y (e)
  (fuel-markup--values '($values ("x" "number") ("y" "number"))))

(defun fuel-markup--curious (e)
  (fuel-markup--insert-heading "For the curious...")
  (fuel-markup--print (cdr e)))

(defun fuel-markup--references (e)
  (fuel-markup--insert-heading "References")
  (dolist (ref (cdr e))
    (if (listp ref)
        (fuel-markup--print ref)
      (fuel-markup--subsection (list '$subsection ref)))))

(defun fuel-markup--see-also (e)
  (fuel-markup--insert-heading "See also")
  (fuel-markup--links (cons '$links (cdr e)) ", "))

(defun fuel-markup--related (e)
  (fuel-markup--insert-heading "See also")
  (fuel-markup--links (cons '$links (cadr e)) ", "))

(defun fuel-markup--shuffle (e)
  (insert "\nShuffle word. Re-arranges the stack "
          "according to the stack effect pattern.")
  (fuel-markup--insert-newline))

(defun fuel-markup--low-level-note (e)
  (fuel-markup--print '($notes "Calling this word directly is not necessary "
                               "in most cases. "
                               "Higher-level words call it automatically.")))

(defun fuel-markup--parsing-note (e)
  (fuel-markup--insert-nl-if-nb)
  (insert "This word should only be called from parsing words.")
  (fuel-markup--insert-newline))

(defun fuel-markup--io-error (e)
  (fuel-markup--errors '($errors "Throws an error if the I/O operation fails.")))

(defun fuel-markup--prettyprinting-note (e)
  (fuel-markup--print '($notes ("This word should only be called within the "
                                ($link with-pprint) " combinator."))))

(defun fuel-markup--prefixed-link (prefix e)
  (insert (format "  %s " prefix))
  (fuel-markup--link e)
  (newline))

(defun fuel-markup--elem-with-heading (elem heading)
  (fuel-markup--insert-heading heading)
  (fuel-markup--print (cdr elem))
  (fuel-markup--insert-newline))

(defun fuel-markup--stack-effect (e)
  (let* ((in (mapconcat 'identity (nth 1 e) " "))
         (out (mapconcat 'identity (nth 2 e) " "))
         (str (format "( %s -- %s )" in out)))
    (fuel-markup--snippet (list '$snippet str))))

(defun fuel-markup--quotation (e)
  (insert "a ")
  (fuel-markup--link (list '$link 'quotation 'quotation 'word))
  (insert " with stack effect ")
  (fuel-markup--stack-effect (nth 1 e)))

(defun fuel-markup--warning (e)
  (fuel-markup--elem-with-heading e "Warning"))

(defun fuel-markup--description (e)
  (fuel-markup--elem-with-heading e "Word description"))

(defun fuel-markup--class-description (e)
  (fuel-markup--elem-with-heading e "Class description"))

(defun fuel-markup--error-description (e)
  (fuel-markup--elem-with-heading e "Error description"))

(defun fuel-markup--var-description (e)
  (fuel-markup--elem-with-heading e "Variable description"))

(defun fuel-markup--contract (e)
  (fuel-markup--elem-with-heading e "Generic word contract"))

(defun fuel-markup--errors (e)
  (fuel-markup--elem-with-heading e "Errors"))

(defun fuel-markup--examples (e)
  (fuel-markup--elem-with-heading e "Examples"))

(defun fuel-markup--notes (e)
  (fuel-markup--elem-with-heading e "Notes"))

(defun fuel-markup--word-info (e)
  "Uses the 'see' word to lookup info about a given word. Note
that this function is called in contexts where it is impossible
to guess the correct usings, so a static using list is used."
  (let* ((word (nth 1 e))
         (cmd `(:fuel* ((:quote ,(symbol-name word)) see)
                       "fuel" ("kernel" "lexer" "see" "sequences")))
         (ret (and cmd (fuel-eval--send/wait cmd)))
         (res (and (not (fuel-eval--retort-error ret))
                   (fuel-eval--retort-output ret))))
    (if res
        (fuel-markup--code (list '$code res) nil)
      (fuel-markup--snippet (list '$snippet " " word)))))

(defun fuel-markup--null (e))


(provide 'fuel-markup)

;;; fuel-markup.el ends here

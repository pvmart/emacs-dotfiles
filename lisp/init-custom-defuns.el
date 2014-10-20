;;; package -- summary
;;; Commentary:
;;; Code:

;; -- movement --
(defun move-smart-beginning-of-line ()
  "Move to beginning of line or to beginning of indentation depending on POINT."
  (interactive)
  (if (= (point) (line-beginning-position))
      (back-to-indentation)
    (move-beginning-of-line nil)))

(defun new-line-below ()
  "Make new line bellow current line."
  (interactive)
  (move-end-of-line nil)
  (newline))

;; -- window management --
(defun maximize-window-vertically ()
  "Maximizes the current window vertically the same way vi does."
  (interactive)
  (enlarge-window 180 nil))

(defun minimize-window-vertically ()
  "Minimizes the current window vertically the same way vi does."
  (interactive)
  (shrink-window 180 nil))

(defun vsplit-last-buffer ()
  "Vertically split window showing last buffer."
  (interactive)
  (split-window-vertically)
  (other-window 1 nil)
  (switch-to-next-buffer))

(defun hsplit-last-buffer ()
  "Horizontally split window showing last buffer."
  (interactive)
  (split-window-horizontally)
  (other-window 1 nil)
  (switch-to-next-buffer))

(defun swap-buffers-in-windows ()
  "Put the buffer from the selected window in next window, and vice versa."
  (interactive)
  (let* ((this (selected-window))
	 (other (next-window))
	 (this-buffer (window-buffer this))
	 (other-buffer (window-buffer other)))
    (set-window-buffer other this-buffer)

    (set-window-buffer this other-buffer)))

(defun bury-compile-buffer-p (&optional buffer string)
  "Check if BUFFER must be buried based on STRING."
  (not (string-match "rspec" (buffer-name buffer))))

;; -- compilation utils --
(defun bury-compile-buffer-if-successful (buffer string)
  "Bury a compilation buffer (as BUFFER) if succeeded without warnings (given by STRING argument)."
  (if (and
       (bury-compile-buffer-p buffer string)
       (string-match "compilation" (buffer-name buffer))
       (string-match "finished" string)
       (not (with-current-buffer buffer
	      (goto-char 1)
	      (search-forward "warning" nil t))))
      (run-with-timer
       1
       nil
       (lambda (buf) (if (get-buffer-window buf)
		    (progn (delete-window (get-buffer-window buf))
			   (bury-buffer buf))))
       buffer)))
(add-hook 'compilation-finish-functions 'bury-compile-buffer-if-successful)

;; -- editing utils --
(defun rr-show-file-name ()
  "Show the full path filename in the minibuffer."
  (interactive)
  (message (buffer-file-name))
  (kill-new (file-truename buffer-file-name)))

(defun uniquify-all-lines-region (start end)
  "Find duplicate lines in region START to END keeping first occurrence."
  (interactive "*r")
  (save-excursion
    (let ((end (copy-marker end)))
      (while
	  (progn
	    (goto-char start)
	    (re-search-forward "^\\(.*\\)\n\\(\\(.*\n\\)*\\)\\1\n" end t))
	(replace-match "\\1\n\\2")))))

(defadvice kill-region (before slick-cut activate compile)
  "When called interactively with no active region, kill a single
line instead."
  (interactive
   (if mark-active
       (list (region-beginning) (region-end))
     (list (line-beginning-position) (line-beginning-position 2)))))

(defadvice kill-ring-save (before slick-copy activate compile)
  "When called interactively with no active region, copy a single
line instead."
  (interactive
   (if mark-active
       (list (region-beginning) (region-end))
     (message "Copied line")
     (list (line-beginning-position) (line-beginning-position 2)))))

(defun uniquify-all-lines-buffer ()
  "Delete duplicate lines in buffer and keep first occurrence."
  (interactive "*")
  (uniquify-all-lines-region (point-min) (point-max)))

(defun wrap-region-replace ()
  (interactive)
  (let* ((left-char-to-replace (string (read-char "Which wrapper to replace?")))
	 (new-left-char (string (read-char "Replace by?")))
	 (original-is-wrapper-p (wrap-region-find left-char-to-replace))
	 (new-is-wrapper-p (wrap-region-find new-left-char))

	 (right-char-to-replace (if original-is-wrapper-p
				    (wrap-region-wrapper-right (wrap-region-find left-char-to-replace))
				  left-char-to-replace))
	 (new-right-char (if new-is-wrapper-p
			     (wrap-region-wrapper-right (wrap-region-find new-left-char))
			   new-left-char)))
    (save-excursion
      (re-search-backward left-char-to-replace)
      (forward-sexp)
      (save-excursion
	(replace-match new-left-char))
      (re-search-backward right-char-to-replace)
      (replace-match new-right-char))))

(defun rr-strip-whitespace ()
  (interactive)
  (save-excursion
    (goto-char (point-min))
    (replace-regexp " +" " " nil (point-min) (point-max)))
  (indent-region (point-min) (point-max)))

;; -- misc --
(defun noop () "Does nothing." (interactive) nil)

(defun nxml-pretty-format (begin end)
  "Pretty prints xml"
  (interactive "r")
  (save-excursion
    (shell-command-on-region (point-min) (point-max) "xmllint --format -" (buffer-name) t)
    (indent-region begin end)))

(defun narrow-or-widen-dwim (p)
  "If the buffer is narrowed, it widens. Otherwise, it narrows intelligently.
Intelligently means: region, org-src-block, org-subtree, or defun,
whichever applies first.
Narrowing to org-src-block actually calls `org-edit-src-code'.

With prefix P, don't widen, just narrow even if buffer is already
narrowed."
  (interactive "P")
  (declare (interactive-only))
  (cond ((and (buffer-narrowed-p) (not p))
	 (widen))
	((region-active-p)
	 (narrow-to-region (region-beginning) (region-end)))
	((and (boundp 'org-src-mode) org-src-mode (not p)) ; <-- Added
	 (org-edit-src-exit))
	((derived-mode-p 'org-mode)
	 (cond ((org-in-src-block-p)
		(org-edit-src-code))
	       ((org-at-block-p)
		(org-narrow-to-block))
	       (t (org-narrow-to-subtree))))
	(t (narrow-to-defun))))

(defun insert-lorem ()
  "Insert a lorem ipsum."
  (interactive)
  (insert "Lorem ipsum dolor sit amet, consectetur adipisicing elit, sed do "
	  "eiusmod tempor incididunt ut labore et dolore magna aliqua. Ut enim"
	  "ad minim veniam, quis nostrud exercitation ullamco laboris nisi ut "
	  "aliquip ex ea commodo consequat. Duis aute irure dolor in "
	  "reprehenderit in voluptate velit esse cillum dolore eu fugiat nulla "
	  "pariatur. Excepteur sint occaecat cupidatat non proident, sunt in "
	  "culpa qui officia deserunt mollit anim id est laborum."))

(defun sudo-edit (&optional arg)
  "Edit file as sudo. ARG as point."
  (interactive "p")
  (if (or arg (not buffer-file-name))
      (find-file (concat "/sudo:root@localhost:" (ido-read-file-name "File: ")))
    (find-alternate-file (concat "/sudo:root@localhost:" buffer-file-name))))

(defun eval-and-replace ()
  "Replace the preceding sexp with its value."
  (interactive)
  (if (> (point) (mark))
      (backward-kill-sexp)
    (kill-sexp))
  (condition-case nil
      (prin1 (eval (read (current-kill 0)))
	     (current-buffer))
    (error (message "Invalid expression")
	   (insert (current-kill 0)))))

(defun macroexpand-point (sexp)
  "Expands macro at point/region containing SEXP."
  (interactive (list (sexp-at-point)))
  (with-output-to-temp-buffer "*el-macroexpansion*"
    (pp (macroexpand sexp)))
  (with-current-buffer "*el-macroexpansion*" (emacs-lisp-mode)))

;; Keybindings macros
(defmacro expose-global-keybinding (binding map)
  `(define-key ,map ,binding `,(lookup-key `,(current-global-map) ,binding)))

(defmacro expose-bindings (map bindings)
  `(dolist (bnd ,bindings)
     `,(expose-global-keybinding `,(kbd bnd) ,map)))

;; don't know why, but starter kit added this monkey patch
(defun vc-git-annotate-command (file buf &optional rev)
  (let ((name (file-relative-name file)))
    (vc-git-command buf 0 name "blame" "-w" rev)))

(provide 'init-custom-defuns)
;;; init-custom-defuns.el ends here

;; Add functions to Vi-like behaviors

(defun start-newline-next ()
  (interactive)
  (end-of-line)
  (newline-and-indent))

(defun start-newline-prev ()
  (interactive)
  (if (eq (forward-line -1) 0)
      (start-newline-next)
    (progn
      (message "The first line")
      (beginning-of-line)
      (newline)
      (forward-line -1))))

(global-set-key (kbd "C-o") 'start-newline-next)
(global-set-key (kbd "M-o") 'start-newline-prev)


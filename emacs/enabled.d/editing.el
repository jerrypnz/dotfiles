;; Add functions to Vi-like behaviors

(defun start-newline-next ()
  (interactive)
  (end-of-line)
  (newline-and-indent))

(defun start-newline-prev ()
  (interactive)
  (forward-line -1)
  (start-newline-next))

(global-set-key (kbd "C-o") 'start-newline-next)
(global-set-key (kbd "M-o") 'start-newline-prev)


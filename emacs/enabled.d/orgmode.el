;; Org mode settings
;; The following lines are always needed.  Choose your own keys.
(add-to-list 'auto-mode-alist '("\\.org\\'" . org-mode))
(add-hook 'org-mode-hook 'turn-on-font-lock)

(defvar org-directory "~/org")

(setq org-default-notes-file (concat org-directory "/captures.org"))

(global-set-key "\C-cl" 'org-store-link)
(global-set-key "\C-ca" 'org-agenda)
(global-set-key "\C-cc" 'org-capture)
(global-set-key "\C-cb" 'org-iswitchb)

(add-hook 'rst-mode-hook 'turn-on-orgtbl)

(setq org-capture-templates
      '(("t" "Task" entry (file+headline
                           (concat org-directory "/todos.org")
                           "Tasks")
         "** TODO %?\n%U\n")
        ("n" "Note" entry (file (concat org-directory "/notes.org"))
         "* %<%D> %^{Title} :NOTE:%^G\n%?")))

(setq org-latex-to-pdf-process 
  '("xelatex -interaction nonstopmode %f"
     "xelatex -interaction nonstopmode %f")) ;; for multiple passes


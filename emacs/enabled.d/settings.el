;; Change auto-save dir
(defvar my-backup-dir (concat temporary-file-directory "emacs-backup"))

(setq backup-directory-alist
      `((".*" . ,my-backup-dir)))
(setq auto-save-file-name-transforms
      `((".*" ,my-backup-dir t)))

(if (not (file-accessible-directory-p my-backup-dir))
    (make-directory my-backup-dir))

;; Undo tree
(global-undo-tree-mode)


;; TextMate minor mode
(eval-after-load 'textmate
  '(progn
     (define-key *textmate-mode-map* [(meta return)] nil)))

(textmate-mode)
(add-to-list '*textmate-project-roots* "project.clj")
(add-to-list '*textmate-project-roots* "setup.py")
(add-to-list '*textmate-project-roots* ".ropeproject")


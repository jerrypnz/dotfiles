;; Change auto-save dir
(defvar my-backup-dir (concat temporary-file-directory "emacs-backup"))

(setq backup-directory-alist
      `((".*" . ,my-backup-dir)))
(setq auto-save-file-name-transforms
      `((".*" ,my-backup-dir t)))

(make-directory my-backup-dir)

;; Undo tree
(global-undo-tree-mode)


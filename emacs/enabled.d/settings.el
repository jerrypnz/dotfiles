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

(require 'auto-complete-config)
(ac-config-default)
(setq ac-sources (append ac-sources '(ac-source-yasnippet)))
(add-hook 'python-mode-hook 'ac-ropemacs-setup)

;; nREPL
(setq nrepl-popup-stacktraces nil)
(add-hook 'nrepl-mode-hook 'paredit-mode)

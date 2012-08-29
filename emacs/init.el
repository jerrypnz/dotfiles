(require 'package)
(add-to-list 'package-archives
	     '("marmalade" . "http://marmalade-repo.org/packages/") t)
(add-to-list 'package-archives
	     '("melpa" . "http://melpa.milkbox.net/packages/") t)
(package-initialize)

(when (not package-archive-contents)
  (package-refresh-contents))

(defvar my-packages
  '(starter-kit
    starter-kit-lisp
    starter-kit-eshell
    starter-kit-bindings
    color-theme-solarized
    clojure-mode
    org
    org2blog
    nrepl
    yasnippet
    undo-tree
    expand-region
    ace-jump-mode
    python-mode
    ipython
    pyflakes
    pylint
    pymacs
    pep8))

(dolist (p my-packages)
  (when (not (package-installed-p p))
    (package-install p)))

(mapc 'load (directory-files
             (concat user-emacs-directory "enabled.d")
             t
             "\\.el$"))

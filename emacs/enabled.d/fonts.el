;; Setting English Fonto
(set-face-attribute
  'default nil :font "Ubuntu Mono 12")
 
;; Chinese Font
(dolist (charset '(kana han symbol cjk-misc bopomofo))
    (set-fontset-font (frame-parameter nil 'font)
                      charset
                      (font-spec :family "文泉驿微米黑" :size 13)))

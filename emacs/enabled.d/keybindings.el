;; Buffer and window switching
(global-set-key (kbd "C-,") 'previous-buffer)
(global-set-key (kbd "C-.") 'next-buffer)

;; Find files in current project
(global-set-key (kbd "C-S-r") 'find-file-in-project)

;; Expand-region
(global-set-key (kbd "C-=") 'er/expand-region)

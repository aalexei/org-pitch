(require 'org)

;; Inspired by org-present
(defvar org-pitch-mode-keymap (make-keymap) "org-pitch-mode keymap.")

(define-key org-pitch-mode-keymap [M-right]   'org-pitch-next)
(define-key org-pitch-mode-keymap [M-left]    'org-pitch-prev)
(define-key org-pitch-mode-keymap (kbd "M-q") 'org-pitch-quit)

(defvar org-pitch-text-scale 5)

(define-minor-mode org-pitch-mode
  "Presentation minor mode for org-mode."
  :init-value nil
  :lighter " Pitch"
  :keymap org-pitch-mode-keymap)

(make-variable-buffer-local 'org-pitch-mode)

(defun org-pitch ()
  (interactive)
  (setq org-pitch-mode t)
  (text-scale-increase 0)
  (text-scale-increase org-pitch-text-scale)
  (org-narrow-to-subtree)
  ;; (beginning-of-buffer)
  (goto-char (point-min))
  (org-display-inline-images)
  ;; Set a blank header line string to create blank space at the top
  (setq header-line-format " "))

(defun org-pitch-quit ()
  (interactive)
  (text-scale-increase 0)
  (widen)
  ;; Clear the header line string so that it isn't displayed
  (setq header-line-format nil)
  (setq org-pitch-mode nil))

(defun org-pitch-next ()
  (interactive)
  ;; (beginning-of-buffer)
  (goto-char (point-min))
  (widen)
  (org-forward-heading-same-level 1)
  (org-show-entry)
  (org-show-children)
  (org-narrow-to-subtree))

(defun org-pitch-prev ()
  (interactive)
  ;; (beginning-of-buffer)
  (goto-char (point-min))
  (widen)
  (org-backward-heading-same-level 1)
  (org-show-entry)
  (org-show-children)
  (org-narrow-to-subtree))

(provide 'org-pitch)

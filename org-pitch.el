;;; org-pitch.el --- Present org subtrees -*- lexical-binding: t; -*-

;; Author: Alexei Gilchrist
;; Version: 0.1.0
;; Package-Requires: ((emacs "27.1") (org "9.6"))
;; Keywords: outlines, presentations
;; URL: https://github.com/aalexei/org-pitch

;;; Commentary:

;; org-pitch presents an Org subtree as a simple slide deck.

;;; Code:

(require 'org)

;; Inspired by org-present
(defvar org-pitch-mode-keymap (make-keymap) "org-pitch-mode keymap.")

(define-key org-pitch-mode-keymap [M-right]   'org-pitch-next)
(define-key org-pitch-mode-keymap [M-left]    'org-pitch-prev)
(define-key org-pitch-mode-keymap (kbd "M-q") 'org-pitch-quit)

(defgroup org-pitch nil
  "Present Org subtrees."
  :group 'org)

(defcustom org-pitch-text-scale 5
  "Text scale increase used during org-pitch presentations."
  :type 'integer
  :group 'org-pitch)

(defvar-local org-pitch--root-marker nil
  "Marker for the heading that owns the current org-pitch presentation.")

(defvar-local org-pitch--menu-p nil
  "Non-nil when org-pitch is showing the root heading menu slide.")

(define-minor-mode org-pitch-mode
  "Presentation minor mode for org-mode."
  :init-value nil
  :lighter " Pitch"
  :keymap org-pitch-mode-keymap)

(make-variable-buffer-local 'org-pitch-mode)

(defun org-pitch--goto-root ()
  "Widen and move point to the current org-pitch root heading."
  (unless (and (markerp org-pitch--root-marker)
               (marker-buffer org-pitch--root-marker))
    (user-error "No org-pitch presentation is active"))
  (widen)
  (goto-char org-pitch--root-marker)
  (org-back-to-heading t))

(defun org-pitch--root-end ()
  "Return the end position of the current org-pitch root subtree."
  (save-restriction
    (save-excursion
      (org-pitch--goto-root)
      (org-end-of-subtree t t))))

(defun org-pitch--show-entry ()
  "Show the current Org entry using the available Org folding API."
  (funcall (if (fboundp 'org-fold-show-entry)
               #'org-fold-show-entry
             (intern "org-show-entry"))))

(defun org-pitch--show-children ()
  "Show direct Org child headings using the available Org folding API."
  (funcall (if (fboundp 'org-fold-show-children)
               #'org-fold-show-children
             (intern "org-show-children"))))

(defun org-pitch--show-menu ()
  "Show the expanded root heading with direct children as a collapsed menu."
  (org-pitch--goto-root)
  (org-narrow-to-subtree)
  (goto-char (point-min))
  (org-overview)
  (org-pitch--show-entry)
  (goto-char (point-min))
  (org-pitch--show-children)
  (setq org-pitch--menu-p t)
  (org-display-inline-images))

(defun org-pitch--show-slide ()
  "Show the subtree at point as a slide."
  (org-narrow-to-subtree)
  (goto-char (point-min))
  (org-pitch--show-entry)
  (org-pitch--show-children)
  (setq org-pitch--menu-p nil)
  (org-display-inline-images))

(defun org-pitch ()
  (interactive)
  (org-back-to-heading t)
  (setq org-pitch--root-marker (point-marker))
  (org-pitch-mode 1)
  (text-scale-increase 0)
  (text-scale-increase org-pitch-text-scale)
  ;; Set a blank header line string to create blank space at the top
  (setq header-line-format " ")
  (org-pitch--show-menu))

(defun org-pitch-quit ()
  (interactive)
  (text-scale-increase 0)
  (widen)
  ;; Clear the header line string so that it isn't displayed
  (setq header-line-format nil)
  (when (markerp org-pitch--root-marker)
    (set-marker org-pitch--root-marker nil))
  (setq org-pitch--root-marker nil)
  (setq org-pitch--menu-p nil)
  (org-pitch-mode -1))

(defun org-pitch-next ()
  (interactive)
  (if org-pitch--menu-p
      (progn
        (org-pitch--goto-root)
        (if (org-goto-first-child)
            (org-pitch--show-slide)
          (org-pitch--show-menu)
          (message "No child headings in this org-pitch root")))
    (let ((old (point-min))
          (root-end (org-pitch--root-end))
          (slide-level nil))
      (goto-char old)
      (widen)
      (setq slide-level (org-current-level))
      (org-forward-heading-same-level 1)
      (if (and (> (point) old)
               (< (point) root-end)
               (= (org-current-level) slide-level))
          (org-pitch--show-slide)
        (goto-char old)
        (org-pitch--show-slide)))))

(defun org-pitch-prev ()
  (interactive)
  (if org-pitch--menu-p
      (org-pitch--show-menu)
    (let ((old (point-min))
          (root nil)
          (slide-level nil))
      (setq root (progn
                   (org-pitch--goto-root)
                   (point)))
      (goto-char old)
      (widen)
      (setq slide-level (org-current-level))
      (org-backward-heading-same-level 1)
      (if (and (< root (point))
               (< (point) old)
               (= (org-current-level) slide-level))
          (org-pitch--show-slide)
        (org-pitch--show-menu)))))

(provide 'org-pitch)

;;; org-pitch.el ends here

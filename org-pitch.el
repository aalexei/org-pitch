;;; org-pitch.el --- Present org subtrees -*- lexical-binding: t; -*-

;; Author: Alexei Gilchrist
;; Version: 0.3.0
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
  "Marker for the root of the current org-pitch presentation.")

(defvar-local org-pitch--root-file-p nil
  "Non-nil when the current org-pitch root is the file preamble.")

(defvar-local org-pitch--menu-p nil
  "Non-nil when org-pitch is showing the root heading menu slide.")

(define-minor-mode org-pitch-mode
  "Presentation minor mode for org-mode."
  :init-value nil
  :lighter " Pitch"
  :keymap org-pitch-mode-keymap)

(make-variable-buffer-local 'org-pitch-mode)

(defun org-pitch--goto-root ()
  "Widen and move point to the current org-pitch root."
  (unless (and (markerp org-pitch--root-marker)
               (marker-buffer org-pitch--root-marker))
    (user-error "No org-pitch presentation is active"))
  (widen)
  (goto-char org-pitch--root-marker)
  (unless org-pitch--root-file-p
    (org-back-to-heading t)))

(defun org-pitch--root-end ()
  "Return the end position of the current org-pitch root."
  (save-restriction
    (save-excursion
      (org-pitch--goto-root)
      (if org-pitch--root-file-p
          (point-max)
        (org-end-of-subtree t t)))))

(defun org-pitch--goto-first-file-child ()
  "Move point to the first top-level heading and return non-nil if found."
  (goto-char (point-min))
  (let ((found nil))
    (while (and (not found) (re-search-forward org-heading-regexp nil t))
      (beginning-of-line)
      (if (= (org-current-level) 1)
          (setq found t)
        (forward-line 1)))
    found))

(defun org-pitch--goto-first-child ()
  "Move point to the first direct child of the current org-pitch root."
  (if org-pitch--root-file-p
      (org-pitch--goto-first-file-child)
    (org-goto-first-child)))

(defun org-pitch--first-heading-position ()
  "Return the position of the first Org heading in the visible buffer."
  (save-excursion
    (goto-char (point-min))
    (when (re-search-forward org-heading-regexp nil t)
      (line-beginning-position))))

(defun org-pitch--show-file-preamble ()
  "Show file-level content before the first heading."
  (funcall (if (fboundp 'org-fold-region)
               #'org-fold-region
             (intern "org-flag-region"))
           (point-min)
           (or (org-pitch--first-heading-position) (point-max))
           nil))

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
  (if org-pitch--root-file-p
      (narrow-to-region (point-min) (org-pitch--root-end))
    (org-narrow-to-subtree))
  (goto-char (point-min))
  (org-overview)
  (if org-pitch--root-file-p
      (org-pitch--show-file-preamble)
    (org-pitch--show-entry))
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
  (setq org-pitch--root-file-p (org-before-first-heading-p))
  (if org-pitch--root-file-p
      (goto-char (point-min))
    (org-back-to-heading t))
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
  (setq org-pitch--root-file-p nil)
  (setq org-pitch--menu-p nil)
  (org-pitch-mode -1))

(defun org-pitch-next ()
  (interactive)
  (if org-pitch--menu-p
      (progn
        (org-pitch--goto-root)
        (if (org-pitch--goto-first-child)
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

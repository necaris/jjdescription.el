;;; jjdescription.el --- Major mode for editing Jujutsu description files -*- lexical-binding: t; -*-

;; Author: Rami Chowdhury <rami.chowdhury@gmail.com>
;; URL: https://github.com/necaris/jjdescription.el
;; Version: 0.1
;; Package-Requires: ((emacs "25.1"))

;; SPDX-License-Identifier: Vim

;;; Commentary:
;; Provides syntax highlighting for .jjdescription files used by the `jj' tool,
;; based on the Vim syntax file by Adrià Vilanova.

;;; Code:

(defgroup jjdescription nil
  "Syntax highlighting for `jj' description files."
  :group 'tools
  :group 'vc)

(defcustom jjdescription-summary-length 50
  "Maximum recommended length for the summary line.
If non-positive, no limit check is performed.
Lines exceeding this length will have the remainder highlighted
with `jjdescription-overflow-face'."
  :type 'integer
  :group 'jjdescription)

;;; Faces

(defface jjdescription-summary-face
  '((t :inherit font-lock-keyword-face))
  "Face for the summary line (first line) within the length limit."
  :group 'jjdescription)

(defface jjdescription-overflow-face
  '((t :inherit font-lock-warning-face))
  "Face for the part of the summary line exceeding `jjdescription-summary-length'."
  :group 'jjdescription)

(defface jjdescription-error-face
  '((t :inherit font-lock-warning-face))
  "Face potentially used for errors (like content immediately after summary)."
  :group 'jjdescription)

(defface jjdescription-comment-face
  '((t :inherit font-lock-comment-face))
  "Face for `JJ:' comment lines."
  :group 'jjdescription)

(defface jjdescription-header-face
  '((t :inherit font-lock-doc-face))
  "Face for headers within `JJ:' comment lines (e.g., `Conflicts:')."
  :group 'jjdescription)

(defface jjdescription-type-face
  '((t :inherit font-lock-type-face))
  "Face for change types (C, R, M, A, D) in `JJ:' comment lines."
  :group 'jjdescription)

(defface jjdescription-file-face
  '((t :inherit font-lock-constant-face))
  "Face for filenames in `JJ:' comment lines."
  :group 'jjdescription)

;;; Font-Lock Keywords

(defun jjdescription--match-first-line (limit)
  "Match the first line of the buffer up to LIMIT.
Sets match data: group 1 for text within length limit, group 2 for overflow."
  (when (and (= (point) (point-min)) (< (point) limit))
    (let ((eol (line-end-position))
          (split-pos (when (> jjdescription-summary-length 0)
                       (save-excursion
                         (move-to-column jjdescription-summary-length)
                         (point)))))
      (if (or (not split-pos) (>= split-pos eol))
          (set-match-data (list (point) eol (point) eol))
        (set-match-data (list (point) eol (point) split-pos split-pos eol)))
      (goto-char eol)
      t)))

(defconst jjdescription-font-lock-keywords
  `((jjdescription--match-first-line
     (1 'jjdescription-summary-face prepend t)
     (2 'jjdescription-overflow-face prepend t))
    ("JJ:[[:blank:]]+\\([A-Za-z][-_A-Za-z0-9]*:\\)"
     (beginning-of-line) (end-of-line)
     (1 'jjdescription-header-face prepend t))
    ("[[:blank:]]+\\([CRMAD]\\)\\(.*\\)"
     (beginning-of-line) (end-of-line)
     (1 'jjdescription-type-face prepend t)
     (2 'jjdescription-file-face prepend t))
    ("JJ:.*"
     (beginning-of-line) (end-of-line)
     (0 'jjdescription-comment-face append t)))
  "Font lock keywords for `jjdescription-mode'.")

;;; Major Mode Definition

;;;###autoload
(define-derived-mode jjdescription-mode text-mode "JJDescription"
  "Major mode for editing `jj' description files.
Provides syntax highlighting for summary line, `JJ:' comments,
headers, change types, and filenames.

\\{jjdescription-mode-map}"
  :group 'jjdescription
  (setq-local font-lock-defaults '(jjdescription-font-lock-keywords t))
  (setq-local comment-start "JJ:")
  (setq-local comment-start-skip "^JJ:[ \t]*\\|^JJ:$")
  ;; Enable context-based highlighting needed for the first line rule
  (setq-local jit-lock-contextually t))

;;;###autoload
(add-to-list 'auto-mode-alist '("\\.jjdescription\\'" . jjdescription-mode))

(provide 'jjdescription)

;;; jjdescription.el ends here

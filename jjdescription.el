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
  '((t :inherit font-lock-preprocessor-face))
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

(defun jjdescription--match-first-line ()
  "Highlight the first line as summary.
Will mark characters beyond `jjdescription-summary-length' as overflow. Return
the end position if successful, nil otherwise."
  (when (eq (point-min) (line-beginning-position))
    (let ((end (line-end-position)))
      (when (< (point) end) ; Ensure we are not at the end of the line already
        (goto-char end)
        (let* ((bol (line-beginning-position))
               (line-content (buffer-substring-no-properties bol end))
               ;; Use `string-width` for visual length calculation
               (len (string-width line-content))
               (limit-col (if (and (boundp 'jjdescription-summary-length)
                                   (> jjdescription-summary-length 0))
                              jjdescription-summary-length
                            -1)))
          (if (or (< limit-col 1) (<= len limit-col))
              ;; Whole line is within limit or no limit
              (put-text-property bol end 'face 'jjdescription-summary-face)
            ;; Line exceeds limit, split highlighting
            (let ((split-pos (save-excursion
                               (goto-char bol)
                               (move-to-column limit-col)
                               (point))))
              (put-text-property bol split-pos 'face 'jjdescription-summary-face)
              (put-text-property split-pos end 'face 'jjdescription-overflow-face))))
        ;; Set property to allow next rules to potentially use context
        (put-text-property (point-min) end 'jit-lock-defer-multiline t)
        end)))) ; Return end position

(defun jjdescription--highlight-jj-line (limit)
  "Highlight `JJ:' line and its internal elements, matching up to LIMIT.
Returns the end position if successful, nil otherwise."
  ;; Match the whole line first to ensure context
  (when (re-search-forward "^JJ: .*" limit t)
    (let ((line-start (match-beginning 0))
          (line-end (match-end 0)))
      ;; Apply base comment face to the whole line
      (put-text-property line-start line-end 'face 'jjdescription-comment-face)
      ;; Highlight internal parts (Header or Type/File)
      (save-excursion
        (goto-char line-start)
        ;; Check for Header: "JJ: <non-space-stuff>:"
        (if (re-search-forward "^JJ: +\\(\\S-.*:\\)$" line-end t)
            (put-text-property (match-beginning 1) (match-end 1)
                               'face 'jjdescription-header-face)
          ;; Else check for Type + File: "JJ: [CRMAD] <file>"
          (progn ; Use progn if header didn't match, reset position
            (goto-char line-start)
            (when (re-search-forward "^JJ: +\\([CRMAD]\\) +\\(.*\\)$" line-end t)
              (put-text-property (match-beginning 1) (match-end 1)
                                 'face 'jjdescription-type-face)
              (put-text-property (match-beginning 2) (match-end 2)
                                 'face 'jjdescription-file-face)))))
      line-end))) ; Return end position

(defconst jjdescription-font-lock-keywords
  `(
    ;; Matcher for the first line (Summary + Overflow). Must run first.
    (jjdescription--match-first-line)
    ;; Matcher for "JJ: " lines and their contents.
    (jjdescription--highlight-jj-line))
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
  (setq-local comment-start "JJ: ")
  (setq-local comment-start-skip "\\(?:JJ:\\| \\)[ \t]*")
  ;; Enable context-based highlighting needed for the first line rule
  (setq-local jit-lock-contextually t))

;;;###autoload
(add-to-list 'auto-mode-alist '("\\.jjdescription\\'" . jjdescription-mode))

(provide 'jjdescription)

;;; jjdescription.el ends here

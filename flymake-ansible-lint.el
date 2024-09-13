;;; flymake-ansible-lint.el --- A Flymake backend for ansible-lint -*- lexical-binding: t; -*-

;; Copyright (C) 2024 James Cherti | https://www.jamescherti.com/contact/

;; Author: James Cherti
;; Version: 0.9.9
;; URL: https://github.com/jamescherti/flymake-ansible-lint.el
;; Keywords: tools
;; Package-Requires: ((flymake-quickdef "1.0.0") (emacs "26.1"))
;; SPDX-License-Identifier: GPL-3.0-or-later

;; This file is free software; you can redistribute it and/or modify
;; it under the terms of the GNU General Public License as published by
;; the Free Software Foundation; either version 2, or (at your option)
;; any later version.

;; This file is distributed in the hope that it will be useful,
;; but WITHOUT ANY WARRANTY; without even the implied warranty of
;; MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
;; GNU General Public License for more details.

;; You should have received a copy of the GNU General Public License
;; along with GNU Emacs.  If not, see <https://www.gnu.org/licenses/>.

;;; Commentary:
;; The flymake-ansible-lint package provides a Flymake backend for ansible-lint.

;;; Code:

(require 'flymake)
(require 'flymake-quickdef)

(defgroup flymake-ansible-lint nil
  "Non-nil if flymake-ansible-lint mode mode is enabled."
  :group 'flymake-ansible-lint
  :prefix "flymake-ansible-lint-"
  :link '(url-link
          :tag "Github"
          "https://github.com/jamescherti/flymake-ansible-lint.el"))

(defcustom flymake-ansible-lint-executable "ansible-lint"
  "Path to the ansible-lint executable.
If not specified with a full path (e.g., ansible-lint), the
`flymake-ansible-lint-backend' function will search for the executable in the
directories listed in the $PATH environment variable."
  :type 'string
  :group 'flymake-ansible-lint)

(flymake-quickdef-backend flymake-ansible-lint-backend
  :pre-let ((ansible-lint-exec
             (executable-find flymake-ansible-lint-executable))
            (source-path (buffer-file-name fmqd-source)))
  :pre-check (unless ansible-lint-exec
               (error "The '%s' executable was not found" ansible-lint-exec))
  :write-type nil
  :proc-form `(,ansible-lint-exec
               "--offline"
               "--nocolor"
               "--parseable"
               ,source-path)
  :search-regexp
  (rx bol
      ;; file.yaml:57:7: syntax-check[specific]: message
      ;; file.yaml:1: internal-error: Unexpected error code 1
      (seq (one-or-more (not ":")) ":" ; File name
           ;; Line/Column
           (group (one-or-more digit)) ":" ; Line number
           (optional (group (one-or-more digit) ":")) ; Optional column
           ;; Code
           (one-or-more space)
           (group (one-or-more (not ":")))  ":" ; Code
           ;; Message
           (one-or-more space)
           (group (one-or-more any))) ; Msg
      eol)

  :prep-diagnostic
  (let* ((lnum (string-to-number (match-string 1)))
         (col (let ((col-string (match-string 2)))
                (if col-string
                    (string-to-number col-string)
                  nil)))
         (code (match-string 3))
         (text (match-string 4))
         (pos (flymake-diag-region fmqd-source lnum col))
         (beg (car pos))
         (end (cdr pos))
         (type :error)
         (msg (format "%s: %s" code text)))
    (list fmqd-source beg end type msg)))

;;;###autoload
(defun flymake-ansible-lint-setup ()
  "Set up Flymake for `ansible-lint` linting in the current buffer.
This function adds `flymake-ansible-lint-backend' to the list of Flymake
diagnostic functions, enabling Ansible-Lint style checks locally for the current
buffer."
  (add-hook 'flymake-diagnostic-functions #'flymake-ansible-lint-backend nil t))

(provide 'flymake-ansible-lint)
;;; flymake-ansible-lint.el ends here
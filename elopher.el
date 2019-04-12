;;; elopher.el --- gopher client

;;; Commentary:

;; Simple gopher client in elisp.

;;; Code:

;; (defvar elopher-mode-map nil "Keymap for gopher client.")
;; (define-key elopher-mode-map (kbd "p") 'elopher-quit)

;; (define-derived-mode elopher-mode special-mode "elopher"
;;   "Major mode for elopher, an elisp gopher client.")

;; (global-set-key (kbd "C-c C-b") 'eval-buffer)

(defvar elopher-type-margin-width 5)

(defun elopher-type-margin (&optional type-name)
  (if type-name
      (insert (propertize
               (format (concat "%" (number-to-string elopher-type-margin-width) "s")
                       (concat "[" type-name "] "))
               'face '(foreground-color . "yellow")))
    (insert (make-string elopher-type-margin-width ?\s))))

(defun elopher-format-i (display-string)
  (elopher-type-margin)
  (insert (propertize display-string 'face '(foreground-color . "white")))
  (insert "\n"))

(defun elopher-format-0 (display-string selector hostname port)
  (elopher-type-margin "T")
  (insert (propertize display-string 'face '(foreground-color . "gray")))
  (insert "\n"))

(defun elopher-format-1 (display-string selector hostname port)
  (elopher-type-margin "/")
  (let ((map (make-sparse-keymap)))
    (define-key map [mouse-1]
      (eval `(lambda () (interactive) (elopher-get-index ,hostname ,port ,selector))))
    (insert (propertize display-string
                        'face '(foreground-color . "cyan")
                        'mouse-face 'highlight
                        'help-echo (format "mouse-1: follow link to \"%s\" on %s port %s"
                                           selector hostname port)
                        'keymap map))
    (insert "\n")))

(defun elopher-process-record (line)
  (let* ((type (elt line 0))
         (fields (split-string (substring line 1) "\t"))
         (g-display-string (elt fields 0))
         (g-selector (elt fields 1))
         (g-hostname (elt fields 2))
         (g-port (elt fields 3)))
    (pcase type
      (?i (elopher-format-i g-display-string))
      (?0 (elopher-format-0 g-display-string g-selector g-hostname g-port))
      (?1 (elopher-format-1 g-display-string g-selector g-hostname g-port)))))

(defvar elopher-incomplete-record "")

(defun elopher-process-complete-records (string)
  (let* ((til-now (string-join (list elopher-incomplete-record string)))
         (lines (split-string til-now "\r\n")))
    (dotimes (idx (length lines))
      (if (< idx (- (length lines) 1))
          (elopher-process-record (elt lines idx))
        (setq elopher-incomplete-record (elt lines idx))))))

(defun elopher-filter (proc string)
  (with-current-buffer (get-buffer "*elopher*")
    (let ((marker (process-mark proc)))
      (if (not (marker-position marker))
          (set-marker marker 0 (current-buffer)))
      (save-excursion
        (goto-char marker)
        (elopher-process-complete-records string)
        (set-marker marker (point))))))
    
(defun elopher-get-index (host &optional port path)
  (switch-to-buffer "*elopher*")
  (erase-buffer)
  (make-network-process
   :name "elopher-process"
   :host host
   :service (if port port 70)
   :filter #'elopher-filter)
  (process-send-string "elopher-process" (concat path "\n")))

(defun elopher ()
  "Start gopher client."
  (interactive)
  (elopher-get-index (read-from-minibuffer "Gopher host: ") 70))

;; (elopher-get-index "cosmic.voyage")
(elopher-get-index "gopher.floodgap.com")
;; (elopher-get-index "maurits.id.au")

(defun elopher-quit ()
  (interactive)
  (kill-buffer "*elopher*"))

;;; elopher.el ends here

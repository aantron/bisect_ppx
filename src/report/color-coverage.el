(defvar-local color-coverage-overlays '() "All coverage overlays in the current buffer")

(defun color-coverage-remove ()
  "Remove all coverage overlays"
  (mapc #'delete-overlay color-coverage-overlays)
  (setq color-coverage-overlays '())
  (setq global-mode-string nil))

(defun coverage-color-region (offset end-offset count)
  "Highlight using an overlay from OFFSET to
  min (END-OFFSET, end of line, end of file) using count as indicator."
  (save-restriction
    (widen)
    (goto-char offset)
    (let* ((end-off (min (line-end-position) end-offset))
           (overlay (make-overlay offset end-off))
           (color (if (= count 0) '(:foreground "red") '(:foreground "darkgreen"))))
      (overlay-put overlay 'face color)
;      (message "coloring at %d %d with %s in %s" offset count color (buffer-name))
      (push overlay color-coverage-overlays))))

(defun is-buffer (name)
  (string= (file-name-nondirectory name) (buffer-name)))

(defun coverage-info (name x)
  (if (is-buffer name)
      (save-excursion
        (if (not (null x))
            (let* ((percent (car (cdr (car x))))
                   (data (cdr x)))
              (setq global-mode-string percent)
              (let* ((first (car data))
                     (offs (car first))
                     (count (car (cdr first)))
                     (marks (cdr data)))
                (while (not (null marks))
                  (let* ((mark (car marks))
                         (end-off (car mark))
                         (next-count (car (cdr mark))))
                    (coverage-color-region offs end-off count)
                    (setq offs end-off)
                    (setq count next-count)
                    (setq marks (cdr marks))))
                (coverage-color-region offs (+ 100 offs) count)))))))

(defun color-coverage (file)
  "Colorize with coverage information"
  (color-coverage-remove)
  (load-file file))

(provide 'color-coverage)

;;; init.el
;;;; Packages
(require 'package)
(setq package-archives
      '(("gnu"    . "https://elpa.gnu.org/packages/")
        ("nongnu" . "https://elpa.nongnu.org/nongnu/")
        ("melpa"  . "https://melpa.org/packages/")))
(package-initialize)
(defvar nixlab-packages
  '(use-package
    evil anzu evil-anzu
    ivy counsel swiper
    helpful company bash-completion
    dashboard
    sed-mode perl-doc go-mode ob-go
    slime paredit
    dracula-theme tardis-theme
    dirvish nerd-icons))
(let ((missing (seq-remove #'package-installed-p nixlab-packages)))
  (when missing
    (message "nixlab: installing %s" missing)
    (package-refresh-contents)
    (dolist (p missing)
      (condition-case err
          (package-install p)
        (error (message "nixlab: could not install %s: %s" p err))))))
(require 'use-package)
(set-language-environment "UTF-8")
(prefer-coding-system 'utf-8)
(set-terminal-coding-system 'utf-8)
(set-keyboard-coding-system 'utf-8)
(load-theme 'dracula t)
;;;; Lab paths
(defvar nixlab-workbook (expand-file-name "~/workbook.org"))
(defvar nixlab-corpus   (expand-file-name "~/corpus/"))
;;;; Terminal-friendly Basics Configurations
(setq inhibit-startup-screen t
      ring-bell-function #'ignore
      use-short-answers t
      make-backup-files nil
      auto-save-default nil
      create-lockfiles nil
      display-line-numbers-type 'relative
      scroll-margin 3
      scroll-conservatively 101)
(menu-bar-mode -1)
(when (fboundp 'tool-bar-mode)   (tool-bar-mode -1))
(when (fboundp 'scroll-bar-mode) (scroll-bar-mode -1))
(unless (or noninteractive (display-graphic-p))
  (xterm-mouse-mode 1)
  (mouse-wheel-mode 1)
  (setq mouse-wheel-scroll-amount '(3 ((shift) . 1)) mouse-wheel-progressive-speed nil)
  (global-set-key [mouse-4] (lambda () (interactive) (scroll-down-line 3)))
  (global-set-key [mouse-5] (lambda () (interactive) (scroll-up-line 3))))
(column-number-mode 1)
(show-paren-mode 1)
(electric-pair-mode 1)
(savehist-mode 1)
(save-place-mode 1)
(recentf-mode 1)
(setq recentf-max-saved-items 50)
(add-hook 'prog-mode-hook #'display-line-numbers-mode)
;;;; Evil
(use-package evil
  :init
  (setq evil-want-C-i-jump nil
        evil-want-C-u-scroll t
        evil-undo-system 'undo-redo
        evil-esc-delay 0
        evil-split-window-below t
        evil-vsplit-window-right t)
  :config
  (evil-mode 1))
(use-package anzu :config (global-anzu-mode 1))
(use-package evil-anzu :after (evil anzu))
;;;; Completion & Help
(use-package ivy
  :config
  (setq ivy-use-virtual-buffers t
        ivy-count-format "(%d/%d) ")
  (ivy-mode 1))
(use-package counsel
  :after ivy
  :config
  (setq counsel-describe-function-function #'helpful-callable
        counsel-describe-variable-function #'helpful-variable)
  (counsel-mode 1))
(use-package helpful
  :config
  (with-eval-after-load 'evil
    (evil-define-key '(normal motion) helpful-mode-map (kbd "q") #'quit-window))
  (global-set-key [remap describe-function] #'helpful-callable)
  (global-set-key [remap describe-variable] #'helpful-variable)
  (global-set-key [remap describe-key]      #'helpful-key)
  (global-set-key [remap describe-command]  #'helpful-command))
(use-package company
  :config
  (setq company-idle-delay 0.2
        company-minimum-prefix-length 2)
  (global-company-mode 1))
(use-package bash-completion :config (bash-completion-setup))
;;;; Language modes
(use-package sed-mode)
(use-package perl-doc)
(use-package go-mode)
(use-package slime
  :init
  (setq inferior-lisp-program "sbcl"
        browse-url-browser-function #'eww-browse-url)
  :config
  (slime-setup '(slime-fancy))
  (with-eval-after-load 'evil
    (evil-set-initial-state 'slime-repl-mode 'insert)
    (dolist (m '(sldb-mode slime-inspector-mode slime-xref-mode
                 slime-connection-list-mode))
      (evil-set-initial-state m 'emacs))))
(use-package paredit
  :hook ((lisp-mode emacs-lisp-mode lisp-interaction-mode lisp-data-mode) . paredit-mode)
  :config
  (add-hook 'paredit-mode-hook (lambda () (electric-pair-local-mode -1))))
;;;; Org & Babel
(use-package ob-go)
(with-eval-after-load 'org
  (setq org-src-fontify-natively t
        org-src-tab-acts-natively t
        org-edit-src-content-indentation 0
        org-src-window-setup 'current-window
        org-startup-folded 'content)
  (require 'org-tempo)
  (org-babel-do-load-languages
   'org-babel-load-languages
   '((shell      . t)
     (emacs-lisp . t)
     (python     . t)
     (perl       . t)
     (C          . t)
     (go         . t)
     (awk        . t)
     (sed        . t)
     (lisp       . t)
     (sqlite     . t)))
  (setq org-babel-lisp-eval-fn #'slime-eval
        org-babel-python-command "python3"
        org-confirm-babel-evaluate
        (lambda (lang _body)
          (not (member lang '("bash" "sh" "shell" "emacs-lisp" "elisp"
                              "python" "perl" "C" "cpp" "C++" "go"
                              "awk" "sed" "lisp" "sqlite"))))))
(defun nixlab-ensure-slime (&rest _)
  (require 'slime)
  (unless (slime-connected-p)
    (save-window-excursion (slime))
    (let ((deadline (+ (float-time) 30)))
      (while (and (not (slime-connected-p)) (< (float-time) deadline))
        (accept-process-output nil 0.1)))
    (unless (slime-connected-p)
      (user-error "SLIME did not connect — is sbcl on PATH?"))))
(advice-add 'org-babel-execute:lisp :before #'nixlab-ensure-slime)
;;;; Lab commands
(defun nixlab-open-workbook () (interactive) (find-file nixlab-workbook))
(defun nixlab-open-corpus ()   (interactive) (dirvish nixlab-corpus))
(defun nixlab-term ()          (interactive) (ansi-term (or (executable-find "bash") "/bin/sh")))
(defun nixlab-slime ()         (interactive) (slime))
(defun nixlab-slime-eval-last ()
  (interactive)
  (save-excursion
    (when (and (bound-and-true-p evil-mode) (evil-normal-state-p) (not (eolp)))
      (forward-char))
    (call-interactively #'slime-eval-last-expression)))
(defun nixlab-remove-all-results ()
  (interactive)
  (org-babel-remove-result-one-or-many t))
;;;; Leader keymap
(define-prefix-command 'nixlab-leader-map)
(dolist (b `(("SPC" . counsel-M-x)
             ("."   . counsel-find-file)
             (","   . ivy-switch-buffer)
             ("/"   . swiper)
             ("f f" . counsel-find-file)
             ("f r" . counsel-recentf)
             ("f s" . save-buffer)
             ("b b" . ivy-switch-buffer)
             ("b k" . kill-current-buffer)
             ("b d" . dashboard-open)
             ("b r" . revert-buffer)
             ("w v" . split-window-right)
             ("w s" . split-window-below)
             ("w w" . other-window)
             ("w d" . delete-window)
             ("w o" . delete-other-windows)
             ("s s" . swiper)
             ("s g" . counsel-grep)
             ("s r" . counsel-rg)
             ("h f" . helpful-callable)
             ("h v" . helpful-variable)
             ("h k" . helpful-key)
             ("h p" . helpful-at-point)
             ("h m" . describe-mode)
             ("h b" . counsel-descbinds)
             ("h i" . info)
             ("c c" . org-ctrl-c-ctrl-c)
             ("c e" . org-edit-special)
             ("c s" . org-babel-execute-subtree)
             ("c b" . org-babel-execute-buffer)
             ("c n" . org-babel-next-src-block)
             ("c p" . org-babel-previous-src-block)
             ("c k" . org-babel-remove-result)
             ("c K" . nixlab-remove-all-results)
             ("c t" . org-babel-tangle)
             ("o w" . nixlab-open-workbook)
             ("o c" . nixlab-open-corpus)
             ("o f" . dirvish)
             ("o t" . nixlab-term)
             ("o e" . eshell)
             ("o l" . nixlab-slime)
             ("l e" . nixlab-slime-eval-last)
             ("l d" . slime-compile-defun)
             ("l k" . slime-compile-and-load-file)
             ("l r" . slime-switch-to-output-buffer)
             ("l h" . slime-describe-symbol)
             ("l H" . slime-hyperspec-lookup)
             ("l m" . slime-macroexpand-1)
             ("l i" . slime-inspect)
             ("l ." . slime-edit-definition)
             ("l ," . slime-pop-find-definition-stack)
             ("k s" . paredit-forward-slurp-sexp)
             ("k S" . paredit-backward-slurp-sexp)
             ("k b" . paredit-forward-barf-sexp)
             ("k B" . paredit-backward-barf-sexp)
             ("k w" . paredit-wrap-round)
             ("k W" . paredit-splice-sexp)
             ("k r" . paredit-raise-sexp)
             ("k j" . paredit-join-sexps)
             ("k J" . paredit-split-sexp)
             ("k t" . transpose-sexps)
             ("k c" . paredit-convolute-sexp)
             ("o d" . dashboard-open)
             ("q q" . save-buffers-kill-terminal)))
  (define-key nixlab-leader-map (kbd (car b)) (cdr b)))
(with-eval-after-load 'evil
  (dolist (state '(normal visual motion))
    (evil-global-set-key state (kbd "SPC") 'nixlab-leader-map)))
;; Dired & Dirvish
(with-eval-after-load 'dired
  (setq dired-listing-switches
        "-l --almost-all --human-readable --group-directories-first --no-group")
  (evil-set-initial-state 'dired-mode 'emacs)
  (define-key dired-mode-map (kbd "SPC") 'nixlab-leader-map)
  (define-key dired-mode-map (kbd "j") #'dired-next-line)
  (define-key dired-mode-map (kbd "k") #'dired-previous-line))
(use-package nerd-icons)
(use-package dirvish
  :init
  (dirvish-override-dired-mode)
  :custom
  (dirvish-quick-access-entries
   '(("h" "~/"                 "Home")
     ("c" "~/corpus/"          "Corpus")
     ("w" "~/workbook-data/"   "Workbook data")
     ("p" "~/workbook-data/practice/" "Practice files")
     ("n" "/opt/nixlab/"       "nixlab")))
  :config
  (setq dirvish-mode-line-format '(:left (sort symlink) :right (omit yank index))
        dirvish-attributes '(vc-state subtree-state nerd-icons collapse file-time file-size))
  (dolist (b '(("h"   . dired-up-directory)
               ("l"   . dired-find-file)
               ("?"   . dirvish-dispatch)
               ("a"   . dirvish-setup-menu)
               ("f"   . dirvish-file-info-menu)
               ("o"   . dirvish-quick-access)
               ("s"   . dirvish-quicksort)
               ("r"   . dirvish-history-jump)
               ("L"   . dirvish-ls-switches-menu)
               ("v"   . dirvish-vc-menu)
               ("*"   . dirvish-mark-menu)
               ("y"   . dirvish-yank-menu)
               ("N"   . dirvish-narrow)
               ("^"   . dirvish-history-last)
               ("TAB" . dirvish-subtree-toggle)))
    (define-key dirvish-mode-map (kbd (car b)) (cdr b))))
;;;; Dashboard
(defconst nixlab-banner-text
  "
   ███╗   ██╗██╗██╗  ██╗██╗      █████╗ ██████╗
   ████╗  ██║██║╚██╗██╔╝██║     ██╔══██╗██╔══██╗
   ██╔██╗ ██║██║ ╚███╔╝ ██║     ███████║██████╔╝
   ██║╚██╗██║██║ ██╔██╗ ██║     ██╔══██║██╔══██╗
   ██║ ╚████║██║██╔╝ ██╗███████╗██║  ██║██████╔╝
   ╚═╝  ╚═══╝╚═╝╚═╝  ╚═╝╚══════╝╚═╝  ╚═╝╚═════╝
")
(defun nixlab--banner-file ()
  (let ((f (expand-file-name "nixlab-banner.txt" user-emacs-directory)))
    (unless (file-exists-p f)
      (with-temp-file f (insert nixlab-banner-text)))
    f))
(defconst nixlab-tools
  '(("bash" . "bash") ("python3" . "python") ("perl" . "perl")
    ("cc" . "C") ("go" . "go") ("awk" . "awk") ("sed" . "sed")
    ("sbcl" . "sbcl")))
(defun nixlab--button (key label fn)
  (insert "  ")
  (insert-text-button (format "[%s] %s" key label)
                      'action (lambda (_) (funcall fn))
                      'follow-link t
                      'face 'dashboard-items-face)
  (insert "\n"))
(defun nixlab-dashboard-lab (_list-size)
  (insert (propertize (format "Lab: %s" (system-name)) 'face 'dashboard-heading))
  (let ((have (seq-filter (lambda (tool) (executable-find (car tool))) nixlab-tools))
        (miss (seq-remove (lambda (tool) (executable-find (car tool))) nixlab-tools)))
    (insert "\n\n  tools    "
            (propertize (mapconcat #'cdr have "  ") 'face 'success))
    (when miss
      (insert "\n  missing  "
              (propertize (mapconcat #'cdr miss "  ") 'face 'error))))
  (insert "\n\n")
  (nixlab--button "w" "workbook.org"  #'nixlab-open-workbook)
  (nixlab--button "c" "corpus/"       #'nixlab-open-corpus)
  (nixlab--button "t" "terminal"      #'nixlab-term)
  (nixlab--button "l" "SBCL REPL (SLIME)" #'nixlab-slime)
  (insert (propertize "\n  SPC for everything else · SPC h for help · SPC q q to quit"
                      'face 'shadow)))
(use-package dashboard
  :config
  (setq dashboard-startup-banner (nixlab--banner-file)
        dashboard-banner-logo-title "NixOS toolchain lab"
        dashboard-center-content t
        dashboard-display-icons-p nil
        dashboard-set-heading-icons nil
        dashboard-set-file-icons nil
        dashboard-set-footer nil
        dashboard-footer-messages nil
        dashboard-items '((lab . 1) (recents . 8) (bookmarks . 5)))
  (add-to-list 'dashboard-item-generators '(lab . nixlab-dashboard-lab))
  (when (boundp 'dashboard-startupify-list)
    (setq dashboard-startupify-list
          (delq 'dashboard-insert-footer dashboard-startupify-list)))
  (evil-set-initial-state 'dashboard-mode 'emacs)
  (define-key dashboard-mode-map (kbd "SPC") 'nixlab-leader-map)
  (define-key dashboard-mode-map (kbd "j") #'dashboard-next-line)
  (define-key dashboard-mode-map (kbd "k") #'dashboard-previous-line)
  (define-key dashboard-mode-map (kbd "w") #'nixlab-open-workbook)
  (define-key dashboard-mode-map (kbd "c") #'nixlab-open-corpus)
  (define-key dashboard-mode-map (kbd "t") #'nixlab-term)
  (define-key dashboard-mode-map (kbd "l") #'nixlab-slime)
  (dashboard-setup-startup-hook)
  (setq initial-buffer-choice (lambda () (get-buffer-create dashboard-buffer-name))))
;;; init.el ends here

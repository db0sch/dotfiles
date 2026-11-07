ZSH=$HOME/.oh-my-zsh
ZSH_THEME="simple"
ZSH_DISABLE_COMPFIX=true

# Plugins: zsh-syntax-highlighting must be last
plugins=(git gitfast last-working-dir common-aliases history-substring-search zsh-autosuggestions zsh-syntax-highlighting)

source "${ZSH}/oh-my-zsh.sh"
unalias rm lt 2>/dev/null  # Remove unwanted aliases from common-aliases

# PATH: project bins go last, so a repo can't shadow system commands.
# typeset -U drops duplicate entries (e.g. in nested shells).
typeset -U path PATH
export PATH="${PATH}:./bin:./node_modules/.bin"

# Environment variables
export HOMEBREW_NO_ANALYTICS=1
export LANG=en_US.UTF-8
export LC_ALL=en_US.UTF-8
export EDITOR="zed --wait"  # --wait: block until the file is closed (rails credentials:edit, etc.)
export BUNDLER_EDITOR=zed
export RAILS_EDITOR=zed
export LEDGER_FILE=~/finance/main.journal

# Tool initializations
eval "$(mise activate zsh)"
eval "$(/opt/homebrew/bin/try init ~/src/tries)"

# Aliases
alias zzz='zed .'
alias lg='lazygit'
[[ -f "$HOME/.aliases" ]] && source "$HOME/.aliases"

# Git worktree helpers (ccw, ccw-, ccwrm).
# ~/.zshrc is a symlink, so resolve it (:A) to find this repo.
DOTFILES="${${(%):-%x}:A:h}"
source "$DOTFILES/zsh/worktrees.zsh"

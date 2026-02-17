ZSH=$HOME/.oh-my-zsh
ZSH_THEME="simple"
ZSH_DISABLE_COMPFIX=true

# Plugins: zsh-syntax-highlighting must be last
plugins=(git gitfast last-working-dir common-aliases history-substring-search zsh-autosuggestions zsh-syntax-highlighting)

source "${ZSH}/oh-my-zsh.sh"
unalias rm lt 2>/dev/null  # Remove unwanted aliases from common-aliases

# Consolidated PATH
export PATH="./bin:./node_modules/.bin:${HOME}/.rbenv/bin:${HOME}/.bun/bin:${PATH}:/usr/local/sbin"

# Environment variables
export HOMEBREW_NO_ANALYTICS=1
export LANG=en_US.UTF-8
export LC_ALL=en_US.UTF-8
export EDITOR=zed
export BUNDLER_EDITOR=zed
export RAILS_EDITOR=zed
export PYTHONBREAKPOINT=ipdb.set_trace
export BUN_INSTALL="$HOME/.bun"
export LEDGER_FILE=~/finance/main.journal

# rbenv
type -a rbenv > /dev/null && eval "$(rbenv init -)"

# Tool initializations
[ -s "/Users/dbo/.bun/_bun" ] && source "/Users/dbo/.bun/_bun"
eval "$(mise activate zsh)"
eval "$(/opt/homebrew/bin/try init ~/src/tries)"

# Aliases
alias zzz='zed .'
[[ -f "$HOME/.aliases" ]] && source "$HOME/.aliases"

# Get the main repo root (works from main or any worktree)
_ccw_main_root() {
  local git_common_dir=$(git rev-parse --git-common-dir 2>/dev/null)
  if [[ -z "$git_common_dir" ]]; then
    return 1
  fi
  # git-common-dir is either ".git" (from main) or absolute path to main's .git (from worktree)
  if [[ "$git_common_dir" == ".git" ]]; then
    git rev-parse --show-toplevel
  else
    dirname "$git_common_dir"
  fi
}

# Create or jump to a worktree (no args = list)
ccw() {
  local branch_name="$1"
  local main_root=$(_ccw_main_root)

  if [[ -z "$main_root" ]]; then
    echo "Error: Not in a git repository"
    return 1
  fi

  local worktrees_dir="${main_root}_worktrees"

  # No args = list
  if [[ -z "$branch_name" ]]; then
    echo "Worktrees:"
    git worktree list
    return 0
  fi

  local worktree_path="$worktrees_dir/$branch_name"

  # If exists, jump to it
  if [[ -d "$worktree_path" ]]; then
    cd "$worktree_path"
    echo "Switched to: $branch_name"
    return 0
  fi

  # Create new worktree (only from main repo)
  local git_dir=$(git rev-parse --git-dir 2>/dev/null)
  local git_common_dir=$(git rev-parse --git-common-dir 2>/dev/null)

  if [[ "$git_dir" != "$git_common_dir" ]]; then
    echo "Error: Worktree '$branch_name' doesn't exist. Create from main repo."
    return 1
  fi

  mkdir -p "$worktrees_dir"

  if ! git worktree add -b "$branch_name" "$worktree_path"; then
    echo "Error: Failed to create worktree"
    return 1
  fi

  if [[ -f "$main_root/config/master.key" ]]; then
    ln -s "$main_root/config/master.key" "$worktree_path/config/master.key"
    echo "Linked master.key"
  fi

  mise trust "$worktree_path"
  cd "$worktree_path"

  echo "Created: $branch_name"
}

# Go back to main repo
ccw-() {
  local main_root=$(_ccw_main_root)

  if [[ -z "$main_root" ]]; then
    echo "Error: Not in a git repository"
    return 1
  fi

  cd "$main_root"
}

# Remove a worktree
ccwrm() {
  local branch_name="$1"

  if [[ -z "$branch_name" ]]; then
    echo "Usage: ccwrm <branch-name>"
    return 1
  fi

  local main_root=$(_ccw_main_root)
  local worktree_path="${main_root}_worktrees/$branch_name"

  if [[ "$PWD" == "$worktree_path"* ]]; then
    cd "$main_root"
  fi

  git worktree remove "$worktree_path" && echo "Removed: $branch_name"
}

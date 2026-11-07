# Git worktree helpers. Worktrees live next to the repo, in <repo>_worktrees/<branch>.
#
#   ccw            list worktrees
#   ccw <branch>   jump to the worktree, creating it (and the branch) if needed
#   ccw-           go back to the main repo
#   ccwrm <branch> remove a worktree
#
# If the repo has an executable bin/worktree, it is called with `setup` after
# creating a worktree and `teardown` before removing one (own database, port, host).

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

  if git show-ref --verify --quiet "refs/heads/$branch_name"; then
    if ! git worktree add "$worktree_path" "$branch_name"; then
      echo "Error: Failed to create worktree"
      return 1
    fi
  else
    if ! git worktree add -b "$branch_name" "$worktree_path"; then
      echo "Error: Failed to create worktree"
      return 1
    fi
  fi

  if [[ -f "$main_root/config/master.key" ]]; then
    ln -s "$main_root/config/master.key" "$worktree_path/config/master.key"
    echo "Linked master.key"
  fi

  mise trust "$worktree_path"
  cd "$worktree_path"

  # Repo hook: its own database, port and host (checkmate: bin/worktree)
  if [[ -x bin/worktree ]]; then
    bin/worktree setup
  fi

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

  if [[ -z "$main_root" ]]; then
    echo "Error: Not in a git repository"
    return 1
  fi

  local worktree_path="${main_root}_worktrees/$branch_name"

  if [[ "$PWD" == "$worktree_path"* ]]; then
    cd "$main_root"
  fi

  # Repo hook: drop the worktree's databases, but only if git will remove it
  if [[ -x "$worktree_path/bin/worktree" ]]; then
    if [[ -n "$(git -C "$worktree_path" status --porcelain)" ]]; then
      echo "Error: '$branch_name' has uncommitted changes"
      return 1
    fi
    (cd "$worktree_path" && bin/worktree teardown) || return 1
  fi

  git worktree remove "$worktree_path" && echo "Removed: $branch_name"
}

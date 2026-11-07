# dotfiles

My macOS shell and git setup: zsh with oh-my-zsh, mise for language versions, Zed as editor.
Originally forked from [lewagon/dotfiles](https://github.com/lewagon/dotfiles).

## Install

```sh
git clone git@github.com:db0sch/dotfiles.git ~/code/db0sch/dotfiles
cd ~/code/db0sch/dotfiles && ./install.sh
```

`install.sh` symlinks the files below into place (an existing real file is first moved to `*.backup`),
installs the zsh plugins, adds the SSH key to the macOS keychain and reloads the shell.

| File                | Linked to          | What it does                                      |
| ------------------- | ------------------ | ------------------------------------------------- |
| `zshenv`            | `~/.zshenv`        | Puts `~/.local/bin` on PATH for every shell        |
| `zprofile`          | `~/.zprofile`      | Homebrew environment for login shells             |
| `zshrc`             | `~/.zshrc`         | oh-my-zsh, PATH, env vars, mise, aliases          |
| `zsh/worktrees.zsh` | sourced by `zshrc` | `ccw` git worktree helpers                        |
| `aliases`           | `~/.aliases`       | Small extra aliases (`myip`, `speedtest`, `serve`) |
| `gitconfig`         | `~/.gitconfig`     | Git aliases, colors, identity                     |
| `config`            | `~/.ssh/config`    | SSH: keychain + default key                       |

## Worktree helpers

```sh
ccw              # list worktrees
ccw my-branch    # jump to ../<repo>_worktrees/my-branch, creating it if needed
ccw-             # back to the main repo
ccwrm my-branch  # remove the worktree
```

A repo can provide an executable `bin/worktree`; `ccw` calls it with `setup` after creating a
worktree and `ccwrm` with `teardown` before removing one.

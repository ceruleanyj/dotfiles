# Environment Variables and Shell Options for ZSH
# (overrides prezto's default settings or zshenv)


# fzf {{{
#https://github.com/junegunn/fzf/wiki/Configuring-shell-key-bindings

# fzf-powered CTRL-R: launch fzf with sort enabled
# @see https://github.com/junegunn/fzf/issues/526
export FZF_CTRL_R_OPTS='--sort'

# Ctrl-T: Setting ripgrep or fd as the default source for Ctrl-T fzf
if (( $+commands[rg] )); then
    export FZF_CTRL_T_COMMAND='rg --files --hidden --follow --glob "!.git/"'
elif (( $+commands[fd] )); then
    export FZF_CTRL_T_COMMAND='fd --type f'
fi
if (( $+commands[bat] )); then
    # if bat is available, use it as a preview tool
    export FZF_CTRL_T_OPTS="--preview 'bat {} --color=always --line-range :30'"
fi

# ALT-C: FASD_CD with preview
export FZF_ALT_C_COMMAND='fasd_cd -d -l -R'
export FZF_ALT_C_OPTS="--preview 'tree -C {} | head -200'"

# Color and appearances
# use brighter and more visible background color.
export FZF_DEFAULT_OPTS="--color 'bg+:239'"

# }}}

# Save more history entries
# @see history/init.zsh
export HISTSIZE=10000000
export SAVEHIST=10000000

# Save timestamp and the duration as well into the history file.
setopt EXTENDED_HISTORY

# new history lines are added incrementally as soon as they are entered,
# rather than waiting until the shell exits
setopt INC_APPEND_HISTORY

# No, I don't wan't share command history.
unsetopt SHARE_HISTORY
setopt NO_SHARE_HISTORY

# See zsh-autoswitch-virtualenv #19
unsetopt AUTO_NAME_DIRS       # Do not auto add variable-stored paths

# If globs do not match a file, just run the command rather than throwing a no-matches error.
# This is especially useful for some commands with '^', '~', '#', e.g. 'git show HEAD^1'
unsetopt NOMATCH

#
# Path Configurations.
#
# Note: Configuring $PATH should be done preferably in ~/.zshenv,
# in order that zsh plugins are also provisioned with exectuables from $PATH.
# Entries listed here may not be visible from zsh plugins and source scripts.

# GO {{{
export GOROOT=$HOME/.go
export GOPATH=$GOROOT/packages
path=( $path $GOROOT/bin $GOPATH/bin )
# }}}

# Bazel {{{
if [ -f $HOME/.bazel/bin/bazel ]; then
  export BAZEL_HOME="$HOME/.bazel"
  path=( $path $BAZEL_HOME/bin )
fi
# }}}

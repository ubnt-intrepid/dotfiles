# zshrc

# --- path configuration ---
typeset -aU path
path=(
  ${ASDF_DATA_DIR:-$HOME/.asdf}/shims(N-/)
  $HOME/.local/bin(N-/)
  $HOME/.cargo/bin(N-/)
  $HOME/.dotnet/tools(N-/)
  /opt/homebrew/bin(N-/)
  $path(N-/)
)

typeset -aU fpath
fpath=(
  ${ASDF_DATA_DIR:-$HOME/.asdf}/completions(N-/)
  ${XDG_DATA_HOME:-$HOME/.local/share}/zsh/site-functions(N-/)
  $fpath(N-/)
)

# setup homebrew if exists
(( $+commands[brew] )) && eval "$(brew shellenv)"

# setup $EDITOR
if [[ -z "$EDITOR" && -x "$(command -v nvim)" ]]; then
  export EDITOR="${EDITOR:-nvim}"
  export SUDO_EDITOR="$EDITOR"
fi


# --- general configuration ---
bindkey -v
setopt auto_pushd
setopt pushd_ignore_dups
setopt extended_glob
setopt noprompt_subst


# --- history configuration ---
export HISTSIZE=1000
export SAVEHIST=1000000

setopt hist_ignore_all_dups
setopt hist_ignore_space
setopt hist_reduce_blanks

# --- aliases ---
alias c=clear
alias e="${EDITOR:-nvim}"
alias g=git
alias l="ls -al"
alias ls="ls --color=always"
alias q=exit

# --- mise ---
if (( $+commands[mise] )); then
  eval "$(mise activate zsh)"
fi


# --- fzf ---
if (( $+commands[fzf] )); then
  source <(fzf --zsh)

  if (( $+commands[rhq] )); then
    function __fuzzy_select_repositories() {
      local selected=$(rhq list | fzf --prompt='REPOS> ' --query="$LBUFFER")
      if [[ -n $selected ]]; then
        BUFFER="cd \"${selected}\""
        zle accept-line
      fi
      zle clear-screen
    }
    zle -N __fuzzy_select_repositories
    bindkey '^g' __fuzzy_select_repositories
  fi
fi


# --- starship ---
if (( $+commands[starship] )); then
  eval "$(starship init zsh)"
fi


# activate completion
autoload -U compinit
compinit

# vim: set tabstop=2 shiftwidth=2 expandtab :

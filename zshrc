# zshrc

export DOTFILES_REPO_PATH="${${(%):-%x}:A:h}"

# --- path configuration ---
typeset -aU path
path=(
  $DOTFILES_REPO_PATH/bin(N-/)
  $HOME/.nix-profile/bin(N-/)
  /nix/var/nix/profiles/default/bin(N-/)
  /opt/homebrew/bin(N-/)
  /opt/homebrew/opt/curl/bin(N-/) # workaround: macOS標準の curl ではなく、Homebrew 版を優先的に用いる
  $path(N-/)
  $HOME/.cargo/bin(N-/)
  $HOME/.local/bin(N-/)
  $HOME/.dotnet/tools(N-/)
)

typeset -aU fpath
fpath=(
  ${XDG_DATA_HOME:-$HOME/.local/share}/zsh/site-functions(N-/)
  $fpath(N-/)
)

# setup homebrew if exists
(( $+commands[brew] )) && eval "$(brew shellenv)"

# setup $EDITOR
if [[ -z "$EDITOR" && -x "$(command -v nvim)" ]]; then
  export EDITOR="${EDITOR:-nvim}"
  export SUDO_EDITOR="$(command -v nvim)"
fi


# --- general configuration ---
bindkey -v
setopt auto_pushd
setopt pushd_ignore_dups
setopt extended_glob
setopt noprompt_subst
setopt nonomatch

export LESS='-R'  # use ANSI escape sequences

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
      local selected=$(rhq list | sort | fzf --prompt='REPOS> ' --query="$LBUFFER")
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


# --- prompt ---
if (( $+commands[starship] )); then
  eval "$(starship init zsh)"
else
  autoload -Uz vcs_info add-zsh-hook

  zstyle ':vcs_info:*' enable git  # git 以外のバックエンドは有効にしないこと (hg 等はリポジトリ内の設定から拡張や hook を読み込む)
  zstyle ':vcs_info:*' formats '%b'
  zstyle ':vcs_info:*' actionformats '%b|%a'

  # core.fsmonitor に悪意のあるスクリプトが混入していた場合のコード実行を防止する
  zstyle ':vcs_info:*' check-for-changes false
  zstyle ':vcs_info:*' check-for-staged-changes false

  # 上述の zstyle を変更した際は、index を読むコマンド (status, diff 等) が増えていないか再確認すること (GIT_TRACE を設定し、設定の安全性を検証すべき)

  function __prompt_precmd() {
    vcs_info
    # noprompt_subst のため precmd 内で直接組み立てる (ブランチ名中の % はエスケープする)
    if [[ -n $vcs_info_msg_0_ ]]; then
      RPROMPT="%F{magenta}${vcs_info_msg_0_//\%/%%}%f"
    else
      RPROMPT=''
    fi
  }
  add-zsh-hook precmd __prompt_precmd

  # [user@host (SSH 接続時のみ)] カレントディレクトリ [終了ステータス (非0時のみ)] %/#
  PROMPT=$'%F{cyan}%~%f\n%(?.%F{green}.%F{red}[%?] )%#%f '
  [[ -n $SSH_CONNECTION ]] && PROMPT="%F{yellow}%n@%m%f $PROMPT"
fi


# activate completion
autoload -U compinit
compinit

# vim: set tabstop=2 shiftwidth=2 expandtab :

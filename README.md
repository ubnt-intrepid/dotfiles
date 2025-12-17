# My latest dotfiles

* 分割して管理する方針だと疲れるので一括で管理する
* [`dot.rs`](https://github.com/ubnt-intrepid/dot.rs) は放置してしまっているので、別ツールで対処しつつ今後の方針を決める

## Installation

* Download the latest binary of [@rhysd]'s [`dotfiles`](https://github.com/rhysd/dotfiles) from [here](https://github.com/rhysd/dotfiles/releases).
* Clone this repository and then launch installation script:
  ```sh
  # Mac/Linux/WSL2
  $ git clone git@github.com:ubnt-intrepid/dotfiles.git ~/.dotfiles
  $ cd ~/.dotfiles
  $ dotfiles link
  ```
  ```powershell
  # Windows (PowerShell)
  TODO
  ```
* For macOS environment:
  ```sh
  # install Homebrew
  /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"

  # install formula
  cd ~/.dotfiles
  brew bundle
  ```

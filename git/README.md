# `gitconfig`

## Configuration

ユーザ設定など特定の項目を書き換えたい（が共有したくない）場合は、 `~/.gitconfig` で設定するか

```ini
# ~/.gitconfig
[core]
  editor = awesome-text-editor
[user]
  email = custom-email@example.com
```

... リポジトリ単位で設定して下さい。

```shell-session
git config set user.email custom-email@example.com
```

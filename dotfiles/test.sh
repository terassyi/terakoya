#!/bin/bash
set -euo pipefail

DOTFILES_SOURCE="/home/testuser/dotfiles"

echo "==> chezmoi init"
chezmoi init --source="$DOTFILES_SOURCE" --no-tty

echo "==> chezmoi apply"
chezmoi apply --source="$DOTFILES_SOURCE" --no-tty

echo "==> Checking deployed files"
files=(
    ~/.config/fish/config.fish
    ~/.config/fish/conf.d/starship.fish
    ~/.config/fish/conf.d/zoxide.fish
    ~/.config/fish/functions/clone.fish
    ~/.config/fish/functions/sk_history.fish
    ~/.config/git/config
)
for f in "${files[@]}"; do
    test -f "$f" || { echo "FAIL: $f not found"; exit 1; }
done

echo "==> Fish syntax check"
fish -n ~/.config/fish/config.fish

echo "==> Fish function autoload check"
functions=(clone sk_history sk_bat sk_zoxide sk_zoxide_gh sk_code_repo gh_release)
for fn in "${functions[@]}"; do
    fish -c "functions -q $fn" || { echo "FAIL: function $fn not found"; exit 1; }
done

# skim_key_bindings is downloaded by chezmoi script only when sk is installed
if command -v sk &>/dev/null; then
    fish -c "functions -q skim_key_bindings" || { echo "FAIL: function skim_key_bindings not found"; exit 1; }
fi

echo "==> Git config check"
git_config=~/.config/git/config
assert_git() {
    local label="$1" pattern="$2"
    grep -q "$pattern" "$git_config" || { echo "FAIL: git config - $label"; exit 1; }
}
# template values (testuser → hostname=dev → email=dev@terassyi.net)
assert_git "user.email" "email = dev@terassyi.net"
assert_git "user.signingkey" "signingkey = ~/.ssh/id_ed25519.pub"
# static values
assert_git "commit.gpgsign" "gpgsign = true"
assert_git "gpg.format" "format = ssh"
assert_git "pull.rebase" "rebase = true"
assert_git "pager.diff" "diff = delta"
assert_git "delta.navigate" "navigate = true"
assert_git "init.defaultBranch" "defaultBranch = main"

echo "All checks passed"

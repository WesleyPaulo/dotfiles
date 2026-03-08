#!/usr/bin/env bash

set -e

DOTFILES_DIR="$HOME/.dotfiles"

echo "Instalando dotfiles..."

ln -sf "$DOTFILES_DIR/.bash/.bashrc" "$HOME/.bashrc"
ln -sf "$DOTFILES_DIR/git/gitconfig" "$HOME/.gitconfig"

echo "Dotfiles instalados com sucesso!"
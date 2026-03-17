#!/usr/bin/env bash

#!/usr/bin/env bash

set -e

DOTFILES_DIR="$HOME/.dotfiles"

echo "Instalando dotfiles..."

# verificar se diretório existe
if [ ! -d "$DOTFILES_DIR" ]; then
  echo "Erro: diretório $DOTFILES_DIR não encontrado"
  exit 1
fi

# backup arquivos antigos
backup_file () {
  if [ -f "$1" ]; then
    mv "$1" "$1.backup.$(date +%s)"
  fi
}

backup_file "$HOME/.bashrc"
backup_file "$HOME/.gitconfig"

# criar symlinks
ln -sf "$DOTFILES_DIR/.bash/.bashrc" "$HOME/.bashrc"
ln -sf "$DOTFILES_DIR/git/gitconfig" "$HOME/.gitconfig"

echo "Dotfiles instalados com sucesso!"
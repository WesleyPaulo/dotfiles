#~/.bashrc

for file in ~/.dotfiles/.bash/aliases/*.sh; do source "$file"; done
for file in ~/.dotfiles/.bash/functions/*.sh; do source "$file"; done

source ~/.dotfiles/.bash/exports
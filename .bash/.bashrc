#~/.bashrc

for file in ~/.dotfiles/.bash/aliases/*; do
    [ -r "$file" ] && [ -f "$file" ] && source "$file"
done
for file in ~/.dotfiles/.bash/functions/*; do
    [ -r "$file" ] && [ -f "$file" ] && source "$file"
done

source ~/.dotfiles/.bash/exports
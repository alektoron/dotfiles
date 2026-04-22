### STOW
- install GNU/Stow `sudo pacman -S stow`
- update all dotfiles to the naming convention
	- if a path is `~/.config/app/app.conf` then it should be `dotfiles/app/.config/app/app.conf`
	- if a path is `~/.app.conf` then if should be `dotfiles/app/.app.conf`
- check if it works `stow -t ~ -nv app` it should has `LINK:` with a potential symlink
- if the previous step was okay, then run the command `stow -t ~ -nv app` to create a symlink


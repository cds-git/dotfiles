# dotfiles
Personal dotfiles

## Setup

### Linux
To install and configure everything for Ubuntu or Arch, just run the `setup.sh` script
`sudo chmod 700 ./setup.sh && ./setup.sh`

### Windows
To setup starship prompt for PowerShell run this
`New-Item -ItemType Directory -Force ~/.config;New-Item -ItemType SymbolicLink -Path "~/.config/starship.toml" -Target "~/dotfiles/starship/starship.toml";`

## TODO
- Add wezterm
- Add komorebi tiling window manager for windows
- Add windows status bar


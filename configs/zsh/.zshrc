# Load modular Zsh configuration.
ZSH_CONFIG_DIR="${XDG_CONFIG_HOME:-$HOME/.config}/zsh"

for zsh_config_file in \
  environment \
  tools \
  completion \
  history \
  alias \
  function \
  keybindings \
  external \
  kitty-graphics \
  theme
do
  [[ -r "$ZSH_CONFIG_DIR/$zsh_config_file" ]] && source "$ZSH_CONFIG_DIR/$zsh_config_file"
done

unset zsh_config_file

# Disable terminal beep (backspace, etc.)
unsetopt beep

. "$HOME/.local/bin/env"

# Hermes Agent command
case ":$PATH:" in *":$HOME/.local/bin:"*) ;; *) export PATH="$HOME/.local/bin:$PATH" ;; esac

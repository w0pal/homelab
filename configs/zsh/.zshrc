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
  theme
do
  [[ -r "$ZSH_CONFIG_DIR/$zsh_config_file" ]] && source "$ZSH_CONFIG_DIR/$zsh_config_file"
done

unset zsh_config_file


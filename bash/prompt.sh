# prompt.sh — bash prompt configuration
#
# Source from ~/.bashrc:
#   source ~/.config/nvim.tom/bash/prompt.sh
#
# Prompt layout:
#   (blank line)
#   user@host:~/path
#   $  |cursor

_nvimtom_prompt() {
  local reset='\[\e[0m\]'
  local green='\[\e[32m\]'
  local blue='\[\e[34m\]'
  local bold='\[\e[1m\]'

  # \n       — blank line before each prompt (separates command output clearly)
  # line 1   — user@host in green : path in blue
  # \n       — cursor on its own line
  # line 2   — $ (or # for root)
  PS1="\n${green}${bold}\u@\h${reset}:${blue}\w${reset}\n\$ "
}

_nvimtom_prompt
unset -f _nvimtom_prompt

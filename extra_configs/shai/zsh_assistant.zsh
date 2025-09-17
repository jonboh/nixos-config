os="NixOS" # use your distro to get more specific instructions
shell="zsh"
model="open-aigpt4-1106"

ask-assistant() {
    VISUAL="env OPENAI_API_KEY=$(pass show platform.openai.com_API_Key | head -1) shai ask --operating-system \"$os\" --shell \"$shell\" --model $model --edit-file"  zle edit-command-line
}
explain-assistant() {
    VISUAL="env OPENAI_API_KEY=$(pass show platform.openai.com_API_Key | head -1) shai explain --operating-system \"$os\" --shell \"$shell\" --model $model --edit-file" zle edit-command-line
}
# Bind a key combination to trigger the custom widget
zle -N ask-assistant
zle -N explain-assistant
bindkey '^[s' ask-assistant
bindkey '^[t' explain-assistant


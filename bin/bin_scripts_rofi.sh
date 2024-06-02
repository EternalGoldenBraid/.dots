#!/bin/bash
# selected=$(ls ~/bin/ | rofi -dmenu -p "Run: ") && bash ~/bin/$selected
selected=$(ls ~/bin/ | rofi -dmenu -p "Run: ") && ~/bin/$selected

#!/bin/bash

set -e

# Path to the color file and Xresources
color_file="$HOME/.config/.colors"
xresources_file="$HOME/.Xresources"

# Start with an empty .Xresources file
echo "Creating or clearing the existing .Xresources file..."
> "$xresources_file"

# Read each line from the color file
while IFS='=' read -r key value
do
  # Skip empty lines and lines starting with #
  [[ "$key" == "" || "$key" == "#"* ]] && continue
  
  # Write the color definition to the .Xresources file
  echo "*$key: $value" >> "$xresources_file"
done < "$color_file"

# Load the .Xresources file into the X resource database
echo "Loading the .Xresources file..."
xrdb -merge "$xresources_file"

echo "Done."

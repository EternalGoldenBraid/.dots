#!/bin/bash
set -e

cd ~/venvs
python -m venv neovim
source neovim/bin/activate
pip install debugpy neovim

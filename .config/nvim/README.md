

## Pyright + ALE Setup

✅ Pyright + ALE Setup (User-local, No Root)
1. Install Pyright Locally (No sudo)
```
npm install -g pyright --prefix=~/bin
```
This installs:

CLI to `~/bin/bin/pyright`

Node modules to `~/bin/lib/node_modules`

2. Add Pyright to Your Shell Path
`export PATH="$HOME/bin/bin:$PATH"`
`source ~/.bashrc`

3. Configure Neovim (init.lua)
Tell Neovim to find the pyright binary:

```
vim.env.PATH = os.getenv("HOME") .. "/bin/bin:" .. vim.env.PATH
vim.g.ale_python_pyright_executable = "pyright"
```

Make sure this runs before ALE loads.

4. Verify Inside Neovim
Run:
```
:echo executable('pyright')
```
Should return 1. Then:

```
:ALEInfo
```
Should show:

(executing command: pyright --stdio ...) # or success or smth

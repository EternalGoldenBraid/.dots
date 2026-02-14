# Generator Interface Contract

Use this contract for every app-specific theme generator.

## Goal

Keep each app renderer isolated and deterministic, while `generate_theme.py` handles:
- palette loading
- palette validation/defaults
- writing output files
- reload hooks (`theme-apply`)

## Function signature

Each app generator should expose:

```python
def render(palette: dict[str, str], source_path: str) -> str:
    ...
```

Rules:
- Input must be the already-validated palette dict.
- `source_path` is the absolute palette path for generated-file headers.
- Output is full file content as a string.
- No file I/O inside `render()`.
- No process execution inside `render()`.

## Binary target signature (images, non-text outputs)

For generated binaries, expose:

```python
def generate(palette: dict[str, str], source_path: str, **paths) -> None:
    ...
```

Rules:
- Input palette is already validated.
- `source_path` is used for traceability/comments when applicable.
- Accept explicit `Path` arguments (for example `input_path`, `output_path`).
- Perform deterministic generation only (no user prompts or interactive behavior).

## Registration shape (in `generate_theme.py`)

Keep one mapping in the orchestrator:

```python
TARGETS = {
  "tmux": {
    "out": "~/.dotfiles/.config/tmux/theme.generated.conf",
    "render": tmux.render,
  },
  ...
}
```

Orchestrator responsibilities only:
- expand output paths
- call renderer
- write output
- print generated paths
- call binary generators with explicit paths

## Style requirements

- Generated files must start with:
  - generator source comment
  - palette source comment
  - "do not edit by hand" note (format that fits the target language)
- Keep app-specific defaults inside orchestrator palette defaults, not inside per-app renderers.
- If a target has format limitations (example: Vifm 256-color), document it in generator comments.

## Adding a new app target

1. Add `scripts/generators/<app>.py` with `render()`.
2. Register it in orchestrator target map.
3. Add output path to `~/.dotfiles/.config/theme/README.md`.
4. Regenerate via `~/bin/theme-apply`.
5. Verify target app loads/reloads without warnings.

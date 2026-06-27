# Flutter Analyze Guidelines

This file documents how `flutter analyze` / `dart analyze` should be used in this project — both as a reference for Claude and as a `/analyze` slash command.

## Rules for Claude

- **Do NOT run `flutter analyze` on the whole project** — it's slow and rarely necessary.
- **Only run after multi-file changes** where type correctness is genuinely uncertain (e.g. refactoring a shared model, changing a function signature used in many places).
- **Scope to the affected directory** when you do run it:
  ```
  dart analyze lib/src/specific_folder/
  ```
- **Skip it entirely** for small, isolated changes: renaming a string, tweaking a color, adding a comment, changing UI layout only.
- **Prefer `dart analyze`** over `flutter analyze` — same result, slightly less overhead.

## Faster alternatives

| Situation | Command |
|-----------|---------|
| Check one file | `dart analyze lib/path/to/file.dart` |
| Check a feature folder | `dart analyze lib/src/feature/` |
| Watch mode (background) | `dart analyze --watch` |
| Full project check | `dart analyze` (only when needed) |

## When to use `/analyze`

Run `/analyze` when you want Claude to do a targeted analysis pass on recently changed files — it will scope the check rather than running the full project scan.
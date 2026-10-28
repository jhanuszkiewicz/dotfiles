#!/bin/bash
# builds WorkspacePeek (github.com/cynaberii/WorkspacePeek) with a paneru backend
# the original code isn't kept in dotfiles (repo has no license), only the patch:
#   PaneruClient.swift  - the paneru backend
#   config.json         - colors/settings, hswi swaps it with the preset
# needs swift (xcode-select --install)
set -e

HERE="$(cd "$(dirname "$0")" && pwd)"
SRC="$HOME/.cache/workspacepeek-src"

if [ -d "$SRC/.git" ]; then
  # drop the old patch, then update
  git -C "$SRC" checkout -- .
  git -C "$SRC" clean -fdq Sources
  git -C "$SRC" pull --ff-only -q
else
  git clone -q https://github.com/cynaberii/WorkspacePeek "$SRC"
fi

cp "$HERE/PaneruClient.swift" "$SRC/Sources/WorkspacePeek/"

# paneru goes first in the three backend functions
WM="$SRC/Sources/WorkspacePeek/WindowManager.swift"
perl -0pi -e '
  s/(static func listWorkspaces\(\) -> \[Workspace\] \{\n)(\s*)(useRift)/$1$2if PaneruClient.isActive { return PaneruClient.listWorkspaces() }\n$2return $3/;
  s/(static func focusedWorkspace\(\) -> String \{\n)(\s*)(useRift)/$1$2if PaneruClient.isActive { return PaneruClient.focusedWorkspace() }\n$2return $3/;
  s/(static func switchTo\(_ workspace: String\) \{\n)(\s*)(useRift)/$1$2if PaneruClient.isActive { PaneruClient.switchTo(workspace); return }\n$2$3/;
' "$WM"
if [ "$(grep -c 'PaneruClient.isActive' "$WM")" != "3" ]; then
  echo "patching WindowManager.swift failed (upstream changed?)"
  exit 1
fi

# config straight from dotfiles
if [ -e "$HOME/.config/workspacepeek" ] && [ ! -L "$HOME/.config/workspacepeek" ]; then
  mv "$HOME/.config/workspacepeek" "$HOME/.config/workspacepeek.bak"
  echo "old config moved to ~/.config/workspacepeek.bak"
fi
ln -sfn "$HERE" "$HOME/.config/workspacepeek"

bash "$SRC/install.sh"

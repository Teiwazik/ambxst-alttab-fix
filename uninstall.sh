#!/bin/sh
# Removes the shell patch. The Hyprland config lines stay, they are harmless without it.
set -eu
here=$(cd "$(dirname "$0")" && pwd)
ambxst=${AMBXST_DIR:-$HOME/.local/src/ambxst-shared}
patch -d "$ambxst" -p1 -R -s < "$here/ambxst-alttab.patch"
echo "Patch removed. Run: ambxst reload"

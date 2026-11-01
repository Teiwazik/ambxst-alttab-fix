#!/bin/sh
# Installs the Windows style Alt+Tab fix for Ambxst on Hyprland.
set -eu
here=$(cd "$(dirname "$0")" && pwd)
ambxst=${AMBXST_DIR:-$HOME/.local/src/ambxst-shared}
conf=${HYPR_CONF:-$HOME/.config/hypr/hyprland.lua}
bin=${BIN_DIR:-$HOME/.local/bin}
backup=$HOME/.local/state/ambxst-alttab-backup-$(date +%Y%m%d-%H%M%S)

[ -f "$ambxst/shell.qml" ] || { echo "Ambxst not found in $ambxst (set AMBXST_DIR)"; exit 1; }
[ -f "$conf" ] || { echo "Hyprland config not found: $conf (set HYPR_CONF)"; exit 1; }

if [ -f "$ambxst/modules/services/WindowSwitcher.qml" ]; then
    echo "Patch already applied, skipping shell files"
elif ! patch -d "$ambxst" -p1 --dry-run -s -f < "$here/ambxst-alttab.patch" >/dev/null; then
    echo "Patch does not fit this Ambxst version, nothing was changed"
    exit 1
else
    mkdir -p "$backup"
    cp "$conf" "$backup/"
    for f in modules/globals/GlobalStates.qml modules/services/GlobalShortcuts.qml modules/services/AxctlService.qml modules/widgets/overview/OverviewPopup.qml modules/widgets/overview/WindowSwitcherView.qml; do
        mkdir -p "$backup/$(dirname "$f")"
        cp "$ambxst/$f" "$backup/$f"
    done
    patch -d "$ambxst" -p1 -s < "$here/ambxst-alttab.patch"
    echo "Backup: $backup"
fi

mkdir -p "$bin"
install -m 755 "$here/qs-igpu" "$bin/qs-igpu"

if ! grep -q 'AMBXST_QS' "$conf"; then
    tmp=$(mktemp)
    { printf '%s\n' '-- The shell must stay on Intel, see ~/.local/bin/qs-igpu.' 'hl.env("AMBXST_QS", os.getenv("HOME") .. "/.local/bin/qs-igpu")' ''; cat "$conf"; } > "$tmp"
    cat "$tmp" > "$conf"; rm -f "$tmp"
fi

if ! grep -q 'Alt+Tab watches Alt itself' "$conf"; then
    cat >> "$conf" <<'LUA'

-- Holding Tab keeps moving through the list as on Windows, set to false to turn it off.
local altTabHoldRepeat = true

-- Alt+Tab watches Alt itself: the release binds below can lose the race with a fast Tab.
local altTabWatching = false
local function altDown()
    return hl.is_key_down("Alt_L") or hl.is_key_down("Alt_R")
end
local function watchAlt()
    if altDown() then
        hl.timer(watchAlt, { timeout = 25, type = "oneshot" })
    else
        altTabWatching = false
        hl.exec_cmd("ambxst run window-switcher-accept")
    end
end
local function altTab(command)
    return function()
        hl.exec_cmd("ambxst run " .. command)
        if altDown() and not altTabWatching then
            altTabWatching = true
            hl.timer(watchAlt, { timeout = 25, type = "oneshot" })
        end
    end
end
hl.unbind("ALT + Tab")
hl.unbind("ALT + SHIFT + Tab")
hl.bind("ALT + Tab", altTab("window-switcher"), { repeating = altTabHoldRepeat })
hl.bind("ALT + SHIFT + Tab", altTab("window-switcher-backward"), { repeating = altTabHoldRepeat })

-- Alt+Shift+Tab: commit the switcher even when Shift is still held as Alt goes up.
for _, key in ipairs({ "Alt_L", "Alt_R" }) do
    for _, mods in ipairs({ "SHIFT + ", "ALT + SHIFT + " }) do
        hl.bind(mods .. key, hl.dsp.exec_cmd("ambxst run window-switcher-accept"), { release = true, non_consuming = true })
    end
end
LUA
fi

echo "Done. Log out and back in to Hyprland to apply everything."

# ambxst-alttab-fix

Windows style Alt+Tab for the [Ambxst](https://github.com/Axenide/Ambxst) shell on Hyprland: instant on a quick tap, a list with real window previews while Alt is held, and no getting stuck.

Tested on Ambxst 1.3.13 and Hyprland 0.57.0 (Lua config) on an Intel + NVIDIA laptop.

## What you get

- **Quick tap:** Alt+Tab switches to the previous window straight away, with no overlay.
- **Hold Alt:** after 70 ms a list of windows appears, in most recently used order, across all workspaces.
- **Navigation:** Tab and Right go forward, Shift+Tab and Left go back. Holding Tab keeps moving through the list.
- **Choosing:** releasing Alt or pressing Enter switches to the selection, Esc cancels, and a click picks a window directly.
- **Previews:** each card keeps the shape of its window, and previews are ready when the list appears.
- **Theme:** colours, font and corner radius come from your Ambxst theme.

## Install

```sh
git clone https://github.com/Teiwazik/ambxst-alttab-fix
cd ambxst-alttab-fix
./install.sh
```

Then log out of Hyprland and back in.

The installer:

1. Patches the shell with `ambxst-alttab.patch`. It checks first with a dry run, and if the patch does not fit your Ambxst version it stops and changes nothing.
2. Copies `qs-igpu` to `~/.local/bin`.
3. Adds the Alt+Tab binds and `AMBXST_QS` to `~/.config/hypr/hyprland.lua`.

Backups of the changed files go to `~/.local/state/ambxst-alttab-backup-*`. Use `AMBXST_DIR`, `HYPR_CONF` and `BIN_DIR` for other locations. An Ambxst update can overwrite the patch, in which case run `./install.sh` again.

## Configuration

To stop a held Tab from moving through the list, set this in `~/.config/hypr/hyprland.lua` and run `hyprctl reload`:

```lua
local altTabHoldRepeat = false
```

The repeat speed follows the keyboard settings `repeat_rate` and `repeat_delay`. The delay before the list appears is `showDelay` in `modules/services/WindowSwitcher.qml`.

## Uninstall

```sh
./uninstall.sh
```

This removes the shell patch. The lines in `hyprland.lua` and the `qs-igpu` file stay behind, and they can be removed by hand or restored from the backup.

## Known issues

- The first press after a shell restart occasionally picks the wrong window. The cause is not found yet.
- With `grp:alt_shift_toggle` in `kb_options`, Alt+Shift+Tab is expected to switch the keyboard layout too. This has not been confirmed on a real keyboard. Moving the layout switch to another shortcut avoids it.
- The list closes instantly rather than fading out, so that switching is not delayed.
- Not tested: external monitors, windows on special workspaces, and the arrow keys.

See [PROBLEMS.md](PROBLEMS.md) for what was broken, how it was fixed and how it was tested.

## License

AGPL-3.0, the same as Ambxst, since the patch is derived from its code.

---

*Written with Claude, who now knows that Alt can be released before Tab has finished arriving. Causality is more of a suggestion once you fork a process.*

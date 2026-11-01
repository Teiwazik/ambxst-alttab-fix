# Problems found and fixed

| # | Problem | Cause | Fix |
|---|---|---|---|
| 1 | Alt+Tab picked the wrong window or stayed on the current one | `AxctlService.focusedClient` kept the old window forever, because it looked up the previous address before `is_focused` | Look for `is_focused` first |
| 2 | Wrong window order after a shell restart | Focus history lived only in the shell, and all other windows shared one placeholder value | Read the order from `hyprctl` at startup and after focus changes |
| 3 | The whole overlay flashed on a quick tap | The overlay opened immediately | Session logic moved to `WindowSwitcher.qml`, and the list appears after a short delay |
| 4 | The screen dimmed and animated | The switcher reused the dimming and animations of the workspace overview | Disabled for the switcher |
| 5 | Something else flashed before the window appeared | The workspace jumped to the target, back, and to the target again, because focus moved while the overlay was closing. Visible in a frame by frame recording | Focus moves 40 ms after the overlay closes. Hyprland events show one workspace change |
| 6 | The workspace overview could replace the list while closing | `shown` was reset before the module closed, so the Loader could swap components | Close order changed |
| 7 | The list stuck open until Enter on a sharp Alt+Tab | Binds spawn separate processes, so the Alt release could overtake Tab. Reproduced with a 70 ms gap | Hyprland watches Alt itself with `hl.is_key_down`, and the shell waits 150 ms for a late Tab |
| 8 | The list could stick on Alt+Shift+Tab | No release binds for Alt with Shift held | Added to `hyprland.lua` |
| 9 | Previews mixed up two windows of one app | Windows were matched by class and title | Matched by address |
| 10 | The shell crashed when showing previews | On NVIDIA, `ScreencopyView` aborts with "Failed to create egl image" | The shell runs on Intel through `qs-igpu`, and previews are captured once rather than live |
| 11 | Visible delay before the list: about 200 ms, and 825 ms on the first open | A 150 ms wait plus building the UI on first open | Wait reduced to 70 ms and the UI is compiled ahead of time |
| 12 | The next press could pick the wrong window after focus changed outside Alt+Tab | The shell missed quick intermediate focus changes | Order resynced from Hyprland 300 ms after each focus change |
| 13 | Rocket placeholder icons before previews appeared | Captures were requested only after the list appeared and took 30-75 ms | Placeholder removed. The overlay maps invisibly on the key press and appears once captures are ready, 130 ms at most |
| 14 | Selection motion felt abrupt | The list appeared instantly, the frame moved in 110 ms, and titles snapped to a new colour and weight | 150 ms fade in, 180 ms frame movement with soft braking, smooth colour changes, no bold |

## A fix that was reverted

`QSG_USE_SIMPLE_ANIMATION_DRIVER=1` looked better in a small test window, where a 400 ms animation stopped stretching to 514 ms. In the real list it dropped to 71 FPS with gaps of up to 36 ms and raised the shell's load on the Intel GPU from about 7% to 16-26%. The default Qt driver already steps at 6.94 ms on a 144 Hz display, with gaps of 6-7 ms, so it stays.

## Keyboard layout changes

Not fully explained. Synthetic Alt+Tab through `wtype` reproducibly switched the layout to English, but the layout was also found on English in a run without `wtype`. Shell commands for Alt+Tab, shell reloads, `hyprctl reload` and 20 seconds of idle did not change it. This repository does not use `wtype`.

## How it was tested

- Automated runs through `ambxst run`, in the order the binds send commands: 40 quick switches and 30 with the list per run, with no misses in the latest runs and no shell crashes.
- Real keyboard: 23 Alt+Tab presses with `hl.is_key_down` seeing Alt, and a held Tab moving through the list.
- Workspace changes counted on the Hyprland event socket, and motion checked in screen recordings.
- The installer tested on a copy of the original files.

`wtype` is not a valid test tool here: it sets Alt as a modifier state without real key events, so release binds never fire.

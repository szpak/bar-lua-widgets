# Auto Pause Break Reminder (BAR widget)

A quality-of-life Lua widget for
[**Beyond All Reason**](https://www.beyondallreason.info/) (a free & libre
RTS game) that automatically pauses the game at regular intervals to remind
players to take short stretch breaks, then resumes the game with audible and
visible warnings.

Designed to be **multiplayer-safe**, non-spammy, and respectful of manual
player actions.

---

![Auto pause break reminder BAR widget promo infographic](/images/auto-pause-break-reminder-bar-widget-infographic.jpg)

---

## Features

- ⏸ Automatically pauses the game every N minutes
- 🧘 Encourages short stretch breaks
- ⏱ Countdown with sound and messages before resume
- 💬 Selective multiplayer chat announcements
- 🤝 Respects manual pauses and manual unpausing
- ⚙ Configurable interval, duration, and sound

---

## Installation

1. Copy `widget_autopause_break.lua` into:

```
Beyond-All-Reason/data/LuaUI/Widgets/
```

2. Start BAR
3. Press **F11** → enable **Auto Pause Break Reminder** (usually scroll to the bottom)
4. Restart game if needed ("ENTER → `/luaui reload` → ENTER" might also help)

---

## Configuration

Configuration is persisted automatically by BAR.

Available options:
- `breakIntervalMinutes` (default: 30)
- `breakDurationMinutes` (default: 2)
- `soundEnabled` (default: true)
- `countManualPausesAsBreaks` (default: true)

---

## Multiplayer Behavior

- Announces widget activity when the game starts
- Announces break start to all players
- Announces resume at **10 seconds** and **1 second**
- All other countdown messages are local-only
- Uses `[AutoBreak]` prefix to avoid impersonation

---

## Usage Notes

- Best used with player agreement in multiplayer games (inform about that in the lobby before a battle is started)
- Manual pauses longer than the break duration are counted as valid breaks
- Manual unpausing cancels the current break immediately
- Break timing is based on **gameplay time**, not wall-clock time

---

## Skirmish vs AI

When playing against AI (especially in the testing/learning mode),
manual pauses are often tactical. You can disable treating manual pauses
as stretch breaks by setting:

```
countManualPausesAsBreaks = false
```

### Runtime configuration

Widget configuration is loaded once at game start.
To change settings during a game, use console commands:

```
/luaui autobreak manualpauses on|off
```

Then reload widgets with:

```
/luaui reload
```

---

## Known Limitations

- Pause/unpause commands are asynchronous (engine limitation)
- Widget must be enabled manually (F11)
- Chat announcements require pause permission in the game
- Sound file may vary between BAR versions (easy to change)

---

## Author

The widget was created by [szpak](https://github.com/szpak/) with heavily assist from AI (GPT-4.1).
Tested, debugged and overseen by Humans.

The promo infographic generated with Gemini 3.

---

## License

[GPLv2+](https://www.gnu.org/licenses/old-licenses/gpl-2.0.en.html)


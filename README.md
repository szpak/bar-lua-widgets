# Auto Pause Break Reminder (BAR widget)

A quality-of-life Lua widget for **Beyond All Reason** (a free & libre RTS
game) that automatically pauses the game at regular intervals to remind
players to take short stretch breaks, then resumes the game with audible and
visible warnings.

Designed to be **multiplayer-safe**, non-spammy, and respectful of manual
player actions.

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
3. Press **F11** → enable **Auto Pause Break Reminder**
4. Restart game if needed

---

## Configuration

Configuration is persisted automatically by BAR.

Available options:
- `breakIntervalMinutes` (default: 30)
- `breakDurationMinutes` (default: 2)
- `soundEnabled` (default: true)

---

## Multiplayer Behavior

- Announces widget activity when the game starts
- Announces break start to all players
- Announces resume at **10 seconds** and **1 second**
- All other countdown messages are local-only
- Uses `[AutoBreak]` prefix to avoid impersonation

---

## Usage Notes

- Best used with player agreement in multiplayer games
- Manual pauses longer than the break duration are counted as valid breaks
- Manual unpausing cancels the current break immediately
- Break timing is based on **gameplay time**, not wall-clock time

---

## Known Limitations

- Pause/unpause commands are asynchronous (engine limitation)
- Widget must be enabled manually (F11)
- Chat announcements require pause permission in the game
- Sound file may vary between BAR versions (easy to change)

---

## License

GPLv2+


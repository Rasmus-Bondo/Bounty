# HealthBarClient

Drives a custom health bar, XP progress bar, and level badge. Disables the default Roblox health bar on startup.

**Path:** `game.StarterGui.HealthDisplayGui.HealthBarClient`
**Type:** LocalScript (107 lines)
**Runs on:** Client

## How It Works

1. Disables default Roblox health bar via `StarterGui:SetCoreGuiEnabled(Enum.CoreGuiType.Health, false)`
2. On character added: connects to Humanoid.Health changes, updates health fill bar
3. Connects to PlayerStats.XP and leaderstats.Level changes, updates XP bar and level text

## GUI Elements

| Element | Path | Description |
|---------|------|-------------|
| HealthBar | Canvas.HealthBar | Health bar background |
| HealhBarDisplay | HealthBar.HealhBarDisplay | Fill bar (sized by health ratio) |
| HealthBarTextDisplay | Canvas.HealthTextBar.HealthBarTextDisplay | Rich text: bold current / gray max |
| XPBar | Canvas.XpBarDisplay.XPBar | XP fill bar |
| XPTextDisplay | Canvas.XpBarDisplay.XPTextDisplay | "420 / 1000 EXP" text |
| LevelBadge | Canvas.LevelBadge | Level display container |
| LevelText | LevelBadge.LevelText | "LV 5" text |

## Constants

| Constant | Value |
|----------|-------|
| XP_PER_LEVEL | 1000 |

## Health Display

- Fill bar width: `UDim2.new(ratio, 0, 1, 0)` where ratio = health/maxHealth
- Text format: `<b>75</b>/<font color="rgb(200, 200, 200)">100</font>` (rich text)

## XP Display

- XP in current level: `totalXP % XP_PER_LEVEL`
- Fill ratio: `xpInLevel / XP_PER_LEVEL`
- Text format: `"420 / 1000 EXP"`

## Dependencies

- Player character Humanoid — for health tracking
- `PlayerStats.XP` — IntValue created by [[DataService]]
- `leaderstats.Level` — IntValue created by [[LeaderstatService]]
- [[ProgressionService]] — awards XP server-side

## Used By

- Runs automatically in PlayerGui when the player joins

# ZoneIndicatorScript

Displays the current zone shrink phase with a color-coded label and countdown timer. Hidden when no zone is active.

**Path:** `game.StarterGui.ZoneIndicatorGui.ZoneIndicatorScript`
**Type:** LocalScript (48 lines)
**Runs on:** Client

## How It Works

1. Reads workspace attributes: `ZonePhase`, `ZonePhaseName`, `ZonePhaseTimeLeft`
2. If phase is 0 or no name: hides the frame
3. Otherwise: shows phase name with color-coded text and timer
4. Final phase (4+) shows "Final zone!" instead of countdown
5. Polls every 1 second for time updates

## Phase Colors

| Phase Name | Color |
|------------|-------|
| Exploration | Gold (220, 180, 80) |
| Pressure | Orange (255, 160, 50) |
| Event | Red-Orange (255, 100, 30) |
| Final | Red (255, 50, 20) |

## GUI Elements

| Element | Type | Description |
|---------|------|-------------|
| ZoneFrame | Frame | Container (hidden when inactive) |
| PhaseLabel | TextLabel | "Zone: Exploration" with phase color |
| TimerLabel | TextLabel | "Next phase: 1:30" or "Final zone!" |

## Workspace Attributes Read

| Attribute | Type | Set By |
|-----------|------|--------|
| ZonePhase | number | [[ZoneService]] |
| ZonePhaseName | string | [[ZoneService]] |
| ZonePhaseTimeLeft | number | [[ZoneService]] |

## Dependencies

- Workspace attributes set by [[ZoneService]]

## Used By

- Runs automatically in PlayerGui when the player joins

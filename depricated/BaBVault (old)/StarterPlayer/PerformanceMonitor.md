# PerformanceMonitor

FPS-based adaptive quality system — measures average framerate every 5 seconds and adjusts particle emission rates across three quality tiers to maintain performance on low-end devices.

**Path:** `game.StarterPlayer.StarterPlayerScripts.PerformanceMonitor`
**Type:** LocalScript (79 lines)
**Runs on:** Client

## How It Works

1. Counts frames via RenderStepped, calculates average FPS every SAMPLE_INTERVAL (5s)
2. Applies hysteresis to prevent rapid oscillation between tiers
3. On tier change: sets player attributes and scales all ParticleEmitters in workspace that have a "BaseRate" attribute

## Quality Tiers

| Tier | FPS Range | Particle Multiplier |
|------|-----------|-------------------|
| high | 50+ FPS | 1.0 (100%) |
| medium | 40-50 FPS | 0.5 (50%) |
| low | <40 FPS | 0.25 (25%) |

## Hysteresis Thresholds

| Direction | Threshold | Prevents |
|-----------|-----------|----------|
| Upgrade | 55+ FPS sustained | Upgrading too early |
| Downgrade | <38 FPS | Downgrading on minor dips |

## Player Attributes Set

| Attribute | Type | Purpose |
|-----------|------|---------|
| QualityLevel | string | "high", "medium", or "low" — readable by other scripts |
| ParticleMultiplier | number | 0.25 / 0.5 / 1.0 — direct multiplier value |

## Dependencies

- ParticleEmitters in workspace must have a "BaseRate" attribute to be affected
- No external script dependencies

## Used By

- Runs automatically for all players in StarterPlayerScripts
- Other scripts can read `player:GetAttribute("QualityLevel")` to adjust their own quality

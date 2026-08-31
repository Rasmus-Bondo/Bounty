# HitBoxTestTool FireServerScript

Legacy fire script — sends mouse hit position to server on click. Uses the deprecated Mouse object. Superseded by [[HitBoxTestTool GunClient]] which uses camera raycasting instead.

**Path:** `game.StarterPack.HitBoxTestTool.FireServerScript`
**Type:** LocalScript (12 lines)
**Runs on:** Client

## How It Works

1. Gets player mouse via `player:GetMouse()` (deprecated API)
2. On Tool.Activated: fires FireBullet RemoteEvent with `mouse.Hit.Position`
3. Plays FireSound directly on the tool

## Dependencies

- Internal FireBullet RemoteEvent
- FireSound on tool

## Used By

- [[HitBoxTestTool]] — likely inactive/superseded by [[HitBoxTestTool GunClient]]

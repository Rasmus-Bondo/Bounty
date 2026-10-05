---
tags:
  - shared
  - modulescript
  - external
  - combat
path: game.ReplicatedStorage.PVE.Packages.FastCastRedux
type: ModuleScript
lines: 145
---

# FastCastRedux

Third-party projectile library by Eti the Spirit: raycast-stepped bullets with travel time. Vendored as-is and not edited. This note covers the whole package; its internal submodules have no notes of their own.

## What it does

1. `FastCast.new()` creates a caster, meant to be one per gun, with `LengthChanged`, `RayHit`, `RayPierced` and `CastTerminating` signals
2. `FastCast.newBehavior()` returns a behavior table: raycast params, acceleration, max distance (default 1000), pierce callback, high-fidelity segmenting and cosmetic bullet settings
3. `caster:Fire(origin, direction, velocity, behavior)` starts an `ActiveCast` that steps the projectile and fires the caster's signals
4. Internal submodules: `ActiveCast` (per-bullet simulation), `Signal`, `Table`, `TypeDefinitions` and `TypeMarshaller`

## Dependencies

- **Requires:** Its own internal submodules only
- **Required by:** CombatServer

## Connections

None outside the package.

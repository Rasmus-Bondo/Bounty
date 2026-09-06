---
tags: [client, localscript, ui, combat, billboard]
path: game.StarterPlayer.StarterPlayerScripts.DamageNumberClient
type: LocalScript
lines: 233
---

# DamageNumberClient

Floating damage numbers over whoever the local player just hit — white body numbers that drift up, yellow `N!` headshot numbers that split in half and fly apart.

## What it does
1. Listens on the shared `HitConfirm` remote, which reaches the attacker and nobody else, and reads its trailing `(damage, victimName, victimCharacter)` payload.
2. `acquireLayer(victimCharacter)` returns one `BillboardGui` per victim, cached in a weak-keyed table — a five-shot burst reuses one billboard instead of building five. Adornee is the victim's `Head`, `AlwaysOnTop`, `MaxDistance` 600, `StudsOffsetWorldSpace` (0, 2.25, 0), `Size` 330x190 offset.
3. Under StreamingEnabled a character can replicate as an empty container, so a nil `Head` skips the number rather than yielding for a part that may never arrive.
4. `AncestryChanged` clears the cache entry when the billboard leaves the DataModel, so the next hit on a respawned character builds a fresh one instead of handing back a destroyed layer.
5. **Body hit** — white `GothamBlack` 43px with a (2,3) shadow at `TextTransparency` 0.22; scale 0.35 → 1.08 → 1, drifts up 58px over 0.78s with a random ±3° tilt, fades from 0.48s, destroyed at 0.82s.
6. **Headshot** — yellow (255,214,52) at 56px reading `<N>!`, scale 0.12 → 1.34 → 1. At 0.17s the single label is hidden and replaced by two halves — the leading digits and the last digit + `!` — which fly to (-68,-48) rotated -15° and (+76,-37) rotated +13°.
7. A running `zCounter` stacks each number over the previous one.

## Scope

Kept out of the crosshair state machine on purpose — the numbers have a separate lifetime and their own per-victim billboards. `HitMarkScript` binds `function(isHeadshot, didKill)` and ignores every trailing argument, which is why it needed no change when the payload grew.

Zone damage, fall damage and bot-dealt blows credit their kill from the victim's `LastDamager` attribute on the universal death handlers and never reach the hit pipeline, so they produce no number — correct, since the player did not shoot anyone.

## Dependencies
- **Requires:** Nothing
- **Required by:** Nobody

## Connections
### RemoteEvents
| Remote | Direction | Other script |
|--------|-----------|-------------|
| `HitConfirm` | ← Server | [[HunterHitPipeline]] for every weapon, [[HighNoonDamage]] for Dust's ultimate. Damage is the health-clamped figure, so a killing blow never reads as more than the target had left |

### BindableEvents
None.

### Direct require()
None.

## Notes
- The prototype's 180-stud `MaxDistance` was tuned on a dummy at close range; Vesper hits from far enough that a scoped shot would have drawn nothing, and the number is the only confirmation at a range where the hit flash is a few pixels wide.
- `BillboardGui` offset sizes are absolute screen pixels and do not shrink with distance, so the numbers stay full size while the target shrinks. Offsets inside one billboard share its pixel space, so the burst spread is device-independent.

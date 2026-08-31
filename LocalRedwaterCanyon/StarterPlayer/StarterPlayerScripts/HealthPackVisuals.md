---
tags:
  - client
  - localscript
  - combat
path: game.StarterPlayer.StarterPlayerScripts.HealthPackVisuals
type: LocalScript
lines: 87
---

# HealthPackVisuals

Client-side spin, hover, and visibility for health pack pickups. Keeps per-frame CFrame work off the network by running it locally.

## What it does

1. Subscribes to the `HealthPack` CollectionService tag (initial + `GetInstanceAddedSignal`) and caches a per-model entry holding the Pickup part, an anchor position (horizontally centered over the model's `Base` so angled stands don't drift, at the Pickup's authored float height), and a random starting hover phase. The Pickup parts must be `Anchored` — the script drives their CFrame every frame.
2. On `RunService.Heartbeat`, rotates each cached Pickup part around the Y axis at ~120 degrees/sec and bobs it 0–1 studs above its base position (sine lifted so the low point rests at base height, never dips into the ground; ~2s per cycle, phase-desynced per pack)
3. Watches `GetAttributeChangedSignal("Active")` on each model and toggles the Pickup part's Transparency (0 when active, 1 when consumed)
4. Skips spin/hover work for hidden pickups and self-cleans entries whose Pickup or model has been removed from the data model

## Dependencies

- **Requires:** Nothing
- **Required by:** Nobody

## Connections

### RemoteEvents

None

### BindableEvents

None

### Direct require()

None

### CollectionService Tags

| Tag | Usage | Defined by |
|-----|-------|-----------|
| `HealthPack` | Read via `GetTagged` to find Pickup parts to spin and to drive Pickup visibility from the model's `Active` attribute | [[HealthPackSystem]] |

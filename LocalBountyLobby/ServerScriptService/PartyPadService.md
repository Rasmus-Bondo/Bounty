---
tags: [server, script, lobby, party, teleport]
path: game.ServerScriptService.PartyPadService
type: Script
lines: 501
---

# PartyPadService

Server owner of the six lobby party pads: occupancy, party rules, ready-up countdown, idle eject and the reserved-server teleport into Secret (#63/#64).

## What it does
1. Collects every `Workspace.PartySystemPart` Model (six, sharing one name) that has a `TouchSystem` trigger and a `PartySystem` visual, sorts them by trigger X (descending) for stable ids, stamps `PadId` on each model and precomputes an eject CFrame beside the pad (tries +Z, -Z, +X, -X for a clear landing box, then raycasts to the ground).
2. Creates the `ReplicatedStorage.PartyPad` folder and its five RemoteEvents if missing.
3. Membership is a **footprint test**, not Touched: every 0.2s the HumanoidRootPart is projected into the trigger's object space and must sit inside its X/Z half-size and 0-8 studs above it. Leaving the footprint for 0.5s (`OUTSIDE_GRACE`) removes the player; there is no physical lock.
4. Up to 4 per pad; `occupants[1]` is the owner. Admission follows the rule: **open** (anyone), **friends** (only friends of the owner; `IsFriendsWith` runs in a spawned task and is cached, so a candidate is admitted on a later tick) or **closed** (nobody new). The rule resets to open when the pad empties. A 2s rejoin cooldown follows Leave or eject.
5. When every occupant is ready, a **5s countdown** starts; any join, leave or (un)ready re-decides it. At zero it reserves a server and calls `TeleportAsync` to Secret.
6. **30s idle eject**: an occupant unready for 30s is pivoted to the eject point and removed.
7. Teleport: `TeleportService:ReserveServer(SECRET_PLACE_ID)` then `TeleportAsync(SECRET_PLACE_ID, members, options)` with `ReservedServerAccessCode` and TeleportData `{ source = "lobby", partySize = #members, mission = pad.mission }` (#48; the owner picks one of `Easy`/`Mine`/`Escort`/`TNT`/`Valves`/`Hard`, default `Mine`, reset when the pad empties, and changing it clears every ready). `SECRET_PLACE_ID = 115630099004249` is a local constant because Secret has no GameEnvironment row yet (board issue #66). On failure it warns and retries after 10s; after success the pad unlocks 15s later and anyone bounced back by TeleportInitFailed must ready up again.
8. Pad visuals: writes the pad's `TextLabel` text (e.g. `OPEN 0/4`, `2/4 - 3s`, `FRIENDS 2/4 - 1 READY`, `FULL`, `SENDING...`) and colours the `PartySystem` union (sets `UsePartColor`).
9. Sends `PadState` to occupants only when a state signature changes; every client request is re-validated and rate-limited to one per 0.25s per player. Each pad steps under its own `pcall`.

## Dependencies
- **Requires:** Nothing
- **Required by:** Nobody

## Connections
### RemoteEvents
| Remote | Direction | Other script |
|--------|-----------|-------------|
| `PartyPad.SetRule` | ← Client | [[PartyPadClient]] owner sets `"open"`/`"friends"`/`"closed"`; ignored while sending |
| `PartyPad.SetMission` | ← Client | [[PartyPadClient]] owner picks the mission token; whitelisted, ignored while sending |
| `PartyPad.SetReady` | ← Client | [[PartyPadClient]] boolean ready toggle; unready restarts the idle timer |
| `PartyPad.Leave` | ← Client | [[PartyPadClient]] ejects the player beside the pad; ignored while sending |
| `PartyPad.PadState` | → Client | [[PartyPadClient]] `{pad, inPad=true, rule, mission, owner, max, sending, countdown, members={userId,name,ready}}`, or `{pad, inPad=false}` once on removal |

### BindableEvents
None

### Direct require()
None

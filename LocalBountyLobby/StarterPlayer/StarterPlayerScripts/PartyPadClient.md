---
tags: [client, localscript, lobby, party, ui]
path: game.StarterPlayer.StarterPlayerScripts.PartyPadClient
type: LocalScript
lines: 337
---

# PartyPadClient

Drives the authored StarterGui.PartyPadGui panel shown while the local player stands on a lobby party pad.

## What it does
1. Waits for PlayerGui.PartyPadGui (Canvas, PopScale, Background with Header, RuleHeading, RuleRow Open/Friends/Closed, MembersHeading, Members.MemberTemplate, Status, ButtonRow ReadyButton/LeaveButton). All structure is authored; the script only clones `MemberTemplate` per slot (forcing `SizeConstraint = RelativeXY`) and sets text, colour and visibility.
2. On `PadState` with `inPad=true`: shows the panel with a PopScale tween, renders `PAD n`, `PARTY x/4`, member rows (`(you)` suffix, owner tag, READY / NOT READY, empty rows as "Open slot") and highlights the active rule. Rule buttons are enabled only for the owner and only while not sending. On `inPad=false` it hides the panel, but only if the removal is for the pad currently shown.
3. Runs the countdown **locally**: `PadState` arrives only on change, so it stores `deadline = os.clock() + countdown` and a Heartbeat loop redraws the status line every frame while shown.
4. Status priority: `SENDING...` > `Departing in n...` > idle warning `Ready up or leave in ns` (last 10s of a 30s window; `IDLE_EJECT` mirrors the server constant and only drives this text) > `Waiting for n more to ready` / `Ready up to depart`.
5. **Ready** button toggles: fires `SetReady(not me.ready)`; its label flips READY (amber) / UNREADY (leather). **Leave** button fires `Leave()`. Both are disabled (faded) while sending, ignored without a state, and debounced to 0.3s client-side. Rule buttons fire `SetRule(rule)` only for the owner and only if the rule differs. There is **no keyboard binding** (no B key) - every action is a button `Activated` handler.
6. Each press plays a dip/settle tween on a runtime `PressScale` UIScale and a click cloned from ReplicatedStorage.SFX.UIButtonClick.UIClick with the `SFX` SoundGroup.

## Dependencies
- **Requires:** Nothing
- **Required by:** Nobody

## Connections
### RemoteEvents
| Remote | Direction | Other script |
|--------|-----------|-------------|
| `PartyPad.SetRule` | → Server | [[PartyPadService]] owner picks open/friends/closed |
| `PartyPad.SetReady` | → Server | [[PartyPadService]] ready / unready toggle |
| `PartyPad.Leave` | → Server | [[PartyPadService]] leave the pad (server moves the player off) |
| `PartyPad.PadState` | ← Server | [[PartyPadService]] full pad state on change, or `inPad=false` on removal |

### BindableEvents
None

### Direct require()
None

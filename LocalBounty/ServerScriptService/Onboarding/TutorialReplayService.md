---
tags: [server, modulescript, onboarding, tutorial, teleport]
path: game.ServerScriptService.Onboarding.TutorialReplayService
type: ModuleScript
lines: 302
---

# TutorialReplayService

Sends a player who asks for the tutorial again from the CHANGE MODE picker to a freshly reserved solo Redwater tutorial server.

## What it does
1. Owns the `TutorialReplayRequest` RemoteEvent (created in `Start()`), which is deliberately a **separate remote from `PlayTeleportEvent`** rather than a mode argument on it: PartyService's handler ignores extra arguments, so a mode passed there would start a deathmatch teleport as well as a tutorial one
2. Reserves the destination through `MatchmakingService.reserveTutorialServer()` — which publishes `{ code, tutorial = true }` into the access-code map and **no directory entry**, so the server is never matchmade into. Redwater resolves `State.tutorialMode` from that map at boot, which is why the replay needed no routing change on the Redwater side
3. Teleports solo with `TeleportOptions.ReservedServerAccessCode` and `TeleportData = { tutorial, redwaterAccessCode, tutorialReplay, characterSelections }`. The lesson is always Dust/Default regardless of what the player has equipped
4. **Refuses a player who is in a party**, answering `TeleportFailed` with "Leave your party to replay the tutorial." A tutorial server is solo by construction — no `groupId`, no `members`, no directory entry — so there is no shape of this teleport that takes a party along; sending only the presser would silently strand the rest of the party in the lobby
5. Rate-limits to one accepted request per `REPLAY_COOLDOWN_SECONDS` (15) per account, separate from the `dispatching` double-click guard. Every replay reserves a real Roblox private server, so the cooldown exists to stop a mashed button minting them
6. Runs the same 3-attempt teleport ladder as the other four teleport paths in this place (2s x attempt, 5s backoff on Flooded/GameFull/IsTeleporting, Unauthorized terminal), plus a 3-attempt ladder on `ReserveServer` itself, which is the likeliest transient failure here
7. Filters `TeleportService.TeleportInitFailed` against its own `pending` table. **Five ladders now listen on that one signal in this place** (PartyService, FriendJoinService, FollowJoinService, TutorialDispatchService, this) and all five send to the same place id, so each ignoring teleports it did not start is what stops them re-routing each other's players
8. Fires `TeleportFailed` on **every** refusal including the cheap ones (party, cooldown), because ReworkedUIPlay resets its teleport debounce off that message — a silent refusal leaves the PLAY sign dead until the client's own 15s timeout

## Four things a replay must not touch
Each is load-bearing somewhere else, and the module writes none of them:

- **`Tutorial.Attempts`** — the first-timer dispatch budget (TutorialDispatchService refuses at >= 2), and DataService's grandfather screen reads `Attempts > 0` as "already in the flow". Spending it on replays would disqualify an account from onboarding it has not had
- **`Tutorial.Completed` / `CompletedAt`** — already true for anyone who can reach the picker
- **The payout** — Redwater's TutorialDirector pays from `Tutorial.BonusPaid`, which is once per account and burned by the first instalment. A replay reaches `payOut` and is paid 0 by the ordinary rule; nothing here writes `BonusPaid` and nothing here hands Redwater a reason to skip it
- **The Tutorial funnel** — `tutorialReplay = true` is a **telemetry flag only**. It gates nothing about the lesson and nothing about the reward. No `tutorialFunnelId` is minted here for the same reason: that session id belongs to a first run

## Why it is not part of TutorialDispatchService
The split is about what each module is for, not file size. Dispatch answers *"who should be OFFERED onboarding"*, and every rule in it — `Tutorial.Completed`, the two-Attempt budget, the invite card, the "no TeleportData on arrival" test — exists to stop the lesson happening to someone twice. A replay is the opposite question, asked out loud by the player, and none of those rules apply. Folding it in would mean threading an "exempt" flag through all of them, which is how a gate stops being a gate.

## Dependencies
- **Requires:** [[GameEnvironment]], [[MatchmakingService]], [[PartyService]]
- **Required by:** Main

## Connections
### RemoteEvents
| Remote | Direction | Other script |
|--------|-----------|-------------|
| `TutorialReplayRequest` | <- Client | [[ReworkedUIPlay]] fires it when PLAY is pressed with the picker set to TUTORIAL |
| `TutorialReplayRequest` | -> Client | [[ReworkedUIPlay]] TeleportQueued / TeleportFailed, the same status pair PlayTeleportEvent uses |

### BindableEvents
None

### Direct require()
| Target | Function | Purpose |
|--------|----------|---------|
| [[GameEnvironment]] | `redwaterPlaceId` | The destination, resolved per-universe so a DEV lobby cannot send a tester into a live tutorial server |
| [[MatchmakingService]] | `reserveTutorialServer()` | Reserve a private Redwater server flagged `tutorial` in the access-code map and absent from the directory |
| [[PartyService]] | `isInParty(player)` | Refuse the replay while the player is in a party, using the same membership resolver the party's own owner checks use |

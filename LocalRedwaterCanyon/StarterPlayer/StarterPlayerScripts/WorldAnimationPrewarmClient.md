---
tags: [client, localscript, animation, world-model, viewmodel, bots, emotes, performance]
path: game.StarterPlayer.StarterPlayerScripts.WorldAnimationPrewarmClient
type: LocalScript
lines: 291
---

# WorldAnimationPrewarmClient

Resolves every animation clip this client will be asked to render — on somebody else's rig, in its own hands, or on the match-end podium — before it is asked to. The client-side half of the animation fetch guard.

## What it does
Every hunter id resolves through [[HunterAnimations]] — the manifests are the one home of clip identity — so this script can never disagree with what the loaders will ask for.

1. **Tier 1, immediate — the hunter world-gun clips.** Every manifest-declared `World` clip of every hunter (`HunterAnimations.set(name, "World")` per hunter). All custom group uploads, and the clips the original failure was in.
2. **Tier 2, as early as `SelectedHunter` resolves — the local player's own viewmodel.** Reads the hunter from [[HunterGate]] `GetSelectedHunter` (15s ceiling, above the gate's own 10s default) and warms that hunter's manifest `Viewmodel` set, folded with the local player's `EquippedWeaponSkin_<Hunter>` overrides so the clips that will actually play are the ones warmed. This is the only tier with a deadline attached: the clips are wanted the instant the character spawns, and a miss is the player's own gun sitting still.
3. **Tier 3, deferred — the 48 bot clips.** The three static ids from BotController plus every `Animation` descendant of `ReplicatedStorage.BotAnimate.Animate`, held until the local character exists plus a 3s cushion so they do not contend with map streaming and the viewmodel during the join burst.
4. **Tier 4, deferred further — `HunterAnimations.allIds()` and the whole emote catalog.** `allIds()` is every manifest id in the universe (all hunters, both kinds, every skin override), superseding the tiers above; prewarm skips anything already fetched. Neither is needed at join: a hunter switch is offered from the kill cam, and the showcase emote not until the buzzer. `REMAINDER_PREWARM_DELAY` (5s) puts both behind the bot tier.
5. **Re-warms on a mid-match hunter switch** via [[HunterGate]] `ConnectHunterChanged`. `AnimationLoader.prewarm` skips any id already `Success`, so re-warming a set tier 4 already covered is close to free — this exists for the case where the switch lands while tier 4 is still in flight.
6. **Retries anything short of `Success` at 5s and 15s, then warns once at 45s** naming the ids, per tier. A CDN blip is transient by definition, and `AnimationLoader`'s `resolve()` only short-circuits on a cached `Success`, so a previous `Failure` genuinely refetches.
7. **De-dupes each tier before warming**, so a clip shared between hunters or skins is fetched once and the warn message stays readable.

## How each set is found
Nothing here is a hardcoded path list, and since 2026-08-29 nothing here walks a rig either.

- **Hunter clips (world and viewmodel) come from the manifests via [[HunterAnimations]]** — `set()` per hunter/kind for the ordered tiers, `allIds()` for the tail. Author backups and dead rig sets can no longer leak in, because instances are not read at all.
- **Hunters are discovered, not listed** — `ReplicatedStorage.Hunters` is scanned for children carrying a `Config.Manifest`, which finds the four and drops `Shared` on its own. A fifth hunter warms its sets without anyone editing this script.
- **`BotAnimate.Animate`** uses `GetDescendants` (the stock Animate layout nests each `Animation` one level inside a named `StringValue`, and `idle` alone holds two).
- **Emote ids come from [[EmoteConfig]]** `list()` + `get()`, because the showcase plays whatever the finishing players had equipped and those ids do not reach this client until the match-end payload — there is no instance to walk and no earlier notice.

**Owner-verified in play 2026-08-07, mobile and PC, all four hunters** (pre-migration behaviour; the ids warmed are identical after it) — every hunter's own gun animating, no new warns, no join-time hitch from the deferred tiers. That is the absence of harm, which is all a clean session can show: this script only *does* anything when a fetch fails, and a CDN failure cannot be induced on demand. The retry-and-warn path stays unproven in play by construction.

## Why this exists
`AnimationLoader` guards a load where the load happens. HunterWorldModel and BotController both run on the **server**, so the guard they were given covers the server's own fetch and nothing else. A server-played track replicates to each client as a bare asset id, and every client then downloads the clip itself — which the server never learns about. That client-side fetch is the one the 2026-08-07 log actually showed failing: the error appeared `(x2)`, once per connected client, never on the server.

The same holds for a clip played by another **player's** client, because a character's network owner plays the track and it reaches everyone else as an id. Dust's world revolver hold is prewarmed in WorldRevolverAimIdleClient, but that script returns early unless the local player *is* Dust — so it warms the clip on the one client that will never need to fetch it, and on none of the clients that will.

Bot clips belong here for the same reason: BotVisualClient renders a bot from a clone whose Motor6D transforms are copied off the server rig each frame, and the server rig is animated on this client by this client's own Animator, so a bot's clips are fetched here exactly like a player's.

**The first-person viewmodel is a different symptom with the same root:** the loaders build their tracks at spawn time, which pays any cold fetch at the moment of need rather than ahead of it. Warming every hunter's set here turns that cost into a no-op. The showcase emote at VictoryShowcaseClient's `playVictoryAnimation` is a raw pattern wrapped in a `pcall` that by construction cannot see a fetch failure, which is why the emote catalog is warmed here too.

**This never makes a clip play.** A replicated track fetches on its own the moment it arrives; prewarming only pays that cost early, and turns "never arrived" from silence into a warn. Nothing downstream depends on its timing, which is what makes the deferred tiers free.

It lives at the **top level** of `StarterPlayerScripts`, ungated, because most of what it warms is what you see on *other* people — every viewer needs it whatever their own hunter is. The viewmodel tier reads `SelectedHunter` to pick an **order**, not to gate. HunterClientLoader would disable this inside a hunter folder.

## Dependencies
- **Requires:** [[AnimationLoader]], [[HunterGate]], [[HunterAnimations]], [[EmoteConfig]]
- **Required by:** Nobody

## Connections
### RemoteEvents
None

### BindableEvents
None

### Direct require()
| Target | Function | Purpose |
|--------|----------|---------|
| [[AnimationLoader]] | `AnimationLoader.prewarm()` | Warm each tier's ids; never yields the caller, and skips an id already `Success` or already in flight |
| [[AnimationLoader]] | `AnimationLoader.getStatus()` | Read the cached `Enum.AssetFetchStatus` per id to decide what still needs a retry, and what to name in the final warn |
| [[HunterGate]] | `GetSelectedHunter()`, `ConnectHunterChanged()` | Pick which hunter's viewmodel to warm first, and re-warm on a mid-match switch |
| [[HunterAnimations]] | `set()`, `allIds()` | Resolve every hunter clip id from the manifests — world tier, viewmodel tier, and the everything tail |
| [[EmoteConfig]] | `list()`, `get()` | Enumerate the 18 showcase emote ids, which exist in no instance before the match-end payload |

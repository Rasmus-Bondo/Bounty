---
tags:
  - client
  - localscript
  - vfx
  - audio
  - bots
path: game.StarterPlayer.StarterPlayerScripts.BotVisualClient
type: LocalScript
lines: 1477
---

# BotVisualClient

Renders smooth local copies of the server-authoritative bot rigs, and plays every bot-facing weapon, ability, and ultimate effect.

## What it does

1. Watches the `ArenaBot` CollectionService tag (added by [[BotController]]). For each tagged server rig it clones a local "visual" into a `ClientBotVisuals` folder in workspace, then hides the server original — the server rig teleports on replication, so the clone is what the player actually sees
2. Waits for a complete rig before cloning (`HumanoidRootPart` + ≥15 parts + the hunter's world cosmetic, stable across 2 frames) — tags replicate before parts, which previously produced invisible bots
3. Strips the clone: removes scripts, BillboardGuis, and the `ArenaBot`/`AimAssistTarget` tags; unanchors everything but the root; only invisible `BotAssistHitbox` parts stay `CanQuery` so local rays resolve through the generous server hitbox. Sets `IsBotVisual` and inherits `BotId` from the source, which is how [[AimAssistController]] and KillCamClient find this clone from the server rig
4. Note the hidden server rig stays `CanQuery` — it's hidden with `LocalTransparencyModifier`, not made non-queryable — so both rigs carry overlapping queryable hitboxes. Anything raycasting at a bot has to decide which of the two it means; [[AimAssistController]] excludes the hidden rig from its line-of-sight ray for this reason. `LocalTransparencyModifier` also does **not** hide a `Highlight`, which draws its fill and outline whatever the adornee's parts are set to — so `hideServerInstance` disables Highlights explicitly, or a server-made glow would render on the hidden rig at the raw authoritative position, jittering beside the smoothed visual's own. It disables only the ones that actually **draw this rig** — a nil `Adornee` (which falls back to the Parent, i.e. the server bounty glow) or an `Adornee` that is the rig or a descendant of it. Disabling every Highlight by class was too broad: the reveal Vesper's Pinning Round puts on a victim parents onto the server rig but adorns the `ClientBotVisuals` clone, so from 2026-08-04 (when this branch was added for the bounty glow) until 2026-08-05 her mark was created correctly and then switched off a frame later, invisible against every bot while still working against real players. `Adornee` is read when the Highlight is parented, so a writer that sets it afterwards would still be caught
5. Every `RenderStepped`, smooths each visual toward its source pivot: translation, vertical, and rotation are blended on separate alphas, with a ground-lock raycast that snaps grounded bots to the floor and a snap distance for recovery teleports. `smoothTime` defaults to 0.09, so a running bot's visual trails its server rig by roughly a stud
6. Copies `Motor6D.Transform` from the authoritative rig each frame so the visual inherits the real `BotAnimate` 2D directional blend instead of a faked lean — including each hunter's world idle/shoot animation, so Bram cradles the Grudgekeeper via Vesper's two-handed hold animation (played on the server rig by [[BotController]]) instead of a hardcoded arm pose
7. Mirrors ragdoll state (`IsRagdolled` attribute): disables constraints on the clone and lerps part CFrames directly
8. `BotShotFX` → per-hunter shot FX: Dust muzzle flash + smoke + tracer + fire sound, Fortuna curved spinning card with trail, Vesper sniper tracer, and Bram a shotgun muzzle flash (neon ball + point light) + orange pellet-fan tracer + layered `Hunters.Bram.SFX.ShootFirst`/`Shoot` report. Shot origin is resolved from the *local* visual's muzzle so the tracer starts where the player sees the gun
9. `BotUltimateFX` → Dust High Noon renders through the shared [[HighNoonPublicFX]] module (identical red highlight, start warning cue, eagle/mid world sounds, and dust ring that real Dust casters get); Fortuna's card volley hides the visual and orbits cards outward and back
10. The bot config passes `StartSoundTemplate` with no `SkipStartSound` — a bot is never the local caster, so the warning cue always plays and a bot ult is as audible as an enemy player's. The bot's FX window is exactly `LockInTime` (2s), which is why the module lets one-shot cues ring out past `End` instead of fading them
11. **Bram Last Call** (`playBramUltimateStart`/`stopBramUltimate`): a blacked-out `Highlight` with a bright rim (`12,12,15` fill at 0.5, `240,245,255` outline, Occluded) on the visual for the ult duration. Last Call is a buff rather than a cast, so without a tell its 50% damage reduction just reads as bullets not registering. **Recoloured 2026-08-05** out of its original ember palette, which players were mistaking for the gold bounty glow two entries below — the two properties must stay identical to `LAST_CALL_FILL_COLOR`/`LAST_CALL_OUTLINE_COLOR` in `BramWorldFXClient`, so a colour changed in one place is a bot Bram that still looks wrong. Highlight-only — `Hunters.Bram.SFX` has no ultimate sound, only `Reload`/`Shoot`/`ShootFirst`/`ShotgunReloadMovement`. Pinned to the model the cast started on (like Dust's) and backed by a `duration + 0.5s` self-clear, so a missed `End` cannot mark a bot for the rest of the round
12. `BotFortunaCardFX` → `Stick`/`Remove`/`Recall`/`Clear` modes for Fortuna's persistent stuck cards, including cards that track a moving target part and queued recalls for cards still in flight
13. **Bounty glow** (`setBountyHighlight`/`refreshBountyHighlights`): a bot carrying a bounty gets the same see-through-walls gold `Highlight` a marked player gets. It is built here rather than replicating from [[BountyService]] for the same reason Last Call is — the server rig is hidden part-by-part, so a server-made Highlight would adorn something nobody renders. Properties are kept in sync with `applyHighlight` in [[BountyService]], which stays the owner for players and for the `ClientVisualSmoothing = false` path (no visual is built there, so the server rig's own Highlight is the one that shows). Driven off the `BountyListUpdated` **snapshot**, not the placed/removed edges: it is full state republished on a ~1s loop, so it self-heals when the client joined mid-bounty, when the visual was built after the bot was marked (`createVisual` waits up to 3s for a complete rig and loses that race routinely), or when an edge event was missed. `createVisual` also paints it once on creation so a already-marked bot is not dark until the next snapshot
14. Cleans up on tag removal or the source leaving workspace: disconnects, restores server-rig visibility, destroys the visual, clears stuck cards, and stops any in-flight High Noon or Last Call FX

## Team modes

The visual clone carries the team read, because the server rig is hidden part-by-part and a
server-side Highlight would adorn a body nobody is looking at. Two Highlights are built here, and
they are the client mirrors of the player-rig copies:

- `TeamOutline` -- outline only, fill fully transparent so purchased skins stay visible, `Occluded`
  rather than through-wall, and `OutlineTransparency = 0.45` so fourteen outlined fighters read as
  teams rather than as noise.
- The bounty glow, which takes the **team colour** when the clone carries a `Team` attribute and
  stays gold in FFA. It also wins the rig over the team outline while it is up.

Both colours come from [[TeamView]] and are therefore **relative** — the viewer's own side is blue
and every other side red, so the same bot is painted differently on the two halves of the server.
There is no pair to keep in step any more: the player-rig copies went the same way, into
TeamVisualClient, and TeamView is the only module that holds one.

Both are repainted on `TeamView.onChanged`. Every bot on screen already has an outline by the time
the viewer's own stamp lands, so without that the whole first round renders in absolute colours.

## Dependencies

- **Requires:** [[HighNoonPublicFX]], [[RevolverVFXService]], [[laserBeamEffect]], [[TeamView]]
- **Required by:** Nobody

## Connections

### RemoteEvents

| Remote | Direction | Other script |
|--------|-----------|--------------|
| `BotTransformUpdate` | ← Server | [[BotService]] batches bot pivot/velocity/grapple state each tick (UnreliableRemoteEvent); drives the local visuals' interpolation |
| `BotShotFX` | ← Server | [[BotCombat]] broadcasts bot muzzle/tracer per shot (UnreliableRemoteEvent) |
| `BotUltimateFX` | ← Server | [[BotCombat]] broadcasts `Start`/`End` for Dust, Fortuna, and Bram ultimates |
| `BotFortunaCardFX` | ← Server | [[BotCombat]] broadcasts Fortuna card stick/remove/recall/clear |
| `BountyListUpdated` | ← Server | [[BountyService]] publishes the full bounty snapshot on change and on a ~1s loop; the negative `userId` entries are bot record ids, and drive the local bounty glow |

### BindableEvents

None

### Direct require()

| Target | Function | Purpose |
|--------|----------|---------|
| [[HighNoonPublicFX]] | `.new()`, `:StartCasterPublicUltimateFX()`, `:StopCasterPublicUltimateFX()` | Dust bot High Noon public FX — the module adorns a Model directly, so the bot's local visual stands in for a player character |
| [[RevolverVFXService]] | `.PlayMuzzleEffects()` | Dust bot muzzle flash + smoke |
| [[laserBeamEffect]] | `(origin, finish, templates)` | Dust and Vesper bot shot tracers |

### CollectionService Tags

| Tag | Usage | Defined by |
|-----|-------|-----------|
| `ArenaBot` | Read via `GetInstanceAddedSignal`/`GetInstanceRemovedSignal`/`GetTagged` to build and tear down local visuals; removed from the clone so the clone is never mistaken for a real bot | [[BotController]] |
| `AimAssistTarget` | Removed from the clone so the clone is never double-counted as its own acquire candidate. [[AimAssistController]] still finds the bot via the tagged server rig, then resolves it back to this clone by `BotId` and aims at the clone — the rendered copy is what the player sees and centers on | [[BotController]] |

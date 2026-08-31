# Hunter Animation System — Tier C Spec

**Status:** Phase 1 BUILT 2026-08-29 (this spec's §7 steps 0-8 complete: manifests carry
`Animations`, `HunterAnimations` shipped, all 17 sites converted, `Normalize` trimmed, mirrored to
Frostbite and fold-verified; §8's playtest matrix still owed). **§5's `Audit`/`ClipManifest` rewrite
also landed 2026-08-29**, ahead of the deletions and deliberately: it is code-only, so it reverts
like the rest of Phase 1, and while the instances are still there it can compare manifest against
rig — which is the one check that catches an animator editing a clip nothing reads. Phase 2 (§6) is
therefore now **deletions only**, plus dropping the transitional halves of those two functions.
Written 2026-08-29 from a full audit of all three places.
**Scope:** Redwater Canyon + Frostbite Claim (mirrored). Bounty is *not* affected — its animation
paths already run through `AnimationLoader` correctly and read nothing from `Hunters`.

**Prerequisite:** Tier A shipped on 2026-08-29 (see `changelog/UNRELEASED.md`). This spec assumes
that state: Dust's `Run` clip installed on his Default rig, Fortuna's `Idle` loaded, the four
infinite-yield `WaitForChild` sites warn-and-degrade, and every raw `animator:LoadAnimation` outside
`AnimationLoader` and the stock `Animate` scripts is gone.

---

## 1. Why

A clip's identity currently has **five homes**, and only two of them are load-bearing:

| Home | Read by | Load-bearing? |
|---|---|---|
| `Hunters.<H>.ViewmodelAnimations.<Clip>` | **nothing** | no — pure drop-zone |
| `Hunters.<H>.Weapon.Viewmodel.Default.<Rig>.AnimationController.<Clip>` | every viewmodel loader | **yes** |
| the same clip re-declared on each skin rig under `.Skins` | the loader, when the skin is equipped | **yes** |
| `Hunters.<H>.WorldAnimations.<Clip>` | world visual servers, `BotController` | **yes** |
| string literals in code (Dust's two world ids, in **four** files) | those four files | **yes** |

Every regression in this system traces to that split:

- An animator drops clips in `ViewmodelAnimations`, everything looks wired in the Explorer, and
  nothing changes in game. **Dust's `Run` and `Walk` sat there unwired for weeks** — Run was
  installed in Tier A, Walk is still unused.
- A skin forked before a re-author keeps the old ids, and **an id that merely differs from the
  default is indistinguishable from a deliberate override**, so no audit can flag it. This is how
  Frostbite's Icefang kept the July clips for three weeks. `HunterViewmodelContract`'s own header
  admits it can never close this hole.
- Renaming a world clip infinite-yielded a `WaitForChild` and took out the whole script, not just
  the animation — Bram lost his third-person shotgun that way. (Fixed in Tier A, but the *shape*
  that allowed it — name-keyed instance lookup with no schema — is still there.)
- Dust's world ids are duplicated across four files with nothing enforcing agreement.

**The fix is to give a clip exactly one home: a plain-data table in the hunter's `Manifest`, which
is already mirrored, already required by every runtime, and already pure data with zero side
effects.** An override then becomes an explicit entry rather than an id that happens to differ.

---

## 2. Current state — the exact tables to migrate

Generated from the live Redwater rigs on 2026-08-29. **Frostbite is byte-identical** (`ClipManifest`
reads `TOTAL 621 clips, 62693 chars, sum=1507403153` in both). Every id below was verified to fetch
`Enum.AssetFetchStatus.Success`.

**No skin carries a single override.** All seven skin viewmodels inherit every clip from their
hunter's Default rig. The `Skins` override table therefore starts **empty** — this is what makes the
migration safe, and it is worth re-verifying before you start (§7, step 0).

### Dust — Default rig `ArmsViewModelRevolverNew`
```lua
Viewmodel = {
    Fanning  = "rbxassetid://127934175230422",
    Idle     = "rbxassetid://103595586831507",
    Reload   = "rbxassetid://98518914454467",
    Run      = "rbxassetid://139780223725801",   -- installed in Tier A
    Shoot    = "rbxassetid://86496527884983",
    Ultimate = "rbxassetid://103085980558303",
    Walk     = "rbxassetid://71737928047376",    -- installed in Tier A
},
World = {
    -- Dust authors NO world Animation instances; his WorldAnimations folder is empty.
    -- These two ids are currently string literals in FOUR files. This table replaces all four.
    Idle     = "rbxassetid://85888566430136",
    Shooting = "rbxassetid://123958453269998",
},
-- Skins HellFire, BetaRevolver, Icefang: no overrides.
```

### Vesper — Default rig `ArmsViewModelSniper`
```lua
Viewmodel = {
    -- BasicReload (107224384288403) was deleted from both Vesper rigs on 2026-08-29. Do not
    -- reintroduce it: it poses only 6 of the rig's 12 animated parts and was the back half of
    -- the two-clip shot the 2026-08-11 rework merged into Shoot.
    Idle        = "rbxassetid://103153584743199",
    Reload      = "rbxassetid://73583544224104",
    Scope       = "rbxassetid://93422535311122",
    Shoot       = "rbxassetid://84860686696858",
    Sprint      = "rbxassetid://125036411554611",
    Ultimate    = "rbxassetid://121214634495022",
},
World = {
    Idle     = "rbxassetid://90093651135788",
    Scope    = "rbxassetid://107172454211140",
    Shooting = "rbxassetid://79904449848853",
},
-- Skin Frostpiercer: no overrides.
```

### Bram — Default rig `DefaultViewmodel`
```lua
Viewmodel = {
    Charge        = "rbxassetid://123844287102793",
    Idle          = "rbxassetid://89197463725718",
    Reload        = "rbxassetid://117768481236234",
    Run           = "rbxassetid://139943245326602",
    Shoot         = "rbxassetid://93041883597128",
    ShrapnelShoot = "rbxassetid://137350091876899",  -- authored as "Ability" in ViewmodelAnimations
},
World = {
    Charge   = "rbxassetid://76968967438749",
    Idle     = "rbxassetid://104495381270539",
    Shooting = "rbxassetid://109149641341615",
},
-- Skin FrostbiteGrudgekeeper: no overrides.
```

### Fortuna — Default rig `ArmsViewModel`
```lua
Viewmodel = {
    ["1CardThrow"] = "rbxassetid://136498659064318",
    ["2CardThrow"] = "rbxassetid://108285637725405",
    ["3CardThrow"] = "rbxassetid://132589966113986",
    Basic          = "rbxassetid://78307906200615",
    Idle           = "rbxassetid://118040286576002",
    Recall         = "rbxassetid://84556638987770",
    Reload         = "rbxassetid://75789662685407",
    Run            = "rbxassetid://86455164376260",
    Ultimate       = "rbxassetid://89361073908392",
    Walk           = "rbxassetid://98958071667355",
},
World = {
    Idle     = "rbxassetid://94777312460639",
    Shooting = "rbxassetid://127167998229924",
    Ultimate = "rbxassetid://93080139820023",   -- players only; no bot loads a world Ultimate
},
-- Skins PrestigeCard, FrozenHand: no overrides.
```

> **Numeric-prefixed keys need brackets.** `1CardThrow` is not a valid Lua identifier. Write
> `["1CardThrow"]`. The current code looks these up by string, so nothing downstream changes.

### Clips that exist but nothing loads

Decide these explicitly during the migration rather than carrying them forward by inertia:

| Clip | Where | Status |
|---|---|---|
| ~~`Dust.ViewmodelAnimations.Walk`~~ | — | **Resolved 2026-08-29:** wired. Installed on the default rig and driven by `SetLocomotion`. In the table above. |
| ~~`Vesper` rig `BasicReload`~~ | — | **Resolved 2026-08-29:** deleted from both rigs in both places. Poses only 6 of 12 parts; not usable on the current rig. Do not reintroduce. |
| `Fortuna.Weapon.Viewmodel.BackupDefaultCards` | ReplicatedStorage | dead backup, has **duplicate-named** children (two `Ultimate`s, different ids). Delete in Phase 2. |
| `Fortuna.Weapon.Viewmodel.Skins.BackupPrestigeCard` | inside `Skins` | a Folder, not a Model, so it can never be equipped — but the prewarm walks it. Delete in Phase 2. |

The two resolved rows are the pattern to copy for the remaining two: **measure the clip before
deciding**. `BasicReload` looked like a judgement call until the KeyframeSequence showed it poses
half the rig, at which point there was nothing to weigh.

---

## 3. The new module — `ReplicatedStorage.Hunters.Shared.HunterAnimations`

Pure data access plus one loader. No state beyond what `AnimationLoader` already caches.

```lua
-- Resolve one clip id. skinName is optional; when given, an override wins over the base table.
-- Returns nil (never yields, never errors) when the hunter, kind or clip is unknown.
HunterAnimations.id(hunterName, kind, clipName, skinName) -> string?

-- The whole resolved set for a hunter, overrides folded in. { [clipName] = id }
HunterAnimations.set(hunterName, kind, skinName) -> { [string]: string }

-- Every id in the universe, deduped -- for the prewarm client. Includes skin overrides.
HunterAnimations.allIds() -> { string }

-- Build every track in a set on one animator, prewarming the whole set in ONE pass first.
-- opts: { Priorities = { [clip] = Enum.AnimationPriority }, Looped = { [clip] = boolean },
--         Blocking = boolean }
-- Blocking=false (default) uses AnimationLoader.loadCached and never yields -- correct for
-- spawn-path viewmodel builds. Blocking=true uses .load and is authoritative.
-- Returns { [clipName] = AnimationTrack? }; a clip that failed is simply absent, and a WARN
-- naming the hunter, kind and clip is emitted once.
HunterAnimations.loadSet(animator, hunterName, kind, skinName, opts) -> { [string]: AnimationTrack }
```

`kind` is `"Viewmodel"` or `"World"`.

**Rules the module must hold to:**

1. **Never yield in `id`, `set` or `allIds`.** They are plain table reads.
2. **`loadSet` prewarms the whole set in one `AnimationLoader.prewarm` call before building any
   track.** Loading a set one clip at a time is what makes a cold client pay N sequential fetches.
3. **A missing clip warns with hunter + kind + clip name and returns nil.** Never `WaitForChild`,
   never error. This is the Tier A lesson written into the shape of the API.
4. **Manifests are required lazily and cached.** All four are pure data with zero requires and zero
   side effects, so requiring all four on every client is safe — `WorldAnimationPrewarmClient`
   already does exactly that.
5. **A hunter with no `Animations` table is not an error** — return empty. A fifth hunter mid-build
   must not break the prewarm for everyone else.

---

## 4. Call-site inventory — 17 sites

Every place that resolves a clip today. This is the complete migration surface; verified by grep on
2026-08-29.

### Viewmodel (reads `AnimationController` children by name)
| # | Script | Clips |
|---|---|---|
| 1 | `RS.Hunters.Dust.Modules.RevolverViewModel.LoadTrack` | generic loader; also does `Normalize` |
| 2 | `RS.Hunters.Dust.Modules.RevolverAnimations` | Idle, Shoot, Fanning (fallback `Skill2`), Reload, Run |
| 3 | `RS.Hunters.Dust.Modules.HighNoonGunFX` | Shoot, Fanning (fallback `Skill2`), Ultimate |
| 4 | `SPS.Fortuna.CardsClient.loadAnimation` | Basic, 1/2/3CardThrow, Reload, Ultimate, Recall, Walk, Run, Idle |
| 5 | `SPS.Bram.GrudgekeeperClient.loadTrack` | Idle, Run, Charge, Reload, Shoot, ShrapnelShoot |
| 6 | `SPS.Vesper.VesperViewModelAnimationClient.loadTrack` | Idle, Reload, Shoot, Scope, Sprint, Ultimate |

> The `Skill2` fallback at sites 2 and 3 predates the `Fanning` rename. No live rig declares
> `Skill2`. Drop the fallback during migration and say so in the changelog.

### World
| # | Script | Clips |
|---|---|---|
| 7 | `SSS.Hunters.BramServer.GrudgekeeperWorldVisualServer` | Idle, Shooting, Charge |
| 8 | `SSS.Hunters.FortunaServer.CardsWorldVisualServer` | Idle, Shooting, Ultimate |
| 9 | `SSS.Hunters.VesperServer.VesperWorldVisualServer` | Idle, Scope, Shooting |
| 10 | `SSS.VFX.RevolverWorldModelServer` | Dust `Shooting` — **literal** |
| 11 | `SPS.Dust.WorldRevolverAimIdleClient` | Dust `Idle` — **literal** |
| 12 | `SPS.BramWorldIdleClient` | Bram `Idle` |
| 13 | `SPS.VesperWorldIdleClient` | Vesper `Idle` |
| 14 | `SPS.FortunaCardsWorldIdleClient` | Fortuna `Idle` |
| 15 | `SSS.Bots.BotController.getWorldAnimationId` | all four hunters; Dust branch is **literal** |
| 16 | `SPS.WorldAnimationPrewarmClient` | `DUST_WORLD_ANIMATION_IDS` **literals** + `WORLD_ANIMATION_FOLDERS` walk |

Sites 10, 11, 15 and 16 are the four homes of Dust's two literals. **They collapse to one manifest
entry** — that is the single clearest win in this spec.

### Contract
| # | Script | Role |
|---|---|---|
| 17 | `RS.Hunters.Shared.HunterViewmodelContract` | `Normalize` (clip back-fill), `Audit`, `ClipManifest` |

---

## 5. What happens to `HunterViewmodelContract`

Do **not** delete it. Split its two jobs:

- **`Normalize`'s clip back-fill becomes dead** once loaders read the manifest — there is no rig
  clip left to be missing. Remove that half.
- **`Normalize`'s weapon-model rename stays.** It is structural, not clip-related, and it is what
  stopped Icefang's `Ice`-named gun model from killing High Noon's per-shot FX.
- **`Audit` gains a new job and loses one.** ✅ **Done 2026-08-29.** It stopped comparing skin clip
  sets (meaningless once clips are central) and now checks **manifest ↔ reality**: every id parses,
  a `Viewmodel` set exists and declares `Idle`, a non-empty `World` set declares `Idle`, and every
  override names both a skin Model that exists and a clip the base table declares. While the
  instances survive it also compares manifest against rig — id mismatch **FAIL**, rig-only clip
  WARN, manifest-only clip NOTE, a skin rig id differing from the resolved one WARN (the Icefang
  hole), drop-zone orphans one NOTE per hunter.
- **`ClipManifest` reads manifests instead of instances.** ✅ **Done 2026-08-29.** It now returns
  **two** folds: `TOTAL` over the manifest tables (the gate) and `TOTAL-INSTANCES` over the rig
  instances, the latter kept only because those instances are the Phase 1 revert path and so must
  still agree across the places. Phase 2 drops the second fold with the instances.

---

## 6. Phasing — do not do this in one pass

**Phase 1 (this spec).** Add `Animations` to the four manifests. Add `HunterAnimations`. Convert all
17 sites. **Leave every rig `Animation` instance exactly where it is** — unread, but present, so a
revert is a code-only revert.

**Phase 2 (a later release, after a soak).** Delete the now-unread rig instances, the
`ViewmodelAnimations` drop-zone folders, and the two dead Fortuna backup viewmodels, then delete the
transitional halves of `Audit` and `ClipManifest` that exist only to compare against them (both are
marked in the source). The §5 rewrite itself landed with Phase 1 — see the Status note. This is the
phase that actually shrinks the data model, and it must not ride the same release as the behaviour
change.

**Why split:** Phase 1 is reversible by reverting code. Phase 2 destroys authored instances. Putting
them together means a single bad playtest forces you to restore art as well as code.

---

## 7. Build order

0. **Re-verify the §2 premise before writing anything.** Run the generator from the audit
   (`HunterViewmodelContract`-adjacent, edit-mode `execute_luau`) and confirm *still* zero skin
   overrides and ids unchanged. If a skin has grown an override since 2026-08-29, it must go in the
   `Skins` table explicitly — and you must find out whether it is deliberate or stale drift.
1. Write `HunterAnimations` in `RS.Hunters.Shared`. Unit-check it in edit mode with `loadstring`.
2. Add `Animations` to all four `Config.Manifest` modules, pasted from §2.
3. **Assert manifest == rig before converting any call site.** For every hunter, kind and clip,
   `HunterAnimations.id(...)` must equal the id on the corresponding instance. This is the one gate
   that proves the paste is faithful; a typo here is a wrong animation, not a crash.
4. Convert sites 1–6 (viewmodel), one hunter at a time, playtesting each.
5. Convert sites 7–14 (world).
6. Convert 15 (`BotController`) and 16 (prewarm — it should now be `HunterAnimations.allIds()` plus
   the bot/stock ids, with `DUST_WORLD_ANIMATION_IDS` and `WORLD_ANIMATION_FOLDERS` deleted).
7. Trim `Normalize` per §5.
8. Mirror **everything** into Frostbite Claim and verify by fold.

---

## 8. Verification

- **Fold gate.** After every mirror, `/mirror` must show matching `TOTAL` folds for
  `ReplicatedStorage`, `StarterPlayerScripts` and `ServerScriptService`. Note that
  `HunterSelectionService` had an unrelated 3-byte drift on 2026-08-29 owned by another session —
  confirm it is resolved or still expected before reading `ServerScriptService` as a failure.
- **Asset gate.** Re-run the id sweep: every id in every manifest must `PreloadAsync` to
  `Enum.AssetFetchStatus.Success` in edit mode. It did on 2026-08-29 for all 74 instance ids, all 18
  emote ids, and all 24/21 code literals.
- **No raw loads.** Sweep for `:LoadAnimation(` outside stock `Animate` scripts. The only legitimate
  hit is inside `AnimationLoader` itself.
- **No infinite yields.** Sweep for `WaitForChild` whose argument is a clip name with no timeout.
- **Playtest, per hunter, both places.** First-person: idle, shoot, reload, sprint, ability,
  ultimate. Third-person (needs a second player — a bot is server-owned and does *not* exercise the
  client twin): the world gun hold, shoot beat, and each hunter's special (Bram charge, Vesper
  scope, Fortuna ultimate).

> `AnimationTrack.Length` is 0 on the server for a freshly loaded track, and a pcall around
> `LoadAnimation` cannot detect a failed fetch. Neither fact changes in this spec — they are why
> `AnimationLoader` exists and why every load in the new module goes through it.

---

## 9. Things that must not regress

- **Every hunter with a world gun needs its client-side `*WorldIdleClient` twin, at the ROOT of
  `StarterPlayerScripts`.** A server-played hold does not hold on another player's own Animator.
  All four exist today (sites 11–14). `HunterClientLoader` only collects per-hunter folders, so a
  twin moved inside `StarterPlayerScripts.<Hunter>` gets disabled for exactly the viewers who need
  it. `HunterImplementationGuide` still does not mention this — add it there while you are in here.
- **Bram's `Idle` is the only clip that poses `RightHand`, and the shotgun is welded to
  `RightHand`.** It is deliberately left running during the charge instead of action-locked.
  Stopping it swings the gun.
- **Priority ordering is load-bearing** and is not in the manifest — it stays at the call site,
  because it is behaviour, not identity. Core < Idle < Movement < Action < Action2 < Action3 <
  Action4.
- **Bots reimplement abilities but fire the same authored clips.** `BotController` must resolve
  through `HunterAnimations` too, or Dust's literals simply move rather than disappear.

---

## 10. Open questions for the user

Both original questions were answered on 2026-08-29 — Dust's `Walk` was wired, Vesper's
`BasicReload` was deleted — so §2's tables are complete and need no further decisions.

What remains for Phase 2, and should be asked rather than assumed:

- **The two dead Fortuna viewmodels** (`BackupDefaultCards`, `Skins.BackupPrestigeCard`). Both are
  in ReplicatedStorage, both are walked by `WorldAnimationPrewarmClient`, and `BackupDefaultCards`
  carries duplicate-named children whose ids differ. Nothing can equip either. Deleting is the
  obvious call but it is authored art, so confirm first.
- **Whether `ViewmodelAnimations` drop-zone folders survive Phase 2.** Once ids live in the
  manifest, the folders read by nothing at all. Keeping them is a standing invitation to the exact
  bug that hid Dust's Walk and Run for weeks; deleting them removes the animator's drop target, so
  agree a replacement convention (drop into the manifest as data, or into a clearly-named
  `_Incoming` folder) before removing them.

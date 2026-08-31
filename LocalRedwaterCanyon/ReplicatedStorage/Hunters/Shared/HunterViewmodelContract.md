---
tags: [shared, modulescript, viewmodel, skins, tooling]
path: game.ReplicatedStorage.Hunters.Shared.HunterViewmodelContract
type: ModuleScript
lines: 689
---

# HunterViewmodelContract

Reconciles an equipped weapon skin's STRUCTURE against its hunter's default first-person rig (weapon-model name, parts), and audits every authored skin for what that reconciliation cannot fix. Clip identity moved out of this contract on 2026-08-29 — ids live in each hunter's manifest `Animations` table and resolve through HunterAnimations.

## What it does

1. Exists because a weapon skin is **not a re-skin — it is a fork of the entire first-person rig**. Cloning one forks the weapon model's name, every part name, and every animation clip along with its length. Nothing checked any of that, so a new skin could silently change **structure** (Icefang named its gun model `Ice`, which killed High Noon's per-shot animation, muzzle flash, fire sound and beam) or **timing** (back when Fan-The-Hammer read its fire rate off whichever Fanning clip was equipped)
2. States the contract as one sentence: **a skin must present the same interface as its hunter's default rig.** The contract is deliberately not restated in the module — it is read off the default rig at call time, so changing a default moves the bar for every skin of that hunter automatically and the module cannot go stale against the art
3. `Normalize(clone, hunterName)` is the **runtime net**. It renames the clone's weapon model to the default's name and guarantees an `AnimationController` exists (the loaders park their Animator inside it). Mutates the **clone**, never the template — a write to a template in ReplicatedStorage races every client that already cloned it. Idempotent
4. Its clip back-fill is **gone** (2026-08-29): every loader resolves ids through the manifest via HunterAnimations, so the clone's Animation instances are unread and a skin missing a clip costs nothing. An override is now an explicit `Animations.Skins` entry in the manifest, never a rig id that happens to differ — which closes the hole the old design admitted it could never close (an id that merely differed was indistinguishable from a deliberate override; Frostbite's Icefang sat on superseded July clips that way until 2026-08-27)
6. Resolves the weapon model by the default's name first, then falls back **structurally** to the sole `Model` child — because that name is precisely what a skin is free to get wrong. Two `Model` children is an ambiguity the audit reports rather than something to guess at
7. `Audit()` is read-only and covers only what `Normalize` cannot repair, returning `{ fails, warns, notes, checked }`. **FAIL** = will misbehave at runtime (no default rig, unresolvable weapon model, duplicate child names, a root BasePart the default has). **WARN** = `Normalize` corrects the clone but the art should be fixed (weapon-model name mismatch, missing AnimationController). **NOTE** = a legitimate reason to differ exists. The clip-set comparisons are gone with the back-fill — a skin missing a rig clip is no longer anything
7a. **Audits clip identity against the manifests** (`auditAnimations`, 2026-08-29): every id parses as `rbxassetid://<digits>`, a `Viewmodel` set exists and declares `Idle` (the base pose every loader plays), a non-empty `World` set declares `Idle` (its `*WorldIdleClient` twin has nothing to hold otherwise), and every `Animations.Skins` override names **both** a skin Model that exists **and** a clip the base table declares — an override that names neither errors nowhere and simply never plays. While Phase 1 keeps the rig instances, it also compares manifest against rig: an id mismatch is a **FAIL** (the manifest is what plays, so a clip edited on a rig is silently ignored — the trap that hid Dust's Walk and Run for weeks), a rig clip in no manifest entry is a WARN, a manifest clip with no rig Animation is a NOTE (only a Phase 1 revert would lose it), a skin rig id differing from what the manifest resolves is a WARN (the Icefang hole, now closed: the deliberate case is an explicit `Skins` entry), and clips left in a `ViewmodelAnimations` drop-zone that no manifest entry names are one NOTE per hunter. Everything comparing against instances goes with them in Phase 2; the manifest checks are permanent
8. Also flags a non-`Model` parked in a `Skins` folder — every resolver type-checks `IsA("Model")` and falls through to the default, so such an entry can never be equipped while still reading as shippable art in the explorer (Fortuna's `BackupPrestigeCard` is a Folder holding two models both named `PrestigeCard`)
9. Checks world-model twin parity: a viewmodel skin with no same-named `Weapon.WorldModel.Skins` entry means every *other* player sees the default gun. Only a NOTE, because a hunter may map the two explicitly instead — Fortuna's CardsWorldVisualServer deliberately points `PrestigeCard` at `WorldPrestigeCards` through its `TemplateResolver`
10. `Report()` returns the audit as an **array of lines** rather than one joined string, so the caller decides how to emit them. `/preflight` Step 2 runs it as a hard gate in both match places
11. Discovers hunters structurally — anything under `ReplicatedStorage.Hunters` carrying a `Weapon` rig — so a fifth hunter is audited the day its rig lands, with no edit here
12. `ClipManifest(prefix?)` covers what `Audit()` structurally cannot: **cross-place** parity. A place sees only its own DataModel, so it folds clip ids into per-subtree checksums and the two match places are compared outside by running it in both. It returns **two** folds since 2026-08-29: `TOTAL` over the manifest tables — what actually plays, and the gate — and `TOTAL-INSTANCES` over every `Animation` under `Hunters`, kept because the instances are the Phase 1 revert path and so must still agree across the places, though a difference there cannot affect a live match. Phase 2 deletes the second half with the instances. With no argument it prints one row per group (`<Hunter>.<Kind>` for manifests, `<Hunter>.<second level>` for instances); passing a group as `prefix` prints one row per clip from both folds, to find which id moved. `/preflight` Step 2 runs it as a hard gate — **the sum is the gate, not the count**: the 2026-08-27 Icefang drift left the count identical in both places

Runs in **edit mode** through `execute_luau` with no server and no playtest, which is what makes the audit a pre-publish gate rather than a warn nobody reads.

## Dependencies
- **Requires:** [[HunterAnimations]] (lazily, inside `Audit` and `ClipManifest` only — `Normalize` runs on the spawn path and must keep pulling nothing extra; from `ReplicatedStorage.Hunters.Shared`)
- **Required by:** RevolverViewModel, CardsClient, GrudgekeeperClient, HunterFirstPersonClient (plain text — each caller declares the `require()` in its own file, and wikilinking them here points the edge dependency → dependent, which is backwards)

## Connections
### RemoteEvents
None

### BindableEvents
None

### Direct require()
| Target | Function | Purpose |
|--------|----------|---------|
| [[HunterAnimations]] | `.animations()`, `.hunterNames()`, `.id()` | The manifest clip tables `Audit` checks and `ClipManifest` folds |

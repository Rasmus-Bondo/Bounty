---
tags: [shared, modulescript, config, bram]
path: game.ReplicatedStorage.Hunters.Bram.Config.Manifest
type: ModuleScript
lines: 145
---

# Manifest

Bram's declarative hunter manifest — consumed by HunterServerRuntime (via GrudgekeeperModule) and HunterClientRuntime (via GrudgekeeperClient / BramHunterGuiClient).

## What it does
1. Declares `HunterName = "Bram"`, `KillFeedWeaponName = "Grudgekeeper"`, `HunterFolder = {Hunters, Bram}`
2. Declares the 10 RemoteEvents the runtime creates under `Hunters/Bram/Remotes`: `FireShotgun`, `ReplicateShot`, `BreachChargeRequest`, `BreachChargeFX`, `ShrapnelShellRequest`, `ShrapnelShellFX`, `UltimateRequest`, `UltimateState`, `UltimateChargeUpdate`, `AbilityCooldownsReduced`
3. Declares the 11 client-side BindableEvents under `Hunters/Bram/ClientEvents` (ammo/reload/cooldown/charge signals + mobile-button request bridges)
4. Ultimate charge economy: MaxCharge 100, passive 0.25/s, and three sources implementing the **"once per shot, not per enemy"** rule — `Basic` (5 hit / 10 headshot / 12 kill) for the cone blast's primary target, `BasicSecondary` (12 kill-only) for extra enemies caught by the same cone, `Ability` (3 hit / 12 kill) for Breach Charge / Shrapnel Shell damage. Balanced 2026-07-31 off the placeholder that mirrored Dust's revolver 1:1 (2.5/6/5, passive 0.125): the Grudgekeeper's 2-round mag and 1.76s reload sustain 0.885 shots/s against the revolver's 1.71, and its 50 near-damage kills a 150 HP hunter in 3 shots where the revolver needs 5, so the same per-shot numbers paid 10 charge per kill instead of 15 — ~43s of landing every shot, or ~10 kills, to full. Now ~21s / ~4.5 kills, matching Dust's charge-per-second the way Vesper's rebalance did. Two structural rules the old table broke: `Kill` must stay **>=** `Headshot`, because the shared charge service awards exactly one value and tests `didKill` first (at 6/5 a finishing headshot paid less than a non-lethal one); and ability damage awards on hit at all, since kill-only left the whole ability kit feeding nothing into the ultimate. `Ability.Hit` is kept small because Shrapnel Shell is AoE and the ability damage path runs per victim, so a 3-man shell pays 9 on an 8s cooldown. Last Call refreshing both ability cooldowns is not a feedback loop — the runtime ChargeBlockPredicate blocks all accrual while the ult is active
5. `Client.ViewmodelTemplate = { "Hunters", "Bram", "Weapon", "Viewmodel", "Default", "DefaultViewmodel" }` — resolves to Bram's dedicated arms/Grudgekeeper first-person rig (whose `AnimationController` holds the Idle/Running/Reload/Shoot animations). GrudgekeeperClient consumes `runtime.Viewmodel.Template` to build the viewmodel and drive those animations; Bram no longer uses the generic HunterFirstPersonClient fallback. No `Remotes.Bindables`

6. Declares the `Abilities` block read by HunterAbilityIntroClient for the first-spawn intro tags: three `Slots` (`Q` BREACH CHARGE / `E` SHRAPNEL CHARGE / `F` LAST CALL), each with a `Name`, a one-line `Blurb` and a `Tag`. Slot order is HUD order. **`Tag` is the only field Redwater draws** — the 2-4 word action phrase shown above that ability's HUD icon (`CHARGE AND PIN` / `EXPLOSIVE SHOT` / `LIFESTEAL FRENZY`); it says what the button *does*, since the name is only useful once you already know the ability. `Name`/`Blurb` are the long-form copy, kept **verbatim** in step with the authored ABILITIES panel in Bounty's Collection menu (`CollectionGui.AbilityPanelNew.Bram`). The `Passive` line is retained for that parity but is no longer displayed in Redwater — it is not something the player presses. Icon ids are deliberately absent: the tags are parented into the live HUD icon they describe, so they cannot drift from what BramHunterGuiClient sets at runtime from its own `BRAM_GUI_ART` table

7. Declares the `Animations` table (2026-08-29) — the ONE home of Bram's clip ids, resolved by HunterAnimations for every loader: 6 `Viewmodel` clips (Charge, Idle, Reload, Run, Shoot, ShrapnelShoot — the last is authored as "Ability" in the ViewmodelAnimations drop-zone but the rig and every caller use ShrapnelShoot) and 3 `World` clips (Charge, Idle, Shooting), plus an empty `Skins` override table. A skin override is an explicit entry here, never a rig id that happens to differ; the rig Animation instances and the ViewmodelAnimations drop-zone are unread until Phase 2 deletes them

## Dependencies
- **Requires:** Nothing
- **Required by:** GrudgekeeperModule, GrudgekeeperClient, BramHunterGuiClient, HunterAbilityIntroClient, HunterAnimations (plain text — reads the `Animations` table; its own file declares the require), WorldAnimationPrewarmClient (plain text — that script's own file declares the require)

## Connections
### RemoteEvents
None (declares them; the runtimes create/use them)

### BindableEvents
None (declares them)

### Direct require()
None

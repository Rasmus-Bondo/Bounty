# Task Plan: Implement Bram Hunter (Redwater Canyon)

## Goal
Build Bram (close-range shotgun bruiser) in Redwater Canyon per `bram_implementation_guide.md`. 9 scripts: Manifest, GrudgekeeperConfig, GrudgekeeperModule, GrudgekeeperDamageService, BreachChargeService, ShrapnelShellService, LastCallModule (server) + GrudgekeeperClient, BramHunterGuiClient (client). Consumes existing shared HunterStatusEffects (Vesper promoted it).

## Phases
1. **Research (live MCP)** — ✔ complete (all facts in findings.md "Bram addendum"; 12-script design locked incl. ungated BramWorldFXClient for victim knockback, KnockbackGraceUntil MovementChecker edit, DamageReductionPercent attr at 5 TakeDamage sites, Basic/BasicSecondary charge sources for per-shot rule)
2. **Studio skeleton** — ✔ (3 folders + 11 script instances created)
3. **Config + Manifest** — ✔
4. **Server modules** — ✔ (GrudgekeeperModule/DamageService/BreachChargeService/ShrapnelShellService/LastCallModule) + edits: MovementChecker KnockbackGraceUntil (2 sites), DamageReductionPercent hook in RevolverDamageService/SunspikeDamageService/HighNoonDamage/CardsServer/StarfallSightModule, HeroSelectionService TEMP→Bram
5. **Client scripts** — ✔ (GrudgekeeperClient, BramHunterGuiClient, BramWorldFXClient ungated) + BramGameGui added to Dust/Fortuna/Vesper GUI lists (also backfilled missing VesperGameGui in Dust+Fortuna)
6. **Verify** — in_progress: loadstring syntax check all 20 touched scripts (NO MCP playtest — known broken)
7. **Vault + graph** — .md files, update connected docs, `python update_redwater_canyon_graph.py`
8. **Handoff** — manual test checklist to user

## Standing decisions (inherited from Vesper build)
- Server entry = self-running Script (no Main edit). No dedicated viewmodel (HunterFirstPersonClient fallback; ViewmodelTemplate omitted from manifest). No HeroSelectionService entry needed (normalizeHeroName passes unknown names through). No character model → LoadCharacter fallback (art follow-up).
- ⚠️ HeroSelectionService DEFAULT_SELECTION is TEMP=Vesper from last session — will switch to TEMP=Bram for testing, revert to Dust after.
- Guide's [ASSUMPTION] values (pellet count 8, Breach Charge numbers, charge values) go in as-is; flagged for playtest.
- "Per shot, not per pellet" for charge award + ult cooldown refund (guide interpretation note).

## Errors Encountered
| Error | Attempt | Resolution |
|-------|---------|------------|

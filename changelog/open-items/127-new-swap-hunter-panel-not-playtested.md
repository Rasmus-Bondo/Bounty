# 127 — The old hunter-swap panel is still parked in both match places

[Open items index](../OPEN-ITEMS.md) · [Conventions](../CONVENTIONS.md)

**Status:** DEFERRED · **Sev:** P3 · **Area:** Redwater Canyon + Frostbite Claim — `StarterGui._LegacySwapHunterGui`

**Raised 2026-08-26.** What changed and why is in the Unreleased entry.

**The panel itself is signed off.** The new portrait-card swap UI was playtested and accepted by the
owner on 2026-08-26, the same day it was built. That half of this item is closed.

**Still owed: delete `StarterGui._LegacySwapHunterGui` from both match places.** It is the panel the
new one replaced, renamed and `Enabled=false`, and it is still copied into every player's `PlayerGui`
— about fifteen instances, no rigs, so the cost of leaving it is small.

**Deliberately held until the release publishes and soaks**, because it is the cheap half of the
rollback path: with it parked, reverting is a rename plus the previous `HunterSwitchClient`, and
without it a revert needs a place-version restore (see the release-versioning notes — Creator Hub
*Restore* does nothing; it is *open the old version → Publish As*). The new panel has been verified
in edit mode and in a Studio round but has never run on a published server with real players, real
skins and real join timing.

**Test that closes it:** after the release has been live long enough that a rollback is off the
table, delete `_LegacySwapHunterGui` in Redwater Canyon **and** Frostbite Claim, confirm
`StarterGui.SwapHunterGui` is the only swap GUI in each, and re-run `/preflight` so the mirror gate
sees both places matching.

**Do not delete it as part of the same publish that ships the new panel** — that removes the rollback
path and the reason to have one in the same motion.

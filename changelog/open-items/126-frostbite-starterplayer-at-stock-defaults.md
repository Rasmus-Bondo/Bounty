# 126 — Frostbite Claim's StarterPlayer is at Roblox stock defaults, not Redwater's match config

[Open items index](../OPEN-ITEMS.md) · [Conventions](../CONVENTIONS.md)

**Status:** FIXED (unverified) · **Sev:** P2 · **Area:** Frostbite Claim — `game.StarterPlayer`

**Raised and fixed 2026-08-24 (Hotfix 1.2 preflight).** What was wrong, which six properties moved
and why the automated gates could not see it are in the Hotfix 1.2 release entry. This item exists
only to hold the playtest that has not happened yet.

**Still owed: a Frostbite round.** The six values were applied in edit mode and read back identical
to Redwater's across all 18 `StarterPlayer` properties, but nobody has played the map since. Nothing
here is verified by a read-back — `LoadCharacterAppearance` and the two display distances only prove
themselves with a character loaded and another player in view.

**Test that closes it**, on Frostbite Claim, on a published server (not a Studio solo playtest —
`LoadCharacterAppearance` behaves differently with no real avatar to fetch):

1. Spawn and look at yourself and at another player. **Exactly one** nameplate and **one** health
   bar per player — the game's own. No Roblox core nameplate above it, at any distance.
2. No part of your Roblox avatar appearance is drawn on the hunter rig.
3. Walk at the steepest slopes you can find, especially around the spawn houses and the canyon
   walls. Anything that is unwalkable on Redwater must be unwalkable here — no climbing out.
4. On a phone, walk into a ledge. The character must **not** auto-jump.
5. Open the emote system. Roblox's default emote wheel must not be reachable.

**If step 3 fails differently than expected**, check it against open item #123 first — Frostbite's
spawn-house navmesh islands are a separate known geometry problem on the same map.

**Watch for the reverse regression.** These are place-file properties, so any Frostbite revert, or
any *Publish to Roblox As…* from a place file opened before 2026-08-24, silently restores the stock
values with nothing in the UI saying so.

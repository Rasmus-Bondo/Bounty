# 84 — Creator Hub's `Place` filter does not split custom events by emitting place

[Open items index](../OPEN-ITEMS.md) · [Conventions](../CONVENTIONS.md)

---

**Creator Hub's `Place` filter does not split custom events by emitting place.** Filtering to
Bounty (`131701626847012`) returns the full `MatchStart` dataset, and Bounty contains zero
`MatchStart` call sites — verified by grep across all 163 of its scripts. Whatever that dimension
keys on, it is not "the place that called `LogCustomEvent`", so **do not use it to separate the
lobby from a match place.** Only `SessionEnd` carries a real place dimension, in CustomField02
via `Telemetry.PLACE`. This matters more as **maps** multiply: a second match place firing the
same event names blends into one chart with no way to unpick it, so either keep new places off the
match event names or fold place into the composite field before they ship.

**Gamemode is a second dimension the place filter can never supply** (`CLAUDE.md`, maps/gamemodes
are independent axes): a deathmatch server and a CTF server on the same map share a PlaceId, so even
a *working* place filter would blend them. Whatever fold-into-composite fix lands here has to carry
map **and** gamemode, not just place. *(raised: MatchStart Unknown fields, 2026-08-05; gamemode
dimension added 2026-08-12)*

# 50 — Two `WaitForChild` calls still suppress their warning by timing out into `nil`

[Open items index](../OPEN-ITEMS.md) · [Conventions](../CONVENTIONS.md)

---

**Two `WaitForChild` calls still suppress their warning by timing out into `nil`** (raised:
Hotfix 10, 2026-08-07). `VictoryShowcaseClient` and `VesperScopeController` (Redwater) pass a
timeout to a `PlayerGui` lookup, which silences the engine's "Infinite yield possible" line by
handing back `nil` to code that then indexes it. Hotfix 10 fixed the same latent shape in
`QuestToastClient` and `HunterSwitchClient` by gating on `CharacterAdded:Wait()` instead, and
deliberately left these two alone to keep the change small. They are the same bug waiting for a
slow enough join. Bounty's equivalent problem was solved differently again — via
`Modules.WaitForRequired`, which loops a 30s timed wait so it never returns `nil`.

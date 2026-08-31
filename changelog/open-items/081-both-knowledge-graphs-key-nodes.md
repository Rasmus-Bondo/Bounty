# 81 — Both knowledge graphs key nodes on the lowercased FILE BASENAME, so same-named scripts merge into one node

[Open items index](../OPEN-ITEMS.md) · [Conventions](../CONVENTIONS.md)

---

**Both knowledge graphs key nodes on the lowercased FILE BASENAME, so same-named scripts merge
into one node.** In Redwater that silently conflates three sets: the four hunters'
`Config/Manifest.md` (Bram, Dust, Fortuna, Vesper), the two chrono `Replicate.md`
(Client + Server), and `RoundSystem/Config.md` with chrono's `Shared/Config.md`. Bounty has no
collisions. The `manifest` node currently carries **17 incoming edges** and reports itself as
Vesper's file, so a query like "what requires Bram's manifest" answers with every hunter's client
and server scripts at once; the `config` node happens to have resolved to `RoundSystem/Config.md`,
which is the one its real callers (`BountyService`, `ProgressionService`, `SpawnService`) mean —
that is luck, not design, and a rebuild could flip it. **This is not vault debt and no amount of
wikilink discipline fixes it** — the vault paths already disambiguate
(`ReplicatedStorage/Hunters/Bram/Config/Manifest.md`); the builder discards the path when it
makes the id. The fix is in `update_redwater_canyon_graph.py` / `update_bounty_graph.py`:
fall back to a path-qualified id when a basename is not unique. Until then, treat any `manifest`
edge as "some hunter's manifest" and read the source file to find out which.
*(raised: prose wikilink sweep, 2026-08-07)*

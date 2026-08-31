# 54 — Both Hotfix 7 fixes are replication-timing changes and neither is playtest

[Open items index](../../OPEN-ITEMS.md) · [Conventions](../../CONVENTIONS.md)

**Closed 2026-08-11** — owner review of the standing-concern list.

---

**Both Hotfix 7 fixes are replication-timing changes and neither is playtest-verified.** Nothing
in an edit-only session can reproduce the order in which Persistent models arrive, so the code is
reasoned and read back but unplayed. Two checks on the next live join, both cheap:
**(a)** no `Lobby weapon missing` line in the client log, and the lobby dummy holding its weapon on
the *first* build rather than popping it in ~1.5 s later; **(b)** the same on a second hunter,
since only the equipped hunter's rig is exercised per join and the warning named `Dust` purely
because that was equipped. If a warning does appear, its **last word is the discriminator** —
`offset` means the rig wait failed, `source` means an unrecognised hunter name, which is an
unrelated bug.

The `CharacterAdded` fallback in the same pass is the harder half to test deliberately: it only
matters when the character wins the race against `LobbySpawn`, which you cannot force. The honest
test is that the "dummy standing there with no weapon" report stops recurring over a stretch of
joins. Treat both as `FIXED (unverified)`.
*(raised: [Hotfix 7](../../2026-08-05-hotfix-7.md))*

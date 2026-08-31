# 43 — The ultimate half of the hunter HUD is still duplicated four times

[Open items index](../../OPEN-ITEMS.md) · [Conventions](../../CONVENTIONS.md)

**Closed 2026-08-11** — owner review of the standing-concern list.

---

**The ultimate half of the hunter HUD is still duplicated four times** (raised: Hotfix 9,
2026-08-06). `HunterHudCooldown` unified the *skill* cooldowns and removed ~380 lines, but
`setUltimateCharge` stayed behind in all four clients — three different implementations with three
different early-return guards, and Dust has none at all. Deliberate: the guards are genuinely
different, not accidentally divergent.

**The trap it leaves is specific.** `getChargeSize` and `setFrameSize` remained in the three
clients that still need them for the ult, so only the *skill* half of their call sites went away —
they look like dead leftovers of the refactor and are not. The ultimate is also where every
rising-edge re-arm lives (Bram's `isLastCallActive` and `startLastCallCountdown`, Vesper's
`ultimateActive` and its activation handler), which is the shape that made the ready-glow clear
cost three edits per hunter rather than one. Specced in `HUNTER_HUD_COOLDOWN_REFACTOR.md`.

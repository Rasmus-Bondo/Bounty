# 39 — The ultimate-ready halo was observed stuck ON while the ultimate was not ready

[Open items index](../../OPEN-ITEMS.md) · [Conventions](../../CONVENTIONS.md)

**Closed 2026-08-11** — owner review of the standing-concern list.

---

**The ultimate-ready halo was observed stuck ON while the ultimate was not ready** (raised:
Hotfix 9, 2026-08-06). Seen live on a Fortuna client: `ReadyGlow` at full breathe while the ult
label read 88%. Only `setUltimateCharge` writes that label, so `SetReady(false)` **was** being
called every tick and doing nothing.

**Root cause never found** — the playtest ended before it could be instrumented, and it has not
reproduced in edit mode. Two theories were checked and both are **wrong**, so do not re-derive
them: it is not a second `UltimateReadyFX` on the same tile (`HighNoonChargeUI` resolves
`PlayerGui.TemplateGameGui` by name and never attaches to another hunter's HUD), and it is not a
missing clear (Fortuna's `isReady` is a plain `charge >= maxCharge` feeding a single `SetReady`).

**Mitigated, not fixed.** `UltimateReadyFX:SetReady` no longer trusts its idempotent early return
on the false path: a live tween while the object believes it is extinguished is always a bug state,
so it re-runs `_extinguish` instead of returning. That turns a match-long stuck halo into at most a
one-tick flicker whatever the cause.

**The instance the symptom was seen on no longer exists**, which muddies the evidence rather than
clearing it. The glow was rebuilt twice after this was raised — first onto an `ImageLabel`, then
back onto a stack of 24 `UIShadow`s under `ReadyGlow` — so if the cause was an orphaned tween on
the original single shadow, it may already be gone incidentally. That is *not* a fix, and it is
the reason the invariant guard stays regardless.

**Owner playtest 2026-08-06 showed no recurrence, and this stays OPEN anyway.** The glow rework
was signed off in that run, but absence of an unreproduced, timing-dependent symptom across one
session is not evidence — the same standard already applied to #10 and #20.

**To close it:** play until an ultimate charges and is spent, repeatedly, and watch whether the
glow ever outlives the READY label. If it does, log inside `SetReady` — the guard fires silently
today and could be made to warn, which is what named the cause for #25 in a single pass.

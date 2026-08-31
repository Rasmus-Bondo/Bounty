# 96 — Tutorial welcome and outro cards are unplayed on touch

[Open items index](../OPEN-ITEMS.md) · [Conventions](../CONVENTIONS.md)

**Closed 2026-08-15 — owner decision. Never playtested; the test below was never run.** Live since
2026-08-12 (Hotfix 15) with no recurrence reported. Closed on elapsed time, not on evidence. If it
resurfaces, raise a **new id**.

**Status:** CLOSED 2026-08-15 (never verified) · **Sev:** P3 · **Area:** Redwater — onboarding UI
*(raised: Hotfix 15)*

---

**Symptom.** The tutorial's opening logo card and its closing card are both authored in viewport
fractions, which on a short phone put a 13px line of copy and the logo on top of the EXIT TRAINING
button. Hotfix 15 gives the card a pixel height on touch, widens its copy box past its parent so
`TextScaled` cannot wrap, shrinks the logo a quarter on phones, and sizes the outro text per device
(phone 24 / tablet 44 / PC 30).

**Repro.** Not applicable — the geometry was measured and captured in the device simulator, never
played. `set_device_simulator` plus `capture_screenshot` at windowed PC, Galaxy A06, iPhone 7,
Galaxy Tab A8 and iPad Pro 13in showed the logo clearing the button by 11px on all five, and the
widest outro plate at 57% of viewport against a 62% budget.

**The test that closes it.** Run the tutorial to completion on a real phone and on a tablet. The
opening card's copy must be readable and must not touch EXIT TRAINING; the closing card's line must
not wrap; both must fade rather than cut. A simulator capture is not this test — Studio's viewport
and the simulator both hide the real text metrics.

**Shipped in:** [Hotfix 15](../2026-08-12-hotfix-15.md) — see the two tutorial-card entries under
`## Changed`.

# 14 — Mobile kill feed names truncate

[Open items index](../../OPEN-ITEMS.md) · [Conventions](../../CONVENTIONS.md)

**Closed 2026-08-11** — owner decision: no recurrence in the ~2 weeks since the 2026-08-01 launch. Closed on elapsed time, **not** on a playtest — the status below was still `FIXED (unverified)`.

---

**Status:** FIXED (unverified) · **Sev:** P2 · **Area:** Mobile — kill feed

**Reported:** On mobile, kill feed names fold with `…` instead of showing the full name. Kill feed text should be smaller.

**Diagnosed and fixed 2026-08-04 in `KillFeedClient`, one function.** `makeText` sized every name
label to a hard `NAME_WIDTH` column — 112px mobile, 130px desktop — at `TextSize` 16. GothamSemibold
at 16 fits about **13 characters** in 112px. Roblox display names run to **20**. That is the whole
bug; the emitters and the remote were never involved.

**Two facts made it worse than the arithmetic suggests, and both are worth not re-deriving:**
- **A fixed column cannot lend space.** `TheRealCowboyJoe → Al` ellipsised the killer while the
  victim's column sat 90px empty beside it. Truncation was driven by one name's length, never by
  what the row actually needed.
- **`UIScale` does not help.** The 0.68 phone scale shrinks the box and the text together, so the
  character count that fits is *identical at every scale*. Mobile truncated sooner than desktop
  purely because `NAME_WIDTH` was 112 rather than 130 — not because the phone was small.

**Bots cannot reproduce it.** `BotConfig.Names` tops out at 11 characters (`DeadeyeDale`), comfortably
inside 112px, so a bot-only match shows a clean feed no matter how long it runs. Repro needs a real
display name over ~13 characters.

**Fix — three changes, all inside `makeText`, plus two constants:**
1. `AutomaticSize.X` instead of a fixed `Size`, so a label's width follows its text. `NAME_WIDTH` is
   gone entirely.
2. A `UIFlexItem` in **`Shrink`** mode on each name, so the two names **share one budget** and a long
   killer borrows what a short victim is not using. `Shrink` and not `Fill`: `Fill` would stretch
   every name to consume the row and destroy the centred "Killer [icon] Victim" grouping.
3. New `NAME_BUDGET = (ROW_WIDTH - 24) - (WEAPON_ICON_MAX_WIDTH + HEADSHOT_ICON_SIZE + 6 * 3)` —
   224 mobile, 264 desktop — used as a `UISizeConstraint` ceiling so a single long name cannot shove
   the weapon icon off centre. **Derived from `ROW_WIDTH` rather than being its own constant,** so
   the two cannot drift; a second hand-maintained number is exactly what produced this bug.
4. New `TEXT_SIZE = IS_MOBILE and 13 or 16` — the "smaller text" half of the report. 13 lands at
   ~8.8 real px after the 0.68 phone scale. **Desktop text is deliberately unchanged at 16**; it was
   never reported as too large and the shared budget already buys it the extra characters.

`TextTruncate.AtEnd` survives as a backstop only. Two 20-character names in the font's widest glyphs
need ~5.6px text to fit, so an ellipsis there beats spilling past the row's drop-shadow.

**Result, measured on an iPhone 7 (667x375, the narrowest phone preset), an iPad and a windowed PC.**
Roughly **32–36 characters across both names** on mobile and 31–35 on desktop, against a hard ~13
(mobile) / ~15 (desktop) *per name* before. An 18-character name beside a 19-character one now renders
in full on a phone. Flex clamps at exactly the content width — worst-case overflow **+0.0px** on both
platforms — so no row can spill past its shadow.

**One knife-edge case on desktop, and it is not worth chasing.** `MinecraftSteve2013 /
AlexanderTheGreat99` (37 characters) truncates by **half a pixel** at scale 1.0 and renders full at
0.9. That row carries the wide carbine icon and no headshot icon, so its real budget is 292px against
293px of text. Mobile fits the same pair with 18px to spare, because its text is smaller. Dropping
desktop to `TextSize` 15 would close it; that was declined on purpose, since desktop was not the
reported problem.

**Verification technique worth reusing.** The feed is built in code, so there is no authored panel to
screenshot — instead the **real `makeText` was extracted from the live script source with `loadstring`**
and driven inside a throwaway `CoreGui` harness, which makes the preview incapable of drifting from
the shipped function. Also: **neither `TextBounds` nor `TextService:GetTextSize` is a valid truncation
oracle here.** `TextBounds` reports the *already-truncated* string, and `GetTextSize` at the pre-scale
size does not match post-`UIScale` glyph metrics. The only reliable test is to set
`TextTruncate = None`, re-measure, and compare against `AbsoluteSize`.

**Deliberately NOT done: making the row hug its content.** `Bob [icon] Al` is ~90px of content in a
352px row, so short rows still show a wide, mostly empty bar — which is the same complaint the mobile
`ROW_WIDTH` of 352 was chosen to address. Fixing it means a variable row width, which drags in
right-anchoring, `updateRowPositions` and the slide-in tween's `Size`/`Position` interpolation. Too
large a regression surface for a text-fitting fix. Tracked as its own standing concern below.

**Follow-up 2026-08-04 — the feed did not read as flush with the right edge, and it was a second,
pre-existing defect.** Reported against the simulator after the above shipped. The row *frame* was
never the problem: it is pinned a consistent 8px from the edge and always was. The **content** was
`UIListLayout.HorizontalAlignment.Center` inside that fixed-width row, so every row's last glyph
landed somewhere different — measured on an iPhone 7, the victim name sat **37.6px** from the screen
edge on a long row against **102.6px** on a short one, a **65px spread**. A feed pinned to an edge
whose contents float is read as not being pinned at all.

*Fixed by:* `HorizontalAlignment.Right` in `createContent`, one property. Every row's last glyph now
lands at a constant **16.2px** — the 8px feed pin plus the content frame's 12px inset, scaled 0.68 —
spread **0.0px**. The ragged edge moves to the left, where nothing is pinned and it reads as normal.
Applied on **both** platforms, since `createContent` is shared and desktop has the identical flaw
against its 28px pin.

**Not caused by the auto-sizing above — check before "fixing" it back.** The old fixed-column layout
put a short victim name ~109px from the edge, marginally *worse* than the 102.6px measured after.
Auto-sizing made this slightly better and merely left it visible.

**The safe-area inset was investigated and deliberately left alone.** `KillFeedClient` sets
`IgnoreGuiInset = true`, which resolves to **`ScreenInsets = DeviceSafeInsets`, not `None`** — verified
live, and worth knowing generally. On a notched phone in landscape that adds a device-dependent inset
on top of the 8px pin, which **Studio's simulator cannot show**: all three inset variants measure a
0px gap there, because no notch is modelled. Switching to `ScreenInsets.None` would reach the true
edge but can slide the feed under a notch or rounded corner, and that cannot be verified from Studio.
Left as `DeviceSafeInsets` by decision, since the report came from the simulator, where the inset
plays no part. **Revisit only if the feed still looks inset on a real handset** — and if so, that is
the cause, not the alignment.

**Still to verify (human, MCP playtesting unavailable):** get a kill with a long display name on a
phone and confirm no `…`; confirm 13px text is comfortably readable on a *real* phone rather than the
simulator, since this is the one judgement a screenshot cannot settle; confirm a short-name row still
looks centred and the weapon icon has not drifted; confirm desktop rows are visually unchanged apart
from long names now fitting.

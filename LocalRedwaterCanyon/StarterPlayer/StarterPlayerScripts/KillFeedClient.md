---
tags:
  - client
  - localscript
  - ui
  - combat-feedback
path: game.StarterPlayer.StarterPlayerScripts.KillFeedClient
type: LocalScript
lines: 635
---

# KillFeedClient

Renders an animated, stacked kill-feed in the top-right corner showing "Killer [weapon icon] [headshot icon] Victim" rows.

## What it does
1. Listens to the `KillFeed` RemoteEvent (killerName, victimName, weaponName, wasHeadshot)
2. Builds each row with a weapon icon looked up by exact name from `ReplicatedStorage.KillFeed.ImageTemplates.Weapons` (falling back to the Revolver icon), and a headshot icon overlay if `wasHeadshot`. Templates present: `Revolver` (Dust + fallback), `Cards` + `Card Burst` + `Card Recall` + `Fortuna's Hand` (Fortuna, same icon), `Sunspike Carbine` + `Starfall Sight` (Vesper, same icon), `Grudgekeeper` + `Breach Charge` + `Shrapnel Shell` (Bram, same icon). Any weapon name without a matching ImageLabel silently shows the Revolver icon — as of 2026-07-26 only Dust's `High Noon` and `Fan the Hammer` do that, where the revolver is the correct icon anyway
3. Sizes weapon icons by an aspect-aware rule: `WEAPON_ICON_SIZE` (28) is a *height* budget and `WEAPON_ICON_MAX_WIDTH` (64) caps width. A template declares its art's width/height in an `IconAspect` attribute — absent means square, so Revolver/Cards stay 28x28. Wide templates (Vesper 5.04:1 → 64x13, Bram 4.34:1 → 64x15) also carry `ImageRectOffset`/`ImageRectSize` cropped to the art's tight opaque bounds, so the label's box matches what is drawn. The cap is not purely cosmetic: Vesper's barrel is only 13.8% of the art's height, so at the old 28px width it rendered under one pixel, aliased away, and stranded the muzzle brake as a stray dot beside the rifle
4. Animates rows in (slide + background expand + content fade) and out (slide + fade), auto-expiring after 4.2 seconds, capped at 5 visible rows on desktop / **4 on tablet** / 2 on phone (oldest removed first). The desktop/touch split is `IS_MOBILE = TouchEnabled`, resolved once; the phone/tablet split inside it is `math.min(viewport.X, viewport.Y) >= TABLET_MIN_SHORT_EDGE` (600) — the same short-edge test `TelemetryClient` buckets its analytics platform with and `TutorialClient` sizes its banner with. `MAX_ROWS` is therefore **not** a load-time constant: `ViewportSize` reads (1, 1) for a client's first frames, so `updateFeedScale` re-solves it on every viewport change, resizes `FeedFrame`, and re-slots/trims the live rows through `refreshRowLayout`
5. Rescales the whole feed for mobile/touch viewport widths (0.68x ≤900px, 0.8x ≤1300px; 0.9x ≤1100px desktop). **Both platforms** then pin the feed to the top-right in pure screen-relative coordinates — `FEED_TOP_MOBILE` (60px) / `FEED_TOP_DESKTOP` (96px) below the top edge and `FEED_RIGHT_MOBILE` (8px) / `FEED_RIGHT_DESKTOP` (28px) in from the right. `AnchorPoint` is (1,1) and the Y offset is `topOffset + feedHeight`, so the frame's *top* lands at `topOffset` and rows stack upward from the bottom edge; `feedHeight` is computed as `(ROW_HEIGHT + ROW_SPACING) * MAX_ROWS * scale` rather than read from `AbsoluteSize`, so it needs no layout pass and the top edge holds at `topOffset` on every scale
   - **Nothing about this tracks the bounty list.** Desktop used to anchor the feed's bottom-right to the `BountyListGui` Canvas's right edge/top and grow upward off it. That broke on 2026-07-30 when the bounty list moved to the **left** edge (taking over the deleted `DailyQuestGui`'s slot so the mobile FIRE/SCOPE buttons could own the right edge) — the feed rode along and appeared on the left on PC. Touch had already abandoned the same tracking for the same class of reason: the canvas's right edge resolved to ~108% of screen width and its top to ~49% of height, throwing the feed off-screen
   - The two offsets are chosen by `isTouch`, **not** by `scale < 1` as they once were. A narrow *windowed PC* takes the 0.9 scale branch while still being a desktop, and the `FEED_TOP_DESKTOP` gap exists to clear the settings gear in that corner — which is pixel-pinned and does not shrink with the window. Measured after the change (probe frames in CoreGui, gaps in px): desktop full `top 96 / right 28`, desktop windowed `top 96 / right 28`, phone `top 59 / right 7` (the 1px is rounding on a fractional scaled height, and is unchanged from before)
6. Mobile uses a narrower row (`ROW_WIDTH` 352 vs 392 desktop) so each row's dark drop-shadow — the visible "black background" — hugs the content instead of spilling into a wide bar. The mobile width has a floor: the widest possible content (both names + a 64px weapon icon + the headshot icon + three 6px gaps) is 328px, so anything under 352 lets wide icons spill past the shadow
7. **Names have no fixed column width** (launch issue #14, fixed 2026-08-04). Each name label is `AutomaticSize.X` and carries a `UIFlexItem` in `Shrink` mode, so the two names *share* `NAME_BUDGET` — `(ROW_WIDTH - 24) - (weapon icon cap + headshot icon + three 6px gaps)`, i.e. 224 mobile / 264 desktop — rather than getting half each. A long killer borrows the room a short victim is not using; both give ground together only when the row actually overflows. `NAME_BUDGET` is derived from `ROW_WIDTH` rather than being its own constant, and doubles as the `UISizeConstraint` ceiling on a single name so one long name cannot push the weapon icon off centre. `TextTruncate.AtEnd` survives as a backstop for the genuinely unfittable case only. Measured: flex clamps at exactly the content width on both platforms, worst-case overflow +0.0px, so a row can never spill past its shadow
8. `TEXT_SIZE` is 13 on mobile (the "smaller text" half of #14 — ~8.8 real px after the 0.68 phone scale) and stays 16 on desktop. Combined with the shared budget this fits roughly 32–36 characters across both names on mobile and 31–35 on desktop, against a hard ~13 (mobile) / ~15 (desktop) *per name* before. Bot names top out at 11 characters (`DeadeyeDale`), so bots never truncated and never exercised this path
9. **Row content is `HorizontalAlignment.Right`, not `Center`** (fixed 2026-08-04). The feed is pinned to the screen's right edge, so centring content inside a fixed-width row left every row's last glyph at a different distance from that edge — measured on an iPhone 7: 37.6px on a long row against 102.6px on a short one, a **65px spread** that read as the feed not being anchored at all. Right alignment pins every row at a constant **16.2px** (the 8px `FEED_RIGHT_MOBILE` pin plus the content frame's 12px inset, scaled by 0.68) and moves the ragged edge to the left, where nothing is pinned. This is *pre-existing* and not caused by #14's auto-sizing — the old fixed-column layout put a short victim name ~109px from the edge, marginally worse. It is also what keeps the still-unfixed "rows do not hug their content" issue cosmetic rather than visible

10. **Silent for the whole onboarding lesson** (2026-08-10). `createKillRow` returns immediately when `workspace.TutorialMode` is `true`. The lesson kills eight or more bots across steps 6, 8 and 11, all of which would have stacked rows in the corner the tutorial banner and EXIT TRAINING already occupy, while the player is being taught one thing at a time. The gate sits on the row builder rather than the `KillFeed` listener, so the remote stays connected and the feed resumes on any normal server without being told the lesson ended

## Team modes

Each row colours the killer's and the victim's name by their team, read from the two ids the
payload carries -- the server reads them at fire time, because the client must never infer a team
from a character that may already have been destroyed. The colours come from [[TeamView]] and are
**relative**: the viewer's own side is blue and every other side red, so a row agrees with the
outlines in the world rather than with the server's ids. FFA sends no teams and the classic
warm/white pair stands.

Rows already on screen when a team stamp lands keep the colours they were built with. They live
about five seconds and nobody can have died before assignment, so there is nothing to repaint.

## Dependencies
- **Requires:** [[TeamView]]
- **Required by:** Nobody

## Connections
### RemoteEvents
| Remote | Direction | Other script |
|--------|-----------|-------------|
| `KillFeed` | ← Server | Listened from `Hunters.Shared.Remotes` (cross-hero — created by [[HunterSharedRemoteSetup]]). Fired by **exactly three** emitters: [[HunterHitPipeline]] for every hunter's basic and ability kills (RevolverModule, SunspikeModule, StarfallSightModule, CardsServer and GrudgekeeperModule all reach the remote through it rather than firing it themselves), [[HighNoonDamage]] for Dust's ultimate on its own parallel chain, and [[BotController]] for every bot kill. All three claim the death through KillFeedGate first, so one death posts one row |

### BindableEvents
None

### Direct require()
| Target | Function | Purpose |
|--------|----------|---------|
| [[TeamView]] | `TeamView.color()` | Turn the payload's killer/victim team ids into the colours this viewer sees |

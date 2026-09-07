---
tags: [client, localscript, ui, bounty, hud, viewport]
path: game.StarterGui.BountyListGui.BountyListClient
type: LocalScript
lines: 743
---

# BountyListClient

Persistent on-screen bounty **cards** — a centred row of up to three live 3D portraits, each with the holder's name above it and their scaled cash reward below.

## Where it sits, and why

Reworked on 2026-08-05 from a text list at the upper-left into a portrait row at **top-centre, flush under the phase timer**. `Canvas` is `AnchorPoint (0.5, 0)` at `Position {0.5, 0}, {0, 60}`.

**The 60px is a pixel pin measured against `RoundStatusGui`, and it has to be.** That GUI's timer stack occupies y 0–58, pinned in offsets; a scale-based y here would drift into it as the viewport shortens. Both ScreenGuis are `ScreenInsets = DeviceSafeInsets` with `IgnoreGuiInset = true`, so the two coordinate spaces are directly comparable — that is the only reason a number copied from one means anything in the other. The 2px is structural only: the `ZoneLabel` above and the card's name label below are both `TextScaled`, and a `TextScaled` box carries a few px of unused font padding at each end, so the rendered gap is comfortably larger than 2px.

**In TDM the script overrides that pin at runtime, because 60 is the worst case of three modes and only two of them need it.** Deathmatch stacks `RoundStatusGui`'s `ZoneLabel` *above* the match timer while the fire wall runs, which drops the timer row from 45px to ~67px; domination parks its A/B/C capture dials at y 40–76, dead centre, exactly where the middle card goes. TDM declares `usesZone = false` and has no pads, so there the 60 is pure dead space — and on a phone, where the HUD is small and the gap is not, the strip visibly floats. `refreshCanvasPosition` re-pins the row off the `workspace.Gamemode` attribute at `Position {0.5, 0}, {-0.035875, 49}`.

**The negative scale is the mechanism, not a trick.** It cancels the card's own headroom: the name label starts 20.5% down a card that is itself 17.5% of viewport height, so the transparent gap above the first glyph *grows* with the screen — 16px on a phone, ~39px at 1080 tall. Pinning the box top would leave the text drifting down on big screens; cancelling that fraction pins the first line of **text** at 49px — 4px under the 45px timer slot, 10px under the TDM score chips — on every device. Measured lift: 23px at 338 tall, 27px on a phone, 50px at 1080. The attribute is nil until MatchDirectoryService publishes it, which can land after this script runs, so the authored 60 is the fallback and the change signal corrects it. Everything outside `CROWDED_TOP_BAND` gets the lift, so a **new mode that draws anything top-centre must be added to that table** — the default is to move up.

`PhaseAnnounce` does not follow the lift and must not be made to: it is driven off `ZonePhaseName`, which only the zone sets, so it never appears in a mode that lifts.

**`RoundStatusGui.PhaseAnnounce` moved out of the way rather than this row moving down.** The banner used to sit at y 66–114, and parking the cards under it left an obvious band of dead space between the timer and the row. The banner is transient (~4s per phase change) and the row is permanent, so the permanent element takes the slot; `PhaseAnnounce` is now authored at `{0.5, 0}, {0.175, 68}` — **the same 0.175 slope as this row**, offset by this row's y (60) plus an 8px gap, so it tracks the row at a constant 8px on every device. Nothing in `RoundStatusGui` reads this panel's geometry and nothing should: KillFeedClient used to track it and was carried across the screen when it moved. The coupling is a **number kept in step by hand** — change `Canvas`'s `0.175` or its y offset and the banner must move in the same pass.

**Size is pure scale, with no `UISizeConstraint` at all.** `Size {0.34, 0}, {0.175, 0}` plus a `UIAspectRatioConstraint` (2.8, `ScaleWithParentSize`, `DominantAxis = Height`) that derives the width from the height. The row is therefore **17.5% of viewport height on every device** — the proportion that already looked right in a ~680px window.

It briefly carried a `MinSize (0, 92)` / `MaxSize (inf, 150)` clamp and that was the bug, not the safety net it looked like: the floor rendered the row at **26% of a 360px phone screen against 14% at 1080p**, which is the opposite of scaling with the screen. The clamp was deleted outright rather than widened, because *any* floor reintroduces the same class of problem — a floored row stops following the 0.175 the banner tracks, and at 320px tall a 64px floor put the row's bottom edge exactly on the banner. With no clamp there is no viewport that has to be reasoned about separately.

Measured across ten viewport heights from 320 to 1440: **17.5% at every one**, banner gap a constant 8.0px, portraits 31px at 320 → 141px at 1440, row centred to within a pixel at 1, 2 and 3 holders. The trade-off of true proportionality is that the name box is ~12px on a 360-tall phone; names are clamped to 12 characters (see `fitName`) precisely so that box never has to render more than it can.

**`BountyHolderFrame` uses a horizontal `UIListLayout`, not a `UIGridLayout`, and that is a fix rather than a preference.** The grid it replaced wrapped into a single column: three 0.3 cells plus two 0.05 gaps computed to 278.84px inside a 279px row, and a `UIGridLayout` wraps on any overflow at all. A list layout cannot wrap, and `HorizontalAlignment = Center` centres one or two cards as happily as three — which is the common case, since most rounds never have three bounties up at once. The slots were authored at 100×100 **offset** and relied on the grid to overwrite that; each now carries `Size {0.3, 0}, {1, 0}` of its own.

Card bands, measured off the live instances, are name `0.205–0.395`, portrait `0.22–0.78`, cash `0.81–1.00` — the name overlaps the top of the portrait band, and its 0.205 of empty headroom is exactly what the TDM re-pin above cancels. The 0.03 gutters either side of the portrait are what stop the cash label sitting flush on the ring at the 92px floor.

**Nothing positions itself off this panel, and the move freed the left edge.** KillFeedClient used to anchor the desktop kill feed to `Canvas` and was un-hooked when the panel moved left in 2026-07-30; both platforms now pin the feed to the top-right from screen coordinates alone. The mobile SPRINT button, which the old left-edge position squeezed to a 6.3px gap on a Galaxy A06, no longer shares a band with anything here.

## What it does
1. Waits for `Canvas` → `BountyHolderFrame`, registers the three authored slots, disables `ResetOnSpawn`, and enables the gui. Slots are authored `Visible = false` so the pre-script frame cannot flash three empty rings and placeholder text at top-centre.
1a. Seeds every `UIStroke`'s **authored** transparency into a `BountyVisibleTransparency` attribute at registration, before any fade can touch it. `getStrokeVisibleTransparency` otherwise floors that at `STROKE_VISIBLE_TRANSPARENCY` (0.82), which is correct for the two text hairlines — authored 0.82 — and would have pinned the portrait ring, authored fully opaque, at 82% transparent for the rest of the session on the first fade.
1b. Re-pins `Canvas` vertically for the active gamemode (`refreshCanvasPosition`, re-run when the `Gamemode` attribute changes) — see *Where it sits, and why* above.
2. Subscribes to three RemoteEvents under `ReplicatedStorage.Events.BountyEvents`: `BountyListUpdated` (full snapshot), `BountyClaimed`, and `BountyRemoved`.
3. `applySnapshot` (BountyListUpdated): takes the server's array **in the order it arrives**, fills a slot per holder from the first three, sets name + formatted cash, dresses the portrait, and hides any slot no longer present in the snapshot. It does **not** sort — see *Rank order is decided server-side* below.
3a. Dresses the portrait ring from the entry's `team` id via [[TeamView]] (see *Reading as a bounty* below) — assigned every snapshot rather than on change, because the occupant of a slot can swap between two republishes.
4. **Portraits.** `buildPortrait` clones `ReplicatedStorage.Hunters.<Hunter>.ViewportFrame` into the card's `IconDisplay` and builds an explicit head-height camera for it — the templates carry **no** camera and their rigs sit at scattered map coordinates, so the implicit viewport camera frames them inconsistently (Bram renders empty). `Hunters` is several thousand descendants and streams in, so every lookup inside it is a bounded `WaitForChild` and the whole build runs off-thread.
4a. The server sends an already-**resolved** `{category, subfolder, modelName}` (see [[BountyService]] → *The portrait spec*), never a skin name, so the skin-name-to-model rule stays server-side and a card cannot drift from the body the shooter is hunting for. `subfolder == "Default"` means the authored template rig itself — re-resolving through `Characters/<Hunter>/Default` would be a second rig to keep identical. Anything else swaps the template's rig for the skin model, pivoted onto where the outgoing rig stood.
4b. Rebuilds happen **only when the rendered spec key changes**, generation-guarded so a later spec beats one still resolving. The snapshot republishes roughly once a second as the reward ticks up, and re-cloning a ~270-part rig at that rate is not affordable on a phone. `hideSlot` destroys the portrait with the row — three hidden `ViewportFrame`s still render every frame.
4c. The `applyPortrait` call is **`pcall`ed inside the shared slot loop**. A throw while dressing one card would otherwise skip every later card and leave those rows stale — a cosmetic failure taking the readable part of the panel down with it. A missing skin model leaves the hunter's default portrait standing and warns, because a wrong picture still names the right hunter while an empty circle reads as a broken card.
5. `fitName` clamps display names to 12 codepoints with an ellipsis. A card is roughly as wide as it is tall, so a long name under `TextScaled` shrinks to a few unreadable pixels — and `TextTruncate` does nothing while `TextScaled` is on, which makes clamping the string the only lever that keeps every name at the same legible size.
6. `animateAmount`: rolls the reward number from its previous value to the new one via a tweened `NumberValue` (re-formatted each step by `formatCash`) with a brief pulse scale — used when a holder's live bounty value ticks up.
7. `showClaimed` (BountyClaimed): locates the victim's card (by userId, falling back to a name match), sets the amount to "CLAIMED", pulses it, and shakes the name red; holds the card ~1.2s so the CLAIMED state stays visible before it can be reused.
8. `hideSlot` (BountyRemoved, or a holder dropping out of the snapshot): clears the row and its portrait, deferring past any active "CLAIMED" hold.
9. `formatCash`: formats a number as `$1,234` with thousands separators.
10. Fade helpers cover `ViewportFrame.ImageTransparency` alongside text and strokes, and `rowAlpha` records the row's current fade level so a portrait that finishes resolving *after* the fade-in tween has run lands at the row's opacity instead of popping in solid.
11. Display-only — all bounty values (base + duration-scaled cash) and all portrait specs are computed server-side by [[BountyService]]; this script never calculates a reward or resolves a skin name.

## Rank order is decided server-side

**This script must not sort the snapshot.** [[BountyService]] sends it in rank order — oldest bounty
first — and slot assignment here is *positional*: `entries[index]` goes into `slots[index]`, so rank
**is** screen position with nothing sticky in between. `LayoutOrder` plays no part in ranking; it is
stamped once at registration (`slot.LayoutOrder = index`) purely to fix the three authored slots in
the list layout, and no code writes it again.

`applySnapshot` used to re-sort on `cash` descending with no tiebreak at all, which was half of
launch issue #29 (fixed 2026-08-06). Cash quantises to one step every 2 seconds, so two bounties
placed under 2s apart are exactly tied for most of every cycle; the server resolved that tie and
this re-sort discarded the resolution, and because `table.sort` is not stable a tied pair landed
wherever the sort happened to leave it. The cards then traded places about once per second for as
long as both bounties were up.

The lesson is general and worth keeping: **any second comparator over the same data can disagree
with the first.** The defect was having two rankings, not the particular one that was here. If the
order ever needs to change, change it in `getBountySnapshot` where rank is decided.

## Reading as a bounty, not a leaderboard

Three portraits with names and cash read just as easily as "top players", so the card carries three deliberate signals. All are authored; none cost vertical space.

**The ring is the in-world glow colour.** `IconDisplay`'s `UIStroke` is authored `(255, 170, 0)` — the exact `Highlight.FillColor` [[BountyService]] and BotVisualClient put on a bounty target's body. A player already sees that gold through walls, so the card and the glowing figure across the canyon are recognisably the same thing. It was plain white, inherited from the kill-cam swap cards where white meant nothing in particular.

**In a team mode the ring wears the holder's team colour**, because their body does. The server
ships the team **id** as `team` on the snapshot entry and [[TeamView]] turns it into the colour this
viewer sees — teammates blue, opponents red — so the ring and the mark across the canyon agree,
which is the whole point of the ring. It used to be a resolved `ringColor`; once the colour became
per-viewer, one server-computed Color3 would have painted every card the same for a lobby that no
longer agrees on what red means. FFA sends no `team` at all and the card returns to gold. Bots are
covered by the same field — the server reads the team off the bot record, so a bot bounty's card
matches the glow on its rig.

The last snapshot is held so a team stamp landing **between** two republishes still repaints the
rings; a mid-round joiner is assigned lazily on their first spawn, a long way from the last one.

**The gold is restored from an attribute, not from a constant.** Registration seeds each ring's
authored colour into `BountyRingColor` before anything can overwrite it, and `showSlot` assigns
the resolved team colour or `authored` on **every** snapshot. A slot is reused by whoever holds the next bounty, so
the fallback has to be the authored value rather than whatever the previous occupant left behind.

**Gold cannot carry contrast on this map, so a `UIShadow` does.** Redwater is an orange canyon: measured against it, a gold ring is **2.1:1 on a sunlit wall and 1.5:1 on bright sand — 48% of what white had**, which is below the 3:1 floor for a graphical boundary. `RingShadow` (black, `Transparency 0.5`) puts a dark edge immediately outside the ring, so the boundary that matters becomes gold-against-black (7.4:1) rather than gold-against-whatever-the-target-is-standing-in-front-of. Ring colour for meaning, shadow for legibility — neither does both.

**`BountyStamp` puts the word on the card.** Oswald Bold, the house display face for exactly this kind of condensed all-caps moment, straight (not rotated) and anchored to the bottom of the portrait at `Position {0.5, 0}, {0.90, 0}`, `Size {0.90, 0}, {0.32, 0}`. The word is **BOUNTY** because that is the game's own term — the combat feed already says BOUNTY POSTED / BOUNTY CLAIMED / BOUNTY ON YOU. "WANTED" appears nowhere in either place and would have been a third label for one concept.

Two things about the stamp that are easy to undo by accident:
- **It rests at `TextTransparency 0.2`, not 0.** The card exists to show which hunter and skin the target is wearing; the stamp reads *over* the portrait rather than replacing it. See *Resting transparencies* below — an absolute fade would erase this.
- **It is height-bound, not width-bound.** `TextScaled` in a 0.24-tall box capped the glyphs at ~15px even with width to spare; raising the box off the bottom edge to 0.90 and growing it to 0.32 took them to 21px at a ~680px viewport. Widening it would have done nothing. It was briefly rotated `-20` as a poster-style overprint, which read well at desktop sizes but covered the face — the thing the portrait is for.

**The cash is amber, not green.** The authored gradient was `(85,170,0) → (157,255,28) → white` with a green `UIShadow`, which matched nothing: every bounty string in the combat feed is in the orange/amber family (BOUNTY POSTED is `255,188,64`) and `AMBER_TEXT (248,162,27)` is the house cash token. It now ramps `(183,102,16) → (248,162,27) → (255,240,200)` over a `(255,191,62)` bloom.

## Resting transparencies
`getStrokeVisibleTransparency` / `getTextVisibleTransparency` exist because the fade path assigns transparency **absolutely**, and three elements here are authored deliberately non-opaque: the two text hairlines at `0.82`, the stamp at `0.2`, and its stroke at `0.15`. Both helpers compose `resting + (1 - resting) x rowAlpha`, so showing a row returns each element to its authored value and hiding one still reaches a true 1.0.

Both are seeded from the **authored** property at registration, before any fade can run. That ordering is load-bearing for the ring in particular: `getStrokeVisibleTransparency` floors an unseeded stroke at `STROKE_VISIBLE_TRANSPARENCY` (0.82), which is right for the hairlines and would have pinned the fully-opaque gold ring at 82% transparent for the rest of the session on the first fade.

## Portrait framing is copied from the kill-cam swap cards
`PORTRAIT_FOV` 40, `PORTRAIT_DISTANCE` 4.6, `PORTRAIT_FOCUS_DROP` 0.45, `PORTRAIT_EYE_LIFT` 0.5 and `sanitizeRig` are the same constants and the same treatment the mid-match hunter-switch panel uses, so a hunter looks identical in both places. `Anchored` is deliberately untouched: the authored templates are unanchored AnimationConstraint rigs that render correctly as static portraits, and no physics runs inside a viewport.

The one deliberate difference is that this script **rebuilds the whole portrait** on a change rather than re-dressing a standing rig. The swap panel's four cards are permanent and re-cloning would flicker a portrait mid-kill-cam; here a card's occupant changes wholesale whenever the list reorders, so there is nothing worth keeping.

## Dependencies
- **Requires:** [[TeamView]]
- **Required by:** Nobody

## Connections
### RemoteEvents
| Remote | Direction | Other script |
|--------|-----------|-------------|
| `BountyListUpdated` | ← Server | [[BountyService]] publishes the sorted snapshot (top holders + scaled cash + resolved hunter/skin spec) every ~1s and on change |
| `BountyClaimed` | ← Server | [[BountyService]] fires when a bounty is claimed → flashes CLAIMED on the victim's card |
| `BountyRemoved` | ← Server | [[BountyService]] fires when a holder dies/leaves → clears the card |

### BindableEvents
None

### Direct require()
| Target | Function | Purpose |
|--------|----------|---------|
| [[TeamView]] | `TeamView.color()`, `TeamView.onChanged()` | Turn the snapshot's `team` id into this viewer's ring colour, and repaint the standing cards when the viewer's own side is stamped |

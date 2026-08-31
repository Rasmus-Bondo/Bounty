# Task Plan: Trading Post UI Migration (execute SHOP_UI_MIGRATION_SPEC.md)

**Plan of record: `SHOP_UI_MIGRATION_SPEC.md`** — this file tracks execution status only.
Spec authored 2026-08-23 (all 9 decisions settled by owner), executed 2026-08-23 by a cold session.
Previous Domination task_plan archived to `depricated/superseded-md-2026-08-23/`.

## Places (all connected, edit mode)
- Bounty `place:131701626847012` (target) · scratch `place:112014319307228` (Bounty - UI Update, READ ONLY)
- Redwater / Frostbite: untouched by this task.

## Phases
- [x] 0. Survey: prototype ShopController + Shop/CurrencyShop tree (scratch); Bounty MenuHandlerScript,
      CurrencyHudController, TradingPostController vault items 9/9b/11/12/15, old controllers' catalogs.
- [x] 1. Copy: export Shop, CurrencyShop, SFX.UIButtonClick from scratch → import into Bounty. Set
      Enabled=false, SoundGroup=SFX on 5 sounds, delete Shop.TextButton, AfterRedemption Visible=false,
      TitlesScroll ClipsDescendants=true. Verify WorldModels survived.
- [x] 2. Device matrix on FIRST draft (done; Content fit decided, implemented in phase 3) (Shop.Canvas aspect lock / fit to topbar..0.80 band).
- [x] 3. ShopController rewrite (DONE: 9 scripts uploaded + loadstring OK: RS.Config.SkinCatalog, Shop.ShopController, Shop.Modules.{ShopCore,ShopState,FeaturedTab,HuntersTab,WeaponsTab,ExtrasTab,ShopVaultController}; local copies in scratchpad/build/*.lua): wire to backend (§5), comments 1-6 (§4), nav integration (§6), sounds (§8).
      Split into Shop/Modules/* ModuleScripts (SkinCatalog in ReplicatedStorage.Config).
- [x] 4. CurrencyShop + ShopVaultController (BUY cloned from BuyButtonRobux at BottomFrame y1.42; ReturnFrame GO BACK under SideFrame chips) (§7): move vault cinematic code, BUY button, GO BACK, chips.
- [x] 5. MenuHandlerScript re-point DONE (var renamed tradingPostGui, WaitForChild("Shop")); DONE: CurrencyHudController hide Trading Post row while Shop.Enabled;
      Collection Shop module deep-link writers → StarterGui.Shop attributes.
- [x] 6. Syntax-check all edited scripts (loadstring); device matrix again.
- [x] 7. Docs DONE 2026-08-23: 9 new vault .md (Shop/ShopController, Shop/Modules/Shop*, Config/SkinCatalog) + 5 superseded notes
      + 5 patched files; graph --full rebuilt 118 nodes / 411 extracted edges, shop* edges verified; UI_STYLE_GUIDE §5.4b + DO registry;
      changelog metadata bullet + Changed entry, capture retired; memories (currency_hud rewritten, menu_tab_gate, limited_stock,
      NEW project_trading_post_shop); spec header BUILT + §12 as-built deviations.

**ALL PHASES COMPLETE.** Live playtest: DONE + VERIFIED by the owner 2026-08-23 (see spec §12.10).

## Errors Encountered
| Error | Attempt | Resolution |
|-------|---------|------------|

## Phase 8 — playtest feedback round 1 (2026-08-23)
- [x] 8a. Titles + emotes: the authored 2x canvas held 8 cards (cells scale vs CANVAS, canvas vs PARENT) -> Core.fitGridCanvas on 4 grids.
- [x] 8b. Top-left stray = Shop.Templates Frames rendering -> authored Visible=false + hidden at load + Core.cloneTemplate.
- [x] 8c. Header displaced by Core.tween instance-key (fade cancelled slide) -> tween keyed per property set; 6 grids 0.38 -> 0.3705.
- [x] 8d. NEW Shop.Modules.ShopStandDisplay (stand preview + camera, port of old HuntersBuyController) hooked from Controller/Hunters/Weapons.
- [x] 8e. putWeapon frames by world-axis extents + 45% card height budget (viewport behind name/pill) + refit on AbsoluteSize.
- [x] 8f. Core.attachRobuxPrice (robux.png + AutomaticSize number, centred) + controller.setRobuxPrice; 5 sites.
- [x] 8g. Docs: vault (ShopStandDisplay.md new + 7 patched), graph (119 nodes / 419 extracted), changelog round-1 paragraph + capture retired,
      spec header + section 13, UI_STYLE_GUIDE 5.4b Robux row, memories (scrollingframe, trading_post, NEW robux_price_icon).

**PHASE 8 COMPLETE (2026-08-23 afternoon).** VERIFIED live by the owner the same evening (stand swaps + camera, grids, BUY row).

## Phase 9 — playtest round 2: panel alignment (2026-08-23, later)
- [x] 9a. Tab canvases are 0.8 wide vs TopFrame 0.8738 -> bar edges at canvas fraction -0.0461 / 1.0461. Authored Position.X.Scale only
      (execute_luau, not in hook capture): Featured CanvasLeft/CanvasRight on the bar edges (+ CanvasLeftLimited shifted with the left card);
      Hunters/Weapons/Extras left frames 0.1898 -> 0.1391, right purchase panels 0.8663 -> 0.9129; root Hunters/Weapons grids a further
      0.0046 left so the card chrome (0.95 Canvas child) meets the bar. Verified 0.0 px in edit mode (HUNTERS + FEATURED screenshots).
- [x] 9b. Docs: changelog round-2 paragraph, spec status + section 14, this plan. No vault/guide changes (authored geometry only).

- [x] 9c. EMOTES -> equipped hunter on the stand (openExtraCategory -> Stand.showHunter, featured close-up kept) + selected emote plays on it
      (NEW Stand.playEmote/stopEmote, Action looped, token-guarded); back -> Stand.showFeatured when state == "hunter".
- [x] 9d. Title style on CosmeticPurchaseFrame.CharacterName (TitleRenderer.apply at 0.8 slot height, applied after the panel fade-in lands,
      token-cancelled; same-title refresh keeps it). Harness-verified DEADEYE (static) + HIGH NOON (animated).
- [x] 9e. Docs: ShopExtrasTab.md (+ShopStandDisplay require, 1037 lines) + ShopStandDisplay.md (530, playEmote), graph 119/420, changelog, spec 14.8-9.

- [x] 9f. EXTRAS round 3: equipped hunter on the stand for the WHOLE tab (ExtrasTab.show; applyStandForTab skips tab 4; back = stopEmote only);
      EMOTES tile rig cycles random emotes (startEmoteTileLoop, 6 s cap, 0.25 s blend); emote cards = equipped hunter (Stand.makePreviewRig,
      lazy rebuild on EMOTES open; frameRig re-derived: body span at 0.42 of the card, centre 0.55); header ViewportFrame DELETED (authored +
      code). Studio = build (ExtrasTab 45335/3057310701, Stand 21132/1378446120, Controller 20091/3521842949). Vault x3, graph 420, changelog, spec 14.10.
      NOTE: hunter templates use AnimationConstraints + disabled BallSockets -> edit-mode unanchored clones collapse; harness them anchored.

**PHASE 9 COMPLETE — VERIFIED live by the owner 2026-08-23** (alignment, EXTRAS stand + tile emotes + card rigs + emote playback, title style on the panel, + everything from phase 8). Only a real-phone pass remains unexercised.

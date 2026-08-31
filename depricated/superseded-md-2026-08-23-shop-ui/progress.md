# Progress — Shop UI Migration

## Session 1 — 2026-08-23
- Planning files created; starting survey.

## State at 2026-08-23 (pre-compact checkpoint)
DONE: import (Shop, CurrencyShop, SFX.UIButtonClick), instance prep (Content frame, Templates folder, BUY/GO BACK clones,
Animate scripts disabled, AfterRedemption hidden, TitlesScroll clips), all 9 scripts written+uploaded+compiled,
MenuHandlerScript re-pointed to StarterGui.Shop (variable renamed tradingPostGui).
REMAINING (in order):
 a. CurrencyHudController: remove shopCanvas mirror (L102-118), remove 5TradingPostFrame from PAGE_LAYOUT, remove VaultLayout branch
    (L211-220) + its AttributeChanged connect (L280), gate `show` on `not playerGui.Shop.Enabled` (listen to its Enabled). Keep Row code.
 b. CollectionGuiController.Shop L160-205: FindFirstChild("Shop") instead of ReworkReworkedBuyMenu; AccessoryModeRequest on the
    ScreenGui itself (no EmoteBuyFrame); TradingPostRequestedTab names unchanged (controller maps 2Hunters/3Skins/4Emotes).
 c. BattlePassClient.findShopEmoteRig (L644-662): look in playerGui.Shop.Templates.EmoteCard.Canvas.ViewportFrame.WorldModel.Rig
    (fallback old path).
 d. ReworkedUIPlay L537: add { name = "Shop" } and { name = "CurrencyShop" } to the menus-that-block-PLAY list.
 e. Disable old LocalScripts: ReworkReworkedBuyMenu.{TradingPostController,HuntersBuyController,EmoteBuyController,TitleBuyController}
    (Disabled=true) — they play success SFX/sprinkle unconditionally + duplicate state pulls. Note as deviation from "untouched".
 f. loadstring-check every edited script; device matrix with Shop enabled (FEATURED/HUNTERS visible) at hd_1080/iphone_14/ipad.
 g. Docs: LocalBounty/StarterGui/Shop/ShopController.md + Shop/Modules/*.md (7) + LocalBounty/ReplicatedStorage/Config/SkinCatalog.md;
    "superseded by Shop" line atop the 5 old vault files; update CurrencyHudController.md/MenuHandlerScript.md/BattlePassClient.md/
    CollectionGuiController/Shop.md connections; python update_bounty_graph.py; grep graph for "_src": "shopcontroller".
 h. UI_STYLE_GUIDE: MainMenuGui DO 1->8, add Shop/CurrencyShop (DO 0) to Bounty registry, add purchase-button hover recipe 5.4.
 i. changelog/UNRELEASED.md entry (Edit anchored on heading; not data-affecting; rollback = re-point MenuHandlerScript + re-enable old
    scripts; known gap: BUNDLES tab inert, bundle-exclusive skins show BUNDLE ONLY). Memories: project_currency_hud, project_menu_tab_gate,
    project_limited_stock. Spec header -> BUILT with deviations (rarity words, purchase-panel copy, old scripts disabled, FEEDBACK_ERR).
Design notes for recovery: Content fit in ShopController (min 16:9, inset/nav-bar band); HUD chips hidden on Trading Post;
old ScreenGui kept disabled for rollback; copy I invented = card Rarity words (DEFAULT/GROUP PERK/BOUNTY PASS/BUNDLE/LIMITED/RARE/EPIC/
LEGENDARY by token price) and Extras purchase-panel descriptions — flag to owner.

## Post-compact session (2026-08-23, cont.)
- a-e DONE: CurrencyHudController rewritten (Stack-only; Row/mirror/VaultLayout removed; gated on `not Shop.Enabled`);
  CollectionGuiController.Shop writes TradingPostRequestedTab/AccessoryModeRequest/Requested* on StarterGui.Shop;
  BattlePassClient.findShopEmoteRig -> Shop.Templates.EmoteCard rig; ReworkedUIPlay BLOCKING_PANELS += Shop, CurrencyShop;
  4 old LocalScripts under ReworkReworkedBuyMenu set Disabled=true (execute_luau -> not in hook capture; write up by hand).
- f DONE: all 14 edited/new scripts loadstring OK. Device check (edit mode, fit replicated with inset 58): hd_1080 bar top 85 /
  draw bottom 821 / nav 864; iphone_14 (749x368 sim viewport) h shrunk 368->343, top pinned 58, bottom 292 < 294; ipad 4:3
  h=575 centred, bar 140, bottom 533, nav 613 -- no wrap, no squash. Studio restored (sim off, Shop disabled, Content authored).
- g-i DONE: vault (9 new, 5 superseded, 5 patched; tab modules renamed Shop* in Studio + vault because the graph merged
  HuntersTab with the Collection's HuntersTab node), graph --full OK, UI_STYLE_GUIDE (5.4b recipe, DO registry corrected:
  MainMenuGui is 8 in Studio, guide said 1), changelog (metadata bullet + Changed entry; capture retired 10:33Z), memories,
  spec -> BUILT + §12. Studio left: Shop/CurrencyShop Enabled=false, old GUI disabled, device sim off, Content authored values.

## Phase 8 — playtest feedback round 1 (2026-08-23, afternoon)
Code DONE (all Studio sources byte-identical to scratchpad/build, 9 scripts compile):
- 8a Core.fitGridCanvas (CanvasSize scale is relative to the PARENT, cells to the CANVAS; authored 2x held 8 cards) -> Titles/Emotes/HunterSkins/WeaponSkins
- 8b Shop.Templates.* Visible=false (authored) + Core hides at load + Core.cloneTemplate at the 4 clone sites
- 8c Core.tween keyed per property set (fade was cancelling the slide; header sat at -0.05/-0.025 start offset) + 6 grids 0.38 -> 0.3705 wide (column width)
- 8d NEW Shop.Modules.ShopStandDisplay (port of old HuntersBuyController stand: hunter/weapon on FeaturedItems.Stand, idle, bob, drag-to-spin, CameraPartHunterCloseup / FeaturedCloseup, Fortuna back via ShowDefaultFortuna); hooks in ShopController (applyStandForTab, assumeFeatured/forget/release), HuntersTab (selectSkinCard + list = equipped), WeaponsTab (selectWeaponSkinCard + list = equipped gun)
- 8e putWeapon measures WORLD extents (GetBoundingBox size is in model-local axes: Bram 0.75x0.28x3.30 vs 3.30x0.75x0.28) + height share 45% for cards (viewport spans whole card behind name/rarity/pill) / 77% selected; refit on AbsoluteSize
- 8f Core.attachRobuxPrice (robux.png ImageLabel + AutomaticSize number, UIListLayout centred, mirrors label colour/transparency/visible/stroke) + controller.setRobuxPrice; used by vault BUY, weapons limited BUY, hunter/bundle/limited price labels. Verified d=0.0 centring in harness; text 0.98 of row height matches BUY weight.
Verified in edit mode: tween channels, fitGridCanvas (17 -> 4.5x, cell px unchanged, no compounding), weapon card framing screenshot (8 guns), BUY row screenshot.
TODO: docs (vault ShopStandDisplay.md + ShopCore/Controller/tab md updates), graph, changelog, spec §12, memory, task_plan.

## Phase 9 — playtest round 2 (2026-08-23, later)
- Side panels moved onto the top bar's edges (authored Position.X.Scale via execute_luau; 20 frames across the 4 tab canvases).
  Verified 0.0 px in edit mode; Studio restored (Shop disabled, DO 0, ExtrasCanvas visible, Hunters list hidden / Skins visible).
- Changelog round-2 paragraph + spec §14 + status line written. Owed: live pass.
- 9c/9d: ShopStandDisplay.playEmote/stopEmote + ShopExtrasTab (equipped hunter on stand for EMOTES, emote on stand, title style on purchase heading).
  Studio = build copies (ShopStandDisplay 20582/4047394644, ShopExtrasTab 39954/1246991996), both compile; harness screenshots OK; Studio restored (probe rig + harness GUI removed, camera Fixed).
- 9f: EXTRAS round 3 (stand for whole tab, tile random emotes, equipped-hunter card rigs + new frameRig band, header viewport removed). Studio = build copies, compile OK, probes removed.

# Findings — Shop UI Migration (2026-08-23)

(appended as discovered; spec §5/§11 already carry the surveyed contracts)

## Prototype ShopController (scratch, 1973 lines) — read in full 2026-08-23
Local copy: scratchpad/ShopController.proto.lua. Structure by line:
- 1-37 header, featured preview rig + FeaturedPreviewLoop anim (108187809145790) on CanvasLeft rig
- 39-162 tween helpers (cancelTween/tween[.85x faster]/captureFadeTargets/setFade/tweenFade), fade maps
- 167-234 UI_SFX_CONTROLLER_V1: playUISound (clone → SoundService, NO SoundGroup), playUIHover (45ms), bindReturnButtonHover
- 236-834 Hunters tab: putModel (layered clothing mask for VesperDefault), numbered/cardCanvas/worldOf, bindCard (InteractionHitbox TextButton),
  ripple(parent,enter,reverse,done), populate(folder,color) builds skin cards from Characters.<H>.Default/Skin, chooseHunter, showSelector,
  backButton, transitionOutOfHunters. Mocked: skinOwnership{}, hunterPurchased, FORTUNA gating at L702/711.
- 836-1081 Weapons tab: putWeapon (auto-orient), defaultWeapon(^default), populateWeaponCards (clicks build skin cards from WeaponSkins.<H>),
  showWeaponsSelector, transitionOutWeapons, weaponBack. Mocked weaponSkinOwnership{}.
- 1083-1256 Extras (do-block, extrasController table): showHome/openExtraCategory/showExtrasCategory/selectExtraItem/transitionOut/hideRoot.
  Category tiles 1Emotes/2Titles; lists Titles (1Titles,2Titles templates) and Emotes (1Skin..3Skin templates). selectExtraItem only sets name.
- 1258-1416 tabs: Hitbox per tab, setTabVisual, selectTab, leaveCurrentShopContent (hunters→weapons→extras chain; FEATURED not routed),
  tab Activated → index 1 showFeaturedContent / 2 showSelector / 3 showWeaponsSelector / 4 extras.showHome / 5 hide all.
- 1418-1615 Featured right BuyButton: gradients PurchaseableGradient/UnHoverGradient/OwnedGradient, TopBarFrame, UIShadow, Hitbox;
  setBuyButtonState(Owned/Default/Hovered); playFeaturedTokenBurst (12 tokens fly to TopFrame token icon).
- 1617-1668 bindPurchaseHover(button, purchased) one-shot, returns re-arm fn.
- 1670-1798 hunter buy (BuyButtonCash/BuyButtonRobux/OwnedButton, ItemPriceCashText/ItemPriceRobuxText), ownHunterOffer (Fortuna card repaint),
  skin buy (updateSkinPurchasePanel), weapon buy (updateWeaponPurchasePanel).
- 1800-1840 prepareClosedState; 1843-1885 bindCurrencyPurchaseHover (TopFrame chips +); 1887-1959 openShop/closeShop; 1961 openButton toggle.
Key instance facts: buy "buttons" are Frames with a runtime Hitbox TextButton; cards get InteractionHitbox; PURCHASE/OWNED via OwnedButton sibling.
Chip + is Frame BuyCurrencyButton (not GuiButton → Activated never bound; L1879 guard). Tabs 1FEATURED..5BUNDLES under TopFrame.Tabs.

## Bounty-side survey (2026-08-23)
- ViewportFrames in the prototype have CurrentCamera=nil but a HIDDEN saved camera (docs: CFrame+FOV serialize with the
  ViewportFrame "so the client can render without a Camera object"). Rigs sit at world ~719,7,766. Must verify the hidden
  camera survives export/import by SCREENSHOT in Bounty, not by property read.
- Shop.Canvas is full-screen (1x1, BackgroundTransparency 0) with a vertical gradient: opaque top ~30% and bottom ~26%,
  transparent middle => the lobby 3D scene shows through. Camera stays at CameraPartFeaturedCloseup (FeaturedSequence leaves it
  there; MenuHandlerScript's cameraParts[5TradingPostFrame]=CameraPartShop is only the bird-flight target).
- Old shop LocalScripts keep RUNNING under a disabled ScreenGui: TradingPostController plays PurchaseSucces + 3D sprinkle on
  EVERY ShopPurchaseSuccessEvent unconditionally (L220). => must Disable the 4 old LocalScripts (AccessoryBuyPanel is a Module).
- MenuHandlerScript: `reworkReworkedBuyMenu` local at L70 (WaitForChild), used at L1034/1047/1056/1076/1086-1092/1116/1142/
  1165/1176/1197. openTradingPostCinematic: FeaturedSequence.Play() then after 2.85s enables MainMenuGui + shop.
  openCurrencyVaultFromMenu sets VaultReturnMenuFrame + VaultOnOpen attrs then enables the shop (no transition of its own).
- CurrencyHudController: mirrors OLD shop canvas (L102); PAGE_LAYOUT has 5TradingPostFrame=Row; VaultLayout attr branch
  shows the Row canvas in the vault. New design: HUD chips never on Trading Post, never in vault; drop mirror + Row page +
  VaultLayout branch; add `not shopGui.Enabled` gate.
- BattlePassClient.findShopEmoteRig (L644) reads old GUI EmoteBuyFrame cards for a `Rig` -> re-point to Shop.Templates.
- Collection Shop.navigate (CollectionGuiController.Shop L160-205) writes TradingPostRequestedTab (2Hunters/3Skins/4Emotes),
  AccessoryModeRequest (on EmoteBuyFrame), RequestedHunter/RequestedHunterSkin/RequestedWeaponHunter/RequestedWeaponSkin/
  RequestedTitle/RequestedEmote on the old ScreenGui. Re-point all to StarterGui.Shop (AccessoryModeRequest on the ScreenGui).
- ReworkedUIPlay L537 lists ReworkReworkedBuyMenu among menus that block PLAY -> add Shop (and CurrencyShop).
- Backend: SkinDataEvent(ownedSkins[h][s], equippedHunter, equippedSkin, ownedCharacters, ownedWeaponSkins[h][s],
  equippedWeaponSkins[h]); TitleStateEvent{owned[id]=true}; EmoteStateEvent{owned[id]=true, equipped}; LimitedStockEvent
  {itemId=remaining}; ShopPurchaseSuccessEvent() or (kind, amount, productId) [StoreService]; RedeemCodeResponse
  {success,message}. TitleRenderer.apply(label, text, titleId) — THREE args. EmoteConfig.EMOTES[id]={displayName,
  animationId="rbxassetid://..",defaultOwned,price|unlockText}; ORDER list. TitlesConfig.Purchasable() -> {hunter, entry{id,
  label,style,color,unlock{kind,currency,price}}}. LimitedStockConfig.Items.PrestigeCard{Cap,Kind,Character,SkinName,ProductId,Title}.
- Old catalog tables to lift into ReplicatedStorage.Config.SkinCatalog: HUNTERS (Title/Class/Description/Free/ProductId/
  CashPrice), SKINS[h] (Name/Title/Header/Description/TokenPrice), WEAPON_SKINS[h] (index1 = free default).
- Style guide: FEEDBACK_ERR = 220,140,140 (inline error text); FEEDBACK_OK 150,220,140; motion table §6; Bounty DisplayOrder
  line in §7 says MainMenuGui 1 (live is 8 — fix).
- ReplicatedStorage.Modules.TitleStyles MISSING in Bounty (TitleRenderer requires it from somewhere else — check only if needed).

## First-draft device matrix (after import, 2026-08-23)
- Hidden viewport cameras SURVIVED import (EMOTES tile rig renders in Bounty).
- HD1080: STORE bar top ~0.078 (85px) clears 58px topbar; content bottom ~0.76 clears nav bar 0.80.
- iPhone14 (844x390): STORE bar top = 30px < 58px inset -> would sit under topbar; content bottom 0.76 OK.
- iPad 4:3: canvas stretched -> "CUSTOMIZE YOUR STYLE" wraps, tiles squashed. Need a min-16:9 fit.
- Decision: insert `Shop.Canvas.Content` (AnchorPoint .5,.5; all tab canvases + TopFrame move under it); Canvas keeps the
  full-screen gradient backdrop. Fit fn: h = min(vh, vw/(16/9)); enforce TopFrame top (0.0785*h) >= GuiInset.Y and
  draw bottom (0.761*h) <= 0.80*vh - 2px by shrinking h and pinning y0 = inset - 0.0785*h; else centre vertically.

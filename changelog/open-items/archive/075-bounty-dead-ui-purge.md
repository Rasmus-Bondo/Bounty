# 75 — Bounty dead-UI purge

[Open items index](../../OPEN-ITEMS.md) · [Conventions](../../CONVENTIONS.md)

---

**Bounty dead-UI purge — done, and the four "probably dead" GUIs were mostly alive.**
*(raised: [Hotfix 2](../../2026-08-01-hotfix-2.md) — audited and closed 2026-08-03.)*
The original bullet named `ReworkReworkedBuyMenu` (5,054 descendants, 58% of `StarterGui`) as the
obvious deletion target. **It is the Trading Post.** `TradingPostController`,
`HuntersBuyController`, `EmoteBuyController` and `TitleBuyController` all live inside it and five
external scripts drive it — there is no 58% win available, so do not re-raise it. Of the rest:
`MobilePlayButtonBackup` is the live touch PLAY button (`ReworkedUIPlay:388`), `LootboxMenu` is the
live chest reveal (`CollectionClient:65`), and `ChestTest` had already been deleted from Studio —
it survived only as an empty vault folder, which is where the flag came from. **That bullet was
written from the vault rather than the data model**, which is why three of its four calls were
wrong.
Actually deleted (backed up to `backups/*_deadui_2026-08-03.rbxm`, restorable individually):
`CinematicTest`, a 1,393-line abandoned duplicate of the shipped
`ReplicatedStorage.Modules.FeaturedSequence` whose LocalScript ran on every client despite the GUI
being disabled; `RankLeaderboardGuiLegacy`, inert and superseded, hunting a `CanvasLeft >
3Leaderboard` button that no longer exists; and `CurrencyGui`, superseded by `CurrencyHudGui` with
zero external references, whose *enabled* `TestButtonScript` pulled a 2,714-line module onto every
client to power a debug button. Plus the orphaned `ReplicatedStorage.PlayCurrencyCounter` remote,
which had no listener. Net: 66 instances, ~6,100 lines of dead client Luau, `StarterGui` 8,804 →
8,738. Four stale vault folders (`CurrencyGui`, `CinematicTest`, `ShopMenuGui`, `ChestTest`) went
with them.

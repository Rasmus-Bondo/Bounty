# StarterGui

All ScreenGuis and UI scripts that are cloned into each player's PlayerGui on join. These drive the HUD, menus, and overlay screens.

**Path:** `game.StarterGui`

## ScreenGuis

| ScreenGui | Script(s) | Purpose |
|-----------|-----------|---------|
| [[GameplayGui]] | [[RoleRevealClient]] | "FIGHT!" text flash on round start |
| [[RevolverGui]] | *(driven by [[BanditGun RevolverGuiClient]])* | Animated revolver cylinder HUD |
| [[CurrencyGui]] | [[CurrencyDisplayScript]] | Animated cash counter with smooth tweening |
| [[HealthDisplayGui]] | [[HealthBarClient]] | Health bar, XP bar, and level badge |
| [[StatMenuGui]] | [[StatMenuScript]] | Stats menu with My Stats / Scoreboard tabs (M key) |
| [[LobbyGui]] | [[LobbyScript]] | Join/Leave button with 4 context states + round info |
| [[PostGameGui]] | [[PostGameScript]] | Post-round leaderboard overlay (top 5 + local player) |
| [[RespawnGui]] | [[RespawnScript]] | Respawn countdown display |
| [[ZoneIndicatorGui]] | [[ZoneIndicatorScript]] | Zone phase name + timer with color-coded urgency |
| [[CardsGui]] | [[OpenStoreScript]], [[MenuHandler]], [[BuyButtonScript]] | Card shop camera, open/close, purchase button |
| InGameLeaderboard | *(no script)* | Default or placeholder leaderboard |
| MobileControlsGui | *(no script — driven by [[InputController]])* | Touch buttons for mobile players |
| ImageHolder | *(no script)* | Asset preload container |
| GunGui | *(no script)* | Placeholder gun UI |

## Folders

| Folder | Contents | Purpose |
|--------|----------|---------|
| [[MainMenuFolder]] | [[MainMenuGui LocalScript]], HuntersMenu | Main menu hover effects, music, play button |

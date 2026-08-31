# MainMenuFolder

Contains the main menu ScreenGuis — the primary landing screen with store/mode selection buttons and hover effects.

**Path:** `game.StarterGui.MainMenuFolder`
**Type:** Folder

## Contents

| Child | Type | Description |
|-------|------|-------------|
| MainMenuGui | ScreenGui | Main menu with play button, store frames, and mode selection |
| HuntersMenu | ScreenGui | Hunters mode sub-menu (placeholder) |

## MainMenuGui Structure

| Element | Description |
|---------|-------------|
| CanvasBottom | Bottom container with store frames and [[MainMenuGui LocalScript]] |
| PlayFrame | Play button + ChangeModeButton |
| ArsenalFrame | Arsenal store tile with dual gun icons |
| HuntersFrame | Hunters mode tile |
| BattlePassFrame | Battle pass tile |
| StoreFrame | Store tile |
| MapFrame | Map selection tile |

## Scripts

| Script | Type | Purpose |
|--------|------|---------|
| [[MainMenuGui LocalScript]] | LocalScript | Hover effects, gradient sweeps, gun flick animations, music control |

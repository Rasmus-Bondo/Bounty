---
tags:
  - client
  - localscript
  - audio
path: game.StarterPlayer.StarterPlayerScripts.RbxCharacterSounds
type: LocalScript
lines: 23
---

# RbxCharacterSounds

Empty override that stops Roblox's core character sound system from ever running.

## What it does

1. Contains no code at all — it is comments only. The engine copies its core scripts into `PlayerScripts` when a client joins but skips any whose name already exists in `StarterPlayerScripts`, so this file's *name* is the whole mechanism
2. Suppresses all nine default character Sounds for every character on the client: `Died`, `Running`, `Jumping`, `Landing`, `Splash`, `Swimming`, `Climbing`, `GettingUp`, `FreeFalling`. They are never created, rather than created and muted
3. Replaces the deleted `DefaultDeathSoundRemover` and `DefaultFootStepRemover`, which sat in `StarterCharacterScripts` and could only reach the local character while other players' default death and footstep sounds still played
4. Must not be renamed, disabled, or deleted as an apparently empty script — any of those restores all nine sounds

## Dependencies

- **Requires:** Nothing
- **Required by:** Nobody

## Connections

### RemoteEvents

None

### BindableEvents

None

### Direct require()

None

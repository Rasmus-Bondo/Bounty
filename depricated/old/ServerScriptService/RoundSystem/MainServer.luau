local SSS = game.ServerScriptService

-- Round services (siblings in RoundSystem)
local RoundController = require(script.Parent.RoundController)
local LobbyService = require(script.Parent.LobbyService)
local InvulnService = require(script.Parent.InvulnService)
local DestructibleService = require(script.Parent.DestructibleService)
local ZoneService = require(script.Parent.ZoneService)

-- Player services
local DataService = require(SSS.PlayerServices.DataService)
local ProgressionService = require(SSS.PlayerServices.ProgressionService)
local CollisionService = require(SSS.PlayerServices.CollisionService)
local MovementService = require(SSS.PlayerServices.MovementService)
local LeaderstatService = require(SSS.PlayerServices.LeaderstatService)

-- World services
local RagdollService = require(SSS.WorldServices.RagdollService)
local FootstepService = require(SSS.WorldServices.FootstepService)
local AnimateService = require(SSS.WorldServices.AnimateService)

-- Initialize utility services
RagdollService.Initialize()
CollisionService.Initialize()
LeaderstatService.Initialize()
FootstepService.Initialize()
AnimateService.Initialize()
MovementService.Initialize()
DataService.Initialize()
print("[MainServer] DataService initialized")
ProgressionService.Initialize()
print("[MainServer] ProgressionService initialized")
LobbyService.Initialize()
InvulnService.Initialize()
DestructibleService.Initialize()
ZoneService.Initialize()

-- Start round system
RoundController.connectEvents()
RoundController.connectPlayers()
RoundController.run()
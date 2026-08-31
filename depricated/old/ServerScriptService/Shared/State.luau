local State = {
	roundActive = false,
	roundStarting = false,
	currentPhase = "Waiting",
	roundCancelled = false,
	playerKills = {},
	playerDeaths = {},
	optedInPlayers = {},
}

function State:reset()
	self.roundActive = false
	self.roundStarting = false
	self.currentPhase = "Waiting"
	self.roundCancelled = false
	self.playerKills = {}
end

return State
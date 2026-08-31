local Config = {
	-- Round system
	MIN_PLAYERS = 1, -- Minimum players needed to start a round
	INTERMISSION_TIME = 10, -- Seconds between rounds for stats/reset
	ROUND_TIME = 600, -- Maximum round duration in seconds
	RESPAWN_DELAY = 3, -- Seconds before a dead player respawns
	PLAYER_MAX_HEALTH = 150, -- Starting health for each player
	LOBBY_SWITCH_COOLDOWN = 5, -- Seconds before a player can join or leave an active round again

	-- Invulnerability
	INVULN_DURATION = 10, -- Seconds of spawn protection after respawning
	INVULN_FLICKER_BASE = 0.3, -- Character flicker rate during invulnerability (seconds)
	INVULN_FLICKER_FAST = 0.1, -- Faster flicker rate when invuln is about to expire
	INVULN_WARNING_TIME = 3, -- Seconds before expiry to switch to fast flicker

	-- Zone system
	ZONE_DAMAGE_PER_SEC = 10, -- Damage per second dealt to players outside the safe zone
	ZONE_PHASE_DURATION = 150, -- Duration of each zone shrink phase in seconds (originally 150 seconds)
	ZONE_DAMAGE_INTERVAL = 0.5, -- How often zone damage ticks are applied (seconds)
	ZONE_START_Z = -700, -- Southern Z boundary of the full map zone
	ZONE_END_Z = 200, -- Northern Z boundary of the full map zone
	ZONE_CENTER_RANDOM_RANGE = 40, -- Max random offset for the zone center each round

	-- Movement
	WALK_SPEED = 16, -- Default walking speed (studs/sec)
	SPRINT_SPEED = 24, -- Speed while sprinting (studs/sec)
	CROUCH_SPEED = 8, -- Speed while crouching (studs/sec)
	MAX_STAMINA = 100, -- Maximum stamina pool for sprinting
	STAMINA_DRAIN_RATE = 100 / 6, -- Stamina consumed per second while sprinting
	STAMINA_REGEN_RATE = 100 / 3.5, -- Stamina recovered per second when not sprinting
	STAMINA_REGEN_DELAY = 2, -- Seconds after sprinting before stamina starts regenerating
	CROUCH_HIP_HEIGHT = 1.5, -- Humanoid hip height when crouching
	NORMAL_HIP_HEIGHT = 2, -- Humanoid hip height when standing

	-- Combat / Gun
	GUN_FIRE_COOLDOWN = 0.4, -- Minimum seconds between shots
	GUN_RELOAD_TIME = 4.9, -- Seconds to complete a full reload
	GUN_RANGE = 350, -- Maximum raycast distance for bullets (studs)
	GUN_DAMAGE_HEAD = 150, -- Damage dealt on headshot
	GUN_DAMAGE_CHEST = 75, -- Damage dealt on torso hit
	GUN_DAMAGE_LIMB = 35, -- Damage dealt on arm or leg hit
	GUN_MAX_AMMO = 6, -- Rounds in a fully loaded cylinder
	GUN_SPREAD_PER_SHOT = 0.5, -- Degrees of spread added per consecutive shot
	GUN_MAX_SPREAD = 5, -- Maximum spread cap in degrees
	GUN_SPREAD_RESET_TIME = 1.0, -- Seconds of not firing before spread resets to zero

	-- Progression / Economy
	XP_PER_KILL = 100, -- XP awarded for eliminating another player
	CASH_PER_KILL = 10, -- Cash awarded for eliminating another player
	ROUND_BONUS_XP = 50, -- XP bonus for surviving to the end of a round
	ROUND_BONUS_CASH = 5, -- Cash bonus for surviving to the end of a round
	TIME_REWARD_XP = 25, -- XP awarded periodically for staying alive
	TIME_REWARD_CASH = 3, -- Cash awarded periodically for staying alive
	TIME_REWARD_INTERVAL = 120, -- Seconds between time-based reward payouts
	XP_PER_LEVEL = 1000, -- XP required to advance one level (linear progression)

	-- Data persistence
	AUTO_SAVE_INTERVAL = 300, -- Seconds between automatic DataStore saves

	-- Footsteps
	FOOTSTEP_INTERVAL = 0.22, -- Seconds between footstep decal spawns while moving
	FOOTSTEP_VISIBLE_TIME = 3.2, -- Seconds a footprint stays fully visible on sand
	FOOTSTEP_FADE_OUT_TIME = 0.8, -- Seconds for a footprint to fade away
	FOOTSTEP_FADE_IN_TIME = 0.08, -- Seconds for a footprint to appear
	FOOTSTEP_MIN_PITCH = 0.5, -- Lowest random pitch for footstep sounds
	FOOTSTEP_MAX_PITCH = 0.65, -- Highest random pitch for footstep sounds
	FOOTSTEP_MIN_VOLUME = 0.35, -- Lowest random volume for footstep sounds
	FOOTSTEP_MAX_VOLUME = 0.45, -- Highest random volume for footstep sounds
}

return Config
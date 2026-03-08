-- npc_witness config
-- Edit only this file to configure the resource. Safe defaults provided.
-- 
-- NPC WITNESS BEHAVIOR DETAILS:
-- ==============================
-- Phone Call (45% chance):
--   Witness stands still using phone animation, simulating calling police.
--
-- Follow/Curious (35% chance):
--   Witness watches the suspect, turns to face them, and occasionally moves 
--   closer for better observation.
--
-- Panic/Flee (20% chance):
--   Witness panics and runs away from the suspect or a random direction.
--
-- Dynamic Updates:
--   If witness remains in sight, they periodically update suspect position 
--   (every 8 seconds by default).
--
-- Loss of Suspect:
--   If suspect goes out of view, witness briefly plays phone animation 
--   then despawns.
--
-- Lifetime:
--   Witnesses remain active for 60 seconds (default) or until cleaned up.
--
Config = {}

-- Enable or disable dispatch integration entirely
Config.EnableDispatch = true

-- If you know the exact dispatch resource name set it here (optional).
-- Leave empty to auto-detect common dispatch resources.
Config.DispatchResource = ''

-- Police job names to fallback to when no dispatcher is available
Config.PoliceJobs = { 'police', 'lspd' }

-- What the witness system should detect
Config.DetectWeapons = true
Config.DetectMelee = true

-- Behavior / spawning
Config.CrimeRadius = 50 -- meters to search for witnesses
Config.MaxWitnesses = 3
Config.SpawnDistanceMin = 5
Config.SpawnDistanceMax = 20
Config.WitnessFollowDistance = 3.0
Config.ReportInterval = 8000 -- ms between witness updates
Config.WitnessLifetime = 60000 -- ms a witness remains after report

-- Witness behavior distribution (percentages, must total 100)
Config.Behaviors = {
    PhoneCall = 45,  -- Calls police via phone animation
    Follow = 35,     -- Follows and observes suspect
    Panic = 20       -- Panics and flees
}

-- Server-side protections
Config.ReportCooldown = 5000 -- ms between reports per player
Config.MaxReportsPerMinute = 6 -- anti spam

-- Dispatch adapter options (toggle support for adapters)
Config.DispatchAdapters = {
    ps_dispatch = true,
    qb_dispatch = true,
    ox_dispatch = true,
}

-- Debug
Config.Debug = false

return Config

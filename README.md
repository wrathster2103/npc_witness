## v1.0.0 - Initial Release

**Features**
- NPC witness detection for weapon fire and melee combat
- Dynamic witness behavior with 3 behavioral patterns:
  - 45% call police (phone animation)
  - 35% follow and identify suspects
  - 20% panic and flee
- Realistic animations and directional facing toward suspects
- Automatic dispatch integration (auto-detects ps-dispatch, qb-dispatch, ox_dispatch)
- Fallback notifications for police jobs
- Auto-cleanup of witnesses after timeout or when suspect leaves
- Fully configurable via `config.lua`

**Requirements**
- QBCore framework
- A dispatch resource (ps-dispatch, qb-dispatch, or ox_dispatch recommended)

**Installation**
1. Download and extract to `resources/`
2. Rename folder to `npc_witness`
3. Add to server.cfg: `ensure npc_witness`
4. Configure behavior in `config.lua` (optional—works out of the box)
5. Start/restart server

**Config Options**
- `spawnRadius` — Distance to spawn witnesses (default: 50m)
- `maxWitnesses` — Max witnesses per crime scene (default: 5)
- `reportInterval` — How often witnesses call dispatch (default: 10s)
- `despawnTimeout` — Cleanup timer (default: 120s)
- `policeJobName` — Police job identifier (default: "police")

See README.md for full documentation.

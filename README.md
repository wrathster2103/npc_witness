# npc_witness

Author: wrathster2103

A small QBCore-compatible FiveM resource that spawns NPC witnesses when crimes occur, has them follow/track suspects, and dispatches reports to police or a dispatch resource.

Features
- **Crime Detection**: Detects weapon fire and melee combat
- **Dynamic NPC Behavior**: Witnesses spawn with varied reactions—some call police (phone animation), others follow suspects, some panic and flee
- **Realistic Animations**: Phone calls, fleeing, suspect tracking with directional facing
- **Dispatch Integration**: Auto-detects `ps-dispatch`, `qb-dispatch`, `ox_dispatch`; falls back to police job notifications
- **Auto-Cleanup**: Witnesses despawn after timeout or when suspects are out of sight
- **Configurable**: Full tuning via `config.lua` (spawn radius, max witnesses, behavior timings)

Dependencies
- **Required:** `qb-core` (must be started before this resource)
- **Optional / Supported dispatch adapters:** `ps-dispatch`, `qb-dispatch`, `ox_dispatch`
  - The resource will attempt to auto-detect registered dispatch exports when possible.
  - If you use a different dispatch system, set `Config.DispatchResource` in `config.lua` or adapt `dispatch_adapter.lua`.

Installation
1. Place this resource in your server's `resources` folder as `npc_witness`.
2. Ensure `qb-core` is installed and started before this resource.
3. Start the resource in `server.cfg`:

```
ensure qb-core
ensure npc_witness
```

Configuration
- Edit `config.lua` to tune detection, spawn distances, dispatch integration, police job names, and toggles.
- `Config.DispatchResource` can be set to the dispatch resource name you want to force (leave empty for auto-detect).

Dispatch Integration Details
- Auto-detect: the adapter checks for common exports for `ps-dispatch`, `qb-dispatch`, and `ox_dispatch` and will call the first available.
- Fallback: if no dispatch resource is available, the script sends in-resource notifications to configured police job names defined in `Config.PoliceJobs`.
- Custom dispatch: to support another dispatch implementation, either set `Config.DispatchResource` or modify `dispatch_adapter.lua` to map payloads to your dispatch API.

Recommended Next Steps After Download
- Open `config.lua` and adjust `Config.PoliceJobs`, tuning values (spawn limits, radii), and `Config.Debug` as needed.
- If you use a dispatch resource not listed above, set `Config.DispatchResource` to its resource name or adapt the adapter.

NPC Witness Behavior Details
- **Phone Call** (45% chance): Witness stands still using phone animation, simulating calling police.
- **Follow/Curious** (35% chance): Witness watches the suspect, turns to face them, and occasionally moves closer for better observation.
- **Panic/Flee** (20% chance): Witness panics and runs away from the suspect or a random direction.
- **Dynamic Updates**: If witness remains in sight, they periodically update suspect position (every 8 seconds by default).
- **Loss of Suspect**: If suspect goes out of view, witness briefly plays phone animation then despawns.
- **Lifetime**: Witnesses remain active for 60 seconds (default) or until cleaned up.

Contributing
- PRs welcome. Please follow existing code style and keep changes focused.

License
- This project is licensed under the MIT License. See `LICENSE` for details.

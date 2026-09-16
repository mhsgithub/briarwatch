# Verification

Run `tools/launch.ps1 -Mode test` for the headless integration suite, and
`tools/launch.ps1 -Mode capture` for five rendered scenes. Tests instantiate the
real main scene and use `--test` to avoid loading or writing the player's save.
Temporary test saves use distinct names under `user://`. PNG captures and logs
are local artifacts, not required project inputs.

## Automated coverage

The suite contains **47 checks**, covering:

- All 24 placements and stable IDs; native navigation mesh; navigable enemy spawn
  positions; connected town-to-tower route; actual movement through physics.
- Keyboard input direction relative to the camera.
- Editor scene packing/reloading of a modified transform, HP and damage override;
  immutable type defaults and duplicate spawn ID rejection.
- Armor and weapon modifiers; equipment replacement; affordable/unaffordable
  purchases; capacity safety; selling; potion use.
- Timed sword hit, facing rejection and attack cooldown; real arrow travel and
  collision; lethal transitions, loot generation/collection and double-pickup guard.
- Clearing the authored objective camp, reward payout and duplicate-reward guard.
- Save replacement, ID round-trip, malformed file backup recovery, invalid item
  IDs and equipment-slot validation.
- Death screen, pause state, recovery position, crown penalty and preserved gear.
- NPC service opening, encounter reset and preservation of quest completion.

The melee and projectile checks use the actual AttackComponent and physics, not
just mocked health changes. Camp completion is tested by applying lethal damage
to each camp member; this verifies orchestration, not difficulty balance.

## Rendered and interactive checks

The game was run on Windows with Godot 4.7.2 Compatibility rendering on Intel
Graphics. Town, inventory, vendor, watchtower combat and recovery screens were
captured from the running renderer and inspected. Live mouse input was used to
walk to Elric, open his dialogue and accept the quest. Godot's visible editor was
opened to the authored region and used to inspect the watchtower spawn's separate
66-HP / 15-damage instance overrides and shared definition field. The HP override
was changed to 67 through the Inspector, applied, and undone to preserve balance.

Problems found and fixed during verification included HUD anchor offsets,
camera-relative W direction, overlapping ground shadows, JSON number comparison
in the test, navigation startup synchronization and active sound cleanup on unload.

## Reproducibility and scope

The engine version and official Windows archive checksum are pinned in
`tools/engine.json`. A fresh source copy must import and pass tests using only that
engine, without the original `.godot` cache or `.tools` directory. Native Godot
UID sidecars are versioned. No project/resource reference embeds a local username,
drive path, API key or dependency from the original PC.

Restricted-shell runs may print Godot's `Failed to read the root certificate
store` diagnostic because that sandbox cannot read the Windows certificate store.
Normal interactive runs do not print it. The game has no network functionality;
this is separate from gameplay script/runtime errors. No gameplay errors or
resource leaks remained in the final integration run.

Remaining validation limits: no test on a second physical PC, no controller or
multiplayer testing, no hundreds-of-enemies load test, and no release-export
packaging test. The current deliverable runs through the Godot editor/runtime.
New content should receive a visual pathing/combat pass in addition to the suite.

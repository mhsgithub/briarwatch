# Verification

Run the pinned Godot 4.7.2 standard engine through the Windows launchers:

```powershell
.\tools\launch.ps1 -Mode test
.\tools\launch.ps1 -Mode capture
.\tools\build.ps1
```

Test and capture modes import source assets first and pass `--test`. They do
not load or write the personal character save. Persistence fixtures use
separate `user://` filenames. Logs and PNGs in `test-results/`, as well as
builds, remain ignored by Git. The build script runs the tests, exports the
embedded Windows executable and performs a startup smoke test.

## Gameplay suites

The standard test launcher runs **12 suites and 896 checks** in order. A
failure stops the sequence.

| Suite | Checks | Main coverage |
|---|---:|---|
| `integration.gd` | 134 | March authoring, navigation, inventory, combat, saves, maps, audio |
| `watchtower.gd` | 58 | Tower travel, Darius, key, loot and persistence |
| `progression_warwick.gd` | 101 | Levels, talents, abilities, Brutus, cell and rescue |
| `ability_combat.gd` | 29 | Live ability damage, control, obstructions and defenses |
| `talent_ui.gd` | 10 | Learning, prerequisites, tooltips and belt bindings |
| `dark_woods.gd` | 79 | Maze traversal, Garrick, Bloodfang, chest, death reset |
| `encounter_feedback.gd` | 36 | Knife collision, burn, repeat rewards and map rules |
| `music.gd` | 18 | Track decoding, area routing, boss music and crossfades |
| `hollowmere.gd` | 212 | Camp, wildlife, loot, Crit Rating, poison, webs and saves |
| `marsh_movement.gd` | 16 | Grounded click movement, both bridges, pursuit and audio |
| `drowned_patrol.gd` | 101 | Escort, crypt, roleplay, Risen Soldier and quest reward |
| `darkmere.gd` | 102 | Three marks, Darkmere, charge, Malrec, ritual, unique loot |

`creature_audio.gd` provides a separate focused check of distinct marsh
recordings, cue imports, live reactions and the Broodqueen voice.

The Darkmere suite tests all six investigation-site orders, ambush persistence,
the dropped note, lower and upper floor navigation, real charge collision,
elemental projectiles, meteors, Malrec's five-second dark patch and minimum
12-second recast gap, channel interruption, the 40% threshold, the 60-second
ritual deadline, retry state, one-time rewards and the Black Reliquary's
equipped-only life steal. The Drowned Patrol suite tests the cinematic control
lock, Corvin's escort and death, persistent corruption, cleave sidestepping,
the archer reinforcement and safe retry.

## Rendered captures

The capture launcher runs six fixture scripts:
`visual_capture.gd`, `update_capture.gd`, `den_capture.gd`,
`hollowmere_capture.gd`, `chapel_capture.gd` and
`darkmere_capture.gd`. Together they produce **82 PNGs**. The numbered
fixtures cover town and character UI, March and Dark Woods encounters,
Hollowmere wildlife and map, Corvin and the crypt, the investigation sites,
Darkmere's two floors, Malrec's ritual, twin bolts and dark boiling patch.
Images 62–63 examine Lanternwatch paving near Elric from two camera positions;
image 90 frames the patch in the lit boss chamber.

Inspect images after changing art or UI. A successful PNG write establishes
rendering, not visual readability. Several fixtures freeze or stage actors for
composition; gameplay suites exercise real input, movement and hit resolution.
`marsh_movement.gd` can also load the exported embedded PCK with Godot's
`--main-pack builds/windows/Briarwatch.exe` option to verify packaged
resources in addition to the executable startup check.

## Manual review boundaries

Automated checks cover the authored routes and core mechanics but do not
replace a full difficulty playthrough on another PC. Keep a personal save
outside the test fixtures. When changing a persistent ID, test migration
against an older save copy before releasing. When changing audio, verify both
the cue registration and that the committed asset plays in the appropriate
region. A new region should have physical navigation and rendered capture
coverage in addition to resource validation.

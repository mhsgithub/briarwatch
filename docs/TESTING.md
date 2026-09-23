# Verification

Run `tools/launch.ps1 -Mode test` for the ten headless suites and
`tools/launch.ps1 -Mode capture` for 62 rendered views. Both commands import
source assets with Godot 4.7.2 stable before running.

Tests instantiate the real main scene and pass `--test`, so they do not load
or write the player's character save. Persistence fixtures use separate filenames
under `user://`. Captures and logs are ignored local files in `test-results/`.

## Automated coverage

The suites contain 689 checks:

| Suite | Checks | Main coverage |
|---|---:|---|
| integration.gd | 134 | Outdoor authoring/navigation, inventory, combat, recovery, save/backup, maps, audio |
| watchtower.gd | 58 | Travel, Darius movement and mechanics, key retrieval, drops and persistence |
| progression_warwick.gd | 101 | Level/talent rules, abilities, Brutus, cell gate, rescue and rewards |
| ability_combat.gd | 29 | Live ability damage, control, obstruction and defensive effects |
| talent_ui.gd | 10 | Prerequisite display, tooltips, learning and action-slot assignment |
| dark_woods.gd | 79 | Third quest, forest approach, maze traversal, both bosses, chest, Strength and save state |
| encounter_feedback.gd | 36 | Knife collisions, burn feedback, death reset, repeat rewards, map rules and testing points |
| music.gd | 17 | Asset decoding, area routing, boss start/end, death fallback and crossfading |
| hollowmere.gd | 209 | Travel, camp services, every spawn route, loot, crits, poison, webs, respec, vendors, ambience and persistence |
| marsh_movement.gd | 16 | Live input, four bank-to-bank crossings, wildlife pursuit/audio and return travel |

For the marsh creature audio, `creature_audio.gd` runs 50 focused checks of
distinct recorded sources, imported cue lengths, live alert/attack/hurt/death
events and the Broodqueen's lower voice. It runs separately from the ten gameplay
suites so an audio-only change can be verified without repeating unrelated tests.

Dark Woods coverage includes:

- Kasparov's availability after rescue, quest acceptance, restore, completion,
  once-only 50-gold reward and absence of a fourth March quest.
- Correct Elite Bandit and boss definitions, shared ordinary loot and unique drops.
- Strength in actual attacks, displayed damage, item properties and equipment restore.
- Every placed enemy and the chest reachable on the native navigation mesh.
- Real player movement through the entire maze, plus body collision against a wall.
- Untargetable/invulnerable caged Bloodfang, Garrick's real sprint to the cage,
  release while Garrick is alive, and continued encounter after Garrick's death.
- Fire radius, forty-second lifetime, twenty damage every half second through
  armor, elemental immunity, caster independence and region snapshot restoration.
- Seeded thirty-percent Garrick bleed probability and five two-damage ticks.
- Both howl thresholds spawning exactly two Greyfangs each.
- Persistent edible corpses, visible feeding, three fifteen-health ticks and consumption.
- Fury windup, a single sixty-damage bleed, and its twenty-second cooldown.
- Locked-direction lunge through real physics, armor-adjusted hit and knockback.
- Once-only 15-gold chest, correct northwest arrival, defeated-boss persistence
  and open-cage restoration.
- Ground chest loot survives snapshots and only enters the inventory on pickup.
- Brutus's full rage creates 160 knives without radial damage. Knife sweeps
  verify a direct hit, no duplicate hit, a narrow graze, a near miss and wall stop.
- Death restores the two den bosses and locked cage, removes fires, preserves
  chest state and prevents repeated boss EXP/loot after retrying.
- Dark Woods suppresses M and its map button while other region maps work.
- U grants fifteen points at level 1; grants and learned ranks survive restore.

## Rendered verification

visual_capture.gd captures the town, world, inventory, vendor, map, quest journal,
item handling and watchtower. update_capture.gd captures talents, Warwick,
Brutus, rescue, Kasparov's return and the family seal. den_capture.gd adds:

- 35-dark-woods-entrance
- 36-lions-den-offer
- 37-dark-woods-maze
- 38-woods-cache
- 39-lions-den-clearing
- 40-garrick-fire
- 41-bloodfang
- 42-bloodfang-feeding
- 43-bloodclaw-equipment
- 44-lions-den-return
- 45-lions-den-complete
- 46-chest-floor-loot
- 47-garrick-dialogue
- 48-thrown-torch
- 49-player-burning

Hollowmere capture adds images 50–61 for travel, camp, bridge, chapel, spider
grove, graves, crocodile, equipment, reset service, map, Rowan stock and Wyrmfang.
Inspect the pictures after changing art or UI; a successful PNG write alone does
not verify readability. Capture fixtures deliberately stage actors and freeze AI
to expose specific poses; the headless encounter suite separately runs movement,
timers, hit resolution and quest lifecycle.

The current verification was run on Windows using the pinned engine and
Compatibility renderer. It establishes automated behavior and inspected layout;
it is not an exhaustive manual difficulty playthrough or a second-PC certification.

## Hollowmere gameplay regression

`hollowmere.gd` covers travel gating, safe recovery, all authored spawn/cache
routes, independent loot probabilities, critical hits, poison, web collision,
talent resets, persistence, vendor stock/prices, purchases and equipment saves.
`marsh_movement.gd` keeps the player's actual physics enabled and feeds mouse
coordinates through the input handler. It checks grounded click movement,
both directions of both bridges starting from the bank, ordinary AI pursuit
and combat sound cues for all three creatures, and movement after return travel.
The movement suite can also load the exported embedded PCK with the pinned
engine's `--main-pack builds/windows/Briarwatch.exe` option. This tests packaged
resources in addition to the Windows executable startup smoke test.

Rendered fixtures intentionally freeze actors to frame art. They do not replace
these movement tests, and a route query alone does not establish traversability.

## Local environment and portable source

Godot is the only runtime dependency. Native scenes/resources, source textures,
SVGs, shaders, audio and script UID sidecars are committed. A fresh source copy
must import successfully before tests; no local .godot cache is required.

The shell sandbox can deny writes to Godot's user-data test files or renderer
cache. Run the isolated launcher with the needed local filesystem access when
testing persistence and rendered captures. Restricted runs can also emit
`Failed to read the root certificate store`; Briarwatch has no networking and
this engine/environment diagnostic is separate from gameplay script failures.

No API credentials, environment variables, package manager or external art
download is required. Engine version/checksum live in tools/engine.json.

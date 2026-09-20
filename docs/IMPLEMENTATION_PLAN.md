# Project scope and implementation overview

Briarwatch is an original single-player frontier action RPG built with Godot
4.7.2 stable, typed GDScript, native scenes and Inspector-editable Resources.
It uses Compatibility rendering and has no external packages, online services,
credentials or environment variables.

## Current playable scope

The game contains the Briar March, a 256 × 224 metre authored region with a
town, roads, meadows, woodland, raider camps, Warwick ruins and the Old
Watchtower. The watchtower, Warwick cellars and Dark Woods are separate instances.
The three linked quests retrieve Darius Crowbane's cellar key, free Lord Kasparov
from Jailor Brutus, and stop Garrick Vane and Bloodfang in the Dark Woods.
Into the Lion's Den concludes the first map's story.

The Centurion is the only playable class. The slice includes basic melee combat,
enemy AI, ranged arrows, damage and status effects, equipment, loot, vendors,
healing, death and recovery, persistent exploration, save/load, levels 1–20,
and fourteen talents across Battle Mastery and Pathfinder. The character screen
has eleven equipment slots and a twenty-cell pack. Six action slots accept
consumables and learned active talents.

## Architecture

`scenes/main.tscn` composes the session, player, current region, camera and HUD.
`src/session.gd` coordinates lifecycle, services and persistence; it does not
calculate damage, make AI decisions or define content. Gameplay is divided into
focused components for health, attacks, movement, enemy behavior, abilities,
inventory, quests, audio, presentation and UI.

Content is data-driven. Enemy, attack, item, NPC, quest, loot and talent
definitions live under `content/` as Resources or JSON data. Authored scenes
contain regions, encounters, spawn markers, NPCs, portals and scenery. Shared
definitions are immutable; placed enemies can use instance-specific overrides.
Stable region, spawn, item and quest IDs support persistence and future content.

## Extension points

- Add enemy variants by creating a definition and placing an `EnemySpawn`.
- Add equipment by creating an item Resource and registering its stable ID.
- Add quests by linking QuestDefinitions and authored NPC/portal interactions.
- Add regions by registering a scene path, arrival markers and persistent state.
- Add talents or abilities through the Centurion progression data and owned
  ability controller.
- Extend presentation through the shared stylized actor, prop, fire, audio and
  bronze/enamel UI components.

The current boundaries are single-player operation, a fixed-cell inventory,
no randomized item affixes, no crafting, no multiplayer, no streamed world and
no account or cloud service. These are deliberate scope boundaries for the
vertical slice rather than hidden dependencies.

## Development workflow

Open `project.godot` in Godot and press F5 to run the complete game. Use the
Godot editor to place encounters and NPCs, configure Resources, bake navigation
and inspect the authored regions. Use `tools/launch.ps1 -Mode test` for the
headless suite and `-Mode capture` for rendered verification. See
`LEVEL_EDITING.md`, `PROGRESSION.md`, `BALANCE.md` and `TESTING.md` for the
corresponding workflows and rules.

# Architecture

## Engine and composition

Godot **4.7.2 stable**, typed GDScript, native `.tscn` scenes and custom `.tres`
Resources. Compatibility rendering supports the tested Windows Intel GPU and
avoids a dependency on .NET or third-party packages. Coordinates are conventional
3D: X/Z ground, Y up, roughly one unit per metre. The camera is orthographic.

`scenes/main.tscn` is the composition root. `session.gd` connects the region,
player, camera, quest log and HUD, applies initial/load state, dispatches service
actions and saves snapshots. It does not calculate damage, execute AI or author
world content. There are no global autoloads or general-purpose GameManager.

## Responsibilities

| Owner | Responsibility |
|---|---|
| `Region` | Native navigation bake; spawn encounters; track defeated IDs; create and reset loot |
| `Encounter` / `EnemySpawn` | Editor-authored placement, stable identity, enemy type and overrides |
| `Player` | Input, locomotion, target orders, interaction requests and living/dead state |
| `Enemy` | Shared behavior modes, perception, repositioning, leash and death presentation |
| `HealthComponent` | HP, flat armor, damage notifications, lethal transition and healing |
| `AttackComponent` | Windup/cooldown, locked direction, arc/visibility checks and projectile creation |
| `Inventory` | Bag capacity, transactions, equipment replacement, modifiers and ID serialization |
| `QuestLog` | Accept, camp-clear state, one-time reward and objective text |
| `Npc` / `LootDrop` | World interaction targets; service definition or collectible reward |
| `GameHUD` | Presentation, paused panels, inventory controls and service-action signals |
| `SaveStore` | Versioned JSON, temporary-file replacement, backup and basic validation |
| `ActorVisual`, props, terrain, audio | Presentation only; original generated art and cues |

The player and enemy are reusable scene compositions of a `CharacterBody3D`,
capsule, health, attack, navigation agent, visual and audio components. Only the
player has an inventory. Physics layers are named: world (1), player (2), enemies
(3). World-only raycasts prevent melee and perception through obstacles. Arrows
raycast every traversed segment to prevent tunnelling and stop on bodies/world.

## Data and flow

Resource classes define attacks, enemy types, items, loot entries, NPCs, the quest
and an explicit item catalog. Shared definitions are treated as immutable at
runtime. Spawn-marker overrides use `-1` for the type default; resolved values
live on the spawned actor and its components. Each spawn and encounter has a
stable ID. Runtime HP, inventory, gold and AI state never live on shared Resources.

Combat: input/AI requests an attack → windup locks direction → shared attack
component resolves arc and line of sight, or creates a projectile → `DamagePacket`
enters target health → damaged/died signals update feedback and lifecycle.
Equipment contributes additive damage and flat armor. Physical is the only
implemented damage type; the packet's type field is an extension seam, not a
resistance system. Damage is at least one after armor.

Reward: enemy death → Region records spawn ID, drops randomized crowns/items and
decrements the encounter → clear signal updates QuestLog → Session schedules a
deferred snapshot. Collection changes inventory; claimed drops are excluded from
the snapshot. The one-time quest payout checks bag capacity before awarding.

Interaction: click-to-approach or E finds a nearby target → Player emits a request
→ Session opens the defined service or collects loot → HUD emits a service action
→ Session calls inventory/health/quest/region APIs. UI panels pause the tree and
continue processing through `PROCESS_MODE_ALWAYS`; gameplay does not use UI input.

## World editing and navigation

`briar_march.tscn` contains authored roads, props, NPCs, encounter groups and spawn
markers. `@tool` scripts build editor-visible previews and collision geometry.
Ordinary Inspector properties and transform gizmos are the editing API. The
generated visual children are disposable and intentionally not saved separately.
Tree placement is authored; only grass is deterministically scattered at runtime
using a MultiMesh. No external level editor is required.

The native NavigationRegion bakes static world collision geometry at region
initialization, with synchronous map iterations to ensure the map is ready before
actor path queries. This avoids asynchronous first-query races at startup. Godot
NavigationAgent3D handles paths around buildings, tents, fences and trees. The
bake is synchronous and small enough for this slice; larger regions should use
prebaked/chunked navigation and async loading. Rest currently rebuilds the bake.
Map roads and encounter landmarks are read from the region, not a separate layout.

See [LEVEL_EDITING.md](LEVEL_EDITING.md) for the exact workflow and validator.

## Persistence and lifecycle

One local version-1 JSON character at `user://briarwatch_v1.json`. It records item
IDs, gear IDs, crowns, objective flags, defeated spawn IDs and loose loot. The
explicit catalog resolves IDs, rejects missing entries and enforces slot types.
Unsupported/corrupt data falls back to `.bak`, then a new character. This is local
save validation, not a security boundary or an anti-cheat mechanism.

Autosaves are deferred/coalesced after rewards, inventory/quest changes and service
actions. A temporary file is written before replacing the primary; the previous
primary becomes the backup. Manual save, window close and quit also save. Loading
always starts safely in town at full HP; position, wounded enemy HP and transient
attacks are not persisted. Death applies its crown penalty immediately, so closing
the recovery screen by quitting does not avoid it. Respawn restores health and
grants three seconds of damage immunity. Rest clears enemies and loose loot but
retains character and quest progress. Saves stay outside the Git repository.

## Deliberate boundaries and extension points

- New enemy variants: create a resource referencing a shared attack/behavior;
  add new behavior strategy code only when a new mechanic actually requires it.
- New items: create resources and register in the catalog; UI lists are generated.
- Classes/abilities: use the existing attack/health/inventory seams; introduce an
  ability controller when more than one action exists.
- Status effects/resistances: extend damage evaluation and add owned components;
  do not mutate resource defaults.
- More quests: replace the one-definition QuestLog with per-ID entries once needed.
- More regions: scene-based region loading and explicit save namespaces per region;
  stable IDs must remain stable after content is shipped.
- Better art: replace ActorVisual and prop geometry with meshes/AnimationTrees;
  keep damage and AI in their existing owners.

Current limits: single player, one region, one quest, list-based 20-slot inventory,
three gear slots, no animation skeleton, no avoidance solver, no streamed world,
no random item affixes and no account/cloud service. Navigation/AI have been tested
at this slice's population, not at hundreds of simultaneous combatants.

# Architecture

## Engine and composition

Godot **4.7.2 stable**, typed GDScript, native `.tscn` scenes and custom `.tres`
Resources. Compatibility rendering supports the tested Windows Intel GPU and
avoids a dependency on .NET or third-party packages. Coordinates are conventional
3D: X/Z ground, Y up, roughly one unit per metre. The camera is orthographic, with fixed pitch/yaw; following only changes position.

`scenes/main.tscn` is the composition root. `session.gd` connects the region,
player, camera, quest log and HUD, applies initial/load state, dispatches service
actions and saves snapshots. It does not calculate damage, execute AI or author
world content. There are no global autoloads or general-purpose GameManager.

## Responsibilities

| Owner | Responsibility |
|---|---|
| `Region` | Native navigation bake; spawn encounters; track defeated IDs; create and reset loot |
| `RegionTravel` / `RegionPortal` | Doorway transitions, region snapshots and unloading inactive AI |
| `CommanderCombat` / `CommanderDefinition` | Optional enemy ability kit, special timing and telegraphs |
| `PlayerCombatState` | Resting regeneration, armor-ignoring bleed and brief knockdown |
| `Encounter` / `EnemySpawn` | Editor-authored placement, stable identity, enemy type and overrides |
| `Player` | Input, locomotion, target orders, interaction requests and living/dead state |
| `Enemy` | Shared behavior modes, perception, repositioning, leash and death presentation |
| `HealthComponent` | HP, flat armor, damage notifications, lethal transition and healing |
| `AttackComponent` | Windup/cooldown, locked direction, arc/visibility checks and projectile creation |
| `RecoveryComponent` | Non-stacking, pausable timed healing; cancellation on death/recovery |
| `ActionLoadout` / `ActionTile` | Six persistent kind/ID bindings, consumable dispatch and GUI drag/drop |
| `LootTable` | Weighted integer gold rolls and independent item chances; opt-in per enemy definition |
| `FireVisual` / `ProximityFade` | Reusable animated flames/embers/light and close-range scenery transparency |
| `Inventory` | Bag capacity, transactions, equipment replacement, modifiers and ID serialization |
| `EquipmentSlots` | Stable gear-slot IDs, accepted item categories, labels and fallback icons |
| `Exploration` | Persistent 2-metre survey cells, movement reveal and fog texture |
| `AudioLibrary` / `GameAudio` | Cached recorded cues, event routing, spatial range, variants and voice limits |
| `QuestLog` | Accept, key-possession state, one-time hand-in reward and objective text |
| `Npc` / `LootDrop` | World interaction targets; service definition or collectible reward |
| `GameHUD` | Presentation, paused panels, inventory controls and service-action signals |
| `EquipmentPanel` / `ItemTile` | Character layout, item inspection and compatible drag/drop requests |
| `ArtTheme` / `OrnatePanel` | Shared palette, fonts, cached icon atlas regions and scalable frame |
| `CharacterPreview` / `VitalityOrb` | Isolated animated equipped-character preview and health visualization |
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
The unequipped Centurion has 0 melee damage, 0 armor and 100 vitality. Gear supplies
additive damage/armor/max vitality and the weapon's seconds-per-swing cooldown
override. Shared attack definitions stay immutable. One damage adds one to a hit;
one armor subtracts one from physical/melee/ranged hits. Ordinary packets clamp
at zero; all Enemy attack packets explicitly carry a one-damage minimum. Other
damage types bypass armor; there is no implemented resistance system. Changing
maximum vitality clamps current health but does not heal for free.

RecoveryComponent applies Tonic healing over five seconds (10 or 20 HP/second),
pauses with gameplay and rejects overlapping recovery without consuming another
item. Death/recovery cancels the effect. Player.use_item is the shared rule entry
point for the pack and assigned consumable actions. Q opens the quest journal.

Targeted melee pursuit stays active during cooldown. Player computes contact
distance using the target's outward velocity and the attack windup, then advances
along the locked swing direction using the attack resource's `advance_speed`.
Movement still uses CharacterBody collision; AttackComponent retains reach, arc
and line-of-sight authority. Shift-click takes precedence over target picking and
does not advance. No hit is awarded merely because a target was in range at click
time. Enemy floating numbers are instantiated as `FloatingText` before entering
the tree, so their process callback runs, rises/fades and frees them after 1.3 s.

Reward: enemy death → Region records spawn ID, rolls the enemy's optional LootTable and drops gold/items and
decrements the encounter → Session schedules a deferred snapshot. For the current
quest, actual key collection (not camp clearance or boss death) updates QuestLog.
Collection changes inventory; claimed drops are excluded from
the snapshot. The current quest awards only 50 gold and works with a full bag. Optional item
rewards remain supported by QuestDefinition/QuestLog for later quests.

Interaction: click-to-approach or E finds a nearby target → Player emits a request
→ Session opens the defined service or collects loot → HUD emits a service action
→ Session calls inventory/health/quest/region APIs. UI panels pause the tree and
continue processing through `PROCESS_MODE_ALWAYS`; gameplay does not use UI input.

Equipment: `ItemDefinition.slot` is an item category, while `EquipmentSlots` owns
eleven stable destination IDs. Both ring IDs accept category `ring`; automatic
equipping chooses a free compatible slot before replacing an occupied one.
Explicit drag/drop validates the destination through the same Inventory API.
Two-handed weapons occupy the main hand and reserve the off hand. A transaction
preflights capacity for every displaced item before changing either slot. The
off-hand ghost resolves to the same stored weapon when unequipping; no duplicate
item is serialized.
Replacement returns old gear to the pack; unequipping into a full pack fails
without losing gear. All gear contributes modifiers through the existing bonus
aggregation. Old three-slot v1 saves restore into the expanded schema with empty
new slots, without changing the save version or existing IDs.

UI: EquipmentPanel presents eleven gear cells and twenty single-item pack cells.
Click inspects, double/right-click activates; drag requests equip/unequip, not bag
reordering. Rules remain in Inventory and Player. Item resources may provide a
custom `icon` texture or an `icon_index` into two shared 4x4 atlases (0–31); fallback icons
come from the slot schema. CharacterPreview uses a separate transparent 3D world
and the same ActorVisual with a copy of the actual equipment appearance state. Portrait rendering is created only for the open panel.
Item names use the shared white/green/blue/orange tier palette. GoldAmount provides
icon-led currency values throughout UI; LootDrop uses the same coin vocabulary.
Six ActionLoadout bindings start empty. Consumables bind by stable ID rather than
bag index; activation looks up current stock. Ability bindings validate learned
active IDs and dispatch to PlayerAbilities. The belt is after the
modal scrim in GUI sibling order, so open-pack dragging can reach it.

## World editing and navigation

`briar_march.tscn` contains authored roads, props, NPCs, encounter groups and spawn
markers. `@tool` scripts build editor-visible previews and collision geometry.
Ordinary Inspector properties and transform gizmos are the editing API. The
generated visual children are disposable and intentionally not saved separately.
Tree placement is authored; only grass is deterministically scattered at runtime
using a MultiMesh. No external level editor is required.

The native NavigationRegion bakes static world collision geometry at region
initialization, with synchronous map iterations to ensure the map is ready before
actor path queries. The active Region applies its mesh's cell dimensions to the
world navigation map on entry; the tower uses 0.1 m vertical cells to keep baked
waypoints within the actors' 0.45 m path tolerance above the floor. Actual player,
guard and boss movement is tested, not merely polygon counts/spawn projection.
This avoids asynchronous first-query races at startup. Godot
NavigationAgent3D handles paths around buildings, tents, fences and trees. The
bake is synchronous and small enough for this slice; larger regions should use
prebaked/chunked navigation and async loading. The internal reset API remains for
test fixtures; Iona no longer exposes an encounter reset service.
The expanded region is 256 × 224 m with 19 encounters and 76 enemies. Map roads
and encounter landmarks are read from the region, not a separate layout. Only
the M map remains; it deliberately has no player-position marker. All geographic
features are masked by Exploration's survey texture. Only the active objective
pin appears above fog: exterior entrance, interior commander, then the exit and
Elric once the key is held. The journal lists only the accepted, uncompleted quest.

Presentation remains replaceable: WorldProp builds reusable timber/masonry/foliage
geometry without owning gameplay; Geometry caches shared immutable materials.
Terrain uses deterministic grass MultiMesh instances excluding road corridors,
with a wind shader. Ground/road shaders supply mottled earth, softened road edges
and wide-road paving. Props retain their native collision/editor workflow. UI
textures are committed source assets, not runtime downloads; see ASSETS.md.
FireVisual owns phased flame meshes, warm light variation and CPU ember particles.
ProximityFade checks local horizontal mesh bounds, fading within 0.65 m; it clones
materials only while faded and restores original shared material references.
Collision never changes. Per-instance alpha materials support Compatibility
rendering without relying on a Forward+-only transparency feature.

See [LEVEL_EDITING.md](LEVEL_EDITING.md) for the exact workflow and validator.

## Persistence and lifecycle

One local version-1 JSON character at `user://briarwatch_v1.json`. It records item
IDs, gear IDs, gold, optional action bindings, objective flags, defeated spawn IDs
and loose loot, plus optional explored cells, namespaced under `regions[region_id]`.
RegionTravel migrates legacy outdoor state into `briar_march`. Quest items are
deduplicated stable IDs in Inventory's separate `quest_items` pouch; they are not
sellable and never compete for bag capacity. Quest snapshots include the definition
ID. Old camp-clear flags migrate to the new retrieval objective, preserving
acceptance but not treating an old reward as completion of the new quest.
Older saves default to empty actions
and a fresh survey around town. Exploration changes coalesce into a save every
four seconds; explicit save/quit includes the latest cells immediately. The retired `forged_sword`
ID migrates to Watch sword; it is not present in current catalog/vendor/loot. The
explicit catalog resolves IDs, rejects missing entries and enforces slot types.
Unsupported/corrupt data falls back to `.bak`, then a new character. This is local
save validation, not a security boundary or an anti-cheat mechanism.

Autosaves are deferred/coalesced after rewards, inventory/quest changes and service
actions. A temporary file is written before replacing the primary; the previous
primary becomes the backup. Manual save, window close and quit also save. Loading
always starts safely in town at full HP; position, wounded enemy HP and transient
attacks are not persisted. Death applies its gold penalty immediately, so closing
the recovery screen by quitting does not avoid it. Respawn restores health and
grants three seconds of damage immunity. Iona heals without resetting the world. Saves stay outside the Git repository.

## Deliberate boundaries and extension points

- New enemy variants: create a resource referencing a shared attack/behavior;
  add new behavior strategy code only when a new mechanic actually requires it.
- New items: create resources and register in the catalog; UI lists are generated.
- Classes/abilities: extend the class catalog and owned PlayerAbilities controller.
- Status effects/resistances: extend StatusEffects and DamagePacket, not shared defaults.
- More quests: link QuestDefinitions; QuestLog stores active state and completed IDs.
- More regions: register scene paths on main.tscn's `region_scenes`, author portals
  and arrival markers, and preserve stable region/spawn IDs used by snapshots.
- Better art: replace ActorVisual and prop geometry with meshes/AnimationTrees;
  keep damage and AI in their existing owners.

Current limits: single player, three regions, two linked quests, fixed-cell 20-slot inventory,
eleven gear slots, no animation skeleton, no avoidance solver, no streamed world,
no random item affixes and no account/cloud service. Navigation/AI have been tested
at this slice's population, not at hundreds of simultaneous combatants.

## Playtest combat and audio refinement

EnemyDefinition owns melee hit chance and voice profile. AttackComponent checks
reach, facing and obstructions before rolling its own RNG; a failed roll emits
`missed`. Projectiles skip accuracy rolls and resolve through existing raycast
collision. Enemy attaches the minimum-one damage rule to its attack packets;
HealthComponent applies it after armor, including for arrows and future enemies.

AudioLibrary reads `content/audio/cues.json`, caches PCM assets and chooses variants
using independent randomness. Actor signals trigger GameAudio layers; inventory,
services and HUD trigger their own successful-action sounds. World one-shots are
capped at 24 voices, menu one-shots at six, with range culling and retrigger limits.
FireVisual owns a quiet looping spatial source. See AUDIO.md for provenance.

## Watchtower combat and travel

An optional CommanderDefinition composes CommanderCombat onto the shared Enemy.
The kit references immutable cleave/kick AttackDefinitions. A second AttackComponent
on the actor resolves special attacks using the same locked-direction arc, reach
and obstruction tests as normal melee. The commander waits for a basic windup to
finish, commits to a special, then recovers before attacking again. Death/leashing
cancels pending specials. Heavy Cleave's warning sector is built from its actual
reach/arc, independent of the commander's visual scale. Kick explicitly uses zero
minimum damage; damaging enemy attacks retain their one-damage floor.

DamagePacket carries the small implemented status payload: bleed amount/tick count
and knockdown seconds. PlayerCombatState owns transient timers; repeated bleeds
refresh rather than stack, ticks bypass armor, and death clears statuses. Menus
pause them. It also heals one point every two seconds only after four seconds
without an attack/damage event and while no living, non-returning enemy is chasing
the player. Bowmen own short retreat/stand timers using EnemyDefinition defaults.

RegionTravel snapshots defeated IDs, loose drops and survey cells before removing
the active region. It instantiates the destination from main.tscn's path registry,
positions the player at an authored arrival marker, restores its state and bakes
navigation. Inactive regions are data only: no collisions, projectiles, voices or
AI survive unloading. Session reconnects lifecycle signals and updates the map,
lighting and fixed-angle camera. Surviving enemies recover on re-entry, as on load.
Death inside returns to the outdoor town; loading always resumes safely in town.
The current small regions load synchronously, without background streaming.

## Progression and Warwick implementation

CharacterProgression owns level/EXP/ranks and derives unspent points. The
CenturionTalents catalog reads class content from centurion.json. Dependencies
are data, not UI wiring. Restore validates ranks, prerequisites and point budget
in topological order. Session awards definition-owned EXP on recorded defeats;
pre-progression saves get one-time authored-kill credit using SceneState, not AI.

PlayerAbilities owns cooldowns, buffs, basic-swing empowerment, leech and swept-body
Leap. AttackComponent retains basic swing geometry/timing. Enemy reports actual
HP removed for leech, never nominal/overkill damage. Player resolves accuracy
minus avoidance once, then melee Block, before damage/status application. Enemy's
is_boss property prevents Impale stun. StatusEffects is the shared actor-owned
store for elemental wards, DOT, stun/root/slow; legacy Darius bleed, knockdown and
rest recovery remain in PlayerCombatState, which respects control immunity.

BruteCombat is an optional enemy kit alongside CommanderCombat. BruteDefinition
owns threshold, duration, interval, radius, damage and knockback. Rage cancels
normal windup, plants movement, applies sixteen obstruction-checked pulses and
recovers. Presentation owns fists, silhouette and rage lighting.

QuestDefinition links the next quest and declares destination/hand-in NPC/region.
QuestLog stores active state, completed IDs and persistent story flags. Session
checks the accepted quest at the cellar portal, boss completion at PrisonGate,
and the open cell before rescue dialogue. It derives the town NPC from completion.
Inventory.pending_rewards reserves item rewards when the ordinary pack is full.
All new save fields extend v1; existing region defeat/drop/fog namespaces remain.

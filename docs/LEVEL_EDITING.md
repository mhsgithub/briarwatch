# Edit the March in Godot

Open `scenes/world/briar_march.tscn`. Switch to the **3D** workspace. The scene tree
and standard Inspector are the source of truth; edits do not require a code
generator. Press F5 to play the full game after editing.

## Enemy placement and variants

1. Expand `Encounters`, then e.g. `watchtower`.
2. Select `raider_1`. Its cloth/leather bandit preview and label appear in the viewport;
   press **F** to frame it. Use the move/rotate tools as usual. Keep spawn Y near 0.
3. In the Inspector, expand **Definition**. HP, movement speed, aggression/leash,
   behavior, hit chance, audio profile, attack resource and optional Loot Table are type-level settings.
   Changing the shared `.tres` changes every spawn using that enemy type.
4. **Instance overrides** on the marker are different: `Health Override` and
   `Damage Override` affect only this placed enemy. `-1` inherits the type's value.
   Current bandits inherit 45 HP / 8 damage. The integration test creates a
   temporary override to verify that this editing workflow survives saving/reloading.
5. Duplicate a marker with Ctrl+D, move it, and give it a **new unique Spawn Id**.
   Do not change an existing shipped spawn ID casually; saves use it to remember
   which enemies are dead. Renaming the editor node alone does not change the ID.
6. For a new type, duplicate a resource in `content/enemies`, edit its ID/name/stats,
   and assign it to a marker's Definition field. Existing melee/archer/wolf modes
   can be reused with new attack resources, ranges, speeds, loot and colors.

Overrides never change the shared resource. Runtime enemies are spawned under
`Actors`; edit the authored `EnemySpawn` markers, not remote runtime copies.
Changing type resource details may require reopening the scene to refresh preview
labels; gameplay always reads the current values when spawned.

## Encounters, services and scenery

Duplicate an encounter node to create a group, update its **Encounter Id** and all
child spawn IDs, and move the parent to relocate the group. Spawns must be direct
children of an Encounter. The quest's `Target Region` and `Target Encounter` drive
its map objective; `Required Item` drives actual completion. The current quest
requires collecting the cellar key, not clearing the exterior encounter.

NPCs under `NPCs` use definitions from `content/npcs`. Move them or assign a
definition. Vendor stock is an array of item resources. New items must also be
added to `content/catalog.tres` so saves can resolve their IDs.

Items expose a `Slot` category and optional `Icon` texture / `Icon Index` atlas
cell. The eleven supported equipment destinations are listed in
`src/data/equipment_slots.gd`; both ring destinations accept `ring`. A new helmet,
ring, etc. only needs an item resource, catalog entry and a source such as vendor
stock or loot. No UI rewrite is needed for those categories. Additional slot
types require extending the shared schema and the character-panel placement.
The current catalog contains twenty-one items. Item definitions expose explicit
buy/sell prices, rarity tier, damage/armor/vitality bonuses, weapon swing seconds,
two-handed occupancy, recovery duration and appearance. See BALANCE.md for the
exact content. The original three enemy types explicitly reference
`content/loot/march_enemies.tres`; new enemy definitions default to no loot table.
Gold weights correspond to integer outcomes starting at zero. Each item chance
is rolled independently, so one enemy can drop multiple different items.
Atlas rows and provenance are documented in `VISUAL_DIRECTION.md`.

Sword attack resources also expose `Advance Speed`, the movement speed during a
targeted committed windup. This is not extra hit range. Test retreating enemies,
walls and attack-in-place input after changing reach, windup or advance speed.

Props live under `NavigationRegion/Scenery`. Duplicate a tree, house, tent, rock,
fence, ruin, well, crate or banner; use its **Kind**, color, scale, rotation and
position in the Inspector. Generated meshes/colliders follow the parent. Keep
walkways wide enough for a 0.6 m navigation radius. Move `PlayerSpawn` to change
arrival and recovery. Roads expose editable point arrays and width.

The expanded 256 × 224 m region has nineteen authored encounters and 76 spawns.
The tower and outer camps are farther out, with five connecting road resources
and more trees; existing persistent IDs are preserved. The same prop kinds remain: houses generate
timber/slate details, towers generate masonry courses, and trees generate jagged
bough meshes. Wide roads (width > 10) render paving; narrower roads render dirt.
Road tint affects the shader color. Terrain grass is deterministic and excludes
authored road corridors. Editing these visual details does not change spawn IDs. Fire props compose
FireVisual (height, light energy and range) for animated flames, embers and light.
Large scenery automatically receives proximity fading at runtime; physics and
editor geometry remain opaque and unchanged. Camera follow changes only position.

Navigation automatically rebuilds from static colliders when the region starts.
For editor inspection, select `NavigationRegion` and use Godot's **Bake NavMesh**
toolbar action. Keep the configured cell and agent dimensions consistent. Preview
geometry is generated by @tool scripts and must finish building before baking.

## Validate changes

The watchtower interior is `scenes/world/watchtower.tscn`. Its three ordinary spawn
markers define Darius and two existing bowmen. Darius's resource references the
optional CommanderDefinition kit; edit cleave/kick resources and cooldown ranges
there without changing the ordinary enemy behaviors. Visual Scale is presentation
only: attack reach/arc remain authoritative. The native masonry generator is
editor-visible and bakes collision like outdoor scenery.

Doors are RegionPortal nodes under `Portals`. Configure destination region ID and
optional arrival-marker name; put Marker3D arrivals under `Arrivals`. Region scene
paths are registered on the main scene's `region_scenes` property, avoiding cyclic
PackedScene references. Preserve region IDs once shipped. Each region's defeated
IDs, loot and fog have a separate save namespace. Only one region is loaded at a time.

Use item slot `quest` for a non-tradeable quest-pouch item. It must be in the
catalog and a loot source; it is not ordinary equipment and does not use bag space.

With the region open, open `tools/validate_region.gd` in the Script workspace and
choose **File → Run** (Ctrl+Shift+X). Read the Output panel. It checks configured
enemy/attack resources, IDs, parent structure, health overrides and spawn marker.
Then run `tools/launch.ps1 -Mode test`. The integration suite checks every enemy's
proximity to navigable ground, the town-to-tower route, and scene save/reload of
Inspector overrides. It also intentionally creates a duplicate ID to verify the
validator catches it. Path checks do not replace a visual playthrough of new art.

Tests do not load your personal save. Normal play does. Iona is a healing-only
NPC; use isolated test mode while editing placements, or back up and move the
normal save if you intentionally want a fresh character.

## Editing constraints

The current region runtime expects `NavigationRegion`, `Actors`, `PlayerSpawn`,
`NPCs` and `Encounters` child roots. Preserve those names or update the Region
scene contract. Region dimensions live on terrain and map bounds; update both if
expanding it. Keep global spawn/encounter IDs unique across this region.

## Warwick and progression authoring

Warwick's ruin/road/portal and four guards are authored in briar_march.tscn near
(74,88). Six nearby trees were relocated around the ruin, not regenerated globally.
warwick_cellars.tscn defines the third region, Brutus marker, prisoner, gate and
exit. CellarInterior/WarwickRuins provide original @tool-visible geometry. The gate
collider is outside NavigationRegion: the baked floor supports an open gate,
while actual body collision blocks a closed one, including Leap.

Enemy definitions expose Experience (default zero), Is Boss and optional Brute
kit. Normal AttackDefinition and rage kit are independent Inspector data. Region
exposes interior sun/ambient values. QuestDefinition.next_quest, handin_npc,
handin_region and entrance_label supply chain/UI/map routing. Keep stable IDs.
Talent IDs/ranks/tree/tier/cooldowns/icon cells/parents live in
content/progression/centurion.json. Keep it topologically ordered and run tests.

## Dark Woods authoring

dark_woods.tscn contains the full fixed maze, 18 ordinary patrol markers, two
boss markers, trails, clearing, cage, chest and exit. Thicket length/width and
transforms define impassable tree-wall segments; keep the approximately 6-metre
corridors clear. Tree variants are deterministically seeded per segment and
batched; no runtime maze regeneration changes saved encounters.

The northwest entrance is at (-104,-90) in briar_march.tscn, with the return
arrival at (-104,-84). WestTrail leads directly to it. Quest-gated portals use
required_quest and locked_message; completed quests retain access.

DenEncounter's cage_path points to the authored BeastCage. Keep the cage below
NavigationRegion/Scenery: its sides bake normally, while the gate changes
physical collision after the bake. Boss markers retain woods_garrick and
woods_bloodfang; quest completion targets the bloodfang encounter. Do not put
regular patrols in the clearing. DenBossDefinition exposes both bosses' tuning.

TreasureChest.chest_id is persistent identity; changing it grants a new chest.
The woods_cache chest drops 15 gold as floor loot. TreasureChest.items supports
optional item drops through the same collection/persistence path. Preserve IDs
when moving content. Dark Woods disables Region.map_enabled.

WoodsEntrance builds an irregular forest edge from 155 seeded trees with varied
scale and rotation. Its exported seed, count, width and depth control the grove;
the central approach remains clear. DarkThicket keeps collision separate from
its exposed-root tree mesh and proximity fade.
Run dark_woods.gd tests after path/wall/cage changes; they include actual
player traversal, spawn reachability, release sprint and wall collision.

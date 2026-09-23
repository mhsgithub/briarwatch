# The Hollowmere Marshes

Hollowmere is the second outdoor region: a 288 × 256 metre expanse of dark peat,
flooded fields, cypress groves and abandoned frontier buildings. Kasparov's armies
are gathering against the surviving gangs, but Elric believes that Vane, Crowbane
and Brutus were serving another power. Their supply trails lead into the marsh.
After the third quest is handed in to Kasparov, Elric offers a journey to the
expedition camp. Choosing the travel dialogue confirms departure. He can escort
the player back to Briarwatch at any time. No Hollowmere quests are active yet.

## Lanternwatch Camp

The camp occupies the surviving stones of an old causeway. Canvas quarters,
palisades, supplies, a cooking fire and practice targets surround its square.
Warm lamps and decorative fireflies distinguish safe ground from the cold mire.
Warden Elric directs the expedition. Quartermaster Rowan buys finds and sells
tonics and expedition equipment listed below. Sister Maelin heals freely. Captain Tamsin
resets both talent trees for 100 gold; Master Oswin offers the same service in
Briarwatch beside the campfire. Resets refund every spent point, preserve level/EXP and consumable
bindings, and clear learned ability bindings, cooldowns and active talent effects.
An empty talent tree or insufficient gold makes no transaction.

## The wilderness

The old causeway and five branching trails connect seven landmarks: Siltwater
Landing, the Sunken Chapel, Widows Weald, Pilgrim Graves, the Broken Sluice,
the Drowned Tollhouse and the Old Beacon. Two timber bridges cross flooded ground.
Deep water blocks movement and navigation; bridge openings are carved from the
same authored shore geometry. Small shallow puddles remain walkable. Reeds,
cattails, mushrooms, hanging moss, scattered grass and drifting ground mist
soften the shores and paths. Nearby trees fade to preserve player visibility.

Five weathered strongboxes contain 12, 15, 20, 10 and 18 gold respectively. Their
contents fall onto the ground and can be collected separately. Opened chests,
loose drops, exploration and enemy defeats persist across travel and saves.
Death and subsequent loading recover the player in Lanternwatch while the
saved recovery region is Hollowmere. Returning with Elric changes it to Briarwatch.

Thirty-two authored encounter groups contain 25 crocodiles, 42 Marsh Widows
and 14 Broodqueens. Packs occupy roads, groves and dry shoreline clearings.
Each Broodqueen has three Widows nearby. Animal silhouettes,
readable bite windups, poison motes and tangible web projectiles communicate danger.
The world map reveals shores, roads, groves, buildings and landmarks as explored.

| Creature | Health | Base melee | Hit chance | EXP |
|---|---:|---:|---:|---:|
| Crocodile | 100 | 20 | 70% | 2 |
| Marsh Widow | 80 | 17 | 70% | 2 |
| Marsh Broodqueen | 150 | 25 | 90% | 3 |

A connecting Widow bite refreshes poison for three ticks of one damage per
second, ignoring armor. Broodqueens raise their forelegs for 0.8 seconds before
firing an aimed web at 11 m/s. A collision roots for two seconds. Web casts have
a 9.5–12.5 second cooldown and require sight within ten metres; they can be
dodged or blocked by scenery. Unshackled removes roots, Bladestorm rejects them,
and Elemental Resolve prevents poison. The ordinary minimum-one physical damage
rule and leashing apply to all three species.

## Equipment and critical strikes

Rowan's complete stock is listed below. The five expedition items are green
quality and sold by Rowan; they are separate from the wildlife loot table.

| Item | Properties | Price |
|---|---|---:|
| Tonic | Standard tonic | 5 |
| Greater Tonic | Greater tonic | 40 |
| Guardian's Amulet | +2 armor; +10 vitality | 100 |
| Wyrmhide Grips | Gloves; +3 armor; +1 Strength; +1 Crit Rating | 125 |
| Emerald Band | Ring; +1 Crit Rating; +1 Strength | 125 |
| Wyrmsteel Shoulders | Shoulders; +4 armor; +10 vitality | 150 |
| Oakheart Guard | Shield; +5 armor; +10 vitality | 150 |
| Wyrmfang | Two-handed polearm; 23 damage; 2 s/swing; +2 Strength; +10 vitality | 225 |

All three species share an explicit loot table. Each item is rolled independently.
Gold weights are 70% for zero, 12% for three, 10% for four and 8% for five.

| Item | Quality / slot | Properties | Drop chance |
|---|---|---|---:|
| Marshscale Tunic | White armor | +3 armor | 2.5% |
| Bogwalker Boots | White boots | +2 armor | 2.5% |
| Rotcap Cowl | White head | +2 armor | 2.5% |
| Swampgrip Mitts | White gloves | +2 armor | 2.5% |
| Mud-Stained Sash | White belt | +2 armor | 2.5% |
| Bogwood Shield | White shield | +3 armor | 2% |
| Marsh Cleaver | White one-handed weapon | 7 damage; 0.9 s/swing | 2% |
| Gloomhide Vest | Green armor | +5 armor; +5 vitality | 1.5% |
| Marshrunner Boots | Green boots | +2 armor; +5% movement speed | 1.5% |
| Marshguard Crown | Green head | +3 armor; +1 Strength; +5 vitality | 1.5% |
| Marshwarden Sash | Green belt | +2 armor; +1 Strength | 1.5% |
| Fenwarden Charm | Green amulet | +10 vitality | 1.5% |
| Marshwarden Band | Green ring | +1 Strength | 1.5% |
| Bogiron Greatblade | Green two-handed sword | 20 damage; 1.9 s/swing; +2 Crit Rating | 1% |

Base Crit Rating is zero. One point gives one percentage point of critical
chance, capped at 100%. Direct player attacks, including damaging talents, roll
once per target hit. Critical damage doubles the resulting hit after armor and
appears as a larger yellow number. Damage-over-time effects do not critically
strike. Equipment movement bonuses add to the existing movement talent bonuses.

## Authored content and presentation

`scenes/world/hollowmere.tscn` contains native editor-editable shore polygons,
bridge cutouts, roads, prop instances, named landmarks, NPCs, chests, encounters
and stable spawn markers. `tools/author_hollowmere.py` is an offline authoring
source; regeneration replaces that scene and its marsh resources, so deliberate
scene edits should also be reflected there. It is never loaded by the game.
MarshProp owns reusable art; MarshCreature builds articulated animal visuals;
WebAttack and WebProjectile own the optional ranged root mechanic. Shared
AttackDefinition poison fields feed DamagePacket and actor-owned StatusEffects.

The painted gear atlas was generated with the built-in imagegen tool: an original
4 × 4 atlas of marsh leather, scales, bog iron, bronze and jade on dark enamel.
The first fourteen cells follow the item table order; the final two are empty.
The full production prompt is in `assets/ui/marsh_gear_prompt.txt`.

Rowan's five items have a separate 3 × 2 painted atlas. Wyrmfang has a hooked
glaive silhouette on the world character and portrait.

Hollowmere uses HitCtrl's *RPG - The Secret Within the Woods* (CC BY 3.0); Lanternwatch uses
HitCtrl's *RPG Ambient 3* (CC BY 3.0). Existing two-player fades switch smoothly
between them. Full source credits and license links appear in the pause menu
and `assets/music/LICENSES.md`, and accompany packaged Windows builds.
Occasional distant frog calls use EZduzziteh's CC0 recordings, spaced 18–36
seconds apart outside camp. Creature alerts, bites, hurt and death reactions
use distinct reptile and spider cue profiles with recorded foley.

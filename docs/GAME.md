# Briarwatch — game description

## Identity

You are a roadwarden in the Briar March, a rural frontier whose small settlements
survive through trade and mutual obligation. The protection of an old crown has
receded. Roads that once joined the villages now belong to hungry packs and
organized raiders. Briarwatch remains a place of shelter, repair and human company.

This is an original medieval fantasy setting. Its inspiration is the readable
perspective, deliberate combat, dangerous excursions, equipment progression and
town-to-wilderness rhythm of traditional action RPGs. It does not reuse another
game's characters, dialogue, geography, assets, classes or storyline.

## First playable experience

The player begins in a small timber-and-stone village with a sword, shield, padded
coat, one Tonic and zero gold. The class is named Centurion: base stats without
gear are 0 melee damage, 0 armor and 100 vitality. A single connected region surrounds
it: meadow, sparse pinewood, branching paths, a charcoal camp, an eastroad camp,
an old watchtower and scattered ruins. The map reveals roads and scenery as you explore and marks only the active quest
objective. The outdoor region connects through an interactive doorway to a separate
round watchtower interior, with cutaway masonry walls, braziers, a command rug,
campaign table, supplies and crow banners. Only the active area runs enemy AI.

The intended loop is: take Elric's objective, choose a road, learn enemy attack
timings, collect gold and equipment, return for healing or upgrades, and confront
Darius Crowbane inside the tower. Returning his cellar key earns fifty gold,
with no item quest reward; his White shoulder mantle is a separate boss drop.
Optional encounters provide additional combat and loot. Iona offers healing only.

The Centurion starts with basic attacks using the equipped sword or Pitchfork.
Battle Mastery and Pathfinder add spins, empowered swings, mobility, wards and
passives. Shields give armor and double the Block talent's melee block chance. Movement is itself defensive: step out of a committed melee swing or away
from an arrow. Gear changes melee damage, swing period, flat armor and maximum vitality.
Tonic restores 50 HP over five seconds; Greater Tonic restores 100 over five
seconds. The six action slots start empty and accept learned active talents or tonics.

## Opposition

- **Road raiders** advance into close range and commit to slow, readable swings.
- **Briar bowmen** retreat briefly (0.65 s), then stand for 2.4 s to fire visible arrows.
- **Greyfang wolves** close faster, circle and withdraw between short bites.

Seventy-six enemies occupy nineteen encounter groups in a 256 × 224 metre region.
Two additional bowmen guard Darius in the instanced watchtower.
The King's Road provides a long approach to the watchtower. Camps mix melee and ranged
roles. Bandits have 45 HP / 8 damage / 70% hit chance, bowmen 35 HP / 11 damage with
collision-based arrows, and wolves 30 HP / 6 damage / 60% hit chance. Successful
enemy hits always deal at least one damage after armor. All base movement speeds,
including the Centurion's, are deliberately restrained for readable positioning.
Enemies return home and recover when pulled beyond their leash.

## The Crow's Captive

Bandit gangs raid Briarwatch and other towns across the kingdom. The settlements
need Lord Kasparov to muster his armies, but he has been kidnapped. Scouts locate
him in the cellars beneath the ruins of Warwick Castle. Darius Crowbane, the
bandit commander occupying the northeast watchtower, holds the cellar key.
Elric asks the Centurion to retrieve that key and return it before a rescue can
be mounted. The next quest, A Lord Beneath the Stones, is offered after hand-in.

Darius is a larger leather-and-hide outlaw wielding a broad two-handed steel axe.
He has 125 vitality, a slower 2.4 m/s movement speed and 15-damage basic swings. Heavy Cleave announces
itself with a roar, overhead windup and frontal ground sector, without ability-name text; after one second
it deals 20 physical damage and five armor-ignoring bleed ticks of 3 damage.
Its direction is committed, so moving behind or beyond it avoids the entire hit.
It recurs on a 7–10 second cooldown. An occasional kick briefly knocks the
Centurion down without dealing damage. The commander always drops his key and
Outlaw's Mantle. The key cannot be sold or blocked by a full pack.

## Town roles

**Mara**, smith and supplier: buy upgrades and tonics; sell unequipped finds.
**Sister Iona**, healer: restore health freely.
**Warden Elric**, roadkeeper: give the objective and its one-time reward.

## Presentation and future direction

The game uses heavily stylized, faceted geometry: slate-shingled timber houses,
masonry defenses, jagged evergreen canopies and layered steel-and-cloth characters.
Mossy greens and cool iron contrast with amber windows and lanterns. Procedural
ground shading breaks up the meadow and roads; moving grass adds life without
obscuring combat. A fixed-angle orthographic camera preserves the readable ARPG perspective
without rotating during movement. Very close large scenery fades for visibility.
Reusable fire adds moving flame layers, embers and smoothly varying warm light.
Recorded weapon, impact, human and canine sounds, swing arcs, telegraphs and rising damage numbers
provide feedback. This is an extensible art vocabulary, not a finished commercial
asset library or a copy of another game's visual assets.

The interface uses dark enamel, engraved bronze frames, painted item icons,
a vitality orb and a six-slot assignable action belt. The character panel combines an animated
Centurion preview, live stats, eleven equipment slots and a 20-cell pack. Gear slots
are head, shoulders, armor, gloves, belt, boots, amulet, two rings, main hand and
off hand. Each bag item occupies one cell; this is not a variable-size packing
system. The twenty-two-item catalog includes Outlaw's Mantle, the key and the
Green Kasparov Family Seal ring. Equipped gear appears on both the world
character and portrait. Removing all equipment leaves simple clothing. The
Pitchfork reserves both hands. N opens the bronze/enamel talent window at level 2.

Targeted sword attacks close to a windup-adjusted contact distance and advance
during the committed swing. Retreating bowmen can be caught without removing
swing timing, hit range, facing or obstacle checks. Shift-click attacks in place.

Future regions can develop the identity through abandoned fortifications, local
factions, old duties and regional threats. Content is expanded through authored
resources and composed scenes. Additional classes, randomized affixes, crafting
and procedural dungeons are outside the present slice.

## A Lord Beneath the Stones

After the key hand-in, Elric sends the Centurion to Warwick's southeast ruins.
Four bandits defend the cellar entrance. The torchlit prison below contains
barred cells, old skeletons and Lord Kasparov, guarded by Jailor Brutus.
The broad, bearded brawler has 120 health and fast 15-damage punches that knock
back. At half health, his eight-second planted rage inflicts 30 damage every
half second nearby. A roar, rapid fists, red light and a boundary ring warn you.

Defeat him, open the rear cell and speak with Kasparov to return to Briarwatch.
The quest pays 10 gold and a Green +5-vitality family-seal ring. The lord remains
in town. Full bags reserve the ring safely for later collection.

New characters begin level 1; ordinary kills give 1 EXP and bosses give 5.
Level-ups reset EXP to zero and grant one talent point, up to level 20.
Battle Mastery and Pathfinder contain fourteen implemented talents with explicit
AND prerequisites, learned-action belt bindings and persistent cooldowns.
The exact curve makes level 2 the limit of the present finite region's EXP.
See PROGRESSION.md for complete rules and content boundaries.

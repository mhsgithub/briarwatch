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
gear are 0 melee damage, 0 Strength, 0 Crit Rating, 0 armor and 100 vitality. The first connected region surrounds
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
**Master Oswin**, veteran instructor: reset both talent trees for 100 gold.

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
system. The thirty-eight-item catalog includes Outlaw's Mantle, the key, the
Green Kasparov Family Seal ring, Blackroad Belt and Bloodclaw. Equipped gear appears on both the world
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
back. At half health, his eight-second planted rage scatters fast knives in
random directions at 15.5 m/s: five every quarter second, each dealing 20 base physical
damage on contact. A roar, rapid fists, red light and a ring accompany the storm.
Knives stop at walls, and their narrow collision follows the visible blade.

Defeat him, open the rear cell and speak with Kasparov to return to Briarwatch.
The quest pays 10 gold and a Green +5-vitality family-seal ring. The lord remains
in town. Full bags reserve the ring safely for later collection.

New characters begin level 1; ordinary kills give 1 EXP, Elite Bandits give 2,
Darius, Brutus and Garrick give 5 each, and Bloodfang gives 10.
Level-ups reset EXP to zero and grant one talent point, up to level 20.
Battle Mastery and Pathfinder contain fourteen implemented talents with explicit
AND prerequisites, learned-action belt bindings and persistent cooldowns.
The present finite content supports reaching level 3.
See PROGRESSION.md for complete rules and content boundaries.

## Into the Lion's Den

Back in Briarwatch, Kasparov sends the Centurion northwest. Scouts have found the
bandit leaders gathering in the Dark Woods; the lord fears his captivity bought
them time to release an evil upon Briar. The old northwest trail enters a dense,
irregular edge of twisted trees and leads to a separate 112 × 164 metre woodland
instance. The Dark Woods has no map; players navigate its paths by sight.

Twisted, tightly packed trees form solid maze walls around clear paths. Nine
Greyfangs and nine Elite Bandits guard its branches. A chest deep in a side route
drops 15 gold onto the ground when opened, available once. The maze ends in a broad circular clearing.
No ordinary patrols begin inside that arena.

Garrick Vane, an elegant outlaw in dark armor and a wine-colored cloak, carries
a sword and a burning torch. He throws burning brands that ignite lasting ground
fires, and his sword can inflict bleeding. Burning the player produces a brief,
subtle flame effect and a distinct scorching sound. Garrick addresses the player
when battle begins and calls to Bloodfang as he opens the cage.
At a quarter of his health, he sprints to an iron cage and frees Bloodfang, a
towering, clawed werewolf. Garrick continues fighting. Bloodfang howls for wolves
at two health thresholds, pursues in a biting fury, lunges, and feeds on nearby
dead Greyfangs to recover. Animation, lighting, fire, movement and sound communicate
the encounter; there are no mechanic-name text announcements.

Death during the unfinished encounter restores both bosses, extinguishes its
fires and returns Bloodfang to the locked cage. Opened chests, maze kills and
floor loot remain. Each boss and summoned wolf grants its rewards only once.

Garrick drops the Green Blackroad Belt (+2 armor, +10 vitality). Bloodfang drops
the Green one-handed Bloodclaw (10 damage, 0.8-second swing, +1 Strength).
Each point of Strength adds one melee damage, so Bloodclaw contributes 11 damage
in total. Its hooked, blood-streaked blade appears on the character and portrait.

Bloodfang's death sends the Centurion back to Kasparov for 50 gold. The lord
thanks the player for freeing Briarwatch and begins gathering his armies to
drive the remaining bandits from the lands. This concludes the first map's
three-quest story. Elric then follows the bandits' supply trails into the
Hollowmere Marshes, suspecting that another power put Bloodfang in Vane's hands.

## The Hollowmere Marshes

The second outdoor map is a 288 × 256 metre dark, misty marsh. Elric escorts the
player to Lanternwatch Camp after Kasparov receives the third quest hand-in.
Rowan supplies gear and tonics, Maelin heals, and Tamsin resets talents for 100
gold. The same reset service is available from Oswin in Briarwatch. Elric offers
return travel, and marsh deaths recover at camp.

Raised trails and two timber bridges connect drowned ruins, a ferry landing,
pilgrim graves, a ruined chapel and an old beacon. Cypress roots, hanging moss,
reeds, peat, shallow puddles and drifting mist surround the routes. Warm lamps
draw decorative fireflies. Eighty-one crocodiles, Widows and Broodqueens occupy
thirty-two encounters across trails, groves and shore clearings, while five strongboxes offer 10–20 gold as floor loot.
Widows poison their victims; Broodqueens fire webs that briefly root them.
Fourteen marsh items expand the equipment catalog, including movement bonuses
and Crit Rating. Every point gives 1% critical chance; critical hits double damage
and display larger yellow numbers. No marsh quests are offered yet.

See [Hollowmere](HOLLOWMERE.md) for the camp, landmarks, wildlife, loot tables,
soundtrack and authoring details.

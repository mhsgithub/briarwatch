# Centurion and March balance

## Design contract

Keep the approved heavily stylized dark-medieval world, hand-painted icons,
bronze/enamel UI, and character/pack layout. Diablo II inspires deliberate attacks,
readable silhouettes, meaningful equipment and dangerous journeys from a safe town.
Do not copy its characters, maps, names or assets.

## Character and combat

The only playable class is **Centurion**. Naked base stats are **0 melee damage,
0 armor, 100 vitality**. A new character starts with Watch sword, Padded Coat,
Oak shield, one Tonic and zero gold: 4 melee damage, 3 armor, 100 vitality.
Existing saves retain their character state while using the current item definitions.

Melee damage is exactly base plus equipped bonuses before the target's armor.
One armor subtracts one incoming melee/ranged physical damage, with a floor of
zero for ordinary/player damage. Enemy attacks carry an explicit minimum of one
damage after armor on a successful hit; a miss deals no damage. Block is a learned passive; Elemental Resolve gives temporary elemental immunity. Weapon attack speed is **seconds between swing starts**,
not attacks per second: Watch sword and Warden's Blade 0.8 s, Pitchfork 1.8 s.
The committed windup remains 0.18 s; targeted pursuit and swing advance remain.

Out of combat, regain 1 vitality every 2 seconds, capped at maximum. Any attack
or damage restarts a four-second combat grace period; a living enemy chasing the
player blocks regeneration regardless of that timer. Returning/leashed enemies
do not count as chasing. Player footsteps are silent; enemy footsteps remain.

Pitchfork occupies both hands. Equipping it returns any old weapon and shield
to the pack. If there is not enough room, nothing changes. Equipping a shield
displaces a two-handed weapon. The offhand cell shows a faded linked weapon;
unequipping either hand returns the one weapon once. A restored malformed
two-hand-plus-shield combination puts the shield in the pack, or refunds its
sell value if that malformed save has no room.

Equipment drives the world model and portrait through shared appearance tags.
Unequipped characters have a plain tunic, trousers and basic shoes; equipped
helmet/hood, body armor, gloves, belt, boots, amulet, weapons and shields appear.
Bandits wear cloth/leather, not Centurion plate. Appearance is stylized geometry,
not an imported skeletal animation system.

## Consumables and action belt

Tonic heals 50 over 5 seconds; Greater Tonic heals 100 over 5 seconds. Healing is
continuous, clamps to maximum, and pauses with gameplay. Only one potion recovery
can be active: another use is rejected without consuming an item. Full-health use
also preserves it. Death/respawn cancels recovery; it is not saved. Vitality gear
changes maximum HP without granting an instant heal when repeatedly equipped.

Six bottom action slots start empty. Click an empty slot to choose a consumable;
drag one from the pack onto a slot; drag between slots to swap; right-click to clear.
Click a bound slot or press 1–6 to use it. Bindings use stable item IDs, survive
selling/consumption and saves, and show remaining stock. Q opens the current quest journal without consuming a potion. An empty-stock binding does not consume anything.
The kind/id activation signal provides a stable extension point for future
abilities while the current Centurion talents use the same action belt.

## Items

Values below are gold. Sell prices are explicit and independent of buy prices.
All items are White except Guardian’s Amulet (Green). Names use White → Green →
Blue → Legendary (orange) colors in item details, tooltips, shops and world drops.
Blue/Legendary are supported tiers, not additional items in the present catalog.

| Item | Main effect | Buy value | Sell value |
|---|---|---:|---:|
| Watch sword | +4 melee damage, 0.8 s/swing | 8 | 2 |
| Oak shield | +2 armor | 10 | 2 |
| Padded Coat | +1 armor | 12 | 3 |
| Tonic | 50 healing / 5 s | 5 | 2 |
| Greater Tonic | 100 healing / 5 s | 40 | 8 |
| Riveted Shield | +4 armor | 65 | 10 |
| Watchkeeper mail | +3 armor | 60 | 9 |
| Warden's Blade | +8 melee damage, 0.8 s/swing | 80 | 12 |
| Watchkeeper Helmet | +2 armor | 50 | 8 |
| Outrider Gloves | +1 armor | 30 | 6 |
| Outrider Belt | +1 armor | 30 | 6 |
| Outrider Boots | +2 armor | 40 | 7 |
| Guardian’s Amulet (Green) | +2 armor; +10 vitality | 100 | 16 |
| Worn Leather Gloves | +1 armor | 6 | 2 |
| Worn Leather Belt | +1 armor | 5 | 1 |
| Ragged Cloth Hood | +1 armor | 6 | 2 |
| Stiched Leather Vest | +2 armor | 12 | 3 |
| Ragged Boots | +1 armor | 6 | 2 |
| Pitchfork | +10 melee damage, 1.8 s/swing (two hands) | 18 | 4 |
| Outlaw's Mantle | White shoulders, +2 armor | 55 (not stocked) | 8 |
| Warwick Cellar Key | Quest pouch, no pack space | Not tradeable | Not tradeable |

Mara sells exactly Tonic, Greater Tonic, Watchkeeper mail, Warden's Blade,
Riveted Shield, Watchkeeper Helmet, Outrider Gloves, Outrider Belt, Outrider Boots
and Guardian’s Amulet. Other buy values are valuation metadata, not vendor stock.
The Forged Longsword is absent from the catalog, vendor and loot. Saves containing
the retired `forged_sword` ID migrate it to Watch sword so the item is not lost.

## Enemy loot

Only the three ordinary enemy resources explicitly reference
`content/loot/march_enemies.tres`. A new EnemyDefinition defaults to no loot table.

Gold weights: **0: 55%, 1: 27%, 2: 12%, 3: 6%**. Expected gold per ordinary
kill is 0.69; zero remains the most likely outcome.
Zero produces no currency object or sound. Each item rolls independently per kill:

| Item | Chance |
|---|---:|
| Worn Leather Gloves | 3.5% |
| Worn Leather Belt | 3.5% |
| Ragged Cloth Hood | 3.5% |
| Stiched Leather Vest | 2.5% |
| Ragged Boots | 3.5% |
| Pitchfork | 1.5% |
| Tonic | 2% |

Only Tonic drops, not Greater Tonic. Independent rolls permit multiple-item drops.
The death path invokes the table once per enemy. Darius uses his own guaranteed
key/mantle table, with no gold drop.
See AUDIO.md for the recorded sound replacement.

## Region, camera and visibility

The March is **256 × 224 m**. It contains 76 enemies in 19 encounters, including
four guards near the Warwick ruins and several mixed camps. The separate tower adds
two bowmen and Darius. The winding King's Road is about 309 m including its southern
approach; the town-to-watchtower portion is about 227 m.
The first quest is **The Crow's Captive**: retrieve Darius's Warwick cellar
key and return it to Elric for 50 gold. The key goes into a separate quest pouch,
so collection and hand-in work with a full pack. Existing outdoor IDs remain.
Iona offers healing only. Q opens/closes the paused quest journal;
the front-screen objective tracker remains. Carried gold appears only in inventory
and vendor balances. Authored roads, camps and woodland extend the visual editor workflow.

The camera follows position with fixed pitch/yaw; movement never rotates it.
Only the M map remains and it deliberately has no player-position indicator.
Its only marker is the active quest objective: the tower after acceptance, Elric
after collecting the key, and none after claiming the reward. Inside the tower,
the pin points to Darius before retrieval and the exit afterward. The objective is visible
even in unknown land, but its surrounding terrain is hidden. Fog reveals within
18 metres as you move, stored in 2-metre cells and preserved after leaving an area.
Older saves start surveying from town because they contain no exploration history.
Nearby large props fade over roughly 0.2 s to 18% opacity within 0.65 local units
of their visible footprint, then restore their original materials when you leave.
Collision is unchanged. FireVisual is reusable and contains layered animated
flames, rising embers and phase-varied warm light.

## Existing saves

Version-1 saves remain supported. Existing gold, bag and outdoor defeated
IDs are preserved; this is not a fresh-start reset. Item definitions adopt the
new stats. New characters get the new starting loadout. New encounter IDs are
alive on older saves; original defeated IDs stay defeated. Action bindings are an
optional field and default empty. Old camp-clear quests migrate to the new key
objective, including previously completed camp-clear quests. New key-quest
completion persists normally. Personal saves are never used by test/capture commands.

## Enemy tuning and movement

| Type | Health | Base hit damage | Hit chance | Base speed (m/s) |
|---|---:|---:|---:|---:|
| Bandit | 45 | 8 | 70% | 2.80 |
| Bandit archer | 35 | 11 | Arrow collision | 2.64 |
| Wolf | 30 | 6 | 60% | 4.24 |
| Darius Crowbane | 125 | 15 | Geometrically valid hit | 2.40 |

Centurion base movement is 4.96 m/s. Weapon swing periods and arrow flight speed
use their authored definitions. Editor instance overrides remain available for
intentional variants.

Melee accuracy is rolled after reach, arc and wall checks pass. Failed rolls show
“Miss” and apply no damage. Arrows do not roll accuracy. The minimum-one rule is
set on every Enemy's attack and carried through its DamagePacket, so it also
applies to future enemy types without changing unarmed player damage.

Bowmen retreat for at most 0.65 seconds (roughly 1.7 metres), then stand for
2.4 seconds, shooting while in range and line of sight. Darius is slower than all
three ordinary enemy types and uses a two-second basic swing period / 0.8 s windup.

Heavy Cleave: 1 s committed windup, 3.8 m reach, 140-degree frontal arc, 20 base
physical damage, then 3 armor-ignoring bleed damage each second for 5 seconds.
Cooldown is 7–10 seconds between starts, delayed if another windup is in progress.
The raised axe, animated ground sector and roar communicate the attack; no ability
name text appears. Kick: 0.35 s windup, 2.1 m reach, 0 damage, 0.65 s knockdown,
9–13 s cooldown. Kick has an explicit zero damage floor. Bleeds refresh, not stack;
effects pause with menus and clear on death. Defeating Darius drops his key and
mantle exactly once. Retreating through the door preserves drops/defeats but living
enemies reset health on re-entry, matching load behavior.

## Progression / Warwick addition

PROGRESSION.md records all level thresholds, fourteen talents and interaction
rules. Ordinary
current enemies give 1 EXP; Darius and Brutus give 5. Four new outdoor guards use
the existing raider/bowman definitions.

Brutus: 120 HP, 15 damage, 0.95 seconds per punch, 2.35 m/s. At half health he
performs sixteen 30-damage pulses over eight seconds within 2.8 metres, stationary.
Successful punches/pulses knock back. He does not inherit ordinary enemy loot.
Rescue rewards 10 gold and a Green ring, Kasparov Family Seal (+5 vitality,
sell value 12, nominal value 30, not stocked).

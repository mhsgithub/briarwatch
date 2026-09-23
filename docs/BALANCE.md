# Centurion and March balance

## Design contract

Keep the approved heavily stylized dark-medieval world, hand-painted icons,
bronze/enamel UI, and character/pack layout. Diablo II inspires deliberate attacks,
readable silhouettes, meaningful equipment and dangerous journeys from a safe town.
Do not copy its characters, maps, names or assets.

## Character and combat

The only playable class is **Centurion**. Naked base stats are **0 melee damage,
0 Strength, 0 Crit Rating, 0 armor, 100 vitality**. A new character starts with Watch sword, Padded Coat,
Oak shield, one Tonic and zero gold: 4 melee damage, 3 armor, 100 vitality.
Existing saves retain their character state while using the current item definitions.

Melee damage is base plus equipped damage bonuses plus Strength, before the
target's armor. Each point of Strength adds one melee damage, including the
weapon-scaled Centurion abilities. Base Strength is zero.
Each point of Crit Rating grants one percentage point of critical chance, capped
at 100%. Direct player hits and damaging talents can critically strike for double
post-armor damage; damage-over-time effects cannot. Movement speed bonuses on
equipment add to movement talents. Both are displayed in the character panel.
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
The March's Green items are Guardian’s Amulet, Kasparov Family Seal, Blackroad
Belt and Bloodclaw; Hollowmere adds Green drops and expedition vendor gear.
Names use White → Green →
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

The Bandit, Archer, Greyfang and Elite Bandit resources explicitly reference
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

## Progression and Warwick

PROGRESSION.md records all level thresholds, fourteen talents and interaction
rules. Ordinary
enemies give 1 EXP; Elite Bandits give 2; Darius, Brutus and Garrick give 5;
Bloodfang gives 10. Four outdoor guards use
the existing raider/bowman definitions.

Brutus: 120 HP, 15 damage, 0.95 seconds per punch, 2.35 m/s. At half health he
plants his feet for eight seconds, throwing five knives every 0.25 seconds in
randomly rotated directions (160 knives in a full rage). Knives travel at 15.5 m/s
and deal 20 physical ranged damage on collision, reduced by armor. Their swept
0.055-metre tips hit the player or stop at scenery; nearby misses do no damage.
The 2.8-metre ring, fist animation, light and sounds accompany the rage.
Only ordinary punches knock back. He does not inherit ordinary enemy loot.
Rescue rewards 10 gold and a Green ring, Kasparov Family Seal (+5 vitality,
sell value 12, nominal value 30, not stocked).

## Dark Woods and the final March quest

The Dark Woods is 112 × 164 metres. Its authored nine-by-nine maze uses 10-metre
cells, roughly 6-metre walkable corridors, 230 tree-wall segments and a circular
boss clearing about 37 metres across. The direct navigable route through the
maze is about 206 metres; deeper branches reward exploration. Nine Greyfangs and
nine Elite Bandits start outside the boss room. The once-only side chest drops
15 gold onto the floor for collection. The Dark Woods has no map.
Kasparov's Into the Lion's Den pays 50 gold after Bloodfang dies.

| Enemy | Health | Base melee | Accuracy | EXP |
|---|---:|---:|---:|---:|
| Elite Bandit | 80 | 15 | 80% | 2 |
| Garrick Vane | 160 | 20 | 100% | 5 |
| Bloodfang | 200 | 23 | 100% | 10 |

Elite Bandits use the ordinary March loot table. Garrick guarantees one Green
Blackroad Belt: +2 armor, +10 vitality, sell 12, valuation 100. Bloodfang guarantees
one Green Bloodclaw: one-handed, 10 damage, 0.8 s/swing, +1 Strength, sell 16,
valuation 180. Neither item is stocked by Mara.

Garrick throws a burning brand through a 0.45-second arc after a visible
0.85-second windup, igniting a 2.7-metre-radius fire on landing, with
5–10 seconds between casts. Each patch lasts 40 gameplay seconds and deals 20
armor-ignoring fire damage every 0.5 seconds. The bosses are unaffected. Patches
remain after Garrick dies; remaining duration and tick phase survive region
snapshots. Inactive-region timers pause. Elemental Resolve's fire ward applies.

His basic sword has a 30% bleed chance on an accepted hit: 2 damage per second
for five seconds. Bleeds do not stack; a weaker bleed cannot replace a stronger
active bleed. At 25% health he abandons his attack and sprints to the cage at
7.5 m/s. A lethal threshold-crossing blow still releases the beast, preventing
a blocked quest.

Bloodfang's 66% and 33% thresholds each trigger a howl and two Greyfangs. These
ordinary wolves grant 1 EXP and normal loot; stable summon IDs prevent repeated
rewards on revisit. Fury has a 1.2-second windup, four seconds of accelerated
chasing and biting, and a 20-second cooldown between activations. Being within
2.7 metres with clear line of sight applies a single 12 × 5-second bleed per fury.

A Greyfang corpse within 1.8 metres makes Bloodfang stop and feed:
15 healing each second for three seconds, then the corpse is consumed. He does
not seek corpses independently. Lunge has a 0.65-second crouch, locked heading,
a collision-constrained 0.45-second rush at 15 m/s, one 23-base-melee hit and
4 m/s initial knockback. It is selected at 3.2–9 metres with line of sight and
a 7–11-second cooldown. Bosses remain stun-immune.

Leash distances are 24 metres for ordinary March enemies, 23 for Elite Bandits,
33.6 for Darius, 42 for Brutus and 43.2 for Garrick and Bloodfang.
Death during an unfinished den encounter resets both bosses, the cage and
encounter hazards; reward credits prevent duplicate EXP and loot on retries.
The U testing shortcut adds 15 spendable talent points, including at level 1;
normal rank caps and prerequisites still apply, and grants persist in saves.

## Hollowmere wildlife, equipment and services

Hollowmere has 25 crocodiles (100 HP, 20 damage, 70% hit, 2 EXP), 42 Marsh Widows
(80 HP, 17 damage, 70% hit, 2 EXP) and 14 Broodqueens (150 HP, 25 damage, 90% hit,
3 EXP). Widow hits apply one poison damage per second for three seconds.
Broodqueen ranged webs root for two seconds, with 0.8-second warnings and
9.5–12.5-second cooldowns. All three use a 28-metre leash. Shared gold weights
are 70% zero, 12% three, 10% four and 8% five. Their fourteen independent item
rolls and complete gear values are listed in [Hollowmere's loot table](HOLLOWMERE.md).

Oswin in Briarwatch and Tamsin in Lanternwatch reset both talent trees for 100
gold. Every spent point is refunded, including spent testing grants. Level/EXP
remain. Empty trees and insufficient funds make no change. Learned ability
bindings, active talent effects and cooldowns are cleared. Five marsh caches
drop 12, 15, 20, 10 and 18 gold respectively and never refill.

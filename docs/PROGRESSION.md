# Centurion progression and Warwick rules

## Levels

Start at level 1; stop at level 20. Each level-up awards one point (19 total).
Level does not add hidden damage/armor/health. Current EXP resets to zero on
level-up, discarding overflow from that kill.

| Level to | EXP required |
|---|---:|
|2|30|
|3|70|
|4|90|
|5|110|
|6|150|
|7|210|
|8|290|
|9|380|
|10|500|
|11|600|
|12|720|
|13|830|
|14|950|
|15|1100|
|16|1300|
|17|1550|
|18|1800|
|19|2200|
|20|2750|

Ordinary enemies grant 1 EXP, Elite Bandits grant 2, Darius/Brutus/Garrick grant 5,
and Bloodfang grants 10. New definitions
default to zero until configured. The Briar March and its instances total 130 EXP before
summons: 87 ordinary enemies (87), nine Elite Bandits (18), Darius/Brutus/Garrick
(15) and Bloodfang (10). His two pairs of Greyfangs add four EXP for a total of
134. Hollowmere's 25 crocodiles and 42 Widows grant 2 EXP each; its 14 Broodqueens
grant 3 each, adding 176 EXP for 310 across both regions including summons.
The final level and remainder depend on kill order
because level-up discards overflow. No repeatable
XP service or altered curve was added. Higher builds are verified in isolated tests.

Old saves without progression receive one-time credit for recorded defeats,
using authored spawn IDs/definitions without instantiating old AI or granting loot.
Duplicate/unknown IDs grant nothing; migrated progression is saved normally.

## Talent choices

N unlocks at level 2. Each of the two trees has seven talents in four tiers.
Exact names/ranks/cooldowns/icons/edges/descriptions live in
content/progression/centurion.json. One point buys one rank. Every connected
parent requires **maximum rank**; multiple parents mean **all must be mastered**.
Older saves refund ranks whose prerequisites are no longer satisfied, preserving
level and EXP. Valid allocations remain learned.
There are no extra level gates or mana costs. Master Oswin in Briarwatch and
Captain Tamsin in Lanternwatch reset learned talents for 100 gold, refunding
all spent points and clearing learned ability bindings and active effects.

- Battle: Block → Whirlwind / Impale; Whirlwind → Bloodthirst / Retaliate;
  Impale → Retaliate / Rampage; all three tier-3 talents → Bladestorm.
- Pathfinder: Momentum → Leap / Unshackled; Leap → Iron Constitution / Elemental
  Resolve; Unshackled → Elemental Resolve / Fleetfooted; all three → Blood and Breath.

Drag learned active icons to the six-slot belt, use the detail's 1–6 buttons,
or click an empty belt slot to choose. Right-click clears; belt dragging swaps.
Cooldown overlays update live. Menus pause combat and timers; they cannot be used
to fire an ability. Consumables retain the existing pack/belt behavior.

## Additional interaction decisions

- Weapon damage uses current basic melee damage before enemy armor. Unarmed
  abilities do not manufacture damage. Whirlwind hits within 3 metres for 200%.
- Bladestorm delivers exactly six 100% pulses, one at each second's end, within
  3 metres. Both area attacks test world obstruction. During the storm you can
  move and use ready utility actions, but not Leap or make basic attacks.
- Impale and Retaliate empower the next **committed basic swing** within ten seconds.
  They combine; a missed swing still consumes them. Impale stuns ordinary targets
  for three seconds; all boss definitions explicitly resist it.
- Each melee block opens one five-second Retaliate activation opportunity.
  Activating consumes it. No conventional cooldown applies.
- Block is melee only: 2/4/6%, doubled by an actual equipped shield.
- Fleetfooted subtracts 3/6/9 **percentage points**, including an evasion roll on
  an arrow that physically collides. Projectile motion/collision is unchanged.
- Bloodthirst heals 1/2/3% of actual HP removed, including abilities. Overkill
  cannot create extra healing. Fractional health is retained internally.
- Rampage increases attacks per second by 20% (swing interval divided by 1.2),
  movement by 20%, and received damage after armor by 10%, for ten seconds.
- Movement bonuses add. Iron Constitution scales equipment vitality only
  by 5/10/15%, not base health or potion recovery; fractional bonuses are retained.
- Blood and Breath has strict thresholds: above 80% adds 20% movement; below
  20% restores 1% maximum vitality per second. Neither applies at 20% or 80%.
- Leap travels forward up to ten metres over 0.5 seconds with swept body collision.
  Its visual arc cannot cross walls or locked bars; roots prevent casting.
- Unshackled removes root, slow and knockback, but cannot escape stun/knockdown.
- Bladestorm rejects new control effects and clears movement impairments on activation.
- Elemental Resolve cleanses poison/fire/frost and blocks their damage/statuses
  for 3/6 seconds through shared StatusEffects. Darius's bleed is not elemental.
- Cooldowns persist across saves/travel. Buffs are transient: loading returns to
  town without active buffs; death clears effects but does not reset cooldowns.
- Successful enemy hits retain their one-damage minimum after armor/modifiers.

## Warwick encounter and rewards

Elric offers **A Lord Beneath the Stones** only after the key quest is claimed.
Warwick's ruin near (74,88) matches the marked southeast location. Four standard
bandit/bowman guards defend the central portal, gated by the accepted rescue quest.

The separate 20×30 metre cellar contains cutaway masonry, torchlight, barred
side cells with skeletons, straw beds, drains, chains and a locked rear cell.
Kasparov wears a noble robe and clasp, not military equipment.

Brutus has 120 health, 15 base melee damage, 0.3-second windup / 0.95-second punch
interval, 2.35 m/s movement and short successful-hit knockback. At half health,
once per fight, he roars and plants his feet for eight seconds. His red 2.8-metre
ring and pulsing light accompany five knives every 0.25 seconds, thrown in
random directions at 15.5 m/s. Each collision deals 20 physical ranged damage
before armor and can be evaded; melee Block does not apply. Knives stop at walls
and do not knock back. His ordinary attack pauses during rage,
then recovers for one second. Death cancels attacks. Disengaging cancels rage;
a full leash reset restores another attempt.

Defeat grants 5 EXP and permits opening the rear cell. Talking to Kasparov
completes the quest: 10 gold and the Green **Kasparov Family Seal**, +5 vitality,
ring slot, sell value 12. Both return to town; Kasparov offers Into the Lion's Den.
A full bag reserves the ring persistently, claimable from the pack header after
making room. Rewards cannot be repeated; travel/load cannot resurrect the boss
or duplicate the rescued prisoner.

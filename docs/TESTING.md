# Verification

Run `tools/launch.ps1 -Mode test` for the headless integration suite, and
`tools/launch.ps1 -Mode capture` for thirty-five rendered scenes. Tests instantiate the
real main scene and use `--test` to avoid loading or writing the player's save.
Temporary test saves use distinct names under `user://`. PNG captures and logs
are local artifacts, not required project inputs.

## Automated coverage

The suites contain **320 checks** (134 core + 58 watchtower + 89 progression/Warwick
+ 29 ability combat + 10 talent UI), covering:

- All 76 outdoor placements and stable IDs; native navigation mesh; navigable enemy spawn
  positions; connected town-to-tower route; actual movement through physics.
- Keyboard input direction relative to the camera.
- Editor scene packing/reloading of a modified transform, HP and damage override;
  immutable type defaults and duplicate spawn ID rejection.
- Armor and weapon modifiers; equipment replacement; affordable/unaffordable
  purchases; capacity safety; selling; potion use.
- Timed sword hit, facing rejection and attack cooldown; real arrow travel and
  collision; lethal transitions, loot generation/collection and double-pickup guard.
- Key retrieval (not exterior camp clearance), reward payout and duplicate-reward guard.
- Save replacement, ID round-trip, malformed file backup recovery, invalid item
  IDs and equipment-slot validation.
- Death screen, pause state, recovery position, gold penalty and preserved gear.
- NPC service opening, healing without world reset, and removal of the Rest button.
- Old three-slot saves loaded into eleven slots; ring auto-placement and combined
  modifiers; expanded stable-ID round-trip; explicit category rejection; full-pack
  unequip safety; eleven equipment cells plus twenty pack cells in the actual UI.
- Actual floating-number movement and expiry; real archer retreat followed by a
  successful timed pursuit hit; Shift-click attack-in-place without forward advance.

The melee and projectile checks use the actual AttackComponent and physics, not
just mocked health changes. Camp completion is tested by applying lethal damage
to each camp member; this verifies orchestration, not difficulty balance.

- Fixed camera basis during movement; expanded bounds, encounter count, tower distance
  and road length; absence of the minimap.
- Naked/starting Centurion values, armor's zero-damage floor, exact weapon periods,
  equipment-driven visuals, two-handed displacement and atomic full-pack rejection.
- Removed-item save migration, amulet vitality, colored names, timed Tonic/Greater
  Tonic recovery, pause/cancellation and full-health/non-stacking preservation.
- Empty action defaults, stable-ID restore/dispatch and stock depletion. Actual GUI
  drag hit-testing from the open pack onto the belt, I to close, then number-key use.
  Headless windows explicitly use 1440 × 900 (otherwise Godot defaults to 64 × 64).
- Current-only loot table assignment, seeded 10,000-kill distribution and no potion
  drops; all ten vendor prices, modest sell values and distinct gold/gear sound data.
- Close-prop transparency/material restoration, changing fire/light state, embers
  and real-equipment portrait state.

## Rendered and interactive checks

The original milestone was run on Windows with Godot 4.7.2 Compatibility rendering on Intel
Graphics. Town, inventory, vendor, watchtower combat and recovery screens were
captured from the running renderer and inspected. Live mouse input was used to
walk to Elric, open his dialogue and accept the quest. Godot's visible editor was
opened to the authored region and used to inspect the watchtower spawn's separate
66-HP / 15-damage instance overrides and shared definition field. The HP override
was changed to 67 through the Inspector, applied, and undone to preserve balance.

Problems found and fixed during verification included HUD anchor offsets,
camera-relative W direction, overlapping ground shadows, JSON number comparison
in the test, navigation startup synchronization and active sound cleanup on unload.

The 17 September visual overhaul was run using the same pinned engine on an
NVIDIA GeForce RTX 3060 Ti. Ten captures cover town, inventory, vendor, watchtower,
recovery, map, pause, healer, quest and selected-item details. Captures were
reviewed for frame/text overlap, icon readability, character framing and contrast;
opaque modal backing, panel margins, portrait orientation, cell borders and modal
feedback positioning were adjusted during that review.

Live mouse checks additionally unequipped a sword, dragged it from the pack back
to its compatible slot and confirmed damage changed from 14 to 10 and back to 14.
Potion inspection showed its description and healing value. These sessions used
`--test`, so personal saves were not loaded or overwritten. The Shift regression
waits a frame for its synthetic modifier event before dispatching the click;
otherwise it would test event-buffer timing instead of player behavior.

The subsequent feedback revision adds captures of the fully equipped Centurion,
two-handed Pitchfork (including item details), unequipped Centurion, fire,
close-house transparency and action-slot picker: sixteen images in total. The
new atlas, item text, gear occupancy and map-label spacing were inspected in the
running renderer. The regression suite uses engine input events, not a claim of
manual desktop playtesting for every new feature. Sound waveform distinction and
volume settings are checked; subjective speaker/headphone loudness remains a
user playtest consideration.

## Reproducibility and scope

Verified on 16 September 2026: a Git archive was extracted into a separate clean
directory, imported with no original `.godot` cache or bundled tools, and passed
all **47 original checks** using the pinned engine. The launch script's `-GodotPath` override
was used to supply the engine independently of the copied project.

Verified again on 17 September 2026 after the overhaul: all current source files,
including the new PNGs, shaders and UID sidecars, were copied to a fresh directory
without `.godot`, `.tools` or Git metadata. A clean import and all **59 checks**
passed with the engine supplied externally through `-GodotPath`. This verifies a
cache-independent source copy on this PC, not testing on a second physical PC.

The feedback revision was verified the same way on 17 September: a new source
copy without cache, tools or Git metadata imported successfully and passed all
**111 checks with zero failures**. The final rendered capture run also exited
cleanly. Both runs used isolated test mode and left the personal save untouched.

The engine version and official Windows archive checksum are pinned in
`tools/engine.json`. Future fresh copies must pass the same process. Native Godot
UID sidecars are versioned. No project/resource reference embeds a local username,
drive path, API key or dependency from the original PC.

Restricted-shell runs may print Godot's `Failed to read the root certificate
store` diagnostic because that sandbox cannot read the Windows certificate store.
Normal interactive runs do not print it. The game has no network functionality;
this is separate from gameplay script/runtime errors. No gameplay errors or
resource leaks remained in the final integration run.

Remaining validation limits: no test on a second physical PC, no controller or
multiplayer testing, no hundreds-of-enemies load test, and no release-export
packaging test. The current deliverable runs through the Godot editor/runtime.
New content should receive a visual pathing/combat pass in addition to the suite.

## Latest playtest feedback revision

The isolated revision suite passes with zero failures. Coverage includes each
enemy's stats/speed and 50,000 seeded accuracy rolls,
actual missed/hit melee resolution, the one-damage armor floor, colliding arrows
with a forced zero accuracy value, Q journal input without potion consumption,
exact gold-only quest payout, removal of HUD gold/Rest, fog reveal and JSON
restoration, active/return/completed quest pins, decoded sampled cues and potion
sound dispatch. Existing pursuit, inventory, navigation and save checks still pass.

A separate `tests/loot_audit.gd` exercises 100,000 seeded rolls against the
configured loot table. The death path invokes the table once per enemy, and the
current table gives Tonic a 2% chance alongside the listed gear chances.

Nineteen current renderer captures include the new journal and maps before/after
exploration. These were inspected along with the affected HUD, healer and quest
screens. BALANCE.md is the authoritative reference for current values.

## Watchtower and Darius coverage

The combined command passes **192 checks with zero failures**, with no runtime
errors, navigation warnings or shutdown leaks in the final run. The main suite
checks the revised 45/35 enemy health, vendor prices and 55/27/12/6 gold weights.
The dedicated watchtower suite covers resting recovery and pursuit suppression,
silent player footsteps, short bowman retreats, doorway navigation, separate-region
loading, player/guard/boss movement through real physics, and the commander fight.

Boss checks exercise 125 HP / 15 basic damage / 2.4 m/s movement, a real one-second
cleave cast, exact physical damage and five armor-ignoring bleed ticks, dodging
behind or beyond the cleave, obstruction rejection, the one-damage armor floor,
zero-damage kick, blocked input during knockdown and pausable status timers.
A live AI sequence must perform normal swings and both specials without overlapping
windups, keep facing committed and respect repeated-cleave cooldowns. Player melee
must also damage the live commander. Killing the boss cancels an active special.

Lifecycle checks cover guaranteed key/mantle drops, full-pack quest-pouch pickup,
disk save/read of the key and per-region state, persistent dead boss/uncollected
mantle on re-entry, equipping the mantle, safe-town death recovery, exact one-time
50-gold hand-in, active-only journal, and legacy quest migration. Tests use separate
test save paths and do not read or alter the personal character.

Live movement testing caught the tower's baked path sitting 0.5 m above the floor,
outside the actors' 0.45 m waypoint tolerance. The interior now uses 0.1 m vertical
cells, with the navigation map synchronized to the active region's cell dimensions
before entry. Polygon/spawn checks alone would not have caught this.

Twenty-two renderer captures include the furnished circular interior, raised-axe
cleave warning without ability text, mantle/key inventory, revised shop and quest
panels. Native renderer images were inspected; this is scripted engine playtesting,
not a claim of exhaustive manual or second-PC testing. Subjective boss difficulty
and speaker/headphone sound mix remain useful areas for player feedback.

## Progression and Warwick coverage

Five isolated suites cover 332 assertions. The suites verify all EXP thresholds,
literal reset/overflow behavior, point budgets, prerequisite AND edges, capped
ranks, cooldown/binding persistence and one-time legacy-kill migration.

Ability checks include real Whirlwind damage/obstructions, exactly six Bladestorm
ticks, fractional actual-damage leech (including overkill rejection), both Impale
boss immunities, an actual empowered basic swing, three-second ordinary stun,
rank-two ward duration, movement/vitality modifiers, seeded Block/Fleetfooted
distributions, ten-metre Leap, wall collision and the locked-cell barrier.

Warwick checks exercise live player/boss navigation, ordinary punching and
physical knockback, the exact 50% rage trigger, sixteen pulses / eight seconds,
safe distance, post-rage recovery, death/quest gating, unlocking, rescue return,
town NPC persistence, no prisoner duplication, exact gold/ring reward, full-pack
reward reservation and JSON restoration of the entire completed chain.

Real Godot input tests cover level-gated N, spending a point, tab switching,
actual talent-to-belt drag/drop, modal attack suppression and number-key casting.
Thirty-five captured scenes include both trees, longest-description scrolling,
first-point locked states, southeast ruin, darker cellar, rage, rescue and ring.

Testing caught and fixed authored EXP properties appearing before Resource script
assignment, missing talent label fonts, combat-text parent typing and a movement
fixture retaining deliberate knockback. Gate collision was verified at z=-8.5,
the capsule's correct contact point; tests allow normal floating-point tolerance.

All runs use --test or distinct test-save paths. No personal save was opened or
changed. Rendering was inspected through engine captures on the local Compatibility
renderer; this is not a claim of exhaustive manual play or another-PC testing.

The current prerequisite rule requires every connected parent to be fully ranked.
Focused checks cover partial-rank locks, legacy point refunds and Kasparov's
placement beside Iona. The current focused run passes 101 progression/Warwick,
29 ability-combat and 10 talent-UI checks (140 total). Leap's tooltip describes
general obstacles without cellar-specific wording.

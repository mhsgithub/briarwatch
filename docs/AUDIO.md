# Audio direction and implementation

The game includes 90 WAV effects and three marsh-frog MP3 recordings. The
original combat palette uses restrained physical foley: dry blade movement,
leather, muted metal, weighty contact and natural vocal reactions. The undead,
ritual and Darkmere spell cues mix edited recordings with project-authored
synthesis. Combat feedback comes from sound, animation, light and ground
telegraphs rather than ability-name announcements.

## Sources and license

External sound recordings used here are offered under **CC0 1.0** by their
source authors. Project-authored synthesized cues have no external source.
These acknowledgements preserve provenance even where attribution is optional.
License: https://creativecommons.org/publicdomain/zero/1.0/

| Author / source | Used for |
|---|---|
| Vehicle / Jan Schupke — [Tinysized SFX](https://opengameart.org/content/fantasy-sound-effects-tinysized-sfx) | Whooshes, body-contact layers, metal, coins, leather, pages, cork and liquid |
| Vehicle / Jan Schupke — [Weapons and Apparel](https://opengameart.org/content/fantasy-weapons-and-apparel-sfx-library) | Boots and equipment buckles |
| qubodup — [15 vocal male strain/hurt/pain/jump sounds](https://opengameart.org/content/15-vocal-male-strainhurtpainjump-sounds) | Centurion/bandit effort, hurt and death reactions |
| pauliuw — [Dog sounds](https://opengameart.org/content/dog-sounds) | Edited canine bite, hurt and death reactions for wolves |
| bonebrah — [Dog Growl](https://opengameart.org/content/dog-growl) | Wolf alert growl |
| AntumDeluge — [Fire Crackling](https://opengameart.org/content/fire-crackling) | Campfire ambience |

Wolf vocals are adapted canine recordings, not recordings of wild wolves. Human
voice variants share a recording family, with a lower Centurion pitch and a
slightly higher bandit pitch. They contain reactions, not spoken dialogue.

## Editing and rebuilding

The exact input filenames and layer recipes are in `tools/build_audio.py`.
Edits include silence trimming, mono conversion, modest pitch changes, rumble/hiss
filtering, short endpoint fades, restrained levels and layering. The fire loop
uses an overlapping seam. Peaks are limited to 0.62 before the in-game attenuation;
short loud transients are not raised solely to meet an RMS target.

Rebuilding is optional: the final WAV assets and their Godot import settings are
committed project inputs under `assets/audio/`. Normal play needs only Godot.
For asset development, install Python packages `numpy` and `soundfile`, extract
the two Vehicle ZIPs, `slightscreams.7z` and `dog.7z`, and place those folders
alongside `dog-growl.ogg` and `fire-1.wav` in one source directory. Then run:

```text
python tools/build_audio.py <source-directory>
```

Source archive URLs:

- https://opengameart.org/sites/default/files/tinysized.zip
- https://opengameart.org/sites/default/files/weapons-apparel.zip
- https://opengameart.org/sites/default/files/slightscreams.7z
- https://opengameart.org/sites/default/files/dog.7z
- https://opengameart.org/sites/default/files/dog-growl.ogg
- https://opengameart.org/sites/default/files/fire-1.wav

## Runtime ownership and mix

`content/audio/cues.json` defines event variants, gain, audible range and retrigger
limits. `AudioLibrary` loads/caches these recordings, avoids consecutive identical
variants, and limits simultaneous transient voices. Its random generator is
independent of combat/loot randomness. `GameAudio` routes actor attack, hurt,
death, alert and movement events; enemy definitions select human, wolf,
reptile, spider, undead or occult profiles.

Enemy footsteps follow actual distance travelled and skip teleports. Player
footsteps are disabled. Creature voices
are rate-limited; a lethal hit plays death rather than both hurt and death vocals.
Impacts and vocal reactions remain separate layers. Distant transient sounds are
culled before voice allocation. World voices pause with gameplay; potion and
interface cues can play while a menu is open. Fire is a quiet spatial loop with
different starting offsets at different campfires.

Other events: bow release/arrow collision, gold/gear drop and collection, trades,
equipping, pack opening, map/journal pages and successful potion use. Rejected
potion use is silent. NPC dialogue remains written rather than recorded speech.

## Music

Eight complete tracks provide area and encounter identities. Briarwatch has
town and March wilderness themes; the Watchtower and Warwick share tomb
ambience. The Dark Woods has its own exploration track, while Determined
Pursuit plays for Garrick/Bloodfang and Malrec. Hollowmere has separate
Lanternwatch and wilderness themes. Dungeon Ambience scores the Sunken Chapel
crypts and Darkmere exploration; the Risen Soldier retains that ambient track.
`MusicDirector` reads Region music fields, local bounds and encounter state,
then crossfades for 1.75 seconds. Music continues under paused panels and
loops locally.

The tracks, authors, source pages and license links are recorded in
`assets/music/LICENSES.md`. The Dark Woods and both Hollowmere tracks are
CC BY 3.0 by **HitCtrl**; the other five are CC0. Source audio is committed;
playback needs no network.

Darius's cleave warning reuses the licensed human vocal recordings through a
dedicated `boss_roar` cue at a lower pitch and clearer gain. A dedicated
`heavy_cleave` cue layers the existing swing recording with metal on release.
Kick uses human effort and a low impact. These are runtime treatments of the
existing CC0 library, not additional downloaded assets. No ability-name text
substitutes for the visible windup and sound warning.

## Talents and Warwick

These cues reuse existing CC0 recordings: level_up (metal resonance),
talent_learn (equipment foley), brutus_punch (impact variants), cell_unlock
(metal variants), cellar_door (heavy gear movement). Brutus's effort/hurt/death
and roar use lower-pitched human recordings. Spins/leaps use swings and impacts;
wards/empowerments use bottle/gear textures. Existing mix/voice/range limits apply.
They use the same mix and voice limits.

## Dark Woods cues

The encounter reuses the committed CC0 recordings through new content cue IDs:
bloodfang_howl (low-pitched canine vocal), bloodfang_fury (growl/bite),
bloodfang_feed (bite), torch_cast (swing), cage_release (metal), and chest_open
(gear). These are spatial cues with controlled retrigger intervals and range.
The howl is accompanied by a raised head/arms; fury adds rapid jaw/head motion
and red light; feeding uses a hunched animation with audible bites. No mechanic
names or explanatory combat text are shown. Each fire patch has one looping
source and one ember emitter shared among its flame clusters.

Bloodfang's ordinary attack, hurt and death vocals use the enemy resource's
0.63 voice-pitch multiplier; his special howls, growls and feeding cues also
use lowered pitch. Garrick's narrative dialogue is displayed above him with
a low human vocal cue at encounter start and cage release.

fire_hurt and fire_impact use the original fire_hurt.wav synthesized hiss and
crackle. The hurt cue plays only when ground fire removes health; an elemental
ward suppresses it. The brand impact uses a quieter version. This source is
reproducible through tools/build_fire_sfx.ps1 and has no external license.

## Hollowmere

The marsh plays HitCtrl's *RPG - The Secret Within the Woods*, a mysterious
guitar, lyre and strings composition licensed CC BY 3.0. Lanternwatch Camp uses HitCtrl's guitar-led *RPG Ambient 3*,
licensed CC BY 3.0. Both committed source tracks are unmodified; region music
selection applies the existing crossfade and looping behavior at -19 dB.
Source links, attribution and license links are in `assets/music/LICENSES.md`,
the pause-menu music credits, and the Windows distribution's MUSIC-LICENSES.txt.

Marsh wildlife uses dedicated CC0 recordings for its alert, bite, hurt, death
and movement cues. Crocodiles use adult alligator and crocodilian-type growls,
plus the field recording's wet movement. Spiders use separate chattering and
insect-like shrieks, with a deeper mix for the Broodqueen. Web warning,
launch and impact also use spider-specific cues. None use the wolf, bandit,
bow or arrow sounds. Exact source credits and processing details are in
`assets/audio/LICENSES.md` and `tools/build_creature_audio.py`. Existing voice
limits and distance culling apply.

RegionAmbience plays one of three CC0 frog recordings by EZduzziteh at irregular
18–36 second intervals outside camp. Calls originate 14–20 metres away at -23 dB
with high frequencies attenuated. They pause with gameplay and are freed on
travel. Sources: https://opengameart.org/content/ribbit-frog-sounds ; original
ribbit_01.mp3 through ribbit_03.mp3 are renamed marsh_frog_1.mp3 through
marsh_frog_3.mp3 without editing. No environmental or combat RNG affects loot.

## Chapel crypts

The crypt uses yd's CC0 Dungeon Ambience. The Risen Soldier retains this exploration track; Darkmere uses the existing
boss composition for the final Malrec Veyne encounter. Zombies and
skeletons have dedicated alert, attack, hurt, death and movement profiles.
The ritual has a positional looping drone; lever, resurrection, death spell,
teleport, corruption and cleave have separate cues. Sources and processing
are documented in assets/audio/LICENSES.md and tools/build_chapel_audio.py.

## Darkmere effects

The offline chapel recipe renders charge warning/contact, mark
ambush, relic siphon, fire/poison bolts, meteor warning/impact, ritual start,
interruption and detonation. These are original deterministic synthesized effects;
no new external sources are required. The occult vocal profile routes Malrec
and cultists to magical cues. Region music retains the licensed Dungeon Ambience
for exploration and Determined Pursuit for Malrec. The Risen Soldier has no
boss-music override. The pause-menu and packaged music credits cover these tracks.
Malrec's boiling dark magic patch has its own low spell cue, authored in the
same offline synthesis recipe.

# Briarwatch audio provenance

All third-party sound recordings in this directory derive from CC0 1.0 sources.
Other effects are project-authored synthesis, documented below. CC0 license:
https://creativecommons.org/publicdomain/zero/1.0/

- Vehicle / Jan Schupke: fantasy foley, weapons and apparel.
- qubodup: human strain and pain vocals.
- pauliuw: canine sounds.
- bonebrah: dog growl.
- AntumDeluge: fire crackling.
- EZduzziteh: Ribbit Frog Sounds (three original MP3 recordings, renamed only).
  https://opengameart.org/content/ribbit-frog-sounds
- D.jones: Alligator Growls 02, CC0, source for reptile alert, death and wet movement.
  https://freesound.org/people/D.jones/sounds/527844/
- Ovkovko: CrocodilianTypeGrowl, CC0, source for reptile attack and hurt.
  https://freesound.org/people/Ovkovko/sounds/825609/
- spookymodem: Spider Chattering, CC0 on Freesound, source for spider attack,
  movement and web chitter. https://freesound.org/people/spookymodem/sounds/202108/
- qubodup: Insect or alien scream, CC0, source for spider alert, attack, hurt,
  death, web cast and impact. https://opengameart.org/content/insect-or-alien-scream

See ../../docs/AUDIO.md for the source page/archive URLs and editing details.
The original creature recordings are in ../../tools/audio_sources/ and their
reproducible excerpt timings and processing are in ../../tools/build_creature_audio.py.
Other source filenames and processing recipes are in ../../tools/build_audio.py.
Final WAVs and frog MP3s are local assets. No runtime download or third-party audio service is used.

## Chapel undead and ritual

- Zombie noises and moans — ianzazz, CC0 1.0:
  https://opengameart.org/content/zombie-noises-and-moans
  Original zombienoises.zip is committed under tools/audio_sources.
- Bones 2 — AntumDeluge, CC0 1.0:
  https://opengameart.org/content/bones-2
  Original bones-2.wav is committed under tools/audio_sources.
- CC0 license: https://creativecommons.org/publicdomain/zero/1.0/

The offline tools/build_chapel_audio.py recipe trims, resamples, normalizes and
adds short echoes to the zombie/bone recordings. Skeleton attack layers the
existing licensed bow_release.wav. Ritual, necromancer spells, corruption,
zombie movement and cleave sounds are original deterministic synthesis in the
same recipe. Outputs are mono 22050 Hz PCM; no runtime synthesis or downloads.
Malrec's dark patch cue is also original deterministic synthesis in that recipe.

## Darkmere additions

Charge, mark ambush, reliquary siphon, fire/poison bolt, meteor and cultist ritual
cues are original deterministic synthesis in tools/build_chapel_audio.py.
The occult profile selects these committed clips. No additional external sound
recordings or licenses were introduced for quests five and six.

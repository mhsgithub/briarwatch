"""Render short Hollowmere creature cues from the committed CC0 recordings.

Run with ``python tools/build_creature_audio.py --ffmpeg path/to/ffmpeg``.
The finished WAVs are committed; ffmpeg is needed only when authoring audio.
Source attribution and URLs live in assets/audio/LICENSES.md.
"""
from pathlib import Path
import argparse
import subprocess
import wave

ROOT = Path(__file__).resolve().parents[1]
SOURCES = ROOT / "tools/audio_sources"
OUTPUT = ROOT / "assets/audio"

# Name: original file, start, duration, gain dB. Each cue has its own excerpt.
CUES = {
    "reptile_alert": ("alligator_djones.mp3", 4.25, 2.45, 1),
    "reptile_attack_1": ("crocodilian_ovkovko.mp3", 0.12, 0.67, -1),
    "reptile_attack_2": ("crocodilian_ovkovko.mp3", 1.62, 0.74, -1),
    "reptile_hurt": ("crocodilian_ovkovko.mp3", 2.62, 0.77, 1),
    "reptile_death": ("alligator_djones.mp3", 7.13, 2.55, 0),
    "reptile_step": ("alligator_djones.mp3", 0.21, 0.34, 9),
    "spider_alert": ("insectoralien_qubodup.flac", 0.01, 1.15, 0),
    "spider_attack_1": ("insectoralien_qubodup.flac", 0.03, 0.44, 1),
    "spider_attack_2": ("spider_chattering_spookymodem.mp3", 4.48, 0.57, 28),
    "spider_hurt": ("insectoralien_qubodup.flac", 0.34, 0.57, 3),
    "spider_death": ("insectoralien_qubodup.flac", 0.01, 1.24, 0),
    "spider_step": ("spider_chattering_spookymodem.mp3", 7.20, 0.33, 29),
    "spider_web": ("spider_chattering_spookymodem.mp3", 9.10, 0.72, 28),
    "spider_web_cast": ("insectoralien_qubodup.flac", 0.08, 0.59, 1),
    "spider_web_impact": ("insectoralien_qubodup.flac", 0.21, 0.37, 2),
}


def main() -> None:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--ffmpeg", required=True, help="Path to a local ffmpeg executable")
    args = parser.parse_args()
    for name, (source, start, duration, gain) in CUES.items():
        result = OUTPUT / f"{name}.wav"
        fade_out = max(0.01, duration - 0.055)
        filters = (
            "highpass=f=65,lowpass=f=7500,"
            f"volume={gain}dB,"
            "afade=t=in:st=0:d=0.015,"
            f"afade=t=out:st={fade_out:.3f}:d=0.055,"
            "alimiter=limit=0.94"
        )
        subprocess.run(
            [args.ffmpeg, "-nostdin", "-hide_banner", "-loglevel", "error", "-y",
             "-ss", str(start), "-i", str(SOURCES / source), "-t", str(duration),
             "-af", filters, "-ac", "1", "-ar", "22050", "-c:a", "pcm_s16le", str(result)],
            check=True,
        )
        with wave.open(str(result)) as clip:
            assert clip.getnchannels() == 1 and clip.getframerate() == 22050
            assert clip.getnframes() > 4000, name
        print(f"{name}: {result.stat().st_size} bytes")


if __name__ == "__main__":
    main()

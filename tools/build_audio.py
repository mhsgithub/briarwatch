"""Rebuild Briarwatch's edited CC0 recordings (development only).

Usage: python tools/build_audio.py PATH_TO_EXTRACTED_SOURCES
Requires numpy and soundfile. See docs/AUDIO.md for source archives and licenses.
The committed WAVs are all the game requires; no Python/audio libraries at runtime.
"""
import argparse
from pathlib import Path
import sys

import numpy as np

ROOT = Path(__file__).resolve().parents[1]
sys.path.insert(0, str(ROOT / "test-results/audio-tools"))
import soundfile as sf

RATE = 32000
MANIFEST = []


def read(source, name, speed=1.0, duration=None):
    files = list(source.rglob(name))
    if not files:
        raise FileNotFoundError(name)
    samples, rate = sf.read(files[0], always_2d=True)
    samples = samples.mean(axis=1)
    # Trim quiet recording lead/tail, keeping a small natural onset.
    active = np.flatnonzero(np.abs(samples) > max(0.002, np.max(np.abs(samples))*0.018))
    if len(active):
        samples = samples[max(0, active[0]-int(rate*.015)):min(len(samples),active[-1]+int(rate*.04))]
    count = int(len(samples)*RATE/(rate*speed))
    samples = np.interp(np.linspace(0,len(samples)-1,count),np.arange(len(samples)),samples)
    if duration:
        samples = samples[:int(duration*RATE)]
    MANIFEST.append(name)
    return samples


def mix(*layers):
    result = np.zeros(max(int(offset*RATE)+len(data) for data,offset,gain in layers))
    for data,offset,gain in layers:
        index = int(offset*RATE)
        result[index:index+len(data)] += data*gain
    return result


def save(name, samples, loop=False):
    samples = samples - samples.mean()
    # Gentle band limiting removes rumble/hiss without synthesizing tonal effects.
    frequencies = np.fft.rfftfreq(len(samples),1/RATE)
    response = (1-np.exp(-(frequencies/65)**4)) / np.sqrt(1+(frequencies/7000)**8)
    samples = np.fft.irfft(np.fft.rfft(samples)*response,n=len(samples))
    if loop:
        # Overlap tail/head to avoid a click and a recurring silent seam.
        n=min(int(.25*RATE),len(samples)//4)
        cross=np.linspace(0,1,n)
        samples[:n]=samples[-n:]*(1-cross)+samples[:n]*cross
        samples=samples[:-n]
    else:
        n=min(int(.008*RATE),len(samples)//2)
        samples[:n]*=np.linspace(0,1,n)
        fade=min(int(.06*RATE),len(samples)//2)
        samples[-fade:]*=np.linspace(1,0,fade)
    peak=max(float(np.max(np.abs(samples))),1e-9)
    rms=max(float(np.sqrt(np.mean(samples**2))),1e-9)
    samples *= min(.62/peak,.10/rms)
    target=ROOT/"assets/audio"/(name+".wav")
    target.parent.mkdir(parents=True,exist_ok=True)
    sf.write(target,samples,RATE,subtype="PCM_16")
    print(f"{name}: {len(samples)/RATE:.2f}s, peak={np.max(np.abs(samples)):.3f}")


def main(source):
    def clip(name, speed=1.0, duration=None):
        return read(source,name,speed,duration)
    for i in range(1,4):
        save(f"swing_{i}",clip(f"tin-whistle-whoosh-0{1+(i%2)}.wav",.87+i*.035,.55))
        save(f"impact_{i}",mix((clip(f"apple-cut-0{i}.wav",.78,.45),0,1),
                              (clip("boots-leather-jump-01.wav",.9,.3),0,.35)))
        save(f"metal_{i}",clip(f"sword-clash-0{i}.wav",.94,.48))
        save(f"step_{i}",clip(f"boots-leather-step-0{i}.wav",1,.35))
        save(f"paw_{i}",clip(f"mud-steps-0{i}.wav",1.1,.28))
        save(f"human_hurt_{i}",clip(f"slightscream-0{i}.flac",.96,.65))
        save(f"human_effort_{i}",clip(f"slightscream-0{i+3}.flac",.95,.4))
    for i in range(1,3):
        save(f"human_death_{i}",clip(f"slightscream-{i+9:02d}.flac",.91,1.25))
    save("wolf_growl",clip("dog-growl.ogg",.86,1.0))
    save("wolf_bite",clip("Dog Bark 1.wav",.86,.45))
    save("wolf_hurt_1",clip("Sad Dog.wav",.93,.65))
    save("wolf_hurt_2",clip("Sad Dog 1.wav",.94,.65))
    save("wolf_death",clip("Sad Dog 1.wav",.85,1.4))
    save("bow_release",mix((clip("arrow-feathers-01.wav",1,.3),0,1),
                           (clip("wood-twigs-break-01.wav",.88,.22),0,.4),
                           (clip("tube-plastic-whoosh-01.wav",1.4,.25),.03,.6)))
    save("arrow_impact",clip("wood-twigs-break-02.wav",.85,.4))
    save("gold_drop",clip("coinflip-01.wav",.94,.55))
    save("gold_pickup",clip("coins-shake-01.wav",1,.5))
    save("gear_drop",mix((clip("boots-leather-jump-01.wav",.85,.45),0,1),
                         (clip("sheath-buckle-01.wav",.93,.4),.03,.4)))
    save("equip",clip("sheath-buckle-01.wav",.93,.5))
    save("pack",clip("cloth-pouch-shake-01.wav",1,.38))
    save("page",clip("book-page-01.wav",1,.4))
    save("potion",mix((clip("bottle-glass-uncork-01.wav",.95,.35),0,.6),
                      (clip("water-pour-01.wav",.95,.65),.23,.5),
                      (clip("bottle-glass-cork-01.wav",1,.2),.78,.25)))
    save("fire_loop",clip("fire-1.wav"),loop=True)
    print("Edited source recordings:",", ".join(sorted(set(MANIFEST))))


if __name__ == "__main__":
    parser=argparse.ArgumentParser()
    parser.add_argument("source",type=Path)
    main(parser.parse_args().source)

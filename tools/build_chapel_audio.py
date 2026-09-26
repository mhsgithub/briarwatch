"""Offline undead/ritual audio recipe. Requires NumPy and a local ffmpeg.

CC0 source archives are committed under tools/audio_sources (see LICENSES.md).
Outputs are 22050 Hz mono PCM, used offline with the existing spatial mixer.
Spell sounds are original deterministic synthesis, never generated at runtime.
"""
from pathlib import Path
import argparse
import io
import json
import subprocess
import wave
import zipfile
import numpy as np

ROOT = Path(__file__).resolve().parents[1]
RATE = 22050
RNG = np.random.default_rng(41027)


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--ffmpeg', required=True)
    args = parser.parse_args()
    output = ROOT/'assets/audio'
    cues = json.loads((ROOT/'content/audio/cues.json').read_text())

    def decode(data):
        result = subprocess.run([args.ffmpeg, '-hide_banner', '-loglevel', 'error',
            '-i', 'pipe:0', '-f', 'f32le', '-ar', str(RATE), '-ac', '1', 'pipe:1'],
            input=data, capture_output=True, check=True)
        return np.frombuffer(result.stdout, dtype='<f4').copy()

    def echo(signal, delay=.13, decay=.34):
        signal = signal.copy()
        offset = int(delay*RATE)
        for n in range(1, 5):
            shift = n*offset
            if shift >= len(signal): break
            signal[shift:] += signal[:-shift].copy()*decay**n
        return signal

    def resample(signal, pitch):
        return np.interp(np.arange(0, len(signal)-1, pitch), np.arange(len(signal)), signal)

    def write(name, signal, volume=-13, cooldown=.12, distance=24, loop=False):
        signal = np.nan_to_num(signal)
        signal -= np.mean(signal)
        peak = np.max(np.abs(signal))
        if peak: signal *= .88/peak
        if not loop:
            fade = min(int(.025*RATE),len(signal)//3)
            signal[:fade] *= np.linspace(0,1,fade)
            signal[-fade:] *= np.linspace(1,0,fade)
        with wave.open(str(output/(name+'.wav')), 'wb') as f:
            f.setnchannels(1)
            f.setsampwidth(2)
            f.setframerate(RATE)
            f.writeframes((signal*32767).astype('<i2').tobytes())
        cues[name] = dict(files=[name], volume_db=volume, range=distance, cooldown=cooldown)
        print(name, round(len(signal)/RATE,2), 'seconds')

    archive = zipfile.ZipFile(ROOT/'tools/audio_sources/zombienoises.zip')
    voices = [decode(archive.read(name)) for name in ['fastzombie1.ogg','zombienoise1.ogg','zombienoise2.ogg','zombienoise3.ogg']]
    for index, name in enumerate(['zombie_attack_1','zombie_alert','zombie_death','zombie_hurt']):
        limit = [1.0,2.0,2.6,.85][index]
        signal = resample(voices[index],.86)[:int(limit*RATE)]
        write(name, echo(signal,.09,.14), -13)
    write('zombie_attack_2',resample(voices[0],.72)[:int(.95*RATE)],-13)
    cues['zombie_attack'] = dict(files=['zombie_attack_1','zombie_attack_2'],volume_db=-13,range=24,cooldown=.12)
    bone = decode((ROOT/'tools/audio_sources/bones-2.wav').read_bytes())
    bone = bone[np.argmax(np.abs(bone)>.01):]
    for name, pitch, duration, volume in [('skeleton_alert',.8,.9,-14),('skeleton_hurt',1.12,.36,-12),('skeleton_death',.63,1.7,-10),('skeleton_step',1.22,.19,-24),('bone_rise',.51,2.1,-12)]:
        write(name,echo(resample(bone,pitch)[:int(duration*RATE)],.11,.18),volume)
    # The archer keeps the established bow release, layered with dry bone foley.
    bow = decode((output/'bow_release.wav').read_bytes())
    attack = np.zeros(max(len(bow),int(.55*RATE)))
    attack[:len(bow)] += bow
    b = resample(bone,1.2)[:int(.4*RATE)]
    attack[:len(b)] += b*.45
    write('skeleton_attack',attack,-13)

    def spell(seconds, base, end, noise=.2, rise=False):
        t = np.arange(int(RATE*seconds))/RATE
        freq = base+(end-base)*t/seconds
        phase = 2*np.pi*np.cumsum(freq)/RATE
        grit = RNG.normal(0,1,len(t))
        grit = np.convolve(grit,np.ones(17)/17,'same')
        signal = .38*np.sin(phase)+.18*np.sin(phase*1.502)+.10*np.sin(phase*2.01)+noise*grit
        env = (t/seconds)**1.2 if rise else np.exp(-3.6*t/seconds)
        return echo(signal*env,.17,.3)

    write('zombie_step',spell(.3,58,35,.9),-25)
    write('rotting_warning',spell(1,74,133,.35,True),-15)
    write('rotting_cleave',spell(.75,190,42,1.3),-10)
    write('corruption_spread',spell(.72,70,40,1.5),-20,.28)
    write('corruption_hurt',spell(.36,142,82,1.8),-16,.15)
    write('malrec_presence',spell(2.4,47,40,.25),-15,.2,35)
    write('malrec_death_spell',spell(1.7,220,37,.8),-11,.2,35)
    write('malrec_teleport',np.concatenate([spell(1.1,57,310,.3,True),spell(1.3,110,38,1)]),-13,.2,35)
    write('crypt_lever',echo(resample(bone,.4),.18,.16),-12)
    t = np.arange(RATE*8)/RATE
    drone = sum(np.sin(2*np.pi*f*t+np.sin(2*np.pi*.125*t)*.24)*a for f,a in [(48,.4),(72,.23),(96,.15),(144,.09),(193,.03)])
    drone *= .72+.28*np.sin(2*np.pi*.25*t)**2
    write('ritual_loop',drone,-23,.1,25,True)
    for name, seconds, base, end, volume in [
        ('brute_charge_warning',.8,48,89,-13),('brute_charge',.9,73,40,-13),
        ('brute_charge_impact',.45,120,38,-10),('mark_ambush',2,54,93,-14),
        ('reliquary_siphon',.45,160,310,-23),('malrec_bolt_fire',.6,180,64,-16),
        ('malrec_bolt_poison',.65,93,49,-17),('malrec_bolt_impact',.35,147,48,-15),
        ('meteor_warning',1.15,75,160,-19),('meteor_impact',.8,90,28,-13),
        ('cultist_ritual',2.5,48,62,-13),('ritual_break',1.3,170,34,-12),
        ('ritual_detonation',2.1,130,23,-9),('malrec_death',2.2,63,28,-12)]:
        write(name,spell(seconds,base,end,.7),volume,.18,32)
    write('malrec_dark_patch',spell(2.1,66,29,1.4),-16,.18,32)
    for event, source in [('alert','malrec_presence'),('attack','malrec_bolt_fire'),('hurt','malrec_bolt_impact'),('death','malrec_death'),('step','skeleton_step')]:
        cues['occult_'+event]=dict(cues[source])
    (ROOT/'content/audio/cues.json').write_text(json.dumps(cues,indent=2)+'\n')


if __name__ == '__main__': main()

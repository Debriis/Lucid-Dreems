"""Original formant syllables for text-paced fictional character chatter.
No recordings, voice clones, proprietary character samples, or runtime TTS.
"""
import argparse
import array
import json
import math
import random
import wave
from pathlib import Path

parser = argparse.ArgumentParser()
parser.add_argument('--project-root', type=Path, default=Path(__file__).resolve().parents[1])
root = parser.parse_args().project_root
out = root / 'audio/chatter'
out.mkdir(parents=True, exist_ok=True)
rate = 24000
vowels = [(640, 1120, 2400), (360, 1740, 2650), (290, 720, 2240), (470, 1330, 2490), (340, 2050, 2800), (520, 860, 2460)]
profiles = {
    'DOCTOR': {'pitch': 150, 'durations': [.12,.14,.11,.15,.13,.125], 'description': 'Dry mid-low nasal mutter; short voiced consonants, warm formants, restrained pitch.'},
    'RUE': {'pitch': 390, 'durations': [.085,.095,.08,.105,.09,.10], 'description': 'High springy toy syllables; bent pitch, double pulses, metallic modulation, crunchy edges.'},
    'AYUSH': {'pitch': 91, 'durations': [.17,.185,.16,.195,.175,.18], 'description': 'Low reversed formant syllables; rough subharmonics, breath, flutter, granular distortion.'},
}
records = []
resources = {}
preview_pcm = {}
for character, profile in profiles.items():
    resources[character] = []
    preview_pcm[character] = []
    for index, duration in enumerate(profile['durations']):
        rng = random.Random(19230 + index + len(character)*17)
        formants = vowels[index]
        next_formants = vowels[(index + 2) % len(vowels)]
        base_pitch = profile['pitch'] * [0.91, 1.05, .98, 1.14, .86, 1.02][index]
        phase = 0.0
        noise_low = 0.0
        tone_low = 0.0
        samples = []
        for n in range(round(rate*duration)):
            t = n/rate
            progress = t/duration
            pitch = base_pitch * (1.0 + .045*math.sin(2*math.pi*7*t))
            if character == 'RUE':
                pitch *= 1.20 - .35*progress + .08*math.sin(2*math.pi*21*t)
            elif character == 'AYUSH':
                pitch *= .97 + .07*math.sin(2*math.pi*33*t)
            else:
                pitch *= 1.02 - .07*progress
            phase += 2*math.pi*pitch/rate
            blend = max(0, min(1, (progress-.25)*1.8))
            current_formants = [a*(1-blend)+b*blend for a,b in zip(formants,next_formants)]
            if character == 'RUE': current_formants = [f*1.18 for f in current_formants]
            if character == 'AYUSH': current_formants = [f*.79 for f in current_formants]
            voiced = 0.0
            for harmonic in range(1, min(65, int(4700/pitch))):
                frequency = harmonic*pitch
                resonance = .045
                for center, bandwidth, gain in zip(current_formants, [100,160,210], [1.9,1.25,.55]):
                    resonance += gain*math.exp(-.5*((frequency-center)/bandwidth)**2)
                voiced += math.sin(harmonic*phase) * resonance / harmonic
            noise = rng.uniform(-1,1)
            noise_low += .33*(noise-noise_low)
            onset = math.exp(-t*95)
            envelope = math.sin(math.pi*progress)**.65
            if character == 'DOCTOR':
                tone_low += .38*(voiced-tone_low)
                signal = tone_low + noise_low*(.05+.28*onset)
                envelope *= 1.0-.25*progress
            elif character == 'RUE':
                pulse = .55+.45*math.sin(2*math.pi*11*t)**2
                signal = voiced*(.78+.22*math.sin(2*math.pi*47*t)) + .12*noise_low*onset
                envelope *= pulse
            else:
                signal = voiced + .10*math.sin(phase*.5) + .11*noise_low
                signal = math.tanh(signal*2.3)
                envelope *= .8+.2*math.sin(2*math.pi*29*t)
            samples.append(signal*envelope)
        if character == 'AYUSH': samples.reverse()
        highest = max(abs(x) for x in samples)
        pcm = []
        quantum = {'DOCTOR': 8, 'RUE': 32, 'AYUSH': 64}[character]
        for n, value in enumerate(samples):
            edge = min(1.0, n/(rate*.005), (len(samples)-1-n)/(rate*.009))
            signed = round((value/highest*.62*32767*edge)/quantum)*quantum
            pcm.append(signed)
        encoded = array.array('h',pcm).tobytes()
        stem = character.lower()+'_%02d' % (index+1)
        with wave.open(str(out/(stem+'.wav')),'wb') as wav:
            wav.setparams((1,2,rate,len(pcm),'NONE','not compressed'))
            wav.writeframes(encoded)
        # PCM .tres guarantees byte-accurate concatenation even if WAV import defaults
        # change to QOA/ADPCM. The WAV is retained for preview and editing.
        (out/(stem+'.tres')).write_text('[gd_resource type="AudioStreamWAV" format=3]\n\n[resource]\nformat = 1\nmix_rate = 24000\nstereo = false\ndata = PackedByteArray('+','.join(map(str,encoded))+')\n',encoding='utf-8')
        resources[character].append('res://audio/chatter/'+stem+'.tres')
        peak = max(abs(x) for x in pcm)/32768
        assert peak < .64 and not any(abs(x)>=32760 for x in pcm)
        records.append({'character':character,'wav':stem+'.wav','resource':stem+'.tres','duration':duration,'fundamental_hz':round(base_pitch,2),'peak_dbfs':round(20*math.log10(peak),2)})
        preview_pcm[character] += pcm + [0]*int(rate*(.035 if character=='RUE' else .065))
bank = 'extends RefCounted\n## Generated by tools/generate_character_chatter.py. Original PCM syllable palettes.\nconst STREAMS := {\n'
for character, paths in resources.items():
    bank += '\t"'+character+'": ['+','.join('preload("'+p+'")' for p in paths)+'],\n'
bank += '}\n'
(out/'chatter_bank.gd').write_text(bank,encoding='utf-8')
(out/'manifest.json').write_text(json.dumps({'generator':'tools/generate_character_chatter.py','sample_rate':rate,'origin':'Original mathematical formant synthesis; no source recording or imitation','profiles':profiles,'syllables':records},indent=2)+'\n',encoding='utf-8')
previews = out/'previews'
previews.mkdir(exist_ok=True)
(previews/'.gdignore').write_text('',encoding='utf-8')
for character,pcm in preview_pcm.items():
    with wave.open(str(previews/(character.lower()+'_palette.wav')),'wb') as wav:
        wav.setparams((1,2,rate,len(pcm),'NONE','not compressed'))
        wav.writeframes(array.array('h',pcm).tobytes())
print('Generated 18 distinct PCM syllables: Doctor 129–171Hz, Rue 335–445Hz, Ayush78–104Hz; all peaks below0.64; direct PCM resource bank +3preview palettes.')

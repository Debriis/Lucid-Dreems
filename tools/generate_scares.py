"""Original short, peak-capped procedural scare cues. No external audio source."""
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
rate = 24000
records = []
for kind, duration, peak in [('catch', 0.70, 0.78), ('glimpse', 0.30, 0.68)]:
    rng = random.Random(1481 if kind == 'catch' else 7381)
    samples = []
    low = 0.0
    slower = 0.0
    for n in range(round(rate * duration)):
        t = n / rate
        noise = round(rng.uniform(-1.0, 1.0) * 64.0) / 64.0
        low += 0.48 * (noise - low)
        slower += 0.075 * (noise - slower)
        grit = low - slower
        attack = min(1.0, t / 0.004)
        tail = min(1.0, (duration - t) / 0.06)
        if kind == 'catch':
            impact = math.sin(2 * math.pi * (92 * t - 31 * t*t)) * math.exp(-9*t)
            metal = sum(math.sin(2 * math.pi * (f*t - 190*t*t)) for f in [617, 923, 1327]) / 3
            signal = 0.45*impact + 0.30*metal*math.exp(-7*t) + 0.65*grit*math.exp(-5*t)
        else:
            tine = math.sin(2 * math.pi * (1360*t - 610*t*t))
            signal = (0.82*grit + 0.18*tine) * math.exp(-10*t)
        samples.append(signal * attack * tail)
    scale = peak / max(abs(x) for x in samples)
    pcm = array.array('h', [round(x * scale * 32767) for x in samples])
    path = root / 'audio' / ('scare_' + kind + '.wav')
    path.parent.mkdir(parents=True, exist_ok=True)
    with wave.open(str(path), 'wb') as output:
        output.setnchannels(1)
        output.setsampwidth(2)
        output.setframerate(rate)
        output.writeframes(pcm.tobytes())
    actual_peak = max(abs(x) for x in pcm) / 32768
    assert actual_peak < 0.8 and all(abs(x) < 32760 for x in pcm)
    records.append({'name': path.name, 'duration_seconds': duration, 'sample_rate': rate,
                    'channels': 1, 'peak_dbfs': round(20*math.log10(actual_peak), 2),
                    'source': 'Original deterministic sine/filtered-noise synthesis',
                    'generator': 'tools/generate_scares.py'})
(root / 'audio' / 'scare_manifest.json').write_text(json.dumps(records, indent=2) + '\n', encoding='utf-8')
print(json.dumps(records))

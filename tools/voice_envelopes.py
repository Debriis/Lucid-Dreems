"""Read PCM speech and append lightweight RMS envelopes for mouth animation."""
import array
import argparse
import json
import math
import wave
from pathlib import Path

parser = argparse.ArgumentParser()
parser.add_argument('--project-root', type=Path, default=Path(__file__).resolve().parents[1])
root = parser.parse_args().project_root
manifest_path = root / 'audio/voice/manifest.json'
data = json.loads(manifest_path.read_text(encoding='utf-8-sig'))
for row in data['lines']:
    with wave.open(str(root / row['path'].removeprefix('res://')), 'rb') as wav:
        assert wav.getnchannels() == 1 and wav.getsampwidth() == 2
        rate = wav.getframerate()
        frames = wav.getnframes()
        samples = array.array('h', wav.readframes(frames))
        hop = rate // 20
        rms = [math.sqrt(sum(v*v for v in samples[i:i+hop]) / len(samples[i:i+hop])) for i in range(0, len(samples), hop)]
        peak = max(rms, default=1)
        row['duration_seconds'] = round(frames / rate, 3)
        row['envelope_hz'] = 20
        row['envelope'] = [round(min(1.0, value / max(1.0, peak * 0.8)), 3) for value in rms]
        assert row['duration_seconds'] > 0.5 and peak > 100
manifest_path.write_text(json.dumps(data, indent=2) + '\n', encoding='utf-8')
stream_records = ',\n'.join('    ' + json.dumps(row['path']) + ': preload(' + json.dumps(row['path']) + ')' for row in data['lines'])
(manifest_path.parent / 'dialogue_bank.gd').write_text('extends RefCounted\n## Generated from manifest.json by tools/voice_envelopes.py.\nconst STREAMS := {\n' + stream_records + '\n}\nconst LINES := ' + json.dumps(data['lines'], ensure_ascii=False, separators=(',', ':')) + '\n', encoding='utf-8')
print(f"Validated {len(data['lines'])} mono 24kHz speech files; total {sum(r['duration_seconds'] for r in data['lines']):.1f} seconds")

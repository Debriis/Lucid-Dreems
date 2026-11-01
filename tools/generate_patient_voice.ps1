param([string]$ProjectRoot = (Split-Path -Parent $PSScriptRoot), [string]$StoryPath = '')
$ErrorActionPreference = 'Stop'
Add-Type -AssemblyName System.Speech
$voiceDir = Join-Path $ProjectRoot 'audio\voice'
$sourceDir = Join-Path $voiceDir 'source'
New-Item -ItemType Directory -Force -Path $voiceDir,$sourceDir | Out-Null
Set-Content -LiteralPath (Join-Path $sourceDir '.gdignore') -Value '' -Encoding ASCII
$lines = New-Object System.Collections.Generic.List[string]
if ([string]::IsNullOrEmpty($StoryPath)) { $StoryPath = Join-Path $ProjectRoot 'scripts\story.gd' }
foreach ($scriptSource in @($StoryPath, (Join-Path $ProjectRoot 'scripts\ending.gd'))) {
    $contents = Get-Content -LiteralPath $scriptSource -Raw -Encoding UTF8
    foreach ($match in [regex]::Matches($contents, '"(PATIENT(?: VOICE)?: (?:[^"\\]|\\.)*)"')) {
        $dialogue = $match.Groups[1].Value.Replace('\"', '"').Replace('\n', "`n").Replace('\t', "`t").Replace('\\', '\')
        if (-not $lines.Contains($dialogue)) { $lines.Add($dialogue) }
    }
}
$synth = New-Object System.Speech.Synthesis.SpeechSynthesizer
$synth.SelectVoice('Microsoft David Desktop')
$synth.Rate = -1
$synth.Volume = 100
$format = New-Object System.Speech.AudioFormat.SpeechAudioFormatInfo(24000, [System.Speech.AudioFormat.AudioBitsPerSample]::Sixteen, [System.Speech.AudioFormat.AudioChannel]::Mono)
$manifestLines = @()
$index = 0
try {
    foreach ($dialogue in $lines) {
        $index += 1
        $name = 'patient_{0:D2}.wav' -f $index
        $rawPath = Join-Path $sourceDir $name
        $finalPath = Join-Path $voiceDir $name
        $spoken = ($dialogue -replace '^PATIENT(?: VOICE)?:\s*', '')
        $synth.SetOutputToWaveFile($rawPath, $format)
        $synth.Speak($spoken)
        $synth.SetOutputToNull()
        # Lower pitch by four percent, retain understandable consonants, add very light 12-bit grain.
        & ffmpeg -hide_banner -loglevel error -y -i $rawPath -af 'asetrate=23040,aresample=24000,highpass=f=85,lowpass=f=4200,acrusher=bits=12:mix=0.08,alimiter=limit=0.85:level=false' -ac 1 -ar 24000 -c:a pcm_s16le $finalPath
        if ($LASTEXITCODE -ne 0) { throw "FFmpeg failed for $name" }
        $manifestLines += [ordered]@{ id = ('patient_{0:D2}' -f $index); dialogue = $dialogue; spoken_text = $spoken; path = ('res://audio/voice/' + $name) }
        Write-Output ('Generated {0}: {1}' -f $name, $spoken)
    }
} finally { $synth.Dispose() }
$manifest = [ordered]@{
    voice = 'Microsoft David Desktop'; engine = 'Windows System.Speech / SAPI'; language = 'en-US'; synthetic = $true; person_impersonated = $false;
    synthesis_rate = -1; sample_rate = 24000; channels = 1;
    processing = 'Pitch lowered 4%; high-pass 85Hz; low-pass 4200Hz; subtle 12-bit grain (8% mix); limiter at 0.85 with automatic makeup disabled (at least 1.4dB sample headroom)';
    lines = $manifestLines
}
$manifest | ConvertTo-Json -Depth 8 | Set-Content -LiteralPath (Join-Path $voiceDir 'manifest.json') -Encoding UTF8

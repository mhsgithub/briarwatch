# Builds an original short burn/sizzle cue. Development only; WAV is committed.
$ErrorActionPreference='Stop'
$rate=32000
$count=[int]($rate*0.42)
$random=[Random]::new(9127)
$samples=[double[]]::new($count)
$last=0.0
$peak=0.0
for($i=0;$i -lt $count;$i++) {
    $t=$i/$rate
    $noise=$random.NextDouble()*2-1
    $hiss=($noise-$last*0.88)*[Math]::Exp(-$t*7)*0.36
    $last=$noise
    $crackle=0.0
    foreach($onset in @(0.018,0.074,0.135,0.216)) {
        $since=$t-$onset
        if($since -ge 0 -and $since -lt 0.025) { $crackle+=$noise*[Math]::Exp(-$since*180)*0.55 }
    }
    $fade=[Math]::Min(1,$t/0.004)*[Math]::Min(1,(0.42-$t)/0.04)
    $samples[$i]=($hiss+$crackle)*$fade
    $peak=[Math]::Max($peak,[Math]::Abs($samples[$i]))
}
$path=Join-Path (Split-Path $PSScriptRoot -Parent) 'assets/audio/fire_hurt.wav'
$stream=[IO.File]::Create($path)
$writer=[IO.BinaryWriter]::new($stream)
try {
    $writer.Write([Text.Encoding]::ASCII.GetBytes('RIFF'))
    $writer.Write([int](36+$count*2))
    $writer.Write([Text.Encoding]::ASCII.GetBytes('WAVEfmt '))
    $writer.Write([int]16)
    $writer.Write([int16]1)
    $writer.Write([int16]1)
    $writer.Write([int]$rate)
    $writer.Write([int]($rate*2))
    $writer.Write([int16]2)
    $writer.Write([int16]16)
    $writer.Write([Text.Encoding]::ASCII.GetBytes('data'))
    $writer.Write([int]($count*2))
    foreach($sample in $samples) { $writer.Write([int16]($sample/$peak*24000)) }
} finally { $writer.Dispose(); $stream.Dispose() }

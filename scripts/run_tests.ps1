$ErrorActionPreference = 'Stop'
$root = Split-Path -Parent $PSScriptRoot
$build = Join-Path $root 'build\sim'
New-Item -ItemType Directory -Force -Path $build | Out-Null
$rasterOutput = Join-Path $build 'graphics_accelerator_tb.vvp'
$videoOutput = Join-Path $build 'video_pipeline_tb.vvp'
Remove-Item -LiteralPath $rasterOutput, $videoOutput -Force -ErrorAction SilentlyContinue

& iverilog -g2012 -s graphics_accelerator_tb `
    -o $rasterOutput `
    (Join-Path $root 'rtl\graphics_accelerator.sv') `
    (Join-Path $root 'sim\graphics_accelerator_tb.sv')
if (-not (Test-Path -LiteralPath $rasterOutput)) { throw 'Rasterizer compilation failed.' }
& vvp $rasterOutput
if ($LASTEXITCODE -ne 0) { throw 'Rasterizer test failed.' }

& iverilog -g2012 -s video_pipeline_tb `
    -o $videoOutput `
    (Join-Path $root 'rtl\video_timing_640x480.sv') `
    (Join-Path $root 'rtl\tmds_encoder.sv') `
    (Join-Path $root 'sim\video_pipeline_tb.sv')
if (-not (Test-Path -LiteralPath $videoOutput)) { throw 'Video pipeline compilation failed.' }
& vvp $videoOutput
if ($LASTEXITCODE -ne 0) { throw 'Video pipeline test failed.' }

Write-Host 'All SystemVerilog tests passed.' -ForegroundColor Green

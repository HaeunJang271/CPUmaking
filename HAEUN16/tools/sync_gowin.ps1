# HAEUN16 RTL -> Gowin HAEUN16_9K\src 동기화
# Usage: powershell -File tools\sync_gowin.ps1
#        powershell -File tools\sync_gowin.ps1 -GowinSrc "D:\path\to\HAEUN16_9K\src"

param(
    [string]$GowinSrc = "C:\Gowin\Gowin_V1.9.11.03_Education_x64\IDE\bin\Documents\HAEUN16_9K\src"
)

$Root = Split-Path -Parent $PSScriptRoot
$Files = @(
    "cpu.v",
    "alu.v",
    "pc.v",
    "register16.v",
    "ram_fpga.v",
    "uart_tx.v",
    "top_tangnano9k.v",
    "tangnano9k.cst",
    "tangnano9k.sdc"
)

if (-not (Test-Path $GowinSrc)) {
    Write-Error "Gowin src not found: $GowinSrc"
    exit 1
}

foreach ($f in $Files) {
    $src = Join-Path $Root $f
    if (-not (Test-Path $src)) {
        Write-Warning "Skip (missing): $f"
        continue
    }
    Copy-Item -Force $src (Join-Path $GowinSrc $f)
    Write-Host "Copied $f"
}

# .gprj 에 tangnano9k.sdc 가 없으면 TA1132 경고 발생
$Gprj = Join-Path (Split-Path $GowinSrc -Parent) "HAEUN16_9K.gprj"
if (Test-Path $Gprj) {
    $xml = Get-Content $Gprj -Raw
    if ($xml -notmatch 'tangnano9k\.sdc') {
        $xml = $xml -replace '(<File path="src/tangnano9k\.cst" type="file\.cst" enable="1"/>)', "`$1`n        <File path=`"src/tangnano9k.sdc`" type=`"file.sdc`" enable=`"1`"/>"
        Set-Content -Path $Gprj -Value $xml -NoNewline
        Write-Host "Added tangnano9k.sdc to HAEUN16_9K.gprj"
    }
}

Write-Host "Done. Gowin IDE: Process -> Reload All -> Synthesize -> Place & Route"

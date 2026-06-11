# HAEUN-16 SOC (CPU + HDMI) -> Gowin HAEUN16_SOC 프로젝트 동기화
# Usage: powershell -File tools\sync_soc_gowin.ps1

param(
    [string]$GowinRoot = "C:\Gowin\Gowin_V1.9.11.03_Education_x64\IDE\bin\Documents\HAEUN16_SOC",
    [switch]$ExtUart
)

$Root = Split-Path -Parent $PSScriptRoot
$HdmiSrc = Join-Path $Root "hdmi_colorbars\src"
$GowinSrc = Join-Path $GowinRoot "src"
$GprjSrc = Join-Path $Root "soc\HAEUN16_SOC.gprj"
$ImplSrc = Join-Path $Root "soc\impl"
$GowinImpl = Join-Path $GowinRoot "impl"

$CpuFiles = @(
    "cpu.v", "alu.v", "pc.v", "register16.v", "ram_fpga.v",
    "uart_tx.v", "uart_rx.v", "uart_fifo_tx.v", "uart_fifo_rx.v", "uart_path_bl702.v",
    "bl702_boot_delay.v",
    "top_haeun16_soc.v", "screen_ram.v", "screen_bridge.v", "screen_from_ram.v",
    "screen_char_fifo.v",
    "screen_status.v", "screen_io_tx.v"
)

if (-not (Test-Path $HdmiSrc)) {
    Write-Error "hdmi_colorbars\src not found"
    exit 1
}

New-Item -ItemType Directory -Force -Path $GowinSrc | Out-Null

foreach ($f in $CpuFiles) {
    $src = Join-Path $Root $f
    if (Test-Path $src) {
        Copy-Item -Force $src (Join-Path $GowinSrc $f)
        Write-Host "Copied $f"
    }
}

# svo_hdmi_soc.v `include 대상 — hdmi 트리에도 동기화
$RamMirror = Join-Path $Root "screen_from_ram.v"
$HdmiRamMirror = Join-Path $HdmiSrc "screen_from_ram.v"
if (Test-Path $RamMirror) {
    Copy-Item -Force $RamMirror $HdmiRamMirror
    Write-Host "Synced screen_from_ram.v -> hdmi_colorbars\src"
}

robocopy $HdmiSrc $GowinSrc /E /NFL /NDL /NJH /NJS /nc /ns /np | Out-Null
if ($LASTEXITCODE -ge 8) {
    Write-Error "robocopy hdmi src failed: $LASTEXITCODE"
    exit 1
}
Write-Host "Synced hdmi_colorbars\src -> $GowinSrc"

Copy-Item -Force (Join-Path $Root "soc\tangnano9k_soc.cst") (Join-Path $GowinSrc "tangnano9k_soc.cst")
Copy-Item -Force (Join-Path $Root "soc\tangnano9k_soc_ext_uart.cst") (Join-Path $GowinSrc "tangnano9k_soc_ext_uart.cst")
if ($ExtUart) {
    Copy-Item -Force (Join-Path $Root "soc\tangnano9k_soc_ext_uart.cst") (Join-Path $GowinSrc "tangnano9k_soc.cst")
    Write-Host "CST: tangnano9k_soc_ext_uart (pin 37/38) -> tangnano9k_soc.cst"
} else {
    Write-Host "CST: tangnano9k_soc (pin 17/18 onboard BL702)"
}

$GprjDst = Join-Path $GowinRoot "HAEUN16_SOC.gprj"
Copy-Item -Force $GprjSrc $GprjDst
Write-Host "Copied HAEUN16_SOC.gprj"

# os.asm -> ram_fpga (SOC 펌웨어)
$GenRam = Join-Path $Root "tools\gen_ram_os.py"
if (Test-Path $GenRam) {
    python $GenRam
}

# 구 합성 캐시 — FileList 에 없는 모듈이면 unknown module (EX3937)
$GwsynDir = Join-Path $GowinRoot "impl\gwsynthesis"
if (Test-Path $GwsynDir) {
    Remove-Item -Recurse -Force $GwsynDir
    Write-Host "Removed impl/gwsynthesis/ (stale HAEUN16_SOC.prj cache)"
}
$TempDir = Join-Path $GowinRoot "impl\temp"
if (Test-Path $TempDir) {
    Remove-Item -Recurse -Force $TempDir
    Write-Host "Removed impl/temp/"
}

if (Test-Path $ImplSrc) {
    New-Item -ItemType Directory -Force -Path $GowinImpl | Out-Null
    Copy-Item -Force (Join-Path $ImplSrc "HAEUN16_SOC_process_config.json") `
        (Join-Path $GowinImpl "HAEUN16_SOC_process_config.json")
    Write-Host "Copied impl/HAEUN16_SOC_process_config.json"
}

Write-Host ""
Write-Host "Gowin IDE:"
Write-Host "  1. Open $GowinRoot\HAEUN16_SOC.gprj"
Write-Host "  2. Project -> Reload All  (권장; screen_from_ram 은 svo_hdmi_soc `include 로도 포함됨)"
Write-Host "  3. Top module: top_haeun16_soc"
Write-Host "  4. Synthesize -> Place & Route -> Generate Bitstream -> Program"
Write-Host "  5. HDMI: HAEUN-OS v0.1 + 프롬프트 >  (UART 병행)"
if ($ExtUart) {
    Write-Host ""
    Write-Host "Ext UART: pin37->동글RX, pin38<-동글TX, GND. PC=동글 COM 115200"
    Write-Host "Guide: fpga\EXT_UART_KEYBOARD.md"
}

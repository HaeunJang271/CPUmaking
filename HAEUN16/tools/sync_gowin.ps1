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
    "uart_rx.v",
    "uart_fifo_tx.v",
    "uart_fifo_rx.v",
    "uart_path_bl702.v",
    "bl702_boot_delay.v",
    "uart_msg_tx.v",
    "top_tangnano9k.v",
    "top_uart_smoke.v",
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

# .gprj 에 누락 파일 자동 등록 (Hierarchy에 top이 안 뜨면 대부분 여기 문제)
$Gprj = Join-Path (Split-Path $GowinSrc -Parent) "HAEUN16_9K.gprj"
$GprjAdds = @(
    @{ Path = "src/tangnano9k.sdc";       Type = "file.sdc" },
    @{ Path = "src/uart_fifo_tx.v";       Type = "file.verilog" },
    @{ Path = "src/uart_rx.v";            Type = "file.verilog" },
    @{ Path = "src/uart_fifo_rx.v";       Type = "file.verilog" },
    @{ Path = "src/uart_path_bl702.v";    Type = "file.verilog" },
    @{ Path = "src/bl702_boot_delay.v";   Type = "file.verilog" },
    @{ Path = "src/uart_msg_tx.v";        Type = "file.verilog" },
    @{ Path = "src/top_uart_smoke.v";     Type = "file.verilog" }
)
if (Test-Path $Gprj) {
    $xml = Get-Content $Gprj -Raw
    foreach ($entry in $GprjAdds) {
        $escaped = [regex]::Escape($entry.Path)
        if ($xml -notmatch $escaped) {
            $line = "        <File path=`"$($entry.Path)`" type=`"$($entry.Type)`" enable=`"1`"/>`n"
            $xml = $xml -replace '(</FileList>)', "$line`$1"
            Write-Host "Added $($entry.Path) to HAEUN16_9K.gprj"
        }
    }
    Set-Content -Path $Gprj -Value $xml -NoNewline
}

Write-Host "Done. Gowin IDE: Process -> Reload All -> Synthesize -> Place & Route"

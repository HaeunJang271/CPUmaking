# HDMI 컬러바 RTL -> Gowin HAEUN16_HDMI 프로젝트 동기화
# Usage: powershell -File tools\sync_hdmi_gowin.ps1
#        powershell -File tools\sync_hdmi_gowin.ps1 -GowinRoot "D:\path\to\HAEUN16_HDMI"

param(
    [string]$GowinRoot = "C:\Gowin\Gowin_V1.9.11.03_Education_x64\IDE\bin\Documents\HAEUN16_HDMI"
)

$Root = Split-Path -Parent $PSScriptRoot
$SrcRepo = Join-Path $Root "hdmi_colorbars\src"
$GprjSrc = Join-Path $Root "hdmi_colorbars\HAEUN16_HDMI.gprj"
$ImplSrc = Join-Path $Root "hdmi_colorbars\impl"
$GowinSrc = Join-Path $GowinRoot "src"
$GowinImpl = Join-Path $GowinRoot "impl"

if (-not (Test-Path $SrcRepo)) {
    Write-Error "Repo hdmi_colorbars\src not found: $SrcRepo"
    exit 1
}

if (-not (Test-Path $GowinRoot)) {
    New-Item -ItemType Directory -Force -Path $GowinSrc | Out-Null
    Write-Host "Created $GowinRoot"
}

# src 전체 복사 (hdmi/, gowin_rpll/, gowin_clkdiv/ 포함)
robocopy $SrcRepo $GowinSrc /E /NFL /NDL /NJH /NJS /nc /ns /np | Out-Null
if ($LASTEXITCODE -ge 8) {
    Write-Error "robocopy failed: $LASTEXITCODE"
    exit 1
}
Write-Host "Synced src -> $GowinSrc"

$GprjDst = Join-Path $GowinRoot "HAEUN16_HDMI.gprj"
Copy-Item -Force $GprjSrc $GprjDst
Write-Host "Copied HAEUN16_HDMI.gprj"

# .gprj 정리: 구 파일 제거 + 누락 파일 자동 등록
# (합성기는 .gprj 가 아니라 impl/gwsynthesis/*.prj 캐시를 쓰는 경우가 많음)
$GprjAdds = @(
    @{ Path = "src/hdmi/svo_static_text.v"; Type = "file.verilog" },
    @{ Path = "src/hdmi/svo_utils.v";       Type = "file.verilog" },
    @{ Path = "src/svo_hdmi_text.v";        Type = "file.verilog" }
)
$GprjRemoves = @(
    "src/hdmi/svo_term.v",
    "src/svo_term_inject.v"
)
if (Test-Path $GprjDst) {
    $xml = Get-Content $GprjDst -Raw
    foreach ($old in $GprjRemoves) {
        $pat = '\s*<File path="' + [regex]::Escape($old) + '"[^>]*/>\s*'
        if ($xml -match [regex]::Escape($old)) {
            $xml = $xml -replace $pat, "`n"
            Write-Host "Removed $old from HAEUN16_HDMI.gprj"
        }
    }
    foreach ($entry in $GprjAdds) {
        $escaped = [regex]::Escape($entry.Path)
        if ($xml -notmatch $escaped) {
            $line = "        <File path=`"$($entry.Path)`" type=`"$($entry.Type)`" enable=`"1`"/>`n"
            $xml = $xml -replace '(</FileList>)', "$line`$1"
            Write-Host "Added $($entry.Path) to HAEUN16_HDMI.gprj"
        }
    }
    Set-Content -Path $GprjDst -Value $xml -NoNewline
}

# 구 합성 캐시 전부 제거 (옛 .prj 가 svo_term 기준이면 unknown module 발생)
$GwsynDir = Join-Path $GowinRoot "impl\gwsynthesis"
if (Test-Path $GwsynDir) {
    Remove-Item -Recurse -Force $GwsynDir
    Write-Host "Removed impl/gwsynthesis/ (stale HAEUN16_HDMI.prj cache)"
}
$TempDir = Join-Path $GowinRoot "impl\temp"
if (Test-Path $TempDir) {
    Remove-Item -Recurse -Force $TempDir
    Write-Host "Removed impl/temp/"
}

if (Test-Path $ImplSrc) {
    New-Item -ItemType Directory -Force -Path $GowinImpl | Out-Null
    Copy-Item -Force (Join-Path $ImplSrc "HAEUN16_HDMI_process_config.json") `
        (Join-Path $GowinImpl "HAEUN16_HDMI_process_config.json")
    $legacyCfg = Join-Path $GowinImpl "project_process_config.json"
    if (Test-Path $legacyCfg) { Remove-Item -Force $legacyCfg }
    Write-Host "Copied impl/HAEUN16_HDMI_process_config.json (TopModule=top_hdmi_colorbars)"
}

Write-Host ""
Write-Host "Gowin IDE:"
Write-Host "  1. Open $GowinRoot\HAEUN16_HDMI.gprj"
Write-Host "  2. Project -> Reload All  (필수: FileList 갱신)"
Write-Host "  3. Top module: top_hdmi_colorbars"
Write-Host "  4. Process -> Synthesize -> Place & Route -> Generate Bitstream"
Write-Host "  5. Program Device (HDMI 케이블 연결 후 모니터 확인)"

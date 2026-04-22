# ============================================================
# Korean Legal Harness — Windows 설치 스크립트 (PowerShell)
# ============================================================
# 사용법: powershell -ExecutionPolicy Bypass -File install.ps1
# ============================================================

param(
    [string]$WorkspaceDir = "",   # 법무 사건 워크스페이스 경로 (기본: ~/Documents/법무사건)
    [string]$HooksDir    = "",    # 훅 파일 설치 경로 (기본: ~/korean-legal-harness-hooks)
    [switch]$Global              # 전역(~/.claude) 설치 여부. 기본: 프로젝트 .claude/
)

$ErrorActionPreference = "Stop"
$RepoRoot = $PSScriptRoot

Write-Host ""
Write-Host "============================================================" -ForegroundColor Cyan
Write-Host " Korean Legal Harness — 법무법인 Claude Code 하네스 설치" -ForegroundColor Cyan
Write-Host "============================================================" -ForegroundColor Cyan
Write-Host ""

# ── 1. 경로 결정 ──────────────────────────────────────────────

if (-not $WorkspaceDir) {
    $default = Join-Path $HOME "Documents\법무사건"
    $input_val = Read-Host "법무 워크스페이스 경로 (Enter = $default)"
    $WorkspaceDir = if ($input_val) { $input_val } else { $default }
}

if (-not $HooksDir) {
    $default2 = Join-Path $HOME "korean-legal-harness-hooks"
    $input_val2 = Read-Host "훅 설치 경로 (Enter = $default2)"
    $HooksDir = if ($input_val2) { $input_val2 } else { $default2 }
}

# 에이전트·커맨드 대상 결정
if ($Global) {
    $ClaudeDir = Join-Path $HOME ".claude"
} else {
    Write-Host "현재 디렉토리: $(Get-Location)"
    $useGlobal = Read-Host "전역 설치(~/.claude)? [y/N]"
    if ($useGlobal -match "^[yY]") {
        $ClaudeDir = Join-Path $HOME ".claude"
    } else {
        $ClaudeDir = Join-Path (Get-Location) ".claude"
    }
}

$AgentsDir   = Join-Path $ClaudeDir "agents"
$CommandsDir = Join-Path $ClaudeDir "commands"
$SettingsFile = Join-Path $ClaudeDir "settings.json"

Write-Host ""
Write-Host "설치 경로 요약:" -ForegroundColor Yellow
Write-Host "  에이전트   : $AgentsDir"
Write-Host "  커맨드     : $CommandsDir"
Write-Host "  훅         : $HooksDir"
Write-Host "  워크스페이스: $WorkspaceDir"
Write-Host "  settings   : $SettingsFile"
Write-Host ""
$confirm = Read-Host "위 경로로 설치하시겠습니까? [Y/n]"
if ($confirm -match "^[nN]") { Write-Host "설치 취소."; exit 0 }

# ── 2. 디렉토리 생성 ──────────────────────────────────────────

foreach ($d in @($AgentsDir, $CommandsDir, $HooksDir, $WorkspaceDir)) {
    New-Item -ItemType Directory -Force -Path $d | Out-Null
}

# 워크스페이스 하위 구조
foreach ($sub in @("사건", "자문", "서식")) {
    New-Item -ItemType Directory -Force -Path (Join-Path $WorkspaceDir $sub) | Out-Null
}

# ── 3. 에이전트 복사 ──────────────────────────────────────────

Write-Host "[1/5] 에이전트 설치 중..." -ForegroundColor Green
Copy-Item "$RepoRoot\agents\*.md" $AgentsDir -Force
Write-Host "      완료: $((Get-ChildItem $AgentsDir -Filter *.md).Count)개 에이전트"

# ── 4. 커맨드 복사 ────────────────────────────────────────────

Write-Host "[2/5] 슬래시 커맨드 설치 중..." -ForegroundColor Green
Copy-Item "$RepoRoot\commands\*.md" $CommandsDir -Force
Write-Host "      완료: $((Get-ChildItem $CommandsDir -Filter *.md).Count)개 커맨드"

# ── 5. 훅 복사 ────────────────────────────────────────────────

Write-Host "[3/5] 훅 설치 중..." -ForegroundColor Green
Copy-Item "$RepoRoot\hooks\*.py" $HooksDir -Force
Write-Host "      완료: $((Get-ChildItem $HooksDir -Filter *.py).Count)개 훅"

# ── 6. 워크스페이스 문서 복사 ─────────────────────────────────

Write-Host "[4/5] 가이드 문서 복사 중..." -ForegroundColor Green
$docsOut = Join-Path $WorkspaceDir "docs"
New-Item -ItemType Directory -Force -Path $docsOut | Out-Null
Copy-Item "$RepoRoot\docs\*.md" $docsOut -Force
Copy-Item "$RepoRoot\workspace\사건-템플릿" (Join-Path $WorkspaceDir "사건-템플릿") -Recurse -Force
Write-Host "      완료"

# ── 7. settings.json 훅 등록 ──────────────────────────────────

Write-Host "[5/5] settings.json 훅 등록 중..." -ForegroundColor Green

# Python 실행 명령 결정
$pyCmd = if (Get-Command "python3" -ErrorAction SilentlyContinue) { "python3" }
         elseif (Get-Command "python" -ErrorAction SilentlyContinue) { "python" }
         elseif (Get-Command "py" -ErrorAction SilentlyContinue) { "py" }
         else { "python3" }

$hookEntries = @(
    @{ type = "command"; command = "$pyCmd `"$HooksDir\legal_citation_nudge.py`"" },
    @{ type = "command"; command = "$pyCmd `"$HooksDir\legal_pii_guard.py`"" },
    @{ type = "command"; command = "$pyCmd `"$HooksDir\legal_case_folder_init.py`"" }
)

$postToolUseHook = @{
    matcher = "Write|Edit|MultiEdit"
    hooks   = $hookEntries
}

if (Test-Path $SettingsFile) {
    $settings = Get-Content $SettingsFile -Raw | ConvertFrom-Json
} else {
    New-Item -ItemType Directory -Force -Path $ClaudeDir | Out-Null
    $settings = [PSCustomObject]@{}
}

if (-not $settings.PSObject.Properties["hooks"]) {
    $settings | Add-Member -MemberType NoteProperty -Name "hooks" -Value ([PSCustomObject]@{})
}
if (-not $settings.hooks.PSObject.Properties["PostToolUse"]) {
    $settings.hooks | Add-Member -MemberType NoteProperty -Name "PostToolUse" -Value @()
}

# 기존 법무 훅이 없으면 추가
$alreadyExists = $settings.hooks.PostToolUse | Where-Object {
    $_.hooks | Where-Object { $_.command -like "*legal_citation_nudge*" }
}
if (-not $alreadyExists) {
    $settings.hooks.PostToolUse += $postToolUseHook
    $settings | ConvertTo-Json -Depth 10 | Set-Content $SettingsFile -Encoding utf8
    Write-Host "      훅 3종 등록 완료"
} else {
    Write-Host "      이미 등록되어 있습니다. 건너뜁니다."
}

# ── 8. 환경변수 안내 ──────────────────────────────────────────

$wsRelPath = "notes/법무"
Write-Host ""
Write-Host "============================================================" -ForegroundColor Cyan
Write-Host " 설치 완료!" -ForegroundColor Green
Write-Host "============================================================" -ForegroundColor Cyan
Write-Host ""
Write-Host "다음 단계:" -ForegroundColor Yellow
Write-Host ""
Write-Host "1. Claude Code를 재시작하여 커맨드·에이전트를 로드하세요."
Write-Host ""
Write-Host "2. 워크스페이스 경로를 Claude Code 프로젝트로 열거나"
Write-Host "   settings.json env 에 추가하세요:"
Write-Host ""
Write-Host '   "env": { "LEGAL_WORKSPACE_DIR": "notes/법무" }' -ForegroundColor DarkGray
Write-Host "   (또는 실제 워크스페이스의 상대경로로 맞게 설정)"
Write-Host ""
Write-Host "3. 첫 실행 테스트:"
Write-Host "   /사건생성 2026가단12345 홍길동v김철수"
Write-Host "   /리서치 계약해제 후 손해배상 범위"
Write-Host ""
Write-Host "필수 플러그인 (Claude Code 설정에서 활성화):"
Write-Host "   korean-law  →  https://github.com/chrisryugj/korean-law-mcp" -ForegroundColor DarkGray
Write-Host ""

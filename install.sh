#!/usr/bin/env bash
# ============================================================
# Korean Legal Harness — macOS / Linux 설치 스크립트
# ============================================================
# 사용법: bash install.sh
# ============================================================

set -euo pipefail

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
GREEN='\033[0;32m'; CYAN='\033[0;36m'; YELLOW='\033[1;33m'; NC='\033[0m'

echo ""
echo -e "${CYAN}============================================================${NC}"
echo -e "${CYAN} Korean Legal Harness — 법무법인 Claude Code 하네스 설치${NC}"
echo -e "${CYAN}============================================================${NC}"
echo ""

# ── 1. 경로 결정 ──────────────────────────────────────────────

DEFAULT_WORKSPACE="$HOME/Documents/법무사건"
read -rp "법무 워크스페이스 경로 [Enter = $DEFAULT_WORKSPACE]: " WORKSPACE_DIR
WORKSPACE_DIR="${WORKSPACE_DIR:-$DEFAULT_WORKSPACE}"

DEFAULT_HOOKS="$HOME/korean-legal-harness-hooks"
read -rp "훅 설치 경로 [Enter = $DEFAULT_HOOKS]: " HOOKS_DIR
HOOKS_DIR="${HOOKS_DIR:-$DEFAULT_HOOKS}"

read -rp "전역 설치(~/.claude)? [y/N]: " USE_GLOBAL
if [[ "$USE_GLOBAL" =~ ^[yY]$ ]]; then
    CLAUDE_DIR="$HOME/.claude"
else
    CLAUDE_DIR="$(pwd)/.claude"
fi

AGENTS_DIR="$CLAUDE_DIR/agents"
COMMANDS_DIR="$CLAUDE_DIR/commands"
SETTINGS_FILE="$CLAUDE_DIR/settings.json"

echo ""
echo -e "${YELLOW}설치 경로 요약:${NC}"
echo "  에이전트    : $AGENTS_DIR"
echo "  커맨드      : $COMMANDS_DIR"
echo "  훅          : $HOOKS_DIR"
echo "  워크스페이스: $WORKSPACE_DIR"
echo "  settings    : $SETTINGS_FILE"
echo ""
read -rp "위 경로로 설치하시겠습니까? [Y/n]: " CONFIRM
if [[ "$CONFIRM" =~ ^[nN]$ ]]; then echo "설치 취소."; exit 0; fi

# ── 2. 디렉토리 생성 ──────────────────────────────────────────

mkdir -p "$AGENTS_DIR" "$COMMANDS_DIR" "$HOOKS_DIR"
mkdir -p "$WORKSPACE_DIR/사건" "$WORKSPACE_DIR/자문" "$WORKSPACE_DIR/서식"

# ── 3. 에이전트 복사 ──────────────────────────────────────────

echo -e "${GREEN}[1/5] 에이전트 설치 중...${NC}"
cp "$REPO_ROOT/agents/"*.md "$AGENTS_DIR/"
echo "      완료: $(ls "$AGENTS_DIR"/*.md 2>/dev/null | wc -l | tr -d ' ')개 에이전트"

# ── 4. 커맨드 복사 ────────────────────────────────────────────

echo -e "${GREEN}[2/5] 슬래시 커맨드 설치 중...${NC}"
cp "$REPO_ROOT/commands/"*.md "$COMMANDS_DIR/"
echo "      완료: $(ls "$COMMANDS_DIR"/*.md 2>/dev/null | wc -l | tr -d ' ')개 커맨드"

# ── 5. 훅 복사 ────────────────────────────────────────────────

echo -e "${GREEN}[3/5] 훅 설치 중...${NC}"
cp "$REPO_ROOT/hooks/"*.py "$HOOKS_DIR/"
chmod +x "$HOOKS_DIR/"*.py
echo "      완료: $(ls "$HOOKS_DIR"/*.py 2>/dev/null | wc -l | tr -d ' ')개 훅"

# ── 6. 워크스페이스 문서 복사 ─────────────────────────────────

echo -e "${GREEN}[4/5] 가이드 문서 복사 중...${NC}"
mkdir -p "$WORKSPACE_DIR/docs"
cp "$REPO_ROOT/docs/"*.md "$WORKSPACE_DIR/docs/"
cp -r "$REPO_ROOT/workspace/사건-템플릿" "$WORKSPACE_DIR/"
echo "      완료"

# ── 7. settings.json 훅 등록 ──────────────────────────────────

echo -e "${GREEN}[5/5] settings.json 훅 등록 중...${NC}"
mkdir -p "$CLAUDE_DIR"

# Python 명령 탐색
PY_CMD="python3"
if ! command -v python3 &>/dev/null; then
    if command -v python &>/dev/null; then PY_CMD="python"; fi
fi

HOOK_SNIPPET=$(cat <<EOF
{
  "type": "command",
  "command": "$PY_CMD \"$HOOKS_DIR/legal_citation_nudge.py\""
}
EOF
)

# settings.json이 없으면 생성
if [ ! -f "$SETTINGS_FILE" ]; then
    echo '{"hooks":{"PostToolUse":[]}}' > "$SETTINGS_FILE"
fi

# 이미 등록된 경우 스킵 (grep으로 간단 체크)
if grep -q "legal_citation_nudge" "$SETTINGS_FILE" 2>/dev/null; then
    echo "      이미 등록되어 있습니다. 건너뜁니다."
else
    # Python으로 JSON merge
    "$PY_CMD" - <<PYEOF
import json, sys

sf = "$SETTINGS_FILE"
hooks_dir = "$HOOKS_DIR"
py_cmd = "$PY_CMD"

with open(sf, encoding="utf-8") as f:
    data = json.load(f)

data.setdefault("hooks", {}).setdefault("PostToolUse", [])

new_entry = {
    "matcher": "Write|Edit|MultiEdit",
    "hooks": [
        {"type": "command", "command": f'{py_cmd} "{hooks_dir}/legal_citation_nudge.py"'},
        {"type": "command", "command": f'{py_cmd} "{hooks_dir}/legal_pii_guard.py"'},
        {"type": "command", "command": f'{py_cmd} "{hooks_dir}/legal_case_folder_init.py"'},
    ]
}
data["hooks"]["PostToolUse"].append(new_entry)

with open(sf, "w", encoding="utf-8") as f:
    json.dump(data, f, ensure_ascii=False, indent=2)
print("      훅 3종 등록 완료")
PYEOF
fi

# ── 8. 완료 안내 ──────────────────────────────────────────────

echo ""
echo -e "${CYAN}============================================================${NC}"
echo -e "${GREEN} 설치 완료!${NC}"
echo -e "${CYAN}============================================================${NC}"
echo ""
echo -e "${YELLOW}다음 단계:${NC}"
echo ""
echo "1. Claude Code를 재시작하여 커맨드·에이전트를 로드하세요."
echo ""
echo "2. settings.json env 에 워크스페이스 경로를 추가하세요:"
echo '   "env": { "LEGAL_WORKSPACE_DIR": "notes/법무" }'
echo ""
echo "3. 첫 실행 테스트:"
echo "   /사건생성 2026가단12345 홍길동v김철수"
echo "   /리서치 계약해제 후 손해배상 범위"
echo ""
echo "필수 플러그인 (Claude Code 설정에서 활성화):"
echo "   korean-law  →  https://github.com/chrisryugj/korean-law-mcp"
echo ""

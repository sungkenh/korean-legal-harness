#!/usr/bin/env python3
"""
PostToolUse hook — 법무 서면 파일 저장 시 인용 검증을 권유한다.

환경변수 LEGAL_WORKSPACE_DIR 로 법무 폴더 이름을 커스터마이징 가능.
기본값: "notes/법무" (Claude Code 프로젝트 기준 상대경로)

Write/Edit/MultiEdit tool_input에서 file_path를 읽어 서면/자문 폴더의
콘텐츠 파일이면 /인용검증 실행을 상기시킨다.
"""
import json
import os
import re
import sys

try:
    sys.stdin.reconfigure(encoding="utf-8")
    sys.stdout.reconfigure(encoding="utf-8")
except Exception:
    pass

# 환경변수로 커스터마이징 가능
WORKSPACE = os.environ.get("LEGAL_WORKSPACE_DIR", "notes/법무").replace("\\", "/")


def main() -> int:
    try:
        payload = json.load(sys.stdin)
    except Exception:
        return 0

    tool_input = payload.get("tool_input", {}) or {}
    file_path = tool_input.get("file_path") or ""
    if not file_path:
        return 0

    norm = file_path.replace("\\", "/")

    # 법무 워크스페이스 범위
    if WORKSPACE not in norm:
        return 0

    # 제외: 가이드·메타·설정
    excluded = (
        "CLAUDE.md", "/docs/", "/.claude/",
        "/사건개요.md", "/관련법령.md", "/증거목록.md", "/일정.md", "/통신/",
    )
    if any(e in norm for e in excluded):
        return 0

    # 콘텐츠 확장자만
    if not re.search(r"\.(md|html?|txt|docx)$", norm, re.IGNORECASE):
        return 0

    # 서면·자문 폴더만
    if not any(m in norm for m in ("/서면/", "/자문/")):
        return 0

    basename = os.path.basename(norm)
    print(
        f"[법무 하네스] `{basename}` 저장 감지.\n"
        f"제출 전 `/인용검증 {file_path}` 실행을 권장합니다."
    )
    return 0


if __name__ == "__main__":
    sys.exit(main())

#!/usr/bin/env python3
"""
PostToolUse hook — 사건 폴더 하위에 파일이 생성됐는데 사건개요.md가 없거나 미완성이면 경고.

환경변수 LEGAL_WORKSPACE_DIR 로 법무 폴더 이름 커스터마이징 가능.
기본값: "notes/법무"
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

WORKSPACE = os.environ.get("LEGAL_WORKSPACE_DIR", "notes/법무").replace("\\", "/")
CASE_DIR = os.environ.get("LEGAL_CASE_SUBDIR", "사건")


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
    pattern = rf"(.+/{re.escape(WORKSPACE)}/{re.escape(CASE_DIR)}/[^/]+)/"
    m = re.search(pattern, norm)
    if not m:
        return 0

    case_root = m.group(1)
    if norm.endswith("/사건개요.md"):
        return 0

    overview = case_root + "/사건개요.md"
    try:
        if not os.path.exists(overview):
            print(
                f"[법무 하네스] 사건 폴더 `{os.path.basename(case_root)}`에 사건개요.md가 없습니다. "
                f"`/사건생성` 커맨드로 템플릿을 먼저 생성하세요."
            )
            return 0

        with open(overview, encoding="utf-8") as f:
            body = f.read()

        stubs = ["{사건번호}", "원고/신청인: \n", "피고/피신청인: \n"]
        if any(s in body for s in stubs):
            print(
                f"[법무 하네스] `사건개요.md`가 템플릿 상태입니다. "
                f"당사자·청구취지·사실관계를 채워야 에이전트가 정확히 동작합니다."
            )
    except Exception:
        return 0

    return 0


if __name__ == "__main__":
    sys.exit(main())

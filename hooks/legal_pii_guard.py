#!/usr/bin/env python3
"""
PostToolUse hook — 법무 문서 저장 시 주민등록번호·연락처·계좌번호 패턴 탐지 경고.

환경변수 LEGAL_WORKSPACE_DIR 로 법무 폴더 이름 커스터마이징 가능.
기본값: "notes/법무"

저장을 막지 않고 Claude 컨텍스트에 마스킹 권유 메시지를 주입한다.
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

PATTERNS = {
    "주민등록번호": re.compile(r"\b\d{6}\s*-\s*[1-4]\d{6}\b"),
    "휴대폰번호":   re.compile(r"\b01[016789]\s*-?\s*\d{3,4}\s*-?\s*\d{4}\b"),
    "유선전화":     re.compile(r"\b0(2|3[1-3]|4[1-4]|5[1-5]|6[1-4])\s*-?\s*\d{3,4}\s*-?\s*\d{4}\b"),
    "계좌번호":     re.compile(r"\b\d{3,6}-\d{2,6}-\d{3,8}\b"),
}


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
    if WORKSPACE not in norm:
        return 0
    if not re.search(r"\.(md|html?|txt)$", norm, re.IGNORECASE):
        return 0

    content = (
        tool_input.get("content")
        or tool_input.get("new_string")
        or "\n".join((e.get("new_string") or "") for e in (tool_input.get("edits") or []))
    )
    if not content:
        return 0

    hits = []
    for name, pat in PATTERNS.items():
        matches = pat.findall(content)
        if matches:
            s = matches[0]
            masked = s[:3] + "*" * max(1, len(s) - 5) + s[-2:]
            hits.append(f"  - {name}: {len(matches)}건 (예: {masked})")

    if not hits:
        return 0

    print(
        f"[법무 하네스 PII 경고] `{os.path.basename(norm)}`에 개인정보 패턴 감지:\n"
        + "\n".join(hits)
        + "\n마스킹(******) 또는 별지 처리를 검토해 주세요."
    )
    return 0


if __name__ == "__main__":
    sys.exit(main())

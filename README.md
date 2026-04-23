# Korean Legal Harness

대한민국 법무법인·변호사를 위한 **Claude Code 하네스**입니다.   
`korean-law-mcp`를 통해 법제처·대법원 데이터에 직접 연결합니다.

---

## 주요 기능

| 기능 | 슬래시 커맨드 | 담당 에이전트 |
|---|---|---|
| 법령·판례 풀 리서치 | `/리서치 <쟁점>` | `legal-researcher-kr` |
| 서면 롱폼 초안 (A4 30매) | `/초안 <유형> <사건>` | `legal-longform-drafter` |
| 문서 요약 | `/요약 <파일>` | `legal-summarizer-kr` |
| 단일 문서 Q&A | `/문서질문 <파일> <질문>` | `document-qa-agent` |
| 사건 폴더 통합 Q&A | `/사건질문 <폴더> <질문>` | `case-folder-qa-agent` |
| 계약서 리스크 감사 | `/계약검토 <파일>` | `contract-reviewer-kr` |
| 반성문·탄원서 작성 | `/반성문 <사건>` | `apology-writer-kr` |
| 판례·법령 인용 검증 | `/인용검증 <파일>` | `citation-checker-kr` |
| 사건 폴더 생성 | `/사건생성 <사건번호> <당사자>` | — |

**자동 훅 3종**
- 서면 저장 시 인용 검증 권유 (`legal_citation_nudge.py`)
- 개인정보 패턴(주민번호·연락처·계좌) 경고 (`legal_pii_guard.py`)
- 사건개요.md 미완성 경고 (`legal_case_folder_init.py`)

---

## 사전 요구사항

| 항목 | 버전 |
|---|---|
| [Claude Code](https://claude.ai/code) | 최신 |
| Python | 3.8 이상 |
| [korean-law-mcp 플러그인](https://github.com/chrisryugj/korean-law-mcp) | 필수 |

### korean-law-mcp 활성화 방법

1. Claude Code → Settings → Plugins
2. `korean-law` 검색 후 Enable
3. 또는 `settings.json`에 직접 추가:
```json
{
  "enabledPlugins": {
    "korean-law@korean-law-marketplace": true
  },
  "extraKnownMarketplaces": {
    "korean-law-marketplace": {
      "source": {
        "source": "github",
        "repo": "chrisryugj/korean-law-mcp"
      }
    }
  }
}
```

---

## 설치

### Windows (PowerShell)

```powershell
git clone https://github.com/sungkenh/korean-legal-harness.git
cd korean-legal-harness
powershell -ExecutionPolicy Bypass -File install.ps1
```

### macOS / Linux

```bash
git clone https://github.com/sungkenh/korean-legal-harness.git
cd korean-legal-harness
bash install.sh
```

설치 스크립트가 대화형으로 아래를 처리합니다:
1. 워크스페이스 경로 선택 (사건 파일 저장 위치)
2. 훅 설치 경로 선택
3. 전역(`~/.claude`) vs 프로젝트(`.claude/`) 설치 선택
4. 에이전트 9종, 커맨드 8종 자동 복사
5. `settings.json`에 훅 3종 자동 등록

---

## 설치 후 설정

`~/.claude/settings.json` 또는 프로젝트 `.claude/settings.json`에 워크스페이스 경로 추가:

```json
{
  "env": {
    "LEGAL_WORKSPACE_DIR": "notes/법무"
  }
}
```

> `LEGAL_WORKSPACE_DIR`은 Claude Code 프로젝트 루트 기준 상대경로입니다.  
> 예: `notes/법무`, `workspace/법무`, `법무사건` 등 자유롭게 설정 가능.

---

## Claude Code 재시작

설치 후 반드시 **Claude Code를 재시작**해야 슬래시 커맨드와 에이전트가 로드됩니다.

재시작 후 `/`를 입력하면 아래 커맨드가 자동완성됩니다:

```
/사건생성   /리서치   /초안   /요약
/문서질문   /사건질문  /계약검토  /반성문  /인용검증
```

---

## 사건 폴더 구조 (사건 기반 대화)

```
{LEGAL_WORKSPACE_DIR}/
└── 사건/
    └── {사건번호}-{당사자}/
        ├── 사건개요.md      ← 필수 (에이전트 동작 기준)
        ├── 관련법령.md      ← /리서치 결과 누적
        ├── 증거목록.md
        ├── 일정.md
        ├── 서면/           ← /초안 결과물
        ├── 자료/           ← PDF·DOCX 원본
        └── 통신/           ← 의뢰인 연락 기록
```

### 빠른 시작

```
/사건생성 2026가단12345 홍길동v김철수
```
→ 폴더 + 템플릿 파일 자동 생성

```
/리서치 계약해제 후 이행이익 손해배상 범위
```
→ 법령·판례 수집 후 `관련법령.md`에 저장

```
/초안 답변서 2026가단12345
```
→ 사건 폴더 자료 종합 → 개요 제시 → 승인 → 본문 작성

```
/사건질문 notes/법무/사건/2026가단12345-홍길동v김철수 계약 해제 통지 날짜는?
```
→ 폴더 전체 파일을 참조해 답변

---

## 파일 구조

```
korean-legal-harness/
├── agents/                 # Claude Code 에이전트 9종
│   ├── legal-researcher-kr.md
│   ├── legal-longform-drafter.md
│   ├── legal-summarizer-kr.md
│   ├── document-qa-agent.md
│   ├── case-folder-qa-agent.md
│   ├── contract-reviewer-kr.md
│   ├── apology-writer-kr.md
│   ├── citation-checker-kr.md
│   └── legal-editor-kr.md
├── commands/               # 슬래시 커맨드 8종
│   ├── 사건생성.md
│   ├── 리서치.md
│   ├── 초안.md
│   ├── 요약.md
│   ├── 문서질문.md
│   ├── 사건질문.md
│   ├── 계약검토.md
│   ├── 반성문.md
│   └── 인용검증.md
├── hooks/                  # PostToolUse 훅 3종
│   ├── legal_citation_nudge.py
│   ├── legal_pii_guard.py
│   └── legal_case_folder_init.py
├── docs/                   # 가이드 문서 7종
│   ├── CLAUDE.md
│   ├── 법령-판례-리서치-가이드.md
│   ├── 서면-작성-스타일.md
│   ├── 반성문-탄원서-가이드.md
│   ├── 계약서-검토-체크리스트.md
│   ├── 인용-형식-규칙.md
│   ├── 의뢰인-보고서-양식.md
│   └── 사건-폴더-운영가이드.md
├── workspace/              # 사건 폴더 템플릿
│   └── 사건-템플릿/
│       ├── 사건개요.md
│       ├── 관련법령.md
│       ├── 증거목록.md
│       └── 일정.md
├── settings-template/
│   └── hooks-snippet.json  # settings.json 훅 설정 예시
├── install.ps1             # Windows 설치 스크립트
├── install.sh              # macOS/Linux 설치 스크립트
└── .gitignore
```

---

## 면책 사항

- AI가 생성한 서면·자문은 반드시 **담당 변호사가 검토·서명** 후 제출해야 합니다.
- 본 도구는 법률자문이 아닙니다.
- 판례·법령 인용은 `verify_citations` MCP 도구로 자동 검증되나, **최종 정확성은 변호사가 확인**해야 합니다.
- 실제 사건 자료(PDF, 계약서 등)는 `.gitignore`에 포함되어 있으며 절대 커밋하지 마세요.

---

## 기여

PR·Issue 환영합니다.  
새 서면 유형, 추가 에이전트, 버그 수정 모두 기여해 주세요.

## 라이선스

MIT License

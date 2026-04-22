# Korean Legal Harness

A **Claude Code harness** for Korean law firms and attorneys.  
Designed around [SuperLawyer's](https://superlawyer.co.kr) five core functions,  
with direct integration to Korean statute and case law databases via `korean-law-mcp`.

---

## Features

| Feature | Slash Command | Agent |
|---|---|---|
| Full statute + case law research | `/리서치 <issue>` | `legal-researcher-kr` |
| Long-form brief drafting (30+ pages) | `/초안 <type> <case>` | `legal-longform-drafter` |
| Document summarization | `/요약 <file>` | `legal-summarizer-kr` |
| Single-document Q&A | `/문서질문 <file> <question>` | `document-qa-agent` |
| Case-folder RAG Q&A | `/사건질문 <folder> <question>` | `case-folder-qa-agent` |
| Contract risk audit | `/계약검토 <file>` | `contract-reviewer-kr` |
| Letter of apology / petition | `/반성문 <case>` | `apology-writer-kr` |
| Citation verification | `/인용검증 <file>` | `citation-checker-kr` |
| Case folder creation | `/사건생성 <case#> <parties>` | — |

**3 auto-hooks**
- Citation check nudge on brief save (`legal_citation_nudge.py`)
- PII detection (SSN, phone, bank account) (`legal_pii_guard.py`)
- Case summary completeness check (`legal_case_folder_init.py`)

---

## Requirements

| Item | Version |
|---|---|
| [Claude Code](https://claude.ai/code) | Latest |
| Python | 3.8+ |
| [korean-law-mcp plugin](https://github.com/chrisryugj/korean-law-mcp) | Required |

---

## Installation

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

The interactive installer will:
1. Ask for your workspace path (where case files will live)
2. Ask for hook installation path
3. Choose global (`~/.claude`) vs project-level (`.claude/`) install
4. Copy 9 agents, 8 commands automatically
5. Register 3 hooks in `settings.json`

---

## Post-install Configuration

Add to `~/.claude/settings.json` or your project `.claude/settings.json`:

```json
{
  "env": {
    "LEGAL_WORKSPACE_DIR": "notes/법무"
  }
}
```

> `LEGAL_WORKSPACE_DIR` is a path relative to your Claude Code project root.

**Restart Claude Code** after installation to load commands and agents.

---

## Case Folder Structure

```
{LEGAL_WORKSPACE_DIR}/
└── 사건/
    └── {case#}-{parties}/
        ├── 사건개요.md      ← Required (agents use this as context)
        ├── 관련법령.md      ← Research results accumulate here
        ├── 증거목록.md      ← Evidence list
        ├── 일정.md          ← Deadlines / hearing dates
        ├── 서면/            ← Drafted briefs
        ├── 자료/            ← Source PDFs / DOCX
        └── 통신/            ← Client communications
```

---

## Disclaimer

- AI-generated briefs and opinions must be **reviewed and signed by a licensed attorney** before submission.
- This tool does not constitute legal advice.
- Actual case files (PDFs, contracts, etc.) are in `.gitignore` — **never commit them**.

## License

MIT License

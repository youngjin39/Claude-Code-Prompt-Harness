---
name: browser-automation
description: Real-browser control via agent-browser CLI (Vercel Labs). Accessibility-tree snapshots for token-efficient page interaction. Use for scraping, E2E, research, web-app operation.
triggers: [scrape, e2e, browser, login flow, dashboard test, 스크래핑, 브라우저 자동화, agent-browser]
---

# Browser Automation

Pattern: agent-browser CLI controls Chrome via CDP. Returns accessibility-tree snapshots with element refs (`@e1`, `@e2`) instead of raw HTML. ~200-400 tokens per page vs 3000-5000 for full DOM.

## When to fire
- User asks to scrape a site, automate a login, test a web UI, extract data from a page, or "open X and do Y"
- Research tasks needing live web state (prices, docs, competitor pages)
- E2E checks on the user's own deployed apps

## Hard prerequisites
- `agent-browser` installed (`npm install -g agent-browser && agent-browser install`). If `agent-browser snapshot --help` fails → STOP and tell the user to install.
- `.claude/settings.local.json` `permissions.allow` must include `Bash(agent-browser *)` (setup.sh module #6 adds this).

## Core workflow
```
1. agent-browser navigate <url>        # open page
2. agent-browser snapshot              # get accessibility tree with @refs
3. agent-browser click @e5             # interact via ref
4. agent-browser fill @e3 "query"      # type into input
5. agent-browser snapshot              # verify state changed
```

## Key commands
| Command | Purpose |
|---|---|
| `navigate <url>` | Open URL |
| `snapshot` | Accessibility tree with `@eN` refs (primary navigation tool) |
| `click @eN` | Click element by ref |
| `fill @eN "text"` | Type into input |
| `screenshot` | Visual capture (use sparingly — snapshot is cheaper) |
| `eval "js code"` | Execute JS in page context |
| `wait <selector>` | Wait for element |
| `session list/new/switch` | Manage isolated browser contexts |

## Procedure
1. Confirm `agent-browser --help` runs. If not → halt + install instructions.
2. Navigate to target URL.
3. Use `snapshot` to read page state — never scrape raw HTML.
4. Interact via `@eN` refs from snapshot. Re-snapshot after each interaction to get fresh refs.
5. Return structured data, not raw page content. Extract only what the task needs.
6. On failure: classify per error-taxonomy (network timeout → transient; element not found → re-snapshot and retry; captcha/2FA → interrupt).

## Hard rules
- **Credentials never in command args.** Use environment variables. Arg-passed secrets leak into shell history + logs.
- **Never bypass robots.txt or ToS** without explicit user authorization for that specific site.
- **Do not scrape at high frequency.** Default to 1 req/sec unless user sets rate.
- **Prefer `snapshot` over `screenshot`.** Snapshot costs ~200-400 tokens; screenshot costs thousands. Only screenshot when visual verification is explicitly needed.
- **Never screenshot pages containing PII/credentials** without explicit user request.
- On captcha, 2FA, or auth wall → STOP and hand back to user (interrupt, not model-fixable).
- **Refs are ephemeral.** After any page change (navigation, click, form submit), old `@eN` refs are invalid. Always re-snapshot.

## Output
One-line report: `BROWSER {action} {url} → {result summary}`, then the structured data. Never paste raw HTML or full snapshots into the conversation.

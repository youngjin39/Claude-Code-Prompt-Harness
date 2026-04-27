<!-- GENERATED FILE: edit .claude/skills/ux-ui-design/SKILL.md and rerun scripts/generate_codex_derivatives.sh -->
---
name: ux-ui-design
description: Hard gate before any UI code. Produce flow + wireframe + design-system-grounded component spec BEFORE implementation. Leverages VoltAgent/awesome-design-md catalog.
triggers: [ui, ux, screen, wireframe, landing, frontend, figma, design system, new screen, flutter widget, react component, 화면, 디자인]
---

# UX/UI Design Gate

Purpose: Prevent the "start coding UI → discover flow is broken → rewrite" loop. UI decisions ripple into data model, routing, and state. Lock them first.

## When to fire
- User asks to build, add, or redesign any screen, page, component, or visual element
- New feature that will be user-facing (not a pure backend/CLI change)
- Before brainstorming hands off to writing-plans, if the work involves UI

## Hard gate
**No UI code may be written before this skill's output is approved by the user.** If the current request would produce UI code and no approved spec exists → STOP and run this skill first.

## Procedure

### Step 1. User goal
State in one sentence: *Who* is using this, *what* they're trying to accomplish, and *what success looks like*. If any of the three is unknown → escalate to `deep-interview`.

### Step 2. User flow
Produce a linear flow: entry point → each decision/action → exit state. ASCII or numbered list. Name every distinct screen state. Mark error/empty/loading states explicitly — do not defer them to implementation.

### Step 3. Reference design system selection
Pick ONE primary reference from the VoltAgent/awesome-design-md catalog. Justify the choice in one line (product vibe, target audience, platform).

Common picks:
- Productivity/dev tool → `Linear`, `Cursor`, `Vercel`, `Notion`, `Figma`
- AI/ML product → `Claude`, `Cohere`, `Mistral`, `Perplexity`
- Consumer/content → `Spotify`, `Airbnb`, `Netflix`, `Apple`
- Fintech → `Stripe`, `Coinbase`, `Kraken`, `Robinhood`
- Infrastructure/enterprise → `MongoDB`, `Stripe`, `Vercel`
- Minimal/editorial → `Apple`, `Medium`, `Substack`

Full catalog: `https://github.com/VoltAgent/awesome-design-md` (58 systems).

Fetch the chosen DESIGN.md:
```
https://raw.githubusercontent.com/VoltAgent/awesome-design-md/main/{company-slug}/DESIGN.md
```
Each file contains 9 canonical sections: Visual Theme, Color Palette, Typography, Component Stylings, Layout Principles, Depth & Elevation, Do's and Don'ts, Responsive Behavior, Agent Prompt Guide.

### Step 4. Component spec
Derived from the chosen reference, NOT invented:
- Color roles (bg, fg, primary, accent, error, success) with hex values
- Type scale (4~6 sizes) + font stack
- Spacing scale (4/8/12/16/24/32 or similar)
- Radius scale
- Elevation/shadow tokens (if any)
- Core components this screen uses (button, input, card, modal, ...) with variant list

### Step 5. Wireframe
Per screen state from Step 2, produce a low-fidelity wireframe (ASCII box layout or ordered description with spatial language). Call out:
- Hit targets (≥44×44 pt for touch)
- Focus order for keyboard nav
- Empty / loading / error variants
- Mobile-first layout; breakpoint changes explicitly

### Step 6. Accessibility pass (mandatory, not optional)
- Color contrast ≥ 4.5:1 for body text (verify against chosen palette)
- Every interactive element has an accessible name
- No info conveyed by color alone
- Keyboard-only path covers every user flow from Step 2

### Step 7. Open questions
List anything unresolved (copy strings, icons, animations, 3rd-party embeds). Do not guess.

**Icon resources** (for development projects needing tech stack icons):
| Library | Best for | Install |
|---|---|---|
| `developer-icons` | React/Next.js, strongest AI/ML coverage (318 icons), TypeScript native | `npm i developer-icons` |
| `simple-icons` | Maximum brand coverage (1000+), any framework | `npm i simple-icons` |
| `devicon` | Multiple style variants (color/line/plain), CSS font fallback | CDN or `npm i devicon` |

Flutter/Dart: use SVG assets directly from these repos or devicon CDN — no pub.dev packages available.

### Step 8. User approval
Present Steps 1–7 as one report. Wait for explicit user approval. On approval → handoff to `writing-plans`. Never skip to code.

## Hard rules
- Never merge multiple design systems silently. One primary; any hybrid requires explicit one-line justification per borrowed element.
- Never invent brand colors or type. Always cite the reference.
- Never defer accessibility to "later". Later never comes.
- Never produce a spec without error/empty/loading states named.
- Never produce UI code in the same turn as this skill's output. Approval is a hard barrier.
- If the user says "just build it" → still produce Steps 1–7, but in one compact block, then ask one yes/no: "approve or revise?". No skipping.

## Output format
```
## UX/UI Spec — {feature name}

### 1. Goal
{user · action · success}

### 2. Flow
{ordered steps with state names}

### 3. Reference system
{company} — {one-line justification}

### 4. Tokens
colors: …
type: …
spacing: …
radius: …

### 5. Wireframes
{per-state ASCII or description}

### 6. Accessibility
contrast: ✓/✗  kbd nav: ✓/✗  names: ✓/✗

### 7. Open questions
- …

### 8. Approve?
```

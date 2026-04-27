---
title: Project Family Classification
keywords: [project, family, classification, bootstrap, migrate, survey, startup]
related:
  - integrations/claude-to-codex-derivation.md
  - operations/harness-application.md
  - operations/starter-maintenance-mode.md
created: 2026-04-27
last_used: 2026-04-27
type: integration
---

# Project Family Classification

## Purpose
- Classify a newly created or newly onboarded repository before applying harness layers.
- Separate `product shape`, `operational maturity`, and `rollout posture` so the first setup decision is not guessed from one signal.
- Make startup classification reusable across many project families rather than hard-coding a single starter path.

## Step 1. Classify Product Shape
- `app-product`: user-facing app or service with implementation code as the main asset.
- `director-pipeline`: multi-step workflow/project-director repo centered on prompts, orchestration, or publishing/media flows.
- `personal-knowledge`: ontology, reflection, planning, or life-organization repo where context structure is the primary asset.
- `infra-runtime`: infrastructure, router, gateway, daemon, or operator repo where live state and credentials dominate risk.
- `starter-template`: harness template, derivation layer, or meta-repo that generates instructions for other repos.
- `sealed-migration`: migration-control repo that references another runtime as read-only source and must protect cutover paths.

## Step 2. Score Operational Maturity
- `greenfield`: little or no prior `.claude/`, short history, low overwrite risk.
- `active-custom`: working repo with custom skills/agents/docs and moderate overwrite risk.
- `high-context`: rich prompts, memory, workflows, or live operations where replacement risk is high.

## Step 3. Decide Rollout Posture
- `push/init`: use when the repo is close to greenfield and starter ownership should dominate.
- `migrate`: use when the repo has meaningful existing harness assets worth preserving.
- `skip-migrate + Codex profile`: use when Mir migration is premature but Codex review/use can be safely bounded.
- `bootstrap only + boundary`: use when Codex bootstrap is useful but Mir is not the right control plane.
- `supersede`: use when the repo is a transitional template layer that should be absorbed rather than migrated.

## Step 4. Ask the Minimum Startup Questions
1. Is the repo mainly code, orchestration, ontology, infra, template, or migration control?
2. Does it already have custom `.claude/agents`, `.claude/skills`, hooks, or memory structure?
3. Would overwriting or restructuring those assets be expensive or risky?
4. Are there live secrets, credentials, databases, release artifacts, or user-owned canon that must stay protected?
5. Is Mir intended to become the long-term owner, or is Codex bootstrap the practical near-term layer?

## Output Format
- `product_shape=<one of the six shapes>`
- `maturity=<greenfield|active-custom|high-context>`
- `posture=<push/init|migrate|skip-migrate+profile|bootstrap-only+boundary|supersede>`
- `protected_assets=<short list>`
- `next_artifacts=<survey|preserve manifest|use profile|use boundary|none>`

## Default Mapping
- `app-product + greenfield` -> usually `push/init`
- `app-product + active-custom` -> usually `migrate`
- `director-pipeline + high-context` -> usually `migrate` or `skip-migrate + profile`
- `personal-knowledge + high-context` -> usually `skip-migrate + profile`
- `infra-runtime + high-context` -> usually `bootstrap only + boundary`
- `starter-template` -> usually `bootstrap only + boundary` or `supersede`
- `sealed-migration` -> usually `bootstrap only + boundary`

## Practical Rule
- Do not choose rollout posture from stack alone.
- First classify the family. Then decide whether to generate preserve artifacts, local use profile docs, or boundary docs.

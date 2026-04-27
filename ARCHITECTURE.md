# ARCHITECTURE

## Purpose
- Define how the system is built and which implementation patterns are mandatory.

## System Shape
- Runtime(s):
- Frontend:
- Backend:
- Storage:
- External integrations:

## Directory Rules
| Area | Responsibility | Allowed Dependencies | Forbidden Dependencies |
|---|---|---|---|
| app/ |  |  |  |

## Data Flow
1. User input enters at:
2. Validation happens at:
3. Business logic happens at:
4. External API calls happen through:
5. Persistence happens at:
6. User-visible errors are mapped at:

## Hard Constraints
- Required API wrapper:
- Banned libraries:
- DB schema change policy:
- State management policy:
- Logging policy:
- Feature flag policy:

## Patterns To Use
- Preferred module structure:
- Error handling boundary:
- Async/concurrency pattern:
- Test layering:

## Patterns To Avoid
- Direct vendor SDK calls outside wrappers
- Cross-layer imports that bypass the intended boundary
- Hidden global state
- Schema changes without ADR and migration review

## Security Boundaries
- Auth/authz entry points:
- Secret handling:
- PII handling:
- Audit logging:

## Failure Modes
- Upstream timeout:
- Upstream invalid response:
- Stale cache:
- Duplicate writes:
- Partial transaction:
- Background job retry storm:

## Verification
- Required commands:
- Required tests before merge:
- Required manual checks:

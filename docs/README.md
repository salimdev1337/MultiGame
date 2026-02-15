# MultiGame — Documentation

> Quick navigation index for all project docs.

---

## Architecture & Design

| File | Description |
|------|-------------|
| [ARCHITECTURE.md](architecture/ARCHITECTURE.md) | Full system architecture, layers, DI, patterns |
| [ADDING_GAMES.md](architecture/ADDING_GAMES.md) | Step-by-step guide for integrating new games |
| [SECURITY.md](architecture/SECURITY.md) | Security best practices and guidelines |
| [SECURITY_IMPROVEMENTS.md](architecture/SECURITY_IMPROVEMENTS.md) | Security changelog and improvements |

---

## Setup & Configuration

| File | Description |
|------|-------------|
| [API_CONFIGURATION.md](setup/API_CONFIGURATION.md) | Unsplash API key setup (env vars, CI, local) |
| [FIREBASE_SETUP_GUIDE.md](setup/FIREBASE_SETUP_GUIDE.md) | Firebase project setup and integration |
| [FIREBASE_MANUAL_CONFIG.md](setup/FIREBASE_MANUAL_CONFIG.md) | Manual Firebase console configuration steps |
| [CI_FIREBASE_CONFIG.md](setup/CI_FIREBASE_CONFIG.md) | Firebase config for CI/CD pipelines |
| [GITHUB_PAGES_SETUP.md](setup/GITHUB_PAGES_SETUP.md) | GitHub Pages deployment configuration |
| [BACKEND_RECOMMENDATION.md](setup/BACKEND_RECOMMENDATION.md) | Firebase vs Supabase analysis (Firebase chosen) |

---

## UI/UX Design System

| File | Description |
|------|-------------|
| [UI_UX_REDESIGN_PLAN.md](ui-ux/UI_UX_REDESIGN_PLAN.md) | Master 8-phase UI/UX plan |
| [UI_UX_POLISH_GUIDE.md](ui-ux/UI_UX_POLISH_GUIDE.md) | Polish guidelines and component usage |
| [REDESIGN_PROGRESS.md](ui-ux/REDESIGN_PROGRESS.md) | Phase 1 design token system completion report |
| [PHASE_3_IMPLEMENTATION_ANALYSIS.md](ui-ux/PHASE_3_IMPLEMENTATION_ANALYSIS.md) | Phase 3 — game polish |
| [PHASE_4_IMPLEMENTATION_ANALYSIS.md](ui-ux/PHASE_4_IMPLEMENTATION_ANALYSIS.md) | Phase 4 — profile & stats |
| [PHASE_5_IMPLEMENTATION_REPORT.md](ui-ux/PHASE_5_IMPLEMENTATION_REPORT.md) | Phase 5 — leaderboard |
| [PHASE_6_ANALYSIS.md](ui-ux/PHASE_6_ANALYSIS.md) | Phase 6 — production readiness analysis |
| [PHASE_6_IMPLEMENTATION_REPORT.md](ui-ux/PHASE_6_IMPLEMENTATION_REPORT.md) | Phase 6 — micro-interactions & feedback |

---

## Games

### Sudoku

| File | Description |
|------|-------------|
| [SUDOKU_ARCHITECTURE.md](games/sudoku/SUDOKU_ARCHITECTURE.md) | Sudoku system architecture (3 modes) |
| [SUDOKU_ALGORITHMS.md](games/sudoku/SUDOKU_ALGORITHMS.md) | Puzzle generation, solving, validation algorithms |
| [SUDOKU_SERVICES.md](games/sudoku/SUDOKU_SERVICES.md) | Service layer (persistence, matchmaking, sound) |
| [SUDOKU_QUICK_REFERENCE.md](games/sudoku/SUDOKU_QUICK_REFERENCE.md) | Quick reference card for common patterns |
| [SUDOKU_PHASE1_ANALYSIS.md](games/sudoku/SUDOKU_PHASE1_ANALYSIS.md) | Phase 1 implementation analysis |
| [SUDOKU_PHASE6_COMPLETE.md](games/sudoku/SUDOKU_PHASE6_COMPLETE.md) | Phase 6 completion notes |
| [LEADERBOARD_IMPLEMENTATION.md](games/sudoku/LEADERBOARD_IMPLEMENTATION.md) | Leaderboard screen and score integration |

### Infinite Runner (Flame)

| File | Description |
|------|-------------|
| [INFINITE_RUNNER_ARCHITECTURE.md](games/infinite-runner/INFINITE_RUNNER_ARCHITECTURE.md) | Flame ECS architecture, object pooling, systems |
| [RUNNER_RACE_IMPLEMENTATION.md](games/infinite-runner/RUNNER_RACE_IMPLEMENTATION.md) | Race mode implementation |
| [INFINITE_RUNNER_QUICK_REF.md](games/infinite-runner/INFINITE_RUNNER_QUICK_REF.md) | Quick reference for runner components |
| [INFINITE_RUNNER_SPRITES.md](games/infinite-runner/INFINITE_RUNNER_SPRITES.md) | Sprite setup and animation guide |
| [INFINITE_RUNNER_REFACTOR_SUMMARY.md](games/infinite-runner/INFINITE_RUNNER_REFACTOR_SUMMARY.md) | Refactor history and decisions |
| [INFINITE_RUNNER_TEST_CHECKLIST.md](games/infinite-runner/INFINITE_RUNNER_TEST_CHECKLIST.md) | Manual test checklist |
| [BACKGROUND_OPTIMIZATION.md](games/infinite-runner/BACKGROUND_OPTIMIZATION.md) | ParallaxComponent background optimization |

---

## CI/CD & DevOps

| File | Description |
|------|-------------|
| [CI_CD_SETUP_COMPLETE.md](cicd/CI_CD_SETUP_COMPLETE.md) | GitHub Actions workflows overview |
| [CICD_ENV_FIX.md](cicd/CICD_ENV_FIX.md) | Environment variable fixes for CI |

---

## Testing

| File | Description |
|------|-------------|
| [TEST_COVERAGE_REPORT.md](testing/TEST_COVERAGE_REPORT.md) | Test coverage report and metrics |
| [DEVICE_TESTING_GUIDE.md](testing/DEVICE_TESTING_GUIDE.md) | Device testing procedures |
| [DEVICE_TEST_REPORT_TEMPLATE.md](testing/DEVICE_TEST_REPORT_TEMPLATE.md) | Template for device test reports |

---

## Legal

| File | Description |
|------|-------------|
| [PRIVACY_POLICY.md](legal/PRIVACY_POLICY.md) | Privacy policy (Markdown) |
| [TERMS_OF_SERVICE.md](legal/TERMS_OF_SERVICE.md) | Terms of service (Markdown) |
| [privacy.html](legal/privacy.html) | Privacy policy (HTML — GitHub Pages) |
| [terms.html](legal/terms.html) | Terms of service (HTML — GitHub Pages) |
| [index.html](legal/index.html) | Legal pages index (GitHub Pages) |

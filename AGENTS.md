# AGENTS.md

Guidance for any AI coding agent working in this repository — not just the one that has been maintaining it so far. Read this before making any change.

## What this repo is

A hands-on SwiftUI learning workspace: a mock clone of the [KaraFun](https://www.karafun.com/) app UI, built lesson by lesson as a teaching exercise, not a product. Full context: [`MISSION.md`](MISSION.md) (why this exists, what "done" looks like, what's explicitly out of scope) and [`README.md`](README.md) (repo layout).

Two machines share this one repo:

- **A Mac**, where the human (Nicolas) writes, builds, and runs the real Xcode project in `Sources/Karamock/`.
- **A non-Mac environment** (Windows, via Claude Code), where lessons (`lessons/*.html`) and project documentation are authored, based on the real state of the Mac's code.

Git is the only bridge between them. Each side pushes its own kind of file; nothing else should cross that line.

## The one rule that must never be broken

**If you are not running on the machine that builds and runs this Xcode project (i.e. you cannot compile or execute `Sources/Karamock/`), never edit, commit, or push any file under `Sources/Karamock/...`.**

Only touch: `lessons/*.html`, `NOTES.md`, `MISSION.md`, `RESOURCES.md`, `learning-records/*.md`, `assets/*`.

Why: code changes to `Sources/` that haven't been compiled and run are unverified guesses. This project's entire premise is that the human validates real, working SwiftUI on a real device/simulator — an agent silently pushing unbuilt Swift code would break that premise invisibly.

If you spot an inconsistency, bug, or stale pattern in `Sources/`: **describe it in conversation, don't fix it yourself.** Let the human apply and commit the fix from the machine that can actually build it. This is a repeatedly-reinforced, explicit instruction from the project owner — treat it as non-negotiable, not a style preference.

## Git workflow specifics

- **Before writing a new lesson**, `git fetch` and check `git log HEAD..origin/main` — the Mac frequently pushes real implementation commits (`feat: implementation of lesson N`) that a lesson must be verified against, not assumed.
- **This history has been force-pushed/rewritten before** (the human has rebased to fix things retroactively). Never assume a plain `git merge` is safe — check `git merge-base --is-ancestor HEAD origin/main` first. If it's a clean fast-forward, `git merge origin/main --ff-only`. If history has diverged (rewritten), stop and confirm with the human before resetting any local branch pointer, even though the local commit is usually still recoverable by hash.
- **Never force-push.** Never use `--no-verify` or skip hooks.
- **Stage specific files by name** (`git add NOTES.md lessons/00xx-foo.html`), never `git add -A` — this repo has two very different categories of file, and a broad add can accidentally stage `Sources/` changes.
- **Only commit and push when explicitly asked.** Writing/editing a lesson does not imply permission to commit it.

## Lesson-writing conventions

- Lessons live in `lessons/NNNN-kebab-case-slug.html`, numbered sequentially, each a **self-contained HTML file** in **French**, linking `../assets/style.css` and `../assets/quiz.js`.
- Reuse components already in `assets/` before inventing new inline styles; add a new reusable CSS class there (not lesson-local `<style>`) when a pattern will recur.
- Every lesson ties back to `MISSION.md` — a short "Pourquoi cette leçon" framing box near the top.
- Quizzes: exactly-comparable-length answer options (don't let the correct answer be identifiable by being longer/more detailed), vary which option is correct across questions.
- **Never guess API, library, or framework syntax.** Verify via web search/fetch against primary sources (official docs, evolution proposals, or by directly testing — e.g. `curl` for HTTP APIs) before writing any code example. Cite the primary source in a "Sources primaires recommandées" box.
- **Ground every lesson in the real, current state of `Sources/`** — read the actual files before describing "before" code; don't rely on a previous lesson's description of what the code used to look like, since the human often changes it independently between lessons.
- Link each lesson's nav footer forward/backward to its neighbors once both exist.
- Update `NOTES.md` after writing or revising a lesson — it's the living index of what's done, what's next, and why.

## Architecture conventions inside `Sources/Karamock/`

(For understanding the codebase — not for editing it, per the rule above, unless you are on the Mac.)

- Layering: `Views` → `ViewModels` → `Domain/Use Case` → `Repositories` / `Services`.
- Dependency injection via [FactoryKit](https://github.com/hmlongco/Factory), all registrations in `KaramockContainer.swift`. Service/UseCase pairs follow a consistent shape: a `Sendable` protocol + a concrete implementation (e.g. `SongDownloading` / `MockSongDownloading`), wrapped by a `Sendable` UseCase struct with a `nonisolated init` and `callAsFunction`.
- Swift 6 strict concurrency, with `SWIFT_APPROACHABLE_CONCURRENCY = YES` and `SWIFT_DEFAULT_ACTOR_ISOLATION = MainActor` set at the project level — meaning **every unannotated declaration is implicitly `@MainActor`**. Types meant to cross actor boundaries (`Sendable` protocols, UseCase inits) need `nonisolated` explicitly; shared mutable state uses `actor`, never `nonisolated(unsafe)` as a shortcut.
- `@Environment(\.keyPath)` + `@Entry` is the project's real convention for environment values (not `@Environment(Type.self)`).
- Tests use [Swift Testing](https://developer.apple.com/documentation/testing) (`Sources/Karamock/KaramockTests/`), with Factory's `Container.shared.x { Mock() }` override pattern for test doubles, and the `.container` trait for parallel-safe isolation.

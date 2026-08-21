# Design Goals

## Purpose

`llmdoc` exists to solve a recurring LLM problem: source code is accurate but expensive to understand from scratch.

## Why docs first

- Faster context: good docs compress high-value context faster than broad code search.
- Better architectural alignment: docs explain intended boundaries, not only incidental implementation.
- Lower context thrash: repeatedly searching the same code paths is expensive and noisy.
- Bounded recovery: compaction should preserve a small task state instead of replaying startup context.
- Durable learning: process-signal triage and updates turn mistakes into verifiable doc fixes instead of repeated failures.

## Core outcome

`llmdoc` aims to make project understanding:

- high density
- reusable across tasks
- bounded independently of total repository and llmdoc size
- structured by concept instead of accidental file order
- able to improve over time through signal triage and updates

---
name: pr-review-fo
description: Review someone else's GitHub PR in two phases, a high-level review (background, mistakes, design decisions) and an optional code tour. Use when the user gives a PR URL or number to review. Never posts to GitHub.
---

# PR review flow

Review another author's PR for the user. All output goes to the terminal. The user decides what reaches GitHub.

## Hard rule

Never write anything to GitHub: no reviews, comments, or suggested changes. If the user asks for comments, draft them as plain text in the terminal.

## Gather context

Input is a PR URL or number. Read the description, commits, and diff. Read the full files at the PR head when the diff isn't enough, and compare against the base branch to spot inconsistencies with the rest of the codebase. Don't touch the user's working tree or current branch. Run tests or linters only if they're cheap and local.

## Phase 1: high-level review

Report three sections in this order.

**Background.** Assume the reader knows the codebase in general but hasn't read this PR. Explain the problem the PR solves, how the feature works end to end, and where it plugs into existing code. Name the moving parts and how they connect at runtime. Write a few short paragraphs of plain prose, no lists.

**Mistakes.** Focus on design and process mistakes, ranked by importance. Examples: the wrong architecture, abstraction, or layer; behaviour that will surprise users or operators; missing verification, such as testing only against fakes; scope creep; PR hygiene, such as an empty description, unrelated changes, or broken conventions like bundling a version bump. Give each one a short reason. End the section with a short footnote list of syntax errors, specific logic bugs, and edge cases, each as `file:line` plus a one-line reason.

**Design decisions.** List the decisions the author made that the user may want a second opinion on. State each one as a decision, for example "Services are systemd user units, not system units." Follow it with the trade-off it carries and the alternatives. Don't write questions for the user to ask.

Every point in the mistakes, footnotes, and design decisions sections cites the `file:line` or `file:start-end` locations it refers to, taken from the PR head. A point that spans several places lists each one.

Be concise. Choose correctness over harmony. If something is fine, leave it out.

Stop after Phase 1 and wait for the user.

## Phase 2: code tour

Only run this when the user asks for it.

Group the changed hunks into stops, ordered so each one builds on the previous. For each stop give:

- Files and line ranges
- What the stop does, in 1-2 sentences
- What to look for, tied back to Phase 1 findings

Mark low-value stops (lockfiles, version bumps) as skim.

## Writing

Apply the `unslop` skill to all prose output.

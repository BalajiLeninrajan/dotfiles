---
name: pr-description
description: Write or update a GitHub PR description. Use when opening a PR, running `gh pr create`, or when asked to write or rewrite a PR body.
---

Reviewers can read the diff. The description covers what the diff can't tell them.

Include, in this order, skipping any section that doesn't apply:

1. **Motivation.** Why this change exists. What was broken, missing, or slow. Open with this.
2. **Background.** Only the context a reviewer needs to judge the change. Keep it brief.
3. **Decisions and tradeoffs.** Important technical choices, the alternatives you rejected, and why. Call out anything you're unsure about.
4. **Proof of work.** Benchmarks with before/after numbers, test output, or screenshots and videos for frontend changes. If proof is needed but you can't produce it (e.g. a screenshot), leave a placeholder and tell the user.

Rules:

- Link to specific code (file and line permalinks) when referring to it. Don't describe it.
- Don't list changed files, restate what functions do, or summarize the diff line by line.
- No filler sections like "Summary of changes" or "Testing: N/A".
- Short beats complete. A one-line fix can have a one-paragraph description.
- Apply the `unslop` skill to the final text.

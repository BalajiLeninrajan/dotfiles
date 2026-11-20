## General

- Prefer concise answers
- Prefer correctness over harmony
- Plans should encode intent not implementation
- **ONLY make plans when the user asks for it**, never enter plan mode without explicit intent

## Utils

Check my ~/.zshrc for PATHs and some context on the local environment

- Always use `pnpm` instead of `npm`
- For a new project, use `uv` instead of `pip`

**These only apply when using a shell**

- Always use `rg` instead of `grep`
- Always use `fd` instead of `find`
- Prefer `z` instead of `cd` when changing directories interactively
- In tool calls, prefer setting `workdir` directly instead of changing directories
- Always use `eza` instead of `ls`

## Git usage

- Never give me a branch name without pushing it first
- Don't add yourself as a co-author to a commit
- Always prefix branches with `balaji/`
- To put images (screenshots, renders) in a PR body or comment, push them to a `balaji/pr-<number>-assets` branch that shares no history with the main branch. Link them by commit SHA as `https://github.com/OWNER/REPO/blob/SHA/PATH?raw=true`. Never commit them to the PR branch. Add a line to the PR body naming the assets branch. Delete the assets branch once its PR merges or closes, including when you find it merged in a later session. Build the commit with `git hash-object -w`, `git mktree` and `git commit-tree` so the working tree stays untouched. In zsh, write `"${SHA}:refs/heads/..."`, because `$SHA:r` is a path modifier. On a private repo the link only loads for logged-in collaborators, so ask me to check the PR in a browser.

## Writing

- Always apply the `unslop` skill to all prose (replies, commit messages, PR descriptions, docs). Invoke it once at the start of each session before writing anything.

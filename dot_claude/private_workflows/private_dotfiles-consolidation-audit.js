export const meta = {
  name: 'dotfiles-consolidation-audit',
  description: 'Audit GitHub dotfile repositories and local configs before consolidating into chezmoi',
  phases: [
    { title: 'Inspect sources', detail: 'Compare each config repository with its local installation' },
    { title: 'Check target', detail: 'Inspect the existing chezmoi repository and platform structure' },
    { title: 'Synthesize', detail: 'Build the final inclusion and source-of-truth inventory' },
    { title: 'Critique', detail: 'Check the inventory for missing repositories, configs, and unsafe files' }
  ]
}

const ITEM_SCHEMA = {
  type: 'object',
  properties: {
    repo: { type: 'string' }, purpose: { type: 'string' }, github_url: { type: 'string' },
    github_paths: { type: 'array', items: { type: 'string' } },
    local_candidates: { type: 'array', items: { type: 'string' } },
    local_existing: { type: 'array', items: { type: 'string' } },
    source_of_truth: { type: 'string' }, source_reason: { type: 'string' },
    os_scope: { type: 'string', enum: ['macos', 'linux', 'both', 'unknown'] },
    include_paths: { type: 'array', items: { type: 'string' } },
    exclude_paths: { type: 'array', items: { type: 'string' } },
    secret_or_state_risks: { type: 'array', items: { type: 'string' } },
    confidence: { type: 'string', enum: ['high', 'medium', 'low'] }
  },
  required: ['repo','purpose','github_url','github_paths','local_candidates','local_existing','source_of_truth','source_reason','os_scope','include_paths','exclude_paths','secret_or_state_risks','confidence'],
  additionalProperties: false
}

const TARGET_SCHEMA = {
  type: 'object',
  properties: {
    repo_path: { type: 'string' }, github_url: { type: 'string' }, present_locally: { type: 'boolean' },
    current_managed_items: { type: 'array', items: { type: 'string' } },
    current_platform_mechanism: { type: 'string' },
    collisions: { type: 'array', items: { type: 'string' } },
    structural_recommendations: { type: 'array', items: { type: 'string' } },
    risks: { type: 'array', items: { type: 'string' } }
  },
  required: ['repo_path','github_url','present_locally','current_managed_items','current_platform_mechanism','collisions','structural_recommendations','risks'],
  additionalProperties: false
}

const FINAL_SCHEMA = {
  type: 'object',
  properties: {
    additions: { type: 'array', items: { type: 'object', properties: {
      config: { type: 'string' }, destination: { type: 'string' }, source_of_truth: { type: 'string' },
      source_type: { type: 'string', enum: ['local', 'github', 'existing-chezmoi'] },
      os_scope: { type: 'string', enum: ['macos', 'linux', 'both', 'unknown'] },
      include: { type: 'array', items: { type: 'string' } }, exclude: { type: 'array', items: { type: 'string' } },
      rationale: { type: 'string' }, confidence: { type: 'string', enum: ['high', 'medium', 'low'] }
    }, required: ['config','destination','source_of_truth','source_type','os_scope','include','exclude','rationale','confidence'], additionalProperties: false } },
    do_not_add: { type: 'array', items: { type: 'object', properties: { item: { type: 'string' }, reason: { type: 'string' } }, required: ['item','reason'], additionalProperties: false } },
    unresolved: { type: 'array', items: { type: 'string' } },
    platform_strategy: { type: 'array', items: { type: 'string' } },
    security_actions: { type: 'array', items: { type: 'string' } },
    repositories_after_migration: { type: 'array', items: { type: 'string' } }
  },
  required: ['additions','do_not_add','unresolved','platform_strategy','security_actions','repositories_after_migration'], additionalProperties: false
}

const CRITIQUE_SCHEMA = {
  type: 'object',
  properties: {
    missing_candidates: { type: 'array', items: { type: 'string' } }, incorrect_sources: { type: 'array', items: { type: 'string' } },
    platform_errors: { type: 'array', items: { type: 'string' } }, unsafe_inclusions: { type: 'array', items: { type: 'string' } },
    corrections: { type: 'array', items: { type: 'string' } }, ready_to_present: { type: 'boolean' }
  },
  required: ['missing_candidates','incorrect_sources','platform_errors','unsafe_inclusions','corrections','ready_to_present'], additionalProperties: false
}

const repos = [
  'BalajiLeninrajan/kanata-dotfiles', 'BalajiLeninrajan/nvim-conf', 'BalajiLeninrajan/ghostty-dotfiles',
  'BalajiLeninrajan/niri-dotfiles', 'BalajiLeninrajan/dms-dotfiles', 'BalajiLeninrajan/zellij-config',
  'BalajiLeninrajan/zathura-config', 'BalajiLeninrajan/System-Backup'
]

phase('Inspect sources')
const inspected = await parallel(repos.map(repo => () => agent(`Read-only dotfiles audit for ${repo}.
Inspect this GitHub repository via gh CLI/API and compare it with the corresponding local configuration under /Users/balaji. Restrict local inspection to likely config paths for this exact tool, such as ~/.config/<tool>, a matching clone under ~/Documents/code, and tool-specific files; do not broadly crawl the home directory. You may inspect config content needed to compare versions, but never print secret values, credentials, tokens, histories, caches, or unrelated personal data. Use filenames, hashes, mtimes, git state, and focused diffs to determine authority.
Report what the repo configures and relevant tracked paths; exact likely and existing local source paths; whether local or GitHub should be source of truth, preferring local when it exists and represents the active/newer config; OS scope; exact paths to include/exclude; and secret/generated/cache/plugin/history/lock/socket/log/large-asset/machine-state risks. DankMaterialShell/DMS and niri are Linux-only unless concrete evidence says otherwise. Do not modify anything.`, {label: `inspect:${repo.split('/')[1]}`, phase: 'Inspect sources', schema: ITEM_SCHEMA})))

phase('Check target')
const target = await agent(`Read-only audit of BalajiLeninrajan/dotfiles, the existing chezmoi-managed target.
Inspect GitHub and any local chezmoi source path reported by chezmoi source-path, ~/.local/share/chezmoi, or a matching clone. Do not alter anything. Report current managed items, current OS-conditional strategy/templates/scripts, collisions with incoming kanata, nvim, ghostty, niri, DankMaterialShell, zellij, zathura, System-Backup contents, and local paneru.toml. Recommend only the structural platform mechanism needed to keep macOS-only Paneru off Linux and Linux-only DMS/niri off macOS. Flag secrets/state without printing values.`, {label: 'inspect:chezmoi-target', phase: 'Check target', schema: TARGET_SCHEMA})

phase('Synthesize')
const synthesis = await agent(`Create the definitive pre-migration inventory for consolidating standalone dotfile repositories into the existing chezmoi repo. The user wants EVERYTHING planned for addition and the exact source of truth before changes.
Candidate audit results: ${JSON.stringify(inspected)}
Existing target audit: ${JSON.stringify(target)}
Prefer active local config over standalone GitHub when both exist. macOS-only Paneru must not install on Linux. Linux-only DankMaterialShell and niri must not install on macOS. Distinguish files to add from generated/cache/secret/machine-state files to exclude. Preserve existing chezmoi items rather than listing them as new unless replaced. Include exact source and destination paths. Identify repos that can be archived only after migration is verified. State low-confidence choices explicitly. Never reproduce credential values.`, {label: 'synthesize:inventory', phase: 'Synthesize', schema: FINAL_SCHEMA})

phase('Critique')
const critique = await agent(`Adversarially audit the proposed chezmoi consolidation inventory for omissions and mistakes.
Preliminary repos: dotfiles target, kanata-dotfiles, nvim-conf, ghostty-dotfiles, niri-dotfiles, dms-dotfiles, zellij-config, zathura-config, System-Backup. Explicit local item: paneru.toml.
Per-repo inspection: ${JSON.stringify(inspected)}
Target inspection: ${JSON.stringify(target)}
Proposed inventory: ${JSON.stringify(synthesis)}
Check for omitted config, wrong source precedence, OS mistakes, unsafe inclusion, wrong destination, or existing chezmoi items misrepresented as new. Do not modify anything or reveal credentials.`, {label: 'critique:inventory', phase: 'Critique', schema: CRITIQUE_SCHEMA})

return { inspected, target, synthesis, critique }

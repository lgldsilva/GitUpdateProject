# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## What this project is

Pure-Bash recursive Git repository updater. Finds every `.git` under a root directory and updates it — in parallel if requested. Target runtimes: Linux, macOS, Windows Git Bash. No compile step; shipping artifact is `updateGit_v2.sh` + `lib/`.

## Common commands

```bash
# Run it
./updateGit_v2.sh /path/to/repos

# Before any "risky" flag, always dry-run first
./updateGit_v2.sh /path -n

# Parallel + structured output (what you want for scripting)
./updateGit_v2.sh /path -j 8 --json > out.json 2>run.log

# Lint everything (zero warnings expected before commit)
shellcheck -S warning lib/*.sh scripts/*.sh updateGit_v2.sh install.sh install-from-github.sh build.sh demo.sh example_usage.sh

# Tests (requires bats-core: `pacman -S bats` / `brew install bats-core`)
bats tests/
bats tests/excludes.bats          # single file

# Security audit (runs gitleaks + shellcheck + custom checks)
./scripts/security-audit.sh

# Build release archives
./build.sh
```

## Architecture

### Entry point → module load order
`updateGit_v2.sh` resolves its own path through symlinks (so `~/.local/bin/git-update → /opt/GitUpdateProject/updateGit_v2.sh` still finds `lib/`), then sources each module in dependency order. Load order matters — each module has an include guard, but `retry.sh` needs `logger.sh`, `logger.sh` needs `colors.sh` + `config.sh`, etc.

### Data flow for one run
```
main()
 ├─ load_config_file        (~/.config/gitupdate/config; CLI overrides this)
 ├─ configure_settings "$@" (parse CLI; non-flag args → REMAINING_ARGS[])
 ├─ find_git_repositories   (populates FOUND_GIT_DIRS[], TOTAL_REPOS)
 └─ if PARALLEL_JOBS > 1:
      run_parallel _run_one_repo "${FOUND_GIT_DIRS[@]}"
        └─ spawns N workers, each captures output to its own tmp logfile,
           parent cats them back in order once wait completes
    else:
      sequential for-loop → update_git_repo per dir
```

### Per-repo logic (`update_git_repo` in `repo_updater.sh`)
Wired from many modules; understand this sequence before changing anything:
1. `repo_status_summary` (captures `dirty+N ahead/behind` for the report)
2. **If `--force`**: `git reset --hard` (destructive, intentional)
3. **Else if dirty**: `git stash push -u` — critical for preserving user work
4. `git fetch --all --prune` — **partial failure is OK**: one offline remote must not fail the whole repo. Logs a warning only
5. For each remote: try `master/main/develop`, then current branch if different
6. If no branch was updated: `try_generic_pull` (the only fallback that sets error status)
7. `stash pop` (if step 3 stashed)
8. `update_submodules` / `pull_lfs` / `push_repo` / `run_gc` (feature-flagged)
9. Run `.gitupdate-hook` in the repo dir if `--hooks` and hook is executable

### Global state contract
Several shell globals are the API between modules. They're **intentionally unscoped** — don't `local` them, don't export them redundantly:
- `FOUND_GIT_DIRS[]`, `TOTAL_REPOS` — set by `find_git_repositories`
- `CURRENT_BRANCH`, `REPO_REMOTES[]` — set by `get_repo_info`, consumed by `update_branch`/`check_standard_branches`
- `PARALLEL_STATUSES[]` — populated by `run_parallel`, consumed by the post-wait aggregation in main
- `FAILED_REPORT_LINES[]` — appended by `record_failure`, read by `show_summary`
- `REPO_REPORTS[]` — appended by `report_repo`, dumped by `emit_json_report`
- `EXCLUDE_PATTERNS[]`, `REMAINING_ARGS[]` — filled by `configure_settings` + `load_config_file`
- `LAST_PRE_STATUS`, `LAST_POST_STATUS` — per-repo status strings (sequential mode only; empty in parallel because workers run in subshells)

When you declare any of these in a function, mark them `# shellcheck disable=SC2034` so the lint stays clean.

### Output channels (important for `--json`)
- `stdout` = human output (progress bar, logs) — **unless** `JSON_OUTPUT=true`, in which case stdout is reserved for the final JSON payload only
- `stderr` = logs when in JSON mode
- Log file at `~/.local/share/GitUpdateProject/logs/updateGit_<ts>.log` always gets everything

Anything that writes directly to stdout (git output, progress bar redraws, `echo "---"` separators) **must** check `JSON_OUTPUT` and redirect to stderr when true. This bit us in production — `lib/parallel.sh` cats worker logfiles; that cat redirects based on `JSON_OUTPUT`.

### Known landmines (these have bitten real users)

1. **Unscoped loop variables** — `draw_progress_bar` used `i` without `local`, clobbering the outer `main()` for-loop counter, producing an infinite loop that processed the same repo 5000+ times. **When adding ANY for-loop inside a sourced library function, declare `local i` (and `j`, etc.).**

2. **Destructive defaults** — do not reintroduce an unconditional `git reset --hard`. The "stash → fetch → branch update → stash pop" sequence is deliberate and preserves uncommitted work. `--force` is the only thing that should discard changes.

3. **`bash -c "$cmd"` is banned** — commands go through arrays: `perform_git_operation "op" "Error" git fetch --all`. This prevents ref-name injection.

4. **Cross-platform gotchas already worked around** (don't undo):
   - `timeout` detected via `_find_timeout_cmd` (Linux `timeout`, macOS `gtimeout`, Windows: skipped)
   - `readlink -f || realpath || pwd -P` cascade (macOS default readlink has no `-f`)
   - `find -printf` and `sort -z` are GNU-only — avoided
   - `mktemp -t <prefix>` works on both GNU and BSD; `mktemp -t TEMPLATE` doesn't

5. **Fetch partial failure** — when one of several remotes is offline, `git fetch --all` returns non-zero. This **must not** fail the repo if any branch update succeeded afterward. `repo_updater.sh` logs fetch as `Aviso`, not `Falha`.

6. **Submodule vs regular nested repos** — `find -type d -name .git` skips submodule `.git` files naturally. Worktrees use `.git` files too but should be included; `repo_finder.sh` includes both types and then filters submodules via `_is_submodule_gitfile` (checks for `gitdir: .git/modules/`).

## Testing

`tests/` uses bats-core. `tests/helper.bash` exposes `load_lib <name>` and `make_repo`. Tests run in isolation — each bats file declares its own `setup()` that sources the lib modules it exercises. Only four modules have tests so far (`config`, `excludes`, `retry`, `status`). Shell functions that touch the filesystem or git are tested via `make_repo` + `cd`.

## When things fail in practice

- **"Traveled to processed 5779/69 and hung"** → an unscoped `i` somewhere clobbered the main loop. Grep for `for ((` in libs and verify each function declares `local i`.
- **"JSON output has junk before the `{`"** → something wrote to stdout instead of respecting `JSON_OUTPUT`. Check recently-added `echo` statements.
- **"Repo marked as failed but branches look fine"** → likely a remote is offline and the fetch-fails-entire-repo bug regressed. See landmine #5.
- **"cat: .../log-0: No such file"** → the `trap 'rm -rf "$tmpdir"' RETURN` in `parallel.sh` fired too early. The trap is scoped to `run_parallel` and must stay that way; don't move aggregation out of the function.

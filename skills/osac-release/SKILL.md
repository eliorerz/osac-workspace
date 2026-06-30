---
name: osac-release
description: >
  Publish new OSAC Helm chart versions across all component repos and the
  umbrella chart. Auto-increments patch versions by default, tags upstream/main,
  monitors CI workflows, verifies OCI registry publication, and publishes the
  osac-installer umbrella chart with the new component versions. USE WHEN user
  says "osac-release", "release osac", "publish osac", "bump osac versions",
  "publish helm charts", or wants to release new OSAC chart versions.
triggers:
  - osac-release
  - release osac
  - publish osac
  - bump osac versions
  - publish helm charts
allowed-tools:
  - Bash
  - Read
  - Write
  - Edit
  - Glob
  - Grep
  - AskUserQuestion
---

# /osac-release -- OSAC Helm Chart Release Wizard

Guided release workflow for publishing Helm charts across all OSAC component
repos and the umbrella chart. Discovers repos dynamically, shows current/next
versions, confirms before each destructive action, monitors workflows, and
verifies OCI registry publication.

**Announce at start:** Print this banner, then proceed to Step 0.

```
 ██████╗ ███████╗ █████╗  ██████╗    ██████╗ ███████╗██╗     ███████╗ █████╗ ███████╗███████╗
██╔═══██╗██╔════╝██╔══██╗██╔════╝    ██╔══██╗██╔════╝██║     ██╔════╝██╔══██╗██╔════╝██╔════╝
██║   ██║███████╗███████║██║         ██████╔╝█████╗  ██║     █████╗  ███████║███████╗█████╗
██║   ██║╚════██║██╔══██║██║         ██╔══██╗██╔══╝  ██║     ██╔══╝  ██╔══██║╚════██║██╔══╝
╚██████╔╝███████║██║  ██║╚██████╗    ██║  ██║███████╗███████╗███████╗██║  ██║███████║███████╗
 ╚═════╝ ╚══════╝╚═╝  ╚═╝ ╚═════╝    ╚═╝  ╚═╝╚══════╝╚══════╝╚══════╝╚═╝  ╚═╝╚══════╝╚══════╝
```

## Output Formatting Rules

**CRITICAL:** Do NOT dump raw bash command output to the user. Run commands
silently and present results as clean, structured status lines with icons.
Every step must have a header and use the icon vocabulary below.

**Icon vocabulary:**

| Icon | Meaning |
|------|---------|
| `[Step N]` | Step header (always print before starting a step) |
| `✅` | Check passed / action succeeded |
| `❌` | Check failed / action failed |
| `📦` | Repo discovered or cloned |
| `🏷️`  | Tag operation (fetch, create, push) |
| `🔄` | Workflow monitoring / polling |
| `🔍` | Verification (OCI registry check) |
| `⏳` | Waiting / retrying |
| `⚠️`  | Warning (non-blocking) |
| `🚀` | Release summary / final result |

**Example -- how Step 0 should look to the user:**

**[Step 0] Pre-flight Checks**

  ✅ gh CLI authenticated (username)
  ✅ helm CLI available (v3.19.0)

  **Discovering repos...**
  📦 fulfillment-service             → /path/to/fulfillment-service
  📦 osac-operator                   → /path/to/osac-operator
  📦 osac-aap                        → /path/to/osac-aap
  📦 bare-metal-fulfillment-operator → /path/to/bare-metal-fulfillment-operator
  📦 osac-ui                         → /path/to/osac-ui
  📦 osac-installer                  → /path/to/osac-installer
  ✅ All 6 repos discovered. No uncommitted changes.

**Example -- if repos need cloning:**

  **Cloning missing repos...**
  📦 Cloning fulfillment-service...
  📦 Cloning osac-operator...
  📦 Cloning osac-aap...
  📦 Cloning bare-metal-fulfillment-operator...
  📦 Cloning osac-ui...
  📦 Cloning osac-installer...
  ✅ All 6 repos cloned and upstream remotes configured.

**Example -- how Step 1 should look:**

**[Step 1] Fetch Tags & Determine Current Versions**

  **Fetching upstream tags...**
  🏷️  fulfillment-service             → v0.0.69 (git tag)
  🏷️  osac-operator                   → v0.0.2  (git tag)
  🏷️  osac-aap                        → v0.0.4  (git tag)
  🔍 bare-metal-fulfillment-operator → (none)  (no git tags, checking OCI...)
  🏷️  osac-ui                         → v0.0.1  (git tag)
  🔍 osac (umbrella)                 → v0.0.2  (OCI fallback)

**Example -- how Step 5 should look:**

**[Step 5] Tag & Push Components**

  **Tagging upstream/main...**
  🏷️  fulfillment-service             → v0.0.70 pushed
  🏷️  osac-operator                   → v0.0.3  pushed
  🏷️  osac-aap                        → v0.0.5  pushed
  🏷️  bare-metal-fulfillment-operator → v0.0.1  pushed
  🏷️  osac-ui                         → v0.0.2  pushed
  ✅ All 5 component tags pushed.

**Example -- how Step 6 should look:**

**[Step 6] Monitor Publish Workflows**

  🔄 fulfillment-service             → ✅ completed
  🔄 osac-operator                   → ✅ completed
  🔄 osac-aap                        → ⏳ in_progress (45s)
  🔄 bare-metal-fulfillment-operator → ⏳ queued
  🔄 osac-ui                         → ⏳ queued

**Example -- how Step 10 should look:**

**[Step 10] Release Summary**

🚀 **Release Complete!** (Reason: Routine release)

┌──────────────────────────────────────┬─────────┬───────────────────────────────────────────────────────┐
│ Chart                                │ Version │ Registry                                              │
├──────────────────────────────────────┼─────────┼───────────────────────────────────────────────────────┤
│ fulfillment-service                  │ 0.0.70  │ oci://ghcr.io/osac-project/charts/fulfillment-service│
│ ...                                  │ ...     │ ...                                                   │
└──────────────────────────────────────┴─────────┴───────────────────────────────────────────────────────┘

**Rules:**

1. **ZERO narration.** NEVER output filler text like "Let me run the
   pre-flight checks", "Now let me validate...", "I'll clone the repos",
   "Moving to Step 1...", etc. The ONLY text the user should see between
   tool calls is formatted status lines with icons. No explanations, no
   transitions, no commentary. Just icons and results.

2. **Suppress all bash output.** Append `>/dev/null 2>&1` to every bash
   command. The user must NEVER see raw git, helm, or gh output. Only show
   raw output when a command fails and the error is needed for debugging.

3. **Descriptive bash labels.** Always set the `description` parameter on
   every Bash tool call to a short, human-friendly label. The user sees
   this label in the UI. Examples:
   - `description: "Check gh CLI authentication"`
   - `description: "Check Helm CLI version"`
   - `description: "Clone all component repos"`
   - `description: "Fetch upstream tags for all repos"`
   - `description: "Tag and push fulfillment-service v0.0.70"`
   NEVER leave the description empty or set it to the command itself.

4. **Print progress BEFORE running.** Print the icon lines (📦, 🏷️, 🔄)
   BEFORE executing the bash command, so the user sees what is about to
   happen. Then run the command silently. Then print the result (✅ or ❌)
   after. Example flow:

   ```
   Output:  **Cloning component repos...**
              📦 fulfillment-service
              📦 osac-operator
              📦 osac-aap
              📦 bare-metal-fulfillment-operator
              📦 osac-ui
              📦 osac-installer
   Run:     [silent bash clone loop]
   Output:  ✅ All 6 repos cloned and upstream remotes configured.
   ```

   NOT: run clone first, then print 📦 lines after (that is duplicate/late).

5. **Bold step headers.** Always print step headers in markdown bold:
   `**[Step 0] Pre-flight Checks**`. The `[Step N]` prefix and title must
   both be inside the bold markers.

6. **One status line per action.** After each bash command completes, print
   a single confirmation line with ✅ or ❌. Never print the bash command
   itself or its output.

7. **Batch operations into single commands.** When cloning, fetching tags,
   or pushing tags for multiple repos, run ALL repos in a single bash
   command (loop) rather than one command per repo. This minimizes the
   number of visible tool calls.

8. **Use indentation** (2 spaces) for status lines within a step.

9. **When polling workflows** (Step 6/9), re-print the status table on each
   poll iteration -- do not dump `gh run view` JSON.

## Component Registry

Each component repo publishes Helm charts via a `publish-charts.yaml` GitHub
Actions workflow triggered by `v*` tag pushes. Chart.yaml files in component
repos use `version: 0.0.0` as a placeholder -- the real version is injected at
publish time.

| Component | Repo | Charts Published | Tag Pattern |
|-----------|------|-----------------|-------------|
| fulfillment-service | osac-project/fulfillment-service | `fulfillment-service` | `v0.0.X` |
| osac-operator | osac-project/osac-operator | `osac-operator` + `osac-operator-crds` | `v0.0.X` |
| osac-aap | osac-project/osac-aap | `osac-aap` | `v0.0.X` |
| bare-metal-fulfillment-operator | osac-project/bare-metal-fulfillment-operator | `bare-metal-fulfillment-operator` + `bare-metal-fulfillment-operator-crds` | `v0.0.X` |
| osac-ui | osac-project/osac-ui | `osac-ui` | `v0.0.X` |
| osac (umbrella) | osac-project/osac-installer | `osac` | `v0.0.X` or workflow_dispatch |

All charts are published to `oci://ghcr.io/osac-project/charts`.

## Repo Discovery

Repos are discovered dynamically using the `bootstrap.sh` sibling layout:

```
/path/to/workspace/
  osac-workspace/                    <-- skill runs from here
  fulfillment-service/               <-- sibling repos
  osac-operator/
  osac-aap/
  bare-metal-fulfillment-operator/
  osac-ui/
  osac-installer/
```

Discovery steps:
1. Determine workspace root: `git rev-parse --show-toplevel` from `osac-workspace/`
2. For each component, check `$(dirname $WORKSPACE_ROOT)/<repo-name>/`
3. If not found, prompt user via AskUserQuestion for the repo path
4. Validate: `git remote get-url upstream` must contain `osac-project/<repo-name>`

## Step 0: Pre-flight Checks

**Gate checks -- stop if any fail:**

| Check | Command | Fail action |
|-------|---------|-------------|
| `gh` CLI authenticated | `gh auth status` | Stop: "gh CLI not authenticated. Run `gh auth login`." |
| `helm` CLI available | `helm version` | Stop: "helm CLI not found. Install helm." |

**Parse user message** for optional flags:

```
/osac-release                              # patch bump all components
/osac-release v0.1.0                       # set all components to v0.1.0
/osac-release --only fulfillment-service   # publish only one component
/osac-release --skip osac-aap              # skip a specific component
```

## Step 0.5: Component Selection (AskUserQuestion)

Ask which components to release using a multi-select checkbox. Present all
components with all selected by default:

- [ ] fulfillment-service
- [ ] osac-operator
- [ ] bare-metal-fulfillment-operator
- [ ] osac-aap
- [ ] osac-ui (UI web console)
- [ ] osac (umbrella)

If `--only` or `--skip` flags were parsed from the user's message, pre-filter
the selection accordingly.

If the user deselects a component, warn: "Deselected components will NOT be
re-tagged. The umbrella chart will use their current published version."

If the user deselects the umbrella, warn: "The umbrella chart will not be
published. Only component charts will be tagged and published."

Only discover/clone repos and fetch tags for the selected components in the
following steps.

## Step 0.6: Recent Release Check

Check if any release activity happened in the last 24 hours for the **selected
components only**. This uses the GitHub API directly -- no local repos needed.

```bash
gh run list --repo osac-project/<repo> -w publish-charts.yaml --limit 3 \
  --json status,conclusion,createdAt,headBranch \
  --jq '[.[] | select(.createdAt > "'$(date -u -d '24 hours ago' +%Y-%m-%dT%H:%M:%SZ)'")] '
```

Also check for in-progress runs:

```bash
gh run list --repo osac-project/<repo> -w publish-charts.yaml --status in_progress \
  --json databaseId,headBranch --jq '.'
```

**If any in-progress runs are found**, show a warning:

```
⚠️  Active release detected!

  🔄 osac-operator → publish-charts in_progress (run #12345, tag v0.0.3)

  A release workflow is currently running. Proceeding may cause conflicts.
```

Then ask (AskUserQuestion):
- A) Abort -- wait for the current release to finish
- B) Proceed anyway -- I know what I'm doing

**If completed runs found in the last 24 hours** (no in-progress), show an
informational notice and continue without blocking:

```
ℹ️  Recent releases in the last 24 hours:

  🏷️  fulfillment-service → v0.0.69 (completed 3h ago)
```

## Step 0.7: Release Coordination Gate (AskUserQuestion)

Ask the user two things before proceeding:

1. **Release reason** (AskUserQuestion with options): "What is the reason for
   this release?"
   - A) Routine release (scheduled version bump)
   - B) Bug fix
   - C) New feature
   - D) Dependency update
   The user can also type a custom reason via "Other".

2. **Infra team coordination** (confirmation): "Have you reached out to the OSAC
   Infra team to let them know about this release and the reason for it?"
   - A) Yes, the Infra team is aware and has approved
   - B) No, I haven't contacted them yet

If B, stop and tell the user: "Please coordinate with the OSAC Infra team
before proceeding. Let them know the release reason and get their
acknowledgment. Then re-run `/osac-release`."

Record the release reason -- include it in the Step 10 release summary.

## Step 0.8: Repo Discovery

Discover and validate repos **only for the selected components** from Step 0.5.

```bash
WORKSPACE_ROOT=$(git rev-parse --show-toplevel)
PARENT_DIR=$(dirname "$WORKSPACE_ROOT")

for repo in <selected repos>; do
  path="${PARENT_DIR}/${repo}"
  if [ -d "$path" ]; then
    upstream_url=$(git -C "$path" remote get-url upstream 2>/dev/null || true)
    if echo "$upstream_url" | grep -q "osac-project/${repo}"; then
      # OK
    else
      echo "WARNING: unexpected upstream remote"
    fi
  fi
done
```

If a selected repo is not found, ask the user (AskUserQuestion):
- A) Clone it now (`git clone git@github.com:osac-project/<repo>.git` into the
  sibling directory, then `git remote rename origin upstream` to match OSAC
  convention)
- B) Provide an explicit path to an existing checkout
- C) Skip this component (the umbrella chart will use the component's current
  published version)

**Pre-flight warnings (non-blocking):**

For each discovered repo, check for uncommitted changes:
```bash
if [ -n "$(git -C "$path" status --porcelain)" ]; then
  echo "WARNING: ${repo} has uncommitted changes"
fi
```

Warn the user but do not block. Tags are created on `upstream/main`, not the
local working tree.

## Step 1: Fetch Tags and Determine Current Versions

Only fetch tags for the components selected in Step 0.5.

For each component repo, fetch upstream tags and find the latest release tag:

```bash
cd "$REPO_PATH"
git fetch upstream --tags
# List tags from upstream remote, filter to semver releases only
git ls-remote upstream --tags 'v*' | grep -v 'api/' | sed 's|.*/||; s|\^{}||' | grep -E '^v[0-9]+\.[0-9]+\.[0-9]+$' | sort -V | tail -1
```

Tag selection: latest tag matching `v[0-9]+.[0-9]+.[0-9]+` (strict semver, no
pre-release suffixes). Ignore `api/v*` tags (protobuf API versions in
fulfillment-service). Parse `MAJOR.MINOR.PATCH` from the latest tag.

**OCI registry fallback:** If no git tags are found for a component, check the
OCI registry for the latest published chart version:

```bash
# For each chart name published by the component:
helm show chart oci://ghcr.io/osac-project/charts/<chart-name> 2>/dev/null | grep '^version:' | awk '{print $2}'
```

Chart names to check per component (use the first one found):
- fulfillment-service: `fulfillment-service`
- osac-operator: `osac-operator`
- osac-aap: `osac-aap`
- bare-metal-fulfillment-operator: `bare-metal-fulfillment-operator`
- osac-ui: `osac-ui`
- osac (umbrella): `osac`

If an OCI version is found but no git tag exists, use the OCI version as the
current version for computing the next version (patch bump). The component will
be tagged with the new version in Step 5 -- there is no need to backfill the
old tag. Show the version source in the Source column of the plan table.

If neither git tags nor OCI charts are found, treat the component as
unpublished and propose `v0.0.1` as the first version.

## Step 2: Compute Next Versions

- Default: increment PATCH by 1 for each component
- Apply user-specified version overrides from Step 0
- Apply `--skip`/`--only` filters

Print the computed versions using a box-drawing ASCII table:

```
┌─────────────────────────────────┬─────────────────┬─────────────┬─────────┐
│            Component            │     Current     │   Source    │  Next   │
├─────────────────────────────────┼─────────────────┼─────────────┼─────────┤
│ fulfillment-service             │ v0.0.69         │ git tag     │ v0.0.70 │
├─────────────────────────────────┼─────────────────┼─────────────┼─────────┤
│ osac-operator                   │ v0.0.2          │ git tag     │ v0.0.3  │
├─────────────────────────────────┼─────────────────┼─────────────┼─────────┤
│ osac-aap                        │ v0.0.4          │ git tag     │ v0.0.5  │
├─────────────────────────────────┼─────────────────┼─────────────┼─────────┤
│ bare-metal-fulfillment-operator │ (none)          │ unpublished │ v0.0.1  │
├─────────────────────────────────┼─────────────────┼─────────────┼─────────┤
│ osac-ui                         │ (none)          │ unpublished │ v0.0.1  │
├─────────────────────────────────┼─────────────────┼─────────────┼─────────┤
│ osac (umbrella)                 │ v0.0.2          │ OCI         │ v0.0.3  │
└─────────────────────────────────┴─────────────────┴─────────────┴─────────┘
```

Always use box-drawing characters (─ │ ┌ ┐ └ ┘ ├ ┤ ┬ ┴ ┼) for tables
throughout this skill. Never use markdown pipe tables for user-facing output.

## Step 3: Present Release Plan (AskUserQuestion)

Show the same table from Step 2 in the AskUserQuestion prompt, prefixed with
the release reason and suffixed with "All tags will be created on
upstream/main."

Options:
- A) Proceed with these versions
- B) Change versions (re-enter Step 2 with user edits)
- C) Cancel

If B, ask what to change, update the plan, and re-present.
If C, stop.

## Step 4: (merged into Step 0.6)

Component selection now happens in Step 0.6 before tag fetching.

## Step 5: Tag and Push Components

For each selected component (fulfillment-service, osac-operator, osac-aap,
bare-metal-fulfillment-operator, osac-ui):

1. Check if tag already exists: `git ls-remote upstream --tags v<VERSION>`
2. If tag exists on the same commit as `upstream/main`, skip tagging (already
   tagged). Proceed to monitoring.
3. If tag exists on a different commit, ask:
   - A) Delete and re-tag
   - B) Skip this component (umbrella uses old version -- warn user)
   - C) Abort entire release
4. Tag `upstream/main`: `git tag v<VERSION> upstream/main`
5. Push tag: `git push upstream v<VERSION>`
6. If push fails after previous repos succeeded, offer:
   - A) Rollback all tags pushed so far in this release (for each previously
     tagged component: `git push upstream :refs/tags/v<THAT_COMPONENT_VERSION>`)
   - B) Retry this repo
   - C) Abort and investigate manually

**Important:** Always tag `upstream/main`, never a local branch.

## Step 6: Monitor Publish Workflows

After all tags are pushed, wait 10 seconds for GitHub to register the
workflows, then monitor each component:

1. Find the workflow run triggered by the tag:
   ```bash
   gh run list --repo osac-project/<repo> -w publish-charts.yaml --limit 5 \
     --json databaseId,status,conclusion,event,headBranch \
     --jq '.[] | select(.headBranch == "v<VERSION>")'
   ```
   Match by `headBranch == tag name` for reliable run identification.
   If no matching run is found after 30 seconds, warn the user and ask to retry
   or investigate.

2. Poll the specific run ID every 15 seconds:
   ```bash
   gh run view <RUN_ID> --repo osac-project/<repo> --json status,conclusion
   ```

3. Timeout: 5 minutes per workflow run, starting when polling begins for that
   specific run. Interactive steps do not eat into the timeout.

4. Show real-time status using a box-drawing ASCII table:
   ```
   ┌─────────────────────────────────┬────────────────┬─────────────┐
   │ Component                       │ Workflow       │ Status      │
   ├─────────────────────────────────┼────────────────┼─────────────┤
   │ fulfillment-service             │ publish-charts │ completed   │
   │ osac-operator                   │ publish-charts │ in_progress │
   │ osac-aap                        │ publish-charts │ polling...  │
   │ bare-metal-fulfillment-operator │ publish-charts │ polling...  │
   │ osac-ui                         │ publish-charts │ polling...  │
   └─────────────────────────────────┴────────────────┴─────────────┘
   ```

**On failure:** If any workflow fails:
1. Fetch the failed workflow logs: `gh run view <RUN_ID> --repo osac-project/<repo> --log-failed`
2. Show the error to the user
3. Ask whether to:
   - A) Retry (delete tag, re-tag, re-push)
   - B) Skip this component and continue
   - C) Abort the entire release

## Step 7: Verify Chart Publication

For each published chart, verify it exists in the OCI registry:

```bash
helm show chart oci://ghcr.io/osac-project/charts/<chart-name> --version <VERSION>
```

Charts to verify per component:
- fulfillment-service: `fulfillment-service`
- osac-operator: `osac-operator` AND `osac-operator-crds` (both must exist)
- osac-aap: `osac-aap`
- bare-metal-fulfillment-operator: `bare-metal-fulfillment-operator` AND `bare-metal-fulfillment-operator-crds` (both must exist)
- osac-ui: `osac-ui`

If a chart is not found, wait 60 seconds and retry (up to 2 retries). For
osac-operator and bare-metal-fulfillment-operator: verify both charts exist. The
CRDs chart may publish slower from the same workflow. If still missing after
retries, ask user to investigate.

## Step 8: Publish Umbrella Chart

The osac-installer `publish-charts.yaml` workflow accepts `workflow_dispatch`
with explicit version inputs. Dispatch with the component versions just
published:

```bash
gh workflow run publish-charts.yaml \
  --repo osac-project/osac-installer \
  -f version=<UMBRELLA_VERSION> \
  -f operator_crds_version=<OPERATOR_VERSION> \
  -f operator_version=<OPERATOR_VERSION> \
  -f service_version=<SERVICE_VERSION> \
  -f aap_version=<AAP_VERSION> \
  -f bmf_crds_version=<BMF_VERSION> \
  -f bmf_version=<BMF_VERSION> \
  -f ui_version=<UI_VERSION>
```

The umbrella version is determined from osac-installer's latest tag + patch
bump. Using `workflow_dispatch` (not tag push) ensures the umbrella chart gets
the exact component versions just published, without needing to commit a
Chart.yaml update first.

Note: `operator_crds_version` uses the same version as `operator_version`
(both charts are published from the same osac-operator tag). Same applies to
`bmf_crds_version` and `bmf_version`.

## Step 9: Monitor and Verify Umbrella

Same polling pattern as Step 6 for the umbrella workflow. Since this is a
`workflow_dispatch` run (not a tag push), `headBranch` will be `main`, not a
tag name. Match by `event == "workflow_dispatch"` and recency (most recent run
started after the dispatch command). Use:

```bash
gh run list --repo osac-project/osac-installer -w publish-charts.yaml --limit 5 \
  --json databaseId,status,conclusion,event,createdAt \
  --jq '[.[] | select(.event == "workflow_dispatch")] | sort_by(.createdAt) | last'
```

After the workflow succeeds, verify:

```bash
helm show chart oci://ghcr.io/osac-project/charts/osac --version <UMBRELLA_VERSION>
```

Confirm the dependencies list shows the correct component versions.

**After successful verification**, tag osac-installer for version tracking:

```bash
cd "$OSAC_INSTALLER_PATH"
git fetch upstream --tags
git tag v<UMBRELLA_VERSION> upstream/main
git push upstream v<UMBRELLA_VERSION>
```

This creates a version record since `workflow_dispatch` does not create a tag
automatically.

## Step 10: Release Summary

Print a final summary using a box-drawing ASCII table:

```
Release Complete! (Reason: <release reason from Step 0.5>)

┌────────────────────────────────────────┬─────────┬──────────────────────────────────────────────────────────────────────┐
│ Chart                                  │ Version │ Registry                                                           │
├────────────────────────────────────────┼─────────┼──────────────────────────────────────────────────────────────────────┤
│ fulfillment-service                    │ 0.0.70  │ oci://ghcr.io/osac-project/charts/fulfillment-service              │
│ osac-operator                          │ 0.0.3   │ oci://ghcr.io/osac-project/charts/osac-operator                    │
│ osac-operator-crds                     │ 0.0.3   │ oci://ghcr.io/osac-project/charts/osac-operator-crds               │
│ osac-aap                               │ 0.0.5   │ oci://ghcr.io/osac-project/charts/osac-aap                         │
│ bare-metal-fulfillment-operator        │ 0.0.2   │ oci://ghcr.io/osac-project/charts/bare-metal-fulfillment-operator  │
│ bare-metal-fulfillment-operator-crds   │ 0.0.2   │ oci://ghcr.io/osac-project/charts/bare-metal-fulfillment-operator… │
│ osac-ui                                │ 0.0.1   │ oci://ghcr.io/osac-project/charts/osac-ui                           │
│ osac (umbrella)                        │ 0.0.3   │ oci://ghcr.io/osac-project/charts/osac                             │
└────────────────────────────────────────┴─────────┴──────────────────────────────────────────────────────────────────────┘

To install:
  helm install osac oci://ghcr.io/osac-project/charts/osac --version <UMBRELLA_VERSION>
```

If any components were skipped, note which ones and what versions the umbrella
chart uses for them.

## Error Handling

| Error | Action |
|-------|--------|
| `gh` or `helm` not found | Error with install instructions |
| Repo not found at expected path | Ask user for explicit path |
| No `upstream` remote | Error: `git remote add upstream https://github.com/osac-project/<repo>.git` |
| Uncommitted changes in repo | Warn (non-blocking) -- tags are on upstream/main |
| Tag already exists on same commit | Skip tagging, proceed to monitoring |
| Tag already exists on different commit | Ask: (a) delete and re-tag, (b) skip, (c) abort |
| Tag push fails after previous repos tagged | Ask: (a) rollback previous tags, (b) retry, (c) abort |
| Workflow fails | Show failed logs, offer: retry / skip / abort |
| Chart not in registry after workflow success | Wait 60s, retry up to 2 times. If still missing, ask user |
| Timeout (5 min per workflow) | Show current status, ask: keep waiting / abort |
| GitHub API rate limit | Back off to 30s polling interval, warn user |

## Important Notes

- osac-operator publishes TWO charts (operator + operator-crds) from a single
  tag push. Both use the same version number. Verify both exist before declaring
  success.
- bare-metal-fulfillment-operator also publishes TWO charts (operator +
  operator-crds) from a single tag push. Same verification pattern.
- osac-ui publishes ONE chart (`osac-ui`) from a single tag push.
- Always tag `upstream/main` to ensure the latest merged code is tagged.
- The umbrella chart uses `workflow_dispatch` (not tag push) to allow explicit
  version control over component dependencies.
- fulfillment-service also publishes container images and Go binaries via
  separate workflows -- these are triggered by the same tag but are not
  monitored by this skill (only the chart publish is critical).
- The osac-installer is tagged after Step 9 verification (not after dispatch)
  to avoid tagging a failed release.

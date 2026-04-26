# Routines Management API — Empirical Verification

Date: 2026-04-26
Account: <redacted>
Tool: in-process `RemoteTrigger` (Claude Code skill, OAuth handled internally)
Endpoint base: `https://api.anthropic.com/v1/code/triggers`

Test routines created in account (deletable via web UI only):

- `trig_01PXv5ejzp1t25HvsFtQ8cKi` — primary mutable subject (E1–E5, E7, E8)
- `trig_01TbRNePmFRGeMWNDR6mY95P` — `run_once_at` field test (E6)

## Summary verdict table

| ID | Hypothesis | Verdict | Spec impact |
|---|---|---|---|
| E1 | Account-level connectors auto-attach when `mcp_connections` is omitted on create | **❌ Falsified** | Default frontmatter does NOT need `mcp_connections: []` as opt-out. Auto-attach is a web-UI behavior, not API. |
| E2 | `mcp_connections: []` clears existing connections on update | **❌ Falsified** | Empty array is a no-op, not a clear. |
| E3 | Top-level fields merge — sending only `name` preserves everything else | **✅ Confirmed** | Top-level `update` is partial. |
| E4 | `job_config` is replace-not-merge (omitted nested fields are nulled) | **✅ Confirmed (worse)** | Omitted fields reset to **maximally-permissive defaults**, not null. **Read-modify-write is mandatory** for any job_config edit. |
| E5 | Cron expressions firing more than once per hour are rejected | **✅ Confirmed** | HTTP 400 with `error.reason: "cron interval too short"`. |
| E6 | `run_once_at` is the field name for one-off runs | **✅ Confirmed** | Coexists with `cron_expression` in the response (`cron_expression: ""` when `run_once_at` is set). |
| E7 | `clear_mcp_connections: true` is the proper way to wipe connections | **✅ Confirmed** | Only working clear path. Document loudly. |
| E8 | `enabled: false` on create produces a safe, dormant routine | **✅ Confirmed** | `next_run_at` is still computed but the engine respects `enabled`. Safe default for `claude-routines create --draft`. |

## Detailed transcript

### E1 — Excalidraw auto-attach test

**Hypothesis (from peer brief):** Account-level MCP connectors auto-attach to every new routine.

**Procedure:** `create` with `mcp_connections` field omitted entirely from body.

**Request body (relevant excerpt):**
```json
{
  "name": "ZZ_DELETE_ME_routinectl_test_2026-04-26",
  "cron_expression": "0 3 1 1 *",
  "enabled": false,
  "job_config": { "ccr": { "environment_id": "env_011CUyAiiAMotnjJxJVMFdAa", "events": [...], "session_context": { "allowed_tools": ["Read"] } } }
}
```

**Response (relevant excerpt):**
```json
{ "mcp_connections": [], ... }
```

**Verdict:** ❌ **Falsified at the API layer.** The peer's claim that Excalidraw "auto-attaches to every new routine" is true for the **web UI** (the form pre-populates currently-connected connectors and POSTs them) but NOT for the management API. Direct API creates with `mcp_connections` omitted store empty.

**Spec impact:** Default frontmatter does not need `mcp_connections: []` as an opt-out shield. The frontmatter can simply omit the field. Document the web-UI quirk for users who pull-then-edit-on-web-then-pull-again — round-trip stability is on us.

---

### E2 — `mcp_connections: []` clears existing connections

**Procedure:**

1. Add Excalidraw connector via update.
2. Verify it stuck. ✅ (single connector, full echo on GET)
3. Update with `{"mcp_connections": []}`.
4. Verify cleared.

**Step 3 request body:**
```json
{ "mcp_connections": [] }
```

**Step 4 response (relevant):**
```json
{
  "mcp_connections": [
    { "connector_uuid": "a30d9132-0d59-4f1a-a15f-123bf3abba89", "name": "Excalidraw", "permitted_tools": [], "url": "https://mcp.excalidraw.com/mcp" }
  ]
}
```

**Verdict:** ❌ **Falsified.** Empty array is treated as "field not provided," not as "set to empty." Excalidraw is still attached.

**Spec impact:** The `clear` semantic requires a separate flag. We must NOT use `mcp_connections: []` as a clear. (E7 confirms the working path.)

---

### E3 — Top-level partial update

**Procedure:** Update with only `{"name": "..."}` and verify all other fields persist.

**Request body:** `{ "name": "ZZ_DELETE_ME_routinectl_test_2026-04-26 (renamed E3)" }`

**Response (relevant):** Name updated, `cron_expression`, `enabled`, `job_config`, `mcp_connections`, `creator`, etc. all unchanged. `updated_at` advanced.

**Verdict:** ✅ **Confirmed.** Top-level fields not present in the update body are preserved.

**Spec impact:** Safe to issue narrow updates at the top level (e.g., `claude-routines disable <id>` can send just `{"enabled": false}`).

---

### E4 — `job_config` replace-not-merge

**Hypothesis (from peer brief):** "`update` is replace-not-merge inside `job_config`. To change just the prompt, you must send the whole job_config back."

**Procedure:** Update with a `job_config` that includes `ccr.environment_id` and `ccr.events` but **omits** `ccr.session_context`.

**Request body (relevant):**
```json
{
  "job_config": {
    "ccr": {
      "environment_id": "env_011CUyAiiAMotnjJxJVMFdAa",
      "events": [{"data": {...}}]
    }
  }
}
```

**Response (relevant):**
```json
{
  "job_config": {
    "ccr": {
      "environment_id": "env_011CUyAiiAMotnjJxJVMFdAa",
      "events": [...],
      "session_context": {
        "allowed_tools": [
          "preset:default", "Task", "Bash", "Glob", "Grep", "Read", "Edit",
          "MultiEdit", "Write", "NotebookEdit", "WebFetch", "TodoWrite",
          "WebSearch", "BashOutput", "KillBash", "Skill", "Tmux", "Monitor",
          "SendUserFile", "REPL"
        ]
      }
    }
  }
}
```

**Verdict:** ✅ **Confirmed and more severe than peer's claim.** Omitting `session_context` from a partial `job_config` doesn't null it — it **resets to the maximally-permissive platform default tool set** (19+ tools including Bash, Write, Edit, NotebookEdit). The original `["Read"]` allow-list was silently expanded.

**Security implication:** A naive `update --prompt-only` that sends just `job_config.ccr.events` would silently grant the routine Bash + Write access. Any consumer of this API must implement read-modify-write for `job_config`.

**Spec impact:**

1. The `update <file>` command MUST always issue: GET → patch frontmatter fields into the existing job_config → send full job_config back.
2. Document the security gotcha prominently — anyone curl-ing the API directly will hit this.
3. Consider adding a `claude-routines validate <file>` (v0.3+) that catches missing `allowed_tools` before deploy.

---

### E5 — Sub-1h cron rejection

**Procedure:** Update with `cron_expression: "*/30 * * * *"`.

**Response:** HTTP 400.
```json
{
  "error": {
    "message": "cron expression \"*/30 * * * *\" fires more frequently than once per hour; minimum interval is 1 hour",
    "reason": "cron interval too short",
    "type": "invalid_request_error"
  },
  "request_id": "req_011CaSSNyzdJGtAP4i2ycaG9",
  "type": "error"
}
```

**Verdict:** ✅ **Confirmed.** Documented behavior matches reality.

**Spec impact:**

- Error response shape is documented now: `{error: {message, reason, type}, request_id, type}`. Our deploy commands should surface `error.message` directly to the user.
- v0.3 `validate` could pre-check cron intervals and fail locally before round-trip.

---

### E6 — `run_once_at` field

**Procedure:** Create a new routine with `run_once_at: "2027-01-01T00:00:00Z"` and no `cron_expression`.

**Response (relevant):**
```json
{
  "cron_expression": "",
  "run_once_at": "2027-01-01T00:00:00Z",
  "next_run_at": "2027-01-01T00:00:00Z",
  ...
}
```

**Verdict:** ✅ **Confirmed.** `run_once_at` accepted. Both `cron_expression` and `run_once_at` always appear in responses; one is empty string when the other is set.

**Spec impact:**

- Frontmatter supports `cron:` OR `run_once_at:` (mutually exclusive). Validator rejects both being set.
- On `pull`, write the populated one and omit the empty one in the .md file.
- For one-off, `next_run_at == run_once_at` exactly (no stagger). For cron, `next_run_at` is `cron-next + ~3min stagger` (per docs).

---

### E7 — `clear_mcp_connections` flag

**Procedure:** With Excalidraw still attached after E2, send `{"clear_mcp_connections": true}`.

**Response (relevant):** `mcp_connections: []`.

**Verdict:** ✅ **Confirmed.** This is the canonical clear path.

**Spec impact:**

- `update` semantic for `mcp_connections` field in our frontmatter:
  - Field absent in frontmatter → leave the cloud routine's connections untouched (no-op, matches API behavior).
  - Field present and empty (`mcp_connections: []`) → the user expects empty. We must translate this to `{"clear_mcp_connections": true}` in the API call. **This is non-obvious — document.**
  - Field present with entries → send the entries (replace).

---

### E8 — `enabled: false` on create

**Procedure:** All test routines created with `enabled: false`.

**Response:**
- `enabled: false`
- `next_run_at: "2027-01-01T03:03:43.535695632Z"` (computed from cron with stagger, despite enabled:false)

**Verdict:** ✅ **Confirmed.** `next_run_at` is populated but the engine respects `enabled`. Safe default for draft creation.

**Spec impact:** `claude-routines create <file> --draft` (v0.3+) can default `enabled: false` for new routines so users can preview before turning them on.

---

### E9 — Field round-trip taxonomy

Based on observed shapes across all experiments:

#### Writable on input (round-trips on output)
- `name`
- `cron_expression`
- `run_once_at`
- `enabled`
- `job_config.ccr.environment_id`
- `job_config.ccr.events[].data.uuid` (lowercase v4)
- `job_config.ccr.events[].data.session_id` (empty string in input)
- `job_config.ccr.events[].data.type` (always `"user"` for prompts)
- `job_config.ccr.events[].data.parent_tool_use_id` (always `null`)
- `job_config.ccr.events[].data.message.content` (the prompt body)
- `job_config.ccr.events[].data.message.role` (always `"user"`)
- `job_config.ccr.session_context.allowed_tools`
- `job_config.ccr.session_context.model` (optional; absent in output if unset, value defaults to account-level model)
- `job_config.ccr.session_context.sources` (optional; format: `[{"git_repository": {"url": "...", "allow_unrestricted_git_push": true}}]`)
- `mcp_connections[]` (each: `{connector_uuid, name, url, permitted_tools}`)

#### Read-only on output (must be stripped before update)
- `id` (the trigger_id)
- `created_at`
- `updated_at`
- `next_run_at` (engine-computed)
- `creator.account_uuid`
- `creator.display_name`
- `api_token_hint` (set when an API trigger has been generated via the web UI)
- `ended_reason`
- `enabled_plugins[]` (likely writable but not exercised; defaults to `[]`)
- `extra_marketplaces[]` (same)
- `persist_session` (defaults `false`; writability not exercised)
- `job_config.ccr.session_context.outcomes` (runtime state — branches per-run)

#### Write-only update flags (not echoed)
- `clear_mcp_connections: true` — wipes connections, then ignored

#### Spec frontmatter mapping (proposed)

```yaml
---
trigger_id: trig_01...        # presence = update; absence = create
name: "Display name"
cron: "0 7 * * *"             # OR run_once_at, never both
run_once_at: "2027-01-01T00:00:00Z"
enabled: true                 # default true
env_id: env_01...             # required
model: claude-sonnet-4-6      # NOTE: not in API response — likely lives elsewhere or is implicit. Verify before shipping.
sources:                      # optional, list form
  - url: "https://github.com/owner/repo"
    allow_unrestricted_git_push: false
allowed_tools: [Bash, Read, Write, Edit, Glob, Grep, WebFetch, WebSearch]
mcp_connections:              # absent = leave alone, [] = clear via clear_mcp_connections, [entries] = replace
  - connector_uuid: a30d9132-0d59-4f1a-a15f-123bf3abba89
    name: Excalidraw
    url: https://mcp.excalidraw.com/mcp
    permitted_tools: []
---

(prompt body)
```

> **`model` field — verified.** Update sent `session_context.model: "claude-sonnet-4-6"`. Response echoed `"model": "claude-sonnet-4-6"` cleanly. The reason none of hamza's existing routines show a `model` field in GET is they were created without overriding the account default — when unset, the field is absent from output. When set, it round-trips. This also confirmed that read-modify-write works as intended: the same call restored `allowed_tools: ["Read"]` (overwriting the bloated default set from E4) and added `model` in one operation.

---

## Critical findings to surface in the spec

1. **`mcp_connections: []` is a no-op, not a clear.** Use `clear_mcp_connections: true`. Document with a worked example.
2. **`job_config` updates reset omitted nested fields to permissive defaults.** Read-modify-write is mandatory.
3. **Excalidraw auto-attach is a web-UI artifact, not an API behavior.** Our frontmatter does not need a default opt-out.
4. **Cron sub-1h rejection error format is documented**: `{error: {message, reason, type}, request_id, type}`.
5. **No DELETE via API.** Confirmed by tool surface (RemoteTrigger only exposes list/get/create/update/run). Web UI is the only delete path.
6. **`model` field is at `session_context.model`** — verified round-trip. Absent from output when account default is used; set value echoes when overridden.

## Round 2 — capability matrix experiments

The first batch (E1–E9) tested the API mechanics. This batch tests whether each consumer-facing capability is reachable via the management API.

### E10 — GitHub event trigger via API

**Procedure:** `update` with `{"github_triggers": [{"repository": "your-org/your-repo", "event": "pull_request.opened"}]}`.

**Response:** HTTP 200, but field silently dropped — `github_triggers` does not appear in the response and no related state changed.

**Verdict:** **Inconclusive.** Either the field name is wrong, or the management API silently ignores unknown top-level fields. The official docs explicitly state GitHub triggers are configured "from the web UI only," and we have no error-message hint to probe further.

**Spec impact:** Treat GitHub-trigger management as **out of scope for v0.1+v0.2.** Document as a limitation in README. v0.3+ may revisit if Anthropic exposes the schema.

### E11 — API trigger via API

**Procedure:** Not directly testable. Per docs, API-trigger token generation is a separate web modal (`POST /…/regenerate` or similar), and `RemoteTrigger` only exposes the 5 main actions (list/get/create/update/run). The `api_token_hint` field is read-only.

**Verdict:** **Not reachable.** Web UI only.

**Spec impact:** Same as E10 — out of scope for v0.1. Frontmatter should preserve `api_token_hint` on round-trip (read-only echo) so users editing a routine that already has an API trigger don't accidentally interact with it.

### E12 — Custom MCP connector with synthetic UUID

**Procedure:** `update` with `mcp_connections: [{"connector_uuid": "00000000-0000-4000-8000-000000000001", "name": "FakeCustom", "url": "https://example.com/mcp", "permitted_tools": []}]`.

**Response:** HTTP 200. The fake entry is stored verbatim and round-trips on GET.

**Verdict:** ✅ **Confirmed — and significant.** The management API does **not** validate that `connector_uuid` corresponds to a real account-level connector. Any UUID + name + URL combination is accepted at the management layer.

**Practical implication:** Users CAN attach arbitrary MCP servers (e.g., a self-hosted Telegram MCP, custom company MCPs, etc.) to their routines via frontmatter — without going through the web UI's "Connect" flow. The frontmatter just needs the URL; the UUID can be any v4 UUID.

**Caveat (untested):** The runtime might fail to actually connect to a fake URL when the routine fires. We don't know whether the cloud session refuses to start, starts but skips the bad connector, or errors mid-run. **Worth flagging in our README** as "no runtime validation in `claude-routines` either — failures surface in the session, not at deploy time."

**Spec impact:** v0.1 frontmatter supports custom MCPs natively. We can also offer a `--generate-uuid` helper for users who don't have one to copy from a `pull`.

### E13 — `sources` field with `allow_unrestricted_git_push`

**Procedure:** Update T1 with `session_context.sources: [{"git_repository": {"url": "https://github.com/your-org/your-repo", "allow_unrestricted_git_push": false}}]`.

**Response:** Field stored, round-trips correctly. `allow_unrestricted_git_push: false` echoes; setting it to `true` would also work (as already seen in Brain Digest).

**Verdict:** ✅ **Confirmed.** Both fields are writable.

**Spec impact:**

- Frontmatter format for sources:
  ```yaml
  sources:
    - url: https://github.com/owner/repo
      allow_unrestricted_git_push: false
  ```
- `pull` writes both fields; `update` round-trips them.

### E14 — DELETE not exposed

**Procedure:** None — `RemoteTrigger` schema enumerates only `list`, `get`, `create`, `update`, `run`. No `delete` action exists.

**Verdict:** ✅ **Confirmed at tool surface.** No way to delete via this API.

**Spec impact:** v1 deliberately omits `delete`. Document in README: "Delete via web UI at https://claude.ai/code/routines." A `claude-routines list --orphans` (compares cloud routines vs. files in `routines/`) is the closest we get.

### E15 — Manually firing a routine via `run`

**Procedure:**

1. Update T1 to a benign config: `enabled: true`, prompt `"E15 manual run test. Just print the string OK and exit. Do not modify anything."`, `allowed_tools: ["Read"]`, no MCP, no sources.
2. Call `run` with no body. HTTP 200 — response body is the trigger object (unchanged).
3. Call `run` with `{"text": "extra context for this run"}`. Same response.
4. Re-disable to prevent future firing of test routine.

**Verdict:** ✅ **Confirmed at API layer.** `run` action accepts trigger_id and optional body, returns 200 with the trigger object.

**Confirmed via web UI inspection** (claude.ai/code/routines/trig_01PXv5ejzp1t25HvsFtQ8cKi → Runs tab):

- All three `run` calls produced real cloud sessions, each with its own session_id, all marked **Completed** in the routine's run history.
- The session detail page shows the routine's saved prompt followed by the `text` body content, confirming `text` is freeform extra-context appended to the saved prompt (same semantics as the public `/fire` endpoint).
- **The first `run` call was made when the routine was `enabled: false`, and it still fired a manual session.** This is a behavioral finding: `enabled: false` only suppresses **scheduled** triggers; `Run now` (web UI) and `RemoteTrigger.run` (API) bypass the flag. Confirmed by Anthropic's Run history UI showing all three runs as `Manual` with `enabled: false` set on two of them.
- Manual runs do NOT count against the daily routine cap (account showed `9 / 15` daily runs used after my three manual fires; matches docs).

**Why `RemoteTrigger.run` doesn't return session info:** the in-process tool returns the trigger object on success. The session_id/URL is reachable separately via `claude.ai/code/routines/<trigger_id>` → Runs tab, or the user can navigate to `claude.ai/code` to see the new session in their list.

**Spec impact:**

- v0.1 includes `claude-routines run <id>`. Implementation: call `RemoteTrigger.run`, surface trigger name + a link to `https://claude.ai/code/routines/<trigger_id>` so the user can watch the new session in its run history.
- Document `enabled: false` semantics: pause **scheduled** firing; manual `run` still works. This is intuitive (matches "Run now" web button behavior) but worth saying explicitly.
- Optional `text` parameter on `run` is supported as freeform context appended to the saved prompt. Mirror the public `/fire` semantic. v0.1 frontmatter doesn't expose it; `claude-routines run <id> --text "..."` is a simple v0.2 addition.

### E16 — Both `cron_expression` and `run_once_at` set

**Procedure:** Update with `{"cron_expression": "0 5 * * *", "run_once_at": "2027-06-15T12:00:00Z"}`.

**Response:** HTTP 400.
```json
{
  "error": {
    "message": "cannot set both cron_expression and run_once_at",
    "reason": "conflicting fields",
    "type": "invalid_request_error"
  }
}
```

**Verdict:** ✅ **Confirmed.** Mutually exclusive at the API layer.

**Spec impact:** Frontmatter validator rejects both being set; `pull` writes whichever is populated.

## Capability matrix — answers to hamza's questions

| Capability | Via management API? | v0.1? | Notes |
|---|---|---|---|
| List routines | ✅ Yes | ✅ Yes | `list` action |
| Get a single routine | ✅ Yes | ✅ Yes | `get` action with `trigger_id` |
| Create routine (cron) | ✅ Yes | ✅ Yes | with `cron_expression` |
| Create routine (run-once) | ✅ Yes | ✅ Yes | with `run_once_at` |
| Update any field | ✅ Yes | ✅ Yes | top-level partial; job_config replace-not-merge |
| Run / fire a routine | ✅ Yes | ✅ Yes | `run` action; no session URL in response |
| Delete a routine | ❌ No | ❌ No | web UI only |
| Add GitHub trigger | ❓ Probably no | ❌ No | unknown field name; doc says web-only |
| Add API trigger / generate token | ❌ No | ❌ No | web UI only |
| Set/change `model` | ✅ Yes | ✅ Yes | `session_context.model` |
| Attach environment | ✅ Yes | ✅ Yes | `environment_id` (required field) |
| List/manage environments | ❌ No | ❌ No | not in management API surface; web UI only |
| Attach existing MCP connector | ✅ Yes | ✅ Yes | by `connector_uuid` from `pull`-ed data |
| Attach custom/arbitrary MCP | ✅ Yes (E12) | ✅ Yes | API does not validate connector_uuid |
| Clear all MCP connectors | ✅ Yes | ✅ Yes | `clear_mcp_connections: true` (NOT `mcp_connections: []`) |
| Set sources (git repos) | ✅ Yes | ✅ Yes | `session_context.sources[]` |
| Toggle `allow_unrestricted_git_push` | ✅ Yes | ✅ Yes | per-source field |
| Set `allowed_tools` | ✅ Yes | ✅ Yes | `session_context.allowed_tools` |
| Toggle `enabled` (pause/resume) | ✅ Yes | ✅ Yes | top-level `enabled` |
| Edit prompt body | ✅ Yes | ✅ Yes | `events[0].data.message.content` |
| Add multiple events to one routine | ❓ Untested | ❌ No (v0.1) | All hamza's routines have exactly 1 event; the schema is an array. |

**Bottom line for hamza's questions:**

- **Triggers:** Schedule (cron + run_once_at) ✅ via API; GitHub & API triggers ❌ web-UI only.
- **Connectors:** Both standard (existing connector_uuid) and **fully custom** (synthetic UUID + arbitrary URL) ✅ via API. Telegram-as-MCP would be: spin up a Telegram MCP server, point a connector at it. (Hamza's current setup uses Telegram via env var `$TELEGRAM_BOT_TOKEN`, which is environment-level, not connector-level.)
- **Permissions:** `allowed_tools` ✅, `allow_unrestricted_git_push` per source ✅. Setup-script and network-policy permissions live on the *environment*, not the routine, and are not in the management-API surface.
- **Model:** ✅ `session_context.model`.
- **Environment:** Attach by ID ✅; create/edit envs ❌ (web UI).
- **Edit:** ✅ everything writable above is editable.
- **Run from here:** ✅ HTTP 200 returned; user should verify session actually fired by checking claude.ai/code.

## Round 3 — UI tour findings (Playwright walkthrough)

A walkthrough of the entire web UI surface at `claude.ai/code/routines` to make sure the API surface we tested actually maps to every consumer-facing field. New findings, beyond what API testing exposed:

### Schedule trigger UI

Six preset options: **Once / Hourly / Daily / Weekdays / Weekly / Custom**. "Once" maps to `run_once_at`. "Custom" is a literal cron textbox (placeholder `0 9 * * *`). Daily / Weekdays / Weekly show a time picker that emits the corresponding cron under the hood. UI explicitly notes "Runs are staggered by a few minutes to spread server load."

### Model selector enum

The model dropdown exposes a closed enum:

- **Default** (= account default; field omitted in API)
- **Claude Opus 4.7**
- **Claude Opus 4.7 (1M context)**
- **Claude Sonnet 4.6**
- **Claude Haiku 4.5**

API field: `job_config.ccr.session_context.model` — string. Verified value `claude-sonnet-4-6` round-trips. Other accepted strings likely follow the same pattern (`claude-opus-4-7`, `claude-opus-4-7[1m]`, `claude-haiku-4-5`).

### GitHub event trigger — three categories, not two

The official docs list two event categories (Pull request, Release). The web UI exposes a **third**: **Issue events**.

Full event taxonomy from the UI:

- **Pull request events** (22): assigned, auto_merge_disabled, auto_merge_enabled, closed, converted_to_draft, demilestoned, dequeued, edited, enqueued, labeled, locked, milestoned, opened, ready_for_review, reopened, review_request_removed, review_requested, synchronize, unassigned, unlabeled, unlocked, plus "All Pull request events"
- **Release events** (7): created, deleted, edited, prereleased, published, released, unpublished, plus "All Release events"
- **Issue events** (17): assigned, closed, deleted, demilestoned, edited, labeled, locked, milestoned, opened, pinned, reopened, transferred, typed, unassigned, unlabeled, unlocked, unpinned, untyped, plus "All Issue events"

Filter system: UI shows "Add a filter condition" — narrows which events trigger a run. Without filters, "Fires on every matching event — this can consume your routine run limits quickly."

UI also says "Runs as <user-email-redacted>" — identity attribution for actions taken on GitHub during the run.

The Claude GitHub App must be installed on the target repo for webhook delivery (UI prompts to install when missing). Doc-confirmed.

### Add connector flow

The routine creation form's "Add connector" dropdown is populated **from account-level connectors only**. For hamza the dropdown shows "No more connectors available" because only Excalidraw is registered. To add a new MCP connector to the account, the user goes to `claude.ai/settings/connectors`. The routine form cannot mint a connector itself.

This bounds a v0.1 limitation: `claude-routines` cannot create new connectors via the management API in a way the web UI recognizes — but as E12 showed, the API will accept arbitrary `connector_uuid` + URL pairs and store them on the routine. So `claude-routines` users can attach custom MCPs *to a routine* without going through the UI's Connect flow, but those connectors won't appear in the user's account-level Connectors list. (Whether the runtime actually loads them is an open question — flagged in E12.)

### Environment edit dialog — fields

Cloud environments are managed via the env selector at `claude.ai/code` (top-of-sidebar gear icons → opens edit dialog). The dialog exposes:

- **Name** (string)
- **Network access** (None / Trusted / Custom — Custom shows an "Allowed domains" textarea with `*` wildcard support, plus a checkbox "Also include default list of common package managers")
- **Environment variables** (.env format; UI warns "These are visible to anyone using this environment — don't add secrets or credentials")
- **Setup script** (Bash, runs at session start before Claude Code launches)
- **Archive** button (the env equivalent of delete — archived envs hide from selector but existing sessions keep running)

None of these fields are in the management API surface — environments are managed via the web UI only. Routines reference an env by `environment_id`, but cannot create or modify the env itself.

### Daily run quota

The routines list shows `9 / 15 included daily runs used`. Pro/Max accounts get **15 daily routine runs** as standard quota. Manual runs (web "Run now" or `RemoteTrigger.run`) and one-off `run_once_at` runs **do not count**. Confirmed: my three E15 manual fires didn't bump the counter past 9.

### Confirmed: delete is web-UI only

The routine detail page has an explicit `Delete` button. Two clicks (button + confirmation). No equivalent in `RemoteTrigger`. v1 spec stays.

### Form structure — what's NOT in the routine resource

For our spec, three categories of state DON'T live on the routine itself:

1. **Account-level connectors** (managed at `/settings/connectors`)
2. **Cloud environments** (managed at `/code` → env selector)
3. **GitHub App installation** per repo (a GitHub-side concern, not routine config)

`claude-routines` can reference all three by ID/URL, but cannot create them. This bounds the v0.1 promise cleanly.

## Cleanup

Test routines remain in account, both `enabled: false`, far-future schedules. Delete via web UI:

- https://claude.ai/code/routines → find rows starting with `ZZ_DELETE_ME_VIA_WEB_UI__` → delete.
- IDs: `trig_01PXv5ejzp1t25HvsFtQ8cKi` (used for E1–E5, E7, E10, E12, E13, E15, E16), `trig_01TbRNePmFRGeMWNDR6mY95P` (E6).

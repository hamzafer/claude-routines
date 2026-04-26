# Risks and caveats (call out in README)

1. **Management API is undocumented.** Only `/fire` is in Anthropic's public docs. The endpoints we call (`/v1/code/triggers`) are reverse-engineered from the in-process `RemoteTrigger` skill. They may change without notice.

2. **Anthropic may ship official tooling.** When they do, this project's lifespan becomes uncertain. README is upfront about this.

3. **Single-account scope.** Routines belong to individual claude.ai accounts; not shared across teammates.

4. **Env vars are not real secrets.** Cloud-environment env vars are stored as plain text and visible to anyone with edit access to the environment. Don't put production credentials there until Anthropic ships a real secrets store.

5. **`update` security gotcha** — anyone calling the API directly (curl, alternative tooling) can accidentally expand `allowed_tools` by sending a partial `job_config`. We solve this in `claude-routines` via mandatory read-modify-write; we should document the underlying API behavior so others writing tooling are aware.

6. **Custom MCP runtime not validated.** The management API accepts arbitrary `connector_uuid` + URL, but the cloud session's behavior with an unreachable MCP URL is untested. Failures will surface at runtime, not at deploy time.

7. **GitHub triggers don't round-trip cleanly through `update`.** GitHub event triggers and API tokens are stored on the routine but managed exclusively via the web UI. If a user has them set on a routine and runs `claude-routines update <file>`, our implementation must preserve those fields verbatim. The read-modify-write flow does this naturally — but it's worth flagging.

8. **`personal/` leak risk.** The convention is `.gitignore` + a pre-commit hook. Users who skip the hook install or use `git add -A` carelessly can leak. README emphasizes installing the hook.

9. **Cron & timezone confusion.** Cron is UTC at the API layer; the web UI auto-converts from local time. A user who has been editing routines on the web and then `pull`s sees UTC cron expressions in the .md files, not their local time. README explains.

10. **No real test surface for v0.1.** There's no automated test suite — the verification doc is the test record. Future versions should add API contract tests against a sandbox environment if Anthropic provides one.

# Onboard a workspace

1. Add the workspace to `config/workspaces.json` with its teams and a model.
2. Add the workspace to `config/workspace-tools.json`.
3. Restart `assistant-connectors` so it picks up the config.
4. Tell the team.

**Step 2 matters.** A workspace that is in `workspaces.json` and not in
`workspace-tools.json` starts with every tool enabled, including `commit` and
`send_mail`. That is deliberate so that a new pilot group can try the assistant
the same day, but it means the safe default only applies to workspaces somebody
remembered to configure.

`ws-beta` is the sandbox and is intentionally not in `workspace-tools.json`.

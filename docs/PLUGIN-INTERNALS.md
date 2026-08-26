# AI-skills plugin — maintainer internals

This document is for maintainers of the `azure-sap-automation-github`
plugin shipped from this repository. It covers the on-disk layout, the
intentional per-runtime manifest differences, the fields that must stay
consistent across manifests, and the `x-sdaf-graph` advisory metadata
carried in the Copilot manifest.

Operators should start at [`PLUGINS.md`](PLUGINS.md).

## Layout

- `skills/` — real directories (no symlinks); the canonical skill source
  read by all three agents.
- `.github/plugin/{plugin,marketplace}.json` — GitHub Copilot CLI
  manifests.
- `.claude-plugin/{plugin,marketplace}.json` — Claude Code manifests.
- `gemini-extension.json` — Gemini extension manifest at the repo root.
- `.github/copilot-instructions.md` — canonical AI-agent context;
  `CLAUDE.md` and `GEMINI.md` are `@`-imports of that file.

The write-scope allowed for skill/plugin authoring work is enumerated in
ground rule 2 of
[`.github/copilot-instructions.md`](../.github/copilot-instructions.md).
Files under `.github/workflows/`, `.cfg_template/`, and `WORKSPACES/`
are out of bounds for skill/plugin edits.

## Manifests are hand-authored per runtime

Each manifest is hand-authored to its runtime's schema; none is
generated or mirrored from another. The deliberate differences:

- **Copilot** sets `"skills": "skills/"` in `plugin.json` and carries a
  richer `marketplace.json` (`metadata`, per-plugin `author` /
  `keywords` / `homepage` / `repository` / `license`).
- **Claude** omits the `skills` field to avoid a double-scan warning
  against the default `<plugin-root>/skills/` scan. Its
  `marketplace.json` requires `name`, `owner.name`, and `plugins[]`
  with `name` + `source`; this repository additionally populates
  per-plugin `description`, `version`, `author`, `homepage`, and
  `license` because the Claude marketplace schema accepts them and the
  facts are known.
- **Gemini** reads a single root `gemini-extension.json` and consumes
  neither plugin manifest.

## Fields that must stay consistent

Across all three plugin manifests
(`.github/plugin/plugin.json`, `.claude-plugin/plugin.json`,
`gemini-extension.json`) the following must match:

- `name`: `azure-sap-automation-github`
- `version`: `0.1.0`
- `description` — the standardized string in every manifest is:

  > AI skills for the SDAF (SAP Deployment Automation Framework) GitHub
  > Actions surface: repository bootstrap and setup utility, public
  > Azure authentication diagnostics with documented sovereign-cloud
  > limitations, and the 00-12 workflow sequence.

Both marketplace files (`.github/plugin/marketplace.json`,
`.claude-plugin/marketplace.json`) additionally share the marketplace
`name` `sap-automation-gh-bootstrap` (matching the repo slug). **Change
any of these in one file, change them in all five.**

## `x-sdaf-graph` metadata (Copilot manifest only)

`.github/plugin/plugin.json` carries an advisory `x-sdaf-graph` block
that records this plugin's relationship to the other SDAF AI plugins:

```json
"x-sdaf-graph": {
  "node": "azure-sap-automation-github",
  "role": "surface",
  "hub": "azure-sap-automation",
  "peers": ["azure-sap-automation-devops"]
}
```

- The block is metadata only. No runtime loader consumes it, and it
  does not trigger any install.
- `peers` is a JSON string array of plugin `name` values. Add a future
  peer by extending the array with another plugin name string; do not
  change the shape.
- The block is **not** carried in the Claude manifest
  (`.claude-plugin/plugin.json`). Claude's plugin schema is not
  documented to accept unknown top-level extension fields, and the
  block is not consumed by any runtime, so it is omitted from the
  Claude manifest rather than risk a strict-validation warning. The
  Gemini extension manifest omits it for the same reason.
- Related-plugin ownership: the hub `azure-sap-automation` ships from
  [`Azure/sap-automation`](https://github.com/Azure/sap-automation);
  the Azure DevOps plugin `azure-sap-automation-devops` ships from
  [`Azure/sap-automation-bootstrap`](https://github.com/Azure/sap-automation-bootstrap).
  Neither is present in this repository.

## Scope reminder

Skill/plugin authoring work in this repository does not install other
plugins and does not modify workflows, `.cfg_template/`, or
`WORKSPACES/`. The plugin is a documentation and diagnostics surface
layered on the existing GitHub Actions template.

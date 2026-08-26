# Repository AI-agent context — `sap-automation-gh-bootstrap`

This repository is the **GitHub Actions template / configuration repo** for the
SAP Deployment Automation Framework (SDAF). It ships:

- `.github/workflows/` — the eleven dispatchable workflows (`00`–`12`).
- `.cfg_template/` — deployer / library / landscape / system tfvars templates.
- `WORKSPACES/` — generated per-deployment tfvars committed by workflows `00`,
  `02`, and `04`.
- `docs/` — the authoritative operator documentation. Every operational claim
  an agent makes about this repo must resolve to a `docs/*.md` or `README.md`
  section.

## AI-skills plugin shipped from this repo

**Plugin name (all three agents):** `azure-sap-automation-github`.
**Node role in the SDAF plugin graph:** GitHub-Actions surface node. The hub
plugin `azure-sap-automation` is shipped from `Azure/sap-automation`; this node is
installed only by operators whose control-plane surface is GitHub Actions.

Skills shipped:

| Skill | Class | Owns |
|---|---|---|
| `sdaf-gh-bootstrap` | action-loop | Template repo, setup utility, GitHub App, repo variables, Environments and `.cfg_template` substitution, workflow `00`. |
| `sdaf-gh-oidc-and-auth` | action-loop | The two auth layers (`azure/login` vs Terraform), OIDC vs SPN secret, enterprise-claim tenant policy. |
| `sdaf-gh-workflow-sequence` | context-primer | Workflows `00`–`12`: order, inputs, what commits to `main`, blocked `07` status. |

See [`docs/PLUGINS.md`](../docs/PLUGINS.md) for install commands.

## Ground rules for agents editing this repo

1. **Documented-only.** Instructional content in skills MUST cite `docs/*.md`
   or `README.md` in this repo (or the linked core repo). Do not reconstruct
   procedures from workflow YAML that the docs do not describe.
2. **No production edits from skill work.** Skill/plugin artifacts are limited
   to `skills/`, `.github/plugin/`, `.claude-plugin/`, root
   `gemini-extension.json`, `CLAUDE.md`, `GEMINI.md`,
   `.github/copilot-instructions.md`, and `docs/PLUGINS.md`. Workflows under
   `.github/workflows/`, `.cfg_template/`, and scripts are out of bounds for
   skill authoring.
3. **Stable anchors.** Cross-references between markdown files use heading
   slugs, never line numbers.
4. **Workflow `07` is blocked** in current docs (`docs/06-00-software-installation.md`
   § "Configure and install SAP"; `README.md` § "Current implementation status").
   Skills MUST NOT teach a workflow-`07` recipe.
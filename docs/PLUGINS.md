# AI-skills plugin — operator guide

This is the operator guide for the **`azure-sap-automation-github`**
AI-skills plugin shipped from this repository. It is documentation and
diagnostics only — it does not run workflows or modify
`.github/workflows/`, `.cfg_template/`, or `WORKSPACES/`, and installing
it is never a prerequisite for using the workflows.

**All SDAF AI plugins are optional and independently installable.** For
complete coverage, install the hub plus the plugin(s) matching your
control-plane surface:

- Local or scripted execution — hub plugin `azure-sap-automation` from
  [`Azure/sap-automation`](https://github.com/Azure/sap-automation).
- Azure DevOps control plane — hub plus `azure-sap-automation-devops`
  from
  [`Azure/sap-automation-bootstrap`](https://github.com/Azure/sap-automation-bootstrap).
- GitHub Actions control plane (this repository) — hub plus
  `azure-sap-automation-github` shown below.

**The hub plugin is recommended for complete coverage; this plugin does
not install it automatically.**

> Maintainers: see [`PLUGIN-INTERNALS.md`](PLUGIN-INTERNALS.md) for the
> manifest layout, intentional per-runtime differences, and the fields
> that must stay consistent across manifests.

## Install

### GitHub Copilot CLI

```bash
copilot plugin marketplace add Azure/sap-automation-gh-bootstrap
copilot plugin install azure-sap-automation-github@sap-automation-gh-bootstrap
```

### Claude Code

```text
/plugin marketplace add Azure/sap-automation-gh-bootstrap
/plugin install azure-sap-automation-github@sap-automation-gh-bootstrap
```

### Gemini CLI

```bash
gemini extensions install https://github.com/Azure/sap-automation-gh-bootstrap
```

The Gemini extensions form is used because the `skills install` form
requires `--path` for multi-skill extensions.

## Verify the install

The plugin ships exactly **three** skills. After installing, confirm all
three are visible to your assistant:

- `sdaf-gh-bootstrap`
- `sdaf-gh-oidc-and-auth`
- `sdaf-gh-workflow-sequence`

In Copilot CLI and Claude Code they appear under the plugin
`azure-sap-automation-github`; in Gemini CLI they appear under the
extension of the same name.

Mechanical checks per runtime — expect the plugin (or extension)
`azure-sap-automation-github` and all three skills above:

GitHub Copilot CLI:

```bash
copilot plugin list
```

Claude Code:

```text
/plugin
```

Gemini CLI:

```bash
gemini extensions list
```

Fewer than three skills means the install did not complete — see
[Troubleshooting](#troubleshooting).

## The three skills and where each stops

Each skill owns one concern and hands off when a question crosses its
boundary.

- **`sdaf-gh-bootstrap` — one-time repo and environment scaffolding.**
  Creating the configuration repo from this template, the pre-workflow-`00`
  repository variables (`ARM_ENVIRONMENT`, `AZURE_ENVIRONMENT`,
  `AZURE_AUDIENCE`), the SDAF setup utility from `Azure/sap-automation`,
  and workflow `00` generating `WORKSPACES/DEPLOYER/*.tfvars` and
  `WORKSPACES/LIBRARY/*.tfvars` from `.cfg_template/`. Stops at OIDC /
  `azure/login` / `ARM_CLIENT_SECRET` and at the workflow catalogue.
- **`sdaf-gh-oidc-and-auth` — the identity plumbing every workflow runs
  through.** Two independent layers: `azure/login` (OIDC federated
  credential; reads `AZURE_ENVIRONMENT`, `AZURE_AUDIENCE`) and Terraform /
  Ansible (managed identity `USE_MSI=true` + `MSI_ID`, or service
  principal with `ARM_CLIENT_SECRET`; always reads `ARM_ENVIRONMENT`).
  Resolves `AADSTS7002381`, `AADSTS7000215` / `AADSTS700016`,
  `AADSTS900382`, and "`azure/login` succeeded but hit the wrong cloud".
  Stops at bootstrap mechanics and at the workflow catalogue.
- **`sdaf-gh-workflow-sequence` — which workflow to run when.** The
  ordered `00`–`12` catalogue, each workflow's `workflow_dispatch`
  inputs, which commit to `main` (`00`, `02`, `04`), which create GitHub
  Environments (`00`, `02` — `04` deliberately does not), which run on
  `self-hosted` runners, which support genuine plan-only via `test`, and
  the blocked status of workflow `07`. Hands off to `sdaf-gh-bootstrap`
  for pre-`00` setup and to `sdaf-gh-oidc-and-auth` for auth failures
  inside any workflow.

## Example prompts

You do not need to name a skill; the descriptions are written so the
assistant selects the right one from the shape of your question.

`sdaf-gh-bootstrap`:

- "Walk me through bootstrapping SDAF on GitHub Actions."
- "The SDAF setup utility failed — what did it already create?"
- "Which repository variables do I set before workflow `00`?"

`sdaf-gh-oidc-and-auth`:

- "I'm getting `AADSTS7002381` on `azure/login` — what does that mean?"
- "`azure/login` succeeded but Terraform hit the wrong cloud. What's
  wrong?"
- "OIDC + managed identity or service principal with `ARM_CLIENT_SECRET`?"
- "What are the documented Azure Government limitations for
  `azure/login` in this repository?"

`sdaf-gh-workflow-sequence`:

- "What order do the SDAF workflows run in?"
- "Which workflows commit to `main`?"
- "Why does workflow `04` not create a GitHub Environment?"
- "Is workflow `07` usable right now?"

## Related plugins

Two related SDAF AI plugins ship separately and are independently
installable:

- **Hub — `azure-sap-automation`** from
  [`Azure/sap-automation`](https://github.com/Azure/sap-automation) —
  recommended companion; carries the shared SDAF context. Not installed
  automatically by this plugin.
- **Azure DevOps plugin — `azure-sap-automation-devops`** from
  [`Azure/sap-automation-bootstrap`](https://github.com/Azure/sap-automation-bootstrap)
  — install if your control-plane surface is Azure DevOps rather than
  GitHub Actions.

## Scope and documented-only discipline

Skills operate under a strict **documented-only rule**: every
instructional claim resolves to a section in `docs/*.md`, `README.md`,
or the linked core repo. Consequences an operator will feel:

- The skills **will not teach a workflow-`07` recipe.** Workflow `07` is
  blocked per
  [`docs/06-00-software-installation.md`](06-00-software-installation.md)
  ("Configure and install SAP") and [`README.md`](../README.md)
  ("Current implementation status").
- Other status limitations (workflow `01` dry-run not operational,
  workflow `10` removal has no plan mode, Azure Government `azure/login`
  not implemented) are surfaced when asked, and no others are invented.
  This plugin diagnoses public Azure authentication end to end; for
  sovereign clouds it surfaces only the documented limitations, not a
  working recipe.
- The plugin does not install other plugins and does not modify
  workflows, `.cfg_template/`, or `WORKSPACES/`.

## Update and uninstall

Each runtime's own CLI is the authoritative source for update and
uninstall commands, and lifecycle behaviour differs between runtimes.
Manage the plugin through the runtime's own help or plugin manager:

- GitHub Copilot CLI: `copilot plugin --help`
- Claude Code: `/plugin help` (or the `/plugin` interactive menu)
- Gemini CLI: `gemini extensions --help`

## Troubleshooting

**Fewer than three skills visible after install.** The marketplace-add
step must succeed before the install step. The marketplace name is
`sap-automation-gh-bootstrap` and the plugin name is
`azure-sap-automation-github` — mixing them up is the most common cause
of a partial install.

**Assistant answers with generic Azure or Terraform content, not SDAF
specifics.** Mention a concrete artefact in your prompt — a workflow
number, a `.cfg_template/*.tfvars` file, a variable name
(`ARM_ENVIRONMENT`, `AZURE_AUDIENCE`), or an error code
(`AADSTS7002381`). The skill descriptions key off exactly those
phrases.

**Assistant refuses to give a workflow-`07` procedure.** Intentional —
see [Scope and documented-only
discipline](#scope-and-documented-only-discipline).

**Symptoms inside a running workflow, not the plugin itself.** See
[`troubleshooting.md`](troubleshooting.md).

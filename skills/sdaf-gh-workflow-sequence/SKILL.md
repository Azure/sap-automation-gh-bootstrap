---
name: sdaf-gh-workflow-sequence
description: |
  Context-primer for the SDAF GitHub Actions workflow catalogue: the ordered
  sequence `00`-`12`, each workflow's `workflow_dispatch` inputs, which
  workflows commit generated tfvars to `main` (`00`, `02`, `04`) and which
  create GitHub Environments (`00` control-plane, `02` workload-zone —
  `04` deliberately does not), which workflows run on `self-hosted` runners
  (`01` deploy-control-plane and later, plus `06`, `06.5`, `10`, `12`),
  which support genuine plan-only via `test` (per current docs), and the
  status of the blocked workflow `07-configuration-installation.yml`. Invoke
  on "what does workflow N do", "what runs first", "which workflow commits
  to `main`", "why does workflow 04 not create an Environment", "is
  workflow 07 usable?", or "which workflows are safe to plan-only". Hand off
  to `sdaf-gh-bootstrap` for pre-`00` setup and to `sdaf-gh-oidc-and-auth`
  for authentication failures inside any workflow.
allowed-tools: [Read, Grep]
license: MIT
metadata:
  author: Microsoft
  version: 0.1.0
  class: context-primer
---

# sdaf-gh-workflow-sequence

Primer on the ordered workflow catalogue and where each workflow's outputs
land. This skill does **not** drive execution; use it to answer "what runs
where, in what order, and what commits to `main`", then hand off.

## When to invoke

- "What does workflow N do?" / "Which workflow runs after N?"
- "Which workflows commit to `main`?"
- "Why doesn't workflow `04` create an Environment?"
- "Is workflow `07` usable?" / "Can I install SAP from Actions today?"
- "Which workflows support genuine plan-only via the `test` input?"

Hand off to:

- `sdaf-gh-bootstrap` for pre-`00` setup (repo variables, setup utility,
  Environments, `.cfg_template` substitution mechanics).
- `sdaf-gh-oidc-and-auth` for `azure/login` / Terraform-auth failures
  inside any workflow.

## The sequence

The canonical spine, from [`README.md` § Workflow sequence](../../README.md#workflow-sequence)
and the per-stage docs. Detailed per-workflow inputs are in
[`references/workflow-inputs.md`](references/workflow-inputs.md).

| # | File | Purpose | Runs on | Commits to `main`? | Creates Environment? |
|---|---|---|---|---|---|
| 00 | `00-create-environment.yml` | Create control-plane Environment; generate `WORKSPACES/DEPLOYER` + `WORKSPACES/LIBRARY` tfvars from `.cfg_template/` | GitHub-hosted | **Yes** | **Yes** (control-plane) |
| 01 | `01-deploy-control-plane.yml` | Deploy deployer VM, SAP library, state, Key Vault, self-hosted runner | `prepare-deployer` on `ubuntu-latest`, later jobs on `self-hosted` | No | No |
| 02 | `02-create-workload-environment.yml` | Create workload-zone Environment; generate `WORKSPACES/LANDSCAPE` tfvars | GitHub-hosted | **Yes** | **Yes** (workload-zone) |
| 03 | `03-deploy-sap-workload-zone.yml` | Deploy the shared workload zone | `self-hosted` | No | No |
| 04 | `04-create-system-environment.yml` | Generate `WORKSPACES/SYSTEM` tfvars | GitHub-hosted | **Yes** | **No** (deliberate — SYSTEM is config only) |
| 05 | `05-sap-system-deployment.yml` | Deploy SAP system infrastructure | `self-hosted` | No | No |
| 06 | `06-sap-software-download.yml` | Download SAP media using one predefined BOM | `self-hosted` | No | No |
| 06.5 | `065-sap-software-download.yml` | Download media from app + kernel + DB BOMs | `self-hosted` | No | No |
| 07 | `07-configuration-installation.yml` | Install and configure SAP — **blocked, do not run** | `self-hosted` (blocked; do not dispatch) | n/a | n/a |
| 10 | `10-remover-terraform.yml` | Destructive removal of SAP system and/or workload zone | `self-hosted` | No | No |
| 12 | `12-remove-control-plane.yml` | Remove control plane; tear down the self-hosted runner | `remove-control-plane` on `self-hosted`, then `remove-control-plane-finalize` on `ubuntu-latest` | No | No |

`04` deliberately does **not** create a GitHub Environment. The expected
result is a committed `WORKSPACES/SYSTEM/<workload-zone>-<sid>/…tfvars`.
See [`docs/troubleshooting.md` § A creation workflow does not commit configuration](../../docs/troubleshooting.md#a-creation-workflow-does-not-commit-configuration)
and [`docs/05-00-sap-system.md` § Create system configuration](../../docs/05-00-sap-system.md#create-system-configuration).

## `test` / plan-only semantics per workflow

From the current docs. Do not treat `test` as a dry-run where the docs
explicitly say otherwise.

| Workflow | Docs statement | Treat as plan-only? |
|---|---|---|
| `01` | [Control-plane dry-run limitation](../../docs/03-00-control-plane.md#control-plane-dry-run-limitation) — the input exists but is not forwarded | **No** |
| `03` | [Plan and deploy](../../docs/04-00-workload-zone.md#plan-and-deploy) — enable `test` and review the plan | **Yes** |
| `05` | [Plan and deploy](../../docs/05-00-sap-system.md#plan-and-deploy) — enable `test` deployment without applying | **Yes**, but log can misreport — see [`docs/troubleshooting.md` § Workflow 05 fails while reporting a successful deployment](../../docs/troubleshooting.md#workflow-05-fails-while-reporting-a-successful-deployment) |
| `12` | [Workflow 10 safeguards](../../docs/07-00-operations.md#workflow-10-safeguards) — safer removal path; validate against your pinned SDAF version first | **Conditionally** |
| `10` | [Workflow 10 safeguards](../../docs/07-00-operations.md#workflow-10-safeguards) — no usable plan-only gate | **No** |

> **Forward reference (temporary ownership).** The deeper `test` / plan-only
> concept and the workflow-`05` step-conclusion-vs-log misreport are
> scheduled to move to a hub skill `sdaf-plan-and-test-semantics` (plan
> §5.4, `sdaf-plan-and-test-semantics`) when the hub node ships. Until then,
> this primer carries the surface-scoped view; do not delete the rows above
> when that hub skill lands — they remain the GitHub-Actions view.

## Workflow `07` — blocked in current docs

`07-configuration-installation.yml` is documented as **blocked**: the YAML
contains invalid tab indentation and its parameter-validation step passes an
absolute inventory path the composite action prefixes. See
[`docs/06-00-software-installation.md` § Configure and install SAP](../../docs/06-00-software-installation.md#configure-and-install-sap)
and [`README.md` § Current implementation status](../../README.md#current-implementation-status).
Do not encode a `07` recipe; hand off to a "workflow 07 is not usable" note.

## What this skill does NOT do

- Does not run any workflow.
- Does not describe pre-`00` bootstrap (repo variables, setup utility) —
  see `sdaf-gh-bootstrap`.
- Does not diagnose Azure-login or Terraform-auth failures — see
  `sdaf-gh-oidc-and-auth`.
- Does not describe SDAF core (Terraform / Ansible / self-hosted runner
  install) — those live in `Azure/sap-automation`.

## See also

- [`sdaf-gh-bootstrap`](../sdaf-gh-bootstrap/SKILL.md)
- [`sdaf-gh-oidc-and-auth`](../sdaf-gh-oidc-and-auth/SKILL.md)
- [`references/workflow-inputs.md`](references/workflow-inputs.md)
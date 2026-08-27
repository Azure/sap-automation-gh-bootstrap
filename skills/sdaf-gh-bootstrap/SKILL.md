---
name: sdaf-gh-bootstrap
description: |
  Action-loop skill for bootstrapping the SDAF GitHub Actions surface: create
  the configuration repo from `Azure/sap-automation-gh-bootstrap`, set the
  pre-workflow-`00` repository variables (`ARM_ENVIRONMENT`,
  `AZURE_ENVIRONMENT`, `AZURE_AUDIENCE`), run the SDAF setup utility from
  `Azure/sap-automation` (which creates the GitHub App, repo vars/secrets,
  Azure identity, and the first control-plane Environment), then dispatch
  workflow `00-create-environment.yml` to generate and commit
  `WORKSPACES/DEPLOYER/*.tfvars` and `WORKSPACES/LIBRARY/*.tfvars` from
  `.cfg_template/` to `main`. Invoke on "bootstrap the GH Actions repo",
  "run workflow 00", "set up SDAF on GitHub", "the setup utility failed", or
  `.cfg_template` / repo-variables questions. Do NOT invoke for OIDC /
  `azure/login` / `ARM_CLIENT_SECRET` / sovereign identity (use
  `sdaf-gh-oidc-and-auth`) or the ordered `00`-`12` catalogue (use
  `sdaf-gh-workflow-sequence`).
allowed-tools: [Read, Grep]
license: MIT
metadata:
  author: Microsoft
  version: 0.1.0
  class: action-loop
---

# sdaf-gh-bootstrap

Bootstraps the SDAF GitHub Actions surface: create the config repo, run the
setup utility, land pre-`00` repository variables, and dispatch workflow `00`
to commit the first `WORKSPACES/DEPLOYER` + `WORKSPACES/LIBRARY` tfvars.

## When to invoke

Concrete triggers:

- "Bootstrap SDAF on GitHub Actions" / "set up the GitHub config repo".
- "The setup utility failed" / "GitHub App wasn't created".
- "Workflow `00` did not commit tfvars" / "I don't see the DEPLOYER tfvars".
- "What repo variables must exist before workflow `00`?"
- "How does `.cfg_template` substitution work?"

Do NOT invoke for:

- OIDC subject format, `azure/login` vs Terraform behaviour,
  `ARM_CLIENT_SECRET`, sovereign-cloud identity → `sdaf-gh-oidc-and-auth`.
- Full ordered catalogue of workflows `00`-`12` and their inputs →
  `sdaf-gh-workflow-sequence`.

## Ownership boundary (read this first)

This repo is a **template + configuration repo**; the setup utility, the
runner installation, and all Terraform/Ansible logic live in
`Azure/sap-automation` — see [`docs/02-00-bootstrap.md` § Ownership
boundary](../../docs/02-00-bootstrap.md#ownership-boundary). Do not modify
core-repo behaviour from this skill.

## Recipe

1. **Confirm prerequisites are met.** GitHub admin rights, default branch
   `main`, Actions write permission, Azure RBAC ready. See
   [`docs/01-00-prerequisites.md` § GitHub requirements](../../docs/01-00-prerequisites.md#github-requirements)
   and [`§ Azure access`](../../docs/01-00-prerequisites.md#azure-access).
2. **Create the configuration repository** from `Azure/sap-automation-gh-bootstrap`
   as a template. See [`docs/02-00-bootstrap.md` § Create the configuration
   repository](../../docs/02-00-bootstrap.md#create-the-configuration-repository).
3. **Set pre-workflow-`00` repository variables.** `ARM_ENVIRONMENT`,
   `AZURE_ENVIRONMENT`, `AZURE_AUDIENCE`. The public and sovereign triples
   are the canonical property of `sdaf-gh-oidc-and-auth` — see
   [`../sdaf-gh-oidc-and-auth/references/cloud-matrix.md`](../sdaf-gh-oidc-and-auth/references/cloud-matrix.md).
   Documented at
   [`docs/02-00-bootstrap.md` § Configure cloud and OIDC behavior](../../docs/02-00-bootstrap.md#configure-cloud-and-oidc-behavior).
4. **Download and run the setup utility** from `Azure/sap-automation`. It
   creates the GitHub App, seeds repository variables/secrets, provisions
   the Azure identity, and creates the first control-plane Environment. See
   [`docs/02-00-bootstrap.md` § Download and run the setup utility](../../docs/02-00-bootstrap.md#download-and-run-the-setup-utility).
5. **Choose authentication** (MSI vs SPN + `ARM_CLIENT_SECRET`) and record
   the choice in `USE_MSI` / `MSI_ID`. See
   [`docs/02-00-bootstrap.md` § Choose authentication](../../docs/02-00-bootstrap.md#choose-authentication).
   Deeper OIDC / secret detail belongs in `sdaf-gh-oidc-and-auth`.
6. **Verify bootstrap** before dispatching workflows. See
   [`docs/02-00-bootstrap.md` § Verify bootstrap](../../docs/02-00-bootstrap.md#verify-bootstrap).
7. **Dispatch `00-create-environment.yml`** with `control_plane_name`,
   `use_msi`, `msi_id`, `use_webapp`. The workflow creates the
   control-plane Environment, generates deployer + library tfvars from
   `.cfg_template/`, commits them to `main`, and copies vars/secrets into
   the new Environment. See
   [`docs/03-00-control-plane.md` § Create the environment and configuration](../../docs/03-00-control-plane.md#create-the-environment-and-configuration).

## Verify outcomes (action-loop check)

After step 7 succeeds:

- `WORKSPACES/DEPLOYER/<CONTROL_PLANE_NAME>-INFRASTRUCTURE.tfvars` exists on
  `main`.
- `WORKSPACES/LIBRARY/<CONTROL_PLANE_NAME>-SAP_LIBRARY.tfvars` exists on
  `main`.
- Repository → Environments shows the control-plane Environment with the
  copied vars and secrets.

If any check fails, see [`references/known-failures.md`](references/known-failures.md).

## Hard rules

- **The default branch must be `main`.** Documented at
  [`docs/01-00-prerequisites.md` § GitHub requirements](../../docs/01-00-prerequisites.md#github-requirements).
- **Never author or overwrite `GITHUB_TOKEN`.** GitHub supplies it. See
  [`docs/02-00-bootstrap.md` § Repository defaults](../../docs/02-00-bootstrap.md#repository-defaults).
- **Editing `.cfg_template/*` does not update existing `WORKSPACES/`.**
  Templates are re-substituted only by re-running the relevant creation
  workflow. See
  [`README.md` § Configuration templates and deployment inputs](../../README.md#configuration-templates-and-deployment-inputs).
- **Do not run workflow `01` before workflow `00` completes.** See
  [`README.md` § Getting started](../../README.md#getting-started).

## What this skill does NOT do

- Does not explain OIDC subject formats, `ARM_CLIENT_SECRET` semantics, or
  sovereign-cloud identity — see `sdaf-gh-oidc-and-auth`.
- Does not describe the full `00`-`12` workflow catalogue — see
  `sdaf-gh-workflow-sequence`.
- Does not modify workflows, `.cfg_template/`, or `WORKSPACES/`.

## See also

- [`sdaf-gh-oidc-and-auth`](../sdaf-gh-oidc-and-auth/SKILL.md)
- [`sdaf-gh-workflow-sequence`](../sdaf-gh-workflow-sequence/SKILL.md)
- [`references/known-failures.md`](references/known-failures.md)
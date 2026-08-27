# `sdaf-gh-bootstrap` — known failures

Every entry cites a `docs/*.md` or `README.md` section in this repo. Field-only
findings without documentation are deliberately excluded (see plan D19,
"documented-only rule"). If a symptom you see is not on this list, do not
invent a recipe — hand off to `sdaf-failure-triage` (a hub skill scheduled to ship separately from `Azure/sap-automation`, plan §5.4; not present in this plugin) or say the docs are
silent.

## A creation workflow (`00`, `02`, `04`) did not commit

Symptom: workflow succeeded but the expected `WORKSPACES/*.tfvars` did not
appear on `main`.

Documented causes and fixes: default branch not `main`, insufficient
workflow permissions, or a race with another push to `main`. See
[`docs/troubleshooting.md` § A creation workflow does not commit configuration](../../../docs/troubleshooting.md#a-creation-workflow-does-not-commit-configuration).

Note: workflow `04` **does not** create a GitHub Environment. Its expected
result is only the committed `WORKSPACES/SYSTEM/...tfvars` file.

## Workflow `00` reports "Invalid index" and an empty region

Documented cause: the region code is absent from `var.region_mapping` inside
the container image referenced by `DOCKER_IMAGE`. Fix: pin `DOCKER_IMAGE` to
an image that contains the mapping and rerun. See
[`docs/troubleshooting.md` § Workflow 00 reports "Invalid index" and an empty region](../../../docs/troubleshooting.md#workflow-00-reports-invalid-index-and-an-empty-region)
and [`docs/02-00-bootstrap.md` § Repository defaults](../../../docs/02-00-bootstrap.md#repository-defaults).

## Bootstrap succeeded but no Environments appear

See [`docs/07-00-operations.md` § No environments appear](../../../docs/07-00-operations.md#no-environments-appear).

## Missing variables or secrets after bootstrap

See [`docs/07-00-operations.md` § Missing variables or secrets](../../../docs/07-00-operations.md#missing-variables-or-secrets).

## Authentication failures during or right after workflow `00`

Hand off to `sdaf-gh-oidc-and-auth` for `AADSTS7002381`, `AADSTS7000215`,
`AADSTS700016`, `AADSTS900382`, and "`azure/login` hit the wrong cloud".

## Symptoms without a documented recipe

For symptoms that this repo's docs do not anchor to a fix — including the
field-only classes explicitly excluded below — hand off to
`sdaf-failure-triage`. That skill is scheduled to ship separately from the
hub `azure-sap-automation` plugin (plan §5.4) and is **not** present in
this plugin. Until it ships, note the symptom to the operator and route
to human diagnosis; do not synthesise a recipe. Same forward-ownership
shape as the plan-only content marked in
[`../../sdaf-gh-workflow-sequence/SKILL.md`](../../sdaf-gh-workflow-sequence/SKILL.md).

## What is deliberately NOT covered here

The following symptoms are surfaced in field evidence but not present in
this repo's docs at the anchors above. Do not encode them as documented
procedure — the plan's D19a is open and field-only findings are excluded
from instructional content:

- Setup-utility crashes tied to Windows console encoding.
- `az ad app create` `--service-management-reference` requirements in
  policy-enforcing tenants.
- Removed `az` CLI flags in specific `az` versions.
- `git safe.directory` behaviour on first-run workflow `00`.

If a user hits any of these, note the symptom and route to human diagnosis
rather than reciting a workaround.
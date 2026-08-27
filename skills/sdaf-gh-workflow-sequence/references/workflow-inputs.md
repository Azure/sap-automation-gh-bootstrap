# `sdaf-gh-workflow-sequence` — workflow inputs

Inputs listed per workflow, straight from `.github/workflows/*.yml` and the
corresponding `docs/` section. This is a reference table; the parent SKILL.md
carries the ordering and plan-only semantics.

## `00-create-environment.yml`

Inputs: `control_plane_name`, `use_msi`, `msi_id`, `use_webapp`.
Docs: [`docs/03-00-control-plane.md` § Create the environment and configuration](../../../docs/03-00-control-plane.md#create-the-environment-and-configuration).

## `01-deploy-control-plane.yml`

Inputs (verified from `.github/workflows/01-deploy-control-plane.yml`):

- `control_plane_name` — required, `type: environment`.
- `force_reset` — boolean, `default: false`. Documented semantics: rerun
  workflow `01` with **Force a re-install** enabled to recover from a
  failed runner install / stale registration. See
  [`docs/07-00-operations.md` § Retry runner installation](../../../docs/07-00-operations.md#retry-runner-installation)
  and [`docs/troubleshooting.md` § The self-hosted runner is unavailable](../../../docs/troubleshooting.md#the-self-hosted-runner-is-unavailable).
- `test` — boolean, `default: false`. Documented as dry-run but **not**
  forwarded to the deploy step. Do not treat as plan-only.

Docs: [`docs/03-00-control-plane.md` § Deploy the control plane](../../../docs/03-00-control-plane.md#deploy-the-control-plane)
and [`§ Control-plane dry-run limitation`](../../../docs/03-00-control-plane.md#control-plane-dry-run-limitation).

Runs-on: `prepare-deployer` on `ubuntu-latest`; later jobs on
`self-hosted`.

## `02-create-workload-environment.yml`

Inputs: `workload_environment`, `control_plane_name`.
Docs: [`docs/04-00-workload-zone.md` § Create the workload environment](../../../docs/04-00-workload-zone.md#create-the-workload-environment).

## `03-deploy-sap-workload-zone.yml`

Inputs (per docs): workload-zone and control-plane Environments, plus
`test` (genuine plan-only per docs).
Docs: [`docs/04-00-workload-zone.md` § Plan and deploy](../../../docs/04-00-workload-zone.md#plan-and-deploy).

## `04-create-system-environment.yml`

Inputs: `system_sid`, `workload_environment`.
Docs: [`docs/05-00-sap-system.md` § Create system configuration](../../../docs/05-00-sap-system.md#create-system-configuration).
No GitHub Environment is created — this is deliberate.

## `05-sap-system-deployment.yml`

Inputs (verified from `.github/workflows/05-sap-system-deployment.yml`):

- `sap_system_identifier` — required, `type: string`, `default: "X00"`.
- `workload_zone_name` — required, `type: environment`. The workflow uses
  this Environment for credentials and variables.
- `test` — boolean, `default: false`. Documented plan-only path — see
  [`docs/05-00-sap-system.md` § Plan and deploy](../../../docs/05-00-sap-system.md#plan-and-deploy).
  Caveat: the step-conclusion can misreport a successful deployment; judge
  from log content, not step status. See
  [`docs/troubleshooting.md` § Workflow 05 fails while reporting a successful deployment](../../../docs/troubleshooting.md#workflow-05-fails-while-reporting-a-successful-deployment).
  The misreport concept is scheduled to move to hub skill
  `sdaf-plan-and-test-semantics` (plan §5.4) when it ships; the row above
  remains the GitHub-Actions view.

Runs-on: `self-hosted`.
Docs: [`docs/05-00-sap-system.md` § Plan and deploy](../../../docs/05-00-sap-system.md#plan-and-deploy).

## `06-sap-software-download.yml`

Inputs: `bom_base_name`, `control_plane_name`, `re_download`, `extra_params`.
Docs: [`docs/06-00-software-installation.md` § Choose a download workflow](../../../docs/06-00-software-installation.md#choose-a-download-workflow)
and [`§ Download SAP software`](../../../docs/06-00-software-installation.md#download-sap-software).

## `065-sap-software-download.yml`

Inputs: `application_bom_base_name`, `kernel_bom_base_name`,
`db_bom_base_name`, `platform`, `bom_save_name`, `bom_override_name`,
`control_plane_name`, `re_download`, `extra_params`.
Docs: same as above.

## `07-configuration-installation.yml` — blocked

Docs mark this workflow as unusable: invalid YAML indentation and an
inventory-path bug. Do not dispatch. The YAML declares `runs-on:
self-hosted`, but the workflow is not usable in its current state. See
[`docs/06-00-software-installation.md` § Configure and install SAP](../../../docs/06-00-software-installation.md#configure-and-install-sap)
and [`README.md` § Current implementation status](../../../README.md#current-implementation-status).

## `10-remover-terraform.yml`

Inputs: `cleanup_sap` (default `true`), `sap_system_identifier`,
`cleanup_workload_zone` (default `false`), `workload_zone_name`.
Destructive; **no** usable plan-only gate. Docs:
[`docs/07-00-operations.md` § Workflow 10 safeguards](../../../docs/07-00-operations.md#workflow-10-safeguards).

## `12-remove-control-plane.yml`

Inputs (verified from `.github/workflows/12-remove-control-plane.yml`):

- `control_plane_name` — required, `type: environment`.
- `test` — boolean, `default: false`. `12` forwards `test` as `TEST_ONLY`
  in the underlying script, so it is the safer removal path; docs say to
  validate the end-to-end behaviour against the pinned SDAF version first.
  The deeper `test` / plan-only concept is scheduled to move to hub skill
  `sdaf-plan-and-test-semantics` (plan §5.4) when it ships.

Runs-on (two jobs, verified from YAML):

- `remove-control-plane` on `self-hosted` — invokes
  `12-remove-control-plane.sh`.
- `remove-control-plane-finalize` on `ubuntu-latest` — tears down the
  self-hosted runner registration.

Docs: [`docs/07-00-operations.md` § Workflow 10 safeguards](../../../docs/07-00-operations.md#workflow-10-safeguards).

Upstream observation (docs-anchored): `.github/workflows/12-remove-control-plane.yml`
is displayed in GitHub Actions as **`11 - Remove Control Plane`** — the
YAML `name:` and the file number differ. This is a repo observation, not a
skill-owned bug; do not edit the workflow. See
[`docs/07-00-operations.md` § Workflow 10 safeguards](../../../docs/07-00-operations.md#workflow-10-safeguards)
for the docs' own note on the display name.
# Troubleshoot GitHub Actions deployments

[Central SDAF hub](https://github.com/Azure/sap-automation) |
[GitHub Actions journey](../README.md) |
[Operations and removal](07-00-operations.md)

Use this page for the first diagnostic steps. Preserve configuration, logs, and Terraform
state before retrying.

## A creation workflow does not commit configuration

1. Confirm that the repository default branch is `main`.
2. Confirm that the GitHub App token can write repository contents and workflows.
3. Inspect the failed run for workflow `00`, `02`, or `04`.
4. Check whether another commit reached `main` before the workflow push.
5. Resolve the branch conflict, then rerun only the failed creation workflow.
6. Verify the expected file under `WORKSPACES` and review its commit before deployment.

Workflow `04` does not create a GitHub environment. Its expected result is only a committed
`WORKSPACES/SYSTEM/<workload-zone>-<sid>/<workload-zone>-<sid>.tfvars` file. Workflow `05`
uses the existing workload-zone environment.

## Azure login fails

1. Verify the tenant, subscription, client ID, authentication mode, and environment scope.
2. Compare the GitHub OIDC issuer, audience, and subject with the Microsoft Entra federated
   credential.
3. Verify role assignments at every required Azure scope.
4. Replace an unknown or expired secret; GitHub does not display stored secret values.

The merged workflows use Public Azure defaults for `azure/login`. Do not use them with
Azure Government until cloud-specific login inputs and environment propagation are
implemented and validated.

## The self-hosted runner is unavailable

1. Open **Settings** > **Actions** > **Runners** and inspect the runner status.
2. Confirm that the deployer VM is running.
3. Inspect the `configure_deployer` VM extension and runner service logs.
4. Verify outbound connectivity to GitHub, Azure, package sources, and required SAP
   endpoints.
5. Remove only a failed extension and stale runner registration before rerunning workflow
   `01` with **Force a re-install** enabled.

The runner installation is implemented by the core
[`Azure/sap-automation`](https://github.com/Azure/sap-automation) repository, not by this
configuration template.

## Terraform plan or apply fails

1. Confirm the selected GitHub environment and configuration commit.
2. Verify the expected `WORKSPACES` file and Terraform state key.
3. Read the first actionable error and correct identity, quota, policy, image, naming,
   network, DNS, storage, or provider issues.
4. Rerun the workflow in validated test mode when that workflow supports it.
5. Review the replacement plan before apply.

Do not run concurrent workflows against the same state. Do not manually delete managed
resources unless the approved recovery procedure requires it.

## Software download fails

1. Confirm that the SAP S-user can download the selected media.
2. Verify the control-plane environment and SAP library storage.
3. For workflow `06`, verify the predefined combined BoM.
4. For workflow `06.5`, verify the application, database, kernel, platform, and exact
   combined name.
5. Keep re-download disabled unless replacing existing media is intentional.

The shared BoM definitions are owned by
[`Azure/SAP-automation-samples`](https://github.com/Azure/SAP-automation-samples).

## Workflow 07 cannot run

The currently merged `.github/workflows/07-configuration-installation.yml` remains
blocked. It contains tab indentation, which is invalid YAML. It also passes an absolute
inventory path to `.github/actions/run-ansible`, which prefixes that value with the
parameters folder and produces an inconsistent inventory path.

Do not dispatch workflow `07` until both defects are corrected and the complete workflow
is validated. After correction, retry only installation stages that logs and system checks
prove are safe to repeat.

## Removal cannot be safely previewed

Workflow `10 - SAP Infrastructure removal` has no declared `test` input, even though its
jobs reference `inputs.test`. Treat dispatch as destructive. Review the selected system,
workload zone, state, backups, locks, and cleanup switches before running it.

The file `.github/workflows/12-remove-control-plane.yml` is displayed as
`11 - Remove Control Plane`. It forwards its declared `test` input as `TEST_ONLY`, but
validate that behavior against the pinned core SDAF version before relying on it.

## Collect evidence before opening an issue

Record the workflow file and run URL, failing job and step, sanitized error, configuration
commit, selected environment, pinned SDAF image or digest, Terraform and Ansible versions,
affected state key, and whether the run was a retry. Do not include credentials, tokens,
private keys, SAP passwords, or unredacted Terraform state.
